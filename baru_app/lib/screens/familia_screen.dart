import 'dart:async';

import '../widgets/ranking_do_laco.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/familia.dart';
import '../l10n.dart';
import '../l10n_familia.dart';
import '../l10n_foto.dart';
import '../services/familia_sync.dart';
import '../services/foto_de_perfil.dart';
import '../services/notification_service.dart';
import '../services/localizacao.dart';
import '../services/overlay_service.dart';
import '../services/tempo_de_tela_ios.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/botao_baru.dart';
import '../widgets/componentes.dart';
import 'mapa_familia_screen.dart';

/// Modo família (docs/CONTROLE_PARENTAL.md, fase 4).
///
/// Uma tela, três situações:
/// - sem família: escolher "sou o responsável" ou "este celular é de uma criança";
/// - responsável: cada criança com o dia de hoje, as regras e os avisos;
/// - criança: a família, a meta e a autorização de tempo de tela do aparelho.
class FamiliaScreen extends StatefulWidget {
  const FamiliaScreen({super.key, this.repo, this.comConta, this.sondaSobreposicao, this.sondaFiltro, this.sondaNotificacoes, this.semMapa = false});

  /// Para os testes: o mapa sem baixar quadrinhos.
  @visibleForTesting
  final bool semMapa;

  /// Para o teste trocar o banco.
  final FamiliaRepo? repo;

  /// Para o teste: finge que há (ou não) uma conta logada.
  @visibleForTesting
  final bool? comConta;

  /// Para o teste: responde se o app pode aparecer sobre outros (Android).
  @visibleForTesting
  final Future<bool> Function()? sondaSobreposicao;

  /// Para o teste: responde se a VPN do filtro já foi permitida (Android).
  @visibleForTesting
  final Future<bool> Function()? sondaFiltro;

  /// Para o teste: responde se as notificações do Baru estão ligadas.
  @visibleForTesting
  final Future<bool> Function()? sondaNotificacoes;

  /// Só para as capturas da loja (test/capturas_loja_test.dart): a casca
  /// abre esta tela em vez da real. Nulo no app.
  static FamiliaScreen? deTeste;

  static const chaveCriar = Key('familia-criar');
  static const chaveEntrar = Key('familia-entrar');

  @override
  State<FamiliaScreen> createState() => _FamiliaScreenState();
}

class _FamiliaScreenState extends State<FamiliaScreen> with WidgetsBindingObserver {
  late final FamiliaRepo _repo = widget.repo ?? FamiliaRepo();
  MinhaFamilia? _familia;
  EstadoTempoDeTela _tela = EstadoTempoDeTela.indisponivel;
  bool _sobrepor = true;
  bool _filtroPronto = true;
  Map<String, MapaDaFamilia> _mapas = const {};
  PermissaoDeLocal _local = PermissaoDeLocal.negada;
  bool _avisoDeLocalMostrado = false;
  String? _erro;
  bool _ocupado = false;
  bool _todaAtividade = false;

  /// Laço aberto no mapa (o último escolhido neste celular).
  String? _lacoAtual;
  static const _chaveLacoAtual = 'baru_laco_atual';

  /// Hora do último SOS que este celular marcou como visto.
  DateTime? _sosVisto;
  static const _chaveSosVisto = 'baru_familia_sos_visto';

  /// Sobe a cada recarga: o mapa relê as posições.
  int _recarga = 0;

  /// Pede ao mapa para abrir uma pessoa (o aviso de SOS).
  final _focoNoMapa = ValueNotifier<String?>(null);

  /// Responsável com notificações desligadas não vê o SOS: aviso no topo.
  bool _notificacoes = true;

  final _nome = TextEditingController();
  final _codigo = TextEditingController();

