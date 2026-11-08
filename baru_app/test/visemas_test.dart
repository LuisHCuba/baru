// Visemas da fala (laudo 30, §3.2 e §3.7): os sete formatos de boca
// (X A B C D E F) por humor, mais susto e festa, de cada espécie — as folhas
// que a série "A turma do Baru" indexa por visema, e o material que
// `test/boca_medidas.py` mede. Só com CAPTURAS=1:
//
//   CAPTURAS=1 flutter test test/visemas_test.dart
//   CAPTURAS=1 ESPECIES=otter,fox flutter test test/visemas_test.dart
//
// Sai em build/visemas/<espécie>/:
//   <humor>-<visema>.png   o bicho inteiro (caixa 260×220, ×3), humor
//                          contente, radiante, neutro, sono, saudade;
//   susto-<visema>.png     contente com `susto: 1`; festa-<visema>.png,
//                          radiante com `festa: 1`;
//   corpo-<visema>.png     contente, com `semBoca: true` e os outros
//                          parâmetros do visema — a base da camada de boca
//                          (corpo-x é o corpo em repouso sem boca);
//   boca-<visema>.png      só a boca (humor contente), fundo transparente,
//                          recorte centrado na âncora.
// E build/visemas/ancoras.json: por captura, a transformação do canvas na
// hora de desenhar a boca, a origem e a largura dela (unidades da cabeça), o
// ponto da âncora em pixels da captura e a escala (pixels por unidade); por
// espécie, a tabela `BocaDaEspecie`; por camada de boca, o recorte.
//
// **Como a camada de boca é feita.** O bicho é capturado inteiro duas vezes,
// com a boca do visema e com `semBoca: true` (e a mesma abertura, para o
// queixo, que desce com a boca bem aberta, ficar no corpo e não na camada),
// e a camada é a diferença: cada pixel que mudou entra com a cor do quadro
// com boca, o resto fica transparente. É o mais robusto dos dois caminhos
// possíveis: usa só a API pública do painter, não precisa de um segundo
// painter que saiba onde cada espécie desenha a boca, e a composição (corpo
// + camada na âncora) devolve o quadro original pixel a pixel. O preço é que
// as bordas da boca carregam o pelo com que foram suavizadas — invisível na
// escala da série.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baru_app/data/crescimento.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:baru_app/widgets/vida/motor_de_vida.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _ligado = Platform.environment['CAPTURAS'] == '1';
const _pasta = 'build/visemas';
const _tamanho = Size(260, 220);
const _densidade = 3.0;

const _humores = {
  'contente': Mood.content,
  'radiante': Mood.radiant,
  'neutro': Mood.neutral,
  'sono': Mood.sleepy,
  'saudade': Mood.missingYou,
};

/// Um quadro capturado: os pixels (RGBA, alfa reto) e o tamanho.
class _Quadro {
  _Quadro(this.pixels, this.largura, this.altura);
  final Uint8List pixels;
  final int largura;
  final int altura;
}

Widget _cena(Species sp, Mood humor, QuadroFixo q) => SizedBox(
  width: _tamanho.width,
  height: _tamanho.height,
  child: PetView(
    species: sp,
    mood: humor,
    activity: Activity.idle,
    coat: 0,
    estagio: EstagioDoBicho.adulto,
    interativo: false,
    width: _tamanho.width,
    height: _tamanho.height,
    quadro: q,
  ),
);

/// A âncora como o painter a entregou, mais o ponto em pixels da captura e
/// a escala (pixels por unidade da cabeça).
Map<String, dynamic> _ancora(Float64List m, Offset o, double w) {
  final px = (m[0] * o.dx + m[4] * o.dy + m[12]) * _densidade;
  final py = (m[1] * o.dx + m[5] * o.dy + m[13]) * _densidade;
  final escala = (m[0] * m[5] - m[1] * m[4]).abs();
  return {
    'm': m.toList(),
    'o': [o.dx, o.dy],
    'w': w,
    'p': [px, py],
    'escala': _densidade * (escala > 0 ? _raiz(escala) : 1),
  };
}

