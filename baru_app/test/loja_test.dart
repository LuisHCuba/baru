import 'package:baru_app/data/row_codec.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A loja do habitat.
///
/// Duas coisas mudaram e as duas têm regra: **ter deixou de ser o mesmo que
/// usar**, e há três naturezas de item com exclusões diferentes.

ShopItemDef _de(String id) => itemPorId(id)!;

AppState _rico({int folhas = 5000}) {
  final s = AppState()..startCompanionship();
  s.leaves = folhas;
  return s;
}

void main() {
  group('o catálogo', () {
    test('todo item tem nome nos quatro idiomas, e nenhum sobra', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final s = AppState()..lang = lang;
        expect(
          s.t.itemNames.length,
          shopItems.length,
          reason: 'a lista de nomes é indexada pela ordem de shopItems ($lang)',
        );
        for (final item in shopItems) {
          final nome = s.t.nomeDoItem(
            item.id,
            shopItems.map((e) => e.id).toList(),
          );
          expect(nome, isNotEmpty, reason: '${item.id}/$lang');
          expect(nome, isNot(item.id), reason: '${item.id}/$lang sem tradução');
        }
        s.dispose();
      }
    });

    test('toda roupa diz onde vai e com que cor', () {
      for (final i in shopItems) {
        if (i.categoria != CategoriaDeItem.roupa) continue;
        expect(i.vestimenta, isNotNull, reason: i.id);
        expect(i.cor, isNotNull, reason: i.id);
      }
    });

    test('todo id é único', () {
      final ids = shopItems.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('comprar e usar', () {
    test('comprar já coloca em cena: ninguém compra para deixar na gaveta', () {
      final s = _rico();
      s.buy(_de('rock'));
      expect(s.owned, contains('rock'));
      expect(s.estaEquipado('rock'), isTrue);
      s.dispose();
    });

    test('dá para tirar e colocar de volta sem gastar de novo', () {
      final s = _rico();
      s.buy(_de('rock'));
      final folhas = s.leaves;

      expect(s.alternaEquipado(_de('rock')), isFalse);
      expect(s.estaEquipado('rock'), isFalse);
      expect(s.objetosNaCena, isNot(contains('rock')));

      expect(s.alternaEquipado(_de('rock')), isTrue);
      expect(s.leaves, folhas, reason: 'tirar e pôr não custa nada');
      s.dispose();
    });

    test('não dá para equipar o que não é seu', () {
      final s = AppState()..startCompanionship();
      expect(s.alternaEquipado(_de('boat')), isFalse);
      expect(s.estaEquipado('boat'), isFalse);
      s.dispose();
    });

    test('objeto de cena não tem exclusão: pode ter todos', () {
      final s = _rico();
      for (final i in itensDeCena) {
        s.buy(i);
      }
      expect(s.objetosNaCena.length, itensDeCena.length);
      s.dispose();
    });
  });

  group('as exclusões', () {
    test('só um cenário por vez', () {
      final s = _rico();
      s.buy(_de('entardecer'));
      expect(s.cenarioAtivo?.id, 'entardecer');

      s.buy(_de('chuva'));
      expect(
        s.cenarioAtivo?.id,
        'chuva',
        reason: 'o bicho mora num mundo só',
      );
      expect(s.estaEquipado('entardecer'), isFalse);
      expect(
        s.owned,
        contains('entardecer'),
        reason: 'continua comprado; só não está em uso',
      );
      s.dispose();
    });

    test('uma peça por lugar do corpo', () {
      final s = _rico();
      s.buy(_de('chapeu_palha'));
      s.buy(_de('gorro'));
      expect(
        s.roupaEm(Vestimenta.cabeca)?.id,
        'gorro',
        reason: 'dois chapéus na mesma cabeça é bug, não estilo',
      );
      expect(s.estaEquipado('chapeu_palha'), isFalse);

      // Lugares diferentes convivem.
      s.buy(_de('cachecol'));
      s.buy(_de('oculos'));
      expect(s.roupaEm(Vestimenta.cabeca)?.id, 'gorro');
      expect(s.roupaEm(Vestimenta.pescoco)?.id, 'cachecol');
      expect(s.roupaEm(Vestimenta.rosto)?.id, 'oculos');
      expect(s.roupasDoBicho.length, 3);
      s.dispose();
    });

    test('cenário e roupa não brigam com objeto de cena', () {
      final s = _rico();
      s.buy(_de('rock'));
      s.buy(_de('chuva'));
      s.buy(_de('gorro'));
      expect(s.objetosNaCena, contains('rock'));
      expect(s.cenarioAtivo?.id, 'chuva');
      expect(s.roupaDeCabeca, 'gorro');
      s.dispose();
    });
  });

  group('o que sobrevive ao fechar o app', () {
    test('o que está em uso volta igual', () {
      final s = _rico();
      s.buy(_de('rock'));
      s.buy(_de('gorro'));
      s.alternaEquipado(_de('rock'));

      final volta = AppState(snapshot: s.toSnapshot());
      expect(volta.owned, containsAll(['rock', 'gorro']));
      expect(volta.estaEquipado('rock'), isFalse);
      expect(volta.estaEquipado('gorro'), isTrue);
      s.dispose();
      volta.dispose();
    });

    test('inventário antigo, sem "equipado", continua na cena', () {
      // Como era antes: comprado é igual a colocado.
      final antigo = AppState()..startCompanionship();
      antigo.owned = ['lily', 'rock'];
      final snap = antigo.toSnapshot().copyWith(equipados: const []);

      final volta = AppState(snapshot: snap);
      expect(
        volta.objetosNaCena,
        containsAll(['lily', 'rock']),
        reason: 'a atualização não pode esvaziar o habitat de quem já tinha',
      );
      antigo.dispose();
      volta.dispose();
    });

    test('o "em uso" faz a volta pelas linhas do remoto', () {
      final s = _rico();
      s.buy(_de('rock'));
      s.buy(_de('lily'));
      s.alternaEquipado(_de('lily'));

      const codec = BaruRowCodec();
      final linhas = codec.inventoryRows(userId: 'u', s: s.toSnapshot());
      final porId = {for (final l in linhas) l['item_id']: l['equipped']};
      expect(porId['rock'], isTrue);
      expect(porId['lily'], isFalse);

      final volta = codec.fromRows(
        profile: {'screen': 'home', 'onb': 5, 'companionship_started': true},
        inventory: linhas,
      );
      expect(volta.owned, containsAll(['rock', 'lily']));
      expect(volta.equipados, contains('rock'));
      expect(volta.equipados, isNot(contains('lily')));
      s.dispose();
    });
  });
}
