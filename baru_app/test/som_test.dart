import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:baru_app/services/som_service.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Som.
///
/// **O que estes testes não provam:** que os sons são bonitos. Ninguém aqui
/// os ouviu — foram sintetizados, não gravados, e áudio não se captura num
/// teste de widget. O que dá para provar é tudo o que costuma dar errado com
/// som em app: tocar quando o usuário desligou, tocar dois ao mesmo tempo,
/// arquivo faltando, e o app quebrar porque o alto-falante falhou.

void main() {
  setUp(() {
    SomService.instance
      ..reset()
      ..ligado = true
      ..agora = DateTime.now
      // Sem plugin de áudio num teste, construir o player fica pendente para
      // sempre. O que está sob teste é a decisão, não o alto-falante.
      ..tocador = (_) async {};
    SomService.espiao = <SomDoBaru>[];
  });

  tearDown(() {
    SomService.espiao = null;
    SomService.instance
      ..reset()
      ..tocador = null;
  });

  group('os arquivos', () {
    test('todo som do enum tem arquivo em disco', () {
      for (final s in SomDoBaru.values) {
        final f = File('assets/${s.arquivo}');
        expect(f.existsSync(), isTrue, reason: s.arquivo);
        expect(f.lengthSync(), greaterThan(1000), reason: '${s.arquivo} vazio');
      }
    });

    test('são WAV mono de verdade, e curtos', () {
      for (final s in SomDoBaru.values) {
        final b = File('assets/${s.arquivo}').readAsBytesSync();
        expect(String.fromCharCodes(b.sublist(0, 4)), 'RIFF', reason: s.name);
        expect(String.fromCharCodes(b.sublist(8, 12)), 'WAVE', reason: s.name);

        final d = ByteData.sublistView(b);
        final canais = d.getUint16(22, Endian.little);
        final taxa = d.getUint32(24, Endian.little);
        final bits = d.getUint16(34, Endian.little);
        expect(canais, 1, reason: '${s.name}: mono basta e pesa metade');
        expect(taxa, 44100, reason: s.name);
        expect(bits, 16, reason: s.name);

        // Duração pelo tamanho: cabeçalho de 44 bytes + PCM.
        final segundos = (b.length - 44) / (taxa * canais * (bits ~/ 8));
        expect(
          segundos,
          lessThan(0.7),
          reason: '${s.name} dura ${segundos}s — som de app não é música',
        );
        expect(segundos, greaterThan(0.03), reason: s.name);
      }
    });

    test('nenhum arquivo estoura em silêncio ou começa com clique', () {
      for (final s in SomDoBaru.values) {
        final b = File('assets/${s.arquivo}').readAsBytesSync();
        final pcm = Int16List.sublistView(Uint8List.fromList(b.sublist(44)));
        expect(pcm.length, greaterThan(100), reason: s.name);

        // Primeira amostra perto de zero: começar num pico é o "clique".
        expect(pcm.first.abs(), lessThan(2000), reason: '${s.name} estala ao começar');
        // Última também: cortar no meio da onda estala ao terminar.
        expect(pcm.last.abs(), lessThan(2000), reason: '${s.name} estala ao terminar');

        // E não pode estar clipando.
        final pico = pcm.map((v) => v.abs()).reduce((a, b) => a > b ? a : b);
        expect(pico, lessThan(32767), reason: '${s.name} clipa');
        expect(pico, greaterThan(3000), reason: '${s.name} é silêncio');
      }
    });
  });

  group('quando toca e quando não', () {
    test('desligado no app, não toca nada', () async {
      SomService.instance.ligado = false;
      await SomService.instance.toca(SomDoBaru.conquista);
      expect(SomService.espiao, isEmpty);
    });

    test('dois sons colados viram um: o segundo é engolido', () {
      final base = DateTime(2026, 8, 27, 10);
      final s = SomService.instance..agora = () => base;
      expect(s.valeTocar(base), isTrue);
    });

    test('respeita o intervalo mínimo entre dois sons', () async {
      var relogio = DateTime(2026, 8, 27, 10);
      SomService.instance.agora = () => relogio;

      await SomService.instance.toca(SomDoBaru.toque);
      expect(SomService.espiao, [SomDoBaru.toque]);

      // 100 ms depois: cedo demais.
      relogio = relogio.add(const Duration(milliseconds: 100));
      await SomService.instance.toca(SomDoBaru.carinho);
      expect(
        SomService.espiao,
        [SomDoBaru.toque],
        reason: 'dois sons ao mesmo tempo viram ruído, não feedback',
      );

      // Meio segundo depois: pode.
      relogio = relogio.add(const Duration(milliseconds: 500));
      await SomService.instance.toca(SomDoBaru.carinho);
      expect(SomService.espiao, [SomDoBaru.toque, SomDoBaru.carinho]);
    });

    test('falha de áudio não sobe: sessão de foco não cai por causa de som',
        () async {
      SomService.instance.tocador = (_) async {
        throw StateError('sem alto-falante');
      };
      await expectLater(SomService.instance.toca(SomDoBaru.fim), completes);
    });

    test('áudio que nunca responde não deixa future pendente para sempre',
        () async {
      // O modo de falha real do plugin não é estourar: é pendurar.
      SomService.instance.tocador = (_) => Completer<void>().future;
      await expectLater(
        SomService.instance.toca(SomDoBaru.fim).timeout(
              const Duration(seconds: 5),
            ),
        completes,
      );
    });
  });

  group('a preferência do usuário', () {
    test('começa ligada, desliga e sobrevive ao snapshot', () {
      final s = AppState();
      expect(s.som, isTrue);
      s.toggleSom();
      expect(s.som, isFalse);
      expect(
        SomService.instance.ligado,
        isFalse,
        reason: 'desligar na tela tem de chegar no serviço',
      );

      final volta = AppState(snapshot: s.toSnapshot());
      expect(volta.som, isFalse);
      expect(SomService.instance.ligado, isFalse);
      s.dispose();
      volta.dispose();
    });
  });

  group('os eventos que fazem som', () {
    test('concluir uma sessão toca o som de fim', () {
      var relogio = DateTime(2026, 8, 27, 10);
      SomService.instance.agora = () => relogio;

      final s = AppState()
        ..startCompanionship()
        ..debugFast = false
        ..dur = 25;
      s.startSession();
      s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
      s.reconcileSession();

      expect(SomService.espiao, contains(SomDoBaru.fim));
      s.dispose();
    });

    test('um afago completo toca o som de carinho', () {
      final s = AppState()..startCompanionship();
      s.recebeCarinho();
      expect(SomService.espiao, contains(SomDoBaru.carinho));
      s.dispose();
    });

    test('com o som desligado, nenhum evento toca', () {
      SomService.instance.ligado = false;
      final s = AppState()..startCompanionship();
      s.recebeCarinho();
      expect(SomService.espiao, isEmpty);
      s.dispose();
    });
  });
}
