import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/progressao.dart';
import '../l10n_trilha.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/componentes.dart';
import '../widgets/habitat.dart';

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
    garanteTextosDaTrilha();
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
        // "Passo 3 de 22" é a resposta literal à reclamação — "não faz muito
        // sentido exatamente em que momento eu tô, em que passo". Fica no
        // topo porque é a pergunta que a tela existe para responder; qualquer
        // outra informação antes dela é ruído.
        Text(
          proximo == null
              ? t.s('trilhaPassoFim')
              : t.fill(t.s('trilhaPassoDe'), {
                  'n': p.passoAtual,
                  't': p.totalDePassos,
                }),
          style: estilo(Tipo.corpoForte, color: Cores.acentoTexto),
        ),
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
        SeletorDeHabitat(app: app),
        const SizedBox(height: Espaco.lg),
        _Caminho(app: app, progresso: p),
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
          // A frase do que falta, não só a fração.
          //
          // "4/7" diz o placar; não diz o que fazer. A reclamação foi que o
          // critério "não é coerente" — e uma barra sem frase obriga o
          // usuário a adivinhar de que unidade é o número.
          Text(
            oQueFaltaNoMarco(app, marco),
            style: estilo(Tipo.corpoForte, color: Cores.acentoForte),
          ),
          const SizedBox(height: Espaco.xxs),
          Text(
            premiosDoMarco(app, marco).join(' · '),
            style: estilo(Tipo.corpoPequeno, color: Cores.acentoTexto),
          ),
        ],
      ),
    );
  }
}

/// Os habitats abertos pela trilha, para escolher de dentro dela.
///
/// O habitat não tinha relação nenhuma com a trilha, e não havia como trocar
/// de lugar sem sair da tela. Aqui os dois se encontram: o que a trilha abriu
/// fica à mão, e o que ela ainda não abriu mostra em que passo abre — que é o
/// que faz alguém querer subir.
class SeletorDeHabitat extends StatelessWidget {
  const SeletorDeHabitat({super.key, required this.app});

  final AppState app;

  static const chave = Key('seletor-de-habitat');

