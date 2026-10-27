/// A bolinha e a castanha do habitat: o que o bicho persegue.
///
/// Pesquisa 20, mecânicas 9 e 10. A bolinha é arremessada com o dedo e cai,
/// quica e rola com física; o bicho vai atrás no jeito da espécie e chuta
/// quando alcança, algumas vezes, até cansar. A castanha de baru sai do
/// potinho no canto: arrastada até a boca ele come da mão; solta longe, cai
/// no chão e ele vai buscar.
///
/// A cena fala com o bicho por um [ValueNotifier] de [InteresseDoBicho], em
/// unidades do desenho dele; ele responde por [BrinquedosDoHabitatState.alcancou].
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';
import '../services/som_service.dart';
import 'pet.dart';
import 'vida/motor_de_vida.dart';

/// Onde fica o chão e como passar de pixel da cena para o desenho do bicho.
class GeometriaDosBrinquedos {
  const GeometriaDosBrinquedos({
    required this.largura,
    required this.escala,
    required this.baseDoBicho,
    this.agua = false,
  });

  /// Largura da cena, em px.
  final double largura;

  /// A escala do bicho (px por unidade do desenho).
  final double escala;

  /// O y (px) da base da caixa de 150 unidades do bicho, na cena.
  final double baseDoBicho;

  /// Ele está na água: as coisas boiam na lâmina em vez de pousar no chão.
  final bool agua;

  static const _alturaDoBicho = 150.0;
  static const _repouso = _alturaDoBicho / 2 + 10;

  /// Os pés dele ficam 5 unidades acima da base da caixa.
  double get chao => agua
      ? baseDoBicho -
            (_alturaDoBicho - PetView.linhaDaguaEm(_alturaDoBicho)) * escala
      : baseDoBicho - 5 * escala;

  /// Até onde ele alcança, dos dois lados (ver `areaDeAndar` no habitat).
  double get margem => 64 * escala;

  /// Pixel da cena → unidades do desenho, relativas ao repouso do corpo.
  Offset paraOBicho(Offset p) => Offset(
    (p.dx - largura / 2) / escala,
    (p.dy - baseDoBicho) / escala + _alturaDoBicho - _repouso,
  );

  /// Um x do desenho do bicho → pixel da cena.
  double naCena(double x) => largura / 2 + x * escala;
}

class BrinquedosDoHabitat extends StatefulWidget {
  const BrinquedosDoHabitat({
    super.key,
    required this.geometria,
    required this.interesse,
    required this.rotuloDaBola,
    required this.rotuloDoPetisco,
  });

  final GeometriaDosBrinquedos geometria;

  /// Para onde o bicho deve olhar e ir. Escrito por esta camada.
  final ValueNotifier<InteresseDoBicho?> interesse;

  final String rotuloDaBola;
  final String rotuloDoPetisco;

  static const bolaKey = Key('brinquedo-bola');
  static const poteKey = Key('brinquedo-pote');

  @override
  State<BrinquedosDoHabitat> createState() => BrinquedosDoHabitatState();
}

