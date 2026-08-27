
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
        ]),
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _PetPainter(
              species: widget.species,
              mood: widget.mood,
              activity: widget.activity,
              coat: AppColors
                  .coat[widget.coat.clamp(0, AppColors.coat.length - 1)],
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
  });

  final Species species;
  final Mood mood;
  final Activity activity;
  final Color coat;
  final _Pose pose;

  // --- estado derivado ----------------------------------------------------

  bool get dormindo => activity == Activity.nap || mood == Mood.sleepy;
  bool get triste => mood == Mood.missingYou;
  bool get feliz => mood == Mood.radiant || pose.carinho > 0.35;
  bool get nadando => activity == Activity.swim;
  bool get pastando => activity == Activity.graze;

  /// Olho fechado por sono, por piscada ou por bocejo.
  double get fechamento => dormindo
      ? 1.0
      : math.max(pose.pisca, pose.bocejo).clamp(0.0, 1.0);

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
      pose.olhar.dx * 0.05 * pose.amplitudeToque +
      (pastando ? pose.boia * 0.05 * pose.amplitude : 0);

  // ======================================================================
  // CAPIVARA — corpo de barril, focinho reto, orelhas pequenas
  // ======================================================================

  void _capivara(Canvas canvas) {
    final amp = pose.amplitude;
    final passo = pose.boia * amp;

    // Patas de trás, atrás do corpo. Escuras, senão somem na barriga.
    _pata(canvas, const Offset(38, 28), 15, 18, sombraForte, passo * 2.2,
        dedos: false);
    _pata(canvas, const Offset(16, 30), 15, 18, sombraForte, -passo * 2.2,
        dedos: false);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(12, 2), width: 118, height: 68),
      topo: 0.92,
      base: 1.04,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    // Barriga: uma faixa baixa, não a metade do bicho.
    _oval(
      canvas,
      Rect.fromCenter(center: const Offset(18, 30), width: 78, height: 30),
      barriga,
    );
    // Luz no lombo, discreta: contraste forte aqui vira linha dura.
    _oval(
      canvas,
      Rect.fromCenter(center: const Offset(2, -30), width: 80, height: 22),
      luz.withValues(alpha: 0.16),
    );
    canvas.restore();

    // Patas da frente, na frente do corpo.
    _pata(canvas, const Offset(-24, 28), 15, 19, sombra, -passo * 2.4);
    _pata(canvas, const Offset(-2, 30), 15, 19, sombraForte, passo * 2.4);

    // Pescoço: sem esta massa a cabeça lia como uma bola solta encostada.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(-34, -4), width: 46, height: 52),
      ),
      _p(pelo),
    );

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(-56, -12 + pose.respiro * amp * 0.9);
    canvas.rotate(_cabecaGiro - (pastando ? 0.18 : 0) + (triste ? 0.10 : 0));

    // Orelhas antes da cabeça: ficam encaixadas, não flutuando.
    _orelhaRedonda(canvas, const Offset(-8, -26), 15, 16, -0.30);
    _orelhaRedonda(canvas, const Offset(15, -29), 15, 16, 0.22);

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: 68, height: 60),
        topo: 0.96,
      ),
      _p(pelo),
    );

    // Focinho: baixo e achatado. A capivara tem a frente do rosto reta, e um
    // focinho redondo grande faria dela um urso.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(-22, 16), width: 34, height: 20),
        esq: 0.76,
        base: 0.86,
      ),
      _p(claro),
    );

    _narina(canvas, const Offset(-31, 12));
    _boca(canvas, const Offset(-24, 21), 11);
    if (feliz) _bochecha(canvas, const Offset(-12, 15), const Offset(20, 12));

    _olho(canvas, const Offset(-10, -7), 5.6);
    _olho(canvas, const Offset(16, -9), 5.6);

    canvas.restore();
  }

  // ======================================================================
  // LONTRA — corpo comprido e liso, cauda grossa que afina
  // ======================================================================

  void _lontra(Canvas canvas) {
    final amp = pose.amplitude;
    final rabo = pose.cauda * amp;

    // Cauda: uma faixa que sai do corpo e afina, curvando com a animação.
    canvas.drawPath(
      Path()
        ..moveTo(50, -10)
        ..cubicTo(82, -14 + rabo * 5, 100, 6 + rabo * 14, 94, 30 + rabo * 18)
        ..cubicTo(90, 16 + rabo * 12, 76, 10 + rabo * 5, 50, 14)
        ..close(),
      _p(sombra),
    );

    _patinha(canvas, Offset(30, 26 + rabo * 1.5), sombraForte);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(6, 2), width: 124, height: 54),
      topo: 0.9,
      dir: 0.84,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    _oval(
      canvas,
      Rect.fromCenter(center: const Offset(2, 18), width: 104, height: 32),
      barriga,
    );
    _oval(
      canvas,
      Rect.fromCenter(center: const Offset(-4, -18), width: 92, height: 20),
      luz.withValues(alpha: 0.30),
    );
    canvas.restore();

    // Patas da frente remam quando ela nada.
    final remada = nadando ? math.sin(pose.boia * math.pi) * 4.5 * amp : 0.0;
    _patinha(canvas, Offset(-24, 23 + remada), claro);
    _patinha(canvas, Offset(-6, 26 - remada), pelo);

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(-52, -14 + pose.respiro * amp * 0.9);
    canvas.rotate(_cabecaGiro + (nadando ? -0.12 : 0));

    _orelhaRedonda(canvas, const Offset(-4, -18), 9, 9, -0.22);
    _orelhaRedonda(canvas, const Offset(16, -19), 9, 9, 0.22);

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: 48, height: 44),
        base: 1.05,
      ),
      _p(pelo),
    );

    // Focinho largo e achatado, a marca da lontra.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(-12, 11), width: 34, height: 24),
        base: 0.86,
      ),
      _p(barriga),
    );

    _narina(canvas, const Offset(-22, 6));
    _boca(canvas, const Offset(-16, 16), 12);
    _bigodes(canvas, const Offset(-24, 10));
    if (feliz) _bochecha(canvas, const Offset(-5, 12), const Offset(16, 10));

    _olho(canvas, const Offset(-5, -6), 4.8);
    _olho(canvas, const Offset(14, -7), 4.8);

    canvas.restore();
  }

  // ======================================================================
  // TARTARUGA — casco em cúpula com escudos, pescoço que estica
  // ======================================================================

  void _tartaruga(Canvas canvas) {
    final amp = pose.amplitude;
    // O pescoço estica de leve ao respirar, e bastante quando fazem carinho.
    final estica = (pose.boia * 3 * amp) + pose.carinho * 6;

    // Patas maiores e mais baixas: numa tartaruga elas aparecem sob o casco.
    _pata(canvas, const Offset(36, 28), 20, 17, sombraForte,
        pose.boia * amp * 1.6);
    _pata(canvas, const Offset(-16, 30), 20, 17, sombra,
        -pose.boia * amp * 1.6);

    // Casco: uma cúpula, não meia elipse.
    final casco = Path()
      ..moveTo(-58, 18)
      ..cubicTo(-56, -42, 54, -42, 62, 18)
      ..close();
    canvas.drawPath(casco, _p(sombra));

    canvas.save();
    canvas.clipPath(casco);
    // Escudos: é isso que faz ler "casco" em vez de "meia-lua".
    final linha = _traco(sombraForte.withValues(alpha: 0.55), 2.2);
    for (final x in [-32.0, -8.0, 16.0, 38.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 18)
          ..cubicTo(x + 3, -6, x + 7, -18, x + 13, -26),
        linha,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(-54, -4)
        ..cubicTo(-20, -18, 26, -18, 56, -4),
      linha,
    );
    _oval(
      canvas,
      Rect.fromCenter(center: const Offset(-10, -22), width: 56, height: 16),
      luz.withValues(alpha: 0.28),
    );
    canvas.restore();

    // Plastrão: o casco de baixo. Recuado das pontas — a carapaça avança
    // sobre ele — e com aresta própria, senão lia como um vão branco entre
    // o casco e as patas.
    final plastrao = Path()
      ..moveTo(-50, 17)
      ..cubicTo(-28, 33, 30, 33, 54, 17)
      ..cubicTo(30, 23, -28, 23, -50, 17)
      ..close();
    canvas.drawPath(plastrao, _p(barriga));
    canvas.drawPath(
      Path()
        ..moveTo(-50, 17)
        ..cubicTo(-28, 33, 30, 33, 54, 17),
      _traco(sombraForte.withValues(alpha: 0.35), 1.6),
    );

    // --- pescoço e cabeça -------------------------------------------------
    canvas.save();
    canvas.translate(-54 - estica, 4 - estica * 0.3);
    canvas.rotate(_cabecaGiro - 0.06);

    // O pescoço liga a cabeça ao casco. Sem ele a cabeça flutuava. Da cor da
    // pele, não do plastrão: com o tom claro os dois viravam uma faixa só.
    canvas.drawPath(
      Path()
        ..moveTo(2, -7)
        ..cubicTo(16, -10, 30, -7, 38, 2)
        ..cubicTo(30, 11, 16, 13, 2, 11)
        ..close(),
      _p(sombra),
    );

    // Cabeça pequena: numa tartaruga o casco domina, não o rosto.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: 34, height: 29),
        esq: 1.04,
      ),
      _p(pelo),
    );

    _narina(canvas, const Offset(-13, -2));
    _boca(canvas, const Offset(-10, 7), 10);
    if (feliz) _bochecha(canvas, const Offset(-3, 6), const Offset(11, 4));

    _olho(canvas, const Offset(-3, -5), 3.9);
    _olho(canvas, const Offset(10, -6), 3.9);

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
    canvas.restore();
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

  void _bigodes(Canvas canvas, Offset o) {
    final t = _traco(sombraForte.withValues(alpha: 0.5), 1.2);
    // Os bigodes acompanham a respiração de leve.
    final abre = pose.respiro * pose.amplitude * 1.1;
    for (var i = 0; i < 3; i++) {
      final dy = (i - 1) * 3.5;
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy + dy)
          ..cubicTo(
            o.dx - 6, o.dy + dy - 1 - abre,
            o.dx - 11, o.dy + dy - 2 - abre * 1.3,
            o.dx - 16, o.dy + dy - 2 - abre * 1.5,
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
        old.pose.amplitude != pose.amplitude;
  }
}
