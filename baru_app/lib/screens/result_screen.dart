import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progressao.dart';
import '../data/resumo_da_sessao.dart';
import '../models.dart';
import '../services/som_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/habitat.dart';
import '../widgets/pet.dart';
import 'missoes_screen.dart' show tituloDaMissao;

/// O fim da sessão, em sequência (laudo 01, §6).
///
/// Cada recompensa tem o seu segundo de palco, uma por vez, e a animação
/// acontece **nesta** tela, a partir do retrato "antes" (`ResumoDaSessao`):
///
/// 1. **E1** — "+10" conta de zero e as folhas voam até o saldo, que pulsa
///    a cada chegada; a barra de XP enche, com o bônus da raiz noutro tom.
/// 2. **E2/E4** — a raiz, o bicho crescendo, o nível: as cenas da casca, que
///    esperam esta tela terminar a E1 (`AppState.celebracoesEmEspera`).
/// 3. **E3** — as missões que esta sessão fez andar, cada barra do valor de
///    antes ao de agora; a que fechou vira "pronta para colher".
/// 4. **E5** — o fecho: "Dia feito" ou o próximo passo mais perto do fim.
///
/// Toque em qualquer lugar adianta a E1. "Reduzir movimento": tudo no valor
/// final, sem voo.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final resumo = app.ultimoResumo;
    if (app.aborted || resumo == null) return const _Desistencia();
    return _Sequencia(resumo: resumo);
  }
}

/// Desistir não custa nada (§1): o bicho continua contente, a tela é curta.
/// Desistiu: o bicho continua no habitat dele, e a porta segue aberta.
///
/// Era um bicho solto num fundo creme vazio, com "Ele continua aqui" mesmo
/// para a Nina. Agora é a mesma cena da home, contente — cara de pena aqui
/// seria cobrança —, e o caminho de volta ao foco fica a um toque.
class _Desistencia extends StatelessWidget {
  const _Desistencia();

