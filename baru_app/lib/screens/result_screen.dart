import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final won = !app.aborted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 34),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PetView(
                  species: app.species,
                  mood: won ? Mood.radiant : Mood.missingYou,
                  activity: Activity.idle,
                  coat: app.color,
                  scale: 1.15,
                ),
                if (won) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 12, 22, 12),
                    decoration: BoxDecoration(
                      color: AppColors.orangeA(0.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LeafMark(size: 19, color: AppColors.orange),
                        const SizedBox(width: 11),
                        Text(
                          t.fill(t.reward, {'k': app.reward}),
                          style: nunito(size: 21, weight: FontWeight.w800, color: AppColors.orangeDeep),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  won
                      ? t.fill(t.resWon, {'m': app.sessionMinutes})
                      : t.fill(t.resLost, {'n': app.displayName}),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: nunito(size: 26, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
                ),
                const SizedBox(height: 10),
                Text(
                  won ? t.fill(t.resWonSub, {'n': app.displayName}) : t.resLostSub,
                  textAlign: TextAlign.center,
                  style: nunito(size: 15, height: 1.5, color: AppColors.inkA(0.68)),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(child: _stat(t.leavesLbl, '${app.leaves}')),
                    const SizedBox(width: 12),
                    Expanded(child: _stat(t.presentLbl, '${app.streak}')),
                  ],
                ),
              ],
            ),
          ),
          GhostButton(label: t.shareBtn, onTap: app.openShare, icon: Icons.share_outlined),
          const SizedBox(height: 10),
          PrimaryButton(label: t.back, onTap: app.voltar),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.inkA(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: nunito(size: 11, weight: FontWeight.w600, letterSpacing: 0.7, height: 1.3, color: AppColors.inkA(0.45))),
          const SizedBox(height: 8),
          Text(value, style: nunito(size: 24, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}
