// As animações do site (baru.lhcx.tech), tiradas do desenho do app.
//
// O site não roda Flutter. Para o bicho dele andar, voar e nadar como no
// app — e não deslizar de um lado para o outro —, este teste fotografa as
// poses do motor de vida quadro a quadro, pelo mesmo `PetView`, e grava os
// quadros em `build/animacoes_site/`. `tool/folhas_do_site.py` junta cada
// sequência numa folha de sprites para o site.
//
// O passo replica a conta de `MotorDeVida._passo` com o passo inteiro
// (intensidade 1): saltitando (capivara, lontra, gata, raposa, buldogue,
// coruja) ou gingando (tartaruga, pinguim, axolote). O voo, a braçada e a
// brincadeira são o laço de cada ação, de 0 a 1.
//
// A respiração, o sono e as fases saem em densidade 3: aparecem grandes na
// tela (o bicho principal do topo, o palco das fases). O resto sai em 1,5. O `animacoes.json` traz a densidade
// de cada folha (`d`) para o site manter todos na mesma escala.
//
// Só roda com CAPTURAS=1:
//   CAPTURAS=1 flutter test test/animacoes_site_test.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:baru_app/data/crescimento.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:baru_app/widgets/vida/motor_de_vida.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _ligado = Platform.environment['CAPTURAS'] == '1';
const _pasta = 'build/animacoes_site';

/// O quadro: largo o bastante para a asa aberta e o salto.
const _tamanho = Size(260, 220);
const _densidade = 1.5;

/// Quem anda aos saltinhos (`JeitoDeCacar.saltita`, em pet.dart).
const _saltitam = {
  Species.capybara, Species.otter, Species.cat, Species.fox,
  Species.frenchie, Species.owl,
};

/// Quem nada (acaoDoBicho: nado). A coruja voa; gata e raposa brincam.
const _nadam = {
  Species.capybara, Species.otter, Species.tortoise, Species.penguin,
  Species.axolotl,
};

/// O passo inteiro numa fase `f` (0..1 é um ciclo: dois passos). Correndo
/// (atrás da bola), o quique é de galope, o corpo pende bem mais para a
/// frente e cada pata que bate levanta poeira — `MotorDeVida._passo`.
SaidaDaVida passoNa(double f, {required bool saltita, bool correndo = false}) {
  final fase = f * 2 * math.pi;
  final onda = math.sin(fase);
  final arco = math.sin(math.pi * ((f * 2) % 1));
  final sobe = saltita
      ? arco * (correndo ? 12.0 : 7.0)
      : (1 - math.cos(2 * fase)) / 2 * (correndo ? 8.0 : 3.0);
  final s = (f * 2) % 1;
  final elastico = saltita
      ? (s < 0.14
          ? (1 - s / 0.14) * 0.9
          : s > 0.9
          ? (s - 0.9) / 0.1 * 0.9
          : -math.sin(math.pi * (s - 0.14) / 0.76) * 0.55)
      : math.pow(math.cos(fase).abs(), 8) * 0.55 -
          (1 - math.pow(math.cos(fase).abs(), 8)) * 0.15;
  final par = (f * 2).floor().isEven;
  return SaidaDaVida(
    respiro: math.sin(fase) * 0.2,
    passada: onda,
    gingado: saltita ? 0 : onda * 0.045,
    andando: 1,
    inclina: correndo ? 0.10 : 0.03,
    corrida: correndo ? 1 : 0,
    // A poeira das duas últimas pisadas, atrás de quem corre (x, idade 0..1).
    poeira: correndo
        ? [Offset(-16, (f * 2) % 1), Offset(-22, ((f * 2) % 1 + 0.5) % 1)]
        : const [],
    elastico: elastico.toDouble(),
    pataEsquerda: saltita ? arco * (par ? 1.0 : 0.35) : math.max(0.0, onda),
    pataDireita: saltita ? arco * (par ? 0.35 : 1.0) : math.max(0.0, -onda),
    desloca: Offset(0, -sobe),
    // A cabeça para onde vai (direita); o site espelha para a volta.
    olhar: const Offset(0.8, 0),
    virada: const Offset(0.7, 0),
    corpoLivre: true,
  );
}

