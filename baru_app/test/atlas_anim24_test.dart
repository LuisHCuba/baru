// As animações do site (baru.lhcx.tech), tiradas do desenho do app.
//
// O site não roda Flutter. Para o bicho dele andar, voar e nadar como no
// app — e não deslizar de um lado para o outro —, este teste fotografa as
// poses do motor de vida quadro a quadro, pelo mesmo `PetView`, e grava os
// quadros em `build/atlas_anim24/`. `tool/folhas_do_site.py` junta cada
// sequência numa folha de sprites para o site.
//
// O passo sai da MESMA conta do app (`CicloDoPasso`, em motor_de_vida.dart),
// por tipo de locomoção da espécie (`jeitoDaEspecie`): galope pesado da
// capivara, saltito da lontra/gata/raposa, saltinhos da coruja, gingado do
// pinguim, arrasto da tartaruga, bamboleio do buldogue, ondulação do
// axolote. Cada ciclo são 24 quadros (dois passos), com cabeça atrasada
// 2 quadros, cauda meia fase atrás e as duas metades alternando de lado
// (laudo 34 R1/R2/R5/R7). O voo, a braçada e a brincadeira são o laço de
// cada ação, de 0 a 1, com o quadro 0 num ponto de velocidade zero para o
// laço emendar (MOV-19).
//
// A respiração, o sono e as fases saem em densidade 3: aparecem grandes na
// tela (o bicho principal do topo, o palco das fases). O resto sai em 1,5.
// O `animacoes.json` traz a densidade de cada folha (`d`) para o site manter
// todos na mesma escala.
//
// Medidas: `python3 test/movimento_medidas.py` (patas que levantam, corpo
// ≤ 6 % de squash, emenda, cabeça atrasada…).
//
// Só roda com CAPTURAS=1:
//   CAPTURAS=1 flutter test test/atlas_anim24_test.dart
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
const _pasta = 'build/atlas_anim24';

/// O quadro: largo o bastante para a asa aberta e o salto.
const _tamanho = Size(260, 220);
const _densidade = 1.5;

/// Quem nada (acaoDoBicho: nado). A coruja voa; gata e raposa brincam.
const _nadam = {
  Species.capybara,
  Species.otter,
  Species.tortoise,
  Species.penguin,
  Species.axolotl,
};

/// Quadros por ciclo de andar/correr/nadar/voar/brincar.
const n = 24;

/// O passo inteiro numa fase `f` (0..1 é um ciclo: dois passos), pela
/// locomoção da espécie — a conta de `MotorDeVida._passo` com intensidade
/// 1. Correndo (atrás da bola) a cadência é de galope: o corpo pende 12°
/// para a frente, a cabeça vai à frente, a cauda estica, as duas patas
/// recolhem na fase aérea e cada pisada levanta poeira (MOV-03).
SaidaDaVida passoNa(
  double f, {
  required Species especie,
  bool correndo = false,
}) {
  final loc = jeitoDaEspecie(especie).locomocao;
  final corrida = correndo ? 1.0 : 0.0;
  final c = CicloDoPasso.em(loc, f, corrida: corrida);
  // A cabeça chega 2 quadros depois do corpo (follow-through): ela fica
  // onde o corpo estava dois quadros atrás.
  final antes = CicloDoPasso.em(loc, f - 2 / n, corrida: corrida);
  final fase = f * 2 * math.pi;
  // O desenho sai ESPELHADO (`virado`) com a cabeça virada para o -x do
  // corpo: na folha o bicho olha para a direita (para onde vai; o site
  // espelha para a volta) e a cauda, desenhada no +x do corpo, fica
  // ATRÁS — sem o espelho a raposa andava com a cauda na frente (RAP-10).
  // Por isso o pender e a cabeça adiante entram com o sinal trocado.
  return SaidaDaVida(
    respiro: math.sin(fase) * 0.2,
    passada: math.sin(fase),
    gingado: c.gingado,
    andando: 1,
    inclina: -(0.03 + 0.14 * corrida),
    corrida: corrida,
    // A poeira das duas últimas pisadas, atrás de quem corre (x, idade 0..1).
    poeira: correndo
        ? [Offset(16, (f * 2) % 1), Offset(22, ((f * 2) % 1 + 0.5) % 1)]
        : const [],
    elastico: c.elastico,
    pataEsquerda: c.pataEsquerda,
    pataDireita: c.pataDireita,
    desloca: Offset(0, -c.sobe),
    cauda: c.cauda,
    cabecaAtraso: Offset(-c.cabecaDx, c.sobe - antes.sobe),
    cabecaGiro: c.contraRolo,
    // Correndo, olhos semicerrados.
    pisca: 0.2 * corrida,
    faseDoPasso: f % 1,
    virado: true,
    olhar: const Offset(-0.8, 0),
    virada: const Offset(-0.7, 0),
    corpoLivre: true,
  );
}

