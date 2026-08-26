import 'package:baru_app/auth_gate.dart';
import 'package:baru_app/data/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('sem Supabase configurado entra direto no onboarding', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repos = BaruRepositories.memory();
    await repos.init();

    await tester.pumpWidget(AuthGate(repos: repos));
    await tester.pumpAndSettle();

    expect(find.text('Em que idioma você quer falar com ele?'), findsOneWidget);
  });
}
