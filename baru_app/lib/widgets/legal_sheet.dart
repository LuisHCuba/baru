import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

void showLegalSheet(
  BuildContext context, {
  required String title,
  required String body,
  required String close,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scroll) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(Espaco.xl, Espaco.md, Espaco.xl, Espaco.xl),
            child: Column(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.inkA(0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: Espaco.md),
                const AppIcon(Icons.article_outlined, size: 26, color: AppColors.green),
                const SizedBox(height: Espaco.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: nunito(
                    size: 23,
                    weight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: Espaco.md),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    children: [
                      Text(
                        body,
                        style: nunito(
                          size: 14.5,
                          height: 1.5,
                          color: Cores.tinta700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Espaco.sm),
                BotaoBaru(rotulo: close, aoTocar: () => Navigator.pop(ctx)),
              ],
            ),
          );
        },
      );
    },
  );
}
