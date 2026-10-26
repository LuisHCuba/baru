// O bicho da sobreposição é o bicho da pessoa.
//
// A sobreposição do Android desenhava um bicho genérico em Kotlin. Agora o
// Dart rasteriza o `PetView` real em quadros (respiração e piscada) e o
// Kotlin só os anima. Estes testes travam o lado Dart: o que entra na chave,
// quantos quadros saem, que eles de fato diferem entre si, e que o cache não
// redesenha à toa.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/services/quadros_do_bicho.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = AparenciaDoBicho(especie: Species.owl, pelagem: 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('chave da aparência', () {
    test('muda com espécie, pelagem, roupa e peça de cabeça', () {
      final chaves = {
        _base.chave,
        const AparenciaDoBicho(especie: Species.penguin, pelagem: 0).chave,
        const AparenciaDoBicho(especie: Species.owl, pelagem: 1).chave,
        const AparenciaDoBicho(
          especie: Species.owl,
          pelagem: 0,
          roupas: {Vestimenta.pescoco: Color(0xFFCC3333)},
        ).chave,
        const AparenciaDoBicho(
          especie: Species.owl,
          pelagem: 0,
          roupaDeCabeca: 'chapeu',
        ).chave,
      };
      expect(chaves, hasLength(5));
    });

    test('a ordem das roupas no mapa não muda a chave', () {
      const a = AparenciaDoBicho(
        especie: Species.cat,
        pelagem: 2,
        roupas: {
          Vestimenta.cabeca: Color(0xFF112233),
          Vestimenta.rosto: Color(0xFF445566),
        },
      );
      const b = AparenciaDoBicho(
        especie: Species.cat,
        pelagem: 2,
        roupas: {
          Vestimenta.rosto: Color(0xFF445566),
          Vestimenta.cabeca: Color(0xFF112233),
        },
      );
      expect(a.chave, b.chave);
      expect(a, b);
    });
  });

  test('a respiração vai do peito vazio ao cheio em passos iguais', () {
    final r = QuadrosDoBicho.respiros;
    expect(r, hasLength(QuadrosDoBicho.quadrosDeRespiro));
    expect(r.first, -1);
    expect(r.last, 1);
    for (var i = 1; i < r.length; i++) {
      expect(r[i] - r[i - 1], closeTo(2 / (r.length - 1), 1e-9));
    }
  });

  group('envio ao Android', () {
    late QuadrosDoBicho q;
    late List<MethodCall> chamadas;
    late List<String> desenhados;
    var respostaDoNativo = true;
    String? chaveNoNativo;

    setUp(() {
      q = QuadrosDoBicho.instance..zeraParaTeste();
      chamadas = [];
      desenhados = [];
      respostaDoNativo = true;
      chaveNoNativo = null;
      q.rasteriza = (w, chave, tamanho) async {
        desenhados.add(chave);
        return '/dados/home_widget/$chave.png';
      };
      q.canal = const MethodChannel('teste/quadros');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(q.canal, (c) async {
        if (c.method == 'quadrosChave') return chaveNoNativo;
        chamadas.add(c);
        return respostaDoNativo;
      });
    });

    tearDown(() {
      q.rasteriza = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(q.canal, null);
    });

    test('desenha seis quadros de fôlego e uma piscada, e manda os caminhos',
        () async {
      await q.atualiza(_base);
      expect(desenhados, hasLength(7));
      final prefixo = desenhados.first.substring(0, desenhados.first.length - 2);
      expect(prefixo, startsWith('baru_bicho_'));
      expect(desenhados, [
        for (var i = 0; i < 6; i++) '${prefixo}_$i',
        '${prefixo}_pisca',
      ]);
      expect(chamadas, hasLength(1));
      final c = chamadas.single;
      expect(c.method, 'quadros');
      final args = c.arguments as Map;
      expect(args['chave'], _base.chave);
      expect(args['respiro'], hasLength(6));
      expect(args['piscar'], '/dados/home_widget/${prefixo}_pisca.png');
    });

    test('se o Android já tem esta aparência, não desenha de novo', () async {
      // A primeira saída de cada processo redesenhava sempre, por cima dos
      // arquivos que a sobreposição podia estar lendo (auditoria 5.1).
      chaveNoNativo = _base.chave;
      await q.atualiza(_base);
      expect(desenhados, isEmpty);
      expect(chamadas, isEmpty);
    });

    test('cada leva grava em arquivos novos, nunca sobre os anteriores',
        () async {
      await q.atualiza(_base);
      final primeira = desenhados.toSet();
      desenhados.clear();
      await q.atualiza(const AparenciaDoBicho(
        especie: Species.owl,
        pelagem: 2,
      ));
      expect(desenhados.toSet().intersection(primeira), isEmpty);
    });

    test('mesma aparência não redesenha; roupa nova redesenha', () async {
      await q.atualiza(_base);
      await q.atualiza(_base);
      expect(q.desenhos, 1);
      await q.atualiza(const AparenciaDoBicho(
        especie: Species.owl,
        pelagem: 0,
        roupaDeCabeca: 'chapeu',
      ));
      expect(q.desenhos, 2);
    });

    test('se o Android não guardou, a próxima saída tenta de novo', () async {
      respostaDoNativo = false;
      await q.atualiza(_base);
      respostaDoNativo = true;
      await q.atualiza(_base);
      expect(q.desenhos, 2);
    });

    test('duas saídas seguidas não desenham em paralelo', () async {
      final f1 = q.atualiza(_base);
      final f2 = q.atualiza(_base);
      await Future.wait([f1, f2]);
      expect(q.desenhos, 1);
    });

    test('uma falha ao desenhar não vaza para quem chamou', () async {
      q.rasteriza = (w, chave, tamanho) async => throw StateError('disco');
      await expectLater(q.atualiza(_base), completes);
      expect(chamadas, isEmpty);
    });
  });

  group('os quadros', () {
    Future<Uint8List> pixels(WidgetTester tester, QuadroFixo quadro,
        {Species especie = Species.owl}) async {
      final chave = GlobalKey();
      await tester.pumpWidget(Center(
        child: RepaintBoundary(
          key: chave,
          child: QuadrosDoBicho.cena(
            AparenciaDoBicho(especie: especie, pelagem: 0),
            quadro,
          ),
        ),
      ));
      final b = chave.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      late Uint8List px;
      await tester.runAsync(() async {
        final img = await b.toImage(pixelRatio: 1);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        img.dispose();
        px = raw!.buffer.asUint8List();
        // Para olhar a olho: CAPTURAS=1 grava os quadros em build/.
        if (Platform.environment['CAPTURAS'] == '1') {
          final nome = '${especie.name}-r${quadro.respiro}-p${quadro.pisca}';
          File('build/quadros_do_bicho/$nome.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(data!.buffer.asUint8List());
        }
      });
      return px;
    }

    int diferentes(Uint8List a, Uint8List b) {
      var n = 0;
      for (var i = 0; i < a.length; i += 4) {
        if (a[i] != b[i] || a[i + 1] != b[i + 1] || a[i + 2] != b[i + 2]) {
          n++;
        }
      }
      return n;
    }

    testWidgets('o peito cheio e a piscada mudam o desenho, sem relógio',
        (tester) async {
      for (final sp in Species.values) {
        final vazio = await pixels(tester, const QuadroFixo(respiro: -1),
            especie: sp);
        final cheio = await pixels(tester, const QuadroFixo(respiro: 1),
            especie: sp);
        final pisca = await pixels(tester, const QuadroFixo(pisca: 1),
            especie: sp);
        expect(diferentes(vazio, cheio), greaterThan(0),
            reason: '${sp.name}: respirar não mexeu o desenho');
        expect(diferentes(vazio, pisca), greaterThan(0),
            reason: '${sp.name}: piscar não fechou o olho');
      }
      // Sem `repeat` nem piscada agendada: nenhum Timer pendente no fim.
      // O próprio `testWidgets` reprova se sobrar um.
    });

    testWidgets('o quadro é o mesmo bicho que o PetView animado desenha',
        (tester) async {
      // Repouso do PetView com "reduzir movimento": ciclo 0, olho aberto.
      // A pose do quadro com respiro 0 tem de cair no mesmo desenho que o
      // bicho parado da home — senão seriam dois bichos.
      final q = await pixels(tester, const QuadroFixo(respiro: 0));
      final chave = GlobalKey();
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Center(
          child: RepaintBoundary(
            key: chave,
            child: SizedBox(
              width: QuadrosDoBicho.tamanho.width,
              height: QuadrosDoBicho.tamanho.height,
              child: PetView(
                species: Species.owl,
                mood: Mood.content,
                activity: Activity.idle,
                coat: 0,
                interativo: false,
                width: QuadrosDoBicho.tamanho.width,
                height: QuadrosDoBicho.tamanho.height,
              ),
            ),
          ),
        ),
      ));
      final b = chave.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      late Uint8List home;
      await tester.runAsync(() async {
        final img = await b.toImage(pixelRatio: 1);
        final raw = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        img.dispose();
        home = raw!.buffer.asUint8List();
      });
      // Com "reduzir movimento" os contínuos param em 0.5 → respiro 0
      // depois da curva; a amplitude reduzida (0.25) só pesa no que se
      // move, e parado não há o que pesar. Tolerância para a borda do
      // antisserrilhado.
      expect(diferentes(q, home), lessThan(q.length ~/ 4 ~/ 100));
    });
  });
}
