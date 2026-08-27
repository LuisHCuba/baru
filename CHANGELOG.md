# Changelog

Formato: entradas por data, agrupadas em Adicionado / Corrigido / Alterado /
Removido. Datas em AAAA-MM-DD.

## 2026-08-27 — navegação, carinho e o elenco refeito

### O QUE MUDOU NA TELA

- **O botão voltar do Android funciona.** Era a queixa: em qualquer tela ele
  fechava o app. Agora tem pilha de verdade: num detalhe volta um passo, numa
  aba que não é a home volta para a home, e só na home ele sai. Durante uma
  sessão de foco ele **pergunta** em vez de descartar o foco em silêncio.
- **As telas entram com transição, não com corte seco.** Irmãos deslizam de
  lado, filho entra em profundidade, modal sobe de baixo — e a barra de
  destinos é fixa: ela sobrevive à troca de tela.
- **Cada tela tem endereço** (`/trilha`, `/missoes`, `/tempo`…): o app tem deep
  link, e na web a barra do navegador mostra onde você está.
- **Dá para acariciar o Baru.** Passe a mão nele: ele acompanha a mão com o
  olhar, encosta a cabeça, aperta os olhinhos de contentamento, o pelo se
  levanta sob o dedo e sobem coraçõezinhos. A mão **ronrona** — um clique curto
  a cada tanto de percurso.
- Afago completo rende **+3 XP** com um rótulo que sobe do bicho, e o
  **Vínculo** aparece na trilha ("Vínculo · 23 afagos").
- **Capivara, lontra e tartaruga foram refeitas.** Eram de perfil: um corpo-ovo
  comprido com uma cabeça-ovo colada na ponta. Agora são personagens de frente,
  na mesma construção da coruja — cabeça grande, cara legível, corpo compacto,
  membros visíveis. A capivara ganhou o focinho rombudo que a define; a lontra,
  bigodes dos dois lados e focinheira escura; a tartaruga virou casco-corpo com
  a cabeça saindo por cima.

### Corrigido

- **"Erro ao sincronizar" a cada gravação.** Causa encontrada e provada por
  sonda REST: `baru_app_categories` **não existe no projeto remoto**, e
  `pushSettings` faz um `delete` nela em toda gravação, mesmo sem nenhuma
  reclassificação. O que dependia deste lado está feito — a migração existe,
  foi validada em banco limpo, e o app parou de chamar isso de falha de rede.
  Aplicar no remoto é do humano: **BL-10**.
- Tabela ausente no remoto agora tem tipo próprio (`TabelaAusenteNoRemoto`) e
  mensagem própria em 4 idiomas, dizendo **qual** tabela falta. Antes o app
  dizia "não foi possível sincronizar" e tentava de novo para sempre — mentira
  em dois níveis: não é falha de rede, e tentar de novo nunca resolve.
- XP, nível celebrado e marcos existiam **só no aparelho**: nenhuma coluna
  remota. Desinstalar zerava a trilha. Agora vão para `baru_progression`.

### Adicionado

- `lib/navegacao.dart`: classificação de rota (destino/detalhe/modal/fluxo),
  `PaginaBaru` com transição derivada do tipo, `BaruRouterDelegate` e
  `BaruRouteParser`. `MaterialApp` virou `MaterialApp.router`.
- Migration 8 `baru_progression` (xp, nível celebrado, marcos, afeto, carinhos
  do dia) com RLS e as 4 políticas.
- `Balanco.carinhosPorDia` (5) e `Balanco.xpPorCarinho` (3).
- `test/navegacao_test.dart` (17) e `test/carinho_test.dart` (11).

### Portões (execução real)

- `flutter analyze`: No issues found
- `flutter test`: **324 passando, 1 pulado** (eram 296)
- `supabase db reset` em banco limpo: 8 migrations, 15 tabelas, **0 sem RLS**,
  58 políticas
- RLS de `baru_progression` provada em SQL: A vê 1 linha, `UPDATE 0` e
  `DELETE 0` na linha de B, `anon` vê 0
- Os testes de voltar-do-sistema e de carinho foram verificados por mutação

## 2026-08-27 — arte e reações do companheiro

### O QUE MUDOU NA TELA

- **Cada bicho virou um bicho.** A silhueta é desenhada em camadas de anatomia
  com curvas de Bézier — corpo, barriga, membros, cauda, cabeça, focinho,
  olhos — no lugar dos retângulos arredondados empilhados. A lontra tem
  bigodes e cauda grossa que afina; a tartaruga tem cúpula com escudos,
  plastrão e cabeça pequena; a coruja tem disco facial, tufos de base larga e
  ponta afiada, asas dobradas sobre o corpo e **pés pousados com três dedos**.
- **Ele faz coisas sozinho.** A cada 7 a 15 s ele se espreguiça (com bocejo e
  olhos fechados), sacode a cabeça, ou olha em volta. Só quando está à toa:
  nadando, pastando ou dormindo o corpo já tem o que fazer.
