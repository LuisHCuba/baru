import { comCors, jsonResponse, servico, usuarioDe } from '../_shared/http.ts'
import { asaas, asaasConfigurado, cpfValido, ErroAsaas, hojeEmSaoPaulo, IdPlano, PLANOS } from '../_shared/asaas.ts'

/**
 * Assinatura do Baru no Asaas, sempre da própria pessoa (id vem do JWT).
 *
 * **Comprar não exige conta.** Sem login, só `assinar` é aceito, com o e-mail
 * no corpo: a assinatura vai para a conta desse e-mail, que é criada se ainda
 * não existir. A pessoa entra no app depois, com Google ou com o mesmo e-mail
 * ("esqueci a senha" cria a senha). Sem login nunca se mexe numa assinatura
 * viva: trocar plano, forma ou cancelar continua exigindo entrar.
 *
 *   { acao: 'estado' }     → acesso, assinatura e se já há cadastro no Asaas
 *   { acao: 'assinar', plano, forma, aceite, termosVersao, documento?, nome? }
 *                          → cria (ou troca) a assinatura e devolve a cobrança a pagar
 *   { acao: 'cobranca' }   → a cobrança em aberto (para a página sobreviver a recarregar)
 *   { acao: 'cancelar' }   → cancela no Asaas; o acesso vale até pago_ate
 *
 * Quem libera é o webhook (`asaas-webhook`), quando o pagamento é confirmado.
 * Esta função só cria a cobrança. O CPF vai direto para o cadastro do cliente
 * no Asaas e não é guardado no Baru.
 */

type Forma = 'PIX' | 'BOLETO' | 'CREDIT_CARD'
const FORMAS = new Set<Forma>(['PIX', 'BOLETO', 'CREDIT_CARD'])

interface Assinatura {
  user_id: string
  plano: IdPlano
  status: string
  asaas_cliente_id: string | null
  asaas_assinatura_id: string | null
  valor_centavos: number | null
  link_pagamento: string | null
  pago_ate: string | null
  cancelada_em: string | null
  forma_pagamento: Forma | null
  cobranca_id: string | null
}

const COLUNAS =
  'user_id, plano, status, asaas_cliente_id, asaas_assinatura_id, valor_centavos, link_pagamento, pago_ate, cancelada_em, forma_pagamento, cobranca_id'

interface CobrancaAsaas {
  id: string
  status?: string
  dueDate?: string
  value?: number
  invoiceUrl?: string
  bankSlipUrl?: string | null
  billingType?: string
}

interface Pagamento {
  id: string
  forma: Forma
  valorCentavos: number | null
  vencimento: string | null
  linkAsaas: string | null
  pix?: { imagem: string; copiaECola: string; expiraEm: string | null }
  boleto?: { linhaDigitavel: string; pdf: string | null }
}

