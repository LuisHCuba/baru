# Onda 4 — auditoria visual pelo simulador

Fonte: capturas do Playwright em `scratchpad/sim-412` (jornada completa), `sim-360` e `sim-320` (jornada curta). Ignorados: as 6 cenas repetidas de "cavar" (erro do script) e a ausência da tela de login (modo local).

## As 7 queixas do dono do produto

| # | Queixa | Veredito | Evidência |
|---|---|---|---|
| 1 | Espaçamento / aperto antes dos chips e do "Começar foco" | **Parcial.** Em 412 está resolvido. Em 360/320 piorou: a cena tem altura fixa e empurra a saudação, os chips e o CTA para baixo da dobra. | 412: 038, 041. 360: 038. 320: 037, 038, 084 |
| 2 | Raiz de 3 dias com os últimos dias sem pintar | **Não dá para verificar.** A simulação só chega a 1 dia. Hoje aparece pintado, mas a cor muda de tela para tela (ver D8). | 061, 092, 181 |
| 3 | Comemoração de missão estilo Duolingo | **Corrigido.** Raios, check, recompensas, "Colher agora" e "Colho depois". Sobra um vazio grande entre as recompensas e o CTA. | 096, 098 |
| 4 | Bicho "flutuando" no foco | **Parcial.** Tem habitat, borboleta, vaso com broto que cresce (058→088) e carinho funcionando (quadros/043). Problemas: a dica fica em cima da lua, o vaso é cortado na borda direita e há ~200px vazios entre a cena e o timer. | 057, 058, 085, 088; 320: 058 |
| 5 | Bicho triste após desistir; itens amadores | **Parcial.** A cena de desistência ficou neutra (091). Mas a home logo depois mostra o bicho de cara triste e a manchete "Uma sessão de 25min parou no meio hoje" (092, 320/084). Os itens agora têm arte (120, 054), mas várias miniaturas são só uma cena vazia com um detalhe minúsculo (Cogumelos, Vaga-lumes). | 091, 092, 120, 054 |
| 6 | Ajustes e permissões feios | **Majoritariamente corrigido.** Ajustes estão limpos (154–157). Permissões ainda alarmistas: "Não concedida" e "Sem ela:" em vermelho, como se fosse erro. | 033, 034, 154, 160 |
| 7 | Elementos desconexos, jornada fraca, crescimento difícil de acompanhar | **Parcial.** O cartão de estágio com silhueta e "Pipoca cresceu!" ajudam. Mas a celebração de crescimento sai apagada (D2), a Trilha não mostra o bicho e os habitats bloqueados usam a mesma miniatura da Lagoa. | 064, 136, 140, 141 |

## Outros defeitos, por severidade

### Alta

- **D1 — Chave de tradução crua na tela** (`181-endereco-sequencia-p0`): aparece "raizCompartilhar" como texto de botão. Na semântica também: "1 dias presente". **Correção:** adicionar a string no ARB, revisar o plural (`{n, plural, one{1 dia} other{# dias}}`) e incluir um teste que procure chaves camelCase visíveis.
- **D2 — Celebração de crescimento apagada** (`064-s1-cena1`, `136-s6-cena0`, quadros/065 q00): o título, "AGORA: FILHOTE/JOVEM", o texto e o botão "Continuar" ficam com ~50% de opacidade sobre o fundo marrom, e o resultado aparece por trás. É justamente o momento-chave do crescimento. **Correção:** o conteúdo precisa ficar acima do scrim com opacidade 1, e o fundo deve ser opaco ou ter blur.
- **D3 — CTA principal fora da tela em 360/320** (`sim-320/037`, `038`, `084`; `sim-360/038`): a cena ocupa ~60% da altura. Em 320 o texto do estágio é cortado ("abrir os ..."), e "Oi! Eu sou Pipoca" e "Começar foco" ficam invisíveis. **Correção:** altura da cena = `min(largura*0,9, altura*0,38)`, e chips + CTA sempre acima da dobra.
- **D4 — Home pós-sessão sem "Começar foco" visível** (412: `092`, `125`, `130`, `138`): depois da primeira sessão, a dobra mostra relatório e "Últimos 7 dias" (com as letras cortadas pela barra de navegação). Os chips e o CTA somem para baixo. **Correção:** manter chips + CTA logo abaixo do cartão de estágio em todos os estados da home.
- **D5 — Pronome errado** (`086`, `sim-320/078`): o bicho foi definido como Fêmea e o botão diz "Ficar com ele". O onboarding também diz "falar com ele" (001) antes de o sexo existir. **Correção:** usar `select` por sexo nas strings ("Ficar com ela/ele/Pipoca"). Sem sexo definido, usar o nome.
- **D6 — Folha de compartilhar presa e cena duplicada** (`194`, `195`, `197`): o "voltar" fecha a rota mas a folha continua aberta. Uma segunda cópia do habitat (a captura de 402×296) fica sobreposta à cena real. Há um console com "Null check operator used on a null value", e o seletor de idioma deixou de responder em seguida. **Correção:** fechar o modal no `PopScope`/voltar, renderizar a captura offstage e corrigir o null-check.
- **D7 — Espécies liberadas no onboarding e bloqueadas nos Ajustes** (`024`/`027` vs `166`): no onboarding dá para escolher Lontra, Tartaruga e Coruja. Nos Ajustes elas aparecem com cadeado "Abre no passo 7/8/17", e a lista nem está ordenada por passo (17 antes de 13). **Correção:** usar a mesma regra nos dois lugares e ordenar por passo de desbloqueio.

