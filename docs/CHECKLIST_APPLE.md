# Checklist de envio à App Store — LHCX (Baru, Ecoin, Deixa)

A conta Apple Developer é uma só (time PHV3N8AFK4) para os três apps. Cada
recusa conta contra a conta inteira: depois de muitas recusas seguidas a Apple
passa a fazer revisão estendida e avisa que pode remover a conta do Developer
Program. **Perder a conta derruba os três apps.**

Regras de uso deste checklist:

- Nenhum envio à revisão (App Store ou revisão beta do TestFlight) sem passar
  por **todos** os itens abaixo. Item que não se aplica: escrever "n/a" e o
  porquê.
- O Luis aprova cada envio. A mensagem de pedido lista o que foi conferido.
- Depois de uma recusa: ler a mensagem inteira, corrigir a causa no app ou na
  página da loja, **responder à Apple** e só então reenviar. Nunca marcar como
  resolvido e reenviar o mesmo build sem mudança real.
- Recusa de conceito ou design (4.3 spam, 4.2 funcionalidade mínima): não
  reenviar o mesmo build. Responder explicando o que o app tem de único e,
  se a Apple mantiver, recorrer ao App Review Board.
- Build e publicação só neste Mac (nunca GitHub Actions).
- Segredos (chave da API, certificado, senhas de contas de teste) ficam no
  Infisical LHCX_CENTRAL. Nada em arquivo solto, nada impresso em log.

---

## 1. O build

- [ ] Versão e número de build novos (o número nunca se repete).
- [ ] Compilado em modo release, neste Mac, com o certificado e os perfis
      App Store da LHCX (Infisical).
- [ ] Assinatura conferida em cada parte com
      `codesign -d --entitlements :- <app ou .appex>`: o app **e cada
      extensão** têm os entitlements que o código usa (Family Controls, App
      Groups, Sign in with Apple, push, etc.).
- [ ] Cada bundle ID (app e extensões) tem as capacidades ligadas no portal,
      inclusive as que dependem de aprovação da Apple (ex.: Family Controls
      **Distribution**). Os perfis App Store foram gerados **depois** disso.
- [ ] Extensões no formato certo (ex.: DeviceActivityReport como ExtensionKit,
      em `Extensions/`).
- [ ] `ITSAppUsesNonExemptEncryption` definido no Info.plist.
- [ ] Só iPhone, se o app não foi pensado para iPad (senão a Apple exige
      capturas e revisão de iPad).
- [ ] Ícone sem transparência e sem o ícone padrão do Flutter; tela de
      abertura com a marca.
- [ ] O app abre do zero em aparelho/simulador limpo, sem travar, sem tela
      branca e sem depender de nada só de desenvolvimento.
- [ ] Endereços de volta (deep links do login com Google/Apple) registrados
      no Info.plist (`CFBundleURLTypes`) e testados.

## 2. Login e conta de teste

- [ ] Se o app tem login com Google (ou outro login de terceiros), tem
      **Entrar com a Apple** no mesmo destaque (diretriz 4.8).
- [ ] Conta de teste do revisor criada, com a senha no Infisical, e **login
      testado** com ela antes do envio.
- [ ] A conta de teste tem **acesso total**: plano ou cortesia ativa, sem
      paywall, sem "seu teste acabou", sem passo que dependa de e-mail ou SMS.
- [ ] A conta de teste já está no estado que mostra os recursos sensíveis
      (ex.: Baru: criança numa família de teste com localização ligada;
      Ecoin: espaço com dados de exemplo; Deixa: roteiro pronto).
- [ ] Mesmos dados em "Revisão do app" (App Store) e na revisão beta do
      TestFlight.
- [ ] Excluir a conta pelo próprio app funciona (5.1.1(v)).

## 3. Instruções ao revisor (notas da revisão)

- [ ] Em inglês, curtas, com o caminho exato até cada recurso que usa
      permissão sensível ou API especial (ex.: "Settings > Family").
- [ ] Explicam as APIs especiais e as aprovações (ex.: Family Controls
      Distribution, pedido GCCF4RXN4U).
- [ ] Contato: Luis Cuba, adm@lhcx.tech, telefone da empresa (ERP).
- [ ] Se houver recurso difícil de ver, link de vídeo de demonstração.

## 4. Permissões e privacidade

- [ ] Toda permissão pedida tem texto de uso claro no Info.plist (câmera,
      microfone, fala, fotos, localização "quando em uso" e "sempre",
      notificações, Screen Time).
