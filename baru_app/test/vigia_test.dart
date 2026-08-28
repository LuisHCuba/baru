import 'package:baru_app/l10n.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/services/overlay_service.dart';
import 'package:baru_app/services/vigia_service.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// O vigia da sessão de foco.
///
/// Sair do Baru durante uma sessão não fazia nada — nem aviso, nem chamada
/// de volta. A causa não era regra de domínio: com o app em segundo plano o
/// Flutter **não executa**, e o único gatilho do companheiro estava no
/// `didChangeAppLifecycleState`, que só dispara quando a pessoa **volta**.
///
/// Aqui se prova o contrato com o lado nativo: quando o vigia é chamado,
/// quando é desligado, e o que vai junto. O serviço em si é Kotlin e está
/// registrado em BL-12 para verificação em aparelho.

/// Grava o que foi para a plataforma.
class _CanalEspiao {
  _CanalEspiao(this.nome);

  final String nome;
  final chamadas = <MethodCall>[];
  bool responde = true;

  MethodChannel arma() {
    final canal = MethodChannel(nome);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (chamada) async {
      chamadas.add(chamada);
      return responde;
    });
    return canal;
  }

  List<String> get metodos => chamadas.map((c) => c.method).toList();

  MethodCall? ultima(String metodo) {
    for (final c in chamadas.reversed) {
      if (c.method == metodo) return c;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CanalEspiao espiao;

  late _CanalEspiao overlay;

  setUp(() {
    espiao = _CanalEspiao('baru/vigia-teste');
    VigiaService.instance
      ..canal = espiao.arma()
      ..zeraParaTeste();
    // A sessão só levanta o vigia com "desenhar sobre outros apps"
    // concedido. O padrão do teste é conceder; quem quer provar a falta
    // vira o `responde`.
    overlay = _CanalEspiao('baru/overlay-teste');
    OverlayService.instance.canal = overlay.arma();
    addTearDown(() => OverlayService.instance.canal =
        const MethodChannel('baru/overlay'));
  });

  group('o contrato com a plataforma', () {
    test('começar manda a fala, a espécie e a cor do pelo', () async {
      await VigiaService.instance.comeca(
        fala: 'Ei',
        pelo: 0xFF112233,
        especie: 'capybara',
        acaoFechar: 'Fechar',
        acaoMais: 'Mais',
        notifTitulo: 'Baru está em foco',
        notifCorpo: 'Volte quando acabar.',
      );

      final c = espiao.ultima('vigiaComeca');
      expect(c, isNotNull);
      final args = c!.arguments as Map;
      // O lado nativo não escreve produto: tudo o que aparece na tela da
      // pessoa sai daqui, já traduzido.
      expect(args['fala'], 'Ei');
      expect(args['especie'], 'capybara');
      expect(args['pelo'], 0xFF112233);
      expect(args['notifTitulo'], 'Baru está em foco');
    });

    test('começar duas vezes não levanta dois vigias', () async {
      Future<void> chama() => VigiaService.instance.comeca(
            fala: 'Ei',
            pelo: 1,
            especie: 'owl',
            acaoFechar: 'x',
            acaoMais: 'y',
            notifTitulo: 't',
            notifCorpo: 'c',
          );
      await chama();
      await chama();

      expect(
        espiao.metodos.where((m) => m == 'vigiaComeca').length,
        1,
        reason: 'reiniciar zeraria o descanso entre aparições',
      );
    });

    test('parar vale mesmo sem o Dart lembrar que começou', () async {
      // O caso real: o app é morto durante a sessão e renasce sem memória.
      // O serviço sobreviveu — é essa a graça dele. Um `para()` que
      // desistisse aqui deixaria a notificação fixa para sempre na barra.
      await VigiaService.instance.para();

      expect(espiao.metodos, contains('vigiaPara'));
    });

    test('plataforma sem o canal não derruba a sessão', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel('baru/vigia-teste'),
        (_) async => throw MissingPluginException('sem canal'),
      );

      await expectLater(
        VigiaService.instance.comeca(
          fala: 'Ei',
          pelo: 1,
          especie: 'owl',
          acaoFechar: 'x',
          acaoMais: 'y',
          notifTitulo: 't',
          notifCorpo: 'c',
        ),
        completion(isFalse),
      );
      await expectLater(VigiaService.instance.para(), completes);
    });
  });

  group('o ícone do app', () {
    setUp(() => IconeService.instance
      ..canal = espiao.arma()
      ..zeraParaTeste());

    test('escolher o bicho troca o ícone da gaveta', () async {
      await IconeService.instance.usa('owl');

      final c = espiao.ultima('trocaIcone');
      expect(c, isNotNull);
      expect((c!.arguments as Map)['especie'], 'owl');
    });

    test('pedir o mesmo bicho de novo não troca nada', () async {
      // Cada troca faz muitos launchers removerem e recolocarem o atalho.
      await IconeService.instance.usa('owl');
      espiao.chamadas.clear();
      await IconeService.instance.usa('owl');

      expect(espiao.metodos, isEmpty);
    });

    test('trocar de espécie nos ajustes chega ao ícone', () async {
      final app = AppState()
        ..onb = 9
        ..companionshipStarted = true;
      addTearDown(app.dispose);
      espiao.chamadas.clear();

      app.pickSpecies(Species.fox);
      await Future<void>.delayed(Duration.zero);

      expect((espiao.ultima('trocaIcone')!.arguments as Map)['especie'],
          'fox');
    });
  });

  group('o ciclo da sessão', () {
    test('começar o foco levanta o vigia', () async {
      final app = AppState()
        ..onb = 9
        ..companionshipStarted = true;
      addTearDown(app.dispose);

      app.startSession();
      await Future<void>.delayed(Duration.zero);

      expect(espiao.metodos, contains('vigiaComeca'));
    });

    test('sem sobreposição, avisa em vez de vigiar em silêncio', () async {
      // O vigia sem essa permissão sobe, ve a pessoa sair, e nao consegue
      // aparecer. Silencio aqui e indistinguivel de "o app nao funciona".
      overlay.responde = false; // temPermissao -> false

      final avisos = <String>[];
      final app = AppState(onUserMessage: avisos.add)
        ..onb = 9
        ..companionshipStarted = true;
      addTearDown(app.dispose);
      espiao.chamadas.clear();

      app.startSession();
      await Future<void>.delayed(Duration.zero);

      expect(avisos, contains(T('pt').vigiaSemPermissao));
      expect(espiao.metodos, isNot(contains('vigiaComeca')));
    });

    test('desistir do foco desliga o vigia', () async {
      final app = AppState()
        ..onb = 9
        ..companionshipStarted = true;
      addTearDown(app.dispose);

      app.startSession();
      await Future<void>.delayed(Duration.zero);
      espiao.chamadas.clear();

      app.abandon();
      await Future<void>.delayed(Duration.zero);

      expect(
        espiao.metodos,
        contains('vigiaPara'),
        reason: 'vigia que sobrevive à sessão é notificação que não sai mais',
      );
    });
  });
}
