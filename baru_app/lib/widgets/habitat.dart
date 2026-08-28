import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'pet.dart';

/// O desenho de um habitat da trilha: que terra é aquela.
///
/// Separado de [LuzDaCena] porque as duas coisas respondem a perguntas
/// diferentes e mudam por motivos diferentes. A luz é **quando** — 22h
/// escurece a água em qualquer lugar. O habitat é **onde** — o igarapé é
/// fechado e escuro às duas da tarde também. Se o habitat trocasse a cor
/// crua, a noite sumiria dentro dele; por isso ele entra como *tinta* por
/// cima da luz, com [forca] dizendo o quanto puxa.
class CenarioDoHabitat {
  const CenarioDoHabitat({
    required this.id,
    required this.agua,
    required this.aguaFunda,
    required this.colina,
    required this.areia,
    this.forca = 0.62,
    this.linhaDagua = 118,
    this.colinaTras = 130,
    this.colinaFrente = 140,
    this.pico = 0,
    this.faixaDeAreia = 1,
  });

  final String id;

  final Color agua;
  final Color aguaFunda;
  final Color colina;
  final Color areia;

  /// Quanto o lugar puxa a cor da luz para a dele, de 0 a 1.
  final double forca;

  /// Altura da lâmina d'água, em unidades do design, medida do fundo.
  final double linhaDagua;

  /// Altura das duas colinas, em unidades do design.
  final double colinaTras;
  final double colinaFrente;

  /// 0 = duna redonda; 1 = pico de serra.
  ///
  /// Uma silhueta só para os dois, interpolada — dois desenhos separados
  /// sairiam do lugar um em relação ao outro na primeira vez que alguém
  /// mexesse na deriva. Ver [silhuetaDeColina].
  final double pico;

  /// Multiplicador da faixa de areia. Praia tem margem larga; serra quase não
  /// tem.
  final double faixaDeAreia;

  Color aguaCom(Color luz) => Color.lerp(luz, agua, forca) ?? agua;
  Color aguaFundaCom(Color luz) =>
      Color.lerp(luz, aguaFunda, forca) ?? aguaFunda;
  Color colinaCom(Color luz) => Color.lerp(luz, colina, forca) ?? colina;
  Color areiaCom(Color luz) => Color.lerp(luz, areia, forca) ?? areia;

  /// O desenho de cada habitat da trilha.
  ///
  /// A `lagoa` tem [forca] zero de propósito: é a cena que já existia, e o
  /// primeiro dia de quem instala o app não pode mudar de aparência por causa
  /// de uma refatoração.
  static const porId = <String, CenarioDoHabitat>{
    'lagoa': CenarioDoHabitat(
      id: 'lagoa',
      agua: Color(0xFFC9DCC0),
      aguaFunda: Color(0xFFAECBA3),
      colina: Color(0xFFC5D8B6),
      areia: Color(0xFFE9D6B6),
      forca: 0,
    ),
    'igarape': CenarioDoHabitat(
      id: 'igarape',
      agua: Color(0xFF7FA07A),
      aguaFunda: Color(0xFF5A7A5C),
      colina: Color(0xFF8AAC72),
      areia: Color(0xFFC7B994),
      linhaDagua: 112,
      colinaTras: 152,
      colinaFrente: 164,
      pico: 0.18,
      faixaDeAreia: 0.7,
    ),
    'manguezal': CenarioDoHabitat(
      id: 'manguezal',
      agua: Color(0xFF9C9A6A),
      aguaFunda: Color(0xFF7A7852),
      colina: Color(0xFF7E9469),
      areia: Color(0xFFC0AF84),
      linhaDagua: 128,
      colinaTras: 118,
      colinaFrente: 126,
      faixaDeAreia: 1.5,
    ),
    'serra': CenarioDoHabitat(
      id: 'serra',
      agua: Color(0xFF8FB4C4),
      aguaFunda: Color(0xFF67909F),
      colina: Color(0xFF97A49E),
      areia: Color(0xFFBFB4A3),
      linhaDagua: 94,
      colinaTras: 182,
      colinaFrente: 196,
      pico: 0.86,
      faixaDeAreia: 0.5,
    ),
    'praia': CenarioDoHabitat(
      id: 'praia',
      agua: Color(0xFF7FC7C4),
      aguaFunda: Color(0xFF4A9CA1),
      colina: Color(0xFFCCC5A4),
      areia: Color(0xFFF0DEB8),
      linhaDagua: 132,
      colinaTras: 92,
      colinaFrente: 100,
      faixaDeAreia: 1.9,
    ),
    'ilha': CenarioDoHabitat(
      id: 'ilha',
      agua: Color(0xFF5FB0C9),
      aguaFunda: Color(0xFF37809E),
      colina: Color(0xFF7DA968),
      areia: Color(0xFFF2E1C1),
      linhaDagua: 142,
      colinaTras: 108,
      colinaFrente: 86,
      pico: 0.38,
      faixaDeAreia: 1.4,
    ),
  };

