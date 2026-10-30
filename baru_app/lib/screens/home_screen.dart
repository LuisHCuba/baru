import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n_humor.dart';
import '../l10n_loja.dart';
import '../l10n_missoes.dart';
import '../data/crescimento.dart';
import '../models.dart';
import '../state.dart';
import 'trilha_screen.dart';
import '../theme.dart';
import '../widgets/acesso.dart';
import '../widgets/common.dart';
import '../widgets/crescimento.dart';
import '../widgets/mundo/mundo.dart';

/// A home é o mundo dele.
///
/// A tela inteira é o lugar onde ele vive (`MundoDoBaru`), e a interface
/// fica nas bordas, o mínimo possível (pesquisa 23):
///
/// * **No alto, um indicador só**: a raiz e as folhas, juntas, no canto —
///   informação, como a posição e o mapa nos cantos do Mario Kart (NN/g,
///   heurística 8 aplicada a jogos).
/// * **No meio, o mundo**: o que se faz com ele se faz nele — carinho no
///   bicho, a bola e o pote de petiscos no chão (diegético). Nada de botão
///   flutuando por cima da cena.
/// * **Embaixo, um painel só**: a alça do "Seu dia" (o resto do dia, um
///   nível abaixo — divulgação progressiva), a única ação da tela, "Começar
///   foco" com a duração no mesmo botão (botão dividido do Material 3), e
///   as abas, que só navegam (Apple HIG, Tab bars). É o padrão do acessório
///   preso à barra de abas, como o MiniPlayer do Music.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const seuDiaKey = Key('home-seu-dia');
  static const balaoKey = Key('home-balao');
  static const indicadorKey = Key('home-indicador');

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cabeca = ValueNotifier<Offset?>(null);
  bool _balaoAberto = true;
  Timer? _recolheBalao;

  /// A fala que o balão mostrou por último: quando ela muda, ele volta.
  String? _falaMostrada;
  bool _estavaCoberta = false;

  /// Disse o que tinha a dizer: o balão some e o mundo fica limpo. Não fica
  /// um ícone de conversa preso na cabeça dele — era mais um botão sobre a
  /// cena. Volta quando a fala muda ou quando se volta à home.
  void _mostraBalao() {
    _balaoAberto = true;
    _recolheBalao?.cancel();
    _recolheBalao = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _balaoAberto = false);
    });
  }

  @override
  void dispose() {
    _recolheBalao?.cancel();
    _cabeca.dispose();
    super.dispose();
  }

  bool _primeira(AppState app) =>
      app.sessoesConcluidas == 0 &&
      app.completedToday == 0 &&
      app.sessions.isEmpty &&
      app.streak == 0 &&
      app.daysAway == 0 &&
      !app.abandonedToday;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final pad = MediaQuery.paddingOf(context);
    final tela = MediaQuery.sizeOf(context);
    final primeira = _primeira(app);
    final fala = app.falaDoHumor;
    final cap = primeira
        ? t.fill(t.s('homeBoasVindasT'), {'n': app.displayName})
        : app.frase(t.humorCap(fala), fala.valores);
    final sub = primeira
        ? t.s(
            Crescimento.botaOvo(app.species)
                ? 'homeBoasVindasOvo'
                : 'homeBoasVindasNinho',
          )
        : app.frase(t.humorSub(fala), fala.valores);
    // Voltando de uma tela de detalhe (a home ficou por baixo, viva), ele
    // fala de novo; coberta, o relógio do balão para (auditoria).
    final atual = ModalRoute.isCurrentOf(context) ?? true;
    if (!atual) {
      _recolheBalao?.cancel();
    } else if (_estavaCoberta || _falaMostrada != '$cap|$sub') {
      _falaMostrada = '$cap|$sub';
      _mostraBalao();
    }
    _estavaCoberta = !atual;

    return Stack(
      fit: StackFit.expand,
      children: [
        MundoDoBaru(cabecaNaTela: _cabeca),

        // --- no alto: o indicador, num canto -------------------------------
        Positioned(
          top: pad.top + Espaco.sm,
          right: Espaco.md,
          child: _Indicador(app: app),
        ),

        // --- a reta final do teste, por cima do habitat --------------------
        // Abaixo do indicador: ele declara `minHeight: 44`, e é esse o vão.
        Positioned(
          top: pad.top + Espaco.sm + 44 + Espaco.sm,
          left: Espaco.md,
          right: Espaco.md,
          child: FaixaDoTeste(t: t),
        ),

        // --- a fala dele, num balão junto da cabeça ------------------------
        Positioned.fill(
          child: ValueListenableBuilder<Offset?>(
            valueListenable: _cabeca,
            builder: (context, o, _) {
              if (o == null || o.dx < -40 || o.dx > tela.width + 40) {
                return const SizedBox.shrink();
              }
              const largura = 236.0;
              final esquerda = (o.dx - largura * 0.3).clamp(
                12.0,
                tela.width - largura - 12,
              );
              return Stack(
                children: [
                  Positioned(
                    left: esquerda,
                    width: largura,
                    bottom: tela.height - o.dy + 6,
                    // Um toque dispensa a fala antes da hora.
                    child: IgnorePointer(
                      ignoring: !_balaoAberto,
                      child: AnimatedOpacity(
                        opacity: _balaoAberto ? 1 : 0,
                        duration: Tempo.componente,
                        child: GestureDetector(
                          onTap: () {
                            _recolheBalao?.cancel();
                            setState(() => _balaoAberto = false);
                          },
                          child: _Balao(
                            key: HomeScreen.balaoKey,
                            titulo: cap,
                            texto: sub,
                            pontaEm: (o.dx - esquerda).clamp(
                              24.0,
                              largura - 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// O que fica preso em cima das abas na home: a alça do "Seu dia" e a ação
/// da tela. Vive na mesma superfície das abas ([BottomTabs.acima]), para
/// que o pé da tela seja um painel só, e não três camadas de botões.
class AcessorioDaHome extends StatelessWidget {
  const AcessorioDaHome({super.key, required this.navegador});

  static const duracaoKey = Key('home-duracao');

  /// O painel mora na casca, fora do `Navigator` das telas: as folhas abrem
  /// pelo contexto dele.
  final GlobalKey<NavigatorState> navegador;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    if (app.missoesResgataveis > 0) garanteTextosDeMissoes();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A alça: tocar ou puxar para cima abre o resto do dia.
        Semantics(
          button: true,
          // O pontinho de "tem prêmio" também se ouve (auditoria, 6).
          label: app.missoesResgataveis > 0
              ? '${t.seuDia}, '
                    '${t.fill(t.mqQuantasColher, {'n': app.missoesResgataveis})}'
              : t.seuDia,
          child: GestureDetector(
            key: HomeScreen.seuDiaKey,
            behavior: HitTestBehavior.opaque,
            onTap: _abreSeuDia,
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) < -150) _abreSeuDia();
            },
            child: SizedBox(
              height: 34,
              width: double.infinity,
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Cores.tinta.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.seuDia,
                          style: nunito(
                            size: 12,
                            weight: FontWeight.w800,
                            color: Cores.tinta700,
                          ),
                        ),
                        if (app.missoesResgataveis > 0) ...[
                          const SizedBox(width: Espaco.xxs),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Cores.mel400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.md,
            Espaco.xxs,
            Espaco.md,
            Espaco.xs,
          ),
          // Botão dividido: a ação e, colada nela, a escolha que a muda.
          child: Row(
            children: [
              Expanded(
                child: BotaoBaru(rotulo: t.start, aoTocar: app.startSession),
              ),
              const SizedBox(width: Espaco.xs),
              Semantics(
                label: t.duracaoT,
                child: BotaoBaru(
                  key: duracaoKey,
                  papel: PapelDoBotao.secundario,
                  expande: false,
                  icone: const Icon(Icons.timer_outlined, size: 18),
                  rotulo: _rotuloDaDuracao(app, app.dur),
                  aoTocar: () {
                    final c = navegador.currentContext;
                    if (c != null) _escolheDuracao(c, app);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Sem o contexto do `Navigator` não há onde abrir a folha: o da casca
  // fica fora dele (auditoria, 7).
  void _abreSeuDia() {
    final c = navegador.currentContext;
    if (c != null) SeuDia.abre(c);
  }

  static String _rotuloDaDuracao(AppState app, int min) =>
      app.lang == 'zh' ? '$min分' : '$min${app.lang == 'en' ? 'm' : 'min'}';

  static void _escolheDuracao(BuildContext context, AppState app) {
    app.comFolhaDaHome(
      () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Cores.superficie,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (context) => AppScope(
          state: app,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Espaco.lg,
              Espaco.lg,
              Espaco.lg,
              Espaco.xl + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.t.duracaoT,
                  style: nunito(size: 18, weight: FontWeight.w800),
                ),
                const SizedBox(height: Espaco.md),
                Row(
                  children: [
                    for (var i = 0; i < durations.length; i++) ...[
                      if (i > 0) const SizedBox(width: Espaco.xs),
                      SelectChip(
                        label: i == 3
                            ? app.t.custom
                            : _rotuloDaDuracao(app, durations[i]),
                        selected: app.dur == durations[i],
                        onTap: () {
                          app.pickDur(durations[i]);
                          Navigator.of(context).pop();
                        },
                        expand: true,
                        height: 46,
                        radius: 14,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A raiz e as folhas, juntas, num canto: o placar dele. Cada metade leva
/// à sua tela.
class _Indicador extends StatelessWidget {
  const _Indicador({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final estilo = nunito(size: 14, weight: FontWeight.w800, tabular: true);
    Widget metade({
      required String rotulo,
      required VoidCallback aoTocar,
      required Widget glifo,
      required Widget numero,
      required EdgeInsets padding,
    }) => Semantics(
      button: true,
      label: rotulo,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: aoTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: padding,
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [glifo, const SizedBox(width: 5), numero],
              ),
            ),
          ),
        ),
      ),
    );
    return Vidro(
      key: HomeScreen.indicadorKey,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          metade(
            rotulo: app.streakText,
            aoTocar: () => app.go(AppScreen.sequencia),
            glifo: const GlifoRaiz(tamanho: 18),
            numero: Text('${app.streak}', style: estilo),
            padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
          ),
          Container(
            width: 1,
            height: 18,
            color: Cores.tinta.withValues(alpha: 0.12),
          ),
          metade(
            rotulo: '${app.leaves} ${app.t.leavesLbl}',
            aoTocar: () => app.go(AppScreen.folhas),
            glifo: const GlifoFolha(tamanho: 17),
            numero: ContadorAnimado(valor: app.leaves, estiloTexto: estilo),
            padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          ),
        ],
      ),
    );
  }
}

/// Vidro fosco: o fundo do mundo aparece por trás, desfocado.
class Vidro extends StatelessWidget {
  const Vidro({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.cor,
    this.raio = 999,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? cor;
  final double raio;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(raio),
        boxShadow: [
          BoxShadow(
            color: Cores.tinta.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(raio),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            color: cor ?? Cores.superficieElevada.withValues(alpha: 0.74),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A fala do humor, num balão com a ponta na cabeça dele.
class _Balao extends StatelessWidget {
  const _Balao({
    super.key,
    required this.titulo,
    required this.texto,
    required this.pontaEm,
  });

  final String titulo;
  final String texto;
  final double pontaEm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          decoration: BoxDecoration(
            color: Cores.superficieElevada.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Cores.tinta.withValues(alpha: 0.14),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                titulo,
                key: const Key('home-humor-cap'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: nunito(size: 15, weight: FontWeight.w800, height: 1.25),
              ),
              const SizedBox(height: 3),
              Text(
                texto,
                key: const Key('home-humor-sub'),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: nunito(size: 13, height: 1.35, color: Cores.tinta700),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: pontaEm - 8),
          child: CustomPaint(
            size: const Size(16, 9),
            painter: _PontaDoBalao(
              Cores.superficieElevada.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }
}

class _PontaDoBalao extends CustomPainter {
  const _PontaDoBalao(this.cor);

  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width * 0.35, size.height)
        ..close(),
      Paint()..color = cor,
    );
  }

  @override
  bool shouldRepaint(_PontaDoBalao old) => old.cor != cor;
}

/// O resto do dia, numa folha que sobe da home: crescimento, relatório,
/// semana, tempo de tela, nível, missões e o próximo item da loja.
class SeuDia extends StatelessWidget {
  const SeuDia({super.key, required this.app});

  final AppState app;

  static Future<void> abre(BuildContext context) {
    final app = AppScope.of(context);
    return app.comFolhaDaHome(
      () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AppScope(
          state: app,
          child: _FechaAoSair(
            app: app,
            child: DraggableScrollableSheet(
              initialChildSize: 0.72,
              minChildSize: 0.4,
              maxChildSize: 0.94,
              expand: false,
              builder: (context, rolagem) => Container(
                decoration: const BoxDecoration(
                  color: Cores.superficie,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListenableBuilder(
                  listenable: app,
                  builder: (context, _) => ListView(
                    controller: rolagem,
                    padding: EdgeInsets.fromLTRB(
                      Espaco.lg,
                      Espaco.sm,
                      Espaco.lg,
                      Espaco.xl + MediaQuery.paddingOf(context).bottom,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: Espaco.md),
                          decoration: BoxDecoration(
                            color: Cores.tinta.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      SeuDia(app: app),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _primeira =>
      app.sessoesConcluidas == 0 &&
      app.completedToday == 0 &&
      app.sessions.isEmpty &&
      app.streak == 0 &&
      app.daysAway == 0 &&
      !app.abandonedToday;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final primeira = _primeira;
    final next = app.nextItem;
    final usagePct = (app.usage / (app.goal * 1.35)).clamp(0.0, 1.0);
    final unlockPct = next == null
        ? 1.0
        : (app.leaves / next.price).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(t.seuDia, style: nunito(size: 22, weight: FontWeight.w800)),
        const SizedBox(height: Espaco.md),
        const BarraDoCrescimento(),
        const SizedBox(height: Espaco.md),
        if (!primeira)
          GestureDetector(
            onTap: () => app.go(AppScreen.report),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Espaco.md,
                vertical: Espaco.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.greenA(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const AppIcon(
                    Icons.insights,
                    size: 16,
                    color: AppColors.green,
                  ),
                  const SizedBox(width: Espaco.sm),
                  Expanded(
                    child: Text(
                      t.reportReady,
                      style: nunito(
                        size: 13.5,
                        weight: FontWeight.w700,
                        color: AppColors.greenDeep,
                      ),
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
                    Text(
                      t.weekT.toUpperCase(),
                      style: nunito(
                        size: 11.5,
                        weight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Cores.tinta700,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        app.streakText,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: nunito(
                          size: 12.5,
                          weight: FontWeight.w700,
                          color: AppColors.green,
                        ),
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
                            Text(
                              t.days[i],
                              style: nunito(
                                size: 10.5,
                                weight: FontWeight.w600,
                                color: Cores.tinta700,
                              ),
                            ),
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
                        t.fill(t.usageOf, {
                          'u': app.fmt(app.usage),
                          'g': app.fmt(app.goal),
                        }),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: nunito(
                          size: 14,
                          weight: FontWeight.w700,
                          height: 1.35,
                        ),
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
                    style: nunito(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Cores.tinta700,
                    ),
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
          padding: const EdgeInsets.fromLTRB(
            Espaco.md,
            Espaco.md,
            Espaco.md,
            Espaco.md,
          ),
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
                child: next == null
                    ? null
                    : ItemSwatch(next, maxW: 38, maxH: 34),
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
                          ? t.fill(t.s('unlockPronto'), {
                              'i': t.nomeDoItemDaLoja(next.id),
                            })
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
                      style: nunito(
                        size: 13.5,
                        weight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: Espaco.xs),
                    TrackFill(
                      pct: unlockPct,
                      height: 8,
                      color: AppColors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Espaco.xs),
              const Chevron(),
            ],
          ),
        ),
        const SizedBox(height: Espaco.sm),
        // A foto saiu de cima do mundo: mora aqui, com o resto do dia.
        SoftCard(
          onTap: () {
            Navigator.of(context).pop();
            app.openShare();
          },
          child: Row(
            children: [
              const AppIcon(
                Icons.photo_camera_outlined,
                size: 18,
                color: AppColors.green,
              ),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Text(
                  t.fotoDoBicho,
                  style: nunito(size: 14, weight: FontWeight.w700),
                ),
              ),
              const Chevron(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(WeekDayKind k) {
    switch (k) {
      // Igual à tela da raiz: presente é verde com check, hoje é terracota
      // (a cor da raiz). Cada tela tinha o seu jeito (simulador, D8).
      case WeekDayKind.present:
        return Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Cores.folha600,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 12,
            color: Cores.tintaClara,
          ),
        );
      case WeekDayKind.frozen:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Cores.ceu600, width: 2),
          ),
        );
      case WeekDayKind.today:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Cores.raiz500.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: Cores.raiz500, width: 2),
          ),
        );
      case WeekDayKind.empty:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.inkA(0.13),
            shape: BoxShape.circle,
          ),
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
            Etiqueta(texto: t.missaoResgatar, cor: Cores.mel400, forte: true)
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

/// Fecha a folha quando um cartão dela leva para outra tela: deixá-la
/// aberta por baixo fazia ela voltar no "voltar", e o painel da home ficava
/// escondido enquanto isso (auditoria de dcf82c9, 4).
class _FechaAoSair extends StatefulWidget {
  const _FechaAoSair({required this.app, required this.child});

  final AppState app;
  final Widget child;

  @override
  State<_FechaAoSair> createState() => _FechaAoSairState();
}

class _FechaAoSairState extends State<_FechaAoSair> {
  @override
  void initState() {
    super.initState();
    widget.app.addListener(_ouve);
  }

  @override
  void dispose() {
    widget.app.removeListener(_ouve);
    super.dispose();
  }

  void _ouve() {
    if (widget.app.screen == AppScreen.home) return;
    widget.app.removeListener(_ouve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final rota = ModalRoute.of(context);
      if (rota != null && rota.isActive) {
        Navigator.of(context).removeRoute(rota);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
