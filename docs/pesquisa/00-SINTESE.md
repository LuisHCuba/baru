# Síntese da pesquisa e plano de execução — outubro de 2026

Nove laudos (`01` a `09` nesta pasta, ~10 mil linhas, fontes citadas em cada
um) leram o app inteiro, as capturas atuais e a concorrência. Este documento
junta o que eles dizem, decide onde discordam e fixa a ordem de execução.
Cada item construído passa por **auditoria independente** (um agente que não
escreveu o código, com o laudo e o critério de aceite na mão) antes de
entrar no `main`.

## O que os laudos concordam (achados de 3 ou mais laudos)

1. **A "saudade" lê como raiva.** A pálpebra e a sobrancelha de tristeza não
   são espelhadas entre os olhos (`pet.dart:3605-3625`): um olho triste, o
   outro bravo, nas 9 espécies. A lágrima fica num ponto fixo do quadro e cai
   fora do rosto. E a cara triste aparece até depois de desistir de uma
   sessão (`result_screen.dart:27`). [03, 06, 07, 08, 02]
2. **O bicho não cresce.** Não existe estágio de vida no código. [02, 05, 06, 07, 08]
3. **A sobreposição desenha um bicho genérico** em Kotlin, com orelha de
   mamífero até no pinguim e no axolote; o widget da tela inicial já sabe
   rasterizar o `PetView` real em PNG — é o caminho. [02, 03, 05, 07]
4. **O momento de recompensa é mudo e estático**: fim de sessão, compra,
   coleta de missão, nível. [01, 03, 04, 05, 09]
5. **Quatro linguagens visuais misturadas**: bicho chapado, cenário abstrato,
   73 ícones Material genéricos, cartões em quatro tintas; a folha tem 4
   desenhos e 3 cores. [03, 05]
6. **Sons sem identidade**: 6 de 7 são dois senos puros, 5 tonalidades
   diferentes, o mais importante (fim de sessão) é dos mais baixos; e o app
   provavelmente **pausa a música da pessoa** a cada som. [04]

## Decisões (onde os laudos divergiram)

| Assunto | Decisão | Por quê |
|---|---|---|
| Régua do crescimento | **Sessões de foco concluídas com aquela espécie** ("sessões juntos"), estágios em **0 / 1 / 5 / 15 / 40** sessões. Nunca regride, nunca se compra. | A trilha (06) não serve: a raposa abre no passo 22 e nasceria adulta. XP (05) mistura fontes. Sessões é o que a pessoa entende ("cresceu porque eu foquei") — 07 e 08 chegaram a isso sozinhos. Limiares a calibrar com dados reais. |
| O "ovo" | Coruja, pinguim, tartaruga e axolote: **ovo**. Capivara, lontra, gata, raposa, buldogue: **recém-nascido de olhos fechados no ninho** (05, 06, 08: realismo). A 1ª sessão concluída **choca/acorda** o bicho, numa cena própria. | Pedido explícito do dono ("a coruja começa em um ovo") e biologia. |
| Último estágio | **"Pleno"** (adulto no auge), nunca idoso. | Bicho visivelmente velho conflita com "nunca morre" (08). |
| Contas existentes | Na migração, cada espécie já liberada recebe como "sessões juntos" o total de sessões concluídas da conta. | O app está em teste interno (sem público), então ninguém perde um adulto que tinha; quem já usa vê o estágio real do bicho. Registrar em ADR. |
| Tecnologia do bicho | **CustomPainter procedural continua sendo a fonte única** (05). Rive fica para um piloto futuro (03), não agora. | Sem animador humano; uma segunda fonte de verdade duplicaria cada correção. |
| Sobreposição | Dart rasteriza quadros do `PetView` real (espécie, pelagem, roupa, humor, estágio) ao iniciar a sessão; Kotlin anima respiração e piscar com esses quadros; o desenho genérico vira só reserva. (02, 03, 05, 07) | Sem segunda engine Flutter (frágil no Android 15); sem portar o painter para Kotlin. |
| Raiz (ofensiva) | Segue contando só sessão concluída nesta etapa. "Foco de 10 min conta" (01-U3) e "raiz adormecida" (01-U5) mudam regra de produto: ficam para decisão do dono. | Não mudar contrato sem o dono. |
| Espécies redesenhadas | Coruja-buraqueira, pinguim-de-magalhães, axolote com cauda e guelras plumosas, raposa com marcas brancas, tartaruga → tracajá (06, 07, 08). **Entram por espécie, cada uma auditada**; as chaves internas (`owl`, `tortoise`…) não mudam. | Coerência biológica e diferença de silhueta (lontra e capivara coincidem 83%). |

