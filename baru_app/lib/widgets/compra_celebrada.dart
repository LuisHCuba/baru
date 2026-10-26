/// A compra celebrada.
///
/// Comprar era um número que caía e um botão que mudava de rótulo: gastar
/// folhas sem resposta parecia erro (laudo 09, R1; laudo 05, R8). Agora o
/// item entra num cartão com mola, as folhas se espalham em volta, e a
/// pessoa escolhe: ver no habitat, ou seguir na loja.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n_loja.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'habitat.dart';
import 'loja_vitrine.dart';

Future<void> mostraCompraCelebrada(
  BuildContext context,
  AppState app,
  ShopItemDef item,
  LuzDaCena luz,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: app.t.compraSeguir,
    barrierColor: Cores.tintaA(0.55),
    transitionDuration: Movimento.duracao(context, Tempo.componente),
    pageBuilder: (contexto, _, __) => _CompraCelebrada(
      app: app,
      item: item,
      luz: luz,
    ),
  );
}

class _CompraCelebrada extends StatefulWidget {
  const _CompraCelebrada({
    required this.app,
    required this.item,
    required this.luz,
  });

  final AppState app;
  final ShopItemDef item;
  final LuzDaCena luz;

  static const chave = Key('compra-celebrada');

  @override
  State<_CompraCelebrada> createState() => _CompraCelebradaState();
}

class _CompraCelebradaState extends State<_CompraCelebrada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (Movimento.reduzido(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final t = app.t;
    final nome = t.nomeDoItemDaLoja(widget.item.id);
    final roupa = widget.item.categoria == CategoriaDeItem.roupa;
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final entra = Curves.easeOutBack.transform(_c.value.clamp(0.0, 1.0));
          return Transform.scale(
            scale: 0.7 + 0.3 * entra,
            child: Opacity(
              opacity: _c.value.clamp(0.0, 1.0),
              child: Material(
                key: _CompraCelebrada.chave,
                color: Cores.superficie,
                borderRadius: Raio.todos(Raio.folha),
                child: SizedBox(
                  width: 320,
                  child: Padding(
                    padding: const EdgeInsets.all(Espaco.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            MiniaturaDaLoja(
                              item: widget.item,
                              luz: widget.luz,
                              altura: 150,
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _Folhas(t: _c.value),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Espaco.md),
                        Text(t.compraT, style: estilo(Tipo.tituloGrande)),
                        const SizedBox(height: Espaco.xxs),
                        Text(
                          roupa
                              ? t.fill(t.compraSubRoupa, {'a': app.displayName})
                              : t.fill(t.compraSubObjeto, {'i': nome}),
                          textAlign: TextAlign.center,
                          style: estilo(
                            Tipo.corpo,
                            color: Cores.tinta700,
                          ),
                        ),
                        const SizedBox(height: Espaco.lg),
                        BotaoBaru(
                          rotulo: t.compraVer,
                          aoTocar: () {
                            Navigator.of(context).pop();
                            app.go(AppScreen.home);
                          },
                        ),
                        const SizedBox(height: Espaco.xs),
                        TextAction(
                          label: t.compraSeguir,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Folhas se abrindo em volta do item.
class _Folhas extends CustomPainter {
  _Folhas({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final c = size.center(Offset.zero);
    final abre = Curves.easeOutCubic.transform(t);
    final some = (1 - t).clamp(0.0, 1.0);
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2 + 0.3;
      final p = c + Offset(math.cos(a) * 130, math.sin(a) * 85) * abre;
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + t * 3);
      const s = 7.0;
      canvas.drawPath(
        Path()
          ..moveTo(-s, 0)
          ..quadraticBezierTo(0, -s * 0.7, s, 0)
          ..quadraticBezierTo(0, s * 0.7, -s, 0)
          ..close(),
        Paint()
          ..color = (i.isEven ? Cores.folha600 : Cores.mel400)
              .withValues(alpha: some),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Folhas old) => old.t != t;
}
