import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/som_service.dart';
import '../theme.dart';

/// A toca de onde sai a recompensa.
///
/// **Por que não um botão "Resgatar".** Recompensa que chega sozinha não é
/// sentida. O gesto é o que transforma "ganhei" em "eu tirei dali" — é o
/// mesmo motivo pelo qual abrir um presente vale mais que recebê-lo aberto.
///
/// **Por que uma toca e não um baú.** Baú é vocabulário de RPG. Aqui o
/// mundo é bicho e mato: o Baru guarda coisa embaixo da terra, e a pessoa
/// **cava** para achar.
///
/// **Como funciona.** Cada toque (ou arrasto) tira uma camada de terra. A
/// cada camada o buraco cresce, a terra voa, o chão treme um pouco e o
/// aparelho responde. Na última, a terra abre de vez e o prêmio sobe.
///
/// Nada disso é enfeite opcional: [PRECISA_DE] gestos é o contrato, e sem
/// eles não abre.
class Toca extends StatefulWidget {
  const Toca({
    super.key,
    required this.aoAbrir,
    required this.rotuloDoPremio,
    this.icone = Icons.eco_rounded,
    this.cor = Cores.primaria,
  });

  /// Chamado uma vez, quando a terra abre.
  final VoidCallback aoAbrir;

  /// O que está lá dentro, já traduzido.
  final String rotuloDoPremio;

  final IconData icone;
  final Color cor;

  /// Quantos gestos até abrir.
  ///
  /// Três: um é acidente, cinco é trabalho. Três dá ritmo — cava, cava,
  /// abriu — e cabe no tempo em que a pessoa ainda está olhando.
  static const precisaDe = 3;

  static const chave = Key('toca');
  static const chaveDoPremio = Key('toca-premio');

  @override
  State<Toca> createState() => _TocaState();
}

class _TocaState extends State<Toca> with TickerProviderStateMixin {
  late final AnimationController _cava = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _abre = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  int _gestos = 0;
  bool _aberta = false;

  /// O quanto da terra já saiu, de 0 a 1.
  double get _escavado => (_gestos / Toca.precisaDe).clamp(0.0, 1.0);

  @override
  void dispose() {
    _cava.dispose();
    _abre.dispose();
    super.dispose();
  }

