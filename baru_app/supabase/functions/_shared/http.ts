import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4'

const cabecalhos = {
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

/** Origem exata; nunca refletir uma origem arbitrária. O app não manda origem. */
function origemPermitida(origem: string): boolean {
  const configuradas = Deno.env.get('CORS_ALLOWED_ORIGINS') ?? 'https://baru.lhcx.tech,http://localhost:8787'
  return configuradas.split(',').map(valor => valor.trim()).includes(origem)
}

export function jsonResponse(corpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...cabecalhos, 'content-type': 'application/json' },
  })
}

export function comCors(handler: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    const origem = req.headers.get('origin')
    if (origem && !origemPermitida(origem)) return jsonResponse({ error: 'forbidden' }, 403)
    const resposta = req.method === 'OPTIONS' ? new Response('ok', { headers: cabecalhos }) : await handler(req)
    const headers = new Headers(resposta.headers)
    headers.set('Vary', 'Origin')
    if (origem) headers.set('Access-Control-Allow-Origin', origem)
    return new Response(resposta.body, { status: resposta.status, headers })
  }
}

let cliente: SupabaseClient | null = null

/** Cliente service-role: ignora a RLS. Só nas Edge Functions. */
export function servico(): SupabaseClient {
  cliente ??= createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
    auth: { persistSession: false, autoRefreshToken: false },
  })
  return cliente
}

/** Id da pessoa pelo JWT, ou null. */
export async function usuarioDe(req: Request): Promise<string | null> {
  const token = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '')
  if (!token) return null
  const { data, error } = await servico().auth.getUser(token)
  return error ? null : data.user?.id ?? null
}
