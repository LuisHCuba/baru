import 'package:flutter/material.dart';

import '../l10n_humor.dart';
import '../models.dart';
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
      padding: const EdgeInsets.fromLTRB(Espaco.xl, Espaco.md, Espaco.xl, Espaco.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, Espaco.sm, 2, Espaco.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: t.back,
                child: GestureDetector(
                  onTap: app.voltar,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: AppIcon(Icons.arrow_back_rounded, size: 22),
                  ),
                ),
              ),
              Text(
                t.fill(t.repTitle, {'n': app.displayName}),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: nunito(size: 27, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.5),
              ),
              const SizedBox(height: 6),
              Text(t.repDate, style: nunito(size: 14, color: Cores.tinta700)),
            ],
          ),
        ),
        if (!app.usageAccess)
          SemTempoDeTela(app: app)
        else
        GestureDetector(
          onTap: () => app.go(AppScreen.tempo),
          behavior: HitTestBehavior.opaque,
          child: Container(
          padding: const EdgeInsets.all(Espaco.lg),
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
                        const SizedBox(height: Espaco.xxs),
                        Text(t.repUsed, style: nunito(size: 13, color: Cores.tinta700)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(app.fmt(app.goal), style: nunito(size: 16, weight: FontWeight.w700, color: Cores.tinta700)),
                      const SizedBox(height: Espaco.xxs),
                      Text(t.repGoal, style: nunito(size: 13, color: Cores.tinta700)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: Espaco.md),
              TrackFill(
                pct: usagePct,
                height: 14,
                color: app.underGoal ? AppColors.green : Cores.tinta500,
              ),
              const SizedBox(height: Espaco.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      app.usageVerdict,
                      style: nunito(size: 13.5, weight: FontWeight.w600, height: 1.45, color: app.underGoal ? Cores.folha700 : Cores.tinta700),
                    ),
                  ),
                  const Chevron(),
                ],
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: Espaco.md),
        Container(
          padding: const EdgeInsets.fromLTRB(Espaco.lg, Espaco.md, Espaco.lg, Espaco.md),
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
                    activity: app.atividadeForaDaAgua,
                    coat: app.color,
                    estagio: app.estagioVisivel,
                    roupas: app.roupasDoBicho,
                    roupaDeCabeca: app.roupaDeCabeca,
                  ),
                ),
              ),
              const SizedBox(width: Espaco.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // A mesma fala da home, com o fato e o número. Duas
                      // telas dizendo coisas diferentes sobre o mesmo dia é
                      // pior que uma delas dizer pouco.
                      app.frase(t.humorCap(app.falaDoHumor), app.falaDoHumor.valores),
                      style: nunito(size: 16.5, weight: FontWeight.w800, height: 1.3),
                    ),
                    const SizedBox(height: Espaco.xxs),
                    Text(
                      app.frase(t.humorSub(app.falaDoHumor), app.falaDoHumor.valores),
                      style: nunito(size: 13, height: 1.4, color: Cores.tinta700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Espaco.lg),
        _row(t.repSessions, '${app.completedToday}'),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _row(
          t.repBonus,
          app.underGoalQuestDone ? '+${AppState.underGoalBonus}' : '—',
          color: Cores.folha700,
        ),
        Divider(height: 1, color: AppColors.inkA(0.08)),
        _row(t.repPresent, app.streakText),
        Padding(
          padding: const EdgeInsets.fromLTRB(Espaco.xxs, Espaco.xxs, Espaco.xxs, Espaco.lg),
          child: Text(t.freezeNote(app.freezesLeft), style: nunito(size: 12.5, height: 1.5, color: Cores.tinta700)),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espaco.xxs, Espaco.md, Espaco.xxs, Espaco.md),
      child: Row(
        children: [
          Flexible(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: nunito(size: 15, weight: FontWeight.w600))),
          const SizedBox(width: Espaco.sm),
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
