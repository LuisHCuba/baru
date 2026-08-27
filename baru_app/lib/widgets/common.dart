import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'app_icons.dart';
import 'componentes.dart';

export 'app_frame.dart';
export 'app_icons.dart';
export 'componentes.dart';

class _Hover extends StatefulWidget {
  const _Hover({required this.builder, this.onTap, this.enabled = true});

  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final live = widget.enabled && widget.onTap != null;
    return MouseRegion(
      onEnter: live ? (_) => setState(() => hover = true) : null,
      onExit: live ? (_) => setState(() => hover = false) : null,
      cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: widget.builder(hover),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 56,
    this.radius = 20,
    this.weight = FontWeight.w700,
    this.size = 17,
    this.shadow = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final FontWeight weight;
  final double size;
  final bool shadow;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _Hover(
      enabled: enabled,
      onTap: onTap,
      builder: (hover) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: height,
          decoration: BoxDecoration(
            color: enabled
                ? (hover ? AppColors.greenHover : AppColors.green)
                : AppColors.inkA(0.07),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: enabled && shadow ? AppShadows.cta : null,
          ),
          alignment: Alignment.center,
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nunito(
                size: size,
                weight: weight,
                color: enabled ? AppColors.cream : AppColors.inkA(0.4),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 54,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _Hover(
      onTap: onTap,
      builder: (hover) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: height,
          decoration: BoxDecoration(
            color: AppColors.inkA(hover ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          alignment: Alignment.center,
          child: Semantics(
            button: true,
            label: label,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  AppIcon(icon!, size: 18),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nunito(size: 16, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TextAction extends StatelessWidget {
  const TextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 48,
    this.color,
  });

  final String label;
  final VoidCallback onTap;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: Center(
          child: Semantics(
            button: true,
            label: label,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nunito(
                size: 15,
                weight: FontWeight.w600,
                color: color ?? AppColors.inkA(0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.radius = 14,
    this.size = 14,
    this.expand = false,
    this.height,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final double radius;
  final double size;
  final bool expand;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final child = _Hover(
      onTap: onTap,
      builder: (hover) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: height,
          padding: height == null ? padding : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.ink
                : AppColors.inkA(hover ? 0.11 : 0.06),
            borderRadius: BorderRadius.circular(radius),
          ),
          alignment: Alignment.center,
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: nunito(
                size: size,
                weight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? AppColors.cream : AppColors.ink,
              ),
            ),
          ),
        );
      },
    );
    return expand ? Expanded(child: child) : child;
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color, this.padding});

  final String text;
  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text.toUpperCase(),
        style: nunito(
          size: 11.5,
          weight: FontWeight.w600,
          letterSpacing: 0.8,
          color: color ?? AppColors.inkA(0.42),
        ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(19, 17, 19, 17),
    this.onTap,
    this.muted = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    Widget box({bool hover = false}) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: padding,
        decoration: BoxDecoration(
          color: muted
              ? AppColors.inkA(hover ? 0.07 : 0.045)
              : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: muted ? null : Border.all(color: AppColors.inkA(0.085)),
          boxShadow: muted ? null : AppShadows.card,
        ),
        child: child,
      );
    }

    if (onTap == null) return box();
    return _Hover(onTap: onTap, builder: (hover) => box(hover: hover));
  }
}

class LeafMark extends StatelessWidget {
  const LeafMark({super.key, this.size = 15, this.color = AppColors.green});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(size * 0.53),
          topRight: Radius.circular(size * 0.13),
          bottomRight: Radius.circular(size * 0.53),
          bottomLeft: Radius.circular(size * 0.13),
        ),
      ),
    );
  }
}

/// O saldo de folhas.
///
/// O número **sobe animado**: recompensa que troca de valor sem transição some
/// da percepção. O usuário resgata uma missão e precisa ver as folhas
/// chegarem, não descobrir depois que o número mudou.
class LeafBadge extends StatelessWidget {
  const LeafBadge({
    super.key,
    required this.leaves,
    this.filled = true,
  });

