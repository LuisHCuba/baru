import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/som_service.dart';

import '../theme.dart';
import 'toca.dart';

/// Celebração de conquista: nível novo ou marco da trilha.
///
/// Silêncio depois de conquistar é falha de produto (§7). O usuário fez algo
/// difícil; a tela tem de reconhecer — com partícula, brilho e háptico, por
/// tempo contido, sem bloquear quem quer seguir.
class Celebracao extends StatefulWidget {
  const Celebracao({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.aoFechar,
    this.icone = Icons.auto_awesome_rounded,
    this.cor = Cores.mel400,
    this.precisaCavar = false,
    this.som = SomDoBaru.conquista,
    this.bicho,
    this.tituloDaToca,
    this.ajudaDaToca,
  });

  /// O cabeçalho e a dica da toca, os mesmos das Missões. Sem eles a cena
  /// era uma meia-lua marrom sem instrução, e quem não sabia cavar ficava
  /// preso nela (simulador da Fase 4, alto 3).
  final String? tituloDaToca;
  final String? ajudaDaToca;

  /// O bicho da pessoa, comemorando junto. Quando vem, ele ocupa o lugar do
  /// ícone: a conquista é dos dois, e um ícone genérico num círculo não é de
  /// ninguém (laudo 01, U11; laudo 03, 4.9).
  final Widget? bicho;

  final String titulo;
  final String subtitulo;
  final VoidCallback aoFechar;
  final IconData icone;
  final Color cor;

  /// A conquista sai da toca, e não aparece sozinha.
  ///
  /// Recompensa que chega pronta não é sentida: é o gesto que transforma
  /// "ganhei" em "eu tirei dali". Ligado em nível e marco da trilha, que
  /// **são** recompensas; desligado na saudação da chegada, que é um "bom
  /// te ver" e não um prêmio — fazer alguém cavar para receber um
  /// cumprimento seria pedágio.
  final bool precisaCavar;

  /// O som da cena. Cada conquista tem o seu: o de herói gasto todo dia na
  /// saudação deixava de dizer "conquista".
  final SomDoBaru som;

  static const chave = Key('celebracao');
  static const chaveDaToca = Key('celebracao-toca');

  @override
  State<Celebracao> createState() => _CelebracaoState();
}

