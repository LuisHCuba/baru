import { comCors, jsonResponse, servico, usuarioDe } from '../_shared/http.ts'
import { ambienteDoJws, lerTransacao, testeLocalLiberado } from '../_shared/apple.ts'

/**
 * Assinatura comprada dentro do app (loja do celular).
 *
 *   { loja: 'google', token, produto, laco? }  → confere com a Google Play, confirma
 *                                         (acknowledge) e libera o acesso.
 *   { loja: 'apple', jws, laco? }         → confere a assinatura da Apple na
 *                                         transação do StoreKit 2 e libera o acesso.
 *                                         Renovação e cancelamento chegam por
 *                                         `loja-apple-notificacoes`.
 *
 * Produtos: baru_assinatura (individual: planos base mensal e anual) e
 * baru_familia (família: libera as primeiras 6 pessoas do laço `laco`, que o
 * comprador precisa administrar) e baru_familia_mais (Família+: até 10).
 *
 * A compra só vale para a conta que comprou: o app manda o id da conta como
 * obfuscatedAccountId, e a Google devolve o mesmo valor na conferência.
 *
 * Segredo: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (conta de serviço com acesso à API
 * da Google Play), nos segredos das Edge Functions. Cópia do Infisical.
 */

const PACOTE = 'tech.lhcx.baru'
const PRODUTOS = new Set(['baru_assinatura', 'baru_familia', 'baru_familia_mais'])
const FAMILIA = new Set(['baru_familia', 'baru_familia_mais'])
const API = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACOTE}`

const b64url = (b: ArrayBuffer | Uint8Array | string) =>
  btoa(typeof b === 'string' ? b : String.fromCharCode(...new Uint8Array(b instanceof Uint8Array ? b : new Uint8Array(b))))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

let tokenGoogle: { valor: string; ate: number } | null = null

/** Token de acesso da conta de serviço (JWT assinado com RS256). */
async function acessoGoogle(): Promise<string> {
  if (tokenGoogle && tokenGoogle.ate > Date.now() + 60_000) return tokenGoogle.valor
  const sa = JSON.parse(Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON') ?? '{}')
  if (!sa.client_email || !sa.private_key) throw new Error('conta de serviço da Google ausente')
  const agora = Math.floor(Date.now() / 1000)
  const cab = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const corpo = b64url(JSON.stringify({
    iss: sa.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token', iat: agora, exp: agora + 3000,
  }))
  const pem = String(sa.private_key).replace(/-----[^-]+-----/g, '').replace(/\s+/g, '')
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  const chave = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'])
  const assinatura = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', chave, new TextEncoder().encode(`${cab}.${corpo}`))
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${cab}.${corpo}.${b64url(assinatura)}`,
  })
  const j = await r.json()
  if (!r.ok || !j.access_token) throw new Error(`token da Google: ${r.status}`)
  tokenGoogle = { valor: j.access_token, ate: Date.now() + (j.expires_in ?? 3000) * 1000 }
  return tokenGoogle.valor
}

async function google(metodo: string, caminho: string): Promise<{ status: number; corpo: Record<string, unknown> }> {
  const r = await fetch(`${API}${caminho}`, {
    method: metodo,
    headers: { authorization: `Bearer ${await acessoGoogle()}`, 'content-type': 'application/json' },
    body: metodo === 'POST' ? '{}' : undefined,
  })
  const texto = await r.text()
  return { status: r.status, corpo: texto ? JSON.parse(texto) : {} }
}


/** Plano família: só o administrador do laço compra, e um laço tem um plano família só. */
async function confereFamilia(uid: string, laco: string | null): Promise<Response | null> {
  if (!laco) return jsonResponse({ error: 'laco_obrigatorio', message: 'Escolha o laço que o plano família vai cobrir.' }, 400)
  const db0 = servico()
  const { data: eu } = await db0.from('baru_familia_membros').select('papel, admin')
    .eq('familia_id', laco).eq('user_id', uid).is('saiu_em', null).maybeSingle()
  if (!eu || eu.papel !== 'responsavel' || !eu.admin) {
    return jsonResponse({ error: 'nao_admin', message: 'Só um administrador do laço assina o plano família.' }, 403)
  }
  const { data: outro } = await db0.from('baru_assinaturas_loja').select('user_id')
    .eq('laco_id', laco).in('produto', [...FAMILIA]).is('revogada_em', null).gt('expira_em', new Date().toISOString())
    .neq('user_id', uid).maybeSingle()
  if (outro) return jsonResponse({ error: 'ja_coberto', message: 'Este laço já tem plano família.' }, 409)
  return null
}

