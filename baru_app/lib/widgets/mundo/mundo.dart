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
  /// [baixo]: quanto do pé da tela o painel de baixo cobre. O mundo se
  /// arruma na parte que se vê: em 320×640 o chão a 70% da tela inteira
  /// caía atrás do painel, e o bicho ficava sem pés.
  GeometriaDoMundo(this.tela, {double baixo = 0})
    : largura = tela.width * ZonasDoMundo.telas,
      visivel = math.max(tela.height * 0.5, tela.height - baixo),
      escala =
          (math.min(
                    tela.width / 412,
                    math.max(tela.height * 0.5, tela.height - baixo) / 725,
                  ) *
                  1.6)
              .clamp(1.0, 2.2);

  final Size tela;
  final double largura;

  /// A altura que fica à vista, acima do painel.
  final double visivel;

  /// Px por unidade do desenho do bicho.
  final double escala;

  double get altura => tela.height;

  /// Onde ficam os pés dele na terra, e a lâmina d'água da lagoa.
  double get chao => visivel * 0.86;
  double get linhaDagua => visivel * 0.905;

  /// A linha do horizonte, onde o chão encontra as colinas.
  double get horizonte => visivel * 0.69;

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
  const MundoDoBaru({super.key, this.cabecaNaTela, this.agora});

  /// Onde está a cabeça dele na tela (para o balão de fala da home).
  final ValueNotifier<Offset?>? cabecaNaTela;

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
  final _topoDoPet = ValueNotifier<Offset?>(null);
  final _tempo = ValueNotifier<double>(0);
  final _cabeca = ValueNotifier<Offset?>(null);
  final _interesse = ValueNotifier<InteresseDoBicho?>(null);
  final brinquedos = GlobalKey<BrinquedosDoHabitatState>();

  /// Está na água agora (pulou da beira e a cena o pôs lá).
  bool _naAgua = false;

  /// O que ele escolheu sozinho: ir para a água (true) ou para a terra.
  bool? _escolha;

  /// A atividade que o humor pedia da última vez: quando muda, a escolha
  /// dele de antes deixa de valer (auditoria de d59006a, 3).
  Activity? _pedidoAntes;
  ZonaDoMundo _zona = ZonaDoMundo.margem;

  /// O "+3 XP" do carinho, subindo da cabeça.
  String? _premio;
  double _premioDesde = -10;

  GeometriaDoMundo? _g;
  bool _parado = false;
  bool? _aguaAntes;

  // --- o passeio do tempo livre -----------------------------------------
  // Sem nada pedindo outra coisa, ele ficava a manhã inteira no mesmo
  // palmo da margem: o mundo tinha 2,6 telas e ele usava uma. Bicho tem
  // área de vida e a percorre (pesquisa 22): de tempos em tempos escolhe
  // um canto — a toca, os brinquedos, outro trecho da margem —, vai até lá
  // e fica um pouco.
  final _sorte = math.Random();
  bool _livre = false;
  (double, double)? _passeio;
  double _chegouNoPasseio = -1;
  double _ficaNoPasseio = 0;
  double _proximoPasseio = 18 + math.Random().nextDouble() * 20;

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
    _topoDoPet.dispose();
    _tempo.dispose();
    _cabeca.dispose();
    _interesse.dispose();
    super.dispose();
  }

  /// Onde a câmera está (px do mundo), para o teste.
  @visibleForTesting
  double get cameraX => _camera.value;

  void _tique(Duration agora) {
    final dt = _antes == Duration.zero
        ? 1 / 60
        : ((agora - _antes).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _antes = agora;
    _t += dt;
    // Sem movimento pedido o capim e as nuvens param: nada redesenha o
    // fundo a cada quadro (auditoria, 7).
    if (!_parado) _tempo.value = _t;
    final g = _g;
    if (g == null) return;
    final petPx = g.px(_posicao.value);
    final maxCam = g.largura - g.tela.width;
    final segue = (petPx - g.tela.width / 2).clamp(0.0, maxCam);
    var cam = _camera.value < 0 ? segue : _camera.value;
    if (_t < _manualAte) {
      // Arrasto solto: inércia que morre.
      cam += _camVel * dt;
      _camVel *= math.exp(-dt * 4);
    } else {
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
      // Correndo, a câmera mansa ficava para trás e ele saía pela borda.
      // Mansa até onde der; o corpo inteiro, sempre no quadro.
      final margem = 90 * g.escala;
      if (g.tela.width > 2 * margem) {
        cam = cam.clamp(petPx - g.tela.width + margem, petPx - margem);
      }
    }
    _camera.value = cam.clamp(0.0, maxCam);

    // A cabeça dele na tela, para o balão: o alto da cabeça que o próprio
    // bicho informa. A conta pela linha do chão errava de espécie para
    // espécie e não acompanhava pulo nem voo, e o balão cobria o rosto.
    // Parado (movimento reduzido), o bicho não informa nada: vale a conta
    // pela linha do chão.
    final topo = _topoDoPet.value;
    final caixa = context.findRenderObject();
    if (topo != null && caixa is RenderBox && caixa.attached) {
      // Só a altura vem do bicho; o x é o desta câmera, que o desenho só
      // aplica no quadro seguinte.
      _cabeca.value = Offset(
        petPx - _camera.value,
        caixa.globalToLocal(topo).dy,
      );
    } else {
      final y = _naAgua
          ? g.linhaDagua - 95 * g.escala
          : g.chao - 142 * g.escala;
      _cabeca.value = Offset(petPx - _camera.value, y);
    }
    widget.cabecaNaTela?.value = _cabeca.value;

    // A zona dele muda o que a cena pede (dormir só na toca etc.).
    final z = g.zonaDe(petPx);
    if (z != _zona) setState(() => _zona = z);
    _passeia(g);
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
    // O axolote não sai da água.
    if (app.species == Species.axolotl) return true;
    if (!_nadador(app) || app.activity == Activity.nap) return false;
    final e = _escolha;
    if (e != null) return e;
    return app.activity == Activity.swim;
  }

  /// A atividade que o desenho recebe, pela zona onde ele está de fato.
  Activity _atividade(AppState app) {
    if (_parado && !_naAgua) {
      // Parado ele não anda até a zona: dorme, come ou fica onde está.
      // Nadar fora d'água não existe; quem não nada, brinca ali mesmo.
      return app.activity == Activity.swim && _nadador(app)
          ? Activity.idle
          : app.activity;
    }
    if (_naAgua) {
      return app.activity == Activity.nap ? Activity.nap : Activity.swim;
    }
    switch (app.activity) {
      case Activity.nap:
        // Dorme na toca — no buraco, não na fronteira da zona: dormindo
        // ele para de andar, e dormia na beira, meio em cima da entrada.
        final g = _g;
        if (g == null) return Activity.idle;
        final f = g.faixa(ZonasDoMundo.toca, folga: 40);
        final u = _posicao.value;
        return u >= f.$1 - 4 && u <= f.$2 + 4 ? Activity.nap : Activity.idle;
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
    if (_parado) return null;
    final querAgua = _querAgua(app);
    if (_naAgua) {
      if (app.species == Species.axolotl) return null;
      return querAgua ? null : g.beiraNaAgua;
    }
    if (querAgua) return g.beiraNaTerra;
    return switch (app.activity) {
      Activity.nap => g.faixa(ZonasDoMundo.toca, folga: 40),
      Activity.swim =>
        _nadador(app) ? null : g.faixa(ZonasDoMundo.brinquedos, folga: 30),
      _ =>
        _passeio ??
            (_zona == ZonaDoMundo.margem || _zona == ZonaDoMundo.brinquedos
                ? null
                : g.faixa(ZonasDoMundo.margem, folga: 30)),
    };
  }

  void _passeia(GeometriaDoMundo g) {
    final p = _passeio;
    if (!_livre) {
      if (p != null) setState(() => _passeio = null);
      return;
    }
    if (p == null) {
      if (_t < _proximoPasseio) return;
      // Um trecho de 8% do mundo dentro de um canto que não é onde ele está.
      // A zona pela posição dele na terra, e não pela `_zona` do quadro
      // anterior: logo depois de sair da água ela ainda dizia "lagoa" e o
      // passeio caía no trecho onde ele já estava (auditoria).
      final aqui = g.zonaDe(g.px(_posicao.value.clamp(g.terra.$1, g.terra.$2)));
      final cantos = [
        ZonasDoMundo.toca,
        ZonasDoMundo.brinquedos,
        ZonasDoMundo.margem,
      ].where((c) => g.zonaDe(g.x((c.$1 + c.$2) / 2)) != aqui).toList();
      final c = cantos[_sorte.nextInt(cantos.length)];
      final largura = math.min(0.08, c.$2 - c.$1);
      final a = c.$1 + _sorte.nextDouble() * (c.$2 - c.$1 - largura);
      setState(() {
        _passeio = g.faixa((a, a + largura));
        _chegouNoPasseio = -1;
        _ficaNoPasseio = 12 + _sorte.nextDouble() * 16;
      });
      return;
    }
    final u = _posicao.value;
    if (u < p.$1 - 4 || u > p.$2 + 4) return;
    if (_chegouNoPasseio < 0) {
      _chegouNoPasseio = _t;
    } else if (_t - _chegouNoPasseio > _ficaNoPasseio) {
      setState(() {
        _passeio = null;
        _proximoPasseio = _t + 25 + _sorte.nextDouble() * 35;
      });
    }
  }

  bool _brincaNoCanto(AppState app) =>
      !_parado &&
      app.activity == Activity.swim &&
      !_nadador(app) &&
      _zona == ZonaDoMundo.brinquedos;

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
    _parado = Movimento.reduzido(context);
    // Ovo e ninho não andam: escolher passeio para eles deixava um alvo
    // velho esperando o bicho crescer (auditoria).
    _livre =
        !_parado &&
        !_naAgua &&
        app.estagioVisivel != EstagioDoBicho.inicio &&
        (app.activity == Activity.idle || app.activity == Activity.graze);
    // O axolote mora na água, dormindo inclusive (descansa no fundo). Só
    // "começar" nela deixava preso na beira quem abria o app no cochilo
    // (auditoria, 4).
    if (app.species == Species.axolotl) _naAgua = true;
    if (_pedidoAntes != app.activity) {
      _pedidoAntes = app.activity;
      _escolha = null;
    }

    // O balão já diz a fala: o mundo só se apresenta (repetir a fala aqui
    // fazia o leitor de tela ler duas vezes; auditoria, 11).
    return Semantics(
      image: true,
      label: app.displayName,
      child: LayoutBuilder(
        builder: (context, c) {
          // O pé é a altura medida do painel. Com outra coisa por cima (uma
          // folha, uma tela de detalhe entrando) o mundo fica como estava:
          // o corpo encolhia no meio da transição e o chão pulava 150 px
          // (auditoria de dcf82c9, 2).
          final anterior = _g;
          final GeometriaDoMundo g;
          if (anterior != null && !(ModalRoute.isCurrentOf(context) ?? true)) {
            g = anterior;
          } else {
            g = GeometriaDoMundo(
              Size(c.maxWidth, c.maxHeight),
              baixo: app.alturaDoPainel > 0
                  ? app.alturaDoPainel
                  : MediaQuery.paddingOf(context).bottom,
            );
          }
          final primeira = _g == null;
          _g = g;
          if (primeira) {
            // Começa com o bicho no meio da margem, e a câmera nele.
            _camera.value = -1;
          }
          final atividade = _atividade(app);
          final naAgua = _naAgua;
          // Só a troca de terra para água (e de volta) desliza. Quando o
          // chão muda porque o painel foi medido, ele vai junto na hora:
          // deslizando, ele nascia atrás do painel e subia (auditoria).
          final trocouDeMeio = _aguaAntes != null && _aguaAntes != naAgua;
          _aguaAntes = naAgua;
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
                  // O mundo de verdade, que anda com a câmera. A caixa tem a
                  // largura do mundo inteiro: com um `OverflowBox` de uma
                  // tela, o toque só valia no primeiro terço do mundo e o
                  // bicho, a bola e o pote não respondiam (auditoria, 1).
                  Positioned(
                    left: 0,
                    top: 0,
                    width: g.largura,
                    height: g.altura,
                    child: AnimatedBuilder(
                      animation: _camera,
                      builder: (context, filho) => Transform.translate(
                        offset: Offset(-math.max(0.0, _camera.value), 0),
                        child: filho,
                      ),
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
                              duration: trocouDeMeio
                                  ? const Duration(milliseconds: 450)
                                  : Duration.zero,
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
                                // Brincando no canto, o canto é o limite: a
                                // disparada passava da zona, a cena trocava a
                                // brincadeira por "parado" e ele voltava, em
                                // ciclo (auditoria, 10).
                                limites: naAgua
                                    ? g.agua
                                    : _brincaNoCanto(app)
                                    ? g.faixa(ZonasDoMundo.brinquedos)
                                    : g.terra,
                                destino: _destino(app, g),
                                naAgua: naAgua,
                                chamadoPelaAgua:
                                    !naAgua && _querAgua(app) ||
                                    naAgua && !_querAgua(app),
                                posicao: _posicao,
                                topoNaTela: _topoDoPet,
                                sombra: true,
                                corDaAgua: Color.lerp(
                                  cenario.aguaCom(luz.agua),
                                  cenario.aguaFundaCom(luz.aguaFunda),
                                  0.35,
                                ),
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
                                        app.species != Species.axolotl
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
                                  // O pote é uma coisa do mundo, no chão da
                                  // margem, perto de onde ele nasce — não um
                                  // botão por cima da cena.
                                  ondeDoPote: Offset(g.x(0.42), g.chao),
                                  podeConvidar: app.activity != Activity.nap,
                                  // A bola e o pote moram na terra, mesmo com
                                  // ele nadando: com o chão da água, a bola
                                  // afundava no gramado (auditoria, 5).
                                  geometria: GeometriaDosBrinquedos(
                                    largura: g.largura,
                                    escala: g.escala,
                                    baseDoBicho: g.chao + 5 * g.escala,
                                    xMin: g.px(g.terra.$1),
                                    xMax: g.px(g.terra.$2),
                                    // À vista quando a home abre: no canto
                                    // dos brinquedos ela nascia fora da tela
                                    // e ninguém sabia que havia bola.
                                    xInicialDaBola: g.x(0.6),
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
