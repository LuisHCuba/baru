import 'package:baru_app/l10n.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/folha_restrita.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A permissão que o Android trava.
///
/// Do Android 13 em diante, uma permissão sensível como
/// `PACKAGE_USAGE_STATS` fica bloqueada quando o app foi instalado por
/// arquivo, fora de uma loja. A chave nem liga, e o aviso do sistema fala
/// em risco a dados pessoais e financeiros.
///
/// O texto antigo — "ative nas configurações do sistema" — mandava a pessoa
/// justamente para a tela onde o botão está travado.

void main() {
  testWidgets('a folha traz os quatro passos e o atalho', (tester) async {
    final t = T('pt');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FolhaRestrita(lang: 'pt'))),
    );

    expect(find.text(t.restritoT), findsOneWidget);
    for (final passo in [
      t.restrito1,
      t.restrito2,
      t.restrito3,
      t.restrito4,
    ]) {
      expect(find.text(passo), findsOneWidget, reason: passo);
    }
    expect(find.byKey(FolhaRestrita.chaveAbrir), findsOneWidget);
  });

  testWidgets('a folha existe nos quatro idiomas', (tester) async {
    for (final lang in ['pt', 'en', 'es', 'zh']) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: FolhaRestrita(lang: lang))),
      );
      final t = T(lang);
      expect(find.text(t.restritoT), findsOneWidget, reason: lang);
      expect(find.text(t.restrito3), findsOneWidget, reason: lang);
    }
  });

  test('recusa do sistema chama quem sabe abrir o passo a passo', () {
    // O que se prova: a recusa não vira mais um aviso solto. Quem escuta
    // recebe o chamado, e é ele que abre a folha.
    var abriu = 0;
    final app = AppState()..aoBloqueioDoSistema = () => abriu++;
    addTearDown(app.dispose);

    app.pedeAcessoDeUsoParaTeste(concedido: false);
    expect(abriu, 1);

    app.pedeAcessoDeUsoParaTeste(concedido: true);
    expect(abriu, 1, reason: 'concedido não abre passo a passo nenhum');
  });

  test('sem ninguém escutando, ainda avisa por texto', () {
    final mensagens = <String>[];
    final app = AppState(onUserMessage: mensagens.add);
    addTearDown(app.dispose);

    app.pedeAcessoDeUsoParaTeste(concedido: false);
    expect(mensagens, [T('pt').permUsageDenied]);
  });
}
