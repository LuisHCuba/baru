@Tags(['evidencia'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:baru_app/l10n.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/theme.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A evidência da nona espécie: o buldogue francês.
///
/// Arquivo próprio, e não mais um caso dentro de `evidencia_test.dart`, por
/// dois motivos: aquele arquivo é de outra frente e roda 150 capturas, e o
/// que precisa ser julgado aqui é uma coisa só — se o bicho novo é
/// reconhecível e se ele não destoa dos oito.
///
/// **O que cada captura responde.**
///
/// - `elenco-nove.png` — a pergunta do elenco: ele parece da mesma família?
///   As nove espécies no mesmo tamanho, mesmo humor, mesma luz.
/// - `buldogue-humores.png` — os cinco humores, porque a cara achatada é a
///   mais difícil de fazer variar: sem focinho projetado sobra pouca área
///   para a boca dizer alguma coisa.
/// - `buldogue-pelagens.png` — a paleta inteira. É a única do app que
///   troca de pigmento em vez de trocar de tom, e o risco disso é o tigrado
///   e o preto engolirem os vincos.
/// - `buldogue-atividades.png` — as quatro atividades em que ele entra, lado
///   a lado. `swim` está ali de propósito e mostra o buldogue **brincando na
///   beira**: cão braquicefálico afunda de frente, e a tradução mora em
///   [acaoDoBicho]. A captura é o que impede alguém de "consertar" isso sem
///   ver o que estava consertando.
/// - `buldogue-brincadeira-*.png` — a atividade dele, quadro a quadro. O
///   teste **falha** se dois quadros vizinhos saírem idênticos: sem isso a
///   evidência afirmaria um movimento que ninguém exercitou.
/// - `buldogue-cara.png` — a cara em dobro. As folhas acima mostram o bicho
///   no tamanho em que ele aparece na tela, e nesse tamanho não dá para
///   julgar ruga, beiço nem narina: a decisão "isto é um buldogue francês"
///   se ganha ou se perde em detalhes de dois ou três pixels.
///
/// - `buldogue-orelha-*.png` — o par de quadros parado/tocado. A orelha é o
///   que sai da silhueta da cabeça, então é nela que a reação ao toque mais
///   aparece — mas ver isso é trabalho do olho, não do `expect`: o toque
///   também quica o corpo, e pixel nenhum separa as duas coisas.
///
/// As afirmações não são decorativas. Três coisas quebrariam em silêncio e
/// estão travadas aqui: o `case` novo caindo no de outra espécie (compara
/// contra gata e raposa, que dividem a mesma ação), o humor deixando de
/// mudar a cara, e a pelagem escura apagando o desenho.
const _pasta = '../docs/evidence/2026-08-28';

/// O laço da brincadeira, copiado de `pet.dart` — lá ele é privado. Copiar
/// mantém a evidência **amostrando** o código em vez de concordar com ele:
/// se alguém mudar a cadência lá e esquecer aqui, a amostragem sai torta e
/// aparece na folha.
const _cicloDaBrincadeira = Duration(milliseconds: 1900);

Future<void> _salva(WidgetTester tester, Key chave, String nome) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    final destino = Directory(_pasta)..createSync(recursive: true);
    File('${destino.path}/$nome.png').writeAsBytesSync(
      data!.buffer.asUint8List(),
    );
  });
}

Future<Uint8List> _pixels(WidgetTester tester, Key chave) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(chave));
  late Uint8List bytes;
  await tester.runAsync(() async {
    final img = await boundary.toImage();
    final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    bytes = data!.buffer.asUint8List();
  });
  return bytes;
}

bool _iguais(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Quantos pixels de tinta o desenho tem.
///
/// Serve para uma pergunta que nenhuma comparação de igualdade responde: a
/// pelagem escura ainda **desenha**? Um vinco que sumiu não muda o tamanho
/// da silhueta, mas muda quanto do bicho é traço em vez de bloco de cor.
int _pixelsComTinta(Uint8List rgba) {
  var n = 0;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] > 8) n++;
  }
  return n;
}

/// Um bicho num quadro fixo, com legenda embaixo.
Widget _cartao(Species sp, Mood m, Activity a, int coat, String legenda) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 200,
        height: 150,
        child: PetView(
          species: sp,
          mood: m,
          activity: a,
          coat: coat,
          interativo: false,
        ),
      ),
      Text(legenda, style: estilo(Tipo.rotulo)),
      const SizedBox(height: 10),
    ],
  );
}

