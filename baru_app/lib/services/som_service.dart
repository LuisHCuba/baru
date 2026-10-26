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
/// 2. Silencioso do sistema ganha do app, e a música de quem está ouvindo
///    não para. Por isso o contexto de áudio é declarado em [contexto]: o
///    padrão do `audioplayers` é tocar como **mídia pedindo foco
///    permanente**, e o Android tira o Spotify do ar a cada toque no bicho.
///    (O comentário antigo dizia que já era "sonification"; não era —
///    nenhum contexto era configurado.)
/// 3. Falha de áudio nunca sobe. Não ter alto-falante, estar num teste sem
///    plugin, o arquivo faltar — nada disso pode derrubar uma sessão de foco.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Os sons que o app tem.
///
/// Todos saem de `tool/sons/gera_sons.py`: madeira afinada (marimba e
/// kalimba), madeira seca e água, numa tonalidade só — Fá maior pentatônica —
/// e com o motivo Lá–Dó–Fá como família (laudo 04). O nível de cada um vem da
/// masterização, pela hierarquia do laudo (§4.4), não do volume do player.
enum SomDoBaru {
  /// Subiu de nível. O herói maior: o motivo com o grave e o topo em Fá.
  conquista,

  /// Marco da trilha. Parente do nível, sem o grave.
  marco,

  /// Missão resgatada. O motivo rápido em kalimba, em três inversões.
  resgate(variacoes: 3),

  /// Sessão de foco concluída.
  fim,

  /// Toque no companheiro. Uma nota da pentatônica, quatro tomadas — até a
  /// voz de cada espécie chegar.
  toque(variacoes: 4),

  /// Afago completo.
  carinho(variacoes: 3),

  /// A mão raspando a terra da toca. Toca a cada gesto de cavar.
  cavar(variacoes: 4),

  /// O prêmio saindo de dentro da toca.
  ///
  /// Separado do [resgate]: aquele é o "recebi", este é o "achei". O
  /// momento de abrir precisa de som próprio, senão a cena inteira acontece
  /// em silêncio e vira animação decorativa.
  premio,

  /// A chegada do dia. **Não é herói:** tocar o som de conquista todo dia
  /// gastava o som que marca conquista de verdade.
  chegada,

  /// Desistiu da sessão. Resolvido, descendo para a terça de Fá: "tudo bem",
  /// não "você falhou". Baixo de propósito.
  desistencia,

  /// Sessão começou: um respiro e uma nota, depois silêncio.
  inicio,

  /// Folhas creditadas.
  folhas,

  /// Compra na loja.
  compra,

  /// A raiz cresceu hoje. A cena inteira num arquivo, sincronizado com a
  /// animação (ver `CenaDaRaiz`): gota, toque na ponta, três notas subindo,
  /// o plim do contador.
  raiz,

  /// A raiz cresceu e chegou a um marco: a mesma subida mais o galho.
  raizMarco(arquivoBase: 'raiz_marco'),

  /// O bicho nasceu ou cresceu.
  crescimento;

  const SomDoBaru({this.variacoes = 1, this.arquivoBase});

  /// Quantas tomadas o som tem. Mais de uma, o serviço sorteia — o mesmo
  /// som idêntico toda vez é o que faz um som de app cansar.
  final int variacoes;

  final String? arquivoBase;

  String get _base => arquivoBase ?? name;

  /// Todos os arquivos deste som.
  List<String> get arquivos => [
        if (variacoes == 1)
          'sons/$_base.wav'
        else
          for (var i = 1; i <= variacoes; i++) 'sons/${_base}_$i.wav',
      ];

  /// O arquivo da tomada [i] (com volta).
  String arquivo([int i = 0]) => arquivos[i % arquivos.length];
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
  final _sorte = math.Random();

  /// Para o som que estiver tocando. A cena que é pulada não pode deixar o
  /// arpejo dela tocando sobre a tela seguinte.
  Future<void> para() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

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

  /// Efeito de interface, não mídia.
  ///
  /// Android: uso `assistanceSonification` (sai pelo volume do sistema, que o
  /// modo silencioso e o vibrar calam) e **nenhum** pedido de foco de áudio,
  /// então quem está tocando música continua tocando. iOS: categoria
  /// `ambient`, que obedece a chave lateral e mistura com o que estiver
  /// tocando.
  @visibleForTesting
  static final contexto = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    // `ambient` já mistura com o áudio dos outros apps — é a definição da
    // categoria. Pedir `mixWithOthers` junto não é redundância inofensiva: o
    // plugin recusa a combinação com uma asserção, e em modo debug todo som
    // falhava calado.
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  Future<void> _tocaDeVerdade(SomDoBaru som) async {
    if (!_armado) return;
    var p = _player;
    if (p == null) {
      // Só guarda o tocador depois de o contexto pegar. Guardado antes, uma
      // falha aqui deixava os sons seguintes tocando **sem** contexto — com
      // foco de áudio, que é justamente pausar a música da pessoa. Assim a
      // próxima vez tenta de novo, e o som que falhou só não toca.
      final novo = AudioPlayer();
      try {
        await novo.setAudioContext(contexto);
      } catch (_) {
        unawaited(novo.dispose().catchError((_) {}));
        rethrow;
      }
      p = _player = novo;
    }
    await p.setReleaseMode(ReleaseMode.stop);
    await p.setPlayerMode(PlayerMode.lowLatency);
    // Volume cheio: o nível de cada som foi decidido na masterização.
    await p.play(
      AssetSource(som.arquivo(_sorte.nextInt(som.variacoes))),
      volume: 1,
    );
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
