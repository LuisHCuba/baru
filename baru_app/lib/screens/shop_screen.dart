import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 20),
          child: Row(
            children: [
              Text(t.shopT, style: nunito(size: 27, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
              const Spacer(),
              LeafBadge(leaves: app.leaves, filled: false),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shopItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, i) {
            final it = shopItems[i];
            final owned = app.owned.contains(it.id);
            final canBuy = !owned && app.leaves >= it.price;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inkA(0.045),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 62, child: ItemSwatch(it, maxW: 96, maxH: 58)),
                  const SizedBox(height: 10),
                  Text(
                    t.items[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: nunito(size: 14, weight: FontWeight.w700, height: 1.3),
                  ),
                  const Spacer(),
                  if (owned)
                    _btn(
                      t.shopOwned,
                      AppColors.greenA(0.16),
                      AppColors.greenHover,
                      icon: Icons.check_rounded,
                    )
                  else if (canBuy)
                    GestureDetector(
                      onTap: () => app.buy(it),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const LeafMark(size: 11, color: AppColors.cream),
                            const SizedBox(width: 7),
                            Text('${it.price}', style: nunito(size: 13, weight: FontWeight.w700, color: AppColors.cream)),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.inkA(0.06),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LeafMark(size: 11, color: AppColors.inkA(0.25)),
                          const SizedBox(width: 7),
                          Text('${it.price}', style: nunito(size: 13, weight: FontWeight.w700, color: AppColors.inkA(0.42))),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 20, 2, 24),
          child: Text(t.shopNote, style: nunito(size: 12.5, height: 1.5, color: AppColors.inkA(0.5))),
        ),
      ],
    );
  }

  Widget _btn(String label, Color bg, Color fg, {IconData? icon}) {
    return Container(
      height: 38,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nunito(size: 13, weight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