  static const chaveDeNovo = Key('resultado-de-novo');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    return LayoutBuilder(
      builder: (context, c) => Column(
        children: [
          HabitatScene(
            height: (c.maxHeight * 0.50).clamp(260.0, 460.0),
            moldura: false,
            atividade: Activity.idle,
            humor: Mood.content,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Espaco.xl,
                Espaco.xl,
                Espaco.xl,
                Espaco.lg,
              ),
              child: Column(
                children: [
                  Text(
                    t.fill(t.resLost, {'n': app.displayName}),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: nunito(
                      size: 26,
                      weight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: Espaco.sm),
                  Text(
                    t.resLostSub,
                    textAlign: TextAlign.center,
                    style: nunito(
                      size: 15,
                      height: 1.5,
                      color: Cores.tinta700,
                    ),
                  ),
                  const Spacer(),
                  BotaoBaru(
                    key: chaveDeNovo,
                    rotulo: t.fill(t.resDeNovo, {'m': app.dur}),
                    aoTocar: () {
                      app.voltar();
                      app.startSession();
                    },
                  ),
                  const SizedBox(height: Espaco.sm),
                  BotaoBaru(
                    rotulo: t.back,
                    papel: PapelDoBotao.secundario,
                    aoTocar: app.voltar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sequencia extends StatefulWidget {
  const _Sequencia({required this.resumo});

  final ResumoDaSessao resumo;

  static const chave = Key('resultado-sequencia');
  static const chaveDoSaldo = Key('resultado-saldo');
  static const chaveDoGanho = Key('resultado-ganho');

  /// A E1 inteira: contagem, voo e XP.
  static const duracaoE1 = Duration(milliseconds: 2100);

  @override
  State<_Sequencia> createState() => _SequenciaState();
}

class _SequenciaState extends State<_Sequencia> with TickerProviderStateMixin {
  // `preserve`: a variante reduzida é desenhada aqui, não pelo relógio.
  late final AnimationController _e1 = AnimationController(
    vsync: this,
    duration: _Sequencia.duracaoE1,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _e3 = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    animationBehavior: AnimationBehavior.preserve,
  );

  final _raiz = GlobalKey();
  final _ganho = GlobalKey();
  final _saldo = GlobalKey();

  double _ultimoMs = 0;
  bool _somDasFolhas = false;

  static const _folhasNoVoo = 8;

  @override
  void initState() {
    super.initState();
    _e1.addListener(_disparos);
    _e1.addStatusListener((s) {
      if (s == AnimationStatus.completed) _terminouE1();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_e1.isAnimating || _e1.isCompleted) return;
    if (Movimento.reduzido(context)) {
      _e1.value = 1;
      _e3.value = 1;
      unawaited(SomService.instance.toca(SomDoBaru.folhas));
      _terminouE1();
    } else {
      _e1.forward();
    }
  }

  void _terminouE1() {
    // Agora as cenas da casca: raiz, crescimento, nível. O pós-quadro evita
    // mexer no estado no meio de um build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).liberaCelebracoes();
    });
  }

  /// Ticks das folhas chegando e o som da contagem, por limiar de relógio.
  void _disparos() {
    final ms = _e1.value * _Sequencia.duracaoE1.inMilliseconds;
    for (var i = 0; i < _folhasNoVoo; i += 2) {
      final chega = _chegadaDa(i);
      if (_ultimoMs < chega && ms >= chega) HapticFeedback.selectionClick();
    }
    if (!_somDasFolhas && ms >= 950) {
      _somDasFolhas = true;
      unawaited(SomService.instance.toca(SomDoBaru.folhas));
    }
    _ultimoMs = ms;
  }

  /// Quando a folha [i] chega ao saldo, em ms.
  double _chegadaDa(int i) => 650 + i * 85.0;

  void _toque() {
    if (_e1.isCompleted) return;
    if (!_somDasFolhas) {
      _somDasFolhas = true;
      unawaited(SomService.instance.toca(SomDoBaru.folhas));
    }
    _e1.value = 1;
    _terminouE1();
  }

  @override
  void dispose() {
    _e1.dispose();
    _e3.dispose();
    super.dispose();
  }

  double _f(double ms, double de, double ate, [Curve c = Curves.linear]) =>
      c.transform(((ms - de) / (ate - de)).clamp(0.0, 1.0));

  Offset? _centroDe(GlobalKey k) {
    final caixa = k.currentContext?.findRenderObject() as RenderBox?;
    final raiz = _raiz.currentContext?.findRenderObject() as RenderBox?;
    if (caixa == null || raiz == null || !caixa.hasSize) return null;
    return caixa.localToGlobal(caixa.size.center(Offset.zero), ancestor: raiz);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final r = widget.resumo;

    // A E3 começa quando a E1 acabou e as cenas da casca já passaram.
    if (_e1.isCompleted &&
        !app.temCelebracaoPendente &&
        !_e3.isAnimating &&
        !_e3.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _e3.forward();
      });
    }

    return GestureDetector(
      key: _Sequencia.chave,
      behavior: HitTestBehavior.translucent,
      onTap: _toque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_e1, _e3]),
        builder: (context, _) {
          final ms = _e1.value * _Sequencia.duracaoE1.inMilliseconds;
          final conta = _f(ms, 350, 950, Curves.easeOut);
          final chegaram = [
            for (var i = 0; i < _folhasNoVoo; i++) ms >= _chegadaDa(i),
          ].where((c) => c).length;
          // O destino é o saldo **real**: um marco da trilha pode ter pago
          // junto, e a tela não pode parar num número que não existe
          // (auditoria da Onda 2, item 8, 1.1).
          final ganhoReal = app.leaves - r.folhasAntes;
          final saldo =
              r.folhasAntes + (ganhoReal * chegaram / _folhasNoVoo).round();
          final pulso = chegaram == 0 || chegaram == _folhasNoVoo
              ? 0.0
              : math.sin(((ms - 650) % 85) / 85 * math.pi);
          final xpSessao = _f(ms, 1350, 1800, Curves.easeInOut);
          final xpRaiz = _f(ms, 1800, 2100, Curves.easeInOut);

          return Stack(
            key: _raiz,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.xl, Espaco.md, Espaco.xl, Espaco.xxl),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        Transform.scale(
                          scale: 1 + 0.12 * pulso,
                          child: KeyedSubtree(
                            key: _saldo,
                            child: LeafBadge(
                              key: _Sequencia.chaveDoSaldo,
                              leaves: saldo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            PetView(
                              species: app.species,
                              mood: Mood.radiant,
                              activity: Activity.idle,
                              coat: app.color,
                              estagio: app.estagioVisivel,
                              roupas: app.roupasDoBicho,
                              roupaDeCabeca: app.roupaDeCabeca,
                              scale: 1.05,
                            ),
                            const SizedBox(height: Espaco.sm),
                            _Ganho(
                              key: _ganho,
                              valor: (r.folhasDaSessao * conta).round(),
                            ),
                            const SizedBox(height: Espaco.md),
                            Text(
                              t.fill(t.resWon, {'m': r.minutos}),
                              textAlign: TextAlign.center,
                              style: nunito(
                                size: 24,
                                weight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: Espaco.md),
                            _BarraDeXp(
                              resumo: r,
                              sessao: xpSessao,
                              raiz: xpRaiz,
                            ),
                            const SizedBox(height: Espaco.md),
                            Opacity(
                              // Logo abaixo do XP, à vista sem rolar: com quatro
                              // missões na lista ele ficava atrás dos botões.
                              opacity: _f(ms, 1800, 2100),
                              child: Text(
                                _fecho(app),
                                key: const Key('resultado-fecho'),
                                textAlign: TextAlign.center,
                                style: nunito(
                                  size: 15,
                                  height: 1.5,
                                  weight: FontWeight.w600,
                                  color: AppColors.inkA(0.7),
                                ),
                              ),
                            ),
                            if (r.missoes.isNotEmpty) ...[
                              const SizedBox(height: Espaco.md),
                              _Missoes(
                                app: app,
                                missoes: r.missoes,
                                t: _e3.value,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Espaco.sm),
                    BotaoBaru(
                      rotulo: t.shareBtn,
                      aoTocar: app.openShare,
                      icone: const Icon(Icons.share_outlined),
                      papel: PapelDoBotao.secundario,
                    ),
                    const SizedBox(height: Espaco.sm),
                    BotaoBaru(rotulo: t.back, aoTocar: app.voltar),
                  ],
                ),
              ),
              // As folhas em voo, por cima de tudo.
              if (ms > 0 && ms < 1500)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _Voo(
                        de: _centroDe(_ganho),
                        ate: _centroDe(_saldo),
                        ms: ms,
                        chegadas: [
                          for (var i = 0; i < _folhasNoVoo; i++) _chegadaDa(i),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// "Dia feito" quando a raiz cresceu hoje e a principal do dia está
  /// cumprida (ou não se aplica); senão, o passo mais perto do fim.
  String _fecho(AppState app) {
    final t = app.t;
    final d = app.missaoDoDescanso;
    final principalOk = !d.disponivel || d.concluida || d.resgatada;
    final abertas = app.missoesDiarias
        .where((m) => m.disponivel && !m.concluida && !m.resgatada)
        .toList()
      ..sort((a, b) => b.fracao.compareTo(a.fracao));
    // "Dia feito" só é verdade com a raiz crescida, a principal cumprida e
    // nada pronto esperando colheita — prêmio parado não é dia fechado.
    if (app.completedToday >= 1 &&
        principalOk &&
        app.missoesResgataveis == 0) {
      return t.fill(t.resDiaFeito, {'a': app.displayName});
    }
    if (abertas.isEmpty) return t.fill(t.resWonSub, {'n': app.displayName});
    final m = abertas.first;
    return t.fill(t.resProximo, {
      'm': tituloDaMissao(app, m),
      'p': m.progresso,
      't': m.alvo,
      'f': m.folhas,
    });
  }
}

/// O "+10 folhas" que conta de zero.
class _Ganho extends StatelessWidget {
  const _Ganho({super.key, required this.valor});

  final int valor;

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).t;
    return Container(
      key: _Sequencia.chaveDoGanho,
      padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.sm, Espaco.lg, Espaco.sm),
      decoration: BoxDecoration(
        color: Cores.folha600.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GlifoFolha(tamanho: 22),
          const SizedBox(width: Espaco.sm),
          Text(
            t.fill(t.reward, {'k': valor}),
            style: nunito(
              size: 21,
              weight: FontWeight.w800,
              color: Cores.folha700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A barra do nível enchendo com o XP da sessão e, noutro tom, o da raiz.
class _BarraDeXp extends StatelessWidget {
  const _BarraDeXp({
    required this.resumo,
    required this.sessao,
    required this.raiz,
  });

  final ResumoDaSessao resumo;
  final double sessao;
  final double raiz;

  @override
  Widget build(BuildContext context) {
    final t = AppScope.of(context).t;
    final xp = resumo.xpAntes +
        resumo.xpDaSessao * sessao +
        resumo.xpDaRaiz * raiz;
    final nivel = Balanco.nivelPara(xp.floor());
    final de = Balanco.xpAcumuladoPara(nivel);
    final ate = Balanco.xpAcumuladoPara(nivel + 1);
    final fracao = ate <= de ? 1.0 : ((xp - de) / (ate - de)).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Text(
              t.fill(t.celebNivel, {'n': nivel}),
              style: nunito(
                size: 13,
                weight: FontWeight.w800,
                color: Cores.mel700,
              ),
            ),
            const Spacer(),
            Opacity(
              opacity: sessao > 0 ? 1 : 0,
              child: const GlifoXp(tamanho: 14),
            ),
            const SizedBox(width: Espaco.xxs),
            Opacity(
              opacity: sessao > 0 ? 1 : 0,
              child: Text(
                t.fill(t.resXp, {'n': resumo.xpDaSessao}),
                style: nunito(
                  size: 13,
                  weight: FontWeight.w800,
                  color: Cores.mel700,
                ),
              ),
            ),
            if (resumo.xpDaRaiz > 0) ...[
              const SizedBox(width: Espaco.xs),
              Opacity(
                opacity: raiz > 0 ? 1 : 0,
                child: Text(
                  t.fill(t.resRaizXp, {'n': resumo.xpDaRaiz}),
                  style: nunito(
                    size: 13,
                    weight: FontWeight.w800,
                    color: Cores.raiz600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Espaco.xs),
        BarraAnimada(
          fracao: fracao,
          altura: 10,
          // Progresso é verde até o fim; o bônus da raiz fica no texto
          // terracota ao lado (a barra inteira em raiz500 dava 2,5:1).
          cor: Cores.folha600,
          duracao: Duration.zero,
        ),
      ],
    );
  }
}

/// As missões que esta sessão fez andar, cada barra do antes ao agora.
class _Missoes extends StatelessWidget {
  const _Missoes({required this.app, required this.missoes, required this.t});

  final AppState app;
  final List<MissaoTocada> missoes;

  /// 0 a 1, o andar das barras.
  final double t;

  @override
  Widget build(BuildContext context) {
    final tx = app.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tx.resMissoesT,
          style: nunito(
            size: 11.5,
            weight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Cores.tinta700,
          ),
        ),
        const SizedBox(height: Espaco.xs),
        for (final m in missoes)
          Padding(
            padding: const EdgeInsets.only(bottom: Espaco.xs),
            child: _MissaoQueAndou(app: app, m: m, t: t),
          ),
      ],
    );
  }
}

class _MissaoQueAndou extends StatelessWidget {
  const _MissaoQueAndou({required this.app, required this.m, required this.t});

  final AppState app;
  final MissaoTocada m;
  final double t;

  @override
  Widget build(BuildContext context) {
    final tx = app.t;
    final d = m.depois;
    final antes = m.antes.fracao;
    final fracao = antes + (d.fracao - antes) * Curves.easeOut.transform(t);
    final pronta = d.concluida && t >= 1;
    final progresso =
        (m.antes.progresso + (d.progresso - m.antes.progresso) * t).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.sm, Espaco.sm, Espaco.sm),
      decoration: BoxDecoration(
        color: pronta
            ? Cores.mel400.withValues(alpha: 0.24)
            : AppColors.inkA(0.045),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloDaMissao(app, d),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nunito(size: 13.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                BarraAnimada(
                  fracao: fracao,
                  altura: 7,
                  duracao: Duration.zero,
                ),
                const SizedBox(height: Espaco.xxs),
                Text(
                  pronta ? tx.resPronta : '$progresso/${d.alvo}',
                  style: nunito(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: pronta ? Cores.mel700 : Cores.tinta700,
                  ),
                ),
              ],
            ),
          ),
          // Sem botão "Colher" aqui: a cena "Missão cumprida!" vem logo
          // depois com o dela, e dois "Colher" seguidos era um a mais.
          if (pronta) ...[
            const SizedBox(width: Espaco.sm),
            const GlifoFolha(tamanho: 22),
          ],
        ],
      ),
    );
  }
}

/// As folhas voando do "+10" até o saldo, em arco.
class _Voo extends CustomPainter {
  _Voo({
    required this.de,
    required this.ate,
    required this.ms,
    required this.chegadas,
  });

  final Offset? de;
  final Offset? ate;
  final double ms;
  final List<double> chegadas;

  static const _duracaoDoVoo = 420.0;

  @override
  void paint(Canvas canvas, Size size) {
    final a = de;
    final b = ate;
    if (a == null || b == null) return;
    for (var i = 0; i < chegadas.length; i++) {
      final sai = chegadas[i] - _duracaoDoVoo;
      final u = ((ms - sai) / _duracaoDoVoo).clamp(0.0, 1.0);
      if (u <= 0 || u >= 1) continue;
      final e = Curves.easeInOut.transform(u);
      // Arco: o ponto de controle sobe e abre para o lado de cada folha.
      final lado = i.isEven ? 1.0 : -1.0;
      final controle = Offset(
        (a.dx + b.dx) / 2 + lado * 40,
        math.min(a.dy, b.dy) - 60,
      );
      final p = Offset(
        (1 - e) * (1 - e) * a.dx + 2 * (1 - e) * e * controle.dx + e * e * b.dx,
        (1 - e) * (1 - e) * a.dy + 2 * (1 - e) * e * controle.dy + e * e * b.dy,
      );
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(u * math.pi * 2 * lado);
      const s = 7.0;
      canvas.drawPath(
        Path()
          ..moveTo(-s, 0)
          ..quadraticBezierTo(0, -s * 0.7, s, 0)
          ..quadraticBezierTo(0, s * 0.7, -s, 0)
          ..close(),
        // A moeda voa na cor dela: é a mesma folha do saldo.
        Paint()..color = Cores.folha600,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Voo old) =>
      old.ms != ms || old.de != de || old.ate != ate;
}
