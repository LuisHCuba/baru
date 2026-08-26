import 'package:baru_app/auth_gate.dart';
import 'package:baru_app/data/repositories.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A escolha de idioma é o passo 1 do onboarding — mas o login vem antes dele.
/// Num app com quatro idiomas de primeira classe (contrato §2), a porta de
/// entrada não pode falar só português.

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('idioma a partir do locale do aparelho', () {
    test('reconhece os quatro idiomas do contrato', () {
      expect(langFromLocale(const Locale('pt', 'BR')), 'pt');
      expect(langFromLocale(const Locale('en', 'US')), 'en');
      expect(langFromLocale(const Locale('es', 'AR')), 'es');
      expect(
        langFromLocale(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ),
        'zh',
      );
    });

    test('idioma não suportado cai em pt', () {
      expect(langFromLocale(const Locale('de')), 'pt');
      expect(langFromLocale(const Locale('ja')), 'pt');
    });

    test('não depende de caixa alta ou baixa', () {
      expect(langFromLocale(const Locale('EN')), 'en');
    });
  });

  testWidgets('sem Supabase o gate entra direto e não trava em português',
      (tester) async {
    final repos = BaruRepositories.memory();
    await repos.init();
    await tester.pumpWidget(AuthGate(repos: repos));
    await tester.pump();

    // Sem credenciais o app é offline: nenhuma tela de login aparece.
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets('a tela de login usa o idioma que recebe', (tester) async {
    for (final lang in ['pt', 'en', 'es', 'zh']) {
      await tester.pumpWidget(
        MaterialApp(
          locale: localeFor(lang),
          home: AuthScreen(lang: lang, onAuthenticated: () async {}),
        ),
      );
      await tester.pump();

      final t = T(lang);
      expect(
        find.text(t.authLoginTitle),
        findsOneWidget,
        reason: 'título do login em $lang',
      );
      expect(
        find.text(t.authSignIn),
        findsOneWidget,
        reason: 'botão de entrar em $lang',
      );
    }
  });

  test('as mensagens do bootstrap resolvem nos 4 idiomas', () {
    // O AuthGate mostra estas duas em SnackBar depois do login. Antes elas só
    // existiam em pt, e o cast de T.s() estourava nos outros idiomas.
    for (final lang in ['pt', 'en', 'es', 'zh']) {
      final t = T(lang);
      expect(t.syncFail, isNotEmpty, reason: lang);
      expect(t.bootstrapOffline, isNotEmpty, reason: lang);
      expect(t.authBootstrapLoading, isNotEmpty, reason: lang);
    }
  });
}
