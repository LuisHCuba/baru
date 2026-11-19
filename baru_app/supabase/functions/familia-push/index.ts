import { jsonResponse, servico } from '../_shared/http.ts'

/**
 * Push silencioso para o iPhone da criança quando o responsável muda uma regra
 * (pausa, tempo extra, horários, meta). O iPhone acorda em segundo plano, busca
 * as regras com a chave do aparelho e aplica — sem a criança abrir o Baru.
 *
 * Quem chama: o trigger baru_familia_avisa_push (pg_net), logo depois de uma
 * regra mudar. Sem segredo compartilhado: a função só envia se as regras da
 * criança mudaram no último minuto e meio. O pior que alguém de fora consegue
 * é um push silencioso a mais, que só faz o iPhone reler as próprias regras.
 *
 * Segredos da função (fonte: Infisical LHCX_CENTRAL/prod; o Supabase recebe
 * por sincronização do Infisical — nunca editar direto no painel):
 *   APNS_KEY_P8      conteúdo do AuthKey_XXXX.p8 (chave de push da Apple)
 *   APNS_KEY_ID      Key ID da chave (10 caracteres)
 * Opcionais: APNS_TEAM_ID (padrão PHV3N8AFK4), APNS_TOPIC (padrão tech.lhcx.baru).
 *
 * Sem os segredos da Apple, responde 200 sem enviar (não quebra o banco).
 */

const enc = new TextEncoder()
const b64url = (b: ArrayBuffer | Uint8Array) =>
  btoa(String.fromCharCode(...new Uint8Array(b instanceof Uint8Array ? b : new Uint8Array(b))))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

let jwtCache: { token: string; em: number } | null = null

/** JWT ES256 da Apple, reaproveitado por 50 minutos (a Apple aceita até 1 h). */
async function jwtDaApple(): Promise<string | null> {
  const p8 = Deno.env.get('APNS_KEY_P8')
  const kid = Deno.env.get('APNS_KEY_ID')
  const iss = Deno.env.get('APNS_TEAM_ID') ?? 'PHV3N8AFK4'
  if (!p8 || !kid || !iss) return null
  const agora = Math.floor(Date.now() / 1000)
  if (jwtCache && agora - jwtCache.em < 50 * 60) return jwtCache.token
  const der = Uint8Array.from(
    atob(p8.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '')),
    c => c.charCodeAt(0),
  )
  const chave = await crypto.subtle.importKey('pkcs8', der, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign'])
  const cab = b64url(enc.encode(JSON.stringify({ alg: 'ES256', kid })))
  const corpo = b64url(enc.encode(JSON.stringify({ iss, iat: agora })))
  const assinatura = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, chave, enc.encode(`${cab}.${corpo}`))
  const token = `${cab}.${corpo}.${b64url(assinatura)}`
  jwtCache = { token, em: agora }
  return token
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method' }, 405)
  const { crianca_id } = await req.json().catch(() => ({}))
  if (typeof crianca_id !== 'string' || !/^[0-9a-f-]{36}$/i.test(crianca_id)) return jsonResponse({ error: 'crianca_id' }, 400)

  // Só logo depois de uma mudança de regra.
  const { data: regra } = await servico()
    .from('baru_familia_regras').select('atualizado_em').eq('crianca_id', crianca_id).maybeSingle()
  if (!regra || Date.now() - new Date(regra.atualizado_em).getTime() > 90_000) {
    return jsonResponse({ enviados: 0, motivo: 'sem mudança recente' })
  }

  const jwt = await jwtDaApple()
  if (!jwt) return jsonResponse({ enviados: 0, motivo: 'sem chave da Apple' })

  const { data: aparelhos, error } = await servico()
    .from('baru_familia_aparelhos')
    .select('chave_hash, push_token, push_ambiente')
    .eq('crianca_id', crianca_id)
    .eq('plataforma', 'ios')
    .not('push_token', 'is', null)
  if (error) return jsonResponse({ error: error.message }, 500)

  const topico = Deno.env.get('APNS_TOPIC') ?? 'tech.lhcx.baru'
  let enviados = 0
  for (const a of aparelhos ?? []) {
    const host = a.push_ambiente === 'sandbox' ? 'api.sandbox.push.apple.com' : 'api.push.apple.com'
    const r = await fetch(`https://${host}/3/device/${a.push_token}`, {
      method: 'POST',
      headers: {
        authorization: `bearer ${jwt}`,
        'apns-topic': topico,
        'apns-push-type': 'background',
        'apns-priority': '5',
        'apns-expiration': String(Math.floor(Date.now() / 1000) + 3600),
      },
      body: JSON.stringify({ aps: { 'content-available': 1 }, baru: 'regras' }),
    })
    if (r.ok) enviados++
    else {
      const motivo = await r.text().catch(() => '')
      // Token que a Apple diz não valer mais sai da lista.
      if (r.status === 410 || motivo.includes('BadDeviceToken') || motivo.includes('Unregistered')) {
        await servico().from('baru_familia_aparelhos').update({ push_token: null }).eq('chave_hash', a.chave_hash)
      } else {
        console.error('APNs', r.status, motivo)
      }
    }
  }
  return jsonResponse({ enviados })
})
