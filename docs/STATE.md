# Estado — 2026-10-30, fim do turno

Branch: `develop`, **5 commits à frente de `main`** | Build: **verde**
Google Play: **1.0.3 (código 4) em produção, 100%**, na revisão do Google.

| Portão | Resultado (execução real, hoje) |
|---|---|
| `flutter analyze` | **No issues found** (3,6 s) |
| `flutter test` | **1244 passando, 26 pulados** (era 460 no retrato anterior) |
| `flutter build appbundle --release` | **app-release.aab, 65,1 MB**, assinado com a chave de upload (SHA-1 `CC:29:72:A5:…:E4:3C`) |
| Publicação | código **4** na faixa `production`, 100% — confirmado pela Developer API |
| Schema remoto | as **20 migrations** do repositório respondem na sonda REST, inclusive `baru_cobranca` e `baru_assinaturas` |
| Edge Functions | `asaas-assinatura` (v8) e `asaas-webhook` (v6), ambas **ACTIVE** |
| `flutter test test/integration` | não rodou neste turno (precisa de Docker e do stack local) |

## O que mudou de status desde o retrato de 2026-08-27

As três frases que o documento antigo repetia e que **deixaram de ser verdade**:

- **"Ainda não publicável."** É publicável e está publicado. A keystore existe
  fora do repositório, `android/app/build.gradle.kts` aponta o `signingConfig`
  de release para ela e cai no debug só quando o `key.properties` falta.
- **"O banco remoto está atrás do repositório."** Não está mais. A sonda de
  hoje achou `baru_app_categories`, `baru_progression` com
  `missoes_resgatadas` e `dias_abaixo_na_semana`/`semana_de`,
  `baru_inventory_items.equipped` e `baru_settings.som`. Os bloqueios BL-10,
  BL-12 e BL-16 de migration estão vencidos.
- **"Trial e planos existem só localmente."** Existe cobrança de verdade: 7
  dias grátis e assinatura mensal ou anual comprada no site, com o direito de
  acesso decidido pelo servidor (`baru_meu_acesso`), nunca pelo aparelho.

## Abra o app e você vê

Frases que são verdade hoje e não eram no retrato anterior:

- **Continuar com Google** na tela de entrar e na de criar conta, nos 4
  idiomas. Abre o navegador e volta por `tech.lhcx.baru://login-callback`.
- **7 dias grátis e depois assinatura.** Quando o teste acaba o app mostra uma
  tela **neutra, sem preço** — ele só pergunta ao servidor se há acesso. A
  compra acontece no site, e `baru_cobranca.ligada_em` mantém tudo liberado
  até a cobrança ser ligada de fato.
- **Pausas ao longo do dia** (ADR-028): o app lê 7 dias de uso, acha as horas
  em que a tela mais prende e as maratonas de 20 min, e chama para descansar
  nesses momentos — até 3 por dia, entre 9h e 21h. Hora ignorada perde peso.
- **Notificações animadas**: o companheiro respira e pisca dentro do recado,
  em cenário de acordo com o assunto e na luz da hora em que toca.
- **Widget na tela inicial** no padrão dos apps de hábito, em dois tamanhos na
  lista do Android, e ícone próprio na barra de notificação.
- **Rastro do carinho embaixo do dedo**, e a festa interrompe o episódio: se o
  bicho estiver comendo ou pastando, ele larga e pula.
- **Excluir a conta cancela a assinatura no Asaas** antes de apagar o dado.

E segue valendo tudo o que o retrato anterior listou: botão voltar que
funciona, trilha como caminho, "Sua conta", quiz uma pergunta por tela,
apagar meus dados, carinho no bicho, habitat por hora do dia, tempo de tela
por categoria, trilha, missões, celebração de nível.

## Pronto e funcionando

- Flutter 3.44 · 1244 testes · 4 idiomas (pt, en, es, zh).
- Design system em código: tokens de cor, espaço, raio, elevação, tipografia;
  movimento com durações nomeadas e curvas com física.
