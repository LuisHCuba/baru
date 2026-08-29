import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/descanso_do_dia.dart';
import '../data/descanso_retencao.dart';

/// Notificações locais: relatório da noite (21h) e "senti sua falta".
class BaruNotifications {
  BaruNotifications._();

  static final BaruNotifications instance = BaruNotifications._();

  static const _eveningId = 1001;
  static const _missedId = 1002;
  static const _trialId = 1003;

  /// **A única contagem viva na barra.**
  ///
  /// Um id só, de propósito. Durante uma sessão de foco havia duas
  /// notificações ao mesmo tempo — esta, do plugin, e a do
  /// `VigiaDaSessao`, que é um serviço em primeiro plano e portanto
  /// **precisa** ter notificação própria. Ids diferentes (1004 e 4711) em
  /// canais diferentes não se sobrescrevem: o `NotificationManager` guarda
  /// por (pacote, tag, id), e nenhuma das duas usava tag. O resultado eram
  /// duas linhas com o mesmo título e o mesmo corpo, e só uma delas com a
  /// contagem — exatamente o "não está dinâmico" que o dono relatou.
  ///
  /// Agora o Kotlin posta neste mesmo id, neste mesmo canal. Duas escritas
  /// no mesmo id são uma **atualização**, não uma segunda notificação: é o
  /// padrão documentado para atualizar a notificação de um serviço em
  /// primeiro plano. Quem escrever por último ganha, e as duas carregam a
  /// mesma contagem, então não existe "perder a corrida".
  ///
  /// O valor viaja para o lado nativo em [_publicaNoNativo] — o Kotlin não
  /// repete a constante.
  static const sessaoId = 1004;

  /// O aviso de sessão concluída, agendado para o fim dela.
  static const sessaoFimId = 1005;

  /// O chamado diário do descanso, no horário do hábito (RD-01).
  static const descansoId = 1006;

  /// A raiz em risco (RD-02). São **dois** ids porque o aviso é agendado
  /// para hoje e para amanhã — ver [sincronizaRetencao].
  static const raizHojeId = 1007;
  static const raizAmanhaId = 1008;

  /// Canal separado: a sessão é persistente e silenciosa; os lembretes tocam.
  static const canalSessao = 'baru_sessao';
  static const canalLembretes = 'baru_reminders';

  /// Id da ação de desistir na notificação da sessão.
  static const acaoDesistir = 'baru_desistir';

  /// Id da ação de encerrar a missão do descanso.
  static const acaoEncerraDescanso = 'baru_descanso_encerra';

  /// Id da ação que só traz a pessoa de volta ao app.
  static const acaoVoltar = 'baru_voltar';

  static const _lastMissedKey = 'baru_last_missed_notify';

  /// O canal para o lado nativo desenhar a **mesma** contagem.
  ///
  /// Separado de `baru/overlay` de propósito: aquele é da frente da
  /// sobreposição, e dois donos no mesmo canal é como se perde um método em
  /// merge.
  static const _canalDaBarra = MethodChannel('baru/barra');

  /// Injetável: sem plataforma, um teste não exercita contrato nenhum.
  @visibleForTesting
  MethodChannel canalDaBarra = _canalDaBarra;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Chamado quando o usuário toca "Desistir" na notificação da sessão.
  /// Ligado pelo app; nulo em teste e em web.
  ///
  /// **Por que é propriedade e não campo.** O toque pode ter **acordado o
  /// app do zero**: nesse caso a ação chega durante o `init()`, antes de
  /// existir árvore de widgets para registrar o callback. Guardar a ação e
  /// entregá-la a quem chegar depois é o que faz "Desistir" com o app morto
  /// significar alguma coisa.
  void Function()? get aoDesistirPelaBarra => _aoDesistir;
  void Function()? _aoDesistir;
  set aoDesistirPelaBarra(void Function()? f) {
    _aoDesistir = f;
    _escoaPendente();
  }

