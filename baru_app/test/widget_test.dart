import 'package:baru_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('abre no onboarding em português', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const BaruApp());
    expect(find.text('Em que idioma você quer falar com ele?'), findsOneWidget);
    expect(find.text('Português'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });
}
