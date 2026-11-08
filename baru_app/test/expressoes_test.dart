// Capturas do lote "expressões" e "olhos e piscada" (auditoria rodada 1):
// por espécie, os quadros fixos das assinaturas do rosto (susto, espanto,
// grito, riso, festa no pico e no pouso, meia piscada, olhar nas quatro
// direções) e duas sequências de 30 quadros a 30 qps saídas do motor de
// vida (`susto-seq`, `festa-seq`), com o registro por quadro em JSON para
// `expressoes_medidas.py`. Só com CAPTURAS=1; ESPECIES=a,b filtra.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/data/crescimento.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:baru_app/widgets/vida/motor_de_vida.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _ligado = Platform.environment['CAPTURAS'] == '1';
const _pasta = 'build/expressoes';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> grava(
    WidgetTester tester,
    Species sp,
    Mood m,
    QuadroFixo q,
    String nome, {
    double ratio = 3,
  }) async {
    final chave = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: chave,
            child: SizedBox(
              width: 260,
              height: 220,
              child: PetView(
                species: sp,
                mood: m,
                activity: Activity.idle,
                coat: 0,
                estagio: EstagioDoBicho.adulto,
                interativo: false,
                width: 260,
                height: 220,
                quadro: q,
              ),
            ),
          ),
        ),
      ),
    );
    final b =
        chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await b.toImage(pixelRatio: ratio);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      File('$_pasta/$nome.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  MotorDeVida motor(Species sp) => MotorDeVida(semente: sp.index * 31 + 7)
    ..podeAndar = false
    ..energia = 0.75
    ..periodoRespiro = 3.2
    ..repertorio = const {}
    ..medianaDoPiscar = 3.6
    ..jeito = sp == Species.tortoise
        ? const JeitoDeCacar(velocidade: 12)
        : const JeitoDeCacar(saltita: true);

  Map<String, double> registro(SaidaDaVida s) => {
    'altura': s.altura,
    'achata': s.achata,
    'susto': s.susto,
    'festa': s.festa,
    'pisca': s.pisca,
    'grito': s.grito,
    'riso': s.riso,
  };

  final quais =
      (Platform.environment['ESPECIES'] ??
              Species.values.map((s) => s.name).join(','))
          .split(',');
  final especies = Species.values.where((s) => quais.contains(s.name));

  testWidgets('quadros fixos das expressões (x3)', skip: !_ligado, (
    tester,
  ) async {
    for (final sp in especies) {
      final p = sp.name;
      Future<void> q(String nome, Mood m, QuadroFixo quadro) =>
          grava(tester, sp, m, quadro, '$p/$nome');
      await q('contente', Mood.content, const QuadroFixo());
      await q('radiante', Mood.radiant, const QuadroFixo());
      await q('neutro', Mood.neutral, const QuadroFixo());
      await q('saudade', Mood.missingYou, const QuadroFixo());
      await q('sono', Mood.sleepy, const QuadroFixo());
      await q(
        'susto',
        Mood.content,
        const QuadroFixo(vida: SaidaDaVida(susto: 1)),
      );
      await q(
        'espanto',
        Mood.content,
        const QuadroFixo(vida: SaidaDaVida(susto: 0.65)),
      );
      await q(
        'grito',
        Mood.content,
        const QuadroFixo(vida: SaidaDaVida(grito: 1)),
      );
      await q(
        'riso-aberto',
        Mood.content,
        const QuadroFixo(vida: SaidaDaVida(riso: 1)),
      );
      await q(
        'riso-fechado',
        Mood.content,
        const QuadroFixo(vida: SaidaDaVida(riso: 0.12)),
      );
      await q(
        'festa-pico',
        Mood.radiant,
        const QuadroFixo(
          pisca: 1,
          vida: SaidaDaVida(festa: 1, altura: 9, achata: -0.2),
        ),
      );
      await q(
        'festa-pouso',
        Mood.radiant,
        const QuadroFixo(vida: SaidaDaVida(festa: 1, achata: 0.4)),
      );
      await q('meiapisca', Mood.content, const QuadroFixo(pisca: 0.5));
      await q('pisca', Mood.content, const QuadroFixo(pisca: 1));
      await q('meiapisca-neutro', Mood.neutral, const QuadroFixo(pisca: 0.5));
      await q('pisca-sono', Mood.sleepy, const QuadroFixo(pisca: 1));
      for (final (nome, olhar) in [
        ('olhar-esq', const Offset(-1, 0)),
        ('olhar-dir', const Offset(1, 0)),
        ('olhar-cima', const Offset(0, -1)),
        ('olhar-baixo', const Offset(0, 1)),
      ]) {
        await q(
          nome,
          Mood.content,
          QuadroFixo(vida: SaidaDaVida(olhar: olhar)),
        );
      }
    }
  });

  testWidgets(
    'sequências do motor: susto e festa, 30 quadros a 30 qps (x2)',
    skip: !_ligado,
    (tester) async {
      for (final sp in especies) {
        final p = sp.name;
        final log = <String, List<Map<String, double>>>{};
        for (final (nome, dispara) in [
          ('susto-seq', (MotorDeVida m) => m.assusta()),
          ('festa-seq', (MotorDeVida m) => m.comemora(duracao: 3)),
          ('grito-seq', (MotorDeVida m) => m.grita()),
          ('riso-seq', (MotorDeVida m) => m.ri()),
        ]) {
          final m = motor(sp);
          for (var i = 0; i < 90; i++) {
            m.passo(1 / 30);
          }
          dispara(m);
          final quadros = <Map<String, double>>[];
          for (var i = 0; i < 30; i++) {
            final s = m.passo(1 / 30);
            quadros.add(registro(s));
            if (nome == 'susto-seq' || nome == 'festa-seq') {
              await grava(
                tester,
                sp,
                nome == 'festa-seq' ? Mood.radiant : Mood.content,
                QuadroFixo(respiro: s.respiro, pisca: s.pisca, vida: s),
                '$p/$nome/$i',
                ratio: 2,
              );
            }
          }
          log[nome] = quadros;
        }
        File('$_pasta/$p/seq.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonEncode(log));
      }
    },
  );

  test('piscadas em 30 s do motor (capivara e coruja)', skip: !_ligado, () {
    final saida = <String, List<double>>{};
    for (final sp in [Species.capybara, Species.owl]) {
      final m = motor(sp)
        ..medianaDoPiscar = sp == Species.owl ? 4.6 : 3.6
        ..maxIntervaloDoPiscar = sp == Species.owl ? 3.2 : 12.0;
      final piscas = <double>[];
      for (var i = 0; i < 900; i++) {
        piscas.add(m.passo(1 / 30).pisca);
      }
      saida[sp.name] = piscas;
    }
    File('$_pasta/piscadas.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(saida));
  });
}
