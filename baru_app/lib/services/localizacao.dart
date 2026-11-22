import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Estado da permissão de localização neste celular.
/// Versão do app mandada ao servidor (o responsável vê quando o celular da
/// criança está com uma versão antiga). Igual ao `version` do pubspec.yaml.
const versaoDoApp = '1.0.14+24';

enum PermissaoDeLocal {
  /// Localização do sistema desligada.
  desligada,

  /// Nunca pedida (iPhone).
  naoPedida,
  negada,

  /// Só com o app aberto: não avisa chegou/saiu com o Baru fechado.
  quandoUsa,
  sempre;

  bool get concedida => this == quandoUsa || this == sempre;

  /// Nome guardado no servidor (`baru_familia_aparelhos.local_estado`).
  String get noServidor => switch (this) {
        desligada => 'desligada',
        naoPedida => 'nao_pedida',
        negada => 'negada',
        quandoUsa => 'quando_usa',
        sempre => 'sempre',
      };

  static PermissaoDeLocal de(String? s) => switch (s) {
        'desligada' => desligada,
        'nao_pedida' => naoPedida,
        'quando_usa' => quandoUsa,
        'sempre' => sempre,
        _ => negada,
      };
}

/// Uma posição lida agora no aparelho.
@immutable
class PosicaoAgora {
  const PosicaoAgora({required this.lat, required this.lng, this.precisaoM, this.bateria});
  final double lat;
  final double lng;
  final int? precisaoM;
  final int? bateria;
}

/// Canal "baru/local" (LocalDaFamilia.kt e LocalDaFamilia.swift). Sem
/// plataforma nativa (web, testes), responde como "desligada".
class LocalNativo {
  LocalNativo._();

  static const _canal = MethodChannel('baru/local');

  /// Para os testes trocarem o canal.
  @visibleForTesting
  static Future<dynamic> Function(String metodo, [Object? args])? sonda;

  static Future<T?> _chama<T>(String metodo, [Object? args]) async {
    if (sonda != null) return await sonda!(metodo, args) as T?;
    if (kIsWeb) return null;
    try {
      return await _canal.invokeMethod<T>(metodo, args);
    } catch (e) {
      debugPrint('Baru: localização não respondeu ($metodo) — $e');
      return null;
    }
  }

  static Future<PermissaoDeLocal> estado() async => PermissaoDeLocal.de(await _chama<String>('estado'));

  /// Pede a permissão. [sempre]: também "o tempo todo", para chegou/saiu com o app fechado.
  static Future<PermissaoDeLocal> pedir({bool sempre = true}) async =>
      PermissaoDeLocal.de(await _chama<String>('pedir', {'sempre': sempre}));

  static Future<PosicaoAgora?> agora() async {
    final m = await _chama<Map<dynamic, dynamic>>('agora');
    if (m == null || m['lat'] == null) return null;
    return PosicaoAgora(
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      precisaoM: (m['precisao'] as num?)?.toInt(),
      bateria: (m['bateria'] as num?)?.toInt(),
    );
  }

  /// Celular da criança: liga/desliga o envio da posição com o app fechado.
  static Future<void> configura({required bool ligada, String? chave, required String url, required String anon}) =>
      _chama('configura', {'ligada': ligada, 'chave': chave, 'url': url, 'anon': anon});

  /// Celular do responsável: chave e textos dos avisos (nulo desliga).
  static Future<void> avisos(String? json) => _chama('avisos', {'json': json});

  static Future<void> abrirAjustes() => _chama('abrirAjustes');
}
