import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_pet.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/session_screen.dart';
import 'package:baru_app/state.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cada atividade tem animação própria, e ela é a certa.
///
/// Os testes daqui não conferem se a animação "existe no código". Eles
/// **capturam os pixels** e olham para faixas escolhidas do quadro, onde só
/// uma coisa pode desenhar. É a diferença entre provar que o quadro mudou —
/// o que a respiração já faria sozinha — e provar que *a braçada* empurrou a
/// água, que *a cabeça* desceu até o chão, que *a folha* caiu no bicho que
/// dorme.
///
/// A escolha das faixas está anotada caso a caso: elas dependem da geometria
/// do desenho, e mudar o desenho sem mudar o teste faria o teste passar
/// dizendo nada.

const _larguraDoQuadro = 200;
const _alturaDoQuadro = 150;

Widget _cena({
  required Activity activity,
  Species species = Species.capybara,
  Mood mood = Mood.content,
}) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: PetView(
          species: species,
          mood: mood,
          activity: activity,
          coat: 0,
          interativo: false,
        ),
      ),
    ),
  );
}

/// Pixels crus do desenho neste instante, em RGBA.
///
/// `toImage()` completa na thread de rasterização, fora do fake-async do
/// `flutter_test`: sem `runAsync` o Future nunca resolve e o teste trava.
Future<Uint8List> _quadro(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(PetView.cenaKey),
  );
  final bytes = await tester.runAsync(() async {
    final img = await boundary.toImage();
    expect(img.width, _larguraDoQuadro);
    expect(img.height, _alturaDoQuadro);
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

bool _mudou(Uint8List a, Uint8List b) {
  if (a.length != b.length) return true;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return true;
  }
  return false;
}

/// Quantos pixels de fato pintados existem numa faixa do quadro.
///
/// O limiar de 8 no canal alfa ignora a franja de antisserrilhado, que
/// aparece a um ou dois pixels de qualquer traço e faria uma faixa "vazia"
/// contar um punhado de pixels fantasmas.
int _pintadosEm(Uint8List px, int x0, int y0, int x1, int y1) {
  var n = 0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      if (px[(y * _larguraDoQuadro + x) * 4 + 3] > 8) n++;
    }
  }
  return n;
}

/// A primeira linha pintada dentro de uma coluna do quadro.
///
/// É a medida mais estável que existe aqui: não depende de quantos pixels
/// foram pintados, só de **onde** a coisa está.
int _topoDe(Uint8List px, int x0, int x1) {
  for (var y = 0; y < _alturaDoQuadro; y++) {
    if (_pintadosEm(px, x0, y, x1, y + 1) > 0) return y;
  }
  return _alturaDoQuadro;
}

/// A largura da silhueta numa faixa de linhas.
///
/// Mede o peito enchendo: o squash/stretch da respiração alarga o corpo
/// inteiro, e a faixa de linhas exclui a cabeça, o Zzz e a folha — que se
/// mexem por conta própria e falseariam a conta.
int _larguraDoTronco(Uint8List px, int y0, int y1) {
  var esq = _larguraDoQuadro, dir = -1;
  for (var y = y0; y < y1; y++) {
    for (var x = 0; x < _larguraDoQuadro; x++) {
      if (px[(y * _larguraDoQuadro + x) * 4 + 3] > 8) {
        if (x < esq) esq = x;
        if (x > dir) dir = x;
      }
    }
  }
  return dir < 0 ? 0 : dir - esq;
}

void _movimentoReduzido(WidgetTester tester) {
  tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(
    tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
  );
}

/// Uma volta inteira do laço, em [passos] amostras.
Future<List<Uint8List>> _voltaCompleta(
  WidgetTester tester,
  Duration ciclo,
  int passos,
) async {
  final quadros = <Uint8List>[];
  final passo = Duration(microseconds: ciclo.inMicroseconds ~/ passos);
  for (var i = 0; i < passos; i++) {
    quadros.add(await _quadro(tester));
    await tester.pump(passo);
  }
  return quadros;
}

