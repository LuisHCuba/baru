import 'package:baru_app/data/quiz.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/onboarding_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/common.dart';
import 'package:baru_app/widgets/pet_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// O onboarding.
///
/// Seis perguntas empilhadas numa rolagem só viravam formulário — e
/// formulário no onboarding é onde se desiste. Uma por tela, escolher já
/// avança, e a barra anda a cada resposta.

Future<AppState> _abre(WidgetTester tester, {int passo = 2}) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final app = AppState()..onb = passo;
  addTearDown(app.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const OnboardingScreen()),
      ),
    ),
  );
  await tester.pump();
  return app;
}

double _fracaoDaBarra(WidgetTester tester) =>
    tester.widget<OnbDots>(find.byType(OnbDots)).fracaoDoAtual;

void main() {
  group('uma pergunta por tela', () {
    testWidgets('só a pergunta da vez aparece', (tester) async {
      final app = await _abre(tester);

      expect(find.text(app.t.perguntaDoQuiz(quiz[0].id)), findsOneWidget);
      expect(
        find.text(app.t.perguntaDoQuiz(quiz[1].id)),
        findsNothing,
        reason: 'as seis juntas viram formulário',
      );
      for (final o in quiz[0].opcoes) {
        expect(find.text(app.t.opcaoDoQuiz(o.id)), findsOneWidget);
      }
    });

    testWidgets('escolher já avança para a seguinte', (tester) async {
      final app = await _abre(tester);

      await tester.tap(find.text(app.t.opcaoDoQuiz(quiz[0].opcoes[1].id)));
      await tester.pump();

      expect(app.perguntaAtual, 1);
      expect(find.text(app.t.perguntaDoQuiz(quiz[1].id)), findsOneWidget);
      expect(
        app.respostasDoQuiz[quiz[0].id],
        quiz[0].opcoes[1].id,
        reason: 'avançar não pode perder a resposta',
      );
    });

    testWidgets('dá para voltar e trocar a resposta', (tester) async {
      final app = await _abre(tester);

      await tester.tap(find.text(app.t.opcaoDoQuiz(quiz[0].opcoes[0].id)));
      await tester.pump();
      expect(app.perguntaAtual, 1);

      await tester.tap(find.text(app.t.quizVoltar));
      await tester.pump();
      expect(app.perguntaAtual, 0);

      // A escolha anterior continua marcada.
      await tester.tap(find.text(app.t.opcaoDoQuiz(quiz[0].opcoes[2].id)));
      await tester.pump();
      expect(app.respostasDoQuiz[quiz[0].id], quiz[0].opcoes[2].id);
    });

    testWidgets('na primeira pergunta não há para onde voltar', (
      tester,
    ) async {
      final app = await _abre(tester);
      expect(find.text(app.t.quizVoltar), findsNothing);
    });

    testWidgets('a última não avança sozinha: ela abre o botão de seguir', (
      tester,
    ) async {
      final app = await _abre(tester);
      for (var i = 0; i < quiz.length; i++) {
        await tester.tap(find.text(app.t.opcaoDoQuiz(quiz[i].opcoes[0].id)));
        await tester.pump();
      }
      expect(app.perguntaAtual, quiz.length - 1);
      expect(app.quizDone, isTrue);
      expect(find.text(app.t.quizCta), findsOneWidget);
    });
  });

  group('a barra de progresso', () {
    testWidgets('anda a cada resposta, e não fica parada seis telas', (
      tester,
    ) async {
      final app = await _abre(tester);
      expect(_fracaoDaBarra(tester), 0);

      final vistas = <double>[];
      for (var i = 0; i < quiz.length; i++) {
        await tester.tap(find.text(app.t.opcaoDoQuiz(quiz[i].opcoes[0].id)));
        await tester.pump();
        vistas.add(_fracaoDaBarra(tester));
      }

      // Estritamente crescente: se ficasse parada, a pessoa não veria que
      // está avançando.
      for (var i = 1; i < vistas.length; i++) {
        expect(vistas[i], greaterThan(vistas[i - 1]), reason: 'passo $i');
      }
      expect(vistas.last, 1.0);
    });

    testWidgets('fora do quiz a barra não é fracionada', (tester) async {
      await _abre(tester, passo: 1);
      expect(_fracaoDaBarra(tester), 1);
    });
  });

  group('a revelação', () {
    testWidgets('deixa escolher espécie, sexo, pelagem e nome', (
      tester,
    ) async {
      final app = await _abre(tester, passo: 2);
      for (final p in quiz) {
        app.pickQuiz(p.id, p.opcoes.first.id);
      }
      app.nextOnb();
      await tester.pump();

      expect(app.onb, 3);
      expect(find.byType(PetNameField), findsOneWidget);
      expect(find.byType(CoatPicker), findsOneWidget);
      expect(find.byType(SpeciesPicker), findsOneWidget);
      expect(find.text(app.t.setSexo.toUpperCase()), findsOneWidget);

      // O sexo é escolhido aqui, não escondido em ajustes.
      expect(app.sexo, Sexo.naoDito);
      await tester.tap(find.text(app.t.setSexoF));
      await tester.pump();
      expect(app.sexo, Sexo.femea);
    });

    testWidgets('trocar de espécie ali muda o bicho desenhado', (
      tester,
    ) async {
      final app = await _abre(tester, passo: 2);
      for (final p in quiz) {
        app.pickQuiz(p.id, p.opcoes.first.id);
      }
      app.nextOnb();
      await tester.pump();

      final antes = app.species;
      final outra =
          Species.values.firstWhere((e) => e != antes && e.index < 4);
      // A revelação é um `ListView` e o seletor tem oito espécies: na janela
      // do teste o chip nasce abaixo da dobra e um `tap` direto erra o alvo
      // — avisa "would not hit test" e passa reto, deixando a espécie
      // intacta. Rolar até ele é o que a pessoa faz com o dedo.
      final alvo = find.text(app.t.animalName(outra.name));
      await tester.ensureVisible(alvo);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(alvo);
      await tester.pump();
      expect(app.species, outra);
    });
  });
}
