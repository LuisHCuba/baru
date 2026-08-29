import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/missoes.dart';
import '../l10n.dart';
import '../l10n_descanso.dart';
import '../l10n_missoes.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/toca.dart';

/// Missões diárias e semanais.
///
/// **A queixa era "está confuso, não é linear".** E era: cinco cartões
/// idênticos sob dois rótulos de prazo — "HOJE" e "ESTA SEMANA" — pedem que a
/// pessoa leia os cinco, compare progressos e decida sozinha por onde
/// começar. Prazo é informação útil, mas não é hierarquia: às nove da manhã,
/// "até domingo" e "até meia-noite" não dizem qual cartão merece o dedo.
///
/// A tela agora responde três perguntas, nesta ordem, e cada uma é um bloco:
///
/// 1. **O que eu faço agora?** A missão do descanso, sozinha no topo, com o
///    botão que a começa. É a principal do dia (D-01) e até aqui não
///    aparecia em lugar nenhum — estava modelada, contabilizada, paga, e
///    invisível.
/// 2. **O que já é meu?** O que está pronto para colher, antes de tudo o
///    mais: é folha parada na mesa.
/// 3. **O que ainda dá para fechar hoje?** As diárias em andamento, da mais
///    perto para a mais longe.
///
/// Depois, e só depois, o que corre sozinho: a semana em linhas magras, os
/// convites de permissão e o que já foi colhido. Nada some da tela — o §5
/// exige a anatomia inteira visível —, mas o que exige decisão agora ocupa o
/// tamanho de uma decisão, e o resto ocupa o tamanho de um lembrete.
class MissoesScreen extends StatelessWidget {
  const MissoesScreen({super.key});

  static const rota = '/missoes';

  @override
  Widget build(BuildContext context) {
    garanteTextosDeMissoes();
    garanteTextosDoDescanso();
    final app = AppScope.of(context);
    final t = app.t;

    if (!app.companionshipStarted) {
      return EstadoVazio(
        icone: Icons.flag_outlined,
        titulo: t.missoesVaziaT,
        corpo: t.missoesVaziaB,
      );
    }

    final descanso = app.missaoDoDescanso;
    final retomada = app.missaoDeRetomada;
    final todas = [...app.missoesDiarias, ...app.missoesSemanais];

    // Um grupo por decisão, não por prazo.
    final aColher = todas.where((m) => m.resgatavel).toList();
    final agora = _porProximidade(
      todas.where(
        (m) =>
            m.estado == EstadoDaMissao.emProgresso &&
            m.ritmo == RitmoDaMissao.diaria,
      ),
    );
    final semana = todas
        .where(
          (m) =>
              m.estado == EstadoDaMissao.emProgresso &&
              m.ritmo == RitmoDaMissao.semanal,
        )
        .toList();
    final espera = todas
        .where((m) => m.estado == EstadoDaMissao.precisaPermissao)
        .toList();
    final feitas =
        todas.where((m) => m.estado == EstadoDaMissao.resgatada).toList();

    // O descanso entra na conta do "tudo feito": ele é a principal do dia,
    // e dizer "tudo feito" com a principal em aberto seria mentira.
    final tudoFeito =
        todas.where((m) => m.disponivel).every((m) => m.resgatada) &&
            (!descanso.disponivel || descanso.resgatada) &&
            (retomada == null || retomada.resgatada);

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
        const SizedBox(height: Espaco.md),
        CartaoDoDescanso(app: app),
        // Logo abaixo da principal, e acima de tudo o que é sorteado: no dia
        // em que ela existe, é o assunto do dia. Nos outros o bloco some
        // inteiro, porque `_Bloco` não desenha rótulo sobre lista vazia.
        _Bloco(
          rotulo: t.mqRetomada,
          cor: Cores.primariaEscura,
          filhos: [
            if (retomada != null) CartaoDeMissao(app: app, missao: retomada),
          ],
        ),
        // A ordem dos blocos é a hierarquia. Colher primeiro porque é o
        // único que já está pago e só espera o gesto.
        _Bloco(
          rotulo: t.mqColher,
          cor: Cores.acentoTexto,
          sufixo: aColher.isEmpty
              ? null
              : t.fill(t.mqQuantasColher, {'n': aColher.length}),
          filhos: [
            for (final m in aColher) CartaoDeMissao(app: app, missao: m),
          ],
        ),
        _Bloco(
          rotulo: t.mqAgora,
          filhos: [for (final m in agora) CartaoDeMissao(app: app, missao: m)],
        ),
        _Bloco(
          rotulo: t.mqSemana,
          filhos: [
            for (final m in semana)
              CartaoDeMissao(app: app, missao: m, compacto: true),
          ],
        ),
        _Bloco(
          rotulo: t.mqEspera,
          filhos: [for (final m in espera) CartaoDeMissao(app: app, missao: m)],
        ),
        _Bloco(
          rotulo: t.mqFeitas,
          filhos: [
            for (final m in feitas)
              CartaoDeMissao(app: app, missao: m, compacto: true),
          ],
        ),
      ],
    );
  }

  /// Da mais perto de fechar para a mais longe.
  ///
  /// "O que dá para fechar hoje" é a pergunta que a pessoa faz olhando esta
  /// lista, e uma missão a 90% responde melhor que uma a 10%. O desempate
  /// pelo id existe porque `List.sort` não é estável: sem ele, três missões
  /// em zero trocariam de lugar entre dois `build` e a lista piscaria.
  static List<Missao> _porProximidade(Iterable<Missao> ms) {
    final l = ms.toList()
      ..sort((a, b) {
        final porFracao = b.fracao.compareTo(a.fracao);
        return porFracao != 0 ? porFracao : a.id.compareTo(b.id);
      });
    return l;
  }
}

