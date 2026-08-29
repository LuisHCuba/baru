
/// O companheiro do Baru.
///
/// Duas coisas moram aqui e nenhuma é opcional para o produto:
///
/// **Forma.** Cada espécie tem silhueta própria, desenhada com `Path` e curvas
/// de Bézier, em camadas de anatomia — corpo, barriga, membros, cauda, cabeça,
/// orelhas, focinho, olhos. A versão anterior empilhava retângulos
/// arredondados: a lontra era uma barra com uma bola em cima, e os tufos da
/// coruja flutuavam soltos, desencaixados da cabeça.
///
/// **Movimento.** Um rig simples ([_Pose]) calcula o deslocamento de cada
/// parte a cada quadro. O bicho respira, pisca — às vezes duas vezes seguidas
/// —, mexe as orelhas, balança a cauda, rema quando nada, mastiga quando
/// pasta, e **olha para onde você tocou**.
///
/// **Atividade.** Além do contínuo, cada atividade tem um laço próprio
/// ([_ciclo]): a braçada, a batida de asa, a mastigada, o salto. O contínuo
/// diz que ele está vivo; o laço diz o que ele está fazendo. Eram a mesma
/// coisa antes, e por isso "nadando" e "parado" saíam quase idênticos na
/// tela — o corpo só boiava mais forte.
///
/// Com "reduzir movimento" ligado o contínuo e o laço param e a pose fica
/// neutra, mas o toque continua respondendo, com amplitude menor. A pose
/// neutra de cada atividade continua sendo diferente das outras: quem pediu
/// menos movimento perde a animação, não a informação.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/som_service.dart';
import '../theme.dart';

/// Um gesto de ocioso: o que o bicho faz quando ninguém está pedindo nada.
///
/// Sem isso o repouso é só a respiração em laço, e laço curto o olho pega em
/// segundos — passa a impressão de sprite, não de bicho.
enum GestoOcioso {
  nenhum,
  espreguica,
  sacode,
  olhaEmVolta,
  coca,
  fareja,
  saltinho,
}

/// O que a espécie **de fato** faz quando a cena pede uma atividade.
///
/// [Activity] nasce do humor (`state.dart`) e é a mesma para as oito
/// espécies. Isso basta para "está descansando" e não basta para "está
/// nadando": coruja não nada, pinguim não pasta, gata não entra na água.
/// Aqui a atividade pedida vira a ação daquele bicho — e é a ação que o
/// desenho **e a legenda** seguem. Se a tela diz que ele está voando, ele
/// tem de estar voando.
///
/// A alternativa descartada foi acrescentar valores a [Activity]: ela é
/// persistida indiretamente pelo humor e lida por `habitat.dart` e
/// `state.dart`, arquivos de outra frente. A tradução mora aqui, onde o
/// desenho está, e nada mais no app precisa saber dela.
enum AcaoDoBicho {
  /// À toa, no chão, sem tarefa.
  ocioso,

  /// Dormindo.
  cochilo,

  /// Nadando de verdade, com o corpo na linha d'água.
  nado,

  /// Voando: só a coruja.
  voo,

  /// Pastando: cabeça no chão, mastiga embaixo.
  pasto,

  /// Petiscando: pega no chão e mastiga com a cabeça erguida.
  petisco,

  /// Brincando na beira: agacha, salta, cai.
  brincadeira,
}

/// Traduz a atividade da cena para o que **esta** espécie faz.
///
/// As decisões, uma a uma:
///
/// - **Nada:** capivara, lontra, pinguim, axolote e tartaruga. A tartaruga do
///   app é de orelha vermelha (a listra está desenhada em `_tartaruga`), que
///   é aquática — ela nada tanto quanto a lontra.
/// - **Coruja no lugar do nado: voa.** É o que o dono do produto pediu em
///   palavras — "está falando que ele está voando? tem que estar voando".
/// - **Gata e raposa no lugar do nado: brincam.** Nenhuma das duas entra na
///   água por vontade própria. Desenhá-las nadando seria bonito e falso; o
///   salto na beira entrega a mesma energia da atividade de humor radiante.
/// - **Pasta:** capivara e tartaruga, as duas herbívoras de pastagem. As
///   outras sete **petiscam**: a lontra abre um molusco, o pinguim engole um
///   peixe, a coruja come no poleiro, a gata e a raposa comem o que
///   caçaram, o buldogue come o que lhe serviram, o axolote suga do fundo.
///   Mecanicamente é o mesmo laço; o que muda é onde a mastigação acontece —
///   no chão ou com a cabeça erguida.
AcaoDoBicho acaoDoBicho(Species especie, Activity atividade) {
  switch (atividade) {
    case Activity.nap:
      return AcaoDoBicho.cochilo;
    case Activity.idle:
      return AcaoDoBicho.ocioso;
    case Activity.swim:
      switch (especie) {
        case Species.capybara:
        case Species.otter:
        case Species.penguin:
        case Species.axolotl:
        case Species.tortoise:
          return AcaoDoBicho.nado;
        case Species.owl:
          return AcaoDoBicho.voo;
        case Species.cat:
        case Species.fox:
        // Buldogue francês **não nada**, e não é opinião: focinho achatado,
        // tronco denso e patas curtas fazem o cão braquicefálico afundar de
        // frente. Criador nenhum solta um sem colete. Desenhá-lo nadando
        // seria bonito e falso — ele brinca na beira, como a gata e a
        // raposa.
        case Species.frenchie:
          return AcaoDoBicho.brincadeira;
      }
    case Activity.graze:
      switch (especie) {
        case Species.capybara:
        case Species.tortoise:
          return AcaoDoBicho.pasto;
        case Species.otter:
        case Species.owl:
        case Species.axolotl:
        case Species.penguin:
        case Species.cat:
        case Species.fox:
        case Species.frenchie:
          return AcaoDoBicho.petisco;
      }
  }
}

/// Quem mergulha em vez de boiar.
///
/// Capivara e tartaruga nadam com o dorso fora da água e a cabeça alta — o
/// corpo é o flutuador. Lontra, pinguim e axolote são torpedos: afundam
/// menos o corpo e mais a linha do dorso, e o que os move é a ondulação,
/// não a remada das patas. Desenhar os cinco iguais faria a lontra parecer
/// uma capivara de outra cor.
bool _mergulhador(Species especie) =>
    especie == Species.otter ||
    especie == Species.penguin ||
    especie == Species.axolotl;

/// As marcações de pelagem do buldogue francês.
///
/// Só esta espécie tem: nas outras oito a paleta é uma escada de tons do
/// mesmo pelo, e trocar de índice é trocar de intensidade. No buldogue as
/// entradas são pelos de registro diferentes — fulvo, tigrado, pied — e cada
/// um vem com um desenho junto. Ignorar isso deixava as seis opções da loja
/// sendo o mesmo cão em seis tintas.
enum _MarcaDoBuldogue {
  /// Fulvo: a frente da cara escura, subindo em dois lobos até os olhos.
  mascara,

  /// Pied: peito, patas e uma faixa no meio da cara em branco.
  pied,

  /// Tigrado: listras verticais no corpo e na cabeça.
  tigrado,

  /// Blue e preto: pelo liso. É o que o padrão da raça dá para eles.
  solida,
}

// --- ritmos das atividades ---------------------------------------------
//
// Ficam aqui, e não em `design/motion.dart`, pelo mesmo motivo dos outros
// tempos deste arquivo: são cadências de anatomia, não de interface. Cada
// número é a resposta a um defeito visto na tela, anotado ao lado.

/// Uma braçada. Mais lento não lê como nado, lê como boia à deriva.
const _cicloDoNado = Duration(milliseconds: 1150);

/// Uma batida de asa. Curta: asa lenta é planeio, e planeio parece parado.
const _cicloDoVoo = Duration(milliseconds: 820);

/// Abaixa, mastiga, levanta, olha em volta. Longo de propósito — é um
/// ritmo, não um tique. Abaixo de uns 4 s vira mordida nervosa.
const _cicloDoPasto = Duration(milliseconds: 5600);

/// Agacha, salta, cai, assenta.
const _cicloDaBrincadeira = Duration(milliseconds: 1900);

/// À toa: a troca de apoio de pé. Lento a ponto de não se notar de propósito
/// — o que se nota é a ausência dela.
const _cicloDoOcio = Duration(milliseconds: 7400);

/// Dormindo, o laço só carrega a folha que desceu nele.
const _cicloDoSono = Duration(milliseconds: 13000);

/// Respiração de quem dorme: quase o dobro do período normal, e mais funda.
const _respiracaoDormindo = Duration(milliseconds: 6400);

/// Respiração de quem está se esforçando — nadando, voando, brincando.
const _respiracaoNoEsforco = Duration(milliseconds: 2200);

class PetView extends StatefulWidget {
  const PetView({
    super.key,
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
    this.scale = 1,
    this.width = 200,
    this.height = 150,
    this.alignment = Alignment.center,
    this.interativo = true,
    this.aoCarinho,
    this.roupas = const {},
    this.roupaDeCabeca,
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final int coat;
  final double scale;
  final double width;
  final double height;
  final Alignment alignment;

  /// Responde ao toque. Desligado em miniaturas e capturas.
  final bool interativo;

  /// Um afago completo: o dedo percorreu o bicho até ele ficar satisfeito.
  /// Dispara uma vez por gesto.
  final VoidCallback? aoCarinho;

  /// O que ele está vestindo, por lugar do corpo.
  final Map<Vestimenta, Color> roupas;

  /// O id da peça de cabeça, que muda o desenho.
  final String? roupaDeCabeca;

  /// Quanto o dedo precisa percorrer para encher a satisfação.
  ///
  /// Curto demais e o carinho vira um toque; longo demais e ninguém chega ao
  /// fim. 520 px é da ordem de três passadas no corpo inteiro.
  static const percursoDoAfago = 520.0;

  /// A cada tanto de percurso, um clique — o ronronar.
  static const passoDoRonrom = 26.0;

  /// Chave da camada que o teste captura para provar que o desenho mudou.
  static const cenaKey = Key('pet-cena');

  /// Onde a lâmina d'água cruza o quadro do bicho, para uma dada altura.
  ///
  /// Público porque quem desenha água atrás dele precisa desenhar **na mesma
  /// linha**: duas lâminas em alturas diferentes leem como defeito, não como
  /// cena. Sai da posição do corpo (`altura/2 + 10`) mais os 2 px que o
  /// painter usa — ver a nota em `_PetPainter.paint`.
  static double linhaDaguaEm(double altura) => altura / 2 + 12;

  /// Espelha o gesto de ocioso em curso, para o teste poder afirmar que ele
  /// aconteceu. Nulo em produção — o gesto é sorteado por um `Timer` e não há
  /// como observá-lo de fora sem esta costura.
  @visibleForTesting
  static ValueNotifier<GestoOcioso>? observadorDeGesto;

  /// Fixa qual gesto será sorteado. Nulo em produção — existe porque uma
  /// captura de evidência do bocejo não pode depender de um dado de três
  /// faces cair no lado certo.
  @visibleForTesting
  static GestoOcioso? gestoForcado;

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _respiro = AnimationController(
    vsync: this,
    duration: Tempo.respiracao,
  );

  /// Período diferente do da respiração de propósito: se os dois ciclos
  /// batessem, o movimento pareceria mecânico.
  late final AnimationController _flutua = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4700),
  );

  /// A cauda tem ritmo próprio, mais solto.
  late final AnimationController _cauda = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// O laço da atividade: uma volta completa do que ele está fazendo.
  ///
  /// `repeat()` **sem** `reverse`, ao contrário dos outros três. Uma braçada
  /// não é simétrica: a pata puxa e volta por caminhos diferentes, e a
  /// pastagem é abaixa → mastiga → levanta → olha, que de trás para a frente
  /// vira outra coisa. Com `reverse` o bicho desmastigava.
  late final AnimationController _ciclo = AnimationController(
    vsync: this,
    duration: _cicloDoOcio,
  );