## Ordem de execução

### Onda 1 — correções de alto retorno (pequenas, sem decisão pendente)
1. **Humores**: espelhar sobrancelha e pálpebra, sobrancelha "pidona" na
   saudade, lágrima ancorada no rosto (ou fora), sem pelo escurecido, sem cara
   triste após desistir. Aceite: golden por espécie com as pontas internas das
   duas sobrancelhas acima das externas na saudade. [03 R-V1, 06 R1, 07 R3, 08 R1]
2. **Som não pausa a música**: `AudioContext` de efeito (sem foco de áudio),
   respeita modo silencioso. [04 #1]
3. **Faixa da semana**: hoje vira ✓ na hora; últimos 7 dias em vez de semana
   que zera na segunda. [01 U4]
4. **`proximoItem`** sugere o item mais barato disponível. [09 R4]

### Onda 2 — os pedidos explícitos do dono
5. **Bicho real na sobreposição** (item 7 do dono). [05 R2]
6. **Estágios de crescimento** (item 6): dado, 5 estágios × 9 espécies no
   painter, cena de eclosão/evolução, barra "falta X sessões para crescer" na
   home, nada regride. [02 R1, 05 R1, 06–08]
7. **Cena "raiz cresceu hoje"** e marcos de raiz celebrados (estilo ofensiva
   do Duolingo, sem culpa). [01 U1/U2]
8. **Fim de sessão em sequência**: folhas voando até o saldo, XP, raiz,
   missões prontas, fecho "Dia feito"; colher todas as missões de uma vez;
   compra celebrada. [01 U7/U11/U12, 05 R7/R8, 09 R1/R3]
9. **Identidade sonora**: uma tonalidade, madeira/água/folha, hierarquia,
   eventos mudos ganham som, variações, háptico casado, voz por espécie.
   Produção com ElevenLabs + síntese. [04]

### Onda 3 — visual e vida
10. **Sistema visual**: glifo único de folha/raiz/XP, paleta semântica com
    contraste AA testado, botão 3D único. [03 R-V2/3/4]
11. **Redesenho de espécies** e humores pelo corpo (orelha, cauda, postura),
    gestos ociosos por espécie, amplitude de respiração legível, transição de
    humor. [03 R-V6, 05 R4–R6, 06–08]
12. **Notificações**: canais por tipo, nada em dia já cumprido, textos que
    variam, deep link para a tela certa. [01 U14–U16]

### Onda 4 — jornada e economia (depois)
Diário do bicho pós-trilha [08 R11], banca do dia e coleções [09 R7/R8],
bosque como sumidouro [09 R11], ícones próprios [03 R-V5], habitat em
camadas [03 R-V8], nomes de trilha por espécie [06–08].

## Pendências para o dono decidir
- Raiz cresce com foco de 10 min ou com o descanso cumprido? (01 U3)
- "Raiz adormecida" com replantio por esforço no lugar de quebra? (01 U5)
- O plano pago promete "a loja completa" (`l10n.dart:884`), mas nada restringe
  a loja: o que a assinatura entrega? (09)
- Trocar a tartaruga-de-orelha-vermelha (invasora no Brasil) pelo tracajá?
  Tratado aqui como redesenho visual, mas o nome "tartaruga" fica.
