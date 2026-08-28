import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_loja.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/shop_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/habitat.dart';
import 'package:baru_app/widgets/loja_vitrine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A loja como vitrine.
///
/// O que estes testes seguram é o que quebra quando alguém acrescenta um
/// item: o objeto que não aparece em prateleira nenhuma, a peça desenhada
/// fora da cena, o cenário que a loja vende e o habitat não sabe acender, e
/// o nome que volta como id cru.

AppState _loja({int folhas = 0, List<String> tem = const []}) {
  final s = AppState()..startCompanionship();
  s.leaves = folhas;
  s.owned = List<String>.from(tem);
  s.equipados = tem.toSet();
  return s;
}

Future<void> _abre(WidgetTester tester, AppState app) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.data,
      home: Scaffold(
        backgroundColor: Cores.superficie,
        body: AppScope(state: app, child: const ShopScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('o catálogo', () {
    test('todo objeto de cena mora numa coleção', () {
      // A loja monta as prateleiras percorrendo `Colecao.values`. Objeto sem
      // coleção não cai em prateleira nenhuma: fica comprável pelo banco e
      // invisível na tela.
      for (final i in itensDeCena) {
        expect(i.colecao, isNotNull, reason: '${i.id} não tem prateleira');
      }
      final emPrateleiras = {
        for (final c in Colecao.values) ...itensDaColecao(c).map((i) => i.id),
      };
      expect(
        emPrateleiras.length,
        itensDeCena.length,
        reason: 'todo objeto tem de aparecer em exatamente uma prateleira',
      );
    });

    test('roupa e cenário não têm coleção — a seção deles já é a prateleira',
        () {
      for (final i in shopItems) {
        if (i.categoria == CategoriaDeItem.objeto) continue;
        expect(i.colecao, isNull, reason: i.id);
      }
    });

    test('nenhuma peça é desenhada fora da cena', () {
      // Peça fora de 372×296 é item comprado e invisível — o pior defeito
      // possível numa loja.
      for (final item in itensDeCena) {
        expect(item.parts, isNotEmpty, reason: '${item.id} não desenha nada');
        for (final p in item.parts) {
          expect(p.x, greaterThanOrEqualTo(0), reason: item.id);
          expect(p.y, greaterThanOrEqualTo(0), reason: item.id);
          expect(p.x + p.w, lessThanOrEqualTo(372), reason: item.id);
          expect(p.y + p.h, lessThanOrEqualTo(296), reason: item.id);
        }
      }
    });

    test('os atalhos de habitat só citam objeto que existe', () {
      // `habitats` alimenta o painel de depuração e a captura de evidência.
      // Um id escrito errado ali não estoura: some da cena em silêncio.
      final objetos = itensDeCena.map((i) => i.id).toSet();
      for (final entrada in habitats.entries) {
        for (final id in entrada.value) {
          expect(
            objetos,
            contains(id),
            reason: '${entrada.key} cita "$id", que não é objeto de cena',
          );
        }
      }
      expect(
        habitats['full']!.length,
        itensDeCena.length,
        reason: '"cheio" tem de querer dizer o catálogo inteiro',
      );
    });

    test('todo cenário da loja sabe acender o habitat', () {
      // Cenário é a única categoria que não se desenha sozinha: quem pinta a
      // luz dele é `LuzDaCena.doCenario`, por id. Um cenário novo no
      // catálogo sem entrada lá é um item que a pessoa compra e que não muda
      // nada na cena.
      for (final i in itensDaCategoria(CategoriaDeItem.cenario)) {
        expect(
          LuzDaCena.doCenario(i.id),
          isNotNull,
          reason: '${i.id} não tem luz em habitat.dart',
        );
      }
    });
  });

  group('o nome do item', () {
    test('item novo tem nome por id nos quatro idiomas', () {
      garanteTextosDaLoja();
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final t = T(lang);
        expect(t.nomeDoItemDaLoja('cerejeira'), isNot('cerejeira'));
        expect(t.nomeDoItemDaLoja('vagalumes'), isNot('vagalumes'));
      }
    });

    test('a lista posicional do catálogo principal não alcança os novos', () {
      // A regressão que já aconteceu: nome resolvido pela **posição** em
      // `shopItems`. Com a loja maior que a lista de nomes, o item novo volta
      // como id cru — e é por isso que ele resolve por id.
      final t = T('pt');
      final posicional = t.nomeDoItem(
        'cerejeira',
        shopItems.map((e) => e.id).toList(),
      );
      expect(
        posicional,
        'cerejeira',
        reason: 'a posicional devolve o id cru, sem estourar',
      );
      garanteTextosDaLoja();
      expect(t.nomeDoItemDaLoja('cerejeira'), 'Cerejeira');
    });

    test('item antigo continua saindo do catálogo principal', () {
      garanteTextosDaLoja();
      expect(T('pt').nomeDoItemDaLoja('lily'), 'Vitórias-régias');
      expect(T('en').nomeDoItemDaLoja('lily'), 'Water lilies');
    });
  });

  group('os textos da loja', () {
    const base = 'pt';
    final pt = textosDaLoja[base]!;

    test('os quatro idiomas do contrato existem', () {
      expect(textosDaLoja.keys.toSet(), {'pt', 'en', 'es', 'zh'});
    });

    for (final lang in ['en', 'es', 'zh']) {
      test('$lang tem as mesmas chaves, sem vazio e com os placeholders', () {
        final m = textosDaLoja[lang]!;
        expect(m.keys.toSet(), pt.keys.toSet(), reason: 'chaves de $lang');
        for (final chave in pt.keys) {
          expect(m[chave]!.trim(), isNotEmpty, reason: '$lang.$chave');
          expect(
            _marcadores(m[chave]!),
            _marcadores(pt[chave]!),
            reason: 'placeholders divergem em $lang.$chave — a tela mostraria '
                'o token cru ou perderia o número',
          );
        }
      });
    }

    test('todo item novo e toda coleção têm texto', () {
      garanteTextosDaLoja();
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final t = T(lang);
        for (final c in Colecao.values) {
          expect(t.nomeDaColecao(c), isNot(contains('lojaColecao')));
          expect(t.subtituloDaColecao(c), isNot(contains('lojaColecaoSub')));
        }
        for (final i in itensDaCategoria(CategoriaDeItem.cenario)) {
          expect(t.descricaoDoCenario(i.id), isNotEmpty, reason: i.id);
        }
      }
    });

    test('chave que não existe volta como a própria chave, sem estourar', () {
      garanteTextosDaLoja();
      expect(T('pt').descricaoDoCenario('nao_existe'), isEmpty);
    });
  });

  group('o recorte da miniatura', () {
    test('enquadra o item e não sai da cena', () {
      for (final item in itensDeCena) {
        final r = CenaEmMiniatura.recorteDe(item.parts, 1.5);
        expect(r.left, greaterThanOrEqualTo(0), reason: item.id);
        expect(r.top, greaterThanOrEqualTo(0), reason: item.id);
        expect(r.right, lessThanOrEqualTo(372.001), reason: item.id);
        expect(r.bottom, lessThanOrEqualTo(296.001), reason: item.id);
        // E o item precisa caber dentro do recorte, senão a miniatura mostra
        // meia pedra.
        for (final p in item.parts) {
          expect(r.left, lessThanOrEqualTo(p.x + 0.001), reason: item.id);
          expect(r.top, lessThanOrEqualTo(p.y + 0.001), reason: item.id);
          expect(r.right, greaterThanOrEqualTo(p.x + p.w - 0.001),
              reason: item.id);
          expect(r.bottom, greaterThanOrEqualTo(p.y + p.h - 0.001),
              reason: item.id);
        }
      }
    });

    test('lista de peças vazia não estoura', () {
      // Roupa e cenário não têm peças. `reduce` em lista vazia já derrubou o
      // `ItemSwatch` uma vez; aqui a saída é a cena inteira.
      final r = CenaEmMiniatura.recorteDe(const [], 1.5);
      expect(r, const Rect.fromLTWH(0, 0, 372, 296));
    });

    test('sobra mundo em volta do item', () {
      // Se o recorte fosse o próprio item, a miniatura voltaria a ser um
      // quadrado com um recorte no meio — que é o que a loja era.
      final pedra = itemPorId('rock')!;
      final r = CenaEmMiniatura.recorteDe(pedra.parts, 1.5);
      final largura = pedra.parts
          .map((p) => p.x + p.w)
          .reduce((a, b) => a > b ? a : b) -
          pedra.parts.map((p) => p.x).reduce((a, b) => a < b ? a : b);
      expect(r.width, greaterThan(largura * 1.5));
    });
  });

  group('a tela', () {
    testWidgets('abre sem estourar e mostra as quatro prateleiras',
        (tester) async {
      final app = _loja(folhas: 300, tem: ['lily', 'rock']);
      await _abre(tester, app);

      final t = app.t;
      for (final c in Colecao.values) {
        expect(
          find.text(t.nomeDaColecao(c)),
          findsOneWidget,
          reason: 'prateleira ${c.name}',
        );
      }
      expect(tester.takeException(), isNull);
      app.dispose();
    });

    testWidgets('o destaque é o mais caro que o saldo alcança', (tester) async {
      // Com 190 folhas, o mais caro ao alcance é o lampião (190). É isso que
      // transforma saldo guardado em vontade de gastar.
      final app = _loja(folhas: 190);
      await _abre(tester, app);

      expect(find.text(app.t.lojaDestaqueAgora), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ShopScreen.chaveDestaque),
          matching: find.text('Lampião'),
        ),
        findsOneWidget,
      );
      app.dispose();
    });

    testWidgets('sem saldo, o destaque vira a próxima meta', (tester) async {
      final app = _loja();
      await _abre(tester, app);

      expect(find.text(app.t.lojaDestaqueProximo), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(ShopScreen.chaveDestaque),
          matching: find.text('Vitórias-régias'),
        ),
        findsOneWidget,
        reason: 'o mais barato que falta',
      );
      app.dispose();
    });

    testWidgets('o filtro "meus itens" esconde o que não é seu',
        (tester) async {
      final app = _loja(tem: ['rock']);
      await _abre(tester, app);

      expect(find.text('Vitórias-régias'), findsWidgets);

      await tester.tap(find.text(app.t.lojaFiltroMeus));
      await tester.pump();

      expect(
        find.text('Vitórias-régias'),
        findsNothing,
        reason: 'não é dele, não aparece',
      );
      expect(find.text('Pedra da fonte'), findsWidgets);
      app.dispose();
    });

    testWidgets('sem nada seu, o filtro tem saída em vez de tela branca',
        (tester) async {
      final app = _loja();
      await _abre(tester, app);

      await tester.tap(find.text(app.t.lojaFiltroMeus));
      await tester.pump();

      expect(find.text(app.t.lojaVazioMeusT), findsOneWidget);
      await tester.tap(find.text(app.t.lojaVerTudo));
      await tester.pump();
      expect(find.text(app.t.lojaVazioMeusT), findsNothing);
      app.dispose();
    });

    testWidgets('com tudo comprado, nada estoura e o destaque se despede',
        (tester) async {
      // O caso que quebra por `reduce` em lista vazia: sem nenhum item
      // faltando, "o mais barato que falta" não existe. Já derrubou o
      // `ItemSwatch` uma vez, pelo mesmo motivo.
      final app = _loja(tem: shopItems.map((i) => i.id).toList());
      await _abre(tester, app);

      expect(find.text(app.t.lojaTudoSeu), findsOneWidget);

      await tester.tap(find.text(app.t.lojaFiltroPosso));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(app.t.lojaVazioPossoT), findsOneWidget);
      app.dispose();
    });

    testWidgets('comprar pela prateleira desconta e já coloca em cena',
        (tester) async {
      final app = _loja(folhas: 100);
      await _abre(tester, app);

      // O primeiro cartão da prateleira da água é o mais barato: a
      // vitória-régia, a 40.
      await tester.tap(find.text('40').first);
      await tester.pump();

      expect(app.owned, contains('lily'));
      expect(app.leaves, 60);
      expect(app.estaEquipado('lily'), isTrue);
      expect(find.text(app.t.lojaEmUso), findsWidgets);
      app.dispose();
    });
  });
}

final _rePlaceholder = RegExp(r'\{(\w+)\}');

Set<String> _marcadores(String texto) =>
    _rePlaceholder.allMatches(texto).map((m) => m.group(1)!).toSet();
