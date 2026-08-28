/// O vigia da sessão de foco.
///
/// **O buraco que isto tapa.** Durante uma sessão, sair do Baru para o
/// TikTok não fazia nada: nenhum aviso, nenhuma chamada de volta. A causa
/// não estava em regra de domínio nenhuma — com o app em segundo plano o
/// Flutter **não executa**. O único gatilho do companheiro morava no
/// `didChangeAppLifecycleState`, que só dispara quando a pessoa **volta**,
/// e um aviso que chega depois da volta não serve para nada.
///
/// Quem roda fora do app é um serviço em primeiro plano do Android. Este
/// arquivo é só o encanamento: quem decide **quando** e **o que dizer**
/// continua sendo o domínio, e a fala chega ao lado nativo já traduzida.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// O ícone do app na gaveta é o bicho da pessoa.
///
/// O Android não deixa trocar o ícone de um app instalado. O que se troca é
/// **qual componente responde por LAUNCHER**: o manifesto tem um
/// `activity-alias` por espécie, e exatamente um fica ligado.
///
/// Só espécie, não humor. Trocar de ícone faz muitos launchers removerem e
/// recolocarem o atalho — em alguns ele some da tela inicial. Uma troca
/// quando a pessoa escolhe o bicho é aceitável; uma a cada mudança de humor
/// faria o ícone piscar na cara dela o dia inteiro. O humor aparece onde
/// custa zero: no habitat, na notificação e no overlay.
class IconeService {
  IconeService._();

  static final IconeService instance = IconeService._();

  static const _canal = MethodChannel('baru/overlay');

  @visibleForTesting
  MethodChannel canal = _canal;

  /// Só fala com a plataforma depois de armado.
  ///
  /// `MethodChannel` exige binding. O domínio é testado em Dart puro, sem
  /// binding nenhum, e uma chamada a partir de `pickSpecies` ou
  /// `startSession` derrubava vinte e um testes com "Binding has not yet
  /// been initialized" — mesma armadilha do `AudioPlayer`. Quem arma é o
  /// `BaruApp.initState`, que só existe quando há app de verdade.
  bool _armado = false;

  void arma() => _armado = true;

  /// A última espécie pedida, para não repetir a troca à toa.
  String? _atual;

  @visibleForTesting
  void zeraParaTeste() {
    _atual = null;
    _armado = true;
  }

  Future<bool> usa(String especie) async {
    if (!_armado || kIsWeb || especie.isEmpty || especie == _atual) {
      return false;
    }
    try {
      final ok = await canal.invokeMethod<bool>('trocaIcone', {
        'especie': especie,
      });
      if (ok ?? false) _atual = especie;
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

class VigiaService {
  VigiaService._();

  static final VigiaService instance = VigiaService._();

  static const _canal = MethodChannel('baru/overlay');

  /// Injetável: sem plataforma, um teste não exercita regra nenhuma.
  @visibleForTesting
  MethodChannel canal = _canal;

  /// O vigia está de pé neste momento.
  bool get vigiando => _vigiando;
  bool _vigiando = false;

  /// Só fala com a plataforma depois de armado.
  ///
  /// `MethodChannel` exige binding. O domínio é testado em Dart puro, sem
  /// binding nenhum, e uma chamada a partir de `pickSpecies` ou
  /// `startSession` derrubava vinte e um testes com "Binding has not yet
  /// been initialized" — mesma armadilha do `AudioPlayer`. Quem arma é o
  /// `BaruApp.initState`, que só existe quando há app de verdade.
  bool _armado = false;

  void arma() => _armado = true;


  @visibleForTesting
  void zeraParaTeste() {
    _vigiando = false;
    _armado = true;
  }

  /// A chave da fala padrão dentro do dicionário que vai para o vigia.
  ///
  /// Um sublinhado porque nenhum pacote Android se chama assim: não há como
  /// um app real colidir com ela.
  static const chaveDaFalaPadrao = '_';

  /// Empacota a fala padrão e as falas por app numa string só.
  ///
  /// **Por que uma string e não um argumento novo.** O caminho até o vigia
  /// passa pelo `MainActivity`, que copia extras nomeados um a um para o
  /// `Intent` do serviço. Um argumento que ele não conhece é descartado em
  /// silêncio — o mapa nunca chegaria. O campo `fala` já atravessa esse
  /// caminho inteiro, então é ele que carrega o dicionário.
  ///
  /// Fica legível dos dois lados: JSON de um nível, `{"pacote": "fala"}`,
  /// com a fala padrão em [chaveDaFalaPadrao]. Sem falas por app o formato
  /// não muda — vai a string crua, como sempre foi, e o lado nativo não
  /// precisa saber que este recurso existe.
  ///
  /// O que **não** acontece aqui: escrever texto. Toda frase já chega
  /// traduzida do catálogo; isto é envelope, não conteúdo.
  @visibleForTesting
  static String empacotaFalas(String padrao, Map<String, String> porPacote) {
    if (porPacote.isEmpty) return padrao;
    return jsonEncode({chaveDaFalaPadrao: padrao, ...porPacote});
  }

  /// Começa a vigiar. Idempotente.
  ///
  /// Chamar duas vezes não empilha dois serviços — e não chamar de novo a
  /// cada retomada do app evita reiniciar o descanso entre aparições, que é
  /// o que impede o companheiro de virar assédio.
  ///
  /// [falasPorPacote] é o dicionário pacote→fala já traduzido. Ele existe
  /// porque "o YouTube de novo?" e "o TikTok de novo?" são falas diferentes,
  /// e só o lado nativo sabe qual app está na frente no instante em que o
  /// companheiro aparece. Vazio: todo mundo ouve [fala].
  Future<bool> comeca({
    required String fala,
    required int pelo,
    required String especie,
    required String acaoFechar,
    required String acaoMais,
    required String notifTitulo,
    required String notifCorpo,
    Map<String, String> falasPorPacote = const {},
  }) async {
    if (!_armado || kIsWeb || _vigiando) return _vigiando;
    try {
      final ok = await canal.invokeMethod<bool>('vigiaComeca', {
        'fala': empacotaFalas(fala, falasPorPacote),
        'pelo': pelo,
        'especie': especie,
        'acaoFechar': acaoFechar,
        'acaoMais': acaoMais,
        'notifTitulo': notifTitulo,
        'notifCorpo': notifCorpo,
      });
      _vigiando = ok ?? false;
      return _vigiando;
    } on MissingPluginException {
      // Plataforma sem o canal: web, desktop, teste. A sessão continua
      // inteira — só não há quem chame de volta.
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Para de vigiar. Idempotente, e chamada em todo fim de sessão —
  /// concluída, abandonada ou reconciliada pelo relógio. Um vigia que
  /// sobrevive à sessão é uma notificação fixa que não sai mais.
  Future<void> para() async {
    // Sem o guarda de `_vigiando`: se o app for morto durante a sessão, o
    // serviço sobrevive (é essa a graça dele) mas o Dart renasce sem
    // memória nenhuma. Um `para()` que desiste porque "não estava
    // vigiando" deixaria a notificação fixa para sempre na barra. Parar
    // duas vezes não custa nada; parar de menos custa caro.
    if (!_armado || kIsWeb) return;
    _vigiando = false;
    try {
      await canal.invokeMethod<void>('vigiaPara');
    } on MissingPluginException {
      // Nada a parar.
    } on PlatformException {
      // Idem.
    }
  }
}
