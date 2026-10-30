import { jsonResponse, servico } from '../_shared/http.ts'
import { asaas } from '../_shared/asaas.ts'

/**
 * Webhook do Asaas para as assinaturas do Baru.
 *
 * Cadastro no painel do Asaas (Integrações → Webhooks):
 *   URL:   https://<projeto>.supabase.co/functions/v1/asaas-webhook
 *   Token: o mesmo valor do segredo ASAAS_WEBHOOK_TOKEN
 *   Eventos: cobranças e assinaturas.
 *
 * A conta Asaas também cobra o Ecoin e a Academy: evento que não é de uma
 * assinatura do Baru é só confirmado, sem gravar nada.
 *
 * Responde 200 rápido em tudo que não é falha nossa; em falha, 500, e o Asaas
 * reenvia (o registro em `baru_asaas_eventos` é apagado para o reenvio valer).
 */

interface Cobranca {
  id: string
  status?: string
  subscription?: string | null
  dueDate?: string
}
interface EventoAsaas {
  id?: string
  event?: string
  payment?: Cobranca
  subscription?: { id: string; status?: string; deleted?: boolean }
}

const PAGO = new Set(['PAYMENT_CONFIRMED', 'PAYMENT_RECEIVED'])
const DESFEITO = new Set(['PAYMENT_REFUNDED', 'PAYMENT_CHARGEBACK_REQUESTED', 'PAYMENT_RECEIVED_IN_CASH_UNDONE'])
const ASSINATURA_ENCERRADA = new Set(['SUBSCRIPTION_DELETED', 'SUBSCRIPTION_INACTIVATED'])

function iguais(a: string, b: string): boolean {
  if (a.length !== b.length) return false
  let diferenca = 0
  for (let i = 0; i < a.length; i++) diferenca |= a.charCodeAt(i) ^ b.charCodeAt(i)
  return diferenca === 0
}

Deno.serve(async req => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405)
  const esperado = Deno.env.get('ASAAS_WEBHOOK_TOKEN') ?? ''
  const recebido = req.headers.get('asaas-access-token') ?? ''
  if (!esperado || !iguais(recebido, esperado)) return jsonResponse({ error: 'unauthorized' }, 401)

  let evento: EventoAsaas
  try {
    evento = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  if (!evento.id || !evento.event) return jsonResponse({ ok: true, ignorado: true })

  const assinaturaId = evento.payment?.subscription ?? evento.subscription?.id ?? null
  if (!assinaturaId) return jsonResponse({ ok: true, ignorado: true })

  const supa = servico()
  const { data: dona } = await supa.from('baru_assinaturas')
    .select('user_id, status, pago_ate')
    .eq('asaas_assinatura_id', assinaturaId)
    .maybeSingle()
  if (!dona) return jsonResponse({ ok: true, ignorado: true })

  const { data: inserido } = await supa.from('baru_asaas_eventos')
    .upsert({ id: evento.id, tipo: evento.event, payload: evento }, { onConflict: 'id', ignoreDuplicates: true })
    .select('id')
  if (!inserido?.length) return jsonResponse({ ok: true, duplicado: true })

  try {
    const mudanca = await aplicar(evento, assinaturaId, dona as { status: string; pago_ate: string | null })
    if (mudanca) {
      const { error } = await supa.from('baru_assinaturas')
        .update({ ...mudanca, atualizado_em: new Date().toISOString() })
        .eq('asaas_assinatura_id', assinaturaId)
      if (error) throw error
    }
    await supa.from('baru_asaas_eventos').update({ processado_em: new Date().toISOString() }).eq('id', evento.id)
    return jsonResponse({ ok: true })
  } catch (falha) {
    console.error('asaas-webhook:', falha instanceof Error ? falha.message : String(falha))
    await supa.from('baru_asaas_eventos').delete().eq('id', evento.id)
    return jsonResponse({ error: 'falha_ao_processar' }, 500)
  }
})

async function aplicar(
  evento: EventoAsaas,
  assinaturaId: string,
  atual: { status: string; pago_ate: string | null },
): Promise<Record<string, unknown> | null> {
  const tipo = evento.event!

  if (PAGO.has(tipo)) {
    // O período pago vai até o próximo vencimento da assinatura.
    const assinatura = await asaas<{ nextDueDate?: string; status?: string }>(
      'GET', `/subscriptions/${encodeURIComponent(assinaturaId)}`,
    )
    const ate = assinatura.nextDueDate ?? null
    const pagoAte = [ate, atual.pago_ate].filter(Boolean).sort().at(-1) ?? null
    return {
      status: atual.status === 'cancelada' ? 'cancelada' : 'ativa',
      pago_ate: pagoAte,
      link_pagamento: null,
      cobranca_id: null,
    }
  }

  if (tipo === 'PAYMENT_OVERDUE') {
    // Fora de ordem: um vencido atrasado não rebaixa quem já pagou adiante.
    const vencimento = evento.payment?.dueDate ?? ''
    if (atual.pago_ate && vencimento && atual.pago_ate > vencimento) return null
    if (atual.status === 'cancelada') return null
    return { status: 'atrasada' }
  }

  if (DESFEITO.has(tipo)) return { status: 'cancelada', pago_ate: null, link_pagamento: null }

  if (ASSINATURA_ENCERRADA.has(tipo)) {
    return { status: 'cancelada', link_pagamento: null, cancelada_em: new Date().toISOString() }
  }

  return null
}
