/// As folhas que saem do prêmio e voam até o saldo.
///
/// Colher uma missão creditava as folhas num número no canto que mudava
/// sozinho: o prêmio "aparecia" no saldo sem que a pessoa visse o caminho.
/// O caminho é o que liga as duas coisas — "ganhei ali, está aqui agora"
/// (laudo 09, R3; laudo 05, R7). É o mesmo gesto do fim de sessão.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';
import 'glifos.dart';

/// Acha, a partir de [raiz], o primeiro widget com [chave] e devolve o
/// centro dele na tela.
Offset? centroDe(BuildContext raiz, Key chave) {
  Element? achado;
  void visita(Element e) {
    if (achado != null) return;
    if (e.widget.key == chave) {
      achado = e;
      return;
    }
    e.visitChildren(visita);
  }

  (raiz as Element).visitChildren(visita);
  final caixa = achado?.findRenderObject();
  if (caixa is! RenderBox || !caixa.attached || !caixa.hasSize) return null;
  return caixa.localToGlobal(caixa.size.center(Offset.zero));
}

/// Solta [quantas] folhas de [de] até [para], por cima de tudo.
///
/// Com "reduzir movimento" não voa nada: o saldo já sobe contado.
void voaFolhas(
  BuildContext context, {
  required Offset de,
  required Offset para,
  int quantas = 6,
}) {
  if (Movimento.reduzido(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entrada;
  entrada = OverlayEntry(
    builder: (_) => _Voo(
      de: de,
      para: para,
      quantas: quantas,
      aoChegar: () => entrada.remove(),
    ),
  );
  overlay.insert(entrada);
}

class _Voo extends StatefulWidget {
  const _Voo({
    required this.de,
    required this.para,
    required this.quantas,
    required this.aoChegar,
  });

  final Offset de;
  final Offset para;
  final int quantas;
  final VoidCallback aoChegar;

  @override
  State<_Voo> createState() => _VooState();
}

class _VooState extends State<_Voo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward().whenComplete(() {
      HapticFeedback.selectionClick();
      widget.aoChegar();
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          children: [
            for (var i = 0; i < widget.quantas; i++) _folha(i),
          ],
        ),
      ),
    );
  }

  Widget _folha(int i) {
    // Cada uma sai um pouco depois da outra, por um arco próprio: uma
    // revoada, não um bloco.
    final atraso = i * 0.06;
    final u = ((_c.value - atraso) / (1 - atraso * 1.5)).clamp(0.0, 1.0);
    final e = Curves.easeInCubic.transform(u);
    final lado = i.isEven ? 1.0 : -1.0;
    final controle = Offset(
      (widget.de.dx + widget.para.dx) / 2 + lado * (40 + i * 9),
      math.min(widget.de.dy, widget.para.dy) - 60 - i * 6,
    );
    final p = Offset(
      (1 - e) * (1 - e) * widget.de.dx +
          2 * (1 - e) * e * controle.dx +
          e * e * widget.para.dx,
      (1 - e) * (1 - e) * widget.de.dy +
          2 * (1 - e) * e * controle.dy +
          e * e * widget.para.dy,
    );
    const lado0 = 22.0;
    // Encolhe ao chegar: entra no saldo em vez de cobri-lo.
    final tamanho = lado0 * (1 - 0.45 * e);
    return Positioned(
      left: p.dx - tamanho / 2,
      top: p.dy - tamanho / 2,
      child: Opacity(
        opacity: u <= 0 ? 0 : (u > 0.92 ? (1 - u) / 0.08 : 1),
        child: Transform.rotate(
          angle: lado * e * math.pi * 1.2,
          child: GlifoFolha(tamanho: tamanho),
        ),
      ),
    );
  }
}