Widget _cena(Species sp, Activity atv, QuadroFixo q,
        {EstagioDoBicho estagio = EstagioDoBicho.adulto, Mood humor = Mood.content, Color? agua}) =>
    SizedBox(
      width: _tamanho.width,
      height: _tamanho.height,
      child: PetView(
        species: sp,
        mood: humor,
        activity: atv,
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

  Future<void> grava(WidgetTester tester, Widget w, String nome, {double densidade = _densidade}) async {
    final chave = GlobalKey();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: RepaintBoundary(key: chave, child: w)),
    ));
    final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await b.toImage(pixelRatio: densidade);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      File('$_pasta/$nome.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  const n = 12;
  double t(int i) => i / n;

  testWidgets('o passo de cada bicho', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (var i = 0; i < n; i++) {
        await grava(
          tester,
          _cena(sp, Activity.idle, QuadroFixo(
            acao: AcaoDoBicho.ocioso,
            vida: passoNa(t(i), saltita: _saltitam.contains(sp)),
          )),
          'anda-${sp.name}/$i',
        );
      }
    }
  });

  testWidgets('a corrida atrás da bola', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (var i = 0; i < n; i++) {
        await grava(
          tester,
          _cena(sp, Activity.idle, QuadroFixo(
            acao: AcaoDoBicho.ocioso,
            vida: passoNa(t(i), saltita: _saltitam.contains(sp), correndo: true),
          ), humor: Mood.radiant),
          'corre-${sp.name}/$i',
        );
      }
    }
  });

  // Comer: a bocada (a cabeça desce até a comida e volta) e a mastigação de
  // cabeça erguida, com a comida na boca. Capivara e tartaruga pastam (a
  // cabeça vai mais fundo, no capim); as outras sete petiscam
  // (`acaoDoBicho` com Activity.graze decide).
  testWidgets('o episódio de comer', skip: !_ligado, (tester) async {
    const quadros = 16;
    for (final sp in Species.values) {
      for (var i = 0; i < quadros; i++) {
        final f = i / quadros;
        // 0..0,35: a bocada; 0,35..1: mastiga (quatro mordidas).
        final bocada = f < 0.35 ? math.sin(math.pi * f / 0.35) : 0.0;
        final mastiga = f < 0.35 ? 0.0 : 0.5 - 0.5 * math.cos((f - 0.35) / 0.65 * math.pi * 2 * 4);
        await grava(
          tester,
          _cena(sp, Activity.graze, QuadroFixo(
            respiro: math.sin(f * 2 * math.pi) * 0.3,
            vida: SaidaDaVida(
              atividadeAtiva: true,
              corpoLivre: false,
              cabecaNoChao: bocada,
              mastigando: mastiga,
              comendo: f >= 0.3,
              cicloDaAtividade: f,
            ),
          )),
          'come-${sp.name}/$i',
        );
      }
    }
  });

  testWidgets('o voo da coruja', skip: !_ligado, (tester) async {
    for (var i = 0; i < n; i++) {
      final f = t(i);
      await grava(
        tester,
        _cena(Species.owl, Activity.swim, QuadroFixo(
          acao: AcaoDoBicho.voo,
          ciclo: f,
          vida: SaidaDaVida(
            voando: true,
            atividadeAtiva: true,
            corpoLivre: false,
            cicloDaAtividade: f,
            forcaDaAtividade: 1,
            altura: 30,
            desloca: Offset(0, -math.sin(f * 2 * math.pi) * 4.5),
          ),
        )),
        'voa-owl/$i',
      );
    }
  });

  testWidgets('a braçada de quem nada', skip: !_ligado, (tester) async {
    for (final sp in _nadam) {
      for (var i = 0; i < n; i++) {
        final f = t(i);
        await grava(
          tester,
          _cena(sp, Activity.swim, QuadroFixo(
            acao: AcaoDoBicho.nado,
            ciclo: f,
            vida: SaidaDaVida(
              atividadeAtiva: true,
              corpoLivre: false,
              cicloDaAtividade: f,
              forcaDaAtividade: 1,
              boia: math.sin(f * 2 * math.pi),
            ),
          ), agua: const Color(0xFF7FC0D6), humor: Mood.radiant),
          'nada-${sp.name}/$i',
        );
      }
    }
  });

  testWidgets('a brincadeira da gata e da raposa', skip: !_ligado, (tester) async {
    for (final sp in [Species.cat, Species.fox]) {
      for (var i = 0; i < n; i++) {
        final f = t(i);
        await grava(
          tester,
          _cena(sp, Activity.swim, QuadroFixo(
            acao: AcaoDoBicho.brincadeira,
            ciclo: f,
            vida: SaidaDaVida(atividadeAtiva: true, corpoLivre: false, cicloDaAtividade: f, forcaDaAtividade: 1),
          ), humor: Mood.radiant),
          'brinca-${sp.name}/$i',
        );
      }
    }
  });

  testWidgets('o sono e o fôlego', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (var i = 0; i < 8; i++) {
        final r = math.sin(i / 8 * 2 * math.pi);
        await grava(
          tester,
          _cena(sp, Activity.nap, QuadroFixo(respiro: r, acao: AcaoDoBicho.cochilo), humor: Mood.sleepy),
          'dorme-${sp.name}/$i',
          densidade: 3,
        );
        await grava(
          tester,
          _cena(sp, Activity.idle, QuadroFixo(respiro: r, pisca: i == 5 ? 1 : 0)),
          'respira-${sp.name}/$i',
          densidade: 3,
        );
      }
    }
  });

  testWidgets('as cinco fases de cada espécie', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (final e in EstagioDoBicho.values) {
        await grava(tester, _cena(sp, Activity.idle, const QuadroFixo(), estagio: e), 'fase-${sp.name}/${e.name}', densidade: 3);
      }
    }
  });
}