Deno.serve(comCors(async req => {
  if (req.method !== 'POST') return jsonResponse({ error: 'method_not_allowed' }, 405)
  let corpo: Record<string, unknown>
  try {
    corpo = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const logado = await usuarioDe(req)
  const semLogin = !logado
  let usuarioId = logado
  let contaNova = false
  if (!usuarioId) {
    if (corpo.acao !== 'assinar') return jsonResponse({ error: 'unauthorized' }, 401)
    if (!asaasConfigurado()) {
      return jsonResponse({ error: 'pagamento_indisponivel', message: 'O pagamento ainda não está disponível. Tente mais tarde.' }, 503)
    }
    // Tudo conferido antes de tocar em conta: um CPF digitado errado não
    // pode deixar para trás uma conta criada à toa.
    const invalido = validaCompraSemLogin(corpo)
    if (invalido) return invalido
    const conta = await contaDoEmail(corpo.email)
    if ('erro' in conta) return conta.erro
    usuarioId = conta.id
    contaNova = conta.nova
  }

  const { data: linha, error } = await servico().from('baru_assinaturas').select(COLUNAS).eq('user_id', usuarioId).maybeSingle()
  if (error) {
    console.error('baru_assinaturas:', error.message)
    return jsonResponse({ error: 'assinatura_indisponivel' }, 503)
  }
  const atual = linha as Assinatura | null
  if (semLogin && viva(atual)) {
    return jsonResponse({
      error: 'ja_assina',
      message: 'Este e-mail já tem uma assinatura. Entre na sua conta para trocar o plano ou a forma de pagamento.',
    }, 409)
  }

  if (corpo.acao === 'estado') return jsonResponse(estado(atual))

  if (!asaasConfigurado()) {
    return jsonResponse({ error: 'pagamento_indisponivel', message: 'O pagamento ainda não está disponível. Tente mais tarde.' }, 503)
  }

  try {
    if (corpo.acao === 'cobranca') return jsonResponse({ pagamento: await cobrancaEmAberto(atual) })
    if (corpo.acao === 'cancelar') return await cancelar(atual, usuarioId)
    if (corpo.acao === 'assinar') return await assinar(atual, usuarioId, corpo, semLogin ? { contaNova } : undefined)
    return jsonResponse({ error: 'parametros_invalidos' }, 400)
  } catch (falha) {
    const mensagem = falha instanceof Error ? falha.message : String(falha)
    console.error('asaas-assinatura:', mensagem)
    if (falha instanceof ErroAsaas && falha.status >= 400 && falha.status < 500) {
      return jsonResponse({ error: 'asaas_recusou', message: `O meio de pagamento recusou: ${mensagem}` }, 422)
    }
    return jsonResponse({ error: 'asaas_indisponivel', message: 'O meio de pagamento não respondeu. Tente de novo em instantes.' }, 502)
  }
}))

function viva(a: Assinatura | null): boolean {
  return Boolean(a?.asaas_assinatura_id && ['pendente', 'ativa', 'atrasada'].includes(a.status))
}

function estado(atual: Assinatura | null) {
  return {
    assinatura: atual
      ? {
          plano: atual.plano,
          status: atual.status,
          pagoAte: atual.pago_ate,
          forma: atual.forma_pagamento,
          valorCentavos: atual.valor_centavos,
        }
      : null,
    temCadastro: Boolean(atual?.asaas_cliente_id),
    pagamentoDisponivel: asaasConfigurado(),
  }
}

/** Fim do teste (AAAA-MM-DD em São Paulo), se a cobrança já estiver ligada. */
async function fimDoTeste(usuarioId: string): Promise<string | null> {
  const supa = servico()
  const [{ data: cobranca }, { data: usuario }] = await Promise.all([
    supa.from('baru_cobranca').select('ligada_em').eq('id', 1).maybeSingle(),
    supa.auth.admin.getUserById(usuarioId),
  ])
  const ligada = (cobranca as { ligada_em?: string | null } | null)?.ligada_em
  const criado = usuario?.user?.created_at
  if (!ligada || !criado) return null
  const inicio = Math.max(Date.parse(ligada), Date.parse(criado))
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Sao_Paulo' }).format(new Date(inicio + 7 * 86400000))
}

function validaCompraSemLogin(corpo: Record<string, unknown>): Response | null {
  if (corpo.plano !== 'monthly' && corpo.plano !== 'annual') return jsonResponse({ error: 'parametros_invalidos' }, 400)
  if (!FORMAS.has(corpo.forma as Forma)) return jsonResponse({ error: 'forma_invalida', message: 'Escolha Pix, cartão ou boleto.' }, 400)
  if (corpo.aceite !== true) {
    return jsonResponse({ error: 'aceite_obrigatorio', message: 'É preciso aceitar os termos para assinar.' }, 400)
  }
  const documento = typeof corpo.documento === 'string' ? corpo.documento : ''
  if (!cpfValido(documento)) return jsonResponse({ error: 'documento_invalido', message: 'CPF inválido.' }, 400)
  const nome = typeof corpo.nome === 'string' ? corpo.nome.trim() : ''
  if (nome.length < 3) return jsonResponse({ error: 'nome_invalido', message: 'Informe o nome completo.' }, 400)
  return null
}

/**
 * A conta de quem compra sem login: a do e-mail, criada se não existir.
 *
 * Criada já confirmada e sem senha: quem digitou um e-mail que não é seu não
 * ganha nada com isso (não há senha para entrar, e nada é liberado sem
 * pagamento), e o dono do e-mail entra depois com Google — que se liga a esta
 * conta pelo e-mail — ou com "esqueci a senha". Nenhum e-mail é disparado
 * daqui: a função não pode virar um canhão de spam.
 */
async function contaDoEmail(valor: unknown): Promise<{ id: string; nova: boolean } | { erro: Response }> {
  const email = typeof valor === 'string' ? valor.trim().toLowerCase() : ''
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email) || email.length > 200) {
    return { erro: jsonResponse({ error: 'email_invalido', message: 'Informe um e-mail válido.' }, 400) }
  }
  const supa = servico()
  const criado = await supa.auth.admin.createUser({ email, email_confirm: true })
  if (criado.data?.user) return { id: criado.data.user.id, nova: true }
  // Já existe: o link mágico gerado (e não enviado) devolve o usuário.
  const link = await supa.auth.admin.generateLink({ type: 'magiclink', email })
  if (link.data?.user) return { id: link.data.user.id, nova: false }
  console.error('conta do e-mail:', criado.error?.message, link.error?.message)
  return { erro: jsonResponse({ error: 'conta_indisponivel', message: 'Não deu para registrar este e-mail agora. Tente de novo em instantes.' }, 503) }
}