  @override
  void initState() {
    super.initState();
    garanteTextosDaFamilia();
    garanteTextosDaFoto();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_carrega());
  }

  /// Voltou dos ajustes do celular: confere de novo as notificações.
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) unawaited(_confereNotificacoes());
  }

  Future<void> _confereNotificacoes() async {
    if (kIsWeb) return;
    bool ligadas;
    try {
      ligadas = await (widget.sondaNotificacoes ?? BaruNotifications.instance.hasPermission)();
    } catch (_) {
      ligadas = true;
    }
    if (mounted && ligadas != _notificacoes) setState(() => _notificacoes = ligadas);
  }

  Future<void> _ligaNotificacoes() async {
    final ok = await BaruNotifications.instance.ensurePermission();
    // Negadas de vez: só pelos ajustes do sistema.
    if (!ok) await LocalNativo.abrirAjustes();
    await _confereNotificacoes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focoNoMapa.dispose();
    _nome.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _carrega() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _sosVisto = DateTime.tryParse(prefs.getString(_chaveSosVisto) ?? '');
      _lacoAtual ??= prefs.getString(_chaveLacoAtual);
      final f = await _repo.minha();
      final tela = await TempoDeTelaIos.estado();
      final sobrepor = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? await (widget.sondaSobreposicao ?? OverlayService.instance.temPermissao)()
          : true;
      final filtroPronto = !kIsWeb && defaultTargetPlatform == TargetPlatform.android && f.souCrianca &&
              (f.minhasRegras?.filtroSites ?? false)
          ? true // sem filtro de sites no Android (VpnService recusado pela Google)
          : true;
      // Localização: o mapa de cada família (responsável) e a permissão deste celular (criança).
      final mapas = <String, MapaDaFamilia>{};
      for (final fam in f.familias.where((x) => x.souResponsavel)) {
        try {
          mapas[fam.id] = await _repo.mapa(fam.id);
        } catch (_) {}
      }
      final local = f.souCrianca ? await LocalNativo.estado() : PermissaoDeLocal.negada;
      if (!mounted) return;
      setState(() {
        _recarga++;
        _familia = f;
        _mapas = mapas;
        _local = local;
        _tela = tela;
        _sobrepor = sobrepor;
        _filtroPronto = filtroPronto;
        _erro = null;
      });
      if (f.souCrianca) unawaited(FamiliaSync.instance.envia(AppScope.of(context)));
      if (f.souResponsavel) unawaited(_confereNotificacoes());
      if (f.souCrianca && (f.minhasRegras?.localizacao ?? false) && !local.concedida &&
          local != PermissaoDeLocal.desligada && !_avisoDeLocalMostrado) {
        _avisoDeLocalMostrado = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final app = AppScope.of(context);
          if (!await mostraAvisoDeLocalizacao(context, app.t)) return;
          await LocalNativo.pedir(sempre: true);
          await FamiliaSync.instance.envia(app);
          await _carrega();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  Future<void> _faz(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await acao();
      await _carrega();
    } catch (e) {
      if (mounted) setState(() => _erro = _limpa(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  /// A mensagem do banco sem o embrulho do PostgrestException.
  static String _limpa(Object e) {
    final s = '$e';
    final m = RegExp(r'message: ([^,]+)').firstMatch(s);
    return (m?.group(1) ?? s).trim();
  }

  String get _plataforma => kIsWeb
      ? 'web'
      : defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final f = _familia;

    // Responsável: a aba é o mapa. Tempo de tela e regras ficam em cada pessoa.
    final lacos = (widget.comConta ?? app.canSignOut) && f != null && !f.souCrianca
        ? f.familias.where((x) => x.souResponsavel).toList()
        : const <Familia>[];
    if (lacos.isNotEmpty) {
      final atual = lacos.where((x) => x.id == _lacoAtual).firstOrNull ?? lacos.first;
      return _mapaPrincipal(t, app, atual, lacos);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(titulo: t.s('famT'), subtitulo: t.s('famSub')),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carrega,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Espaco.margemTela, Espaco.sm, Espaco.margemTela, Espaco.xxl),
              children: [
                if (_erro != null) ...[
                  Text(t.fill(t.s('famErro'), {'e': _erro!}), style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
                  const SizedBox(height: Espaco.sm),
                ],
                if (!(widget.comConta ?? app.canSignOut))
                  EstadoVazio(icone: Icons.family_restroom_rounded, titulo: t.s('famT'), corpo: t.s('famSemConta'))
                else if (f == null)
                  const Padding(padding: EdgeInsets.all(Espaco.xxl), child: Center(child: CircularProgressIndicator()))
                else if (f.souCrianca)
                  ..._crianca(t, app, f)
                else if (f.souResponsavel)
                  ..._responsavel(t, app, f)
                else
                  ..._semFamilia(t),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // ------------------------------------------------------------ mapa (responsável)

  Widget _mapaPrincipal(T t, AppState app, Familia f, List<Familia> lacos) {
    final sos = _sosRecente(f);
    final avisos = _visiveis(f);
    return MapaFamiliaScreen(
      key: ValueKey('mapa-${f.id}'),
      familiaId: f.id,
      t: t,
      repo: _repo,
      principal: true,
      semMapa: widget.semMapa,
      recarga: _recarga,
      foco: _focoNoMapa,
      titulo: f.nome,
      topoDaFolha: _SeletorDeLacos(
        t: t,
        lacos: lacos,
        atual: f.id,
        aoEscolher: _escolheLaco,
        aoCriar: _ocupado ? null : () => _novoLaco(t),
      ),
      aoAdicionar: _ocupado || !f.souAdmin ? null : () => _adicionar(t, f),
      aoGerenciar: f.souAdmin ? (id, nome, admin) => _gerenciar(t, f, id, nome, admin ? 'admin' : 'membro') : null,
      aoGerenciarDependente: f.souAdmin ? (id, nome) => _gerenciar(t, f, id, nome, 'dependente') : null,
      aoMudarMeuLocal: (_) => unawaited(FamiliaSync.instance.envia(app)),
      avisosNoTopo: [
        if (!_notificacoes)
          Material(
            key: const Key('familia-notif-desligadas'),
            color: Cores.alerta,
            borderRadius: BorderRadius.circular(Raio.cartao),
            child: InkWell(
              borderRadius: BorderRadius.circular(Raio.cartao),
              onTap: _ligaNotificacoes,
              child: Padding(
                padding: const EdgeInsets.all(Espaco.sm),
                child: Row(children: [
                  const Icon(Icons.notifications_off_rounded, color: Colors.white),
                  const SizedBox(width: Espaco.sm),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.s('famNotifOffT'), style: estilo(Tipo.corpoForte, color: Colors.white)),
                      Text(t.s('famNotifOffBotao'), key: const Key('familia-notif-ligar'),
                          style: estilo(Tipo.corpoPequeno, color: Colors.white.withValues(alpha: 0.9))),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ]),
              ),
            ),
          ),
        if (sos != null)
          _AlertaDeSos(
            t: t,
            nome: _nomeDe(t, f, sos.criancaId),
            em: sos.em,
            aoTocar: () => _focoNoMapa.value = sos.criancaId,
            aoFechar: () => _marcaSosVisto(sos),
          ),
      ],
      detalheDaPessoa: (context, id) {
        final c = f.criancas.where((x) => x.id == id).firstOrNull;
        if (c == null) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _CartaoDaCrianca(
            crianca: c,
            app: app,
            ocupado: _ocupado,
            aoAbrir: () => _abreRegras(t, app, f, c),
            aoExtra: (n) => _faz(() => _repo.tempoExtra(c.id, n)),
            aoPausar: () => _escolhePausa(t, c),
            aoRetomar: () => _faz(() => _repo.pausar(c.id, null)),
            bateria: _mapas[f.id]?.criancas.where((x) => x.id == c.id).firstOrNull?.atual?.bateria,
            aoTrocarFoto: () async {
              if (await FotoDePerfil.escolhe(context, t, dono: c.id, temFoto: c.foto != null)) await _carrega();
            },
          ),
          const SizedBox(height: Espaco.xs),
          // Localização desta pessoa: ligar pede consentimento; desligar fica à mão.
          Align(
            alignment: Alignment.centerLeft,
            child: c.regras.localizacao
                ? TextButton.icon(
                    key: Key('local-${c.id}'),
                    onPressed: _ocupado ? null : () => _ligaLocal(t, c, false),
                    icon: const Icon(Icons.location_off_outlined, size: 18),
                    label: Text(t.s('famLocalDesligar')),
                  )
                : TextButton.icon(
                    key: Key('local-${c.id}'),
                    onPressed: _ocupado ? null : () => _ligaLocal(t, c, true),
                    icon: const Icon(Icons.location_on_outlined, size: 18),
                    label: Text(t.fill(t.s('locLigar'), {'n': c.apelido ?? t.s('famCriancaPadrao')})),
                  ),
          ),
        ]);
      },
      acoesDaFolha: [
        const SizedBox(height: Espaco.md),
        RankingDoLaco(laco: f.id, t: t, aoAssinar: () => app.go(AppScreen.paywall)),
        if (avisos.isNotEmpty) ...[
          const SizedBox(height: Espaco.md),
          _TituloDaSecao(t.s('famSecAtividade')),
          CartaoBaru(
            padding: const EdgeInsets.symmetric(horizontal: Espaco.md, vertical: Espaco.xs),
            child: Column(children: [
              for (final e in avisos.take(_todaAtividade ? 30 : 5))
                _LinhaDeEvento(evento: e, nome: _nomeDe(t, f, e.criancaId), t: t),
              if (avisos.length > 5)
                TextButton(
                  key: const Key('familia-ver-tudo'),
                  onPressed: () => setState(() => _todaAtividade = !_todaAtividade),
                  child: Text(t.s(_todaAtividade ? 'famVerMenos' : 'famVerTodos')),
                ),
            ]),
          ),
        ],
        // Mais de 6 pessoas: o plano família não cobre todo mundo; o Família+ cobre até 10.
        if (f.souAdmin && f.criancas.length + f.responsaveis.length > 6) ...[
          const SizedBox(height: Espaco.md),
          CartaoBaru(
            key: const Key('laco-familia-mais'),
            cor: Cores.primariaA(0.10),
            elevado: false,
            onTap: () => app.go(AppScreen.paywall),
            child: Row(children: [
              const Icon(Icons.workspace_premium_outlined, color: Cores.primariaEscura),
              const SizedBox(width: Espaco.sm),
              Expanded(child: Text(t.s('lacoFamiliaMais'), style: estilo(Tipo.corpoPequeno))),
              const Icon(Icons.chevron_right_rounded, color: Cores.primariaEscura),
            ]),
          ),
        ],
        const SizedBox(height: Espaco.md),
        if (f.souAdmin)
          BotaoBaru(
            key: const Key('familia-gerar'),
            rotulo: t.s('lacoAdicionar'),
            papel: PapelDoBotao.secundario,
            ativo: !_ocupado,
            aoTocar: () => _adicionar(t, f),
          ),
      ],
    );
  }

  /// Adicionar alguém: adulto (entra como membro) ou dependente.
  Future<void> _adicionar(T t, Familia f) async {
    final escolha = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Cores.canvas,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(t.s('lacoAdicionar'), style: estilo(Tipo.subtitulo))),
          ListTile(
            key: const Key('adicionar-adulto'),
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(t.s('nivelMembro')),
            subtitle: Text(t.s('nivelMembroSub')),
            onTap: () => Navigator.pop(ctx, false),
          ),
          ListTile(
            key: const Key('adicionar-dependente'),
            leading: const Icon(Icons.child_care_rounded),
            title: Text(t.s('nivelDependente')),
            subtitle: Text(t.s('nivelDependenteSub')),
            onTap: () => Navigator.pop(ctx, true),
          ),
        ]),
      ),
    );
    if (escolha == null) return;
    await _convidar(t, f, crianca: escolha);
  }

  /// Administrador: muda o nível de alguém ou tira do laço.
  Future<void> _gerenciar(T t, Familia f, String id, String nome, String nivelAtual) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Cores.canvas,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: Espaco.sm),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: Text(nome, style: estilo(Tipo.titulo)), subtitle: Text(t.s('nivelT'))),
            for (final n in const ['admin', 'membro', 'dependente'])
              ListTile(
                key: Key('nivel-$n'),
                leading: Icon(n == nivelAtual ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: n == nivelAtual ? Cores.primariaEscura : Cores.tinta500),
                title: Text(t.s(switch (n) { 'admin' => 'nivelAdmin', 'membro' => 'nivelMembro', _ => 'nivelDependente' })),
                subtitle: Text(t.s(switch (n) { 'admin' => 'nivelAdminSub', 'membro' => 'nivelMembroSub', _ => 'nivelDependenteSub' })),
                onTap: () => Navigator.pop(ctx, n),
              ),
            const Divider(),
            ListTile(
              key: const Key('nivel-tirar'),
              leading: const Icon(Icons.person_remove_outlined, color: Cores.alerta),
              title: Text(t.s('famRemover'), style: const TextStyle(color: Cores.alerta)),
              onTap: () => Navigator.pop(ctx, 'tirar'),
            ),
          ]),
        ),
      ),
    );
    if (r == null || r == nivelAtual || !mounted) return;
    if (r == 'tirar') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(t.fill(t.s('famRemoverConfirma'), {'n': nome})),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.s('locCancelar'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.s('famRemover'), style: const TextStyle(color: Cores.alerta))),
          ],
        ),
      );
      if (ok == true) await _faz(() => _repo.remover(f.id, id));
      return;
    }
    await _faz(() => _repo.nivel(f.id, id, r));
  }

  Future<void> _escolheLaco(String id) async {
    setState(() => _lacoAtual = id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveLacoAtual, id);
  }

  Future<void> _novoLaco(T t) async {
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoNovoLaco(t: t),
    );
    if (nome == null) return;
    String? id;
    await _faz(() async {
      id = await _repo.criar(nome);
    });
    if (id != null && mounted) await _escolheLaco(id!);
  }
  // ------------------------------------------------------------ sem família

  List<Widget> _semFamilia(T t) => [
        Text(t.s('famNenhumaT'), style: estilo(Tipo.titulo)),
        const SizedBox(height: Espaco.xs),
        Text(t.s('famNenhumaCorpo'), style: estilo(Tipo.corpo, color: Cores.tinta700)),
        const SizedBox(height: Espaco.lg),
        // Quem disse no começo que este celular é de uma criança vê primeiro o código.
        if (AppScope.of(context).paraQuem == 'filho') ...[
          _cartaoEntrar(t),
          const SizedBox(height: Espaco.md),
        ],
        CartaoBaru(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.s('famSouResp'), style: estilo(Tipo.subtitulo)),
              const SizedBox(height: Espaco.xxs),
              Text(t.s('famSouRespSub'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
              const SizedBox(height: Espaco.sm),
              TextField(
                controller: _nome,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                decoration: InputDecoration(labelText: t.s('famNomeDaFamilia'), hintText: t.s('famNomePadrao'), counterText: ''),
              ),
              const SizedBox(height: Espaco.sm),
              BotaoBaru(
                key: FamiliaScreen.chaveCriar,
                rotulo: t.s('famCriar'),
                ativo: !_ocupado,
                aoTocar: () => _faz(() async {
                  final nome = _nome.text.trim().isEmpty ? t.s('famNomePadrao') : _nome.text.trim();
                  await _repo.criar(nome);
                }),
              ),
            ],
          ),
        ),
        if (AppScope.of(context).paraQuem != 'filho') ...[
          const SizedBox(height: Espaco.md),
          _cartaoEntrar(t),
        ],
      ];

  Widget _cartaoEntrar(T t) => CartaoBaru(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.s('famSouCrianca'), style: estilo(Tipo.subtitulo)),
            const SizedBox(height: Espaco.xxs),
            Text(t.s('famSouCriancaSub'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            const SizedBox(height: Espaco.sm),
            TextField(
              controller: _codigo,
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
              style: estilo(Tipo.numeroGrande, tabular: true).copyWith(letterSpacing: 6),
              textAlign: TextAlign.center,
              decoration: InputDecoration(labelText: t.s('famCodigo'), helperText: t.s('famCodigoAjuda'), counterText: ''),
            ),
            const SizedBox(height: Espaco.sm),
            BotaoBaru(
              key: FamiliaScreen.chaveEntrar,
              rotulo: t.s('famEntrar'),
              papel: PapelDoBotao.secundario,
              ativo: !_ocupado,
              aoTocar: () => _faz(() async {
                await _repo.entrar(_codigo.text, plataforma: _plataforma);
                _codigo.clear();
              }),
            ),
          ],
        ),
      );

  // ------------------------------------------------------------ responsável

  List<Widget> _responsavel(T t, AppState app, MinhaFamilia m) {
    final out = <Widget>[];
    for (final f in m.familias.where((f) => f.souResponsavel)) {
      final mapa = _mapas[f.id];
      final avisos = _visiveis(f);
      final sos = _sosRecente(f);
      out.addAll([
        // 1. Quem é a família e o único botão de criar.
        Row(
          children: [
            Expanded(child: Text(f.nome, style: estilo(Tipo.titulo))),
            TextButton.icon(
              onPressed: _ocupado ? null : () => _convidar(t, f, crianca: true),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t.s('famAddCrianca')),
            ),
          ],
        ),
        const SizedBox(height: Espaco.sm),
        // Sem notificações o SOS chega calado na tela: isto vem antes de tudo.
        if (!_notificacoes) ...[
          CartaoBaru(
            key: const Key('familia-notif-desligadas'),
            cor: Cores.alerta.withValues(alpha: 0.12),
            elevado: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Icon(Icons.notifications_off_rounded, color: Cores.alerta),
                const SizedBox(width: Espaco.sm),
                Expanded(child: Text(t.s('famNotifOffT'), style: estilo(Tipo.corpoForte, color: Cores.alerta))),
              ]),
              const SizedBox(height: Espaco.xxs),
              Text(t.s('famNotifOffC'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
              const SizedBox(height: Espaco.sm),
              BotaoBaru(
                key: const Key('familia-notif-ligar'),
                rotulo: t.s('famNotifOffBotao'),
                papel: PapelDoBotao.destrutivo,
                aoTocar: _ligaNotificacoes,
              ),
            ]),
          ),
          const SizedBox(height: Espaco.md),
        ],
        // 2. Urgente primeiro: um pedido de ajuda recente fica no topo, em vermelho.
        if (sos != null) ...[
          _AlertaDeSos(
            t: t,
            nome: _nomeDe(t, f, sos.criancaId),
            em: sos.em,
            aoTocar: () => _abreMapa(t, f, sos.criancaId),
          ),
          const SizedBox(height: Espaco.md),
        ],
        if (f.criancas.isEmpty)
          CartaoBaru(
            child: EstadoVazio(
              icone: Icons.child_care_rounded,
              titulo: t.s('famSemCriancas'),
              corpo: t.s('famSemCriancasCorpo'),
              acao: () => _convidar(t, f, crianca: true),
              rotuloAcao: t.s('famGerarCodigo'),
            ),
          )
        else ...[
          // 3. Onde estão: uma linha por criança e o mapa a um toque.
          _TituloDaSecao(t.s('famSecOnde')),
          CartaoBaru(
            padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.xs, Espaco.md, Espaco.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final c in f.criancas) ...[
                  _LinhaDeOnde(
                    t: t,
                    crianca: c,
                    local: mapa?.criancas.where((x) => x.id == c.id).firstOrNull,
                    ocupado: _ocupado,
                    aoLocal: (ligar) => _ligaLocal(t, c, ligar),
                    aoPedirLocal: () => _faz(() async {
                      await _repo.pedirLocal(c.id);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.s('locPedido'))));
                    }),
                    aoVerMapa: () => _abreMapa(t, f, c.id),
                  ),
                  Divider(height: 1, color: Cores.tintaA(0.07)),
                ],
                const SizedBox(height: Espaco.sm),
                BotaoBaru(
                  key: const Key('familia-mapa'),
                  rotulo: t.s('famAbrirMapa'),
                  papel: PapelDoBotao.secundario,
                  aoTocar: () => _abreMapa(t, f, null),
                ),
              ],
            ),
          ),
          const SizedBox(height: Espaco.lg),
          // 4. Tempo de tela: um cartão por criança, com as ações do dia.
          _TituloDaSecao(t.s('famSecTela')),
          for (final c in f.criancas) ...[
            _CartaoDaCrianca(
              crianca: c,
              app: app,
              ocupado: _ocupado,
              aoAbrir: () => _abreRegras(t, app, f, c),
              aoExtra: (n) => _faz(() => _repo.tempoExtra(c.id, n)),
              aoPausar: () => _escolhePausa(t, c),
              aoRetomar: () => _faz(() => _repo.pausar(c.id, null)),
              bateria: mapa?.criancas.where((x) => x.id == c.id).firstOrNull?.atual?.bateria,
            ),
            const SizedBox(height: Espaco.sm),
          ],
        ],
        // 5. Atividade: o histórico, curto por padrão.
        if (avisos.isNotEmpty) ...[
          const SizedBox(height: Espaco.md),
          _TituloDaSecao(t.s('famSecAtividade')),
          CartaoBaru(
            padding: const EdgeInsets.symmetric(horizontal: Espaco.md, vertical: Espaco.xs),
            child: Column(
              children: [
                for (final e in avisos.take(_todaAtividade ? 30 : 5))
                  _LinhaDeEvento(evento: e, nome: _nomeDe(t, f, e.criancaId), t: t),
                if (avisos.length > 5)
                  TextButton(
                    key: const Key('familia-ver-tudo'),
                    onPressed: () => setState(() => _todaAtividade = !_todaAtividade),
                    child: Text(t.s(_todaAtividade ? 'famVerMenos' : 'famVerTodos')),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Espaco.lg),
        Center(
          child: TextButton.icon(
            onPressed: _ocupado ? null : () => _convidar(t, f, crianca: false),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
            label: Text(t.s('famConvidarResp')),
          ),
        ),
        const SizedBox(height: Espaco.lg),
      ]);
    }
    return out;
  }

  /// O pedido de ajuda das últimas 12 horas que ainda não foi marcado como visto.
  EventoDaFamilia? _sosRecente(Familia f) {
    final limite = DateTime.now().subtract(const Duration(hours: 12));
    for (final e in f.eventos) {
      if (e.tipo != 'sos' || !e.em.toLocal().isAfter(limite)) continue;
      if (_sosVisto != null && !e.em.isAfter(_sosVisto!)) return null;
      return e;
    }
    return null;
  }

  Future<void> _marcaSosVisto(EventoDaFamilia e) async {
    setState(() => _sosVisto = e.em);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chaveSosVisto, e.em.toIso8601String());
  }

  /// Ligar pede o consentimento do responsável (LGPD/ECA): fica registrado no banco.
  Future<void> _ligaLocal(T t, CriancaNaFamilia c, bool ligar) async {
    final nome = c.apelido ?? t.s('famCriancaPadrao');
    if (ligar) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.fill(t.s('locConsentT'), {'n': nome})),
          content: Text(t.fill(t.s('locConsentCorpo'), {'n': nome}), style: estilo(Tipo.corpo)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.s('locCancelar'))),
            TextButton(key: const Key('local-consentir'), onPressed: () => Navigator.pop(ctx, true), child: Text(t.s('locConsentOk'))),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _faz(() => _repo.localizacao(c.id, ligada: ligar));
  }

  Future<void> _abreMapa(T t, Familia f, String? criancaId) async {
    // Tela cheia, por cima das abas: o mapa não divide espaço.
    await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
      builder: (_) => MapaFamiliaScreen(familiaId: f.id, t: t, repo: _repo, focoCriancaId: criancaId),
    ));
    await _carrega();
  }

  /// SOS: segura o botão, confirma, e a posição vai para a família com aviso.
  Future<void> _sos(T t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.s('locSosT')),
        content: Text(t.s('locSosCorpo'), style: estilo(Tipo.corpo)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.s('locCancelar'))),
          FilledButton(
            key: const Key('sos-enviar'),
            style: FilledButton.styleFrom(backgroundColor: Cores.alerta),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.s('locSosEnviar')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _ocupado = true);
    final enviado = await FamiliaSync.sos();
    if (!mounted) return;
    setState(() => _ocupado = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: enviado ? Cores.folha700 : Cores.alerta,
      content: Text(t.s(enviado ? 'locSosEnviado' : 'locSosFalhou')),
    ));
    await _carrega();
  }

  /// O responsável escolhe, por criança, quais avisos quer ver.
  static const _avisoDoEvento = {
    'chegou': 'lugares',
    'saiu_de': 'lugares',
    'meta_75': 'meta_75',
    'meta_batida': 'meta_batida',
    'meta_passou': 'meta_passou',
    'autorizacao_revogada': 'autorizacao',
    'regras_mudaram': 'regras',
  };

  List<EventoDaFamilia> _visiveis(Familia f) => f.eventos.where((e) {
        final chave = _avisoDoEvento[e.tipo];
        if (chave == null) return true;
        final c = f.criancas.where((c) => c.id == e.criancaId).firstOrNull;
        return (c?.regras.avisos ?? RegrasDaFamilia.avisosPadrao)[chave] ?? true;
      }).toList();

  Future<void> _escolhePausa(T t, CriancaNaFamilia c) async {
    final agora = DateTime.now();
    final amanha7 = DateTime(agora.year, agora.month, agora.day + 1, 7);
    final ate = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Cores.canvas,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(t.s('famPausarAgora'), style: estilo(Tipo.subtitulo))),
          ListTile(leading: const Icon(Icons.timer_outlined), title: Text(t.s('famPausa30')),
              onTap: () => Navigator.pop(ctx, agora.add(const Duration(minutes: 30)))),
          ListTile(leading: const Icon(Icons.hourglass_bottom_rounded), title: Text(t.s('famPausa1h')),
              onTap: () => Navigator.pop(ctx, agora.add(const Duration(hours: 1)))),
          ListTile(leading: const Icon(Icons.bedtime_outlined), title: Text(t.s('famPausaAmanha')),
              onTap: () => Navigator.pop(ctx, amanha7)),
        ]),
      ),
    );
    if (ate != null) await _faz(() => _repo.pausar(c.id, ate));
  }

  String _nomeDe(T t, Familia f, String? id) {
    for (final c in f.criancas) {
      if (c.id == id) return c.apelido ?? t.s('famCriancaPadrao');
    }
    return t.s('famCriancaPadrao');
  }

  Future<void> _convidar(T t, Familia f, {required bool crianca}) async {
    String? apelido;
    if (crianca) {
      // O diálogo é dono do campo: descartar o controlador aqui, com o
      // diálogo ainda fechando na tela, derrubava a tela inteira.
      apelido = await showDialog<String>(
        context: context,
        builder: (_) => _DialogoDoApelido(t: t),
      );
      if (apelido == null) return;
    }
    ConviteDaFamilia? convite;
    await _faz(() async {
      convite = await _repo.convidar(f.id, crianca: crianca, apelido: apelido);
    });
    final c = convite;
    if (c == null || !mounted) return;
    final h = TimeOfDay.fromDateTime(c.expiraEm.toLocal()).format(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(crianca ? t.s('famAddCrianca') : t.s('famConvidarResp')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(crianca ? t.s('famCodigoGerado') : t.s('famCodigoResp'), style: estilo(Tipo.corpo)),
            const SizedBox(height: Espaco.md),
            // Numa linha só, em qualquer largura: código partido ao meio
            // vira dois códigos para quem lê.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SelectableText(
                c.codigo,
                key: const Key('familia-codigo'),
                maxLines: 1,
                style: estilo(Tipo.numeroGrande, tabular: true).copyWith(letterSpacing: 6),
              ),
            ),
            const SizedBox(height: Espaco.xs),
            Text(t.fill(t.s('famValeAte'), {'h': h}), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  Future<void> _abreRegras(T t, AppState app, Familia f, CriancaNaFamilia c) async {
    final mudou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Cores.canvas,
      builder: (ctx) => _FolhaDeRegras(t: t, app: app, crianca: c, repo: _repo, familia: f),
    );
    if (mudou == true) await _carrega();
  }

  // ------------------------------------------------------------ criança

  List<Widget> _crianca(T t, AppState app, MinhaFamilia m) {
    final f = m.familias.firstWhere((x) => !x.souResponsavel, orElse: () => m.familias.first);
    final r = m.minhasRegras ?? const RegrasDaFamilia();
    final agora = DateTime.now();
    final agoraSemTela = r.horarioAgora(agora) != null;
    final pausada = r.pausadaEm(agora);
    final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    return [
      // "Família Familia Cuba" não: se o nome já diz família, vai só o nome.
      Text(RegExp(r'^(fam[ií]lia|family|家)', caseSensitive: false).hasMatch(f.nome.trim()) ? f.nome : t.fill(t.s('famCriancaT'), {'f': f.nome}),
          style: estilo(Tipo.titulo)),
      const SizedBox(height: Espaco.xxs),
      Text(t.fill(t.s('famCriancaSub'), {'r': f.responsaveis.join(', ')}), style: estilo(Tipo.corpo, color: Cores.tinta700)),
      const SizedBox(height: Espaco.md),
      if (r.localizacao) ...[
        _CartaoDaLocalizacao(
          t: t,
          permissao: _local,
          ocupado: _ocupado,
          aoPermitir: () => _faz(() async {
            if (_local == PermissaoDeLocal.desligada) {
              await LocalNativo.abrirAjustes();
              return;
            }
            if (!await mostraAvisoDeLocalizacao(context, t)) return;
            final antes = _local;
            final depois = await LocalNativo.pedir(sempre: true);
            // Negado de vez (ou "sempre" já recusado): só pelos ajustes do sistema.
            if (depois == antes) await LocalNativo.abrirAjustes();
            await FamiliaSync.instance.envia(app);
          }),
        ),
        const SizedBox(height: Espaco.sm),
      ],
      if (pausada) ...[
        CartaoBaru(
          cor: Cores.alerta.withValues(alpha: 0.10),
          elevado: false,
          child: Row(children: [
            const Icon(Icons.pause_circle_filled_rounded, color: Cores.alerta),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Text(
                t.fill(t.s('famPausadaCrianca'), {'h': TimeOfDay.fromDateTime(r.pausaAte!.toLocal()).format(context)}),
                style: estilo(Tipo.corpoForte),
              ),
            ),
          ]),
        ),
        const SizedBox(height: Espaco.sm),
      ] else if (agoraSemTela) ...[
        CartaoBaru(
          cor: Cores.primariaA(0.10),
          elevado: false,
          child: Row(children: [
            const Icon(Icons.bedtime_rounded, color: Cores.primariaEscura),
            const SizedBox(width: Espaco.sm),
            Expanded(child: Text(t.s('famSemTelaAgora'), style: estilo(Tipo.corpoForte))),
          ]),
        ),
        const SizedBox(height: Espaco.sm),
      ],
      CartaoBaru(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.s('famMinhaMeta').toUpperCase(), style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700)),
            const SizedBox(height: Espaco.xxs),
            Text(app.fmt(r.metaDe(agora)), style: estilo(Tipo.numeroGrande, tabular: true)),
            if (r.extraHojeMin > 0)
              Text(t.fill(t.s('famExtraHoje'), {'n': app.fmt(r.extraHojeMin)}), style: estilo(Tipo.corpoPequeno, color: Cores.folha700)),
            const SizedBox(height: Espaco.xs),
            Text(
              r.horariosSemTela.isEmpty ? '${t.s('famSemTela')}: ${t.s('famSemTelaNenhum')}' : '${t.s('famSemTela')}: ${_descreveHorarios(t, r.horariosSemTela)}',
              style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
            ),
          ],
        ),
      ),
      const SizedBox(height: Espaco.sm),
      if (ios && _tela.suportado) ...[
        if (!_tela.autorizado)
          BotaoBaru(
            rotulo: t.s('famAutorizar'),
            ativo: !_ocupado,
            aoTocar: () => _faz(() async {
              _tela = await TempoDeTelaIos.pedirAutorizacao(crianca: true);
              await FamiliaSync.instance.envia(app);
            }),
          )
        else ...[
          Text('✓ ${t.s('famAutorizado')}', style: estilo(Tipo.corpoForte, color: Cores.folha700)),
          const SizedBox(height: Espaco.xs),
          BotaoBaru(
            rotulo: _tela.temEscolha
                ? t.fill(t.s('famAppsEscolhidos'), {'n': _tela.apps + _tela.categorias + _tela.sites})
                : t.s('famEscolherApps'),
            papel: PapelDoBotao.secundario,
            ativo: !_ocupado,
            aoTocar: () => _faz(() async {
              _tela = await TempoDeTelaIos.escolherApps();
              await FamiliaSync.instance.envia(app);
            }),
          ),
        ],
        const SizedBox(height: Espaco.xxs),
        if (!_tela.autorizado) Text(t.s('famAutorizarSub'), textAlign: TextAlign.center, style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
      ] else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
        if (!_filtroPronto) ...[
          CartaoBaru(
            onTap: () => _faz(() async {
              await FamiliaSync.pedeFiltro();
              await FamiliaSync.instance.envia(app);
            }),
            child: Row(children: [
              const Icon(Icons.shield_outlined, color: Cores.alerta),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.s('famFiltroAtivar'), style: estilo(Tipo.corpoForte)),
                  Text(t.s('famFiltroAtivarSub'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: Espaco.sm),
        ],
        if (!_sobrepor) ...[
          CartaoBaru(
            onTap: () => _faz(OverlayService.instance.pedePermissao),
            child: Row(children: [
              const Icon(Icons.layers_outlined, color: Cores.alerta),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.s('famSobrepor'), style: estilo(Tipo.corpoForte)),
                  Text(t.s('famSobreporSub'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                ]),
              ),
              Text(t.s('famAndroidUsoOff'), style: estilo(Tipo.rotulo, color: Cores.alerta)),
            ]),
          ),
          const SizedBox(height: Espaco.sm),
        ],
        CartaoBaru(
          onTap: app.usageAccess ? null : () => _faz(app.toggleUsageAccess),
          child: Row(children: [
            Icon(app.usageAccess ? Icons.check_circle_rounded : Icons.query_stats_rounded,
                color: app.usageAccess ? Cores.folha600 : Cores.alerta),
            const SizedBox(width: Espaco.sm),
            Expanded(child: Text(t.s('famAndroidUso'), style: estilo(Tipo.corpoForte))),
            Text(app.usageAccess ? t.s('famAndroidUsoOn') : t.s('famAndroidUsoOff'),
                style: estilo(Tipo.rotulo, color: app.usageAccess ? Cores.folha700 : Cores.alerta)),
          ]),
        ),
      ],
      const SizedBox(height: Espaco.lg),
      Center(
        child: Tooltip(
          message: t.s('locSosSegure'),
          child: GestureDetector(
            key: const Key('familia-sos'),
            onLongPress: _ocupado ? null : () => _sos(t),
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Cores.alerta,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Cores.alerta.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Text(t.s('locSosBotao'), style: estilo(Tipo.titulo, color: Colors.white)),
            ),
          ),
        ),
      ),
      const SizedBox(height: Espaco.xs),
      Text(t.s('locSosSegure'), textAlign: TextAlign.center, style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
      const SizedBox(height: Espaco.lg),
    ];
  }
}