  /// Chamado quando o usuário encerra o descanso pela barra.
  void Function()? get aoEncerrarDescansoPelaBarra => _aoEncerrarDescanso;
  void Function()? _aoEncerrarDescanso;
  set aoEncerrarDescansoPelaBarra(void Function()? f) {
    _aoEncerrarDescanso = f;
    _escoaPendente();
  }

  /// De onde sai o rótulo do botão "voltar ao app".
  ///
  /// **Uma função e não uma string** porque o idioma muda nos ajustes, e a
  /// notificação da sessão pode ser postada muito depois disso. Guardar o
  /// texto congelaria o idioma do arranque na única tela do produto que a
  /// pessoa lê sem abrir o app.
  ///
  /// Nulo em teste e em web: sem rótulo, a notificação sai sem o botão e o
  /// toque no corpo continua abrindo o app.
  String Function()? rotuloDeVolta;

  /// A ação que chegou antes de haver quem a atendesse.
  String? _acaoPendente;

  /// Entrega a ação guardada, se já houver quem a atenda.
  ///
  /// Só limpa a pendência quando **alguém atendeu**: um toque que chega
  /// entre o `init()` e o `initState` do app não pode virar um clique
  /// perdido.
  void _escoaPendente() {
    final acao = _acaoPendente;
    if (acao == null) return;
    if (acao == acaoDesistir && _aoDesistir != null) {
      _acaoPendente = null;
      _aoDesistir!();
      return;
    }
    if (acao == acaoEncerraDescanso && _aoEncerrarDescanso != null) {
      _acaoPendente = null;
      _aoEncerrarDescanso!();
    }
  }

  /// Só para o teste: dá o serviço por armado, sem plataforma nativa.
  ///
  /// `init()` faz três coisas que exigem aparelho — fuso, plugin e canais —
  /// e o que se quer provar aqui é o que vem **depois**: quem fica com a
  /// barra, o que atravessa o canal, e o que acontece com um toque que
  /// chegou cedo demais. Mesma armadilha e mesma saída do
  /// `VigiaService.zeraParaTeste`.
  @visibleForTesting
  void preparaParaTeste({bool pronto = true}) {
    _ready = pronto;
    _contagemAtual = null;
    _acaoPendente = null;
    _aoDesistir = null;
    _aoEncerrarDescanso = null;
    rotuloDeVolta = null;
  }

  /// Puxa do lado nativo a ação que ficou guardada.
  ///
  /// **No arranque a frio o toque chega antes de existir Dart para ouvir**: a
  /// activity nasce por causa dele, e o canal só ganha handler dentro do
  /// `init()`. Um `invokeMethod` empurrado pelo nativo naquele intervalo cai
  /// num canal sem ouvinte. Por isso quem chega depois é quem pergunta.
  @visibleForTesting
  Future<void> puxaAcaoGuardada() async {
    if (kIsWeb) return;
    try {
      recebeAcaoDaBarra(
        await canalDaBarra.invokeMethod<String>('acaoPendente'),
      );
    } on MissingPluginException {
      // Web, desktop, teste: nada guardado.
    } on PlatformException {
      // Idem.
    }
  }

  /// Roteia uma ação vinda da barra, de onde quer que ela tenha vindo.
  ///
  /// Três caminhos chegam aqui e é o mesmo destino nos três: o plugin com o
  /// app vivo, o plugin no arranque a frio (`getNotificationAppLaunchDetails`)
  /// e o botão da notificação do serviço em primeiro plano, que passa pelo
  /// `MainActivity`.
  /// Ação desconhecida — [acaoVoltar] inclusive — não decide nada: só as
  /// duas que têm dono aqui saem daqui como decisão. Voltar ao app é voltar
  /// ao app; se ele abandonasse a sessão de passagem, seria uma armadilha.
  @visibleForTesting
  void recebeAcaoDaBarra(String? acaoId) {
    if (acaoId == null) return;
    _acaoPendente = acaoId;
    _escoaPendente();
  }

