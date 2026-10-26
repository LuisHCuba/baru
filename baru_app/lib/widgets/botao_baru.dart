/// O botão do Baru: um só, com cinco papéis (laudo 03, §4.8 e R-V4).
///
/// **Por que um só.** Havia cinco botões — `PrimaryButton`, `GhostButton`,
/// o compacto do estado vazio, o chip "Resgatar" e a pílula de preço da
/// loja — cada um com sua altura, raio, sombra e resposta ao toque (ou
/// nenhuma). Botão que não responde ao dedo parece imagem de botão.
///
/// **Por que com lábio.** A face fica 4 dp acima de uma faixa mais escura
/// da mesma cor; sob o dedo ela desce até o lábio e volta com um leve
/// passo além. O botão "afunda", o aparelho dá um toque curto, e a pessoa
/// sente que apertou alguma coisa. É a parte de "feito para tocar" que o
/// app não tinha.
///
/// **Cor é papel, não gosto** ([Cores]): verde é ação, mel é colher uma
/// recompensa, terracota é a raiz. Todos os pares de face e texto passam
/// de 4,5:1 (`test/contraste_test.dart`).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/motion.dart';
import '../design/tokens.dart';
import '../theme.dart' show estilo;

enum PapelDoBotao {
  /// A ação da tela.
  primario,

  /// Colher, abrir, receber.
  recompensa,

  /// Só o que é da raiz.
  raiz,

  /// A segunda opção, ao lado da primária.
  secundario,

  /// Apagar, sair, revogar. Creme com texto tijolo: se declara sem roubar
  /// a primazia do caminho seguro.
  destrutivo,
}

class _Cores {
  const _Cores(this.face, this.labio, this.texto);
  final Color face;
  final Color labio;
  final Color texto;
}

_Cores _coresDo(PapelDoBotao papel) => switch (papel) {
      PapelDoBotao.primario =>
        const _Cores(Cores.folha600, Cores.folha700, Cores.tintaClara),
      PapelDoBotao.recompensa =>
        const _Cores(Cores.mel400, Cores.mel600, Cores.tinta),
      PapelDoBotao.raiz =>
        const _Cores(Cores.raiz600, Cores.raiz700, Cores.tintaClara),
      PapelDoBotao.secundario =>
        const _Cores(Cores.creme, Cores.cremeLabio, Cores.tinta),
      PapelDoBotao.destrutivo =>
        const _Cores(Cores.creme, Cores.cremeLabio, Cores.alerta),
    };

/// Face e texto de cada papel, para o teste de contraste.
@visibleForTesting
Map<PapelDoBotao, (Color, Color)> get paresDoBotao => {
      for (final p in PapelDoBotao.values)
        p: (_coresDo(p).face, _coresDo(p).texto),
    };

class BotaoBaru extends StatefulWidget {
  const BotaoBaru({
    super.key,
    required this.rotulo,
    required this.aoTocar,
    this.papel = PapelDoBotao.primario,
    this.icone,
    this.altura = alturaPadrao,
    this.expande = true,
    this.ativo = true,
    this.tamanhoDoTexto,
  });

  static const alturaPadrao = 56.0;
  static const alturaCompacta = 44.0;

  final String rotulo;
  final VoidCallback? aoTocar;
  final PapelDoBotao papel;

  /// À esquerda do rótulo, do conjunto próprio ([GlifoFolha] e irmãos) ou
  /// um ícone. Recebe a cor do texto por [IconTheme].
  final Widget? icone;

  /// A altura total, lábio incluído.
  final double altura;

  /// Ocupa a largura que tiver. Falso: do tamanho do rótulo.
  final bool expande;
  final bool ativo;
  final double? tamanhoDoTexto;

  @override
  State<BotaoBaru> createState() => _BotaoBaruState();
}

class _BotaoBaruState extends State<BotaoBaru> {
  bool _apertado = false;
  bool _sobre = false;

  bool get _vivo => widget.ativo && widget.aoTocar != null;

  void _aperta(bool v) {
    if (!_vivo || _apertado == v) return;
    setState(() => _apertado = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = _coresDo(widget.papel);
    final vivo = _vivo;
    final labio = vivo ? (widget.altura >= 48 ? 4.0 : 3.0) : 0.0;
    final reduzido = Movimento.reduzido(context);
    // Sem movimento pedido, o aperto é só a face escurecendo.
    final desce = _apertado && !reduzido;
    final face = !vivo
        ? Cores.trilho
        : _apertado && reduzido
            ? Color.lerp(c.face, c.labio, 0.5)!
            : _sobre
                ? Color.lerp(c.face, c.labio, 0.18)!
                : c.face;
    final corDoTexto = vivo ? c.texto : Cores.tinta500;
    final raio = BorderRadius.circular(
      widget.altura >= 48 ? 18 : 14,
    );
    final tamanho = widget.tamanhoDoTexto ?? (widget.altura >= 48 ? 17.0 : 15.0);

    final rotulo = Text(
      widget.rotulo,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: estilo(Tipo.subtitulo, color: corDoTexto, weight: FontWeight.w800)
          .copyWith(fontSize: tamanho, height: 1.2),
    );
    final conteudo = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icone != null) ...[
          IconTheme.merge(
            data: IconThemeData(color: corDoTexto, size: 20),
            child: widget.icone!,
          ),
          const SizedBox(width: Espaco.xs),
        ],
        Flexible(child: rotulo),
      ],
    );

    final faceDoBotao = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      height: widget.altura - labio,
      padding: const EdgeInsets.symmetric(horizontal: Espaco.lg),
      decoration: BoxDecoration(color: face, borderRadius: raio),
      // `widthFactor: 1` deixa o botão do tamanho do rótulo quando não
      // expande; `alignment` no container o esticaria até a borda.
      child: Center(widthFactor: widget.expande ? null : 1, child: conteudo),
    );

    return Semantics(
      button: true,
      enabled: vivo,
      label: widget.rotulo,
      excludeSemantics: true,
      onTap: vivo ? widget.aoTocar : null,
      child: MouseRegion(
        cursor: vivo ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: vivo ? (_) => setState(() => _sobre = true) : null,
        onExit: vivo ? (_) => setState(() => _sobre = false) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _aperta(true),
          onTapUp: (_) => _aperta(false),
          onTapCancel: () => _aperta(false),
          onTap: vivo
              ? () {
                  HapticFeedback.lightImpact();
                  widget.aoTocar!();
                }
              : null,
          child: SizedBox(
            height: widget.altura,
            width: widget.expande ? double.infinity : null,
            child: Stack(
              children: [
                if (labio > 0)
                  Positioned.fill(
                    top: labio,
                    child: DecoratedBox(
                      decoration:
                          BoxDecoration(color: c.labio, borderRadius: raio),
                    ),
                  ),
                AnimatedPadding(
                  // 70 ms para descer, 120 ms para voltar com o passo além.
                  duration: Duration(milliseconds: desce ? 70 : 120),
                  curve: desce ? Curves.easeOut : Curvas.entrada,
                  padding: EdgeInsets.only(
                    top: desce ? labio : 0,
                    bottom: desce ? 0 : labio,
                  ),
                  child: faceDoBotao,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
