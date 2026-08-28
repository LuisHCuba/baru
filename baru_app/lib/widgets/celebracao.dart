import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/som_service.dart';

import '../theme.dart';
import 'toca.dart';

/// Celebração de conquista: nível novo ou marco da trilha.
///
/// Silêncio depois de conquistar é falha de produto (§7). O usuário fez algo
/// difícil; a tela tem de reconhecer — com partícula, brilho e háptico, por
/// tempo contido, sem bloquear quem quer seguir.
class Celebracao extends StatefulWidget {
  const Celebracao({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.aoFechar,
    this.icone = Icons.auto_awesome_rounded,
    this.cor = Cores.acento,
    this.precisaCavar = false,
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback aoFechar;
  final IconData icone;
  final Color cor;

  /// A conquista sai da toca, e não aparece sozinha.
  ///
  /// Recompensa que chega pronta não é sentida: é o gesto que transforma
  /// "ganhei" em "eu tirei dali". Ligado em nível e marco da trilha, que
  /// **são** recompensas; desligado na saudação da chegada, que é um "bom
  /// te ver" e não um prêmio — fazer alguém cavar para receber um
  /// cumprimento seria pedágio.
  final bool precisaCavar;

  static const chave = Key('celebracao');
  static const chaveDaToca = Key('celebracao-toca');

  @override
  State<Celebracao> createState() => _CelebracaoState();
}

class _CelebracaoState extends State<Celebracao>
    with SingleTickerProviderStateMixin {
  /// `preserve`: com "reduzir movimento", a celebração encolhe de amplitude,
  /// mas não pode passar tão rápido que ninguém veja o que conquistou.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Tempo.celebracao,
    animationBehavior: AnimationBehavior.preserve,
  );

  final _particulas = List.generate(18, (i) {
    final sorte = math.Random(i * 977);
    return _Particula(
      angulo: (i / 18) * math.pi * 2 + sorte.nextDouble() * 0.3,
      distancia: 80 + sorte.nextDouble() * 90,
      tamanho: 4 + sorte.nextDouble() * 6,
      atraso: sorte.nextDouble() * 0.18,
    );
  });

  /// Já foi cavada (ou nunca precisou ser).
  late bool _aberta = !widget.precisaCavar;

  @override
  void initState() {
    super.initState();
    if (widget.precisaCavar) return;
    _explode();
  }

  void _explode() {
    HapticFeedback.heavyImpact();
    // O som acompanha o háptico: os dois marcam o mesmo instante.
    unawaited(SomService.instance.toca(SomDoBaru.conquista));
    _c.forward();
    // Fecha sozinha: conquista não pode virar bloqueio.
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted) widget.aoFechar();
        });
      }
    });
  }

  /// A cena de cavar, antes da conquista aparecer.
  ///
  /// Sem `onTap` de fechar no véu: quem está cavando não pode perder o
  /// prêmio por encostar fora do buraco.
  Widget _aToca() {
    return Positioned.fill(
      key: Celebracao.chave,
      child: ColoredBox(
        color: Cores.tintaA(0.82),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Espaco.margemTela),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.titulo,
                  textAlign: TextAlign.center,
                  style: estilo(Tipo.titulo, color: Cores.superficie),
                ),
                Toca(
                  key: Celebracao.chaveDaToca,
                  rotuloDoPremio: widget.subtitulo,
                  icone: widget.icone,
                  cor: widget.cor,
                  aoAbrir: () {
                    if (!mounted) return;
                    setState(() => _aberta = true);
                    _explode();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_aberta) return _aToca();
    final amplitude = Movimento.amplitude(context, 1);
    return Positioned.fill(
      key: Celebracao.chave,
      child: GestureDetector(
        onTap: widget.aoFechar,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final entrada = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
            return ColoredBox(
              // Véu forte: o texto é creme, e sobre fundo claro ele some.
              // Contraste é requisito, não gosto.
              color: Cores.tintaA(0.82 * (t * 2.2).clamp(0.0, 1.0)),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(300, 300),
                      painter: _Explosao(
                        t: t,
                        cor: widget.cor,
                        particulas: _particulas,
                        amplitude: amplitude,
                      ),
                    ),
                    Transform.scale(
                      scale: 0.7 + 0.3 * entrada,
                      child: Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: widget.cor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.cor.withValues(alpha: 0.5),
                                    blurRadius: 40 * amplitude,
                                    spreadRadius: 6 * amplitude,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icone,
                                size: 42,
                                color: Cores.tintaClara,
                              ),
                            ),
                            const SizedBox(height: Espaco.lg),
                            Text(
                              widget.titulo,
                              textAlign: TextAlign.center,
                              style: estilo(
                                Tipo.displayGrande,
                                color: Cores.tintaClara,
                              ),
                            ),
                            const SizedBox(height: Espaco.xs),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Espaco.xxl,
                              ),
                              child: Text(
                                widget.subtitulo,
                                textAlign: TextAlign.center,
                                style: estilo(
                                  Tipo.corpoGrande,
                                  color: Cores.tintaClara.withValues(alpha: 0.8),
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
            );
          },
        ),
      ),
    );
  }
}

class _Particula {
  const _Particula({
    required this.angulo,
    required this.distancia,
    required this.tamanho,
    required this.atraso,
  });

  final double angulo;
  final double distancia;
  final double tamanho;
  final double atraso;
}

class _Explosao extends CustomPainter {
  const _Explosao({
    required this.t,
    required this.cor,
    required this.particulas,
    required this.amplitude,
  });

  final double t;
  final Color cor;
  final List<_Particula> particulas;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    for (final p in particulas) {
      final avanco = ((t - p.atraso) / (1 - p.atraso)).clamp(0.0, 1.0);
      if (avanco <= 0) continue;
      final saida = Curves.easeOutQuart.transform(avanco);
      final some = (1 - avanco).clamp(0.0, 1.0);
      final d = p.distancia * saida * amplitude;
      canvas.drawCircle(
        centro + Offset(math.cos(p.angulo) * d, math.sin(p.angulo) * d),
        p.tamanho * some,
        Paint()..color = cor.withValues(alpha: 0.85 * some),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Explosao old) => old.t != t;
}
