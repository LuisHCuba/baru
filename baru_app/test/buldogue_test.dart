/// O que faz o desenho ser **um buldogue francês**, e não um cão qualquer.
///
/// `evidencia_buldogue_test.dart` gera as folhas para o olho julgar. Este
/// arquivo é o outro lado: afirma em número o que a folha mostra, para que a
/// próxima pessoa que mexer em `_buldogue` descubra pela suíte, e não por uma
/// captura que ninguém abriu, que apagou um traço da raça.
///
/// **Por que medir pixel, e não chamar função.** Tudo em `pet.dart` é
/// privado e sem retorno: `_orelhaDeMorcego` pinta e devolve `void`. A única
/// superfície observável é o quadro. Então cada caso aqui mede uma
/// propriedade **geométrica ou de cor** do quadro que só existe se a parte
/// tiver sido desenhada — e nenhum caso compara com um PNG guardado, porque
/// golden trava o desenho inteiro e falha em qualquer ajuste de curva.
///
/// **Verificado por mutação.** Cada limiar foi conferido quebrando o desenho
/// de propósito e vendo o caso falhar. O que foi quebrado está anotado em
/// cada `expect`.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baru_app/models.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// O quadro do bicho. Fixo: as coordenadas abaixo são deste tamanho.
const _larg = 200;

Future<Uint8List> _quadro(WidgetTester tester) async {
  final b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(PetView.cenaKey),
  );
  final bytes = await tester.runAsync(() async {
    final img = await b.toImage();
    final d = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    return d!.buffer.asUint8List();
  });
  return bytes!;
}

