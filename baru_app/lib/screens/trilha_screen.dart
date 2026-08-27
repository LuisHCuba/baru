import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/progressao.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/componentes.dart';

/// A trilha: a tela que responde "por que eu volto amanhã".
///
/// Antes o app tinha "Habitat nível N", que era o número de itens dividido por
/// três com outro nome — não havia progressão nenhuma, nem nada a alcançar.
class TrilhaScreen extends StatelessWidget {
  const TrilhaScreen({super.key, this.aoVoltar});

  final VoidCallback? aoVoltar;

  static const rota = '/trilha';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final p = app.progresso;

    if (!app.companionshipStarted) {
      return EstadoVazio(
        icone: Icons.route_rounded,
        titulo: t.trilhaVaziaT,
        corpo: t.trilhaVaziaB,
      );
    }

    final proximo = p.proximoMarco;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espaco.margemTela,
        Espaco.md,
        Espaco.margemTela,
        Espaco.xxl,
      ),
      children: [
        Text(t.trilhaT, style: estilo(Tipo.display)),
        const SizedBox(height: Espaco.xxs),
        Text(
          t.trilhaSub,
          style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
        ),
        const SizedBox(height: Espaco.md),
        CartaoNivel(app: app),
        if (proximo != null) ...[
          const SizedBox(height: Espaco.sm),
          CartaoProximoPasso(app: app, marco: proximo),
        ],
        const SizedBox(height: Espaco.lg),
        _Caminho(app: app, progresso: p, atual: proximo),
      ],
    );
  }
}

/// O próximo passo, em destaque no topo.
///
/// A trilha é longa e rolável: sem este resumo, o usuário teria de procurar
/// onde está para descobrir o que fazer a seguir.
class CartaoProximoPasso extends StatelessWidget {
  const CartaoProximoPasso({
    super.key,
    required this.app,
    required this.marco,
  });

  final AppState app;
  final Marco marco;

  static const chave = Key('proximo-passo');

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final p = app.progresso;
    return CartaoBaru(
      key: chave,
      cor: Cores.acentoA(0.10),
      elevado: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.trilhaProximo,
            style: estilo(Tipo.rotuloPequeno, color: Cores.acentoTexto),
          ),
          const SizedBox(height: Espaco.xxs),
          Text(tituloDoMarco(app, marco), style: estilo(Tipo.subtitulo)),
          const SizedBox(height: Espaco.xs),
          Row(
            children: [
              Expanded(
                child: BarraAnimada(
                  fracao: p.fracaoDe(marco),
                  altura: 8,
                  cor: Cores.acento,
                  fundo: Cores.acentoA(0.18),
                ),
              ),
              const SizedBox(width: Espaco.xs),
              Text(
                '${p.valorDe(marco.tipo)}/${marco.alvo}',
                style: estilo(
                  Tipo.rotuloPequeno,
                  color: Cores.acentoTexto,
                  tabular: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.xs),
          Text(
            premiosDoMarco(app, marco).join(' · '),
            style: estilo(Tipo.corpoPequeno, color: Cores.acentoTexto),
          ),
        ],
      ),
    );
  }
}

/// Nível, XP e quanto falta — o cartão que a trilha e a home compartilham.
class CartaoNivel extends StatelessWidget {
  const CartaoNivel({super.key, required this.app, this.compacto = false});

  final AppState app;
  final bool compacto;

