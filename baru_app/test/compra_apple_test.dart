import 'package:baru_app/services/compra_loja.dart';
import 'package:flutter_test/flutter_test.dart';

/// Diretriz 3.1.1 da Apple: todo plano vendido fora do app também está à
/// venda no iPhone pela compra dentro do app.
void main() {
  test('cada plano tem um produto da Apple, e só um', () {
    final planos = CompraLoja.produtosApple.values.toList();
    expect(planos.toSet(), PlanoDaLoja.values.toSet());
    expect(planos.length, PlanoDaLoja.values.length);
  });

  test('os produtos de família da Apple contam como família', () {
    expect(CompraLoja.ehFamilia('tech.lhcx.baru.familia.mensal'), isTrue);
    expect(CompraLoja.ehFamilia('tech.lhcx.baru.familia.anual'), isTrue);
    expect(CompraLoja.ehFamilia('tech.lhcx.baru.familiamais.mensal'), isTrue);
    expect(CompraLoja.ehFamilia('tech.lhcx.baru.mensal'), isFalse);
    expect(CompraLoja.ehFamilia('tech.lhcx.baru.anual'), isFalse);
  });

  test('os ids seguem o arquivo de teste local e o servidor', () {
    expect(CompraLoja.produtosApple.keys, everyElement(startsWith('tech.lhcx.baru.')));
  });
}