String _descreveHorarios(T t, List<HorarioSemTela> hs) =>
    hs.map((h) => '${h.inicio}–${h.fim}').join(', ');

/// Faixa noturna padrão que o responsável liga com um toque.
const horarioNoturno = HorarioSemTela(dias: [1, 2, 3, 4, 5], inicio: '21:00', fim: '07:00');

class _CartaoDaCrianca extends StatelessWidget {
  const _CartaoDaCrianca({
    required this.crianca,
    required this.app,
    required this.aoAbrir,
    required this.aoExtra,
    required this.aoPausar,
    required this.aoRetomar,
    this.ocupado = false,
    this.bateria,
    this.aoTrocarFoto,
  });

  /// Responsável toca na foto da criança para trocar.
  final VoidCallback? aoTrocarFoto;

  final CriancaNaFamilia crianca;
  final AppState app;
  final VoidCallback aoAbrir;
  final ValueChanged<int> aoExtra;
  final VoidCallback aoPausar;
  final VoidCallback aoRetomar;
  final bool ocupado;
  final int? bateria;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final c = crianca;
    final agora = DateTime.now();
    final hoje = c.hoje;
    final meta = c.regras.metaDe(agora);
    final uso = hoje?.usoMin ?? 0;
    final fracao = meta <= 0 ? 0.0 : (uso / meta).clamp(0.0, 1.0);
    final passou = meta > 0 && uso >= meta;
    final pausada = c.regras.pausadaEm(agora);
    final linhaUso = hoje == null
        ? t.s('famSemDados')
        : t.fill(t.s(hoje.usoExato ? 'famUsoExato' : 'famUsoAoMenos'), {'u': app.fmt(uso), 'm': app.fmt(meta)});
    final detalhe = [
      if (c.nomeDoBicho != null) c.nomeDoBicho!,
      if (c.plataforma != null) c.plataforma == 'ios' ? 'iPhone' : 'Android',
      if (bateria != null && bateria! >= 0) t.fill(t.s('locBateria'), {'n': bateria!}),
    ].join(' · ');
    return CartaoBaru(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quem: nome grande, aparelho embaixo, regras no canto.
          Row(children: [
            Semantics(
              button: aoTrocarFoto != null,
              label: t.s('fotoTrocar'),
              child: GestureDetector(
                key: Key('foto-${c.id}'),
                onTap: aoTrocarFoto,
                child: Stack(clipBehavior: Clip.none, children: [
                  FotoOuLetra(dono: c.id, versao: c.foto, nome: c.apelido ?? t.s('famCriancaPadrao'), raio: 24,
                      cor: Cores.primariaA(0.14), corDaLetra: Cores.primariaEscura),
                  if (aoTrocarFoto != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Cores.primariaEscura, shape: BoxShape.circle),
                        child: const Icon(Icons.photo_camera_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.apelido ?? t.s('famCriancaPadrao'), style: estilo(Tipo.subtitulo)),
                if (detalhe.isNotEmpty) Text(detalhe, style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
              ]),
            ),
            IconButton(
              tooltip: t.s('famEditarRegras'),
              onPressed: aoAbrir,
              icon: const Icon(Icons.tune_rounded, color: Cores.tinta700),
            ),
          ]),
          if (pausada) ...[
            const SizedBox(height: Espaco.xs),
            Etiqueta(
              texto: t.fill(t.s('famPausada'), {'h': TimeOfDay.fromDateTime(c.regras.pausaAte!.toLocal()).format(context)}),
              cor: Cores.alerta,
              icone: Icons.pause_circle_filled_rounded,
            ),
          ],
          const SizedBox(height: Espaco.md),
          // Hoje: a frase do uso e a barra até a meta.
          Text(linhaUso, key: Key('hoje-${c.id}'), style: estilo(hoje == null ? Tipo.corpo : Tipo.titulo)),
          const SizedBox(height: Espaco.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fracao,
              minHeight: 10,
              backgroundColor: Cores.trilho,
              color: passou ? Cores.alerta : Cores.folha600,
            ),
          ),
          if (c.regras.extraHojeMin > 0 || hoje?.metaBatidaEm != null || (hoje?.focos ?? 0) > 0) ...[
            const SizedBox(height: Espaco.xxs),
            Wrap(spacing: Espaco.sm, children: [
              if (c.regras.extraHojeMin > 0)
                Text(t.fill(t.s('famExtraHoje'), {'n': app.fmt(c.regras.extraHojeMin)}), style: estilo(Tipo.corpoPequeno, color: Cores.folha700)),
              if (hoje?.metaBatidaEm != null)
                Text(t.fill(t.s('famMetaBatida'), {'h': TimeOfDay.fromDateTime(hoje!.metaBatidaEm!.toLocal()).format(context)}),
                    style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
              if ((hoje?.focos ?? 0) > 0)
                Text(hoje!.focos == 1 ? t.s('famFoco1') : t.fill(t.s('famFocos'), {'n': hoje.focos}), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            ]),
          ],
          const SizedBox(height: Espaco.md),
          // As três ações do dia, lado a lado e do mesmo tamanho.
          Row(children: [
            Expanded(child: _AcaoDoDia(chave: 'mais15-${c.id}', icone: Icons.add_rounded, rotulo: '+15 min', aoTocar: ocupado ? null : () => aoExtra(15))),
            const SizedBox(width: Espaco.xs),
            Expanded(child: _AcaoDoDia(chave: 'mais30-${c.id}', icone: Icons.add_rounded, rotulo: '+30 min', aoTocar: ocupado ? null : () => aoExtra(30))),
            const SizedBox(width: Espaco.xs),
            Expanded(
              child: pausada
                  ? _AcaoDoDia(chave: 'retomar-${c.id}', icone: Icons.play_arrow_rounded, rotulo: t.s('famRetomarCurto'), forte: true, aoTocar: ocupado ? null : aoRetomar)
                  : _AcaoDoDia(chave: 'pausar-${c.id}', icone: Icons.pause_rounded, rotulo: t.s('famPausarCurto'), aoTocar: ocupado ? null : aoPausar),
            ),
          ]),
          if (c.regras.extraHojeMin > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: ocupado ? null : () => aoExtra(-c.regras.extraHojeMin), child: Text(t.s('famTirarExtra'))),
            ),
          const SizedBox(height: Espaco.md),
          Text(t.s('famSemana').toUpperCase(), style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700)),
          const SizedBox(height: Espaco.xs),
          if (c.semana.any((d) => d.usoMin > 0))
            _Semana(dias: c.semana, regras: c.regras, t: t)
          else
            Text(t.s('famSemanaVazia'), key: Key('semana-vazia-${c.id}'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
        ],
      ),
    );
  }
}

