/// A raiz cresceu hoje: a cena do primeiro foco do dia.
///
/// É o equivalente da animação de ofensiva do Duolingo, que o dono citou
/// pelo nome. O storyboard é o do laudo 01 (§5), quadro a quadro:
///
/// | ms        | o que acontece                                          |
/// |-----------|---------------------------------------------------------|
/// | 0–400     | o painel de terra sobe; o bicho já está na grama         |
/// | 400–750   | uma gota de luz se forma sob o bicho e escorre pela raiz |
/// | 750       | a gota toca a ponta: clarão                             |
/// | 750–1350  | a raiz alonga de N para N+1 (e brota o galho, se marco)  |
/// | 1150–1450 | o contador gira de N para N+1                            |
/// | 1200–1650 | o bicho dá um pulinho; folhinhas saem da grama            |
/// | 1450–2000 | título, a linha do dia e o ✓ de hoje na faixa            |
/// | 2000–2400 | tudo para; o botão aparece                               |
///
/// No marco (3, 7, 14, 30…) a cena ganha +900 ms: a terra treme, o galho
/// novo assenta, e entra o botão de compartilhar a raiz.
///
/// Som e háptico disparam por **limiar do controlador**, não por
/// `Future.delayed`: pular a cena não deixa som atrasado tocando. O som da
/// cena é um arquivo só (`SomDoBaru.raiz`), mixado no tempo da animação.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/som_service.dart';
import '../state.dart';
import '../theme.dart';
import 'cartao_da_raiz.dart';
import 'common.dart';
import 'pet.dart';
import 'raiz.dart';

/// A linha que muda a cada dia, na prioridade do storyboard: recorde, depois
/// galho perto, depois uma de cinco que gira com os dias.
String linhaDaRaiz(T t, {required int dias, required bool recorde}) {
  if (recorde) return t.raizRecorde;
  final proximo = RaizViva.proximoMarco(dias);
  if (proximo != null) {
    final falta = proximo - dias;
    if (falta == 1) return t.raizFaltaGalho1;
    if (falta <= 3) return t.fill(t.raizFaltaGalho, {'n': falta});
  }
  final linhas = [
    t.raizLinha1,
    t.raizLinha2,
    t.raizLinha3,
    t.raizLinha4,
    t.raizLinha5,
  ];
  return linhas[dias % linhas.length];
}

class CenaDaRaiz extends StatefulWidget {
  const CenaDaRaiz({
    super.key,
    required this.dias,
    required this.recorde,
    required this.aoFechar,
  });

  /// Os dias **depois** de crescer (N+1).
  final int dias;
  final bool recorde;
  final VoidCallback aoFechar;

  static const chave = Key('cena-da-raiz');
  static const chaveDoContador = Key('cena-da-raiz-contador');

  /// O dia virou marco (3, 7, 14, 30…)?
  bool get marco => RaizViva.marcos.contains(dias);

  /// Duração total: 2,4 s, ou 3,3 s no marco.
  Duration get duracao => Duration(milliseconds: marco ? 3300 : 2400);

  @override
  State<CenaDaRaiz> createState() => _CenaDaRaizState();
}