  static const chave = Key('cartao-nivel');

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final noTeto = app.nivel >= Balanco.nivelMaximo;
    return CartaoBaru(
      key: chave,
      padding: EdgeInsets.all(compacto ? Espaco.md : Espaco.lg),
      cor: Cores.primariaA(0.10),
      elevado: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.fill(t.nivelRotulo, {'n': app.nivel}),
                  style: estilo(
                    compacto ? Tipo.subtitulo : Tipo.tituloGrande,
                    color: Cores.primariaEscura,
                  ),
                ),
              ),
              ContadorAnimado(
                valor: app.xp,
                sufixo: ' ${t.xpRotulo}',
                estiloTexto: estilo(Tipo.rotulo, color: Cores.primariaEscura),
              ),
            ],
          ),
          const SizedBox(height: Espaco.xs),
          BarraAnimada(
            fracao: app.progressoNoNivel,
            altura: compacto ? 8 : 10,
            cor: Cores.primaria,
            fundo: Cores.primariaA(0.16),
          ),
          const SizedBox(height: Espaco.xs),
          Text(
            noTeto
                ? t.nivelMax
                : t.fill(t.nivelFalta, {
                    'x': app.xpParaProximoNivel,
                    'n': app.nivel + 1,
                  }),
            style: estilo(Tipo.corpoPequeno, color: Cores.primariaEscura),
          ),
          // O vínculo só aparece depois do primeiro afago: uma linha zerada
          // seria só uma coisa a mais para ler.
          if (app.afeto > 0) ...[
            const SizedBox(height: Espaco.xs),
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: Cores.acento,
                ),
                const SizedBox(width: Espaco.xxs),
                Text(
                  '${t.vinculoRotulo} · ${t.fill(t.vinculoSub, {'n': app.afeto})}',
                  style: estilo(
                    Tipo.corpoPequeno,
                    color: Cores.primariaEscura,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// O caminho: os marcos como nós de uma trilha que serpenteia.
///
/// Antes era uma lista de cartões empilhados — informação correta, leitura de
/// planilha. Um caminho com nós grandes diz de relance onde você está, o que
/// já passou e o que vem, que é o que faz alguém querer o próximo passo.
class _Caminho extends StatelessWidget {
  const _Caminho({required this.app, required this.progresso, this.atual});

  final AppState app;
  final ProgressoDaTrilha progresso;
  final Marco? atual;

  /// Distância vertical entre dois nós.
  static const passo = 104.0;
  static const diametro = 72.0;

  /// Quanto o caminho serpenteia para os lados.
  static const amplitude = 0.62;

  /// Onde o nó [i] fica, de -1 (esquerda) a 1 (direita).
  static double desvioDe(int i) => math.sin(i * 0.95) * amplitude;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final meio = c.maxWidth / 2;
        final raioUtil = (c.maxWidth - diametro) / 2 - Espaco.sm;
        Offset centro(int i) => Offset(
              meio + desvioDe(i) * raioUtil,
              passo / 2 + i * passo,
            );

        return SizedBox(
          height: trilha.length * passo,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinhaDoCaminho(
                    pontos: [
                      for (var i = 0; i < trilha.length; i++) centro(i),
                    ],
                    conquistados: [
                      for (final m in trilha) progresso.alcancou(m),
                    ],
                  ),
                ),
              ),
              // O rótulo fica do lado oposto ao desvio do nó: assim ele
              // sempre tem espaço e nunca sai do quadro.
              for (var i = 0; i < trilha.length; i++)
                _RotuloDoNo(
                  app: app,
                  marco: trilha[i],
                  progresso: progresso,
                  ehAtual: atual?.id == trilha[i].id,
                  centro: centro(i),
                  aEsquerda: desvioDe(i) > 0,
                  largura: c.maxWidth,
                ),
              for (var i = 0; i < trilha.length; i++)
                Positioned(
                  left: centro(i).dx - diametro / 2,
                  top: centro(i).dy - diametro / 2,
                  child: _No(
                    app: app,
                    marco: trilha[i],
                    progresso: progresso,
                    ehAtual: atual?.id == trilha[i].id,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// O nome do marco, ao lado do nó.
///
/// Sem ele o caminho era uma fileira de bolinhas anônimas: bonito e mudo.
/// Ninguém descobre o que falta fazer tocando em cada uma.
class _RotuloDoNo extends StatelessWidget {
  const _RotuloDoNo({
    required this.app,
    required this.marco,
    required this.progresso,
    required this.ehAtual,
    required this.centro,
    required this.aEsquerda,
    required this.largura,
  });

  final AppState app;
  final Marco marco;
  final ProgressoDaTrilha progresso;
  final bool ehAtual;
  final Offset centro;
  final bool aEsquerda;
  final double largura;

  @override
  Widget build(BuildContext context) {
    final feito = progresso.alcancou(marco);
    final larguraDoTexto =
        (aEsquerda ? centro.dx : largura - centro.dx) -
            _Caminho.diametro / 2 -
            Espaco.sm;
    if (larguraDoTexto < 60) return const SizedBox.shrink();

    final cor = feito
        ? Cores.primariaEscura
        : ehAtual
            ? Cores.acentoForte
            : Cores.tintaA(0.45);

    return Positioned(
      left: aEsquerda ? 0 : centro.dx + _Caminho.diametro / 2 + Espaco.sm,
      top: centro.dy - 30,
      width: larguraDoTexto,
      // O nome ao lado do nó abre o mesmo detalhe. Antes só o círculo de
      // 72 px respondia, e o texto ficava ali parecendo tocável sem ser.
      child: GestureDetector(
        onTap: () => abreDetalheDoMarco(context, app, marco, progresso),
        behavior: HitTestBehavior.opaque,
        child: Column(
        crossAxisAlignment:
            aEsquerda ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ehAtual) ...[
            // `FittedBox`: a etiqueta tem largura intrínseca e a coluna do
            // rótulo é estreita quando o nó cai perto da borda. Sem isto ela
            // estourava para fora do quadro — 58 px no pior caso.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  aEsquerda ? Alignment.centerRight : Alignment.centerLeft,
              child: Etiqueta(
                texto: app.t.trilhaAqui,
                cor: Cores.acento,
                forte: true,
              ),
            ),
            const SizedBox(height: Espaco.xxs),
          ],
          Text(
            tituloDoMarco(app, marco),
            textAlign: aEsquerda ? TextAlign.right : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: estilo(
              feito || ehAtual ? Tipo.corpoForte : Tipo.corpo,
              color: cor,
            ),
          ),
          if (marco.recompensa.folhas > 0)
            Text(
              app.t.fill(app.t.premioFolhas, {'n': marco.recompensa.folhas}),
              textAlign: aEsquerda ? TextAlign.right : TextAlign.left,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.45)),
              ),
          ],
        ),
      ),
    );
  }
}

