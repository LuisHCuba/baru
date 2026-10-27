/// O crescimento na tela: a barra da home e a cena de nascer e crescer.
///
/// O dono pediu que a diferença fosse "extremamente visível". O desenho já
/// muda por estágio (`PetView.estagio`); aqui ficam as duas peças que fazem
/// a pessoa **acompanhar**: quanto falta (com a forma seguinte à vista, em
/// silhueta) e o momento da virada, que não pode passar em silêncio.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/crescimento.dart';
import '../l10n.dart';
import '../models.dart';
import '../services/som_service.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'pet.dart';

/// O nome do estágio. O começo se chama "ovo" para quem bota ovo e "ninho"
/// para quem nasce de olho fechado.
String nomeDoEstagio(T t, Species s, EstagioDoBicho e) => switch (e) {
      EstagioDoBicho.inicio => Crescimento.botaOvo(s) ? t.estOvo : t.estNinho,
      EstagioDoBicho.filhote => t.estFilhote,
      EstagioDoBicho.jovem => t.estJovem,
      EstagioDoBicho.adulto => t.estAdulto,
      EstagioDoBicho.pleno => t.estPleno,
    };

/// Quanto falta, em palavras. No começo o verbo é o do começo: nascer
/// (ovo) ou abrir os olhos (ninho).
String faltaParaCrescer(T t, AppState app) {
  final falta = Crescimento.faltamPara(app.sessoesJuntos);
  final a = app.displayName;
  if (falta == null) return t.fill(t.crescNoAuge, {'a': a});
  final um = falta == 1;
  final tpl = switch (app.estagio) {
    EstagioDoBicho.inicio => Crescimento.botaOvo(app.species)
        ? (um ? t.crescFaltaNascer1 : t.crescFaltaNascer)
        : (um ? t.crescFaltaAbrir1 : t.crescFaltaAbrir),
    _ => um ? t.crescFalta1 : t.crescFalta,
  };
  return t.fill(tpl, {'n': falta, 'a': a});
}

/// A barra de crescimento da home, logo abaixo do habitat.
///
/// Distinta da barra de nível de propósito: nível é da conta, crescimento é
/// do bicho. À direita, a forma seguinte em silhueta — quem vê a sombra do
/// que vem quer ver a cor.
class BarraDoCrescimento extends StatelessWidget {
  const BarraDoCrescimento({super.key});

