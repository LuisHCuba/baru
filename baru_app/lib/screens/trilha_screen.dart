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
        for (var i = 0; i < trilha.length; i++)
          _Degrau(
            app: app,
            marco: trilha[i],
            progresso: p,
            primeiro: i == 0,
            ultimo: i == trilha.length - 1,
            atual: proximo?.id == trilha[i].id,
          ),
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
        ],
      ),
    );
  }
}

class _Degrau extends StatelessWidget {
  const _Degrau({
    required this.app,
    required this.marco,
    required this.progresso,
    required this.primeiro,
    required this.ultimo,
    required this.atual,
  });

  final AppState app;
  final Marco marco;
  final ProgressoDaTrilha progresso;
  final bool primeiro;
  final bool ultimo;
  final bool atual;

  @override
  Widget build(BuildContext context) {
    final feito = progresso.alcancou(marco);
    final valor = progresso.valorDe(marco.tipo);
    final cor = feito
        ? Cores.primaria
        : atual
            ? Cores.acento
            : Cores.tintaA(0.28);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A linha que liga os degraus: é ela que faz disto uma trilha e não
          // uma lista de cartões soltos.
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 3,
                    color: primeiro
                        ? Colors.transparent
                        : (feito ? Cores.primariaA(0.45) : Cores.tintaA(0.12)),
                  ),
                ),
                _No(feito: feito, atual: atual, cor: cor),
                Expanded(
                  child: Container(
                    width: 3,
                    color: ultimo
                        ? Colors.transparent
                        : (feito ? Cores.primariaA(0.45) : Cores.tintaA(0.12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Espaco.xs),
              child: CartaoBaru(
                padding: const EdgeInsets.all(Espaco.md),
                cor: atual
                    ? Cores.acentoA(0.10)
                    : feito
                        ? Cores.superficieElevada
                        : Cores.tintaA(0.035),
                elevado: atual || feito,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tituloDoMarco(app, marco),
                      style: estilo(
                        Tipo.corpoForte,
                        color: feito || atual
                            ? Cores.tinta
                            : Cores.tintaA(0.62),
                      ),
                    ),
                    const SizedBox(height: Espaco.xs),
                    Row(
                      children: [
                        Etiqueta(
                          texto: feito
                              ? app.t.trilhaFeito
                              : atual
                                  ? app.t.trilhaAgora
                                  : app.t.trilhaBloqueado,
                          cor: cor,
                          forte: atual,
                          icone: feito ? Icons.check_rounded : null,
                        ),
                        const SizedBox(width: Espaco.xs),
                        if (!feito)
                          Text(
                            '$valor/${marco.alvo}',
                            style: estilo(
                              Tipo.rotuloPequeno,
                              color: Cores.tintaA(0.5),
                              tabular: true,
                            ),
                          ),
                      ],
                    ),
                    if (!feito) ...[
                      const SizedBox(height: Espaco.xs),
                      BarraAnimada(
                        fracao: progresso.fracaoDe(marco),
                        altura: 6,
                        cor: cor,
                      ),
                    ],
                    const SizedBox(height: Espaco.xs),
                    Wrap(
                      spacing: Espaco.xs,
                      runSpacing: Espaco.xxs,
                      children: premiosDoMarco(app, marco)
                          .map(
                            (p) => Text(
                              p,
                              style: estilo(
                                Tipo.rotuloPequeno,
                                color: Cores.acentoTexto,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _No extends StatelessWidget {
  const _No({required this.feito, required this.atual, required this.cor});

  final bool feito;
  final bool atual;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final tamanho = atual ? 22.0 : 16.0;
    return AnimatedContainer(
      duration: Movimento.duracao(context, Tempo.componente),
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: feito ? cor : (atual ? cor : Cores.superficie),
        shape: BoxShape.circle,
        border: Border.all(color: cor, width: atual ? 3 : 2.5),
        boxShadow: atual ? Elevacao.cartao : null,
      ),
      child: feito
          ? const Icon(Icons.check_rounded, size: 11, color: Cores.tintaClara)
          : null,
    );
  }
}

/// Título do marco montado do tipo e do alvo — sem 12 chaves de i18n para 12
/// marcos, e novo marco não exige tradução nova.
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
