import 'package:flutter/material.dart';

import '../l10n_missoes.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'app_icons.dart';
import 'arte_dos_itens.dart';
import 'componentes.dart';
import 'glifos.dart';

export 'app_frame.dart';
export 'app_icons.dart';
export 'botao_baru.dart';
export 'componentes.dart';
export 'glifos.dart';

class _Hover extends StatefulWidget {
  const _Hover({required this.builder, this.onTap});

  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final live = widget.onTap != null;
    return MouseRegion(
      onEnter: live ? (_) => setState(() => hover = true) : null,
      onExit: live ? (_) => setState(() => hover = false) : null,
      cursor: live ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.builder(hover),
      ),
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
                color: color ?? Cores.tinta700,
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
          color: color ?? Cores.tinta700,
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
            const GlifoFolha(),
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
  const OnbDots({
    super.key,
    required this.step,
    this.total = 6,
    this.fracaoDoAtual = 1,
  });

  final int step;
  final int total;

  /// O quanto do passo atual já foi andado, de 0 a 1.
  ///
  /// Existe porque o passo do quiz tem seis perguntas dentro dele: sem isto,
  /// a barra ficava parada em seis telas seguidas e a pessoa não via que
  /// estava avançando.
  final double fracaoDoAtual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: List.generate(total, (i) {
          final cheio = i < step;
          final atual = i == step;
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: AppColors.inkA(0.13),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: cheio
                    ? 1
                    : atual
                        ? fracaoDoAtual.clamp(0.0, 1.0)
                        : 0,
                child: AnimatedContainer(
                  duration: Tempo.componente,
                  curve: Curvas.padrao,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
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
    // Roupa e cenário não têm peças de cena: `reduce` numa lista vazia
    // estoura. Quem quiser desenhá-los usa a miniatura da loja.
    if (item.parts.isEmpty) {
      return SizedBox(
        width: maxW,
        height: maxH,
        child: Center(
          child: Icon(
            item.categoria == CategoriaDeItem.roupa
                ? Icons.checkroom_rounded
                : Icons.wb_twilight_rounded,
            size: 30,
            color: item.cor ?? Cores.tinta500,
          ),
        ),
      );
    }
    final caixa = caixaDaArte(item.id, item.parts);
    final k = [maxW / caixa.width, maxH / caixa.height, 1.0]
        .reduce((a, b) => a < b ? a : b);
    return SizedBox(
      width: maxW,
      height: maxH,
      child: Center(
        child: SizedBox(
          width: caixa.width * k,
          height: caixa.height * k,
          child: CustomPaint(painter: _AmostraDoItem(item, caixa, k)),
        ),
      ),
    );
  }
}

/// A arte do objeto, sozinha, enquadrada na caixa dela.
class _AmostraDoItem extends CustomPainter {
  const _AmostraDoItem(this.item, this.caixa, this.k);

  final ShopItemDef item;
  final Rect caixa;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(k);
    canvas.translate(-caixa.left, -caixa.top);
    pintaItem(canvas, item.id, item.parts);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AmostraDoItem old) =>
      old.item != item || old.k != k;
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
            // O que está pronto para colher aparece na aba, de qualquer
            // tela: prêmio parado sem ninguém ver é prêmio perdido.
            final aColher =
                ids[i] == AppScreen.missoes ? app.missoesResgataveis : 0;
            if (aColher > 0) garanteTextosDeMissoes();
            return Expanded(
              child: Semantics(
                button: true,
                selected: on,
                label: aColher > 0
                    ? '${app.t.tabs[i]}, '
                        '${app.t.fill(app.t.mqQuantasColher, {'n': aColher})}'
                    : app.t.tabs[i],
                child: GestureDetector(
                  onTap: () => app.go(ids[i]),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AppIcon(
                                on ? tabGlyphs[i].on : tabGlyphs[i].off,
                                size: 22,
                                color:
                                    on ? AppColors.green : Cores.tinta500,
                              ),
                              if (aColher > 0)
                                Positioned(
                                  key: const Key('aba-missoes-a-colher'),
                                  right: -9,
                                  top: -5,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Cores.mel400,
                                      borderRadius: BorderRadius.circular(99),
                                      border: Border.all(
                                        color: AppColors.cream,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      '$aColher',
                                      style: nunito(
                                        size: 10,
                                        weight: FontWeight.w800,
                                        color: Cores.tinta,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                            color: on ? AppColors.green : Cores.tinta700,
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

/// O lugar do tempo de tela quando não há acesso ao uso.
///
/// O contrato (§8) é claro: sem permissão o app não estima nem inventa. A
/// home e o relatório mostravam "0min de 4h30" e "4h30 abaixo da meta" —
/// um número que ninguém mediu (simulador da Fase 4, alto 1).
class SemTempoDeTela extends StatelessWidget {
  const SemTempoDeTela({super.key, required this.app});

  final AppState app;

  static const chave = Key('sem-tempo-de-tela');

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    return SoftCard(
      key: chave,
      muted: true,
      onTap: () => app.go(AppScreen.tempo),
      child: Row(
        children: [
          const AppIcon(Icons.lock_clock_outlined, size: 22, color: Cores.tinta500),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.telaSemPermissaoT, style: estilo(Tipo.corpoForte)),
                const SizedBox(height: 2),
                Text(
                  t.telaSemPermissaoB,
                  style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
                ),
              ],
            ),
          ),
          const SizedBox(width: Espaco.xs),
          const Chevron(),
        ],
      ),
    );
  }
}
