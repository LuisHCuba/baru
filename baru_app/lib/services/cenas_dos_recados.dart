/// As cenas das notificações animadas.
///
/// **O pedido.** As notificações tinham de ser como o widget: o bicho da
/// pessoa, numa cena que muda com a hora e com o que se está dizendo — e
/// mexendo. Uma notificação do Android é `RemoteViews`, como o widget: não
/// roda `CustomPainter` nem Flutter. O que ela sabe fazer é trocar imagens
/// num `ViewFlipper`, sozinha, enquanto está na tela.
///
/// Então o caminho é o mesmo da sobreposição (laudo 05, §5): o Dart
/// rasteriza o `PetView` de verdade em alguns quadros — respiração e
/// piscada — e o Kotlin só anima a troca. Aqui, com duas diferenças:
///
/// * **um bicho por tema.** A pausa chama com o bicho bocejando, o convite
///   com ele contente, a raiz com ele radiante, a despedida com ele
///   dormindo. O humor é o recado antes da frase;
/// * **um fundo por tema e por luz.** Árvore e sombra na pausa, trilha de
///   brotos no convite, o corte de terra com a raiz, o ninho na despedida —
///   cada um de manhã, de tarde e de noite. O Kotlin escolhe a luz pela
///   hora em que o recado toca, com o app fechado.
///
/// Desenha ao sair do app, junto dos quadros da sobreposição, e só quando a
/// aparência do bicho muda.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../design/tokens.dart';
import '../models.dart';
import '../widgets/pet.dart';
import 'quadros_do_bicho.dart';

/// Sobre o que o recado fala. Decide o humor do bicho e o cenário.
enum TemaDoRecado {
  /// A pausa ao longo do dia: o bicho boceja debaixo de uma árvore.
  pausa(Mood.sleepy, Activity.idle),

  /// O convite do dia: contente, numa trilha de brotos.
  convite(Mood.content, Activity.idle),

  /// A raiz em risco: radiante, sobre o corte de terra com a raiz. Nunca
  /// triste (laudo 01, U9): o recado é "ainda dá", não "vai perder".
  raiz(Mood.radiant, Activity.idle),

  /// A despedida da escada: dormindo no ninho.
  despedida(Mood.sleepy, Activity.nap);

  const TemaDoRecado(this.humor, this.atividade);

  final Mood humor;
  final Activity atividade;
}

/// A luz da cena. O Kotlin escolhe pela hora do toque, com a mesma regra
/// de [luzDa].
enum LuzDoRecado {
  manha(Color(0xFF7CC8EC), Color(0xFFCDEBF7)),
  tarde(Color(0xFFF2B26B), Color(0xFFF9DDB0)),
  noite(Color(0xFF3B3F86), Color(0xFF6A5BB0));

  const LuzDoRecado(this.cimo, this.horizonte);

  final Color cimo;
  final Color horizonte;
}

/// Manhã até 12h, tarde até 18h, noite depois. Espelho de
/// `RecadoAnimado.luzDa` (Kotlin).
LuzDoRecado luzDa(DateTime quando) {
  final h = quando.hour;
  if (h >= 5 && h < 12) return LuzDoRecado.manha;
  if (h >= 12 && h < 18) return LuzDoRecado.tarde;
  return LuzDoRecado.noite;
}

class CenasDosRecados {
  CenasDosRecados._();

  static final CenasDosRecados instance = CenasDosRecados._();

  /// O bicho de cada quadro, em pixels finais.
  ///
  /// **Pequeno de propósito.** A notificação viaja ao processo do sistema
  /// por Binder, com os bitmaps **descomprimidos** (4 bytes por pixel), e a
  /// transação tem teto prático de ~1 MB — o mesmo que esvaziou o widget na
  /// primeira versão (ver `WidgetService.tamanhoDoPng`). Cinco quadros de
  /// 144×122 dão ~350 KB; o fundo, sem alfa, ~110 KB; a vista curta, com os
  /// quadros reduzidos, ~170 KB. Sobra folga.
  static const tamanhoDoQuadro = Size(144, 122);

