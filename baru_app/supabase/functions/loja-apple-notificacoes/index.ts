import { jsonResponse, servico } from '../_shared/http.ts'
import { ambienteDoJws, lerTransacao, verificador } from '../_shared/apple.ts'

/**
 * Avisos da App Store (App Store Server Notifications V2) sobre as
 * assinaturas do Baru no iPhone.
 *
 * Cadastro na App Store Connect (Baru → Informações do app → Notificações do
 * servidor da App Store), versão 2, produção e sandbox:
 *   https://<projeto>.supabase.co/functions/v1/loja-apple-notificacoes
 *
 * Sem login: quem garante a origem é a assinatura da Apple em cada aviso,
 * conferida com o certificado raiz fixado em _shared/apple.ts. Aviso de teste
 * local (Xcode) é ignorado.
 *
 * Renovou → expira_em avança. Cancelou a renovação → renova = false.
 * Reembolso ou revogação → revogada_em, e o acesso cai na hora.
 * Responde 200 em tudo que não é falha nossa; em falha, 500 e a Apple reenvia.
 */
Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405)

  let signedPayload = ''
  try {
    const corpo = await req.json()
    signedPayload = typeof corpo?.signedPayload === 'string' ? corpo.signedPayload : ''
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const ambiente = signedPayload ? ambienteDoJws(signedPayload) : null
  if (!ambiente || ambiente === 'Xcode') return jsonResponse({ ok: true, ignorada: true })

  let aviso
  try {
    aviso = await verificador(ambiente).verifyAndDecodeNotification(signedPayload)
  } catch (e) {
    console.error('loja-apple-notificacoes: assinatura inválida', e instanceof Error ? e.message : String(e))
    return jsonResponse({ error: 'assinatura_invalida' }, 400)
  }

  const db = servico()
  const id = aviso.notificationUUID ?? ''
  const tipo = [aviso.notificationType, aviso.subtype].filter(Boolean).join('/')
  if (id) {
    const { error: repetido } = await db.from('baru_apple_notificacoes').insert({ id, tipo })
    if (repetido) return jsonResponse({ ok: true, repetida: true })
  }

  try {
    const jwsTransacao = aviso.data?.signedTransactionInfo
    if (!jwsTransacao) return jsonResponse({ ok: true })
    const t = await lerTransacao(jwsTransacao, ambiente)

    let renova: boolean | undefined
    if (aviso.data?.signedRenewalInfo) {
      const r = await verificador(ambiente).verifyAndDecodeRenewalInfo(aviso.data.signedRenewalInfo)
      renova = r.autoRenewStatus === 1
    }
    const revogada = t.revogadaEm ??
      (aviso.notificationType === 'REFUND' || aviso.notificationType === 'REVOKE' ? new Date().toISOString() : null)

    const mudanca = {
      produto: t.produto,
      plano_base: t.planoBase,
      expira_em: t.expiraEm,
      revogada_em: revogada,
      teste: t.ambiente !== 'Production',
      ...(renova === undefined ? {} : { renova }),
      atualizado_em: new Date().toISOString(),
    }

    const { data: atual } = await db.from('baru_assinaturas_loja')
      .select('user_id').eq('compra_id', t.transacaoOriginalId).maybeSingle()
    if (atual) {
      const { error } = await db.from('baru_assinaturas_loja').update(mudanca).eq('user_id', atual.user_id)
      if (error) throw new Error(error.message)
    } else if (t.conta && !t.produto.startsWith('baru_familia')) {
      // A compra chegou aqui antes do app avisar: grava pela conta que
      // comprou. Plano família espera o app, que diz qual laço ele cobre.
      const { data: usuario } = await db.auth.admin.getUserById(t.conta)
      if (usuario?.user) {
        const { error } = await db.from('baru_assinaturas_loja').upsert({
          user_id: t.conta,
          loja: 'apple',
          compra_id: t.transacaoOriginalId,
          ...mudanca,
        })
        if (error) throw new Error(error.message)
      }
    }
    return jsonResponse({ ok: true })
  } catch (e) {
    console.error('loja-apple-notificacoes:', e instanceof Error ? e.message : String(e))
    if (id) await db.from('baru_apple_notificacoes').delete().eq('id', id)
    return jsonResponse({ error: 'erro_interno' }, 500)
  }
})
