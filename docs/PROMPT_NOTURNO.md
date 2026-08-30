# MISSÃO NOTURNA — Baru completo nas três frentes, pronto amanhã de manhã

Você é o agente responsável pelo turno noturno do produto **Baru** no repositório
`LuisHCuba/baru`. Você trabalha sozinho, decide sozinho e NÃO faz perguntas ao
humano. Toda decisão ambígua você resolve seguindo, nesta ordem: (1) este
prompt, (2) `docs/PRODUCT.md` (contrato de produto), (3) `docs/RELATORIO_UX_DUOLINGO.md`
(análise de UX com prioridades), (4) seu melhor julgamento — registrado como ADR
em `docs/DECISIONS.md`. Decisão tomada não se rediscute durante o turno.

## O produto, em um parágrafo (memorize — isto guia tudo)

**Baru é um app mobile de redução de tempo de tela e foco em que um bicho de
estimação vive num habitat que reflete o comportamento do usuário.** Você faz
sessões de foco e fica longe do telefone; o bicho fica radiante, a raiz (streak)
aprofunda, o habitat enriquece. Sem punição, sem culpa: o bicho nunca morre,
nunca perde nada, nunca acusa. Conceito: **habitat, não timer**. Tom: caloroso,
4 idiomas (pt/en/es/zh). Referência de qualidade: Duolingo (densidade de
sentimento) com o tom do Baru.

Este parágrafo é o posicionamento canônico. Grave-o em `docs/POSICIONAMENTO.md`
(nos 4 idiomas, com uma versão de 1 frase, 1 parágrafo e 3 bullets de benefício)
e use-o literalmente na landing, no README e na tela de promessa do onboarding.
Uma fonte, três públicos: dono, cliente final e desenvolvedor.

## Leia antes de escrever qualquer linha

`docs/PRODUCT.md` · `docs/STATE.md` · `docs/BLOCKERS.md` · `docs/ROADMAP.md` ·
`docs/RELATORIO_UX_DUOLINGO.md` (o plano de trabalho vem dele) · `CHANGELOG.md` ·
`baru_app/GO_LIVE.md` · `landing/README.md` · `docs/DATA_MODEL.md`.

## Regras invioláveis (quebrar qualquer uma = turno reprovado)

1. **Sem punição** no produto, nunca (PRODUCT.md §1).
2. **Toda string nova nasce nos 4 idiomas** via catálogos `lib/l10n*.dart`; zero string fixa.
3. **Design system**: nenhuma cor/espaço/raio fora dos tokens de `lib/design/`.
4. **Nunca inventar dado**: sem permissão/medição, estado vazio honesto. Vale
   para o admin também: sem dado, "sem dados ainda", jamais número fake.
5. **Nenhum segredo no repositório nem em cliente**: chaves publicáveis via
   env/injeção (padrão já existente em `landing/injeta-config.js`);
   `service_role` do Supabase NUNCA em código de cliente.
6. **O que só um humano pode fazer** (keystore de release, IAP nas lojas,
   entitlement iOS, env vars no Netlify, aplicar migrations no Supabase remoto)
   você NÃO simula: valida localmente, documenta o comando exato em
   `docs/BLOCKERS.md` e segue.

## Fluxo de trabalho

- Branch `night/<data-de-hoje>`. Commits pequenos com mensagem clara.
- Merge na `main` **somente** com os portões verdes: `flutter analyze` sem
  issues, `flutter test` 100% (exceto skips já existentes), `supabase db reset`
  limpo se você criar migration, e `flutter build apk --release` compilando.
- A cada frente concluída: atualizar `CHANGELOG.md`; ao fim do turno reescrever
  `docs/STATE.md` (retrato honesto: o que fechou, o que ficou, portões
  executados de verdade — nunca declarar portão que não rodou).
- Evidência visual: regenerar/estender os PNGs de `docs/evidence/` para o que
  mudou de tela.

---

## FRENTE 1 — O aplicativo (Flutter, `baru_app/`)

Executar o plano de `docs/RELATORIO_UX_DUOLINGO.md`, nesta ordem, parando onde o
tempo acabar (nunca pela metade: cada item fecha com teste + i18n + evidência):

1. **Pacote P0 inteiro**: os 14 defeitos B1–B14 (tabela da seção 11) + R4
   (saída "Agora não" no paywall) + R5 (locale do aparelho) + R7 (háptico/som
   nos botões do loop) + R10 (chip "Livre" vira seletor real) + R12 (higiene da
   sessão) + R18 (sorteio de missões garante dia jogável) + R26 (alvo da
   carteira) + R28/R29 (notificação de saudade agendada de verdade + deep link
   em toda notificação) + R32 (share com pré-visualização) + R35 (data real no
   relatório).
