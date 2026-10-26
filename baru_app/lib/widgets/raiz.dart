import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// A raiz, desenhada.
///
/// **Por que deixar de ser um número.** "12 dias" é um placar; placar se
/// perde sem doer. Uma raiz que a pessoa viu engrossar ao longo de doze dias
/// é uma coisa que ela construiu — e ninguém joga fora o que construiu. É a
/// mesma diferença entre um contador e um jardim.
///
/// **Como cresce.** Três coisas mudam com os dias, e nenhuma delas é
/// aleatória:
///
/// 1. **Profundidade.** A raiz principal desce mais fundo, com desaceleração
///    — os primeiros dias mudam muito, o quinquagésimo muda pouco. Sem isso,
///    ou ela sai da tela ou o dia 100 é igual ao dia 10.
/// 2. **Espessura.** O tronco engrossa. Raiz fina é raiz nova.
/// 3. **Ramificações.** Nascem em marcos, não a cada dia: um galho novo tem
///    de ser um acontecimento.
///
/// **Determinismo.** O mesmo número de dias desenha sempre a mesma raiz. Sem
/// `Random` de relógio: a raiz de alguém é dela, e não pode mudar de forma
/// entre duas aberturas do app. A variação vem de um gerador semeado pelo
/// próprio número de dias.
class RaizViva extends StatelessWidget {
  const RaizViva({
    super.key,
    required this.dias,
    // Terracota em todo lugar: a raiz tem uma cor só (ADR-027).
    this.cor = Cores.raiz600,
    this.corDaTerra = const Color(0xFFEDE3D2),
    this.mostraTerra = true,
    this.diasExatos,
  });

  /// Dias presentes. É a única entrada: a forma é função dele.
  final int dias;

  /// Os dias com fração, para a raiz **crescer** na tela (de N para N+1 na
  /// cena da raiz). A forma segue determinística: só alonga, engrossa e
  /// faz brotar o galho do marco aos poucos.
  final double? diasExatos;

  /// Onde fica a ponta da raiz num quadro deste tamanho.
  ///
  /// A cena da raiz precisa dela para a gota de luz escorrer até o lugar
  /// certo. É a mesma conta do pintor — se um mudar, o teste
  /// `raiz_cena_test.dart` acusa.
  static Offset pontaEm(Size size, double dias) {
    final topo = size.height * 0.12;
    final chao = topo + 6;
    if (dias <= 0) return Offset(size.width / 2, chao + 6);
    final crescimento = 1 - math.exp(-dias / 26);
    final fundo = chao + (size.height - chao) * (0.30 + 0.66 * crescimento);
    final desvio = math.sin(3.1 + dias * 0.3) * 9;
    return Offset(size.width / 2 + desvio, fundo);
  }

  /// A linha da grama: de onde a raiz sai.
  static double chaoEm(Size size) => size.height * 0.12 + 6;

  final Color cor;
  final Color corDaTerra;

  /// A faixa de terra no topo. Desligada no widget da tela inicial, onde o
  /// espaço é curto.
  final bool mostraTerra;

  static const chave = Key('raiz-viva');

  /// Em que dias a raiz ganha um galho novo.
  ///
  /// Escolhidos onde a pessoa já sente que passou de fase: a primeira
  /// semana, o mês, o trimestre. Um galho por dia viraria mato.
  static const marcos = [3, 7, 14, 30, 60, 100, 180, 365];

  /// Quantos galhos a raiz tem hoje.
  static int galhosEm(int dias) =>
      marcos.where((m) => dias >= m).length;

