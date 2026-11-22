import { jsonResponse, servico } from '../_shared/http.ts'

/**
 * Dois usos:
 * 1. { crianca_id }: push silencioso para o iPhone da criança quando o responsável muda uma regra
 * (pausa, tempo extra, horários, meta). O iPhone acorda em segundo plano, busca
 * as regras com a chave do aparelho e aplica — sem a criança abrir o Baru.
 *
 * 2. { evento_id }: aviso visível (SOS, chegou, saiu, meta) para os celulares
 *    dos responsáveis (iPhone pela Apple, Android pelo Firebase) — trigger baru_familia_avisa_responsavel. Só eventos de
 *    até 90 s e uma vez cada (push_em).
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
 *   GOOGLE_PLAY_SERVICE_ACCOUNT_JSON  conta de serviço com papel de admin do FCM (Android)
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


// ---------------------------------------------------------------- Android (FCM)

let tokenGoogle: { valor: string; ate: number } | null = null

/** Token OAuth da conta de serviço (mesma da Play, com papel de admin do FCM). */
async function acessoFcm(): Promise<{ token: string; projeto: string } | null> {
  const sa = JSON.parse(Deno.env.get('GOOGLE_PLAY_SERVICE_ACCOUNT_JSON') ?? '{}')
  if (!sa.client_email || !sa.private_key || !sa.project_id) return null
  if (tokenGoogle && tokenGoogle.ate > Date.now() + 60_000) return { token: tokenGoogle.valor, projeto: sa.project_id }
  const agora = Math.floor(Date.now() / 1000)
  const cab = b64url(enc.encode(JSON.stringify({ alg: 'RS256', typ: 'JWT' })))
  const corpo = b64url(enc.encode(JSON.stringify({
    iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token', iat: agora, exp: agora + 3000,
  })))
  const der = Uint8Array.from(atob(String(sa.private_key).replace(/-----[^-]+-----/g, '').replace(/\s+/g, '')), (c) => c.charCodeAt(0))
  const chave = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'])
  const assinatura = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', chave, enc.encode(`${cab}.${corpo}`))
  const r = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${cab}.${corpo}.${b64url(assinatura)}`,
  })
  const j = await r.json().catch(() => ({}))
  if (!r.ok || !j.access_token) { console.error('token FCM', r.status); return null }
  tokenGoogle = { valor: j.access_token, ate: Date.now() + (j.expires_in ?? 3000) * 1000 }
  return { token: tokenGoogle.valor, projeto: sa.project_id }
}

/**
 * Só dados, prioridade alta: o próprio Baru monta o aviso no idioma do
 * responsável e, no SOS, toca o alarme insistente (canal próprio).
 */
async function enviaAndroid(acesso: { token: string; projeto: string }, tokenFcm: string, dados: Record<string, string>) {
  return await fetch(`https://fcm.googleapis.com/v1/projects/${acesso.projeto}/messages:send`, {
    method: 'POST',
    headers: { authorization: `Bearer ${acesso.token}`, 'content-type': 'application/json' },
    body: JSON.stringify({ message: { token: tokenFcm, data: dados, android: { priority: 'HIGH', ttl: '3600s' } } }),
  })
}

/** Textos dos avisos ao responsável, no idioma do celular dele. */
const AVISOS: Record<string, Record<string, [string, string]>> = {
  pt: {
    sos: ['SOS de {c}', '{c} pediu ajuda. Toque para ver onde está.'],
    chegou: ['{c} chegou', '{c} chegou em {l}.'],
    saiu_de: ['{c} saiu', '{c} saiu de {l}.'],
    meta_75: ['Tempo de tela', '{c} usou 75% da meta de hoje.'],
    meta_batida: ['Tempo de tela', '{c} chegou à meta de hoje.'],
    meta_passou: ['Tempo de tela', '{c} passou bastante da meta de hoje.'],
    autorizacao_revogada: ['Controle desligado', '{c} desligou a permissão de tempo de tela no celular.'],
  },
  en: {
    sos: ['SOS from {c}', '{c} asked for help. Tap to see where.'],
    chegou: ['{c} arrived', '{c} arrived at {l}.'],
    saiu_de: ['{c} left', '{c} left {l}.'],
    meta_75: ['Screen time', '{c} used 75% of today\'s goal.'],
    meta_batida: ['Screen time', '{c} reached today\'s goal.'],
    meta_passou: ['Screen time', '{c} went well over today\'s goal.'],
    autorizacao_revogada: ['Controls off', '{c} turned off screen time permission on the phone.'],
  },
  es: {
    sos: ['SOS de {c}', '{c} pidió ayuda. Toca para ver dónde está.'],
    chegou: ['{c} llegó', '{c} llegó a {l}.'],
    saiu_de: ['{c} salió', '{c} salió de {l}.'],
    meta_75: ['Tiempo de pantalla', '{c} usó el 75% de la meta de hoy.'],
    meta_batida: ['Tiempo de pantalla', '{c} llegó a la meta de hoy.'],
    meta_passou: ['Tiempo de pantalla', '{c} pasó bastante la meta de hoy.'],
    autorizacao_revogada: ['Control apagado', '{c} desactivó el permiso de tiempo de pantalla.'],
  },
  zh: {
    sos: ['{c} 的求助', '{c} 发出了求助。点按查看位置。'],
    chegou: ['{c} 已到达', '{c} 已到达 {l}。'],
    saiu_de: ['{c} 已离开', '{c} 已离开 {l}。'],
    meta_75: ['屏幕时间', '{c} 已用掉今天目标的 75%。'],
    meta_batida: ['屏幕时间', '{c} 已达到今天的目标。'],
    meta_passou: ['屏幕时间', '{c} 已远超今天的目标。'],
    autorizacao_revogada: ['控制已关闭', '{c} 关闭了屏幕时间权限。'],
  },
}

