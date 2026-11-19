import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ponte com o Screen Time da Apple (ios/Runner/TempoDeTelaPlugin.swift).
///
/// No iPhone o app nunca recebe minutos por app: escolhe os apps pelo seletor
/// da Apple, define a meta, e a extensão `BaruMonitor` registra no App Group
/// quais limiares da meta foram atingidos hoje. É isso que chega aqui.
@immutable
class EstadoTempoDeTela {
  const EstadoTempoDeTela({
    required this.suportado,
    this.autorizacao = 'naoDecidido',
    this.modo = 'individual',
    this.metaMin = 0,
    this.apps = 0,
    this.categorias = 0,
    this.sites = 0,
    this.monitorando = false,
    this.atingidosHoje = const [],
    this.escudoAoEstourar = false,
  });

  factory EstadoTempoDeTela.doMapa(Map<dynamic, dynamic> m) => EstadoTempoDeTela(
        suportado: m['suportado'] == true,
        autorizacao: m['autorizacao'] as String? ?? 'naoDecidido',
        modo: m['modo'] as String? ?? 'individual',
        metaMin: (m['metaMin'] as num?)?.toInt() ?? 0,
        apps: (m['apps'] as num?)?.toInt() ?? 0,
        categorias: (m['categorias'] as num?)?.toInt() ?? 0,
        sites: (m['sites'] as num?)?.toInt() ?? 0,
        monitorando: m['monitorando'] == true,
        atingidosHoje: ((m['atingidosHoje'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        escudoAoEstourar: m['escudoAoEstourar'] == true,
      );

  static const indisponivel = EstadoTempoDeTela(suportado: false);

  final bool suportado;

  /// `aprovado`, `negado` ou `naoDecidido`.
  final String autorizacao;

  /// `individual` (a pessoa cuida de si) ou `crianca` (autorizado pelo responsável).
  final String modo;
  final int metaMin;
  final int apps;
  final int categorias;
  final int sites;
  final bool monitorando;

  /// Minutos dos limiares já atingidos hoje, em ordem.
  final List<int> atingidosHoje;
  final bool escudoAoEstourar;

  bool get autorizado => autorizacao == 'aprovado';
  bool get temEscolha => apps + categorias + sites > 0;

  /// Melhor estimativa do uso de hoje: o maior limiar atingido (piso, não exato).
  int get minutosAoMenos => atingidosHoje.isEmpty ? 0 : atingidosHoje.last;

  /// Fração da meta já usada, de 0 em diante (1.0 = meta batida).
  double get fracaoDaMeta => metaMin <= 0 ? 0 : minutosAoMenos / metaMin;
}

class TempoDeTelaIos {
  TempoDeTelaIos._();

  static const _canal = MethodChannel('baru/tempo_de_tela');

  static bool get disponivel => !kIsWeb && Platform.isIOS;

  static Future<EstadoTempoDeTela> _chama(String metodo, [Map<String, Object?>? args]) async {
    if (!disponivel) return EstadoTempoDeTela.indisponivel;
    final r = await _canal.invokeMethod<Map<dynamic, dynamic>>(metodo, args);
    return r == null ? EstadoTempoDeTela.indisponivel : EstadoTempoDeTela.doMapa(r);
  }

  static Future<EstadoTempoDeTela> estado() => _chama('estado');

  /// `crianca` só funciona com a conta da criança no Compartilhamento Familiar:
  /// o iOS pede a senha/Face ID do responsável no próprio aparelho.
  static Future<EstadoTempoDeTela> pedirAutorizacao({bool crianca = false}) =>
      _chama('pedirAutorizacao', {'modo': crianca ? 'crianca' : 'individual'});

  static Future<EstadoTempoDeTela> escolherApps() => _chama('escolherApps');

  static Future<EstadoTempoDeTela> definirMeta(int minutos) =>
      _chama('definirMeta', {'minutos': minutos});

  static Future<EstadoTempoDeTela> pararMonitoramento() => _chama('pararMonitoramento');

  /// Horários sem tela, pausa e filtro de sites que o responsável definiu.
  /// O sistema aplica com o Baru fechado.
  static Future<EstadoTempoDeTela> aplicarRegras({
    required List<Map<String, Object>> horarios,
    DateTime? pausaAte,
    bool filtro = false,
  }) =>
      _chama('aplicarRegras', {
        'horarios': horarios,
        'pausaAteMs': pausaAte?.millisecondsSinceEpoch,
        'filtro': filtro,
      });

  /// Chave do aparelho e endereço do banco: o iPhone busca as regras sozinho
  /// quando chega o push silencioso da família.
  static Future<EstadoTempoDeTela> guardaChave({
    required String? chave,
    required String url,
    required String anon,
    required bool sandbox,
  }) =>
      _chama('guardaChave', {'chave': chave, 'url': url, 'anon': anon, 'sandbox': sandbox});

  static Future<EstadoTempoDeTela> definirEscudo({required bool ativo}) =>
      _chama('definirEscudo', {'ativo': ativo});
}