  late final AnimationController _pisca = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );

  /// Orelha treme rápido e volta.
  late final AnimationController _orelha = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    animationBehavior: AnimationBehavior.preserve,
  );

  /// `preserve` de propósito: com "reduzir movimento" o Flutter encurta a
  /// duração de um controller para 5% — a reação ao toque acabaria antes de
  /// ser vista. Amplitude a gente reduz; o feedback fica.
  late final AnimationController _toque = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Gesto de ocioso: espreguiçar, sacudir a cabeça, olhar em volta.
  late final AnimationController _gesto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
    animationBehavior: AnimationBehavior.preserve,
  );

  final _sorte = math.Random();
  Timer? _proximoPiscar;
  Timer? _proximaOrelha;
  Timer? _proximoGesto;
  GestoOcioso _gestoAtual = GestoOcioso.nenhum;
  bool _continuoLigado = false;

  /// Para onde o bicho está olhando, de -1 a 1 em cada eixo.
  Offset _olhar = Offset.zero;
  Timer? _voltaAOlharPraFrente;

  /// Toques seguidos: a partir do terceiro ele se anima de verdade.
  int _toquesSeguidos = 0;
  Timer? _esfriaToques;

  /// O quanto ele está gostando **agora**. Sobe com o dedo andando em cima
  /// dele e desce sozinho quando o dedo sai.
  late final AnimationController _gosto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Onde o dedo está durante o afago, em coordenadas do widget.
  Offset? _dedo;
  double _percorrido = 0;
  double _desdeORonrom = 0;
  bool _afagoCreditado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Bicho escondido não respira.
  ///
  /// Um `repeat()` pede quadro para sempre. Com o app fora da tela isso é
  /// bateria queimada à toa — e no Flutter web é o que segue pedindo quadro
  /// depois de a view morrer, virando "Trying to render a disposed
  /// EngineFlutterView".
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (!mounted) return;
    switch (estado) {
      case AppLifecycleState.resumed:
        if (!Movimento.reduzido(context)) _iniciaContinuo();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _paraContinuo();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimento.reduzido(context)) {
      _paraContinuo();
    } else {
      _iniciaContinuo();
    }
  }

  /// A atividade mudou debaixo do widget.
  ///
  /// Sem isto o bicho continuava com a cadência da atividade anterior:
  /// entrava na sessão de foco remando no compasso do ócio, sete segundos
  /// por braçada. `didChangeDependencies` não cobre — a dependência não
  /// mudou, o parâmetro é que mudou.
  @override
  void didUpdateWidget(PetView antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.activity != widget.activity ||
        antigo.species != widget.species) {
      _ajustaRitmo();
    }
  }

  AcaoDoBicho get _acao => acaoDoBicho(widget.species, widget.activity);

  Duration get _duracaoDoCiclo => switch (_acao) {
        AcaoDoBicho.nado => _cicloDoNado,
        AcaoDoBicho.voo => _cicloDoVoo,
        AcaoDoBicho.pasto || AcaoDoBicho.petisco => _cicloDoPasto,
        AcaoDoBicho.brincadeira => _cicloDaBrincadeira,
        AcaoDoBicho.cochilo => _cicloDoSono,
        AcaoDoBicho.ocioso => _cicloDoOcio,
      };

  /// A respiração acompanha o esforço: funda e lenta no sono, curta e rápida
  /// na água. É o sinal mais barato de que a atividade mudou, e o primeiro
  /// que o olho lê mesmo sem prestar atenção.
  Duration get _duracaoDaRespiracao => switch (_acao) {
        AcaoDoBicho.cochilo => _respiracaoDormindo,
        AcaoDoBicho.nado ||
        AcaoDoBicho.voo ||
        AcaoDoBicho.brincadeira =>
          _respiracaoNoEsforco,
        _ => Tempo.respiracao,
      };

  void _ajustaRitmo() {
    _ciclo.duration = _duracaoDoCiclo;
    _respiro.duration = _duracaoDaRespiracao;
    if (!_continuoLigado) return;
    // `duration` só vale a partir do próximo `repeat`: o ticker em curso
    // guarda o período com que começou.
    _ciclo.repeat();
    _respiro.repeat(reverse: true);
  }

  void _iniciaContinuo() {
    if (_continuoLigado) return;
    _continuoLigado = true;
    _ciclo.duration = _duracaoDoCiclo;
    _respiro.duration = _duracaoDaRespiracao;
    _respiro.repeat(reverse: true);
    _flutua.repeat(reverse: true);
    _cauda.repeat(reverse: true);
    _ciclo.repeat();
    _agendaPiscar();
    _agendaOrelha();
    _agendaGesto();
  }

  void _paraContinuo() {
    _continuoLigado = false;
    _proximoPiscar?.cancel();
    _proximaOrelha?.cancel();
    _proximoGesto?.cancel();
    _gestoAtual = GestoOcioso.nenhum;
    _gesto
      ..stop()
      ..value = 0;
    for (final c in [_respiro, _flutua, _cauda]) {
      c
        ..stop()
        ..value = 0.5;
    }
    // O laço para em zero, não no meio: fase 0 é a pose de repouso de cada
    // atividade — a folha já pousada no bicho que dorme, a cabeça erguida de
    // quem pasta, as patas paradas de quem nada. Congelar em 0.5 deixaria o
    // bicho de "reduzir movimento" com a boca aberta para sempre.
    _ciclo
      ..stop()
      ..value = 0;
    _pisca
      ..stop()
      ..value = 0;
    _orelha
      ..stop()
      ..value = 0;
  }

  /// Piscada em intervalo irregular, às vezes dupla.
  ///
  /// Cadência fixa parece relógio, não bicho.
  void _agendaPiscar() {
    _proximoPiscar?.cancel();
    final espera = Duration(milliseconds: 1800 + _sorte.nextInt(4600));
    _proximoPiscar = Timer(espera, () async {
      if (!mounted || !_continuoLigado) return;
      final vezes = _sorte.nextInt(5) == 0 ? 2 : 1;
      for (var i = 0; i < vezes; i++) {
        await _pisca.forward(from: 0);
        if (!mounted) return;
        await _pisca.reverse();
        if (!mounted) return;
      }
      _agendaPiscar();
    });
  }

  void _agendaOrelha() {
    _proximaOrelha?.cancel();
    final espera = Duration(milliseconds: 3200 + _sorte.nextInt(7000));
    _proximaOrelha = Timer(espera, () async {
      if (!mounted || !_continuoLigado) return;
      await _orelha.forward(from: 0);
      if (!mounted) return;
      _orelha.value = 0;
      _agendaOrelha();
    });
  }

  /// Um gesto a cada 5–12 s, sorteado, e só quando ele está à toa.
  ///
  /// Nadando, pastando ou dormindo o corpo já tem o que fazer; empilhar um
  /// gesto por cima vira ruído.
  ///
  /// A espera encurtou junto com o repertório: com três gestos a cada 7–15 s
  /// dava para ficar meio minuto olhando e ver o mesmo bocejo duas vezes. Com
  /// seis e a janela mais curta, a repetição some no ruído.
  void _agendaGesto() {
    _proximoGesto?.cancel();
    final espera = Duration(milliseconds: 5000 + _sorte.nextInt(7000));
    _proximoGesto = Timer(espera, () async {
      if (!mounted || !_continuoLigado) return;
      if (_acao != AcaoDoBicho.ocioso || _toque.isAnimating) {
        _agendaGesto();
        return;
      }
      const repertorio = [
        GestoOcioso.espreguica,
        GestoOcioso.sacode,
        GestoOcioso.olhaEmVolta,
        GestoOcioso.coca,
        GestoOcioso.fareja,
        GestoOcioso.saltinho,
      ];
      setState(() {
        _gestoAtual = PetView.gestoForcado ??
            repertorio[_sorte.nextInt(repertorio.length)];
      });
      PetView.observadorDeGesto?.value = _gestoAtual;
      await _gesto.forward(from: 0);
      if (!mounted) return;
      setState(() => _gestoAtual = GestoOcioso.nenhum);
      PetView.observadorDeGesto?.value = GestoOcioso.nenhum;
      _agendaGesto();
    });
  }

  void _reageAoToque(TapDownDetails detalhe) {
    if (!widget.interativo) return;

    _toquesSeguidos += 1;
    _esfriaToques?.cancel();
    _esfriaToques = Timer(const Duration(seconds: 3), () {
      _toquesSeguidos = 0;
    });

    // Atenção repetida anima mais: do terceiro toque em diante a reação é
    // mais forte, como um bicho que percebe que estão brincando com ele.
    if (_toquesSeguidos >= 3) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    unawaited(SomService.instance.toca(SomDoBaru.toque));

    // Olha para o dedo.
    final tamanho = Size(widget.width, widget.height);
    final local = detalhe.localPosition;
    setState(() {
      _olhar = Offset(
        ((local.dx / tamanho.width) * 2 - 1).clamp(-1.0, 1.0),
        ((local.dy / tamanho.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    });
    _voltaAOlharPraFrente?.cancel();
    _voltaAOlharPraFrente = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _olhar = Offset.zero);
    });

    // O toque tem prioridade sobre o ocioso: um bicho que está sendo tocado
    // não continua se espreguiçando.
    if (_gestoAtual != GestoOcioso.nenhum) {
      _gesto.stop();
      _gestoAtual = GestoOcioso.nenhum;
      PetView.observadorDeGesto?.value = GestoOcioso.nenhum;
    }

    _toque.forward(from: 0);
    // Sem exigir o contínuo ligado: com "reduzir movimento" o tremor de
    // orelha é parte da resposta ao toque, e o §7 manda reduzir amplitude,
    // não apagar o retorno.
    if (!_orelha.isAnimating) {
      // `.forward` termina em 1.0 e fica lá. A orelha redonda disfarça
      // (`sin(2π) = 0`), mas o tufo da coruja é linear: sem este reset ele
      // ficava torto até o agendador rodar — até dez segundos depois.
      _orelha.forward(from: 0).then((_) {
        if (mounted) _orelha.value = 0;
      });
    }
  }

  // ======================================================================
  // AFAGO — a mão passando, não o dedo cutucando
  // ======================================================================

  void _comecaAfago(DragStartDetails d) {
    if (!widget.interativo) return;
    _gesto.stop();
    _gestoAtual = GestoOcioso.nenhum;
    _percorrido = 0;
    _desdeORonrom = 0;
    _afagoCreditado = false;
    setState(() => _dedo = d.localPosition);
  }

  void _afaga(DragUpdateDetails d) {
    if (!widget.interativo) return;
    final andou = d.delta.distance;
    _percorrido += andou;
    _desdeORonrom += andou;

    // Ronronar: um clique curto a cada tanto de percurso. Por tempo ficaria
    // igual com o dedo parado — o que não é carinho, é dedo pousado.
    if (_desdeORonrom >= PetView.passoDoRonrom) {
      _desdeORonrom = 0;
      HapticFeedback.selectionClick();
    }

    _gosto.value = (_percorrido / PetView.percursoDoAfago).clamp(0.0, 1.0);

    if (_gosto.value >= 1 && !_afagoCreditado) {
      _afagoCreditado = true;
      HapticFeedback.mediumImpact();
      widget.aoCarinho?.call();
    }

    final tamanho = Size(widget.width, widget.height);
    setState(() {
      _dedo = d.localPosition;
      // Ele acompanha a mão com o olhar enquanto está sendo afagado.
      _olhar = Offset(
        ((d.localPosition.dx / tamanho.width) * 2 - 1).clamp(-1.0, 1.0),
        ((d.localPosition.dy / tamanho.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    });
  }

  void _terminaAfago() {
    if (!widget.interativo) return;
    setState(() => _dedo = null);
    // Desce sozinho: a satisfação não some no instante em que a mão sai.
    if (_gosto.value > 0) _gosto.reverse();
    _voltaAOlharPraFrente?.cancel();
    _voltaAOlharPraFrente = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _olhar = Offset.zero);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _proximoPiscar?.cancel();
    _proximaOrelha?.cancel();
    _proximoGesto?.cancel();
    _voltaAOlharPraFrente?.cancel();
    _esfriaToques?.cancel();
    _respiro.dispose();
    _flutua.dispose();
    _cauda.dispose();
    _ciclo.dispose();
    _pisca.dispose();
    _orelha.dispose();
    _toque.dispose();
    _gesto.dispose();
    _gosto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amplitude = Movimento.reduzido(context) ? 0.25 : 1.0;

    final cena = RepaintBoundary(
      key: PetView.cenaKey,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _respiro,
          _flutua,
          _cauda,
          _ciclo,
          _pisca,
          _orelha,
          _toque,
          _gesto,
          _gosto,
        ]),
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _PetPainter(
              species: widget.species,
              mood: widget.mood,
              activity: widget.activity,
              coat: AppColors.pelagemDe(widget.species, widget.coat),
              coatIndex: widget.coat,
              roupas: widget.roupas,
              roupaDeCabeca: widget.roupaDeCabeca,
              pose: _Pose(
                acao: _acao,
                // Cru, sem curva: o laço da atividade é uma fase que dá a
                // volta. Passá-lo por `easeInOut` como os contínuos criaria
                // um salto na emenda entre 1 e 0 — a braçada travava a cada
                // volta.
                ciclo: _ciclo.value,
                respiro: Curvas.organica.transform(_respiro.value) * 2 - 1,
                boia: Curvas.organica.transform(_flutua.value) * 2 - 1,
                cauda: Curvas.organica.transform(_cauda.value) * 2 - 1,
                pisca: _pisca.value,
                orelha: _orelha.value,
                toque: _toque.value,
                olhar: _gestoAtual == GestoOcioso.olhaEmVolta
                    // Varredura da cabeça: dois lados e volta ao centro.
                    ? Offset(math.sin(_gesto.value * math.pi * 2), -0.12)
                    : _olhar,
                animado: _toquesSeguidos >= 3,
                amplitude: amplitude,
                gesto: _gestoAtual,
                gestoT: _gesto.value,
                dedo: _dedo,
                gosto: _gosto.value,
              ),
            ),
          );
        },
      ),
    );

    final corpo = Transform.scale(
      scale: widget.scale,
      alignment: widget.alignment,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: cena,
      ),
    );

    if (!widget.interativo) return corpo;
    // `opaque`, não `deferToChild`: um CustomPaint sem filho não responde a
    // hit-test, então deferir ao filho deixaria o toque no bicho sem efeito.
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          TapGestureRecognizer.new,
          (r) => r.onTapDown = _reageAoToque,
        ),
        _AfagoVenceARolagem:
            GestureRecognizerFactoryWithHandlers<_AfagoVenceARolagem>(
          _AfagoVenceARolagem.new,
          (r) => r
            ..onStart = _comecaAfago
            ..onUpdate = _afaga
            ..onEnd = ((_) => _terminaAfago())
            ..onCancel = _terminaAfago,
        ),
      },
      child: corpo,
    );
  }
}

/// O arrasto do afago, que não desiste para a rolagem.
///
/// O bicho mora dentro de uma lista rolável. Na arena de gestos, o
/// `VerticalDragGestureRecognizer` do `Scrollable` ganha do `pan` por
/// padrão: o dedo que ia fazer carinho descia a tela, e acariciar o Baru na
/// home era quase impossível.
///
/// Recusar a derrota resolve. `rejectGesture` normalmente encerra o
/// reconhecedor; aqui ele aceita, e o toque fica com quem está por cima —
/// que é o bicho. A rolagem continua inteira em qualquer outro ponto da
/// tela; só não rouba o dedo de dentro do habitat.
class _AfagoVenceARolagem extends PanGestureRecognizer {
  /// Menor que o `kTouchSlop` de 18 que a rolagem usa, e menor ainda que o
  /// `kPanSlop` de 36 do `pan` padrão. É o número que decide a arena: quem
  /// reivindica primeiro leva.
  static const _limiar = 6.0;

  Offset? _origem;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // Reivindicar já no toque roubaria o tap — e tocar no bicho tem
    // resposta própria. Por isso guarda a origem e espera o dedo andar.
    _origem = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    final origem = _origem;
    if (origem != null &&
        event is PointerMoveEvent &&
        (event.position - origem).distance > _limiar) {
      resolve(GestureDisposition.accepted);
    }
    super.handleEvent(event);
  }
}

/// Os valores animados de um quadro. O painter não sabe de controllers.
class _Pose {
  const _Pose({
    required this.acao,
    required this.ciclo,
    required this.respiro,
    required this.boia,
    required this.cauda,
    required this.pisca,
    required this.orelha,
    required this.toque,
    required this.olhar,
    required this.animado,
    required this.amplitude,
    this.gesto = GestoOcioso.nenhum,
    this.gestoT = 0,
    this.dedo,
    this.gosto = 0,
  });

  /// O que ele está fazendo — já traduzido para a espécie.
  final AcaoDoBicho acao;

  /// 0 a 1 dando a volta: a fase do laço da atividade.
  final double ciclo;

  /// -1 a 1, ida e volta contínua. Enche e esvazia o peito.
  final double respiro;

  /// -1 a 1, período diferente do respiro.
  final double boia;

  /// -1 a 1, ritmo próprio da cauda.
  final double cauda;

  /// 0 a 1, onde 1 é olho fechado.
  final double pisca;

  /// 0 a 1, um tremor rápido de orelha.
  final double orelha;

  /// 0 a 1, um pulso disparado pelo toque.
  final double toque;

  /// Para onde olha, -1 a 1 em cada eixo.
  final Offset olhar;

  /// Muitos toques seguidos: reação mais forte.
  final bool animado;

  /// Fator global (menor quando o sistema pede movimento reduzido).
  final double amplitude;

  /// Gesto de ocioso em andamento, e onde ele está (0 a 1).
  final GestoOcioso gesto;
  final double gestoT;

  /// Onde a mão está, em coordenadas do widget. Nulo quando ninguém está
  /// afagando.
  final Offset? dedo;

  /// 0 a 1: o quanto ele está gostando do afago.
  final double gosto;

  /// Amplitude do toque, com piso próprio.
  ///
  /// O §7 manda **reduzir** amplitude quando se pede menos movimento, não
  /// remover o feedback: com o fator global de 0.25 a reação ficava abaixo de
  /// um pixel, e feedback invisível é feedback que não existe.
  double get amplitudeToque => math.max(amplitude, 0.55);

  /// Quicada: sobe rápido e volta oscilando.
  double get quique {
    if (toque == 0) return 0;
    return math.sin(toque * math.pi * 3) * math.exp(-toque * 4);
  }

  /// Fase de "carinho": alta logo depois do toque, some devagar.
  double get carinho => toque == 0 ? 0 : math.exp(-toque * 2.2);

  /// Sino 0→1→0 ao longo do gesto: entra e sai sem corte.
  double get gestoForca =>
      gesto == GestoOcioso.nenhum ? 0 : math.sin(gestoT * math.pi) * amplitude;

  /// Espreguiçar: o corpo se alonga e sobe um pouco.
  double get estica => gesto == GestoOcioso.espreguica ? gestoForca : 0;

  /// Sacudir: a cabeça vai e volta rápido e a oscilação morre.
  double get sacudida {
    if (gesto != GestoOcioso.sacode) return 0;
    return math.sin(gestoT * math.pi * 6) *
        math.exp(-gestoT * 2.2) *
        0.18 *
        amplitude;
  }

  /// Bocejo: os olhos se fecham no meio do espreguiçar.
  double get bocejo {
    if (gesto != GestoOcioso.espreguica) return 0;
    if (gestoT < 0.18 || gestoT > 0.72) return 0;
    return math.sin(((gestoT - 0.18) / 0.54) * math.pi);
  }

  /// Coçar: a cabeça pende para um lado e treme rápido, morrendo no fim.
  double get cocada {
    if (gesto != GestoOcioso.coca) return 0;
    return math.sin(gestoT * math.pi) *
        math.sin(gestoT * math.pi * 11) *
        0.11 *
        amplitude;
  }

  /// Farejar: duas fungadas curtas com o focinho para baixo. Em pixels.
  double get farejada {
    if (gesto != GestoOcioso.fareja) return 0;
    final envelope = math.sin(gestoT * math.pi);
    final fungada = 0.5 - 0.5 * math.cos(gestoT * math.pi * 4);
    return envelope * fungada * 8 * amplitude;
  }

  /// Um pulinho, em pixels para cima. Um só por gesto: dois seguidos leem
  /// como bug de física, não como bicho contente.
  double get saltinho {
    if (gesto != GestoOcioso.saltinho) return 0;
    return math.max(0.0, math.sin(gestoT * math.pi * 2)) * 12 * amplitude;
  }

  // ======================================================================
  // O LAÇO DA ATIVIDADE
  //
  // Tudo daqui para baixo sai de [ciclo], que anda sozinho e dá a volta. Com
  // "reduzir movimento" ele fica em zero — e zero é, em cada caso, a pose
  // de repouso daquela atividade, não o meio de um movimento.
  // ======================================================================

  bool get nadando => acao == AcaoDoBicho.nado;
  bool get voando => acao == AcaoDoBicho.voo;
  bool get brincando => acao == AcaoDoBicho.brincadeira;
  bool get pastando =>
      acao == AcaoDoBicho.pasto || acao == AcaoDoBicho.petisco;

  /// A fase do laço em radianos.
  double get _volta => ciclo * math.pi * 2;

  /// Trapézio: sobe em [entra], fica em 1, desce em [sai], zero fora da
  /// janela. É o que dá fases com começo, meio e fim dentro de um laço — um
  /// seno só daria vaivém, e pastar não é vaivém.
  static double _fase(
    double p,
    double inicio,
    double entra,
    double sai,
    double fim,
  ) {
    if (p <= inicio || p >= fim) return 0;
    if (p < inicio + entra) {
      return Curves.easeInOut.transform((p - inicio) / entra);
    }
    if (p > fim - sai) return Curves.easeInOut.transform((fim - p) / sai);
    return 1;
  }

  /// Patas: o passo do repouso vira remada na água e impulso na brincadeira.
  ///
  /// Sempre em torno de -1 a 1 para as espécies continuarem multiplicando
  /// pelo próprio alcance. Na água a excursão passa de 1 de propósito:
  /// remada curta lê como tremor, não como braçada.
  double get pernas => switch (acao) {
        AcaoDoBicho.nado => math.sin(_volta) * 2.4,
        AcaoDoBicho.brincadeira => math.sin(_volta) * 1.6,
        _ => boia,
      };

  /// Asas e nadadeiras. Voando, batem; nadando, varrem meio ciclo atrás da
  /// remada; no resto, só acompanham a respiração como sempre acompanharam.
  double get asa => switch (acao) {
        AcaoDoBicho.voo => math.sin(_volta) * 3.6,
        AcaoDoBicho.nado => math.sin(_volta - math.pi / 2) * 1.7,
        _ => respiro,
      };

  /// O corpo sobe na batida de asa — e sobe **atrasado** em relação a ela.
  /// Em fase, a coruja parecia um elevador; atrasada, ela voa.
  double get impulsoDoVoo =>
      voando ? math.sin(_volta - math.pi * 0.35) * amplitude : 0;

  /// A brincadeira: agacha na primeira metade do laço, salta na segunda.
  /// Em pixels para cima.
  double get pulo =>
      brincando ? math.max(0.0, math.sin(_volta)) * 16 * amplitude : 0;

  /// O agachamento que antecede o salto, em pixels para baixo.
  ///
  /// Os 4 px fixos são postura, não movimento — bicho brincando fica baixo,
  /// pronto para saltar —, e por isso não passam por [amplitude]: é o que
  /// mantém a brincadeira diferente do ócio para quem desligou a animação.
  double get agacha =>
      brincando ? 4 + math.max(0.0, -math.sin(_volta)) * 5 * amplitude : 0;

  /// O quanto a cabeça desce, em pixels.
  ///
  /// Quem pasta enfia a cabeça no chão e mastiga lá embaixo; quem petisca
  /// abaixa só para pegar e volta a mastigar em cima. É a diferença entre
  /// uma capivara e uma lontra comendo, e é ela que evita o desenho de um
  /// pinguim de bico na grama.
  /// A parcela **postural** é constante e não passa por [amplitude]: quem
  /// come anda de cabeça baixa mesmo parado, e é ela que mantém `graze`
  /// diferente de `idle` para quem pediu menos movimento. A parcela animada
  /// é que reduz.
  double get cabecaDesce => switch (acao) {
        AcaoDoBicho.pasto =>
          6 + _fase(ciclo, 0.04, 0.12, 0.14, 0.66) * 26 * amplitude,
        AcaoDoBicho.petisco =>
          4 + _fase(ciclo, 0.04, 0.10, 0.10, 0.30) * 17 * amplitude,
        _ => 0.0,
      };

  /// Mastigar: 0 a 1, a boca abrindo e fechando na janela de comer.
  double get mastiga {
    final janela = switch (acao) {
      AcaoDoBicho.pasto => _fase(ciclo, 0.16, 0.06, 0.06, 0.62),
      AcaoDoBicho.petisco => _fase(ciclo, 0.26, 0.06, 0.08, 0.72),
      _ => 0.0,
    };
    if (janela <= 0) return 0;
    // Catorze aberturas por laço de 5,6 s: ~2,5 mordidas por segundo, que é
    // o ritmo de um bicho comendo. Mais devagar vira bocejo.
    final abre = 0.5 - 0.5 * math.cos(ciclo * math.pi * 2 * 14);
    return janela * abre * amplitude;
  }

