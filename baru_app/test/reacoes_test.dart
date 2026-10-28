
import 'package:baru_app/widgets/vida/motor_de_vida.dart';
import 'package:flutter_test/flutter_test.dart';

/// As reações do corpo ao dedo e à festa: o corpo cede e volta como borracha,
/// e nada fica deformado depois.

const _dt = 1 / 30;

MotorDeVida _motor() => MotorDeVida(semente: 7, areaDeAndar: 0)
  ..modo = ModoDaAtividade.livre
  ..hora = 12;

/// Roda [segundos] e devolve o maior valor de [de] e o último.
(double, double) _mede(
  MotorDeVida m,
  double segundos,
  double Function(SaidaDaVida) de,
) {
  var maior = 0.0, ultimo = 0.0;
  for (var t = 0.0; t < segundos; t += _dt) {
    ultimo = de(m.passo(_dt));
    if (ultimo.abs() > maior) maior = ultimo.abs();
  }
  return (maior, ultimo);
}

void main() {
  test('o toque afunda o corpo onde encosta, e ele volta', () {
    final m = _motor();
    _mede(m, 1, (q) => 0);
    m.tocado(const Offset(0.3, 0.2));
    final (pico, fim) = _mede(m, 2.5, (q) => q.denteForca);
    expect(pico, greaterThan(0.5));
    expect(fim.abs(), lessThan(0.05), reason: 'a marca do dedo some');
  });

  test('dois toques seguidos: o susto estica o corpo e passa', () {
    final m = _motor();
    _mede(m, 1, (q) => 0);
    m.tocado(const Offset(0.3, 0.2));
    _mede(m, 0.2, (q) => 0);
    m.tocado(const Offset(-0.3, 0.2));
    final (pico, fim) = _mede(m, 3, (q) => q.susto);
    expect(pico, greaterThan(0.5));
    expect(fim.abs(), lessThan(0.05));
  });

  test('o afago segura a marca da mão enquanto ela passa', () {
    final m = _motor();
    _mede(m, 1, (q) => 0);
    final onde = const [
      Offset(0, -0.6),
      Offset(0, 0.4),
      Offset(0.5, -0.1),
    ].firstWhere((o) => MotorDeVida.zonaDe(o) != m.zonaRuim);
    var menor = 1.0;
    for (var t = 0.0; t < 1.5; t += _dt) {
      m.afagado(onde, const Offset(300, 0));
      final q = m.passo(_dt);
      if (t > 0.8 && q.denteForca < menor) menor = q.denteForca;
    }
    expect(menor, greaterThan(0.3), reason: 'a mão continua afundando');
    m.soltouAfago();
    final (_, fim) = _mede(m, 2.5, (q) => q.denteForca);
    expect(fim.abs(), lessThan(0.05));
  });

  test('a comemoração pula e acaba', () {
    final m = _motor();
    _mede(m, 1, (q) => 0);
    m.comemora(duracao: 2);
    var festa = 0.0, alto = 0.0, achata = 0.0;
    for (var t = 0.0; t < 2.5; t += _dt) {
      final q = m.passo(_dt);
      if (q.festa > festa) festa = q.festa;
      if (-q.desloca.dy > alto) alto = -q.desloca.dy;
      if (q.achata.abs() > achata) achata = q.achata.abs();
    }
    expect(festa, greaterThan(0.5));
    expect(alto, greaterThan(3), reason: 'pula');
    expect(achata, greaterThan(0.05), reason: 'estica e achata nos pulos');
    final (_, fim) = _mede(m, 4, (q) => q.festa);
    expect(fim, 0, reason: 'a festa tem fim');
  });
}
