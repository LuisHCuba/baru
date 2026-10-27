import 'package:flutter/material.dart';

import '../l10n_humor.dart';
import '../l10n_loja.dart';
import '../data/crescimento.dart';
import '../models.dart';
import '../state.dart';
import 'trilha_screen.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/crescimento.dart';
import '../widgets/habitat.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    // A primeira home: ninguém focou ainda. Recebe, explica o que vem e põe
    // a ação à vista; relatório e semana esperam ter o que mostrar.
    final primeira = app.sessoesConcluidas == 0 &&
        app.completedToday == 0 &&
        app.sessions.isEmpty &&
        app.streak == 0 &&
        app.daysAway == 0 &&
        !app.abandonedToday;
    final next = app.nextItem;
    final fala = app.falaDoHumor;
    final usagePct = (app.usage / (app.goal * 1.35)).clamp(0.0, 1.0);
    final unlockPct = next == null ? 1.0 : (app.leaves / next.price).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Espaco.lg, Espaco.md, Espaco.lg, Espaco.sm),
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
            const SizedBox(width: Espaco.xs),
            Expanded(
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => app.go(AppScreen.sequencia),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    key: const Key('home-sequencia'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Espaco.md,
                      vertical: Espaco.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Cores.raiz500.withValues(alpha: 0.10),
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
                        // O glifo da raiz, o mesmo do relatório e do cartão.
                        // A raiz viva desenhada em 12 px virava um rabisco
                        // (lido como "tênis" na auditoria visual).
                        const GlifoRaiz(tamanho: 18),
                        const SizedBox(width: Espaco.xs),
                        Flexible(
                          child: Text(
                            app.streakText,
                            overflow: TextOverflow.ellipsis,
                            style: nunito(
                              size: 13,
                              weight: FontWeight.w700,
                              color: Cores.raiz600,
                            ),
                          ),
                        ),
                        const SizedBox(width: Espaco.xxs),
                        const AppIcon(
                          Icons.chevron_right_rounded,
                          size: 15,
                          color: Cores.raiz600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Espaco.md),
        // Em tela baixa (640 dp) a cena de 372 empurrava o "Começar foco"
        // para baixo da dobra (simulador da Onda 4). Ela encolhe até 40% da
        // altura, sem passar do tamanho de sempre.
        HabitatScene(
          height: (MediaQuery.sizeOf(context).height * 0.40)
              .clamp(240.0, HabitatScene.alturaPadrao),
        ),
        const SizedBox(height: Espaco.sm),
        // O crescimento do bicho, logo abaixo dele: quanto falta e o que vem.
        const BarraDoCrescimento(),
        const SizedBox(height: Espaco.md),
        // A legenda diz **o fato** que levou o bicho àquele humor, com o
        // número que o app mediu, e só depois o sentimento. Antes vinha de
        // `moodCap`/`moodSub`: um texto por humor, sempre igual, que dizia
        // "sentiu sua falta" sem dizer se a pessoa sumiu três dias ou se
        // desistiu de uma sessão. Ver `lib/l10n_humor.dart`.
        //
        // `frase` resolve pronome e valores no mesmo passo; separar em dois
        // `fill` deixaria `{P}` cru quando a fala tem número e pronome.
        Text(
          primeira
              ? t.fill(t.s('homeBoasVindasT'), {'n': app.displayName})
              : app.frase(t.humorCap(fala), fala.valores),
          key: const Key('home-humor-cap'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: nunito(size: 26, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
        ),
        const SizedBox(height: Espaco.xs),
        Text(
          primeira
              ? t.s(Crescimento.botaOvo(app.species)
                  ? 'homeBoasVindasOvo'
                  : 'homeBoasVindasNinho')
              : app.frase(t.humorSub(fala), fala.valores),
          key: const Key('home-humor-sub'),
          style: nunito(size: 15, height: 1.5, color: Cores.tinta700),
        ),
        // A ação do app logo depois da fala, em qualquer dia. No fim da
        // lista — depois do relatório, da semana e da loja — ela sumia da
        // tela a partir da segunda sessão (simulador da Onda 4).
        const SizedBox(height: Espaco.md),
        ..._secaoDeFoco(app),
        if (!primeira) const SizedBox(height: Espaco.xl),
        if (!primeira)
        GestureDetector(
          onTap: () => app.go(AppScreen.report),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Espaco.md, vertical: Espaco.sm),
            decoration: BoxDecoration(
              color: AppColors.greenA(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const AppIcon(Icons.insights, size: 16, color: AppColors.green),
                const SizedBox(width: Espaco.sm),
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
        if (!primeira) const SizedBox(height: Espaco.sm),
        if (!primeira)
        SoftCard(
          child: Column(
            children: [
              Row(
                children: [
                  Text(t.weekT.toUpperCase(), style: nunito(size: 11.5, weight: FontWeight.w600, letterSpacing: 0.8, color: Cores.tinta700)),
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
              const SizedBox(height: Espaco.md),
              Row(
                children: [
                  for (final (i, marca) in app.ultimos7Dias)
                    Expanded(
                      child: Column(
                        children: [
                          _dot(marca),
                          const SizedBox(height: Espaco.xs),
                          Text(t.days[i], style: nunito(size: 10.5, weight: FontWeight.w600, color: Cores.tinta700)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Espaco.sm),
        // Sem o acesso ao uso não há número: o cartão não mostra "0min de
        // 4h30", que é medição inventada (§8; simulador, alto 1).
        if (!app.usageAccess)
          SemTempoDeTela(app: app)
        else
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
              const SizedBox(height: Espaco.xxs),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  app.usageShortLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: nunito(size: 13, weight: FontWeight.w600, color: Cores.tinta700),
                ),
              ),
              const SizedBox(height: Espaco.sm),
              TrackFill(
                pct: usagePct,
                // Acima da meta é neutro, nunca alarme (laudo 03 §4.4).
                color: app.underGoal ? AppColors.green : Cores.tinta500,
              ),
            ],
          ),
        ),
        const SizedBox(height: Espaco.sm),
        // Nível e XP de verdade, com a trilha a um toque.
        CartaoNivel(app: app, compacto: true),
        const SizedBox(height: Espaco.sm),
        _ResumoDeMissoes(app: app),
        const SizedBox(height: Espaco.sm),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.md, Espaco.md, Espaco.md),
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
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next == null
                          ? t.unlockDone
                          // Com as folhas já na mão, "faltam 0 folhas" era
                          // a frase errada: o certo é dizer que dá.
                          : app.leaves >= next.price
                              ? t.fill(t.s('unlockPronto'),
                                  {'i': t.nomeDoItemDaLoja(next.id)})
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
                    const SizedBox(height: Espaco.xs),
                    TrackFill(pct: unlockPct, height: 8, color: AppColors.green),
                  ],
                ),
              ),
              const SizedBox(width: Espaco.xs),
              const Chevron(),
            ],
          ),
        ),
        const SizedBox(height: Espaco.md),
      ],
    );
  }

  /// A duração e o "Começar foco". Na primeira home ficam logo abaixo do
  /// bicho: com eles no fim da lista, quem acabou o onboarding precisava
  /// rolar para achar a única ação que importa (simulador da Fase 4, 14).
  List<Widget> _secaoDeFoco(AppState app) {
    final t = app.t;
    return [
            Row(
              children: [
                for (var i = 0; i < durations.length; i++) ...[
                  if (i > 0) const SizedBox(width: Espaco.xs),
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
            const SizedBox(height: Espaco.sm),
            BotaoBaru(
              rotulo: t.start,
              aoTocar: app.startSession,
              altura: 64,
              tamanhoDoTexto: 18,
            ),
    ];
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
            border: Border.all(color: Cores.ceu600, width: 2),
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
            color: aResgatar > 0 ? Cores.mel700 : AppColors.green,
          ),
          const SizedBox(width: Espaco.sm),
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
          const SizedBox(width: Espaco.sm),
          if (aResgatar > 0)
            Etiqueta(
              texto: t.missaoResgatar,
              cor: Cores.mel400,
              forte: true,
            )
          else
            Text(
              '$feitas/${diarias.length}',
              style: nunito(
                size: 13,
                weight: FontWeight.w700,
                color: Cores.tinta700,
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