Future<Uint8List> _desenha(
  WidgetTester tester, {
  Species especie = Species.frenchie,
  Mood humor = Mood.content,
  int coat = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Cores.habitat,
        body: Center(
          child: PetView(
            species: especie,
            mood: humor,
            activity: Activity.idle,
            coat: coat,
            // Sem interação: o gesto de ocioso é sorteado por `Timer` e
            // entraria no meio da medição.
            interativo: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _quadro(tester);
}

/// Luminância do pixel, ou -1 se ali não há tinta.
double _lum(Uint8List d, int x, int y) {
  final i = (y * _larg + x) * 4;
  if (d[i + 3] < 8) return -1;
  return 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2];
}

/// A primeira linha do quadro que tem tinta. É a altura do bicho — e, num
/// bicho cuja parte mais alta é a orelha, é a altura da orelha.
int _primeiraLinhaComTinta(Uint8List d) {
  for (var y = 0; y < 150; y++) {
    for (var x = 0; x < _larg; x++) {
      if (d[(y * _larg + x) * 4 + 3] > 8) return y;
    }
  }
  return 150;
}

/// Os blocos de tinta seguidos numa linha, como `(começo, largura)`.
///
/// Duas orelhas eretas e separadas dão **dois** blocos largos lá em cima. Um
/// bicho de cabeça redonda dá um só; um de orelha pontuda dá dois estreitos.
/// É a medida mais direta de "orelha de morcego" que um quadro permite.
List<(int, int)> _blocos(Uint8List d, int y) {
  final out = <(int, int)>[];
  var ini = -1;
  for (var x = 0; x < _larg; x++) {
    final tem = d[(y * _larg + x) * 4 + 3] > 8;
    if (tem && ini < 0) ini = x;
    if (!tem && ini >= 0) {
      out.add((ini, x - ini));
      ini = -1;
    }
  }
  if (ini >= 0) out.add((ini, _larg - ini));
  return out;
}

/// Quantas vezes a luminância muda ao varrer uma linha.
///
/// Pelo liso dá poucas; pelo rajado dá uma por listra. É o que separa o
/// tigrado das outras cinco pelagens sem depender de nenhuma cor exata.
int _viradasDeTom(Uint8List d, int y, int x0, int x1) {
  var n = 0;
  double? ant;
  for (var x = x0; x <= x1; x++) {
    final l = _lum(d, x, y);
    if (l < 0) continue;
    if (ant != null && (l - ant).abs() > 6) n++;
    ant = l;
  }
  return n;
}

/// Duas orelhas eretas, largas e separadas nesta linha?
bool _duasOrelhasEm(Uint8List d, int y) {
  final b = _blocos(d, y);
  if (b.length != 2) return false;
  if (b[0].$2 < 28 || b[1].$2 < 28) return false;
  return b[1].$1 - (b[0].$1 + b[0].$2) >= 20;
}

// --- pontos de amostra, todos no quadro de 200×150 ------------------------
//
// O corpo é desenhado com o centro em (100, 85) e a cabeça 29 px acima dele.
// Cada ponto abaixo está anotado com a coordenada de cabeça ou de corpo que
// lhe corresponde, porque é assim que `pet.dart` pensa.

/// Dentro da máscara e fora de tudo o mais.
///
/// Cabeça (24, 14): abaixo do olho, ao lado do nariz, acima do beiço e fora
/// do rolo da corda. O ponto foi escolhido justamente aí porque **só** a
/// máscara passa por ele — medir a focinheira não serviria, já que ela é
/// escura no fulvo por conta própria e o caso passaria com a máscara apagada.
/// Foi o que aconteceu na primeira versão deste teste.
const _naMascara = (124, 70);

/// Fora da máscara, dentro da cabeça: cabeça (42, 10). Antes de a prega da
/// papada começar (ela nasce em y = 11) e dentro do crânio, que em y = 10
/// chega a 47.
const _foraDaMascara = (142, 66);

/// Meio do peito (corpo 0,30).
const _peito = (100, 115);

/// Bochecha esquerda e direita na mesma altura (cabeça ∓38, 8). O pied é a
/// única pelagem que sai diferente nas duas.
const _faceEsquerda = (62, 64);
const _faceDireita = (138, 64);

/// Uma linha que corta o tronco abaixo do queixo (corpo y = 21).
const _linhaDoTronco = 106;

void main() {
  setUp(() {
    // O desenho não pode depender de em que ponto do laço o ticker parou.
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets('a orelha de morcego é dele, e de mais ninguém', (tester) async {
    // A orelha é o traço número um da raça: é o único elemento que sai da
    // silhueta da cabeça, então é ele que o olho pega primeiro na miniatura
    // e no ícone. "Larga na base, ereta, e as duas separadas no alto da
    // cabeça" vira, num quadro: **dois** blocos de tinta, cada um com pelo
    // menos 28 px, com pelo menos 20 px de céu entre eles — e isso em três
    // alturas seguidas, para não passar por acaso numa linha só.
    //
    // Mutações que derrubam este caso, as três rodadas de verdade:
    //   - trocar a chamada por `_orelhaRedonda`, a orelha da capivara: em
    //     y = 22 não sobra bloco nenhum, porque a orelha redonda não passa
    //     do crânio.
    //   - afinar a calota de 24 para 14 — a orelha de pastor-alemão que a
    //     segunda tentativa tinha: a largura cai para 25 em y = 22.
    //   - aproximar as bases do meio da cabeça: os blocos ficam com 41 de
    //     largura e 8 px de céu entre eles, e o vão exigido é 20.
    const alturas = [22, 26, 30];

    final buldogue = await _desenha(tester);
    for (final y in alturas) {
      expect(
        _duasOrelhasEm(buldogue, y),
        isTrue,
        reason: 'na linha $y o buldogue não tem duas orelhas largas e '
            'separadas: ${_blocos(buldogue, y)}',
      );
    }

    // E nenhuma das outras oito produz isso. Não é firula: a coruja tem
    // tufos, a gata e a raposa têm orelhas eretas, e o axolote tem guelras
    // saindo dos dois lados — três formas que passariam num teste frouxo.
    for (final outra in Species.values) {
      if (outra == Species.frenchie) continue;
      final d = await _desenha(tester, especie: outra);
      final passa = alturas.every((y) => _duasOrelhasEm(d, y));
      expect(
        passa,
        isFalse,
        reason: '${outra.name} também desenha duas orelhas de morcego — '
            'ou o `case` dele caiu no do buldogue',
      );
    }
  });

  testWidgets('cada pelagem desenha a marcação que a raça tem', (tester) async {
    // A paleta do buldogue é a única do app que troca de pigmento em vez de
    // trocar de tom, e pigmento de cão vem com desenho junto. Sem isto as
    // seis entradas da loja eram o mesmo cão em seis tintas — que foi
    // exatamente o defeito apontado.

    // --- fulvo (0 e 1): máscara escura ------------------------------------
    //
    // A máscara é a lateral do focinho escura contra a bochecha clara, na
    // mesma altura. Mutação: apagar o corpo do `case mascara` em
    // `_marcaDaCabeca` derruba a diferença de 53 para 0 — e a primeira versão
    // deste caso, que media o meio da focinheira, **passava** com a máscara
    // apagada, porque a focinheira é escura por conta própria no fulvo.
    for (final coat in [0, 1]) {
      final d = await _desenha(tester, coat: coat);
      final dentro = _lum(d, _naMascara.$1, _naMascara.$2);
      final fora = _lum(d, _foraDaMascara.$1, _foraDaMascara.$2);
      expect(
        dentro,
        lessThan(fora - 25),
        reason: 'a pelagem $coat é fulva e devia ter máscara: dentro dela '
            '($dentro) não está mais escuro que a bochecha ($fora)',
      );
    }

    // --- creme (2): pied --------------------------------------------------
    final pied = await _desenha(tester, coat: 2);

    // Peito branco. Não "mais claro que o flanco" — o ventre de qualquer
    // pelagem já é mais claro que o flanco; o peito do pied é **branco**, e é
    // isso que a medida absoluta pega.
    //
    // O limiar é 228 e não 215, e a diferença é o teste funcionar ou não.
    // Mutação: trocar `_brancoDoPied` pelo `barriga` das outras pelagens
    // derruba a luminância de 240 para 216 — porque o pelo base do pied já é
    // creme, e o ventre clareado de um creme quase chega ao branco. Com 215
    // a mutação **passava**. Nas cinco pelagens que não são pied o peito não
    // passa de 188, então a folga continua larga dos dois lados.
    expect(
      _lum(pied, _peito.$1, _peito.$2),
      greaterThan(228),
      reason: 'o peito do pied não está branco',
    );

    // A mancha de um olho só. É a assimetria que faz o pied parecer um cão
    // específico em vez de um decalque, e é a única do elenco inteiro.
    // Mutação: espelhar a mancha zera a diferença.
    final esq = _lum(pied, _faceEsquerda.$1, _faceEsquerda.$2);
    final dir = _lum(pied, _faceDireita.$1, _faceDireita.$2);
    expect(
      (esq - dir).abs(),
      greaterThan(60),
      reason: 'o pied não tem mancha em um dos lados da cara: $esq vs $dir',
    );

    // --- tigrado (3): listras ---------------------------------------------
    //
    // Rajado é textura, e textura se mede contando quantas vezes o tom muda
    // ao varrer o tronco. Mutação: apagar `_tigradoDoCorpo` derruba de 14
    // para 3, que é o que as pelagens lisas dão.
    final tigrado = await _desenha(tester, coat: 3);
    final listras = _viradasDeTom(tigrado, _linhaDoTronco, 56, 144);
    expect(
      listras,
      greaterThanOrEqualTo(10),
      reason: 'o tigrado não está rajado: só $listras mudanças de tom no '
          'tronco',
    );

    // --- as outras cinco não são tigradas nem pied ------------------------
    //
    // Metade de um teste de marcação é provar que ela **não** vaza para quem
    // não devia ter. Um `switch` sem `case` fechado pintaria listra em todo
    // mundo e a suíte inteira passaria.
    for (final coat in [0, 1, 2, 4, 5]) {
      final d = await _desenha(tester, coat: coat);
      expect(
        _viradasDeTom(d, _linhaDoTronco, 56, 144),
        lessThan(10),
        reason: 'a pelagem $coat saiu rajada e não devia',
      );
      if (coat == 2) continue;
      final e = _lum(d, _faceEsquerda.$1, _faceEsquerda.$2);
      final dd = _lum(d, _faceDireita.$1, _faceDireita.$2);
      expect(
        (e - dd).abs(),
        lessThan(10),
        reason: 'a pelagem $coat saiu com a cara assimétrica',
      );
      expect(
        _lum(d, _peito.$1, _peito.$2),
        lessThan(215),
        reason: 'a pelagem $coat saiu com o peito branco do pied',
      );
    }

    // --- as quatro que não são fulvas não têm máscara ----------------------
    //
    // Creme, tigrado, blue e preto são cores de pelo, não desenhos: o padrão
    // da raça não dá máscara para elas. Aqui os dois pontos têm de sair
    // iguais. Mutação: pintar a máscara em todas as pelagens abre 53 de
    // diferença e derruba as quatro.
    //
    // O pied entra na conta porque a mancha dele fica na **esquerda** da
    // cara e os dois pontos são da direita. Se alguém trocar a mancha de
    // lado, este caso acusa — o que é ruído, mas ruído útil: a assimetria é
    // parte do desenho e mudá-la tem de doer em algum lugar.
    for (final coat in [2, 3, 4, 5]) {
      final d = await _desenha(tester, coat: coat);
      final dentro = _lum(d, _naMascara.$1, _naMascara.$2);
      final fora = _lum(d, _foraDaMascara.$1, _foraDaMascara.$2);
      expect(
        (dentro - fora).abs(),
        lessThan(8),
        reason: 'a pelagem $coat ganhou máscara, e o padrão da raça não dá '
            'máscara para ela: $dentro contra $fora',
      );
    }

    // A silhueta é a mesma nas seis: marcação pinta por dentro do bicho,
    // nunca por fora dele. Uma listra vazando do tronco mudaria o alfa.
    var area = -1;
    for (var coat = 0; coat < AppColors.coatDe(Species.frenchie).length;
        coat++) {
      final d = await _desenha(tester, coat: coat);
      var n = 0;
      for (var i = 3; i < d.length; i += 4) {
        if (d[i] > 8) n++;
      }
      if (area < 0) {
        area = n;
      } else {
        expect(
          (n - area).abs(),
          lessThan(area ~/ 50),
          reason: 'a pelagem $coat mudou a silhueta: $n contra $area',
        );
      }
    }
  });

  testWidgets('a orelha cai e a língua sai conforme o humor', (tester) async {
    // Os dois sinais que um humano lê num cachorro antes de qualquer boca:
    // a orelha em pé ou caída, e a língua para fora.

    // --- orelha ------------------------------------------------------------
    //
    // A primeira linha com tinta é a ponta da orelha. Orelha ereta chega
    // perto do topo do quadro; orelha deitada para o lado desce. Mutação:
    // zerar `_orelhaTomba` iguala os cinco humores em 9.
    final topo = <Mood, int>{};
    for (final m in Mood.values) {
      topo[m] = _primeiraLinhaComTinta(await _desenha(tester, humor: m));
    }
    expect(
      topo[Mood.radiant]!,
      lessThan(topo[Mood.neutral]!),
      reason: 'a orelha do radiante não está mais alta que a do neutro: '
          '$topo',
    );
    expect(
      topo[Mood.neutral]!,
      lessThan(topo[Mood.sleepy]!),
      reason: 'a orelha não cai com o sono: $topo',
    );
    expect(
      topo[Mood.missingYou]!,
      greaterThan(topo[Mood.neutral]! + 5),
      reason: 'a orelha não cai em quem está sentindo falta: $topo',
    );

    // --- língua ------------------------------------------------------------
    //
    // Conta pixels de rosa-língua na região da boca. O limiar de cor é
    // estreito de propósito: o fulvo do pelo (203,162,116) tem R−B de 87 e
    // fica de fora dos 100 exigidos, então o que sobra é língua mesmo.
    // Mutação: tirar o `mood != Mood.radiant` do início de
    // `_linguaDoBuldogue` faz os cinco humores contarem ~196.
    int rosa(Uint8List d) {
      var n = 0;
      for (var y = 84; y <= 110; y++) {
        for (var x = 84; x <= 116; x++) {
          final i = (y * _larg + x) * 4;
          final r = d[i], g = d[i + 1], b = d[i + 2];
          if (d[i + 3] > 8 && r > 225 && g > 140 && g < 190 && r - b > 100) {
            n++;
          }
        }
      }
      return n;
    }

    expect(
      rosa(await _desenha(tester, humor: Mood.radiant)),
      greaterThan(100),
      reason: 'o buldogue radiante está sem língua de fora',
    );
    for (final m in Mood.values) {
      if (m == Mood.radiant) continue;
      expect(
        rosa(await _desenha(tester, humor: m)),
        0,
        reason: 'o buldogue ${m.name} está de língua para fora, e só o '
            'radiante devia estar',
      );
    }
  });
}
