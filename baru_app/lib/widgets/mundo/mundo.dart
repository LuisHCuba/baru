/// O mundo do bicho: a home inteira é o lugar onde ele vive.
///
/// Um espaço contínuo, mais largo que a tela, com zonas — a toca (dormir),
/// a margem (comer), o canto dos brinquedos (brincar) e a lagoa (nadar) —
/// como o Talking Tom 2 passou a fazer em 2026, no lugar de cômodos
/// separados. A câmera acompanha o bicho quando ele vai de uma zona a outra
/// sozinho; o dedo arrasta para passear e, solto, a câmera volta a ele.
///
/// O bicho escolhe a zona pelo momento: com sono vai até a toca e dorme lá;
/// o humor pede água e ele vai até a beira e pula; brincando, vai aos
/// brinquedos. Quem nada também vai e volta da lagoa por conta própria.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/crescimento.dart';
import '../../l10n_humor.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../brinquedos.dart';
import '../habitat.dart';
import '../pet.dart';
import '../vida/motor_de_vida.dart';
import 'pinta_mundo.dart';

/// As proporções do mundo, em frações da largura dele.
class ZonasDoMundo {
  const ZonasDoMundo._();

  /// O mundo tem esta quantidade de telas de largura.
  static const telas = 2.6;
  // Da esquerda para a direita: toca, brinquedos, margem, lagoa. Ele nasce
  // no meio do mundo, que cai na margem.
  static const toca = (0.0, 0.18);
  static const brinquedos = (0.18, 0.36);
  static const margem = (0.36, 0.7);
  static const lagoa = (0.7, 1.0);

  /// Onde termina a terra e começa a água.
  static const beira = 0.7;
}

enum ZonaDoMundo { toca, margem, brinquedos, lagoa }

/// A geometria do mundo para uma tela.
class GeometriaDoMundo {
  GeometriaDoMundo(this.tela)
    : largura = tela.width * ZonasDoMundo.telas,
      escala = (tela.width / 412 * 1.6).clamp(1.2, 2.2);

  final Size tela;
  final double largura;

  /// Px por unidade do desenho do bicho.
  final double escala;

  double get altura => tela.height;

  /// Onde ficam os pés dele na terra, e a lâmina d'água da lagoa.
  double get chao => altura * 0.70;
  double get linhaDagua => altura * 0.735;

  /// A linha do horizonte, onde o chão encontra as colinas.
  double get horizonte => altura * 0.56;

  double x(double fracao) => largura * fracao;

  /// Px do mundo → unidades do bicho (0 = meio do mundo).
  double unidades(double px) => (px - largura / 2) / escala;
  double px(double unidades) => largura / 2 + unidades * escala;

  (double, double) faixa((double, double) f, {double folga = 0}) =>
      (unidades(x(f.$1) + folga), unidades(x(f.$2) - folga));

  /// Onde ele pode andar na terra e na água.
  (double, double) get terra =>
      (unidades(60 * escala / 1.6), unidades(x(ZonasDoMundo.beira) - 18));
  (double, double) get agua =>
      (unidades(x(ZonasDoMundo.beira) + 26), unidades(largura - 50));

  /// A beira, do lado da terra (para pular) e do lado da água (para sair).
  (double, double) get beiraNaTerra => (
    unidades(x(ZonasDoMundo.beira) - 46),
    unidades(x(ZonasDoMundo.beira) - 22),
  );
  (double, double) get beiraNaAgua => (
    unidades(x(ZonasDoMundo.beira) + 28),
    unidades(x(ZonasDoMundo.beira) + 56),
  );

  ZonaDoMundo zonaDe(double px) {
    final f = px / largura;
    if (f < ZonasDoMundo.toca.$2) return ZonaDoMundo.toca;
    if (f < ZonasDoMundo.brinquedos.$2) return ZonaDoMundo.brinquedos;
    if (f < ZonasDoMundo.beira) return ZonaDoMundo.margem;
    return ZonaDoMundo.lagoa;
  }

  /// O centro horizontal de uma zona, em px do mundo.
  double centroDe(ZonaDoMundo z) => switch (z) {
    ZonaDoMundo.toca => x(0.09),
    ZonaDoMundo.margem => x(0.52),
    ZonaDoMundo.brinquedos => x(0.27),
    ZonaDoMundo.lagoa => x(0.85),
  };
}

class MundoDoBaru extends StatefulWidget {
  const MundoDoBaru({
    super.key,
    this.cabecaNaTela,
    this.zonaNaTela,
    this.agora,
  });

  /// Onde está a cabeça dele na tela (para o balão de fala da home).
  final ValueNotifier<Offset?>? cabecaNaTela;

  /// Qual zona a câmera mostra (para os chips de zona da home).
  final ValueNotifier<ZonaDoMundo>? zonaNaTela;