/// Interpolação suave (cosseno) numa lista de chaves (fase, valor).
double _chaves(List<(double, double)> k, double s) {
  for (var i = 0; i < k.length - 1; i++) {
    final (s0, v0) = k[i];
    final (s1, v1) = k[i + 1];
    if (s >= s0 && s <= s1) {
      final u = (s - s0) / (s1 - s0);
      return v0 + (v1 - v0) * (0.5 - 0.5 * math.cos(u * math.pi));
    }
  }
  return k.last.$2;
}

/// A brincadeira (gata, raposa): agacha, salta, pousa. O laço do desenho
/// (`_Pose.pulo`/`agacha`) dá a altura; aqui entram a borracha com
/// antecipação (estica ao decolar, cede ao pousar, agacha antes), as patas
/// recolhidas no ar e a cabeça 2 quadros atrás (MEL-21, laudo 34 R5).
SaidaDaVida brincaNa(double f) {
  const borracha = [
    (0.0, -0.25),
    (0.08, -0.30),
    (0.30, 0.0),
    (0.50, 0.10),
    (0.56, 0.45),
    (0.70, 0.15),
    (0.90, 0.25),
    (1.0, -0.25),
  ];
  double pulo(double g) => math.max(0.0, math.sin(g * 2 * math.pi)) * 16;
  final noAr = math.max(0.0, math.sin(f * 2 * math.pi));
  return SaidaDaVida(
    atividadeAtiva: true,
    corpoLivre: false,
    cicloDaAtividade: f,
    forcaDaAtividade: 1,
    elastico: _chaves(borracha, f),
    pataEsquerda: noAr,
    pataDireita: noAr * 0.8,
    cabecaAtraso: Offset(0, pulo(f) - pulo(f - 2 / n)),
    cauda: -math.sin((f - 2.5 / n) * 2 * math.pi) * 0.9,
  );
}

