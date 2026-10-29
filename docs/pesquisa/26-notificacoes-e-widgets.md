# 26 — Notificações e widget: como o Duolingo faz, e o que entrou no Baru

Pedido: pesquisar exatamente como o Duolingo faz as notificações (barra, tela de bloqueio, as que descem do topo) e os widgets da tela inicial, como ele decide o horário, e aplicar no Baru.

Classificação das fontes:
- **[P]** primária: a Duolingo, um funcionário dela, ou a documentação oficial da Apple ou do Google.
- **[S]** secundária: imprensa.
- **[NÃO CONFIRMADO]**: não achei fonte primária.

Complementa o laudo 01 (§9 e U9), que já tinha a parte do paper e a regra de tom "sem punição".

## 1. Quando o Duolingo manda

- **23,5 h depois da primeira prática.** O lembrete do dia seguinte é agendado para 23,5 h depois da *primeira* prática do dia. É a variante que "continues to win" nos testes. **[P]** Jackson Shuttleworth (líder de Retenção), [Sub Club](https://subclub.com/episode/how-to-time-reactivation-campaigns-for-maximum-impact-jackson-shuttleworth-duolingo)
  - Horário fixo escolhido pelo usuário falha: a chance de a pessoa estar livre sempre naquela hora "is just zero". **[P]** (mesma fonte)
  - O laudo 01 registrou que não tinha achado fonte para os 23,5 h; agora há.
- **A IA decide hora e texto.** Um sistema de IA decide "when to send" e o que dizer. **[P]** Luis von Ahn, CEO, [Acquired](https://www.acquired.fm/acq2-episodes/why-duolingo-worked-with-luis-von-ahn-ceo)
- **O paper do KDD 2020 trata do texto, não do horário.** O bandit escolhe entre modelos escritos à mão. **[P]** [Yancey & Settles](https://research.duolingo.com/papers/yancey.kdd20.pdf)
  - **Sucesso** é uma lição em até 2 h.
  - **Penalidade de recência:** γ·0,5^(d/h), com γ = 0,017 e meia-vida h = 15 dias.
  - **Escolha:** softmax com τ = 0,0025.
  - **Braços "dormentes":** são os modelos que não podiam sair naquele dia, como o de marco; não são julgados por esses dias.
  - **Resultado contra a escolha aleatória:** DAU +0,5%, retenção D1 de novos +2,2%, D7 de novos +2,0%.

## 2. Quanto e até quando

- **Protect the channel.** Mudar horário e texto era livre. Aumentar o volume exigia "strong justification and CEO approval", porque quem desliga as notificações não volta. **[P]** Jorge Mazal, ex-VP de Produto, [Lenny's Newsletter](https://www.lennysnewsletter.com/p/how-duolingo-reignited-user-growth)
- **Streak saver.** Uma notificação no fim da noite, avisando que a sequência está em risco, foi a "first big win" do time de crescimento. Não há número publicado. **[P]** (mesma fonte)
- **Quando param:**
  - Shuttleworth diz que, depois de 7 dias sem uso, eles desligam os lembretes de prática, e que a eficácia já cai muito depois do 3º ou 4º dia. **[P]** (Sub Club)
  - Von Ahn conta que "at some point" passaram a parar depois de 5 dias. A última mensagem era: "these notifications don't seem to be working. We're going to stop sending them for now". Ela trouxe muita gente de volta, porque soava como a Duolingo desistindo da pessoa. **[P]** (Acquired)
- **Permissão.**
  - Trocar o texto do pedido de "manter a sequência" para "construir um hábito de longo prazo" deu +5% de aceite. **[P]** [Duolingo blog](https://blog.duolingo.com/putting-in-work-the-habit-of-language-learning/)
  - Na Alemanha, "notifications are proven to foster learning success" deu +8% de aceite. Em espanhol não teve efeito. **[P]** [Duolingo blog](https://blog.duolingo.com/copy-testing-experiments/)
- **Rosto na notificação.** A personalidade do Duo nasceu do ícone da coruja aparecendo em toda notificação. **[P]** (Acquired)
- **[NÃO CONFIRMADO]** Não há fonte primária sobre os detalhes técnicos das notificações do Duolingo: canais e importância no Android, imagem do Duo, botões, time-sensitive no iOS.

## 3. O widget do Duolingo

- **O que mostra.** Só se a lição do dia foi feita e o tamanho da sequência. O post diz que é "uma série de ilustrações que mostra o humor do Duo em diferentes partes do dia". Antes da lição ele fica cada vez mais desesperado até a meia-noite; depois, relaxado. **[P]** [blog](https://blog.duolingo.com/widget-feature/)
- **Resultados.** A retenção é bem maior "mesmo controlando" o engajamento prévio de quem instala. Metade dos usuários com widget tem sequência de 6+ meses. Os usuários dizem que o widget funciona tão bem quanto o push. **[P]** (mesma fonte)
  - Não há percentual de DAU publicado.
- **Ilustrações.** Em 2023 vieram mais 25. Em 2025, "nova arte de widget e widgets animados". **[P]** [blog](https://blog.duolingo.com/widget-feature/), [product highlights](https://blog.duolingo.com/product-highlights/)
- **[NÃO CONFIRMADO]** Não há fonte primária sobre:
  - os horários exatos de cada estado;
  - os tamanhos oferecidos;
  - a implementação técnica;
  - uma Live Activity de sequência. A única notícia é um anúncio do Super por Live Activity, que viola a regra da Apple. **[S]** [MacRumors](https://www.macrumors.com/2026/01/02/duolingo-dynamic-island-ad/)

## 4. Limites das plataformas

- **Importância do canal (Android).** `IMPORTANCE_HIGH` "makes a sound and appears as a heads-up notification", ou seja, a que desce do topo. Depois que o canal é criado, só o usuário muda a importância. **[P]** [Android, canais](https://developer.android.com/develop/ui/views/notifications/channels)
- **Alarmes inexatos.** No Android 12+ chegam "within one hour" do horário. `SCHEDULE_EXACT_ALARM` vem negada em instalações novas, e `USE_EXACT_ALARM` é só para despertador e calendário. **[P]** [alarmes](https://developer.android.com/develop/background-work/services/alarms), [Android 14](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- **Widget no Android.** `updatePeriodMillis` não aceita menos de 30 min. Para conteúdo que muda por horário, a documentação indica alarmes inexatos, que somem no reboot. **[P]** [widgets avançados](https://developer.android.com/develop/ui/views/appwidgets/advanced), [alarmes](https://developer.android.com/develop/background-work/services/alarms)
- **Widget no iOS.** O WidgetKit usa uma timeline de estados futuros, com orçamento típico de 40 a 70 recargas por dia. **[P]** [Apple](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date)
- **`home_widget`.** O `renderFlutterWidget` não roda com o app em segundo plano. **[P]** [docs](https://docs.page/abausg/home_widget/features/render-flutter-widgets)
- **Qualidade do widget (Tier 1).** Redimensionar para 2x1 e mais tamanhos, usar o raio de canto do sistema, ter tema claro e escuro, e não ficar desatualizado depois de uma ação no app. **[P]** [qualidade de widget](https://developer.android.com/docs/quality-guidelines/widget-quality)

## 5. O que entrou no Baru

### Widget que muda sozinho ao longo do dia

**Como funciona:**
- O app desenha cinco imagens do bicho e grava as frases traduzidas; o Kotlin escolhe qual mostrar pela hora e por "a raiz já cresceu hoje", com o app fechado.
  - É o mesmo princípio da "série de ilustrações por parte do dia" do Duolingo.
  - O desenho é feito com o app de pé, porque o `renderFlutterWidget` não roda em segundo plano.
- A próxima troca é agendada com alarme inexato e sem acordar o aparelho (`AlarmManager.RTC`). Com a tela apagada ninguém vê o widget, e ele se atualiza quando o aparelho acorda.
- O widget redesenha ao religar o aparelho e quando o relógio ou o fuso mudam.
- **O número da raiz** vale até a meia-noite do dia seguinte à última presença. Depois disso ele some, em vez de afirmar um número que pode ter mudado, e volta certo quando o app abre.

**Os momentos do dia:**

| Momento | Quando | Bicho |
|---|---|---|
| Feito | raiz cresceu hoje, até a meia-noite | radiante, com brilhos |
| Manhã | 5h–12h | contente, acordado |
| Tarde | 12h–18h | esperando |
| Noite | 18h–23h | sonolento |
| Madrugada | 23h–5h | dormindo deitado |

**O tom é o do laudo 01, sem desespero.** O Duolingo usa o Duo cada vez mais desesperado; o Baru usa o bicho que se aconchega e dorme. Um teste garante que nenhum momento usa o humor triste.

### Notificações

1. **Horário dos 23,5 h.**
   - O convite sai 30 min antes do começo do primeiro foco do último dia com foco, se esse dia foi há no máximo 3 dias.
   - Sem isso, vale o horário aprendido do hábito.
   - Sempre entre 8h e 21h.
2. **Escada com fim.**
   - O convite deixou de repetir todo dia para sempre.
   - Agora é um convite por dia de ausência, até o 6º dia; no 7º, a despedida: "Vou ficar quietinho. Não mando mais lembretes. Quando quiser voltar, {pet} vai estar aqui." Depois, silêncio.
   - É o mesmo fato da mensagem do Duolingo, sem a culpa.
   - Tudo é refeito a cada abertura do app, então a escada só chega inteira a quem sumiu.
   - O dia do recado de volta (D+2) fica sem convite.
3. **O recado aprende com a pessoa.** É o bandit do paper, no aparelho.
   - Cada modelo tem uma nota: taxa de acerto com prior 1/2, menos a penalidade γ·0,5^(d/15).
   - Acerto é abrir o app em até 3 h do horário: as 2 h do paper mais 1 h de atraso possível do alarme inexato.
   - γ = 0,15, e não o 0,017 do paper. O paper calibrou γ sobre milhões de envios; aqui são dezenas, de uma pessoa só, e com 0,017 o "melhor" de três envios repetiria todo dia.
   - Agendar a semana de uma vez não repete o texto em dias seguidos.
   - Os modelos de marco só concorrem na véspera do marco: são o braço "dormente" do paper.
   - O caderno fica só no aparelho (`baru_recados_v1`).
   - O convite passou de 3 para 5 textos.
4. **Rosto do bicho em toda notificação de recado,** como ícone grande. O ícone pequeno da barra é monocromático por regra do Android.
5. **Topo da tela.**
   - Convite e raiz em risco passaram para canais de importância alta, então descem do topo (heads-up).
   - Relatório, volta e conta continuam no padrão.
   - O volume não aumentou: continuam no máximo 2 por dia, com 3 h entre eles ("protect the channel").
   - Os canais antigos saem: a importância de um canal não muda depois de criado.
6. **Tela de bloqueio.** Os recados saem com visibilidade pública, porque são recados de hábito, sem segredo, e com a categoria `reminder`.
7. **Pedido de permissão.** O texto passou a falar em hábito: "Um lembrete por dia, no seu horário, para a pausa virar hábito." Foi o enquadramento que deu +5% no Duolingo.

### O que não entrou, e por quê

- **iOS (widget e Live Activity).** O app é Android primeiro, e não há alvo iOS de widget no projeto.
- **Widget 2x1 e tema escuro (Tier 1 completo).** Exige outro layout de `RemoteViews` por tamanho. Fica como próximo passo.
- **Bandit entre usuários.** Exige mandar contagens ao servidor, o que é decisão de produto, conforme o laudo 01, §9.5.
- **Notificação "time-sensitive" ou alarme exato.** Lembrete de pausa não se qualifica para `USE_EXACT_ALARM`.

## 6. Testes

- `test/recados_test.dart`: os 23,5 h, a escada, o aprendizado (acerto, penalidade, ida e volta pelo disco) e os textos nos 4 idiomas.
- `test/widget_tela_inicial_test.dart`: os cinco momentos, a regra de horário, nenhum bicho triste e o tamanho das imagens.
- **Em aparelho (pendente, roteiro):**
  1. Pôr o widget na tela, fechar o app, adiantar o relógio do aparelho para 12h, 18h e 23h e ver a troca.
  2. Concluir um foco e ver o "✓" ao sair do app.
  3. Ficar sem abrir o app e ver o convite descer do topo no horário.