  @override
  Widget build(BuildContext context) {
    garanteTextosDaTrilha();
    final t = app.t;
    final ativo = app.habitatAtivo;
    final abertos = app.progresso.estagioDoHabitat;
    return Column(
      key: chave,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.s('trilhaHabitatsT'), style: estilo(Tipo.titulo)),
        const SizedBox(height: Espaco.xxs),
        Text(
          t.fill(t.s('trilhaHabitatsSub'), {'a': app.displayName}),
          style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.6)),
        ),
        const SizedBox(height: Espaco.sm),
        // Rolagem horizontal: são seis lugares e vão ser mais. Empilhados,
        // empurrariam o caminho para fora da primeira tela — e o caminho é o
        // assunto.
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: habitatsDaTrilha.length,
            separatorBuilder: (_, __) => const SizedBox(width: Espaco.xs),
            itemBuilder: (context, i) {
              final h = habitatsDaTrilha[i];
              return _CartaoDeHabitat(
                app: app,
                habitat: h,
                liberado: h.estagio <= abertos,
                emUso: h.id == ativo.id,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CartaoDeHabitat extends StatelessWidget {
  const _CartaoDeHabitat({
    required this.app,
    required this.habitat,
    required this.liberado,
    required this.emUso,
  });

  final AppState app;
  final HabitatDaTrilha habitat;
  final bool liberado;
  final bool emUso;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final nome = nomeDoHabitat(app, habitat);
    final legenda = liberado
        ? (emUso ? t.s('trilhaHabitatEmUso') : t.s('trilhaHabitatUsar'))
        : t.fill(t.s('trilhaAbreNoPasso'), {
            'n': passoQueAbreOHabitat(habitat),
          });

    return Semantics(
      button: liberado,
      selected: emUso,
      label: '$nome · $legenda',
      child: GestureDetector(
        // Travado não responde ao toque de propósito: um cartão que reage e
        // não faz nada é pior do que um que não reage.
        onTap: liberado && !emUso
            ? () => app.escolheHabitat(habitat.id)
            : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 116,
          padding: const EdgeInsets.all(Espaco.xs),
          decoration: BoxDecoration(
            color: emUso ? Cores.primariaA(0.14) : Cores.superficieElevada,
            borderRadius: Raio.todos(Raio.chip),
            border: Border.all(
              color: emUso ? Cores.primaria : Cores.tintaA(0.10),
              width: emUso ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: Raio.todos(Raio.chip - 4),
                child: Stack(
                  children: [
                    // A prévia continua colorida sob o véu: o lugar travado
                    // tem de dar vontade, não sumir.
                    MiniaturaDoHabitat(
                      habitatId: habitat.id,
                      largura: 100,
                      altura: 62,
                    ),
                    if (!liberado)
                      Positioned.fill(
                        child: Container(
                          color: Cores.tintaA(0.42),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 20,
                            color: Cores.tintaClara,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Espaco.xxs),
              Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estilo(
                  Tipo.corpoForte,
                  color: liberado ? Cores.tinta : Cores.tintaA(0.5),
                ),
              ),
              Text(
                legenda,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estilo(
                  Tipo.corpoPequeno,
                  color: emUso
                      ? Cores.primariaEscura
                      : liberado
                          ? Cores.acentoTexto
                          : Cores.tintaA(0.45),
                ),
              ),
            ],
          ),
        ),
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
  const _Caminho({required this.app, required this.progresso});

  final AppState app;

  /// A única fonte do estado de cada degrau. O caminho não recebe mais "quem
  /// é o atual" por fora: com dois lugares dizendo isso, um deles envelhece.
  final ProgressoDaTrilha progresso;

  /// Distância vertical entre dois nós.
  ///
  /// Eram 104, e cabia porque o rótulo tinha duas linhas. O degrau atual
  /// ganhou a etiqueta "você está aqui" e a frase do que falta: com quatro
  /// linhas, o rótulo alcançava o do degrau seguinte. A trilha é rolável — dar
  /// o espaço custa rolagem, e rolagem é o que o caminho pede mesmo.
  static const passo = 124.0;
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
                  estado: progresso.estadoDe(trilha[i]),
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
                    estado: progresso.estadoDe(trilha[i]),
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
    required this.estado,
    required this.centro,
    required this.aEsquerda,
    required this.largura,
  });

  final AppState app;
  final Marco marco;
  final EstadoNaTrilha estado;
  final Offset centro;
  final bool aEsquerda;
  final double largura;

  @override
  Widget build(BuildContext context) {
    final larguraDoTexto =
        (aEsquerda ? centro.dx : largura - centro.dx) -
            _Caminho.diametro / 2 -
            Espaco.sm;
    if (larguraDoTexto < 60) return const SizedBox.shrink();

    final cor = switch (estado) {
      EstadoNaTrilha.conquistado => Cores.primariaEscura,
      EstadoNaTrilha.atual => Cores.acentoForte,
      // Apagado de verdade, não meio apagado: o degrau travado tem de
      // parecer o que é — ainda não chegou a vez dele.
      EstadoNaTrilha.travado => Cores.tintaA(0.38),
    };

    return Positioned(
      left: aEsquerda ? 0 : centro.dx + _Caminho.diametro / 2 + Espaco.sm,
      top: centro.dy - 34,
      width: larguraDoTexto,
      // O nome ao lado do nó abre o mesmo detalhe. Antes só o círculo de
      // 72 px respondia, e o texto ficava ali parecendo tocável sem ser.
      child: GestureDetector(
        onTap: () => abreDetalheDoMarco(context, app, marco, app.progresso),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment:
              aEsquerda ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (estado == EstadoNaTrilha.atual) ...[
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
                estado == EstadoNaTrilha.travado
                    ? Tipo.corpo
                    : Tipo.corpoForte,
                color: cor,
              ),
            ),
            // No degrau em que a pessoa está, a linha de baixo é o que falta;
            // nos outros, o prêmio.
            //
            // **Uma linha só, não as duas.** Com as duas, o rótulo do degrau
            // atual ficava com quatro linhas e encostava no rótulo do degrau
            // seguinte — medido na captura de evidência. E o prêmio do passo
            // atual já está no cartão do topo, palavra por palavra.
            if (estado == EstadoNaTrilha.atual)
              Text(
                oQueFaltaNoMarco(app, marco),
                textAlign: aEsquerda ? TextAlign.right : TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: estilo(Tipo.corpoPequeno, color: Cores.acentoTexto),
              )
            else if (marco.recompensa.folhas > 0)
              Text(
                app.t.fill(app.t.premioFolhas, {'n': marco.recompensa.folhas}),
                textAlign: aEsquerda ? TextAlign.right : TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estilo(
                  Tipo.corpoPequeno,
                  color: estado == EstadoNaTrilha.travado
                      ? Cores.tintaA(0.34)
                      : Cores.tintaA(0.45),
                ),
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
    required this.estado,
  });

  final AppState app;
  final Marco marco;
  final ProgressoDaTrilha progresso;
  final EstadoNaTrilha estado;

  bool get ehAtual => estado == EstadoNaTrilha.atual;

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
    final estado = widget.estado;
    final feito = estado == EstadoNaTrilha.conquistado;
    final travado = estado == EstadoNaTrilha.travado;
    // **O anel de progresso só existe no degrau atual.**
    //
    // Era este o defeito: todo marco não alcançado desenhava o anel com a
    // fração dele, então quem estava no passo 3 via os passos 9, 12 e 16
    // meio cheios — "os outros níveis já estão carregando". A fração de um
    // degrau que ainda não é a vez não informa nada; ela só faz o caminho
    // inteiro parecer em curso ao mesmo tempo. O número continua vivo no
    // detalhe, que é onde alguém pergunta de propósito.
    final fracao = travado ? 0.0 : widget.progresso.fracaoDe(widget.marco);
    // Opaco também quando bloqueado: com fundo translúcido a linha tracejada
    // atravessava o miolo do nó e parecia rabisco por cima do ícone.
    final cor = feito
        ? Cores.primaria
        : widget.ehAtual
            ? Cores.acento
            : Color.alphaBlend(Cores.tintaA(0.14), Cores.superficie);
    final corDoIcone =
        feito || widget.ehAtual ? Cores.superficie : Cores.tintaA(0.42);
    final icone = switch (estado) {
      EstadoNaTrilha.conquistado => Icons.check_rounded,
      EstadoNaTrilha.atual => _iconeDoMarco(widget.marco.tipo),
      // O cadeado é o que separa "ainda não" de "quase lá". Sem ele, um nó
      // apagado com o ícone do tipo lê como degrau disponível.
      EstadoNaTrilha.travado => Icons.lock_rounded,
    };

    return Semantics(
      button: true,
      label: '${tituloDoMarco(widget.app, widget.marco)} · '
          '${_rotuloDoEstado(widget.app, estado)}',
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
                    child: Icon(icone, size: 26, color: corDoIcone),
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
    garanteTextosDaTrilha();
    final t = app.t;
    final estado = progresso.estadoDe(m);
    final feito = estado == EstadoNaTrilha.conquistado;
    final valor = progresso.valorDe(m.tipo);
    final habitat = m.recompensa.estagioDeHabitat == null
        ? null
        : habitatDoEstagio(m.recompensa.estagioDeHabitat!);

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tituloDoMarco(app, m),
                          style: estilo(Tipo.titulo),
                        ),
                        Text(
                          t.fill(t.s('trilhaPassoDe'), {
                            'n': passoDoMarco(m),
                            't': trilha.length,
                          }),
                          style: estilo(
                            Tipo.corpoPequeno,
                            color: Cores.tintaA(0.55),
                          ),
                        ),
                      ],
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
                // Aqui a fração aparece mesmo no degrau travado: quem abriu
                // o detalhe perguntou de propósito. O que não pode é o
                // caminho responder isso sozinho, sem ninguém perguntar.
                Text(
                  // Sem espaços, igual ao cartão do topo: "4/7".
                  '$valor/${m.alvo}',
                  style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
                ),
                const SizedBox(height: Espaco.xs),
                Text(
                  oQueFaltaNoMarco(app, m),
                  style: estilo(Tipo.corpoForte, color: Cores.acentoForte),
                ),
              ] else ...[
                Etiqueta(
                  texto: t.trilhaFeito,
                  cor: Cores.primaria,
                  icone: Icons.check_rounded,
                ),
                const SizedBox(height: Espaco.xs),
                Text(
                  t.s('trilhaJaSeu'),
                  style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.6)),
                ),
              ],
              const SizedBox(height: Espaco.md),
              // O habitat é o prêmio que dá para ver antes de ganhar. Uma
              // linha de texto ("O habitat cresce") não fazia ninguém querer
              // subir; a prévia do lugar faz.
              if (habitat != null) ...[
                ClipRRect(
                  borderRadius: Raio.todos(Raio.chip),
                  child: MiniaturaDoHabitat(
                    habitatId: habitat.id,
                    altura: 108,
                  ),
                ),
                const SizedBox(height: Espaco.sm),
              ],
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
                      // `Expanded`: o prêmio ganhou o nome do habitat e o da
                      // espécie, e um texto de largura intrínseca dentro de
                      // uma `Row` estoura na primeira linha comprida — 6 px
                      // em "Serra", mais em zh.
                      Expanded(
                        child: Text(
                          premio,
                          style: estilo(Tipo.corpo, color: Cores.acentoForte),
                        ),
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
  garanteTextosDaTrilha();
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
  garanteTextosDaTrilha();
  final t = app.t;
  final out = <String>[];
  if (m.recompensa.folhas > 0) {
    out.add(t.fill(t.premioFolhas, {'n': m.recompensa.folhas}));
  }
  final especie = m.recompensa.especie;
  if (especie != null) {
    out.add(t.fill(t.premioEspecie, {'a': t.animalName(especie.name)}));
  }
  final estagio = m.recompensa.estagioDeHabitat;
  if (estagio != null) {
    // "O habitat cresce" não dizia o que a pessoa ganha. O lugar tem nome, e
    // é o nome que faz querer chegar lá.
    out.add(
      t.fill(t.s('premioHabitatNome'), {
        'h': nomeDoHabitat(app, habitatDoEstagio(estagio)),
      }),
    );
  }
  return out;
}

/// O nome do lugar, no idioma da pessoa.
String nomeDoHabitat(AppState app, HabitatDaTrilha h) {
  garanteTextosDaTrilha();
  // A chave é derivada do id: `lagoa` → `habLagoa`. Uma tabela id→chave
  // seria uma segunda lista para manter em sincronia com a primeira.
  final sufixo = h.id[0].toUpperCase() + h.id.substring(1);
  return app.t.s('hab$sufixo');
}

/// O que falta para um marco, **em uma frase**.
///
/// A fração sozinha ("4/7") é um placar sem unidade: não dá para saber se
/// são sessões, dias seguidos ou dias abaixo da meta, e foi por isso que o
/// critério pareceu incoerente. A frase carrega a unidade e o número, e sai
/// do mesmo contador que o anel desenha — se um mentir, o outro mente junto.
String oQueFaltaNoMarco(AppState app, Marco m) {
  garanteTextosDaTrilha();
  final t = app.t;
  final p = app.progresso;
  if (p.alcancou(m)) return t.s('trilhaJaSeu');
  final falta = p.quantoFalta(m);
  switch (m.tipo) {
    case TipoDeMarco.sessoes:
      return falta == 1
          ? t.s('trilhaFaltaSessao1')
          : t.fill(t.s('trilhaFaltaSessoes'), {'n': falta});
    case TipoDeMarco.diasAbaixoDaMeta:
      return falta == 1
          ? t.s('trilhaFaltaAbaixo1')
          : t.fill(t.s('trilhaFaltaAbaixo'), {'n': falta});
    case TipoDeMarco.sequencia:
      return falta == 1
          ? t.s('trilhaFaltaSeguido1')
          : t.fill(t.s('trilhaFaltaSeguidos'), {'n': falta});
    case TipoDeMarco.nivel:
      // "Faltam 2 níveis" não diz o que fazer hoje. O que a pessoa junta é
      // XP, e é o XP que a barra do cartão de nível já mostra subindo.
      return t.fill(t.s('trilhaFaltaXp'), {
        'n': p.xpQueFaltaPara(m),
        'a': m.alvo,
      });
  }
}

String _rotuloDoEstado(AppState app, EstadoNaTrilha estado) {
  garanteTextosDaTrilha();
  return switch (estado) {
    EstadoNaTrilha.conquistado => app.t.trilhaFeito,
    EstadoNaTrilha.atual => app.t.trilhaAgora,
    EstadoNaTrilha.travado => app.t.s('trilhaTravado'),
  };
}

/// O ícone de cada tipo de marco.
IconData _iconeDoMarco(TipoDeMarco tipo) => switch (tipo) {
      TipoDeMarco.sessoes => Icons.self_improvement_rounded,
      TipoDeMarco.sequencia => Icons.local_fire_department_rounded,
      TipoDeMarco.nivel => Icons.trending_up_rounded,
      TipoDeMarco.diasAbaixoDaMeta => Icons.phonelink_erase_rounded,
    };
