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
