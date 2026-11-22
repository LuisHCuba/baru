import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cobranca.dart';
import '../l10n.dart';
import '../l10n_assinatura.dart';
import '../data/familia.dart';
import '../services/compra_loja.dart';
import '../theme.dart';
import '../widgets/botao_baru.dart';
import '../widgets/componentes.dart';
import '../widgets/legal_sheet.dart';

/// Assinatura do Baru pela loja do celular: uma assinatura só, mensal.
///
/// Regras das lojas seguidas aqui:
/// - Google Play (Pagamentos) e App Store (3.1.1): só a compra da loja, nada
///   de site, Pix ou boleto no app.
/// - Preço vindo da loja, renovação automática explicada, termos e
///   privacidade a um toque, restaurar e gerenciar a assinatura.
///
/// Não depende do AppScope: abre também da tela de fim do teste.
class AssinaturaScreen extends StatefulWidget {
  const AssinaturaScreen({super.key, required this.t, required this.aoLiberado, this.aoVoltar});

  final T t;

  /// O servidor confirmou a compra: quem abriu a tela confere o acesso.
  final VoidCallback aoLiberado;
  final VoidCallback? aoVoltar;

  static const chaveAssinar = Key('assinatura-assinar');

  @override
  State<AssinaturaScreen> createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends State<AssinaturaScreen> {
  Map<PlanoDaLoja, ProductDetails> _planos = const {};
  PlanoDaLoja _escolhido = PlanoDaLoja.anual;
  bool _carregando = true;
  bool _ocupado = false;
  StreamSubscription<AvisoDaLoja>? _avisos;

  /// Laços que eu administro (o plano família cobre um deles).
  List<Familia> _meusLacos = const [];
  String? _laco;

  T get t => widget.t;
  ProductDetails? get _produto => _planos[_escolhido];

  String get _nomeDoLaco => _meusLacos.isEmpty ? '' : _meusLacos.firstWhere((l) => l.id == _laco, orElse: () => _meusLacos.first).nome;

  @override
  void initState() {
    super.initState();
    garanteTextosDaAssinatura();
    CompraLoja.instancia.iniciar();
    _avisos = CompraLoja.instancia.avisos.listen(_aviso);
    _carrega();
  }

  @override
  void dispose() {
    _avisos?.cancel();
    super.dispose();
  }

  Future<void> _carrega() async {
    var planos = const <PlanoDaLoja, ProductDetails>{};
    try {
      planos = await CompraLoja.instancia.planosDaLoja();
    } catch (_) {}
    var lacos = const <Familia>[];
    try {
      final m = await FamiliaRepo(Supabase.instance.client).minha();
      lacos = m.familias.where((f) => f.souAdmin).toList();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _planos = planos;
      _meusLacos = lacos;
      _laco = lacos.isEmpty ? null : lacos.first.id;
      if (!planos.containsKey(_escolhido)) _escolhido = planos.keys.firstOrNull ?? PlanoDaLoja.mensal;
      _carregando = false;
    });
  }

  void _aviso(AvisoDaLoja a) {
    if (!mounted) return;
    final m = ScaffoldMessenger.maybeOf(context);
    switch (a.etapa) {
      case EtapaDaLoja.comprando:
      case EtapaDaLoja.conferindo:
        setState(() => _ocupado = true);
      case EtapaDaLoja.cancelada:
        setState(() => _ocupado = false);
      case EtapaDaLoja.pronto:
        setState(() => _ocupado = false);
        m?.showSnackBar(SnackBar(content: Text(t.s('assPronto'))));
        widget.aoLiberado();
      case EtapaDaLoja.falhou:
        setState(() => _ocupado = false);
        m?.showSnackBar(SnackBar(content: Text(a.mensagem ?? t.s('assFalhou'))));
      case EtapaDaLoja.semConexao:
        setState(() => _ocupado = false);
        m?.showSnackBar(SnackBar(content: Text(t.s('assSemConexao'))));
    }
  }

