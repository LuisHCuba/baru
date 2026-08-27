import 'package:baru_app/services/overlay_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// O companheiro por cima dos outros apps.
///
/// **O que estes testes não provam:** que a janela aparece mesmo sobre o
/// TikTok. Isso é `WindowManager` no Android e só se vê em aparelho.
///
/// O que dá para provar é a parte que separa companhia de assédio: teto por
/// dia, intervalo mínimo, e nada aparecendo sem permissão.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> chamadas;

  void plataforma({required bool permitido}) {
    chamadas = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('baru/overlay'),
      (call) async {
        chamadas.add(call);
        return switch (call.method) {
          'temPermissao' => permitido,
          'mostra' => true,
          _ => null,
        };
      },
    );
  }

  setUp(() {
    plataforma(permitido: true);
    OverlayService.instance
      ..reset()
      ..agora = DateTime.now;
    OverlayService.espiao = <String>[];
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    OverlayService.espiao = null;
    OverlayService.instance.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('baru/overlay'), null);
  });

  Future<bool> mostra() => OverlayService.instance.mostra(
        fala: 'oi',
        pelo: 0xFFB07A4E,
        especie: 'capybara',
        acaoFechar: 'Fechar',
        acaoMais: '+5',
      );

  group('a regra de não insistir', () {
    test('sem permissão, nada aparece', () async {
      plataforma(permitido: false);
      expect(await mostra(), isFalse);
      expect(
        chamadas.map((c) => c.method),
        isNot(contains('mostra')),
        reason: 'nem chega a pedir o desenho',
      );
    });

    test('duas aparições coladas viram uma', () async {
      var relogio = DateTime(2026, 8, 27, 10);
      OverlayService.instance.agora = () => relogio;

      expect(await mostra(), isTrue);
      relogio = relogio.add(const Duration(minutes: 5));
      expect(
        await mostra(),
        isFalse,
        reason: 'aparecer de novo em 5 minutos é perseguição, não companhia',
      );

      relogio = relogio.add(OverlayService.intervaloMinimo);
      expect(await mostra(), isTrue);
    });

    test('tem teto por dia', () async {
      var relogio = DateTime(2026, 8, 27, 8);
      OverlayService.instance.agora = () => relogio;

      for (var i = 0; i < OverlayService.aparicoesPorDia; i++) {
        expect(await mostra(), isTrue, reason: 'aparição $i');
        relogio = relogio.add(const Duration(hours: 1));
      }
      expect(
        await mostra(),
        isFalse,
        reason: 'passado o teto, ele cala a boca até amanhã',
      );
      expect(OverlayService.espiao, hasLength(OverlayService.aparicoesPorDia));
    });

    test('o teto zera na virada do dia', () async {
      var relogio = DateTime(2026, 8, 27, 8);
      OverlayService.instance.agora = () => relogio;
      for (var i = 0; i < OverlayService.aparicoesPorDia; i++) {
        await mostra();
        relogio = relogio.add(const Duration(hours: 1));
      }
      expect(await mostra(), isFalse);

      relogio = DateTime(2026, 8, 28, 8);
      expect(await mostra(), isTrue);
    });
  });

  group('a ponte com o Android', () {
    test('a fala e a pelagem chegam ao lado nativo', () async {
      await mostra();
      final c = chamadas.firstWhere((c) => c.method == 'mostra');
      final args = Map<String, dynamic>.from(c.arguments as Map);
      expect(args['fala'], 'oi');
      expect(args['pelo'], 0xFFB07A4E);
      expect(args['especie'], 'capybara');
      expect(
        args['acaoFechar'],
        'Fechar',
        reason: 'o texto vem traduzido do Dart; o nativo não escreve produto',
      );
    });

    test('pedir permissão só abre a tela do sistema', () async {
      await OverlayService.instance.pedePermissao();
      expect(chamadas.map((c) => c.method), contains('pedePermissao'));
    });

    test('falha da plataforma não sobe', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('baru/overlay'),
        (call) async {
          if (call.method == 'temPermissao') return true;
          throw PlatformException(code: 'boom');
        },
      );
      expect(await mostra(), isFalse);
    });

    test('fora do Android nem tenta', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await OverlayService.instance.temPermissao(), isFalse);
      expect(await mostra(), isFalse);
    });
  });
}