- [ ] Antes de cada pedido do sistema, uma tela do app explica o porquê e tem
      **um botão só que sempre leva ao pedido** (5.1.1(iv)). O aviso de
      "vá aos Ajustes" aparece só depois que a pessoa nega.
- [ ] Nenhuma permissão pedida sem uso real no app.
- [ ] Dados enviados a terceiros (IA, mapas, análise) pedem permissão
      explícita antes do primeiro envio e dizem o que vai e para quem
      (5.1.1(i) e 5.1.2(i)).
- [ ] Questionário de **Privacidade do app** atualizado com tudo que o app
      coleta (localização, contatos, áudio, dados financeiros…) e publicado.
- [ ] Política de privacidade no site atualizada **antes** do envio, com o
      mesmo conteúdo do questionário.

## 5. Pagamento e assinatura (3.1.1 e 3.1.3)

- [ ] O app não vende nada fora da compra dentro do app: sem preço, sem
      checkout, sem botão, link ou texto mandando assinar no site.
- [ ] Termos, privacidade e ajuda abertos de dentro do app também não
      mostram planos nem loja (modo app, ex.: `?app=ios`).
- [ ] Se o app libera recursos pagos comprados no site, a resposta para a
      pergunta 2.1(b) da Apple (quem compra, onde, o que libera) está pronta
      e bate com o app.

## 6. Página da loja

- [ ] Nome, subtítulo, descrição e capturas mostram o que o app **faz de
      diferente**, não só a categoria (evita 4.3 spam). O recurso principal
      aparece na primeira captura.
- [ ] Capturas de iPhone 6,9" (1320 × 2868) reais do app, sem moldura de
      Android e sem texto sobre outras plataformas.
- [ ] Nada na descrição que o build não tenha (recurso prometido = recurso
      testável).
- [ ] Sem emoji na descrição (a Apple recusa os caracteres).
- [ ] Palavras-chave sem marcas de terceiros.
- [ ] Categoria, classificação etária (com controle parental, saúde etc.
      quando for o caso), direitos de conteúdo, preço e países conferidos.
- [ ] Conformidade do app: nenhum formulário pendente (China continental fica
      fora sem licença ICP).

## 7. Antes de clicar em enviar

- [ ] Todos os itens acima marcados ou com "n/a" justificado.
- [ ] Lista do que foi conferido mandada ao Luis e **ok dele**.
- [ ] Um envio por vez por app; nada reenviado enquanto houver resposta da
      Apple pendente.

## 8. Depois do envio

- [ ] Acompanhar a revisão pela App Store Connect, não pela memória: o estado
      real vem de `reviewSubmissions` e das mensagens.
- [ ] Recusa: registrar no repositório (data, diretriz, texto da Apple, o que
      foi corrigido, resposta enviada), como em
      `ecoin-app/app-store/resposta-apple-2026-11-21.txt`.

---

## Específico de cada app

**Baru** (`tech.lhcx.baru` + extensões `.monitor`, `.relatorio`, `.escudo`,
`.escudo-acao`)
- Family Controls Distribution nos 5 bundle IDs; App Group nas que leem dados
  compartilhados.
- Conta de teste: e-mail em `/baru-ios/BARU_CONTA_REVISAO_APPLE_EMAIL` (senha em
  `/baru-ios/BARU_CONTA_REVISAO_APPLE_SENHA`), cortesia vitalícia, criança na
  "Família de revisão" com localização ligada.
- Histórico: 1.0 recusado por Family Controls (contestado, binário estava
  certo) e por 4.3(a) spam em 21/11 (respondido, aguardando).

**Ecoin** (`tech.lhcx.ecoin`)
- IA de terceiros: tela de permissão antes do primeiro envio; política de
  privacidade com a seção da IA.
- Assinatura só no site; no iOS a tela "Seu plano" só mostra o plano atual.
- Conta de teste com plano Completo (senha no Infisical).
- Histórico: 4 envios concluídos entre 19 e 20/11; 1.1.3 (build 114)
  reenviado em 21/11 com resposta sobre 5.1.1(i), 5.1.2(i) e 2.1(b).

**Deixa** (`tech.lhcx.deixa`, app nativo SwiftUI em `deixa/ios`)
- Câmera e microfone: tela antes do pedido com um botão que sempre leva ao
  pedido do iOS.
- Sem plano, uso de espaço ou assinatura no app; termos e privacidade em
  `?app=ios`.
- Histórico: 1 recusa (5.1.1(iv) e 3.1.1) corrigida em 20/11; 1.0 aguardando
  revisão.
