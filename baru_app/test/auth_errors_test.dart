import 'package:baru_app/data/auth_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('traduz credenciais inválidas em pt', () {
    expect(
      translateAuthError(
        AuthException('Invalid login credentials'),
        'pt',
      ),
      contains('incorretos'),
    );
  });

  test('traduz usuário já registrado em en', () {
    expect(
      translateAuthError(
        AuthException('User already registered'),
        'en',
      ),
      contains('already registered'),
    );
  });
}