  static const chave = Key('barra-do-crescimento');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final estagio = app.estagio;
    final pleno = estagio == EstagioDoBicho.pleno;
    final proximo =
        pleno ? null : EstagioDoBicho.values[estagio.index + 1];
    return Semantics(
      container: true,
      label: '${t.crescRotulo}: ${nomeDoEstagio(t, app.species, estagio)}. '
          '${faltaParaCrescer(t, app)}',
      child: ExcludeSemantics(
        child: Container(
          key: chave,
          padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.sm, Espaco.sm, Espaco.sm),
          decoration: BoxDecoration(
            color: AppColors.greenA(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          nomeDoEstagio(t, app.species, estagio).toUpperCase(),
                          style: nunito(
                            size: 11.5,
                            weight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.greenDeep,
                          ),
                        ),
                        const SizedBox(width: Espaco.xs),
                        Expanded(
                          child: Text(
                            faltaParaCrescer(t, app),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: nunito(
                              size: 12.5,
                              weight: FontWeight.w600,
                              color: Cores.tinta700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Espaco.xs),
                    BarraAnimada(
                      fracao: Crescimento.progressoNoEstagio(app.sessoesJuntos),
                      altura: 8,
                      cor: AppColors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Espaco.sm),
              SizedBox(
                width: 54,
                height: 46,
                child: proximo == null
                    ? const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.green,
                        size: 22,
                      )
                    // A forma seguinte, em silhueta.
                    : ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          AppColors.inkA(0.22),
                          BlendMode.srcIn,
                        ),
                        child: FittedBox(
                          child: PetView(
                            species: app.species,
                            mood: Mood.content,
                            activity: Activity.idle,
                            coat: app.color,
                            estagio: proximo,
                            interativo: false,
                            width: 120,
                            height: 100,
                            quadro: const QuadroFixo(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A cena de nascer ou crescer.
///
/// Roteiro do laudo 05 (§4.5), enxuto: o véu escurece; o bicho de antes
/// treme cada vez mais (antecipação); a forma pisca entre a antiga e a nova,
/// cada vez mais rápido; um clarão; a forma nova pousa com mola, folhas
/// voando; o nome do estágio e o que mudou. Espera o toque — é o momento do
/// dia, não um aviso que some sozinho.
///
/// "Reduzir movimento": sem tremor, sem pisca-pisca, sem clarão; a forma
/// antiga dá lugar à nova num esmaecer.
class CenaDoCrescimento extends StatefulWidget {
  const CenaDoCrescimento({
    super.key,
    required this.antes,
    required this.depois,
    required this.aoFechar,
  });

  final EstagioDoBicho antes;
  final EstagioDoBicho depois;
  final VoidCallback aoFechar;

  static const chave = Key('cena-do-crescimento');

  /// A duração da cena até o texto. O toque antes disso só adianta.
  static const duracao = Duration(milliseconds: 4600);

  @override
  State<CenaDoCrescimento> createState() => _CenaDoCrescimentoState();
}

class _CenaDoCrescimentoState extends State<CenaDoCrescimento>
    with SingleTickerProviderStateMixin {
  // `preserve`: com "reduzir movimento" o Flutter encolheria a duração a 5%
  // e a virada passaria antes de ser vista. O que se reduz aqui é o
  // movimento, não o tempo.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: CenaDoCrescimento.duracao,
    animationBehavior: AnimationBehavior.preserve,
  );

  // Marcos da linha do tempo, em fração de [CenaDoCrescimento.duracao].
  static const _tremeAte = 0.36;
  static const _piscaAte = 0.66;
  static const _clarao = 0.70;
  static const _textoDe = 0.82;

  bool _revelou = false;
  int _ultimoTique = -1;

  @override
  void initState() {
    super.initState();
    _c.addListener(_marcaOsTempos);
    _c.forward();
  }

  /// Háptico leve a cada passo da antecipação, e o forte na virada — com o
  /// som de conquista no mesmo instante.
  void _marcaOsTempos() {
    final t = _c.value;
    if (t < _tremeAte) {
      final tique = (t / _tremeAte * 5).floor();
      if (tique != _ultimoTique) {
        _ultimoTique = tique;
        HapticFeedback.selectionClick();
      }
    }
    if (!_revelou && t >= _clarao) {
      _revelou = true;
      HapticFeedback.heavyImpact();
      unawaited(SomService.instance.toca(SomDoBaru.crescimento));
    }
  }

  void _toque() {
    if (_c.value < _textoDe) {
      // Pular encurta, não cancela: a virada acontece igual. `forward`, e
      // não atribuir `value` — a atribuição para o controller, e o texto e
      // o botão ficariam parados no zero.
      _c.forward(from: _textoDe);
      return;
    }
    widget.aoFechar();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _bicho(AppState app, EstagioDoBicho e, {Color? silhueta}) {
    final bicho = PetView(
      species: app.species,
      mood: Mood.radiant,
      activity: Activity.idle,
      coat: app.color,
      roupas: app.roupasDoBicho,
      roupaDeCabeca: app.roupaDeCabeca,
      estagio: e,
      interativo: false,
      width: 220,
      height: 180,
    );
    if (silhueta == null) return bicho;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(silhueta, BlendMode.srcIn),
      child: bicho,
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final reduzido = Movimento.reduzido(context);
    final nome = app.displayName;
    final titulo = t.fill(
      widget.antes == EstagioDoBicho.inicio
          ? (Crescimento.botaOvo(app.species) ? t.crescNasceu : t.crescAbriuOlhos)
          : t.crescCresceu,
      {'a': nome},
    );
    final sub = switch (widget.depois) {
      EstagioDoBicho.inicio || EstagioDoBicho.filhote => t.crescSubFilhote,
      EstagioDoBicho.jovem => t.crescSubJovem,
      EstagioDoBicho.adulto => t.crescSubAdulto,
      EstagioDoBicho.pleno => t.crescSubPleno,
    };
    final agora = t.fill(t.crescAgora, {
      'e': nomeDoEstagio(t, app.species, widget.depois),
    });

    return Positioned.fill(
      key: CenaDoCrescimento.chave,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toque,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value;
            // Começa já escuro: vindo logo depois da cena da raiz, um véu
            // que nasce transparente deixava o resultado piscar aceso por
            // um quadro entre as duas (simulador, médio 10).
            final veu = 0.7 + 0.3 * (v / 0.08).clamp(0.0, 1.0);

            Widget palco;
            var clarao = 0.0;
            if (reduzido) {
              final troca = ((v - 0.45) / 0.15).clamp(0.0, 1.0);
              palco = Stack(alignment: Alignment.center, children: [
                Opacity(opacity: 1 - troca, child: _bicho(app, widget.antes)),
                Opacity(opacity: troca, child: _bicho(app, widget.depois)),
              ]);
            } else if (v < _tremeAte) {
              // Antecipação: o tremor cresce.
              final forca = Curves.easeIn.transform(v / _tremeAte);
              final giro = math.sin(v * 90) * 0.07 * forca;
              palco = Transform.rotate(
                angle: giro,
                child: _bicho(app, widget.antes),
              );
            } else if (v < _piscaAte) {
              // A forma oscila entre a antiga e a nova, acelerando de 1 a
              // 3 ciclos por segundo, num esmaecer suave e não em troca seca.
              // A primeira versão trocava de silhueta até 30 vezes por
              // segundo, creme sobre véu escuro — pisca-pisca acima do que
              // as diretrizes de acessibilidade recomendam (auditoria da
              // Onda 2, 6.4).
              final u = (v - _tremeAte) / (_piscaAte - _tremeAte);
              final segundos = (_piscaAte - _tremeAte) *
                  CenaDoCrescimento.duracao.inMilliseconds /
                  1000;
              // Frequência 1 → 3 Hz: ciclos = ∫ (1 + 2u) dt.
              final ciclos = segundos * (u + u * u);
              final nova = 0.5 - 0.5 * math.cos(ciclos * math.pi * 2);
              palco = Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1 - nova,
                    child: _bicho(app, widget.antes,
                        silhueta: Cores.superficie),
                  ),
                  Opacity(
                    opacity: nova,
                    child: _bicho(app, widget.depois,
                        silhueta: Cores.superficie),
                  ),
                ],
              );
            } else {
              final u = ((v - _piscaAte) / (1 - _piscaAte)).clamp(0.0, 1.0);
              clarao = v < _clarao
                  ? (v - _piscaAte) / (_clarao - _piscaAte)
                  : (1 - (v - _clarao) / 0.06).clamp(0.0, 1.0);
              final pouso = Curves.elasticOut.transform(
                ((v - _clarao) / (1 - _clarao) * 1.6).clamp(0.0, 1.0),
              );
              palco = Transform.scale(
                scale: v < _clarao ? 1 : 0.85 + 0.15 * pouso,
                child: _bicho(
                  app,
                  v < _clarao ? widget.antes : widget.depois,
                  silhueta: v < _clarao ? Cores.superficie : null,
                ),
              );
              if (u > 0 && v >= _clarao) {
                palco = Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: const Size(320, 260),
                      painter: _FolhasVoando(
                        t: ((v - _clarao) / (1 - _clarao)).clamp(0.0, 1.0),
                      ),
                    ),
                    palco,
                  ],
                );
              }
            }

            final texto = ((v - _textoDe) / (1 - _textoDe)).clamp(0.0, 1.0);
            return ColoredBox(
              // Opaco: o resultado atrás aparecia pelo véu e brigava com a
              // cena (simulador da Fase 4, médio 10).
              color: Cores.tintaA(0.98 * veu),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 200, child: Center(child: palco)),
                        const SizedBox(height: Espaco.lg),
                        Opacity(
                          opacity: texto,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Espaco.xxl,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  titulo,
                                  textAlign: TextAlign.center,
                                  style: estilo(
                                    Tipo.displayGrande,
                                    color: Cores.tintaClara,
                                  ),
                                ),
                                const SizedBox(height: Espaco.xs),
                                Text(
                                  agora.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: nunito(
                                    size: 12.5,
                                    weight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: AppColors.greenSoft,
                                  ),
                                ),
                                const SizedBox(height: Espaco.sm),
                                Text(
                                  t.fill(sub, {'a': nome}),
                                  textAlign: TextAlign.center,
                                  style: estilo(
                                    Tipo.corpoGrande,
                                    color: Cores.tintaClara
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: Espaco.xl),
                                IgnorePointer(
                                  ignoring: texto < 0.5,
                                  child: SizedBox(
                                    width: 220,
                                    child: BotaoBaru(
                                      rotulo: t.cont,
                                      aoTocar: widget.aoFechar,
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
                  if (clarao > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        // O clarão é luz no bicho, não um véu branco na tela
                        // inteira — sobre o fundo escuro aquilo virava um
                        // flash cinza.
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              radius: 0.55,
                              colors: [
                                Colors.white.withValues(alpha: clarao * 0.95),
                                Colors.white.withValues(alpha: clarao * 0.35),
                                Colors.white.withValues(alpha: 0),
                              ],
                              stops: const [0, 0.45, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Folhas saindo do bicho na virada: o vocabulário do Baru, não confete.
class _FolhasVoando extends CustomPainter {
  _FolhasVoando({required this.t});

  final double t;

  static final _folhas = List.generate(14, (i) {
    final sorte = math.Random(i * 131 + 7);
    return (
      angulo: (i / 14) * math.pi * 2 + sorte.nextDouble() * 0.4,
      distancia: 70 + sorte.nextDouble() * 70,
      giro: (sorte.nextDouble() - 0.5) * 6,
      tamanho: 7 + sorte.nextDouble() * 6,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final saida = Curves.easeOutCubic.transform(t);
    final some = (1 - (t - 0.55) / 0.45).clamp(0.0, 1.0);
    for (var i = 0; i < _folhas.length; i++) {
      final f = _folhas[i];
      final p = centro +
          Offset(math.cos(f.angulo), math.sin(f.angulo)) *
              (f.distancia * saida) +
          Offset(0, 30 * t * t);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(f.angulo + f.giro * t);
      final s = f.tamanho;
      canvas.drawPath(
        Path()
          ..moveTo(-s, 0)
          ..quadraticBezierTo(0, -s * 0.7, s, 0)
          ..quadraticBezierTo(0, s * 0.7, -s, 0)
          ..close(),
        Paint()
          ..color = (i.isEven ? AppColors.greenSoft : AppColors.green)
              .withValues(alpha: some),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FolhasVoando old) => old.t != t;
}