/// Um bloco da hierarquia: rótulo e cartões. Some inteiro quando vazio.
///
/// Rótulo de seção sobre lista vazia é ruído que promete conteúdo — e a
/// tela já era acusada de confusa com cinco cartões, quanto mais com cinco
/// títulos e nada embaixo de dois deles.
class _Bloco extends StatelessWidget {
  const _Bloco({
    required this.rotulo,
    required this.filhos,
    this.cor,
    this.sufixo,
  });

  final String rotulo;
  final List<Widget> filhos;
  final Color? cor;

  /// Contagem à direita do rótulo — "2 para colher".
  final String? sufixo;

  @override
  Widget build(BuildContext context) {
    if (filhos.isEmpty) return const SizedBox.shrink();
    final tinta = cor ?? Cores.tintaA(0.45);
    return Padding(
      padding: const EdgeInsets.only(top: Espaco.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: Espaco.xxs,
              bottom: Espaco.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rotulo,
                    style: estilo(Tipo.rotuloPequeno, color: tinta),
                  ),
                ),
                if (sufixo != null)
                  Text(
                    sufixo!,
                    style: estilo(Tipo.rotuloPequeno, color: tinta),
                  ),
              ],
            ),
          ),
          for (final f in filhos)
            Padding(
              padding: const EdgeInsets.only(bottom: Espaco.xs),
              child: f,
            ),
        ],
      ),
    );
  }
}

/// A missão do descanso, no lugar que ela merece.
///
/// **Por que um cartão próprio e não mais um da lista.** Ela é fixa (não
/// depende do sorteio da ADR-010), é a única que se começa e se abandona em
/// vez de só acontecer, e é a única cujo estado muda enquanto a tela está
/// aberta. Enfiá-la na mesma fileira das sorteadas foi o que este turno veio
/// desfazer: até agora ela simplesmente não aparecia, e a missão principal do
/// dia existia só no código.
class CartaoDoDescanso extends StatelessWidget {
  const CartaoDoDescanso({super.key, required this.app});

  final AppState app;

  static const chave = Key('missao-descanso');
  static const chaveDoComecar = Key('descanso-comecar');
  static const chaveDoParar = Key('descanso-parar');
  static const chaveDoColher = Key('descanso-colher');

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final m = app.missaoDoDescanso;
    final estado = m.estado;
    final semPermissao = estado == EstadoDaMissao.precisaPermissao;

