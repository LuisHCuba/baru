# Controle parental do Baru ("Modo família")

Decidido em 2026-11-18 com o Luis:

- **Mesmo app, três jeitos de usar.** Na instalação o Baru pergunta: *é para mim*,
  *é para o meu filho* (celular da criança) ou *sou o responsável* (celular do pai/mãe).
- **O responsável acompanha pelo app e pelo meubaru.com** (um painel da família,
  irmão do `/painel`).
- **O Baru não nasce para bloquear.** O centro é a criança ser chamada para fora
  da tela pelo bicho. Pausar apps e filtrar sites são opções que o responsável liga.
- **Android e iOS com o mesmo módulo**, cada um com o que a plataforma permite.

## O que cada plataforma deixa fazer

| | Android | iOS |
|---|---|---|
| Medir o uso | Minutos por app (`UsageStatsManager`, permissão "Acesso ao uso") | Só **limiares**: o iOS avisa a extensão `BaruMonitor` quando o uso dos apps escolhidos passa de 25/50/75/100/150/200 % da meta. Minuto exato só dentro da extensão de relatório e nunca sai dela |
| Quem autoriza | A própria pessoa concede o acesso ao uso | `FamilyControls`: `.individual` (a pessoa) ou `.child` (criança no Compartilhamento Familiar; o iOS pede a senha do responsável) |
| A Nina "dá um oi" | Desenhada por cima dos apps (overlay já existe) | Notificação; não existe overlay sobre outros apps |
| Pausar apps | Tela de pausa ao abrir o app (AccessibilityService ou overlay em tela cheia) | `ManagedSettings` shield com o visual do Baru (extensões ShieldConfiguration/ShieldAction) |
| Sites | VPN local com lista de domínios (fase futura) | `webDomains` no shield + filtro de conteúdo adulto do `ManagedSettings` |
| Impedir desinstalar | Device Admin (fase futura, exige política de loja) | `.child` já impede remover sem o responsável |
| O que vai para o servidor | Total do dia e por categoria, com consentimento do responsável | **Só eventos de limiar** ("meta batida hoje às 17h") — regra 5.1.2(vi) da Apple: dado de Screen Time não sai do aparelho para outros fins |

## Estado (2026-11-19)

### Feito
- **Banco** (migrations no repositório, todas aplicadas exceto a da chave do aparelho):
  - `20261119000000_baru_familia` — famílias, membros, convites (código de 6, 30 min, uso único),
    regras, dia de cada criança, eventos. Tabelas sem policy; tudo por funções `baru_familia_*`.
  - `20261119010000_baru_familia_controles` — meta dos dias de aula e do fim de semana,
    horários sem tela com nome (até 8), tempo extra só hoje, pausar agora (até 24 h),
    avisos por criança. `baru_familia_meta_hoje` decide a meta do dia.
  - `20261119020000_baru_familia_aparelho` — **pendente de aplicar**: chave própria do
    aparelho da criança para o guarda do Android ler as regras sem o login.
- **App** (`lib/screens/familia_screen.dart`, `lib/data/familia.dart`, `lib/services/familia_sync.dart`,
  textos em `lib/l10n_familia.dart` nos 4 idiomas):
  - sem família: criar (responsável) ou entrar com código (criança ou 2º responsável);
  - responsável: cartão por criança com uso de hoje × meta, semana em barras, +15/+30 min,
    pausar/retomar, editor completo de regras e avisos;
  - criança: meta de hoje, aviso de pausa/horário, autorização do Tempo de Uso (iOS) ou
    acesso ao uso e sobreposição (Android).
