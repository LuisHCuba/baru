/// "Missão cumprida!": a comemoração de quando uma sessão fecha missões.
///
/// A missão fechava em silêncio — a barra chegava ao fim numa lista, e só
/// isso. No Duolingo, fechar uma missão é um momento: a tela inteira muda de
/// cor, a barra enche até estourar, o prêmio aparece e há um botão para
/// pegá-lo. Recompensa que não é vista não é sentida (laudo 01, U11), e o
/// dono do produto pediu este pop-up com todas as letras.
///
/// A sequência, em 2,6 s: a cena sobe; cada barra enche do ponto em que
/// estava até o fim; no fim, um estouro de brilho, o título e o toque no
/// aparelho; as recompensas entram uma a uma; por último, os botões.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../services/som_service.dart';
import '../theme.dart' show estilo, nunito;
import 'botao_baru.dart';
import 'glifos.dart';

/// Uma missão na cena: o nome, de onde a barra parte e o que ela paga.
class MissaoNaCena {
  const MissaoNaCena({
    required this.titulo,
    required this.de,
    required this.folhas,
    required this.xp,
  });

  final String titulo;

  /// 0..1: onde a barra estava antes da sessão.
  final double de;
  final int folhas;
  final int xp;
}

class CenaDaMissao extends StatefulWidget {
  const CenaDaMissao({
    super.key,
    required this.missoes,
    required this.bicho,
    required this.titulo,
    required this.rotuloColher,
    required this.rotuloDepois,
    required this.aoColher,
    required this.aoFechar,
  });

  final List<MissaoNaCena> missoes;

  /// O bicho da pessoa, radiante.
  final Widget bicho;
  final String titulo;
  final String rotuloColher;
  final String rotuloDepois;
  final VoidCallback aoColher;
  final VoidCallback aoFechar;

  static const chave = Key('cena-da-missao');
  static const chaveColher = Key('cena-da-missao-colher');

  @override
  State<CenaDaMissao> createState() => _CenaDaMissaoState();
}