/** iPhone: a transação assinada pela Apple (JWS do StoreKit 2). */
async function compraApple(uid: string, corpo: Record<string, unknown>, laco: string | null): Promise<Response> {
  const jws = typeof corpo.jws === 'string' ? corpo.jws : ''
  if (!jws || jws.length > 20000) return jsonResponse({ error: 'parametros_invalidos' }, 400)
  const ambiente = ambienteDoJws(jws)
  if (!ambiente) return jsonResponse({ error: 'compra_invalida', message: 'A compra não pôde ser conferida.' }, 400)
  if (ambiente === 'Xcode' && !testeLocalLiberado(uid)) {
    return jsonResponse({ error: 'teste_local', message: 'Compra de teste local não libera acesso nesta conta.' }, 403)
  }
  let t
  try {
    t = await lerTransacao(jws, ambiente)
  } catch (e) {
    console.error('loja-assinatura: apple', e instanceof Error ? e.message : String(e))
    return jsonResponse({ error: 'compra_invalida', message: 'A compra não pôde ser conferida com a Apple.' }, 400)
  }
  if (t.conta && t.conta !== uid.toLowerCase()) {
    return jsonResponse({ error: 'outra_conta', message: 'Esta assinatura pertence a outra conta do Baru.' }, 409)
  }
  const db = servico()
  const { data: dono } = await db.from('baru_assinaturas_loja').select('user_id, laco_id').eq('compra_id', t.transacaoOriginalId).maybeSingle()
  if (dono && dono.user_id !== uid) {
    return jsonResponse({ error: 'outra_conta', message: 'Esta assinatura pertence a outra conta do Baru.' }, 409)
  }
  // Restaurar ou renovar não diz o laço: vale o que já estava gravado.
  laco ??= dono?.laco_id ?? null
  if (FAMILIA.has(t.produto)) {
    const recusa = await confereFamilia(uid, laco)
    if (recusa) return recusa
  }
  const { error } = await db.from('baru_assinaturas_loja').upsert({
    user_id: uid,
    loja: 'apple',
    produto: t.produto,
    compra_id: t.transacaoOriginalId,
    expira_em: t.expiraEm,
    renova: true,
    revogada_em: t.revogadaEm,
    teste: t.ambiente !== 'Production',
    plano_base: t.planoBase,
    laco_id: FAMILIA.has(t.produto) ? laco : null,
    atualizado_em: new Date().toISOString(),
  })
  if (error) {
    console.error('loja-assinatura: gravar apple', error.message)
    return jsonResponse({ error: 'erro_interno' }, 500)
  }
  const { data: acesso } = await db.rpc('baru_acesso_de', { p_uid: uid })
  return jsonResponse({ acesso })
}

const VALIDOS = new Set(['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'SUBSCRIPTION_STATE_CANCELED'])

Deno.serve(comCors(async (req: Request) => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405)
  const uid = await usuarioDe(req)
  if (!uid) return jsonResponse({ error: 'unauthorized' }, 401)

  let corpo: Record<string, unknown>
  try {
    corpo = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const laco = typeof corpo.laco === 'string' && /^[0-9a-f-]{36}$/i.test(corpo.laco) ? corpo.laco : null
  if (corpo.loja === 'apple') return compraApple(uid, corpo, laco)
  const token = typeof corpo.token === 'string' ? corpo.token : ''
  const produto = typeof corpo.produto === 'string' ? corpo.produto : ''
  if (corpo.loja !== 'google' || !token || token.length > 4000 || !PRODUTOS.has(produto)) {
    return jsonResponse({ error: 'parametros_invalidos' }, 400)
  }
  if (FAMILIA.has(produto)) {
    const recusa = await confereFamilia(uid, laco)
    if (recusa) return recusa
  }

  let compra
  try {
    compra = await google('GET', `/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`)
  } catch (e) {
    console.error('loja-assinatura: google', e instanceof Error ? e.message : String(e))
    return jsonResponse({ error: 'loja_indisponivel', message: 'Não foi possível conferir a compra agora. Tente de novo.' }, 502)
  }
  if (compra.status !== 200) {
    return jsonResponse({ error: 'compra_invalida', message: 'A compra não foi encontrada na Google Play.' }, 400)
  }
  const c = compra.corpo as {
    subscriptionState?: string
    acknowledgementState?: string
    testPurchase?: unknown
    externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string }
    lineItems?: { productId?: string; expiryTime?: string; autoRenewingPlan?: { autoRenewEnabled?: boolean }; offerDetails?: { basePlanId?: string } }[]
  }
  const item = (c.lineItems ?? []).find((l) => l.productId === produto)
  const conta = c.externalAccountIdentifiers?.obfuscatedExternalAccountId
  if (!item?.expiryTime) return jsonResponse({ error: 'compra_invalida', message: 'A compra não é do Baru.' }, 400)
  if (conta && conta !== uid) {
    return jsonResponse({ error: 'outra_conta', message: 'Esta assinatura pertence a outra conta do Baru.' }, 409)
  }

  const db = servico()
  const { data: dono } = await db.from('baru_assinaturas_loja').select('user_id').eq('compra_id', token).maybeSingle()
  if (dono && dono.user_id !== uid) {
    return jsonResponse({ error: 'outra_conta', message: 'Esta assinatura pertence a outra conta do Baru.' }, 409)
  }

  // A Google devolve o dinheiro de compra não confirmada em 3 dias.
  if (c.acknowledgementState === 'ACKNOWLEDGEMENT_STATE_PENDING' && c.subscriptionState === 'SUBSCRIPTION_STATE_ACTIVE') {
    const ack = await google('POST', `/purchases/subscriptions/${encodeURIComponent(item.productId!)}/tokens/${encodeURIComponent(token)}:acknowledge`)
    if (ack.status >= 300) console.error('loja-assinatura: acknowledge', ack.status)
  }

  const vale = VALIDOS.has(c.subscriptionState ?? '')
  const { error } = await db.from('baru_assinaturas_loja').upsert({
    user_id: uid,
    loja: 'google',
    produto: item.productId,
    compra_id: token,
    expira_em: item.expiryTime,
    renova: item.autoRenewingPlan?.autoRenewEnabled ?? false,
    revogada_em: vale ? null : new Date().toISOString(),
    teste: c.testPurchase != null,
    plano_base: item.offerDetails?.basePlanId ?? null,
    laco_id: FAMILIA.has(produto) ? laco : null,
    atualizado_em: new Date().toISOString(),
  })
  if (error) {
    console.error('loja-assinatura: gravar', error.message)
    return jsonResponse({ error: 'erro_interno' }, 500)
  }
  const { data: acesso } = await db.rpc('baru_acesso_de', { p_uid: uid })
  return jsonResponse({ acesso })
}))
