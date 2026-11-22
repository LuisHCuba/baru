import { comCors, jsonResponse, servico, usuarioDe } from '../_shared/http.ts'

/**
 * Assinatura comprada dentro do app (loja do celular).
 *
 *   { loja: 'google', token, produto }  → confere com a Google Play, confirma
 *                                         (acknowledge) e libera o acesso.
 *
 * A compra só vale para a conta que comprou: o app manda o id da conta como
 * obfuscatedAccountId, e a Google devolve o mesmo valor na conferência.
 *
 * Segredo: GOOGLE_PLAY_SERVICE_ACCOUNT_JSON (conta de serviço com acesso à API
 * da Google Play), nos segredos das Edge Functions. Cópia do Infisical.
 */

const PACOTE = 'tech.lhcx.baru'
const PRODUTOS = new Set(['baru_assinatura'])
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
  const token = typeof corpo.token === 'string' ? corpo.token : ''
  const produto = typeof corpo.produto === 'string' ? corpo.produto : ''
  if (corpo.loja !== 'google' || !token || token.length > 4000 || !PRODUTOS.has(produto)) {
    return jsonResponse({ error: 'parametros_invalidos' }, 400)
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
    lineItems?: { productId?: string; expiryTime?: string; autoRenewingPlan?: { autoRenewEnabled?: boolean } }[]
  }
  const item = (c.lineItems ?? []).find((l) => l.productId && PRODUTOS.has(l.productId))
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
    atualizado_em: new Date().toISOString(),
  })
  if (error) {
    console.error('loja-assinatura: gravar', error.message)
    return jsonResponse({ error: 'erro_interno' }, 500)
  }
  const { data: acesso } = await db.rpc('baru_acesso_de', { p_uid: uid })
  return jsonResponse({ acesso })
}))