- **Insistir no carinho aparece na tela.** Do terceiro toque em 3 s em diante
  sobem coraçõezinhos. O háptico já ficava mais forte; a tela não mudava.
- Ele **olha para onde você tocou** e a cabeça acompanha o olhar.
- A piscada tem intervalo irregular e às vezes é dupla.

### Corrigido
- **A orelha ficava levantada depois do toque.** `AnimationController.forward`
  termina em 1.0 e fica lá; só o agendador do tremor resetava, até dez
  segundos depois. Na orelha redonda o defeito se escondia (`sin(2π) = 0`),
  mas o tufo da coruja é linear e ficava torto. Teste em
  `pet_vivo_test.dart` captura os pixels no repouso e depois da reação e
  exige que sejam iguais.
- Com "reduzir movimento" o tremor de orelha do toque não acontecia. O §7
  manda reduzir amplitude, não apagar o retorno.
- Os tufos da coruja eram cortados pelo topo do quadro ao se espreguiçar: ela
  nascia com 3 px de folga.
- As asas da coruja chegavam a ±56 num corpo de ±47 e liam como um halo
  escuro atrás dela, não como asas dobradas.
- Os riscos de pena vazavam a silhueta da asa e pareciam arranhões no fundo.
- Os bigodes da lontra saíam do quadro de 200×150.
- O plastrão da tartaruga era um fio branco entre o casco e as patas.

### Adicionado
- `GestoOcioso` e o rig de gesto em `pet.dart`.
- Costuras de teste `PetView.observadorDeGesto` e `PetView.gestoForcado`,
  nulas em produção: o gesto é disparado por `Timer` com sorteio, e sem elas
  não há como afirmar que aconteceu nem capturar um gesto específico.
- Seis PNGs de reação em `docs/evidence/2026-08-27/` (`reacao-1..6`).
- Sete testes novos em `pet_vivo_test.dart`, todos verificados por mutação:
  removida a funcionalidade, o teste falha.

Portões: `flutter analyze` sem issues, `flutter test` **296 passando e 1
pulado**, 13 testes de evidência verdes em três execuções seguidas.

## 2026-08-27 — turno de produto

### O QUE MUDOU NA TELA

- O Baru **respira, pisca e dá uma quicada quando você toca nele**.
- O habitat ganhou céu em gradiente, sol ou lua com halo, colinas que derivam
  e reflexos andando na água.
- **O habitat às 22h não é mais igual ao das 9h**: céu índigo, água escura,
  lanterna acesa.
- Comprar um item o faz **cair na cena com mola**, com sombra por baixo.
- Tela nova **"Seu tempo de tela"**: quanto conta para a meta, quanto foi no
  total, a quebra por categoria em barras coloridas e a lista por aplicativo
  com nome legível. **O Spotify aparece como Áudio, fora da meta.**
- Tocar num app abre a folha de reclassificação, e o número da meta muda na
  hora.
- Aba nova **"Trilha"**: nível, barra de XP, quanto falta, o próximo passo em
  destaque e doze marcos ligados por uma linha.
- **Subir de nível toma a tela** com partículas e háptico.
- Aba nova **"Missões"**: progresso x de y, recompensa exata em folhas e XP,
  prazo, e um botão "Resgatar" que faz **o saldo de folhas subir animado**.
- A **sessão de foco aparece na barra de notificações**, com contagem
  regressiva viva e botão "Desistir".
- A home mostra o **nível de verdade** no lugar de "Habitat nível N", que era o
  número de itens dividido por três.

Portões: `flutter analyze` sem issues, `flutter test` 289 passando e 1 pulado,
integração 7/7 contra Supabase local, 7 migrations aplicando em banco limpo,
33 PNGs de evidência.

### Adicionado
- Design system em código (`lib/design/tokens.dart`) e sistema de movimento
  (`lib/design/motion.dart`).
- Nunito empacotada em `assets/fonts`; `google_fonts` sai das dependências.
- Contabilidade de tempo de tela (`lib/data/tempo_de_tela.dart`): reconstrução
  de intervalos por par de eventos, quatro categorias de produto, exclusões de
  sistema, tabela de 57 apps e reclassificação pelo usuário (ADR-009).
- Progressão (`lib/data/progressao.dart`): XP, curva de nível, doze marcos,
  espécies desbloqueáveis. Todos os números de balanceamento num arquivo só.
- Missões (`lib/data/missoes.dart`): três diárias e duas semanais, sorteio
  determinístico e resgate idempotente (ADR-010).
- Telas: `tempo_screen`, `trilha_screen`, `missoes_screen`.
- Componentes canônicos: `ContadorAnimado`, `BarraAnimada`, `CartaoBaru`,
  `Etiqueta`, `EstadoVazio`, `Esqueleto`, `Celebracao`.
- Notificação viva da sessão com cronômetro do sistema (ADR-011).
- Migration 7: `baru_app_categories` com RLS e CHECK.
- Evidência visual gerada por teste (`test/evidencia_test.dart`).

### Corrigido
- **Spotify tocando no bolso contava como tempo de tela.** Contava também
  launcher, system UI, teclado e o próprio Baru.
