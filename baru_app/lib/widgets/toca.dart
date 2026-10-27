import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/som_service.dart';
import '../theme.dart';
import 'glifos.dart';

/// A toca de onde sai a recompensa.
///
/// **Por que não um botão "Resgatar".** Recompensa que chega sozinha não é
/// sentida. O gesto é o que transforma "ganhei" em "eu tirei dali" — é o
/// mesmo motivo pelo qual abrir um presente vale mais que recebê-lo aberto.
///
/// **Por que um pote de barro e não um baú.** Baú é vocabulário de RPG. Aqui
/// o mundo é bicho e mato: o bicho guarda coisa embaixo da terra, num pote,
/// e a pessoa **cava** com ele para achar.
///
/// **O desenho: um corte de terra.** A primeira versão era uma meia elipse
/// marrom com um furo, solta num véu escuro — "horrível", nas palavras do
/// dono do produto. Agora a cena é o corte que livro ilustrado faz: em cima
/// a grama e o bicho da pessoa; embaixo as camadas do chão, raízes,
/// pedrinhas, uma minhoca dormindo e, lá no fundo, o pote brilhando. Ver o
/// prêmio enterrado é o que dá vontade de cavar; ver o túnel descendo a
/// cada toque é o que faz o gesto parecer trabalho de verdade.
///
/// **Como funciona.** Cada toque (ou arrasto) é uma pazada: o bicho pula, a
/// terra voa, o túnel desce e o monte ao lado cresce. Na última o túnel
/// chega ao pote, a tampa salta, a luz sobe pelo túnel até o céu e o prêmio
/// sobe junto. [Toca.precisaDe] gestos é o contrato: sem eles não abre.
class Toca extends StatefulWidget {
  const Toca({
    super.key,
    required this.aoAbrir,
    required this.rotuloDoPremio,
    this.icone = const GlifoFolha(tamanho: 34),
    this.cor = Cores.folha600,
    this.corDoRotulo,
    this.bicho,
    this.altura = 330,
    this.cantos = true,
  });

  /// Cantos de baixo arredondados: um bloco de terra recortado. Sem eles,
  /// quando a terra vai até a borda da tela.
  final bool cantos;

  /// A cor do nome do prêmio. Por padrão creme, sobre a etiqueta escura.
  final Color? corDoRotulo;

  /// Chamado uma vez, quando a terra abre.
  final VoidCallback aoAbrir;

  /// O que está lá dentro, já traduzido.
  final String rotuloDoPremio;

  /// O prêmio dentro do pote. A folha, salvo outro.
  final Widget icone;
  final Color cor;

  /// O bicho da pessoa, que cava junto. Sem ele, uma pá fincada no monte.
  final Widget? bicho;

  final double altura;

  /// Quantos gestos até abrir.
  ///
  /// Três: um é acidente, cinco é trabalho. Três dá ritmo — cava, cava,
  /// abriu — e cabe no tempo em que a pessoa ainda está olhando.
  static const precisaDe = 3;

  static const chave = Key('toca');
  static const chaveDoPremio = Key('toca-premio');

  @override
  State<Toca> createState() => _TocaState();
}

class _TocaState extends State<Toca> with TickerProviderStateMixin {
  /// A pazada: o pulo do bicho, o tremor e a terra voando.
  late final AnimationController _pazada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  /// O túnel descendo da profundidade anterior até a nova.
  late final AnimationController _desce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  /// A abertura: tampa, luz e o prêmio subindo.
  late final AnimationController _abre = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  /// O que respira enquanto ninguém mexe: o pote pulsando, a dica do dedo,
  /// a grama, a minhoca.
  late final AnimationController _ambiente = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  int _gestos = 0;
  bool _aberta = false;
  double _profundidadeAntes = 0;

  double get _profundidadeAlvo => (_gestos / Toca.precisaDe).clamp(0.0, 1.0);