/// A linha que liga os nós. O trecho já conquistado é sólido e colorido; o que
/// falta é pontilhado e apagado — dá para ver a fronteira de longe.
class _LinhaDoCaminho extends CustomPainter {
  const _LinhaDoCaminho({required this.pontos, required this.conquistados});

  final List<Offset> pontos;
  final List<bool> conquistados;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < pontos.length - 1; i++) {
      final feito = conquistados[i] && conquistados[i + 1];
      final a = pontos[i];
      final b = pontos[i + 1];
      final tinta = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = feito ? 7 : 6
        ..strokeCap = StrokeCap.round
        ..color = feito ? Cores.primaria : Cores.tintaA(0.13);

      // Curva suave em vez de reta: um caminho não tem quinas.
      final caminho = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(
          a.dx,
          a.dy + (b.dy - a.dy) * 0.55,
          b.dx,
          b.dy - (b.dy - a.dy) * 0.55,
          b.dx,
          b.dy,
        );

      if (feito) {
        canvas.drawPath(caminho, tinta);
      } else {
        _pontilha(canvas, caminho, tinta);
      }
    }
  }

  void _pontilha(Canvas canvas, Path caminho, Paint tinta) {
    const traco = 9.0;
    const vao = 9.0;
    for (final metrica in caminho.computeMetrics()) {
      var d = 0.0;
      while (d < metrica.length) {
        canvas.drawPath(
          metrica.extractPath(d, math.min(d + traco, metrica.length)),
          tinta,
        );
        d += traco + vao;
      }
    }
  }

  @override
  bool shouldRepaint(_LinhaDoCaminho old) =>
      old.pontos != pontos || old.conquistados != conquistados;
}

/// Um nó do caminho.
class _No extends StatefulWidget {
  const _No({
    required this.app,
    required this.marco,
    required this.progresso,
    required this.ehAtual,
  });

  final AppState app;
  final Marco marco;
  final ProgressoDaTrilha progresso;
  final bool ehAtual;

  @override
  State<_No> createState() => _NoState();
}