class BrinquedosDoHabitatState extends State<BrinquedosDoHabitat>
    with SingleTickerProviderStateMixin {
  late final Ticker _relogio = createTicker(_tique);
  Duration _antes = Duration.zero;
  final _sorte = math.Random();

  GeometriaDosBrinquedos get _g => widget.geometria;
  double get _raioDaBola => 12 * _g.escala;
  double get _raioDaCastanha => 8 * _g.escala;

  // --- bola ---------------------------------------------------------------
  Offset? _bola;
  Offset _vBola = Offset.zero;
  double _giro = 0;
  bool _bolaNaMao = false;
  DateTime _pegouEm = DateTime(0);

  /// Quantas vezes ele ainda corre atrás sem a pessoa jogar de novo. Cada
  /// chute gasta uma; a pessoa jogando enche. Sem isto ele chutaria para
  /// sempre, e brincadeira que não acaba não é de bicho, é de máquina.
  int _vontade = 0;

  /// Há quanto tempo ele persegue sem alcançar: a tartaruga desiste.
  double _semAlcancar = 0;

  // --- castanha -----------------------------------------------------------
  Offset? _castanha;
  Offset _vCastanha = Offset.zero;
  bool _castanhaNaMao = false;
  double _poteVoltaEm = 0;
  double _t = 0;
  final List<_Farelo> _farelos = [];

  @override
  void didUpdateWidget(BrinquedosDoHabitat oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A cena mudou de tamanho (ou ele entrou na água): a bola vai junto
    // para o chão novo.
    final b = _bola;
    if (b != null &&
        (oldWidget.geometria.chao != _g.chao ||
            oldWidget.geometria.largura != _g.largura)) {
      _vBola = Offset(_vBola.dx, math.min(_vBola.dy, 0));
      _bola = Offset(
        _limitaX(b.dx, _raioDaBola),
        math.min(b.dy, _chaoDe(_raioDaBola)),
      );
      _liga();
    }
  }

  @override
  void dispose() {
    _relogio.dispose();
    super.dispose();
  }

  /// O bicho chegou na coisa. [xDoBicho] em unidades do desenho dele.
  void alcancou(TipoDeInteresse tipo, double xDoBicho) {
    _semAlcancar = 0;
    switch (tipo) {
      case TipoDeInteresse.comida:
        final c = _castanha;
        if (c == null) return;
        _esfarela(c);
        _castanha = null;
        _castanhaNaMao = false;
        _poteVoltaEm = _t + 4;
        unawaited(SomService.instance.toca(SomDoBaru.mastiga));
      case TipoDeInteresse.bola:
        final b = _bola;
        if (b == null || _bolaNaMao || _vontade <= 0) return;
        _vontade -= 1;
        final ondeEle = _g.naCena(xDoBicho);
        var lado = (b.dx - ondeEle).sign;
        if (lado == 0) lado = _sorte.nextBool() ? 1 : -1;
        // Perto da parede ele chuta para dentro.
        if (b.dx < _g.margem + 30) lado = 1;
        if (b.dx > _g.largura - _g.margem - 30) lado = -1;
        final e = _g.escala;
        _vBola = Offset(
          lado * (150 + _sorte.nextDouble() * 170) * e,
          -(260 + _sorte.nextDouble() * 200) * e,
        );
        HapticFeedback.selectionClick();
        unawaited(SomService.instance.toca(SomDoBaru.quique));
    }
    _publica();
    _liga();
  }

  // ======================================================================
  // Física
  // ======================================================================

  double _chaoDe(double r) => _g.agua ? _g.chao : _g.chao - r;

  double _limitaX(double x, double r) => x.clamp(
    math.max(r + 4, _g.margem),
    math.min(_g.largura - r - 4, _g.largura - _g.margem),
  );

  void _liga() {
    if (!mounted || _relogio.isActive) return;
    _antes = Duration.zero;
    _relogio.start();
  }

  void _tique(Duration agora) {
    final dt = _antes == Duration.zero
        ? 1 / 60
        : ((agora - _antes).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _antes = agora;
    _t += dt;
    var mexe = false;

    final b = _bola;
    if (b != null && !_bolaNaMao) {
      final r = _raioDaBola;
      final (p, v, ativo, impacto) = _cai(b, _vBola, r, dt, volta: 0.58);
      _bola = p;
      _vBola = v;
      _giro += v.dx * dt / r;
      mexe |= ativo;
      if (impacto > 260 * _g.escala) {
        unawaited(SomService.instance.toca(SomDoBaru.quique));
      }
      // Parada e com vontade, mas ele não chega: desiste.
      if (_vontade > 0) {
        _semAlcancar += dt;
        if (_semAlcancar > 14) {
          _vontade = 0;
          _semAlcancar = 0;
        }
      }
    }

    final c = _castanha;
    if (c != null && !_castanhaNaMao) {
      final (p, v, ativo, _) = _cai(
        c,
        _vCastanha,
        _raioDaCastanha,
        dt,
        volta: 0.25,
      );
      _castanha = p;
      _vCastanha = v;
      mexe |= ativo;
    }

    for (final f in _farelos) {
      f.v = f.v + Offset(0, 900 * _g.escala * dt);
      f.p = f.p + f.v * dt;
      f.vida -= dt;
    }
    _farelos.removeWhere((f) => f.vida <= 0);
    mexe |= _farelos.isNotEmpty;
    mexe |= _t < _poteVoltaEm;

    _publica();
    setState(() {});
    if (!mexe && !_bolaNaMao && !_castanhaNaMao) _relogio.stop();
  }

  /// Um passo de queda: gravidade, quique no chão, atrito, paredes.
  (Offset, Offset, bool, double) _cai(
    Offset p,
    Offset v,
    double r,
    double dt, {
    required double volta,
  }) {
    final e = _g.escala;
    v = v + Offset(0, 1500 * e * dt);
    p = p + v * dt;
    var impacto = 0.0;
    final chao = _chaoDe(r);
    if (p.dy >= chao) {
      p = Offset(p.dx, chao);
      if (v.dy > 120 * e && !_g.agua) {
        impacto = v.dy;
        v = Offset(v.dx * 0.92, -v.dy * volta);
      } else {
        v = Offset(v.dx, 0);
      }
    }
    final noChao = p.dy >= chao - 0.5 && v.dy == 0;
    if (noChao) {
      v = Offset(v.dx * math.exp(-(_g.agua ? 1.2 : 2.2) * dt), 0);
    }
    final x = _limitaX(p.dx, r);
    if (x != p.dx) {
      impacto = math.max(impacto, v.dx.abs());
      v = Offset(-v.dx * 0.6, v.dy);
      p = Offset(x, p.dy);
    }
    final ativo = !(noChao && v.dx.abs() < 3 * e);
    if (!ativo) v = Offset.zero;
    return (p, v, ativo, impacto);
  }

  void _publica() {
    final c = _castanha;
    final b = _bola;
    widget.interesse.value = c != null
        ? InteresseDoBicho(
            _g.paraOBicho(c),
            TipoDeInteresse.comida,
            noAr: _castanhaNaMao,
          )
        : b != null && (_bolaNaMao || _vontade > 0)
        ? InteresseDoBicho(
            _g.paraOBicho(b),
            TipoDeInteresse.bola,
            noAr: _bolaNaMao,
          )
        : null;
  }

  void _esfarela(Offset onde) {
    final e = _g.escala;
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + (_sorte.nextDouble() - 0.5) * 2.4;
      final s = (60 + _sorte.nextDouble() * 120) * e;
      _farelos.add(
        _Farelo(
          p: onde,
          v: Offset(math.cos(a) * s, math.sin(a) * s),
          vida: 0.5 + _sorte.nextDouble() * 0.3,
        ),
      );
    }
  }

  // ======================================================================
  // Dedo
  // ======================================================================

  void _pegaBola(Offset onde) {
    _bolaNaMao = true;
    _pegouEm = DateTime.now();
    _vBola = Offset.zero;
    HapticFeedback.selectionClick();
    _publica();
    _liga();
  }

  void _arrastaBola(Offset delta) {
    final b = _bola;
    if (b == null || !_bolaNaMao) return;
    _bola = Offset(
      _limitaX(b.dx + delta.dx, _raioDaBola),
      math.min(b.dy + delta.dy, _chaoDe(_raioDaBola)),
    );
  }

  void _soltaBola(Velocity v) {
    if (!_bolaNaMao) return;
    _bolaNaMao = false;
    final e = _g.escala;
    var vel = v.pixelsPerSecond;
    final rapido = DateTime.now().difference(_pegouEm).inMilliseconds < 220;
    // Um toque, sem arremesso: ela pula um pouquinho no lugar.
    if (vel.distance < 80 && rapido) vel = Offset(0, -380 * e);
    final max = 1500 * e;
    if (vel.distance > max) vel = vel / vel.distance * max;
    _vBola = vel;
    _vontade = 3;
    _semAlcancar = 0;
    _publica();
    _liga();
  }

  void _pegaCastanha(Offset global) {
    if (_t < _poteVoltaEm || _castanha != null) return;
    final caixa = context.findRenderObject() as RenderBox?;
    if (caixa == null) return;
    _castanha = caixa.globalToLocal(global) - Offset(0, 24 * _g.escala);
    _castanhaNaMao = true;
    _vCastanha = Offset.zero;
    HapticFeedback.selectionClick();
    _publica();
    _liga();
  }

  void _arrastaCastanha(Offset delta) {
    final c = _castanha;
    if (c == null || !_castanhaNaMao) return;
    _castanha = Offset(
      (c.dx + delta.dx).clamp(0.0, _g.largura),
      math.min(c.dy + delta.dy, _chaoDe(_raioDaCastanha)),
    );
  }

  void _soltaCastanha() {
    if (!_castanhaNaMao) return;
    _castanhaNaMao = false;
    final c = _castanha;
    if (c != null) _castanha = Offset(_limitaX(c.dx, _raioDaCastanha), c.dy);
    _vCastanha = Offset.zero;
    _publica();
    _liga();
  }

  @override
  Widget build(BuildContext context) {
    // A bola começa no chão, à direita, onde ele alcança.
    _bola ??= Offset(
      _limitaX(_g.largura * 0.78, _raioDaBola),
      _chaoDe(_raioDaBola),
    );
    final b = _bola!;
    final c = _castanha;
    const alvoDaBola = 56.0;
    const pote = 46.0;
    final poteCheio = _t >= _poteVoltaEm && c == null;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PintaBrinquedos(
                bola: b,
                giro: _giro,
                raioDaBola: _raioDaBola,
                castanha: c,
                raioDaCastanha: _raioDaCastanha,
                chao: _g.chao,
                agua: _g.agua,
                farelos: _farelos,
              ),
            ),
          ),
        ),
        // O potinho de castanhas, no canto de baixo.
        Positioned(
          left: 10,
          bottom: 10,
          width: pote,
          height: pote,
          child: Semantics(
            button: true,
            label: widget.rotuloDoPetisco,
            child: RawGestureDetector(
              key: BrinquedosDoHabitat.poteKey,
              behavior: HitTestBehavior.opaque,
              gestures: _arrasto(
                comeca: (d) => _pegaCastanha(d.globalPosition),
                anda: (d) => _arrastaCastanha(d.delta),
                fim: (_) => _soltaCastanha(),
              ),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: poteCheio ? 1 : 0.45,
                child: CustomPaint(painter: _PintaPote(cheio: poteCheio)),
              ),
            ),
          ),
        ),
        Positioned(
          left: b.dx - alvoDaBola / 2,
          top: b.dy - alvoDaBola / 2,
          width: alvoDaBola,
          height: alvoDaBola,
          child: Semantics(
            button: true,
            label: widget.rotuloDaBola,
            child: RawGestureDetector(
              key: BrinquedosDoHabitat.bolaKey,
              behavior: HitTestBehavior.opaque,
              gestures: _arrasto(
                comeca: (d) => _pegaBola(d.localPosition),
                anda: (d) => _arrastaBola(d.delta),
                fim: (d) => _soltaBola(d.velocity),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }

  Map<Type, GestureRecognizerFactory> _arrasto({
    required void Function(DragStartDetails) comeca,
    required void Function(DragUpdateDetails) anda,
    required void Function(DragEndDetails) fim,
  }) => {
    _PegaJa: GestureRecognizerFactoryWithHandlers<_PegaJa>(
      _PegaJa.new,
      (r) => r
        ..onStart = comeca
        ..onUpdate = anda
        ..onEnd = fim
        ..onCancel = () => fim(DragEndDetails()),
    ),
  };
}

/// Pega no toque: a bolinha não espera o dedo andar, senão a rolagem da
/// página leva o arrasto vertical.
class _PegaJa extends PanGestureRecognizer {
  _PegaJa() {
    dragStartBehavior = DragStartBehavior.down;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _Farelo {
  _Farelo({required this.p, required this.v, required this.vida});
  Offset p;
  Offset v;
  double vida;
}

class _PintaBrinquedos extends CustomPainter {
  _PintaBrinquedos({
    required this.bola,
    required this.giro,
    required this.raioDaBola,
    required this.castanha,
    required this.raioDaCastanha,
    required this.chao,
    required this.agua,
    required this.farelos,
  });

  final Offset bola;
  final double giro;
  final double raioDaBola;
  final Offset? castanha;
  final double raioDaCastanha;
  final double chao;
  final bool agua;
  final List<_Farelo> farelos;

  @override
  void paint(Canvas canvas, Size size) {
    _sombra(canvas, bola, raioDaBola);
    final c = castanha;
    if (c != null) _sombra(canvas, c, raioDaCastanha);
    _bola(canvas);
    if (c != null) _castanha(canvas, c, raioDaCastanha);
    for (final f in farelos) {
      canvas.drawCircle(
        f.p,
        raioDaCastanha * 0.22,
        Paint()
          ..color = const Color(
            0xFF9A6233,
          ).withValues(alpha: (f.vida / 0.5).clamp(0.0, 1.0)),
      );
    }
  }

  /// Sombra no chão: menor e mais clara quanto mais alto.
  void _sombra(Canvas canvas, Offset p, double r) {
    if (agua) return;
    final alto = ((chao - r - p.dy) / (r * 8)).clamp(0.0, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(p.dx, chao - 1),
        width: r * 2.2 * (1 - alto * 0.5),
        height: r * 0.5 * (1 - alto * 0.5),
      ),
      Paint()..color = Cores.tintaA(0.16 * (1 - alto * 0.7)),
    );
  }

  void _bola(Canvas canvas) {
    final r = raioDaBola;
    canvas.save();
    canvas.translate(bola.dx, bola.dy);
    canvas.rotate(giro);
    final corpo = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          radius: 1.1,
          colors: [Color(0xFFF59A6E), Cores.raiz500, Cores.raiz600],
          stops: [0, 0.55, 1],
        ).createShader(corpo),
    );
    // A faixa creme que mostra a bola girando.
    canvas.save();
    canvas.clipPath(Path()..addOval(corpo));
    final faixa = Paint()
      ..color = Cores.creme
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.42;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, r * 1.25), radius: r * 1.35),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      faixa,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = Cores.raiz700.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
    // O brilho não gira: a luz vem sempre de cima.
    canvas.drawCircle(
      bola + Offset(-r * 0.38, -r * 0.42),
      r * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  static void _castanha(Canvas canvas, Offset p, double r) {
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(-0.35);
    final forma = Rect.fromCenter(
      center: Offset.zero,
      width: r * 2.5,
      height: r * 1.6,
    );
    canvas.drawOval(
      forma,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB98552), Color(0xFF7A4A26)],
        ).createShader(forma),
    );
    // A costura do baru e o brilho da casca.
    canvas.drawLine(
      Offset(-r * 0.95, r * 0.05),
      Offset(r * 0.95, -r * 0.05),
      Paint()
        ..color = const Color(0xFF5A3418).withValues(alpha: 0.6)
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-r * 0.35, -r * 0.4),
        width: r * 0.9,
        height: r * 0.32,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintaBrinquedos old) => true;
}