- **O companheiro não se movia** — nenhum `AnimationController` no `PetView`.
- **A cena não conhecia a hora do dia.**
- **O toque no bicho não funcionava**: `deferToChild` sobre um `CustomPaint`
  sem filho nunca recebe hit-test.
- Com "reduzir movimento" ligado, o Flutter encurtava o controller para 5% e a
  quicada do toque acabava antes de ser vista.
- **"Habitat nível N" era o número de itens dividido por três.**
- **As quests anunciavam "+10" e "+15" e não creditavam nada.**
- Missão em andamento aparecia rotulada como "concluída".
- O chip de sequência e o cartão de uso truncavam na home.

### Alterado
- A barra de destinos passa a ser **Habitat · Trilha · Missões · Ajustes**.
  Loja e relatório viram telas de detalhe com botão de voltar.
- `LeafBadge` usa contador animado: o saldo sobe em vez de saltar.
- `usage` passa a ser o tempo **contabilizado** (dispersivo + neutro), não a
  soma bruta de foreground.

## 2026-08-26 — turno noturno

Portões ao fim do turno, executados: `flutter analyze` sem issues,
`flutter test` 151 passando e 1 pulado, integração 5/5 contra o stack local,
`supabase db reset` aplicando as 6 migrations num banco limpo.

### Adicionado
- **Bônus de +15 folhas por fechar o dia abaixo da meta** (contrato §5). A
  quest e o relatório anunciavam o bônus e nenhum código creditava. Pago na
  virada do dia (ADR-005).
- **Aviso de 24h antes do fim do trial** (contrato §9). A copy do paywall
  prometia o recado e não havia agendamento.
- **Sessão de foco resiliente**: `sessionStartedAt`/`sessionEndsAt` persistidos,
  retomada ao abrir o app, conclusão de sessão que venceu com o app fechado
  (ADR-008).
- Migration `20260827000000_baru_adopt_rls_auto_enable.sql`: adota no
  repositório a função e o event trigger que só existiam no banco (ADR-002).
- `supabase/config.toml` e `supabase/seed.sql`.
- Suítes novas: `l10n_test`, `mood_test`, `economy_test`, `calendar_test`,
  `session_test`, `sync_test`, `trial_test`, `app_frame_test`,
  `auth_lang_test` e `test/integration/supabase_roundtrip_test`.
- Controle de versão: repositório git, branch `night/2026-08-26`, remote
  `LuisHCuba/baru` (ADR-001), `.gitattributes`.
- Documentação viva: `README.md`, `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`,
  `docs/DATA_MODEL.md`, `docs/DECISIONS.md`, `docs/BACKLOG.md`,
  `docs/BLOCKERS.md`, `docs/STATE.md` e este arquivo.

### Corrigido
- **Crash em en/es/zh**: 5 chaves de i18n só existiam em pt e `T.s()` faz cast
  para `String`. `syncFail` é usada com o idioma do usuário, então qualquer
  falha de sincronização derrubava o app dentro do próprio handler de erro.
- **A faixa "esta semana" nunca zerava na virada** de domingo para segunda:
  dias que ainda não aconteceram apareciam como presentes (ADR-006).
- **`todayIndex` desandava** em relação ao calendário depois de ausência longa,
  e o ponto de "hoje" apontava o dia errado (ADR-006).
- **`daysAway`** passa a ser fato de data. O congelamento o zerava, então
  `missing_you` só aparecia no terceiro dia, e o contrato diz dois.
- **Sincronização perdia a intenção** quando um domínio falhava: a máscara era
  zerada antes do push e um erro abortava os quatro domínios seguintes
  (ADR-007).
- **Moldura de desktop aparecia dentro do celular** deitado; a orientação
  passa a ser travada em retrato no mobile.
- **A porta de entrada falava só português** num app de quatro idiomas.
- Mudança efêmera (folha de compartilhamento, humor forçado, flag de debug)
  disparava push das 13 tabelas, e estado de debug vazava para a conta real.
- `_ready` do gateway ficava preso em `true` após expiração de sessão.
- Migration 5 quebrava ao ser reaplicada — as guardas por
  `information_schema` não protegiam nada (ADR-003).
- `SUPABASE_ENABLED` no `.env` era inerte.
- `.gitignore` deixava `android/build/` e `**/.cxx/` entrarem no versionamento.

### Alterado
- Push de sessões em lote (era um round-trip por sessão, até 80) e remoção de
  inventário numa chamada só.
- `acquired_at` do inventário preservado entre pushes.
- Pull remoto do login em paralelo (eram dez consultas em série).
- A folha de desistência não pausa mais o relógio da sessão — decorrência de
  medir pelo relógio de parede, e mais honesta: olhar a folha já é mexer no
  telefone.
- `baru_app/README.md` deixa de ser boilerplate e aponta para os docs.

### Removido
- E-mail pessoal da conta de teste em `supabase/README.md` — o remote é
  público (ADR-004).
- Referências a `seed_test_user.ps1` e `seed_test_user.sql`, que não existiam.
