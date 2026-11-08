// Atlas da turma do Baru: todos os estados paráveis de cada espécie, em PNG,
// para auditoria visual (boca por nível, humores, piscada, susto, festa,
// olhar, virada, poses do corpo, estágios, comendo, água). Só com CAPTURAS=1.
//
//   CAPTURAS=1 flutter test test/atlas_novelinha_test.dart
//   CAPTURAS=1 ESPECIES=otter,fox flutter test test/atlas_novelinha_test.dart
//
// Sai em build/atlas/<espécie>/<estado>.png (caixa 260×220, ×4).
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
const _pasta = 'build/atlas';
const _tamanho = Size(260, 220);
const _densidade = 4.0;

Widget _cena(
  Species sp,
  Mood humor,
  QuadroFixo q, {
  Activity atividade = Activity.idle,
  EstagioDoBicho estagio = EstagioDoBicho.adulto,
  Color? agua,
}) => SizedBox(
  width: _tamanho.width,
  height: _tamanho.height,
  child: PetView(
    species: sp,
    mood: humor,
    activity: atividade,
    coat: 0,
    estagio: estagio,
    interativo: false,
    width: _tamanho.width,
    height: _tamanho.height,
    corDaAgua: agua,
    quadro: q,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> grava(WidgetTester tester, Widget w, String nome) async {
    final chave = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RepaintBoundary(key: chave, child: w)),
      ),
    );
    final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await b.toImage(pixelRatio: _densidade);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      File('$_pasta/$nome.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  final quais = Platform.environment['ESPECIES']?.split(',');
  final especies = Species.values
      .where((s) => quais == null || quais.contains(s.name))
      .toList();
  const humores = {
    'contente': Mood.content,
    'radiante': Mood.radiant,
    'neutro': Mood.neutral,
    'sono': Mood.sleepy,
    'saudade': Mood.missingYou,
  };

  testWidgets('atlas: boca, humor, piscada, susto, festa', skip: !_ligado, (
    tester,
  ) async {
    for (final sp in especies) {
      final n = sp.name;
      for (final h in humores.entries) {
        for (final b in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]) {
          await grava(
            tester,
            _cena(sp, h.value, QuadroFixo(vida: SaidaDaVida(boca: b))),
            '$n/boca-${h.key}-${(b * 10).round()}',
          );
        }
        await grava(
          tester,
          _cena(sp, h.value, const QuadroFixo(pisca: 1)),
          '$n/pisca-${h.key}',
        );
        await grava(
          tester,
          _cena(sp, h.value, const QuadroFixo(pisca: 0.5)),
          '$n/meiapisca-${h.key}',
        );
      }
      for (final b in [0.0, 0.5, 1.0]) {
        await grava(
          tester,
          _cena(sp, Mood.content, QuadroFixo(vida: SaidaDaVida(susto: 1, boca: b))),
          '$n/susto-${(b * 10).round()}',
        );
        await grava(
          tester,
          _cena(sp, Mood.radiant, QuadroFixo(vida: SaidaDaVida(festa: 1, boca: b))),
          '$n/festa-${(b * 10).round()}',
        );
      }
    }
  });

  testWidgets('atlas: olhar, virada, gestos de cabeça', skip: !_ligado, (
    tester,
  ) async {
    for (final sp in especies) {
      final n = sp.name;
      const olhares = {
        'esq': Offset(-1, 0),
        'dir': Offset(1, 0),
        'cima': Offset(0, -1),
        'baixo': Offset(0, 1),
      };
      for (final o in olhares.entries) {
        await grava(
          tester,
          _cena(sp, Mood.content, QuadroFixo(vida: SaidaDaVida(olhar: o.value))),
          '$n/olhar-${o.key}',
        );
        await grava(
          tester,
          _cena(
            sp,
            Mood.content,
            QuadroFixo(vida: SaidaDaVida(olhar: o.value, virada: o.value)),
          ),
          '$n/virada-${o.key}',
        );
      }
      await grava(
        tester,
        _cena(sp, Mood.content, const QuadroFixo(vida: SaidaDaVida(cabecaGiro: 0.35))),
        '$n/cabeca-giro',
      );
      await grava(
        tester,
        _cena(sp, Mood.content, const QuadroFixo(vida: SaidaDaVida(cabecaDesce: 14))),
        '$n/cabeca-desce',
      );
      await grava(
        tester,
        _cena(sp, Mood.content, const QuadroFixo(vida: SaidaDaVida(inclina: 0.25))),
        '$n/inclina',
      );
    }
  });

  testWidgets('atlas: poses do corpo, comendo, água, estágios', skip: !_ligado, (
    tester,
  ) async {
    for (final sp in especies) {
      final n = sp.name;
      const poses = {
        'deita': SaidaDaVida(deita: 1),
        'reverencia': SaidaDaVida(reverencia: 1),
        'estica': SaidaDaVida(elastico: -0.9, altura: 40, desloca: Offset(0, -40)),
        'achata': SaidaDaVida(elastico: 0.9),
        'achata-pouso': SaidaDaVida(achata: 1),
        'carregado': SaidaDaVida(carregado: true, altura: 60, desloca: Offset(0, -60)),
        'dedo': SaidaDaVida(dente: Offset(0, -10), denteForca: 1),
        'derretido': SaidaDaVida(derretido: 1),
        'emburrado': SaidaDaVida(emburrado: true),
        'pescoco-recolhe': SaidaDaVida(pescoco: -4.2),
        'pescoco-estica': SaidaDaVida(pescoco: 1),
        'mastiga': SaidaDaVida(atividadeAtiva: true, comendo: true, mastigando: 0.8),
        'come-fechado': SaidaDaVida(atividadeAtiva: true, comendo: true, mastigando: 0.0),
        'giro-meio': SaidaDaVida(giro: 0.5),
      };
      for (final p in poses.entries) {
        await grava(
          tester,
          _cena(sp, Mood.content, QuadroFixo(vida: p.value)),
          '$n/pose-${p.key}',
        );
      }
      await grava(
        tester,
        _cena(sp, Mood.sleepy, const QuadroFixo(vida: SaidaDaVida(adormecido: true, deita: 1)), atividade: Activity.nap),
        '$n/pose-dormindo',
      );
      // Na água: parado e remando.
      for (final c in [0.0, 0.25, 0.5, 0.75]) {
        await grava(
          tester,
          _cena(
            sp,
            Mood.content,
            QuadroFixo(acao: AcaoDoBicho.nado, ciclo: c, vida: SaidaDaVida(atividadeAtiva: true, cicloDaAtividade: c, forcaDaAtividade: 1)),
            atividade: Activity.swim,
            agua: const Color(0xFF7FB7A6),
          ),
          '$n/agua-${(c * 100).round()}',
        );
      }
      for (final e in EstagioDoBicho.values) {
        await grava(
          tester,
          _cena(sp, Mood.content, const QuadroFixo(), estagio: e),
          '$n/estagio-${e.name}',
        );
      }
      // Fôlego: peito cheio e vazio.
      await grava(tester, _cena(sp, Mood.content, const QuadroFixo(respiro: 1)), '$n/respiro-cheio');
      await grava(tester, _cena(sp, Mood.content, const QuadroFixo(respiro: -1)), '$n/respiro-vazio');
    }
  });
}
