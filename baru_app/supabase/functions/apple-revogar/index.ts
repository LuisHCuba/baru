import { comCors, jsonResponse, usuarioDe } from '../_shared/http.ts'

/**
 * Revoga o "Entrar com a Apple" ao apagar a conta (exigência da Apple,
 * diretriz 5.1.1(v)). O app pede de novo o "Entrar com a Apple" na hora de
 * apagar e manda o authorizationCode novo; aqui ele vira refresh token e é
 * revogado em /auth/revoke. Chamada com a sessão ainda viva, logo antes do
 * app apagar o login.
 *
 * Corpo: { code }. Resposta: { revogado: boolean }.
 *
 * Segredos (cópia do Infisical, LHCX_CENTRAL/prod/baru-ios):
 *   APPLE_KEY_ID  ← BARU_SIWA_KEY_ID
 *   APPLE_KEY_P8  ← BARU_SIWA_KEY_P8
 *   APPLE_TEAM_ID ← APPLE_TEAM_ID (raiz)
 */

const CLIENTE = 'tech.lhcx.baru'

const b64url = (b: ArrayBuffer | Uint8Array | string) =>
  btoa(typeof b === 'string' ? b : String.fromCharCode(...new Uint8Array(b instanceof Uint8Array ? b : new Uint8Array(b))))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

/** client_secret do "Entrar com a Apple": JWT ES256 assinado com a chave .p8, vale 5 minutos. */
async function segredoDoCliente(): Promise<string | null> {
  const kid = Deno.env.get('APPLE_KEY_ID')
  const p8 = Deno.env.get('APPLE_KEY_P8')
  const equipe = Deno.env.get('APPLE_TEAM_ID')
  if (!kid || !p8 || !equipe) return null
  const pem = p8.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '')
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  const chave = await crypto.subtle.importKey('pkcs8', der, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'])
  const agora = Math.floor(Date.now() / 1000)
  const cab = b64url(JSON.stringify({ alg: 'ES256', kid }))
  const corpo = b64url(JSON.stringify({ iss: equipe, iat: agora, exp: agora + 300, aud: 'https://appleid.apple.com', sub: CLIENTE }))
  const assinatura = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, chave, new TextEncoder().encode(`${cab}.${corpo}`))
  return `${cab}.${corpo}.${b64url(assinatura)}`
}

Deno.serve(comCors(async (req: Request) => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405)
  const uid = await usuarioDe(req)
  if (!uid) return jsonResponse({ error: 'unauthorized' }, 401)
  let code = ''
  try {
    const corpo = await req.json()
    code = typeof corpo?.code === 'string' ? corpo.code : ''
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  if (!code || code.length > 2000) return jsonResponse({ error: 'parametros_invalidos' }, 400)

  const segredo = await segredoDoCliente()
  if (!segredo) {
    console.error('apple-revogar: chaves da Apple ausentes')
    return jsonResponse({ revogado: false, error: 'sem_chave' }, 503)
  }
  const form = (d: Record<string, string>) => new URLSearchParams(d).toString()
  const cabecalho = { 'content-type': 'application/x-www-form-urlencoded' }
  const t = await fetch('https://appleid.apple.com/auth/token', {
    method: 'POST', headers: cabecalho,
    body: form({ client_id: CLIENTE, client_secret: segredo, code, grant_type: 'authorization_code' }),
  })
  if (!t.ok) {
    console.error('apple-revogar: token', t.status, await t.text().catch(() => ''))
    return jsonResponse({ revogado: false, error: 'codigo_recusado' }, 400)
  }
  const j = (await t.json()) as { refresh_token?: string; access_token?: string }
  const token = j.refresh_token ?? j.access_token
  if (!token) return jsonResponse({ revogado: false }, 502)
  const r = await fetch('https://appleid.apple.com/auth/revoke', {
    method: 'POST', headers: cabecalho,
    body: form({ client_id: CLIENTE, client_secret: segredo, token, token_type_hint: j.refresh_token ? 'refresh_token' : 'access_token' }),
  })
  if (!r.ok) console.error('apple-revogar: revoke', r.status)
  return jsonResponse({ revogado: r.ok }, r.ok ? 200 : 502)
}))
