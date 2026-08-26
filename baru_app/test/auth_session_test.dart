import 'package:baru_app/data/auth_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('traduz signup sem sessão (confirmação de e-mail)', () {
    expect(
      translateAuthError(
        const AuthException('email_not_confirmed'),
        'pt',
      ),
      contains('Confirme'),
    );
  });
}