  /// O desenho de um habitat. Cai na lagoa quando o id não é conhecido — um
  /// snapshot de versão futura não pode deixar a cena em branco.
  static CenarioDoHabitat de(String? id) => porId[id] ?? porId['lagoa']!;
}

/// Paleta da cena para um momento do dia.
///
/// A luz é o que faz o habitat parecer um lugar e não um fundo: às 22h a água
/// escurece, o céu vira índigo e a lua substitui o sol.
class LuzDaCena {
  const LuzDaCena({
    required this.ceuAlto,
    required this.ceuBaixo,
    required this.astro,
    required this.haloAstro,
    required this.agua,
    required this.aguaFunda,
    required this.colina,
    required this.areia,
    required this.brilho,
    required this.sombraAmbiente,
    required this.astroAlto,
  });

  final Color ceuAlto;
  final Color ceuBaixo;
  final Color astro;
  final Color haloAstro;
  final Color agua;
  final Color aguaFunda;
  final Color colina;
  final Color areia;

  /// Reflexo na água.
  final Color brilho;

  /// Escurecimento geral aplicado por cima, para a noite pesar.
  final Color sombraAmbiente;

  /// 0 = astro no horizonte, 1 = a pino.
  final double astroAlto;

  /// A luz que o cenário comprado impõe.
  ///
  /// Cenário é o mundo: quando há um, ele ganha da hora do dia. Sem isso,
  /// comprar "noite estrelada" às 14h não mudaria nada e o item pareceria
  /// quebrado.
  static LuzDaCena? doCenario(String? id) {
    switch (id) {
      case 'entardecer':
        return de(PeriodoDoDia.entardecer);
      case 'noite_estrelada':
        return de(PeriodoDoDia.noite);
      case 'chuva':
        return const LuzDaCena(
          ceuAlto: Color(0xFF8A9AAB),
          ceuBaixo: Color(0xFFAFBDC7),
          astro: Color(0x00000000),
          haloAstro: Color(0x00000000),
          agua: Color(0xFF8FA3A8),
          aguaFunda: Color(0xFF75898F),
          colina: Color(0xFF8FA091),
          areia: Color(0xFFB4AC9C),
          brilho: Color(0x44E8F0F4),
          sombraAmbiente: Color(0x1A2A3440),
          astroAlto: 0.5,
        );
      case 'neblina':
        return const LuzDaCena(
          ceuAlto: Color(0xFFE4E0D6),
          ceuBaixo: Color(0xFFF2EEE4),
          astro: Color(0x66FFF0D0),
          haloAstro: Color(0x33FFF0D0),
          agua: Color(0xFFD3D7CB),
          aguaFunda: Color(0xFFBEC3B7),
          colina: Color(0xFFD6DAC9),
          areia: Color(0xFFE3DCCB),
          brilho: Color(0x55FFFFFF),
          sombraAmbiente: Color(0x0DFFFFFF),
          astroAlto: 0.72,
        );
      default:
        return null;
    }
  }

