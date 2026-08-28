import 'dart:io';

import 'package:baru_app/data/auth_errors.dart';
import 'package:baru_app/data/biometria.dart';
import 'package:baru_app/data/cofre.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lembrar a credencial e entrar pelo desbloqueio do aparelho.
///
/// Nada aqui toca o Keystore nem abre diálogo do sistema: o cofre e a
/// biometria entram por injeção. O que se prova é a **regra** — quando
/// grava, quando não grava, quando pede a digital e quando não pede.

const _senha = 'sementeDoBaru7';

Future<void> _abre(
  WidgetTester tester, {
  required Cofre cofre,
  required Biometria bio,
}) async {
  tester.view.physicalSize = const Size(412, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: AuthScreen(
        lang: 'pt',
        cofre: cofre,
        biometria: bio,
        onAuthenticated: () async {},
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  final t = T('pt');

  group('o que o cofre guarda', () {
    test('credencial sem e-mail ou sem senha não é credencial', () {
      expect(
        CredencialLembrada.fromJson({'email': '', 'senha': _senha}),
        isNull,
      );
      expect(
        CredencialLembrada.fromJson({'email': 'a@b.com', 'senha': ''}),
        isNull,
      );
      expect(CredencialLembrada.fromJson({'email': 'a@b.com'}), isNull);
    });

    test('ida e volta preserva os três campos', () {
      const c = CredencialLembrada(
        email: 'a@b.com',
        senha: _senha,
        comBiometria: true,
      );
      expect(CredencialLembrada.fromJson(c.toJson()), c);
    });
  });

  group('depois de um login que deu certo', () {
    test('com o interruptor ligado, guarda os três campos', () async {
      final cofre = CofreDeMentira();
      await aplicaLembranca(
        cofre,
        lembrar: true,
        email: 'ana@exemplo.com',
        senha: _senha,
        comBiometria: true,
      );
      expect(cofre.gravacoes, 1);
      expect(cofre.atual?.email, 'ana@exemplo.com');
      expect(cofre.atual?.senha, _senha);
      expect(cofre.atual?.comBiometria, isTrue);
    });

    test('com o interruptor desligado, não grava nada', () async {
      final cofre = CofreDeMentira();
      await aplicaLembranca(
        cofre,
        lembrar: false,
        email: 'ana@exemplo.com',
        senha: _senha,
        comBiometria: true,
      );
      expect(
        cofre.gravacoes,
        0,
        reason: 'senha guardada sem a pessoa pedir é senha vazada',
      );
      expect(cofre.atual, isNull);
    });

    test('desligar apaga o que estava guardado de antes', () async {
      final cofre = CofreDeMentira(
        const CredencialLembrada(
          email: 'ana@exemplo.com',
          senha: _senha,
          comBiometria: true,
        ),
      );
      await aplicaLembranca(
        cofre,
        lembrar: false,
        email: 'ana@exemplo.com',
        senha: _senha,
        comBiometria: true,
      );
      expect(cofre.atual, isNull);
      expect(cofre.apagamentos, 1);
    });

    test('sem bloqueio de tela, lembrar vale sem prometer biometria',
        () async {
      final cofre = CofreDeMentira();
      await aplicaLembranca(
        cofre,
        lembrar: true,
        email: 'ana@exemplo.com',
        senha: _senha,
        comBiometria: false,
      );
      expect(cofre.atual, isNotNull);
      expect(cofre.atual?.comBiometria, isFalse);
    });
  });

  group('a tela ao abrir', () {
    testWidgets('sem nada guardado, abre no formulário', (tester) async {
      await _abre(tester, cofre: CofreDeMentira(), bio: BiometriaDeMentira());

      expect(find.byKey(AuthScreen.chaveLembrar), findsOneWidget);
      expect(find.byKey(AuthScreen.chaveBiometria), findsNothing);
      expect(find.text(t.authOla), findsNothing);
    });

    testWidgets('com credencial guardada, abre dizendo quem é', (
      tester,
    ) async {
      final cofre = CofreDeMentira(
        const CredencialLembrada(
          email: 'ana@exemplo.com',
          senha: _senha,
          comBiometria: false,
        ),
      );
      await _abre(
        tester,
        cofre: cofre,
        bio: BiometriaDeMentira(),
      );

      expect(find.text(t.authOla), findsOneWidget);
      expect(find.text('ana@exemplo.com'), findsOneWidget);
      expect(find.byKey(AuthScreen.chaveBiometria), findsOneWidget);
      expect(
        find.byKey(AuthScreen.chaveDigitar),
        findsOneWidget,
        reason: 'digitar a senha nunca pode sumir',
      );
    });

    testWidgets('sem suporte no aparelho, não oferece a digital', (
      tester,
    ) async {
      final cofre = CofreDeMentira(
        const CredencialLembrada(
          email: 'ana@exemplo.com',
          senha: _senha,
          comBiometria: true,
        ),
      );
      final bio = BiometriaDeMentira(temSuporte: false);
      await _abre(tester, cofre: cofre, bio: bio);

      expect(find.byKey(AuthScreen.chaveBiometria), findsNothing);
      expect(
        bio.pedidos,
        0,
        reason: 'pedir digital em aparelho sem suporte trava a tela',
      );
    });
  });

  group('quando a digital é pedida', () {
    testWidgets('sozinha, só se a pessoa tinha aceitado', (tester) async {
      final bio = BiometriaDeMentira(aceita: false);
      await _abre(
        tester,
        cofre: CofreDeMentira(
          const CredencialLembrada(
            email: 'ana@exemplo.com',
            senha: _senha,
            comBiometria: true,
          ),
        ),
        bio: bio,
      );
      expect(bio.pedidos, 1);
      expect(bio.ultimoMotivo, t.authBiometriaMotivo);
    });

    testWidgets('sem ter aceitado, a tela espera o toque', (tester) async {
      final bio = BiometriaDeMentira();
      await _abre(
        tester,
        cofre: CofreDeMentira(
          const CredencialLembrada(
            email: 'ana@exemplo.com',
            senha: _senha,
            comBiometria: false,
          ),
        ),
        bio: bio,
      );
      expect(
        bio.pedidos,
        0,
        reason: 'abrir o diálogo do sistema sem ela ter pedido assusta',
      );
    });

    testWidgets('recusar leva ao formulário, não a um erro em vermelho', (
      tester,
    ) async {
      final bio = BiometriaDeMentira(aceita: false);
      await _abre(
        tester,
        cofre: CofreDeMentira(
          const CredencialLembrada(
            email: 'ana@exemplo.com',
            senha: _senha,
            comBiometria: true,
          ),
        ),
        bio: bio,
      );
      await tester.pump();

      expect(find.text(t.authOla), findsNothing);
      expect(find.byKey(AuthScreen.chaveLembrar), findsOneWidget);
      expect(find.text(t.authBiometriaFalhou), findsNothing);
      expect(
        find.text('ana@exemplo.com'),
        findsOneWidget,
        reason: 'o e-mail continua preenchido; só a senha é que falta',
      );
    });
  });

  group('quando a credencial guardada não serve mais', () {
    test('senha recusada pelo servidor esvazia o cofre', () {
      expect(
        credencialRecusada(
          const AuthException('Invalid login credentials',
              code: 'invalid_credentials'),
        ),
        isTrue,
      );
      expect(
        credencialRecusada(const AuthException('User not found')),
        isTrue,
      );
    });

    test('sem rede, a senha guardada não é apagada', () {
      // Apagar aqui seria perder uma senha que está certa por causa de um
      // wi-fi ruim.
      expect(
        credencialRecusada(const SocketException('failed host lookup')),
        isFalse,
      );
      expect(
        credencialRecusada(
          const AuthException('Server error', code: 'unexpected_failure'),
        ),
        isFalse,
      );
    });

    testWidgets('a tela não deixa a pessoa presa no desbloqueio', (
      tester,
    ) async {
      // Sem Supabase ligado, entrar com o que está guardado não vai dar
      // certo. O que se prova aqui é que a tela **sai** do desbloqueio em
      // vez de repetir a digital para sempre — e que o cofre sobrevive,
      // porque falta de configuração não é senha errada.
      final cofre = CofreDeMentira(
        const CredencialLembrada(
          email: 'ana@exemplo.com',
          senha: _senha,
          comBiometria: false,
        ),
      );
      await _abre(tester, cofre: cofre, bio: BiometriaDeMentira());

      await tester.tap(find.byKey(AuthScreen.chaveBiometria));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(AuthScreen.chaveLembrar), findsOneWidget);
      expect(cofre.atual, isNotNull);
      expect(cofre.apagamentos, 0);
    });
  });

  group('trocar de conta', () {
    testWidgets('esvazia o cofre e limpa o e-mail', (tester) async {
      final cofre = CofreDeMentira(
        const CredencialLembrada(
          email: 'ana@exemplo.com',
          senha: _senha,
          comBiometria: false,
        ),
      );
      await _abre(tester, cofre: cofre, bio: BiometriaDeMentira());

      await tester.tap(find.byKey(AuthScreen.chaveOutraConta));
      await tester.pump();

      expect(cofre.atual, isNull);
      expect(cofre.apagamentos, 1);
      expect(find.text('ana@exemplo.com'), findsNothing);
      expect(find.byKey(AuthScreen.chaveLembrar), findsOneWidget);
    });
  });
}