class _CelebracaoState extends State<Celebracao>
    with SingleTickerProviderStateMixin {
  /// `preserve`: com "reduzir movimento", a celebração encolhe de amplitude,
  /// mas não pode passar tão rápido que ninguém veja o que conquistou.
  ///
  /// Criado no `initState`, não preguiçoso: uma celebração que pede cavar
  /// só toca o `_c` ao abrir, e fechada antes disso ("voltar") o criava no
  /// `dispose` — com o widget já desativado, o que estoura a asserção de
  /// ancestral (auditoria da Onda 2, V1).
  late final AnimationController _c;

  final _particulas = List.generate(18, (i) {
    final sorte = math.Random(i * 977);
    return _Particula(
      angulo: (i / 18) * math.pi * 2 + sorte.nextDouble() * 0.3,
      distancia: 80 + sorte.nextDouble() * 90,
      tamanho: 4 + sorte.nextDouble() * 6,
      atraso: sorte.nextDouble() * 0.18,
    );
  });

  /// Já foi cavada (ou nunca precisou ser).
  late bool _aberta = !widget.precisaCavar;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Tempo.celebracao,
      animationBehavior: AnimationBehavior.preserve,
    );
    if (widget.precisaCavar) return;
    _explode();
  }

  void _explode() {
    HapticFeedback.heavyImpact();
    // O som acompanha o háptico: os dois marcam o mesmo instante.
    unawaited(SomService.instance.toca(widget.som));
    _c.forward();
    // Fecha sozinha: conquista não pode virar bloqueio.
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        // O prêmio cavado fica à vista um pouco mais: em 1,1 s as folhas do
        // marco sumiam antes de serem lidas (simulador, médio).
        Future.delayed(
          Duration(milliseconds: widget.precisaCavar ? 2600 : 1100),
          () {
            if (mounted) widget.aoFechar();
          },
        );
      }
    });
  }

  /// A cena de cavar, antes da conquista aparecer.
  ///
  /// Sem `onTap` de fechar no véu: quem está cavando não pode perder o
  /// prêmio por encostar fora do buraco.
  Widget _aToca() {
    // O céu de fim de tarde, com estrelas acendendo: a escavação é um
    // momento, não uma janela escura com um botão marrom no meio.
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E2A45), Color(0xFF5B4A6B), Color(0xFFC98E6B)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: CustomPaint(painter: _Estrelas())),
            ),
            // Títulos no céu; a terra ocupa a parte de baixo da tela de
            // ponta a ponta — o chão é o palco, não um cartão no meio.
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const SizedBox(height: Espaco.xxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Espaco.margemTela,
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.titulo,
                          textAlign: TextAlign.center,
                          style: estilo(
                            Tipo.tituloGrande,
                            color: Cores.superficie,
                          ),
                        ),
                        if (widget.tituloDaToca != null) ...[
                          const SizedBox(height: Espaco.xs),
                          Text(
                            widget.tituloDaToca!,
                            textAlign: TextAlign.center,
                            style: estilo(
                              Tipo.corpoForte,
                              color: Cores.superficie,
                            ),
                          ),
                        ],
                        if (widget.ajudaDaToca != null)
                          Text(
                            widget.ajudaDaToca!,
                            textAlign: TextAlign.center,
                            style: estilo(
                              Tipo.corpo,
                              color: Cores.superficie.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Align(
                        alignment: Alignment.bottomCenter,
                        child: Toca(
                          key: Celebracao.chaveDaToca,
                          rotuloDoPremio: widget.subtitulo,
                          icone: Icon(widget.icone),
                          cor: widget.cor,
                          bicho: widget.bicho,
                          cantos: false,
                          altura: c.maxHeight.clamp(300.0, 620.0),
                          aoAbrir: () {
                            if (!mounted) return;
                            setState(() => _aberta = true);
                            _explode();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A escavação fica embaixo e a conquista entra por cima, escurecendo
    // aos poucos: trocar uma pela outra cortava a terra num quadro só.
    return Positioned.fill(
      key: Celebracao.chave,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.precisaCavar) _aToca(),
          if (_aberta) _conquista(context),
        ],
      ),
    );
  }

  Widget _conquista(BuildContext context) {
    final amplitude = Movimento.amplitude(context, 1);
    return GestureDetector(
      onTap: widget.aoFechar,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final entrada = Curves.easeOutBack.transform(t.clamp(0.0, 1.0));
          final veu = (t * 2.2).clamp(0.0, 1.0);
          return DecoratedBox(
            // O mesmo céu da escavação, quando houve escavação: cortar do
            // entardecer para um véu marrom era um tranco. Escuro o
            // bastante para o texto creme (contraste é requisito).
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2E2A45).withValues(alpha: 0.96 * veu),
                  const Color(0xFF4A3D5E).withValues(alpha: 0.94 * veu),
                  const Color(0xFF6B4E5C).withValues(alpha: 0.92 * veu),
                ],
              ),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: const Size(300, 300),
                    painter: _Explosao(
                      t: t,
                      cor: widget.cor,
                      particulas: _particulas,
                      amplitude: amplitude,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7 + 0.3 * entrada,
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.bicho != null)
                            SizedBox(
                              width: 180,
                              height: 150,
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // O halo da conquista atrás dele.
                                  Positioned(
                                    bottom: 6,
                                    child: Container(
                                      width: 128,
                                      height: 128,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: widget.cor.withValues(
                                          alpha: 0.30,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.cor.withValues(
                                              alpha: 0.45,
                                            ),
                                            blurRadius: 40 * amplitude,
                                            spreadRadius: 6 * amplitude,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  widget.bicho!,
                                ],
                              ),
                            )
                          else
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: widget.cor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.cor.withValues(alpha: 0.5),
                                    blurRadius: 40 * amplitude,
                                    spreadRadius: 6 * amplitude,
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icone,
                                size: 42,
                                // Tinta sobre o mel, creme sobre o vínculo.
                                color: Cores.textoSobre(widget.cor),
                              ),
                            ),
                          const SizedBox(height: Espaco.lg),
                          Text(
                            widget.titulo,
                            textAlign: TextAlign.center,
                            style: estilo(
                              Tipo.displayGrande,
                              color: Cores.tintaClara,
                            ),
                          ),
                          const SizedBox(height: Espaco.xs),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Espaco.xxl,
                            ),
                            child: Text(
                              widget.subtitulo,
                              textAlign: TextAlign.center,
                              style: estilo(
                                Tipo.corpoGrande,
                                color: Cores.tintaClara.withValues(alpha: 0.8),
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
          );
        },
      ),
    );
  }
}

class _Particula {
  const _Particula({
    required this.angulo,
    required this.distancia,
    required this.tamanho,
    required this.atraso,
  });

  final double angulo;
  final double distancia;
  final double tamanho;
  final double atraso;
}

class _Explosao extends CustomPainter {
  const _Explosao({
    required this.t,
    required this.cor,
    required this.particulas,
    required this.amplitude,
  });

  final double t;
  final Color cor;
  final List<_Particula> particulas;
  final double amplitude;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    for (final p in particulas) {
      final avanco = ((t - p.atraso) / (1 - p.atraso)).clamp(0.0, 1.0);
      if (avanco <= 0) continue;
      final saida = Curves.easeOutQuart.transform(avanco);
      final some = (1 - avanco).clamp(0.0, 1.0);
      final d = p.distancia * saida * amplitude;
      canvas.drawCircle(
        centro + Offset(math.cos(p.angulo) * d, math.sin(p.angulo) * d),
        p.tamanho * some,
        Paint()..color = cor.withValues(alpha: 0.85 * some),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Explosao old) => old.t != t;
}

/// Estrelas no céu da escavação, fixas: o movimento fica com a terra.
class _Estrelas extends CustomPainter {
  const _Estrelas();

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(5);
    final p = Paint()..color = const Color(0xCCFFF6E0);
    for (var i = 0; i < 28; i++) {
      final o = Offset(
        r.nextDouble() * size.width,
        r.nextDouble() * size.height * 0.45,
      );
      canvas.drawCircle(o, 0.6 + r.nextDouble() * 1.4, p);
    }
  }

  @override
  bool shouldRepaint(covariant _Estrelas old) => false;
}
