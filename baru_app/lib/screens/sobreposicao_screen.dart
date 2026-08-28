import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/tempo_de_tela.dart';
import '../l10n.dart';
import '../l10n_sobreposicao.dart';
import '../models.dart';
import '../services/overlay_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';
import 'tempo_screen.dart' show corDaCategoria, nomeDaCategoria;

/// A tela de permissões, e a sobreposição como argumento.
///
/// **O defeito que ela conserta.** No aparelho do dono do produto o acesso ao
/// uso estava concedido e "desenhar sobre outros apps" estava negada. O
/// companheiro nunca aparecia e nada no app dizia por quê — recusar uma
/// permissão era indistinguível de o app estar quebrado.
///
/// Então aqui as quatro permissões estão numa lista, cada uma com o que faz,
/// o que deixa de funcionar sem ela, e um caminho de um toque para conceder
/// de novo. É a tela que a pessoa **revisita**: uma recusa no onboarding não
/// é definitiva, e o produto tem de dizer isso.
///
/// A pré-visualização continua no topo. Pedir `SYSTEM_ALERT_WINDOW` sem
/// mostrar é o jeito mais rápido de a pessoa negar: é a mesma permissão que
/// malware usa, e a única defesa honesta é mostrar antes de pedir.
class SobreposicaoScreen extends StatefulWidget {
  const SobreposicaoScreen({super.key});

  static const chavePreview = Key('sobreposicao-preview');
  static const chaveCatalogo = Key('sobreposicao-catalogo');

  @override
  State<SobreposicaoScreen> createState() => _SobreposicaoScreenState();
}

class _SobreposicaoScreenState extends State<SobreposicaoScreen>
    with WidgetsBindingObserver {
  /// O que o sistema respondeu por permissão. Vazio = ainda perguntando.
  Map<PermissaoDoBaru, bool> _estado = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confere();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Voltar da tela do sistema é exatamente quando a resposta mudou.
    if (state == AppLifecycleState.resumed) _confere();
  }

  Future<void> _confere() async {
    final lidas = <PermissaoDoBaru, bool>{};
    for (final p in Permissoes.daPlataforma()) {
      lidas[p] = await Permissoes.concedida(p);
    }
    if (mounted) setState(() => _estado = lidas);
  }

  Future<void> _pede(AppState app, PermissaoDoBaru p) async {
    if (p == PermissaoDoBaru.usoDoAparelho) {
      // Passa pelo domínio, e não direto pelo serviço, porque é o domínio
      // que distingue "a pessoa recusou" de "o Android travou a chave por o
      // app ter vindo de um arquivo" — e só ele sabe abrir o passo a passo.
      try {
        await app.requestUsageAccessFromSettings();
      } catch (_) {
        // Abrir a tela do sistema pode falhar (plataforma sem o plugin, um
        // fabricante sem a Activity). A tela continua de pé e as outras três
        // permissões continuam acessíveis.
      }
    } else {
      await Permissoes.pede(p);
    }
    await _confere();
  }

  @override
  Widget build(BuildContext context) {
    garanteTextosDaSobreposicao();
    final app = AppScope.of(context);
    final t = app.t;
    final ehAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final daPlataforma = Permissoes.daPlataforma();
    final concedidas = _estado.values.where((v) => v).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(
          titulo: t.sobreT,
          subtitulo: t.fill(t.sobreSub, {'n': app.displayName}),
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
              Text(
                t.sobrePreview.toUpperCase(),
                style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
              ),
              const SizedBox(height: Espaco.sm),
              _Previa(app: app),
              const SizedBox(height: Espaco.lg),

              // --- as permissões ---------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.sobPermT.toUpperCase(),
                      style: estilo(
                        Tipo.rotuloPequeno,
                        color: Cores.tintaA(0.45),
                      ),
                    ),
                  ),
                  Text(
                    t.fill(t.sobPermResumo, {
                      'q': concedidas,
                      'total': daPlataforma.length,
                    }),
                    style: estilo(
                      Tipo.rotuloPequeno,
                      color: concedidas == daPlataforma.length
                          ? Cores.primariaEscura
                          : Cores.acentoTexto,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espaco.sm),
              for (final p in daPlataforma) ...[
                CartaoDePermissao(
                  t: t,
                  nomeDoPet: app.displayName,
                  permissao: p,
                  concedida: _estado[p],
                  aoPedir: () => _pede(app, p),
                ),
                const SizedBox(height: Espaco.xs),
              ],
              if (!ehAndroid) ...[
                const SizedBox(height: Espaco.xs),
                _Nota(texto: t.sobreSoAndroid, cor: Cores.neutro),
              ],
              const SizedBox(height: Espaco.xs),
              _Nota(texto: t.sobreComo, cor: Cores.tintaA(0.45)),

              // --- o catálogo de apps ----------------------------------
              const SizedBox(height: Espaco.lg),
              _CatalogoDeApps(key: SobreposicaoScreen.chaveCatalogo, app: app),
            ],
          ),
        ),
      ],
    );
  }
}

