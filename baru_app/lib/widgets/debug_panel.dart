import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

class DebugFab extends StatelessWidget {
  const DebugFab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return FloatingActionButton.small(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.cream,
      onPressed: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.cream,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
          ),
          builder: (_) => const DebugPanel(),
        );
      },
      child: const AppIcon(Icons.bug_report_outlined, size: 18, color: AppColors.cream),
    );
  }
}

class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.inkA(0.055),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG PANEL · DEBUG BUILDS ONLY',
              style: TextStyle(
                fontFamily: 'Menlo',
                fontFamilyFallback: const ['Consolas', 'ui-monospace', 'monospace'],
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: AppColors.inkA(0.45),
              ),
            ),
            const SizedBox(height: 14),
            Text('Force mood', style: nunito(size: 12, weight: FontWeight.w600, color: AppColors.inkA(0.6))),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in Mood.values)
                  _chip(
                    m.name == 'missingYou' ? 'missing_you' : m.name,
                    app.overrideMood == m,
                    () => app.forceMood(m),
                  ),
                _chip('auto', app.overrideMood == null, () => app.forceMood(null)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Habitat / species', style: nunito(size: 12, weight: FontWeight.w600, color: AppColors.inkA(0.6))),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in habitats.keys)
                  _chip(
                    'habitat $k',
                    app.owned.length == habitats[k]!.length,
                    () => app.setHabitat(k),
                  ),
                for (final s in Species.values)
                  _chip(
                    s.name,
                    app.species == s,
                    () => app.setSpecies(s),
                    green: true,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Usage ${app.fmt(app.usage)}', style: nunito(size: 12, weight: FontWeight.w600, color: AppColors.inkA(0.6))),
                _chip('−30m', false, app.usageDown),
                _chip('+30m', false, app.usageUp),
                _chip('advance day', false, app.nextDay),
                _chip('+200 leaves', false, app.grantLeaves),
                _chip('reset', false, app.resetAll),
                _chip(app.debugFast ? 'timer 60×' : 'timer 1×', app.debugFast, app.toggleDebugFast),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'O timer roda a 60× no modo debug: uma sessão de 25 minutos termina em ~25 segundos.',
              style: nunito(size: 11.5, height: 1.5, color: AppColors.inkA(0.45)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback tap, {bool green = false}) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: on
              ? (green ? AppColors.green : AppColors.ink)
              : (green ? AppColors.greenA(0.14) : AppColors.inkA(0.08)),
          borderRadius: BorderRadius.circular(AppRadii.debug),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Menlo',
            fontFamilyFallback: const ['Consolas', 'ui-monospace', 'monospace'],
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: on ? AppColors.cream : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