  /// O fundo da notificação expandida: a faixa larga de 16:7.
  static const tamanhoDoFundo = Size(320, 140);

  /// O peito em cada quadro. Quatro bastam: o Kotlin os percorre indo e
  /// voltando, com fusão entre um e outro.
  static const respiros = [-1.0, -1 / 3, 1 / 3, 1.0];

  static const _canal = MethodChannel('baru/overlay');

  @visibleForTesting
  MethodChannel canal = _canal;

  @visibleForTesting
  Future<String> Function(Widget w, String chave, Size tamanho)? rasteriza;

  @visibleForTesting
  int desenhos = 0;

  String? _ultimaChave;
  Future<void>? _emCurso;

  @visibleForTesting
  void zeraParaTeste() {
    _ultimaChave = null;
    _emCurso = null;
    desenhos = 0;
  }

  /// O bicho de um quadro, no humor do tema.
  static Widget quadro(AparenciaDoBicho a, TemaDoRecado tema, QuadroFixo q) =>
      SizedBox(
        width: tamanhoDoQuadro.width,
        height: tamanhoDoQuadro.height,
        child: PetView(
          species: a.especie,
          mood: tema.humor,
          activity: tema.atividade,
          coat: a.pelagem,
          roupas: a.roupas,
          roupaDeCabeca: a.roupaDeCabeca,
          estagio: a.estagio,
          interativo: false,
          width: tamanhoDoQuadro.width,
          height: tamanhoDoQuadro.height,
          scale: tamanhoDoQuadro.height / 150,
          quadro: q,
        ),
      );

  /// O cenário de um tema numa luz.
  static Widget fundo(TemaDoRecado tema, LuzDoRecado luz) => SizedBox(
        width: tamanhoDoFundo.width,
        height: tamanhoDoFundo.height,
        child: CustomPaint(painter: PintaFundoDoRecado(tema, luz)),
      );

  /// Garante que as cenas gravadas são as desta aparência. Nunca lança:
  /// sem cenas, o Kotlin manda a notificação comum, com o rosto.
  Future<void> atualiza(AparenciaDoBicho a) {
    if (!_ehAndroid && rasteriza == null) return Future.value();
    if (a.chave == _ultimaChave) return Future.value();
    final anterior = _emCurso ?? Future<void>.value();
    final esta = anterior.then((_) => _desenha(a));
    _emCurso = esta;
    return esta;
  }

  Future<void> _desenha(AparenciaDoBicho a) async {
    if (a.chave == _ultimaChave) return;
    try {
      final atual = await canal.invokeMethod<String>('cenasChave');
      if (atual == a.chave) {
        _ultimaChave = a.chave;
        return;
      }
      final desenha = rasteriza ?? _rasterizaDeVerdade;
      // Nome novo a cada leva, como os quadros da sobreposição: os arquivos
      // em uso por uma notificação na tela nunca são sobrescritos.
      final prefixo = 'baru_cena_${QuadrosDoBicho.impressao(
        '${a.chave}|${DateTime.now().microsecondsSinceEpoch}',
      )}';
      final temas = <String, Object>{};
      for (final tema in TemaDoRecado.values) {
        final respiro = <String>[];
        for (var i = 0; i < respiros.length; i++) {
          respiro.add(await desenha(
            quadro(a, tema, QuadroFixo(respiro: respiros[i])),
            '${prefixo}_${tema.name}_$i',
            tamanhoDoQuadro,
          ));
        }
        final pisca = await desenha(
          quadro(a, tema, const QuadroFixo(pisca: 1)),
          '${prefixo}_${tema.name}_pisca',
          tamanhoDoQuadro,
        );
        final fundos = <String, String>{};
        for (final luz in LuzDoRecado.values) {
          fundos[luz.name] = await desenha(
            fundo(tema, luz),
            '${prefixo}_${tema.name}_${luz.name}',
            tamanhoDoFundo,
          );
        }
        temas[tema.name] = {
          'respiro': respiro,
          'pisca': pisca,
          'fundos': fundos,
        };
      }
      desenhos++;
      final ok = await canal.invokeMethod<bool>('cenas', {
        'chave': a.chave,
        'temas': temas,
      });
      if (ok ?? false) _ultimaChave = a.chave;
    } catch (e) {
      debugPrint('Baru: cenas dos recados falharam ($e)');
    }
  }

  /// `pixelRatio: 1`: os tamanhos acima já são os pixels finais, pelo teto
  /// do Binder. A densidade da tela multiplicaria e estouraria.
  Future<String> _rasterizaDeVerdade(Widget w, String chave, Size t) =>
      HomeWidget.renderFlutterWidget(
        w,
        key: chave,
        logicalSize: t,
        pixelRatio: 1,
      );

  bool get _ehAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}