class _NoState extends State<_No> with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Só o nó atual pulsa, e só quando o sistema aceita movimento.
    if (widget.ehAtual && !Movimento.reduzido(context)) {
      if (!_pulso.isAnimating) _pulso.repeat(reverse: true);
    } else {
      _pulso
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feito = widget.progresso.alcancou(widget.marco);
    final fracao = widget.progresso.fracaoDe(widget.marco);
    // Opaco também quando bloqueado: com fundo translúcido a linha tracejada
    // atravessava o miolo do nó e parecia rabisco por cima do ícone.
    final cor = feito
        ? Cores.primaria
        : widget.ehAtual
            ? Cores.acento
            : Color.alphaBlend(Cores.tintaA(0.14), Cores.superficie);
    final corDoIcone =
        feito || widget.ehAtual ? Cores.superficie : Cores.tintaA(0.42);

    return Semantics(
      button: true,
      label: tituloDoMarco(widget.app, widget.marco),
      child: GestureDetector(
        onTap: () => _abreDetalhe(context),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _pulso,
          builder: (context, _) {
            final p = Curvas.organica.transform(_pulso.value);
            return SizedBox(
              width: _Caminho.diametro,
              height: _Caminho.diametro,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo do nó atual: o olho vai direto para ele.
                  if (widget.ehAtual)
                    Container(
                      width: _Caminho.diametro * (0.92 + p * 0.14),
                      height: _Caminho.diametro * (0.92 + p * 0.14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Cores.acentoA(0.22 - p * 0.10),
                      ),
                    ),
                  // Anel de progresso de quem ainda não chegou.
                  if (!feito && fracao > 0)
                    SizedBox(
                      width: _Caminho.diametro - 8,
                      height: _Caminho.diametro - 8,
                      child: CircularProgressIndicator(
                        value: fracao,
                        strokeWidth: 5,
                        backgroundColor: Cores.tintaA(0.10),
                        valueColor: AlwaysStoppedAnimation(
                          widget.ehAtual ? Cores.acento : Cores.primariaClara,
                        ),
                      ),
                    ),
                  Container(
                    width: _Caminho.diametro - 18,
                    height: _Caminho.diametro - 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cor,
                      boxShadow:
                          feito || widget.ehAtual ? Elevacao.cartao : null,
                    ),
                    child: Icon(
                      feito ? Icons.check_rounded : _iconeDoMarco(widget.marco.tipo),
                      size: 26,
                      color: corDoIcone,
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


  void _abreDetalhe(BuildContext context) => abreDetalheDoMarco(
        context,
        widget.app,
        widget.marco,
        widget.progresso,
      );
}

/// O detalhe de um marco. Livre porque **o nó e o rótulo ao lado abrem o
/// mesmo painel**: só o círculo de 72 px respondia, e o nome do marco logo ao
/// lado ficava lá parecendo clicável sem ser.
void abreDetalheDoMarco(
  BuildContext context,
  AppState app,
  Marco m,
  ProgressoDaTrilha progresso,
) {
  {
    final t = app.t;
    final feito = progresso.alcancou(m);
    final valor = progresso.valorDe(m.tipo);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.margemTela),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: feito ? Cores.primaria : Cores.acentoA(0.16),
                    ),
                    child: Icon(
                      feito ? Icons.check_rounded : _iconeDoMarco(m.tipo),
                      size: 22,
                      color: feito ? Cores.superficie : Cores.acentoForte,
                    ),
                  ),
                  const SizedBox(width: Espaco.sm),
                  Expanded(
                    child: Text(
                      tituloDoMarco(app, m),
                      style: estilo(Tipo.titulo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espaco.md),
              if (!feito) ...[
                BarraAnimada(
                  fracao: progresso.fracaoDe(m),
                  cor: Cores.acento,
                  fundo: Cores.acentoA(0.16),
                ),
                const SizedBox(height: Espaco.xs),
                Text(
                  // Sem espaços, igual ao cartão do topo: "4/7".
                  '$valor/${m.alvo}',
                  style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
                ),
              ] else
                Etiqueta(
                  texto: t.trilhaFeito,
                  cor: Cores.primaria,
                  icone: Icons.check_rounded,
                ),
              const SizedBox(height: Espaco.md),
              for (final premio in premiosDoMarco(app, m))
                Padding(
                  padding: const EdgeInsets.only(bottom: Espaco.xxs),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        size: 16,
                        color: Cores.acentoForte,
                      ),
                      const SizedBox(width: Espaco.xs),
                      Text(
                        premio,
                        style: estilo(Tipo.corpo, color: Cores.acentoForte),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


String tituloDoMarco(AppState app, Marco m) {
  final t = app.t;
  switch (m.tipo) {
    case TipoDeMarco.sessoes:
      return m.alvo == 1
          ? t.marcoSessao1
          : t.fill(t.marcoSessoes, {'n': m.alvo});
    case TipoDeMarco.sequencia:
      return t.fill(t.marcoSequencia, {'n': m.alvo});
    case TipoDeMarco.nivel:
      return t.fill(t.marcoNivel, {'n': m.alvo});
    case TipoDeMarco.diasAbaixoDaMeta:
      return m.alvo == 1
          ? t.marcoAbaixo1
          : t.fill(t.marcoAbaixo, {'n': m.alvo});
  }
}

List<String> premiosDoMarco(AppState app, Marco m) {
  final t = app.t;
  final out = <String>[];
  if (m.recompensa.folhas > 0) {
    out.add(t.fill(t.premioFolhas, {'n': m.recompensa.folhas}));
  }
  final especie = m.recompensa.especie;
  if (especie != null) {
    out.add(t.fill(t.premioEspecie, {'a': t.animalName(especie.name)}));
  }
  if (m.recompensa.estagioDeHabitat != null) {
    out.add(t.premioHabitat);
  }
  return out;
}

/// O ícone de cada tipo de marco.
IconData _iconeDoMarco(TipoDeMarco tipo) => switch (tipo) {
      TipoDeMarco.sessoes => Icons.self_improvement_rounded,
      TipoDeMarco.sequencia => Icons.local_fire_department_rounded,
      TipoDeMarco.nivel => Icons.trending_up_rounded,
      TipoDeMarco.diasAbaixoDaMeta => Icons.phonelink_erase_rounded,
    };
