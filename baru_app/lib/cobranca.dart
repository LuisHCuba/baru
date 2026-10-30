import 'package:flutter/foundation.dart';

/// Compra dentro do app.
///
/// As assinaturas ficam no Asaas e a compra acontece no site. Por isso o app
/// não mostra o paywall, o preço nem "Restaurar compras": quem decide o acesso
/// é o servidor (`baru_meu_acesso`), e o app só leva a pessoa ao site.
const cobrancaNaLoja = false;

/// Página inicial do site do Baru: é de lá que a pessoa chega à assinatura.
const siteDoBaru = 'https://baru.lhcx.tech/';

/// O que o servidor respondeu sobre o acesso desta conta.
///
/// O app guardava só o booleano `liberado` e jogava o resto fora — por isso
/// ninguém via quantos dias de teste faltavam. O prazo é do servidor de
/// propósito: `baru_cobranca.ligada_em` e a data de criação da conta vivem lá,
/// e relógio de aparelho se muda nos ajustes.
@immutable
class MeuAcesso {
  const MeuAcesso({
    required this.liberado,
    this.testeAte,
    this.pagoAte,
    this.status,
    this.plano,
  });

  /// O que se assume quando não se conseguiu perguntar: liberado, sem prazo.
  /// Não trancar quem está usando por uma falha que não é dela.
  static const naDuvida = MeuAcesso(liberado: true);

  factory MeuAcesso.doMapa(Map<dynamic, dynamic> m) => MeuAcesso(
    liberado: m['liberado'] != false,
    testeAte: DateTime.tryParse('${m['testeAte']}')?.toLocal(),
    pagoAte: DateTime.tryParse('${m['pagoAte']}')?.toLocal(),
    status: m['status'] as String?,
    plano: m['plano'] as String?,
  );

  final bool liberado;

  /// Fim do teste de 7 dias. Nulo enquanto a cobrança não foi ligada — e aí
  /// não há contagem para mostrar, porque ninguém vai ser barrado.
  final DateTime? testeAte;
  final DateTime? pagoAte;
  final String? status;
  final String? plano;

  /// Assinatura paga valendo hoje.
  bool get pagando {
    final ate = pagoAte;
    if (ate == null) return false;
    final hoje = DateTime.now();
    return !DateTime(ate.year, ate.month, ate.day)
        .isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  /// Está no teste: tem prazo, o prazo não venceu e não é pagante.
  bool get noTeste => testeAte != null && !pagando && liberado;

  /// Dias inteiros que faltam do teste, contando o dia de hoje como 0 quando
  /// o prazo vence hoje. Sem prazo, -1: não há nada para dizer.
  int diasDeTeste([DateTime? agora]) {
    final ate = testeAte;
    if (ate == null) return -1;
    final hoje = agora ?? DateTime.now();
    final n = DateTime(ate.year, ate.month, ate.day)
        .difference(DateTime(hoje.year, hoje.month, hoje.day))
        .inDays;
    return n < 0 ? 0 : n;
  }
}

/// Último acesso lido do servidor, para a tela não ter de perguntar de novo.
///
/// O `AuthGate` já pergunta no arranque e a cada volta do segundo plano; isto
/// só deixa a resposta à vista de quem precisa dela.
final acessoAtual = ValueNotifier<MeuAcesso?>(null);
