import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_sobreposicao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/onboarding_screen.dart';
import 'package:baru_app/screens/sobreposicao_screen.dart';
import 'package:baru_app/screens/tempo_screen.dart' show nomeDaCategoria;
import 'package:baru_app/services/overlay_service.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// As permissões: pedir todas, e dizer o preço de recusar.
///
/// **O defeito, verificado no aparelho do dono do produto.** O acesso ao uso
/// estava concedido; "desenhar sobre outros apps" estava negada. O
/// companheiro nunca aparecia sobre o TikTok e **nada no app dizia por quê**
/// — o onboarding pedia uma permissão só e ia embora, e a sobreposição
/// morava numa linha de Ajustes que ninguém abre.
///
/// O que se prova aqui: as quatro são pedidas uma a uma, cada uma diz o que
/// deixa de funcionar sem ela, recusar continua sendo caminho suportado, e
/// existe uma tela para pedir de novo depois.
///
/// O que **não** se prova: que a janela aparece de fato sobre o TikTok. Isso
/// é `WindowManager` no Android e só se vê em aparelho — BL-12.

/// As permissões que o "sistema" concedeu neste teste.
late Set<PermissaoDoBaru> concedidas;

Future<void> _assenta(WidgetTester tester) async {
  // Sem `pumpAndSettle`: o companheiro respira em laço infinito e a árvore
  // nunca fica quieta. Dois pumps bastam para as sondas assíncronas.
  await tester.pump();
  await tester.pump();
}

/// Traz um alvo para dentro da janela antes de tocar nele.
///
/// Um `ListView` constrói o filho um pouco antes de ele entrar na tela: o
/// finder acha, e o toque cai fora do viewport e não acontece — silenciosa
/// e demoradamente. `scrollUntilVisible` resolve o "ainda não construído" e
/// `ensureVisible` resolve o "construído mas fora da janela".
Future<void> _traz(WidgetTester tester, Finder alvo) async {
  final rolagem = find.byType(Scrollable).first;
  if (alvo.evaluate().isEmpty) {
    await tester.scrollUntilVisible(alvo, 120, scrollable: rolagem);
  }
  await tester.ensureVisible(alvo);
  await tester.pump();
}

Future<AppState> _abreOnboarding(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final app = AppState()..onb = 5;
  addTearDown(app.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const OnboardingScreen()),
      ),
    ),
  );
  await _assenta(tester);
  return app;
}

Future<AppState> _abreTelaDePermissoes(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final app = AppState()
    ..onb = 9
    ..companionshipStarted = true;
  addTearDown(app.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const SobreposicaoScreen()),
      ),
    ),
  );
  await _assenta(tester);
  return app;
}

