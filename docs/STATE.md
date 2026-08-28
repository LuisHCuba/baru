# Estado — 2026-08-27, fim do turno

Branch: `night/2026-08-27`, integrada em `main` | Build: **verde**

| Portão | Resultado (execução real) |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | **460 passando, 1 pulado** (era 151 no início do dia) |
| `flutter test test/integration` | 7/7 contra Supabase local |
| `supabase db reset` em banco limpo | **8 migrations · 15 tabelas · 58 políticas · nenhuma sem RLS** (a migration 9 ainda não foi rodada em banco limpo) |
| Evidência visual | 58 PNGs em `docs/evidence/2026-08-27/` |
| `flutter build apk --release` | **app-release.apk, 51,5 MB** |

## Abra o app e você vê

Frases que são verdade hoje e não eram ontem:

- **O botão voltar do aparelho funciona**: num detalhe volta um passo, numa
  aba volta para a home, e **na home pergunta antes de fechar**, com o bicho
  na folha. Durante a sessão, pergunta também.
- **A trilha virou um caminho** com nós grandes, linha tracejada no que falta
  e "VOCÊ ESTÁ AQUI" no passo atual.
- **Tela "Sua conta"**: e-mail, trocar e-mail, trocar senha, recuperar senha,
  plano e sair.
- **Uma pergunta do quiz por tela**, com a barra andando a cada resposta;
  escolher já avança, e dá para voltar sem perder o que foi respondido. No
  fim se escolhe bicho, sexo, pelagem e nome na mesma tela.
- **"Apagar meus dados"** em Sua conta: apaga aqui e no servidor, atrás de
  uma folha de confirmação onde "Cancelar" é o botão cheio e "Apagar tudo"
  se declara em vermelho — antes ele saía cinza, com cara de desabilitado.
- **O APK de release compila.** Não compilava: `usage_stats` 1.3.1 fica num
  `compileSdk` anterior à API 31 e o `verifyReleaseResources` quebrava em
  `android:attr/lStar not found`.
- **O APK de release tem internet.** O primeiro exportado não tinha: o
  template do Flutter declara `INTERNET` só em `debug/` e `profile/`, e o
  release funde apenas o `main`. O app instalava, abria e toda chamada de
  rede morria em "erro de internet". Há teste lendo o manifesto.
- **Sair do app durante o foco chama o Baru de volta.** Antes não fazia
  nada: com o app em segundo plano o Flutter **não executa**, e o único
  gatilho estava no `didChangeAppLifecycleState`, que só dispara quando a
  pessoa volta. Agora um serviço em primeiro plano pergunta a cada 2 s quem
  está na frente e traz o companheiro por cima, com um minuto de descanso
  entre aparições.
- **O ícone do app é o Baru**, gerado pelo mesmo `CustomPainter` que desenha
  o bicho na tela, e troca quando você troca de espécie. Verificado no
  aparelho: o Android resolve o LAUNCHER para `IconeCapybara`.
- **Faltar "desenhar sobre outros apps" deixou de ser silêncio.** Sem essa
  permissão o vigia via a pessoa sair e não conseguia aparecer, sem dizer
  nada — indistinguível de "o app não funciona".
- **O botão voltar do aparelho funciona nas abas.** Fechava o app. A causa
  não era o `app.voltar()` — era antes: o Flutter avisa o Android com
  `canHandlePop = navigatorCanPop || routeBlocksPop`, e numa aba a pilha tem
  uma página só. Com `targetSdk 36` o *predictive back* vem ligado por
  padrão e o sistema encerrava a activity sem chamar o Dart. A página de
  baixo agora declara que segura o voltar.
- **Arrastar no bicho faz carinho, não rola a tela.** O `pan` só reivindica
  a arena depois de `kPanSlop`, o dobro do que a rolagem usa: ela sempre
  ganhava o dedo primeiro.
- **A permissão travada pelo Android tem passo a passo.** Do Android 13 em
  diante o `PACKAGE_USAGE_STATS` fica bloqueado para app instalado por
  arquivo — o sistema fala em risco a dados pessoais. O aviso antigo mandava
  para a tela onde o botão está travado; agora há os quatro toques que
  destravam e um atalho para começar.
- **A ofensiva virou "raiz"**, nos quatro idiomas: dia presente aprofunda a
  raiz, e é ela que segura o hábito quando a vontade falta.
- **As missões dizem o que fazer e levam onde se faz.** Cada cartão ganhou
  uma linha de "como", e tocar numa missão por fazer abre a tela da ação.
- **A chegada do dia ganha cena.** Abrir o app no primeiro dia novo mostra a
  mesma celebração de conquista, com som e háptico — uma vez por dia, nunca
  a cada volta do background.
- **"Lembrar meus dados" no login**, cifrado no Keystore — e a volta abre
  com "Que bom te ver de novo" e o botão de digital, não com formulário
  vazio. O desbloqueio usa digital, rosto **ou** o PIN do aparelho, então
  quem não cadastrou biometria não fica de fora. Digitar a senha nunca some,
  e credencial recusada pelo servidor cai no formulário em vez de deixar a
  pessoa repetindo uma digital que nunca vai funcionar.
