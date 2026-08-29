@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/screens/session_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A evidência visual das atividades: **sequências de quadros**, não poses.
///
/// Uma captura sozinha não prova animação — prova desenho. Aqui cada
/// atividade sai em seis quadros espaçados ao longo do próprio laço, e o
/// teste **falha** se dois quadros vizinhos saírem byte a byte iguais. É o
/// que impede a evidência de afirmar movimento que não existe.
const _pasta = '../docs/evidence/2026-08-27';

/// Os laços de `pet.dart`, repetidos aqui de propósito: são privados lá, e
/// importá-los faria a evidência concordar com o código em vez de amostrá-lo.
const _laco = {
  'nado': Duration(milliseconds: 1150),
  'voo': Duration(milliseconds: 820),
  'pasto': Duration(milliseconds: 5600),
  'brincadeira': Duration(milliseconds: 1900),
  'sono': Duration(milliseconds: 13000),
  'ocio': Duration(milliseconds: 7400),
};

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File('${destino.path}/$nome.png').writeAsBytesSync(
      data!.buffer.asUint8List(),
    );
  });
}

/// Os pixels crus, para provar que dois quadros da sequência diferem.
Future<Uint8List> _pixels(WidgetTester tester, Key chave) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  late Uint8List bytes;
  await tester.runAsync(() async {
    final img = await boundary.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    bytes = data!.buffer.asUint8List();
  });
  return bytes;
}

