import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/missoes.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/toca.dart';

/// Missões diárias e semanais.
///
/// Antes eram duas linhas de texto com "+10" e "+15" ao lado e um visto
/// binário — sem progresso numérico, sem prazo, sem resgate e sem nada
/// creditando. O §5 pede a anatomia inteira visível no cartão, sem abrir nada.
class MissoesScreen extends StatelessWidget {
  const MissoesScreen({super.key});

  static const rota = '/missoes';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;

    if (!app.companionshipStarted) {
      return EstadoVazio(
        icone: Icons.flag_outlined,
        titulo: t.missoesVaziaT,
        corpo: t.missoesVaziaB,
      );
    }

    final diarias = app.missoesDiarias;
    final semanais = app.missoesSemanais;
    final tudoFeito = [...diarias, ...semanais]
        .where((m) => m.disponivel)
        .every((m) => m.resgatada);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espaco.margemTela,
        Espaco.md,
        Espaco.margemTela,
        Espaco.xxl,
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text(t.missoesT, style: estilo(Tipo.display))),
            LeafBadge(leaves: app.leaves),
          ],
        ),
        const SizedBox(height: Espaco.xxs),
        Text(
          t.missoesSub,
          style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
        ),
        if (tudoFeito) ...[
          const SizedBox(height: Espaco.sm),
          // Estado "vazio" nunca fica vazio: aponta a próxima ação útil.
          CartaoBaru(
            cor: Cores.primariaA(0.10),
            elevado: false,
            onTap: () => app.go(AppScreen.trilha),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Cores.primaria,
                ),
                const SizedBox(width: Espaco.sm),
                Expanded(
                  child: Text(
                    t.missoesTodasFeitas,
                    style: estilo(
                      Tipo.corpoPequeno,
                      color: Cores.primariaEscura,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Cores.primaria,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Espaco.lg),
        _Secao(rotulo: t.missoesDiarias, missoes: diarias, app: app),
        const SizedBox(height: Espaco.lg),
        _Secao(rotulo: t.missoesSemanais, missoes: semanais, app: app),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({
    required this.rotulo,
    required this.missoes,
    required this.app,
  });

  final String rotulo;
  final List<Missao> missoes;
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Espaco.xxs, bottom: Espaco.xs),
          child: Text(
            rotulo,
            style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
          ),
        ),
        for (final m in missoes)
          Padding(
            padding: const EdgeInsets.only(bottom: Espaco.xs),
            child: CartaoDeMissao(app: app, missao: m),
          ),
      ],
    );
  }
}

/// A anatomia do §5, toda no cartão: título em linguagem de ação, progresso
/// numérico e em barra, recompensa exata com o ícone da moeda, prazo e estado.
class CartaoDeMissao extends StatelessWidget {
  const CartaoDeMissao({super.key, required this.app, required this.missao});

  final AppState app;
  final Missao missao;

  static Key chaveDe(String id) => Key('missao-$id');

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final estado = missao.estado;
    final cor = _cor(estado);

