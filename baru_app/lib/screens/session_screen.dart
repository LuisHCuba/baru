import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n_pet.dart';
import '../models.dart';
import '../services/som_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/habitat.dart';
import '../widgets/pet.dart';

/// A tela dos 25 minutos.
///
/// O que ela mostra durante todo esse tempo é **o bicho no lugar dele** — não
/// é decoração, é o produto. Duas reclamações moldaram esta versão: "na hora
/// que eu coloco pra iniciar um foco ele fica só parado na tela", e depois
/// "a coruja fica balançando no ar, sem nada, o mesmo movimento a cada
/// segundo; o usuário deve poder interagir, arrastar o dedo".
///
/// - **A cena é o habitat da pessoa**, em tela cheia: a lagoa, a margem, a
///   luz da hora e os itens que ela comprou. A coruja pisa na margem em vez
///   de flutuar num fundo bege.
/// - **O tempo cresce na cena.** Um broto ao lado do bicho brota, abre
///   folhas e floresce com o foco: dá para ver o que os minutos estão
///   rendendo sem ler número nenhum.
/// - **Ele está vivo para o dedo.** Passear o dedo pela cena faz ele
///   acompanhar com o olhar; tocar a cena solta folhinhas no ponto e ele se
///   vira; arrastar o dedo **nele** é carinho (corações, ronrom no aparelho).
/// - **Ele não repete o mesmo gesto meia hora.** De tempos em tempos sai da
///   atividade da sessão, faz uma pausa à toa — olha em volta, se espreguiça
///   — e volta.
/// - **A atividade é `swim`** (o "banho" do vocabulário do app); o que ela
///   quer dizer em cada espécie quem traduz é [acaoDoBicho]: a gata e a
///   coruja brincam na beira.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  /// A sessão é o banho do bicho. Ver a nota da classe.
  static const atividade = Activity.swim;

  static const chaveDaCena = Key('sessao-cena');

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen>
    with TickerProviderStateMixin {
  /// Para onde ele olha, seguindo o dedo; `null` = olhar dele.
  Offset? _olhar;
  final _cutucadas = ValueNotifier<int>(0);

  /// Folhinhas soltas onde a cena foi tocada.
  final _toques = <_Toque>[];
  late final AnimationController _relogioDosToques = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..addListener(_limpaToques);

  /// A borboleta que passeia pela cena; ele a segue com o olhar.
  late final AnimationController _voo = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 23),
  );

  /// O susto da borboleta quando é tocada: ela dispara para longe.
  late final AnimationController _susto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// O balanço do broto ao vento.
  late final AnimationController _vento = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  /// A pausa à toa no meio da sessão.
  bool _descansando = false;
  Timer? _rotina;

  /// A dica de carinho, até a primeira vez que a pessoa toca a cena.
  bool _dica = true;
  Timer? _someDica;

  Offset? _dedoDesceu;
  DateTime? _quandoDesceu;

  @override
  void initState() {
    super.initState();
    _agendaPausa();
    _someDica = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _dica = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimento.reduzido(context)) {
      _vento.stop();
      _voo.stop();
    } else {
      if (!_vento.isAnimating) _vento.repeat(reverse: true);
      if (!_voo.isAnimating) _voo.repeat();
    }
  }

  /// Uma pausa à toa a cada 35–55 s, de 9 s: sai da água (ou da
  /// brincadeira), olha em volta, e volta.
  void _agendaPausa() {
    _rotina?.cancel();
    final espera = Duration(seconds: 35 + math.Random().nextInt(20));
    _rotina = Timer(_descansando ? const Duration(seconds: 9) : espera, () {
      if (!mounted) return;
      setState(() => _descansando = !_descansando);
      _agendaPausa();
    });
  }

  void _limpaToques() {
    final agora = DateTime.now();
    final antes = _toques.length;
    _toques.removeWhere(
      (t) => agora.difference(t.quando) > const Duration(milliseconds: 1100),
    );
    if (_toques.isEmpty && _relogioDosToques.isAnimating) {
      _relogioDosToques.stop();
    }
    if (antes != _toques.length || _toques.isNotEmpty) setState(() {});
  }

  @override
  void dispose() {
    _rotina?.cancel();
    _someDica?.cancel();
    _relogioDosToques.dispose();
    _vento.dispose();
    _voo.dispose();
    _susto.dispose();
    _cutucadas.dispose();
    super.dispose();
  }

  /// Onde a borboleta está, de 0 a 1 na cena: uma volta preguiçosa em oito,
  /// que se afasta para o alto quando ela leva um susto.
  Offset _ondeABorboleta() {
    final t = _voo.value * math.pi * 2;
    final fuga = Curves.easeIn.transform(_susto.value);
    final volta = _susto.value > 0.7 ? (_susto.value - 0.7) / 0.3 : 0.0;
    return Offset(
      0.5 + 0.36 * math.sin(t * 2) + 0.4 * fuga * (1 - volta),
      0.34 + 0.12 * math.sin(t * 3 + 1) - 0.4 * fuga * (1 - volta),
    );
  }

  /// O dedo em relação ao bicho, -1..1, para ele acompanhar.
  Offset _olharPara(Offset local, Size cena) {
    final centro = Offset(cena.width / 2, cena.height * 0.62);
    return Offset(
      ((local.dx - centro.dx) / (cena.width / 2)).clamp(-1.0, 1.0),
      ((local.dy - centro.dy) / (cena.height / 2)).clamp(-1.0, 1.0),
    );
  }

  /// O retângulo onde ele está: toque ali é dele, e quem responde é ele.
  bool _noBicho(Offset local, Size cena) =>
      (local.dx - cena.width / 2).abs() < cena.width * 0.24 &&
      local.dy > cena.height * 0.30 &&
      local.dy < cena.height * 0.92;

  void _dedoNaCena(Offset local, Size cena) {
    if (_dica) {
      _someDica?.cancel();
      _dica = false;
    }
    setState(() => _olhar = _olharPara(local, cena));
  }

  void _soltouADedo(Offset local, Size cena) {
    final desceu = _dedoDesceu;
    final quando = _quandoDesceu;
    _dedoDesceu = null;
    _quandoDesceu = null;
    // Ele ainda olha para onde o dedo saiu por um instante.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _dedoDesceu == null) setState(() => _olhar = null);
    });
    if (desceu == null || quando == null) return;
    final foiToque = (local - desceu).distance < 14 &&
        DateTime.now().difference(quando) < const Duration(milliseconds: 350);
    if (!foiToque || _noBicho(local, cena)) return;
    final b = _ondeABorboleta();
    if ((local - Offset(b.dx * cena.width, b.dy * cena.height)).distance < 34) {
      // Pegou a borboleta: ela foge, ele pula de alegria.
      _susto.forward(from: 0);
    }

    // Um toque na cena: folhinhas no ponto, e ele se vira para ver.
    HapticFeedback.selectionClick();
    unawaited(SomService.instance.toca(SomDoBaru.toque));
    _toques.add(_Toque(local, DateTime.now(), math.Random().nextInt(1 << 20)));
    _cutucadas.value++;
    if (!_relogioDosToques.isAnimating) _relogioDosToques.repeat();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    garanteTextosDoPet();
    final app = AppScope.of(context);
    final t = app.t;
    final atividade =
        _descansando ? Activity.idle : SessionScreen.atividade;
    final acao = acaoNoEstagio(app.species, atividade, app.estagioVisivel);
    final acaoDaSessao = acaoNoEstagio(
      app.species,
      SessionScreen.atividade,
      app.estagioVisivel,
    );
    final total = app.sessionMinutes * 60;
    final pct =
        total == 0 ? 0.0 : ((total - app.remaining) / total).clamp(0.0, 1.0);
    final mm = (app.remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (app.remaining % 60).toString().padLeft(2, '0');
    final altura = MediaQuery.sizeOf(context).height;
    final alturaDaCena = (altura * 0.56).clamp(300.0, 520.0);

    return Stack(
      children: [
        ColoredBox(
          color: AppColors.sessionBg,
          child: Column(
            children: [
              SizedBox(
                key: SessionScreen.chaveDaCena,
                height: alturaDaCena,
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cena = Size(c.maxWidth, c.maxHeight);
                    final sx = cena.width / HabitatScene.design.width;
                    final sy = cena.height / HabitatScene.design.height;
                    final escala =
                        HabitatScene.presencaDoPet * math.min(sx, sy);
                    return Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (e) {
                        _dedoDesceu = e.localPosition;
                        _quandoDesceu = DateTime.now();
                        _dedoNaCena(e.localPosition, cena);
                      },
                      onPointerMove: (e) => _dedoNaCena(e.localPosition, cena),
                      onPointerUp: (e) => _soltouADedo(e.localPosition, cena),
                      onPointerCancel: (_) => setState(() => _olhar = null),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(Raio.cena),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Sem dedo na cena, ele segue a borboleta com os
                            // olhos — o que dá vida ao tempo parado.
                            AnimatedBuilder(
                              animation: _voo,
                              builder: (context, _) {
                                final b = _ondeABorboleta();
                                return HabitatScene(
                                  height: cena.height,
                                  moldura: false,
                                  atividade: atividade,
                                  humor: Mood.radiant,
                                  olharDoBicho: _olhar ??
                                      _olharPara(
                                        Offset(b.dx * cena.width,
                                            b.dy * cena.height),
                                        cena,
                                      ),
                                  cutucadas: _cutucadas,
                                );
                              },
                            ),
                            // O broto, na margem à esquerda, crescendo com o
                            // foco. Pés no chão onde o bicho pisa na margem.
                            Positioned(
                              left: cena.width * 0.70,
                              bottom: 30 * sy,
                              width: 64 * escala,
                              height: 104 * escala,
                              child: IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _vento,
                                  builder: (context, _) => CustomPaint(
                                    painter: _Broto(
                                      progresso: pct,
                                      vento: _vento.value * 2 - 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _FolhinhasDoToque(_toques),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_voo, _susto]),
                                  builder: (context, _) => CustomPaint(
                                    painter: _Borboleta(
                                      onde: _ondeABorboleta(),
                                      bate: _voo.value * 23 * 9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // O que é esta sessão, num selo sobre a cena.
                            Positioned(
                              top: MediaQuery.paddingOf(context).top +
                                  Espaco.md,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Espaco.md,
                                    vertical: Espaco.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Cores.superficie.withValues(alpha: 0.9),
                                    borderRadius: Raio.todos(Raio.pilula),
                                  ),
                                  child: Text(
                                    t
                                        .fill(t.petRotuloDaSessao(acaoDaSessao),
                                            {'m': app.sessionMinutes})
                                        .toUpperCase(),
                                    style: nunito(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: Cores.tinta700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // A dica de carinho, enquanto ninguém tocou —
                            // logo abaixo do selo, longe do broto e do bicho.
                            Positioned(
                              left: 0,
                              right: 0,
                              top: MediaQuery.paddingOf(context).top +
                                  Espaco.md +
                                  40,
                              child: IgnorePointer(
                                child: AnimatedOpacity(
                                  opacity: _dica ? 1 : 0,
                                  duration: Tempo.componente,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Espaco.md,
                                        vertical: Espaco.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Cores.tinta
                                            .withValues(alpha: 0.72),
                                        borderRadius:
                                            Raio.todos(Raio.pilula),
                                      ),
                                      child: Text(
                                        t.fill(t.s('sessaoDicaCarinho'),
                                            {'n': app.displayName}),
                                        style: nunito(
                                          size: 13,
                                          weight: FontWeight.w700,
                                          color: Cores.tintaClara,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Espaco.xl,
                    Espaco.lg,
                    Espaco.xl,
                    Espaco.md,
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Semantics(
                        liveRegion: true,
                        label: '$mm:$ss',
                        child: Text(
                          '$mm:$ss',
                          style: nunito(
                            size: 66,
                            weight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -2,
                            tabular: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: Espaco.sm),
                      AnimatedSwitcher(
                        duration: Tempo.componente,
                        child: Text(
                          t.fill(
                            t.petFazendoNoEstagio(
                              acao,
                              app.estagioVisivel,
                              app.species,
                            ),
                            {'n': app.displayName},
                          ),
                          key: ValueKey(acao),
                          textAlign: TextAlign.center,
                          style: nunito(size: 15.5, color: Cores.tinta700),
                        ),
                      ),
                      const SizedBox(height: Espaco.lg),
                      TrackFill(pct: pct, height: 8),
                      const Spacer(),
                      TextAction(label: t.give, onTap: app.askQuit, height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (app.confirming) _QuitSheet(app: app),
      ],
    );
  }
}

/// A borboleta da cena: duas asas que batem e um corpinho.
class _Borboleta extends CustomPainter {
  _Borboleta({required this.onde, required this.bate});

  /// 0..1 na cena.
  final Offset onde;
  final double bate;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Offset(onde.dx * size.width, onde.dy * size.height);
    if (p.dx < -20 || p.dx > size.width + 20 || p.dy < -20) return;
    final abre = 0.35 + 0.65 * math.sin(bate).abs();
    canvas.save();
    canvas.translate(p.dx, p.dy);
    for (final lado in [-1.0, 1.0]) {
      canvas.save();
      canvas.scale(lado * abre, 1);
      canvas.drawOval(
        const Rect.fromLTWH(0, -9, 11, 10),
        Paint()..color = const Color(0xFFF2B33D),
      );
      canvas.drawOval(
        const Rect.fromLTWH(0, 0, 8, 7),
        Paint()..color = const Color(0xFFE88A3A),
      );
      canvas.drawCircle(
        const Offset(6, -4),
        1.8,
        Paint()..color = const Color(0xFFFFFBF2),
      );
      canvas.restore();
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-1.4, -8, 2.8, 15),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF3E2F23),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Borboleta old) =>
      old.onde != onde || old.bate != bate;
}

class _Toque {
  _Toque(this.onde, this.quando, this.semente);
  final Offset onde;
  final DateTime quando;
  final int semente;
}

/// Folhinhas que sobem e caem girando de onde o dedo tocou, com um anel que
/// se abre — a cena respondendo ao toque.
class _FolhinhasDoToque extends CustomPainter {
  _FolhinhasDoToque(this.toques);
  final List<_Toque> toques;

  @override
  void paint(Canvas canvas, Size size) {
    final agora = DateTime.now();
    for (final t in toques) {
      final u = (agora.difference(t.quando).inMilliseconds / 1000.0)
          .clamp(0.0, 1.0);
      final some = 1 - u;
      canvas.drawCircle(
        t.onde,
        8 + 34 * Curves.easeOut.transform(u),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..color = Cores.superficie.withValues(alpha: 0.75 * some),
      );
      final sorte = math.Random(t.semente);
      for (var i = 0; i < 5; i++) {
        final ang = -math.pi / 2 + (sorte.nextDouble() - 0.5) * 2.2;
        final forca = 40 + sorte.nextDouble() * 34;
        final p = t.onde +
            Offset(math.cos(ang) * forca * u,
                math.sin(ang) * forca * u + 60 * u * u);
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(u * 5 * (i.isEven ? 1 : -1));
        final cor = (i % 3 == 0 ? Cores.mel400 : Cores.folha500)
            .withValues(alpha: some);
        canvas.drawPath(
          Path()
            ..moveTo(-6, 0)
            ..quadraticBezierTo(0, -5, 6, 0)
            ..quadraticBezierTo(0, 5, -6, 0)
            ..close(),
          Paint()..color = cor,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FolhinhasDoToque old) => true;
}

/// O broto do foco: nasce como semente, abre folhas e floresce no fim.
class _Broto extends CustomPainter {
  _Broto({required this.progresso, required this.vento});
  final double progresso;

  /// -1..1, o balanço.
  final double vento;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height);
    // O montinho de terra.
    canvas.drawOval(
      Rect.fromCenter(
        center: base.translate(0, -3),
        width: size.width * 0.62,
        height: 10,
      ),
      Paint()..color = const Color(0xFF8A6440),
    );
    // Já nasce com um palmo e duas folhinhas: um broto que só aparece
    // depois de minutos é um broto que ninguém viu nascer.
    final cresce =
        0.22 + 0.78 * Curves.easeOut.transform(progresso.clamp(0.0, 1.0));
    final alto = 10 + (size.height - 22) * cresce;
    final pontaX = base.dx + vento * 4 * cresce;
    final ponta = Offset(pontaX, base.dy - alto);
    final caule = Paint()
      ..color = Cores.folha600
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - 4)
        ..quadraticBezierTo(base.dx - 4, base.dy - alto * 0.5, ponta.dx, ponta.dy),
      caule,
    );
    // Uma folha a cada quarto do caminho, alternando os lados.
    for (var i = 0; i < 4; i++) {
      final quando = i < 2 ? -1.0 : 0.12 + (i - 1) * 0.26;
      final abre = ((progresso - quando) / 0.12).clamp(0.0, 1.0);
      if (abre <= 0) continue;
      final f = 0.25 + i * 0.2;
      final ponto = Offset(
        base.dx + (pontaX - base.dx) * f - 2 * (1 - f),
        base.dy - alto * f,
      );
      final lado = i.isEven ? -1.0 : 1.0;
      final tam = 14.0 * Curves.easeOutBack.transform(abre);
      canvas.save();
      canvas.translate(ponto.dx, ponto.dy);
      canvas.rotate(lado * (0.9 - vento * 0.12));
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(tam * 0.5, -tam * 0.55, tam * 1.1, 0)
          ..quadraticBezierTo(tam * 0.5, tam * 0.45, 0, 0)
          ..close(),
        Paint()..color = i.isEven ? Cores.folha500 : Cores.folha600,
      );
      canvas.restore();
    }
    // No fim, a flor.
    final flor = ((progresso - 0.9) / 0.1).clamp(0.0, 1.0);
    if (flor > 0) {
      final r = 7.0 * Curves.easeOutBack.transform(flor);
      for (var k = 0; k < 5; k++) {
        final a = k * math.pi * 2 / 5;
        canvas.drawCircle(
          ponta + Offset(math.cos(a), math.sin(a)) * r * 0.9,
          r * 0.62,
          Paint()..color = const Color(0xFFF7E3A6),
        );
      }
      canvas.drawCircle(ponta, r * 0.5, Paint()..color = Cores.mel400);
    } else {
      // O botão, fechado, na ponta.
      canvas.drawCircle(
        ponta,
        3.6,
        Paint()..color = Cores.folha500,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Broto old) =>
      old.progresso != progresso || old.vento != vento;
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
          padding: const EdgeInsets.fromLTRB(Espaco.xl, Espaco.xxl, Espaco.xl, Espaco.xxxl),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Continua fazendo a mesma coisa da tela de trás: é justamente
              // o que a folha está perguntando — "ele está no meio disso,
              // tem certeza?". Um bicho parado aqui contradiria a pergunta.
              PetView(
                species: app.species,
                mood: Mood.radiant,
                activity: SessionScreen.atividade,
                coat: app.color,
                estagio: app.estagioVisivel,
                roupas: app.roupasDoBicho,
                roupaDeCabeca: app.roupaDeCabeca,
              ),
              const SizedBox(height: Espaco.md),
              Text(
                app.t.fill(app.t.quitTitle, {'n': app.displayName}),
                textAlign: TextAlign.center,
                style: nunito(size: 23, weight: FontWeight.w800, height: 1.25, letterSpacing: -0.3),
              ),
              const SizedBox(height: Espaco.xs),
              Text(
                app.t.quitSub,
                textAlign: TextAlign.center,
                style: nunito(size: 14.5, height: 1.5, color: Cores.tinta700),
              ),
              const SizedBox(height: Espaco.lg),
              BotaoBaru(rotulo: app.t.stay, aoTocar: app.resume),
              TextAction(label: app.t.leave, onTap: app.abandon),
            ],
          ),
        ),
      ),
    );
  }
}
