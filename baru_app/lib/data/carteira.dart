/// De onde vieram as folhas, e para onde foram.
///
/// O app credita folhas em quatro lugares — sessão concluída, marco da
/// trilha, missão resgatada, e o zeramento do primeiro dia — e debita num só,
/// a loja. Nenhum desses lançamentos era mostrado: o usuário via um número
/// mudar e tinha de acreditar.
///
/// **O que este arquivo não faz.** Não finge que a conta fecha. O histórico de
/// sessões guarda as últimas 80 e as compras não têm data gravada, então a
/// soma dos lançamentos pode ser menor que o saldo. Quem chama isto tem de
/// dizer "no histórico guardado", não "total".
library;

import 'app_snapshot.dart';
import 'missoes.dart';
import 'progressao.dart';
import '../models.dart';

/// Uma linha do extrato.
class LancamentoDeFolhas {
  const LancamentoDeFolhas({
    required this.valor,
    required this.origem,
    this.quando,
    this.detalhe,
  });

  /// Positivo entra, negativo sai.
  final int valor;
  final OrigemDeFolhas origem;

  /// Nulo quando o app nunca gravou a data — compras e marcos, por exemplo.
  final DateTime? quando;

  /// Identificador do que gerou o lançamento (id do item, do marco).
  final String? detalhe;

  bool get entrou => valor > 0;
}

enum OrigemDeFolhas { sessao, marco, missao, compra }

/// O extrato, montado a partir do que o snapshot realmente guarda.
class Carteira {
  const Carteira(this.snapshot);

  final AppSnapshot snapshot;

  /// Sessões que renderam folhas, da mais recente para a mais antiga.
  List<LancamentoDeFolhas> get ganhosDeSessao {
    final lista = snapshot.sessions
        .where((s) => s.completed && s.reward > 0)
        .map(
          (s) => LancamentoDeFolhas(
            valor: s.reward,
            origem: OrigemDeFolhas.sessao,
            quando: s.at,
            detalhe: '${s.dur}',
          ),
        )
        .toList();
    lista.sort((a, b) => b.quando!.compareTo(a.quando!));
    return lista;
  }

  /// Marcos já resgatados que pagaram folhas. Sem data: o app nunca gravou
  /// **quando** um marco foi alcançado, só que foi.
  List<LancamentoDeFolhas> get ganhosDeMarco {
    final resgatados = snapshot.marcosResgatados.toSet();
    return trilha
        .where((m) => resgatados.contains(m.id) && m.recompensa.folhas > 0)
        .map(
          (m) => LancamentoDeFolhas(
            valor: m.recompensa.folhas,
            origem: OrigemDeFolhas.marco,
            detalhe: m.id,
          ),
        )
        .toList();
  }

  /// Missões resgatadas. A chave guardada é `id@periodo`; o valor vem da
  /// definição, que é fixa.
  List<LancamentoDeFolhas> get ganhosDeMissao {
    final defs = {
      for (final d in [...poolDiario, ...poolSemanal]) d.id: d,
    };
    final saida = <LancamentoDeFolhas>[];
    for (final chave in snapshot.missoesResgatadas) {
      final id = chave.split('@').first;
      final d = defs[id];
      if (d == null || d.folhas <= 0) continue;
      saida.add(
        LancamentoDeFolhas(
          valor: d.folhas,
          origem: OrigemDeFolhas.missao,
          detalhe: id,
        ),
      );
    }
    return saida;
  }

  /// Itens comprados. Sem data: `owned` guarda só o id.
  List<LancamentoDeFolhas> get gastos {
    final precos = {for (final i in shopItems) i.id: i.price};
    return snapshot.owned
        .where(precos.containsKey)
        .map(
          (id) => LancamentoDeFolhas(
            valor: -precos[id]!,
            origem: OrigemDeFolhas.compra,
            detalhe: id,
          ),
        )
        .toList();
  }

  int _soma(List<LancamentoDeFolhas> l) =>
      l.fold(0, (a, b) => a + b.valor.abs());

  int get totalDeSessoes => _soma(ganhosDeSessao);
  int get totalDeMarcos => _soma(ganhosDeMarco);
  int get totalDeMissoes => _soma(ganhosDeMissao);
  int get totalGasto => _soma(gastos);

  bool get vazia =>
      totalDeSessoes == 0 &&
      totalDeMarcos == 0 &&
      totalDeMissoes == 0 &&
      totalGasto == 0;

  /// O item mais barato que ainda não foi comprado — o alvo natural do saldo.
  ShopItemDef? get proximoItem {
    for (final i in shopItems) {
      if (!snapshot.owned.contains(i.id)) return i;
    }
    return null;
  }
}