class _CenaDaMissaoState extends State<CenaDaMissao>
    with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// Os raios de trás giram devagar enquanto a cena estiver aberta.
  late final AnimationController _raios = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  static const _cheia = 0.55;
  bool _estourou = false;

  @override
  void initState() {
    super.initState();
    _c.addListener(_marcaOEstouro);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimento.reduzido(context)) {
      // Sem a coreografia: a cena chega pronta, com o mesmo toque.
      _c.value = 1;
      _marcaOEstouro();
    } else {
      if (!_c.isAnimating && _c.value == 0) _c.forward();
      if (!_raios.isAnimating) _raios.repeat();
    }
  }

  void _marcaOEstouro() {
    if (_estourou || _c.value < _cheia) return;
    _estourou = true;
    HapticFeedback.heavyImpact();
    unawaited(SomService.instance.toca(SomDoBaru.marco));
  }

  @override
  void dispose() {
    _c.dispose();
    _raios.dispose();
    super.dispose();
  }

  double _faixa(double de, double ate) =>
      ((_c.value - de) / (ate - de)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final folhas = widget.missoes.fold<int>(0, (s, m) => s + m.folhas);
    final xp = widget.missoes.fold<int>(0, (s, m) => s + m.xp);
    return Positioned.fill(
      key: CenaDaMissao.chave,
      // A tela de baixo some para o leitor de tela enquanto a cena estiver
      // na frente.
      child: BlockSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _raios]),
          builder: (context, _) {
            final entra = Curves.easeOutBack.transform(_faixa(0, 0.16));
            final titulo = Curves.easeOutBack.transform(_faixa(_cheia, 0.70));
            final botoes = _faixa(0.86, 1);
            return Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        Cores.mel400,
                        Colors.white,
                        0.25,
                      )!.withValues(alpha: _faixa(0, 0.1)),
                      Cores.mel400.withValues(alpha: _faixa(0, 0.1)),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Espaco.lg,
                      Espaco.lg,
                      Espaco.lg,
                      Espaco.md,
                    ),
                    // Os botões ficam sempre à vista, embaixo; o resto rola se não
                    // couber. Em 360×640 com duas ou três missões o "Colher"
                    // ia para fora da tela (auditoria da Onda 4, M2).
                    child: Column(
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) => SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: c.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // O bicho, pulando de alegria, sobre os raios.
                                    SizedBox(
                                      height: c.maxHeight < 480 ? 130 : 190,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        clipBehavior: Clip.none,
                                        children: [
                                          CustomPaint(
                                            size: const Size(320, 320),
                                            painter: _Raios(
                                              giro: _raios.value * math.pi * 2,
                                              forca: _faixa(0.05, 0.3),
                                            ),
                                          ),
                                          CustomPaint(
                                            size: const Size(320, 320),
                                            painter: _Estouro(
                                              t: _faixa(_cheia, 0.95),
                                            ),
                                          ),
                                          Transform.translate(
                                            offset: Offset(
                                              0,
                                              -18 *
                                                  math.max(
                                                    0,
                                                    math.sin(
                                                      _faixa(_cheia, 0.9) *
                                                          math.pi *
                                                          3,
                                                    ),
                                                  ),
                                            ),
                                            child: Transform.scale(
                                              scale: 0.5 + 0.5 * entra,
                                              child: widget.bicho,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: Espaco.md),
                                    Opacity(
                                      opacity: titulo.clamp(0.0, 1.0),
                                      child: Transform.scale(
                                        scale: 0.6 + 0.4 * titulo,
                                        child: Text(
                                          widget.titulo,
                                          textAlign: TextAlign.center,
                                          style: estilo(Tipo.display),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: Espaco.lg),
                                    for (final (i, m) in widget.missoes.indexed)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: Espaco.sm,
                                        ),
                                        child: Opacity(
                                          opacity: entra.clamp(0.0, 1.0),
                                          child: _CartaoDaMissao(
                                            missao: m,
                                            fracao:
                                                m.de +
                                                (1 - m.de) *
                                                    Curves.easeInOutCubic
                                                        .transform(
                                                          _faixa(
                                                            0.16 + i * 0.05,
                                                            _cheia,
                                                          ),
                                                        ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: Espaco.sm),
                                    // As recompensas, uma de cada vez.
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _Premio(
                                          t: Curves.easeOutBack.transform(
                                            _faixa(0.66, 0.78),
                                          ),
                                          icone: const GlifoFolha(tamanho: 22),
                                          texto: '+$folhas',
                                          cor: Cores.folha700,
                                        ),
                                        const SizedBox(width: Espaco.sm),
                                        _Premio(
                                          t: Curves.easeOutBack.transform(
                                            _faixa(0.74, 0.86),
                                          ),
                                          icone: const GlifoXp(tamanho: 20),
                                          texto: '+$xp XP',
                                          cor: Cores.mel700,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: Espaco.sm),
                        IgnorePointer(
                          ignoring: botoes < 1,
                          child: Opacity(
                            opacity: botoes,
                            child: Column(
                              children: [
                                BotaoBaru(
                                  key: CenaDaMissao.chaveColher,
                                  rotulo: widget.rotuloColher,
                                  aoTocar: widget.aoColher,
                                  icone: const GlifoFolha(
                                    tamanho: 20,
                                    cor: Cores.tintaClara,
                                  ),
                                ),
                                const SizedBox(height: Espaco.xs),
                                Semantics(
                                  button: true,
                                  child: GestureDetector(
                                    onTap: widget.aoFechar,
                                    behavior: HitTestBehavior.opaque,
                                    child: SizedBox(
                                      height: 48,
                                      child: Center(
                                        child: Text(
                                          widget.rotuloDepois,
                                          style: nunito(
                                            size: 15,
                                            weight: FontWeight.w700,
                                            color: Cores.tinta,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CartaoDaMissao extends StatelessWidget {
  const _CartaoDaMissao({required this.missao, required this.fracao});

  final MissaoNaCena missao;
  final double fracao;

  @override
  Widget build(BuildContext context) {
    final cheia = fracao >= 0.999;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espaco.md,
        Espaco.sm,
        Espaco.md,
        Espaco.sm,
      ),
      decoration: BoxDecoration(
        color: Cores.superficieElevada,
        borderRadius: Raio.todos(Raio.cartao),
        boxShadow: Elevacao.cartaoElevado,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missao.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.corpoForte),
                ),
                const SizedBox(height: Espaco.xs),
                ClipRRect(
                  borderRadius: Raio.todos(Raio.pilula),
                  child: SizedBox(
                    height: 12,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Cores.trilho),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: fracao.clamp(0.0, 1.0),
                          child: const ColoredBox(color: Cores.folha600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Espaco.sm),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cheia ? Cores.folha600 : Cores.trilho,
            ),
            child: cheia
                ? const Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: Cores.tintaClara,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Premio extends StatelessWidget {
  const _Premio({
    required this.t,
    required this.icone,
    required this.texto,
    required this.cor,
  });

  final double t;
  final Widget icone;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: t.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.4 + 0.6 * t,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Espaco.md,
            vertical: Espaco.xs,
          ),
          decoration: BoxDecoration(
            color: Cores.superficieElevada,
            borderRadius: Raio.todos(Raio.pilula),
            boxShadow: Elevacao.cartao,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icone,
              const SizedBox(width: Espaco.xs),
              Text(
                texto,
                style: estilo(
                  Tipo.subtitulo,
                  color: cor,
                  tabular: true,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Raios claros girando atrás do bicho.
class _Raios extends CustomPainter {
  _Raios({required this.giro, required this.forca});
  final double giro;
  final double forca;

  @override
  void paint(Canvas canvas, Size size) {
    if (forca <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.width * 0.5;
    final p = Paint()..color = Colors.white.withValues(alpha: 0.32 * forca);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(giro);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi * 2 / 12;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a - 0.11) * r, math.sin(a - 0.11) * r)
          ..lineTo(math.cos(a + 0.11) * r, math.sin(a + 0.11) * r)
          ..close(),
        p,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      c,
      r * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55 * forca),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.42)),
    );
  }

  @override
  bool shouldRepaint(covariant _Raios old) =>
      old.giro != giro || old.forca != forca;
}

/// O estouro quando a barra enche: folhas e estrelinhas para todo lado.
class _Estouro extends CustomPainter {
  _Estouro({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final sorte = math.Random(7);
    final some = 1 - t;
    for (var i = 0; i < 22; i++) {
      final a = i * math.pi * 2 / 22 + sorte.nextDouble() * 0.3;
      final d = (60 + sorte.nextDouble() * 110) * Curves.easeOut.transform(t);
      final p = c + Offset(math.cos(a) * d, math.sin(a) * d + 40 * t * t);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(t * 6 * (i.isEven ? 1 : -1));
      if (i % 3 == 0) {
        canvas.drawCircle(
          Offset.zero,
          3.5,
          Paint()..color = Colors.white.withValues(alpha: some),
        );
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(-7, 0)
            ..quadraticBezierTo(0, -6, 7, 0)
            ..quadraticBezierTo(0, 6, -7, 0)
            ..close(),
          Paint()
            ..color = (i.isEven ? Cores.folha500 : Cores.folha600).withValues(
              alpha: some,
            ),
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _Estouro old) => old.t != t;
}
