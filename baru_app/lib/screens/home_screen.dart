import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/habitat.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final next = app.nextItem;
    final usagePct = (app.usage / (app.goal * 1.35)).clamp(0.0, 1.0);
    final unlockPct = next == null ? 1.0 : (app.leaves / next.price).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      children: [
        Row(
          children: [
            LeafBadge(leaves: app.leaves),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.orangeA(0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppIcon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        app.streakText,
                        overflow: TextOverflow.ellipsis,
                        style: nunito(size: 13, weight: FontWeight.w700, color: AppColors.orangeText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.inkA(0.06),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    t.fill(t.level, {'n': 1 + app.owned.length ~/ 3}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nunito(size: 11.5, weight: FontWeight.w700, color: AppColors.inkA(0.55)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const HabitatScene(),
        const SizedBox(height: 20),
        Text(
          t.fill(t.moodCap(app.moodKey), {'n': app.displayName}),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: nunito(size: 26, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
        ),
        const SizedBox(height: 8),
        Text(
          t.moodSub(app.moodKey),
          style: nunito(size: 15, height: 1.5, color: AppColors.inkA(0.66)),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => app.go(AppScreen.report),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.greenA(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const AppIcon(Icons.insights, size: 16, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t.reportReady,
                    style: nunito(size: 13.5, weight: FontWeight.w700, color: AppColors.greenDeep),
                  ),
                ),
                const Chevron(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            children: [
              Row(
                children: [
                  Text(t.weekT.toUpperCase(), style: nunito(size: 11.5, weight: FontWeight.w600, letterSpacing: 0.8, color: AppColors.inkA(0.42))),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      app.streakText,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: nunito(size: 12.5, weight: FontWeight.w700, color: AppColors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: Column(
                        children: [
                          _dot(app.week[i]),
                          const SizedBox(height: 7),
                          Text(t.days[i], style: nunito(size: 10.5, weight: FontWeight.w600, color: AppColors.inkA(0.42))),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.fill(t.usageOf, {'u': app.fmt(app.usage), 'g': app.fmt(app.goal)}),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: nunito(size: 14, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      app.usageShortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: nunito(size: 13, weight: FontWeight.w600, color: AppColors.inkA(0.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TrackFill(
                pct: usagePct,
                color: app.underGoal ? AppColors.green : AppColors.orange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(19, 17, 19, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(t.questsT),
              const SizedBox(height: 6),
              _quest(t.quest1, '+10', app.completedToday >= 1),
              _quest(t.quest2, '+${AppState.underGoalBonus}', app.underGoalQuestDone),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(17, 15, 17, 15),
          onTap: () => app.go(AppScreen.shop),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.greenA(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: next == null ? null : ItemSwatch(next, maxW: 38, maxH: 34),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next == null
                          ? t.unlockDone
                          : t.fill(t.unlock, {
                              'x': (next.price - app.leaves).clamp(0, 9999),
                              'i': t.items[shopItems.indexOf(next)],
                            }),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nunito(size: 13.5, weight: FontWeight.w700, height: 1.35),
                    ),
                    const SizedBox(height: 9),
                    TrackFill(pct: unlockPct, height: 8, color: AppColors.green),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Chevron(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            for (var i = 0; i < durations.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              SelectChip(
                label: i == 3
                    ? t.custom
                    : (app.lang == 'zh'
                        ? '${durations[i]}分'
                        : '${durations[i]}${app.lang == 'en' ? 'm' : 'min'}'),
                selected: app.dur == durations[i],
                onTap: () => app.pickDur(durations[i]),
                expand: true,
                height: 46,
                radius: 14,
                size: 14,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: t.start,
          onTap: app.startSession,
          height: 64,
          radius: 22,
          weight: FontWeight.w800,
          size: 18,
          shadow: true,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _dot(WeekDayKind k) {
    switch (k) {
      case WeekDayKind.present:
        return Container(
          width: 13,
          height: 13,
          decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
        );
      case WeekDayKind.frozen:
        return Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.orange, width: 2),
          ),
        );
      case WeekDayKind.today:
        return Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: AppColors.greenA(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 2),
          ),
        );
      case WeekDayKind.empty:
        return Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: AppColors.inkA(0.13), shape: BoxShape.circle),
        );
    }
  }

  Widget _quest(String label, String reward, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          QuestMark(done: done),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: nunito(size: 14, weight: FontWeight.w600, height: 1.35))),
          Text(reward, style: nunito(size: 13, weight: FontWeight.w800, color: AppColors.orange)),
        ],
      ),
    );
  }
}