  /// A varredura de cabeça de quem levantou do pasto e olha em volta.
  double get olhadaDoPasto {
    if (!pastando) return 0;
    final janela = _fase(ciclo, 0.70, 0.08, 0.10, 0.94);
    if (janela <= 0) return 0;
    return math.sin((ciclo - 0.70) / 0.24 * math.pi * 2) * janela * amplitude;
  }

  /// À toa ele troca o apoio de um pé para o outro. Em pixels.
  double get pesoNoPe =>
      acao == AcaoDoBicho.ocioso ? math.sin(_volta) * 2.2 * amplitude : 0;
}

class _PetPainter extends CustomPainter {
  _PetPainter({
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
    required this.coatIndex,
    required this.pose,
    this.roupas = const {},
    this.roupaDeCabeca,
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final Color coat;

  /// Qual entrada da paleta da espécie foi escolhida.
  ///
  /// O painter recebia só a **cor** resolvida, e cor não basta para o
  /// buldogue: fulvo, tigrado e pied não são o mesmo pelo em intensidades
  /// diferentes — são marcações diferentes, e a marcação é metade do que faz
  /// alguém reconhecer a raça. Sem o índice o desenho não tem como saber se
  /// pinta máscara escura, manchas brancas ou listras. Nas outras oito
  /// espécies a paleta é uma escada de tons do mesmo pelo e o índice não
  /// muda desenho nenhum — por isso ele só é lido em [_buldogue].
  final int coatIndex;

  final _Pose pose;

  /// A cor da peça em cada lugar do corpo. Vazio: o bicho está pelado.
  final Map<Vestimenta, Color> roupas;

  /// Qual peça de cabeça — chapéu, gorro ou coroa mudam o desenho.
  final String? roupaDeCabeca;

  // --- estado derivado ----------------------------------------------------

  /// A ação já traduzida para a espécie. O painter nunca olha [activity]
  /// direto para decidir desenho: quem faz a tradução é [acaoDoBicho], e ela
  /// é a única fonte — senão a coruja voaria na legenda e nadaria no traço.
  AcaoDoBicho get acao => pose.acao;

  bool get dormindo => acao == AcaoDoBicho.cochilo || mood == Mood.sleepy;
  bool get triste => mood == Mood.missingYou;
  bool get feliz =>
      mood == Mood.radiant || pose.carinho > 0.35 || pose.gosto > 0.25;
  bool get nadando => acao == AcaoDoBicho.nado;
  bool get pastando => pose.pastando;

  /// Nada mergulhando (lontra, pinguim, axolote) em vez de boiando.
  bool get mergulha => _mergulhador(species);

  /// O quanto o corpo afunda na lâmina d'água, em pixels.
  ///
  /// Quem boia mostra o dorso e a cabeça; quem mergulha some quase todo. Foi
  /// **este** número que faltava: sem ele o bicho ficava em cima da água como
  /// um adesivo, e o que o dono viu foi um bicho parado com uns círculos
  /// embaixo.
  double get afunda => !nadando ? 0 : (mergulha ? 20 : 13);

  /// Olho fechado por sono, por piscada, por bocejo ou de contentamento.
  ///
  /// O afago fecha aos poucos: os olhos apertam conforme ele vai gostando,
  /// e o arco de pálpebra virado para cima é a carinha de quem está gostando.
  double get fechamento {
    if (dormindo) return 1.0;
    final derrete = ((pose.gosto - 0.34) / 0.16).clamp(0.0, 1.0);
    return math.max(math.max(pose.pisca, pose.bocejo), derrete).clamp(0.0, 1.0);
  }

  // --- paleta -------------------------------------------------------------

  Color get pelo {
    switch (mood) {
      case Mood.radiant:
        return Color.lerp(coat, Cores.superficie, 0.10)!;
      case Mood.sleepy:
        return Color.lerp(coat, Cores.tinta, 0.10)!;
      case Mood.missingYou:
        return Color.lerp(coat, Cores.tinta, 0.14)!;
      case Mood.neutral:
        return Color.lerp(coat, Cores.tinta, 0.05)!;
      case Mood.content:
        return coat;
    }
  }

  Color get sombra => Color.lerp(pelo, Cores.tinta, 0.30)!;
  Color get sombraForte => Color.lerp(pelo, Cores.tinta, 0.46)!;
  Color get claro => Color.lerp(pelo, Cores.superficie, 0.30)!;
  Color get barriga => Color.lerp(pelo, Cores.superficie, 0.26)!;
  Color get luz => Color.lerp(pelo, Colors.white, 0.30)!;

  Paint _p(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint _traco(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  // --- helpers de forma ---------------------------------------------------

  /// Uma "bolha" fechada por quatro curvas de Bézier — a base de quase tudo
  /// aqui. Muito mais orgânica que um retângulo arredondado, e os fatores por
  /// lado permitem achatar uma ponta sem virar outra forma.
  Path _bolha(
    Rect r, {
    double topo = 1,
    double base = 1,
    double esq = 1,
    double dir = 1,
  }) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    final rx = r.width / 2;
    final ry = r.height / 2;
    const k = 0.5523;
    return Path()
      ..moveTo(cx, cy - ry * topo)
      ..cubicTo(
        cx + rx * k * dir, cy - ry * topo,
        cx + rx * dir, cy - ry * k,
        cx + rx * dir, cy,
      )
      ..cubicTo(
        cx + rx * dir, cy + ry * k * base,
        cx + rx * k * base, cy + ry * base,
        cx, cy + ry * base,
      )
      ..cubicTo(
        cx - rx * k * base, cy + ry * base,
        cx - rx * esq, cy + ry * k * base,
        cx - rx * esq, cy,
      )
      ..cubicTo(
        cx - rx * esq, cy - ry * k,
        cx - rx * k * esq, cy - ry * topo,
        cx, cy - ry * topo,
      )
      ..close();
  }

  void _oval(Canvas c, Rect r, Color cor) => c.drawOval(r, _p(cor));

  // --- entrada ------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    final amp = pose.amplitude;
    final sopro = pose.respiro * amp;
    final boia = pose.boia * amp;

    // A lâmina d'água, em coordenadas do **widget** e não do corpo: água que
    // sobe e desce junto com o bicho não é água, é adesivo. Fica dois pixels
    // abaixo do centro do corpo porque é ali que a lâmina do habitat cruza a
    // caixa do bicho — ele é posicionado a 34 unidades do fundo de uma cena
    // cuja água começa em 118, o que cai em y ≈ 87 numa caixa de 150.
    final linhaDagua = PetView.linhaDaguaEm(size.height);

    // Cada atividade tem o seu jeito de ocupar o espaço.
    final balanco = switch (acao) {
      // Na água o corpo sobe e desce com a braçada, não com a boia: é a
      // remada que levanta o dorso, e o atraso de meia fase é o que dá peso.
      AcaoDoBicho.nado =>
        afunda + math.sin(pose.ciclo * math.pi * 2 - 0.9) * 3.4 * amp,
      AcaoDoBicho.voo => -14 - pose.impulsoDoVoo * 7,
      AcaoDoBicho.cochilo => 6 + sopro * 2.6,
      AcaoDoBicho.pasto || AcaoDoBicho.petisco => boia * 1.2,
      AcaoDoBicho.brincadeira => pose.agacha - pose.pulo,
      AcaoDoBicho.ocioso => boia * 1.2,
    };

    if (nadando) _rastro(canvas, size, linhaDagua);

    // O corpo inteiro vai para uma camada quando ele está na água: o tom da
    // água precisa cair **só sobre o bicho**, e `srcATop` garante isso. Um
    // retângulo translúcido por cima pintaria o habitat junto, e a caixa do
    // bicho apareceria como um quadrado mais escuro dentro da cena.
    //
    // Os limites da camada são folgados de propósito. `saveLayer` recorta no
    // retângulo que recebe, e o bicho **passa** da própria caixa: no habitat
    // ele fica a 34 unidades do fundo da cena e as patas caem abaixo disso.
    // Com `Offset.zero & size` as patas do bicho nadando eram cortadas numa
    // linha reta no meio da água.
    final folga = Rect.fromLTRB(
      -size.width,
      -size.height,
      size.width * 2,
      size.height * 3,
    );
    if (nadando) canvas.saveLayer(folga, Paint());

    canvas.save();
    canvas.translate(
      cx + pose.pesoNoPe,
      cy +
          balanco +
          pose.quique * 7 * pose.amplitudeToque -
          pose.estica * 4 -
          pose.saltinho,
    );

    final giro = switch (acao) {
      AcaoDoBicho.cochilo => -0.16,
      // Rola de um lado para o outro na braçada — é a ondulação do nado.
      // Quem mergulha rola mais: o corpo dele é o remo.
      AcaoDoBicho.nado => -0.04 +
          math.sin(pose.ciclo * math.pi * 2) * (mergulha ? 0.10 : 0.045) * amp,
      AcaoDoBicho.voo => math.sin(pose.ciclo * math.pi * 2) * 0.05 * amp,
      // A inclinação acompanha a cabeça: quanto mais baixa, mais o corpo
      // vai junto. Cabeça descendo com o corpo reto lê como pescoço quebrado.
      AcaoDoBicho.pasto ||
      AcaoDoBicho.petisco =>
        0.05 + pose.cabecaDesce * 0.004,
      // O -0.05 é a mesma postura do agachamento: o peito baixa na frente.
      AcaoDoBicho.brincadeira =>
        -0.05 + math.sin(pose.ciclo * math.pi * 2) * 0.09 * amp,
      AcaoDoBicho.ocioso =>
        triste ? 0.02 : boia * 0.012 + pose.pesoNoPe * 0.006,
    };
    canvas.rotate(giro);

    // Respiração como squash/stretch, mais o quique do toque e o alongamento
    // do espreguiçar. Dormindo a respiração é quase o dobro de funda: é o
    // sinal que faz o sono ser visto sem depender de nenhum símbolo.
    final q = pose.quique * pose.amplitudeToque;
    final e = pose.estica;
    final fundura = dormindo ? 2.1 : 1.0;
    canvas.scale(
      1 + sopro * 0.018 * fundura + q * 0.07 + e * 0.07,
      1 - sopro * 0.014 * fundura - q * 0.07 + e * 0.03,
    );

    switch (species) {
      case Species.capybara:
        _capivara(canvas);
      case Species.otter:
        _lontra(canvas);
      case Species.tortoise:
        _tartaruga(canvas);
      case Species.owl:
        _coruja(canvas);
      case Species.axolotl:
        _axolote(canvas);
      case Species.penguin:
        _pinguim(canvas);
      case Species.cat:
        _gata(canvas);
      case Species.fox:
        _raposa(canvas);
      case Species.frenchie:
        _buldogue(canvas);
    }
    canvas.restore();

    if (nadando) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(folga.left, linhaDagua, folga.right, folga.bottom),
      );
      canvas.drawRect(
        folga,
        Paint()
          ..color = _tomDaAgua
          ..blendMode = BlendMode.srcATop,
      );
      canvas.restore();
      canvas.restore(); // fecha a camada do corpo
      _lamina(canvas, size, linhaDagua);
    }

    if (dormindo) {
      _zzz(canvas, size);
      _folhaDoSono(canvas, size);
    }
    if (feliz) _brilhos(canvas, size);
    if (triste) _pingo(canvas, size);
    if (pose.animado && pose.toque > 0) _coracoes(canvas, size);
    if (pose.gosto > 0) _afago(canvas, size);
  }

  /// O afago, desenhado em coordenadas do widget — não do corpo — porque a
  /// mão está por cima dele, não presa à anatomia.
  void _afago(Canvas canvas, Size size) {
    final g = pose.gosto;
    final dedo = pose.dedo;

    // Pelo levantado sob a mão: dois arcos curtos, como um rastro.
    if (dedo != null) {
      final risco = _traco(luz.withValues(alpha: 0.30 + g * 0.35), 2.4);
      for (var i = 0; i < 2; i++) {
        final r = 11.0 + i * 7;
        canvas.drawArc(
          Rect.fromCircle(center: dedo, radius: r),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          risco,
        );
      }
    }

    // Coraçõezinhos contínuos: a partir da metade da satisfação eles sobem
    // sem parar, e ficam mais fortes até encher.
    if (g < 0.45) return;
    final base = dedo ?? Offset(size.width * 0.5, size.height * 0.42);
    final fase = (pose.respiro + 1) / 2;
    for (var i = 0; i < 3; i++) {
      final f = (fase + i / 3) % 1.0;
      final a = math.sin(f * math.pi) * ((g - 0.45) / 0.55).clamp(0.0, 1.0);
      if (a <= 0.03) continue;
      _coracao(
        canvas,
        Offset(
          base.dx + math.sin(f * math.pi * 2 + i * 2.1) * 13,
          base.dy - 12 - f * 40,
        ),
        3.6 + a * 3.6,
        Cores.acento.withValues(alpha: a * 0.9),
      );
    }
  }

  /// Carinho insistente: três coraçõezinhos que sobem e somem.
  ///
  /// `pose.animado` já existia — era calculado a cada toque seguido e nunca
  /// chegava à tela. O háptico ficava mais forte e nada mudava visualmente.
  void _coracoes(Canvas canvas, Size size) {
    final t = pose.toque;
    if (t >= 1) return;
    final amp = pose.amplitudeToque;
    const partidas = [(0.34, 0.0), (0.52, 0.18), (0.66, 0.38)];
    for (final (fx, atraso) in partidas) {
      final f = ((t - atraso) / (1 - atraso)).clamp(0.0, 1.0);
      if (f <= 0) continue;
      final a = math.sin(f * math.pi).clamp(0.0, 1.0);
      if (a <= 0.02) continue;
      final deriva = math.sin(f * math.pi * 2 + atraso * 9) * 5 * amp;
      _coracao(
        canvas,
        Offset(
          size.width * fx + deriva,
          size.height * 0.40 - f * 34 * amp,
        ),
        4.2 + a * 3.4,
        Cores.acento.withValues(alpha: a * 0.85),
      );
    }
  }

