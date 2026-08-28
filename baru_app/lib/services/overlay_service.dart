/// O companheiro por cima dos outros apps.
///
/// O Android chama isso de "desenhar sobre outros apps"
/// (`SYSTEM_ALERT_WINDOW`). É a única forma de o Baru aparecer enquanto a
/// pessoa está no TikTok — notificação some na aba, e um app de foco que só
/// fala quando está aberto não serve para nada.
///
/// **O que este arquivo não faz:** decidir a hora. Quem decide é o domínio,
/// olhando o tempo de tela. Aqui só existe o encanamento e a regra de não
/// insistir.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'notification_service.dart';
import 'usage_service.dart';

class OverlayService {
  OverlayService._();

  static final OverlayService instance = OverlayService._();

  static const _canal = MethodChannel('baru/overlay');

  /// Injetável: sem plataforma, um teste não consegue exercitar a regra.
  @visibleForTesting
  MethodChannel canal = _canal;

  /// Quantas vezes o Baru pode aparecer por dia, no máximo.
  ///
  /// Sem teto, o "gentil" vira perseguição — e o usuário desliga a permissão
  /// e nunca mais liga.
  static const aparicoesPorDia = 4;

  /// Intervalo mínimo entre duas aparições.
  static const intervaloMinimo = Duration(minutes: 25);

  /// Relógio injetável.
  @visibleForTesting
  DateTime Function() agora = DateTime.now;

  DateTime? _ultima;
  int _hoje = 0;
  DateTime? _diaDoContador;

  /// Registro do que foi pedido. Nulo em produção.
  @visibleForTesting
  static List<String>? espiao;

