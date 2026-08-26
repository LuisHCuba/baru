import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final total = app.dur * 60;
    final pct = total == 0 ? 0.0 : ((total - app.remaining) / total).clamp(0.0, 1.0);
    final mm = (app.remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (app.remaining % 60).toString().padLeft(2, '0');
    return Stack(
      children: [
        ColoredBox(
          color: AppColors.sessionBg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 20, 26, 34),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    t.fill(t.sesLabel, {'m': app.dur}).toUpperCase(),
                    style: nunito(size: 12, weight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.inkA(0.45)),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PetView(
                        species: app.species,
                        mood: Mood.content,
                        activity: Activity.swim,
                        coat: app.color,
                        scale: 1.2,
                      ),
                      const SizedBox(height: 34),
                      Semantics(
                        liveRegion: true,
                        label: '$mm:$ss',
                        child: Text(
                          '$mm:$ss',
                          style: nunito(size: 66, weight: FontWeight.w800, height: 1, letterSpacing: -2, tabular: true),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.fill(t.activityLine, {'n': app.displayName}),
                        style: nunito(size: 15.5, color: AppColors.inkA(0.65)),
                      ),
                      const SizedBox(height: 34),
                      TrackFill(pct: pct, height: 8),
                    ],
                  ),
                ),
                TextAction(label: t.give, onTap: app.askQuit, height: 50),
              ],
            ),
          ),
        ),
        if (app.confirming) _QuitSheet(app: app),
      ],
    );
  }
}

class _QuitSheet extends StatelessWidget {
  const _QuitSheet({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.ink.withValues(alpha: 0.42),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 32, 26, 40),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PetView(
                species: app.species,
                mood: Mood.content,
                activity: Activity.swim,
                coat: app.color,
              ),
              const SizedBox(height: 16),
              Text(
                app.t.fill(app.t.quitTitle, {'n': app.displayName}),
                textAlign: TextAlign.center,
                style: nunito(size: 23, weight: FontWeight.w800, height: 1.25, letterSpacing: -0.3),
              ),
              const SizedBox(height: 8),
              Text(
                app.t.quitSub,
                textAlign: TextAlign.center,
                style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
              ),
              const SizedBox(height: 22),
              PrimaryButton(label: app.t.stay, onTap: app.resume),
              TextAction(label: app.t.leave, onTap: app.abandon),
            ],
          ),
        ),
      ),
    );
  }
}
