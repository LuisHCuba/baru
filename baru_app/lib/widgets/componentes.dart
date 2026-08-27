/// Componentes canônicos do Baru.
///
/// Um componente por função. Variação visual nasce de token, não de widget
/// novo — a alternativa é o que o app tinha: cada tela montando o seu próprio
/// cartão com um raio e uma sombra ligeiramente diferentes.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Número que **sobe animado** em vez de saltar.
///
/// Contador que troca de valor sem transição some da percepção: o usuário não
/// vê a recompensa acontecer, só descobre um número diferente.
class ContadorAnimado extends StatefulWidget {
  const ContadorAnimado({
    super.key,
    required this.valor,
    this.estiloTexto,
    this.prefixo = '',
    this.sufixo = '',
    this.formata,
  });

  final int valor;
  final TextStyle? estiloTexto;
  final String prefixo;
  final String sufixo;

  /// Formatação opcional (por exemplo, minutos viram "2h 30min").
  final String Function(int)? formata;

  @override
  State<ContadorAnimado> createState() => _ContadorAnimadoState();
}

class _ContadorAnimadoState extends State<ContadorAnimado> {
  late double _anterior = widget.valor.toDouble();

  @override
  void didUpdateWidget(ContadorAnimado old) {
    super.didUpdateWidget(old);
    if (old.valor != widget.valor) _anterior = old.valor.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.estiloTexto ?? estilo(Tipo.numero);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _anterior, end: widget.valor.toDouble()),
      duration: Movimento.duracao(context, Tempo.contador),
      curve: Curvas.enfatica,
      builder: (context, v, _) {
        final n = v.round();
        return Text(
          '${widget.prefixo}${widget.formata?.call(n) ?? '$n'}${widget.sufixo}',
          // Tabular para o número não tremer enquanto corre.
          style: base.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

/// Barra de progresso que **cresce** até o valor.
class BarraAnimada extends StatelessWidget {
  const BarraAnimada({
    super.key,
    required this.fracao,
    this.altura = 10,
    this.cor,
    this.fundo,
    this.duracao,
  });

  final double fracao;
  final double altura;
  final Color? cor;
  final Color? fundo;
  final Duration? duracao;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: Raio.todos(Raio.pilula),
      child: Container(
        height: altura,
        color: fundo ?? Cores.tintaA(0.09),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fracao.clamp(0.0, 1.0)),
            duration: Movimento.duracao(context, duracao ?? Tempo.contador),
            curve: Curvas.enfatica,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  color: cor ?? Cores.primaria,
                  borderRadius: Raio.todos(Raio.pilula),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartão canônico. Raio amplo, sombra difusa, e resposta ao toque quando é
/// tocável.
class CartaoBaru extends StatefulWidget {
  const CartaoBaru({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Espaco.lg),
    this.cor,
    this.elevado = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? cor;
  final bool elevado;

  @override
  State<CartaoBaru> createState() => _CartaoBaruState();
}

class _CartaoBaruState extends State<CartaoBaru> {
  bool _pressionado = false;

  @override
  Widget build(BuildContext context) {
    final tocavel = widget.onTap != null;
    final escala = _pressionado ? Movimento.amplitude(context, 0.03) : 0.0;
    return GestureDetector(
      onTap: tocavel
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      onTapDown: tocavel ? (_) => setState(() => _pressionado = true) : null,
      onTapUp: tocavel ? (_) => setState(() => _pressionado = false) : null,
      onTapCancel: tocavel ? () => setState(() => _pressionado = false) : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: 1 - escala,
        duration: Movimento.duracao(context, Tempo.microFeedback),
        curve: Curvas.padrao,
        child: AnimatedContainer(
          duration: Movimento.duracao(context, Tempo.microFeedback),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.cor ?? Cores.superficieElevada,
            borderRadius: Raio.todos(Raio.cartao),
            boxShadow: widget.elevado
                ? (_pressionado ? Elevacao.cartaoElevado : Elevacao.cartao)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Etiqueta curta e colorida — categoria, estado de missão, marco.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    required this.cor,
    this.icone,
    this.forte = false,
  });

  final String texto;
  final Color cor;
  final IconData? icone;

  /// Fundo cheio em vez de tingido.
  final bool forte;

  @override
  Widget build(BuildContext context) {
    final fg = forte ? Cores.tintaClara : cor;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espaco.sm,
        vertical: Espaco.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: forte ? cor : cor.withValues(alpha: 0.15),
        borderRadius: Raio.todos(Raio.pilula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 13, color: fg),
            const SizedBox(width: Espaco.xxs + 2),
          ],
          Text(
            texto,
            style: estilo(Tipo.rotuloPequeno, color: fg)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Estado vazio ou de erro — nunca uma tela em branco.
///
/// O §4B exige que toda tela tenha vazio, erro e offline **com ação**. Uma
/// tela vazia sem saída é um beco.
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({
    super.key,
    required this.icone,
    required this.titulo,
    required this.corpo,
    this.acao,
    this.rotuloAcao,
    this.cor,
  });

  final IconData icone;
  final String titulo;
  final String corpo;
  final VoidCallback? acao;
  final String? rotuloAcao;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Cores.primaria;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 28, color: c),
            ),
            const SizedBox(height: Espaco.md),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: estilo(Tipo.subtitulo),
            ),
            const SizedBox(height: Espaco.xs),
            Text(
              corpo,
              textAlign: TextAlign.center,
              style: estilo(Tipo.corpo, color: Cores.tintaA(0.62)),
            ),
            if (acao != null && rotuloAcao != null) ...[
              const SizedBox(height: Espaco.lg),
              _BotaoCompacto(rotulo: rotuloAcao!, onTap: acao!, cor: c),
            ],
          ],
        ),
      ),
    );
  }
}