  Future<bool> temPermissao() async {
    if (!_ehAndroid) return false;
    try {
      return await canal.invokeMethod<bool>('temPermissao') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre a tela do sistema. Não dá para conceder por código.
  Future<void> pedePermissao() async {
    if (!_ehAndroid) return;
    try {
      await canal.invokeMethod<void>('pedePermissao');
    } catch (_) {}
  }

  /// Vale aparecer agora?
  ///
  /// Separado de [mostra] para o teste poder exercitar a regra sem
  /// plataforma — é aqui que mora a diferença entre companhia e assédio.
  @visibleForTesting
  bool valeAparecer(DateTime quando) {
    final dia = DateTime(quando.year, quando.month, quando.day);
    if (_diaDoContador != dia) {
      _diaDoContador = dia;
      _hoje = 0;
    }
    if (_hoje >= aparicoesPorDia) return false;
    final anterior = _ultima;
    if (anterior != null && quando.difference(anterior) < intervaloMinimo) {
      return false;
    }
    return true;
  }

  /// Mostra o balão. Devolve `false` quando a regra ou a permissão barram.
  Future<bool> mostra({
    required String fala,
    required int pelo,
    required String especie,
    required String acaoFechar,
    required String acaoMais,
  }) async {
    final quando = agora();
    if (!valeAparecer(quando)) return false;
    if (!await temPermissao()) return false;

    _ultima = quando;
    _hoje += 1;
    espiao?.add(fala);

    try {
      return await canal.invokeMethod<bool>('mostra', {
            'fala': fala,
            'pelo': pelo,
            'especie': especie,
            'acaoFechar': acaoFechar,
            'acaoMais': acaoMais,
          }) ??
          false;
    } catch (e) {
      debugPrint('Baru: overlay falhou ($e)');
      return false;
    }
  }

  Future<void> esconde() async {
    if (!_ehAndroid) return;
    try {
      await canal.invokeMethod<void>('esconde');
    } catch (_) {}
  }

  bool get _ehAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @visibleForTesting
  void reset() {
    _ultima = null;
    _hoje = 0;
    _diaDoContador = null;
  }
}

/// As permissões que o Baru precisa para cumprir o que promete.
///
/// **Por que existe uma lista.** No aparelho do dono do produto o acesso ao
/// uso estava concedido e "desenhar sobre outros apps" estava negada — e o
/// app não dizia nada. O companheiro simplesmente nunca aparecia, o que é
/// indistinguível de estar quebrado. Uma permissão que ninguém enumera é uma
/// permissão que ninguém percebe faltando.
enum PermissaoDoBaru {
  /// `PACKAGE_USAGE_STATS`. Sem ela não há tempo de tela nenhum.
  usoDoAparelho,

  /// `SYSTEM_ALERT_WINDOW`. É esta que faltava.
  sobreOutrosApps,

  /// `POST_NOTIFICATIONS`.
  notificacoes,

  /// `SCHEDULE_EXACT_ALARM`.
  alarmeExato,
}

/// Estado e pedido das quatro permissões, num lugar só.
///
/// Elas moram em quatro serviços diferentes (uso, sobreposição, notificação e
/// o `permission_handler`), e é exatamente por isso que ninguém as via
/// juntas. Aqui há uma lista, e uma tela consegue percorrer a lista.
///
/// **Nenhum método daqui estoura.** Fora do Android, num teste sem plataforma
/// ou num aparelho sem o serviço, a resposta honesta é "não concedida" — e a
/// tela mostra o caminho de conceder em vez de morrer.
class Permissoes {
  const Permissoes._();

  /// A ordem em que o onboarding pergunta: da que mais muda o produto para a
  /// que menos muda. Quem desistir no meio já concedeu o que mais importa.
  static const todas = [
    PermissaoDoBaru.usoDoAparelho,
    PermissaoDoBaru.sobreOutrosApps,
    PermissaoDoBaru.notificacoes,
    PermissaoDoBaru.alarmeExato,
  ];

  /// Sonda injetável. Sem isto, um teste de widget não consegue exercitar a
  /// diferença entre "concedida" e "negada" — que é a tela inteira.
  @visibleForTesting
  static Future<bool> Function(PermissaoDoBaru)? sonda;

  /// Registro dos pedidos feitos. Nulo em produção.
  @visibleForTesting
  static List<PermissaoDoBaru>? espiao;

  /// As que existem nesta plataforma.
  ///
  /// Sobreposição e alarme exato são conceitos do Android; no iOS a Apple não
  /// deixa um app desenhar por cima de outro, e perguntar por algo que não
  /// existe é pior que não perguntar.
  static List<PermissaoDoBaru> daPlataforma() {
    final ehAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (ehAndroid) return todas;
    return const [
      PermissaoDoBaru.usoDoAparelho,
      PermissaoDoBaru.notificacoes,
    ];
  }

  static Future<bool> concedida(PermissaoDoBaru p) async {
    final duble = sonda;
    if (duble != null) return duble(p);
    try {
      switch (p) {
        case PermissaoDoBaru.usoDoAparelho:
          return await UsageService.instance.hasUsageAccess();
        case PermissaoDoBaru.sobreOutrosApps:
          return await OverlayService.instance.temPermissao();
        case PermissaoDoBaru.notificacoes:
          return await BaruNotifications.instance.hasPermission();
        case PermissaoDoBaru.alarmeExato:
          return await Permission.scheduleExactAlarm.isGranted;
      }
    } catch (_) {
      // `MissingPluginException` em teste, `PlatformException` em aparelho
      // exótico. Nenhuma das duas é motivo para a tela não abrir.
      return false;
    }
  }

  /// Leva a pessoa até onde a permissão se concede. Nenhuma delas é
  /// concedida por código — o pedido abre um diálogo ou uma tela do sistema.
  ///
  /// Não devolve o resultado de propósito: a resposta só chega quando o app
  /// volta ao primeiro plano, e quem observa isso é o ciclo de vida da tela.
  static Future<void> pede(PermissaoDoBaru p) async {
    espiao?.add(p);
    if (sonda != null) return;
    try {
      switch (p) {
        case PermissaoDoBaru.usoDoAparelho:
          await UsageService.instance.requestUsageAccess();
        case PermissaoDoBaru.sobreOutrosApps:
          await OverlayService.instance.pedePermissao();
        case PermissaoDoBaru.notificacoes:
          await BaruNotifications.instance.ensurePermission();
        case PermissaoDoBaru.alarmeExato:
          await Permission.scheduleExactAlarm.request();
      }
    } catch (_) {
      // Idem: a tela continua de pé e a permissão continua pendente.
    }
  }
}
