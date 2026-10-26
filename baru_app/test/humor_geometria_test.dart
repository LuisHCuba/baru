// A saudade não pode ler como raiva.
//
// Auditoria da Onda 1 (docs/auditoria/onda-1.md, 1b): a correção do rosto
// não tinha teste. Se alguém inverter um lado, a cara brava volta sem
// quebrar nada. Este teste trava a regra nos dois olhos: na tristeza, a
// ponta de **dentro** da pálpebra e da sobrancelha fica acima da de fora.
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Os olhos das espécies ficam entre 6 e 12 de raio, a 11–27 do centro.
  const casos = [
    (Offset(-26, -13), 7.5),
    (Offset(26, -13), 7.5),
    (Offset(-20, 1), 9.0),
    (Offset(20, 1), 9.0),
    (Offset(-11, 0), 6.0),
    (Offset(11, 0), 6.0),
  ];

  test('na tristeza, a ponta de dentro fica acima da de fora nos dois olhos',
      () {
    for (final (o, r) in casos) {
      final g = geometriaDoOlho(o, r, triste: true);
      // y cresce para baixo: "acima" é menor.
      expect(g.palpebraDentro.dy, lessThan(g.palpebraFora.dy), reason: '$o');
      expect(g.sobrancelhaDentro.dy, lessThan(g.sobrancelhaFora.dy),
          reason: '$o');
      // E "dentro" é mesmo o lado do meio da cara.
      expect(g.palpebraDentro.dx.abs(), lessThan(g.palpebraFora.dx.abs()),
          reason: '$o');
      expect(g.sobrancelhaDentro.dx.abs(),
          lessThan(g.sobrancelhaFora.dx.abs()),
          reason: '$o');
    }
  });

  test('os dois olhos são espelho um do outro', () {
    for (var i = 0; i < casos.length; i += 2) {
      final (oe, r) = casos[i];
      final (od, _) = casos[i + 1];
      final e = geometriaDoOlho(oe, r, triste: true);
      final d = geometriaDoOlho(od, r, triste: true);
      Offset espelho(Offset p) => Offset(-p.dx, p.dy);
      expect(espelho(e.palpebraDentro), d.palpebraDentro);
      expect(espelho(e.palpebraFora), d.palpebraFora);
      expect(espelho(e.sobrancelhaDentro), d.sobrancelhaDentro);
      expect(espelho(e.sobrancelhaFora), d.sobrancelhaFora);
    }
  });

  test('no neutro a pálpebra é reta', () {
    for (final (o, r) in casos) {
      final g = geometriaDoOlho(o, r, triste: false);
      expect(g.palpebraDentro.dy, g.palpebraFora.dy);
    }
  });
}