class _BotaoCompacto extends StatelessWidget {
  const _BotaoCompacto({
    required this.rotulo,
    required this.onTap,
    required this.cor,
  });

  final String rotulo;
  final VoidCallback onTap;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: Toque.minimo,
        padding: const EdgeInsets.symmetric(horizontal: Espaco.xl),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: Raio.todos(Raio.botao),
          boxShadow: Elevacao.acaoPrimaria,
        ),
        alignment: Alignment.center,
        child: Text(
          rotulo,
          style: estilo(Tipo.subtitulo, color: Cores.tintaClara),
        ),
      ),
    );
  }
}

/// Esqueleto de carregamento. Nunca um spinner nu (§4B).
class Esqueleto extends StatefulWidget {
  const Esqueleto({
    super.key,
    this.altura = 16,
    this.largura,
    this.raio = Raio.chip,
  });

  final double altura;
  final double? largura;
  final double raio;

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Movimento.reduzido(context)) {
      _c
        ..stop()
        ..value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.altura,
        width: widget.largura,
        decoration: BoxDecoration(
          color: Cores.tintaA(0.05 + _c.value * 0.05),
          borderRadius: Raio.todos(widget.raio),
        ),
      ),
    );
  }
}

/// O topo de uma tela de detalhe: voltar e título.
///
/// Estava privado na tela de tempo. Com três telas de detalhe, copiar era
/// garantir que uma delas ficasse com o alvo de toque ou o espaçamento
/// diferente das outras.
class CabecalhoDeDetalhe extends StatelessWidget {
  const CabecalhoDeDetalhe({
    super.key,
    required this.titulo,
    required this.aoVoltar,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;
  final VoidCallback aoVoltar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espaco.margemTela,
        Espaco.md,
        Espaco.margemTela,
        Espaco.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: 'voltar',
                child: GestureDetector(
                  onTap: aoVoltar,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: Toque.minimo,
                    height: Toque.minimo,
                    child: Icon(Icons.arrow_back_rounded, size: 22),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  titulo,
                  style: estilo(Tipo.display),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (subtitulo != null)
            Padding(
              padding: const EdgeInsets.only(
                left: Toque.minimo,
                top: Espaco.xxs,
              ),
              child: Text(
                subtitulo!,
                style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Uma linha de "rótulo à esquerda, valor à direita".
class LinhaDeValor extends StatelessWidget {
  const LinhaDeValor({
    super.key,
    required this.rotulo,
    required this.valor,
    this.icone,
    this.cor,
    this.detalhe,
  });

  final String rotulo;
  final String valor;
  final IconData? icone;
  final Color? cor;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Cores.tinta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
      child: Row(
        children: [
          if (icone != null) ...[
            Icon(icone, size: 17, color: c),
            const SizedBox(width: Espaco.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: estilo(Tipo.corpo)),
                if (detalhe != null)
                  Text(
                    detalhe!,
                    style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.55)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: Espaco.sm),
          Text(valor, style: estilo(Tipo.subtitulo, color: c, tabular: true)),
        ],
      ),
    );
  }
}
