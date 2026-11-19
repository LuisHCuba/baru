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
- **iOS**: `TempoDeTelaPlugin` + extensão `BaruMonitor`. Meta por limiares; pausa e horários
  sem tela como atividades do DeviceActivity (valem com o app fechado); filtro de conteúdo
  adulto do ManagedSettings. Família Controls (Distribution) aprovado pela Apple (pedido GCCF4RXN4U).
- **Android**: serviço `GuardaDaFamilia` (primeiro plano, `specialUse`): cobre a tela durante
  pausa, horário sem tela ou meta estourada (com "pausar ao estourar"). Livres: o Baru, a tela
  inicial e o telefone. Volta sozinho depois de reiniciar (`GuardaNoBoot`). Com a chave do
  aparelho, busca as regras a cada 2 min com o app fechado.

### Segredos
Todo segredo mora no Infisical (LHCX_CENTRAL, prod). A função `familia-push` usa
`APNS_KEY_P8` e `APNS_KEY_ID`, que chegam ao Supabase pela sincronização do Infisical.

### Limites conhecidos
- **iOS com o app fechado não recebe regras novas** (pausa dada agora, horário mudado): o
  iPhone só aplica o que o responsável mudou quando o Baru abre. Resolver exige push (APNs):
  chave .p8 da Apple + envio pelo Supabase. Os horários e a pausa já entregues ao sistema
  valem com o app fechado.
- **Filtro de sites no Android** não existe (exigiria VPN local). No iOS usa o filtro da Apple.
- Screen Time não funciona no simulador: o teste real do iOS é no aparelho.

## Próxima fase sugerida — localização (plano Baru Família)
Lugares (casa/escola) com aviso de chegada e saída, "onde está agora?" sob pedido, botão SOS,
histórico curto (7 dias). Consentimento do responsável, aviso permanente na criança (LGPD e
ECA Digital), justificativa de localização em segundo plano nas duas lojas.

## Lojas
- **Apple:** pedir *Family Controls (Distribution)* para o app e cada extensão
  (prompt em `PROMPT_family_controls_apple.md`, fora do repositório). Desenvolvimento
  e teste no aparelho funcionam sem aprovação. Screen Time **não funciona no simulador**:
  o teste real é no iPhone.
- **Google Play:** declarar o app como de controle parental / bem-estar digital,
  política de Famílias se o público incluir crianças, e justificar `PACKAGE_USAGE_STATS`
  (e `BIND_ACCESSIBILITY_SERVICE` se a fase 6 usar).
