import 'package:baru_app/cobranca.dart';
import 'package:baru_app/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

/// O prazo do teste e como ele aparece.
///
/// A regra é do servidor, mas a conta de dias é do app — e era justamente ela
/// que não existia: `acessoLiberado()` devolvia um booleano e descartava o
/// `testeAte`, então nenhuma tela tinha o que mostrar.
void main() {
  final hoje = DateTime(2026, 11, 2, 15, 30);

  MeuAcesso comTeste(DateTime ate) =>
      MeuAcesso(liberado: true, testeAte: ate);

  group('dias de teste', () {
    test('sete dias à frente são sete dias, não seis e meio', () {
      expect(comTeste(DateTime(2026, 11, 9, 2)).diasDeTeste(hoje), 7);
    });

    test('vence hoje, em qualquer hora do dia, é zero', () {
      expect(comTeste(DateTime(2026, 11, 2, 0, 1)).diasDeTeste(hoje), 0);
      expect(comTeste(DateTime(2026, 11, 2, 23, 59)).diasDeTeste(hoje), 0);
    });

    test('venceu ontem não devolve negativo', () {
      expect(comTeste(DateTime(2026, 11, 1)).diasDeTeste(hoje), 0);
    });

    test('sem prazo é -1: não há contagem para anunciar', () {
      expect(const MeuAcesso(liberado: true).diasDeTeste(hoje), -1);
      expect(const MeuAcesso(liberado: true).noTeste, isFalse);
    });

    test('a hora não muda a contagem', () {
      final ate = DateTime(2026, 11, 5, 8);
      expect(comTeste(ate).diasDeTeste(DateTime(2026, 11, 2, 0, 1)), 3);
      expect(comTeste(ate).diasDeTeste(DateTime(2026, 11, 2, 23, 59)), 3);
    });
  });

  group('pagante', () {
    test('pago até hoje ainda vale', () {
      final a = MeuAcesso(liberado: true, pagoAte: DateTime.now());
      expect(a.pagando, isTrue);
      expect(a.noTeste, isFalse, reason: 'quem paga não está em teste');
    });

    test('pago até ontem não vale', () {
      final ontem = DateTime.now().subtract(const Duration(days: 1));
      expect(MeuAcesso(liberado: true, pagoAte: ontem).pagando, isFalse);
    });

    test('sem data de pagamento não é pagante', () {
      expect(const MeuAcesso(liberado: true).pagando, isFalse);
    });
  });

  group('resposta do servidor', () {
    test('o mapa do rpc vira acesso', () {
      final a = MeuAcesso.doMapa({
        'liberado': true,
        'testeAte': '2026-11-09T12:00:00+00:00',
        'pagoAte': null,
        'status': 'pendente',
        'plano': 'monthly',
      });
      expect(a.liberado, isTrue);
      expect(a.testeAte, isNotNull);
      expect(a.pagoAte, isNull);
      expect(a.status, 'pendente');
      expect(a.noTeste, isTrue);
    });

    test('liberado ausente conta como liberado, não como barrado', () {
      expect(MeuAcesso.doMapa(const {}).liberado, isTrue);
      expect(MeuAcesso.doMapa(const {'liberado': false}).liberado, isFalse);
    });
  });

  group('textos do acesso', () {
    const chaves = [
      'acessoTesteT',
      'acessoTesteHojeT',
      'acessoTesteB',
      'acessoPagoT',
      'acessoPagoB',
      'acessoSemT',
      'acessoSemB',
      'acessoSite',
      'acessoFaixa',
      'acessoFaixaHoje',
    ];

    for (final lang in ['pt', 'en', 'es', 'zh']) {
      test('$lang tem todas as chaves, sem preço e sem chave à vista', () {
        final t = T(lang);
        for (final k in chaves) {
          final v = t.s(k);
          expect(v, isNotEmpty, reason: '$lang/$k vazio');
          expect(v, isNot(contains(k)), reason: '$lang/$k caiu no próprio id');
          // O app não mostra preço: quem vende é o site. Preço dentro do app
          // é o que tira o app da loja.
          expect(v, isNot(contains(r'R$')), reason: '$lang/$k tem preço');
        }
      });
    }

    test('a contagem substitui o {n}', () {
      final t = T('pt');
      final frase = t.fill(t.acessoTesteT, {'n': 3});
      expect(frase, contains('3'));
      expect(frase, isNot(contains('{n}')));
    });
  });
}