  Future<void> init() async {
    if (kIsWeb || _ready) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resposta) =>
          recebeAcaoDaBarra(resposta.actionId),
    );

    // O botão da notificação do serviço em primeiro plano não passa pelo
    // plugin: ele abre a `MainActivity`, que devolve a ação por aqui.
    canalDaBarra.setMethodCallHandler((chamada) async {
      if (chamada.method == 'acaoDaBarra') {
        recebeAcaoDaBarra(chamada.arguments as String?);
      }
      return null;
    });

    await puxaAcaoGuardada();

    // **O caso que estava furado: o app aberto pela própria notificação.**
    //
    // Com o app morto, `onDidReceiveNotificationResponse` não é chamado —
    // o plugin guarda a resposta no intent de arranque e ela só sai por
    // `getNotificationAppLaunchDetails`. Sem esta consulta, tocar
    // "Desistir" com o app fechado apagava a notificação e não abandonava
    // sessão nenhuma; na volta o relógio concluía a sessão e **pagava** a
    // recompensa de quem tinha desistido.
    try {
      final arranque = await _plugin.getNotificationAppLaunchDetails();
      if (arranque?.didNotificationLaunchApp ?? false) {
        recebeAcaoDaBarra(arranque?.notificationResponse?.actionId);
      }
    } catch (_) {
      // Plataforma sem o plugin: nada a recuperar.
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          canalLembretes,
          'Lembretes Baru',
          description: 'Relatório da noite e mensagens do pet',
          importance: Importance.defaultImportance,
        ),
      );
      // A sessão fica fixa na barra e não pode tocar nem vibrar: o usuário
      // está justamente tentando não ser interrompido.
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          canalSessao,
          'Sessão de foco',
          description: 'Contagem regressiva da sessão em andamento',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
    }

    _ready = true;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    if (await hasPermission()) return true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      if (granted == true) return true;
    }

    final result = await Permission.notification.request();
    return result.isGranted || result.isLimited;
  }

  /// Qual missão está com a contagem da barra neste instante.
  ///
  /// Uma só, porque o id é um só. Guardado para que o descanso não roube a
  /// vez da sessão de foco — ver [mostraDescanso].
  @visibleForTesting
  String? get contagemAtual => _contagemAtual;
  String? _contagemAtual;

  /// A marca da sessão de foco na disputa pela barra.
  static const contagemDeFoco = 'foco';

  /// A marca da missão do descanso.
  static const contagemDeDescanso = 'descanso';

  /// Coloca a sessão na barra de notificações, com contagem regressiva viva.
  ///
  /// A contagem é desenhada pelo **próprio Android**, a partir de
  /// `usesChronometer` e do instante de término: ela continua andando com o
  /// app em background ou morto, sem o Baru precisar atualizar nada.
  Future<void> mostraSessao({
    required DateTime terminaEm,
    required String titulo,
    required String corpo,
    required String rotuloDesistir,
  }) async {
    if (kIsWeb || !_ready) return;
    if (!await hasPermission()) return;

    _contagemAtual = contagemDeFoco;
    final rotuloVoltar = rotuloDeVolta?.call() ?? '';
    final detalhes = detalhesDaSessao(
      terminaEm: terminaEm,
      rotuloDesistir: rotuloDesistir,
      rotuloVoltar: rotuloVoltar,
    );
    // O nativo primeiro: se o vigia já estiver de pé, ele redesenha a
    // notificação com a contagem no mesmo instante, e não sobra janela em
    // que a barra mostre o texto parado do serviço.
    await _publicaNoNativo(
      terminaEm: terminaEm,
      titulo: titulo,
      corpo: corpo,
      rotuloDesistir: rotuloDesistir,
      idDesistir: acaoDesistir,
      rotuloVoltar: rotuloVoltar,
    );
    await _plugin.show(
      id: sessaoId,
      title: titulo,
      body: corpo,
      notificationDetails: detalhes,
    );
  }

  /// Põe a missão do descanso na barra, com a mesma presença da sessão.
  ///
  /// **Por que ela precisa disto.** O descanso é a missão principal do dia e
  /// pede exatamente o contrário de olhar o app: quarenta minutos longe do
  /// telefone. Sem notificação ela sumia da vista no segundo em que começava
  /// a valer — a única missão do produto invisível justamente enquanto corre.
  ///
  /// **O foco tem precedência.** Se uma sessão de foco já está com a barra,
  /// o descanso não a toma: são contagens diferentes com um id só, e a que
  /// tem prazo duro e recompensa é a do foco. Trocar seria mostrar o número
  /// errado para quem está olhando de relance.
  Future<void> mostraDescanso({
    required DateTime terminaEm,
    required String titulo,
    required String corpo,
    required String rotuloEncerrar,
  }) async {
    if (kIsWeb || !_ready) return;
    if (_contagemAtual == contagemDeFoco) return;
    if (!await hasPermission()) return;

    _contagemAtual = contagemDeDescanso;
    final rotuloVoltar = rotuloDeVolta?.call() ?? '';
    final detalhes = detalhesDaContagem(
      terminaEm: terminaEm,
      idDesistir: acaoEncerraDescanso,
      rotuloDesistir: rotuloEncerrar,
      rotuloVoltar: rotuloVoltar,
    );
    await _publicaNoNativo(
      terminaEm: terminaEm,
      titulo: titulo,
      corpo: corpo,
      rotuloDesistir: rotuloEncerrar,
      idDesistir: acaoEncerraDescanso,
      rotuloVoltar: rotuloVoltar,
    );
    await _plugin.show(
      id: sessaoId,
      title: titulo,
      body: corpo,
      notificationDetails: detalhes,
    );
  }

  /// Tira o descanso da barra.
  ///
  /// Não mexe na barra se quem está nela é a sessão de foco: encerrar uma
  /// missão não pode apagar a contagem da outra.
  ///
  /// [focoEmCurso] existe porque [contagemAtual] **não sobrevive à morte do
  /// processo**, e a notificação sobrevive. App morto no meio de uma sessão
  /// e reaberto: a barra ainda tem o cronômetro do foco, e a memória de quem
  /// a escreveu não tem mais. Sem esta pergunta a quem sabe — o estado do
  /// app —, a primeira ida ao segundo plano apagaria o cronômetro de uma
  /// sessão viva, que é exatamente o defeito que este trabalho existe para
  /// resolver.
  Future<void> encerraDescanso({bool focoEmCurso = false}) async {
    if (kIsWeb || !_ready) return;
    if (focoEmCurso || _contagemAtual == contagemDeFoco) return;
    _contagemAtual = null;
    await _publicaNoNativo(terminaEm: null);
    await _plugin.cancel(id: sessaoId);
  }

  /// Quando a contagem do descanso deve acabar, projetada de agora.
  ///
  /// **O relógio do descanso não é o relógio de parede.** O que conta é
  /// `decorrido - fuga - tempo no próprio Baru` (ver `leDescanso`), então um
  /// prazo fixo em `comecouEm + 40 min` mentiria assim que a pessoa pegasse
  /// o telefone. O que não mente é a projeção: **agora + o que falta**.
  ///
  /// Enquanto o telefone está parado — que é a missão inteira — nada é
  /// subtraído e a projeção é exata. Quando a pessoa volta, o app recalcula
  /// e republica: é o único instante em que a conta muda, e é o instante em
  /// que o app está aberto para refazê-la.
  ///
  /// Devolve `null` quando não há o que contar — sem tentativa, tentativa já
  /// completa, rompida ou expirada. Uma contagem que chegou a zero e fica lá
  /// é pior que contagem nenhuma: ela diz que a missão continua quando ela
  /// já acabou.
  ///
  /// Separado da chamada para o teste conferir a regra sem plataforma: o
  /// defeito mora nesta conta, não em quem a publica.
  static DateTime? contagemDoDescanso(
    LeituraDoDescanso? leitura,
    DateTime agora,
  ) {
    if (leitura == null || !leitura.emAndamento) return null;
    final falta = leitura.falta;
    return falta > Duration.zero ? agora.add(falta) : null;
  }

  /// Como a sessão aparece na barra.
  ///
  /// Separado de [mostraSessao] para o teste conferir a configuração sem
  /// precisar de plataforma nativa: o que importa aqui — fixa, silenciosa e
  /// com cronômetro regressivo até o instante certo — é decidido nestes
  /// campos, não na chamada.
  @visibleForTesting
  static NotificationDetails detalhesDaSessao({
    required DateTime terminaEm,
    required String rotuloDesistir,
    String rotuloVoltar = '',
  }) =>
      detalhesDaContagem(
        terminaEm: terminaEm,
        idDesistir: acaoDesistir,
        rotuloDesistir: rotuloDesistir,
        rotuloVoltar: rotuloVoltar,
      );

  /// A forma da única contagem viva na barra.
  ///
  /// Serve às duas missões porque as duas pedem a mesma coisa do sistema:
  /// fixa, silenciosa, contando sozinha, legível na tela de bloqueio. O que
  /// muda entre elas é a palavra — e palavra chega pronta de fora.
  @visibleForTesting
  static NotificationDetails detalhesDaContagem({
    required DateTime terminaEm,
    required String idDesistir,
    required String rotuloDesistir,
    String rotuloVoltar = '',
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        canalSessao,
        'Sessão de foco',
        channelDescription: 'Contagem regressiva da sessão em andamento',
        importance: Importance.low,
        priority: Priority.low,
        // Fixa: não some ao deslizar, e não vira histórico.
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        when: terminaEm.millisecondsSinceEpoch,
        // A contagem é desenhada pelo Android a partir de `when`: continua
        // andando com o app morto.
        usesChronometer: true,
        chronometerCountDown: true,
        // **A tela de bloqueio.** O padrão do Android é `private`: num
        // aparelho com bloqueio seguro a notificação aparece, mas o conteúdo
        // vira "conteúdo oculto" — e a contagem, que é o conteúdo, some. Não
        // há segredo aqui: quanto falta da própria pausa é o que a pessoa
        // precisa ver sem desbloquear nada.
        visibility: NotificationVisibility.public,
        // `stopwatch` é o que isto é. A categoria alimenta a ordenação e o
        // filtro de "não perturbe"; mentir aqui (`alarm`, `call`) compraria
        // destaque com um nome falso — o Android não dá destaque de graça,
        // dá em troca de uma promessa que o app teria de cumprir.
        category: AndroidNotificationCategory.stopwatch,
        actions: [
          AndroidNotificationAction(
            idDesistir,
            rotuloDesistir,
            cancelNotification: true,
            // **A correção do botão que não fazia nada.** Sem isto o plugin
            // manda o toque para um `BroadcastReceiver` que tenta acordar um
            // isolate de segundo plano registrado em
            // `onDidReceiveBackgroundNotificationResponse` — que o app nunca
            // registrou. O botão cancelava a notificação e o app não ficava
            // sabendo: a sessão seguia correndo e, na volta, o relógio
            // **pagava** a recompensa de quem tinha desistido. Com
            // `showsUserInterface` o toque abre o app, e aí a decisão
            // acontece de verdade — o que é o certo de qualquer forma,
            // porque desistir leva à tela de resultado.
            showsUserInterface: true,
          ),
          if (rotuloVoltar.isNotEmpty)
            AndroidNotificationAction(
              acaoVoltar,
              rotuloVoltar,
              showsUserInterface: true,
              // Voltar não é encerrar: a contagem continua exatamente onde
              // estava.
              cancelNotification: false,
            ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: false,
        presentBanner: false,
      ),
    );
  }

  /// Manda a contagem para o lado nativo desenhar a mesma notificação.
  ///
  /// **Por que existe.** O `VigiaDaSessao` é um serviço em primeiro plano e
  /// o Android **obriga** um serviço desses a ter notificação própria — não
  /// dá para ele simplesmente usar a do plugin. O que dá é postar no mesmo
  /// id, com o mesmo conteúdo: aí as duas escritas viram uma notificação só.
  /// Sem isto eram duas, e a que o Android garante manter era justamente a
  /// que **não** contava.
  ///
  /// Nenhuma palavra nasce do outro lado: rótulo, título e corpo vão daqui,
  /// já traduzidos. `terminaEm` nulo significa "não há contagem".
  Future<void> _publicaNoNativo({
    required DateTime? terminaEm,
    String titulo = '',
    String corpo = '',
    String rotuloDesistir = '',
    String idDesistir = acaoDesistir,
    String rotuloVoltar = '',
  }) async {
    if (kIsWeb) return;
    try {
      await canalDaBarra.invokeMethod<void>('contagem', {
        'id': sessaoId,
        'canal': canalSessao,
        'terminaEm': terminaEm?.millisecondsSinceEpoch ?? 0,
        'titulo': titulo,
        'corpo': corpo,
        'rotuloDesistir': rotuloDesistir,
        'idDesistir': idDesistir,
        'rotuloVoltar': rotuloVoltar,
        'idVoltar': acaoVoltar,
      });
    } on MissingPluginException {
      // Web, desktop, teste: a notificação do plugin já basta.
    } on PlatformException {
      // Nada aqui pode derrubar a sessão da pessoa.
    }
  }

  /// A sessão só é anunciada se ainda houver tempo.
  @visibleForTesting
  static bool valeAnunciar(DateTime terminaEm, DateTime agora) =>
      terminaEm.isAfter(agora);

  /// Agenda o aviso de sessão concluída.
  ///
  /// Agendado, não disparado na hora: é o que faz a recompensa chegar mesmo
  /// com o app fechado — que é o caso normal de uma sessão bem-sucedida.
  Future<void> agendaFimDaSessao({
    required DateTime terminaEm,
    required String titulo,
    required String corpo,
  }) async {
    if (kIsWeb || !_ready) return;
    if (!await hasPermission()) return;

    final quando = tz.TZDateTime.from(terminaEm, tz.local);
    if (!quando.isAfter(tz.TZDateTime.now(tz.local))) return;

    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        canalLembretes,
        'Lembretes Baru',
        channelDescription: 'Sessão concluída',
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        id: sessaoFimId,
        title: titulo,
        body: corpo,
        scheduledDate: quando,
        notificationDetails: detalhes,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      // Sem permissão de alarme exato o Android recusa o agendamento. Um
      // aviso alguns minutos atrasado é melhor que nenhum — e a conclusão em
      // si já é reconciliada pelo relógio quando o app abre.
      await _plugin.zonedSchedule(
        id: sessaoFimId,
        title: titulo,
        body: corpo,
        scheduledDate: quando,
        notificationDetails: detalhes,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Tira a sessão da barra e cancela o aviso de fim.
  ///
  /// Chamado ao concluir e ao desistir: agendamento sem motivo tem de sumir.
  ///
  /// Limpa também a contagem guardada do lado nativo. Sem isso, o serviço
  /// levantado pela **próxima** sessão desenharia o prazo da anterior no
  /// intervalo entre subir e receber o novo — uma contagem já vencida, que é
  /// o defeito mais fácil de acreditar que é "o timer travou".
  Future<void> encerraSessao() async {
    if (kIsWeb || !_ready) return;
    _contagemAtual = null;
    await _publicaNoNativo(terminaEm: null);
    await _plugin.cancel(id: sessaoId);
    await _plugin.cancel(id: sessaoFimId);
  }

  /// Onde a próxima ocorrência de um lembrete cai.
  ///
  /// Separado do agendamento para o teste conferir a regra sem plataforma:
  /// o defeito mora aqui, não na chamada. Um lembrete cujo horário já passou
  /// hoje **não** dispara agora — notificação atrasada é a que ensina a
  /// ignorar notificação.
  @visibleForTesting
  static DateTime proximaOcorrencia(LembreteDoDia l, DateTime agora) {
    final hoje = DateTime(agora.year, agora.month, agora.day, l.hora, l.minuto);
    if (l.pulaHoje || !hoje.isAfter(agora)) {
      return hoje.add(const Duration(days: 1));
    }
    return hoje;
  }

  /// Põe de pé o dia de retenção: o chamado do hábito e a raiz em risco.
  ///
  /// O plano vem decidido de fora (`planoDeLembretes`) e os textos chegam
  /// traduzidos: aqui só se agenda. Cancelar o que não está no plano é parte
  /// do contrato — é assim que a raiz deixa de ser cobrada de quem já
  /// apareceu hoje.
  ///
  /// **Por que o descanso repete e a raiz não.** O chamado do hábito diz
  /// sempre a mesma coisa, então repetir todo dia no mesmo horário funciona
  /// mesmo com o app sem abrir há uma semana — que é justamente quem
  /// precisa dele. O aviso da raiz carrega um número que envelhece ("sua
  /// raiz de 12 dias"); repetido, ele diria 12 para sempre. Por isso é
  /// agendado um dia por vez e refeito a cada abertura.
  ///
  /// **Por que também amanhã.** Quem está prestes a quebrar a raiz é
  /// exatamente quem não vai abrir o app amanhã. Um aviso que só existe
  /// enquanto o app é aberto avisa quem não precisa. Os dois agendamentos
  /// são desfeitos assim que a pessoa aparece.
  Future<void> sincronizaRetencao({
    required List<LembreteDoDia> plano,
    required Map<TipoDeLembrete, TextoDeLembrete> textos,
    DateTime? agora,
  }) async {
    if (kIsWeb || !_ready) return;

    if (!await hasPermission()) {
      await _cancelaRetencao();
      return;
    }

    final quandoAgora = agora ?? DateTime.now();

    LembreteDoDia? doTipo(TipoDeLembrete tipo) {
      for (final l in plano) {
        if (l.tipo == tipo) return l;
      }
      return null;
    }

    await _agendaDescanso(doTipo(TipoDeLembrete.descanso), textos, quandoAgora);
    await _agendaRaiz(doTipo(TipoDeLembrete.raizEmRisco), textos, quandoAgora);
  }

  Future<void> _cancelaRetencao() async {
    await _plugin.cancel(id: descansoId);
    await _plugin.cancel(id: raizHojeId);
    await _plugin.cancel(id: raizAmanhaId);
  }

  Future<void> _agendaDescanso(
    LembreteDoDia? lembrete,
    Map<TipoDeLembrete, TextoDeLembrete> textos,
    DateTime agora,
  ) async {
    final texto = textos[TipoDeLembrete.descanso];
    if (lembrete == null || texto == null) {
      await _plugin.cancel(id: descansoId);
      return;
    }

    final quando = proximaOcorrencia(lembrete, agora);
    await _plugin.zonedSchedule(
      id: descansoId,
      title: texto.titulo,
      body: texto.corpo,
      scheduledDate: tz.TZDateTime(
        tz.local,
        quando.year,
        quando.month,
        quando.day,
        quando.hour,
        quando.minute,
      ),
      notificationDetails: _detalhesDeLembrete('Hora do descanso'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _agendaRaiz(
    LembreteDoDia? lembrete,
    Map<TipoDeLembrete, TextoDeLembrete> textos,
    DateTime agora,
  ) async {
    final texto = textos[TipoDeLembrete.raizEmRisco];
    if (lembrete == null || texto == null) {
      await _plugin.cancel(id: raizHojeId);
      await _plugin.cancel(id: raizAmanhaId);
      return;
    }

    final detalhes = _detalhesDeLembrete('Raiz em risco');
    final hoje = DateTime(
      agora.year,
      agora.month,
      agora.day,
      lembrete.hora,
      lembrete.minuto,
    );

    if (hoje.isAfter(agora)) {
      await _agendaEm(raizHojeId, hoje, texto, detalhes);
    } else {
      // A hora do aviso já passou. Mandar agora seria chegar depois do
      // ponto em que ainda dava para fazer alguma coisa.
      await _plugin.cancel(id: raizHojeId);
    }

    await _agendaEm(
      raizAmanhaId,
      hoje.add(const Duration(days: 1)),
      texto,
      detalhes,
    );
  }

  Future<void> _agendaEm(
    int id,
    DateTime quando,
    TextoDeLembrete texto,
    NotificationDetails detalhes,
  ) async {
    await _plugin.zonedSchedule(
      id: id,
      title: texto.titulo,
      body: texto.corpo,
      scheduledDate: tz.TZDateTime(
        tz.local,
        quando.year,
        quando.month,
        quando.day,
        quando.hour,
        quando.minute,
      ),
      notificationDetails: detalhes,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  NotificationDetails _detalhesDeLembrete(String descricao) => NotificationDetails(
        android: AndroidNotificationDetails(
          canalLembretes,
          'Lembretes Baru',
          channelDescription: descricao,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  Future<void> syncSchedules({
    required bool evening,
    int eveningHour = 21,
    int eveningMinute = 0,
    required bool missed,
    required String eveningTitle,
    required String eveningBody,
    required String missedTitle,
    required String missedBody,
    required int daysAway,
    required bool trialActive,
    required DateTime? trialEndsAt,
    required String trialTitle,
    required String trialBody,
  }) async {
    if (kIsWeb || !_ready) return;

    await _syncTrialReminder(
      ativo: trialActive,
      fim: trialEndsAt,
      title: trialTitle,
      body: trialBody,
    );

    if (evening && await hasPermission()) {
      await _scheduleEvening(eveningTitle, eveningBody, eveningHour, eveningMinute);
    } else {
      await _plugin.cancel(id: _eveningId);
    }

    if (!missed || !await hasPermission()) {
      await _plugin.cancel(id: _missedId);
      return;
    }

    if (daysAway >= 2) {
      await _maybeShowMissed(missedTitle, missedBody);
    }
  }

  /// Aviso 24h antes do fim do teste — o contrato de produto §9 e a copy do
  /// paywall prometem esse recado.
  Future<void> _syncTrialReminder({
    required bool ativo,
    required DateTime? fim,
    required String title,
    required String body,
  }) async {
    if (!ativo || fim == null || !await hasPermission()) {
      await _plugin.cancel(id: _trialId);
      return;
    }

    final quando = tz.TZDateTime.from(
      fim.subtract(const Duration(hours: 24)),
      tz.local,
    );
    if (!quando.isAfter(tz.TZDateTime.now(tz.local))) {
      // As 24h já passaram: avisar agora seria avisar tarde.
      await _plugin.cancel(id: _trialId);
      return;
    }

    await _plugin.zonedSchedule(
      id: _trialId,
      title: title,
      body: body,
      scheduledDate: quando,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'baru_reminders',
          'Lembretes Baru',
          channelDescription: 'Fim do teste',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _scheduleEvening(
    String title,
    String body,
    int hora,
    int minuto,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hora,
      minuto,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: _eveningId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'baru_reminders',
          'Lembretes Baru',
          channelDescription: 'Relatório da noite',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _maybeShowMissed(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    if (prefs.getString(_lastMissedKey) == today) return;

    await _plugin.show(
      id: _missedId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'baru_reminders',
          'Lembretes Baru',
          channelDescription: 'Senti sua falta',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    await prefs.setString(_lastMissedKey, today);
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
