import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n_humor.dart';
import '../l10n_loja.dart';
import '../data/crescimento.dart';
import '../models.dart';
import '../state.dart';
import 'trilha_screen.dart';
import '../theme.dart';
import '../widgets/brinquedos.dart';
import '../widgets/comida.dart';
import '../widgets/common.dart';
import '../widgets/crescimento.dart';
import '../widgets/mundo/mundo.dart';

/// A home é o mundo dele.
///
/// Era uma lista: o bicho num cartão de 372 px e, embaixo, seis cartões
/// disputando a atenção (o "hub lotado" que as críticas do Finch apontam).
/// Agora a tela inteira é o lugar onde ele vive (`MundoDoBaru`), e a
/// interface flutua por cima, em vidro: quem é ele e quanto falta para o
/// próximo nível, as folhas, a raiz; a fala dele num balão junto da
/// cabeça; o potinho, decorar e foto na lateral; e embaixo, sempre à vista,
/// a única ação que importa — a duração e o "Começar foco". O resto do dia
/// (tempo de tela, semana, nível, missões, relatório, próximo item) mora na
/// folha "Seu dia", a um gesto.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const seuDiaKey = Key('home-seu-dia');
  static const balaoKey = Key('home-balao');

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _mundo = GlobalKey<MundoDoBaruState>();
  final _cabeca = ValueNotifier<Offset?>(null);
  final _zona = ValueNotifier<ZonaDoMundo>(ZonaDoMundo.margem);
  bool _balaoAberto = true;

  @override
  void dispose() {
    _cabeca.dispose();
    _zona.dispose();
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

    return Stack(
      fit: StackFit.expand,
      children: [
        MundoDoBaru(key: _mundo, cabecaNaTela: _cabeca, zonaNaTela: _zona),

        // --- topo: quem é ele, as folhas, a raiz ---------------------------
        Positioned(
          top: pad.top + Espaco.sm,
          left: Espaco.md,
          right: Espaco.md,
          child: Row(
            children: [
              _Avatar(app: app),
              const Spacer(),
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => app.go(AppScreen.folhas),
                  behavior: HitTestBehavior.opaque,
                  child: LeafBadge(leaves: app.leaves),
                ),
              ),
              const SizedBox(width: Espaco.xs),
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => app.go(AppScreen.sequencia),
                  behavior: HitTestBehavior.opaque,
                  child: Vidro(
                    key: const Key('home-sequencia'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Espaco.sm,
                      vertical: 7,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GlifoRaiz(tamanho: 18),
                        const SizedBox(width: Espaco.xxs),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: tela.width * 0.28,
                          ),
                          child: Text(
                            app.streakText,
                            overflow: TextOverflow.ellipsis,
                            style: nunito(
                              size: 13,
                              weight: FontWeight.w800,
                              color: Cores.raiz600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- as zonas do mundo: onde a câmera está, e para onde ir ---------
        Positioned(
          top: pad.top + 62,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<ZonaDoMundo>(
            valueListenable: _zona,
            builder: (context, z, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (zona, nome) in [
                  (ZonaDoMundo.toca, t.zonaToca),
                  (ZonaDoMundo.brinquedos, t.zonaBrinquedos),
                  (ZonaDoMundo.margem, t.zonaMargem),
                  (ZonaDoMundo.lagoa, t.zonaLagoa),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => _mundo.currentState?.mostra(zona),
                      child: Vidro(
                        cor: zona == z
                            ? Cores.folha600.withValues(alpha: 0.88)
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          nome,
                          style: nunito(
                            size: 11.5,
                            weight: FontWeight.w800,
                            color: zona == z
                                ? Cores.tintaClara
                                : Cores.tinta700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                    child: GestureDetector(
                      onTap: () => setState(() => _balaoAberto = !_balaoAberto),
                      child: _Balao(
                        key: HomeScreen.balaoKey,
                        aberto: _balaoAberto,
                        titulo: cap,
                        texto: sub,
                        pontaEm: (o.dx - esquerda).clamp(24.0, largura - 24),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // --- a lateral: petisco, decorar, foto ------------------------------
        Positioned(
          right: Espaco.md,
          bottom: pad.bottom + 150,
          child: Column(
            children: [
              _BotaoDoPetisco(app: app, mundo: _mundo),
              const SizedBox(height: Espaco.sm),
              _BotaoRedondo(
                icone: Icons.palette_outlined,
                rotulo: t.dockDecorar,
                aoTocar: () => app.go(AppScreen.shop),
              ),
              const SizedBox(height: Espaco.sm),
              _BotaoRedondo(
                icone: Icons.photo_camera_outlined,
                rotulo: t.dockFoto,
                aoTocar: app.openShare,
              ),
            ],
          ),
        ),

        // --- embaixo: o seu dia e o foco ------------------------------------
        Positioned(
          left: Espaco.md,
          right: Espaco.md,
          bottom: pad.bottom + Espaco.sm,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                key: HomeScreen.seuDiaKey,
                onTap: () => SeuDia.abre(context),
                onVerticalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0) < -200) SeuDia.abre(context);
                },
                child: Vidro(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espaco.md,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 18,
                        color: Cores.tinta700,
                      ),
                      const SizedBox(width: Espaco.xxs),
                      Text(
                        t.seuDia,
                        style: nunito(
                          size: 13,
                          weight: FontWeight.w800,
                          color: Cores.tinta700,
                        ),
                      ),
                      if (app.missoesResgataveis > 0) ...[
                        const SizedBox(width: Espaco.xs),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Cores.mel400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Espaco.sm),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _escolheDuracao(context, app),
                    child: Vidro(
                      key: const Key('home-duracao'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Espaco.md,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _rotuloDaDuracao(app, app.dur),
                            style: nunito(size: 16, weight: FontWeight.w800),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: Espaco.sm),
                  Expanded(
                    child: BotaoBaru(
                      rotulo: t.start,
                      aoTocar: app.startSession,
                      altura: 60,
                      tamanhoDoTexto: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _rotuloDaDuracao(AppState app, int min) =>
      app.lang == 'zh' ? '$min分' : '$min${app.lang == 'en' ? 'm' : 'min'}';

  void _escolheDuracao(BuildContext context, AppState app) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AppScope(
        state: app,
        child: Padding(
          // As abas flutuam por cima da folha: o conteúdo para acima delas.
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

/// O nome dele com o anel do nível: quanto falta para o próximo.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${app.displayName}, ${app.t.fill(app.t.nivelRotulo, {'n': app.nivel})}',
      child: GestureDetector(
        onTap: () => app.go(AppScreen.trilha),
        child: Vidro(
          padding: const EdgeInsets.fromLTRB(5, 5, 14, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: app.progressoNoNivel.clamp(0.0, 1.0),
                      strokeWidth: 3.2,
                      backgroundColor: Cores.tinta.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation(Cores.folha600),
                    ),
                    Text(
                      '${app.nivel}',
                      style: nunito(size: 12.5, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Espaco.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  app.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: nunito(size: 14, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A fala do humor, num balão com a ponta na cabeça dele. Tocar recolhe.
class _Balao extends StatelessWidget {
  const _Balao({
    super.key,
    required this.aberto,
    required this.titulo,
    required this.texto,
    required this.pontaEm,
  });

  final bool aberto;
  final String titulo;
  final String texto;
  final double pontaEm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.bottomLeft,
          child: Container(
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
            child: aberto
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        key: const Key('home-humor-cap'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: nunito(
                          size: 15,
                          weight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        texto,
                        key: const Key('home-humor-sub'),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: nunito(
                          size: 13,
                          height: 1.35,
                          color: Cores.tinta700,
                        ),
                      ),
                    ],
                  )
                : const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: Cores.tinta700,
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: aberto ? pontaEm - 8 : 14),
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

class _BotaoRedondo extends StatelessWidget {
  const _BotaoRedondo({
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: rotulo,
      child: GestureDetector(
        onTap: aoTocar,
        child: Vidro(
          padding: const EdgeInsets.all(12),
          child: Icon(icone, size: 22, color: Cores.tinta700),
        ),
      ),
    );
  }
}

/// O potinho na lateral: arrasta o petisco dele até a boca.
class _BotaoDoPetisco extends StatelessWidget {
  const _BotaoDoPetisco({required this.app, required this.mundo});

  final AppState app;
  final GlobalKey<MundoDoBaruState> mundo;

  @override
  Widget build(BuildContext context) {
    BrinquedosDoHabitatState? b() =>
        mundo.currentState?.brinquedos.currentState;
    return Semantics(
      button: true,
      label: app.t.brinqPetisco,
      child: GestureDetector(
        key: BrinquedosDoHabitat.poteKey,
        onPanStart: (d) => b()?.pegaPetisco(d.globalPosition),
        onPanUpdate: (d) => b()?.arrastaPetisco(d.delta),
        onPanEnd: (_) => b()?.soltaPetisco(),
        onPanCancel: () => b()?.soltaPetisco(),
        child: Vidro(
          padding: const EdgeInsets.all(9),
          child: SizedBox(
            width: 28,
            height: 28,
            child: CustomPaint(
              painter: _PetiscoNoBotao(petiscoDe(app.species)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetiscoNoBotao extends CustomPainter {
  const _PetiscoNoBotao(this.c);

  final Comida c;

  @override
  void paint(Canvas canvas, Size size) {
    pintaComida(canvas, c, size.center(Offset.zero), size.width * 0.38);
  }

  @override
  bool shouldRepaint(_PetiscoNoBotao old) => old.c != c;
}

/// O resto do dia, numa folha que sobe da home: crescimento, relatório,
/// semana, tempo de tela, nível, missões e o próximo item da loja.
class SeuDia extends StatelessWidget {
  const SeuDia({super.key, required this.app});

  final AppState app;

  static Future<void> abre(BuildContext context) {
    final app = AppScope.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppScope(
        state: app,
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