  static LuzDaCena de(PeriodoDoDia p) {
    switch (p) {
      case PeriodoDoDia.amanhecer:
        return const LuzDaCena(
          ceuAlto: Color(0xFFF6D9B0),
          ceuBaixo: Color(0xFFF9E9CF),
          astro: Color(0xFFFFC98A),
          haloAstro: Color(0x55FFB870),
          agua: Color(0xFFCFDCC4),
          aguaFunda: Color(0xFFB5C8A8),
          colina: Color(0xFFCBD6B4),
          areia: Color(0xFFE8D5B4),
          brilho: Color(0x66FFF3E0),
          sombraAmbiente: Color(0x0D3E2F23),
          astroAlto: 0.22,
        );
      case PeriodoDoDia.dia:
        return const LuzDaCena(
          ceuAlto: Color(0xFFF4E6CB),
          ceuBaixo: Color(0xFFFAF1E3),
          astro: Color(0xFFFFD79A),
          haloAstro: Color(0x44EF8354),
          agua: Color(0xFFC9DCC0),
          aguaFunda: Color(0xFFAECBA3),
          colina: Color(0xFFC5D8B6),
          areia: Color(0xFFE9D6B6),
          brilho: Color(0x88FFFFFF),
          sombraAmbiente: Color(0x00000000),
          astroAlto: 0.86,
        );
      case PeriodoDoDia.entardecer:
        return const LuzDaCena(
          ceuAlto: Color(0xFFF3C9A0),
          ceuBaixo: Color(0xFFF9DFC0),
          astro: Color(0xFFFF9E5E),
          haloAstro: Color(0x66EF8354),
          agua: Color(0xFFC2CFAE),
          aguaFunda: Color(0xFFA6B896),
          colina: Color(0xFFB9C6A2),
          areia: Color(0xFFE0C39C),
          brilho: Color(0x77FFD9A8),
          sombraAmbiente: Color(0x143E2F23),
          astroAlto: 0.16,
        );
      case PeriodoDoDia.noite:
        return const LuzDaCena(
          ceuAlto: Color(0xFF4A4763),
          ceuBaixo: Color(0xFF7A7189),
          astro: Color(0xFFE8E6F2),
          haloAstro: Color(0x44CFD6F0),
          agua: Color(0xFF5B6B63),
          aguaFunda: Color(0xFF47554F),
          colina: Color(0xFF5E6660),
          areia: Color(0xFF8A7E6E),
          brilho: Color(0x55D6DCF5),
          sombraAmbiente: Color(0x33232033),
          astroAlto: 0.74,
        );
    }
  }
}

/// A cena do habitat.
///
/// Sete camadas com paralaxe própria: céu, astro, colinas, areia, água,
/// itens e companheiro — mais vinheta e luz ambiente por cima. Antes era um
/// retângulo de cor única com formas absolutas em cima.
class HabitatScene extends StatefulWidget {
  const HabitatScene({
    super.key,
    this.height = alturaPadrao,
    this.animado = true,
    this.agora,
  });

  /// Altura da cena na home.
  ///
  /// Eram 296 px, herdados do HTML de referência. O bicho é o produto e
  /// dividia a primeira dobra com meia dúzia de cartões; a cena cresceu 26%
  /// para ele caber grande. A home rola, então nada foi empurrado para fora —
  /// só desceu.
  static const alturaPadrao = 372.0;

  /// Quanto o companheiro ocupa da cena.
  ///
  /// Era 0,82 fixo, e fixo estava errado por dois motivos: não acompanhava a
  /// cena quando ela mudava de tamanho, e não encolhia em tela estreita. Agora
  /// multiplica a escala da cena — o bicho é sempre a mesma fração do quadro,
  /// e passou de 0,82 para 1,34 (+63% de lado, mais que o dobro de área).
  static const presencaDoPet = 1.34;

  final double height;

  /// porque vazamento de memória não aparece na tela nem no teste de widget.
  @visibleForTesting
  static ValueNotifier<int>? observadorDeChegadas;

  /// Desligado em miniaturas e capturas.
  final bool animado;

  /// Injetável para o teste conseguir olhar a cena às 22h.
  final DateTime? agora;

  /// Largura útil do HTML: frame 412 − padding 20+20.
  static const design = Size(372, 296);

  static const cenaKey = Key('habitat-cena');

  @override
  State<HabitatScene> createState() => _HabitatSceneState();
}