class _CenaDaRaizState extends State<CenaDaRaiz>
    with SingleTickerProviderStateMixin {
  // `preserve`: com "reduzir movimento" o Flutter encurtaria a 5%. A
  // variante reduzida é desenhada aqui, não pelo relógio.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duracao,
    animationBehavior: AnimationBehavior.preserve,
  );

  double _ultimoMs = -1;
  bool _pulou = false;

  /// Marcos de tempo em ms. Os do marco se deslocam +900 a partir do Q6.
  double get _extra => widget.marco ? 900 : 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(_disparos);
    _c.forward();
  }

  double get _ms => _c.value * widget.duracao.inMilliseconds;

  bool _passou(double limiar, double antes, double agora) =>
      antes < limiar && agora >= limiar;

  /// Sons e hápticos pelos limiares do relógio.
  void _disparos() {
    final agora = _ms;
    final antes = _ultimoMs;
    _ultimoMs = agora;
    if (_pulou) return;
    final reduzido = Movimento.reduzido(context);
    if (reduzido) {
      if (_passou(200, antes, agora)) {
        _tocaOSom();
        HapticFeedback.mediumImpact();
      }
      return;
    }
    // O arquivo de som começa na gota tocando a ponta (700 ms).
    if (_passou(700, antes, agora)) _tocaOSom();
    if (_passou(750, antes, agora)) HapticFeedback.lightImpact();
    for (final nota in const [850.0, 1000.0, 1150.0]) {
      if (_passou(nota, antes, agora)) HapticFeedback.selectionClick();
    }
    if (_passou(1200, antes, agora)) HapticFeedback.mediumImpact();
    if (widget.marco && _passou(1700, antes, agora)) {
      HapticFeedback.heavyImpact();
    }
    if (_passou(1750 + _extra, antes, agora)) HapticFeedback.selectionClick();
  }

  void _tocaOSom() {
    unawaited(
      SomService.instance.toca(
        widget.marco ? SomDoBaru.raizMarco : SomDoBaru.raiz,
      ),
    );
  }

  /// A partir de 600 ms, um toque leva ao quadro final. O som da cena para
  /// junto: arpejo tocando sobre a tela seguinte é ruído.
  void _toque() {
    if (_c.isCompleted) return;
    if (_ms < 600) return;
    _pulou = true;
    unawaited(SomService.instance.para());
    _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Fração de um intervalo [de, ate] em ms, com curva.
  double _f(double de, double ate, [Curve curva = Curves.linear]) {
    final v = ((_ms - de) / (ate - de)).clamp(0.0, 1.0);
    return curva.transform(v);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final reduzido = Movimento.reduzido(context);
    final n = widget.dias;

    return Positioned.fill(
      key: CenaDaRaiz.chave,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toque,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // Com "reduzir movimento": esmaece direto para o quadro final.
            final fim = reduzido ? _f(0, 200) : 1.0;
            final q = reduzido ? (fim >= 1 ? 1.0 : 0.0) : 1.0;
            double f(double de, double ate, [Curve c = Curves.linear]) =>
                reduzido ? q : _f(de, ate, c);

            final entrada = f(0, 400, Curves.easeOutCubic);
            // Sem movimento não há gota: ela só existe caindo.
            final gotaForma = reduzido ? 0.0 : f(400, 550);
            final gotaCai = f(550, 750, Curves.easeIn);
            final clarao = reduzido ? 0.0 : _f(750, 900);
            final cresce = f(750, 1350, Curves.easeInOutCubic);
            final conta = f(1150, 1400, Curves.easeOutBack);
            final pulo = reduzido ? 0.0 : _f(1200, 1650);
            final treme = widget.marco && !reduzido
                ? math.sin(_f(1450, 1750) * math.pi * 10) *
                      3 *
                      (1 - _f(1450, 1750))
                : 0.0;
            final texto = f(1450 + _extra, 1800 + _extra);
            final hoje = f(1750 + _extra, 2050 + _extra, Curves.easeOutBack);
            final botao = f(2000 + _extra, 2200 + _extra);

            return Opacity(
              opacity: reduzido ? fim : 1,
              child: ColoredBox(
                color: AppColors.cream,
                child: SafeArea(
                  child: Column(
                    children: [
                      // O céu e a grama, com o bicho sentado.
                      Expanded(
                        flex: 24,
                        child: _CeuComBicho(app: app, pulo: pulo),
                      ),
                      // A terra: sobe da borda de baixo.
                      Expanded(
                        flex: 40,
                        child: FractionalTranslation(
                          translation: Offset(0, 1 - entrada),
                          child: Transform.translate(
                            offset: Offset(treme, 0),
                            child: _Terra(
                              dias: n,
                              cresce: cresce,
                              gotaForma: gotaForma,
                              gotaCai: gotaCai,
                              clarao: clarao,
                              conta: conta,
                              // O rótulo acompanha o número à vista: "0 dias"
                              // antes de girar, "1 dia" depois.
                              rotulo: (conta < 0.5 ? n - 1 : n) == 1
                                  ? t.raizDiaRotulo
                                  : t.raizDiasRotulo,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 36,
                        // Rola: com fonte grande, num telefone pequeno, o
                        // botão não pode ficar fora do alcance.
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
                          child: Column(
                            children: [
                              Opacity(
                                opacity: texto,
                                child: Column(
                                  children: [
                                    Text(
                                      widget.marco
                                          ? t.raizGalhoNovo
                                          : t.streakLabel(n),
                                      textAlign: TextAlign.center,
                                      style: estilo(Tipo.display),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      widget.marco
                                          ? t.fill(t.raizGalhoSub, {'n': n})
                                          : linhaDaRaiz(
                                              t,
                                              dias: n,
                                              recorde: widget.recorde,
                                            ),
                                      textAlign: TextAlign.center,
                                      style: estilo(
                                        Tipo.corpoGrande,
                                        color: Cores.tinta700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Opacity(
                                opacity: texto,
                                child: _Faixa(app: app, hoje: hoje),
                              ),
                              const SizedBox(height: 18),
                              IgnorePointer(
                                ignoring: botao < 0.5,
                                child: Opacity(
                                  opacity: botao,
                                  child: Column(
                                    children: [
                                      if (widget.marco)
                                        BotaoDeCompartilharRaiz(app: app),
                                      BotaoBaru(
                                        rotulo: t.cont,
                                        aoTocar: widget.aoFechar,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// O céu claro, a linha da grama e o bicho sentado nela.
class _CeuComBicho extends StatelessWidget {
  const _CeuComBicho({required this.app, required this.pulo});

  final AppState app;

  /// 0 a 1, o pulinho de alegria (Q5).
  final double pulo;

  @override
  Widget build(BuildContext context) {
    final altura = math.sin(pulo * math.pi) * 18;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF6EEDC), Color(0xFFE7EFD6)],
            ),
          ),
        ),
        // A grama, no pé do céu.
        const Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 12,
            width: double.infinity,
            child: ColoredBox(color: Color(0xFF8DB36E)),
          ),
        ),
        // As folhinhas atrás do bicho: saem da grama em volta dele.
        if (pulo > 0 && pulo < 1)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _FolhinhasDaGrama(t: pulo)),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 4 + altura),
            child: PetView(
              species: app.species,
              mood: Mood.radiant,
              activity: Activity.idle,
              coat: app.color,
              roupas: app.roupasDoBicho,
              roupaDeCabeca: app.roupaDeCabeca,
              // O estágio já visto: se o bicho cresceu nesta mesma sessão, a
              // cena do crescimento vem depois e é ela que revela a forma nova
              // (auditoria da Onda 2, item 7, R4).
              estagio: app.estagioJaVisto,
              interativo: false,
              width: 150,
              height: 120,
            ),
          ),
        ),
      ],
    );
  }
}

/// O corte de terra com a raiz, a gota e o contador.
class _Terra extends StatelessWidget {
  const _Terra({
    required this.dias,
    required this.cresce,
    required this.gotaForma,
    required this.gotaCai,
    required this.clarao,
    required this.conta,
    required this.rotulo,
  });

  final int dias;
  final double cresce;
  final double gotaForma;
  final double gotaCai;
  final double clarao;
  final double conta;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    final exatos = (dias - 1) + cresce;
    return ColoredBox(
      color: const Color(0xFFEDE3D2),
      child: Row(
        children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 5,
            child: LayoutBuilder(
              builder: (context, c) {
                final tamanho = Size(c.maxWidth, c.maxHeight);
                // A raiz de poucos dias ocupa só o alto do painel; a cena a
                // aproxima para ela ser o assunto, e afasta conforme ela
                // fica funda (a partir de ~3 meses, escala 1).
                final crescimento = 1 - math.exp(-dias / 26);
                final perto = (0.9 / (0.30 + 0.66 * crescimento)).clamp(
                  1.0,
                  1.8,
                );
                return ClipRect(
                  child: Transform.scale(
                    scale: perto,
                    alignment: Alignment.topCenter,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RaizViva(
                            dias: dias,
                            diasExatos: exatos,
                            corDaTerra: const Color(0xFFEDE3D2),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _Gota(
                              ponta: RaizViva.pontaEm(
                                tamanho,
                                (dias - 1).toDouble(),
                              ),
                              chao: RaizViva.chaoEm(tamanho),
                              forma: gotaForma,
                              cai: gotaCai,
                              clarao: clarao,
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
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Odometro(de: dias - 1, para: dias, t: conta),
                Text(
                  rotulo,
                  style: nunito(
                    size: 14,
                    weight: FontWeight.w700,
                    color: Cores.tinta700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O número rolando de N para N+1, como odômetro; troca de tinta para o
/// acento e dá um pulso.
class _Odometro extends StatelessWidget {
  const _Odometro({required this.de, required this.para, required this.t});

  final int de;
  final int para;
  final double t;

  @override
  Widget build(BuildContext context) {
    final cor = Color.lerp(Cores.tinta, Cores.raiz500, t.clamp(0.0, 1.0))!;
    final pulso = 1 + math.sin(t.clamp(0.0, 1.0) * math.pi) * 0.15;
    final estilo = nunito(size: 46, weight: FontWeight.w800, color: cor);
    return Transform.scale(
      scale: pulso,
      child: SizedBox(
        height: 58,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(0, -58 * t),
                child: Text('$de', style: estilo),
              ),
              Transform.translate(
                offset: Offset(0, 58 * (1 - t)),
                child: Text(
                  '$para',
                  key: CenaDaRaiz.chaveDoContador,
                  style: estilo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gota de luz: forma-se sob o bicho, escorre até a ponta, faz clarão.
class _Gota extends CustomPainter {
  _Gota({
    required this.ponta,
    required this.chao,
    required this.forma,
    required this.cai,
    required this.clarao,
  });

  final Offset ponta;
  final double chao;
  final double forma;
  final double cai;
  final double clarao;

  @override
  void paint(Canvas canvas, Size size) {
    final luz = Cores.raiz500;
    if (forma > 0 && clarao == 0) {
      final origem = Offset(size.width / 2, chao);
      final p = Offset.lerp(origem, ponta, cai)!;
      // O rastro que esmaece atrás da gota.
      if (cai > 0) {
        canvas.drawLine(
          origem,
          p,
          Paint()
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = luz.withValues(alpha: 0.25 * (1 - cai * 0.5)),
        );
      }
      canvas.drawCircle(
        p,
        5 * forma,
        Paint()
          ..color = luz
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(p, 2.4 * forma, Paint()..color = Colors.white);
    }
    if (clarao > 0 && clarao < 1) {
      canvas.drawCircle(
        ponta,
        24 * clarao,
        Paint()..color = luz.withValues(alpha: 0.55 * (1 - clarao)),
      );
    }
  }

  @override
  bool shouldRepaint(_Gota old) =>
      old.forma != forma ||
      old.cai != cai ||
      old.clarao != clarao ||
      old.ponta != ponta;
}

/// Seis folhinhas saindo da linha da grama (não confete: o vocabulário do
/// Baru é folha).
class _FolhinhasDaGrama extends CustomPainter {
  _FolhinhasDaGrama({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final base = Offset(size.width / 2, size.height - 8);
    final some = 1 - t;
    for (var i = 0; i < 7; i++) {
      final lado = i.isEven ? 1.0 : -1.0;
      final abre = 40.0 + i * 11;
      final p =
          base +
          Offset(lado * abre * t, -60 * math.sin(t * math.pi) - i * 3 * t);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(lado * (0.6 + t * 2));
      const s = 6.0;
      canvas.drawPath(
        Path()
          ..moveTo(-s, 0)
          ..quadraticBezierTo(0, -s * 0.7, s, 0)
          ..quadraticBezierTo(0, s * 0.7, -s, 0)
          ..close(),
        Paint()
          ..color = (i.isEven ? AppColors.green : AppColors.greenSoft)
              .withValues(alpha: some),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FolhinhasDaGrama old) => old.t != t;
}

/// A faixa dos últimos 7 dias, com o ponto de hoje virando ✓.
class _Faixa extends StatelessWidget {
  const _Faixa({required this.app, required this.hoje});

  final AppState app;

  /// 0 a 1, a entrada do ✓ de hoje (escala 0 → 1,2 → 1).
  final double hoje;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final dias = app.ultimos7Dias;
    return Row(
      children: [
        for (var k = 0; k < dias.length; k++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: k == dias.length - 1
                      ? Transform.scale(
                          scale: hoje,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Cores.raiz600,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Cores.tintaClara,
                            ),
                          ),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dias[k].$2 == WeekDayKind.present
                                ? AppColors.green
                                : dias[k].$2 == WeekDayKind.frozen
                                ? const Color(0xFF9CC3D5)
                                : AppColors.inkA(0.08),
                          ),
                        ),
                ),
                const SizedBox(height: 5),
                Text(
                  t.days[dias[k].$1],
                  style: nunito(
                    size: 11,
                    weight: FontWeight.w700,
                    color: Cores.tinta700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