Widget _cena(
  Species sp,
  Activity atv,
  QuadroFixo q, {
  EstagioDoBicho estagio = EstagioDoBicho.adulto,
  Mood humor = Mood.content,
  Color? agua,
}) => SizedBox(
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

  Future<void> grava(
    WidgetTester tester,
    Widget w,
    String nome, {
    double densidade = _densidade,
  }) async {
    final chave = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(key: chave, child: w),
        ),
      ),
    );
    final b =
        chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final img = await b.toImage(pixelRatio: densidade);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      img.dispose();
      File('$_pasta/$nome.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  double t(int i) => i / n;

  testWidgets('o passo de cada bicho', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (var i = 0; i < n; i++) {
        await grava(
          tester,
          _cena(
            sp,
            Activity.idle,
            QuadroFixo(
              acao: AcaoDoBicho.ocioso,
              vida: passoNa(t(i), especie: sp),
            ),
          ),
          'anda-${sp.name}/$i',
        );
      }
    }
  });

  // Com humor contente: no radiante as estrelinhas ficavam cozidas e
  // paradas em volta do bicho em todos os quadros (movimento-extra).
  testWidgets('a corrida atrás da bola', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (var i = 0; i < n; i++) {
        await grava(
          tester,
          _cena(
            sp,
            Activity.idle,
            QuadroFixo(
              acao: AcaoDoBicho.ocioso,
              vida: passoNa(t(i), especie: sp, correndo: true),
            ),
          ),
          'corre-${sp.name}/$i',
        );
      }
    }
  });

  // Comer: a bocada (a cabeça desce 17 u até a comida, o corpo pende) e a
  // mastigação de cabeça erguida, com a comida na boca. A comida entra na
  // boca no quadro mais baixo; mastiga a 2 Hz (duas mordidas em ~1 s, cada
  // uma com a boca mudando de forma em 5 quadros — não aberto/fechado em
  // quadros alternados, MOV-08). Capivara e tartaruga pastam (a cabeça vai
  // mais fundo, no capim); as outras sete petiscam (`acaoDoBicho` com
  // Activity.graze decide).
  testWidgets('o episódio de comer', skip: !_ligado, (tester) async {
    const quadros = 16;
    const descida = 0.35;
    for (final sp in Species.values) {
      for (var i = 0; i < quadros; i++) {
        final f = i / quadros;
        // 0..0,35: a bocada (fundo em 0,175); 0,4..1: mastiga (2 mordidas).
        final bocada = f < descida ? math.sin(math.pi * f / descida) : 0.0;
        final mastiga = f < 0.4
            ? 0.0
            : 0.5 - 0.5 * math.cos((f - 0.4) / 0.6 * math.pi * 2 * 2);
        await grava(
          tester,
          _cena(
            sp,
            Activity.graze,
            QuadroFixo(
              respiro: math.sin(f * 2 * math.pi) * 0.3,
              vida: SaidaDaVida(
                atividadeAtiva: true,
                corpoLivre: false,
                // 1,25: a bocada desce 18 u pastando (MOV-08); o app limita
                // a 1,2, a folha pode ir mais fundo porque o corpo pende.
                cabecaNoChao: bocada * 1.25,
                mastigando: mastiga,
                comendo: f >= descida / 2,
                cicloDaAtividade: f,
                // Os olhos fecham um pouco no toque na comida.
                pisca: 0.6 * math.max(0.0, bocada - 0.6) / 0.4,
              ),
            ),
          ),
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
        _cena(
          Species.owl,
          Activity.swim,
          QuadroFixo(
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
          ),
        ),
        'voa-owl/$i',
      );
    }
  });

  // A braçada: o quadro 0 no ponto de velocidade zero da boia (−cos), para
  // o laço emendar (MOV-19). Pende ≈ 7° para onde vai com a cabeça à
  // frente (MOV-06), espelhado como o passo (cauda atrás). O resto da
  // postura (ondula, patas da frente da lontra paradas, cauda do axolote
  // varrendo, pinguim com as duas nadadeiras juntas) é do desenho (`paint`,
  // `_pata`, `OssosDoCorpo`).
  testWidgets('a braçada de quem nada', skip: !_ligado, (tester) async {
    for (final sp in _nadam) {
      for (var i = 0; i < n; i++) {
        final f = t(i);
        await grava(
          tester,
          _cena(
            sp,
            Activity.swim,
            QuadroFixo(
              acao: AcaoDoBicho.nado,
              ciclo: f,
              vida: SaidaDaVida(
                atividadeAtiva: true,
                corpoLivre: false,
                cicloDaAtividade: f,
                forcaDaAtividade: 1,
                boia: -math.cos(f * 2 * math.pi),
                inclina: -0.13,
                cabecaAtraso: const Offset(-5, 0),
                virado: true,
                olhar: const Offset(-0.6, 0),
                virada: const Offset(-0.5, 0),
              ),
            ),
            agua: const Color(0xFF7FC0D6),
          ),
          'nada-${sp.name}/$i',
        );
      }
    }
  });

  testWidgets('a brincadeira da gata e da raposa', skip: !_ligado, (
    tester,
  ) async {
    for (final sp in [Species.cat, Species.fox]) {
      for (var i = 0; i < n; i++) {
        final f = t(i);
        await grava(
          tester,
          _cena(
            sp,
            Activity.swim,
            QuadroFixo(
              acao: AcaoDoBicho.brincadeira,
              ciclo: f,
              vida: brincaNa(f),
            ),
            humor: Mood.radiant,
          ),
          'brinca-${sp.name}/$i',
        );
      }
    }
  });

  // O sono: deitado (não a pose em pé de olhos fechados), 24 quadros por
  // ciclo de fôlego para não dar degraus (MOV-09); a respiração acordada em
  // 8 quadros, como o site já toca.
  testWidgets('o sono e o fôlego', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (var i = 0; i < n; i++) {
        final r = math.sin(i / n * 2 * math.pi);
        await grava(
          tester,
          _cena(
            sp,
            Activity.nap,
            QuadroFixo(
              respiro: r,
              acao: AcaoDoBicho.cochilo,
              vida: SaidaDaVida(respiro: r, deita: 0.85, adormecido: true),
            ),
            humor: Mood.sleepy,
          ),
          'dorme-${sp.name}/$i',
          densidade: 3,
        );
      }
      for (var i = 0; i < 8; i++) {
        final r = math.sin(i / 8 * 2 * math.pi);
        await grava(
          tester,
          _cena(
            sp,
            Activity.idle,
            QuadroFixo(respiro: r, pisca: i == 5 ? 1 : 0),
          ),
          'respira-${sp.name}/$i',
          densidade: 3,
        );
      }
    }
  });

  testWidgets('as cinco fases de cada espécie', skip: !_ligado, (tester) async {
    for (final sp in Species.values) {
      for (final e in EstagioDoBicho.values) {
        await grava(
          tester,
          _cena(sp, Activity.idle, const QuadroFixo(), estagio: e),
          'fase-${sp.name}/${e.name}',
          densidade: 3,
        );
      }
    }
  });
}