async function assinar(
  atual: Assinatura | null,
  usuarioId: string,
  corpo: Record<string, unknown>,
  semLogin?: { contaNova: boolean },
): Promise<Response> {
  const idPlano = corpo.plano
  if (idPlano !== 'monthly' && idPlano !== 'annual') return jsonResponse({ error: 'parametros_invalidos' }, 400)
  const forma = corpo.forma as Forma
  if (!FORMAS.has(forma)) return jsonResponse({ error: 'forma_invalida', message: 'Escolha Pix, cartão ou boleto.' }, 400)
  if (corpo.aceite !== true) {
    return jsonResponse({ error: 'aceite_obrigatorio', message: 'É preciso aceitar os termos para assinar.' }, 400)
  }
  const termosVersao = typeof corpo.termosVersao === 'string' ? corpo.termosVersao.slice(0, 40) : 'desconhecida'
  const plano = PLANOS[idPlano]
  const supa = servico()
  const descricao = `Baru — plano ${plano.nome}. Assinatura do app Baru.`
  const agora = new Date().toISOString()

  // Trocar o ciclo muda a data das cobranças: cancela e cria de novo, abaixo.
  if (atual && viva(atual) && atual.plano === idPlano) {
    await asaas('PUT', `/subscriptions/${encodeURIComponent(atual.asaas_assinatura_id!)}`, {
      billingType: forma,
      updatePendingPayments: true,
    })
    await supa.from('baru_assinaturas').update({
      forma_pagamento: forma,
      termos_aceitos_em: agora,
      termos_versao: termosVersao,
      atualizado_em: agora,
    }).eq('user_id', usuarioId)
    const pagamento = atual.status === 'ativa' ? null : await cobrancaEmAberto({ ...atual, forma_pagamento: forma }, true)
    return jsonResponse({ pagamento })
  }
  if (atual && viva(atual)) {
    await asaas('DELETE', `/subscriptions/${encodeURIComponent(atual.asaas_assinatura_id!)}`)
  }

  let clienteId = atual?.asaas_cliente_id ?? null
  if (!clienteId) {
    const documento = typeof corpo.documento === 'string' ? corpo.documento.replace(/\D/g, '') : ''
    const nome = typeof corpo.nome === 'string' ? corpo.nome.trim().slice(0, 120) : ''
    if (!cpfValido(documento)) return jsonResponse({ error: 'documento_invalido', message: 'CPF inválido.' }, 400)
    if (nome.length < 3) return jsonResponse({ error: 'nome_invalido', message: 'Informe o nome completo.' }, 400)
    const { data: usuario } = await supa.auth.admin.getUserById(usuarioId)
    clienteId = await acharOuCriarCliente({ usuarioId, documento, nome, email: usuario?.user?.email ?? undefined })
  }

  // Quem assina durante o teste, ou ainda tem período pago, só paga quando ele acaba.
  const hoje = hojeEmSaoPaulo()
  const teste = await fimDoTeste(usuarioId)
  const primeiro = [hoje, teste, atual?.pago_ate].filter((d): d is string => Boolean(d)).sort().at(-1)!
  const assinatura = await asaas<{ id: string }>('POST', '/subscriptions', {
    customer: clienteId,
    billingType: forma,
    value: plano.centavos / 100,
    nextDueDate: primeiro,
    cycle: plano.ciclo,
    description: descricao,
    externalReference: usuarioId,
  })

  const cobranca = await primeiraCobrancaAberta(assinatura.id)
  const { error } = await supa.from('baru_assinaturas').upsert({
    user_id: usuarioId,
    plano: idPlano,
    status: 'pendente',
    asaas_cliente_id: clienteId,
    asaas_assinatura_id: assinatura.id,
    valor_centavos: plano.centavos,
    link_pagamento: cobranca?.invoiceUrl ?? null,
    cobranca_id: cobranca?.id ?? null,
    forma_pagamento: forma,
    termos_aceitos_em: agora,
    termos_versao: termosVersao,
    pago_ate: atual?.pago_ate ?? null,
    cancelada_em: null,
    atualizado_em: agora,
  })
  if (error) throw new Error(`gravar assinatura: ${error.message}`)
  return jsonResponse({
    pagamento: cobranca ? await detalharPagamento(cobranca, forma) : null,
    ...(semLogin ? { semLogin: true, contaNova: semLogin.contaNova } : {}),
  })
}

