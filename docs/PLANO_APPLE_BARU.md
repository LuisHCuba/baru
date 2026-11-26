# Plano: Baru de volta à App Store sem nova recusa

Escrito em 21/11/2026. Vale até o Baru ser aprovado. Regras gerais em
[CHECKLIST_APPLE.md](CHECKLIST_APPLE.md).

## Onde estamos

- Baru 1.0 (build 15) **recusado** em 21/11 por 4.3(a) Spam, com o aviso de
  revisão estendida. Antes, em 19/11, uma recusa automática por Family Controls
  (falso alarme, contestado).
- Resposta sobre a 4.3 enviada em 21/11 às 14h39. **Aguardando a Apple.**
- A conta tem 5 recusas no total (Baru 2, Ecoin 2, Deixa 1). Mais uma recusa
  agora pesa muito. Regra: um envio por vez na conta inteira e nada reenviado
  sem corrigir a causa.


## Atualização 25/11/2026: resposta da Apple de 23/11

A Apple **não repetiu a 4.3 (spam)**: a explicação foi aceita. Ficaram dois pontos:

1. **2.5.4 (localização em segundo plano)**: o Info.plist pedia o modo "location"
   em segundo plano, mas o app só usa mudança significativa, visitas e cerca.
   **Resolvido no código (25/11)**: o modo saiu do Info.plist e o app não liga
   mais o rastreio contínuo. Vale no próximo build.
2. **3.1.1 (compra dentro do app)**: código pronto em 25/11, ainda não publicado.
   - ✅ `loja-assinatura` aceita `{ loja: 'apple', jws, laco? }`: confere a
     assinatura da Apple (biblioteca oficial, raiz G3 fixada) e grava com os
     nomes de produto da Google, sem mudar o banco.
   - ✅ `loja-apple-notificacoes` (renovou, cancelou, reembolso) + tabela
     `baru_apple_notificacoes` (migration 20261125120000).
   - ✅ App pede os 5 planos no iPhone e manda o JWS ao servidor.
   - ✅ `ios/Baru.storekit` (loja de teste local). O Xcode não aplicou o arquivo
     quando o app foi rodado por comando; testar abrindo pelo próprio Xcode
     (Product › Run) ou ir direto para o sandbox.
   - ✅ (25/11) Publicado no Supabase do Baru: loja-assinatura v7,
     loja-apple-notificacoes v1 e a tabela baru_apple_notificacoes. Teste:
     sem login → 401; aviso vazio → ignorado; aviso falso → assinatura inválida.
     URL de avisos para a App Store Connect:
     https://slqpuppkapiewjqvedtj.supabase.co/functions/v1/loja-apple-notificacoes
   - ⏳ Criar na App Store Connect o grupo "Planos do Baru" com os 5 produtos
     (ids abaixo) e cadastrar a URL de notificações. Preços: decisão do Luis.
   - ⏳ Compra de teste no TestFlight num iPhone, depois checklist e reenvio.

   Ids: tech.lhcx.baru.mensal, tech.lhcx.baru.anual,
   tech.lhcx.baru.familia.mensal, tech.lhcx.baru.familia.anual,
   tech.lhcx.baru.familiamais.mensal.


### Ficha da App Store: ✅ trocado em 25/11 (com o ok do Luis), conferido lendo de novo

Hoje a ficha leva o revisor aos planos vendidos no site, o mesmo caminho que a
Apple apontou na 3.1.1 do Deixa:

| Campo | Hoje | Trocar para |
|---|---|---|
| URL de suporte (3 idiomas) | https://meubaru.com/ (preços e botão para assinar no painel, Asaas) | https://meubaru.com/ajuda/ |
| URL de marketing (3 idiomas) | https://meubaru.com/ | https://meubaru.com/ajuda/ |
| Política de privacidade (3 idiomas) | https://meubaru.com/privacidade/ (fala de Asaas e CPF) | https://meubaru.com/privacidade/ios/ |
| Descrição | "Tudo também pelo site meubaru.com, no painel do responsável." | tirar a linha (en e es também) |

As três páginas novas estão no ar desde 25/11 (sem preço, sem Asaas, sem
link para o painel). No app, só no iPhone, os termos e a privacidade já citam
/termos/ios e /privacidade/ios.

## Os dois problemas

### 1. A loja apresenta o Baru como "mais um app de foco com bichinho" (4.3)

O nome "Baru: Focus Capybara", o subtítulo ("Foco e tempo de tela sem culpa"),
as palavras-chave (pomodoro, bichinho, capivara) e a abertura da descrição
colocam o Baru na mesma prateleira de dezenas de apps: Capybara Focus,
Happy Capy, Mochi Pets, StayPaws, FocusPet, Shinka, Focus Pet, Time Farm.
O que só o Baru tem (controle dos pais pelo Tempo de Uso com quatro extensões,
painel do responsável no site, localização com lugares e SOS) aparece na
metade da descrição.

### 2. A cobrança no iPhone fere a regra de pagamento (3.1.1 e 3.1.3)

A cobrança está ligada desde 30/10/2026 (`baru_cobranca.ligada_em`). Depois de
7 dias de teste, o app trava (`TesteEncerradoScreen`, chamada em
`lib/auth_gate.dart`) e o único caminho é um botão que abre o site, onde a
assinatura é paga pelo Asaas (Mensal R$ 12,90, Anual R$ 99,90). É o mesmo
problema que derrubou o Ecoin. O revisor usa conta de cortesia e ainda não viu
essa tela, mas é a próxima recusa provável.

