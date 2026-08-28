import 'package:baru_app/models.dart';
import 'package:baru_app/services/widget_service.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// O Baru na tela inicial do aparelho.
///
/// `RemoteViews` roda no processo do launcher e **não** executa
/// `CustomPainter`: o bicho do widget é um PNG que o app rasteriza e grava
/// em disco. Rasterizar é caro, e o estado do app notifica muitas vezes por
/// minuto — daí a regra que este arquivo protege: **só redesenha quando a
/// imagem realmente muda**.
///
/// O provider é Kotlin e está em BL-14 para verificação em aparelho.

class _Espiao {
  final gravados = <String, Object>{};
  int rasterizacoes = 0;
  int avisos = 0;

  void liga() {
    final s = WidgetService.instance..zeraParaTeste();
    s.desenhos = 0;
    s.gravaDado = (chave, valor) async => gravados[chave] = valor;
    s.rasteriza = (w, chave, tamanho) async {
      rasterizacoes++;
      return '/tmp/$chave.png';
    };
    s.avisaOProvider = () async => avisos++;
  }
}

/// `atualiza` é disparo-e-esquece: quem chama não espera a plataforma.
/// O teste espera o microtask para poder afirmar sobre o resultado.
Future<void> _manda(EstadoDoWidget e) async {
  WidgetService.instance.atualiza(e);
  await Future<void>.delayed(Duration.zero);
}

EstadoDoWidget _estado({
  Species especie = Species.capybara,
  Mood humor = Mood.content,
  int pelagem = 0,
  String nome = 'Baru',
  int raiz = 3,
  int uso = 40,
  int meta = 90,
}) =>
    EstadoDoWidget(
      especie: especie,
      humor: humor,
      pelagem: pelagem,
      nome: nome,
      raiz: raiz,
      usoDoDia: uso,
      meta: meta,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Espiao espiao;
  setUp(() {
    espiao = _Espiao()..liga();
  });

  group('o que vai para o widget', () {
    test('a primeira atualização desenha e grava tudo', () async {
      await _manda(_estado(nome: 'Coruja'));

      expect(espiao.rasterizacoes, 1);
      expect(espiao.gravados['baru_nome'], 'Coruja');
      expect(espiao.gravados['baru_raiz'], 3);
      expect(espiao.gravados['baru_uso'], 40);
      expect(espiao.gravados['baru_meta'], 90);
      expect(espiao.gravados['baru_pet_png'], isNotNull);
      expect(espiao.avisos, 1);
    });

    test('estado idêntico não mexe em nada', () async {
      await _manda(_estado());
      await _manda(_estado());

      expect(espiao.rasterizacoes, 1);
      expect(
        espiao.avisos,
        1,
        reason: 'acordar o launcher à toa é bateria da pessoa',
      );
    });

    test('mudar só a raiz não redesenha o bicho', () async {
      // A regra que justifica a classe existir: o estado notifica muitas
      // vezes por minuto, e rasterizar é caro.
      await _manda(_estado(raiz: 3));
      await _manda(_estado(raiz: 4));

      expect(espiao.rasterizacoes, 1);
      expect(espiao.gravados['baru_raiz'], 4);
      expect(espiao.avisos, 2, reason: 'o texto mudou; o launcher precisa ver');
    });

    test('mudar o humor redesenha', () async {
      await _manda(_estado(humor: Mood.content));
      await _manda(_estado(humor: Mood.sleepy));

      expect(espiao.rasterizacoes, 2);
    });

    test('mudar a espécie redesenha', () async {
      await _manda(_estado());
      await _manda(_estado(especie: Species.owl));

      expect(espiao.rasterizacoes, 2);
    });

    test('falha na plataforma não derruba o app', () async {
      WidgetService.instance.rasteriza =
          (w, k, t) async => throw StateError('sem widget na tela');

      await expectLater(_manda(_estado(nome: 'x')), completes);
    });
  });

  group('quando o widget é atualizado', () {
    test('o estado do app vira o estado do widget', () async {
      // O envio saiu do `notifyListeners` e foi para o ciclo de vida: o
      // widget existe para quando o app **não** está na frente, e
      // rasterizar no meio das animações da tela derrubava o relógio dos
      // `AnimationController`. O que se prova aqui é a tradução.
      final app = AppState()
        ..onb = 9
        ..companionshipStarted = true;
      addTearDown(app.dispose);
      app.pickSpecies(Species.fox);

      final e = app.estadoDoWidget;

      expect(e.especie, Species.fox);
      expect(e.nome, app.displayName);
      expect(e.raiz, app.streak);
      expect(e.meta, app.goal);
    });
  });
}
