import 'package:flutter/material.dart';

import '../l10n_loja.dart';
import '../models.dart';
import '../state.dart';
import 'trilha_screen.dart';
import '../theme.dart';
import '../widgets/raiz.dart';
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
        // Os dois números do topo levam a algum lugar. Eram os únicos do app
        // que mudavam sozinhos e não podiam ser tocados: o usuário via o
        // saldo subir e não tinha como saber de onde veio.
        Row(
          children: [
            Semantics(
              button: true,
              child: GestureDetector(
                onTap: () => app.go(AppScreen.folhas),
                behavior: HitTestBehavior.opaque,
                child: LeafBadge(leaves: app.leaves),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => app.go(AppScreen.sequencia),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    key: const Key('home-sequencia'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orangeA(0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // A raiz em miniatura, não a chama.
                        //
                        // Chama é vocabulário de outro app, e aqui o nome da
                        // contagem virou "raiz". Ver o mesmo desenho no
                        // topo da home e na tela da raiz é o que faz a
                        // pessoa reconhecer que são a mesma coisa.
                        SizedBox(
                          width: 12,
                          height: 18,
                          child: RaizViva(
                            dias: app.streak,
                            cor: AppColors.orange,
                            mostraTerra: false,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            app.streakText,
                            overflow: TextOverflow.ellipsis,
                            style: nunito(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.orangeText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const AppIcon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: AppColors.orangeText,
                        ),
                      ],
                    ),
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
          app.frase(t.moodSub(app.moodKey)),
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
          onTap: () => app.go(AppScreen.tempo),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.fill(t.usageOf, {'u': app.fmt(app.usage), 'g': app.fmt(app.goal)}),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nunito(size: 14, weight: FontWeight.w700, height: 1.35),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Chevron(),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  app.usageShortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nunito(size: 13, weight: FontWeight.w600, color: AppColors.inkA(0.5)),
                ),
              ),
              const SizedBox(height: 10),
              TrackFill(
                pct: usagePct,
                color: app.underGoal ? AppColors.green : AppColors.orange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Nível e XP de verdade, com a trilha a um toque.
        CartaoNivel(app: app, compacto: true),
        const SizedBox(height: 12),
        _ResumoDeMissoes(app: app),
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
                              // `nomeDoItemDaLoja` resolve por id e cai no
                              // catálogo antigo sozinho. O `nomeDoItem` de
                              // antes indexava por **posição** e devolvia o
                              // id cru para os 14 itens novos — a home
                              // diria "juncos" em vez de "Juncos da
                              // margem".
                              'i': t.nomeDoItemDaLoja(next.id),
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

}

/// As missões do dia em uma linha, com o que ainda dá para resgatar.
///
/// O cartão antigo mostrava duas quests com visto binário e um "+10" que nada
/// creditava. Este aponta para a tela onde elas existem de verdade.
class _ResumoDeMissoes extends StatelessWidget {
  const _ResumoDeMissoes({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final diarias = app.missoesDiarias;
    final feitas = diarias.where((m) => m.resgatada).length;
    final aResgatar = app.missoesResgataveis;

    return SoftCard(
      onTap: () => app.go(AppScreen.missoes),
      child: Row(
        children: [
          AppIcon(
            aResgatar > 0 ? Icons.redeem_rounded : Icons.flag_outlined,
            size: 18,
            color: aResgatar > 0 ? AppColors.orange : AppColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.missoesT,
                  style: nunito(size: 14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TrackFill(
                  pct: diarias.isEmpty ? 0 : feitas / diarias.length,
                  height: 8,
                  color: AppColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (aResgatar > 0)
            Etiqueta(
              texto: t.missaoResgatar,
              cor: AppColors.orange,
              forte: true,
            )
          else
            Text(
              '$feitas/${diarias.length}',
              style: nunito(
                size: 13,
                weight: FontWeight.w700,
                color: AppColors.inkA(0.5),
                tabular: true,
              ),
            ),
          const SizedBox(width: 6),
          const Chevron(),
        ],
      ),
    );
  }
}
