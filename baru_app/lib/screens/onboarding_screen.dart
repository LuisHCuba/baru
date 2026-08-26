import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';
import '../widgets/pet_profile.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 34),
      child: Column(
        children: [
          OnbDots(step: app.onb),
          Expanded(child: _step(app)),
          const SizedBox(height: 8),
          _cta(app),
        ],
      ),
    );
  }

  Widget _step(AppState app) {
    switch (app.onb) {
      case 0:
        return _lang(app);
      case 1:
        return _promise(app);
      case 2:
        return _quiz(app);
      case 3:
        return _reveal(app);
      case 4:
        return _goal(app);
      default:
        return _perm(app);
    }
  }

  Widget _cta(AppState app) {
    if (app.onb == 0) {
      return PrimaryButton(label: app.t.cont, onTap: app.nextOnb);
    }
    if (app.onb == 1) {
      return PrimaryButton(label: app.t.start, onTap: app.nextOnb);
    }
    if (app.onb == 2) {
      return PrimaryButton(
        label: app.quizDone ? app.t.quizCta : app.t.quizWait,
        onTap: app.quizDone ? app.nextOnb : null,
        enabled: app.quizDone,
      );
    }
    if (app.onb == 3) {
      return PrimaryButton(label: app.t.revealCta, onTap: app.nextOnb);
    }
    if (app.onb == 4) {
      return PrimaryButton(label: app.t.goalCta, onTap: app.nextOnb);
    }
    return Column(
      children: [
        PrimaryButton(
          label: app.t.permAllow,
          onTap: () => app.requestUsageAccessFromOnboarding(),
        ),
        TextAction(label: app.t.permLater, onTap: app.skipUsage),
      ],
    );
  }

  Widget _lang(AppState app) {
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          app.t.langTitle,
          style: nunito(size: 30, weight: FontWeight.w800, height: 1.15, letterSpacing: -0.6),
        ),
        const SizedBox(height: 12),
        Text(
          app.t.langSub,
          style: nunito(size: 15, height: 1.5, color: AppColors.inkA(0.68)),
        ),
        const SizedBox(height: 26),
        for (final l in langs) ...[
          GestureDetector(
            onTap: () => app.setLang(l.id),
            child: Container(
              height: 60,
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                color: app.lang == l.id ? AppColors.greenA(0.14) : AppColors.inkA(0.05),
                borderRadius: BorderRadius.circular(18),
                border: app.lang == l.id
                    ? Border.all(color: AppColors.green, width: 2.5)
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    l.label,
                    style: nunito(
                      size: 18,
                      weight: app.lang == l.id ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (app.lang == l.id) ...[
                    const AppIcon(Icons.check_rounded, size: 18, color: AppColors.green),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    l.tag,
                    style: nunito(
                      size: 13,
                      weight: FontWeight.w700,
                      color: app.lang == l.id ? AppColors.green : AppColors.inkA(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
            ),
          ),
        );
      },
    );
  }

  Widget _promise(AppState app) {
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PetView(
          species: app.species,
          mood: Mood.content,
          activity: Activity.idle,
          coat: app.color,
          scale: 1.15,
        ),
        const SizedBox(height: 26),
        Text(
          app.t.promiseT,
          textAlign: TextAlign.center,
          style: nunito(size: 29, weight: FontWeight.w800, height: 1.15, letterSpacing: -0.6),
        ),
        const SizedBox(height: 14),
        Text(
          app.t.promiseB,
          textAlign: TextAlign.center,
          style: nunito(size: 15.5, height: 1.5, color: AppColors.inkA(0.7)),
        ),
      ],
            ),
          ),
        );
      },
    );
  }

  Widget _quiz(AppState app) {
    final answers = [app.q0, app.q1, app.q2];
    return ListView(
      padding: const EdgeInsets.only(top: 26),
      children: [
        Text(
          app.t.quizT,
          style: nunito(size: 25, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
        ),
        const SizedBox(height: 10),
        Text(
          app.t.quizB,
          style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 3; i++) ...[
          SectionLabel(app.t.quizQ[i]),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in app.t.quizO[i])
                SelectChip(
                  label: o,
                  selected: answers[i] == o,
                  onTap: () => app.pickQuiz(i, o),
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _reveal(AppState app) {
    final sp = app.t.species(app.speciesKey);
    return ListView(
      padding: const EdgeInsets.only(top: 24),
      children: [
        SectionLabel(app.t.revealKicker, color: AppColors.green),
        const SizedBox(height: 10),
        Text(
          sp[0],
          textAlign: TextAlign.center,
          style: nunito(size: 27, weight: FontWeight.w800, height: 1.15, letterSpacing: -0.5),
        ),
        const SizedBox(height: 9),
        Text(
          sp[1],
          textAlign: TextAlign.center,
          style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
        ),
        const SizedBox(height: 16),
        Center(
          child: PetView(
            species: app.species,
            mood: Mood.radiant,
            activity: Activity.idle,
            coat: app.color,
          ),
        ),
        const SizedBox(height: 16),
        PetNameField(
          key: ValueKey(app.speciesKey),
          initial: app.displayName,
          onChanged: app.setName,
        ),
        const SizedBox(height: 18),
        CoatPicker(
          selected: app.color,
          onPick: app.setColor,
          label: app.t.coat,
        ),
      ],
    );
  }

  Widget _goal(AppState app) {
    return ListView(
      padding: const EdgeInsets.only(top: 40),
      children: [
        Text(
          app.t.goalT,
          style: nunito(size: 25, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
        ),
        const SizedBox(height: 10),
        Text(
          app.t.goalB,
          style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            for (var i = 0; i < avgOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 9),
              SelectChip(
                label: app.fmt(avgOptions[i]),
                selected: app.avg == avgOptions[i],
                onTap: () => app.pickAvg(avgOptions[i]),
                expand: true,
                height: 54,
                radius: 16,
                size: 15,
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.greenA(0.10),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(app.t.goalSug, color: AppColors.green),
              const SizedBox(height: 6),
              Text(
                app.fmt(app.goal),
                style: nunito(size: 38, weight: FontWeight.w800, letterSpacing: -1, height: 1.1),
              ),
              const SizedBox(height: 6),
              Text(
                app.t.goalNote,
                style: nunito(size: 13.5, height: 1.5, color: AppColors.inkA(0.65)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _perm(AppState app) {
    return ListView(
      padding: const EdgeInsets.only(top: 34),
      children: [
        Text(
          app.t.permT,
          style: nunito(size: 25, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
        ),
        const SizedBox(height: 10),
        Text(
          app.t.permB,
          style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
        ),
        const SizedBox(height: 22),
        for (final line in [app.t.perm1, app.t.perm2, app.t.perm3])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(line, style: nunito(size: 14.5, height: 1.45)),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.inkA(0.05),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            app.t.permTech,
            style: nunito(size: 12.5, height: 1.5, color: AppColors.inkA(0.6)).copyWith(
              fontFamily: 'Menlo',
            ),
          ),
        ),
      ],
    );
  }
}