    return CartaoBaru(
      key: chave,
      padding: const EdgeInsets.all(Espaco.lg),
      cor: semPermissao ? Cores.tintaA(0.04) : Cores.superficieElevada,
      elevado: !semPermissao,
      // Sem permissão o cartão inteiro vira o convite; com permissão, quem
      // age é o botão. Cartão tocável **e** botão dentro dele disputariam o
      // mesmo dedo e um dos dois perderia.
      onTap: semPermissao ? () => app.go(AppScreen.tempo) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `Wrap` e não `Row`: nem a etiqueta nem a recompensa são texto que
          // se possa cortar pela metade — "A PRINCIPAL DE HOJE" cortada vira
          // outra frase, e "30" cortado vira mentira sobre o prêmio. Quando
          // as duas não couberem na mesma linha (fonte maior, chinês, tela
          // estreita) elas descem, em vez de estourar a largura.
          //
          // O `SizedBox` de largura infinita existe porque `Wrap` encolhe
          // para o conteúdo, e `spaceBetween` sem sobra não separa nada.
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Espaco.xs,
              runSpacing: Espaco.xs,
              children: [
                Etiqueta(
                  texto: t.mqPrincipal,
                  cor: Cores.acento,
                  forte: !semPermissao,
                  icone: Icons.bedtime_rounded,
                ),
                _Recompensa(
                  folhas: m.folhas,
                  xp: m.xp,
                  apagada: estado == EstadoDaMissao.resgatada,
                ),
              ],
            ),
          ),
          const SizedBox(height: Espaco.sm),
          // O título ocupa a linha inteira: é a manchete do cartão, e
          // dividi-la com a recompensa quebrava "Descanse 40 minutos
          // seguidos" em três linhas de duas palavras.
          Text(
            tituloDoDescanso(t, m),
            style: estilo(
              Tipo.titulo,
              color: semPermissao ? Cores.tintaA(0.6) : Cores.tinta,
            ),
          ),
          const SizedBox(height: 2),
          // Uma frase só, e é ela que carrega a perda (D-02): quanto correu,
          // quanto se perdeu na fuga, e o melhor do dia guardado.
          Text(
            recadoDoDescanso(t, m),
            style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.55)),
          ),
          const SizedBox(height: Espaco.sm),
          Row(
            children: [
              Expanded(
                child: BarraAnimada(
                  fracao: m.fracao,
                  altura: 10,
                  cor: m.concluida ? Cores.acento : Cores.primaria,
                ),
              ),
              const SizedBox(width: Espaco.xs),
              Text(
                '${m.progresso}/${m.alvo}',
                style: estilo(
                  Tipo.rotuloPequeno,
                  color: Cores.tintaA(0.55),
                  tabular: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.sm),
          _acao(context, t, m),
        ],
      ),
    );
  }

  Widget _acao(BuildContext context, T t, MissaoDoDescanso m) {
    if (m.estado == EstadoDaMissao.precisaPermissao) {
      return Row(
        children: [
          const Icon(Icons.lock_clock_outlined, size: 17, color: Cores.acento),
          const SizedBox(width: Espaco.xs),
          Expanded(
            child: Text(
              t.missaoPrecisaPermissao,
              style: estilo(Tipo.rotuloPequeno, color: Cores.acentoTexto),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Cores.acento,
          ),
        ],
      );
    }
    if (m.estado == EstadoDaMissao.resgatada) {
      return Etiqueta(
        texto: t.missaoResgatada,
        cor: Cores.primaria,
        icone: Icons.check_rounded,
      );
    }
    if (m.resgatavel) {
      return PrimaryButton(
        key: chaveDoColher,
        label: t.missaoResgatar,
        height: 46,
        onTap: () => abreATocaDoDescanso(context, app),
      );
    }
    if (m.correndo) {
      // Enquanto corre não há botão verde: o que a tela pede é que a pessoa
      // saia dela. O único caminho oferecido é a saída honesta — desistir —,
      // e ela é fantasma para não competir com continuar descansando.
      return GhostButton(
        key: chaveDoParar,
        label: t.mqDescansoParar,
        height: 46,
        icon: Icons.stop_circle_outlined,
        onTap: app.desisteDoDescanso,
      );
    }
    return PrimaryButton(
      key: chaveDoComecar,
      label: t.descansoComecar,
      height: 46,
      onTap: app.comecaODescanso,
    );
  }
}

/// A anatomia do §5, toda no cartão: título em linguagem de ação, progresso
/// numérico e em barra, recompensa exata com o ícone da moeda, prazo e estado.
class CartaoDeMissao extends StatelessWidget {
  const CartaoDeMissao({
    super.key,
    required this.app,
    required this.missao,
    this.compacto = false,
  });

  final AppState app;
  final Missao missao;

  /// Versão magra: sem o "como" e sem o rodapé.
  ///
  /// É o que separa "o que exige decisão agora" de "o que corre sozinho". A
  /// semanal em andamento não precisa explicar onde se faz uma sessão pela
  /// terceira vez na mesma tela, e a já colhida não precisa explicar nada.
  final bool compacto;