/// Uma permissão: o que faz, o que quebra sem ela, e o botão de conceder.
///
/// Pública porque o onboarding mostra exatamente o mesmo cartão. Dois
/// desenhos para a mesma permissão dariam duas explicações diferentes da
/// mesma coisa, e é a explicação que decide se a pessoa concede.
class CartaoDePermissao extends StatelessWidget {
  const CartaoDePermissao({
    super.key,
    required this.t,
    required this.nomeDoPet,
    required this.permissao,
    required this.concedida,
    required this.aoPedir,
  });

  final T t;
  final String nomeDoPet;
  final PermissaoDoBaru permissao;

  /// `null` enquanto o sistema ainda não respondeu — diferente de negada.
  final bool? concedida;

  final VoidCallback aoPedir;

  /// Uma chave por permissão: na tela de permissões há quatro cartões ao
  /// mesmo tempo, e uma chave só faria o teste (e o `Semantics`) não saberem
  /// em qual botão estão tocando.
  static Key chaveDoBotao(PermissaoDoBaru p) => Key('permissao-pedir-${p.name}');

  IconData get _icone => switch (permissao) {
        PermissaoDoBaru.usoDoAparelho => Icons.query_stats_rounded,
        PermissaoDoBaru.sobreOutrosApps => Icons.layers_outlined,
        PermissaoDoBaru.notificacoes => Icons.notifications_none_rounded,
        PermissaoDoBaru.alarmeExato => Icons.alarm_rounded,
      };

  @override
  Widget build(BuildContext context) {
    garanteTextosDaSobreposicao();
    final ok = concedida == true;
    String comOPet(String molde) => t.fill(molde, {'n': nomeDoPet});

    return CartaoBaru(
      padding: const EdgeInsets.all(Espaco.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : _icone,
                size: 22,
                color: ok ? Cores.primaria : Cores.tintaA(0.4),
              ),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.tituloDaPermissao(permissao),
                      style: estilo(Tipo.subtitulo),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ok ? t.sobPermLigada : t.sobPermFalta,
                      style: estilo(
                        Tipo.rotuloPequeno,
                        color: ok ? Cores.primariaEscura : Cores.acentoTexto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.sm),
          Text(
            comOPet(t.oQueFazAPermissao(permissao)),
            style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.7)),
          ),
          // O custo da recusa só aparece quando ela é o estado atual: dizer
          // o que quebra numa permissão já concedida é assustar à toa.
          if (!ok) ...[
            const SizedBox(height: Espaco.sm),
            Container(
              padding: const EdgeInsets.all(Espaco.sm),
              decoration: BoxDecoration(
                color: Cores.acento.withValues(alpha: 0.10),
                borderRadius: Raio.todos(Raio.chip),
              ),
              child: Text.rich(
                TextSpan(
                  style: estilo(Tipo.corpoPequeno, color: Cores.acentoTexto),
                  children: [
                    TextSpan(
                      text: '${t.sobPermSemIsso} ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: comOPet(t.semAPermissao(permissao))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Espaco.sm),
            GhostButton(
              key: chaveDoBotao(permissao),
              label: concedida == null ? t.sobPermPermitir : t.sobPermDeNovo,
              onTap: aoPedir,
            ),
          ],
        ],
      ),
    );
  }
}

/// O catálogo de apps, visível e editável.
///
/// **Por que ele existe aqui.** A reclassificação só existia no relatório do
/// dia, e ali só aparece o que a pessoa **já abriu hoje**. Quem quisesse
/// dizer "jogo, para mim, é produtivo" antes de jogar não tinha por onde. O
/// catálogo do app tem de ser visível e discordável, não uma tabela secreta
/// que decide o número da meta.
///
/// Começa fechado, com seis. Sessenta e tantos cartões abertos de saída
/// empurrariam a tela de permissões — que é o assunto principal — para fora
/// da primeira dobra.
class _CatalogoDeApps extends StatefulWidget {
  const _CatalogoDeApps({super.key, required this.app});

