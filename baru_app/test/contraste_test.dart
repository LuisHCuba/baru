// A paleta passa no WCAG AA (laudo 03, R-V3).
//
// Os pares são os que o app de fato usa: texto × fundo onde aparece. O
// mínimo é 4,5:1 para texto comum e 3:1 para barra, ícone e glifo (SC 1.4.3
// e 1.4.11). Quem trocar um token e reprovar um par fica sabendo aqui, não
// pela pessoa que não consegue ler o rótulo.
import 'package:baru_app/design/tokens.dart';
import 'package:baru_app/widgets/botao_baru.dart';
import 'package:baru_app/widgets/componentes.dart' show faceDaEtiqueta;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

Color _tingido(Color c, double a, Color sobre) =>
    Color.alphaBlend(c.withValues(alpha: a), sobre);

void main() {
  const fundos = {
    'superfície': Cores.superficie,
    'cartão': Cores.superficieElevada,
  };

  test('a fórmula bate com o valor publicado do W3C', () {
    // Preto sobre branco é 21:1 por definição.
    expect(
      Cores.contraste(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
  });

  group('texto ≥ 4,5:1', () {
    const textos = {
      'tinta': Cores.tinta,
      'tinta700 (secundário)': Cores.tinta700,
      'folha600': Cores.folha600,
      'folha700': Cores.folha700,
      'primariaEscura': Cores.primariaEscura,
      'raiz600': Cores.raiz600,
      'acentoTexto': Cores.acentoTexto,
      'mel700 (XP)': Cores.mel700,
      'ceu600': Cores.ceu600,
      'alerta': Cores.alerta,
      'dispersivo': Cores.dispersivo,
      'neutro': Cores.neutro,
      'produtivo': Cores.produtivo,
      'passivo': Cores.passivo,
    };
    for (final t in textos.entries) {
      for (final f in fundos.entries) {
        test('${t.key} sobre ${f.key}', () {
          expect(Cores.contraste(t.value, f.value), greaterThanOrEqualTo(4.5));
        });
      }
    }

    test('as cartelas tingidas: o rótulo na cor sobre ela a 12–28%', () {
      final pares = <String, (Color, Color)>{
        'raiz no chip da home': (
          Cores.raiz600,
          _tingido(Cores.raiz500, 0.10, Cores.superficie),
        ),
        'mel700 no "próximo passo"': (
          Cores.mel700,
          _tingido(Cores.mel400, 0.20, Cores.superficie),
        ),
        'tinta no "colher tudo"': (
          Cores.tinta700,
          _tingido(Cores.mel400, 0.28, Cores.superficieElevada),
        ),
        'mel700 na missão pronta do resultado': (
          Cores.mel700,
          _tingido(Cores.mel400, 0.24, Cores.superficie),
        ),
        'raiz no cartão da raiz': (
          Cores.raiz600,
          _tingido(Cores.raiz500, 0.12, Cores.superficie),
        ),
        'folha700 no ganho da sessão': (
          Cores.folha700,
          _tingido(Cores.folha600, 0.12, Cores.superficie),
        ),
        'alerta no aviso de permissão': (
          Cores.alerta,
          _tingido(Cores.alerta, 0.10, Cores.superficie),
        ),
      };
      for (final p in pares.entries) {
        expect(
          Cores.contraste(p.value.$1, p.value.$2),
          greaterThanOrEqualTo(4.5),
          reason: p.key,
        );
      }
    });

    test('a face de cada papel do botão com o seu texto', () {
      for (final p in paresDoBotao.entries) {
        final (face, texto) = p.value;
        expect(
          Cores.contraste(texto, face),
          greaterThanOrEqualTo(4.5),
          reason: p.key.name,
        );
      }
    });

    test('a etiqueta acha sozinha um rótulo legível em qualquer cor', () {
      for (final c in [
        Cores.mel400,
        Cores.folha600,
        Cores.raiz500,
        Cores.acento,
        Cores.alerta,
        Cores.neutro,
        Cores.passivo,
      ]) {
        final fundo = _tingido(c, 0.12, Cores.superficie);
        expect(
          Cores.contraste(Cores.legivelSobre(c, fundo), fundo),
          greaterThanOrEqualTo(4.5),
        );
        final face = faceDaEtiqueta(c);
        expect(
          Cores.contraste(Cores.textoSobre(face), face),
          greaterThanOrEqualTo(4.5),
          reason: 'etiqueta forte em $c',
        );
      }
    });
  });

  group('barra, ícone e glifo ≥ 3:1', () {
    test('o preenchimento da barra contra o trilho e o cartão', () {
      for (final f in [Cores.trilho, Cores.superficieElevada]) {
        expect(Cores.contraste(Cores.folha600, f), greaterThanOrEqualTo(3));
      }
    });

    test('os glifos e o ícone de apoio sobre a superfície', () {
      for (final c in [
        Cores.folha600,
        Cores.raiz600,
        Cores.mel700,
        Cores.ceu600,
        Cores.tinta500,
      ]) {
        expect(
          Cores.contraste(c, Cores.superficie),
          greaterThanOrEqualTo(3),
          reason: '$c',
        );
      }
    });
  });
}
