import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// A trilha cobra a espécie que entrega.
///
/// **O defeito que isto trava.** `especiesLiberadas` existia sem nenhum
/// consumidor: os dois seletores iteravam `Species.values` inteiro e
/// `pickSpecies` não tinha guarda. Uma conta nova equipava o buldogue no
/// primeiro dia, e os 22 degraus da trilha viravam enfeite — enquanto o
/// habitat, que é a outra recompensa da mesma trilha, já era gateado. A
/// assimetria é que era o defeito.

AppState _novo({Species quiz = Species.capybara}) {
  final a = AppState()
    ..onb = 9
    ..companionshipStarted = true
    ..species = quiz;
  return a;
}

void main() {
  group('no onboarding, o quiz sugere e não sentencia', () {
    test('as quatro de origem estão abertas antes de começar', () {
      // A tela de revelação existe para a pessoa dizer "não, quero a
      // coruja". Gatear ali transformaria a sugestão em sentença.
      final a = _novo()..companionshipStarted = false;
      addTearDown(a.dispose);

      for (final s in ProgressoDaTrilha.deOrigem) {
        expect(a.podeEscolher(s), isTrue, reason: s.name);
      }
    });

    test('mas as cinco da trilha não', () {
      final a = _novo()..companionshipStarted = false;
      addTearDown(a.dispose);

      for (final s in Species.values) {
        if (ProgressoDaTrilha.deOrigem.contains(s)) continue;
        expect(a.podeEscolher(s), isFalse, reason: s.name);
      }
    });
  });

  group('depois do onboarding, vale a trilha', () {
    test('quem escolheu a capivara não pula para a coruja', () {
      // Lontra, tartaruga e coruja são recompensa de degrau. Abrir as
      // quatro para sempre esvaziaria três deles.
      final a = _novo()..companionshipStarted = true;
      addTearDown(a.dispose);

      a.pickSpecies(Species.owl);

      expect(a.species, Species.capybara);
    });

    test('nenhuma das cinco extras entra sem marco', () {
      final a = _novo()..companionshipStarted = true;
      addTearDown(a.dispose);

      for (final s in Species.values) {
        if (s == Species.capybara) continue;
        a.pickSpecies(s);
        expect(a.species, isNot(s), reason: '${s.name} entrou de graça');
      }
    });

    test('quem conquistou o marco equipa', () {
      final marco = trilha.firstWhere((m) => m.recompensa.especie != null);
      final especie = marco.recompensa.especie!;

      // `marcosResgatados` é o piso de posse: quem já recebeu, tem.
      final a = _novo()
        ..companionshipStarted = true
        ..marcosResgatados = {marco.id};
      addTearDown(a.dispose);

      a.pickSpecies(especie);

      expect(a.species, especie);
    });

    test('a espécie que a pessoa já usa nunca é tirada dela', () {
      final a = _novo(quiz: Species.owl)..companionshipStarted = true;
      addTearDown(a.dispose);

      expect(a.podeEscolher(Species.owl), isTrue);
    });
  });

  group('o desenho da trilha', () {
    test('cada espécie fora da capivara abre em algum passo', () {
      // Cadeado sem destino é frustração; cadeado com número é motivo para
      // subir. Uma espécie que não abre em passo nenhum seria inalcançável.
      for (final s in Species.values) {
        if (s == Species.capybara) continue;
        final passo = ProgressoDaTrilha.passoQueAbre(s);
        expect(passo, isNotNull, reason: '${s.name} não abre em passo nenhum');
        expect(passo, greaterThan(0), reason: s.name);
        expect(passo, lessThanOrEqualTo(trilha.length), reason: s.name);
      }
    });

    test('a capivara não é prêmio de degrau nenhum', () {
      // Ela é o piso: quem não conquistou nada ainda tem um companheiro.
      for (final m in trilha) {
        expect(m.recompensa.especie, isNot(Species.capybara), reason: m.id);
      }
    });
  });
}