  final AppState app;

  @override
  State<_CatalogoDeApps> createState() => _CatalogoDeAppsState();
}

class _CatalogoDeAppsState extends State<_CatalogoDeApps> {
  static const _fechado = 6;

  bool _aberto = false;

  @override
  Widget build(BuildContext context) {
    garanteTextosDaSobreposicao();
    final app = widget.app;
    final t = app.t;
    final pacotes = ClassificacaoPadrao.comFala;
    final mostrados = _aberto ? pacotes : pacotes.take(_fechado).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.sobAppsT.toUpperCase(),
          style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
        ),
        const SizedBox(height: Espaco.xs),
        Text(
          t.fill(t.sobAppsSub, {
            'n': app.displayName,
            'q': pacotes.length,
          }),
          style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.6)),
        ),
        const SizedBox(height: Espaco.sm),
        for (final pacote in mostrados) ...[
          _LinhaDoCatalogo(app: app, pacote: pacote),
          const SizedBox(height: Espaco.xxs),
        ],
        TextAction(
          label: _aberto
              ? t.sobAppsVerMenos
              : t.fill(t.sobAppsVerTodos, {'q': pacotes.length}),
          onTap: () => setState(() => _aberto = !_aberto),
        ),
      ],
    );
  }
}

class _LinhaDoCatalogo extends StatelessWidget {
  const _LinhaDoCatalogo({required this.app, required this.pacote});

  final AppState app;
  final String pacote;

  @override
  Widget build(BuildContext context) {
    const padrao = ClassificacaoPadrao();
    const contabilidade = ContabilidadeDeTela();
    final categoria = contabilidade.categoriaDe(pacote, app.ajustesDeCategoria);

    return CartaoBaru(
      elevado: false,
      cor: Cores.tintaA(0.03),
      padding: const EdgeInsets.symmetric(
        horizontal: Espaco.md,
        vertical: Espaco.sm,
      ),
      onTap: () => _abreSeletor(context, app, pacote, categoria),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: corDaCategoria(categoria),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Text(
              padrao.nome(pacote),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estilo(Tipo.corpoForte),
            ),
          ),
          Text(
            nomeDaCategoria(app, categoria),
            style: estilo(Tipo.rotuloPequeno, color: corDaCategoria(categoria)),
          ),
          const SizedBox(width: Espaco.xxs),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Cores.tintaA(0.3),
          ),
        ],
      ),
    );
  }
}

