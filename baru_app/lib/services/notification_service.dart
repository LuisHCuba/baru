import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../data/descanso_retencao.dart';

/// Notificações locais: relatório da noite (21h) e "senti sua falta".
class BaruNotifications {
  BaruNotifications._();

  static final BaruNotifications instance = BaruNotifications._();

  static const _eveningId = 1001;
  static const _missedId = 1002;
  static const _trialId = 1003;

  /// A sessão em curso, fixa na barra.
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
  static const _lastMissedKey = 'baru_last_missed_notify';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Chamado quando o usuário toca "Desistir" na notificação da sessão.
  /// Ligado pelo app; nulo em teste e em web.
  void Function()? aoDesistirPelaBarra;

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
      onDidReceiveNotificationResponse: (resposta) {
        if (resposta.actionId == acaoDesistir) {
          aoDesistirPelaBarra?.call();
        }
      },
    );

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

    await _plugin.show(
      id: sessaoId,
      title: titulo,
      body: corpo,
      notificationDetails: detalhesDaSessao(
        terminaEm: terminaEm,
        rotuloDesistir: rotuloDesistir,
      ),
    );
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
        actions: [
          AndroidNotificationAction(
            acaoDesistir,
            rotuloDesistir,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: false,
        presentBanner: false,
      ),
    );
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
  Future<void> encerraSessao() async {
    if (kIsWeb || !_ready) return;
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