async function enviaApple(jwt: string, token: string, ambiente: string | null, corpo: unknown, tipo: 'background' | 'alert') {
  const host = ambiente === 'sandbox' ? 'api.sandbox.push.apple.com' : 'api.push.apple.com'
  return await fetch(`https://${host}/3/device/${token}`, {
    method: 'POST',
    headers: {
      authorization: `bearer ${jwt}`,
      'apns-topic': Deno.env.get('APNS_TOPIC') ?? 'tech.lhcx.baru',
      'apns-push-type': tipo,
      'apns-priority': tipo === 'alert' ? '10' : '5',
      'apns-expiration': String(Math.floor(Date.now() / 1000) + 3600),
    },
    body: JSON.stringify(corpo),
  })
}

/** Aviso visível para os iPhones dos responsáveis (SOS, chegou, saiu, meta). */
async function avisaResponsaveis(eventoId: number) {
  const db = servico()
  const { data: ev } = await db.from('baru_familia_eventos')
    .select('id, familia_id, crianca_id, tipo, em, detalhe, push_em').eq('id', eventoId).maybeSingle()
  if (!ev || ev.push_em || Date.now() - new Date(ev.em).getTime() > 90_000) return jsonResponse({ enviados: 0, motivo: 'evento velho ou já avisado' })
  await db.from('baru_familia_eventos').update({ push_em: new Date().toISOString() }).eq('id', ev.id)
  const { data: crianca } = await db.from('baru_familia_membros').select('apelido')
    .eq('familia_id', ev.familia_id).eq('user_id', ev.crianca_id).maybeSingle()
  const { data: resp } = await db.from('baru_familia_membros').select('user_id')
    .eq('familia_id', ev.familia_id).eq('papel', 'responsavel').is('saiu_em', null)
  const ids = (resp ?? []).map((r: { user_id: string }) => r.user_id)
  if (!ids.length) return jsonResponse({ enviados: 0 })
  const { data: todos } = await db.from('baru_familia_resp_aparelhos')
    .select('chave_hash, push_token, push_ambiente, idioma, plataforma').in('user_id', ids).not('push_token', 'is', null)
  let enviados = 0

  // Android: Firebase, só dados.
  const androids = (todos ?? []).filter((a: { plataforma: string }) => a.plataforma === 'android')
  const fcm = androids.length ? await acessoFcm() : null
  for (const a of fcm ? androids : []) {
    const r = await enviaAndroid(fcm!, a.push_token, {
      baru: 'aviso', id: String(ev.id), tipo: ev.tipo, crianca: crianca?.apelido ?? '—', lugar: String(ev.detalhe?.lugar ?? ''),
    })
    if (r.ok) enviados++
    else {
      const motivo = await r.text().catch(() => '')
      if (r.status === 404 || motivo.includes('UNREGISTERED')) {
        await db.from('baru_familia_resp_aparelhos').update({ push_token: null }).eq('chave_hash', a.chave_hash)
      } else console.error('FCM aviso', r.status, motivo)
    }
  }

  // iPhone: APNs.
  const aparelhos = (todos ?? []).filter((a: { plataforma: string }) => a.plataforma === 'ios')
  const jwt = aparelhos.length ? await jwtDaApple() : null
  for (const a of jwt ? aparelhos : []) {
    const t = (AVISOS[a.idioma] ?? AVISOS.pt)[ev.tipo]
    if (!t) continue
    const troca = (s: string) => s.replaceAll('{c}', crianca?.apelido ?? '—').replaceAll('{l}', ev.detalhe?.lugar ?? '')
    const r = await enviaApple(jwt!, a.push_token, a.push_ambiente, {
      aps: { alert: { title: troca(t[0]), body: troca(t[1]) }, sound: ev.tipo === 'sos' ? 'default' : undefined,
             'interruption-level': ev.tipo === 'sos' ? 'time-sensitive' : 'active', 'thread-id': `familia-${ev.crianca_id}` },
      baru: 'aviso', tipo: ev.tipo, crianca_id: ev.crianca_id,
    }, 'alert')
    if (r.ok) enviados++
    else {
      const motivo = await r.text().catch(() => '')
      if (r.status === 410 || motivo.includes('BadDeviceToken') || motivo.includes('Unregistered')) {
        await db.from('baru_familia_resp_aparelhos').update({ push_token: null }).eq('chave_hash', a.chave_hash)
      } else console.error('APNs aviso', r.status, motivo)
    }
  }
  return jsonResponse({ enviados })
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method' }, 405)
  const corpoReq = await req.json().catch(() => ({}))
  if (Number.isInteger(corpoReq.evento_id)) return await avisaResponsaveis(corpoReq.evento_id)
  const { crianca_id } = corpoReq
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

  let enviados = 0
  for (const a of aparelhos ?? []) {
    const r = await enviaApple(jwt, a.push_token, a.push_ambiente, { aps: { 'content-available': 1 }, baru: 'regras' }, 'background')
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