class _HabitatSceneState extends State<HabitatScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// Deriva contínua e lenta que move as camadas em velocidades diferentes.
  late final AnimationController _deriva = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  /// O "+3 XP" que sobe quando um afago é concluído.
  late final AnimationController _premio = AnimationController(
    vsync: this,
    duration: Tempo.celebracao,
    animationBehavior: AnimationBehavior.preserve,
  );
  String? _textoDoPremio;

  /// Quantos controllers de chegada estão vivos. Nulo em produção — existe

  /// Itens que já estavam na cena. Item novo entra animado.
  Set<String> _jaVistos = {};
  final Map<String, AnimationController> _chegadas = {};

  bool _continuo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Cena escondida não deriva. Mesmo motivo do companheiro: `repeat()` pede
  /// quadro para sempre, e app fora da tela não tem quadro para dar.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (!mounted) return;
    if (estado == AppLifecycleState.resumed) {
      _ajustaContinuo();
    } else {
      _paraContinuo();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ajustaContinuo();
  }

  void _ajustaContinuo() {
    if (widget.animado && !Movimento.reduzido(context)) {
      if (!_continuo) {
        _continuo = true;
        _deriva.repeat(reverse: true);
      }
    } else {
      _paraContinuo();
    }
  }

  void _paraContinuo() {
    _continuo = false;
    _deriva
      ..stop()
      ..value = 0.5;
  }

  void _sincronizaChegadas(List<String> possuidos) {
    // Quem saiu da cena leva o controller junto.
    //
    // **Isto vazava memória.** Antes um item nunca saía do habitat, então
    // ninguém reparava; com o botão "Tirar" da loja nova, cada retirada
    // deixava um `AnimationController` órfão no mapa, e recolocar o item
    // criava outro por cima sem descartar o primeiro. Colocar e tirar em
    // sequência acumula um por vez.
    //
    // Não é a causa do assert do Flutter web: a chegada é um `forward()` que
    // termina, e controller parado não pede quadro. Quem pede quadro para
    // sempre é `repeat()` — e disso cuida a pausa por ciclo de vida.
    final agora = possuidos.toSet();
    for (final id in _chegadas.keys.toList()) {
      if (agora.contains(id)) continue;
      _chegadas.remove(id)!.dispose();
    }

    for (final id in possuidos) {
      if (_jaVistos.contains(id)) continue;
      // Substituir sem descartar é a outra metade do mesmo vazamento.
      _chegadas.remove(id)?.dispose();
      final c = AnimationController(
        vsync: this,
        duration: Tempo.celebracao,
        animationBehavior: AnimationBehavior.preserve,
      );
      _chegadas[id] = c;
      // Primeira montagem não é chegada: o habitat já vinha com os itens.
      if (_jaVistos.isEmpty && possuidos.length > 1) {
        c.value = 1;
      } else {
        c.forward();
      }
    }
    _jaVistos = possuidos.toSet();
    HabitatScene.observadorDeChegadas?.value = _chegadas.length;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _premio.dispose();
    _deriva.dispose();
    for (final c in _chegadas.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Um afago terminou. Credita e mostra o que ele rendeu.
  ///
  /// Passado o teto do dia o vínculo continua subindo mas o XP não — e dizer
  /// isso é melhor do que não mostrar nada, que pareceria bug.
  void _premia(AppState app) {
    final xp = app.recebeCarinho();
    setState(() {
      _textoDoPremio = xp > 0 ? '+$xp ${app.t.xpRotulo}' : app.frase(app.t.vinculoTeto);
    });
    _premio.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Cenário comprado ganha da hora do dia — é isso que se compra.
    final luz = LuzDaCena.doCenario(app.cenarioAtivo?.id) ??
        LuzDaCena.de(periodoDe(widget.agora ?? DateTime.now()));
    // O lugar vem da trilha; a luz, da hora e da loja. As duas se somam em
    // vez de disputar: o igarapé continua sendo igarapé às 22h.
    final cenario = CenarioDoHabitat.de(app.habitatAtivo.id);
    _sincronizaChegadas(app.objetosNaCena);

    final possuidos =
        itensDeCena.where((i) => app.estaEquipado(i.id)).toList();

    return Semantics(
      image: true,
      label: app.t.fill(app.t.moodCap(app.moodKey), {'n': app.displayName}),
      child: RepaintBoundary(
        key: HabitatScene.cenaKey,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: Raio.todos(Raio.cena),
            boxShadow: Elevacao.cena,
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, c) {
              final sx = c.maxWidth / HabitatScene.design.width;
              // A altura vem da medida real, não de `widget.height`.
              // A folha de compartilhamento encaixa a cena num
              // `SizedBox(296)`: o `Container` acata a restrição apertada do
              // pai e fica em 296, enquanto `widget.height` continuaria
              // dizendo 372 — céu, água e bicho sairiam do lugar na
              // miniatura e no PNG compartilhado.
              final alturaReal =
                  c.maxHeight.isFinite ? c.maxHeight : widget.height;
              final sy = alturaReal / HabitatScene.design.height;
              // O bicho acompanha o menor dos dois: cresce com a cena e
              // encolhe em tela estreita, sem nunca encostar na borda.
              final escalaDoPet =
                  HabitatScene.presencaDoPet * math.min(sx, sy);
              return AnimatedBuilder(
                animation: Listenable.merge([_deriva, ..._chegadas.values]),
                builder: (context, _) {
                  final fase = _deriva.value;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _FundoDaCena(
                          sx: sx,
                          sy: sy,
                          luz: luz,
                          cenario: cenario,
                          fase: fase,
                        ),
                      ),
                      for (final item in possuidos)
                        for (final p in item.parts)
                          _peca(item.id, p, sx, sy),
                      // O companheiro ocupa o lugar da cena que combina com
                      // o que está fazendo: dentro d'água ao nadar, na
                      // margem ao pastar, na areia ao cochilar.
                      //
                      // A sombra sobe com a escala do bicho, não com a da
                      // cena: os pés dele ficam a ~26 unidades do chão da
                      // caixa de 150 px, e é a escala que decide onde isso
                      // cai. Presa ao `sy`, a sombra ficaria no tornozelo.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: _alturaDoPet(app.activity) * sy +
                            26 * escalaDoPet,
                        child: Center(
                          child: Container(
                            width: 141 * escalaDoPet,
                            height: 13 * sy,
                            decoration: BoxDecoration(
                              color: Cores.tintaA(
                                app.activity == Activity.swim ? 0.07 : 0.13,
                              ),
                              borderRadius: Raio.todos(Raio.pilula),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: _alturaDoPet(app.activity) * sy,
                        child: Center(
                          child: PetView(
                            species: app.species,
                            mood: app.mood,
                            activity: app.activity,
                            coat: app.color,
                            scale: escalaDoPet,
                            alignment: Alignment.bottomCenter,
                            interativo: widget.animado,
                            aoCarinho: () => _premia(app),
                            roupas: app.roupasDoBicho,
                            roupaDeCabeca: app.roupaDeCabeca,
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          painter: _LuzEVinheta(luz: luz),
                        ),
                      ),
                      if (_textoDoPremio != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          // Acima da cabeça, e a cabeça sobe com a escala.
                          bottom: _alturaDoPet(app.activity) * sy +
                              118 * escalaDoPet,
                          child: IgnorePointer(
                            child: _PremioSubindo(
                              anima: _premio,
                              texto: _textoDoPremio!,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// Onde o companheiro se apoia, em unidades do design, medido do fundo.
  double _alturaDoPet(Activity a) {
    switch (a) {
      case Activity.swim:
        return 34; // dentro d'água, o corpo afunda um pouco
      case Activity.nap:
        return 52; // deitado na areia
      case Activity.graze:
        return 62; // na margem, mais alto
      case Activity.idle:
        return 56;
    }
  }

  /// Uma peça de item. Entra caindo com mola quando é comprada.
  Widget _peca(String itemId, ShapePart p, double sx, double sy) {
    final chegada = _chegadas[itemId];
    final t = chegada == null
        ? 1.0
        : Curves.easeOutBack.transform(chegada.value.clamp(0.0, 1.0));
    final queda = (1 - t) * 26 * sy;
    return Positioned(
      left: p.x * sx,
      top: p.y * sy - queda,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.4 * t,
          child: Container(
            width: p.w * sx,
            height: p.h * sy,
            decoration: BoxDecoration(
              color: p.c,
              borderRadius: Raio.todos(p.r * sx),
              // Sombra curta: sem ela a peça parece adesivo colado no fundo.
              boxShadow: [
                BoxShadow(
                  color: Cores.tintaA(0.13),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A silhueta de uma colina, de duna a pico.
///
/// Antes as colinas eram `RRect` com raio no topo, e `pico` só encolhia esse
/// raio — o que dá bloco de canto arredondado, não montanha. A serra saía
/// parecendo prédio.
///
/// Uma curva só serve os dois extremos: com [pico] em 0 os controles ficam a
/// 0,5523·r do ápice, que é a aproximação canônica de um arco de círculo — o
/// mesmo domo do `RRect` de antes, com o mesmo trecho reto de flanco. Com
/// [pico] em 1 os controles colapsam no ápice e a curva vira duas retas.
Path silhuetaDeColina({
  required double esquerda,
  required double base,
  required double largura,
  required double altura,
  required double pico,
}) {
  final meio = esquerda + largura / 2;
  final direita = esquerda + largura;
  final topo = base - altura;
  final raio = largura / 2;

  // Onde o flanco reto termina. Na duna é o que sobra abaixo da meia-lua; no
  // pico é quase nada, para a subida começar cedo.
  final retaDeDuna = (altura - raio).clamp(0.0, altura);
  final reta = retaDeDuna + (altura * 0.18 - retaDeDuna) * pico;
  final ombro = base - reta;
  final puxa = 0.5523 * (1 - pico);

  return Path()
    ..moveTo(esquerda, base)
    ..lineTo(esquerda, ombro)
    ..cubicTo(
      esquerda,
      ombro - (ombro - topo) * puxa,
      meio - raio * puxa,
      topo,
      meio,
      topo,
    )
    ..cubicTo(
      meio + raio * puxa,
      topo,
      direita,
      ombro - (ombro - topo) * puxa,
      direita,
      ombro,
    )
    ..lineTo(direita, base)
    ..close();
}

/// Céu, astro, colinas, areia e água — cada camada com a sua deriva.
class _FundoDaCena extends CustomPainter {
  const _FundoDaCena({
    required this.sx,
    required this.sy,
    required this.luz,
    required this.cenario,
    required this.fase,
  });

  final double sx;
  final double sy;
  final LuzDaCena luz;
  final CenarioDoHabitat cenario;
  final double fase;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final corDaColina = cenario.colinaCom(luz.colina);
    final corDaAreia = cenario.areiaCom(luz.areia);

    // --- céu: gradiente, não cor chapada -----------------------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [luz.ceuAlto, luz.ceuBaixo],
        ).createShader(Offset.zero & size),
    );

    // --- astro com halo ----------------------------------------------------
    final ax = w - 54 * sx;
    final ay = h * (0.30 - luz.astroAlto * 0.20) + math.sin(fase * math.pi) * 2;
    canvas.drawCircle(Offset(ax, ay), 46 * sx, Paint()..color = luz.haloAstro);
    canvas.drawCircle(Offset(ax, ay), 26 * sx, Paint()..color = luz.astro);

    // --- colinas: a de trás anda menos que a da frente ---------------------
    final derivaLonge = (fase - 0.5) * 6 * sx;
    final derivaPerto = (fase - 0.5) * 11 * sx;

    // O pé das colinas é medido a partir da lâmina d'água, não do topo do
    // quadro: é a relação que importa — elas afundam ~55 unidades na água, e
    // é isso que precisa continuar valendo quando o habitat sobe ou desce a
    // linha d'água.
    final aguaTopo = h - cenario.linhaDagua * sy;
    final baseTras = aguaTopo + 56 * sy;
    final baseFrente = aguaTopo + 54 * sy;

    canvas.drawPath(
      silhuetaDeColina(
        esquerda: -34 * sx + derivaLonge,
        base: baseTras,
        largura: 224 * sx,
        altura: cenario.colinaTras * sy,
        pico: cenario.pico,
      ),
      Paint()..color = corDaColina.withValues(alpha: 0.85),
    );
    canvas.drawPath(
      silhuetaDeColina(
        esquerda: w - 162 * sx + derivaPerto,
        base: baseFrente,
        largura: 206 * sx,
        altura: cenario.colinaFrente * sy,
        pico: cenario.pico,
      ),
      Paint()..color = corDaColina.withValues(alpha: 0.62),
    );

    // --- água: gradiente de profundidade -----------------------------------
    final agua = Rect.fromLTWH(0, aguaTopo, w, h - aguaTopo);
    canvas.drawRect(
      agua,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cenario.aguaCom(luz.agua),
            cenario.aguaFundaCom(luz.aguaFunda),
          ],
        ).createShader(agua),
    );

    // --- margem de areia: uma curva por cima da água, não uma tarja reta ---
    // Pintada depois da água de propósito: antes, a água cobria a curva e só
    // sobrava uma linha horizontal dura separando os dois.
    final faixa = cenario.faixaDeAreia;
    final margem = Path()
      ..moveTo(0, aguaTopo + 10 * faixa * sy)
      ..cubicTo(
        w * 0.26, aguaTopo - 16 * faixa * sy,
        w * 0.62, aguaTopo + 14 * faixa * sy,
        w, aguaTopo - 10 * faixa * sy,
      )
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, aguaTopo - 34 * faixa * sy, w, 52 * faixa * sy),
    );
    canvas.drawPath(
      margem,
      Paint()..color = corDaAreia.withValues(alpha: 0.72),
    );
    canvas.restore();

    // --- brilhos que deslizam na superfície --------------------------------
    _brilho(canvas, Offset(38 * sx + derivaPerto, h - 76 * sy), 62 * sx, luz.brilho);
    _brilho(canvas, Offset(w - 102 * sx - derivaPerto, h - 44 * sy), 46 * sx,
        luz.brilho.withValues(alpha: 0.6));
    _brilho(canvas, Offset(w * 0.5 + derivaLonge, h - 24 * sy), 34 * sx,
        luz.brilho.withValues(alpha: 0.4));
  }

  void _brilho(Canvas canvas, Offset o, double largura, Color cor) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy, largura, 4),
        const Radius.circular(4),
      ),
      Paint()..color = cor,
    );
  }

  @override
  bool shouldRepaint(covariant _FundoDaCena old) =>
      old.fase != fase ||
      old.luz != luz ||
      old.cenario.id != cenario.id ||
      old.sx != sx ||
      old.sy != sy;
}

/// A cena, em miniatura e sem bicho — o cartão de um habitat na trilha.
///
/// Desenha com **o mesmo painter** da cena grande de propósito: uma prévia
/// pintada à mão viraria mentira na primeira vez que alguém ajustasse a
/// colina, e o usuário escolheria um lugar diferente do que vai receber.
class MiniaturaDoHabitat extends StatelessWidget {
  const MiniaturaDoHabitat({
    super.key,
    required this.habitatId,
    this.largura,
    this.altura = 64,
    this.agora,
  });

  final String habitatId;

  /// Nulo ocupa a largura disponível. Existe porque a prévia dentro da folha
  /// de detalhe é de borda a borda, e fixar 372 px ali estouraria a tela em
  /// qualquer aparelho mais estreito que o frame de referência.
  final double? largura;

  final double altura;

  /// Injetável para a captura de evidência não depender da hora do relógio.
  final DateTime? agora;

  Widget _pinta(double w) => SizedBox(
        width: w,
        height: altura,
        child: CustomPaint(
          painter: _FundoDaCena(
            sx: w / HabitatScene.design.width,
            sy: altura / HabitatScene.design.height,
            luz: LuzDaCena.de(periodoDe(agora ?? DateTime.now())),
            cenario: CenarioDoHabitat.de(habitatId),
            // Miniatura não deriva: meia dúzia delas repintando junto com a
            // cena grande seria trabalho de GPU por nada.
            fase: 0.5,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = largura;
    if (w != null) return _pinta(w);
    return LayoutBuilder(builder: (context, c) => _pinta(c.maxWidth));
  }
}

/// Vinheta e luz ambiente por cima de tudo — é o que dá profundidade.
class _LuzEVinheta extends CustomPainter {
  const _LuzEVinheta({required this.luz});

  final LuzDaCena luz;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(Raio.cena),
    );
    canvas.save();
    canvas.clipRRect(rrect);

    if (luz.sombraAmbiente.a > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = luz.sombraAmbiente);
    }

    // Luz difusa vinda do astro, no canto superior direito.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.72, -0.72),
          radius: 1.1,
          colors: [luz.haloAstro.withValues(alpha: 0.22), const Color(0x00000000)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Cores.tintaA(0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 52
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LuzEVinheta old) => old.luz != luz;
}

/// O ganho de um afago, subindo e sumindo.
///
/// Recompensa sem retorno visível é recompensa que o usuário não sabe que
/// recebeu — e o afago já é a interação mais silenciosa do app.
class _PremioSubindo extends StatelessWidget {
  const _PremioSubindo({required this.anima, required this.texto});

  final Animation<double> anima;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final sobe = Movimento.amplitude(context, 26);
    return AnimatedBuilder(
      animation: anima,
      builder: (context, _) {
        final t = anima.value;
        if (t == 0 || t >= 1) return const SizedBox.shrink();
        // Aparece rápido e some devagar: o olho tem de pegar o número.
        final opacidade = t < 0.18 ? t / 0.18 : (1 - (t - 0.18) / 0.82);
        return Opacity(
          opacity: opacidade.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -Curvas.padrao.transform(t) * sobe),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Espaco.sm,
                  vertical: Espaco.xxs,
                ),
                decoration: BoxDecoration(
                  color: Cores.superficie.withValues(alpha: 0.94),
                  borderRadius: Raio.todos(Raio.pilula),
                  boxShadow: Elevacao.cartao,
                ),
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: estilo(Tipo.rotulo, color: Cores.primariaEscura),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
