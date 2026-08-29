import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quem já recebeu não perde ao virar a chave da corrente.
///
/// **O defeito que isto trava.** A trilha virou linear: um passo só conquista
/// depois do anterior. Espécie e habitat, porém, são **derivados** da trilha
/// e não gravados em lugar nenhum — então uma conta que ganhou o axolote e a
/// Serra quando os marcos eram independentes perderia os dois no instante em
/// que a corrente passasse a valer. Punição retroativa por uma mudança
/// nossa, que o contrato proíbe.
///
/// O piso é `ProgressoDaTrilha.entregues`, alimentado por
/// `AppState.marcosResgatados`. Os testes do domínio já cobrem o piso em si;
/// **este arquivo cobre a fiação** — que ela existe e continua existindo.
/// Sem ele, apagar a linha do `AppState` não quebrava nada.

/// Um `AppState` que recebeu marcos fora de ordem, como acontecia antes.
AppState _contaAntiga(List<String> recebidos) {
  final a = AppState()
    ..onb = 9
    ..companionshipStarted = true
    ..marcosResgatados = recebidos.toSet();
  return a;
}

/// Um marco que entrega espécie, longe do começo da trilha.
Marco _marcoDeEspecie() => trilha.firstWhere(
      (m) => m.recompensa.especie != null,
      orElse: () => trilha.last,
    );

/// Um marco que entrega um estágio de habitat.
Marco? _marcoDeHabitat() {
  for (final m in trilha) {
    if (m.recompensa.estagioDeHabitat != null) return m;
  }
  return null;
}

void main() {
  test('a espécie recebida fora de ordem sobrevive à corrente', () {
    final marco = _marcoDeEspecie();
    final especie = marco.recompensa.especie;
    if (especie == null) {
      markTestSkipped('nenhum marco entrega espécie');
      return;
    }

    // Sem nenhum contador: a corrente não alcançou nada. Só o registro de
    // que este marco já foi pago é que segura a posse.
    final a = _contaAntiga([marco.id]);
    addTearDown(a.dispose);

    // Por id, e não pelo objeto: `alcancados` é `List<Marco>`, e
    // `contains(String)` devolveria `false` sempre — a asserção passaria
    // por vacuidade e não protegeria nada. O analisador pegou.
    expect(
      a.progresso.alcancados.map((m) => m.id),
      isNot(contains(marco.id)),
      reason: 'o piso não devolve o ✓ nem recria buraco na corrente',
    );
    expect(
      a.especiesLiberadas,
      contains(especie),
      reason: 'tirar de volta o que já foi entregue é punição retroativa',
    );
  });

  test('o habitat recebido fora de ordem sobrevive à corrente', () {
    final marco = _marcoDeHabitat();
    if (marco == null) {
      markTestSkipped('nenhum marco entrega habitat');
      return;
    }
    final estagio = marco.recompensa.estagioDeHabitat!;

    final a = _contaAntiga([marco.id]);
    addTearDown(a.dispose);

    expect(
      a.progresso.estagioDoHabitat,
      greaterThanOrEqualTo(estagio),
      reason: 'o habitat em que a pessoa mora não pode regredir',
    );
  });

  test('sem nada recebido, nada é liberado de graça', () {
    // O outro lado: o piso é piso, não presente. Uma conta nova continua
    // tendo de subir a corrente.
    final marco = _marcoDeHabitat();
    if (marco == null) {
      markTestSkipped('nenhum marco entrega habitat');
      return;
    }
    final a = _contaAntiga(const []);
    addTearDown(a.dispose);

    expect(
      a.progresso.estagioDoHabitat,
      lessThan(marco.recompensa.estagioDeHabitat!),
    );
  });

  test('a espécie do quiz continua valendo sem marco nenhum', () {
    final a = _contaAntiga(const [])..species = Species.otter;
    addTearDown(a.dispose);

    expect(a.especiesLiberadas, contains(Species.otter));
  });
}
