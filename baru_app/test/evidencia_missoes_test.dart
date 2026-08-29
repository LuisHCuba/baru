@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/data/descanso_do_dia.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/screens/missoes_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Evidência visual da tela de missões reorganizada.
///
/// Arquivo próprio, e não mais um caso dentro de `evidencia_test.dart`: há
/// trabalho simultâneo naquele, e duas frentes escrevendo no mesmo arquivo
/// batem de frente. O destino dos PNGs é a pasta do dia.
///
/// O que estas capturas provam, e que nenhuma asserção de texto prova: que a
/// hierarquia **se vê**. Um cartão grande no topo, blocos com peso diferente,
/// e a semana em linhas magras lá embaixo — se a tela voltar a ser cinco
/// retângulos iguais, sai na imagem.

const _pasta = '../docs/evidence/2026-08-28';

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  await tester.runAsync(() async {
    final img = await b.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File('${destino.path}/$nome.png')
        .writeAsBytesSync(data!.buffer.asUint8List());
  });
}

ResumoDeTela _tela({int dispersivo = 0}) => ResumoDeTela(
      porApp: {'com.exemplo.feed': Duration(minutes: dispersivo)},
      porCategoria: {
        CategoriaDeApp.dispersivo: Duration(minutes: dispersivo),
      },
    );

AppState _app({
  bool permissao = true,
  int melhorDescanso = 0,
  bool descansando = false,
  int dispersivo = 0,
  int diasFora = 0,
}) =>
    AppState()
      ..onb = 9
      ..companionshipStarted = true
      ..leaves = 128
      ..usageAccess = permissao
      ..resumoTela = _tela(dispersivo: dispersivo)
      ..melhorDescansoHoje = Duration(minutes: melhorDescanso)
      ..daysAway = diasFora
      ..descansoComecouEm = descansando
          ? DateTime.now().subtract(const Duration(minutes: 12))
          : null;

Future<void> _abre(WidgetTester tester, AppState app, Key chave) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Cores.superficie,
        body: RepaintBoundary(
          key: chave,
          child: AppScope(state: app, child: const MissoesScreen()),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('a tela de missões, com a principal do dia no topo', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Um dia em andamento: uma sessão feita, o descanso na metade, nada
    // ainda para colher. É o estado em que a tela mais precisa dizer o que
    // fazer — e era exatamente nele que ela mostrava cinco cartões iguais.
    final app = _app(melhorDescanso: 18, dispersivo: 35)
      ..completedToday = 1
      ..minutosDeFocoHoje = 35
      ..maiorSessaoHoje = 35
      ..sessoesNaSemana = 4
      ..minutosNaSemana = 150;
    addTearDown(app.dispose);

    await _abre(tester, app, const Key('captura-missoes-hoje'));
    await _salva(
      tester,
      const Key('captura-missoes-hoje'),
      'missoes-hierarquia',
    );

    expect(find.byKey(CartaoDoDescanso.chave), findsOneWidget);
    expect(find.byKey(CartaoDoDescanso.chaveDoComecar), findsOneWidget);
  });

  testWidgets('a mesma tela com folha parada na mesa', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Dia cheio: o descanso cumprido e várias sorteadas fechadas. O bloco de
    // colher aparece no topo, laranja, com a contagem ao lado do rótulo.
    final app = _app(melhorDescanso: Descanso.alvo.inMinutes, dispersivo: 15)
      ..completedToday = 3
      ..minutosDeFocoHoje = 150
      ..maiorSessaoHoje = 90
      ..sessoesNaSemana = 6
      ..minutosNaSemana = 320
      ..diasAbaixoNaSemana = 2;
    addTearDown(app.dispose);

    await _abre(tester, app, const Key('captura-missoes-colher'));
    await _salva(
      tester,
      const Key('captura-missoes-colher'),
      'missoes-para-colher',
    );

    expect(find.byKey(CartaoDoDescanso.chaveDoColher), findsOneWidget);
  });

  testWidgets('o dia da volta, com a retomada logo abaixo da principal', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(412, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Dois dias fora, nada feito ainda. É o pior dia possível para voltar, e
    // era o dia em que a tela não tinha nada a dizer.
    final app = _app(diasFora: 2, dispersivo: 40);
    addTearDown(app.dispose);

    await _abre(tester, app, const Key('captura-missoes-volta'));
    await _salva(
      tester,
      const Key('captura-missoes-volta'),
      'missoes-dia-da-volta',
    );

    expect(find.byKey(const Key('missao-retomada')), findsOneWidget);
  });

  testWidgets('o cartão do descanso nos quatro estados', (tester) async {
    tester.view.physicalSize = const Size(1560, 430);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Lado a lado porque o que se julga aqui é a diferença entre eles: a
    // missão principal muda de cara quatro vezes no mesmo dia, e uma captura
    // por estado não deixaria ninguém comparar.
    final estados = <AppState>[
      _app(),
      _app(descansando: true),
      _app(melhorDescanso: Descanso.alvo.inMinutes),
      _app(permissao: false),
    ];
    for (final a in estados) {
      addTearDown(a.dispose);
    }

    // A moldura inteira num só `RepaintBoundary`, e não um por cartão: a
    // comparação entre eles é o assunto da captura.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.canvas,
          body: RepaintBoundary(
            key: const Key('captura-descanso-estados'),
            child: Padding(
              padding: const EdgeInsets.all(Espaco.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final a in estados)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(Espaco.xs),
                        child: CartaoDoDescanso(key: ValueKey(a), app: a),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await _salva(
      tester,
      const Key('captura-descanso-estados'),
      'descanso-quatro-estados',
    );

    // Os quatro caminhos, um por cartão: começar, parar, colher e conceder.
    expect(find.byKey(CartaoDoDescanso.chaveDoComecar), findsOneWidget);
    expect(find.byKey(CartaoDoDescanso.chaveDoParar), findsOneWidget);
    expect(find.byKey(CartaoDoDescanso.chaveDoColher), findsOneWidget);
  });
}