Hoje não há assinante pagante (só 1 mensal cancelada), então mudar a cobrança
não afeta ninguém.

## O que fazer, em ordem

### Fase 0. Esperar a resposta da Apple (agora)

- Não reenviar nada. Não mexer na versão em revisão.
- Quando a Apple responder: ler a mensagem inteira com o Luis antes de agir.
- Se a Apple aprovar a 4.3 com a explicação, **ainda assim não publicar** antes
  da Fase 1: o problema de pagamento continua no build 15.

### Fase 1. Compra dentro do app no iPhone (mesmo modelo do Ecoin)

1. **Decisão do Luis:** preço no iPhone. Sugestão: igual ao site (Mensal
   R$ 12,90 e Anual R$ 99,90, ambos existem na tabela da Apple), como foi
   decidido no Ecoin.
2. Criar o grupo de assinaturas "Planos do Baru" na App Store Connect:
   `tech.lhcx.baru.mensal` e `tech.lhcx.baru.anual`. Depende do Acordo de apps
   pagos, impostos e banco (tarefa 2 do projeto Apple no ERP).
3. App: tela de planos no iPhone com preço da Apple, assinar, restaurar e
   gerenciar, texto de renovação automática, termos e privacidade
   (copiar o padrão de `ecoin-app/lib/features/planos/planos_iphone.dart` e
   `compra_apple.dart`).
4. A tela de fim do teste no iPhone passa a abrir essa tela de planos. **Sem
   link nem menção ao site** no iPhone (nem em ajuda, termos ou e-mails abertos
   pelo app).
5. Servidor (Supabase do Baru): tabela de assinaturas da Apple, `baru_meu_acesso`
   passa a considerar a Apple, funções para registrar a compra e receber as
   notificações da App Store (copiar o padrão do Ecoin: biblioteca oficial da
   Apple e certificado raiz G3 fixado).
6. ✅ (25/11) Conta do revisor (revisao.apple@meubaru.com) conferida no banco: cortesia, sem assinatura do site nem da loja. A cortesia não conta como paga, então "Sua conta" mostra "Assine o Baru" e a tela de assinatura mostra o botão de compra.
7. Testar uma compra completa na loja de testes da Apple (sandbox) pelo
   TestFlight: assinar, renovar, cancelar, restaurar, plano liga e desliga.

### Fase 2. Página da loja nova, centrada no modo família

Tudo abaixo precisa bater com o que o app mostra: o revisor confere.

- **Nome (decisão do Luis).** Sugestões, mantendo a marca:
  - "Baru: Tempo de Tela da Família"
  - "Baru: Controle dos Pais"
  - "Baru: Família e Tempo de Tela"
  Tirar "Focus Capybara".
- **Subtítulo:** algo como "Metas de tela para seus filhos".
- **Palavras-chave:** controle parental, tempo de tela, filhos, família,
  limite de uso, bloqueio de apps, localização, horário sem tela. Tirar
  pomodoro, bichinho e capivara.
- **Descrição:** abrir com o modo família (responsável liga o iPhone do filho
  com um código, metas por dia, horários sem tela, pausa na hora, aviso, painel
  no site, localização com lugares e SOS). O bichinho e o foco entram depois,
  como o jeito de a criança cumprir a meta.
- **Capturas (6,9"):** a primeira mostra o painel do responsável com o filho;
  depois metas e horários, tela de pausa no iPhone da criança, mapa da família,
  e só então o habitat e o bichinho.
- **Categoria:** principal Estilo de vida; considerar Utilidades ou manter
  Produtividade como secundária (não usar Infantil).
- O app em si: o primeiro uso já pergunta "para mim, para o celular do meu
  filho, ou como responsável" (`_PerfilDeUso`). Conferir que o caminho do
  responsável aparece em destaque e funciona com a conta de revisão.

### Fase 3. Se a Apple mantiver a 4.3

- Recorrer ao **App Review Board** (formulário de recurso), com:
  - o que é exclusivo do Baru (lista da Fase 2), com prints;
  - código e arte 100% próprios (9 personagens, animações e sons feitos pela
    LHCX; repositório desde 26/08/2026, 200+ commits);
  - uma conta Apple só, sem apps parecidos em outras contas;
  - vídeo curto do modo família funcionando.
- Pedir uma conversa com a App Review (App Review appointment), se disponível.
- Só depois disso, e com a Fase 1 e a Fase 2 prontas, um **novo build** com a
  página nova. Nunca o build 15 de novo.

### Fase 4. Antes de enviar

- Checklist inteiro (`CHECKLIST_APPLE.md`), sem item em aberto.
- Nenhum outro app da conta em revisão no mesmo momento.
- Ok do Luis por escrito, com a lista do que foi conferido.

## Decisões que são do Luis

1. Preço do Baru no iPhone (sugestão: igual ao site).
2. Nome novo da loja (sugestões na Fase 2).
3. Se recorremos ao App Review Board caso a Apple mantenha a 4.3.

## Fora deste plano (anotar e tratar depois)

- No Android, o app também trava depois do teste e manda para o site. A Google
  Play exige o faturamento dela para assinatura digital. Tratar em plano
  próprio, depois do iPhone.
