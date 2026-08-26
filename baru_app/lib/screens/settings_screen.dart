import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/legal_sheet.dart';
import '../widgets/pet_profile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final goals = _goalChips(app.goal);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 20),
          child: Text(t.setT, style: nunito(size: 27, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.5)),
        ),
        const CompanionCard(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
          decoration: BoxDecoration(
            color: AppColors.greenA(0.10),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.trial
                          ? t.fill(t.planTrial, {'n': app.trialDaysLeft})
                          : t.planNone,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nunito(size: 16, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.trial
                          ? t.fill(t.planTrialSub, {'d': t.formatLongDate(app.paidPlanStart)})
                          : t.planNoneSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nunito(size: 13, height: 1.4, color: AppColors.inkA(0.6)),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => app.go(AppScreen.paywall),
                child: Text(t.setManage, style: nunito(size: 13.5, weight: FontWeight.w700, color: AppColors.green)),
              ),
            ],
          ),
        ),
        SectionLabel(t.setLang, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in langs)
              SelectChip(
                label: l.label,
                selected: app.lang == l.id,
                onTap: () => app.setLang(l.id),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
          ],
        ),
        SectionLabel(t.setGoal, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
        if (goals.length <= 4)
          Row(
            children: [
              for (var i = 0; i < goals.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                SelectChip(
                  label: app.fmt(goals[i]),
                  selected: app.goal == goals[i],
                  onTap: () => app.pickGoal(goals[i]),
                  expand: true,
                  height: 48,
                  radius: 14,
                  size: 13.5,
                ),
              ],
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in goals)
                SelectChip(
                  label: app.fmt(g),
                  selected: app.goal == g,
                  onTap: () => app.pickGoal(g),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
            ],
          ),
        SectionLabel(t.setNotif, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
        _toggleRow(t.setEvening, t.setEveningSub, app.evening, app.toggleEvening),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _toggleRow(t.setMissed, t.setMissedSub, app.missed, app.toggleMissed),
        SectionLabel(t.setUsage, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
        _toggleRow(
          t.permAllow,
          app.usageAccess ? t.setUsageOn : t.setUsageOff,
          app.usageAccess,
          app.toggleUsageAccess,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Text(
            t.setUsageHint,
            style: nunito(size: 12.5, height: 1.4, color: AppColors.inkA(0.5)),
          ),
        ),
        SectionLabel(t.setAbout, padding: const EdgeInsets.fromLTRB(4, 26, 4, 10)),
        _link(t.setRestore, app.restorePurchases, icon: Icons.restore_rounded),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _link(
          t.setPrivacy,
          () => showLegalSheet(
            context,
            title: t.setPrivacy,
            body: t.privacyBody,
            close: t.shareDone,
          ),
          icon: Icons.shield_outlined,
        ),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _link(
          t.setTerms,
          () => showLegalSheet(
            context,
            title: t.setTerms,
            body: t.termsBody,
            close: t.shareDone,
          ),
          icon: Icons.article_outlined,
        ),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _link(t.setReplay, app.restartOnboarding, muted: true, icon: Icons.replay_rounded),
        if (app.canSignOut) ...[
          Divider(height: 1, color: AppColors.inkA(0.08)),
          _link(t.authSignOut, app.signOut, muted: true, icon: Icons.logout_rounded),
        ],
        const SizedBox(height: 26),
      ],
    );
  }

  List<int> _goalChips(int current) {
    final out = [...goalOptions];
    if (!out.contains(current)) {
      out
        ..add(current)
        ..sort();
    }
    return out;
  }

  Widget _toggleRow(String title, String sub, bool on, VoidCallback tap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: nunito(size: 15, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: nunito(size: 12.5, height: 1.4, color: AppColors.inkA(0.5))),
              ],
            ),
          ),
          AppToggle(on: on, onTap: tap),
        ],
      ),
    );
  }

  Widget _link(String label, VoidCallback onTap, {bool muted = false, IconData? icon}) {
    final color = muted ? AppColors.inkA(0.5) : AppColors.ink;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 15, 4, 15),
          child: Row(
            children: [
              if (icon != null) ...[
                AppIcon(icon, size: 20, color: color),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nunito(size: 15, weight: FontWeight.w600, color: color),
                ),
              ),
              const SizedBox(width: 8),
              const Chevron(),
            ],
          ),
        ),
      ),
    );
  }
}