/// Laços em fichas no topo da folha do mapa; a última cria um laço novo.
class _SeletorDeLacos extends StatelessWidget {
  const _SeletorDeLacos({required this.t, required this.lacos, required this.atual, required this.aoEscolher, this.aoCriar});
  final T t;
  final List<Familia> lacos;
  final String atual;
  final ValueChanged<String> aoEscolher;
  final VoidCallback? aoCriar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final l in lacos) ...[
          ChoiceChip(
            key: Key('laco-${l.id}'),
            avatar: const Icon(Icons.groups_rounded, size: 18),
            label: Text(l.nome, style: estilo(Tipo.corpoForte)),
            selected: l.id == atual,
            onSelected: (_) => aoEscolher(l.id),
          ),
          const SizedBox(width: Espaco.xs),
        ],
        ActionChip(
          key: const Key('laco-novo'),
          avatar: const Icon(Icons.add_rounded, size: 18),
          label: Text(t.s('lacoNovo')),
          onPressed: aoCriar,
        ),
      ]),
    );
  }
}

/// Nome do laço novo (o laço funciona igual para todos; o nome é livre).
class _DialogoNovoLaco extends StatefulWidget {
  const _DialogoNovoLaco({required this.t});
  final T t;

  @override
  State<_DialogoNovoLaco> createState() => _DialogoNovoLacoState();
}