  Future<void> _assinar() async {
    final p = _produto;
    if (p == null) return;
    if (_escolhido.ehFamilia && _laco == null) return;
    setState(() => _ocupado = true);
    try {
      await CompraLoja.instancia.assinar(p, laco: _escolhido.ehFamilia ? _laco : null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.s('assFalhou'))));
    }
  }

  Future<void> _restaurar() async {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.s('assProcurando'))));
    try {
      await CompraLoja.instancia.restaurar();
    } catch (_) {}
  }

  void _gerenciar() {
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions?sku=${CompraLoja.produto}&package=tech.lhcx.baru';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final p = _produto;
    final apple = defaultTargetPlatform == TargetPlatform.iOS;
    final acesso = acessoAtual.value;
    final ativa = acesso?.pagando == true;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Espaco.lg, Espaco.sm, Espaco.lg, Espaco.xl),
          children: [
            if (widget.aoVoltar != null)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(onPressed: widget.aoVoltar, icon: const Icon(Icons.close_rounded)),
              ),
            const SizedBox(height: Espaco.sm),
            Text(t.s('assT'), style: estilo(Tipo.display)),
            const SizedBox(height: Espaco.xxs),
            Text(t.s('assSub'), style: estilo(Tipo.corpo, color: Cores.tinta700)),
            const SizedBox(height: Espaco.lg),
            CartaoBaru(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final b in ['assB1', 'assB2', 'assB3'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: Espaco.xs),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_rounded, size: 20, color: Cores.primariaEscura),
                      const SizedBox(width: Espaco.xs),
                      Expanded(child: Text(t.s(b), style: estilo(Tipo.corpo))),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: Espaco.md),
            if (_carregando)
              const Center(child: Padding(padding: EdgeInsets.all(Espaco.sm), child: CircularProgressIndicator()))
            else if (_planos.isEmpty)
              Text(t.s('assIndisponivel'), style: estilo(Tipo.corpoPequeno, color: Cores.alerta))
            else
              for (final plano in PlanoDaLoja.values)
                if (_planos[plano] case final pp?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Espaco.sm),
                    child: _CartaoDoPlano(
                      chave: Key('plano-${plano.name}'),
                      titulo: t.s(switch (plano) {
                        PlanoDaLoja.mensal => 'assPlanoMensal',
                        PlanoDaLoja.anual => 'assPlanoAnual',
                        PlanoDaLoja.familia => 'assPlanoFamilia',
                        PlanoDaLoja.familiaAnual => 'assPlanoFamiliaAnual',
                        PlanoDaLoja.familiaMais => 'assPlanoFamiliaMais',
                      }),
                      preco: plano.ehAnual ? t.fill(t.s('assPorAno'), {'p': pp.price}) : t.fill(t.s('assPorMes'), {'p': pp.price}),
                      nota: switch (plano) {
                        PlanoDaLoja.mensal => t.s('assPlanoMensalNota'),
                        PlanoDaLoja.anual => t.fill(t.s('assPlanoAnualNota'), {'p': '${pp.currencySymbol} ${(pp.rawPrice / 12).toStringAsFixed(2).replaceAll('.', ',')}'}),
                        _ when _meusLacos.isEmpty => t.s('assFamiliaSemLaco'),
                        PlanoDaLoja.familia || PlanoDaLoja.familiaAnual => t.fill(t.s('assPlanoFamiliaNota'), {'l': _nomeDoLaco}),
                        PlanoDaLoja.familiaMais => t.fill(t.s('assPlanoFamiliaMaisNota'), {'l': _nomeDoLaco}),
                      },
                      destaque: plano == PlanoDaLoja.anual,
                      escolhido: plano == _escolhido,
                      ativo: !plano.ehFamilia || _meusLacos.isNotEmpty,
                      aoTocar: () => setState(() => _escolhido = plano),
                    ),
                  ),
            if (_escolhido.ehFamilia && _meusLacos.length > 1)
              Wrap(spacing: Espaco.xs, children: [
                for (final l in _meusLacos)
                  ChoiceChip(label: Text(l.nome), selected: l.id == _laco, onSelected: (_) => setState(() => _laco = l.id)),
              ]),
            const SizedBox(height: Espaco.md),
            if (ativa)
              Text(t.fill(t.s('assAtiva'), {'d': t.formatLongDate(acesso!.pagoAte)}),
                  style: estilo(Tipo.corpoForte, color: Cores.primariaEscura))
            else
              BotaoBaru(
                key: AssinaturaScreen.chaveAssinar,
                rotulo: p == null ? t.s('assT') : t.fill(t.s(_escolhido.ehAnual ? 'assBotaoAno' : 'assBotao'), {'p': p.price}),
                ativo: p != null && !_ocupado && (!_escolhido.ehFamilia || _laco != null),
                aoTocar: _assinar,
              ),
            if (_ocupado)
              Padding(
                padding: const EdgeInsets.only(top: Espaco.sm),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: Espaco.xs),
                  Text(t.s('assConferindo'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                ]),
              ),
            const SizedBox(height: Espaco.md),
            Text(t.s(apple ? 'assRenovaApple' : 'assRenovaGoogle'),
                style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            const SizedBox(height: Espaco.sm),
            Wrap(alignment: WrapAlignment.center, spacing: Espaco.xs, children: [
              TextButton(onPressed: _ocupado ? null : _restaurar, child: Text(t.s('assRestaurar'))),
              TextButton(onPressed: _gerenciar, child: Text(t.s('assGerenciar'))),
              TextButton(
                onPressed: () => showLegalSheet(context, title: t.setTerms, body: t.termsBody, close: t.shareDone),
                child: Text(t.s('assTermos')),
              ),
              TextButton(
                onPressed: () => showLegalSheet(context, title: t.setPrivacy, body: t.privacyBody, close: t.shareDone),
                child: Text(t.s('assPrivacidade')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Um plano para escolher: nome, preço e uma linha de explicação.
class _CartaoDoPlano extends StatelessWidget {
  const _CartaoDoPlano({
    required this.chave,
    required this.titulo,
    required this.preco,
    required this.nota,
    required this.escolhido,
    required this.aoTocar,
    this.destaque = false,
    this.ativo = true,
  });
  final Key chave;
  final String titulo;
  final String preco;
  final String nota;
  final bool escolhido;
  final bool destaque;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: ativo ? 1 : 0.55,
        child: Material(
          key: chave,
          color: escolhido ? Cores.primariaA(0.10) : Cores.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Raio.cartao),
            side: BorderSide(color: escolhido ? Cores.primariaEscura : Cores.trilho, width: escolhido ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Raio.cartao),
            onTap: ativo ? aoTocar : null,
            child: Padding(
              padding: const EdgeInsets.all(Espaco.md),
              child: Row(children: [
                Icon(escolhido ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: escolhido ? Cores.primariaEscura : Cores.tinta500),
                const SizedBox(width: Espaco.sm),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(titulo, style: estilo(Tipo.subtitulo)),
                      if (destaque) ...[
                        const SizedBox(width: Espaco.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Cores.primariaEscura, borderRadius: BorderRadius.circular(6)),
                          child: Text('-33%', style: estilo(Tipo.rotuloPequeno, color: Colors.white)),
                        ),
                      ],
                    ]),
                    Text(preco, style: estilo(Tipo.corpoForte)),
                    Text(nota, style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}
