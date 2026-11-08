// Ep. 4 (estreia da Faísca) + quadros que faltavam no R2. Novelinha "A turma do Baru" (v2 da auditoria): ciclos de vida do MotorDeVida com menos piscadas, a tartaruga encolhida no casco
// (pescoço recolhido do app, falando e dormindo) e a coruja virando o rosto para o lado (virada + giro da cabeça). Só com CAPTURAS=1.
//
// O LAÇO DE VIDA FECHA: os 120 quadros (4 s a 30 fps) são um laço para a
// frente, sem pingue-pongue (laudo 34 R4, MOV-12). Tocado ao contrário, a
// piscada abria rápido e fechava devagar e a cabeça puxava o olho. Para o
// quadro 119 → 0 ser contínuo: o motor roda 360 quadros depois do
// aquecimento, escolhe-se a janela de 120 cuja emenda (119 → 0) é a menor,
// com 1–2 piscadas normais (5–9 quadros) e nenhuma a menos de 14 quadros da
// emenda, e os 12 primeiros quadros são uma mistura (lerp dos campos de
// `SaidaDaVida`) com os 12 que viriam depois do quadro 119. A respiração
// tem período 2 s (dois fôlegos por laço). A medida da emenda sai em
// `build/atlas_vida/laco.json` (nos campos do motor) e em
// `test/movimento_medidas.py` (nos pixels: diff 119→0 ÷ média do laço ≤ 2).
//
// As folhas da fala (-1 e -2) saem com pisca 0: o site não precisa recuar
// o índice para fugir da piscada no meio da fala (MOV-13).
//
//   CAPTURAS=1 ESPECIES=todas flutter test test/atlas_vida_test.dart
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
SaidaDaVida com(SaidaDaVida s, {double boca = 0, double? pescoco, Offset? olhar, Offset? virada, double? cabecaGiro, double? pisca}) =>
    SaidaDaVida(respiro: s.respiro, boia: s.boia, cauda: s.cauda, ciclo: s.ciclo, olhar: olhar ?? s.olhar, inclina: s.inclina, achata: s.achata, desloca: s.desloca, virado: s.virado, balanco: s.balanco, carregado: s.carregado, altura: s.altura, pisca: pisca ?? s.pisca, emburrado: s.emburrado, derretido: s.derretido, passada: s.passada, gingado: s.gingado, andando: s.andando, planando: s.planando, freando: s.freando, deita: s.deita, comendo: s.comendo, reverencia: s.reverencia, giro: s.giro, adormecido: s.adormecido, elastico: s.elastico, dente: s.dente, denteForca: s.denteForca, susto: s.susto, festa: s.festa, planeio: s.planeio, freio: s.freio, corrida: s.corrida, poeira: s.poeira, pataEsquerda: s.pataEsquerda, pataDireita: s.pataDireita, virada: virada ?? s.virada, cabecaAtraso: s.cabecaAtraso, cabecaGiro: cabecaGiro ?? s.cabecaGiro, cabecaDesce: s.cabecaDesce, atividadeAtiva: s.atividadeAtiva, corpoLivre: s.corpoLivre, cabecaNoChao: s.cabecaNoChao, mastigando: s.mastigando, forcaDaAtividade: s.forcaDaAtividade, cicloDaAtividade: s.cicloDaAtividade, voando: s.voando, faseDoPasso: s.faseDoPasso, boca: boca, pescoco: pescoco ?? s.pescoco);

