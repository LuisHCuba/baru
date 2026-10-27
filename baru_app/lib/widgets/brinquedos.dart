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
import '../models.dart';
import '../services/som_service.dart';
import 'comida.dart';
import 'pet.dart';
import 'vida/motor_de_vida.dart';

/// Onde fica o chão e como passar de pixel da cena para o desenho do bicho.
class GeometriaDosBrinquedos {
  const GeometriaDosBrinquedos({
    required this.largura,
    required this.escala,
    required this.baseDoBicho,
    this.agua = false,
    this.xMin,
    this.xMax,
    this.xInicialDaBola,
  });

  /// No mundo da home a bola fica na terra: entre [xMin] e [xMax] (px).
  /// Nulos: a cena inteira, menos a margem de alcance.
  final double? xMin;
  final double? xMax;

  /// Onde a bola começa (px). Nulo: a 78% da largura.
  final double? xInicialDaBola;

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
    required this.especie,
    this.podeConvidar = true,
    this.comPote = true,
    this.ondeDoPote,
  });

  /// Desenhar o potinho no canto da cena. Falso no mundo da home, onde ele
  /// mora na barra lateral e chama [BrinquedosDoHabitatState.pegaPetisco].
  final bool comPote;

  /// Onde o pote fica, em px da cena (o meio da base dele). Nulo: no canto
  /// de baixo, à esquerda.
  final Offset? ondeDoPote;

  /// De quem é o potinho: o petisco é o que esse bicho gosta.
  final Species especie;

  /// Ele pode vir pedir para brincar (acordado, fora do foco).
  final bool podeConvidar;

  /// De quanto em quanto tempo de tela ele pede para brincar: 3 a 5 min,
  /// no máximo (pesquisa 20, mecânica 7). Fixável no teste.
  @visibleForTesting
  static Duration? esperaDoConvite;

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
  late final Ticker _relogio;
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

  /// Foi ele quem foi buscar a bola, para pedir brincadeira.
  bool _convidando = false;
  Timer? _proximoConvite;

  // --- castanha -----------------------------------------------------------
  Offset? _castanha;
  Offset _vCastanha = Offset.zero;
  bool _castanhaNaMao = false;

  /// Há quanto tempo o petisco está no chão sem ele chegar: passa do
  /// ponto, some, e o pote enche de novo (auditoria, 5).
  double _castanhaParada = 0;
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
  void initState() {
    super.initState();
    // Criado já: preguiçoso, ele nasceria no `dispose`, com o elemento
    // desativado, e o `createTicker` quebra procurando o `TickerMode`.
    _relogio = createTicker(_tique);
    _agendaConvite();
  }

  @override
  void dispose() {
    _proximoConvite?.cancel();
    _relogio.dispose();
    super.dispose();
  }

  void _agendaConvite() {
    _proximoConvite?.cancel();
    _proximoConvite = Timer(
      BrinquedosDoHabitat.esperaDoConvite ??
          Duration(seconds: 180 + _sorte.nextInt(120)),
      _convida,
    );
  }

  /// Ele vai buscar a bola sozinho — se nada estiver acontecendo.
  void _convida() {
    if (!mounted) return;
    _agendaConvite();
    if (!widget.podeConvidar ||
        _bolaNaMao ||
        _castanha != null ||
        _vontade > 0 ||
        _relogio.isActive) {
      return;
    }
    _convidando = true;
    _vontade = 1;
    _semAlcancar = 0;
    _publica();
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
        // Quadro longo: ele "alcançou" uma posição velha. Só chuta perto.
        if ((b.dx - _g.naCena(xDoBicho)).abs() > 40 * _g.escala) return;
        _vontade -= 1;
        if (_convidando) {
          // O empurrão de quem quer brincar: devagar, para o meio da cena.
          _convidando = false;
          final meio = _g.largura / 2 - b.dx;
          final lado = meio.abs() < 20
              ? (_sorte.nextBool() ? 1.0 : -1.0)
              : meio.sign;
          _vBola = Offset(lado * 110 * _g.escala, -150 * _g.escala);
          HapticFeedback.selectionClick();
          _publica();
          _liga();
          return;
        }
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
    math.max(r + 4, _g.xMin ?? _g.margem),
    math.min(_g.largura - r - 4, _g.xMax ?? _g.largura - _g.margem),
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
          _convidando = false;
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
      _castanhaParada = ativo ? 0 : _castanhaParada + dt;
      if (_castanhaParada > 12) {
        _castanha = null;
        _castanhaParada = 0;
        _poteVoltaEm = _t + 1;
      }
      mexe = true;
    }

    for (final f in _farelos) {
      f.v = f.v + Offset(0, 900 * _g.escala * dt);
      f.p = f.p + f.v * dt;
      f.vida -= dt;
    }
    _farelos.removeWhere((f) => f.vida <= 0);
    mexe |= _farelos.isNotEmpty;
    mexe |= _t < _poteVoltaEm;
    // Com vontade ele está indo atrás: o relógio segue para ele poder
    // desistir se não alcançar.
    mexe |= _vontade > 0;

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
    // O teto da cena: arremesso forte bate e volta, não some por cima da
    // tela (sem moldura a cena não recorta).
    if (p.dy < r) {
      p = Offset(p.dx, r);
      v = Offset(v.dx, v.dy.abs() * 0.5);
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
            convite: _convidando,
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
    _convidando = false;
    _agendaConvite();
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
      (b.dy + delta.dy).clamp(_raioDaBola, _chaoDe(_raioDaBola)),
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

  /// Tem petisco para dar (o pote enche de novo uns segundos depois).
  bool get temPetisco => _t >= _poteVoltaEm && _castanha == null;

  /// Um petisco cai do pote, ao lado dele.
  void _daPetiscoDoPote() {
    if (!temPetisco) return;
    final o = widget.ondeDoPote ?? Offset(10 + 23, _g.chao);
    _castanha = Offset(
      _limitaX(o.dx + 40 * _g.escala, _raioDaCastanha),
      o.dy - 60 * _g.escala,
    );
    _castanhaNaMao = false;
    _castanhaParada = 0;
    _vCastanha = Offset.zero;
    _convidando = false;
    _agendaConvite();
    _publica();
    _liga();
  }

  void _pegaCastanha(Offset global) {
    if (_t < _poteVoltaEm || _castanha != null) return;
    _convidando = false;
    _agendaConvite();
    final caixa = context.findRenderObject() as RenderBox?;
    if (caixa == null) return;
    _castanha = caixa.globalToLocal(global) - Offset(0, 24 * _g.escala);
    _castanhaNaMao = true;
    _castanhaParada = 0;
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
      (c.dy + delta.dy).clamp(_raioDaCastanha, _chaoDe(_raioDaCastanha)),
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
      _limitaX(_g.xInicialDaBola ?? _g.largura * 0.78, _raioDaBola),
      _chaoDe(_raioDaBola),
    );
    final b = _bola!;
    final c = _castanha;
    const alvoDaBola = 56.0;
    final pote = widget.ondeDoPote == null ? 46.0 : 34 * _g.escala;
    // O alvo do dedo nunca é menor que 48: a tigela em 320 px tinha 34
    // (auditoria de dcf82c9, 3). O desenho fica no meio.
    final alvo = math.max(48.0, pote);
    final poteCheio = _t >= _poteVoltaEm && c == null;
    final o = widget.ondeDoPote;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _PintaBrinquedos(
                petisco: petiscoDe(widget.especie),
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
        // O potinho de petiscos: no canto de baixo, ou onde a cena disser.
        if (widget.comPote)
          Positioned(
            left: o == null ? 10 : o.dx - alvo / 2,
            bottom: o == null ? 10 : null,
            top: o == null ? null : o.dy - pote * 0.9 - (alvo - pote) / 2,
            width: alvo,
            height: alvo,
            child: Semantics(
              button: true,
              label: widget.rotuloDoPetisco,
              // Pelo leitor de tela não há arrasto: o toque deixa o petisco
              // cair ao lado do pote, e ele vem buscar (auditoria, 9).
              onTap: _daPetiscoDoPote,
              child: RawGestureDetector(
                key: BrinquedosDoHabitat.poteKey,
                behavior: HitTestBehavior.opaque,
                gestures: _arrasto(
                  comeca: (d) => _pegaCastanha(d.globalPosition),
                  anda: (d) => _arrastaCastanha(d.delta),
                  fim: (_) => _soltaCastanha(),
                ),
                child: Center(
                  child: SizedBox.square(
                    dimension: pote,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: poteCheio || o != null ? 1 : 0.45,
                      child: CustomPaint(
                        painter: _PintaPote(
                          cheio: poteCheio,
                          petisco: petiscoDe(widget.especie),
                          noChao: o != null,
                        ),
                      ),
                    ),
                  ),
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
    required this.petisco,
  });

  final Comida petisco;
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
    if (c != null) pintaComida(canvas, petisco, c, raioDaCastanha * 1.2);
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

  @override
  bool shouldRepaint(_PintaBrinquedos old) => true;
}

/// O potinho de madeira com castanhas.
class _PintaPote extends CustomPainter {
  const _PintaPote({
    required this.cheio,
    required this.petisco,
    this.noChao = false,
  });

  final bool cheio;
  final Comida petisco;

  /// Uma tigela no chão do mundo, com sombra — e não um botão redondo.
  final bool noChao;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (noChao) {
      _pintaNoChao(canvas, w, h);
      return;
    }
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
      pintaComida(
        canvas,
        petisco,
        Offset(w * 0.38, h * 0.44),
        r * 1.4,
        angulo: -0.3,
      );
      pintaComida(
        canvas,
        petisco,
        Offset(w * 0.62, h * 0.42),
        r * 1.4,
        angulo: 0.4,
      );
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

  void _pintaNoChao(Canvas canvas, double w, double h) {
    // A sombra no capim.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.9),
        width: w * 0.92,
        height: h * 0.16,
      ),
      Paint()..color = Cores.tintaA(0.16),
    );
    final r = w * 0.12;
    if (cheio) {
      for (final (x, y, a) in const [
        (0.34, 0.5, -0.4),
        (0.52, 0.44, 0.15),
        (0.68, 0.52, 0.5),
      ]) {
        pintaComida(canvas, petisco, Offset(w * x, h * y), r * 1.3, angulo: a);
      }
    }
    final borda = h * 0.56;
    final tigela = Path()
      ..moveTo(w * 0.1, borda)
      ..cubicTo(w * 0.12, h * 0.86, w * 0.88, h * 0.86, w * 0.9, borda)
      ..close();
    canvas.drawPath(tigela, Paint()..color = Cores.madeira);
    // Um brilho de verniz na barriga da tigela.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, borda + h * 0.08)
        ..quadraticBezierTo(w * 0.3, h * 0.78, w * 0.44, h * 0.8),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.035
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, borda),
        width: w * 0.8,
        height: h * 0.1,
      ),
      Paint()
        ..color = Cores.madeiraEscura
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  @override
  bool shouldRepaint(_PintaPote old) =>
      old.cheio != cheio || old.petisco != petisco;
}
