// Cliente mínimo da API do Asaas (assinaturas do Baru).
//
// Mesma conta Asaas do Ecoin e da Academy; o Baru tem webhook próprio
// (`asaas-webhook`). A chave nunca sai daqui nem entra em log.
//
// Segredos (Supabase → Edge Functions → Secrets):
//   ASAAS_API_KEY        — chave da API (produção ou sandbox).
//   ASAAS_API_URL        — opcional; padrão https://api.asaas.com/v3
//                          (sandbox: https://api-sandbox.asaas.com/v3).
//   ASAAS_WEBHOOK_TOKEN  — o token cadastrado no webhook do Asaas, que chega
//                          no header `asaas-access-token`.

export type IdPlano = 'monthly' | 'annual'

export const PLANOS: Record<IdPlano, { nome: string; centavos: number; ciclo: 'MONTHLY' | 'YEARLY' }> = {
  monthly: { nome: 'Mensal', centavos: 3490, ciclo: 'MONTHLY' },
  annual: { nome: 'Anual', centavos: 17990, ciclo: 'YEARLY' },
}

export class ErroAsaas extends Error {
  status: number
  constructor(mensagem: string, status: number) {
    super(mensagem)
    this.status = status
  }
}

export function asaasConfigurado(): boolean {
  return Boolean(Deno.env.get('ASAAS_API_KEY'))
}

export async function asaas<T>(metodo: string, caminho: string, corpo?: unknown): Promise<T> {
  const chave = Deno.env.get('ASAAS_API_KEY')
  if (!chave) throw new ErroAsaas('ASAAS_API_KEY ausente', 503)
  const base = (Deno.env.get('ASAAS_API_URL') || 'https://api.asaas.com/v3').replace(/\/+$/, '')
  const resposta = await fetch(`${base}${caminho}`, {
    method: metodo,
    headers: { access_token: chave, 'Content-Type': 'application/json', 'User-Agent': 'baru' },
    body: corpo === undefined ? undefined : JSON.stringify(corpo),
  })
  const texto = await resposta.text()
  if (!resposta.ok) {
    let detalhe = texto
    try {
      const json = JSON.parse(texto) as { errors?: { description?: string }[] }
      detalhe = json.errors?.map(e => e.description).filter(Boolean).join('; ') || texto
    } catch { /* texto puro */ }
    throw new ErroAsaas(detalhe.slice(0, 400), resposta.status)
  }
  return (texto ? JSON.parse(texto) : {}) as T
}

/** AAAA-MM-DD no fuso de São Paulo. */
export function hojeEmSaoPaulo(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' }).format(new Date())
}

/** Por enquanto o Baru aceita só CPF (pessoa física). */
export function cpfValido(valor: string): boolean {
  return valor.replace(/\D/g, '').length === 11 && documentoValido(valor)
}

export function documentoValido(valor: string): boolean {
  const d = valor.replace(/\D/g, '')
  if (d.length === 11) {
    if (/^(\d)\1{10}$/.test(d)) return false
    for (const n of [9, 10]) {
      let soma = 0
      for (let i = 0; i < n; i++) soma += Number(d[i]) * (n + 1 - i)
      if (((soma * 10) % 11) % 10 !== Number(d[n])) return false
    }
    return true
  }
  if (d.length === 14) {
    if (/^(\d)\1{13}$/.test(d)) return false
    const calc = (n: number) => {
      const pesos = n === 12 ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2] : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
      const r = pesos.reduce((acc, p, i) => acc + Number(d[i]) * p, 0) % 11
      return r < 2 ? 0 : 11 - r
    }
    return calc(12) === Number(d[12]) && calc(13) === Number(d[13])
  }
  return false
}