  /// Injetável para o teste ver a cena num horário.
  final DateTime? agora;

  static const mundoKey = Key('mundo-do-baru');

  @override
  State<MundoDoBaru> createState() => MundoDoBaruState();
}

class MundoDoBaruState extends State<MundoDoBaru>
    with SingleTickerProviderStateMixin {
  late final Ticker _relogio;
  Duration _antes = Duration.zero;
  double _t = 0;

  final _camera = ValueNotifier<double>(-1);
  double _camVel = 0;
  double _manualAte = -1;
  final _posicao = ValueNotifier<double>(0);
  final _tempo = ValueNotifier<double>(0);
  final _cabeca = ValueNotifier<Offset?>(null);
  final _interesse = ValueNotifier<InteresseDoBicho?>(null);
  final brinquedos = GlobalKey<BrinquedosDoHabitatState>();

  /// Está na água agora (pulou da beira e a cena o pôs lá).
  bool _naAgua = false;

  /// O que ele escolheu sozinho: ir para a água (true) ou para a terra.
  bool? _escolha;
  ZonaDoMundo _zona = ZonaDoMundo.margem;

  /// O "+3 XP" do carinho, subindo da cabeça.
  String? _premio;
  double _premioDesde = -10;

  GeometriaDoMundo? _g;

  @override
  void initState() {
    super.initState();
    _relogio = createTicker(_tique)..start();
  }

  @override
  void dispose() {
    _relogio.dispose();
    _camera.dispose();
    _posicao.dispose();
    _tempo.dispose();
    _cabeca.dispose();
    _interesse.dispose();
    super.dispose();
  }

  /// Onde a câmera está (px do mundo), para o teste.
  @visibleForTesting
  double get cameraX => _camera.value;

  /// Leva a câmera a uma zona (os chips da home), por alguns segundos.
  void mostra(ZonaDoMundo z) {
    final g = _g;
    if (g == null) return;
    _manualAte = _t + 6;
    _camAlvoManual = (g.centroDe(z) - g.tela.width / 2).clamp(
      0.0,
      g.largura - g.tela.width,
    );
  }

  double? _camAlvoManual;

  void _tique(Duration agora) {
    final dt = _antes == Duration.zero
        ? 1 / 60
        : ((agora - _antes).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _antes = agora;
    _t += dt;
    _tempo.value = _t;
    final g = _g;
    if (g == null) return;
    final petPx = g.px(_posicao.value);
    final maxCam = g.largura - g.tela.width;
    final segue = (petPx - g.tela.width / 2).clamp(0.0, maxCam);
    var cam = _camera.value < 0 ? segue : _camera.value;
    if (_t < _manualAte) {
      final alvo = _camAlvoManual;
      if (alvo != null) {
        cam += (alvo - cam) * (1 - math.exp(-dt * 3));
      } else {
        // Arrasto solto: inércia que morre.
        cam += _camVel * dt;
        _camVel *= math.exp(-dt * 4);
      }
    } else {
      _camAlvoManual = null;
      // A câmera segue o bicho com folga: só anda quando ele chega perto
      // da borda do quadro, e chega devagar.
      final folga = g.tela.width * 0.18;
      final relativo = petPx - cam;
      var alvo = cam;
      if (relativo < folga + g.tela.width * 0.12) {
        alvo = petPx - folga - g.tela.width * 0.12;
      } else if (relativo > g.tela.width - folga - g.tela.width * 0.12) {
        alvo = petPx - g.tela.width + folga + g.tela.width * 0.12;
      }
      cam += (alvo.clamp(0.0, maxCam) - cam) * (1 - math.exp(-dt * 2.2));
    }
    _camera.value = cam.clamp(0.0, maxCam);

    // A cabeça dele na tela, para o balão.
    // O alto da cabeça fica ~140 unidades acima dos pés: o balão para em
    // cima dela, sem cobrir o rosto.
    final y = _naAgua ? g.linhaDagua - 95 * g.escala : g.chao - 142 * g.escala;
    _cabeca.value = Offset(petPx - _camera.value, y);
    widget.cabecaNaTela?.value = _cabeca.value;
    widget.zonaNaTela?.value = g.zonaDe(_camera.value + g.tela.width / 2);

    // A zona dele muda o que a cena pede (dormir só na toca etc.).
    final z = g.zonaDe(petPx);
    if (z != _zona) setState(() => _zona = z);
    if (_premio != null && _t - _premioDesde > 1.6) {
      setState(() => _premio = null);
    }
  }

  // ======================================================================
  // O que o momento pede
  // ======================================================================

  bool _nadador(AppState app) =>
      acaoNoEstagio(app.species, Activity.swim, app.estagioVisivel) ==
      AcaoDoBicho.nado;

  /// Quer estar na água agora?
  bool _querAgua(AppState app) {
    if (!_nadador(app) || app.activity == Activity.nap) return false;
    // O axolote não sai da água.
    if (app.species == Species.axolotl) return true;
    final e = _escolha;
    if (e != null) return e;
    return app.activity == Activity.swim;
  }

  /// A atividade que o desenho recebe, pela zona onde ele está de fato.
  Activity _atividade(AppState app) {
    if (_naAgua) {
      return app.activity == Activity.nap ? Activity.nap : Activity.swim;
    }
    switch (app.activity) {
      case Activity.nap:
        // Dorme na toca; até chegar lá, anda.
        return _zona == ZonaDoMundo.toca ? Activity.nap : Activity.idle;
      case Activity.swim:
        // Quem não nada brinca no canto dos brinquedos.
        if (!_nadador(app)) {
          return _zona == ZonaDoMundo.brinquedos
              ? Activity.swim
              : Activity.idle;
        }
        return Activity.graze;
      case Activity.graze:
      case Activity.idle:
        return app.activity;
    }
  }

  (double, double)? _destino(AppState app, GeometriaDoMundo g) {
    final querAgua = _querAgua(app);
    if (_naAgua) {
      return querAgua ? null : g.beiraNaAgua;
    }
    if (querAgua) return g.beiraNaTerra;
    return switch (app.activity) {
      Activity.nap => g.faixa(ZonasDoMundo.toca, folga: 40),
      Activity.swim =>
        _nadador(app) ? null : g.faixa(ZonasDoMundo.brinquedos, folga: 30),
      _ =>
        _zona == ZonaDoMundo.margem || _zona == ZonaDoMundo.brinquedos
            ? null
            : g.faixa(ZonasDoMundo.margem, folga: 30),
    };
  }

  void _trocaDeLugar(AppState app, bool agua) {
    final g = _g;
    if (g == null || !mounted) return;
    final x = g.px(_posicao.value);
    final naBeira = (x - g.x(ZonasDoMundo.beira)).abs() < 80;
    setState(() {
      if (naBeira) {
        _naAgua = agua;
        _escolha = agua;
      } else {
        // Longe da beira: primeiro vai até ela (o destino cuida disso).
        _escolha = agua;
      }
    });
  }

  void _premia(AppState app) {
    final xp = app.recebeCarinho();
    setState(() {
      _premio = xp > 0
          ? '+$xp ${app.t.xpRotulo}'
          : app.frase(app.t.vinculoTeto);
      _premioDesde = _t;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final agora = widget.agora ?? DateTime.now();
    final luz =
        LuzDaCena.doCenario(app.cenarioAtivo?.id) ??
        LuzDaCena.de(periodoDe(agora));
    final cenario = CenarioDoHabitat.de(app.habitatAtivo.id);
    final itens = itensDeCena.where((i) => app.estaEquipado(i.id)).toList();
    // O axolote começa na água.
    if (app.species == Species.axolotl &&
        app.activity != Activity.nap &&
        !_naAgua &&
        _g == null) {
      _naAgua = true;
    }

    return Semantics(
      image: true,
      label:
          '${app.frase(app.t.humorCap(app.falaDoHumor), app.falaDoHumor.valores)} '
          '${app.frase(app.t.humorSub(app.falaDoHumor), app.falaDoHumor.valores)}',
      child: LayoutBuilder(
        builder: (context, c) {
          final g = GeometriaDoMundo(Size(c.maxWidth, c.maxHeight));
          final primeira = _g == null;
          _g = g;
          if (primeira) {
            // Começa com o bicho no meio da margem, e a câmera nele.
            _camera.value = -1;
          }
          final atividade = _atividade(app);
          final naAgua = _naAgua;
          final baseDaCaixa = naAgua
              ? g.linhaDagua + (150 - PetView.linhaDaguaEm(150)) * g.escala
              : g.chao + 5 * g.escala;
          final palcoK =
              g.x(1 - ZonasDoMundo.beira) / HabitatScene.design.width;
          final palco = Rect.fromLTWH(
            g.x(ZonasDoMundo.beira) - 12,
            g.linhaDagua +
                118 * palcoK * 0.55 -
                HabitatScene.design.height * palcoK,
            HabitatScene.design.width * palcoK,
            HabitatScene.design.height * palcoK,
          );
          return GestureDetector(
            key: MundoDoBaru.mundoKey,
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {
              _camAlvoManual = null;
              _manualAte = _t + 6;
              _camVel = 0;
            },
            onHorizontalDragUpdate: (d) {
              _manualAte = _t + 6;
              _camera.value = (_camera.value - d.delta.dx).clamp(
                0.0,
                g.largura - g.tela.width,
              );
            },
            onHorizontalDragEnd: (d) {
              _manualAte = _t + 6;
              _camVel = -d.velocity.pixelsPerSecond.dx;
            },
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // O fundo em camadas, cada uma com o seu paralaxe.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: FundoDoMundo(
                          g: g,
                          luz: luz,
                          cenario: cenario,
                          camera: _camera,
                          tempo: _tempo,
                        ),
                      ),
                    ),
                  ),
                  // O mundo de verdade, que anda com a câmera.
                  AnimatedBuilder(
                    animation: _camera,
                    builder: (context, filho) => Transform.translate(
                      offset: Offset(-math.max(0.0, _camera.value), 0),
                      child: filho,
                    ),
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: g.largura,
                      maxWidth: g.largura,
                      child: SizedBox(
                        width: g.largura,
                        height: g.altura,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final item in itens)
                              Positioned.fromRect(
                                rect: palco,
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: pintorDeObjetoDaCena(
                                      item,
                                      sx: palcoK,
                                      sy: palcoK,
                                    ),
                                  ),
                                ),
                              ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeInOut,
                              left: 0,
                              width: g.largura,
                              top: baseDaCaixa - 150 * g.escala,
                              height: 150 * g.escala,
                              child: PetView(
                                key: const Key('mundo-pet'),
                                width: g.largura / g.escala,
                                height: 150,
                                scale: g.escala,
                                alignment: Alignment.bottomCenter,
                                areaDeAndar: g.largura / g.escala / 2 - 40,
                                limites: naAgua ? g.agua : g.terra,
                                destino: _destino(app, g),
                                chamadoPelaAgua:
                                    !naAgua && _querAgua(app) ||
                                    naAgua && !_querAgua(app),
                                posicao: _posicao,
                                sombra: true,
                                species: app.species,
                                mood: app.mood,
                                activity: atividade,
                                coat: app.color,
                                estagio: app.estagioVisivel,
                                roupas: app.roupasDoBicho,
                                roupaDeCabeca: app.roupaDeCabeca,
                                aoCarinho: () => _premia(app),
                                interesse: _interesse,
                                aoAlcancar: (tipo, x) =>
                                    brinquedos.currentState?.alcancou(tipo, x),
                                aoMudarDeLugar:
                                    _nadador(app) &&
                                        app.species != Species.axolotl &&
                                        app.activity != Activity.nap
                                    ? (agua) => _trocaDeLugar(app, agua)
                                    : null,
                                ausenciaAoAbrir: Duration(
                                  minutes: app.daysAway > 0
                                      ? app.daysAway * 24 * 60
                                      : 20,
                                ),
                              ),
                            ),
                            if (app.estagioVisivel != EstagioDoBicho.inicio)
                              Positioned.fill(
                                child: BrinquedosDoHabitat(
                                  key: brinquedos,
                                  interesse: _interesse,
                                  rotuloDaBola: app.t.brinqBola,
                                  rotuloDoPetisco: app.t.brinqPetisco,
                                  especie: app.species,
                                  comPote: false,
                                  podeConvidar: app.activity != Activity.nap,
                                  geometria: GeometriaDosBrinquedos(
                                    largura: g.largura,
                                    escala: g.escala,
                                    baseDoBicho: baseDaCaixa,
                                    agua: naAgua,
                                    xMin: g.px(g.terra.$1),
                                    xMax: g.px(g.terra.$2),
                                    xInicialDaBola: g.x(0.27),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // O primeiro plano: capim e flores que passam na frente.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: FrenteDoMundo(
                            g: g,
                            luz: luz,
                            cenario: cenario,
                            camera: _camera,
                            tempo: _tempo,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_premio != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ValueListenableBuilder<Offset?>(
                          valueListenable: _cabeca,
                          builder: (context, o, _) {
                            if (o == null) return const SizedBox.shrink();
                            final sobe = ((_t - _premioDesde) / 1.6).clamp(
                              0.0,
                              1.0,
                            );
                            return Stack(
                              children: [
                                Positioned(
                                  left: o.dx - 90,
                                  width: 180,
                                  top: o.dy - 30 - sobe * 30,
                                  child: Opacity(
                                    opacity: (1 - sobe * sobe).clamp(0.0, 1.0),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Espaco.sm,
                                          vertical: Espaco.xxs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Cores.superficie.withValues(
                                            alpha: 0.94,
                                          ),
                                          borderRadius: Raio.todos(Raio.pilula),
                                          boxShadow: Elevacao.cartao,
                                        ),
                                        child: Text(
                                          _premio!,
                                          style: nunito(
                                            size: 13,
                                            weight: FontWeight.w800,
                                            color: Cores.folha600,
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
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