  double get _profundidade =>
      _profundidadeAntes +
      (_profundidadeAlvo - _profundidadeAntes) *
          Curves.easeOutCubic.transform(_desce.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimento.reduzido(context)) {
      _ambiente.stop();
    } else if (!_ambiente.isAnimating) {
      _ambiente.repeat();
    }
  }

  @override
  void dispose() {
    _pazada.dispose();
    _desce.dispose();
    _abre.dispose();
    _ambiente.dispose();
    super.dispose();
  }

  void _escava() {
    if (_aberta) return;
    final reduzido = Movimento.reduzido(context);
    setState(() {
      _profundidadeAntes = _profundidade;
      _gestos++;
    });
    final ultima = _gestos >= Toca.precisaDe;

    // O háptico acompanha a pazada; a última é a mais forte, e é ela que
    // anuncia que algo vai acontecer.
    ultima ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact();

    // Na última, o som é a abertura — não mais uma raspada. O `SomService`
    // tem limitador de taxa, e dois sons no mesmo instante viram um: tocar
    // `cavar` aqui engolia o `premio`.
    if (!ultima) SomService.instance.toca(SomDoBaru.cavar);

    if (reduzido) {
      _desce.value = 1;
    } else {
      _desce.forward(from: 0);
      _pazada.forward(from: 0);
    }

    if (ultima) {
      setState(() => _aberta = true);
      SomService.instance.toca(SomDoBaru.premio);
      if (reduzido) {
        _abre.value = 1;
        widget.aoAbrir();
      } else {
        _abre.forward(from: 0).then((_) {
          if (mounted) widget.aoAbrir();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !_aberta,
      label: widget.rotuloDoPremio,
      child: GestureDetector(
        key: Toca.chave,
        behavior: HitTestBehavior.opaque,
        onTap: _escava,
        // Arrastar também cava: quem tenta "raspar" a terra com o dedo está
        // fazendo exatamente o gesto que a cena pede.
        onPanEnd: (_) => _escava(),
        child: SizedBox(
          height: widget.altura,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth.isFinite ? c.maxWidth : 360.0;
              final h = widget.altura;
              final g = _Geometria(Size(w, h));
              return AnimatedBuilder(
                animation: Listenable.merge([_pazada, _desce, _abre, _ambiente]),
                builder: (context, _) {
                  final pazada = _pazada.value;
                  final pulo = math.sin(pazada * math.pi);
                  final abre = _abre.value;
                  final sobe = Curves.easeOutBack.transform(
                    ((abre - 0.25) / 0.6).clamp(0.0, 1.0),
                  );
                  final tremor =
                      math.sin(pazada * math.pi * 3) * (1 - pazada) * 3;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(tremor, 0),
                          child: CustomPaint(
                            painter: _CorteDaTerra(
                              g: g,
                              profundidade: _profundidade,
                              pazada: pazada,
                              abre: abre,
                              ambiente: _ambiente.value,
                              cor: widget.cor,
                              comBicho: widget.bicho != null,
                              cantos: widget.cantos,
                            ),
                          ),
                        ),
                      ),
                      // O bicho, à esquerda do buraco: pula e se inclina
                      // para a terra a cada pazada; na abertura, festeja.
                      if (widget.bicho != null)
                        Positioned(
                          left: g.bicho.dx - 78 * g.escalaDoBicho,
                          top: g.superficie -
                              126 * g.escalaDoBicho -
                              18 * pulo -
                              (_aberta ? 12 * math.sin(abre * math.pi) : 0),
                          width: 156 * g.escalaDoBicho,
                          height: 130 * g.escalaDoBicho,
                          child: Transform.rotate(
                            angle: 0.18 * pulo -
                                (_aberta ? 0.08 * math.sin(abre * 9) : 0),
                            alignment: Alignment.bottomCenter,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              child: widget.bicho,
                            ),
                          ),
                        ),
                      // A dica: onde tocar, até a primeira pazada.
                      if (_gestos == 0)
                        Positioned(
                          left: g.buraco - 28,
                          top: g.superficie - 64,
                          width: 56,
                          height: 56,
                          child: IgnorePointer(
                            child: _Dedo(t: _ambiente.value),
                          ),
                        ),
                      // As pazadas que faltam, como marcas no canto.
                      Positioned(
                        right: Espaco.md,
                        top: g.superficie + Espaco.sm,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: (1 - abre * 3).clamp(0.0, 1.0),
                            child: _Marcas(feitas: _gestos, cor: widget.cor),
                          ),
                        ),
                      ),
                      // O prêmio, subindo do pote pelo túnel até o céu.
                      if (_aberta)
                        Positioned(
                          left: g.buraco - 90,
                          width: 180,
                          // Sobe pelo túnel e para no céu, acima do buraco —
                          // ao lado do bicho, não em cima dele.
                          top: g.pote.dy -
                              40 -
                              (g.pote.dy - g.superficie + 150) * sobe,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: (abre * 4).clamp(0.0, 1.0),
                              child: Transform.scale(
                                scale: 0.4 + 0.6 * sobe,
                                child: _Premio(
                                  key: Toca.chaveDoPremio,
                                  rotulo: widget.rotuloDoPremio,
                                  icone: widget.icone,
                                  corDoRotulo:
                                      widget.corDoRotulo ?? Cores.tintaClara,
                                  cor: widget.cor,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Onde fica cada coisa na cena, num lugar só.
class _Geometria {
  _Geometria(this.tamanho);

  final Size tamanho;

  double get w => tamanho.width;
  double get h => tamanho.height;

  /// A linha da grama.
  double get superficie => h * 0.40;

  /// O centro do buraco, um pouco à direita: à esquerda fica o bicho.
  double get buraco => w * 0.56;

  Offset get bicho => Offset(w * 0.24, superficie);

  /// O bicho cresce com a cena: na tela cheia ele sumia no céu.
  double get escalaDoBicho => (h / 420).clamp(1.0, 1.45);

  /// O pote, no fundo, embaixo do buraco.
  Offset get pote => Offset(buraco, h * 0.80);

  /// Até onde o túnel desce para encostar no pote.
  double get fundo => pote.dy - 26;
}

/// A terra em corte: camadas, raízes, pedrinhas, a minhoca, o pote, o túnel,
/// a grama e a terra voando.
///
/// Tudo em `CustomPainter` pelo mesmo motivo do bicho: imagem pronta não
/// acompanha o gesto, e é o acompanhamento que faz a cena parecer resposta.
class _CorteDaTerra extends CustomPainter {
  _CorteDaTerra({
    required this.g,
    required this.profundidade,
    required this.pazada,
    required this.abre,
    required this.ambiente,
    required this.cor,
    required this.comBicho,
    required this.cantos,
  });

  final bool cantos;
  final _Geometria g;
  final double profundidade;
  final double pazada;
  final double abre;
  final double ambiente;
  final Color cor;
  final bool comBicho;

  static const _grama = Color(0xFF8DB86B);
  static const _gramaEscura = Color(0xFF6E9150);
  static const _camadas = [
    Color(0xFF9A7049),
    Color(0xFF835D3D),
    Color(0xFF6C4C33),
    Color(0xFF573D2A),
  ];
  static const _tunel = Color(0xFF2E2118);
  static const _barro = Color(0xFFC8734A);
  static const _barroEscuro = Color(0xFF9E5434);

  Paint _p(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final w = g.w, h = g.h, s = g.superficie;
    final onda = ambiente * math.pi * 2;

    // --- as colinas atrás, no céu -------------------------------------
    // Sem elas a grama era uma régua contra o céu.
    for (final (x0, largura, alto, cor) in [
      (-0.10, 0.70, 0.24, const Color(0x553E3358)),
      (0.45, 0.75, 0.30, const Color(0x664A3D63)),
      (0.10, 0.55, 0.16, const Color(0x88566B4F)),
      (0.62, 0.50, 0.13, const Color(0x99627A57)),
    ]) {
      final l = w * x0, r = w * (x0 + largura), topo = s - h * alto;
      canvas.drawPath(
        Path()
          ..moveTo(l, s + 2)
          ..cubicTo(l + (r - l) * 0.2, topo, l + (r - l) * 0.8, topo, r, s + 2)
          ..close(),
        _p(cor),
      );
    }

    // --- o chão, em camadas -------------------------------------------
    // Cantos de baixo arredondados: um bloco de terra recortado, como num
    // livro, e não uma faixa que some na borda.
    final bloco = RRect.fromRectAndCorners(
      Rect.fromLTRB(0, s, w, h),
      bottomLeft: Radius.circular(cantos ? Raio.cartaoGrande : 0),
      bottomRight: Radius.circular(cantos ? Raio.cartaoGrande : 0),
    );
    canvas.save();
    canvas.clipRRect(bloco);
    for (var i = 0; i < _camadas.length; i++) {
      final topo = s + (h - s) * (i / _camadas.length);
      final camada = Path()..moveTo(0, topo);
      for (var x = 0.0; x <= w + 8; x += 8) {
        camada.lineTo(x, topo + (i == 0 ? 0 : math.sin(x / 38 + i * 1.7) * 5));
      }
      camada
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(camada, _p(_camadas[i]));
    }

    // Pedrinhas e grãos espalhados na terra.
    final r = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final x = r.nextDouble() * w;
      final y = s + 18 + r.nextDouble() * (h - s - 24);
      final tam = 1.5 + r.nextDouble() * 4.5;
      if ((x - g.buraco).abs() < 30) continue;
      final o = Rect.fromCenter(
        center: Offset(x, y),
        width: tam * 2.2,
        height: tam * 1.5,
      );
      canvas.drawOval(
        o,
        _p(i.isEven ? const Color(0xFFB8AC9A) : const Color(0x44000000)),
      );
      if (i.isEven) {
        canvas.drawOval(
          Rect.fromCenter(
            center: o.center.translate(-tam * 0.3, -tam * 0.25),
            width: tam * 0.8,
            height: tam * 0.5,
          ),
          _p(const Color(0x88FFFFFF)),
        );
      }
    }

    // Raízes descendo da grama, com as pontas finas.
    final raiz = Paint()
      ..color = const Color(0xFFD8B98C).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final (x0, comp, curva) in [
      (w * 0.08, 0.34, 18.0),
      (w * 0.16, 0.22, -12.0),
      (w * 0.86, 0.30, -20.0),
      (w * 0.94, 0.18, 10.0),
    ]) {
      final fim = Offset(x0 + curva, s + (h - s) * comp);
      canvas.drawPath(
        Path()
          ..moveTo(x0, s + 2)
          ..quadraticBezierTo(x0 - curva, (s + fim.dy) / 2, fim.dx, fim.dy),
        raiz..strokeWidth = 2.6,
      );
      canvas.drawPath(
        Path()
          ..moveTo(x0 - curva * 0.2, s + (fim.dy - s) * 0.5)
          ..quadraticBezierTo(
            x0 - curva * 0.9,
            s + (fim.dy - s) * 0.62,
            x0 - curva * 1.3,
            s + (fim.dy - s) * 0.8,
          ),
        raiz..strokeWidth = 1.4,
      );
    }

    // A minhoca dormindo, num canto, respirando.
    final minhoca = Offset(w * 0.17, h * 0.72);
    final respira = 1 + 0.05 * math.sin(onda);
    canvas.save();
    canvas.translate(minhoca.dx, minhoca.dy);
    canvas.scale(respira, 1 / respira);
    canvas.drawPath(
      Path()
        ..moveTo(-20, 4)
        ..cubicTo(-14, -8, -4, 10, 4, -2)
        ..cubicTo(8, -8, 14, -6, 18, 0),
      Paint()
        ..color = const Color(0xFFE39A8E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(17, -1), radius: 1.6),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = const Color(0xFF5A3A30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
    // Os "z" de quem dorme — até a terra se abrir.
    if (abre == 0) {
      for (final (k, atraso) in [(0, 0.0), (1, 0.5)]) {
        final t = (ambiente + atraso) % 1;
        final z = TextPainter(
          text: TextSpan(
            text: 'z',
            style: nunito(
              size: 9 + 4 * t + k * 2,
              weight: FontWeight.w800,
              color: const Color(0xFFF2E3CF).withValues(alpha: 1 - t),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        z.paint(canvas, minhoca.translate(20 + 6 * t, -12 - 16 * t));
      }
    }

    // --- o pote, no fundo ----------------------------------------------
    final pote = g.pote;
    final pulsa = abre > 0 ? 1.0 : 0.5 + 0.5 * math.sin(onda);
    canvas.drawCircle(
      pote,
      64,
      Paint()
        ..shader = RadialGradient(
          colors: [
            cor.withValues(alpha: 0.55 * (0.55 + 0.45 * pulsa)),
            cor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: pote, radius: 64)),
    );
    _desenhaPote(canvas, pote, pulsa);

    // --- o túnel ---------------------------------------------------------
    final fundo = s + (g.fundo - s) * profundidade;
    if (profundidade > 0) {
      const largura = 38.0;
      final tunel = RRect.fromRectAndCorners(
        Rect.fromLTRB(g.buraco - largura / 2, s - 2, g.buraco + largura / 2, fundo),
        bottomLeft: const Radius.circular(19),
        bottomRight: const Radius.circular(19),
      );
      // A borda de terra remexida, mais clara, em volta.
      canvas.drawRRect(tunel.inflate(4), _p(const Color(0xFFB08860)));
      canvas.drawRRect(
        tunel,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A3424), _tunel],
          ).createShader(tunel.outerRect),
      );
    }

    // A luz da abertura sobe pelo túnel até o céu.
    if (abre > 0) {
      final luz = Curves.easeOut.transform((abre / 0.5).clamp(0.0, 1.0));
      final topo = pote.dy - (pote.dy - s + 4) * luz;
      final feixe = Rect.fromLTRB(g.buraco - 18, topo, g.buraco + 18, pote.dy);
      canvas.drawRect(
        feixe,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.lerp(cor, Colors.white, 0.55)!.withValues(alpha: 0.95),
              Color.lerp(cor, Colors.white, 0.75)!.withValues(alpha: 0.5),
            ],
          ).createShader(feixe)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    canvas.restore();

    // A luz continua acima do chão, em leque, até o alto da cena.
    if (abre > 0) {
      final luz = Curves.easeOut.transform(((abre - 0.2) / 0.5).clamp(0.0, 1.0));
      final alfa = luz * (1 - ((abre - 0.7) / 0.3).clamp(0.0, 1.0) * 0.6);
      final leque = Path()
        ..moveTo(g.buraco - 16, s)
        ..lineTo(g.buraco - 16 - 70 * luz, s - s * luz)
        ..lineTo(g.buraco + 16 + 70 * luz, s - s * luz)
        ..lineTo(g.buraco + 16, s)
        ..close();
      canvas.drawPath(
        leque,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color.lerp(cor, Colors.white, 0.6)!.withValues(alpha: 0.75 * alfa),
              Color.lerp(cor, Colors.white, 0.8)!.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTRB(0, 0, w, s)),
      );
    }

    // --- a superfície ----------------------------------------------------
    // O monte de terra tirada, ao lado do buraco: cresce a cada pazada.
    final monteX = g.buraco + 48;
    final monte = 0.25 + 0.75 * profundidade;
    canvas.drawPath(
      Path()
        ..moveTo(monteX - 34 * monte, s + 1)
        ..quadraticBezierTo(monteX, s - 30 * monte, monteX + 34 * monte, s + 1)
        ..close(),
      _p(const Color(0xFF9A7049)),
    );
    for (final (dx, dy, raio) in [
      (-10.0, -6.0, 3.0),
      (6.0, -12.0, 2.4),
      (14.0, -4.0, 2.8),
    ]) {
      canvas.drawCircle(
        Offset(monteX + dx * monte, s + dy * monte),
        raio * monte + 0.6,
        _p(const Color(0xFF7A5638)),
      );
    }
    if (!comBicho) {
      // Sem bicho, uma pá fincada no monte diz "cava aqui".
      canvas.save();
      canvas.translate(monteX + 6, s - 18 * monte);
      canvas.rotate(0.35);
      canvas.drawLine(
        Offset.zero,
        const Offset(0, -46),
        Paint()
          ..color = const Color(0xFFA9774E)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -2, 18, 20),
          const Radius.circular(5),
        ),
        _p(const Color(0xFF9AA3A8)),
      );
      canvas.restore();
    }

    // A grama: uma faixa com folhinhas que balançam, aberta no buraco.
    final faixa = Paint()..color = _grama;
    final aberturaDoBuraco = profundidade > 0 ? 24.0 : 0.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(0, s - 6, g.buraco - aberturaDoBuraco, s + 6),
        const Radius.circular(6),
      ),
      faixa,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(g.buraco + aberturaDoBuraco, s - 6, w, s + 6),
        const Radius.circular(6),
      ),
      faixa,
    );
    final folha = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var x = 6.0; x < w; x += 13) {
      if ((x - g.buraco).abs() < aberturaDoBuraco + 6) continue;
      final ginga = math.sin(onda + x / 30) * 2;
      final alto = 7 + (x * 7 % 6);
      canvas.drawLine(
        Offset(x, s - 4),
        Offset(x + ginga, s - 4 - alto),
        folha..color = _gramaEscura,
      );
      canvas.drawLine(
        Offset(x + 4, s - 4),
        Offset(x + 6 + ginga, s - 2 - alto * 0.7),
        folha..color = _grama,
      );
    }
    // Duas florzinhas.
    for (final x in [w * 0.08, w * 0.9]) {
      final f = Offset(x, s - 18);
      canvas.drawLine(Offset(x, s - 4), f, folha..color = _gramaEscura);
      for (var k = 0; k < 5; k++) {
        final a = k * math.pi * 2 / 5 + onda * 0.1;
        canvas.drawCircle(
          f + Offset(math.cos(a), math.sin(a)) * 3.6,
          2.6,
          _p(x < w / 2 ? const Color(0xFFF6D776) : const Color(0xFFF2A7B8)),
        );
      }
      canvas.drawCircle(f, 2, _p(const Color(0xFFFFFFFF)));
    }

    // --- a terra voando --------------------------------------------------
    if (pazada > 0 && pazada < 1) {
      final rr = math.Random(3);
      for (var i = 0; i < 12; i++) {
        final ang = -math.pi / 2 + (rr.nextDouble() - 0.5) * 1.8;
        final forca = 70 + rr.nextDouble() * 60;
        final t = pazada;
        final x = g.buraco + math.cos(ang) * forca * t;
        final y = s - 4 + math.sin(ang) * forca * t + 160 * t * t;
        final tam = 2.2 + rr.nextDouble() * 3.4;
        canvas.drawCircle(
          Offset(x, y),
          tam * (1 - t * 0.4),
          _p(
            (i.isEven ? const Color(0xFF7A5638) : const Color(0xFF9A7049))
                .withValues(alpha: 1 - t * 0.6),
          ),
        );
      }
    }

    // --- o estouro da abertura -------------------------------------------
    if (abre > 0) {
      final t = Curves.easeOut.transform(abre);
      final ra = math.Random(11);
      final alfa = (1 - abre).clamp(0.0, 1.0);
      for (var i = 0; i < 20; i++) {
        final ang = -math.pi / 2 + (ra.nextDouble() - 0.5) * 2.6;
        final dist = (60 + ra.nextDouble() * 120) * t;
        final o = Offset(g.buraco, s) +
            Offset(math.cos(ang), math.sin(ang)) * dist +
            Offset(0, 50 * t * t);
        if (i % 3 == 0) {
          // Brilho em cruz.
          final b = Paint()
            ..color = Color.lerp(cor, Colors.white, 0.5)!.withValues(alpha: alfa)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(o.translate(-5, 0), o.translate(5, 0), b);
          canvas.drawLine(o.translate(0, -5), o.translate(0, 5), b);
        } else {
          // Folhinha girando.
          canvas.save();
          canvas.translate(o.dx, o.dy);
          canvas.rotate(ang + t * 6);
          canvas.drawPath(
            Path()
              ..moveTo(-5, 0)
              ..quadraticBezierTo(0, -4, 5, 0)
              ..quadraticBezierTo(0, 4, -5, 0)
              ..close(),
            _p((i.isEven ? Cores.folha500 : Cores.mel400).withValues(alpha: alfa)),
          );
          canvas.restore();
        }
      }
    }
  }

  void _desenhaPote(Canvas canvas, Offset c, double pulsa) {
    // Sombra no chão de terra.
    canvas.drawOval(
      Rect.fromCenter(center: c.translate(0, 24), width: 60, height: 10),
      _p(const Color(0x44000000)),
    );
    // O bojo.
    final bojo = Rect.fromCenter(center: c.translate(0, 4), width: 58, height: 44);
    canvas.drawOval(
      bojo,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 0.9,
          colors: [Color(0xFFE09469), _barro, _barroEscuro],
          stops: [0, 0.55, 1],
        ).createShader(bojo),
    );
    // A faixa decorada.
    canvas.drawArc(
      bojo.deflate(6),
      0.25,
      math.pi - 0.5,
      false,
      Paint()
        ..color = const Color(0xFFF2D4A8).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var k = 0; k < 5; k++) {
      final a = 0.55 + k * (math.pi - 1.1) / 4;
      canvas.drawCircle(
        bojo.center + Offset(math.cos(a) * 20, math.sin(a) * 13),
        1.6,
        _p(const Color(0xFFF2D4A8)),
      );
    }
    // A boca do pote, com a luz que escapa pela fresta.
    final boca = Rect.fromCenter(center: c.translate(0, -17), width: 34, height: 10);
    canvas.drawOval(boca, _p(_barroEscuro));
    canvas.drawOval(
      boca.deflate(2),
      _p(Color.lerp(cor, Colors.white, 0.6)!.withValues(alpha: 0.5 + 0.5 * pulsa)),
    );
    // A tampa: salta e gira na abertura.
    final salto = Curves.easeOut.transform((abre / 0.45).clamp(0.0, 1.0));
    canvas.save();
    canvas.translate(
      c.dx - 70 * salto,
      c.dy - 22 - 90 * salto + 120 * salto * salto,
    );
    canvas.rotate(-2.4 * salto);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 40, height: 12),
        const Radius.circular(6),
      ),
      _p(const Color(0xFFB05E3A)),
    );
    canvas.drawCircle(const Offset(0, -8), 4.5, _p(_barroEscuro));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -5, 18, 3),
        const Radius.circular(2),
      ),
      _p(const Color(0x55FFFFFF)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CorteDaTerra old) =>
      old.profundidade != profundidade ||
      old.pazada != pazada ||
      old.abre != abre ||
      old.ambiente != ambiente ||
      old.cor != cor ||
      old.g.tamanho != g.tamanho;
}