  /// O próximo marco, ou nulo quando já passou de todos.
  static int? proximoMarco(int dias) {
    for (final m in marcos) {
      if (dias < m) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: chave,
      child: CustomPaint(
        painter: _PintorDaRaiz(
          dias: dias,
          exatos: diasExatos ?? dias.toDouble(),
          cor: cor,
          corDaTerra: corDaTerra,
          mostraTerra: mostraTerra,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PintorDaRaiz extends CustomPainter {
  _PintorDaRaiz({
    required this.dias,
    required this.exatos,
    required this.cor,
    required this.corDaTerra,
    required this.mostraTerra,
  });

  final int dias;
  final double exatos;
  final Color cor;
  final Color corDaTerra;
  final bool mostraTerra;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final topo = size.height * 0.12;
    final chao = topo + 6;

    if (mostraTerra) {
      canvas.drawRect(
        Rect.fromLTWH(0, topo, size.width, size.height - topo),
        Paint()..color = corDaTerra,
      );
    }

    if (exatos <= 0) {
      // Dia zero não é uma raiz de tamanho zero: é uma semente. Desenhar
      // "nada" faria a tela parecer quebrada em vez de recém-começada.
      canvas.drawCircle(
        Offset(size.width / 2, chao + 6),
        5,
        Paint()..color = cor.withValues(alpha: 0.55),
      );
      return;
    }

    // Saturação: os primeiros dias mudam muito, o centésimo quase nada.
    // Sem isso a raiz sai da tela no dia 40.
    final crescimento = 1 - math.exp(-exatos / 26);
    final fundo = chao + (size.height - chao) * (0.30 + 0.66 * crescimento);
    final grossura = 3.0 + 7.0 * crescimento;

    final x = size.width / 2;
    // Semeado pelos dias: a mesma raiz, sempre. Ver a nota da classe.
    final sorte = math.Random(dias * 7919);

    final tinta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = cor;

    // O tronco, com uma sinuosidade leve — raiz reta parece cabo.
    final tronco = Path()..moveTo(x, chao);
    const passos = 14;
    var ultimo = Offset(x, chao);
    for (var i = 1; i <= passos; i++) {
      final t = i / passos;
      final y = chao + (fundo - chao) * t;
      final desvio = math.sin(t * 3.1 + exatos * 0.3) * 9 * t;
      final ponto = Offset(x + desvio, y);
      tronco.lineTo(ponto.dx, ponto.dy);
      ultimo = ponto;
    }
    canvas.drawPath(tronco, tinta..strokeWidth = grossura);

    // A ponta viva: mais clara, e é onde a raiz ainda está indo.
    canvas.drawCircle(
      ultimo,
      grossura * 0.6,
      Paint()..color = cor.withValues(alpha: 0.45),
    );

    // Os galhos. Nascem em marcos, alternando os lados, e o galho mais
    // antigo é o mais grosso e o mais longo — foi o que teve mais tempo.
    //
    // Com dias fracionários, o galho do marco que está chegando brota aos
    // poucos: entra na conta e cresce com a fração.
    final inteiros = exatos.floor();
    final fracao = exatos - inteiros;
    final brotando = fracao > 0 && RaizViva.marcos.contains(inteiros + 1);
    final galhos = RaizViva.galhosEm(inteiros) + (brotando ? 1 : 0);
    for (var g = 0; g < galhos; g++) {
      final t = 0.28 + 0.62 * (g / math.max(1, galhos));
      final origem = Offset(
        x + math.sin(t * 3.1 + exatos * 0.3) * 9 * t,
        chao + (fundo - chao) * t,
      );
      final lado = g.isEven ? 1.0 : -1.0;
      final idade = 1 - g / (galhos + 1);
      final novo = brotando && g == galhos - 1;
      final comp = (size.width * 0.20) *
          (0.55 + 0.45 * idade) *
          (novo ? Curves.easeOutBack.transform(fracao) : 1);
      final abertura = 0.5 + sorte.nextDouble() * 0.45;

      final galho = Path()
        ..moveTo(origem.dx, origem.dy)
        ..quadraticBezierTo(
          origem.dx + lado * comp * 0.55,
          origem.dy + comp * 0.20,
          origem.dx + lado * comp,
          origem.dy + comp * abertura,
        );
      canvas.drawPath(
        galho,
        tinta
          ..strokeWidth = grossura * (0.36 + 0.30 * idade)
          ..color = cor.withValues(alpha: 0.85),
      );
    }
    tinta.color = cor;
  }

  @override
  bool shouldRepaint(_PintorDaRaiz old) =>
      old.dias != dias ||
      old.exatos != exatos ||
      old.cor != cor ||
      old.corDaTerra != corDaTerra ||
      old.mostraTerra != mostraTerra;
}
