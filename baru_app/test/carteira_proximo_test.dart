import 'package:baru_app/data/carteira.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// O alvo sugerido na tela de folhas é o item mais barato ainda não
/// comprado — não o primeiro do catálogo.
void main() {
  test('sugere o mais barato que falta, qualquer que seja a ordem', () {
    final s = AppState()..startCompanionship();
    addTearDown(s.dispose);
    final maisBarato =
        shopItems.reduce((a, b) => b.price < a.price ? b : a);
    expect(Carteira(s.toSnapshot()).proximoItem?.id, maisBarato.id);

    // Comprado o mais barato, o próximo é o mais barato do resto.
    s.owned = [maisBarato.id];
    final resto = shopItems.where((i) => i.id != maisBarato.id);
    final esperado = resto.reduce((a, b) => b.price < a.price ? b : a);
    expect(Carteira(s.toSnapshot()).proximoItem?.id, esperado.id);
  });

  test('loja inteira comprada: não há próximo', () {
    final s = AppState()..startCompanionship();
    addTearDown(s.dispose);
    s.owned = [for (final i in shopItems) i.id];
    expect(Carteira(s.toSnapshot()).proximoItem, isNull);
  });
}