/// Mistura os campos contínuos de dois quadros do motor (a costura do laço).
SaidaDaVida mistura(SaidaDaVida a, SaidaDaVida b, double t) {
  double d(double x, double y) => x + (y - x) * t;
  Offset o(Offset x, Offset y) => Offset.lerp(x, y, t)!;
  // O ciclo dá a volta em 1: mistura pelo caminho mais curto.
  final ciclo = (a.ciclo + (((b.ciclo - a.ciclo + 0.5) % 1) - 0.5) * t) % 1;
  return SaidaDaVida(respiro: d(a.respiro, b.respiro), boia: d(a.boia, b.boia), cauda: d(a.cauda, b.cauda), ciclo: ciclo, olhar: o(a.olhar, b.olhar), inclina: d(a.inclina, b.inclina), achata: d(a.achata, b.achata), desloca: o(a.desloca, b.desloca), virado: t < 0.5 ? a.virado : b.virado, balanco: d(a.balanco, b.balanco), altura: d(a.altura, b.altura), pisca: d(a.pisca, b.pisca), derretido: d(a.derretido, b.derretido), passada: d(a.passada, b.passada), gingado: d(a.gingado, b.gingado), andando: d(a.andando, b.andando), deita: d(a.deita, b.deita), reverencia: d(a.reverencia, b.reverencia), adormecido: a.adormecido, elastico: d(a.elastico, b.elastico), susto: d(a.susto, b.susto), festa: d(a.festa, b.festa), pataEsquerda: d(a.pataEsquerda, b.pataEsquerda), pataDireita: d(a.pataDireita, b.pataDireita), virada: o(a.virada, b.virada), cabecaAtraso: o(a.cabecaAtraso, b.cabecaAtraso), cabecaGiro: d(a.cabecaGiro, b.cabecaGiro), cabecaDesce: d(a.cabecaDesce, b.cabecaDesce), atividadeAtiva: a.atividadeAtiva, corpoLivre: a.corpoLivre, pescoco: d(a.pescoco, b.pescoco), faseDoPasso: a.faseDoPasso,
      // O axolote vive na água: a força e a fase da remada entram no desenho dele mesmo à toa (sem isto os 12 quadros da costura remavam com força 1).
      forcaDaAtividade: d(a.forcaDaAtividade, b.forcaDaAtividade), cicloDaAtividade: a.cicloDaAtividade, cabecaNoChao: d(a.cabecaNoChao, b.cabecaNoChao), mastigando: d(a.mastigando, b.mastigando), comendo: a.comendo, giro: a.giro, planeio: d(a.planeio, b.planeio), freio: d(a.freio, b.freio), corrida: d(a.corrida, b.corrida), emburrado: a.emburrado, carregado: a.carregado, voando: a.voando);
}

/// Distância entre dois quadros do motor, nos campos que mexem o desenho
/// (pesos ≈ pixels por unidade de cada campo).
double distancia(SaidaDaVida a, SaidaDaVida b) =>
    (a.respiro - b.respiro).abs() * 5 + (a.boia - b.boia).abs() * 3 + (a.cauda - b.cauda).abs() * 4 + (a.olhar - b.olhar).distance * 20 +
    (a.inclina - b.inclina).abs() * 60 + (a.achata - b.achata).abs() * 10 + (a.desloca - b.desloca).distance + (a.pisca - b.pisca).abs() * 10 +
    (a.virada - b.virada).distance * 12 + (a.cabecaAtraso - b.cabecaAtraso).distance + (a.cabecaGiro - b.cabecaGiro).abs() * 60 + (a.cabecaDesce - b.cabecaDesce).abs() +
    // Espelhado de um lado e não do outro: o corpo inteiro pula.
    (a.virado != b.virado ? 200 : 0);

/// Os grupos de quadros piscando (início, duração) numa sequência.
List<(int, int)> grupos(List<SaidaDaVida> seq) {
  final g = <(int, int)>[];
  for (var i = 0; i < seq.length; i++) {
    if (seq[i].pisca <= 0.15) continue;
    if (g.isNotEmpty && g.last.$1 + g.last.$2 == i) { g[g.length - 1] = (g.last.$1, g.last.$2 + 1); } else { g.add((i, 1)); }
  }
  return g;
}