/// O cenário de cada recado.
///
/// O céu na luz da hora, um morro embaixo, e o objeto que diz o assunto
/// antes de qualquer palavra. O lado direito fica livre: é onde o Kotlin
/// põe o bicho animado por cima.
class PintaFundoDoRecado extends CustomPainter {
  PintaFundoDoRecado(this.tema, this.luz);

  final TemaDoRecado tema;
  final LuzDoRecado luz;

  bool get _noite => luz == LuzDoRecado.noite;

  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [luz.cimo, luz.horizonte],
        ).createShader(r),
    );
    _astro(canvas, s);

    // O morro: o chão do bicho.
    final chao = _noite ? const Color(0xFF2E4A3A) : const Color(0xFF7DB36B);
    final morro = Path()
      ..moveTo(0, s.height * 0.78)
      ..quadraticBezierTo(s.width * 0.45, s.height * 0.62, s.width, s.height * 0.74)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(morro, Paint()..color = chao);

    switch (tema) {
      case TemaDoRecado.pausa:
        // Sem "z" desenhado aqui: o bicho sonolento já boceja os dele.
        _arvore(canvas, s);
      case TemaDoRecado.convite:
        _trilha(canvas, s);
      case TemaDoRecado.raiz:
        _raiz(canvas, s);
      case TemaDoRecado.despedida:
        _ninho(canvas, s);
    }
  }

  void _astro(Canvas canvas, Size s) {
    if (_noite) {
      final sorte = Random(tema.index * 31 + 7);
      for (var i = 0; i < 18; i++) {
        canvas.drawCircle(
          Offset(sorte.nextDouble() * s.width, sorte.nextDouble() * s.height * 0.5),
          0.6 + sorte.nextDouble() * 1.2,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.4 + sorte.nextDouble() * 0.5),
        );
      }
      final c = Offset(s.width * 0.42, s.height * 0.2);
      final raio = s.height * 0.09;
      canvas.drawCircle(c, raio * 2.2, Paint()..color = Colors.white.withValues(alpha: 0.08));
      canvas.drawCircle(c, raio, Paint()..color = const Color(0xFFFFF3C4));
      canvas.drawCircle(c + Offset(raio * 0.45, -raio * 0.25), raio * 0.9, Paint()..color = luz.cimo);
      return;
    }
    final c = Offset(s.width * 0.42, s.height * 0.22);
    final raio = s.height * 0.1;
    canvas.drawCircle(
      c,
      raio * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF1B8).withValues(alpha: 0.7),
            const Color(0xFFFFF1B8).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: raio * 3)),
    );
    canvas.drawCircle(c, raio, Paint()..color = const Color(0xFFFFE27A));
  }

  /// A árvore da pausa, à esquerda, com a sombra onde descansar.
  void _arvore(Canvas canvas, Size s) {
    final base = Offset(s.width * 0.16, s.height * 0.76);
    canvas.drawOval(
      Rect.fromCenter(center: base + Offset(s.width * 0.06, 4), width: s.width * 0.34, height: s.height * 0.08),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base - Offset(0, s.height * 0.16), width: s.width * 0.03, height: s.height * 0.34),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF7A5232),
    );
    final copa = _noite ? const Color(0xFF2F5C3C) : Cores.folha600;
    for (final (dx, dy, raio) in const [(-0.05, -0.42, 0.17), (0.05, -0.47, 0.19), (0.0, -0.58, 0.16)]) {
      canvas.drawCircle(
        base + Offset(s.width * dx, s.height * dy),
        s.height * raio,
        Paint()..color = copa,
      );
    }
  }

  /// A trilha de brotos do convite.
  void _trilha(Canvas canvas, Size s) {
    final terra = Paint()..color = const Color(0xFFD9B98A).withValues(alpha: _noite ? 0.35 : 0.8);
    final trilha = Path()
      ..moveTo(0, s.height * 0.95)
      ..quadraticBezierTo(s.width * 0.3, s.height * 0.78, s.width * 0.62, s.height * 0.86)
      ..lineTo(s.width * 0.62, s.height * 0.94)
      ..quadraticBezierTo(s.width * 0.3, s.height * 0.88, 0, s.height)
      ..close();
    canvas.drawPath(trilha, terra);
    final broto = Paint()
      ..color = _noite ? const Color(0xFF8FC27A) : Cores.folha600
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final b = Offset(s.width * (0.08 + i * 0.13), s.height * (0.86 - i * 0.03));
      canvas.drawLine(b, b - const Offset(0, 9), broto);
      canvas.drawOval(Rect.fromCenter(center: b + const Offset(-4, -10), width: 8, height: 5), broto);
      canvas.drawOval(Rect.fromCenter(center: b + const Offset(4, -11), width: 8, height: 5), broto);
    }
  }

  /// O corte de terra com a raiz: o mesmo símbolo da sequência no app.
  void _raiz(Canvas canvas, Size s) {
    final topo = s.height * 0.74;
    canvas.drawRect(
      Rect.fromLTRB(0, topo, s.width * 0.6, s.height),
      Paint()..color = const Color(0xFF8B5A3C).withValues(alpha: 0.85),
    );
    final raiz = Paint()
      ..color = Cores.raiz600
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = s.width * 0.26;
    final tronco = Path()
      ..moveTo(x, topo)
      ..quadraticBezierTo(x - 6, topo + 14, x + 2, s.height);
    canvas.drawPath(tronco, raiz);
    raiz.strokeWidth = 2;
    for (final (dy, dx) in const [(10.0, -22.0), (14.0, 20.0), (22.0, -14.0), (26.0, 16.0)]) {
      final o = Offset(x - 2, topo + dy);
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..quadraticBezierTo(o.dx + dx / 2, o.dy + 2, o.dx + dx, o.dy + 8),
        raiz,
      );
    }
    final folha = Paint()..color = Cores.folha600;
    canvas.drawOval(Rect.fromCenter(center: Offset(x - 6, topo - 8), width: 12, height: 7), folha);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + 6, topo - 10), width: 12, height: 7), folha);
  }

  /// O ninho da despedida: galhos trançados embaixo do bicho que dorme.
  void _ninho(Canvas canvas, Size s) {
    final c = Offset(s.width * 0.78, s.height * 0.88);
    final galho = Paint()
      ..color = const Color(0xFF9A6B42)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromCenter(center: c + Offset(0, i * 2.0), width: s.width * 0.42 - i * 6, height: s.height * 0.26),
        0.15,
        pi - 0.3,
        false,
        galho,
      );
    }
  }

  @override
  bool shouldRepaint(PintaFundoDoRecado old) => old.tema != tema || old.luz != luz;
}