- **As telas entram com transição** e a barra de destinos é fixa.
- **Dá para acariciar o Baru**: ele acompanha a mão, aperta os olhos, o pelo
  se levanta sob o dedo, sobem corações, e a mão ronrona.
- **As quatro espécies são um elenco coerente**, todas de frente, com cabeça
  grande e cara legível.
- **O Baru respira, pisca e reage ao toque**, e **faz coisas sozinho**: a
  cada 7–15 s parado ele se espreguiça com bocejo, sacode a cabeça ou olha em
  volta.
- **Insistir no carinho faz subir coraçõezinhos** — do terceiro toque em 3 s.
- O habitat tem céu em gradiente, colinas que derivam e reflexos andando na
  água.
- **O habitat às 22h é diferente do das 9h** — céu índigo, lua com halo, água
  escura.
- **Comprar um item o faz cair na cena com mola**, e ele projeta sombra.
- **"Seu tempo de tela"** mostra quanto conta para a meta, quanto foi no total,
  a quebra por categoria e a lista por app. O Spotify aparece como Áudio, fora
  da meta.
- **Uma aba "Trilha"** com nível, XP, o próximo passo em destaque e doze marcos
  ligados por uma linha.
- **Subir de nível toma a tela** com partículas e háptico.
- **Uma aba "Missões"** com progresso x/y, recompensa exata, prazo e um botão
  "Resgatar" que faz o saldo de folhas subir animado.
- **A sessão de foco aparece na barra de notificações** com contagem regressiva
  e botão "Desistir".

## Pronto e funcionando

- Cinco fatias verticais completas neste turno (dado → regra → persistência →
  tela → animação → háptico → 4 idiomas → teste → evidência).
- Design system em código: tokens de cor, espaço, raio, elevação e tipografia;
  sistema de movimento com durações nomeadas e curvas com física.
- Nunito empacotada: o app não baixa mais a própria fonte.
- Tempo de tela por contabilidade de intervalos, não por soma bruta.
- Progressão real: XP, níveis, doze marcos, espécies desbloqueáveis.
- Missões com sorteio determinístico e resgate idempotente.
- Backend: 14 tabelas com RLS, schema reproduzível do zero.

## Em andamento

Nada pela metade. Todos os ciclos fecharam com portões verdes.

**Próximo passo exato:** aplicar as migrations 7 e 8 no Supabase remoto
(**BL-10**) — é o que faz o "erro ao sincronizar" sumir. Precisa de um humano
com acesso ao projeto; o comando está no arquivo de bloqueios.

## Próximos itens da fila

1. **Aplicar as migrations no remoto** (BL-10).
2. **B-15 assinatura de release do Android** — único bloqueio de publicação.
3. **Estágios de habitat visíveis** — o dado existe (`estagioDoHabitat` sobe
   com os marcos) mas a cena ainda não muda com ele.
4. **Lembretes com propósito** (§6) — sequência em risco, missão quase
   concluída, marco ao alcance.
5. **Onboarding e paywall no novo design system** — as duas telas que ainda
   usam os valores antigos.

## Riscos e dívidas conhecidas

- **O banco remoto está atrás do repositório** (BL-10): faltam
  `baru_app_categories` e `baru_progression`. O app avisa qual tabela falta e
  segue gravando local; nada se perde, mas nada de ajustes, tempo de tela e
  progressão sobe.
- **Nada foi verificado em aparelho.** Animações, notificação e permissão de
  uso têm teste, mas ninguém rodou o app num telefone depois deste turno.
- **A permissão de tempo de tela nunca rodou contra o Android real.** A
  reconstrução de intervalos tem 25 casos sintéticos; a leitura dos eventos
  crus depende de aparelho.
- **Economia autoritativa no cliente** — vira problema no dia do IAP.
- **`AppState` passou de 1200 linhas.** Concentra domínio, plataforma e
  persistência.
- **Nada foi aplicado no Supabase remoto.** A migration 7 existe no
  repositório e foi validada localmente; aplicar é do humano.

## Bloqueios para o humano

| # | O quê |
|---|---|
| BL-01 | Ledger de migrations ausente no projeto remoto |
| BL-03 | Proteção contra senha vazada desligada |
| BL-04 | Um usuário de teste sem e-mail confirmado |
| BL-05 | Keystore de release do Android |
| BL-06 | Entitlement de Screen Time no iOS |
| BL-07 | Produtos de IAP nas lojas |
| BL-09 | **Verificar a notificação da sessão num aparelho** (roteiro no arquivo) |
| BL-10 | ~~Migrations 7, 8 e 9~~ — **aplicadas** (sonda REST em 2026-08-27: as duas tabelas e as colunas novas respondem 200) |
| BL-11 | **O "erro ao sincronizar" ainda aparece no aparelho.** O schema remoto está em dia, então a causa é outra. O app agora nomeia o domínio que falhou; preciso desse nome para investigar |

## Comandos para rodar e validar agora

```
cd baru_app
flutter pub get
flutter analyze
flutter test
flutter run
```

Evidência visual e banco local:

```
flutter test test/evidencia_test.dart      # regenera os PNGs
supabase start && supabase db reset        # migrations do zero
flutter test test/integration --dart-define=BARU_TEST_URL=http://127.0.0.1:54321 --dart-define=BARU_TEST_KEY=<chave>
```