### Média

- **D8 — Cor do dia da raiz inconsistente** (`061` terracota com check, `092` bolinha verde sem check, `181` verde com check). **Correção:** um único componente `DiaDaRaiz`.
- **D9 — Monte de terra da escavação cortado reto embaixo** (`079`, `113`): meia elipse "flutuando" no meio da tela, com aparência amadora. "Nível 2" usado como título da escavação confunde dois eventos. **Correção:** desenhar o chão inteiro (faixa até a base) e separar a subida de nível da escavação.
- **D10 — Bicho triste na home após desistir** (`092`, `sim-320/084`): sobrancelhas de preocupação e boca para baixo, mais a manchete negativa. Contradiz o "nada foi perdido". **Correção:** expressão neutra ou sonolenta e manchete voltada para o próximo passo.
- **D11 — Missão com nome do app no lugar do bicho, e rótulo errado** (`sim-320/049`): "fique com o Baru até o fim" e "Toque em Focar", mas o botão se chama "Começar foco". **Correção:** "fique com {nome}" e "Toque em Começar foco".
- **D12 — Texto truncado nas missões** (`115`, `148`): "Precisa do acesso a…" em todas as missões bloqueadas. O primeiro cartão tem um layout diferente dos demais. **Correção:** quebrar em 2 linhas ou usar "Precisa de permissão" e um layout único.
- **D13 — Rolagem passa por baixo da barra de progresso** (`024`, `027`, `029`): o texto aparece atravessando os segmentos. A loja tem o mesmo problema sob o título fixo (`054`, borda de card solta). **Correção:** dar fundo opaco ao cabeçalho fixo.
- **D14 — Resultado em 320: título "MISSÕES QUE ANDARAM" órfão** (`sim-320/070`): o cartão fica escondido pelos botões fixos. Em `sim-320/033` o rodapé "Nada aqui é definitivo…" sai cortado no meio da linha. **Correção:** usar um fade ou sombra acima do rodapé fixo, ou rolar tudo junto.
- **D15 — Dica do foco sobre a lua; vaso cortado** (`057`, `085`, `sim-320/058`). **Correção:** mover a lua ou a dica e manter o vaso dentro de uma margem de 16px.
- **D16 — "Tudo feito por hoje" com missões ainda pendentes** (`115`): todas as restantes dependem da permissão, então a mensagem engana. **Correção:** "Feito o que dá sem o acesso ao uso".
- **D17 — Trilha sequencial confusa** (`143`): "3 sessões de foco" aparece pendente (ampulheta) com 5 sessões já feitas. As miniaturas de Igarapé e Manguezal são iguais à da Lagoa (`140`). **Correção:** mostrar o progresso real e arte própria para cada habitat.
- **D18 — Tela da loja intitulada "Habitat"** (`120`, `126`): o mesmo nome da aba e da cena. **Correção:** "Loja do habitat".
- **D19 — Folhas de baixo não escurecem a barra de navegação** (`166`, `170`, `174`, `195`): a nav continua clicável e clara sobre o scrim. **Correção:** usar `useRootNavigator: true`.

### Baixa