class _DialogoNovoLacoState extends State<_DialogoNovoLaco> {
  final _nome = TextEditingController();

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _cria() {
    final n = _nome.text.trim();
    if (n.isEmpty) return;
    Navigator.pop(context, n);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      title: Text(t.s('lacoNovo')),
      content: TextField(
        key: const Key('laco-nome'),
        controller: _nome,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: t.s('famNomeDaFamilia'), hintText: t.s('lacoNomeExemplo'), counterText: ''),
        onSubmitted: (_) => _cria(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.s('locCancelar'))),
        TextButton(key: const Key('laco-criar'), onPressed: _cria, child: Text(t.s('famCriar'))),
      ],
    );
  }
}

/// Título de seção: pequeno, em caixa alta, igual em todo o app.
class _TituloDaSecao extends StatelessWidget {
  const _TituloDaSecao(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.xs, 0, Espaco.xs, Espaco.xs),
        child: Text(texto.toUpperCase(),
            style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700).copyWith(letterSpacing: 0.8)),
      );
}

/// Inicial do nome num círculo: cada criança se reconhece de longe.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.nome, this.alerta = false});
  final String nome;
  final bool alerta;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: 20,
        backgroundColor: alerta ? Cores.alerta : Cores.primariaA(0.14),
        child: Text(
          nome.trim().isEmpty ? '?' : nome.trim().characters.first.toUpperCase(),
          style: estilo(Tipo.subtitulo, color: alerta ? Colors.white : Cores.primariaEscura),
        ),
      );
}

