// Sem o sexo dito, o bicho não ganha "ele" por padrão.
//
// A Nina aparecia como "Ele continua aqui" e "Ele espera a próxima":
// português e espanhol não têm pronome neutro, então o nome toma o lugar.
import 'package:baru_app/l10n.dart';
import 'package:baru_app/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sexo não dito usa o nome em português e espanhol', () {
    expect(T('pt').comPronome('{P} espera a próxima.', Sexo.naoDito, {}, 'Nina'),
        'Nina espera a próxima.');
    expect(T('es').comPronome('{P} sigue aquí.', Sexo.naoDito, {}, 'Nina'),
        'Nina sigue aquí.');
  });

  test('sexo dito continua com o pronome', () {
    expect(T('pt').comPronome('{P} espera.', Sexo.femea, {}, 'Nina'), 'Ela espera.');
    expect(T('pt').comPronome('{P} espera.', Sexo.macho, {}, 'Nino'), 'Ele espera.');
  });

  test('inglês mantém o neutro "they"', () {
    expect(T('en').comPronome('{P} waited.', Sexo.naoDito, {}, 'Nina'), 'They waited.');
  });
}