double _raiz(double x) {
  // Sem `dart:math` só por isto: Newton em três passos chega a 1e-9 na
  // faixa de escalas do painter (0,5 a 1,5).
  var r = x > 1 ? x : 1.0;
  for (var i = 0; i < 20; i++) {
    r = 0.5 * (r + x / r);
  }
  return r;
}

Future<Uint8List> _png(ui.Image img) async {
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void _grava(String nome, Uint8List bytes) {
  File('$_pasta/$nome.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

/// A camada de boca: o que mudou entre o quadro com boca e o corpo sem ela,
/// recortado num quadrado centrado na âncora. Devolve o recorte.
Future<List<int>> _camadaDeBoca(
  WidgetTester tester,
  _Quadro comBoca,
  _Quadro corpo,
  List<double> ancora,
  String nome,
) async {
  final w = comBoca.largura, h = comBoca.altura;
  final a = comBoca.pixels, b = corpo.pixels;
  var x0 = w, y0 = h, x1 = -1, y1 = -1;
  final camada = Uint8List(a.length);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      if (a[i] == b[i] &&
          a[i + 1] == b[i + 1] &&
          a[i + 2] == b[i + 2] &&
          a[i + 3] == b[i + 3]) {
        continue;
      }
      camada[i] = a[i];
      camada[i + 1] = a[i + 1];
      camada[i + 2] = a[i + 2];
      // Onde a boca entrou por cima do pelo o pixel é opaco; onde só o
      // contorno mudou (o queixo descendo), fica o alfa do quadro.
      camada[i + 3] = a[i + 3];
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      if (y > y1) y1 = y;
    }
  }
  if (x1 < 0) {
    x0 = ancora[0].round() - 1;
    x1 = x0 + 1;
    y0 = ancora[1].round() - 1;
    y1 = y0 + 1;
  }
  // Quadrado centrado na âncora, cabendo tudo o que mudou (e dentro do
  // quadro: se a âncora estiver perto da borda, o centro sai registrado no
  // JSON mesmo assim).
  final cx = ancora[0], cy = ancora[1];
  var meioX = 0.0, meioY = 0.0;
  for (final x in [x0.toDouble(), x1.toDouble()]) {
    if ((x - cx).abs() > meioX) meioX = (x - cx).abs();
  }
  for (final y in [y0.toDouble(), y1.toDouble()]) {
    if ((y - cy).abs() > meioY) meioY = (y - cy).abs();
  }
  final rx0 = (cx - meioX - 2).floor().clamp(0, w - 1);
  final rx1 = (cx + meioX + 2).ceil().clamp(rx0 + 1, w);
  final ry0 = (cy - meioY - 2).floor().clamp(0, h - 1);
  final ry1 = (cy + meioY + 2).ceil().clamp(ry0 + 1, h);
  final rw = rx1 - rx0, rh = ry1 - ry0;
  final recorte = Uint8List(rw * rh * 4);
  for (var y = 0; y < rh; y++) {
    final de = ((ry0 + y) * w + rx0) * 4;
    recorte.setRange(y * rw * 4, (y + 1) * rw * 4, camada, de);
  }
  await tester.runAsync(() async {
    final feito = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      recorte,
      rw,
      rh,
      ui.PixelFormat.rgba8888,
      feito.complete,
    );
    final img = await feito.future;
    _grava(nome, await _png(img));
    img.dispose();
  });
  return [rx0, ry0, rx1, ry1];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final quais = Platform.environment['ESPECIES']?.split(',');
  final especies = Species.values
      .where((s) => quais == null || quais.contains(s.name))
      .toList();

  testWidgets(
    'visemas por humor, susto, festa e camada de boca (x3)',
    skip: !_ligado,
    (tester) async {
      final saida = <String, dynamic>{};
      Map<String, dynamic>? ultimaAncora;
      PetView.aoDesenharBoca = (m, o, w) => ultimaAncora = _ancora(m, o, w);

      /// Desenha, grava o PNG e devolve os pixels e a âncora daquele quadro.
      Future<(_Quadro, Map<String, dynamic>)> captura(
        Species sp,
        Mood humor,
        QuadroFixo q,
        String nome,
      ) async {
        ultimaAncora = null;
        final chave = GlobalKey();
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: RepaintBoundary(key: chave, child: _cena(sp, humor, q)),
            ),
          ),
        );
        final b =
            chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        late _Quadro quadro;
        await tester.runAsync(() async {
          final img = await b.toImage(pixelRatio: _densidade);
          final raw = await img.toByteData(
            format: ui.ImageByteFormat.rawStraightRgba,
          );
          quadro = _Quadro(raw!.buffer.asUint8List(), img.width, img.height);
          _grava(nome, await _png(img));
          img.dispose();
        });
        expect(
          ultimaAncora,
          isNotNull,
          reason: '$nome: a boca não foi desenhada',
        );
        return (quadro, ultimaAncora!);
      }

      for (final sp in especies) {
        final boca = BocaDaEspecie.de(sp);
        final ancoras = <String, dynamic>{};
        final contente = <Visema, _Quadro>{};
        for (final h in _humores.entries) {
          for (final v in Visema.values) {
            final nome = '${h.key}-${v.name}';
            final (q, a) = await captura(
              sp,
              h.value,
              QuadroFixo.visema(v),
              '${sp.name}/$nome',
            );
            ancoras[nome] = a;
            if (h.value == Mood.content) contente[v] = q;
          }
        }
        for (final v in Visema.values) {
          final (_, a) = await captura(
            sp,
            Mood.content,
            QuadroFixo.visema(v, susto: 1),
            '${sp.name}/susto-${v.name}',
          );
          ancoras['susto-${v.name}'] = a;
          final (_, b) = await captura(
            sp,
            Mood.radiant,
            QuadroFixo.visema(v, festa: 1),
            '${sp.name}/festa-${v.name}',
          );
          ancoras['festa-${v.name}'] = b;
        }

        // O corpo sem boca de cada visema e, por diferença, a camada de boca.
        late _Quadro corpo;
        for (final v in Visema.values) {
          final f = bocaDoVisema(v);
          final (q, a) = await captura(
            sp,
            Mood.content,
            QuadroFixo(
              vida: SaidaDaVida(
                boca: f.abertura,
                largura: f.largura,
                lingua: f.lingua,
                dentes: f.dentes,
                semBoca: true,
              ),
            ),
            '${sp.name}/corpo-${v.name}',
          );
          corpo = q;
          ancoras['corpo-${v.name}'] = a;
          final p = (ancoras['contente-${v.name}']['p'] as List).cast<double>();
          final recorte = await _camadaDeBoca(
            tester,
            contente[v]!,
            corpo,
            p,
            '${sp.name}/boca-${v.name}',
          );
          ancoras['boca-${v.name}'] = {
            ...ancoras['contente-${v.name}'] as Map<String, dynamic>,
            'recorte': recorte,
          };
        }

        saida[sp.name] = {
          'especie': {
            'o': [boca.origem.dx, boca.origem.dy],
            'w': boca.largura,
            'hMax': boca.hMax,
            'folgaNariz': boca.folgaNariz,
            'temDentes': boca.temDentes,
            'temLingua': boca.temLingua,
            'bico': sp == Species.owl || sp == Species.penguin,
          },
          'densidade': _densidade,
          'quadro': [corpo.largura, corpo.altura],
          'capturas': ancoras,
        };
      }
      PetView.aoDesenharBoca = null;

      // Com ESPECIES, completa o JSON que já existir em vez de apagá-lo.
      final arquivo = File('$_pasta/ancoras.json');
      final anterior = arquivo.existsSync()
          ? jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>
          : <String, dynamic>{};
      arquivo
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode({...anterior, ...saida}));
    },
  );
}
