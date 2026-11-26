import 'package:baru_app/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Diretriz 3.1.1 da Apple: no iPhone, os termos e a privacidade do app
/// apontam para as páginas /ios/ do site, sem o pagamento pelo site.
void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('no iPhone, termos e privacidade apontam para as páginas /ios/', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    for (final lang in T.catalog.keys) {
      final t = T(lang);
      expect(t.termsBody, contains('meubaru.com/termos/ios'), reason: lang);
      expect(t.privacyBody, contains('meubaru.com/privacidade/ios'), reason: lang);
    }
  });

  test('no Android, seguem as páginas de sempre', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final t = T('pt');
    expect(t.termsBody, isNot(contains('/ios')));
    expect(t.privacyBody, isNot(contains('/ios')));
  });
}
