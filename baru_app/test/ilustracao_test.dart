import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/ilustracao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Ilustracoes.limpa);

  test(
    'as poses da capivara carregam, no tamanho que o desenho espera',
    () async {
      await Ilustracoes.carrega(Species.capybara);
      final imagens = Ilustracoes.imagens(Species.capybara)!;
      final poses = Ilustracoes.poses(Species.capybara)!;
      expect(imagens.keys.toSet(), poses.keys.toSet());
      for (final e in poses.entries) {
        final img = imagens[e.key]!;
        // As medidas (olhos, cabeça, pés) são em pixels da imagem: se o
        // arquivo mudar de tamanho, elas apontam para o lugar errado.
        expect(img.width.toDouble(), e.value.tamanho.width, reason: '${e.key}');
        expect(
          img.height.toDouble(),
          e.value.tamanho.height,
          reason: '${e.key}',
        );
        for (final o in e.value.olhos) {
          expect(o.dx, inInclusiveRange(0, img.width), reason: '${e.key}');
          expect(o.dy, inInclusiveRange(0, img.height), reason: '${e.key}');
        }
      }
    },
  );

  test('quem não tem ilustração segue desenhado no código', () async {
    await Ilustracoes.carrega(Species.fox);
    expect(Ilustracoes.poses(Species.fox), isNull);
    expect(Ilustracoes.imagens(Species.fox), isNull);
  });
}