/// Pedido de ajuda recente: vermelho, no topo, abre o mapa.
class _AlertaDeSos extends StatelessWidget {
  const _AlertaDeSos({required this.t, required this.nome, required this.em, required this.aoTocar, this.aoFechar});
  final T t;

  /// "Já vi": some até chegar um SOS novo.
  final VoidCallback? aoFechar;
  final String nome;
  final DateTime em;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final h = TimeOfDay.fromDateTime(em.toLocal()).format(context);
    return Material(
      key: const Key('familia-alerta-sos'),
      color: Cores.alerta,
      borderRadius: BorderRadius.circular(Raio.cartao),
      child: InkWell(
        borderRadius: BorderRadius.circular(Raio.cartao),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(Espaco.md),
          child: Row(children: [
            const Icon(Icons.sos_rounded, color: Colors.white, size: 30),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.fill(t.s('famSosAlerta'), {'n': nome, 'h': h}), style: estilo(Tipo.subtitulo, color: Colors.white)),
                Text(t.fill(t.s('famSosAlertaSub'), {'n': nome}), style: estilo(Tipo.corpoPequeno, color: Colors.white.withValues(alpha: 0.9))),
              ]),
            ),
            if (aoFechar != null)
              TextButton(
                key: const Key('familia-sos-visto'),
                onPressed: aoFechar,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  padding: const EdgeInsets.symmetric(horizontal: Espaco.sm),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(t.s('famSosVisto'), style: estilo(Tipo.corpoPequeno, color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

/// Uma criança na seção "Onde estão": onde, há quanto tempo, e o que fazer
/// quando falta posição.
class _LinhaDeOnde extends StatelessWidget {
  const _LinhaDeOnde({
    required this.t,
    required this.crianca,
    required this.local,
    required this.ocupado,
    required this.aoLocal,
    required this.aoPedirLocal,
    required this.aoVerMapa,
  });

  final T t;
  final CriancaNaFamilia crianca;
  final CriancaNoMapa? local;
  final bool ocupado;
  final ValueChanged<bool> aoLocal;
  final VoidCallback aoPedirLocal;
  final VoidCallback aoVerMapa;

  @override
  Widget build(BuildContext context) {
    final c = crianca;
    final nome = c.apelido ?? t.s('famCriancaPadrao');
    final ligada = c.regras.localizacao;
    final motivo = local == null ? null : diagnosticoDoLocal(t, local!);
    final sos = local?.atual?.motivo == 'sos';
    if (!ligada) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
        child: Row(children: [
          _Avatar(nome: nome),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.fill(t.s('locLigar'), {'n': nome}), style: estilo(Tipo.corpoForte)),
              Text(t.s('famLocalDesligada'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            ]),
          ),
          TextButton(
            key: Key('local-${c.id}'),
            onPressed: ocupado ? null : () => aoLocal(true),
            child: Text(t.s('locLigarBotao')),
          ),
        ]),
      );
    }
    return InkWell(
      onTap: aoVerMapa,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Avatar(nome: nome, alerta: sos),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nome, style: estilo(Tipo.corpoForte)),
              Text(
                local?.atual == null ? t.fill(t.s('locSemPosicao'), {'n': nome}) : linhaDoLocal(t, local!.atual!),
                style: estilo(Tipo.corpoPequeno, color: sos ? Cores.alerta : Cores.tinta700),
              ),
              if (motivo != null)
                Padding(
                  padding: const EdgeInsets.only(top: Espaco.xxs),
                  child: Text(motivo, key: Key('local-motivo-${c.id}'), style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
                ),
              Row(children: [
                TextButton.icon(
                  key: Key('atualizar-${c.id}'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: ocupado ? null : aoPedirLocal,
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: Text(t.s('locAtualizar')),
                ),
              ]),
            ]),
          ),
          Switch(
            key: Key('local-${c.id}'),
            value: true,
            onChanged: ocupado ? null : aoLocal,
          ),
        ]),
      ),
    );
  }
}