/// Escolhe, nos 360 quadros, a janela de 120 que melhor fecha, e costura.
/// Devolve (quadros, emenda ÷ média, começo).
(List<SaidaDaVida>, double, int) laco(List<SaidaDaVida> seq, {int n = 120, int costura = 12, int folga = 14}) {
  List<SaidaDaVida> costurado(int i) {
    final w = seq.sublist(i, i + n);
    for (var k = 0; k < costura; k++) { w[k] = mistura(w[k], seq[i + n + k], (costura - k) / (costura + 1)); }
    return w;
  }
  // (emenda ÷ média, maior passo ÷ média) do laço costurado.
  (double, double) mede(List<SaidaDaVida> w) {
    var media = 0.0; var maior = 0.0;
    for (var k = 0; k < n - 1; k++) { final d = distancia(w[k], w[k + 1]); media += d; if (d > maior) maior = d; }
    media /= n - 1;
    if (media <= 0) media = 1e-9;
    return (distancia(w[n - 1], w[0]) / media, maior / media);
  }
  var melhor = -1; var melhorNota = double.infinity;
  for (var i = 0; i + n + costura + 2 <= seq.length; i++) {
    final w = costurado(i);
    final gs = grupos(w);
    // 1–2 piscadas de ≤ 10 quadros, longe da emenda, e nenhuma nos quadros
    // que entram na costura (os que viriam depois do 119).
    final ok = gs.isNotEmpty && gs.length <= 2 && gs.every((g) => g.$2 <= 10 && g.$1 >= folga && g.$1 + g.$2 <= n - folga) &&
        seq.sublist(i + n, i + n + costura + 2).every((s) => s.pisca <= 0.15 && s.virado == w.first.virado) &&
        w.every((s) => s.virado == w.first.virado);
    final (emenda, pop) = mede(w);
    // Sem tranco no laço: o maior passo pesa, e uma inclinação do corpo
    // inteiro (a curiosidade do "chamar") que não volta é descartada.
    var inclinaMin = double.infinity, inclinaMax = -double.infinity;
    for (final s in w) { if (s.inclina < inclinaMin) inclinaMin = s.inclina; if (s.inclina > inclinaMax) inclinaMax = s.inclina; }
    final nota = emenda + 0.3 * pop + (inclinaMax - inclinaMin > 0.08 ? 50 : 0) + (ok ? 0 : 1000);
    if (nota < melhorNota) { melhorNota = nota; melhor = i; }
  }
  final w = costurado(melhor);
  final (emenda, _) = mede(w);
  if (melhorNota >= 1000) debugPrint('laço sem janela com 1–2 piscadas longe da emenda (começo $melhor)');
  return (w, emenda, melhor);
}

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
  // Respiração de 2 s (dois fôlegos por laço de 4 s), piscadas a cada ~2,2 s
  // (1–2 por laço), o jeito da espécie (cauda, locomoção).
  MotorDeVida motor(Species sp) => MotorDeVida(semente: sp.index * 31 + 7)
    ..podeAndar = false ..energia = 0.75 ..periodoRespiro = 2.0 ..repertorio = const {} ..medianaDoPiscar = 2.2
    ..jeito = jeitoDaEspecie(sp);
  final pedidas = (Platform.environment['ESPECIES'] ?? 'otter,fox,axolotl').split(',');
  final quais = pedidas.contains('todas') ? [for (final s in Species.values) s.name, 'tortoise_enc'] : pedidas;
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
  testWidgets('vida (x2): laço de 120 quadros que fecha, em 3 bocas; toco encolhido; coruja de lado e olhando pro céu', skip: !_ligado, (tester) async {
    final piscas = <String, List<int>>{};
    final lacos = <String, Map<String, num>>{};
    for (final sp in Species.values.where((s) => quais.contains(s.name) || (s == Species.tortoise && quais.contains('tortoise_enc')))) {
      final m = motor(sp); for (var i = 0; i < 90; i++) { m.passo(1 / 30); }
      final seq = [for (var i = 0; i < 360; i++) m.passo(1 / 30)];
      final (quadros, emenda, comeco) = laco(seq);
      lacos[sp.name] = {'comeco': comeco, 'emenda_sobre_media': double.parse(emenda.toStringAsFixed(2)), 'piscadas': grupos(quadros).length};
      final so = sp == Species.tortoise && !quais.contains('tortoise');
      for (var i = 0; i < 120; i++) { final s = quadros[i];
        if (s.pisca > 0.15) { piscas.putIfAbsent(sp.name, () => []).add(i); }
        for (final (k, b) in [(0, 0.0), (1, 0.4), (2, 0.85)]) {
          // Nas bocas da fala (-1, -2) o olho não pisca: a piscada fica na -0.
          final p = k == 0 ? s.pisca : 0.0;
          if (!so) await grava(tester, sp, Mood.content, QuadroFixo(respiro: s.respiro, pisca: p, vida: com(s, boca: b, pisca: p)), 'vida-${sp.name}-$k/$i', 2);
          if (sp == Species.tortoise) await grava(tester, sp, Mood.content, QuadroFixo(respiro: s.respiro, pisca: p, vida: com(s, boca: b, pescoco: -4.2, pisca: p)), 'vida-tortoise_enc-$k/$i', 2);
        }
        if (sp == Species.tortoise) await grava(tester, sp, Mood.sleepy, QuadroFixo(respiro: s.respiro, vida: com(s, pescoco: -4.2)), 'vida-tortoise_dorme-0/$i', 2);
      }
    }
    File('$_pasta/piscas.json')..createSync(recursive: true)..writeAsStringSync(piscas.toString());
    File('$_pasta/laco.json')..createSync(recursive: true)..writeAsStringSync(lacos.toString());
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
