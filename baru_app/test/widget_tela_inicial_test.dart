import 'package:baru_app/models.dart';
import 'package:baru_app/services/widget_service.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
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
  int pelagem = 0,
  String nome = 'Baru',
  int raiz = 3,
  int uso = 40,
  int meta = 90,
}) => EstadoDoWidget(
  especie: especie,
  pelagem: pelagem,
  nome: nome,
  raiz: raiz,
  usoDoDia: uso,
  meta: meta,
);

/// Uma conta que já conquistou o marco da espécie pedida.
///
/// A trilha passou a **cobrar** o que entrega: `pickSpecies` recusa espécie
/// não conquistada. Plantar o marco é o caminho honesto — afrouxar a porta
/// para o teste passar apagaria justamente a regra nova.
void _liberaEspecie(AppState a, Species e) {
  final marco = trilha.firstWhere((m) => m.recompensa.especie == e);
  a.marcosResgatados = {...a.marcosResgatados, marco.id};
}

/// Quantas imagens um bicho custa: os cinco momentos do dia nos dois
/// formatos (2×2 e 4×2) e o rosto das notificações.
final _porBicho =
    MomentoDoWidget.values.length * FormatoDoWidget.values.length + 1;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Espiao espiao;
  setUp(() {
    espiao = _Espiao()..liga();
  });

  group('o que vai para o widget', () {
    test('a primeira atualização desenha e grava tudo', () async {
      await _manda(_estado(nome: 'Coruja'));

      expect(
        espiao.rasterizacoes,
        _porBicho,
        reason: 'um bicho por momento do dia, para trocar com o app fechado',
      );
      expect(espiao.gravados['baru_nome'], 'Coruja');
      expect(espiao.gravados['baru_raiz'], 3);
      expect(espiao.gravados['baru_uso'], 40);
      expect(espiao.gravados['baru_meta'], 90);
      for (final m in MomentoDoWidget.values) {
        for (final f in FormatoDoWidget.values) {
          expect(espiao.gravados['baru_png_${m.name}_${f.sufixo}'], isNotNull);
        }
        expect(espiao.gravados['baru_frase_${m.name}'], isNotNull);
      }
      expect(espiao.gravados['baru_semana'], hasLength(7));
      expect(espiao.gravados['baru_letras'], hasLength(7));
      expect(espiao.avisos, 1);
    });

    test('estado idêntico não mexe em nada', () async {
      await _manda(_estado());
      await _manda(_estado());

      expect(espiao.rasterizacoes, _porBicho);
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

      expect(espiao.rasterizacoes, _porBicho);
      expect(espiao.gravados['baru_raiz'], 4);
      expect(espiao.avisos, 2, reason: 'o texto mudou; o launcher precisa ver');
    });

    test('mudar a pelagem redesenha os cinco momentos', () async {
      await _manda(_estado(pelagem: 0));
      await _manda(_estado(pelagem: 1));

      expect(espiao.rasterizacoes, 2 * _porBicho);
    });

    test('mudar a espécie redesenha', () async {
      await _manda(_estado());
      await _manda(_estado(especie: Species.owl));

      expect(espiao.rasterizacoes, 2 * _porBicho);
    });

    test('a presença de hoje viaja como dia, para o Kotlin comparar', () async {
      await _manda(
        EstadoDoWidget(
          especie: Species.capybara,
          pelagem: 0,
          nome: 'Baru',
          raiz: 3,
          usoDoDia: 0,
          meta: 90,
          presenteEm: DateTime(2026, 10, 29, 15, 40),
        ),
      );
      expect(espiao.gravados['baru_presente_em'], '2026-10-29');
    });

    test('falha na plataforma não derruba o app', () async {
      WidgetService.instance.rasteriza = (w, k, t) async =>
          throw StateError('sem widget na tela');

      await expectLater(_manda(_estado(nome: 'x')), completes);
    });
  });

  group('o tamanho do PNG', () {
    test('as cenas dos dois formatos também cabem no Binder', () {
      for (final f in FormatoDoWidget.values) {
        expect(f.tamanho.width * f.tamanho.height, lessThanOrEqualTo(200000));
      }
    });

    test('cabe na transação do Binder', () {
      // `setImageViewBitmap` serializa o bitmap **descomprimido** para o
      // processo do launcher, e a transação tem limite prático de ~1 MB. A
      // primeira versão pedia 320×280 lógicos e deixava o `pixelRatio` no
      // padrão: num aparelho 3× isso vira 960×840 = 3,2 MB, o launcher
      // descarta a imagem em silêncio e sobra um quadrado vazio.
      final t = WidgetService.tamanhoDoPng;
      final bytes = t.width * t.height * 4;

      expect(
        bytes,
        lessThan(1000 * 1024),
        reason: 'acima disso o launcher descarta e o widget fica vazio',
      );
    });

    test('e ainda é maior que um widget 4x2 numa tela comum', () {
      // O outro lado do mesmo cuidado: encolher demais borra a imagem
      // quando o `ImageView` estica.
      expect(WidgetService.tamanhoDoPng.width, greaterThanOrEqualTo(320));
    });

    test('a rasterização pede exatamente esse tamanho', () async {
      final pedidos = <String, Size>{};
      WidgetService.instance.rasteriza = (w, k, t) async {
        pedidos[k] = t;
        return '/tmp/x.png';
      };
      await _manda(_estado());

      for (final m in MomentoDoWidget.values) {
        for (final f in FormatoDoWidget.values) {
          expect(pedidos['baru_png_${m.name}_${f.sufixo}'], f.tamanho);
        }
      }
      expect(pedidos['baru_rosto'], WidgetService.tamanhoDoRosto);
    });
  });

  group('o momento do dia (o widget muda sozinho, como o do Duolingo)', () {
    final hoje = DateTime(2026, 10, 29);
    DateTime as(int h) => DateTime(2026, 10, 29, h, 10);

    test('raiz crescida hoje: feliz o dia todo, até a meia-noite', () {
      for (final h in [6, 13, 19, 23]) {
        expect(momentoDoWidget(hoje, as(h)), MomentoDoWidget.feito);
      }
    });

    test('sem foco hoje: acorda, espera, se aconchega e dorme', () {
      final ontem = hoje.subtract(const Duration(days: 1));
      expect(momentoDoWidget(ontem, as(3)), MomentoDoWidget.madrugada);
      expect(momentoDoWidget(ontem, as(8)), MomentoDoWidget.manha);
      expect(momentoDoWidget(ontem, as(14)), MomentoDoWidget.tarde);
      expect(momentoDoWidget(ontem, as(20)), MomentoDoWidget.noite);
      expect(momentoDoWidget(null, as(23)), MomentoDoWidget.madrugada);
    });

    test('a semana desliza com o app fechado e o hoje é de verdade', () {
      final escrita = DateTime(2026, 10, 27);
      // Gravada na terça (27/10/2026): sete letras do dia 21 ao 27, com
      // um congelado no meio e o dia 27 em curso.
      const gravada = 'eepfppt';
      // No mesmo dia, igual.
      expect(semanaNoDia(gravada, escrita, null, escrita), gravada);
      // Dois dias depois, sem abrir o app: desliza 2, o "t" do dia 27
      // passou sem presença e vira vazio, o 28 vazio, o 29 em curso.
      expect(
        semanaNoDia(gravada, escrita, null, DateTime(2026, 10, 29)),
        'pfppeet',
      );
      // E com a raiz crescida hoje, hoje é presente.
      expect(
        semanaNoDia(
          gravada,
          escrita,
          DateTime(2026, 10, 29),
          DateTime(2026, 10, 29),
        ),
        'pfppeep',
      );
    });

    test('nenhum momento usa o bicho triste (laudo 01, sem desespero)', () {
      for (final m in MomentoDoWidget.values) {
        expect(m.humor, isNot(Mood.missingYou));
      }
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
      _liberaEspecie(app, Species.fox);
      app.pickSpecies(Species.fox);

      final e = app.estadoDoWidget;

      expect(e.especie, Species.fox);
      expect(e.nome, app.displayName);
      expect(e.raiz, app.streak);
      expect(e.meta, app.goal);
      expect(e.frases.keys, containsAll(MomentoDoWidget.values));
      expect(e.frases.values, everyElement(isNotEmpty));
    });
  });
}