/// Botão compacto das ações do cartão: todos do mesmo tamanho, numa linha.
class _AcaoDoDia extends StatelessWidget {
  const _AcaoDoDia({required this.chave, required this.icone, required this.rotulo, required this.aoTocar, this.forte = false});

  final String chave;
  final IconData icone;
  final String rotulo;
  final VoidCallback? aoTocar;
  final bool forte;

  @override
  Widget build(BuildContext context) {
    final cor = forte ? Cores.primariaEscura : Cores.tinta;
    return OutlinedButton.icon(
      key: Key(chave),
      onPressed: aoTocar,
      icon: Icon(icone, size: 18, color: aoTocar == null ? Cores.tinta500 : Cores.primariaEscura),
      label: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo(Tipo.corpoPequeno, color: cor).copyWith(fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: Espaco.xs),
        side: BorderSide(color: forte ? Cores.primariaEscura : Cores.trilho, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: forte ? Cores.primariaA(0.08) : null,
      ),
    );
  }
}

/// No celular da criança: a localização está ligada (sempre visível) e a permissão deste aparelho.
class _CartaoDaLocalizacao extends StatelessWidget {
  const _CartaoDaLocalizacao({required this.t, required this.permissao, required this.aoPermitir, this.ocupado = false});

  final T t;
  final PermissaoDeLocal permissao;
  final VoidCallback aoPermitir;
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final falta = permissao != PermissaoDeLocal.sempre;
    final rotulo = switch (permissao) {
      PermissaoDeLocal.desligada => t.s('locAbrirAjustes'),
      PermissaoDeLocal.quandoUsa => t.s('locPermitirSempre'),
      _ => t.s('locPermitir'),
    };
    return CartaoBaru(
      cor: Cores.primariaA(0.08),
      elevado: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_rounded, color: Cores.primariaEscura),
          const SizedBox(width: Espaco.sm),
          Expanded(child: Text(t.s('locCriancaOn'), style: estilo(Tipo.corpoForte))),
        ]),
        const SizedBox(height: Espaco.xxs),
        Text(t.s('locCriancaOnSub'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
        if (falta) ...[
          const SizedBox(height: Espaco.xs),
          if (permissao == PermissaoDeLocal.desligada)
            Text(t.s('locSistemaDesligado'), style: estilo(Tipo.corpoPequeno, color: Cores.alerta))
          else if (permissao == PermissaoDeLocal.quandoUsa)
            Text(t.s('locPermitirSempreSub'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
          const SizedBox(height: Espaco.xs),
          BotaoBaru(key: const Key('local-permitir'), rotulo: rotulo, papel: PapelDoBotao.secundario, ativo: !ocupado, aoTocar: aoPermitir),
        ],
      ]),
    );
  }
}

/// Os últimos 7 dias em barras, com a linha da meta de cada dia.
class _Semana extends StatelessWidget {
  const _Semana({required this.dias, required this.regras, required this.t});

  final List<DiaDaCrianca> dias;
  final RegrasDaFamilia regras;
  final T t;

  @override
  Widget build(BuildContext context) {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final letras = t.s('famDiasCurtos').split(',');
    final porDia = {for (final d in dias) DateUtils.dateOnly(d.dia): d};
    final lista = [for (var i = 6; i >= 0; i--) hoje.subtract(Duration(days: i))];
    final maximo = [
      for (final d in lista) (porDia[d]?.usoMin ?? 0),
      for (final d in lista) (porDia[d]?.metaMin ?? regras.metaMin),
      1,
    ].reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in lista)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Expanded(
                    child: LayoutBuilder(builder: (_, box) {
                      final dia = porDia[d];
                      final uso = dia?.usoMin ?? 0;
                      final meta = dia?.metaMin ?? regras.metaMin;
                      final h = box.maxHeight * (uso / maximo);
                      return Stack(alignment: Alignment.bottomCenter, children: [
                        Positioned(
                          bottom: box.maxHeight * (meta / maximo),
                          left: 0,
                          right: 0,
                          child: Container(height: 1.5, color: Cores.tintaA(0.25)),
                        ),
                        Container(
                          height: uso == 0 ? 2 : h,
                          decoration: BoxDecoration(
                            color: uso == 0 ? Cores.trilho : (uso >= meta ? Cores.alerta : Cores.folha600),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ]);
                    }),
                  ),
                  const SizedBox(height: 2),
                  Text(letras[(d.weekday - 1) % letras.length],
                      style: estilo(Tipo.rotuloPequeno, color: d == hoje ? Cores.tinta : Cores.tinta500)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinhaDeEvento extends StatelessWidget {
  const _LinhaDeEvento({required this.evento, required this.nome, required this.t});

  final EventoDaFamilia evento;
  final String nome;
  final T t;

  static const _chaves = {
    'meta_75': 'famEvMeta75',
    'meta_batida': 'famEvMetaBatida',
    'meta_passou': 'famEvMetaPassou',
    'entrou': 'famEvEntrou',
    'saiu': 'famEvSaiu',
    'regras_mudaram': 'famEvRegras',
    'autorizacao_revogada': 'famEvAutorizacao',
    'tempo_extra': 'famEvTempoExtra',
    'pausa': 'famEvPausa',
    'chegou': 'famEvChegou',
    'saiu_de': 'famEvSaiuDe',
    'sos': 'famEvSos',
  };

  @override
  Widget build(BuildContext context) {
    final alerta = evento.tipo == 'meta_batida' || evento.tipo == 'meta_passou' || evento.tipo == 'autorizacao_revogada' || evento.tipo == 'sos';
    final chave = evento.tipo == 'localizacao'
        ? (evento.detalhe?['ligada'] == true ? 'famEvLocalOn' : 'famEvLocalOff')
        : _chaves[evento.tipo] ?? evento.tipo;
    final lugar = '${evento.detalhe?['lugar'] ?? ''}';
    final quando = evento.em.toLocal();
    final hoje = DateUtils.isSameDay(quando, DateTime.now());
    final hora = TimeOfDay.fromDateTime(quando).format(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
      child: Row(children: [
        Icon(alerta ? Icons.notifications_active_rounded : Icons.circle, size: alerta ? 18 : 8,
            color: alerta ? Cores.alerta : Cores.tinta500),
        const SizedBox(width: Espaco.sm),
        Expanded(child: Text(t.fill(t.s(chave), {'n': nome, 'l': lugar}), style: estilo(Tipo.corpo))),
        Text(hoje ? hora : '${quando.day}/${quando.month}', style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700)),
      ]),
    );
  }
}

/// Regras de uma criança: metas, horários sem tela, pausa, filtro e avisos.
class _FolhaDeRegras extends StatefulWidget {
  const _FolhaDeRegras({required this.t, required this.app, required this.crianca, required this.repo, required this.familia});

  final T t;
  final AppState app;
  final CriancaNaFamilia crianca;
  final FamiliaRepo repo;
  final Familia familia;

  @override
  State<_FolhaDeRegras> createState() => _FolhaDeRegrasState();
}

class _FolhaDeRegrasState extends State<_FolhaDeRegras> {
  late RegrasDaFamilia _r = widget.crianca.regras;
  bool _salvando = false;
  String? _erro;

  Future<void> _salva() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.repo.salvarRegras(widget.crianca.id, _r);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _erro = _FamiliaScreenState._limpa(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _remove() async {
    final t = widget.t;
    final nome = widget.crianca.apelido ?? t.s('famCriancaPadrao');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.fill(t.s('famRemoverConfirma'), {'n': nome})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.s('famCancelar'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.s('famRemover'), style: const TextStyle(color: Cores.alerta))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.repo.remover(widget.familia.id, widget.crianca.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _erro = _FamiliaScreenState._limpa(e));
    }
  }

  Future<void> _editaHorario([int? indice]) async {
    final atual = indice == null ? null : _r.horariosSemTela[indice];
    final novo = await showDialog<HorarioSemTela>(
      context: context,
      builder: (_) => _DialogoDeHorario(t: widget.t, inicial: atual),
    );
    if (novo == null) return;
    final lista = [..._r.horariosSemTela];
    if (indice == null) {
      lista.add(novo);
    } else {
      lista[indice] = novo;
    }
    setState(() => _r = _r.copia(horariosSemTela: lista));
  }

  Widget _meta(String rotulo, int valor, ValueChanged<int> muda) {
    final app = widget.app;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(rotulo, style: estilo(Tipo.corpoForte))),
        Text(app.fmt(valor), style: estilo(Tipo.subtitulo, tabular: true)),
      ]),
      Slider(
        value: valor.clamp(15, 480).toDouble(),
        min: 15,
        max: 480,
        divisions: (480 - 15) ~/ 15,
        label: app.fmt(valor),
        onChanged: (v) => muda(v.round()),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final letras = t.s('famDiasCurtos').split(',');
    String dias(List<int> ds) => ds.length == 7 ? '' : ds.map((d) => letras[d - 1]).join(' ');
    final fdsIgual = _r.metaFdsMin == null;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      builder: (_, rolagem) => SafeArea(
        child: ListView(
          controller: rolagem,
          padding: EdgeInsets.fromLTRB(Espaco.lg, Espaco.lg, Espaco.lg, Espaco.lg + MediaQuery.viewInsetsOf(context).bottom),
          children: [
            Text('${t.s('famRegras')} · ${widget.crianca.apelido ?? t.s('famCriancaPadrao')}', style: estilo(Tipo.titulo)),
            const SizedBox(height: Espaco.md),
            Text(t.s('famMeta'), style: estilo(Tipo.subtitulo)),
            _meta(t.s('famMetaUteis'), _r.metaMin, (v) => setState(() => _r = _r.copia(metaMin: v))),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.s('famMetaFds'), style: estilo(Tipo.corpoForte)),
              subtitle: Text(fdsIgual ? t.s('famMetaFdsIgual') : widget.app.fmt(_r.metaFdsMin!)),
              value: !fdsIgual,
              onChanged: (v) => setState(() => _r = _r.copia(metaFdsMin: () => v ? _r.metaMin : null)),
            ),
            if (!fdsIgual) _meta(t.s('famMetaFds'), _r.metaFdsMin!, (v) => setState(() => _r = _r.copia(metaFdsMin: () => v))),
            const Divider(height: Espaco.xl),
            Row(children: [
              Expanded(child: Text(t.s('famHorarios'), style: estilo(Tipo.subtitulo))),
              if (_r.horariosSemTela.length < 8)
                TextButton.icon(
                  onPressed: () => _editaHorario(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(t.s('famHorarioNovo')),
                ),
            ]),
            if (_r.horariosSemTela.isEmpty)
              Text(t.s('famSemHorarios'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            for (var i = 0; i < _r.horariosSemTela.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bedtime_outlined),
                title: Text(_r.horariosSemTela[i].nome ?? '${_r.horariosSemTela[i].inicio}–${_r.horariosSemTela[i].fim}'),
                subtitle: Text([
                  '${_r.horariosSemTela[i].inicio}–${_r.horariosSemTela[i].fim}',
                  dias(_r.horariosSemTela[i].dias),
                ].where((x) => x.isNotEmpty).join(' · ')),
                onTap: () => _editaHorario(i),
                trailing: IconButton(
                  tooltip: t.s('famRemoverHorario'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _r = _r.copia(horariosSemTela: [..._r.horariosSemTela]..removeAt(i))),
                ),
              ),
            const Divider(height: Espaco.xl),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.s('famPausar'), style: estilo(Tipo.corpoForte)),
              subtitle: Text(t.s('famPausarSub')),
              value: _r.pausarAoEstourar,
              onChanged: (v) => setState(() => _r = _r.copia(pausarAoEstourar: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.s('famFiltro'), style: estilo(Tipo.corpoForte)),
              subtitle: Text(t.s('famFiltroSub')),
              value: _r.filtroSites,
              onChanged: (v) => setState(() => _r = _r.copia(filtroSites: v)),
            ),
            const Divider(height: Espaco.xl),
            Text(t.s('famAvisosT'), style: estilo(Tipo.subtitulo)),
            for (final a in const [
              ('meta_75', 'famAvMeta75'),
              ('meta_batida', 'famAvMetaBatida'),
              ('meta_passou', 'famAvMetaPassou'),
              ('autorizacao', 'famAvAutorizacao'),
              ('regras', 'famAvRegras'),
              ('lugares', 'famAvisoLugares'),
            ])
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.s(a.$2)),
                value: _r.avisos[a.$1] ?? true,
                onChanged: (v) => setState(() => _r = _r.copia(avisos: {..._r.avisos, a.$1: v ?? false})),
              ),
            if (_erro != null) Text(_erro!, style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
            const SizedBox(height: Espaco.md),
            BotaoBaru(key: const Key('familia-salvar'), rotulo: t.s('famSalvar'), ativo: !_salvando, aoTocar: _salva),
            const SizedBox(height: Espaco.xs),
            TextButton(onPressed: _salvando ? null : _remove, child: Text(t.s('famRemover'), style: const TextStyle(color: Cores.alerta))),
          ],
        ),
      ),
    );
  }
}