    // Missão impossível não é mostrada como missão: vira convite para
    // conceder a permissão que falta.
    if (estado == EstadoDaMissao.precisaPermissao) {
      return CartaoBaru(
        key: chaveDe(missao.id),
        padding: const EdgeInsets.all(Espaco.md),
        cor: Cores.tintaA(0.04),
        elevado: false,
        onTap: app.requestUsageAccessFromSettings,
        child: Row(
          children: [
            Icon(Icons.lock_clock_outlined, size: 19, color: Cores.acento),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tituloDaMissao(app, missao),
                    style: estilo(Tipo.corpoForte, color: Cores.tintaA(0.6)),
                  ),
                  const SizedBox(height: Espaco.xxs),
                  Text(
                    t.missaoPrecisaPermissao,
                    style: estilo(Tipo.rotuloPequeno, color: Cores.acentoTexto),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Cores.acento,
            ),
          ],
        ),
      );
    }

    return CartaoBaru(
      key: chaveDe(missao.id),
      padding: const EdgeInsets.all(Espaco.md),
      cor: estado == EstadoDaMissao.resgatada
          ? Cores.tintaA(0.04)
          : Cores.superficieElevada,
      elevado: estado != EstadoDaMissao.resgatada,
      // Resgatar quando há o que resgatar; senão, levar ao lugar de fazer.
      // Missão que só se lê é lembrete — e a queixa era justamente não
      // saber o que fazer.
      onTap: missao.resgatavel
          ? () => abreATocaDe(context, app, missao)
          : estado == EstadoDaMissao.resgatada
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  app.go(destinoDaMissao(missao));
                },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tituloDaMissao(app, missao),
                  style: estilo(
                    Tipo.corpoForte,
                    color: estado == EstadoDaMissao.resgatada
                        ? Cores.tintaA(0.5)
                        : Cores.tinta,
                  ),
                ),
              ),
              const SizedBox(width: Espaco.xs),
              _Recompensa(missao: missao, apagada: estado == EstadoDaMissao.resgatada),
            ],
          ),
          if (estado != EstadoDaMissao.resgatada) ...[
            const SizedBox(height: 2),
            Text(
              comoDaMissao(app, missao),
              style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.5)),
            ),
          ],
          const SizedBox(height: Espaco.xs),
          Row(
            children: [
              Expanded(
                child: BarraAnimada(
                  fracao: missao.fracao,
                  altura: 8,
                  cor: cor,
                ),
              ),
              const SizedBox(width: Espaco.xs),
              Text(
                '${missao.progresso.clamp(0, missao.alvo)}/${missao.alvo}',
                style: estilo(
                  Tipo.rotuloPequeno,
                  color: Cores.tintaA(0.55),
                  tabular: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.xs),
          Row(
            children: [
              // Em andamento não recebe etiqueta: a barra e o "x/y" já dizem
              // onde a missão está, e chamar de "concluída" o que não está
              // seria a mesma mentira que este turno veio consertar.
              if (missao.resgatavel)
                Etiqueta(
                  texto: t.missaoResgatar,
                  cor: Cores.acento,
                  forte: true,
                  icone: Icons.redeem_rounded,
                )
              else if (estado == EstadoDaMissao.resgatada)
                Etiqueta(
                  texto: t.missaoResgatada,
                  cor: cor,
                  icone: Icons.check_rounded,
                ),
              const Spacer(),
              Text(
                missao.ritmo == RitmoDaMissao.diaria
                    ? t.missaoExpiraHoje
                    : t.missaoExpiraSemana,
                style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _cor(EstadoDaMissao e) {
    switch (e) {
      case EstadoDaMissao.resgatada:
        return Cores.tintaA(0.3);
      case EstadoDaMissao.concluida:
        return Cores.acento;
      case EstadoDaMissao.emProgresso:
        return Cores.primaria;
      case EstadoDaMissao.precisaPermissao:
        return Cores.acento;
    }
  }
}

/// A recompensa exata, com o ícone da moeda — nunca só um número solto.
class _Recompensa extends StatelessWidget {
  const _Recompensa({required this.missao, required this.apagada});

  final Missao missao;
  final bool apagada;

  @override
  Widget build(BuildContext context) {
    final cor = apagada ? Cores.tintaA(0.35) : Cores.acentoTexto;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LeafMark(size: 12, color: cor),
        const SizedBox(width: Espaco.xxs),
        Text(
          '${missao.folhas}',
          style: estilo(Tipo.rotulo, color: cor, tabular: true)
              .copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: Espaco.xs),
        Text(
          '+${missao.xp} XP',
          style: estilo(Tipo.rotuloPequeno, color: cor.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

/// Abre a toca da missão.
///
/// Resgatar era um toque e um número que mudava. Recompensa que chega
/// sozinha não é sentida — é o gesto que transforma "ganhei" em "eu tirei
/// dali". A folha só fecha depois de a terra abrir, e o crédito acontece
/// ali, não no toque.
Future<void> abreATocaDe(
  BuildContext context,
  AppState app,
  Missao missao,
) {
  final t = app.t;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Cores.superficie,
    // Sem arrastar para fechar: a pessoa está cavando, e um arrasto para
    // baixo derrubaria a folha no meio do gesto.
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
    ),
    builder: (folha) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.tocaTitulo, style: estilo(Tipo.titulo)),
            const SizedBox(height: Espaco.xxs),
            Text(
              t.tocaAjuda,
              textAlign: TextAlign.center,
              style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
            ),
            const SizedBox(height: Espaco.sm),
            Toca(
              rotuloDoPremio: t.fill(t.missaoGanhou, {'n': missao.folhas}),
              aoAbrir: () {
                app.resgataMissao(missao);
                // Um respiro para a cena ser vista antes de a folha sair.
                Future.delayed(const Duration(milliseconds: 900), () {
                  if (folha.mounted) Navigator.of(folha).pop();
                });
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// O "como" da missão: o que fazer, e onde.
///
/// O título diz o alvo — "Faça 2 sessões de foco" —, mas quem abre a tela
/// pela primeira vez não sabe onde se faz uma sessão. Sem esta linha a
/// missão vira placar, não tarefa.
String comoDaMissao(AppState app, Missao m) {
  final t = app.t;
  switch (m.definicao.tipo) {
    // Uma frase por tipo, e não a mesma três vezes: três cartões de foco
    // repetindo o mesmo texto viram ruído, e a linha lê como enchimento.
    case TipoDeMissao.sessoesHoje:
      return t.comoFoco;
    case TipoDeMissao.sessaoLonga:
      return t.comoFocoLongo;
    case TipoDeMissao.minutosHoje:
      return t.comoMinutos;
    case TipoDeMissao.abaixoDaMeta:
      return t.comoTela;
    case TipoDeMissao.dispersivoAbaixoDe:
      return t.comoApps;
    case TipoDeMissao.sessoesNaSemana:
    case TipoDeMissao.minutosNaSemana:
    case TipoDeMissao.diasAbaixoNaSemana:
      return t.comoSemana;
  }
}

/// Para onde o cartão leva quando ainda há o que fazer.
///
/// Missão que só se lê é lembrete; missão que se toca e leva ao lugar de
/// fazer é tarefa.
AppScreen destinoDaMissao(Missao m) {
  switch (m.definicao.tipo) {
    case TipoDeMissao.abaixoDaMeta:
    case TipoDeMissao.dispersivoAbaixoDe:
    case TipoDeMissao.diasAbaixoNaSemana:
      return AppScreen.tempo;
    case TipoDeMissao.sessoesHoje:
    case TipoDeMissao.sessaoLonga:
    case TipoDeMissao.minutosHoje:
    case TipoDeMissao.sessoesNaSemana:
    case TipoDeMissao.minutosNaSemana:
      return AppScreen.home;
  }
}

/// Título em linguagem de ação, montado do tipo e do alvo.
String tituloDaMissao(AppState app, Missao m) {
  final t = app.t;
  switch (m.definicao.tipo) {
    case TipoDeMissao.sessoesHoje:
      return m.alvo == 1 ? t.msSessoes1 : t.fill(t.msSessoes, {'n': m.alvo});
    case TipoDeMissao.minutosHoje:
      return t.fill(t.msMinutos, {'n': m.alvo});
    case TipoDeMissao.sessaoLonga:
      return t.fill(t.msSessaoLonga, {'n': m.alvo});
    case TipoDeMissao.abaixoDaMeta:
      return t.msAbaixo;
    case TipoDeMissao.dispersivoAbaixoDe:
      return t.fill(t.msDispersivo, {'n': m.alvo});
    case TipoDeMissao.sessoesNaSemana:
      return t.fill(t.msSemanaSessoes, {'n': m.alvo});
    case TipoDeMissao.minutosNaSemana:
      return t.fill(t.msSemanaMinutos, {'n': m.alvo});
    case TipoDeMissao.diasAbaixoNaSemana:
      return t.fill(t.msSemanaAbaixo, {'n': m.alvo});
  }
}
