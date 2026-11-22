import { jsonResponse, servico } from '../_shared/http.ts'

/**
 * Avisos da Google Play sobre assinaturas (Real-time developer notifications),
 * entregues pelo Pub/Sub (assinatura push para esta URL).
 *
 * Renovou, cancelou, expirou, foi reembolsada: a Google manda só o
 * purchaseToken. Esta função NÃO confia no conteúdo do aviso: consulta a
 * assinatura na API da Google e grava o estado de lá. Um aviso falso só faz
 * a função conferir de novo, sem mudar nada que a Google não confirme.
 *
 * Segredo: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (cópia sincronizada do Infisical).
 */

const PACOTE = 'tech.lhcx.baru'
const PRODUTOS = new Set(['baru_assinatura'])
const API = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACOTE}`
const VALIDOS = new Set(['SUBSCRIPTION_STATE_ACTIVE', 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD', 'SUBSCRIPTION_STATE_CANCELED'])

const b64url = (b: ArrayBuffer | Uint8Array | string) =>
  btoa(typeof b === 'string' ? b : String.fromCharCode(...new Uint8Array(b instanceof Uint8Array ? b : new Uint8Array(b))))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

let tokenGoogle: { valor: string; ate: number } | null = null

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

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405)

  let token = ''
  try {
    const envelope = await req.json()
    const dados = envelope?.message?.data
    if (typeof dados !== 'string') return jsonResponse({ ok: true, ignorado: 'sem dados' })
    const aviso = JSON.parse(atob(dados))
    if (aviso?.packageName !== PACOTE) return jsonResponse({ ok: true, ignorado: 'outro app' })
    if (aviso?.testNotification) return jsonResponse({ ok: true, teste: true })
    token = aviso?.subscriptionNotification?.purchaseToken ?? ''
    if (!token || token.length > 4000) return jsonResponse({ ok: true, ignorado: 'sem assinatura' })
  } catch {
    // Mensagem malformada: 200 para o Pub/Sub não reenviar sem fim.
    return jsonResponse({ ok: true, ignorado: 'malformado' })
  }

  try {
    const r = await fetch(`${API}/purchases/subscriptionsv2/tokens/${encodeURIComponent(token)}`, {
      headers: { authorization: `Bearer ${await acessoGoogle()}` },
    })
    if (r.status === 404 || r.status === 410) return jsonResponse({ ok: true, ignorado: 'compra não existe' })
    if (!r.ok) throw new Error(`google ${r.status}`)
    const c = await r.json() as {
      subscriptionState?: string
      testPurchase?: unknown
      externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string }
      lineItems?: { productId?: string; expiryTime?: string; autoRenewingPlan?: { autoRenewEnabled?: boolean } }[]
    }
    const item = (c.lineItems ?? []).find((l) => l.productId && PRODUTOS.has(l.productId))
    if (!item?.expiryTime) return jsonResponse({ ok: true, ignorado: 'outro produto' })

    const db = servico()
    const { data: atual } = await db.from('baru_assinaturas_loja').select('user_id').eq('compra_id', token).maybeSingle()
    const dono = atual?.user_id ?? c.externalAccountIdentifiers?.obfuscatedExternalAccountId
    if (!dono) return jsonResponse({ ok: true, ignorado: 'sem conta' })
    const vale = VALIDOS.has(c.subscriptionState ?? '')
    const { error } = await db.from('baru_assinaturas_loja').upsert({
      user_id: dono,
      loja: 'google',
      produto: item.productId,
      compra_id: token,
      expira_em: item.expiryTime,
      renova: item.autoRenewingPlan?.autoRenewEnabled ?? false,
      revogada_em: vale ? null : new Date().toISOString(),
      teste: c.testPurchase != null,
      atualizado_em: new Date().toISOString(),
    })
    if (error) throw new Error(error.message)
    return jsonResponse({ ok: true })
  } catch (e) {
    // Falha nossa: 500 e o Pub/Sub reenvia.
    console.error('loja-notificacoes:', e instanceof Error ? e.message : String(e))
    return jsonResponse({ error: 'erro_interno' }, 500)
  }
})