/// Um horário sem tela: nome, dias e de/até.
class _DialogoDeHorario extends StatefulWidget {
  const _DialogoDeHorario({required this.t, this.inicial});

  final T t;
  final HorarioSemTela? inicial;

  @override
  State<_DialogoDeHorario> createState() => _DialogoDeHorarioState();
}

class _DialogoDeHorarioState extends State<_DialogoDeHorario> {
  late final _nome = TextEditingController(text: widget.inicial?.nome ?? '');
  late final Set<int> _dias = {...(widget.inicial?.dias ?? const [1, 2, 3, 4, 5])};
  late String _inicio = widget.inicial?.inicio ?? '21:00';
  late String _fim = widget.inicial?.fim ?? '07:00';

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _hora(bool inicio) async {
    final atual = (inicio ? _inicio : _fim).split(':');
    final r = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(atual[0]), minute: int.parse(atual[1])),
    );
    if (r == null) return;
    final v = '${r.hour.toString().padLeft(2, '0')}:${r.minute.toString().padLeft(2, '0')}';
    setState(() => inicio ? _inicio = v : _fim = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final letras = t.s('famDiasCurtos').split(',');
    return AlertDialog(
      title: Text(t.s('famHorarioNovo')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            controller: _nome,
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: t.s('famHorarioNome'), counterText: ''),
          ),
          const SizedBox(height: Espaco.sm),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _hora(true), child: Text('${t.s('famHorarioDe')} $_inicio'))),
            const SizedBox(width: Espaco.xs),
            Expanded(child: OutlinedButton(onPressed: () => _hora(false), child: Text('${t.s('famHorarioAte')} $_fim'))),
          ]),
          const SizedBox(height: Espaco.sm),
          Text(t.s('famHorarioDias'), style: estilo(Tipo.rotulo)),
          const SizedBox(height: Espaco.xxs),
          Wrap(spacing: 4, runSpacing: 4, children: [
            for (var d = 1; d <= 7; d++)
              FilterChip(
                label: Text(letras[d - 1]),
                selected: _dias.contains(d),
                onSelected: (v) => setState(() => v ? _dias.add(d) : _dias.remove(d)),
              ),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.s('famCancelar'))),
        TextButton(
          onPressed: _dias.isEmpty || _inicio == _fim
              ? null
              : () => Navigator.pop(
                    context,
                    HorarioSemTela(
                      nome: _nome.text.trim().isEmpty ? null : _nome.text.trim(),
                      dias: (_dias.toList()..sort()),
                      inicio: _inicio,
                      fim: _fim,
                    ),
                  ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _DialogoDoApelido extends StatefulWidget {
  const _DialogoDoApelido({required this.t});

  final T t;

  @override
  State<_DialogoDoApelido> createState() => _DialogoDoApelidoState();
}

class _DialogoDoApelidoState extends State<_DialogoDoApelido> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      title: Text(t.s('famAddCrianca')),
      content: TextField(
        key: const Key('familia-apelido'),
        controller: _ctrl,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: t.s('famApelido'), counterText: ''),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.s('famCancelar'))),
        TextButton(
          key: const Key('familia-gerar'),
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(t.s('famGerarCodigo')),
        ),
      ],
    );
  }
}


/// Aviso em destaque antes de pedir a localização (política de dados da Google
/// e diretrizes da Apple): diz o que é coletado, para quê, e que a coleta
/// continua com o app fechado. Só com "Aceitar" o app pede a permissão.
Future<bool> mostraAvisoDeLocalizacao(BuildContext context, T t) async {
  garanteTextosDaFamilia();
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog.fullscreen(
      backgroundColor: Cores.canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            const Icon(Icons.location_on_rounded, size: 64, color: Cores.primariaEscura),
            const SizedBox(height: Espaco.md),
            Text(t.s('locDiscT'), textAlign: TextAlign.center, style: estilo(Tipo.titulo)),
            const SizedBox(height: Espaco.md),
            Text(t.s('locDiscCorpo'), style: estilo(Tipo.corpo)),
            const SizedBox(height: Espaco.md),
            Text(t.s('locDiscPasso'), style: estilo(Tipo.corpoForte)),
            const Spacer(),
            BotaoBaru(key: const Key('local-aviso-aceitar'), rotulo: t.s('locDiscAceitar'), aoTocar: () => Navigator.pop(ctx, true)),
            const SizedBox(height: Espaco.xs),
            TextButton(key: const Key('local-aviso-nao'), onPressed: () => Navigator.pop(ctx, false), child: Text(t.s('locDiscNao'))),
          ]),
        ),
      ),
    ),
  );
  return ok == true;
}