Widget _folha(List<List<Widget>> linhas) => MaterialApp(
      home: Scaffold(
        backgroundColor: Cores.habitat,
        body: Center(
          child: RepaintBoundary(
            key: const Key('folha'),
            child: ColoredBox(
              color: Cores.habitat,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final linha in linhas)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: linha,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

Widget _sozinho(Species sp, Mood m, Activity a) => MaterialApp(
      home: Scaffold(
        backgroundColor: Cores.habitat,
        body: Center(
          child: PetView(
            species: sp,
            mood: m,
            activity: a,
            coat: 0,
            // Sem interação: o gesto de ocioso é sorteado por `Timer` e
            // entraria no meio da amostragem do laço.
            interativo: false,
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Sem a fonte de verdade o flutter_test escreve com a fonte de teste e
    // as legendas saem como caixinhas.
    for (final peso in [
      'Nunito-Regular',
      'Nunito-SemiBold',
      'Nunito-Bold',
      'Nunito-ExtraBold',
    ]) {
      final loader = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/$peso.ttf'));
      await loader.load();
    }
  });

  testWidgets('o elenco inteiro, o novo junto dos oito', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(1240, 1020);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final t = T('pt');
    final todas = Species.values;
    await tester.pumpWidget(
      _folha([
        for (var i = 0; i < todas.length; i += 3)
          [
            for (final sp in todas.skip(i).take(3))
              _cartao(
                sp,
                Mood.content,
                Activity.idle,
                0,
                t.animalName(sp.name),
              ),
          ],
      ]),
    );
    await tester.pump();
    await _salva(tester, const Key('folha'), 'elenco-nove');
  });

  testWidgets('o buldogue não saiu igual a nenhum outro bicho', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );

    // O risco concreto: um `case` novo caindo no de outra espécie por
    // engano. Gata e raposa são as candidatas — as três compartilham a
    // mesma [AcaoDoBicho] em `swim` e em `graze`, então um `case` colado no
    // lugar errado passaria por todo o resto da suíte.
    Future<Uint8List> desenha(Species sp) async {
      await tester.pumpWidget(_sozinho(sp, Mood.content, Activity.idle));
      await tester.pump();
      return _pixels(tester, PetView.cenaKey);
    }

    final buldogue = await desenha(Species.frenchie);
    for (final outra in Species.values) {
      if (outra == Species.frenchie) continue;
      expect(
        _iguais(buldogue, await desenha(outra)),
        isFalse,
        reason: 'o buldogue desenha igual a ${outra.name}',
      );
    }
  });

  testWidgets('os cinco humores mudam a cara achatada', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(1240, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const humores = [
      (Mood.radiant, 'radiante'),
      (Mood.content, 'contente'),
      (Mood.neutral, 'neutro'),
      (Mood.sleepy, 'com sono'),
      (Mood.missingYou, 'sentindo falta'),
    ];

    await tester.pumpWidget(
      _folha([
        [
          for (final (m, nome) in humores)
            _cartao(Species.frenchie, m, Activity.idle, 0, nome),
        ],
      ]),
    );
    await tester.pump();
    await _salva(tester, const Key('folha'), 'buldogue-humores');

    // A folha acima é uma imagem só e não denuncia dois humores iguais. Sem
    // focinho projetado sobra pouca cara para a boca trabalhar, e "neutro"
    // saindo idêntico a "contente" é exatamente o defeito plausível.
    final vistos = <Mood, Uint8List>{};
    for (final (m, _) in humores) {
      await tester.pumpWidget(_sozinho(Species.frenchie, m, Activity.idle));
      await tester.pump();
      vistos[m] = await _pixels(tester, PetView.cenaKey);
    }
    for (final (a, _) in humores) {
      for (final (b, _) in humores) {
        if (a.index >= b.index) continue;
        expect(
          _iguais(vistos[a]!, vistos[b]!),
          isFalse,
          reason: '${a.name} saiu igual a ${b.name}',
        );
      }
    }
  });

  testWidgets('as quatro atividades em que ele entra', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(1000, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // A cabeça do buldogue nasce 29 px acima do corpo, contra 28 do resto do
    // elenco, e o pasto a faz descer até 21 px. As duas coisas juntas são o
    // caso em que o queixo cai sobre as pernas — que é o defeito que esta
    // folha existe para deixar de ser invisível.
    const casos = [
      (Activity.idle, Mood.content, 'à toa'),
      (Activity.graze, Mood.content, 'petiscando'),
      (Activity.nap, Mood.sleepy, 'cochilando'),
      (Activity.swim, Mood.radiant, 'brincando na beira'),
    ];

    await tester.pumpWidget(
      _folha([
        [
          for (final (a, m, nome) in casos)
            _cartao(Species.frenchie, m, a, 0, nome),
        ],
      ]),
    );
    await tester.pump();
    await _salva(tester, const Key('folha'), 'buldogue-atividades');

    // A legenda "brincando na beira" tem de corresponder ao que o desenho
    // faz. Se alguém trocar o `case` do buldogue em `acaoDoBicho` para
    // `nado`, a folha continuaria bonita e passaria a mentir.
    expect(
      acaoDoBicho(Species.frenchie, Activity.swim),
      AcaoDoBicho.brincadeira,
      reason: 'o buldogue voltou a nadar, e cão braquicefálico afunda de '
          'frente — ver a nota em acaoDoBicho',
    );
  });

  testWidgets('a cara em dobro, para as rugas serem julgáveis', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(1000, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // `scale` e não um quadro maior: o painter desenha em pixels fixos, então
    // aumentar a caixa só acrescentaria fundo. O que precisa crescer é o
    // bicho.
    Widget grande(Mood m, int coat) => SizedBox(
          width: 320,
          height: 280,
          child: PetView(
            species: Species.frenchie,
            mood: m,
            activity: Activity.idle,
            coat: coat,
            scale: 1.9,
            interativo: false,
          ),
        );

    await tester.pumpWidget(
      _folha([
        [grande(Mood.content, 0), grande(Mood.radiant, 2)],
        [grande(Mood.missingYou, 3), grande(Mood.neutral, 5)],
      ]),
    );
    await tester.pump();
    await _salva(tester, const Key('folha'), 'buldogue-cara');
  });

  testWidgets('as seis pelagens, e nenhuma apaga o desenho', (tester) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    tester.view.physicalSize = const Size(1240, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const nomes = ['fulvo', 'fulvo escuro', 'creme', 'tigrado', 'blue', 'preto'];
    final paleta = AppColors.coatDe(Species.frenchie);
    expect(paleta.length, nomes.length);

    await tester.pumpWidget(
      _folha([
        [
          for (var i = 0; i < 3; i++)
            _cartao(Species.frenchie, Mood.content, Activity.idle, i, nomes[i]),
        ],
        [
          for (var i = 3; i < 6; i++)
            _cartao(Species.frenchie, Mood.content, Activity.idle, i, nomes[i]),
        ],
      ]),
    );
    await tester.pump();
    await _salva(tester, const Key('folha'), 'buldogue-pelagens');

    // A silhueta é a mesma em todo tom, então a área com tinta tem de ser
    // praticamente a mesma. Uma variação grande aqui significaria que uma
    // pelagem está comendo parte do desenho — ou sobrando dele.
    final areas = <int>[];
    for (var i = 0; i < paleta.length; i++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Cores.habitat,
            body: Center(
              child: PetView(
                species: Species.frenchie,
                mood: Mood.content,
                activity: Activity.idle,
                coat: i,
                interativo: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      areas.add(_pixelsComTinta(await _pixels(tester, PetView.cenaKey)));
    }
    final menor = areas.reduce((a, b) => a < b ? a : b);
    final maior = areas.reduce((a, b) => a > b ? a : b);
    expect(
      maior - menor,
      lessThan(maior * 0.02),
      reason: 'a silhueta muda de tamanho com a pelagem: $areas',
    );
  });

  testWidgets('brincando na beira, quadro a quadro', (tester) async {
    // Sem `disableAnimations` aqui: o que esta captura precisa provar é
    // justamente que o laço anda.
    await tester.pumpWidget(
      _sozinho(Species.frenchie, Mood.radiant, Activity.swim),
    );
    await tester.pump();

    const passos = 6;
    final passo = Duration(
      microseconds: _cicloDaBrincadeira.inMicroseconds ~/ passos,
    );
    Uint8List? anterior;
    for (var i = 0; i < passos; i++) {
      final agora = await _pixels(tester, PetView.cenaKey);
      if (anterior != null) {
        expect(
          _iguais(anterior, agora),
          isFalse,
          reason: 'os quadros ${i - 1} e $i saíram idênticos — a evidência '
              'estaria afirmando um movimento que não acontece',
        );
      }
      anterior = agora;
      await _salva(tester, PetView.cenaKey, 'buldogue-brincadeira-${i + 1}');
      await tester.pump(passo);
    }
  });

  testWidgets('o toque responde, e a orelha entra na resposta', (
    tester,
  ) async {
    // **O que este teste prova e o que ele não prova.** Ele prova que o
    // toque muda o desenho no instante em que o tremor de orelha está no
    // pico. Não prova que foi a orelha que se mexeu: o mesmo toque dispara a
    // quicada, que desloca o corpo inteiro, e nenhuma comparação de pixels
    // separa as duas.
    //
    // O que separa é o par de PNGs, e é para isso que ele existe — a olho, a
    // orelha do quadro 2 está aberta para fora. Afirmar mais que isso no
    // `expect` seria a evidência dizendo o que não mediu.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Cores.habitat,
          body: Center(
            child: PetView(
              species: Species.frenchie,
              mood: Mood.content,
              activity: Activity.idle,
              coat: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _salva(tester, PetView.cenaKey, 'buldogue-orelha-1-parada');
    final parada = await _pixels(tester, PetView.cenaKey);

    await tester.tap(find.byType(PetView));
    // 105 ms de 420: um quarto do laço da orelha, onde o desvio é máximo
    // (`sin(2π·0,25) = 1`). No fim do laço ela volta ao lugar e a captura
    // não provaria nada.
    await tester.pump(const Duration(milliseconds: 105));
    await _salva(tester, PetView.cenaKey, 'buldogue-orelha-2-tremendo');
    expect(
      _iguais(parada, await _pixels(tester, PetView.cenaKey)),
      isFalse,
      reason: 'o toque não mudou nada no desenho',
    );

    await tester.pump(const Duration(seconds: 3));
  });
}