- **Web**: aba Família em `meubaru.com/painel` (repositório `baru.lhcx`, `site/painel/familia.js`).
- **iOS**: `TempoDeTelaPlugin` + quatro extensões: `BaruMonitor` (DeviceActivityMonitor:
  meta por limiares; pausa e horários sem tela valem com o app fechado), `BaruRelatorio`
  (DeviceActivityReport: tempo por app na aba Tempo), `BaruEscudo` (ShieldConfiguration: a
  tela de pausa com o bicho e os textos do Baru, não a tela padrão da Apple) e
  `BaruEscudoAcao` (ShieldAction: o botão da tela de pausa). Filtro de conteúdo adulto do
  ManagedSettings. Family Controls (Distribution) aprovado pela Apple (pedido GCCF4RXN4U);
  os perfis App Store dos cinco bundle IDs (app + 4 extensões) são gerados com essa capacidade.
- **Android**: serviço `GuardaDaFamilia` (primeiro plano, `specialUse`): cobre a tela durante
  pausa, horário sem tela ou meta estourada (com "pausar ao estourar"). Livres: o Baru, a tela
  inicial e o telefone. Volta sozinho depois de reiniciar (`GuardaNoBoot`). Com a chave do
  aparelho, busca as regras a cada 2 min com o app fechado.

### Segredos
Todo segredo mora no Infisical (LHCX_CENTRAL, prod). A função `familia-push` usa
`APNS_KEY_P8` e `APNS_KEY_ID`, que chegam ao Supabase pela sincronização do Infisical.

### Localização (feita, 2026-11-19)
- Banco: migration `20261119040000_baru_familia_local.sql`. Lugares (círculos), posição atual,
  rastro de 7 dias (apagado sozinho), SOS, "onde está agora?" (`baru_familia_pedir_local`).
  Chegou/saiu é decidido no banco a partir das posições (posição com precisão > 200 m não muda
  o lugar). Ligar exige consentimento do responsável (registrado); desligar apaga o rastro.
- Celular da criança: Android pelo guarda (posição a cada 10 min e sob pedido em até 1 min,
  aviso fixo na barra, tipo de serviço `location`); iPhone por mudanças significativas de lugar
  + push silencioso para o pedido, indicador azul. SOS no app (segurar o botão).
- Avisos ao responsável: iPhone por push visível (Edge Function `familia-push`, `evento_id`);
  Android por conferência de 15 em 15 min (`AvisosDaFamilia`, JobScheduler).
- Mapa: app (`mapa_familia_screen.dart`, OpenStreetMap via flutter_map) e `/painel` (Leaflet).
- Testado no emulador Android: pedido, abriu, chegou, saiu, SOS. iPhone: compila e roda no
  simulador; o fluxo real (permissão "sempre", push) só no aparelho.

### Limites conhecidos
- Screen Time e push não funcionam no simulador: o teste real do iOS é no aparelho.
- Android: o aviso ao responsável pode levar até 15 min (sem Firebase/FCM). iPhone é imediato.
- Flutter: o Baru compila com o Flutter 3.44.9 (`~/.local/sdk/flutter-3.44`). O 3.50 exige
  Android Gradle Plugin 9, migração ainda não feita.

## Lojas
- **Apple:** Family Controls (Distribution) aprovado (GCCF4RXN4U). A Apple concede por
  bundle ID: o app e as quatro extensões (`.monitor`, `.relatorio`, `.escudo`, `.escudoacao`)
  precisam da capacidade; o export do TestFlight falha se faltar em algum. Screen Time e
  push **não funcionam no simulador**: o teste real é no iPhone. Na revisão, justificar a
  localização "sempre" (segurança da família, aviso visível, desligável pelo responsável).
- **Google Play:** declarar o app como de controle parental / bem-estar digital. Público-alvo:
  declarar 13+ (o app é instalado e configurado pelo responsável), e não "para crianças":
  a política de Famílias restringe localização em segundo plano em apps feitos para
  crianças — conferir a regra atual no Play Console antes de enviar; e justificar `PACKAGE_USAGE_STATS`
  e **localização em segundo plano** (`ACCESS_BACKGROUND_LOCATION`: formulário no Play Console,
  com vídeo curto mostrando o consentimento do responsável e o aviso fixo na criança).
- **App Store:** justificar a localização "sempre" na revisão (segurança da família, aviso
  visível, desligável pelo responsável).