  void _escava() {
    if (_aberta) return;
    setState(() => _gestos++);

    final ultima = _gestos >= Toca.precisaDe;

    // O háptico sobe junto com o progresso: a última pancada é a mais
    // forte, e é ela que anuncia que algo vai acontecer.
    HapticFeedback.mediumImpact();

    // Na última, o som é a abertura — não mais uma raspada.
    //
    // Não é só estética. O `SomService` tem limitador de taxa, e dois sons
    // no mesmo instante viram um: tocar `cavar` aqui **engolia o
    // `premio`**, e a cena inteira acontecia em silêncio no momento que
    // mais importa.
    if (!ultima) SomService.instance.toca(SomDoBaru.cavar);

    _cava
      ..reset()
      ..forward();

    if (ultima) {
      HapticFeedback.heavyImpact();
      setState(() => _aberta = true);
      SomService.instance.toca(SomDoBaru.premio);
      _abre.forward().then((_) {
        if (mounted) widget.aoAbrir();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !_aberta,
      label: widget.rotuloDoPremio,
      child: GestureDetector(
        key: Toca.chave,
        behavior: HitTestBehavior.opaque,
        onTap: _escava,
        // Arrastar também cava: quem tenta "raspar" a terra com o dedo está
        // fazendo exatamente o gesto que a cena pede.
        onPanEnd: (_) => _escava(),
        child: SizedBox(
          height: 220,
          child: AnimatedBuilder(
            animation: Listenable.merge([_cava, _abre]),
            builder: (context, _) {
              return CustomPaint(
                painter: _PintorDaToca(
                  escavado: _escavado,
                  pancada: _cava.value,
                  abertura: _abre.value,
                  cor: widget.cor,
                ),
                child: Center(
                  child: Opacity(
                    opacity: _abre.value,
                    child: Transform.translate(
                      // O prêmio sobe de dentro do buraco: começa embaixo
                      // da linha do chão e emerge.
                      offset: Offset(0, 40 - 70 * _abre.value),
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * _abre.value,
                        child: _Premio(
                          key: Toca.chaveDoPremio,
                          rotulo: widget.rotuloDoPremio,
                          icone: widget.icone,
                          cor: widget.cor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Premio extends StatelessWidget {
  const _Premio({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.cor,
  });

  final String rotulo;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(Espaco.md),
          decoration: BoxDecoration(
            color: Cores.superficie,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cor.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icone, size: 34, color: cor),
        ),
        const SizedBox(height: Espaco.xs),
        Text(rotulo, style: estilo(Tipo.subtitulo, color: cor)),
      ],
    );
  }
}

/// A terra, o buraco e o que voa.
///
/// Tudo em `CustomPainter` pelo mesmo motivo do bicho: uma imagem pronta
/// não acompanha o gesto, e é o acompanhamento que faz a cena parecer
/// resposta e não vídeo.
class _PintorDaToca extends CustomPainter {
  _PintorDaToca({
    required this.escavado,
    required this.pancada,
    required this.abertura,
    required this.cor,
  });

  final double escavado;

  /// 0→1 a cada gesto. É o tremor e a terra voando.
  final double pancada;

  final double abertura;
  final Color cor;

  static const _terra = Color(0xFF7A5A3C);
  static const _terraClara = Color(0xFF9B7550);
  static const _buraco = Color(0xFF3A2A1C);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height * 0.62);
    final p = Paint()..isAntiAlias = true;

    // O tremor some rápido: `sin` de meia onda, não um balanço que fica.
    final tremor = math.sin(pancada * math.pi) * 4;
    final larguraDoMonte = size.width * 0.62;
    canvas.save();
    canvas.translate(0, tremor);

    final monte = Path()
      ..moveTo(centro.dx - larguraDoMonte / 2, centro.dy + 26)
      ..quadraticBezierTo(
        centro.dx - larguraDoMonte / 2,
        centro.dy - 22,
        centro.dx,
        centro.dy - 26,
      )
      ..quadraticBezierTo(
        centro.dx + larguraDoMonte / 2,
        centro.dy - 22,
        centro.dx + larguraDoMonte / 2,
        centro.dy + 26,
      )
      ..close();
    canvas.drawPath(monte, p..color = _terraClara);

    // O buraco cresce com o que já foi cavado, e escancara na abertura —
    // **até a borda do monte**. Sem o teto ele passava da terra e virava um
    // borrão escuro solto na tela: buraco só lê como buraco enquanto tem
    // chão em volta.
    final teto = larguraDoMonte * 0.36;
    final raio = math.min(
      teto,
      (10 + 44 * escavado) * (1 + 0.45 * abertura),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centro.dx, centro.dy - 2),
        width: raio * 2,
        height: raio * 1.15,
      ),
      p..color = _buraco,
    );

    // Uma borda de terra remexida em volta do buraco.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centro.dx, centro.dy - 2),
        width: raio * 2,
        height: raio * 1.15,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = _terra,
    );

    // A luz que vem de dentro quando abre.
    if (abertura > 0) {
      canvas.drawCircle(
        Offset(centro.dx, centro.dy - 8),
        raio * 1.5 * abertura,
        Paint()
          ..color = cor.withValues(alpha: 0.30 * abertura)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    canvas.restore();

    // Os torrões voando. Nascem no buraco e caem — é o que dá peso ao
    // gesto: sem eles a pancada é só um tremor sem causa.
    if (pancada > 0 && pancada < 1) {
      for (var i = 0; i < 7; i++) {
        final ang = -math.pi / 2 + (i - 3) * 0.34;
        final dist = 62 * pancada;
        final queda = 46 * pancada * pancada;
        final pos = centro +
            Offset(math.cos(ang) * dist, math.sin(ang) * dist + queda - 6);
        canvas.drawCircle(
          pos,
          (4.2 - i % 3).toDouble() * (1 - pancada * 0.5),
          Paint()..color = _terra.withValues(alpha: 1 - pancada),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PintorDaToca old) =>
      old.escavado != escavado ||
      old.pancada != pancada ||
      old.abertura != abertura;
}