void main() {
  setUp(() {
    concedidas = <PermissaoDoBaru>{};
    Permissoes.sonda = (p) async => concedidas.contains(p);
    Permissoes.espiao = <PermissaoDoBaru>[];
    garanteTextosDaSobreposicao();
  });

  tearDown(() {
    Permissoes.sonda = null;
    Permissoes.espiao = null;
  });

  group('o onboarding pede todas', () {
    testWidgets('uma permissão por tela, na ordem, e nenhuma fica de fora', (
      tester,
    ) async {
      final app = await _abreOnboarding(tester);
      final t = app.t;

      for (var i = 0; i < Permissoes.todas.length; i++) {
        final atual = Permissoes.todas[i];
        expect(
          find.text(t.tituloDaPermissao(atual)),
          findsOneWidget,
          reason: 'passo ${i + 1} tem de ser ${atual.name}',
        );
        for (final outra in Permissoes.todas) {
          if (outra == atual) continue;
          expect(
            find.text(t.tituloDaPermissao(outra)),
            findsNothing,
            reason: 'quatro pedidos numa tela só viram um muro de texto',
          );
        }
        expect(
          find.text(t.fill(t.sobPermPasso, {
            'i': i + 1,
            'total': Permissoes.todas.length,
          })),
          findsOneWidget,
        );

        await _traz(tester, find.byKey(AssistenteDePermissoes.chavePular));
        await tester.tap(find.byKey(AssistenteDePermissoes.chavePular));
        await _assenta(tester);
      }

      // A última fecha o onboarding mesmo com tudo recusado: recusar é
      // caminho suportado (contrato de produto §3), não beco sem saída.
      expect(app.companionshipStarted, isTrue);
      expect(app.screen, AppScreen.paywall);
    });

    testWidgets('a sobreposição é pedida — era ela que ficava de fora', (
      tester,
    ) async {
      final app = await _abreOnboarding(tester);
      final t = app.t;

      await tester.tap(find.byKey(AssistenteDePermissoes.chavePular));
      await _assenta(tester);

      expect(
        find.text(t.tituloDaPermissao(PermissaoDoBaru.sobreOutrosApps)),
        findsOneWidget,
      );
      final botao = find.byKey(
        CartaoDePermissao.chaveDoBotao(PermissaoDoBaru.sobreOutrosApps),
      );
      await _traz(tester, botao);
      await tester.tap(botao);
      await _assenta(tester);

      expect(
        Permissoes.espiao,
        contains(PermissaoDoBaru.sobreOutrosApps),
        reason: 'o toque tem de chegar à tela do sistema',
      );
    });

    testWidgets('cada permissão diz o que deixa de funcionar sem ela', (
      tester,
    ) async {
      final app = await _abreOnboarding(tester);
      final t = app.t;

      for (final p in Permissoes.todas) {
        expect(
          find.textContaining(
            t.fill(t.semAPermissao(p), {'n': app.displayName}),
            findRichText: true,
          ),
          findsOneWidget,
          reason: 'pedir sem dizer o custo da recusa é pedir no escuro (${p.name})',
        );
        await _traz(tester, find.byKey(AssistenteDePermissoes.chavePular));
        await tester.tap(find.byKey(AssistenteDePermissoes.chavePular));
        await _assenta(tester);
      }
    });

    testWidgets('conceder avança sozinho para a próxima', (tester) async {
      final app = await _abreOnboarding(tester);
      final t = app.t;

      // Vai até a sobreposição, que é a que o aparelho do dono recusou.
      await tester.tap(find.byKey(AssistenteDePermissoes.chavePular));
      await _assenta(tester);

      concedidas.add(PermissaoDoBaru.sobreOutrosApps);
      final botao = find.byKey(
        CartaoDePermissao.chaveDoBotao(PermissaoDoBaru.sobreOutrosApps),
      );
      await _traz(tester, botao);
      await tester.tap(botao);
      await _assenta(tester);

      expect(
        find.text(t.tituloDaPermissao(PermissaoDoBaru.notificacoes)),
        findsOneWidget,
        reason: 'pedir "continuar" logo depois do sim é pedir duas vezes',
      );
    });
  });

  group('a tela que se revisita', () {
    testWidgets('lista as quatro com o estado de cada uma', (tester) async {
      final app = await _abreTelaDePermissoes(tester);
      final t = app.t;

      // O placar primeiro: rolar até a última permissão tira a linha de
      // cima da janela, e o `ListView` a desmonta.
      expect(
        find.text(t.fill(t.sobPermResumo, {'q': 0, 'total': 4})),
        findsOneWidget,
      );
      for (final p in Permissoes.todas) {
        final titulo = find.text(t.tituloDaPermissao(p));
        await _traz(tester, titulo);
        expect(titulo, findsOneWidget, reason: p.name);
      }
    });

    testWidgets('a concedida aparece concedida, e sem o aviso de recusa', (
      tester,
    ) async {
      concedidas.add(PermissaoDoBaru.usoDoAparelho);
      final app = await _abreTelaDePermissoes(tester);
      final t = app.t;

      expect(
        find.text(t.fill(t.sobPermResumo, {'q': 1, 'total': 4})),
        findsOneWidget,
      );
      expect(find.text(t.sobPermLigada), findsOneWidget);
      expect(
        find.textContaining(
          t.fill(t.semAPermissao(PermissaoDoBaru.usoDoAparelho), {
            'n': app.displayName,
          }),
          findRichText: true,
        ),
        findsNothing,
        reason: 'assustar com o que quebraria numa permissão já dada é ruído',
      );
    });

    testWidgets('dá para pedir de novo o que foi negado', (tester) async {
      final app = await _abreTelaDePermissoes(tester);
      final t = app.t;
      final chave =
          CartaoDePermissao.chaveDoBotao(PermissaoDoBaru.sobreOutrosApps);

      await _traz(tester, find.byKey(chave));
      expect(
        find.descendant(
          of: find.byKey(chave),
          matching: find.text(t.sobPermDeNovo),
        ),
        findsOneWidget,
        reason: 'uma recusa no onboarding não pode ser definitiva',
      );

      await tester.tap(find.byKey(chave));
      await _assenta(tester);
      expect(Permissoes.espiao, contains(PermissaoDoBaru.sobreOutrosApps));
    });
  });

  group('o catálogo de apps na tela', () {
    testWidgets('mostra os apps e deixa a pessoa mudar a categoria', (
      tester,
    ) async {
      final app = await _abreTelaDePermissoes(tester);
      final t = app.t;
      const netflix = 'com.netflix.mediaclient';

      await _traz(tester, find.byKey(SobreposicaoScreen.chaveCatalogo));
      // Começa fechado: sessenta e tantos cartões abertos empurrariam as
      // permissões, que são o assunto da tela, para fora da primeira dobra.
      expect(find.text('Netflix'), findsNothing);

      final verTodos = find.text(t.fill(t.sobAppsVerTodos, {
        'q': ClassificacaoPadrao.comFala.length,
      }));
      await _traz(tester, verTodos);
      await tester.tap(verTodos);
      await _assenta(tester);

      await _traz(tester, find.text('Netflix'));
      await tester.tap(find.text('Netflix'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text(nomeDaCategoria(app, CategoriaDeApp.produtivo)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        app.ajustesDeCategoria[netflix],
        CategoriaDeApp.produtivo,
        reason: 'a classificação embutida tem de ser discordável, e antes só '
            'dava para discordar do que já tinha sido usado hoje',
      );
    });
  });

  group('o que cada plataforma tem', () {
    test('no Android são as quatro', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(Permissoes.daPlataforma(), Permissoes.todas);
    });

    test('fora do Android não se pede o que não existe', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      // A Apple não deixa um app desenhar por cima de outro. Pedir por isso
      // no iPhone seria pedir por algo impossível.
      expect(
        Permissoes.daPlataforma(),
        isNot(contains(PermissaoDoBaru.sobreOutrosApps)),
      );
      expect(
        Permissoes.daPlataforma(),
        contains(PermissaoDoBaru.notificacoes),
      );
    });
  });

  group('os textos das permissões', () {
    test('as quatro têm nome, explicação e custo nos quatro idiomas', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final t = T(lang);
        for (final p in Permissoes.todas) {
          for (final texto in [
            t.tituloDaPermissao(p),
            t.oQueFazAPermissao(p),
            t.semAPermissao(p),
          ]) {
            expect(texto.trim(), isNotEmpty, reason: '$lang/${p.name}');
            expect(
              texto,
              isNot(startsWith('sobPerm')),
              reason: 'chave crua na tela em $lang/${p.name}',
            );
          }
        }
      }
    });
  });
}
