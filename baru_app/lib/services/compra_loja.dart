import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Assinatura do Baru comprada na loja do celular (Google Play no Android,
/// App Store no iPhone). Uma assinatura só, mensal, R$ 14,90.
///
/// A conta do Baru vai junto na compra (Android: obfuscatedAccountId; iPhone:
/// appAccountToken). O servidor (`loja-assinatura`) confere com a loja, e só
/// depois disso a compra é concluída aqui: se a rede cair, a loja entrega de
/// novo na próxima abertura.
class CompraLoja {
  CompraLoja._();
  static final instancia = CompraLoja._();

  /// Id do produto em cada loja.
  static String get produto =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'tech.lhcx.baru.mensal' : 'baru_assinatura';

  /// Plano família (Google Play). No iPhone ainda não existe.
  static const produtoFamilia = 'baru_familia';

  /// Laço do plano família sendo comprado (vai junto para o servidor).
  String? _lacoPendente;

  /// Os planos que a loja oferece agora: individual mensal, individual anual
  /// e família. No Android cada plano base vem como um ProductDetails próprio.
  Future<Map<PlanoDaLoja, ProductDetails>> planosDaLoja() async {
    if (!temLoja || !await _loja.isAvailable()) return const {};
    final ids = defaultTargetPlatform == TargetPlatform.iOS ? {produto} : {produto, produtoFamilia};
    final r = await _loja.queryProductDetails(ids);
    final out = <PlanoDaLoja, ProductDetails>{};
    for (final p in r.productDetails) {
      if (p is GooglePlayProductDetails) {
        final i = p.subscriptionIndex;
        final ofertas = p.productDetails.subscriptionOfferDetails;
        if (i == null || ofertas == null) continue;
        final oferta = ofertas[i];
        // Só o plano base (sem oferta de desconto por cima).
        if (oferta.offerId != null) continue;
        switch (oferta.basePlanId) {
          case 'mensal':
            out[PlanoDaLoja.mensal] = p;
          case 'anual':
            out[PlanoDaLoja.anual] = p;
          case 'familia-mensal':
            out[PlanoDaLoja.familia] = p;
        }
      } else if (p.id == produto) {
        out[PlanoDaLoja.mensal] = p;
      }
    }
    return out;
  }

  static String get loja => defaultTargetPlatform == TargetPlatform.iOS ? 'apple' : 'google';

  /// Na web não há loja: lá a assinatura é pelo site.
  static bool get temLoja =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  final _loja = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _ouvinte;
  final _avisos = StreamController<AvisoDaLoja>.broadcast();

  Stream<AvisoDaLoja> get avisos => _avisos.stream;

  /// Chamado ao abrir o app: compras pendentes e renovações chegam por aqui.
  void iniciar() {
    if (!temLoja) return;
    _ouvinte ??= _loja.purchaseStream.listen(_trata, onError: (Object e) => debugPrint('loja: $e'));
  }

  Future<ProductDetails?> produtoDaLoja() async {
    if (!temLoja || !await _loja.isAvailable()) return null;
    final r = await _loja.queryProductDetails({produto});
    return r.productDetails.isEmpty ? null : r.productDetails.first;
  }

  Future<void> assinar(ProductDetails p, {String? laco}) async {
    final conta = Supabase.instance.client.auth.currentUser?.id;
    if (conta == null) throw StateError('sem_sessao');
    _lacoPendente = laco;
    _avisos.add(const AvisoDaLoja(EtapaDaLoja.comprando));
    await _loja.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p, applicationUserName: conta));
  }

  Future<void> restaurar() => _loja.restorePurchases();

  Future<void> _trata(List<PurchaseDetails> compras) async {
    for (final c in compras) {
      switch (c.status) {
        case PurchaseStatus.pending:
          _avisos.add(const AvisoDaLoja(EtapaDaLoja.comprando));
        case PurchaseStatus.canceled:
          _avisos.add(const AvisoDaLoja(EtapaDaLoja.cancelada));
          if (c.pendingCompletePurchase) await _loja.completePurchase(c);
        case PurchaseStatus.error:
          _avisos.add(const AvisoDaLoja(EtapaDaLoja.falhou));
          if (c.pendingCompletePurchase) await _loja.completePurchase(c);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _registra(c);
      }
    }
  }

  Future<void> _registra(PurchaseDetails c) async {
    final db = Supabase.instance.client;
    if (db.auth.currentUser == null) return;
    _avisos.add(const AvisoDaLoja(EtapaDaLoja.conferindo));
    try {
      await db.functions.invoke('loja-assinatura', body: {
        'loja': loja,
        'produto': c.productID,
        'token': c.verificationData.serverVerificationData,
        if (c.productID == produtoFamilia && _lacoPendente != null) 'laco': _lacoPendente,
      });
      if (c.pendingCompletePurchase) await _loja.completePurchase(c);
      _avisos.add(const AvisoDaLoja(EtapaDaLoja.pronto));
    } on FunctionException catch (e) {
      final msg = e.details is Map ? (e.details as Map)['message'] as String? : null;
      // Recusa definitiva (de outra conta, inválida): conclui para não voltar.
      if (e.status == 400 || e.status == 409) {
        if (c.pendingCompletePurchase) await _loja.completePurchase(c);
      }
      _avisos.add(AvisoDaLoja(EtapaDaLoja.falhou, msg));
    } catch (_) {
      _avisos.add(const AvisoDaLoja(EtapaDaLoja.semConexao));
    }
  }
}

/// Os planos à venda: um preço só por plano em todo lugar.
enum PlanoDaLoja { mensal, anual, familia }

enum EtapaDaLoja { comprando, conferindo, pronto, cancelada, falhou, semConexao }

class AvisoDaLoja {
  const AvisoDaLoja(this.etapa, [this.mensagem]);
  final EtapaDaLoja etapa;
  final String? mensagem;
}
