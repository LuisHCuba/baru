# Roteiro — a visão de produto, inteira

Tudo o que foi pedido, em lugar durável. Nada aqui pode se perder entre
sessões: este arquivo é a memória, não o histórico da conversa.

Referência declarada pelo dono do produto: **tão bom quanto o Duolingo, tão
dinâmico quanto o Clash Royale.**

Legenda: `[ ]` não começou · `[~]` em andamento · `[x]` entregue e provado

---

## 1. Recompensa que se abre com a mão

- [x] **R-01** — Resgatar deixa de ser um botão. Vira uma cena: a **toca** do
  Baru (não um baú — é um app de bicho, não de RPG). A pessoa **cava** ou
  toca na tela para abrir, e o prêmio sai de dentro.
- [x] **R-02** — Som de prêmio no momento da abertura, não no clique.
- [x] **R-03** — A interação é obrigatória: sem o gesto, não abre. É o gesto
  que faz a recompensa ser sentida.
- [x] **R-04** — Mesma cena serve missão, marco da trilha e nível.

## 2. Ícone do app

- [x] **I-01** — O ícone é o Baru, gerado pelo mesmo `CustomPainter` do app.
- [x] **I-02** — Troca com a espécie (`activity-alias`). Verificado no
  aparelho: a gaveta resolve para `IconeOwl`.
- [x] **I-03** — **Ícone adaptativo.** Era esta a causa de "não aparece do
  jeito que pedi": o PNG quadrado era espremido pela máscara do launcher da
  Samsung, com folga em volta. Agora há `adaptive-icon` com camada de frente
  (só o bicho, fundo transparente, dentro dos 72dp da zona segura) e de
  fundo (cor), uma por espécie.
- [x] **I-04** — Ícone monocromático: a silhueta acompanha o tema do
  sistema no Android 13+.
- [x] **I-05** — **Profundidade no ícone.** Era bicho chapado sobre cor
  chapada, e lia como placeholder. Agora a camada de fundo é desenhada —
  gradiente com a luz vindo de cima, folhagem emoldurando pelas bordas,
  vinheta que faz o corte da máscara parecer intenção — e a de frente ganhou
  sombra de chão e o bicho ocupando a zona segura de verdade. As folhas
  nasceram grandes e no meio, virando manchas que competiam com o bicho;
  foram para a borda e diminuíram.

## 3. Widgets

- [x] **W-01** — Widget de tela inicial com o Baru, humor ao vivo, raiz e
  meta do dia.
- [x] **W-02** — Tamanhos: 2x2 e 4x2.
- [x] **W-03** — Toque no widget abre a tela certa (foco, trilha, raiz).
- [x] **W-04** — Atualização quando o humor muda, sem drenar bateria.

> `RemoteViews` **não** desenha `CustomPainter`. O Baru do widget tem de ser
> PNG gerado em tempo de execução pelo app e gravado em disco, com o provider
> apontando para o arquivo — o mesmo caminho do gerador de ícone
> (`test/gera_icone_test.dart`), agora em runtime.

## 3.5 Presença do bicho

- [x] **PB-01** — **O pet está pequeno na tela.** Ele é o produto; hoje ocupa
  pouco da home. Aumentar de verdade, não 10%.
- [ ] **PB-02** — Presença viciante: mais reações, mais vida, mais motivo
  para voltar e olhar.

## 4. A raiz, desenhada

- [x] **RZ-01** — A raiz deixa de ser número e vira **desenho**: cresce,
  engrossa e cria ramificações conforme os dias presentes.
- [x] **RZ-02** — Marcos visuais: a raiz muda de forma em números redondos.
- [x] **RZ-03** — Compartilhável (imagem gerada, não captura de tela).
- [x] **RZ-04** — A raiz aparece no widget e na home, não só na tela dela.

## 5. Trilha

- [x] **T-01** — Não mostrar níveis futuros como se estivessem carregados.
  Quem está no passo 3 vê que está no 3.
- [x] **T-02** — O critério de cada passo tem de ser coerente e legível:
  "o que falta para este passo" em uma frase.
- [x] **T-03** — **Habitats se desbloqueiam subindo a trilha**, estilo arena
  do Clash Royale. Hoje o habitat não tem relação nenhuma com a trilha.
- [x] **T-04** — Trocar de habitat de dentro da trilha.
- [x] **T-05** — Enriquecer: mais passos, mais recompensas, mais a ver.

## 6. Permissões

- [x] **P-01** — Ao abrir, pedir **todas** as permissões de que o app
  precisa, explicando cada uma. Hoje a sobreposição fica de fora e o app
  parece quebrado.
- [x] **P-02** — Se alguma for negada, dizer o que deixa de funcionar — e
  poder pedir de novo depois.

## 7. Sobreposição — todos os apps, não só o TikTok

- [x] **S-01** — O companheiro aparece sobre **qualquer** app que consome o
  tempo da pessoa: TikTok, YouTube, Instagram, Reddit, X, Kwai, Twitch,
  Netflix, jogos.
- [x] **S-02** — O catálogo de apps dispersivos vive no app e é editável
  pela pessoa.
- [x] **S-03** — A fala varia com o app: "o YouTube de novo?" é diferente de
  "o TikTok de novo?".

## 8. Missão do descanso

- [x] **D-01** — A missão diária principal é **descansar**: ficar longe do
  telefone por um tempo (ex.: 40 min), estilo pomodoro.
- [x] **D-02** — Durante a missão, escapar para outro app tem custo
  visível: o companheiro aparece, o progresso da missão para, e a pessoa vê
  o que está perdendo. Sem bloqueio.
- [x] **D-03** — Frequência diária, com a insistência do Duolingo.

> **DECIDIDO (2026-08-28).** Nada de bloqueio. O Android não permite que um
> app bloqueie outro, e o caminho que permitiria — `AccessibilityService` —
> é a permissão mais invasiva do sistema, que a Play exige justificar em
> vídeo e costuma recusar. O produto usa **persistência**: sobreposição
> chamando de volta, perda visível de progresso, o bicho reagindo. Sem
> fingir trava, sem pedir permissão que arrisque a publicação.
- [x] **D-04** — Atrito definido: persistência, nunca bloqueio.

## 9. Retenção diária, estilo Duolingo

- [x] **RD-01** — Lembrete diário no horário que a pessoa costuma usar.
- [x] **RD-02** — A raiz em risco é comunicada antes de quebrar.
- [x] **RD-03** — Recompensa por voltar, não só por performar.

## 10. Social (declarado para depois)

- [ ] **SC-01** — Adicionar amigos.
- [ ] **SC-02** — Competir: placar entre amigos.
- [ ] **SC-03** — Premiação entre amigos.
- [ ] **SC-04** — Enviar **ervas, curas e remédios naturais** — não
  "poções". O vocabulário é da natureza, como o resto do app.

## 11. Loja

- [ ] **L-01** — Enriquecer muito mais: cenários, roupas, objetos.
- [ ] **L-02** — Estética: a loja ainda parece uma grade de quadrados.

## 12. Pagamento

Ver `BLOCKERS.md` BL-11. Recomendação: RevenueCat sobre Play Billing;
Mercado Pago com Pix na web; direito de acesso no Supabase, escrito por
webhook. Travado em contas que só o dono abre.
