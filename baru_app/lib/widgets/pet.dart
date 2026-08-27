
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
/// Com "reduzir movimento" ligado o contínuo para e a pose fica neutra, mas o
/// toque continua respondendo, com amplitude menor.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../services/som_service.dart';
import '../theme.dart';

/// Um gesto de ocioso: o que o bicho faz quando ninguém está pedindo nada.
///
/// Sem isso o repouso é só a respiração em laço, e laço curto o olho pega em
/// segundos — passa a impressão de sprite, não de bicho.
enum GestoOcioso { nenhum, espreguica, sacode, olhaEmVolta }

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

class _PetViewState extends State<PetView> with TickerProviderStateMixin {
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimento.reduzido(context)) {
      _paraContinuo();
    } else {
      _iniciaContinuo();
    }
  }

  void _iniciaContinuo() {
    if (_continuoLigado) return;
    _continuoLigado = true;
    _respiro.repeat(reverse: true);
    _flutua.repeat(reverse: true);
    _cauda.repeat(reverse: true);
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

  /// Um gesto a cada 7–15 s, sorteado, e só quando ele está à toa.
  ///
  /// Nadando, pastando ou dormindo o corpo já tem o que fazer; empilhar um
  /// gesto por cima vira ruído.
  void _agendaGesto() {
    _proximoGesto?.cancel();
    final espera = Duration(milliseconds: 7000 + _sorte.nextInt(8000));
    _proximoGesto = Timer(espera, () async {
      if (!mounted || !_continuoLigado) return;
      if (widget.activity != Activity.idle || _toque.isAnimating) {
        _agendaGesto();
        return;
      }
      const repertorio = [
        GestoOcioso.espreguica,
        GestoOcioso.sacode,
        GestoOcioso.olhaEmVolta,
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
    _proximoPiscar?.cancel();
    _proximaOrelha?.cancel();
    _proximoGesto?.cancel();
    _voltaAOlharPraFrente?.cancel();
    _esfriaToques?.cancel();
    _respiro.dispose();
    _flutua.dispose();
    _cauda.dispose();
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
              roupas: widget.roupas,
              roupaDeCabeca: widget.roupaDeCabeca,
              pose: _Pose(
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
    return GestureDetector(
      onTapDown: _reageAoToque,
      onPanStart: _comecaAfago,
      onPanUpdate: _afaga,
      onPanEnd: (_) => _terminaAfago(),
      onPanCancel: _terminaAfago,
      behavior: HitTestBehavior.opaque,
      child: corpo,
    );
  }
}

/// Os valores animados de um quadro. O painter não sabe de controllers.
class _Pose {
  const _Pose({
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
}

class _PetPainter extends CustomPainter {
  _PetPainter({
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
    required this.pose,
    this.roupas = const {},
    this.roupaDeCabeca,
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final Color coat;
  final _Pose pose;

  /// A cor da peça em cada lugar do corpo. Vazio: o bicho está pelado.
  final Map<Vestimenta, Color> roupas;

  /// Qual peça de cabeça — chapéu, gorro ou coroa mudam o desenho.
  final String? roupaDeCabeca;

  // --- estado derivado ----------------------------------------------------

  bool get dormindo => activity == Activity.nap || mood == Mood.sleepy;
  bool get triste => mood == Mood.missingYou;
  bool get feliz =>
      mood == Mood.radiant || pose.carinho > 0.35 || pose.gosto > 0.25;
  bool get nadando => activity == Activity.swim;
  bool get pastando => activity == Activity.graze;

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

    // Cada atividade tem o seu jeito de ocupar o espaço.
    final balanco = switch (activity) {
      Activity.swim => boia * 3.6,
      Activity.nap => sopro * 1.8,
      Activity.graze => boia * 1.6,
      Activity.idle => boia * 1.2,
    };

    if (nadando) _ondas(canvas, size);

    canvas.save();
    canvas.translate(
      cx,
      cy + balanco + pose.quique * 7 * pose.amplitudeToque - pose.estica * 4,
    );

    final giro = switch (activity) {
      Activity.nap => -0.16,
      Activity.swim => -0.05 + boia * 0.012,
      Activity.graze => 0.06 + boia * 0.05 * amp,
      Activity.idle => triste ? 0.02 : boia * 0.012,
    };
    canvas.rotate(giro);

    // Respiração como squash/stretch, mais o quique do toque e o alongamento
    // do espreguiçar.
    final q = pose.quique * pose.amplitudeToque;
    final e = pose.estica;
    canvas.scale(
      1 + sopro * 0.018 + q * 0.07 + e * 0.07,
      1 - sopro * 0.014 - q * 0.07 + e * 0.03,
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
    }
    canvas.restore();

    if (dormindo) _zzz(canvas, size);
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
  Offset get _olhoDesvio => Offset(
        pose.olhar.dx * 1.8 * pose.amplitudeToque,
        pose.olhar.dy * 1.3 * pose.amplitudeToque,
      );

  /// A cabeça acompanha um pouco o olhar, e balança ao pastar.
  double get _cabecaGiro =>
      pose.sacudida +
      // Encosta a cabeça na mão.
      (pose.dedo == null ? 0 : pose.gosto * 0.06 * pose.amplitudeToque) +
      pose.olhar.dx * 0.05 * pose.amplitudeToque +
      (pastando ? pose.boia * 0.05 * pose.amplitude : 0);

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
    final passo = pose.boia * amp;

    // Patas da frente, apoiadas. Sobem e descem alternadas ao boiar.
    _pata(canvas, const Offset(-23, 51), 27, 17, sombra, passo * 1.6);
    _pata(canvas, const Offset(23, 51), 27, 17, sombra, -passo * 1.6);

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
    canvas.translate(0, -30 + pose.respiro * amp * 0.7);
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
    final rema = pose.boia * amp;
    final balanca = pose.cauda * amp;

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

    _patinha(canvas, Offset(-20, 50 + rema * 1.6), sombra);
    _patinha(canvas, Offset(20, 50 - rema * 1.6), sombra);

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
    canvas.translate(0, -28 + pose.respiro * amp * 0.7);
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
    final estica = (pose.boia * 2.4 * amp) + pose.carinho * 7;

    // Patas: saem por baixo do casco, nos cantos.
    _pata(canvas, const Offset(-47, 52), 25, 22, sombra, pose.boia * amp * 1.4);
    _pata(canvas, const Offset(47, 52), 25, 22, sombra, -pose.boia * amp * 1.4);

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
    canvas.translate(0, -36 - estica);
    canvas.rotate(_cabecaGiro * 0.8);

    // Pescoço: sai da cabeça e entra no casco. É ele que faz a cabeça
    // **sair** do casco em vez de ficar apoiada nele como um chapéu.
    canvas.drawPath(
      Path()
        ..moveTo(-17, 12)
        ..cubicTo(-19, 34, 19, 34, 17, 12)
        ..cubicTo(9, 20, -9, 20, -17, 12)
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
    final asa = pose.respiro * amp;

    // Pés pousados: um tarso curto e três dedos abertos. O galho não existe
    // na cena, então o pé precisa parecer apoiado sozinho.
    final garra = _traco(Cores.acento, 5)..strokeJoin = StrokeJoin.round;
    for (final x in [-19.0, 19.0]) {
      canvas.drawLine(Offset(x, 42), Offset(x, 52), garra);
      for (final dedo in [-1.0, 0.0, 1.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 52)
            ..cubicTo(
              x + dedo * 7,
              55,
              x + dedo * 10,
              57,
              x + dedo * 11,
              59,
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

    // Asas dobradas, encostadas no corpo — abrem de leve ao respirar.
    // Mais escuras e mais largas que antes: encostadas no corpo com a mesma
    // cor, elas sumiam.
    for (final lado in [-1.0, 1.0]) {
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
    canvas.translate(0, -28 + pose.respiro * amp * 0.6);
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
        ..lineTo(0, 22)
        ..close(),
      _p(Cores.acento),
    );

    if (feliz) _bochecha(canvas, const Offset(-34, 17), const Offset(34, 17));
    _veste(canvas, 86, 70);
    canvas.restore();
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
  void _pata(
    Canvas canvas,
    Offset o,
    double w,
    double h,
    Color cor,
    double desloca, {
    bool dedos = true,
  }) {
    canvas.save();
    canvas.translate(o.dx + desloca, o.dy);
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

  void _patinha(Canvas canvas, Offset o, Color cor) =>
      _pata(canvas, o, 16, 13, cor, 0);

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
  void _olho(Canvas canvas, Offset o, double r, {bool coruja = false}) {
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

    if (triste) {
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
  void _boca(Canvas canvas, Offset o, double w) {
    final t = _traco(sombraForte, 1.9);
    final aberta =
        pose.bocejo > 0.3 || pose.carinho > 0.4 || (pastando && pose.boia > 0);

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

  /// Ondas que abrem a partir do bicho, cada anel numa fase diferente.
  void _ondas(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 14);
    const aneis = [(132.0, 17.0, 0.22), (98.0, 12.0, 0.15), (66.0, 8.0, 0.11)];
    final fase01 = (pose.boia + 1) / 2;
    for (var i = 0; i < aneis.length; i++) {
      final (w, h, a) = aneis[i];
      final fase = (fase01 + i * 0.33) % 1.0;
      final cresce = 1 + fase * 0.18 * pose.amplitude;
      final some = (1 - fase * 0.55).clamp(0.25, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * cresce, height: h * cresce),
        _traco(Cores.primaria.withValues(alpha: a * some), 2.5),
      );
    }
  }

  /// Zzz subindo, cada letra numa fase.
  void _zzz(Canvas canvas, Size size) {
    final base = Offset(size.width * 0.70, size.height * 0.30);
    final fase01 = (pose.boia + 1) / 2;
    for (var i = 0; i < 3; i++) {
      final f = (fase01 + i * 0.33) % 1.0;
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
        old.coat != coat ||
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
