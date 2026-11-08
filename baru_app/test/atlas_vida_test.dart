// Ep. 4 (estreia da Faísca) + quadros que faltavam no R2. Novelinha "A turma do Baru" (v2 da auditoria): ciclos de vida do MotorDeVida com menos piscadas, a tartaruga encolhida no casco
// (pescoço recolhido do app, falando e dormindo) e a coruja virando o rosto para o lado (virada + giro da cabeça). Só com CAPTURAS=1.
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
const _pasta = 'build/atlas_vida';
SaidaDaVida com(SaidaDaVida s, {double boca = 0, double? pescoco, Offset? olhar, Offset? virada, double? cabecaGiro}) =>
    SaidaDaVida(respiro: s.respiro, boia: s.boia, cauda: s.cauda, ciclo: s.ciclo, olhar: olhar ?? s.olhar, inclina: s.inclina, achata: s.achata, desloca: s.desloca, virado: s.virado, balanco: s.balanco, carregado: s.carregado, altura: s.altura, pisca: s.pisca, emburrado: s.emburrado, derretido: s.derretido, passada: s.passada, gingado: s.gingado, andando: s.andando, planando: s.planando, freando: s.freando, deita: s.deita, comendo: s.comendo, reverencia: s.reverencia, giro: s.giro, adormecido: s.adormecido, elastico: s.elastico, dente: s.dente, denteForca: s.denteForca, susto: s.susto, festa: s.festa, planeio: s.planeio, freio: s.freio, corrida: s.corrida, poeira: s.poeira, pataEsquerda: s.pataEsquerda, pataDireita: s.pataDireita, virada: s.virada, cabecaAtraso: s.cabecaAtraso, cabecaGiro: s.cabecaGiro, cabecaDesce: s.cabecaDesce, atividadeAtiva: s.atividadeAtiva, corpoLivre: s.corpoLivre, cabecaNoChao: s.cabecaNoChao, mastigando: s.mastigando, forcaDaAtividade: s.forcaDaAtividade, cicloDaAtividade: s.cicloDaAtividade, voando: s.voando,  boca: boca, pescoco: pescoco ?? s.pescoco);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> grava(WidgetTester tester, Species sp, Mood m, QuadroFixo q, String nome, double ratio) async {
    final chave = GlobalKey();
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: RepaintBoundary(key: chave, child: SizedBox(width: 260, height: 220,
        child: PetView(species: sp, mood: m, activity: Activity.idle, coat: 0, estagio: EstagioDoBicho.adulto, interativo: false, width: 260, height: 220, quadro: q))))));
    final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async { final img = await b.toImage(pixelRatio: ratio); final png = await img.toByteData(format: ui.ImageByteFormat.png); img.dispose();
      File('$_pasta/$nome.png')..createSync(recursive: true)..writeAsBytesSync(png!.buffer.asUint8List()); });
  }
  MotorDeVida motor(Species sp) => MotorDeVida(semente: sp.index * 31 + 7)
    ..podeAndar = false ..energia = 0.75 ..periodoRespiro = 3.2 ..repertorio = const {} ..medianaDoPiscar = 6.0
    ..jeito = sp == Species.tortoise ? const JeitoDeCacar(velocidade: 12) : const JeitoDeCacar(saltita: true);
  final quais = (Platform.environment['ESPECIES'] ?? 'otter,fox,axolotl').split(',');
  testWidgets('quadros: fala, humores, susto e festa (x3)', skip: !_ligado, (tester) async {
    const humores = {'contente': Mood.content, 'radiante': Mood.radiant, 'sono': Mood.sleepy, 'saudade': Mood.missingYou};
    for (final sp in Species.values.where((s) => quais.contains(s.name))) {
      var n = 0;
      for (final h in humores.entries) {
        for (var i = 0; i < 6; i++) { await grava(tester, sp, h.value, QuadroFixo(vida: SaidaDaVida(boca: i / 5)), 'bicho-${sp.name}/${n++}', 3); }
        await grava(tester, sp, h.value, const QuadroFixo(pisca: 1), 'bicho-${sp.name}/${n++}', 3);
      }
      for (var i = 0; i < 6; i++) { await grava(tester, sp, Mood.content, QuadroFixo(vida: SaidaDaVida(susto: 1, boca: i / 5)), 'bicho-${sp.name}/${28 + i}', 3); }
      for (var i = 0; i < 6; i++) { await grava(tester, sp, Mood.radiant, QuadroFixo(vida: SaidaDaVida(festa: 1, boca: i / 5)), 'bicho-${sp.name}/${34 + i}', 3); }
    }
  });
  testWidgets('vida (x2): laço de 120 quadros em 3 bocas; toco encolhido; coruja de lado e olhando pro céu', skip: !_ligado, (tester) async {
    final piscas = <String, List<int>>{};
    for (final sp in Species.values.where((s) => quais.contains(s.name) || (s == Species.tortoise && quais.contains('tortoise_enc')))) {
      final m = motor(sp); for (var i = 0; i < 90; i++) { m.passo(1 / 30); }
      final so = sp == Species.tortoise && !quais.contains('tortoise');
      for (var i = 0; i < 120; i++) { final s = m.passo(1 / 30);
        if (s.pisca > 0.15) { piscas.putIfAbsent(sp.name, () => []).add(i); }
        for (final (k, b) in [(0, 0.0), (1, 0.4), (2, 0.85)]) {
          if (!so) await grava(tester, sp, Mood.content, QuadroFixo(respiro: s.respiro, pisca: s.pisca, vida: com(s, boca: b)), 'vida-${sp.name}-$k/$i', 2);
          if (sp == Species.tortoise) await grava(tester, sp, Mood.content, QuadroFixo(respiro: s.respiro, pisca: s.pisca, vida: com(s, boca: b, pescoco: -4.2)), 'vida-tortoise_enc-$k/$i', 2);
        }
        if (sp == Species.tortoise) await grava(tester, sp, Mood.sleepy, QuadroFixo(respiro: s.respiro, vida: com(s, pescoco: -4.2)), 'vida-tortoise_dorme-0/$i', 2);
      }
    }
    File('$_pasta/piscas.json')..createSync(recursive: true)..writeAsStringSync(piscas.toString());
    if (quais.contains('owl')) {
      final m = motor(Species.owl); for (var i = 0; i < 90; i++) { m.passo(1 / 30); }
      for (var i = 0; i < 30; i++) { final s = m.passo(1 / 30); final k = i / 29, e = k * k * (3 - 2 * k);
        await grava(tester, Species.owl, Mood.content, QuadroFixo(respiro: s.respiro,
            vida: SaidaDaVida(respiro: s.respiro, olhar: Offset(1.3 * e, -0.1 * e), virada: Offset(1.0 * e, 0), cabecaGiro: 0.5 * e)), 'lado-owl-0/$i', 2);
      }
      for (var i = 0; i < 24; i++) { final k = i / 23, e = k * k * (3 - 2 * k);
        await grava(tester, Species.owl, Mood.content, QuadroFixo(vida: SaidaDaVida(olhar: Offset(1.0 * e, -1.0 * e), susto: 0.35 * e)), 'cima-owl-0/$i', 2);
      }
    }
  });
}