/// O dedo que mostra onde cavar, tocando o chão em ritmo.
class _Dedo extends StatelessWidget {
  const _Dedo({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final toque = math.sin(t * math.pi * 2);
    return Stack(
      alignment: Alignment.center,
      children: [
        // O anel do toque, abrindo.
        Transform.scale(
          scale: 0.6 + 0.6 * t,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Cores.superficie.withValues(alpha: (1 - t) * 0.9),
                width: 2.5,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(10, 14 + 6 * toque),
          child: Icon(
            Icons.touch_app_rounded,
            size: 34,
            color: Cores.superficie,
            shadows: [Shadow(color: Cores.tintaA(0.5), blurRadius: 6)],
          ),
        ),
      ],
    );
  }
}

/// As pazadas: três marcas, preenchidas a cada uma.
class _Marcas extends StatelessWidget {
  const _Marcas({required this.feitas, required this.cor});

  final int feitas;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espaco.sm,
        vertical: Espaco.xs,
      ),
      decoration: BoxDecoration(
        color: Cores.tintaA(0.35),
        borderRadius: Raio.todos(Raio.pilula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < Toca.precisaDe; i++) ...[
            if (i > 0) const SizedBox(width: Espaco.xxs),
            AnimatedContainer(
              duration: Tempo.componente,
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < feitas ? cor : Colors.transparent,
                border: Border.all(color: Cores.superficie, width: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Premio extends StatelessWidget {
  const _Premio({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.cor,
    required this.corDoRotulo,
  });

  final String rotulo;
  final Widget icone;
  final Color cor;
  final Color corDoRotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(Espaco.md),
          decoration: BoxDecoration(
            color: Cores.superficie,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: 34,
            child: IconTheme.merge(
              data: IconThemeData(size: 34, color: cor),
              child: Center(child: icone),
            ),
          ),
        ),
        const SizedBox(height: Espaco.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Espaco.sm,
            vertical: Espaco.xxs,
          ),
          decoration: BoxDecoration(
            color: Cores.tintaA(0.55),
            borderRadius: Raio.todos(Raio.pilula),
          ),
          child: Text(rotulo, style: estilo(Tipo.subtitulo, color: corDoRotulo)),
        ),
      ],
    );
  }
}