/// O potinho de madeira com castanhas.
class _PintaPote extends CustomPainter {
  const _PintaPote({required this.cheio});

  final bool cheio;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final fundo = Paint()
      ..color = Cores.superficieElevada.withValues(alpha: 0.86);
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, fundo);
    canvas.drawCircle(
      Offset(w / 2, h / 2),
      w / 2 - 0.5,
      Paint()
        ..color = Cores.tintaA(0.12)
        ..style = PaintingStyle.stroke,
    );
    final r = w * 0.11;
    if (cheio) {
      _PintaBrinquedos._castanha(canvas, Offset(w * 0.40, h * 0.47), r);
      _PintaBrinquedos._castanha(canvas, Offset(w * 0.60, h * 0.44), r);
    }
    // A tigela por cima das castanhas.
    final tigela = Path()
      ..moveTo(w * 0.2, h * 0.52)
      ..quadraticBezierTo(w * 0.5, h * 0.92, w * 0.8, h * 0.52)
      ..close();
    canvas.drawPath(tigela, Paint()..color = Cores.madeira);
    canvas.drawLine(
      Offset(w * 0.2, h * 0.52),
      Offset(w * 0.8, h * 0.52),
      Paint()
        ..color = Cores.madeiraEscura
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PintaPote old) => old.cheio != cheio;
}
