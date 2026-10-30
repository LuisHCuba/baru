// As cenas das notificações animadas.
//
// O Dart rasteriza, por tema de recado, o bicho no humor do tema (quatro
// fôlegos e uma piscada) e o cenário em três luzes; o Kotlin anima a troca
// dentro da notificação. Estes testes travam o lado Dart: o que vai ao
// Android, o cache, a regra da luz, e que cada cena de fato se desenha.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/services/cenas_dos_recados.dart';
import 'package:baru_app/services/quadros_do_bicho.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = AparenciaDoBicho(especie: Species.capybara, pelagem: 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('os temas', () {
    test('cada recado tem o seu humor, e nenhum é o bicho com saudade', () {
      // Sem culpa (laudo 01, U9): a notificação chama, não cobra.
      for (final t in TemaDoRecado.values) {
        expect(t.humor, isNot(Mood.missingYou), reason: t.name);
      }
      expect(TemaDoRecado.pausa.humor, Mood.sleepy);
      expect(TemaDoRecado.raiz.humor, Mood.radiant);
      expect(TemaDoRecado.despedida.atividade, Activity.nap);
    });

    test('a luz pela hora do toque: o mesmo corte do Kotlin', () {
      LuzDoRecado em(int h) => luzDa(DateTime(2026, 10, 29, h, 15));
      expect(em(5), LuzDoRecado.manha);
      expect(em(11), LuzDoRecado.manha);
      expect(em(12), LuzDoRecado.tarde);
      expect(em(17), LuzDoRecado.tarde);
      expect(em(18), LuzDoRecado.noite);
      expect(em(4), LuzDoRecado.noite);
    });

    test('cabe no Binder: quadros e fundo bem abaixo de 1 MB', () {
      const q = CenasDosRecados.tamanhoDoQuadro;
      const f = CenasDosRecados.tamanhoDoFundo;
      final quadros = q.width * q.height * 4 * 5;
      final fundo = f.width * f.height * 2;
      expect(quadros + fundo, lessThan(600 * 1024));
    });
  });

  group('envio ao Android', () {
    late CenasDosRecados c;
    late List<MethodCall> chamadas;
    late List<String> desenhados;
    String? chaveNoNativo;

    setUp(() {
      c = CenasDosRecados.instance..zeraParaTeste();
      chamadas = [];
      desenhados = [];
      chaveNoNativo = null;
      c.rasteriza = (w, chave, tamanho) async {
        desenhados.add(chave);
        return '/dados/home_widget/$chave.png';
      };
      c.canal = const MethodChannel('teste/cenas');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(c.canal, (m) async {
        if (m.method == 'cenasChave') return chaveNoNativo;
        chamadas.add(m);
        return true;
      });
    });

    tearDown(() {
      c.rasteriza = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(c.canal, null);
    });

    test('um bicho e três fundos por tema, num envio só', () async {
      await c.atualiza(_base);
      final porTema =
          CenasDosRecados.respiros.length + 1 + LuzDoRecado.values.length;
      expect(desenhados, hasLength(TemaDoRecado.values.length * porTema));
      expect(chamadas, hasLength(1));
      final args = chamadas.single.arguments as Map;
      expect(chamadas.single.method, 'cenas');
      expect(args['chave'], _base.chave);
      final temas = args['temas'] as Map;
      expect(temas.keys.toSet(), {for (final t in TemaDoRecado.values) t.name});
      for (final t in temas.values.cast<Map>()) {
        expect(t['respiro'], hasLength(CenasDosRecados.respiros.length));
        expect(t['pisca'], isA<String>());
        expect((t['fundos'] as Map).keys.toSet(),
            {for (final l in LuzDoRecado.values) l.name});
      }
    });

    test('a mesma aparência não desenha de novo', () async {
      await c.atualiza(_base);
      final antes = desenhados.length;
      await c.atualiza(_base);
      expect(desenhados.length, antes);
    });

    test('o Android já tem as cenas desta aparência: nada a desenhar',
        () async {
      chaveNoNativo = _base.chave;
      await c.atualiza(_base);
      expect(desenhados, isEmpty);
      expect(chamadas, isEmpty);
    });
  });

  group('as cenas se desenham', () {
    Future<Uint8List> foto(WidgetTester tester, Widget w, String nome) async {
      final chave = GlobalKey();
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RepaintBoundary(key: chave, child: w)),
      ));
      final b =
          chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late Uint8List px;
      await tester.runAsync(() async {
        final img = await b.toImage(pixelRatio: 1);
        final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        img.dispose();
        px = raw!.buffer.asUint8List();
        // Para olhar a olho: CAPTURAS=1 grava as cenas em build/.
        if (Platform.environment['CAPTURAS'] == '1') {
          File('build/cenas_dos_recados/$nome.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        }
      });
      return px;
    }

    testWidgets('cada tema tem um cenário próprio em cada luz',
        (tester) async {
      for (final luz in LuzDoRecado.values) {
        final vistos = <String>{};
        for (final tema in TemaDoRecado.values) {
          final px = await foto(
            tester,
            CenasDosRecados.fundo(tema, luz),
            'fundo-${tema.name}-${luz.name}',
          );
          // Pintou de verdade, e não a mesma imagem do tema vizinho.
          expect(px.any((b) => b != 0), isTrue);
          expect(vistos.add('${Object.hashAll(px)}'), isTrue,
              reason: '${tema.name} igual a outro tema em ${luz.name}');
        }
      }
    });

    testWidgets('o bicho de cada tema respira e pisca', (tester) async {
      for (final tema in TemaDoRecado.values) {
        final vazio = await foto(
          tester,
          CenasDosRecados.quadro(_base, tema, const QuadroFixo(respiro: -1)),
          'bicho-${tema.name}-vazio',
        );
        final cheio = await foto(
          tester,
          CenasDosRecados.quadro(_base, tema, const QuadroFixo(respiro: 1)),
          'bicho-${tema.name}-cheio',
        );
        expect(vazio, isNot(equals(cheio)), reason: tema.name);
      }
    });
  });
}
