import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cobranca.dart';
import '../l10n.dart';
import '../l10n_assinatura.dart';
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
  ProductDetails? _produto;
  bool _carregando = true;
  bool _ocupado = false;
  StreamSubscription<AvisoDaLoja>? _avisos;

  T get t => widget.t;

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
    ProductDetails? p;
    try {
      p = await CompraLoja.instancia.produtoDaLoja();
    } catch (_) {}
    if (mounted) setState(() => (_produto = p, _carregando = false));
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
    setState(() => _ocupado = true);
    try {
      await CompraLoja.instancia.assinar(p);
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
                const Divider(height: Espaco.lg),
                if (_carregando)
                  const Center(child: Padding(padding: EdgeInsets.all(Espaco.sm), child: CircularProgressIndicator()))
                else if (p == null)
                  Text(t.s('assIndisponivel'), style: estilo(Tipo.corpoPequeno, color: Cores.alerta))
                else
                  Text(t.fill(t.s('assPorMes'), {'p': p.price}), style: estilo(Tipo.titulo)),
              ]),
            ),
            const SizedBox(height: Espaco.md),
            if (ativa)
              Text(t.fill(t.s('assAtiva'), {'d': t.formatLongDate(acesso!.pagoAte)}),
                  style: estilo(Tipo.corpoForte, color: Cores.primariaEscura))
            else
              BotaoBaru(
                key: AssinaturaScreen.chaveAssinar,
                rotulo: p == null ? t.s('assT') : t.fill(t.s('assBotao'), {'p': p.price}),
                ativo: p != null && !_ocupado,
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
