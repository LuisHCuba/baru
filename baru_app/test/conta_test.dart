import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Conta, pelagem e o próximo passo da trilha.
///
/// Três defeitos que o usuário viu antes de mim: o seletor de pelagem mostrava
/// seis bolinhas e só quatro respondiam, a trilha dizia "você está no passo 1"
/// para quem já tinha conquistado o passo 3, e não havia lugar nenhum para
/// gerenciar a conta.

void main() {
  group('o seletor de pelagem', () {
    test('aceita todos os tons da paleta da espécie, não só quatro', () {
      for (final e in Species.values) {
        final paleta = AppColors.coatDe(e);
        final s = AppState()..pickSpecies(e);
        for (var i = 0; i < paleta.length; i++) {
          s.setColor(i);
          expect(
            s.color,
            i,
            reason: 'a bolinha $i de ${e.name} apareceu e não respondia',
          );
        }
        s.dispose();
      }
    });

    test('índice fora da paleta é preso, não estoura', () {
      final s = AppState()..pickSpecies(Species.tortoise);
      s.setColor(99);
      expect(s.color, AppColors.coatDe(Species.tortoise).length - 1);
      s.setColor(-4);
      expect(s.color, 0);
      s.dispose();
    });

    test('trocar de espécie não deixa um índice inválido para trás', () {
      final s = AppState()..pickSpecies(Species.capybara);
      s.setColor(AppColors.coatDe(Species.capybara).length - 1);
      s.pickSpecies(Species.owl);
      expect(
        s.color,
        lessThan(AppColors.coatDe(Species.owl).length),
      );
      s.dispose();
    });
  });

  group('o próximo passo da trilha', () {
    test('numa conta nova é o primeiro marco, não o de nível', () {
      final s = AppState()..startCompanionship();
      expect(s.progresso.proximoMarco?.id, 'primeiro_foco');
      s.dispose();
    });

    test('um marco já conquistado nunca é apontado como próximo', () {
      final s = AppState()
        ..startCompanionship()
        ..sessoesConcluidas = 30
        ..melhorSequencia = 30
        ..diasAbaixoDaMeta = 30;
      final proximo = s.progresso.proximoMarco;
      if (proximo != null) {
        expect(
          s.progresso.alcancou(proximo),
          isFalse,
          reason: 'apontar para algo já feito é o bug que o usuário viu',
        );
      }
      s.dispose();
    });

    test('escolhe o mais perto de acontecer, não o primeiro da lista', () {
      // Nada feito em sessões, mas quase lá na sequência: o próximo passo
      // tem de ser a sequência.
      final s = AppState()
        ..startCompanionship()
        ..melhorSequencia = 2; // marco 'tres_dias' está a um dia
      final proximo = s.progresso.proximoMarco;
      expect(proximo?.id, 'tres_dias');
      s.dispose();
    });
  });

  group('a conta', () {
    test('sem sessão, as operações dizem que não há conta', () async {
      final s = AppState();
      expect(s.emailDaConta, isEmpty);
      expect(await s.recuperaSenha(), s.t.contaSemConta);
      s.dispose();
    });

    test('valida antes de bater na rede', () async {
      final s = AppState();
      expect(await s.trocaEmail('nao-e-email'), s.t.contaEmailInvalido);
      expect(await s.trocaSenha('123'), s.t.contaSenhaCurta);
      s.dispose();
    });

    test('a conta tem endereço próprio e nasce com a home embaixo', () {
      final s = AppState()..startCompanionship();
      s.abrePorEndereco(AppScreen.conta);
      expect(s.pilha, [AppScreen.home, AppScreen.conta]);
      expect(s.voltar(), isTrue);
      expect(s.screen, AppScreen.home);
      s.dispose();
    });
  });
}
