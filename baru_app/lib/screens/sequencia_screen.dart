import 'package:flutter/material.dart';

import '../data/progressao.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../share/habitat_share.dart';
import '../widgets/cartao_da_raiz.dart';
import '../widgets/raiz.dart';
import '../widgets/common.dart';

/// Sua sequência.
///
/// A home mostrava "N dias seguidos" em dois lugares e nenhum deles levava a
/// nada. O app guarda mais do que isso — a melhor sequência já feita, quantos
/// congelamentos sobram, quantos dias fecharam abaixo da meta — e nada disso
/// aparecia em lugar nenhum.
class SequenciaScreen extends StatelessWidget {
  const SequenciaScreen({super.key});

  static const chaveAtual = Key('sequencia-atual');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final proximo = _proximoMarcoDeSequencia(app);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(
          titulo: t.seqT,
          subtitulo: t.seqSub,
          aoVoltar: app.voltar,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.sm,
              Espaco.margemTela,
              Espaco.xxl,
            ),
            children: [
              _Chama(app: app),
              const SizedBox(height: Espaco.xs),
              // Compartilhar mora aqui e não no cabeçalho: a pessoa quer
              // mostrar **depois** de ver o que construiu, e um botão no
              // topo pede antes de haver motivo.
              _BotaoDeCompartilhar(app: app),
              const SizedBox(height: Espaco.md),
              CartaoBaru(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.seqSemana,
                      style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
                    ),
                    const SizedBox(height: Espaco.md),
                    Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: Column(
                              children: [
                                _Ponto(tipo: app.week[i]),
                                const SizedBox(height: Espaco.xs),
                                Text(
                                  t.days[i],
                                  style: estilo(
                                    Tipo.corpoPequeno,
                                    color: Cores.tintaA(0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (proximo != null) ...[
                const SizedBox(height: Espaco.md),
                CartaoBaru(
                  cor: Cores.acentoA(0.10),
                  elevado: false,
                  onTap: () => app.go(AppScreen.trilha),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        size: 18,
                        color: Cores.acentoForte,
                      ),
                      const SizedBox(width: Espaco.sm),
                      Expanded(
                        child: Text(
                          t.fill(t.seqProximo, {
                            'x': proximo.alvo - app.streak,
                            'm': t.fill(t.marcoSequencia, {'n': proximo.alvo}),
                          }),
                          style: estilo(
                            Tipo.corpo,
                            color: Cores.acentoForte,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Cores.acentoForte,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Espaco.md),
              CartaoBaru(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinhaDeValor(
                      icone: Icons.emoji_events_rounded,
                      rotulo: t.seqMelhor,
                      valor: '${app.melhorSequencia}',
                    ),
                    LinhaDeValor(
                      icone: Icons.ac_unit_rounded,
                      rotulo: t.seqCongelamentos,
                      detalhe: t.seqCongelamentoAjuda,
                      valor: '${app.freezesLeft}',
                    ),
                    LinhaDeValor(
                      icone: Icons.self_improvement_rounded,
                      rotulo: t.seqSessoes,
                      valor: '${app.sessoesConcluidas}',
                    ),
                    LinhaDeValor(
                      icone: Icons.trending_down_rounded,
                      rotulo: t.seqDiasAbaixo,
                      valor: '${app.diasAbaixoDaMeta}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// O primeiro marco de sequência que ainda não foi alcançado.
  Marco? _proximoMarcoDeSequencia(AppState app) {
    for (final m in trilha) {
      if (m.tipo != TipoDeMarco.sequencia) continue;
      if (app.streak < m.alvo) return m;
    }
    return null;
  }
}

class _Chama extends StatelessWidget {
  const _Chama({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final zerada = app.streak == 0;
    return CartaoBaru(
      key: SequenciaScreen.chaveAtual,
      cor: Cores.acentoA(0.12),
      elevado: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.seqAtual,
            style: estilo(Tipo.rotuloPequeno, color: Cores.acentoForte),
          ),
          const SizedBox(height: Espaco.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // A raiz desenhada, não um ícone de fogo.
              //
              // "12 dias" é um placar, e placar se perde sem doer. Uma raiz
              // que a pessoa viu engrossar ao longo de doze dias é uma
              // coisa que ela construiu — e ninguém joga fora o que
              // construiu. A chama, além disso, é vocabulário de outro app.
              SizedBox(
                width: 74,
                height: 96,
                child: RaizViva(
                  dias: app.streak,
                  cor: Cores.acentoForte,
                  corDaTerra: Cores.acentoA(0.10),
                ),
              ),
              const SizedBox(width: Espaco.sm),
              ContadorAnimado(
                valor: app.streak,
                estiloTexto: estilo(
                  Tipo.display,
                  color: Cores.acentoForte,
                  tabular: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.xs),
          Text(
            zerada ? t.seqVaziaB : app.streakText,
            style: estilo(Tipo.corpo, color: Cores.acentoForte),
          ),
        ],
      ),
    );
  }
}

class _Ponto extends StatelessWidget {
  const _Ponto({required this.tipo});

  final WeekDayKind tipo;

  @override
  Widget build(BuildContext context) {
    final (cor, icone) = switch (tipo) {
      WeekDayKind.present => (Cores.primaria, Icons.check_rounded),
      WeekDayKind.frozen => (Cores.neutro, Icons.ac_unit_rounded),
      WeekDayKind.today => (Cores.acento, null),
      WeekDayKind.empty => (Cores.tintaA(0.12), null),
    };
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: tipo == WeekDayKind.today ? null : cor,
        shape: BoxShape.circle,
        border: tipo == WeekDayKind.today
            ? Border.all(color: cor, width: 2.4)
            : null,
      ),
      child: icone == null
          ? null
          : Icon(icone, size: 15, color: Cores.superficie),
    );
  }
}


/// Compartilhar a raiz.
///
/// Gera um cartão próprio em vez de capturar a tela: print leva junto barra
/// de status, hora e bateria, e o que a pessoa quer mostrar é o que ela
/// construiu. O cartão é montado fora da tela, num `Offstage`, porque ele
/// tem proporção de retrato e apareceria deformado no meio da lista.
class _BotaoDeCompartilhar extends StatefulWidget {
  const _BotaoDeCompartilhar({required this.app});

  final AppState app;

  @override
  State<_BotaoDeCompartilhar> createState() => _BotaoDeCompartilharState();
}

class _BotaoDeCompartilharState extends State<_BotaoDeCompartilhar> {
  final _borda = GlobalKey();
  bool _ocupado = false;

  Future<void> _compartilha() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final t = widget.app.t;
    final ok = await HabitatShare.share(
      boundaryKey: _borda,
      text: t.fill(t.raizCartaoRodape, {'a': widget.app.displayName}),
    );
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.shareFail)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    if (app.streak <= 0) {
      // Raiz que ainda não existe não se mostra. Oferecer o botão no dia
      // zero seria convidar a pessoa a exibir um número que ela ainda não
      // tem.
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        // Fora da tela, mas montado: `RepaintBoundary` só rasteriza o que
        // foi realmente desenhado, e `Visibility(visible: false)` não
        // desenha.
        Positioned(
          left: -CartaoDaRaiz.largura * 2,
          child: CartaoDaRaiz(
            dias: app.streak,
            nomeDoPet: app.displayName,
            lang: app.lang,
          ),
        ),
        TextAction(
          key: const Key('raiz-compartilhar'),
          label: _ocupado ? app.t.authLoading : app.t.raizCompartilhar,
          onTap: _compartilha,
        ),
      ],
    );
  }
}