  void _coracao(Canvas canvas, Offset o, double s, Color cor) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + s * 0.75)
        ..cubicTo(
          o.dx - s * 1.35, o.dy - s * 0.15,
          o.dx - s * 0.72, o.dy - s * 1.25,
          o.dx, o.dy - s * 0.42,
        )
        ..cubicTo(
          o.dx + s * 0.72, o.dy - s * 1.25,
          o.dx + s * 1.35, o.dy - s * 0.15,
          o.dx, o.dy + s * 0.75,
        )
        ..close(),
      _p(cor),
    );
  }

  /// Deslocamento do olhar aplicado às pupilas.
  ///
  /// A varredura do pasto entra aqui também: cabeça que gira com a pupila
  /// parada no meio lê como boneco, não como bicho conferindo se está tudo
  /// bem antes de voltar a comer.
  Offset get _olhoDesvio => Offset(
        pose.olhar.dx * 1.8 * pose.amplitudeToque +
            pose.olhadaDoPasto * 2.2,
        pose.olhar.dy * 1.3 * pose.amplitudeToque,
      );

  /// A cabeça acompanha um pouco o olhar, e varre ao levantar do pasto.
  double get _cabecaGiro =>
      pose.sacudida +
      pose.cocada +
      // Encosta a cabeça na mão.
      (pose.dedo == null ? 0 : pose.gosto * 0.06 * pose.amplitudeToque) +
      pose.olhar.dx * 0.05 * pose.amplitudeToque +
      pose.olhadaDoPasto * 0.16;

  /// O quanto a cabeça desce, em pixels — pastando ou farejando.
  ///
  /// Somado ao `translate` da cabeça de cada espécie. Fica num getter só
  /// porque a alternativa era repetir a mesma soma em oito lugares e
  /// esquecer de um.
  double get _cabecaDesce => pose.cabecaDesce + pose.farejada;

  // ======================================================================
  // CAPIVARA — de frente: cabeça grande e chata, focinho rombudo, corpo baixo
  //
  // Antes era de perfil: um corpo-ovo comprido com uma cabeça-ovo colada na
  // ponta. Duas elipses sobrepostas não fazem pescoço nem bochecha, e o
  // resultado lia como batata. De frente a cara domina — que é o que faz um
  // personagem funcionar, e é por isso que a coruja já funcionava.
  // ======================================================================

  void _capivara(Canvas canvas) {
    final amp = pose.amplitude;
    final passo = pose.pernas * amp;

    // Patas da frente, apoiadas. Sobem e descem alternadas ao boiar — e
    // remam de verdade quando ele está na água (ver [_pata]).
    _pata(canvas, const Offset(-23, 51), 27, 17, sombra, passo * 1.6,
        rema: -1);
    _pata(canvas, const Offset(23, 51), 27, 17, sombra, -passo * 1.6, rema: 1);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 18), width: 92, height: 80),
      topo: 0.86,
      base: 1.02,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 32), width: 64, height: 62),
        topo: 0.9,
      ),
      _p(barriga),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -30 + pose.respiro * amp * 0.7 + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.9);

    // Orelhas antes da cabeça: nascem atrás dela, então a base some sob o
    // contorno em vez de ficar boiando em cima.
    // Orelhas pequenas e afastadas: na capivara elas são dois botõezinhos
    // nos cantos de cima. Grandes e altas, ela vira urso.
    _orelhaRedonda(canvas, const Offset(-40, -19), 16, 14, -0.34);
    _orelhaRedonda(canvas, const Offset(40, -19), 16, 14, 0.34);

    // Cabeça larga e de topo baixo: a capivara é quadradona, não redonda.
    // Cabeça quase retangular. É a marca da capivara: um bloco com cantos
    // arredondados, não uma bola. Com `_bolha` ela virava um urso.
    canvas.drawPath(
      Path()..addRRect(
          RRect.fromRectAndCorners(
            Rect.fromCenter(
              center: const Offset(0, 2),
              width: 94,
              height: 74,
            ),
            topLeft: const Radius.circular(34),
            topRight: const Radius.circular(34),
            bottomLeft: const Radius.circular(26),
            bottomRight: const Radius.circular(26),
          ),
        ),
      _p(pelo),
    );

    // Focinho: uma faixa larga e **baixa**, encostada no queixo, com o topo
    // suave. Como oval isolado no meio da cara, lia como máscara colada.
    canvas.save();
    canvas.clipPath(
      Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: const Offset(0, 2),
              width: 94,
              height: 74,
            ),
            const Radius.circular(30),
          ),
        ),
    );
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 27), width: 74, height: 44),
        topo: 0.74,
      ),
      _p(claro),
    );
    canvas.restore();

    // Focinheira: o bloco escuro em cima do focinho, entre as narinas.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 12), width: 26, height: 15),
        base: 1.12,
      ),
      _p(sombraForte),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5, 9), width: 7, height: 4),
      _p(luz.withValues(alpha: 0.4)),
    );

    _boca(canvas, const Offset(0, 27), 26);
    if (feliz) {
      _bochecha(canvas, const Offset(-34, 18), const Offset(34, 18));
    }

    // Olhos altos e afastados: na capivara eles ficam quase na linha das
    // orelhas, para o bicho olhar em volta com o corpo na água.
    _olho(canvas, const Offset(-26, -13), 7.5);
    _olho(canvas, const Offset(26, -13), 7.5);
    _veste(canvas, 96, 78);

    canvas.restore();
  }

  // ======================================================================
  // LONTRA — cabeça redonda, focinho claro, bigodes dos dois lados, cauda
  // ======================================================================

  void _lontra(Canvas canvas) {
    final amp = pose.amplitude;
    final rema = pose.pernas * amp;
    // A cauda da lontra é o leme, e na água ela bate no compasso da braçada
    // em vez de balançar no ritmo solto dela. Sem isto o corpo nadava e a
    // cauda ficava vadiando atrás, em outro tempo.
    final balanca = pose.nadando ? pose.pernas * amp * 1.3 : pose.cauda * amp;

    // Cauda grossa saindo por trás, para um lado, afinando na ponta.
    canvas.drawPath(
      Path()
        ..moveTo(26, 34)
        ..cubicTo(
          58 + balanca * 5, 40,
          74 + balanca * 8, 24 + balanca * 4,
          78 + balanca * 9, 6 + balanca * 6,
        )
        ..cubicTo(
          70 + balanca * 6, 12 + balanca * 3,
          58 + balanca * 3, 30,
          26, 50,
        )
        ..close(),
      _p(sombraForte),
    );

    _patinha(canvas, Offset(-20, 50 + rema * 1.6), sombra, rema: -1);
    _patinha(canvas, Offset(20, 50 - rema * 1.6), sombra, rema: 1);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 18), width: 82, height: 76),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 30), width: 56, height: 58),
        topo: 0.9,
      ),
      _p(barriga),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -28 + pose.respiro * amp * 0.7 + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.9);

    // Orelhas pequenas e altas: na lontra elas quase somem na cabeça.
    _orelhaRedonda(canvas, const Offset(-33, -24), 16, 14, -0.24);
    _orelhaRedonda(canvas, const Offset(33, -24), 16, 14, 0.24);

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: 84, height: 74),
        base: 1.02,
      ),
      _p(pelo),
    );

    // Máscara clara do focinho, larga e baixa.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 14), width: 50, height: 34),
        topo: 0.9,
      ),
      _p(claro),
    );

    // Bigodes presos na borda do focinho, dos dois lados.
    _bigodes(canvas, const Offset(-22, 12));
    _bigodes(canvas, const Offset(22, 12), lado: 1);

    // Focinheira escura, o traço que faz ler "lontra" e não "gato".
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 6), width: 19, height: 13),
        base: 1.1,
      ),
      _p(sombraForte),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(-3.5, 3),
        width: 6,
        height: 3.5,
      ),
      _p(luz.withValues(alpha: 0.45)),
    );

    _boca(canvas, const Offset(0, 19), 20);
    if (feliz) {
      _bochecha(canvas, const Offset(-30, 11), const Offset(30, 11));
    }

    _olho(canvas, const Offset(-21, -12), 7.5);
    _olho(canvas, const Offset(21, -12), 7.5);
    _veste(canvas, 84, 74);

    canvas.restore();
  }

  // ======================================================================
  // TARTARUGA — de frente: casco em cúpula, cabeça grande saindo por cima
  //
  // De perfil o casco virava uma meia-lua com uma cabecinha espetada na
  // ponta. De frente a cúpula sustenta a cara, que é o que a gente olha.
  // ======================================================================

  void _tartaruga(Canvas canvas) {
    final amp = pose.amplitude;
    // A cabeça recolhe e estica de leve ao respirar, e sai mais quando fazem
    // carinho — é o gesto que todo mundo reconhece numa tartaruga.
    // Nadando ela estica o pescoço para manter o focinho fora d'água — o
    // corpo afundou 13 px e sem isto a cabeça entraria junto, o que numa
    // tartaruga é afogamento, não nado.
    final estica =
        (pose.boia * 2.4 * amp) + pose.carinho * 7 + (nadando ? 11 : 0);

    // Patas: saem por baixo do casco, nos cantos. Na água elas viram remos —
    // a tartaruga-de-orelha-vermelha nada com as quatro.
    _pata(canvas, const Offset(-47, 52), 25, 22, sombra,
        pose.pernas * amp * 1.4, rema: -1);
    _pata(canvas, const Offset(47, 52), 25, 22, sombra,
        -pose.pernas * amp * 1.4, rema: 1);

    // --- casco, atrás da cabeça -------------------------------------------
    //
    // O casco fica **atrás**: desenhado por cima, ele engolia o queixo e o
    // bicho parecia dentro de uma panela. Atrás, lê como carapaça nas costas.
    final casco = _bolha(
      Rect.fromCenter(center: const Offset(0, 26), width: 102, height: 78),
      topo: 0.94,
      base: 0.94,
    );
    // O casco é queratina, não pele: puxa para o oliva-amarronzado, senão
    // fica um verde chapado igual ao da cabeça.
    final corDoCasco = Color.lerp(sombra, const Color(0xFF6B5334), 0.32)!;
    canvas.drawPath(casco, _p(corDoCasco));

    canvas.save();
    canvas.clipPath(casco);
    // Escudos: precisam de contraste de verdade. Verde sobre verde some, e o
    // casco vira uma bolha lisa.
    final linha = _traco(Cores.tintaA(0.32), 2.6);

    // Fileira central mais clara: é ela que dá a cúpula.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 32), width: 62, height: 60),
        topo: 0.92,
      ),
      _p(Color.lerp(corDoCasco, Cores.superficie, 0.16)!),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-31, 62)
        ..cubicTo(-31, 4, 31, 4, 31, 62),
      linha,
    );
    // Fileira marginal: o anel de baixo.
    canvas.drawPath(
      Path()
        ..moveTo(-52, 48)
        ..cubicTo(-30, 32, 30, 32, 52, 48),
      linha,
    );
    for (final x in [-17.0, 0.0, 17.0]) {
      canvas.drawLine(Offset(x, 4), Offset(x * 1.1, 34), linha);
    }
    for (final x in [-42.0, -22.0, 22.0, 42.0]) {
      canvas.drawLine(Offset(x, 34), Offset(x * 1.08, 64), linha);
    }
    // Plastrão: a faixa clara da barriga, na frente do casco.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 54), width: 68, height: 42),
        topo: 0.9,
      ),
      _p(barriga),
    );
    canvas.restore();

    // --- cabeça, na frente ------------------------------------------------
    canvas.save();
    canvas.translate(0, -36 - estica + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.8);

    // Pescoço: sai da cabeça e entra no casco. É ele que faz a cabeça
    // **sair** do casco em vez de ficar apoiada nele como um chapéu.
    //
    // E ele estica junto. Com comprimento fixo, levantar a cabeça 11 px para
    // fora d'água abria um buraco entre a cabeça e a carapaça: a tartaruga
    // ficava com a cara boiando solta. O 38 + 1.34·estica mantém a ponta do
    // pescoço sempre uns 5 px **dentro** do casco, em qualquer esticada.
    final pescoco = 38 + estica * 1.34;
    canvas.drawPath(
      Path()
        ..moveTo(-17, 6)
        ..cubicTo(-19, pescoco, 19, pescoco, 17, 6)
        ..cubicTo(9, 14, -9, 14, -17, 6)
        ..close(),
      _p(claro),
    );

    // Cabeça menor que o casco: numa tartaruga a carapaça é o corpo.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: 66, height: 60),
        base: 1.04,
      ),
      _p(pelo),
    );

    // A listra vermelha atrás do olho — é dela que vem o nome
    // "tartaruga-de-orelha-vermelha", e é o que tira a cabeça de "bola
    // verde". Antes era um oval lavado que ninguém via.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(lado * 22, -10)
          ..cubicTo(lado * 29, -10, lado * 32, -6, lado * 32, 0)
          ..cubicTo(lado * 29, 4, lado * 24, 3, lado * 22, -1)
          ..close(),
        _p(Color.lerp(Cores.acento, Cores.acentoForte, 0.35)!),
      );
    }

    _narina(canvas, const Offset(-6, 6));
    _narina(canvas, const Offset(6, 6));
    _boca(canvas, const Offset(0, 16), 24);
    // Sem bochecha rosada: réptil não cora, e sobre o verde a mancha rosa
    // ficava um adesivo colado.

    _olho(canvas, const Offset(-14, -9), 7);
    _olho(canvas, const Offset(14, -9), 7);
    _veste(canvas, 66, 60);

    canvas.restore();
  }

  // ======================================================================
  // CORUJA — disco facial, tufos presos à cabeça, asas dobradas no corpo
  // ======================================================================

  void _coruja(Canvas canvas) {
    final amp = pose.amplitude;
    final asa = pose.asa * amp;

    // Pés: pousados no repouso, recolhidos no voo.
    //
    // Coruja voando com as garras esticadas para baixo é coruja atacando, e
    // o que a cena diz é que ela está indo a algum lugar. Recolhidos contra
    // o corpo, o desenho lê como voo de deslocamento — que é a atividade
    // dela na sessão de foco.
    final recolhe = pose.voando ? 9.0 : 0.0;
    final garra = _traco(Cores.acento, 5)..strokeJoin = StrokeJoin.round;
    for (final x in [-19.0, 19.0]) {
      canvas.drawLine(
        Offset(x, 42 - recolhe * 0.4),
        Offset(x, 52 - recolhe),
        garra,
      );
      for (final dedo in [-1.0, 0.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 52 - recolhe)
            ..cubicTo(
              x + dedo * 7,
              55 - recolhe * 1.3,
              x + dedo * 10,
              57 - recolhe * 1.5,
              x + dedo * 11,
              59 - recolhe * 1.7,
            ),
          garra,
        );
      }
    }

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 4), width: 94, height: 100),
      topo: 0.84,
      base: 1.02,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 22), width: 62, height: 72),
        topo: 0.9,
      ),
      _p(barriga),
    );
    // Padrão de penas no peito.
    final penas = _traco(sombra.withValues(alpha: 0.28), 2);
    for (var linha = 0; linha < 3; linha++) {
      final y = 12.0 + linha * 14;
      for (var i = -1; i <= 1; i++) {
        final x = i * 17.0 + (linha.isOdd ? 8 : 0);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 17, height: 12),
          math.pi,
          math.pi,
          false,
          penas,
        );
      }
    }
    canvas.restore();

    // Asa aberta, batendo: a coruja está voando.
    //
    // É um caminho separado, e não o mesmo `Path` com um número maior. A asa
    // dobrada nasce no ombro e desce colada ao corpo; abrir esse desenho só
    // faria o contorno inchar de lado, que foi a primeira tentativa e ficou
    // parecendo uma coruja gorda. Voar é outra silhueta.
    if (pose.voando) {
      final bate = asa / 3.6;
      for (final lado in [-1.0, 1.0]) {
        final pontaY = -16 - bate * 32;
        final ala = Path()
          ..moveTo(lado * 26, -26)
          ..cubicTo(
            lado * 52, -34 - bate * 16,
            lado * 74, pontaY - 8,
            lado * 86, pontaY,
          )
          ..cubicTo(
            lado * 72, pontaY + 18,
            lado * 50, 2 - bate * 12,
            lado * 26, 18,
          )
          ..close();
        canvas.drawPath(ala, _p(sombraForte));

        // Primárias: os riscos que separam as penas da ponta. Sem eles a
        // asa vira uma pá lisa e o voo parece um planador de papel.
        canvas.save();
        canvas.clipPath(ala);
        final risco = _traco(Cores.tintaA(0.20), 1.9);
        for (var i = 0; i < 4; i++) {
          canvas.drawLine(
            Offset(lado * 40, -14 - bate * 10 + i * 8),
            Offset(lado * (84 - i * 4), pontaY + 4 + i * 7),
            risco,
          );
        }
        canvas.restore();
      }
    }

    // Asas dobradas, encostadas no corpo — abrem de leve ao respirar.
    // Mais escuras e mais largas que antes: encostadas no corpo com a mesma
    // cor, elas sumiam.
    for (final lado in pose.voando ? const <double>[] : const [-1.0, 1.0]) {
      final abre = asa * 2.6 * lado;
      // Borda externa quase no limite do corpo (±47): a asa fica **dobrada**
      // sobre ele e só se afasta ao respirar. Chegando a ±56 no repouso ela
      // virava um halo escuro atrás do bicho em vez de asa.
      final asaPath = Path()
        ..moveTo(lado * 32, -28)
        ..cubicTo(
          lado * (47 + abre), -8,
          lado * (45 + abre), 22,
          lado * 28, 34,
        )
        ..cubicTo(lado * 23, 10, lado * 25, -14, lado * 32, -28)
        ..close();
      canvas.drawPath(asaPath, _p(sombraForte));

      // Penas recortadas na própria asa: soltas, os riscos vazavam a
      // silhueta e pareciam arranhões no fundo.
      canvas.save();
      canvas.clipPath(asaPath);
      final risco = _traco(Cores.tintaA(0.18), 1.8);
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(lado * 24, 4 + i * 9),
          Offset(lado * (46 + abre), 12 + i * 9),
          risco,
        );
      }
      canvas.restore();
    }

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    // -28 e não -32: a ponta do tufo ficava a 3 px do topo do quadro, e ao
    // se espreguiçar (corpo 7% maior e 4 px acima) ela era cortada.
    canvas.translate(0, -28 + pose.respiro * amp * 0.6 + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.8);

    // Tufos: base larga presa à cabeça, ponta afiada. Antes eram bolinhas.
    for (final lado in [-1.0, 1.0]) {
      final treme = pose.orelha * 0.5 * lado;
      canvas.drawPath(
        Path()
          ..moveTo(lado * 8, -24)
          ..cubicTo(
            lado * (18 + treme * 8), -43,
            lado * (30 + treme * 12), -48,
            lado * (36 + treme * 14), -46,
          )
          ..cubicTo(lado * 36, -36, lado * 30, -26, lado * 30, -22)
          ..cubicTo(lado * 22, -20, lado * 14, -20, lado * 8, -24)
          ..close(),
        _p(sombraForte),
      );
    }

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: 86, height: 70),
        base: 0.96,
      ),
      _p(pelo),
    );

    // O disco facial: dois discos claros que se tocam no meio.
    for (final lado in [-1.0, 1.0]) {
      _oval(
        canvas,
        Rect.fromCenter(center: Offset(lado * 20, 2), width: 46, height: 48),
        barriga,
      );
    }

    _olho(canvas, const Offset(-20, 1), 9, coruja: true);
    _olho(canvas, const Offset(20, 1), 9, coruja: true);

    // Bico entre os discos.
    canvas.drawPath(
      Path()
        ..moveTo(-7, 7)
        ..lineTo(7, 7)
        // O bico se alonga na mordida: bico não abre como boca, e sem
        // nenhum sinal a coruja petiscava de cara parada.
        ..lineTo(0, 22 + pose.mastiga * 3)
        ..close(),
      _p(Cores.acento),
    );
    _naBoca(canvas, const Offset(0, 16), 20);

    if (feliz) _bochecha(canvas, const Offset(-34, 17), const Offset(34, 17));
    _veste(canvas, 86, 70);
    canvas.restore();
  }

  // ======================================================================
  // AXOLOTE — guelras que balançam, a marca da espécie
  // ======================================================================

  void _axolote(Canvas canvas) {
    final amp = pose.amplitude;
    final rema = pose.pernas * amp;
    // As guelras têm ritmo próprio e abrem mais quando ele está na água.
    // Nadando elas vão no compasso da braçada: guelra é respiração, e quem
    // se esforça respira no ritmo do esforço.
    final abana = pose.nadando
        ? pose.pernas * amp * 1.2
        : (pose.cauda * amp) * 0.8;

    _pata(canvas, Offset(-20, 49 + rema * 1.4), 16, 12, sombra, 0,
        dedos: false, rema: -1);
    _pata(canvas, Offset(20, 49 - rema * 1.4), 16, 12, sombra, 0,
        dedos: false, rema: 1);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 20), width: 82, height: 71),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 31), width: 56, height: 55),
        topo: 0.9,
      ),
      _p(claro),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -28 + pose.respiro * amp * 0.7 + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.9);

    // Guelras antes da cabeça: os três ramos de cada lado nascem atrás dela.
    final corDaGuelra = Color.lerp(pelo, Cores.acento, 0.34)!;
    for (final lado in [-1.0, 1.0]) {
      final l = lado;
      final a = abana * 3 * l;
      canvas.drawPath(
        Path()
          ..moveTo(l * 30, -18)
          ..cubicTo(l * 44, -31 + a, l * 56, -35 + a, l * 63, -30 + a)
          ..cubicTo(l * 59, -21 + a, l * 49, -15, l * 39, -13)
          ..cubicTo(l * 34, -13, l * 31, -15, l * 30, -18)
          ..close(),
        _p(corDaGuelra),
      );
      canvas.drawPath(
        Path()
          ..moveTo(l * 34, -2)
          ..cubicTo(l * 49, -4 - a, l * 59, -1 - a, l * 62, 6 - a)
          ..cubicTo(l * 56, 12 - a, l * 46, 12, l * 37, 8)
          ..cubicTo(l * 34, 6, l * 33, 2, l * 34, -2)
          ..close(),
        _p(corDaGuelra),
      );
      canvas.drawPath(
        Path()
          ..moveTo(l * 31, 12)
          ..cubicTo(l * 45, 15 + a, l * 54, 21 + a, l * 56, 28 + a)
          ..cubicTo(l * 49, 32 + a, l * 39, 30, l * 32, 23)
          ..cubicTo(l * 29, 19, l * 29, 15, l * 31, 12)
          ..close(),
        _p(corDaGuelra),
      );
    }

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 0.7), width: 86, height: 73),
        base: 1.04,
      ),
      _p(pelo),
    );

    _boca(canvas, const Offset(0, 14), 22);
    if (feliz) _bochecha(canvas, const Offset(-30, 6), const Offset(30, 6));

    _olho(canvas, const Offset(-20, -6), 7.5);
    _olho(canvas, const Offset(20, -6), 7.5);
    _veste(canvas, 86, 73);

    canvas.restore();
  }

  // ======================================================================
  // PINGUIM — barriga clara, nadadeiras coladas, pés laranja
  // ======================================================================

  void _pinguim(Canvas canvas) {
    final amp = pose.amplitude;
    final asa = pose.asa * amp;
    final passo = pose.pernas * amp;

    // Pés laranja com três riscos de dedo, apoiados. Na água eles não
    // caminham: ficam esticados atrás como leme, e quem move o pinguim são
    // as nadadeiras. Um pinguim que rema com o pé é um pato.
    final leme = pose.nadando ? 7.0 : 0.0;
    for (final lado in [-1.0, 1.0]) {
      final desloca = lado * passo * 1.4;
      canvas.save();
      canvas.translate(lado * (17 + leme * 0.6) + desloca, 50 + leme);
      canvas.drawPath(
        _bolha(
          Rect.fromCenter(center: Offset.zero, width: 20, height: 13),
          base: 0.86,
        ),
        _p(Cores.acento),
      );
      final dedo = _traco(Cores.acentoForte, 1.5);
      for (final dx in [-4.4, 0.0, 4.4]) {
        canvas.drawLine(Offset(dx, 3.2), Offset(dx, 6.3), dedo);
      }
      canvas.restore();
    }

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 12), width: 90, height: 91),
      topo: 0.9,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    // Barriga: quase branca, é ela que faz ler "pinguim".
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 17), width: 60, height: 82),
        topo: 0.9,
      ),
      _p(Color.lerp(claro, Cores.superficie, 0.62)!),
    );
    canvas.restore();

    // Nadadeiras: coladas no corpo, abrem de leve ao respirar — e **remam**
    // quando ele está na água, uma subindo enquanto a outra desce.
    //
    // O pinguim "voa" embaixo d'água: é a nadadeira que o empurra, e ela
    // alterna. Abrindo as duas juntas, como no repouso, ele parecia estar
    // dando de ombros.
    for (final lado in [-1.0, 1.0]) {
      final alterna = pose.nadando ? lado : 1.0;
      final abre = asa * 3 * lado * alterna;
      final sobe = pose.nadando ? asa * 5 * lado : 0.0;
      // Borda externa em ±44 num corpo de ±45: a nadadeira fica **dentro**
      // do contorno. Passando dele, sobrava uma fresta do fundo entre as
      // duas, que lia como risco branco no bicho.
      canvas.drawPath(
        Path()
          ..moveTo(lado * 30, -14 + sobe)
          ..cubicTo(
            lado * (44 + abre), 0 + sobe,
            lado * (43 + abre), 24 + sobe,
            lado * 26, 36 + sobe,
          )
          ..cubicTo(lado * 22, 14 + sobe, lado * 23, -4 + sobe,
              lado * 30, -14 + sobe)
          ..close(),
        _p(sombraForte),
      );
    }

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -34 + pose.respiro * amp * 0.6 + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.9);

    canvas.drawPath(
      _bolha(Rect.fromCenter(center: Offset.zero, width: 72, height: 60)),
      _p(pelo),
    );

    // Máscara clara do rosto.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 8), width: 50, height: 32),
        topo: 0.86,
      ),
      _p(Color.lerp(claro, Cores.superficie, 0.62)!),
    );

    if (feliz) _bochecha(canvas, const Offset(-26, 9), const Offset(26, 9));

    _olho(canvas, const Offset(-15, -3), 7);
    _olho(canvas, const Offset(15, -3), 7);

    // Bico: um triângulo laranja, o único traço reto do bicho.
    canvas.drawPath(
      Path()
        ..moveTo(-6, 5)
        ..lineTo(6, 5)
        ..lineTo(0, 17)
        ..close(),
      _p(Cores.acento),
    );
    if (pose.bocejo > 0.3 || pose.carinho > 0.4 || pose.mastiga > 0.30) {
      canvas.drawPath(
        Path()
          ..moveTo(-4.5, 11)
          ..lineTo(4.5, 11)
          ..lineTo(0, 18.5)
          ..close(),
        _p(Color.lerp(Cores.acentoForte, Cores.tinta, 0.35)!),
      );
    }
    _naBoca(canvas, const Offset(0, 12), 18);
    _veste(canvas, 72, 60);

    canvas.restore();
  }

  // ======================================================================
  // GATA — orelhas triangulares, focinho em coração, bigodes longos
  // ======================================================================

  void _gata(Canvas canvas) {
    final amp = pose.amplitude;
    // Brincando, a cauda chicoteia no compasso do salto. É o rabo que
    // denuncia o bicho animado; no ritmo solto de sempre ele parecia
    // distraído no meio do pulo.
    final balanca =
        pose.brincando ? pose.pernas * amp * 1.5 : pose.cauda * amp;

    // Cauda: sobe e enrola, com ritmo próprio.
    canvas.drawPath(
      Path()
        ..moveTo(26, 36)
        ..cubicTo(
          54 + balanca * 4, 30,
          64 + balanca * 7, 10 + balanca * 5,
          60 + balanca * 8, -14 + balanca * 7,
        )
        ..cubicTo(54, -4, 46, 14, 24, 30)
        ..close(),
      _p(sombraForte),
    );

    _pata(canvas, const Offset(-19, 49), 16, 12, sombra, pose.pernas * amp);
    _pata(canvas, const Offset(19, 49), 16, 12, sombra, -pose.pernas * amp);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 20), width: 80, height: 70),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 31), width: 54, height: 53),
        topo: 0.9,
      ),
      _p(claro),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -28 + pose.respiro * amp * 0.7 + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.9);

    // Orelhas triangulares, com a concha por dentro. Antes da cabeça: a base
    // some sob o contorno.
    for (final lado in [-1.0, 1.0]) {
      final treme = pose.orelha * 0.6 * lado;
      canvas.drawPath(
        Path()
          ..moveTo(lado * 34, -14)
          ..cubicTo(
            lado * 40, -30,
            lado * (36 + treme * 6), -42,
            lado * (26 + treme * 8), -45,
          )
          ..cubicTo(lado * 20, -37, lado * 16, -28, lado * 14, -20)
          ..cubicTo(lado * 20, -16, lado * 28, -13, lado * 34, -14)
          ..close(),
        _p(pelo),
      );
      canvas.drawPath(
        Path()
          ..moveTo(lado * 30, -19)
          ..cubicTo(
            lado * 33, -29,
            lado * (31 + treme * 5), -36,
            lado * (25 + treme * 6), -38,
          )
          ..cubicTo(lado * 21, -32, lado * 19, -26, lado * 18, -21)
          ..cubicTo(lado * 22, -19, lado * 27, -18, lado * 30, -19)
          ..close(),
        _p(Color.lerp(sombra, Cores.acento, 0.30)!),
      );
    }

    final cabeca = _bolha(
      Rect.fromCenter(center: const Offset(0.7, 0.7), width: 82, height: 69),
    );
    canvas.drawPath(cabeca, _p(pelo));

    // Listras da testa: o que faz ler "gata" e não "urso".
    canvas.save();
    canvas.clipPath(cabeca);
    final listra = _traco(sombra.withValues(alpha: 0.55), 3);
    for (final x in [-11.0, 0.0, 11.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, -34)
          ..cubicTo(x * 0.9, -29, x * 0.82, -24, x * 0.78, -20),
        listra,
      );
    }
    canvas.restore();

    // Focinheira clara e larga.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 15), width: 34, height: 20),
        topo: 0.86,
      ),
      _p(claro),
    );

    _bigodes(canvas, const Offset(-19, 11));
    _bigodes(canvas, const Offset(19, 11), lado: 1);

    // Nariz em coração invertido — a marca do felino.
    canvas.drawPath(
      Path()
        ..moveTo(-4, 7.5)
        ..cubicTo(-4, 5.8, 4, 5.8, 4, 7.5)
        ..cubicTo(4, 10.5, 1, 12.5, 0, 12.5)
        ..cubicTo(-1, 12.5, -4, 10.5, -4, 7.5)
        ..close(),
      _p(const Color(0xFFD67F74)),
    );

    _boca(canvas, const Offset(0, 17), 20);
    if (feliz) _bochecha(canvas, const Offset(-30, 12), const Offset(30, 12));

    _olho(canvas, const Offset(-19, -6), 7.5);
    _olho(canvas, const Offset(19, -6), 7.5);
    _veste(canvas, 82, 69);

    canvas.restore();
  }

  // ======================================================================
  // RAPOSA — orelhas grandes de ponta escura, cauda de ponta clara
  // ======================================================================

  void _raposa(Canvas canvas) {
    final amp = pose.amplitude;
    // Mesma razão da gata: no salto a pluma acompanha o corpo.
    final balanca =
        pose.brincando ? pose.pernas * amp * 1.5 : pose.cauda * amp;

    // Cauda grossa com a ponta clara — é ela que nomeia a raposa.
    // Cauda em pluma: sai baixa, atrás do corpo, e engrossa até a ponta.
    // Saindo estreita e para cima ela lia como braço levantado.
    final pontaX = 74 + balanca * 6;
    final pontaY = 2 + balanca * 7;
    final cauda = Path()
      ..moveTo(18, 44)
      ..cubicTo(48, 50, 70 + balanca * 4, 34, pontaX, pontaY)
      ..cubicTo(80, -12, 62, -16, 54, -2)
      ..cubicTo(46, 14, 34, 26, 14, 30)
      ..close();
    canvas.drawPath(cauda, _p(sombraForte));
    canvas.save();
    canvas.clipPath(cauda);
    // Ponta clara: é ela que nomeia a raposa. Um disco grande, senão some.
    canvas.drawCircle(Offset(pontaX - 4, pontaY - 4), 17, _p(claro));
    canvas.restore();

    _pata(
        canvas, const Offset(-19, 49), 16, 12, sombraForte, pose.pernas * amp);
    _pata(
        canvas, const Offset(19, 49), 16, 12, sombraForte, -pose.pernas * amp);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 20), width: 78, height: 70),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 27), width: 56, height: 55),
        topo: 0.9,
      ),
      _p(claro),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -28 + pose.respiro * amp * 0.7 + _cabecaDesce);
    canvas.rotate(_cabecaGiro * 0.9);

    // Orelhas grandes, em três camadas: pelo, concha clara e ponta escura.
    for (final lado in [-1.0, 1.0]) {
      final treme = pose.orelha * 0.6 * lado;
      final t = treme * 7;
      canvas.drawPath(
        Path()
          ..moveTo(lado * 38, -10)
          ..cubicTo(lado * 46, -28, lado * (42 + t), -44, lado * (30 + t), -48)
          ..cubicTo(lado * 22, -38, lado * 16, -26, lado * 14, -16)
          ..cubicTo(lado * 22, -12, lado * 32, -10, lado * 38, -10)
          ..close(),
        _p(pelo),
      );
      canvas.drawPath(
        Path()
          ..moveTo(lado * 32, -16)
          ..cubicTo(lado * 36, -26, lado * (33 + t), -34, lado * (27 + t), -37)
          ..cubicTo(lado * 23, -30, lado * 20, -24, lado * 19, -19)
          ..cubicTo(lado * 24, -16, lado * 29, -15, lado * 32, -16)
          ..close(),
        _p(claro),
      );
      canvas.drawPath(
        Path()
          ..moveTo(lado * 37, -27)
          ..cubicTo(lado * 41, -38, lado * (38 + t), -45, lado * (30 + t), -47)
          ..cubicTo(lado * 26, -42, lado * 23, -36, lado * 21, -31)
          ..cubicTo(lado * 26, -28, lado * 33, -26, lado * 37, -27)
          ..close(),
        _p(sombraForte),
      );
    }

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 3), width: 80, height: 66),
      ),
      _p(pelo),
    );

    // Focinho longo e claro, que separa raposa de gata.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 17), width: 52, height: 26),
        topo: 0.86,
      ),
      _p(claro),
    );

    // Nariz escuro na ponta.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 9), width: 13, height: 10),
        base: 1.1,
      ),
      _p(Color.lerp(sombraForte, Cores.tinta, 0.45)!),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-2.4, 7.4), width: 5, height: 3),
      _p(luz.withValues(alpha: 0.45)),
    );

    _boca(canvas, const Offset(0, 19), 20);
    if (feliz) _bochecha(canvas, const Offset(-30, 14), const Offset(30, 14));

    _olho(canvas, const Offset(-19, -4), 7.5);
    _olho(canvas, const Offset(19, -4), 7.5);
    _veste(canvas, 80, 66);

    canvas.restore();
  }

  // ======================================================================
  // BULDOGUE FRANCÊS
  //
  // As oito espécies anteriores são bichos silvestres e o vocabulário delas é
  // o mesmo: focinho que projeta, cabeça mais alta que larga, silhueta que
  // afina para baixo. O buldogue é o contrário nos três, e é isso que o torna
  // reconhecível de longe — não a cor.
  //
  // A primeira tentativa foi um urso claro com duas orelhas redondas: nada
  // ali dizia "buldogue francês". A segunda acertou a orelha ereta e errou o
  // resto — orelha de balão, cara lisa, corpo redondo. O que faltava, e está
  // aqui, são **seis** traços, cada um respondendo a um defeito que dava para
  // apontar com o dedo na captura:
  //
  // 1. **Orelha de morcego, e não de rato nem de pastor-alemão.** Base de 34
  //    no alto do crânio, bordas quase retas, altura de 46 e uma calota de 24
  //    fechando o topo — sobe **sem afinar** e termina em arco. Duas
  //    tentativas erradas vieram antes: uma estufava no meio (borda de fora
  //    em 56 com a base em 44) e virava pá de remo; a outra fechava o topo em
  //    14 e virava orelha em ponta. Ver [_orelhaDeMorcego].
  // 2. **Cara achatada de verdade.** Nariz grande e alto, quase entre os
  //    olhos, sobre uma focinheira larga e **rasa** que não avança nada.
  //    Braquicefálico em desenho é isto: a frente da cara é um plano, não uma
  //    ponta.
  // 3. **Rugas que são dobras, e não riscos.** Cada vinco sai de [_dobraDaPele]
  //    — sombra embaixo, luz um fio acima. Um traço escuro sozinho lê como
  //    arranhão; o par lê como pele dobrada, que é o que a raça tem na testa,
  //    entre os olhos e sobre o focinho.
  // 4. **Papada e beiço.** O crânio é um caminho só que **alarga embaixo**
  //    (±46 no topo, ±48 na bochecha) em vez de afinar como o do resto do
  //    elenco, e o lábio superior cai em dois lobos dos lados do focinho, com
  //    os dentinhos de baixo aparecendo no meio. É o terço inferior da cara,
  //    e sem ele sobra um filhote de focinho curto.
  // 5. **Corpo de pera invertida.** Peito largo no ombro (±53) afinando até a
  //    cintura (±30), com duas pernas dianteiras grossas e curtas descendo por
  //    baixo do peito. A bolha simétrica de antes dava um bicho macio; o
  //    buldogue é compacto e musculoso, e músculo em desenho chapado é
  //    **silhueta**, não sombreado. A cabeça subiu de -24 para -29 por causa
  //    disto: a -24 o queixo cobria o ombro inteiro e a pera não aparecia.
  // 6. **Marcação de pelagem.** Máscara escura no fulvo, peito e patas brancos
  //    com manchas escuras no pied, listras no tigrado. Sem elas as seis
  //    entradas da paleta eram o mesmo cão em seis tintas.
  //
  // Sem cauda, de propósito. A da raça é um toco de três centímetros que de
  // frente não aparece; a pluma da raposa ou a curva da gata dariam outro
  // cachorro, e um toco solto no flanco lê como defeito de traço.
  // ======================================================================

  /// O que a pelagem escolhida **desenha**, além de tingir.
  ///
  /// A paleta do buldogue é a única do elenco que troca de pigmento em vez de
  /// trocar de tom (ver `Cores.pelagemBuldogue`), e pigmento de cão vem com
  /// marcação junto: fulvo vem com máscara, creme é a base do pied, tigrado é
  /// listrado por definição. Tratar as seis como seis tintas era desperdiçar
  /// a metade da pelagem que o olho de fato usa para reconhecer a raça.
  _MarcaDoBuldogue get _marca => switch (coatIndex) {
        0 || 1 => _MarcaDoBuldogue.mascara,
        2 => _MarcaDoBuldogue.pied,
        3 => _MarcaDoBuldogue.tigrado,
        // Blue e preto saem lisos. É o que o padrão da raça dá: são cores de
        // pelo, não desenhos. Forçar mancha neles seria inventar um cão.
        _ => _MarcaDoBuldogue.solida,
      };

  /// O branco do pied: peito, patas e focinho.
  Color get _brancoDoPied => Color.lerp(Cores.superficie, pelo, 0.06)!;

  /// A **mancha** do pied — orelhas, um dos olhos e a sela do dorso.
  ///
  /// O pied não é um cão branco com detalhes brancos, e foi assim que a
  /// primeira versão saiu: base creme com manchas quase brancas por cima, que
  /// contra creme não aparecem de jeito nenhum. Pied é o contrário — o cão é
  /// claro e as **manchas é que são escuras**. Invertida, a pelagem passou de
  /// a mais apagada das seis à mais reconhecível.
  Color get _manchaDoPied => Color.lerp(pelo, Cores.tinta, 0.52)!;

  /// O tom da máscara: o pelo levado quase à tinta.
  ///
  /// Sai de [pelo] e não de uma cor fixa porque a máscara tem de continuar
  /// sendo *aquele* cão mais escuro — uma cor absoluta ficaria roxa no blue e
  /// preta no fulvo, e as duas leriam como buraco na cara.
  ///
  /// 0,45 e não 0,55: na primeira tentativa a máscara ficava tão escura que
  /// engolia nariz, boca e vinco — restavam dois olhos e dois dentes flutuando
  /// num borrão marrom. Máscara é sombra na cara, não buraco nela.
  Color get _tomDaMascara => Color.lerp(pelo, Cores.tinta, 0.45)!;

  /// O quanto a orelha tomba, de 0 (ereta) a 1 (deitada de lado).
  ///
  /// É o sinal de humor mais barato que um cão tem, e o mais legível de
  /// longe: orelha em pé é atenção, orelha caída para os lados é o que todo
  /// mundo chama de "orelha de avião" e lê como abatimento antes de qualquer
  /// boca ou sobrancelha. Num bicho cuja marca registrada **é** a orelha,
  /// desperdiçá-la como enfeite fixo seria jogar fora o melhor canal.
  double get _orelhaTomba {
    final doHumor = switch (mood) {
      Mood.radiant => 0.0,
      Mood.content => 0.05,
      Mood.neutral => 0.18,
      Mood.sleepy => 0.58,
      Mood.missingYou => 0.82,
    };
    // Cochilando ela cai mesmo com humor alegre: o bicho está dormindo, e
    // orelha ereta num bicho de olhos fechados lê como bicho fingindo.
    return math.max(doHumor, acao == AcaoDoBicho.cochilo ? 0.62 : 0.0);
  }

  void _buldogue(Canvas canvas) {
    final amp = pose.amplitude;
    final passo = pose.pernas * amp;

    _buldogueCorpo(canvas, passo);

    // --- cabeça -----------------------------------------------------------
    //
    // Presa a -29, contra os -28 do resto do elenco, e num crânio baixo. Os
    // dois números servem à mesma coisa, e não é só abrir espaço para a
    // orelha: com a cabeça a -24 o queixo descia até a altura 22 do corpo e
    // **cobria o ombro inteiro**. Sobrava do tronco só a cintura, então a
    // pera invertida — o traço que faz o bicho parecer compacto e musculoso —
    // não aparecia em pixel nenhum. Cinco pixels acima e o ombro sai de trás
    // da cabeça dos dois lados.
    //
    // O teto é o quadro: 150 px de altura, e a ponta da orelha não pode
    // passar de uns 9 px do topo — foi o que cortou o tufo da coruja.
    canvas.save();
    canvas.translate(0, -29 + pose.respiro * amp * 0.7 + _cabecaDesce);
    // A inclinação de cabeça do cão que não entende por que você sumiu. Meio
    // grau só; mais que isso e ele fica tonto em vez de sentido.
    canvas.rotate(_cabecaGiro * 0.9 + (triste ? 0.05 : 0));

    _buldogueCabeca(canvas);

    canvas.restore();
  }

  // --- corpo --------------------------------------------------------------

  /// Peito largo, cintura estreita, pernas grossas e curtas.
  void _buldogueCorpo(Canvas canvas, double passo) {
    final pied = _marca == _MarcaDoBuldogue.pied;

    // O tronco em pera invertida. Não sai de [_bolha] como o dos outros oito:
    // aquela primitiva é simétrica no eixo vertical e o que precisa acontecer
    // aqui é o contrário dela — largo em cima, estreito embaixo. Ombro em
    // ±53 na altura 10, cintura em ±30 na altura 54.
    final tronco = Path()
      ..moveTo(0, -17)
      ..cubicTo(30, -17, 52, -5, 53, 13)
      ..cubicTo(54, 31, 43, 47, 30, 54)
      ..cubicTo(19, 61, -19, 61, -30, 54)
      ..cubicTo(-43, 47, -54, 31, -53, 13)
      ..cubicTo(-52, -5, -30, -17, 0, -17)
      ..close();
    canvas.drawPath(tronco, _p(pelo));

    canvas.save();
    canvas.clipPath(tronco);

    // A sela do pied: a mancha escura no dorso e nos ombros. É ela que faz o
    // resto do corpo ler como branco, e não como "creme sem nada".
    if (pied) {
      canvas.drawPath(
        Path()
          ..moveTo(-56, -6)
          ..cubicTo(-40, -22, 40, -22, 56, -6)
          ..cubicTo(50, 14, 30, 4, 8, 10)
          ..cubicTo(-14, 16, -40, 12, -56, -6)
          ..close(),
        _p(_manchaDoPied),
      );
    }

    // O tigrado **antes** do peito, e não depois. Com as listras por cima, a
    // barriga clara saía com um código de barras no meio: rajado é pelo de
    // dorso e de flanco, e o peito de um brindle é justamente onde ele
    // clareia.
    if (_marca == _MarcaDoBuldogue.tigrado) _tigradoDoCorpo(canvas);

    // O peito. No pied é mancha de pelagem e precisa de borda visível; nas
    // outras é só o ventre mais claro, como nas oito espécies antigas.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 30), width: 46, height: 58),
        topo: 0.82,
      ),
      _p(pied ? _brancoDoPied : barriga),
    );

    // O vinco do ombro, um de cada lado. É o que dá o "musculoso": a linha
    // onde a perna da frente encontra o peito. Uma sombra chapada no topo do
    // corpo daria volume mas não daria anatomia — o que lê como força é o
    // traço que mostra onde um músculo acaba e o outro começa.
    //
    // Curto e alto, colado no ombro. Descendo até a cintura, como na primeira
    // versão, ele virava um risco solto no flanco — e o elenco inteiro tem
    // pouquíssimo traço interno, então cada linha a mais aqui destoa.
    for (final lado in [-1.0, 1.0]) {
      _dobraDaPele(
        canvas,
        Path()
          ..moveTo(lado * 30, -11)
          ..cubicTo(lado * 44, -3, lado * 47, 8, lado * 44, 19),
        forca: 0.7,
      );
    }
    canvas.restore();

    // Pernas dianteiras: colunas curtas e grossas, saindo por baixo do peito.
    // Antes só havia as patas, e um corpo sem perna nenhuma boiando sobre
    // dois pés é o que fazia a silhueta ler como bolha macia. Ficam **depois**
    // do recorte do tronco de propósito: elas passam da linha dele embaixo,
    // que é exatamente onde uma perna dianteira aparece num cão sentado de
    // frente.
    //
    // Separadas do peito por **tom**, não por traço. Dois riscos a mais na
    // barriga era o que mais destoava do resto do elenco, onde membro se
    // separa de tronco pela cor e nunca por contorno.
    for (final lado in [-1.0, 1.0]) {
      final desloca = passo * 0.9 * lado;
      final x = lado * 31 + desloca;
      final perna = _bolha(
        Rect.fromCenter(center: Offset(x, 39), width: 21, height: 42),
        // Topo quase reto: a perna sobe e some sob o peito. Com o topo
        // redondo ela virava uma bola encostada no corpo, e o bicho ficava
        // com duas almofadas em vez de duas pernas.
        topo: 0.34,
      );
      canvas.drawPath(perna, _p(Color.lerp(pelo, Cores.tinta, 0.13)!));
      // A meia branca do pied. Desenhada como parte da perna, e não pintando
      // a perna inteira: perna branca inteira somava com o peito branco e o
      // terço de baixo do bicho virava uma mancha só, sem forma.
      if (pied) {
        canvas.save();
        canvas.clipPath(perna);
        canvas.drawRect(
          Rect.fromLTRB(x - 14, 38, x + 14, 62),
          _p(_brancoDoPied),
        );
        canvas.restore();
      }
    }

    // Patas largas e bem afastadas — mais que as de qualquer outro daqui. O
    // buldogue apoia em base ampla, e é isso que o faz parecer plantado no
    // chão em vez de equilibrado sobre as pernas.
    //
    // Depois das pernas, e não antes como nas outras espécies: aqui existe
    // perna, e pé atrás da perna some quase todo.
    //
    // Sem `rema`: ele nunca nada (ver [acaoDoBicho]), e passar o parâmetro
    // seria deixar no código a promessa de um movimento que não acontece.
    final corDaPata = pied ? _brancoDoPied : sombra;
    _pata(canvas, const Offset(-31, 55), 27, 15, corDaPata, passo * 0.9);
    _pata(canvas, const Offset(31, 55), 27, 15, corDaPata, -passo * 0.9);
  }

  /// As listras do tigrado no tronco.
  ///
  /// Verticais e tortas, do dorso para a barriga, afinando embaixo — é como
  /// o brindle corre num cão de verdade, e listra horizontal daria zebra.
  /// Recortadas pelo tronco por quem chama: sem o recorte elas passariam da
  /// silhueta e o bicho ficaria riscado por fora.
  void _tigradoDoCorpo(Canvas canvas) {
    final tinta = _p(Color.lerp(pelo, Cores.tinta, 0.30)!);
    for (var i = 0; i < 13; i++) {
      final x = -50.0 + i * 8.2;
      // A largura oscila de listra para listra. Todas iguais leem como
      // padrão de tecido; o brindle de um cão é irregular.
      final largura = 3.4 + (i % 3) * 1.1;
      canvas.drawPath(
        Path()
          ..moveTo(x, -20)
          ..cubicTo(x + 5, 0, x + 3, 24, x + 8, 48)
          ..lineTo(x + 8 + largura, 48)
          ..cubicTo(x + 3 + largura, 24, x + 5 + largura, 0, x + largura, -20)
          ..close(),
        tinta,
      );
    }
  }

  // --- cabeça -------------------------------------------------------------

  void _buldogueCabeca(Canvas canvas) {
    final tomba = _orelhaTomba;

    // Orelhas antes da cabeça: a base some sob o contorno, como nas outras.
    for (final lado in [-1.0, 1.0]) {
      _orelhaDeMorcego(canvas, lado, tomba);
    }

    // O crânio, **com a papada dentro do mesmo contorno**: topo largo e
    // achatado, laterais quase retas e a maior largura lá embaixo, na altura
    // da bochecha (±48 em y=26 contra ±44 em y=2). É a proporção invertida do
    // resto do elenco, onde a cabeça afina para o queixo; aqui ela alarga,
    // porque o peso do buldogue está na mandíbula.
    //
    // Não sai de [_bolha] e a papada não é mais desenhada à parte. A primeira
    // versão empilhava duas bolhas de bochecha por fora de um crânio oval, e
    // o contorno resultante tinha três calombos de cada lado — de longe lia
    // como cabeça inchada, não como papada. Papada é a **linha** da cabeça
    // descendo e abrindo, e linha só sai de um caminho só.
    final cabeca = Path()
      ..moveTo(0, -21)
      ..cubicTo(31, -21, 45, -13, 46, 5)
      ..cubicTo(48, 20, 46, 30, 40, 36)
      ..cubicTo(32, 44, 16, 46, 0, 46)
      ..cubicTo(-16, 46, -32, 44, -40, 36)
      ..cubicTo(-46, 30, -48, 20, -46, 6)
      ..cubicTo(-44, -12, -25, -20, 0, -20)
      ..close();

    canvas.drawPath(cabeca, _p(pelo));

    canvas.save();
    canvas.clipPath(cabeca);
    _marcaDaCabeca(canvas);
    _rugasDaCabeca(canvas);

    // A prega que separa a papada da bochecha, uma de cada lado. Dentro do
    // recorte porque a papada agora é parte do contorno da cabeça: solta, ela
    // vazava pela borda e virava um risco no ar ao lado do queixo.
    for (final lado in [-1.0, 1.0]) {
      _dobraDaPele(
        canvas,
        Path()
          ..moveTo(lado * 27, 11)
          ..cubicTo(lado * 39, 17, lado * 42, 29, lado * 34, 40),
        forca: 0.85,
      );
    }
    canvas.restore();

    _focinhoDoBuldogue(canvas);

    if (feliz) {
      _bochecha(canvas, const Offset(-37, 22), const Offset(37, 22));
    }

    // Olhos grandes, redondos e bem afastados — 8,6 de raio, o maior do
    // elenco fora a coruja. Os ±27 num crânio de 96 são o que separa o
    // buldogue do resto, onde os olhos vivem a menos de um quarto da largura
    // do centro: juntos, eles empurravam a cara para o meio e o bicho ficava
    // com cara de filhote genérico.
    //
    // `sobrancelha: false` porque ele tem o par próprio, logo abaixo.
    _olho(canvas, const Offset(-27, 2), 8.6, sobrancelha: false);
    _olho(canvas, const Offset(27, 2), 8.6, sobrancelha: false);
    for (final lado in [-1.0, 1.0]) {
      _sobrancelhaDoBuldogue(canvas, lado);
    }

    _veste(canvas, 96, 64);
  }

  /// A orelha de morcego: base larga no alto do crânio, bordas convergindo,
  /// topo estreito e arredondado.
  ///
  /// [tomba] de 0 a 1 deita a orelha para fora, girando-a em torno da própria
  /// base e encolhendo-a um pouco — orelha que tomba sem encurtar parece
  /// orelha quebrada, não orelha relaxada.
  void _orelhaDeMorcego(Canvas canvas, double lado, double tomba) {
    // O tremor de escuta some conforme a orelha cai: cão de orelha deitada
    // não está prestando atenção em nada, e o tremor ali viraria tique.
    final treme = pose.orelha * 0.6 * lado * (1 - tomba);
    final t = treme * 7;

    canvas.save();
    // Gira em torno da base, não do centro: o ponto fixo de uma orelha é onde
    // ela prende no crânio.
    canvas.translate(lado * 27, -6);
    canvas.rotate(lado * tomba * 0.95);
    canvas.scale(1, 1 - tomba * 0.20);
    canvas.translate(-lado * 27, 6);

    // As medidas que fazem a orelha ler como "de morcego": base de 34 num
    // crânio de 96 — mais de um terço da cabeça de cada lado —, altura de 46,
    // e uma **calota larga** fechando o topo. A razão de 1,35 entre altura e
    // base é a do padrão da raça.
    //
    // Duas tentativas erradas ficaram no caminho e valem a nota. A primeira
    // estufava no meio (borda de fora em 56 com a base em 44): virava pá de
    // remo. A segunda afinava o topo para 14: virava orelha de
    // pastor-alemão. O que faz a orelha do buldogue é ela subir **sem
    // afinar** e terminar em arco largo.
    canvas.drawPath(
      Path()
        ..moveTo(lado * 46, 0)
        ..cubicTo(lado * 49, -14, lado * (48 + t), -30, lado * (40 + t), -41)
        ..cubicTo(lado * (34 + t), -49, lado * (21 + t), -49, lado * 16, -38)
        ..cubicTo(lado * 13, -25, lado * 12, -12, lado * 12, 0)
        ..close(),
      _p(_marca == _MarcaDoBuldogue.pied ? _manchaDoPied : pelo),
    );

    // A concha, por dentro, e larga: ela ocupa quase toda a orelha, como o
    // pavilhão de verdade ocupa. Uma fresta fina no meio lia como vinco, não
    // como ouvido.
    //
    // Sai de `sombraForte`, e não de `sombra`: partindo do tom médio ela
    // ficava mais **clara** que o pelo depois da mistura com o acento, e a
    // orelha lia ao contrário — o miolo saltando à frente da borda.
    canvas.drawPath(
      Path()
        ..moveTo(lado * 41, -1)
        ..cubicTo(lado * 43, -14, lado * (42 + t), -27, lado * (36 + t), -36)
        ..cubicTo(lado * (31 + t), -43, lado * (22 + t), -43, lado * 19, -34)
        ..cubicTo(lado * 17, -23, lado * 17, -11, lado * 17, -1)
        ..close(),
      _p(Color.lerp(sombraForte, Cores.acento, 0.28)!),
    );
    canvas.restore();
  }

  /// A marcação da pelagem na cara: máscara, blaze do pied ou listras.
  ///
  /// Chamada **dentro** do recorte do crânio por quem a usa, e por isso não
  /// salva o canvas: quem recorta é quem chama.
  void _marcaDaCabeca(Canvas canvas) {
    switch (_marca) {
      case _MarcaDoBuldogue.mascara:
        // A máscara do fulvo: escurece a frente da cara e sobe em dois lobos
        // para envolver os olhos. Um retângulo escuro no terço de baixo
        // daria barba de bode; o que faz ler "máscara" é ela **subir** até
        // os olhos e parar ali.
        //
        // Largura ±31 num crânio de ±49: ela para bem antes da borda, e é
        // essa faixa de fulvo que sobra na bochecha que a faz ler como
        // máscara. Cobrindo até a borda (±40, como na primeira tentativa) o
        // bicho virava um cão escuro de testa clara.
        //
        // O topo é **um arco só**. A segunda tentativa subia em dois lobos
        // para envolver os olhos e o vão entre eles desenhava um "W" bem em
        // cima do nariz: com as sobrancelhas por perto, a cara saía de macaco
        // zangado em todos os cinco humores. A máscara do buldogue é a frente
        // do focinho escura passando **por baixo** dos olhos, e é só isso.
        canvas.drawPath(
          Path()
            ..moveTo(-31, 13)
            ..cubicTo(-30, 0, -17, -6, 0, -6)
            ..cubicTo(17, -6, 30, 0, 31, 13)
            ..cubicTo(33, 31, 26, 42, 0, 42)
            ..cubicTo(-26, 42, -33, 31, -31, 13)
            ..close(),
          _p(_tomDaMascara),
        );
      case _MarcaDoBuldogue.pied:
        // A mancha de um olho só. É **assimétrica de propósito**: o pied de
        // verdade é assim, e é essa quebra que faz o desenho parecer um cão
        // específico em vez de um decalque. Simétrica ela viraria máscara de
        // bandido, que é outra coisa e já é o desenho do fulvo.
        //
        // Fica na esquerda de quem olha porque é o lado onde a cara tem menos
        // acontecendo: o talo do petisco sai pelo canto direito da boca.
        canvas.drawPath(
          Path()
            ..moveTo(-46, -6)
            ..cubicTo(-42, -20, -22, -22, -13, -12)
            ..cubicTo(-8, -4, -10, 12, -18, 20)
            ..cubicTo(-30, 28, -44, 18, -46, -6)
            ..close(),
          _p(_manchaDoPied),
        );
      case _MarcaDoBuldogue.tigrado:
        // Listras da cara: muitas, finas e tortas. Poucas e grossas — seis de
        // 9 px, como saiu da primeira vez — não leem como tigrado: leem como
        // uniforme listrado. O brindle de um cão é rajado, quase textura, e
        // textura se faz com repetição.
        //
        // Param em y = 12, antes do focinho: cruzando a focinheira elas
        // riscavam o nariz e a boca, que são as duas formas que a cara tem
        // para trabalhar. Listra é fundo, nunca por cima do desenho.
        final tinta = _p(Color.lerp(pelo, Cores.tinta, 0.26)!);
        for (var i = 0; i < 11; i++) {
          final x = -44.0 + i * 8.4;
          if (x.abs() < 9) continue; // deixa o meio da testa livre
          canvas.drawPath(
            Path()
              ..moveTo(x, -24)
              ..cubicTo(x + 3, -12, x + 2, 0, x + 5, 12)
              ..lineTo(x + 8.6, 12)
              ..cubicTo(x + 5.6, 0, x + 6.6, -12, x + 3.6, -24)
              ..close(),
            tinta,
          );
        }
      case _MarcaDoBuldogue.solida:
        break;
    }
  }

  /// Os vincos da cara. Três, e cada um responde a uma pergunta diferente.
  void _rugasDaCabeca(Canvas canvas) {
    // Ruga da testa, entre as sobrancelhas. Arqueada para **cima**, porque a
    // ruga do buldogue nasce do nariz e sobe. Para baixo ela lê como testa
    // franzida, e o bicho fica bravo o tempo todo — inclusive quando a
    // legenda diz que ele está radiante.
    //
    // Ela **funde** com o humor: some quase toda no radiante e aprofunda no
    // sentindo falta, que é o que a testa de um cão de fato faz.
    final vinco = switch (mood) {
      Mood.radiant => 0.35,
      Mood.content => 0.6,
      Mood.neutral => 0.9,
      Mood.sleepy => 0.5,
      Mood.missingYou => 1.0,
    };
    _dobraDaPele(
      canvas,
      Path()
        ..moveTo(-17, -11)
        ..quadraticBezierTo(0, -15 - vinco * 2, 17, -11),
      forca: vinco,
    );

    // O sulco do stop: a depressão vertical entre os olhos, marca da cara
    // achatada. É o que impede a testa de virar uma placa lisa entre dois
    // olhos. Para antes do nariz: descendo até ele o traço encostava na
    // mancha escura e os dois viravam um borrão só.
    _dobraDaPele(
      canvas,
      Path()
        ..moveTo(0, -6)
        ..lineTo(0, -1),
      forca: 0.6,
    );

    // A corda do nariz: a dobra que cruza a ponte, logo acima do focinho. É
    // o vinco mais característico da raça — a única ruga que uma pessoa
    // descreve em palavras ao falar de um buldogue francês.
    //
    // Esta é a única que **não** é um traço: é um rolo cheio, com sombra por
    // baixo. As outras duas são vincos na pele e um par de linhas basta; esta
    // é pele **sobrando**, e sobra de pele tem volume. Como par de linhas ela
    // saía igual à ruga da testa, e a cara ficava com duas listras paralelas
    // em vez de uma testa vincada e um rolo sobre o nariz.
    final fundoDoRolo =
        _marca == _MarcaDoBuldogue.mascara ? _tomDaMascara : pelo;
    // Elipse, e não uma calota de base reta: com `base: 0.5` a borda de baixo
    // saía uma linha horizontal atravessando a cara, e de perto o rolo lia
    // como esparadrapo colado no nariz.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 2), width: 40, height: 12),
      ),
      _p(Color.lerp(fundoDoRolo, luz, 0.26)!),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-19, 4)
        ..cubicTo(-11, 9, 11, 9, 19, 4),
      _traco(sombraForte.withValues(alpha: 0.30), 1.7),
    );
  }

  /// Focinheira rasa, nariz grande, beiço caído e os dentinhos de baixo.
  void _focinhoDoBuldogue(Canvas canvas) {
    // No fulvo mascarado a focinheira é **escura** — é ela o centro da
    // máscara —, no pied é branca, e nas outras é o pelo levemente clareado.
    // Pintar sempre de claro furava um buraco no meio da máscara.
    final corDoFocinho = switch (_marca) {
      _MarcaDoBuldogue.mascara => Color.lerp(_tomDaMascara, pelo, 0.34)!,
      _MarcaDoBuldogue.pied => _brancoDoPied,
      // `claro` (30% para o creme) é o que as outras oito espécies usam, e
      // num pelo preto ele devolve um cinza pálido: de perto o bicho parecia
      // usar focinheira de plástico. Cão preto tem focinho preto; 18% chega
      // para a forma existir sem clarear o pelo.
      _ => Color.lerp(pelo, Cores.superficie, 0.18)!,
    };

    // A focinheira: larga (56 num crânio de 96) e **rasa**. Nas outras
    // espécies ela projeta — a raposa tem 52×26 puxada para a frente. Aqui
    // ela não avança nada, que é o que "braquicefálico" quer dizer em
    // desenho.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 27), width: 56, height: 26),
        topo: 0.70,
      ),
      _p(corDoFocinho),
    );

    // O beiço: o lábio superior caindo em dois lobos, um de cada lado do
    // focinho, com a linha da boca entre eles. Desenhá-lo como um traço só
    // dava um sorriso de gato numa cara que não tem nada de gato — o que a
    // raça tem é lábio pendurado, e lábio pendurado é volume, não linha.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        _bolha(
          Rect.fromCenter(center: Offset(lado * 16, 30), width: 33, height: 25),
          topo: 0.86,
        ),
        _p(Color.lerp(corDoFocinho, sombra, 0.14)!),
      );
    }

    // Nariz enorme, e alto: quase entre os olhos. Mais que o dobro do da
    // raposa (27×17 contra 13×10). Num focinho que não projeta é o nariz que
    // precisa carregar a frente da cara sozinho.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 14), width: 27, height: 17),
        base: 1.12,
      ),
      _p(Color.lerp(sombraForte, Cores.tinta, 0.62)!),
    );
    // Narinas em vírgula, viradas para fora. Dois furos redondos e simétricos
    // leem como tomada elétrica.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(lado * 3.5, 11)
          ..cubicTo(lado * 9, 10, lado * 11, 14, lado * 9, 17.5)
          ..cubicTo(lado * 7, 16.5, lado * 4.5, 14, lado * 3.5, 11)
          ..close(),
        _p(Cores.tinta),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5.5, 9), width: 8, height: 4),
      _p(luz.withValues(alpha: 0.42)),
    );

    // O filtro: o sulco que desce do nariz até a linha da boca, separando os
    // dois lobos do beiço. É de graça e é ele que impede os lobos de leem
    // como duas bolhas encostadas.
    canvas.drawPath(
      Path()
        ..moveTo(0, 22)
        ..lineTo(0, 27),
      _traco(sombra.withValues(alpha: 0.45), 1.8),
    );

    // Tinta cheia na boca, não `sombraForte`: ver a nota em [_boca].
    _boca(
      canvas,
      const Offset(0, 30),
      30,
      cor: Color.lerp(Cores.tinta, corDoFocinho, 0.18)!,
    );
    // Prognatismo: dois dentinhos de baixo aparecendo por cima do lábio. É o
    // traço do padrão da raça que ninguém desenha e todo mundo reconhece —
    // sem ele a cara achatada fica com um sorriso de gato.
    //
    // Desenhados **depois** de [_boca] de propósito: com a boca aberta eles
    // caem sobre o vão escuro, que é onde os dentes de baixo de fato ficam.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        _bolha(
          Rect.fromCenter(center: Offset(lado * 4.4, 34), width: 5.6, height: 6),
          topo: 0.8,
        ),
        _p(Cores.superficie),
      );
    }

    // A língua **depois** dos dentes: ela cai por fora do lábio, e é a
    // primeira coisa que fica na frente de tudo. Desenhada antes, os dois
    // dentinhos ficavam pousados em cima dela.
    _linguaDoBuldogue(canvas);
  }

  /// A língua de fora — só quando ele está de fato alegre.
  ///
  /// É o gesto que o dono do produto reconhece de imediato num cão, e o que
  /// mais separa o buldogue radiante do contente. Fica fora dos outros três
  /// humores de propósito: língua pendurada num bicho que está sentindo sua
  /// falta viraria um cão ofegante, que é outra coisa.
  void _linguaDoBuldogue(Canvas canvas) {
    if (mood != Mood.radiant && pose.gosto < 0.5) return;
    // Ela cresce com a alegria em vez de aparecer inteira de uma vez: um
    // apêndice que liga e desliga entre dois quadros lê como falha de
    // desenho.
    final quanto = mood == Mood.radiant
        ? 1.0
        : ((pose.gosto - 0.5) / 0.5).clamp(0.0, 1.0);
    // Balança de leve com a respiração. Língua parada é língua de plástico.
    final oscila = pose.respiro * pose.amplitude * 1.6;
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(
          center: Offset(oscila, 35 + quanto * 4),
          width: 19,
          height: 9 + quanto * 14,
        ),
        topo: 0.4,
      ),
      _p(Color.lerp(Cores.acento, Cores.superficie, 0.28)!),
    );
    // O sulco do meio: sem ele a língua é uma gota rosa e pode ler como
    // qualquer outra coisa pendurada na boca.
    canvas.drawLine(
      Offset(oscila, 35 + quanto * 2),
      Offset(oscila, 35 + quanto * 11),
      _traco(Color.lerp(Cores.acento, Cores.tinta, 0.35)!, 1.3),
    );
  }

  /// A sobrancelha, que é onde o humor de um cão mora.
  ///
  /// Buldogue francês tem a marca da sobrancelha visível no pelo acima do
  /// olho, e é ela — não a boca — que um humano lê primeiro num cachorro. Os
  /// dois números por humor são a altura da ponta de dentro e a da ponta de
  /// fora, em pixels a partir da linha de base; negativo sobe.
  ///
  /// O par que carrega o desenho todo é o do `missingYou`: ponta interna alta
  /// e externa baixa é a cara de pena, e é anatomicamente o que o músculo
  /// elevador da sobrancelha interna faz num cão pedindo alguma coisa.
  void _sobrancelhaDoBuldogue(Canvas canvas, double lado) {
    final (dentro, fora) = switch (mood) {
      Mood.radiant => (-3.5, -3.0),
      Mood.content => (-1.5, -1.5),
      Mood.neutral => (0.0, 0.0),
      Mood.sleepy => (1.5, 3.0),
      Mood.missingYou => (-5.5, 2.5),
    };
    // Dormindo ela relaxa junto com o resto da cara, qualquer que seja o
    // humor: a sobrancelha erguida de quem está de olhos fechados lê como
    // bicho fingindo que dorme.
    final sono = acao == AcaoDoBicho.cochilo ? 1.0 : 0.0;
    final a = -10.0 + dentro * (1 - sono) + sono * 1.5;
    final b = -10.0 + fora * (1 - sono) + sono * 3.0;
    canvas.drawPath(
      Path()
        ..moveTo(lado * 18, a)
        ..quadraticBezierTo(lado * 27, math.min(a, b) - 1.6, lado * 36, b),
      _traco(sombraForte.withValues(alpha: 0.6), 2.4),
    );
  }

  /// Uma dobra de pele: sombra embaixo, luz um fio acima.
  ///
  /// O par é o ponto todo. Um traço escuro sozinho lê como arranhão; com a
  /// linha clara logo acima ele vira a aresta de uma prega — a pele de cima
  /// pegando luz, a de baixo na sombra dela. É com esta função que a testa,
  /// o stop, a corda do nariz, a papada e o ombro são desenhados, e é por
  /// isso que a paleta do buldogue precisa de tons escuros: num pelo claro
  /// demais a metade escura da dobra desaparece e sobra só o brilho.
  void _dobraDaPele(Canvas canvas, Path linha, {double forca = 1}) {
    // 1,2 px de afastamento e traços de 1,5/1,8. A primeira versão usava 1,5
    // e 1,9/2,2, o que dava uma faixa de quase 4 px: numa cabeça de 66 px de
    // altura a ruga da testa saía do tamanho de uma sobrancelha e a cara
    // ficava com uma grade entre as orelhas.
    canvas.save();
    canvas.translate(0, -1.2);
    canvas.drawPath(
      linha,
      _traco(luz.withValues(alpha: 0.30 * forca), 1.5),
    );
    canvas.restore();
    canvas.drawPath(
      linha,
      _traco(sombraForte.withValues(alpha: 0.40 * forca), 1.8),
    );
  }

  // ======================================================================
  // ROUPA
  // ======================================================================

  /// Veste o que o usuário colocou.
  ///
  /// Desenhado **dentro do sistema de coordenadas da cabeça** de cada
  /// espécie, e escalado pelo tamanho dela: a mesma peça serve na capivara
  /// larga e na tartaruga pequena sem código por espécie.
  void _veste(Canvas canvas, double larguraDaCabeca, double alturaDaCabeca) {
    if (roupas.isEmpty) return;
    final w = larguraDaCabeca / 2;
    final h = alturaDaCabeca / 2;

    // Pescoço primeiro: fica atrás do queixo.
    final pescoco = roupas[Vestimenta.pescoco];
    if (pescoco != null) _cachecol(canvas, w, h, pescoco);

    final rosto = roupas[Vestimenta.rosto];
    if (rosto != null) _oculos(canvas, w, h, rosto);

    final cabeca = roupas[Vestimenta.cabeca];
    if (cabeca != null) _naCabeca(canvas, w, h, cabeca);
  }

  void _cachecol(Canvas canvas, double w, double h, Color cor) {
    final y = h * 0.94;
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.62, y - h * 0.10)
        ..cubicTo(-w * 0.30, y + h * 0.16, w * 0.30, y + h * 0.16,
            w * 0.62, y - h * 0.10)
        ..cubicTo(w * 0.58, y + h * 0.22, -w * 0.58, y + h * 0.22,
            -w * 0.62, y - h * 0.10)
        ..close(),
      _p(cor),
    );
    // A ponta caindo de um lado.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.30, y + h * 0.06)
        ..lineTo(w * 0.50, y + h * 0.62)
        ..lineTo(w * 0.26, y + h * 0.60)
        ..close(),
      _p(Color.lerp(cor, Cores.tinta, 0.18)!),
    );
  }

  void _oculos(Canvas canvas, double w, double h, Color cor) {
    final r = w * 0.20;
    final y = -h * 0.16;
    final aro = _traco(cor, w * 0.045);
    for (final lado in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(lado * w * 0.30, y), r, aro);
    }
    canvas.drawLine(
      Offset(-w * 0.10, y),
      Offset(w * 0.10, y),
      aro,
    );
    // Hastes indo para trás da cabeça.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(lado * (w * 0.30 + r), y),
        Offset(lado * w * 0.96, y - h * 0.06),
        aro,
      );
    }
  }

  void _naCabeca(Canvas canvas, double w, double h, Color cor) {
    switch (roupaDeCabeca) {
      case 'gorro':
        // Gorro: cobre o topo e tem uma pompom.
        canvas.save();
        canvas.clipPath(
          _bolha(
            Rect.fromCenter(
              center: Offset.zero,
              width: w * 2,
              height: h * 2,
            ),
          ),
        );
        // Para em -0.50h: os olhos ficam por volta de -0.33h da cabeça em
        // todas as espécies, e um gorro que os cobre não é gorro, é venda.
        canvas.drawRect(
          Rect.fromLTRB(-w, -h, w, -h * 0.50),
          _p(cor),
        );
        canvas.restore();
        // Barra e pompom saem por fora do recorte.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-w * 0.94, -h * 0.64, w * 0.94, -h * 0.46),
            Radius.circular(h * 0.09),
          ),
          _p(Color.lerp(cor, Cores.superficie, 0.30)!),
        );
        canvas.drawCircle(
          Offset(0, -h * 1.08),
          w * 0.13,
          _p(Color.lerp(cor, Cores.superficie, 0.30)!),
        );

      case 'coroa_folhas':
        // Coroa: folhinhas em volta do topo.
        for (var i = -2; i <= 2; i++) {
          final a = i * 0.34;
          canvas.save();
          canvas.translate(math.sin(a) * w * 0.72, -math.cos(a) * h * 0.82);
          canvas.rotate(a);
          canvas.drawPath(
            _bolha(
              Rect.fromCenter(
                center: Offset.zero,
                width: w * 0.20,
                height: h * 0.34,
              ),
            ),
            _p(i.isEven ? cor : Color.lerp(cor, Cores.superficie, 0.24)!),
          );
          canvas.restore();
        }

      default:
        // Chapéu de palha: aba larga e copa baixa. É o padrão.
        // Aba em -0.74h: mais baixa que isso e ela passa na frente dos
        // olhos, que ficam por volta de -0.33h.
        canvas.drawPath(
          _bolha(
            Rect.fromCenter(
              center: Offset(0, -h * 0.92),
              width: w * 1.02,
              height: h * 0.56,
            ),
            base: 0.4,
          ),
          _p(cor),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -h * 0.76),
            width: w * 2.04,
            height: h * 0.34,
          ),
          _p(Color.lerp(cor, Cores.superficie, 0.16)!),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, -h * 0.88),
              width: w * 1.04,
              height: h * 0.14,
            ),
            Radius.circular(h * 0.07),
          ),
          _p(Color.lerp(cor, Cores.tinta, 0.30)!),
        );
    }
  }

  // ======================================================================
  // PARTES COMPARTILHADAS
  // ======================================================================

  /// Pata com dedinhos, não um retângulo.
  ///
  /// [rema] diz de que lado do corpo esta pata está (-1 ou 1). Na água ela
  /// deixa de andar para a frente e para trás e passa a **descrever uma
  /// elipse** — puxa embaixo, volta em cima —, meio ciclo defasada da outra.
  /// Em fase as duas subiam juntas e o bicho parecia pular, não nadar.
  void _pata(
    Canvas canvas,
    Offset o,
    double w,
    double h,
    Color cor,
    double desloca, {
    bool dedos = true,
    double? rema,
  }) {
    var pos = Offset(o.dx + desloca, o.dy);
    if (rema != null && pose.nadando) {
      final a = (pose.ciclo + (rema < 0 ? 0.0 : 0.5)) * math.pi * 2;
      // O -9 recolhe a pata para debaixo do peito. Bicho nadando não deixa a
      // perna esticada onde ela fica de pé: ela puxa embaixo do corpo. E era
      // o que a fazia sair pela borda de baixo do quadro, já que o corpo
      // inteiro afundou.
      pos = o +
          Offset(
            math.cos(a) * 7 * pose.amplitude,
            math.sin(a) * 9 * pose.amplitude - 9,
          );
    }
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        base: 0.82,
      ),
      _p(cor),
    );
    if (dedos) {
      final dedo = _traco(Color.lerp(cor, Cores.tinta, 0.35)!, 1.4);
      for (final dx in [-w * 0.22, 0.0, w * 0.22]) {
        canvas.drawLine(Offset(dx, h * 0.16), Offset(dx, h * 0.38), dedo);
      }
    }
    canvas.restore();
  }

  void _patinha(Canvas canvas, Offset o, Color cor, {double? rema}) =>
      _pata(canvas, o, 16, 13, cor, 0, rema: rema);

  /// Orelha com concha interna, e um tremor rápido quando o bicho escuta algo.
  void _orelhaRedonda(
    Canvas canvas,
    Offset o,
    double w,
    double h,
    double giroBase,
  ) {
    final treme = math.sin(pose.orelha * math.pi * 2) * 0.24 * pose.amplitude;
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(giroBase + treme);
    _oval(canvas, Rect.fromCenter(center: Offset.zero, width: w, height: h), sombra);
    _oval(
      canvas,
      Rect.fromCenter(center: Offset.zero, width: w * 0.52, height: h * 0.52),
      Color.lerp(sombraForte, Cores.acento, 0.28)!,
    );
    canvas.restore();
  }

  /// Olho: esclera, íris, pupila e dois brilhos.
  ///
  /// A piscada comprime verticalmente e fecha com a pálpebra — bem diferente
  /// de trocar o desenho por um traço.
  ///
  /// [sobrancelha] desliga o risco de tristeza que este método desenha por
  /// conta própria. Existe por causa do buldogue: ele tem par de
  /// sobrancelhas desenhado à parte, que muda de ângulo nos cinco humores, e
  /// as duas coisas empilhadas viravam quatro traços em cima de dois olhos.
  void _olho(
    Canvas canvas,
    Offset o,
    double r, {
    bool coruja = false,
    bool sobrancelha = true,
  }) {
    final f = fechamento;

    if (f > 0.94) {
      // Fechado: um arco de pálpebra, virado para cima quando feliz.
      canvas.drawArc(
        Rect.fromCircle(center: o, radius: r * 0.95),
        feliz ? math.pi + 0.3 : 0.28,
        math.pi - (feliz ? 0.6 : 0.56),
        false,
        _traco(Cores.tinta, 2.2),
      );
      return;
    }

    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.scale(1, (1 - f).clamp(0.06, 1.0));
    canvas.translate(-o.dx, -o.dy);

    canvas.drawCircle(o, r, _p(coruja ? Colors.white : Cores.superficie));

    final desvio = _olhoDesvio + (triste ? const Offset(0.6, 1.4) : Offset.zero);
    final iris = o + desvio;
    if (coruja) {
      canvas.drawCircle(
        iris,
        r * 0.62,
        _p(Color.lerp(Cores.acentoForte, Cores.tinta, 0.35)!),
      );
    }
    canvas.drawCircle(
      iris,
      r * (coruja ? 0.34 : (feliz ? 0.56 : 0.50)),
      _p(Cores.tinta),
    );

    canvas.drawCircle(
      iris + Offset(-r * 0.30, -r * 0.32),
      r * 0.20,
      _p(Colors.white),
    );
    canvas.drawCircle(
      iris + Offset(r * 0.20, r * 0.16),
      r * 0.10,
      _p(Colors.white70),
    );

    // Pálpebra caída quando neutro ou triste.
    if (mood == Mood.neutral || triste) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx - r * 1.05, o.dy - r * (triste ? 0.35 : 0.15))
          ..lineTo(o.dx + r * 1.05, o.dy - r * (triste ? 0.75 : 0.55))
          ..lineTo(o.dx + r * 1.05, o.dy - r * 1.35)
          ..lineTo(o.dx - r * 1.05, o.dy - r * 1.35)
          ..close(),
        _p(pelo),
      );
    }

    if (triste && sobrancelha) {
      canvas.drawLine(
        o + Offset(-r * 0.9, -r * 1.5),
        o + Offset(r * 0.5, -r * 1.1),
        _traco(sombraForte, 1.8),
      );
    }

    canvas.restore();

    // A pálpebra que fecha, por cima e sem a escala vertical.
    if (f > 0.45) {
      canvas.drawLine(
        o + Offset(-r * 0.95, 0),
        o + Offset(r * 0.95, 0),
        _traco(Cores.tinta, 2),
      );
    }
  }

  void _narina(Canvas canvas, Offset o) {
    canvas.drawOval(
      Rect.fromCenter(center: o, width: 7.5, height: 5),
      _p(sombraForte),
    );
    canvas.drawOval(
      Rect.fromCenter(center: o + const Offset(-0.7, -0.9), width: 3, height: 2),
      _p(luz.withValues(alpha: 0.5)),
    );
  }

  /// Boca que muda com o humor — e abre quando fazem carinho ou ele mastiga.
  ///
  /// A mastigada vem do laço da atividade, não mais de `pose.boia > 0`. Com
  /// a boia, a boca ficava metade do tempo aberta e metade fechada num
  /// período de quase cinco segundos: parecia um bicho de queixo caído, não
  /// um bicho comendo.
  /// [cor] troca a tinta do traço. Existe por causa do buldogue: a boca dele
  /// cai sobre a focinheira e, nas pelagens escuras, `sombraForte` sobre pelo
  /// já escuro somem uma na outra — sobravam dois dentinhos brancos flutuando
  /// sem boca nenhuma em volta. Nas outras oito o padrão continua valendo.
  void _boca(Canvas canvas, Offset o, double w, {Color? cor}) {
    final t = _traco(cor ?? sombraForte, 1.9);
    final mastigando = pose.mastiga > 0.30;
    final aberta = pose.bocejo > 0.3 || pose.carinho > 0.4 || mastigando;

    _naBoca(canvas, o, w);

    if (aberta) {
      final r = Rect.fromCenter(
        center: o + const Offset(0, 2),
        width: w * 0.8,
        height: 9,
      );
      canvas.drawArc(
        r,
        0,
        math.pi,
        true,
        _p(Color.lerp(Cores.acento, Cores.tinta, 0.4)!),
      );
      canvas.drawArc(r, 0, math.pi, false, t);
      return;
    }

    switch (mood) {
      case Mood.radiant:
        canvas.drawArc(
          Rect.fromCenter(center: o, width: w, height: w * 0.72),
          0.18,
          math.pi - 0.36,
          false,
          t,
        );
      case Mood.content:
        canvas.drawArc(
          Rect.fromCenter(center: o, width: w * 0.8, height: w * 0.5),
          0.3,
          math.pi - 0.6,
          false,
          t,
        );
      case Mood.neutral:
        canvas.drawLine(o + Offset(-w * 0.3, 0), o + Offset(w * 0.3, 0), t);
      case Mood.sleepy:
        canvas.drawArc(
          Rect.fromCenter(center: o + const Offset(0, 2), width: w * 0.5, height: 6),
          0.2,
          math.pi - 0.4,
          false,
          t,
        );
      case Mood.missingYou:
        canvas.drawArc(
          Rect.fromCenter(center: o + const Offset(0, 6), width: w * 0.8, height: w * 0.5),
          math.pi + 0.3,
          math.pi - 0.6,
          false,
          t,
        );
    }
  }

  /// O que ele está comendo, saindo do canto da boca.
  ///
  /// Um talo verde é o que separa "abriu a boca" de "está comendo". Fica
  /// numa função própria porque as duas espécies de bico (coruja e pinguim)
  /// não passam por [_boca] — elas desenham o bico à mão — e mesmo assim
  /// petiscam.
  void _naBoca(Canvas canvas, Offset o, double w) {
    if (pose.mastiga <= 0.05) return;
    canvas.save();
    canvas.translate(o.dx + w * 0.34, o.dy - 1);
    canvas.rotate(-0.5 + pose.mastiga * 0.24);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(5, -4.5, 12, -3)
        ..quadraticBezierTo(6, 1.5, 0, 0)
        ..close(),
      _p(Cores.primariaClara),
    );
    canvas.restore();
  }

  void _bochecha(Canvas canvas, Offset a, Offset b) {
    final cor = Cores.acento.withValues(alpha: 0.24 + pose.carinho * 0.20);
    for (final o in [a, b]) {
      canvas.drawOval(Rect.fromCenter(center: o, width: 14, height: 8), _p(cor));
    }
  }

  /// Bigodes. [lado] -1 aponta para a esquerda, 1 para a direita — de frente
  /// o bicho tem os dois.
  void _bigodes(Canvas canvas, Offset o, {double lado = -1}) {
    final t = _traco(sombraForte.withValues(alpha: 0.5), 1.2);
    // Os bigodes acompanham a respiração de leve.
    final abre = pose.respiro * pose.amplitude * 1.1;
    for (var i = 0; i < 3; i++) {
      final dy = (i - 1) * 3.5;
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy + dy)
          ..cubicTo(
            o.dx + lado * 7, o.dy + dy - 1 - abre,
            o.dx + lado * 13, o.dy + dy - 2 - abre * 1.3,
            o.dx + lado * 19, o.dy + dy - 3 - abre * 1.5,
          ),
        t,
      );
    }
  }

  // --- efeitos de cena ----------------------------------------------------

  /// O tom que a água põe sobre o que está submerso.
  ///
  /// Verde de igarapé, não azul de piscina: é a cor da água do habitat
  /// (`0xFFC9DCC0` na superfície, `0xFFAECBA3` no fundo), escurecida. Azul
  /// aqui brigaria com a cena inteira.
  static const _tomDaAgua = Color(0x704E7A63);

  /// O rastro: o que a água faz **por causa** do bicho.
  ///
  /// Três coisas, e nenhuma é decorativa. Os anéis dizem que ele se move; as
  /// gotas, que ele bate na água; as bolhas, que há corpo embaixo. Sem elas
  /// o corpo submerso vira uma mancha e o nado some.
  void _rastro(Canvas canvas, Size size, double y) {
    final amp = pose.amplitude;
    final cx = size.width / 2;
    final c = Offset(cx, y + 6);

    // --- anéis abrindo, cada um numa fase ---------------------------------
    // Presos ao laço da braçada, não à boia: é a remada que empurra a água.
    const aneis = [(150.0, 19.0, 0.20), (112.0, 14.0, 0.15), (76.0, 10.0, 0.12)];
    for (var i = 0; i < aneis.length; i++) {
      final (w, h, a) = aneis[i];
      final fase = (pose.ciclo + i * 0.33) % 1.0;
      final cresce = 1 + fase * 0.30 * amp;
      final some = (1 - fase * 0.75).clamp(0.10, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * cresce, height: h * cresce),
        _traco(Cores.superficie.withValues(alpha: a * some), 2.4),
      );
    }

    // --- gotas: uma salva por braçada, do lado que puxou -------------------
    final lado = pose.ciclo < 0.5 ? -1.0 : 1.0;
    final f = (pose.ciclo % 0.5) / 0.5;
    final vida = math.sin(f * math.pi);
    if (vida > 0.05 && amp > 0.3) {
      for (var i = 0; i < 3; i++) {
        final espalha = (i - 1) * 6.0;
        final alto = vida * (11 + i * 3) * amp;
        canvas.drawCircle(
          Offset(cx + lado * (30 + i * 5) + espalha * lado, y - alto),
          1.7 + i * 0.4,
          _p(Cores.superficie.withValues(alpha: vida * 0.7)),
        );
      }
    }

    // --- bolhas subindo do corpo submerso ---------------------------------
    for (var i = 0; i < 3; i++) {
      final b = (pose.ciclo * 0.6 + i * 0.37) % 1.0;
      final r = 1.4 + i * 0.7;
      canvas.drawCircle(
        Offset(cx + math.sin(b * math.pi * 2 + i) * (14 + i * 7),
            size.height - 6 - b * (size.height - 6 - y)),
        r,
        _p(Cores.superficie.withValues(alpha: (1 - b) * 0.30)),
      );
    }
  }

  /// A lâmina d'água por cima do corpo — o menisco.
  ///
  /// Só na largura do bicho, e apagando nas pontas. Uma linha atravessando o
  /// quadro inteiro competiria com a lâmina do habitat, que fica a poucos
  /// pixels dali e muda de altura com o cenário; limitada ao corpo, ela lê
  /// como a água encostando **nele**, que é o que precisa ser dito.
  void _lamina(Canvas canvas, Size size, double y) {
    final amp = pose.amplitude;
    final cx = size.width / 2;
    final r = Rect.fromCenter(center: Offset(cx, y), width: 178, height: 10);
    final onda = Path();
    for (var x = r.left; x <= r.right; x += 5) {
      final yy = y +
          math.sin((x - cx) / 21 + pose.ciclo * math.pi * 2) * 2.1 * amp;
      if (x == r.left) {
        onda.moveTo(x, yy);
      } else {
        onda.lineTo(x, yy);
      }
    }
    canvas.drawPath(
      onda,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..shader = const LinearGradient(
          colors: [
            Color(0x00FAF1E3),
            Color(0xCCFAF1E3),
            Color(0xCCFAF1E3),
            Color(0x00FAF1E3),
          ],
          stops: [0, 0.24, 0.76, 1],
        ).createShader(r),
    );
  }

  /// Zzz subindo, cada letra numa fase.
  ///
  /// Preso ao laço do sono, que é longo: no ritmo da boia as letras subiam
  /// depressa demais para quem está dormindo.
  void _zzz(Canvas canvas, Size size) {
    final base = Offset(size.width * 0.70, size.height * 0.30);
    for (var i = 0; i < 3; i++) {
      final f = (pose.ciclo * 3 + i * 0.33) % 1.0;
      final opacidade = (1 - f) * 0.55;
      if (opacidade <= 0.02) continue;
      _letraZ(
        canvas,
        base + Offset(i * 9.0 + f * 5, -f * 22 * pose.amplitude - i * 6.0),
        5.0 + i * 2.0,
        Cores.tintaA(opacidade),
      );
    }
  }

  /// A folha que desceu e pousou nele.
  ///
  /// O Zzz sozinho é o clichê — e é o que já existia. A folha vem do
  /// vocabulário do próprio app: a moeda do Baru é folha, o habitat é
  /// vegetal, e o §10 do roteiro proíbe "poção" exatamente para nada sair da
  /// natureza. Inventar um símbolo novo (uma lua, uma estrela) seria trazer
  /// para dentro algo que o app não tem.
  ///
  /// O detalhe que faz a coisa funcionar não é a queda: é o que acontece
  /// depois. Pousada, ela **sobe e desce com a respiração dele**. É isso que
  /// lê como "dormindo" em vez de "parado de olhos fechados".
  void _folhaDoSono(Canvas canvas, Size size) {
    final amp = pose.amplitude;
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    // Pousa no flanco, e não em cima da cabeça: a 8 px do centro ela caía
    // no focinho de quase toda espécie, o que lê como folha grudada na
    // cara. É também a posição da fase zero, para quem desligou o movimento
    // ver a folha **em cima dele**, e não parada no ar.
    final pouso = Offset(cx - 26, cy + 26);

    // A queda ocupa a última parte do laço; o resto do tempo ela descansa.
    const comeca = 0.62;
    final caindo = pose.ciclo > comeca && amp > 0.3;
    final Offset onde;
    final double giro;
    if (caindo) {
      final t = (pose.ciclo - comeca) / (1 - comeca);
      final partida = Offset(cx + 40, cy - 78);
      onde = Offset(
        // Bamboleia na descida: folha que cai reta é pedra.
        partida.dx + (pouso.dx - partida.dx) * t + math.sin(t * math.pi * 3) * 9,
        partida.dy + (pouso.dy - partida.dy) * Curves.easeIn.transform(t),
      );
      giro = t * math.pi * 1.6;
    } else {
      onde = pouso + Offset(0, pose.respiro * amp * 1.6);
      giro = -0.5;
    }

    canvas.save();
    canvas.translate(onde.dx, onde.dy);
    canvas.rotate(giro);
    final corpo = Path()
      ..moveTo(-9, 0)
      ..quadraticBezierTo(0, -7, 9, 0)
      ..quadraticBezierTo(0, 7, -9, 0)
      ..close();
    canvas.drawPath(corpo, _p(Cores.primariaClara.withValues(alpha: 0.9)));
    canvas.drawLine(
      const Offset(-8, 0),
      const Offset(8, 0),
      _traco(Cores.primariaEscura.withValues(alpha: 0.55), 1.1),
    );
    canvas.restore();
  }

  void _letraZ(Canvas canvas, Offset o, double s, Color cor) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + s, o.dy)
        ..lineTo(o.dx, o.dy + s)
        ..lineTo(o.dx + s, o.dy + s),
      _traco(cor, 1.8),
    );
  }

  /// Faíscas de alegria: quatro estrelinhas pulsando fora de fase.
  void _brilhos(Canvas canvas, Size size) {
    final fase01 = (pose.respiro + 1) / 2;
    final pontos = [
      (Offset(size.width * 0.26, size.height * 0.22), 5.0, 0.0),
      (Offset(size.width * 0.74, size.height * 0.18), 4.0, 0.35),
      (Offset(size.width * 0.84, size.height * 0.42), 3.2, 0.70),
      (Offset(size.width * 0.17, size.height * 0.44), 3.0, 0.50),
    ];
    for (final (o, s, atraso) in pontos) {
      final f = (fase01 + atraso) % 1.0;
      final pulso = 0.5 + math.sin(f * math.pi * 2) * 0.5;
      final forca = (0.35 + pulso * 0.45 + pose.carinho * 0.3).clamp(0.0, 1.0);
      _estrela(
        canvas,
        o,
        s * (0.7 + pulso * 0.5),
        Cores.acento.withValues(alpha: forca),
      );
    }
  }

  void _estrela(Canvas canvas, Offset o, double s, Color cor) {
    const k = 0.22;
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - s)
        ..cubicTo(o.dx + s * k, o.dy - s * k, o.dx + s * k, o.dy - s * k, o.dx + s, o.dy)
        ..cubicTo(o.dx + s * k, o.dy + s * k, o.dx + s * k, o.dy + s * k, o.dx, o.dy + s)
        ..cubicTo(o.dx - s * k, o.dy + s * k, o.dx - s * k, o.dy + s * k, o.dx - s, o.dy)
        ..cubicTo(o.dx - s * k, o.dy - s * k, o.dx - s * k, o.dy - s * k, o.dx, o.dy - s)
        ..close(),
      _p(cor),
    );
  }

  /// Uma lágrima que desce devagar e some.
  void _pingo(Canvas canvas, Size size) {
    final fase = (pose.boia + 1) / 2;
    final o = Offset(size.width * 0.30, size.height * 0.46 + fase * 16);
    final a = (1 - fase) * 0.55;
    if (a <= 0.02) return;
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - 5)
        ..cubicTo(o.dx + 4, o.dy + 1, o.dx + 3, o.dy + 6, o.dx, o.dy + 6)
        ..cubicTo(o.dx - 3, o.dy + 6, o.dx - 4, o.dy + 1, o.dx, o.dy - 5)
        ..close(),
      _p(const Color(0xFF7FA9C9).withValues(alpha: a)),
    );
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) {
    return old.species != species ||
        old.mood != mood ||
        old.activity != activity ||
        old.pose.acao != pose.acao ||
        old.pose.ciclo != pose.ciclo ||
        old.coat != coat ||
        old.coatIndex != coatIndex ||
        old.pose.respiro != pose.respiro ||
        old.pose.boia != pose.boia ||
        old.pose.cauda != pose.cauda ||
        old.pose.pisca != pose.pisca ||
        old.pose.orelha != pose.orelha ||
        old.pose.toque != pose.toque ||
        old.pose.olhar != pose.olhar ||
        old.pose.animado != pose.animado ||
        old.pose.gesto != pose.gesto ||
        old.pose.gestoT != pose.gestoT ||
        old.roupas.length != roupas.length ||
        old.roupaDeCabeca != roupaDeCabeca ||
        old.pose.dedo != pose.dedo ||
        old.pose.gosto != pose.gosto ||
        old.pose.amplitude != pose.amplitude;
  }
}