async function acharOuCriarCliente(p: { usuarioId: string; documento: string; nome: string; email?: string }): Promise<string> {
  const achados = await asaas<{ data: { id: string; deleted?: boolean }[] }>(
    'GET', `/customers?cpfCnpj=${p.documento}&limit=1`,
  )
  const existente = achados.data?.find(c => !c.deleted)
  if (existente) return existente.id
  const criado = await asaas<{ id: string }>('POST', '/customers', {
    name: p.nome,
    cpfCnpj: p.documento,
    email: p.email,
    externalReference: p.usuarioId,
  })
  return criado.id
}

/** Cobrança mais antiga ainda não paga da assinatura. */
async function primeiraCobrancaAberta(assinaturaId: string): Promise<CobrancaAsaas | null> {
  const cobrancas = await asaas<{ data: CobrancaAsaas[] }>(
    'GET', `/subscriptions/${encodeURIComponent(assinaturaId)}/payments?limit=10`,
  )
  const abertas = (cobrancas.data ?? [])
    .filter(c => c.status === 'PENDING' || c.status === 'OVERDUE')
    .sort((a, b) => (a.dueDate ?? '').localeCompare(b.dueDate ?? ''))
  return abertas[0] ?? null
}

/** A cobrança em aberto, com Pix ou boleto prontos para a tela. */
async function cobrancaEmAberto(a: Assinatura | null, gravar = false): Promise<Pagamento | null> {
  if (!a || !viva(a) || a.status === 'ativa') return null
  const cobranca = await primeiraCobrancaAberta(a.asaas_assinatura_id!)
  if (!cobranca) return null
  if (gravar || cobranca.id !== a.cobranca_id) {
    await servico().from('baru_assinaturas')
      .update({ cobranca_id: cobranca.id, link_pagamento: cobranca.invoiceUrl ?? null })
      .eq('user_id', a.user_id)
  }
  const forma = (FORMAS.has(cobranca.billingType as Forma) ? cobranca.billingType : a.forma_pagamento ?? 'PIX') as Forma
  return detalharPagamento(cobranca, forma)
}

async function detalharPagamento(c: CobrancaAsaas, forma: Forma): Promise<Pagamento> {
  const p: Pagamento = {
    id: c.id,
    forma,
    valorCentavos: typeof c.value === 'number' ? Math.round(c.value * 100) : null,
    vencimento: c.dueDate ?? null,
    linkAsaas: c.invoiceUrl ?? null,
  }
  try {
    if (forma === 'PIX') {
      const q = await asaas<{ encodedImage: string; payload: string; expirationDate?: string }>(
        'GET', `/payments/${encodeURIComponent(c.id)}/pixQrCode`,
      )
      p.pix = { imagem: q.encodedImage, copiaECola: q.payload, expiraEm: q.expirationDate ?? null }
    } else if (forma === 'BOLETO') {
      const f = await asaas<{ identificationField: string }>(
        'GET', `/payments/${encodeURIComponent(c.id)}/identificationField`,
      )
      p.boleto = { linhaDigitavel: f.identificationField, pdf: c.bankSlipUrl ?? null }
    }
  } catch (falha) {
    // Sem o QR ou a linha (ex.: chave Pix não cadastrada na conta), a tela
    // oferece a página do Asaas, que mostra as mesmas opções.
    console.error('dados de pagamento:', falha instanceof Error ? falha.message : String(falha))
  }
  return p
}

async function cancelar(atual: Assinatura | null, usuarioId: string): Promise<Response> {
  if (!atual || !viva(atual)) {
    return jsonResponse({ error: 'sem_assinatura', message: 'Não há assinatura ativa para cancelar.' }, 409)
  }
  try {
    await asaas('DELETE', `/subscriptions/${encodeURIComponent(atual.asaas_assinatura_id!)}`)
  } catch (falha) {
    // Já removida no Asaas: segue e marca aqui.
    if (!(falha instanceof ErroAsaas && falha.status === 404)) throw falha
  }
  const { error } = await servico().from('baru_assinaturas').update({
    status: 'cancelada',
    link_pagamento: null,
    cobranca_id: null,
    cancelada_em: new Date().toISOString(),
    atualizado_em: new Date().toISOString(),
  }).eq('user_id', usuarioId)
  if (error) throw new Error(`cancelar: ${error.message}`)
  return jsonResponse({ cancelada: true, valeAte: atual.pago_ate })
}
