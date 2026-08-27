import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/tempo_de_tela.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/componentes.dart';

/// Onde o seu tempo foi — por categoria e por app.
///
/// Existe porque o usuário precisa **entender** o número da meta, ou não
/// confia nele. Antes o app mostrava um total que somava launcher, system UI e
/// Spotify tocando no bolso, sem nenhuma forma de conferir.
class TempoScreen extends StatelessWidget {
  const TempoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final resumo = app.resumoTela;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cabecalho(titulo: t.telaT, aoVoltar: app.voltar),
        Expanded(
          child: !app.usageAccess
              ? EstadoVazio(
                  icone: Icons.lock_clock_outlined,
                  titulo: t.telaSemPermissaoT,
                  corpo: t.telaSemPermissaoB,
                  rotuloAcao: t.permAllow,
                  acao: app.requestUsageAccessFromSettings,
                  cor: Cores.acento,
                )
              : (resumo == null || resumo.vazio)
                  ? EstadoVazio(
                      icone: Icons.hourglass_empty_rounded,
                      titulo: t.telaVazioT,
                      corpo: t.telaVazioB,
                    )
                  : _Detalhamento(app: app, resumo: resumo),
        ),
      ],
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.titulo, required this.aoVoltar});

  final String titulo;
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
      child: Row(
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
    );
  }
}

class _Detalhamento extends StatelessWidget {
  const _Detalhamento({required this.app, required this.resumo});

  final AppState app;
  final ResumoDeTela resumo;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espaco.margemTela,
        0,
        Espaco.margemTela,
        Espaco.xxl,
      ),
      children: [
        _Destaque(app: app, resumo: resumo),
        const SizedBox(height: Espaco.sm),
        _Categorias(app: app, resumo: resumo),
        const SizedBox(height: Espaco.sm),
        _ComoContamos(texto: t.telaComoContamos),
        const SizedBox(height: Espaco.lg),
        Padding(
          padding: const EdgeInsets.only(left: Espaco.xxs, bottom: Espaco.sm),
          child: Text(
            t.telaPorApp.toUpperCase(),
            style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
          ),
        ),
        for (final e in resumo.appsPorTempo)
          Padding(
            padding: const EdgeInsets.only(bottom: Espaco.xs),
            child: _LinhaDeApp(
              app: app,
              pacote: e.key,
              tempo: e.value,
              maior: resumo.appsPorTempo.first.value,
            ),
          ),
      ],
    );
  }
}

/// O número grande: quanto conta para a meta, e quanto foi no total.
class _Destaque extends StatelessWidget {
  const _Destaque({required this.app, required this.resumo});

  final AppState app;
  final ResumoDeTela resumo;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final contado = resumo.minutosContabilizados;
    final total = resumo.minutosTotais;
    final fracao = app.goal == 0 ? 0.0 : contado / app.goal;
    final acima = contado > app.goal;

    return CartaoBaru(
      padding: const EdgeInsets.all(Espaco.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContadorAnimado(
            valor: contado,
            estiloTexto: estilo(Tipo.numeroGrande),
            formata: app.fmt,
          ),
          const SizedBox(height: Espaco.xxs),
          Text(
            t.telaContado.toUpperCase(),
            style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.5)),
          ),
          const SizedBox(height: Espaco.md),
          BarraAnimada(
            fracao: fracao,
            altura: 12,
            cor: acima ? Cores.acento : Cores.primaria,
          ),
          const SizedBox(height: Espaco.sm),
          Text(
            t.fill(t.telaSub, {
              'd': app.fmt(contado),
              't': app.fmt(total),
            }),
            style: estilo(Tipo.corpo, color: Cores.tintaA(0.62)),
          ),
        ],
      ),
    );
  }
}

class _Categorias extends StatelessWidget {
  const _Categorias({required this.app, required this.resumo});

  final AppState app;
  final ResumoDeTela resumo;

  @override
  Widget build(BuildContext context) {
    final total = resumo.total.inMinutes;
    return CartaoBaru(
      child: Column(
        children: [
          for (final c in CategoriaDeApp.values) ...[
            _linha(app, c, resumo, total),
            if (c != CategoriaDeApp.values.last)
              const SizedBox(height: Espaco.sm),
          ],
        ],
      ),
    );
  }

  Widget _linha(
    AppState app,
    CategoriaDeApp c,
    ResumoDeTela r,
    int total,
  ) {
    final min = (r.porCategoria[c] ?? Duration.zero).inMinutes;
    final fracao = total == 0 ? 0.0 : min / total;
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: corDaCategoria(c),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Espaco.xs),
              Expanded(
                child: Text(
                  nomeDaCategoria(app, c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.rotulo),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BarraAnimada(
            fracao: fracao,
            altura: 8,
            cor: corDaCategoria(c),
          ),
        ),
        const SizedBox(width: Espaco.sm),
        SizedBox(
          width: 66,
          child: Text(
            app.fmt(min),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: estilo(Tipo.rotulo, color: Cores.tintaA(0.6), tabular: true),
          ),
        ),
      ],
    );
  }
}