bool _iguais(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Widget _cena(Species sp, Activity a, Mood m) => MaterialApp(
      home: Scaffold(
        backgroundColor: Cores.habitat,
        body: Center(
          child: PetView(
            species: sp,
            mood: m,
            activity: a,
            coat: 0,
            // Sem gesto de ocioso atrapalhando a amostragem do laço: quem
            // olha a folha tem de ver a atividade, não um bocejo no meio.
            interativo: false,
          ),
        ),
      ),
    );

/// Salva [passos] quadros espaçados ao longo de [ciclo], e exige que a
/// sequência ande.
Future<void> _sequencia(
  WidgetTester tester, {
  required String nome,
  required Duration ciclo,
  int passos = 6,
}) async {
  final passo = Duration(microseconds: ciclo.inMicroseconds ~/ passos);
  Uint8List? anterior;
  for (var i = 0; i < passos; i++) {
    final agora = await _pixels(tester, PetView.cenaKey);
    if (anterior != null) {
      expect(
        _iguais(anterior, agora),
        isFalse,
        reason: '$nome: os quadros ${i - 1} e $i saíram idênticos — a '
            'evidência estaria afirmando um movimento que não acontece',
      );
    }
    anterior = agora;
    await _salva(tester, PetView.cenaKey, '$nome-${i + 1}');
    await tester.pump(passo);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Sem isto o flutter_test desenha texto com a fonte de teste e a captura
    // sai com caixinhas no lugar das letras — evidência inútil.
    for (final peso in [
      'Nunito-Regular',
      'Nunito-SemiBold',
      'Nunito-Bold',
      'Nunito-ExtraBold',
    ]) {
      final loader = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/$peso.ttf'));
      await loader.load();
    }
  });

  testWidgets('nadando: a braçada, quadro a quadro', (tester) async {
    await tester.pumpWidget(
      _cena(Species.capybara, Activity.swim, Mood.radiant),
    );
    await tester.pump();
    await _sequencia(tester, nome: 'atividade-nado-capivara', ciclo: _laco['nado']!);
  });

  testWidgets('nadando: a lontra mergulha diferente da capivara', (
    tester,
  ) async {
    await tester.pumpWidget(_cena(Species.otter, Activity.swim, Mood.radiant));
    await tester.pump();
    await _sequencia(tester, nome: 'atividade-nado-lontra', ciclo: _laco['nado']!);
  });

  testWidgets('nadando: a tartaruga estica o pescoço fora d\'água', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cena(Species.tortoise, Activity.swim, Mood.radiant),
    );
    await tester.pump();
    await _sequencia(
      tester,
      nome: 'atividade-nado-tartaruga',
      ciclo: _laco['nado']!,
    );
  });

  testWidgets('pastando: abaixa, mastiga, levanta, olha', (tester) async {
    await tester.pumpWidget(
      _cena(Species.capybara, Activity.graze, Mood.content),
    );
    await tester.pump();
    await _sequencia(
      tester,
      nome: 'atividade-pasto-capivara',
      ciclo: _laco['pasto']!,
      passos: 8,
    );
  });

  testWidgets('pastando: a tartaruga, a outra herbívora', (tester) async {
    await tester.pumpWidget(
      _cena(Species.tortoise, Activity.graze, Mood.content),
    );
    await tester.pump();
    await _sequencia(
      tester,
      nome: 'atividade-pasto-tartaruga',
      ciclo: _laco['pasto']!,
      passos: 8,
    );
  });

  testWidgets('petiscando: a lontra come com a cabeça erguida', (tester) async {
    await tester.pumpWidget(_cena(Species.otter, Activity.graze, Mood.content));
    await tester.pump();
    await _sequencia(
      tester,
      nome: 'atividade-petisco-lontra',
      ciclo: _laco['pasto']!,
      passos: 8,
    );
  });

  testWidgets('dormindo: a respiração funda e a folha que pousa', (
    tester,
  ) async {
    await tester.pumpWidget(
      _cena(Species.capybara, Activity.nap, Mood.sleepy),
    );
    await tester.pump();
    await _sequencia(
      tester,
      nome: 'atividade-sono-capivara',
      ciclo: _laco['sono']!,
      passos: 8,
    );
  });

  testWidgets('voando: a coruja no lugar do nado', (tester) async {
    await tester.pumpWidget(_cena(Species.owl, Activity.swim, Mood.radiant));
    await tester.pump();
    await _sequencia(tester, nome: 'atividade-voo-coruja', ciclo: _laco['voo']!);
  });

  testWidgets('brincando: a gata no lugar do nado', (tester) async {
    await tester.pumpWidget(_cena(Species.cat, Activity.swim, Mood.radiant));
    await tester.pump();
    await _sequencia(
      tester,
      nome: 'atividade-brincadeira-gata',
      ciclo: _laco['brincadeira']!,
    );
  });

  testWidgets('à toa: o repertório de ocioso', (tester) async {
    // Aqui o interativo fica ligado, senão os gestos não são sorteados. A
    // amostragem é longa o bastante para pegar um deles em cena.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.habitat,
          body: Center(
            child: PetView(
              species: Species.fox,
              mood: Mood.content,
              activity: Activity.idle,
              coat: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _sequencia(
      tester,
      nome: 'atividade-ocio-raposa',
      ciclo: _laco['ocio']!,
      passos: 6,
    );
    // Deixa terminar o que estiver em curso antes de desmontar.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('a folha de todas as espécies nadando', (tester) async {
    // Uma imagem só, para conferir de relance que ninguém está fazendo o que
    // não devia: a coruja com asa aberta, a gata no ar, os que nadam na água.
    //
    // A grade se ajusta ao número de espécies em vez de fixar 4+4. Fixada,
    // ela estourou no dia em que entrou a nona — e uma folha de evidência
    // que quebra ao ganhar um bicho é uma folha que não vai ser regerada.
    const porLinha = 3;
    final linhas = <List<Species>>[
      for (var i = 0; i < Species.values.length; i += porLinha)
        Species.values.skip(i).take(porLinha).toList(),
    ];
    tester.view.physicalSize = Size(
      porLinha * 200,
      linhas.length * 150 + 40,
    );
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.habitat,
          body: RepaintBoundary(
            key: const Key('folha-nado'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final linha in linhas)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final sp in linha)
                        SizedBox(
                          width: 200,
                          height: 150,
                          child: PetView(
                            species: sp,
                            mood: Mood.radiant,
                            activity: Activity.swim,
                            coat: 0,
                            interativo: false,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Um quarto de braçada: a fase zero deixa remo e asa no ponto morto, e a
    // folha inteira sairia parecendo uma fileira de bichos de pé.
    await tester.pump(const Duration(milliseconds: 290));
    await _salva(tester, const Key('folha-nado'), 'atividade-folha-nado');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a tela de sessão, com o bicho em movimento', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final sp in [Species.capybara, Species.owl, Species.cat]) {
      final app = AppState()..startCompanionship();
      app.species = sp;
      app.remaining = 18 * 60 + 42;
      addTearDown(app.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: const Key('tela-sessao'),
            child: Scaffold(
              body: AppScope(state: app, child: const SessionScreen()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 290));
      final antes = await _pixels(tester, const Key('tela-sessao'));
      await _salva(tester, const Key('tela-sessao'), 'sessao-${sp.name}-1');

      await tester.pump(const Duration(milliseconds: 290));
      final depois = await _pixels(tester, const Key('tela-sessao'));
      expect(
        _iguais(antes, depois),
        isFalse,
        reason: 'a tela de sessão de ${sp.name} não mudou em 290 ms — é '
            'exatamente o "ele fica só parado" que motivou o trabalho',
      );
      await _salva(tester, const Key('tela-sessao'), 'sessao-${sp.name}-2');
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