- **D20 — Perguntas do quiz sem "?"** (`006`, `020`). "2 dias seguidos presente" / "Faltam 2 dias para 3 dias seguidos presente" (`140`, `181`) soam errados. **Correção:** "2 dias seguidos de presença".
- **D21 — CTA "Começar foco" na tela de promessa do onboarding** (`004`): o toque não começa foco nenhum. **Correção:** "Vamos lá".
- **D22 — Nome padrão "Baru" = nome do app** (`022`), e o campo de nome não tem rótulo. "PELAGEM" está centralizado, enquanto "SEXO" e "PREFERE OUTRO?" estão à esquerda.
- **D23 — "Sua conta" repete o subtítulo** (`164`: "E-mail, senha e seus dados." duas vezes) e diz "no servidor" em modo local. "Refazer o onboarding" usa jargão em inglês (`157`); trocar por "Refazer a apresentação".
- **D24 — Ícone da raiz no chip da home parece um inseto** (`038`). Nos Ajustes, as linhas misturam itens com e sem ícone, e o alinhamento à esquerda fica irregular (`154`).
- **D25 — Grandes vazios verticais** no resultado (`083`, `192`), na desistência (`091`), na missão cumprida (`096`), nas permissões (`033`) e em "Sua conta" (`164`). **Correção:** centralizar o bloco na vertical ou aproximar o CTA.
- **D26 — Loja em 320** (`sim-320/053`): o chip "Dá para levar" encosta nas bordas e "O que só existe porque ali te…" sai truncado.
- **D27 — Faixa cinza-rosada horizontal atravessando a cena** e retângulo de sombra escuro sob o ninho ou os pés (`038`, `091`). Parecem bugs de camada, não arte. **Correção:** usar uma sombra elíptica suave e integrar a faixa à margem do lago.

---

## Situação das correções (2026-10-27)

Conferido com testes (cada correção de comportamento tem teste que falha no
código anterior) e com uma segunda rodada do simulador.

| Achado | Situação |
|---|---|
| D1 chave crua "raizCompartilhar" | Corrigido: o rótulo registra os textos antes de ler |
| D2 crescimento "apagado" | **Não é defeito**: o véu é 98% opaco; a captura pega o texto ainda entrando (o roteiro fotografa assim que o botão existe na árvore de semântica) |
| D3 CTA fora da tela em 360/320 | Corrigido: a cena da home encolhe até 40% da altura |
| D4 "Começar foco" some depois da 1ª sessão | Corrigido: o bloco de foco vem logo depois da fala, em qualquer dia |
| D5 "Ficar com ele" / "falar com ele" | Corrigido: "Continuar o foco", "Em que idioma vamos conversar?"; sem sexo dito, pt/es usam o nome |
| D6 folha de compartilhar presa + "Null check" | Corrigido nos três caminhos do voltar; na 2ª rodada, **0 erros no console** (a pilha apontava para a semântica do Flutter Web com a folha sobre uma página removida) |
| D7 espécies travadas fora de ordem | Ordenadas pelo passo que abre. Que as espécies de origem não escolhidas voltem a travar é regra de produto, não defeito |
| D8 cor do dia da raiz | Não tratado |
| D9 escavação | **Refeita do zero**: corte de terra com o bicho cavando, pote de barro, túnel, luz subindo (24681cc) |
| D10 bicho triste após desistir | O humor segue o contrato (§3, ADR-020); a cara de saudade virou "olhar pidão" em vez de emburrada (c752f48) |
| D11 "fique com o Baru" / "Toque em Focar" | Corrigido |
| D12 "Precisa do acesso a…" truncado | Até 2 linhas |
| D13 rolagem sob a barra do onboarding | Espaço entre a barra e o conteúdo; o cabeçalho da loja não foi mexido |
| D14 resultado em 320 | Pé da rolagem esmaecido; bicho menor em tela baixa |
| D15 dica sobre a lua; vaso cortado | Corrigido |
| D16 "Tudo feito por hoje" enganoso | Texto próprio quando o resto depende da permissão |
| D17 trilha | Não tratado (progresso sequencial e miniaturas iguais) |
| D18 loja chamada "Habitat" | "Loja do habitat" |
| D19 folhas não cobrem a barra de abas | Não tratado: a barra fica fora do único `Navigator` do app; exige mudar a estrutura da casca |
| D20 "dias seguidos presente" | Corrigido; perguntas do quiz sem "?" não tratadas |
| D21 CTA da promessa | "Continuar" |
| D22, D24, D26 | Não tratados |
| D23 "Sua conta" e "Refazer o onboarding" | Corrigidos ("Refazer a apresentação") |
| D25 vazios verticais | Parcial (escavação e cena da missão) |
| D27 faixa/sombra retangular | Sombra do bicho virou elipse nos pés, e some na água |