/// A folha que troca a categoria de um app.
///
/// Mesmo gesto do relatório do dia: quatro opções, a atual marcada, e o
/// número da meta muda na hora — `reclassifica` recalcula localmente antes de
/// falar com o sistema.
void _abreSeletor(
  BuildContext context,
  AppState app,
  String pacote,
  CategoriaDeApp atual,
) {
  const padrao = ClassificacaoPadrao();
  final t = app.t;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Cores.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
    ),
    builder: (folha) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(padrao.nome(pacote), style: estilo(Tipo.titulo)),
            const SizedBox(height: Espaco.xxs),
            Text(
              t.telaMudarCategoria,
              style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.6)),
            ),
            const SizedBox(height: Espaco.md),
            for (final c in CategoriaDeApp.values)
              Padding(
                padding: const EdgeInsets.only(bottom: Espaco.xs),
                child: CartaoBaru(
                  elevado: false,
                  cor: c == atual
                      ? corDaCategoria(c).withValues(alpha: 0.12)
                      : Cores.tintaA(0.04),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espaco.md,
                    vertical: Espaco.sm,
                  ),
                  onTap: () {
                    Navigator.of(folha).pop();
                    app.reclassifica(pacote, c);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: corDaCategoria(c),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: Espaco.sm),
                      Expanded(
                        child: Text(
                          nomeDaCategoria(app, c),
                          style: estilo(Tipo.subtitulo),
                        ),
                      ),
                      if (c == atual)
                        Icon(
                          Icons.check_rounded,
                          size: 19,
                          color: corDaCategoria(c),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A pré-visualização: o balão como ele aparece sobre o outro app.
///
/// Desenhada com os mesmos tokens e o mesmo `PetView` do app — o que se vê
/// aqui é o que o overlay nativo reproduz em `Canvas`.
class _Previa extends StatelessWidget {
  const _Previa({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    return ClipRRect(
      key: SobreposicaoScreen.chavePreview,
      borderRadius: Raio.todos(Raio.cartao),
      child: Container(
        height: 300,
        color: const Color(0xFF1C1A19),
        child: Stack(
          children: [
            // O "outro app" atrás: barras cinzas, sem imitar marca nenhuma.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(Espaco.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final altura in [18.0, 96.0, 14.0, 70.0])
                      Padding(
                        padding: const EdgeInsets.only(bottom: Espaco.sm),
                        child: Container(
                          height: altura,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: Raio.todos(Raio.campo),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: Espaco.sm,
              bottom: Espaco.sm,
              child: _Balao(app: app, fala: t.sobreFala1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.app, required this.fala});

  final AppState app;
  final String fala;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 224,
          padding: const EdgeInsets.all(Espaco.md),
          decoration: BoxDecoration(
            color: Cores.superficie,
            borderRadius: Raio.todos(Raio.cartao),
            boxShadow: Elevacao.cartaoElevado,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fala, style: estilo(Tipo.corpoForte)),
              const SizedBox(height: Espaco.sm),
              Row(
                children: [
                  Expanded(
                    child: _BotaoFalso(
                      rotulo: t.sobreFechar,
                      cor: Cores.primaria,
                      texto: Cores.superficie,
                    ),
                  ),
                  const SizedBox(width: Espaco.xs),
                  Expanded(
                    child: _BotaoFalso(
                      rotulo: t.sobreMais,
                      cor: Cores.tintaA(0.08),
                      texto: Cores.tinta,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Rabicho apontando para o bicho.
        Padding(
          padding: const EdgeInsets.only(right: 34),
          child: CustomPaint(
            size: const Size(22, 12),
            painter: _Rabicho(),
          ),
        ),
        SizedBox(
          width: 120,
          height: 92,
          child: PetView(
            species: app.species,
            mood: app.mood,
            activity: Activity.idle,
            coat: app.color,
            scale: 0.62,
            interativo: false,
          ),
        ),
      ],
    );
  }
}

class _BotaoFalso extends StatelessWidget {
  const _BotaoFalso({
    required this.rotulo,
    required this.cor,
    required this.texto,
  });

  final String rotulo;
  final Color cor;
  final Color texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: Raio.todos(Raio.pilula),
      ),
      child: Text(
        rotulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: estilo(Tipo.corpoPequeno, color: texto),
      ),
    );
  }
}

class _Rabicho extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.55, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = Cores.superficie,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Nota extends StatelessWidget {
  const _Nota({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: cor),
        const SizedBox(width: Espaco.xs),
        Expanded(
          child: Text(
            texto,
            style: estilo(Tipo.corpoPequeno, color: cor),
          ),
        ),
      ],
    );
  }
}