void main() {
  // ======================================================================
  // A tradução por espécie
  // ======================================================================

  group('cada espécie faz o que é dela', () {
    test('a tabela inteira, espécie por espécie', () {
      // Escrita à mão de propósito: uma tabela derivada da própria função
      // não provaria nada. Se uma linha aqui incomodar alguém, a decisão
      // está justificada no comentário de `acaoDoBicho`.
      const esperado = {
        (Species.capybara, Activity.swim): AcaoDoBicho.nado,
        (Species.otter, Activity.swim): AcaoDoBicho.nado,
        (Species.tortoise, Activity.swim): AcaoDoBicho.nado,
        (Species.penguin, Activity.swim): AcaoDoBicho.nado,
        (Species.axolotl, Activity.swim): AcaoDoBicho.nado,
        (Species.owl, Activity.swim): AcaoDoBicho.voo,
        (Species.cat, Activity.swim): AcaoDoBicho.brincadeira,
        (Species.fox, Activity.swim): AcaoDoBicho.brincadeira,
        (Species.frenchie, Activity.swim): AcaoDoBicho.brincadeira,
        (Species.capybara, Activity.graze): AcaoDoBicho.pasto,
        (Species.tortoise, Activity.graze): AcaoDoBicho.pasto,
        (Species.otter, Activity.graze): AcaoDoBicho.petisco,
        (Species.owl, Activity.graze): AcaoDoBicho.petisco,
        (Species.penguin, Activity.graze): AcaoDoBicho.petisco,
        (Species.axolotl, Activity.graze): AcaoDoBicho.petisco,
        (Species.cat, Activity.graze): AcaoDoBicho.petisco,
        (Species.fox, Activity.graze): AcaoDoBicho.petisco,
        (Species.frenchie, Activity.graze): AcaoDoBicho.petisco,
      };
      // A tabela cobre **todas** as espécies: uma espécie nova que entre no
      // enum sem passar por aqui é uma decisão de produto que ninguém tomou.
      expect(
        esperado.keys.map((c) => c.$1).toSet(),
        Species.values.toSet(),
        reason: 'espécie sem decisão de atividade declarada',
      );
      esperado.forEach((chave, acao) {
        expect(
          acaoDoBicho(chave.$1, chave.$2),
          acao,
          reason: '${chave.$1.name} em ${chave.$2.name}',
        );
      });
    });

    test('dormir e ficar à toa não dependem da espécie', () {
      for (final sp in Species.values) {
        expect(acaoDoBicho(sp, Activity.nap), AcaoDoBicho.cochilo);
        expect(acaoDoBicho(sp, Activity.idle), AcaoDoBicho.ocioso);
      }
    });

    test('nenhuma espécie fica sem ação em nenhuma atividade', () {
      for (final sp in Species.values) {
        for (final a in Activity.values) {
          expect(() => acaoDoBicho(sp, a), returnsNormally);
        }
      }
    });
  });

  // ======================================================================
  // A atividade errada não desenha a certa
  // ======================================================================

  testWidgets('as quatro atividades dão quatro poses diferentes, em toda '
      'espécie', (tester) async {
    // Com movimento reduzido o contínuo e o laço param, então o que sobra é
    // só a **postura** de cada atividade. É o teste mais duro possível: se
    // duas atividades saem iguais aqui, elas só se distinguem enquanto a
    // animação corre — e quem pediu menos movimento fica sem a informação.
    _movimentoReduzido(tester);

    for (final sp in Species.values) {
      final quadros = <Activity, Uint8List>{};
      for (final a in Activity.values) {
        await tester.pumpWidget(_cena(activity: a, species: sp));
        await tester.pump();
        quadros[a] = await _quadro(tester);
      }
      for (final a in Activity.values) {
        for (final b in Activity.values) {
          if (a.index >= b.index) continue;
          expect(
            _mudou(quadros[a]!, quadros[b]!),
            isTrue,
            reason: '${sp.name}: ${a.name} e ${b.name} desenham igual',
          );
        }
      }
    }
  });

  // ======================================================================
  // NADAR
  // ======================================================================

  group('nadar', () {
    // A faixa é a **borda esquerda na linha d'água**. Só uma coisa desenha
    // ali: os anéis do rastro, cuja largura depende exclusivamente da fase
    // da braçada. O corpo mais largo (a capivara) vai de x=53 a x=147, as
    // gotas ficam por volta de x=64 e as bolhas nunca passam de x=72 para a
    // esquerda. Anel parado, faixa vazia.
    const x0 = 0, x1 = 24, y0 = 84, y1 = 104;

    testWidgets('a braçada empurra a água: o anel do rastro anda', (
      tester,
    ) async {
      await tester.pumpWidget(_cena(activity: Activity.swim));
      await tester.pump();

      final contagens = <int>[];
      for (final q in await _voltaCompleta(tester, _umaBracada, 8)) {
        contagens.add(_pintadosEm(q, x0, y0, x1, y1));
      }

      expect(
        contagens.toSet().length,
        greaterThanOrEqualTo(3),
        reason: 'o anel tem de crescer e sumir ao longo da braçada; '
            'contagens iguais são um anel congelado. Vistas: $contagens',
      );
      expect(
        contagens.reduce((a, b) => a > b ? a : b),
        greaterThan(0),
        reason: 'em algum ponto da braçada o anel chega à borda',
      );
    });

    testWidgets('só quem nada molha a cena', (tester) async {
      _movimentoReduzido(tester);

      Future<int> agua(Species sp, Activity a) async {
        await tester.pumpWidget(_cena(activity: a, species: sp));
        await tester.pump();
        return _pintadosEm(await _quadro(tester), x0, y0, x1, y1);
      }

      // A capivara parada não tem nada na linha d'água...
      expect(await agua(Species.capybara, Activity.idle), 0);
      expect(await agua(Species.capybara, Activity.graze), 0);
      // ...e nadando tem.
      expect(
        await agua(Species.capybara, Activity.swim),
        greaterThan(0),
        reason: 'sem rastro nenhum, "nadando" é o bicho de sempre um pouco '
            'mais baixo',
      );
      // A coruja no lugar do nado **voa**: a cena dela não molha.
      expect(
        await agua(Species.owl, Activity.swim),
        0,
        reason: 'coruja com anel de água em volta é coruja nadando',
      );
      // A gata brinca na beira, também sem entrar na água.
      expect(await agua(Species.cat, Activity.swim), 0);
    });

    testWidgets('o que está submerso ganha a cor da água', (tester) async {
      // Afundar não basta: sem o tom da água por cima, a metade de baixo do
      // bicho continua com a cor do pelo e ele lê como um adesivo colado
      // sobre a lagoa, não como um bicho dentro dela.
      //
      // A medida é o **viés de verde** (G − R) do corpo, comparado acima e
      // abaixo da lâmina. O tom da água é esverdeado, então submerso o viés
      // sobe. Num bicho fora d'água os dois lados do corpo têm o mesmo pelo
      // e o viés é o mesmo.
      _movimentoReduzido(tester);

      Future<double> vies(Activity a, int y0, int y1) async {
        await tester.pumpWidget(_cena(activity: a));
        await tester.pump();
        final px = await _quadro(tester);
        var soma = 0.0;
        var n = 0;
        for (var y = y0; y < y1; y++) {
          for (var x = 70; x < 130; x++) {
            final i = (y * _larguraDoQuadro + x) * 4;
            if (px[i + 3] < 200) continue; // só corpo opaco
            soma += px[i + 1] - px[i]; // verde menos vermelho
            n++;
          }
        }
        expect(n, greaterThan(200), reason: 'faixa sem corpo suficiente');
        return soma / n;
      }

      // Faixas simétricas em volta da lâmina, que fica em y = 87.
      final naguaAcima = await vies(Activity.swim, 66, 82);
      final naguaAbaixo = await vies(Activity.swim, 94, 110);
      final secoAcima = await vies(Activity.idle, 66, 82);
      final secoAbaixo = await vies(Activity.idle, 94, 110);

      expect(
        naguaAbaixo - naguaAcima,
        greaterThan(25),
        reason: 'submerso, o corpo tem de puxar para o verde da água. '
            'Acima: $naguaAcima, abaixo: $naguaAbaixo',
      );
      expect(
        (secoAbaixo - secoAcima).abs(),
        lessThan(25),
        reason: 'fora da água as duas metades do bicho têm o mesmo pelo, '
            'senão o teste acima estaria medindo anatomia e não água. '
            'Acima: $secoAcima, abaixo: $secoAbaixo',
      );
    });

    testWidgets('o corpo desce para dentro da água', (tester) async {
      _movimentoReduzido(tester);

      Future<int> topo(Activity a) async {
        await tester.pumpWidget(_cena(activity: a));
        await tester.pump();
        final q = await _quadro(tester);
        for (var y = 0; y < _alturaDoQuadro; y++) {
          if (_pintadosEm(q, 40, y, 160, y + 1) > 0) return y;
        }
        return _alturaDoQuadro;
      }

      final parado = await topo(Activity.idle);
      final naAgua = await topo(Activity.swim);
      expect(
        naAgua,
        greaterThan(parado + 5),
        reason: 'na água o bicho tem de estar mais fundo no quadro; parado '
            'começa em $parado e nadando em $naAgua',
      );
    });

    testWidgets('quem mergulha afunda mais que quem boia', (tester) async {
      _movimentoReduzido(tester);

      Future<int> topo(Species sp) async {
        await tester.pumpWidget(_cena(activity: Activity.swim, species: sp));
        await tester.pump();
        final q = await _quadro(tester);
        for (var y = 0; y < _alturaDoQuadro; y++) {
          if (_pintadosEm(q, 40, y, 160, y + 1) > 0) return y;
        }
        return _alturaDoQuadro;
      }

      // A tartaruga estica o pescoço fora d'água, então ela não entra nesta
      // comparação — o topo do quadro dela é o focinho, não o dorso.
      expect(
        await topo(Species.otter),
        greaterThan(await topo(Species.capybara)),
        reason: 'a lontra é um torpedo e a capivara é um flutuador; nadando '
            'igual, as duas são a mesma capivara de outra cor',
      );
    });
  });

  // ======================================================================
  // PASTAR
  // ======================================================================

  group('pastar', () {
    // A faixa é a **testa**: as linhas onde a cabeça está quando erguida e
    // onde não há nada quando ela desce até o chão. Com a cabeça em cima, o
    // topo do crânio da capivara fica por volta de y=24; abaixada, por
    // volta de y=50. Nada mais desenha acima de y=38 nessa largura.
    const x0 = 40, x1 = 160, y0 = 16, y1 = 38;

    testWidgets('a cabeça desce ao chão e volta — é ciclo, não pose', (
      tester,
    ) async {
      await tester.pumpWidget(_cena(activity: Activity.graze));
      await tester.pump();

      final contagens = <int>[];
      for (final q in await _voltaCompleta(tester, _umaPastagem, 14)) {
        contagens.add(_pintadosEm(q, x0, y0, x1, y1));
      }

      expect(
        contagens.where((c) => c == 0),
        isNotEmpty,
        reason: 'em algum momento do ciclo a cabeça tem de estar no chão. '
            'Vistas: $contagens',
      );
      expect(
        contagens.where((c) => c > 0),
        isNotEmpty,
        reason: 'e em outro ela tem de estar erguida, olhando em volta',
      );
    });

    testWidgets('parado, a cabeça nunca desce', (tester) async {
      await tester.pumpWidget(_cena(activity: Activity.idle));
      await tester.pump();

      for (final q in await _voltaCompleta(tester, _umaPastagem, 14)) {
        expect(
          _pintadosEm(q, x0, y0, x1, y1),
          greaterThan(0),
          reason: 'o bicho à toa não pasta; a cabeça fica onde está',
        );
      }
    });

    testWidgets('quem pasta abaixa mais que quem petisca', (tester) async {
      // Aqui a medida é o **percurso** do alto da cabeça, e não uma faixa
      // fixa: as espécies têm crânios de alturas diferentes, então comparar
      // posições absolutas compararia anatomia, não movimento. O que se
      // compara é quanto cada uma desce a partir de onde ela estava.
      Future<int> percursoDaCabeca(Species sp) async {
        await tester.pumpWidget(_cena(activity: Activity.graze, species: sp));
        await tester.pump();
        final vistos = <int>[];
        for (final q in await _voltaCompleta(tester, _umaVoltaLonga, 40)) {
          vistos.add(_topoDe(q, 40, 70));
        }
        return vistos.reduce((a, b) => a > b ? a : b) -
            vistos.reduce((a, b) => a < b ? a : b);
      }

      // A capivara enfia a cabeça no capim; a lontra pega e come em cima.
      final capivara = await percursoDaCabeca(Species.capybara);
      final lontra = await percursoDaCabeca(Species.otter);
      expect(
        capivara,
        greaterThan(lontra + 5),
        reason: 'lontra de focinho na grama é lontra pastando, e lontra não '
            'pasta. Capivara desceu $capivara px, lontra $lontra px',
      );
    });
  });

  // ======================================================================
  // DORMIR
  // ======================================================================

  group('dormir', () {
    // A faixa é o **caminho da folha** na descida: a fatia de cima do
    // quadro, sem a coluna do Zzz (que mora a partir de x=140). Medido: o
    // corpo do bicho deitado não chega a y=16 em lugar nenhum dessa
    // largura, então tudo que aparecer ali é a folha caindo.
    const x0 = 60, x1 = 138, y0 = 0, y1 = 16;

    testWidgets('uma folha desce e pousa nele', (tester) async {
      await tester.pumpWidget(
        _cena(activity: Activity.nap, mood: Mood.sleepy),
      );
      await tester.pump();

      final contagens = <int>[];
      for (final q in await _voltaCompleta(tester, _umSono, 40)) {
        contagens.add(_pintadosEm(q, x0, y0, x1, y1));
      }

      expect(
        contagens.where((c) => c > 0),
        isNotEmpty,
        reason: 'a folha tem de atravessar o caminho da queda. '
            'Vistas: $contagens',
      );
      expect(
        contagens.where((c) => c == 0),
        isNotEmpty,
        reason: 'e passar a maior parte do tempo pousada nele, fora dali',
      );
    });

    testWidgets('acordado não cai folha nenhuma', (tester) async {
      // Pastando, e não à toa, de propósito: o bicho à toa se espreguiça e
      // dá pulinhos, e o pulo joga o corpo dele para dentro desta mesma
      // faixa. Pastar é acordado e é quieto — mede o que se quer medir.
      await tester.pumpWidget(_cena(activity: Activity.graze));
      await tester.pump();
      for (final q in await _voltaCompleta(tester, _umSono, 40)) {
        expect(_pintadosEm(q, x0, y0, x1, y1), 0);
      }
    });

    testWidgets('a respiração do sono é lenta e funda', (tester) async {
      // O sinal medido é o alto da cabeça, na coluna esquerda do bicho: o
      // Zzz (x ≥ 140) e a folha (x ≥ 72) ficam fora, então o que sobe e
      // desce ali é o peito.
      await tester.pumpWidget(
        _cena(activity: Activity.nap, mood: Mood.sleepy),
      );
      await tester.pump();

      final sinal = <int>[];
      for (final q in await _voltaCompleta(tester, _umaVoltaLonga, 40)) {
        sinal.add(_topoDe(q, 40, 70));
      }

      // Os zeros saem antes de contar. O sinal é inteiro e tem platôs no
      // alto e no fundo de cada fôlego, e comparar deltas vizinhos fazia a
      // inversão cair sempre dentro de um platô — o contador devolvia zero
      // para qualquer velocidade de respiração. Medido: com o fôlego normal
      // no lugar do fôlego do sono, este teste passava.
      final sentidos = <bool>[];
      for (var i = 1; i < sinal.length; i++) {
        final d = sinal[i] - sinal[i - 1];
        if (d != 0) sentidos.add(d > 0);
      }
      var viradas = 0;
      for (var i = 1; i < sentidos.length; i++) {
        if (sentidos[i] != sentidos[i - 1]) viradas++;
      }
      expect(
        viradas,
        lessThanOrEqualTo(2),
        reason: 'em 13 s o peito de quem dorme sobe e desce uma vez só. Com '
            'o fôlego normal (3,4 s) cabem dois ciclos, e as viradas passam '
            'de três. Sinal: $sinal',
      );

      // E é funda. A medida é a **largura do tronco**, não a altura da
      // cabeça: o fator de profundidade entra no squash/stretch, e no alto
      // da cabeça ele vale menos de um pixel — medido, 10 px de percurso
      // com o fator e 9 px sem ele, o que não distingue nada. No peito, que
      // é onde a respiração acontece, são 6 px de expansão com o fator e 3
      // sem: o dobro.
      final larguras = <int>[];
      for (final q in await _voltaCompleta(tester, _umaVoltaLonga, 40)) {
        larguras.add(_larguraDoTronco(q, 100, 140));
      }
      final expansao = larguras.reduce((a, b) => a > b ? a : b) -
          larguras.reduce((a, b) => a < b ? a : b);
      expect(
        expansao,
        greaterThanOrEqualTo(5),
        reason: 'o peito de quem dorme enche mais que o de quem está '
            'acordado. Medido: $expansao px de expansão. Larguras: $larguras',
      );
    });
  });

  // ======================================================================
  // VOAR e BRINCAR — as espécies que não nadam
  // ======================================================================

  group('quem não nada', () {
    testWidgets('a coruja abre as asas e bate', (tester) async {
      // A faixa é a **ponta da asa aberta**, muito além do corpo. Dobrada,
      // a asa não passa de x=150; aberta, ela chega a x=186.
      const x0 = 172, x1 = 196;

      await tester.pumpWidget(
        _cena(activity: Activity.idle, species: Species.owl),
      );
      await tester.pump();
      expect(
        _pintadosEm(await _quadro(tester), x0, 0, x1, _alturaDoQuadro),
        0,
        reason: 'pousada, a asa fica dobrada no corpo',
      );

      await tester.pumpWidget(
        _cena(activity: Activity.swim, species: Species.owl),
      );
      await tester.pump();

      final altas = <int>[];
      final todas = <int>[];
      for (final q in await _voltaCompleta(tester, _umaAsada, 8)) {
        altas.add(_pintadosEm(q, x0, 0, x1, 40));
        todas.add(_pintadosEm(q, x0, 0, x1, _alturaDoQuadro));
      }

      expect(
        todas.every((n) => n > 0),
        isTrue,
        reason: 'no lugar do nado a coruja voa, e voando a asa está aberta '
            'o tempo todo. Vistas: $todas',
      );
      expect(
        altas.where((n) => n > 0),
        isNotEmpty,
        reason: 'a ponta da asa tem de subir na batida. Vistas: $altas',
      );
      expect(
        altas.where((n) => n == 0),
        isNotEmpty,
        reason: 'e descer de volta — asa parada no alto é planeio',
      );
    });

    testWidgets('a gata salta em vez de nadar', (tester) async {
      // A faixa é a **linha acima da orelha em repouso**: só o salto leva o
      // bicho até lá.
      await tester.pumpWidget(
        _cena(activity: Activity.swim, species: Species.cat),
      );
      await tester.pump();

      final alturas = <int>[];
      for (final q in await _voltaCompleta(tester, _umSalto, 8)) {
        var topo = _alturaDoQuadro;
        for (var y = 0; y < _alturaDoQuadro; y++) {
          if (_pintadosEm(q, 40, y, 160, y + 1) > 0) {
            topo = y;
            break;
          }
        }
        alturas.add(topo);
      }
      final maisAlto = alturas.reduce((a, b) => a < b ? a : b);
      final maisBaixo = alturas.reduce((a, b) => a > b ? a : b);
      expect(
        maisBaixo - maisAlto,
        greaterThanOrEqualTo(8),
        reason: 'o salto tem de tirar o bicho do chão de verdade. '
            'Vistas: $alturas',
      );
    });
  });

  // ======================================================================
  // O laço não pode ficar rodando escondido
  // ======================================================================

  testWidgets('o laço da atividade para com o app escondido', (tester) async {
    await tester.pumpWidget(_cena(activity: Activity.swim));
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(
      SchedulerBinding.instance.transientCallbackCount,
      0,
      reason: 'o laço novo é mais um ticker: escondido, ele também tem de '
          'parar de pedir quadro',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
  });

  testWidgets('trocar de atividade troca a cadência', (tester) async {
    // Sem reajustar o ritmo na troca, o bicho entrava na sessão remando no
    // compasso do ócio: sete segundos por braçada, que na tela é um bicho
    // parado. E o defeito era invisível para qualquer teste que só olhasse
    // "o quadro mudou", porque o ócio também mexe o quadro.
    //
    // O que se mede é a **borda esquerda do anel do rastro**: ela caminha
    // para fora conforme a onda abre e salta de volta quando o anel
    // recomeça. É um dente de serra, e o dente só aparece se o laço tiver
    // dado uma volta inteira dentro da braçada. Na cadência do ócio a borda
    // andaria uns três pixels e pronto — sem salto, sem volta.
    await tester.pumpWidget(_cena(activity: Activity.idle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.pumpWidget(_cena(activity: Activity.swim));
    await tester.pump();

    // A faixa fica **abaixo** da lâmina d'água, não em cima dela: o menisco
    // desenhado em volta do bicho chega a x=13 com alfa mínimo e segurava a
    // borda em 13 até o anel passar por baixo dele. Medido na primeira
    // tentativa deste teste, que passou com a cadência errada por causa
    // disso.
    // Duas braçadas, amostradas doze vezes cada: uma volta só termina no
    // último quadro e o salto de volta cairia fora da janela.
    final bordas = <int>[];
    for (final q in await _voltaCompleta(tester, _umaBracada * 2, 24)) {
      var borda = 50;
      for (var x = 0; x < 50; x++) {
        if (_pintadosEm(q, x, 96, x + 1, 106) > 0) {
          borda = x;
          break;
        }
      }
      bordas.add(borda);
    }

    var maiorSalto = 0;
    for (var i = 1; i < bordas.length; i++) {
      final salto = bordas[i] - bordas[i - 1];
      if (salto > maiorSalto) maiorSalto = salto;
    }
    expect(
      maiorSalto,
      greaterThanOrEqualTo(8),
      reason: 'em 1150 ms o anel tem de abrir e **recomeçar**. Sem o salto '
          'de volta, o laço ficou no compasso da atividade anterior. '
          'Bordas vistas: $bordas',
    );
  });

  // ======================================================================
  // A TELA DE SESSÃO
  // ======================================================================

  group('a tela de sessão', () {
    Future<AppState> abre(WidgetTester tester, Species sp) async {
      final app = AppState()..startCompanionship();
      app.species = sp;
      app.remaining = 25 * 60;
      addTearDown(app.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppScope(state: app, child: const SessionScreen()),
          ),
        ),
      );
      await tester.pump();
      return app;
    }

    testWidgets('o bicho não fica parado durante o foco', (tester) async {
      final app = await abre(tester, Species.capybara);
      expect(app.species, Species.capybara);

      final antes = await _quadro(tester);
      // Meia braçada: se a tela estivesse com o bicho parado, isto sairia
      // byte a byte igual — foi exatamente o defeito relatado.
      await tester.pump(const Duration(milliseconds: 575));
      final depois = await _quadro(tester);
      expect(_mudou(antes, depois), isTrue);
    });

    testWidgets('a legenda diz o que o desenho mostra', (tester) async {
      await abre(tester, Species.capybara);
      expect(find.text('Baru está nadando.'), findsOneWidget);
      expect(find.text('BANHO DE 25 MIN'), findsOneWidget);
    });

    testWidgets('a coruja voa, e a tela fala em voo', (tester) async {
      await abre(tester, Species.owl);
      expect(
        find.textContaining('voando'),
        findsOneWidget,
        reason: 'era aqui que a coruja dizia "está nadando"',
      );
      expect(find.textContaining('VOO DE 25 MIN'), findsOneWidget);
      expect(find.textContaining('nadando'), findsNothing);
    });

    testWidgets('a gata brinca, e a tela fala em brincadeira', (tester) async {
      await abre(tester, Species.cat);
      expect(find.textContaining('brincando'), findsOneWidget);
      expect(find.textContaining('nadando'), findsNothing);
    });

    testWidgets('a atividade da sessão é a mesma nas duas cenas', (
      tester,
    ) async {
      final app = await abre(tester, Species.otter);
      app.askQuit();
      await tester.pump();
      final bichos = tester.widgetList<PetView>(find.byType(PetView));
      expect(bichos.length, 2, reason: 'o da tela e o da folha de desistir');
      for (final b in bichos) {
        expect(b.activity, SessionScreen.atividade);
        expect(b.species, Species.otter);
      }
    });
  });

  // ======================================================================
  // Os quatro idiomas do §2
  // ======================================================================

  group('textos do pet', () {
    test('os 4 idiomas existem e têm as mesmas chaves', () {
      expect(textosDoPet.keys.toSet(), {'pt', 'en', 'es', 'zh'});
      final pt = textosDoPet['pt']!.keys.toSet();
      for (final lang in textosDoPet.keys) {
        expect(
          textosDoPet[lang]!.keys.toSet(),
          pt,
          reason: '$lang divergiu do catálogo de pt',
        );
        for (final e in textosDoPet[lang]!.entries) {
          expect(e.value.trim(), isNotEmpty, reason: '$lang.${e.key}');
        }
      }
    });

    test('toda ação tem frase nos quatro idiomas', () {
      garanteTextosDoPet();
      for (final lang in textosDoPet.keys) {
        final t = T(lang);
        for (final acao in AcaoDoBicho.values) {
          final frase = t.petFazendo(acao);
          expect(
            frase,
            isNot(contains('petFazendo_')),
            reason: '$lang não tem frase para ${acao.name} — a tela mostraria '
                'a chave crua',
          );
          expect(frase, contains('{n}'), reason: '$lang.${acao.name}');
          expect(
            t.petRotuloDaSessao(acao),
            contains('{m}'),
            reason: 'o rótulo da sessão precisa do número de minutos',
          );
        }
      }
    });
  });
}

/// Os mesmos períodos que `pet.dart` usa. Repetidos aqui de propósito: são
/// privados lá, e um teste que importasse a constante passaria a concordar
/// com o código em vez de conferi-lo.
const _umaBracada = Duration(milliseconds: 1150);
const _umaAsada = Duration(milliseconds: 820);
const _umaPastagem = Duration(milliseconds: 5600);
const _umSalto = Duration(milliseconds: 1900);
const _umSono = Duration(milliseconds: 13000);

/// Janela longa o bastante para caber mais de uma volta de qualquer laço e
/// mais de um fôlego, inclusive o do sono. Usada onde o que se mede é ritmo,
/// e não a fase de um ciclo específico.
const _umaVoltaLonga = Duration(milliseconds: 13000);