  static Key chaveDe(String id) => Key('missao-$id');

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final estado = missao.estado;
    final cor = _cor(estado);
    final apagada = estado == EstadoDaMissao.resgatada;

    return CartaoBaru(
      key: chaveDe(missao.id),
      padding: EdgeInsets.all(compacto ? Espaco.sm : Espaco.md),
      cor: estado == EstadoDaMissao.emProgresso || missao.resgatavel
          ? Cores.superficieElevada
          : Cores.tintaA(0.04),
      elevado: missao.resgatavel || estado == EstadoDaMissao.emProgresso,
      // Resgatar quando há o que resgatar; senão, levar ao lugar de fazer.
      // Missão que só se lê é lembrete — e a queixa era justamente não
      // saber o que fazer.
      onTap: missao.resgatavel
          ? () => abreATocaDe(context, app, missao)
          : apagada
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
              if (estado == EstadoDaMissao.precisaPermissao) ...[
                const Icon(
                  Icons.lock_clock_outlined,
                  size: 18,
                  color: Cores.acento,
                ),
                const SizedBox(width: Espaco.xs),
              ],
              Expanded(
                child: Text(
                  tituloDaMissao(app, missao),
                  style: estilo(
                    compacto ? Tipo.corpoPequeno : Tipo.corpoForte,
                    color: apagada ||
                            estado == EstadoDaMissao.precisaPermissao
                        ? Cores.tintaA(0.5)
                        : Cores.tinta,
                    weight: compacto ? FontWeight.w700 : null,
                  ),
                ),
              ),
              const SizedBox(width: Espaco.xs),
              _Recompensa(
                folhas: missao.folhas,
                xp: missao.xp,
                apagada: apagada,
              ),
            ],
          ),
          if (!compacto) ...[
            const SizedBox(height: 2),
            // O "como" fica **também** no cartão que espera permissão. Ele
            // some do estado "resgatada" e de mais nenhum: quem ainda não
            // concedeu o acesso é justamente quem menos sabe o que a missão
            // pede, e esconder a explicação dela era deixar o convite mudo.
            if (!apagada)
              Text(
                comoDaMissao(app, missao),
                style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.5)),
              ),
          ],
          SizedBox(height: compacto ? Espaco.xs : Espaco.xs),
          Row(
            children: [
              Expanded(
                child: BarraAnimada(
                  fracao: missao.fracao,
                  altura: compacto ? 6 : 8,
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
          if (!compacto) ...[
            const SizedBox(height: Espaco.xs),
            Row(
              children: [
                // Em andamento não recebe etiqueta: a barra e o "x/y" já
                // dizem onde a missão está, e chamar de "concluída" o que
                // não está seria a mesma mentira que este turno veio
                // consertar.
                if (missao.resgatavel)
                  Etiqueta(
                    texto: t.missaoResgatar,
                    cor: Cores.acento,
                    forte: true,
                    icone: Icons.redeem_rounded,
                  )
                else if (estado == EstadoDaMissao.precisaPermissao)
                  // Texto e não etiqueta: "Precisa do acesso ao uso" é uma
                  // frase, e dentro de uma pílula ela estourava a largura ao
                  // lado do prazo num aparelho de 412dp. Frase que não cabe
                  // não vira pílula menor, vira frase cortada.
                  Flexible(
                    child: Text(
                      t.missaoPrecisaPermissao,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estilo(
                        Tipo.rotuloPequeno,
                        color: Cores.acentoTexto,
                      ),
                    ),
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
  const _Recompensa({
    required this.folhas,
    required this.xp,
    required this.apagada,
  });

  final int folhas;
  final int xp;
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
          '$folhas',
          style: estilo(Tipo.rotulo, color: cor, tabular: true)
              .copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: Espaco.xs),
        Text(
          '+$xp XP',
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
) =>
    _abreAToca(
      context,
      app,
      folhas: missao.folhas,
      aoAbrir: () => app.resgataMissao(missao),
    );

/// A mesma toca, para a missão do descanso.
///
/// **Mesma cena, e não um botão "Resgatar" para esta.** R-04 é explícito: a
/// cena serve missão, marco e nível. A principal do dia seria a última que
/// poderia pagar por um caminho mais pobre — seria justamente a recompensa
/// mais importante chegando do jeito que menos se sente.
Future<void> abreATocaDoDescanso(BuildContext context, AppState app) => _abreAToca(
      context,
      app,
      folhas: app.missaoDoDescanso.folhas,
      aoAbrir: app.resgataODescanso,
    );

Future<void> _abreAToca(
  BuildContext context,
  AppState app, {
  required int folhas,
  required VoidCallback aoAbrir,
}) {
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
              rotuloDoPremio: t.fill(t.missaoGanhou, {'n': folhas}),
              aoAbrir: () {
                aoAbrir();
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
  garanteTextosDeMissoes();
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
    case TipoDeMissao.focoAcimaDoDispersivo:
      return t.comoFocoGanha;
    case TipoDeMissao.diaCompleto:
      return t.comoDiaCompleto;
    case TipoDeMissao.descansoNaSemana:
      return t.comoSemanaDescanso;
    case TipoDeMissao.focoProfundoNaSemana:
      return t.comoSemanaProfundo;
    case TipoDeMissao.carinhoHoje:
      return t.comoCarinho;
    case TipoDeMissao.faixasDeFocoHoje:
      return t.comoFaixas;
    case TipoDeMissao.minutosProdutivos:
      return t.comoProdutivo;
    case TipoDeMissao.fatiaDoDispersivo:
      return t.comoFatia;
    case TipoDeMissao.retomadaHoje:
      return t.comoRetomada;
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
  // Missão travada em permissão leva à tela do tempo, qualquer que seja o
  // tipo: é lá que a permissão se concede, com a explicação do que ela
  // compra. Mandar direto para os ajustes do Android — que era o que este
  // cartão fazia — atira a pessoa para fora do app na frente de um
  // interruptor sem contexto, e ela volta sem ter concedido.
  if (!m.disponivel) return AppScreen.tempo;
  switch (m.definicao.tipo) {
    case TipoDeMissao.abaixoDaMeta:
    case TipoDeMissao.dispersivoAbaixoDe:
    case TipoDeMissao.diasAbaixoNaSemana:
    case TipoDeMissao.focoAcimaDoDispersivo:
    case TipoDeMissao.minutosProdutivos:
    case TipoDeMissao.fatiaDoDispersivo:
      return AppScreen.tempo;
    case TipoDeMissao.sessoesHoje:
    case TipoDeMissao.sessaoLonga:
    case TipoDeMissao.minutosHoje:
    case TipoDeMissao.sessoesNaSemana:
    case TipoDeMissao.minutosNaSemana:
    case TipoDeMissao.diaCompleto:
    case TipoDeMissao.descansoNaSemana:
    case TipoDeMissao.focoProfundoNaSemana:
    case TipoDeMissao.faixasDeFocoHoje:
    case TipoDeMissao.retomadaHoje:
    // O carinho se faz na home, em cima do bicho: é o único destino do
    // quadro que não é uma tela de número.
    case TipoDeMissao.carinhoHoje:
      return AppScreen.home;
  }
}

/// Título em linguagem de ação, montado do tipo e do alvo.
String tituloDaMissao(AppState app, Missao m) {
  garanteTextosDeMissoes();
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
    case TipoDeMissao.focoAcimaDoDispersivo:
      return t.msFocoGanha;
    case TipoDeMissao.diaCompleto:
      return t.msDiaCompleto;
    case TipoDeMissao.descansoNaSemana:
      return t.fill(t.msSemanaDescanso, {'n': m.alvo});
    case TipoDeMissao.focoProfundoNaSemana:
      return t.fill(t.msSemanaProfundo, {'n': m.alvo});
    case TipoDeMissao.carinhoHoje:
      // O nome do bicho no título: "faça carinho em Nina" é uma frase sobre
      // alguém, "faça 3 carinhos" é uma tarefa sobre um contador.
      return t.fill(t.msCarinho, {'n': m.alvo, 'p': app.displayName});
    case TipoDeMissao.faixasDeFocoHoje:
      return t.fill(t.msFaixas, {'n': m.alvo});
    case TipoDeMissao.minutosProdutivos:
      return t.fill(t.msProdutivo, {'n': m.alvo});
    case TipoDeMissao.fatiaDoDispersivo:
      return t.msFatia;
    case TipoDeMissao.retomadaHoje:
      return t.msRetomada;
    case TipoDeMissao.sessoesNaSemana:
      return t.fill(t.msSemanaSessoes, {'n': m.alvo});
    case TipoDeMissao.minutosNaSemana:
      return t.fill(t.msSemanaMinutos, {'n': m.alvo});
    case TipoDeMissao.diasAbaixoNaSemana:
      return t.fill(t.msSemanaAbaixo, {'n': m.alvo});
  }
}
