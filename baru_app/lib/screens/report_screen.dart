import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final usagePct = (app.usage / (app.goal * 1.35)).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.fill(t.repTitle, {'n': app.displayName}),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: nunito(size: 27, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(t.repDate, style: nunito(size: 14, color: AppColors.inkA(0.55))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.inkA(0.045),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.fmt(app.usage), style: nunito(size: 25, weight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(t.repUsed, style: nunito(size: 13, color: AppColors.inkA(0.55))),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(app.fmt(app.goal), style: nunito(size: 16, weight: FontWeight.w700, color: AppColors.inkA(0.6))),
                      const SizedBox(height: 4),
                      Text(t.repGoal, style: nunito(size: 13, color: AppColors.inkA(0.45))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TrackFill(
                pct: usagePct,
                height: 14,
                color: app.underGoal ? AppColors.green : AppColors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                app.usageVerdict,
                style: nunito(size: 13.5, weight: FontWeight.w600, height: 1.45, color: AppColors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          decoration: BoxDecoration(
            color: AppColors.greenA(0.10),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: 69,
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  child: PetView(
                    species: app.species,
                    mood: app.mood,
                    activity: app.activity,
                    coat: app.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.fill(t.moodCap(app.moodKey), {'n': app.displayName}),
                      style: nunito(size: 16.5, weight: FontWeight.w800, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.moodLbl(app.moodKey),
                      style: nunito(size: 13, height: 1.4, color: AppColors.inkA(0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _row(t.repSessions, '${app.completedToday}'),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _row(t.repBonus, app.underGoalQuestDone ? '+15' : '—', color: AppColors.orange),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _row(t.repPresent, app.streakText),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 22),
          child: Text(t.freezeNote(app.freezesLeft), style: nunito(size: 12.5, height: 1.5, color: AppColors.inkA(0.5))),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
      child: Row(
        children: [
          Flexible(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: nunito(size: 15, weight: FontWeight.w600))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: nunito(size: 15, weight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