  final int leaves;
  final bool filled;

  static const chave = Key('saldo-de-folhas');

  @override
  Widget build(BuildContext context) {
    return Container(
      key: chave,
      padding: const EdgeInsets.fromLTRB(11, 8, 14, 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.card : AppColors.greenA(0.13),
        borderRadius: BorderRadius.circular(99),
        border: filled ? Border.all(color: AppColors.inkA(0.085)) : null,
        boxShadow: filled ? AppShadows.card : null,
      ),
      child: Semantics(
        label: '$leaves',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(child: LeafMark()),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: ContadorAnimado(
                valor: leaves,
                estiloTexto: nunito(size: 15, weight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppToggle extends StatelessWidget {
  const AppToggle({super.key, required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 51,
          height: 31,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: on ? AppColors.green : AppColors.inkA(0.18),
            borderRadius: BorderRadius.circular(99),
          ),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TrackFill extends StatelessWidget {
  const TrackFill({
    super.key,
    required this.pct,
    this.height = 10,
    this.color = AppColors.green,
  });

  final double pct;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.inkA(0.09),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: pct.clamp(0, 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnbDots extends StatelessWidget {
  const OnbDots({super.key, required this.step, this.total = 6});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: List.generate(total, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= step ? AppColors.green : AppColors.inkA(0.13),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ItemSwatch extends StatelessWidget {
  const ItemSwatch(this.item, {super.key, this.maxW = 96, this.maxH = 58});

  final ShopItemDef item;
  final double maxW;
  final double maxH;

  @override
  Widget build(BuildContext context) {
    final xs = item.parts.map((p) => p.x);
    final ys = item.parts.map((p) => p.y);
    final x0 = xs.reduce((a, b) => a < b ? a : b);
    final y0 = ys.reduce((a, b) => a < b ? a : b);
    final bw = item.parts.map((p) => p.x + p.w).reduce((a, b) => a > b ? a : b) - x0;
    final bh = item.parts.map((p) => p.y + p.h).reduce((a, b) => a > b ? a : b) - y0;
    final k = [maxW / bw, maxH / bh, 1.0].reduce((a, b) => a < b ? a : b);
    return SizedBox(
      width: maxW,
      height: maxH,
      child: Center(
        child: Transform.scale(
          scale: k,
          child: SizedBox(
            width: bw,
            height: bh,
            child: Stack(
              children: [
                for (final p in item.parts)
                  Positioned(
                    left: p.x - x0,
                    top: p.y - y0,
                    child: Container(
                      width: p.w,
                      height: p.h,
                      decoration: BoxDecoration(
                        color: p.c,
                        borderRadius: BorderRadius.circular(p.r),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BottomTabs extends StatelessWidget {
  const BottomTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Quatro destinos, na ordem em que o produto pensa: onde o bicho mora,
    // para onde a coisa vai, onde se gasta, e onde se ajusta. O relatório é
    // alcançado pelo cartão da home, e o detalhamento de tempo pelo cartão de
    // uso — nenhum deles é destino de primeiro nível.
    final ids = [
      AppScreen.home,
      AppScreen.trilha,
      AppScreen.missoes,
      AppScreen.profile,
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: AppColors.inkA(0.08))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(4, (i) {
            final on = app.screen == ids[i];
            return Expanded(
              child: Semantics(
                button: true,
                selected: on,
                label: app.t.tabs[i],
                child: GestureDetector(
                  onTap: () => app.go(ids[i]),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: AppIcon(
                            on ? tabGlyphs[i].on : tabGlyphs[i].off,
                            size: 22,
                            color: on ? AppColors.green : AppColors.inkA(0.4),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          app.t.tabs[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: nunito(
                            size: 10.5,
                            weight: FontWeight.w700,
                            color: on ? AppColors.green : AppColors.inkA(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