2. **R8 — cadeia de celebração na tela de resultado** (folhas com contador →
   XP enchendo → raiz crescendo → missões tocadas → nível/marco como etapa
   final, nunca véu por cima). É o item de maior retorno do relatório.
3. **R13 + R14 + R15 — raiz como produto**: marcos celebrados com oferta de
   share, risco visível na home depois das 19h, congelamento visível e "raiz
   salva" como cena.
4. **R9** CTA "Começar foco" fixo (sem rolagem) e **R11** pet expressivo em
   todos os humores.
5. Se sobrar noite: R2+R3 (primeira sessão guiada + revelação celebrada), R27
   (variantes de notificação), R30 (quiet hours), R36 (semana real no relatório).

## FRENTE 2 — A landing page (`landing/`)

Reescrever `landing/index.html` mantendo o pipeline de deploy existente
(`netlify.toml`, `injeta-config.js`, lista de espera Supabase):

- **Acima da dobra**: o posicionamento canônico de `docs/POSICIONAMENTO.md` —
  em 5 segundos qualquer visitante entende o que o Baru é, para quem é e o que
  ganha. Headline = a promessa ("Deixe o celular de lado. Alguém fica feliz com
  isso."), sub = a 1 frase canônica, CTA = lista de espera.
- Seções: como funciona (3 passos: foco → bicho feliz → habitat cresce), o
  contrato sem punição (diferencial nº 1, dito com todas as letras), o elenco
  de espécies (assets já existem em `landing/assets/`), a raiz, FAQ curto
  (privacidade do tempo de tela: só agregado, nada sai do aparelho), rodapé com
  Termos/Privacidade.
- 4 idiomas com seletor (reusar as strings dos catálogos do app onde couber),
  paleta e Nunito do design system, leve (sem framework), acessível, responsiva.
- Performance: imagens otimizadas, sem blocking scripts; deve pontuar ≥90 em
  Lighthouse mobile (rode local e registre o número).

## FRENTE 3 — A administração (novo, `admin/`)

Painel web onde o dono gerencia clientes e analisa métricas. Decisões já tomadas:

- **Stack**: site estático em `admin/` (HTML/CSS/JS puro + `@supabase/supabase-js`
  e Chart.js via CDN), segundo site no Netlify (crie `admin/netlify.toml` no
  mesmo padrão de injeção de config). Sem framework, sem build complexo.
- **Acesso**: login Supabase (e-mail/senha) + tabela `baru_admins` (e-mail do
  dono como seed via migration — pegue o e-mail do dono do projeto, não
  hardcode em JS). Toda leitura administrativa via **views/RPCs `security
  definer`** criadas em migration nova, que conferem `baru_admins` e devolvem
  **apenas agregados** — o admin não lê tabela crua de usuário via RLS aberta.
- **Telas** (uma página, navegação por abas):
  1. **Visão geral**: usuários totais/novos, DAU/WAU/MAU, sessões de foco por
     dia (30d), taxa de conclusão vs desistência, distribuição de tamanho de
     raiz, funil de onboarding (contas criadas → onboarding completo → 1ª
     sessão), lista de espera da landing.
  2. **Clientes**: tabela paginada (e-mail, criado em, último acesso, streak,
     nível, plano/trial) com busca; detalhe read-only por cliente.
  3. **Produto**: missões mais/menos concluídas, itens mais comprados,
     espécies escolhidas, retenção D1/D7/D30 por coorte semanal.
- Estados vazios honestos (o banco quase não tem dados reais — o painel deve
  ficar bonito e verdadeiro com 3 usuários). Identidade visual do Baru (tokens).
- Migrations validadas com `supabase db reset` local; comando de aplicação no
  remoto documentado em `docs/BLOCKERS.md` para o humano.
- `admin/README.md`: como rodar local, como fazer deploy, modelo de segurança.

---

## Definição de "pronto e perfeito" (checklist final do turno)

- [ ] Portões verdes (analyze, test, db reset, build apk) — executados, com
      saída colada no STATE.md
- [ ] P0 do app 100% fechado; itens 2–4 da Frente 1 fechados ou não iniciados
      (nada pela metade)
- [ ] Landing nova no ar via pipeline atual, 4 idiomas, posicionamento canônico
      acima da dobra, Lighthouse ≥90 registrado
- [ ] Admin funcional local contra Supabase local, com login, 3 telas,
      agregados via RPC seguros, README e migrations prontas
- [ ] `docs/POSICIONAMENTO.md` criado e referenciado por landing, README e
      onboarding
- [ ] CHANGELOG, STATE.md, DECISIONS.md (ADRs das decisões novas) e BLOCKERS.md
      (lista exata do que depende do humano, com comandos) atualizados
- [ ] Tudo mesclado na `main` com push feito

Comece agora pela leitura dos documentos, depois Frente 1. Não pergunte nada;
decida, registre e entregue.