- Backend: 19 tabelas com RLS, schema reproduzível do zero, 20 migrations.
- Cobrança: duas Edge Functions no ar, webhook do Asaas, direito de acesso no
  servidor.
- Publicação por API: `~/lhcx/tools/play-publicar.py` sobe o AAB sem navegador
  (conta de serviço `play-publisher@baru-513221`).

## Em andamento

Nada pela metade. Os portões fecharam verdes antes da publicação.

**Próximo passo exato:** **testar o login com Google num aparelho**, com a
build da loja quando a revisão liberar. A configuração das duas pontas — status
"Em produção" no Google Auth Platform e `tech.lhcx.baru://login-callback` na
lista de redirects do Supabase — foi fechada hoje, depois do AAB; nada disso
vive dentro do app, mas também nada disso foi exercido por uma pessoa de
verdade.

## Próximos itens da fila

1. **Login com Google em aparelho** — o único caminho novo não exercido.
2. **Ligar a cobrança** (`baru_cobranca.ligada_em`) quando os planos estiverem
   publicados no site; até lá todo mundo segue liberado.
3. **Estágios de habitat visíveis** (C-03) — o dado existe e a cena ignora.
4. **Relatório usando o histórico de sessões** (C-07).
5. **Onboarding e paywall no design system** (C-05).

## Riscos e dívidas conhecidas

- **O login com Google nunca rodou num aparelho.** Se estiver quebrado, o
  estrago é o botão do Google falhar; e-mail e senha continuam funcionando.
- **Pagamento fora da loja é a aposta mais arriscada do produto.** A Google
  Play exige o faturamento dela para bens digitais vendidos *dentro* do app; a
  tela neutra sem preço e sem link de compra é exatamente o que mantém isso
  dentro da política. Qualquer preço, botão de assinar ou link para o site
  nessa tela tira o app da loja.
- **Não se sabe daqui se o Asaas está em sandbox ou produção.** O
  `_shared/asaas.ts` usa `ASAAS_API_URL` com padrão de produção, mas o valor
  real é segredo da Edge Function. A sonda anônima em `baru_cobranca` devolve
  vazio — pode ser tabela vazia ou RLS; não dá para concluir sem login.
- **Nada deste turno foi verificado em aparelho** além do que a loja aceitou.
- **A permissão de tempo de tela nunca rodou contra o Android real.**
- **Economia autoritativa no cliente** — folhas e XP decididos no aparelho.
- **`AppState` passou de 1200 linhas.** Concentra domínio, plataforma e
  persistência.
- **Suíte de integração não rodou neste turno** (precisa de Docker).

## Bloqueios para o humano

Os de migration venceram. O que sobra está em [BLOCKERS.md](BLOCKERS.md), e o
que importa hoje é verificação em aparelho (BL-09, BL-12, BL-14, BL-15, BL-16)
mais os itens de conta: senha vazada desligada (BL-03), usuário de teste sem
e-mail confirmado (BL-04) e entitlement de Screen Time no iOS (BL-06).

## Comandos para rodar e validar agora

```
cd baru_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Publicar uma versão nova (o `--publicar` precisa ser você — o modo automático
do agente bloqueia):

```
flutter build appbundle --release
~/.local/share/lhcx-play-venv/bin/python ~/lhcx/tools/play-publicar.py baru --so-conferir
~/.local/share/lhcx-play-venv/bin/python ~/lhcx/tools/play-publicar.py baru \
  --aab baru_app/build/app/outputs/bundle/release/app-release.aab \
  --notas <arquivo de notas> --nome "1.0.4 (5)" --publicar
```

Evidência visual e banco local:

```
flutter test test/evidencia_test.dart      # regenera os PNGs
supabase start && supabase db reset        # migrations do zero
flutter test test/integration --dart-define=BARU_TEST_URL=http://127.0.0.1:54321 --dart-define=BARU_TEST_KEY=<chave>
```
