/// Som do Baru.
///
/// O §7 pede som curto na celebração. O que **não** se pede é um app que
/// apita: cada som aqui dura menos de 0,6 s, e nenhum toca duas vezes seguidas
/// em menos de meio segundo.
///
/// Três regras que valem mais que o som em si:
///
/// 1. O usuário pode desligar. Um app de foco que faz barulho sem permissão é
///    um app de distração.
/// 2. Silencioso do sistema ganha do app — o `audioplayers` já respeita o
///    perfil no Android e a chave lateral no iOS quando o contexto é de
///    "sonification", que é o que configuramos.
/// 3. Falha de áudio nunca sobe. Não ter alto-falante, estar num teste sem
///    plugin, o arquivo faltar — nada disso pode derrubar uma sessão de foco.
library;

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Os sons que o app tem. O nome é o arquivo em `assets/sons/`.
enum SomDoBaru {
  /// Nível novo ou marco alcançado.
  conquista,

  /// Missão resgatada.
  resgate,

  /// Sessão de foco concluída.
  fim,

  /// Toque no companheiro.
  toque,

  /// Afago completo.
  carinho,

  /// A mão raspando a terra da toca. Toca a cada gesto de cavar.
  cavar,

  /// O prêmio saindo de dentro da toca.
  ///
  /// Separado do [resgate]: aquele é o "recebi", este é o "achei". O
  /// momento de abrir precisa de som próprio, senão a cena inteira acontece
  /// em silêncio e vira animação decorativa.
  premio;

  String get arquivo => 'sons/$name.wav';
}

class SomService {
  SomService._();

  static final SomService instance = SomService._();

  /// Quem realmente toca. Nulo em produção — o teste injeta.
  ///
  /// Construir um `AudioPlayer` num ambiente sem o plugin registrado **fica
  /// pendente para sempre**: o construtor espera uma resposta de canal que
  /// nunca vem. Sem esta costura, um teste que encoste no som trava.
  @visibleForTesting
  Future<void> Function(SomDoBaru)? tocador;

  /// Registro do que foi tocado. Nulo em produção.
  @visibleForTesting
  static List<SomDoBaru>? espiao;

  AudioPlayer? _player;

  /// O app já subiu?
  ///
  /// `AudioPlayer` abre um `EventChannel` no construtor, e um canal exige o
  /// binding do Flutter. Num teste de unidade puro isso estoura **fora** do
  /// `try` — dentro de um listener de stream, noutra zona — e derruba o teste
  /// de quem só queria creditar XP. Então o player só nasce depois que o app
  /// diz que existe.
  bool _armado = false;

  void arma() => _armado = true;

  /// Preferência do usuário. Desligado, nada toca.
  bool ligado = true;

  /// Dois sons no mesmo instante viram ruído: o segundo espera.
  ///
  /// **Por som, não entre sons.** Era global, e isso quebrava sequências
  /// desenhadas de propósito: na toca, o `cavar` da pancada engolia o
  /// `premio` da abertura, e a cena que mais importa acontecia em silêncio.
  /// Repetir o **mesmo** som rápido é que vira ruído; sons diferentes em
  /// sequência são o desenho.
  static const _intervaloMinimo = Duration(milliseconds: 400);

  /// Quem é percussivo e feito para repetir.
  ///
  /// Cavar são três pancadas em um segundo: com o intervalo cheio, a
  /// segunda e a terceira sumiriam e o gesto ficaria mudo no meio.
  ///
  /// **Só estes.** A primeira versão desta correção trocou a regra para
  /// "por som" em todo o catálogo, e isso mudou coisas que ninguém pediu —
  /// tocar no bicho e completar um afago passaram a soar juntos. O limite
  /// global continua sendo a regra; a exceção é a lista.
  static const _percussivos = {SomDoBaru.cavar};

  static const _intervaloCurto = Duration(milliseconds: 90);
  DateTime? _ultimo;

  /// Relógio injetável — o teste não pode depender do relógio de parede.
  @visibleForTesting
  DateTime Function() agora = DateTime.now;

  final _ultimoDe = <SomDoBaru, DateTime>{};

  /// Esquece quando cada som tocou pela última vez.
  ///
  /// O serviço é singleton: sem isto, o limitador de um teste bloqueia o
  /// som do teste seguinte, e a suíte passa ou falha conforme a ordem.
  @visibleForTesting
  void esqueceOsUltimos() {
    _ultimo = null;
    _ultimoDe.clear();
  }

  /// Deve tocar agora?
  ///
  /// Separado de [toca] de propósito: é aqui que mora toda a decisão, e é
  /// isto que o teste consegue exercitar sem plugin de áudio.
  @visibleForTesting
  bool valeTocar(DateTime quando, [SomDoBaru? som]) {
    if (!ligado) return false;
    if (som != null && _percussivos.contains(som)) {
      final anterior = _ultimoDe[som];
      return anterior == null ||
          quando.difference(anterior) >= _intervaloCurto;
    }
    final anterior = _ultimo;
    if (anterior != null && quando.difference(anterior) < _intervaloMinimo) {
      return false;
    }
    return true;
  }

  Future<void> toca(SomDoBaru som) async {
    final quando = agora();
    if (!valeTocar(quando, som)) return;
    _ultimoDe[som] = quando;
    // Um som percussivo não empurra o relógio global: senão três pancadas
    // de cavar deixariam o som seguinte — o do prêmio — mudo.
    if (!_percussivos.contains(som)) _ultimo = quando;
    espiao?.add(som);

    try {
      // Timeout de verdade, não só try/catch: o modo de falha do áudio não é
      // estourar, é **nunca responder**. Sem prazo, um plugin travado deixa
      // um future pendente para sempre a cada som.
      await (tocador ?? _tocaDeVerdade)(som)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      // Sem alto-falante, sem plugin, arquivo faltando: o app segue. Som é
      // enfeite; sessão de foco não é.
      debugPrint('Baru: som falhou (${som.name}: $e)');
    }
  }

  Future<void> _tocaDeVerdade(SomDoBaru som) async {
    if (!_armado) return;
    final p = _player ??= AudioPlayer();
    await p.setReleaseMode(ReleaseMode.stop);
    await p.setPlayerMode(PlayerMode.lowLatency);
    await p.play(AssetSource(som.arquivo), volume: 0.55);
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }

  @visibleForTesting
  void reset() {
    _ultimo = null;
    _player = null;
    _armado = false;
  }
}
