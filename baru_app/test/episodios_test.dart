import 'package:baru_app/widgets/vida/motor_de_vida.dart';
import 'package:flutter_test/flutter_test.dart';

/// O bicho não pode virar laço (pesquisa 22): numa medição de 3 minutos ele
/// passava 93% do tempo no mesmo movimento de pastar, sem um gesto.

MotorDeVida _motor(
  ModoDaAtividade modo, {
  Set<Episodio> repertorio = const {},
}) => MotorDeVida(semente: 7, areaDeAndar: 60)
  ..modo = modo
  ..podeAndar = true
  ..nadando = modo == ModoDaAtividade.nadar
  ..dormindo = modo == ModoDaAtividade.dormir
  ..ocupado = modo == ModoDaAtividade.dormir
  ..hora = 12
  ..repertorio = repertorio;

/// Tempo em cada episódio e a sequência deles, em [segundos].
(Map<Episodio, double>, List<Episodio>) _assiste(
  MotorDeVida m,
  double segundos,
) {
  final tempo = <Episodio, double>{};
  final sequencia = <Episodio>[];
  const dt = 1 / 30;
  for (var t = 0.0; t < segundos; t += dt) {
    m.passo(dt);
    final e = m.episodio;
    tempo[e] = (tempo[e] ?? 0) + dt;
    if (sequencia.isEmpty || sequencia.last != e) sequencia.add(e);
  }
  return (tempo, sequencia);
}

void main() {
  for (final modo in [
    ModoDaAtividade.pastar,
    ModoDaAtividade.petiscar,
    ModoDaAtividade.nadar,
    ModoDaAtividade.brincar,
    ModoDaAtividade.dormir,
  ]) {
    test('${modo.name}: varia, e nada domina', () {
      final (tempo, sequencia) = _assiste(_motor(modo), 300);
      expect(
        tempo.length,
        greaterThanOrEqualTo(3),
        reason: 'episódios distintos em 5 min: ${tempo.keys}',
      );
      final maior = tempo.values.reduce((a, b) => a > b ? a : b);
      // Dormindo, respirar quieto é o normal; o resto vem por cima.
      final teto = modo == ModoDaAtividade.dormir ? 0.72 : 0.6;
      expect(maior / 300, lessThan(teto), reason: '$tempo');
      // Muitas trocas: não fica parado num episódio só.
      expect(sequencia.length, greaterThan(25));
    });
  }

  test('a sequência de episódios não se repete em bloco', () {
    final (_, seq) = _assiste(_motor(ModoDaAtividade.pastar), 600);
    // Se fosse laço, um bloco de 6 episódios voltaria idêntico logo depois.
    var repeticoes = 0;
    for (var i = 0; i + 12 <= seq.length; i++) {
      final a = seq.sublist(i, i + 6).join();
      final b = seq.sublist(i + 6, i + 12).join();
      if (a == b) repeticoes++;
    }
    expect(repeticoes, lessThan(3));
  });

  test('a espécie faz o que é dela', () {
    final (tempo, _) = _assiste(
      _motor(
        ModoDaAtividade.petiscar,
        repertorio: const {Episodio.piscadaLenta, Episodio.amassar},
      ),
      600,
    );
    expect(tempo.keys, containsAll([Episodio.piscadaLenta, Episodio.amassar]));
    // Mas o especial é especial: a piscada lenta não vira cacoete.
    expect((tempo[Episodio.piscadaLenta] ?? 0) / 600, lessThan(0.12));
  });

  test('tomar sol só de dia', () {
    final m = _motor(
      ModoDaAtividade.pastar,
      repertorio: const {Episodio.tomarSol},
    )..hora = 23;
    final (tempo, _) = _assiste(m, 600);
    expect(tempo.containsKey(Episodio.tomarSol), isFalse);
  });
}
