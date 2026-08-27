import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/screens/tempo_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/componentes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tela que torna o número da meta auditável.
///
/// O §4B exige que toda tela tenha carregando, vazio, erro/sem-permissão e
/// sucesso — e que o estado vazio ofereça uma ação, não um beco.

AppState _estado({
  bool permissao = true,
  ResumoDeTela? resumo,
  Map<String, CategoriaDeApp> ajustes = const {},
}) {
  final s = AppState()..startCompanionship();
  s.usageAccess = permissao;
  s.resumoTela = resumo;
  s.ajustesDeCategoria = Map.of(ajustes);
  s.goal = 150;
  return s;
}

ResumoDeTela _diaTipico() => const ResumoDeTela(
      porApp: {
        'com.instagram.android': Duration(minutes: 62),
        'com.whatsapp': Duration(minutes: 31),
        'com.spotify.music': Duration(minutes: 48),
        'com.amazon.kindle': Duration(minutes: 25),
      },
      porCategoria: {
        CategoriaDeApp.dispersivo: Duration(minutes: 62),
        CategoriaDeApp.neutro: Duration(minutes: 31),
        CategoriaDeApp.passivo: Duration(minutes: 48),
        CategoriaDeApp.produtivo: Duration(minutes: 25),
      },
    );

Future<void> _abre(WidgetTester tester, AppState app) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const TempoScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('sem permissão: convida a conceder, não mostra número',
      (tester) async {
    final app = _estado(permissao: false);
    await _abre(tester, app);

    expect(find.text(app.t.telaSemPermissaoT), findsOneWidget);
    expect(
      find.text(app.t.permAllow),
      findsOneWidget,
      reason: 'estado sem permissão tem de oferecer o caminho de um toque',
    );
    expect(
      find.textContaining('min'),
      findsNothing,
      reason: 'sem medição o app não estima nem inventa',
    );
  });

  testWidgets('com permissão e sem dados: vazio honesto', (tester) async {
    final app = _estado(resumo: null);
    await _abre(tester, app);
    expect(find.text(app.t.telaVazioT), findsOneWidget);
  });

  testWidgets('com dados: mostra o que conta e o que não conta',
      (tester) async {
    final app = _estado(resumo: _diaTipico());
    await _abre(tester, app);
    await tester.pump(const Duration(seconds: 1)); // contadores e barras

    // 62 dispersivo + 31 neutro = 93 para a meta; total 166.
    expect(find.text(app.t.telaContado.toUpperCase()), findsOneWidget);
    expect(
      find.textContaining(app.fmt(93)),
      findsWidgets,
      reason: 'o número da meta é dispersivo + neutro',
    );
    expect(
      find.textContaining(app.fmt(166)),
      findsWidgets,
      reason: 'o total também aparece, para o usuário conferir a diferença',
    );
  });

  testWidgets('as quatro categorias aparecem com nome e tempo',
      (tester) async {
    final app = _estado(resumo: _diaTipico());
    await _abre(tester, app);

    expect(find.text(app.t.catDispersivo), findsWidgets);
    expect(find.text(app.t.catNeutro), findsWidgets);
    expect(find.text(app.t.catProdutivo), findsWidgets);
    expect(find.text(app.t.catPassivo), findsWidgets);
  });

  testWidgets('os apps aparecem por nome legível, do maior para o menor',
      (tester) async {
    final app = _estado(resumo: _diaTipico());
    await _abre(tester, app);

    final lista = find.byType(Scrollable).first;
    for (final nome in ['Instagram', 'Spotify', 'WhatsApp', 'Kindle']) {
      await tester.scrollUntilVisible(find.text(nome), 120, scrollable: lista);
      expect(find.text(nome), findsOneWidget, reason: nome);
    }
    expect(
      find.text('com.instagram.android'),
      findsNothing,
      reason: 'nome de pacote cru não diz nada a ninguém',
    );

    // A ordem é a da lista, não a da tela: o Instagram (62 min) vem antes do
    // Kindle (25 min) na árvore, mesmo que a rolagem mude quem está visível.
    final ordem = app.resumoTela!.appsPorTempo.map((e) => e.key).toList();
    expect(ordem.first, 'com.instagram.android');
    expect(ordem.last, 'com.amazon.kindle');
  });

  testWidgets('a explicação de como o tempo é contado está na tela',
      (tester) async {
    final app = _estado(resumo: _diaTipico());
    await _abre(tester, app);
    expect(find.text(app.t.telaComoContamos), findsOneWidget);
  });

  testWidgets('reclassificar um app muda o número da meta na hora',
      (tester) async {
    final app = _estado(resumo: _diaTipico());
    await _abre(tester, app);
    expect(app.resumoTela!.minutosContabilizados, 93);

    // "Eu uso o Instagram para trabalhar."
    await tester.tap(find.text('Instagram'));
    await tester.pumpAndSettle();
    expect(find.text(app.t.telaMudarCategoria), findsOneWidget);

    await tester.tap(find.text(app.t.catProdutivo).last);
    await tester.pumpAndSettle();

    expect(
      app.resumoTela!.minutosContabilizados,
      31,
      reason: 'os 62 do Instagram saíram da meta ao virar produtivo',
    );
    expect(app.usage, 31, reason: 'a meta do app acompanha na hora');
    expect(
      app.ajustesDeCategoria['com.instagram.android'],
      CategoriaDeApp.produtivo,
    );
  });

  testWidgets('a reclassificação sobrevive ao snapshot', (tester) async {
    final app = _estado(
      resumo: _diaTipico(),
      ajustes: {'com.google.android.youtube': CategoriaDeApp.produtivo},
    );
    await _abre(tester, app);

    final volta = AppState(snapshot: app.toSnapshot());
    expect(
      volta.ajustesDeCategoria['com.google.android.youtube'],
      CategoriaDeApp.produtivo,
    );
  });

  testWidgets('a tela cabe em 412x892 sem overflow', (tester) async {
    FlutterError.onError = (details) {
      final texto = details.exceptionAsString();
      if (texto.contains('overflowed')) fail(texto);
    };
    final app = _estado(resumo: _diaTipico());
    await _abre(tester, app);
    expect(tester.takeException(), isNull);
  });

  testWidgets('os números sobem animados em vez de saltar', (tester) async {
    final app = _estado(resumo: _diaTipico());
    await _abre(tester, app);
    expect(
      find.byType(ContadorAnimado),
      findsWidgets,
      reason: 'contador que troca de valor sem transição some da percepção',
    );
    expect(find.byType(BarraAnimada), findsWidgets);
  });
}