class _ComoContamos extends StatelessWidget {
  const _ComoContamos({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        color: Cores.primariaA(0.09),
        borderRadius: Raio.todos(Raio.cartao),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: Cores.primariaEscura,
          ),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Text(
              texto,
              style: estilo(Tipo.corpoPequeno, color: Cores.primariaEscura),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaDeApp extends StatelessWidget {
  const _LinhaDeApp({
    required this.app,
    required this.pacote,
    required this.tempo,
    required this.maior,
  });

  final AppState app;
  final String pacote;
  final Duration tempo;
  final Duration maior;

  @override
  Widget build(BuildContext context) {
    const padrao = ClassificacaoPadrao();
    const contabilidade = ContabilidadeDeTela();
    final categoria =
        contabilidade.categoriaDe(pacote, app.ajustesDeCategoria);
    final fracao =
        maior.inSeconds == 0 ? 0.0 : tempo.inSeconds / maior.inSeconds;

    return CartaoBaru(
      padding: const EdgeInsets.fromLTRB(
        Espaco.md,
        Espaco.sm,
        Espaco.md,
        Espaco.sm,
      ),
      onTap: () => _abreSeletor(context, padrao.nome(pacote), categoria),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        padrao.nome(pacote),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(Tipo.corpoForte),
                      ),
                    ),
                    const SizedBox(width: Espaco.xs),
                    Text(
                      app.fmt(tempo.inMinutes),
                      style: estilo(
                        Tipo.rotulo,
                        color: Cores.tintaA(0.6),
                        tabular: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Espaco.xs),
                Row(
                  children: [
                    Etiqueta(
                      texto: nomeDaCategoria(app, categoria),
                      cor: corDaCategoria(categoria),
                    ),
                    const SizedBox(width: Espaco.xs),
                    Expanded(
                      child: BarraAnimada(
                        fracao: fracao,
                        altura: 6,
                        cor: corDaCategoria(categoria),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Espaco.xs),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Cores.tintaA(0.3),
          ),
        ],
      ),
    );
  }

  void _abreSeletor(
    BuildContext context,
    String nome,
    CategoriaDeApp atual,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.superficie,
      shape: RoundedRectangleBorder(borderRadius: Raio.topo(Raio.folha)),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(nome, style: estilo(Tipo.tituloGrande)),
              const SizedBox(height: Espaco.xxs),
              Text(
                app.t.telaMudarCategoria,
                style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
              ),
              const SizedBox(height: Espaco.lg),
              for (final c in CategoriaDeApp.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espaco.xs),
                  child: _OpcaoCategoria(
                    rotulo: nomeDaCategoria(app, c),
                    cor: corDaCategoria(c),
                    selecionada: c == atual,
                    onTap: () {
                      Navigator.pop(ctx);
                      HapticFeedback.mediumImpact();
                      app.reclassifica(pacote, c);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcaoCategoria extends StatelessWidget {
  const _OpcaoCategoria({
    required this.rotulo,
    required this.cor,
    required this.selecionada,
    required this.onTap,
  });

  final String rotulo;
  final Color cor;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionada,
      label: rotulo,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Movimento.duracao(context, Tempo.componente),
          height: Toque.confortavel,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
          decoration: BoxDecoration(
            color: selecionada ? cor.withValues(alpha: 0.16) : Cores.tintaA(0.05),
            borderRadius: Raio.todos(Raio.botao),
            border: selecionada ? Border.all(color: cor, width: 2.5) : null,
          ),
          child: Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Text(
                  rotulo,
                  style: estilo(
                    Tipo.subtitulo,
                    weight: selecionada ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (selecionada)
                Icon(Icons.check_rounded, size: 19, color: cor),
            ],
          ),
        ),
      ),
    );
  }
}

Color corDaCategoria(CategoriaDeApp c) {
  switch (c) {
    case CategoriaDeApp.dispersivo:
      return Cores.dispersivo;
    case CategoriaDeApp.neutro:
      return Cores.neutro;
    case CategoriaDeApp.produtivo:
      return Cores.produtivo;
    case CategoriaDeApp.passivo:
      return Cores.passivo;
  }
}

String nomeDaCategoria(AppState app, CategoriaDeApp c) {
  switch (c) {
    case CategoriaDeApp.dispersivo:
      return app.t.catDispersivo;
    case CategoriaDeApp.neutro:
      return app.t.catNeutro;
    case CategoriaDeApp.produtivo:
      return app.t.catProdutivo;
    case CategoriaDeApp.passivo:
      return app.t.catPassivo;
  }
}
