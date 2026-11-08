// Folhas da série "A turma do Baru" para o motor único (`turma.js`): tudo o
// que o motor usa sai daqui, numa família só de folhas, todas no MESMO
// quadro de captura (260×220 lógicos), com a âncora da boca exportada por
// quadro. O motor nunca usa a folha estática: o corpo vem sempre de um laço
// de vida (ou de um ciclo/pose) capturado SEM boca, e a boca do visema entra
// por cima, na âncora do quadro (laudo 30 §3.7, achados MN-01/03/04/05).
//
// Só com CAPTURAS=1:
//   CAPTURAS=1 flutter test test/novelinha_folhas_test.dart
//   CAPTURAS=1 ESPECIES=otter,fox flutter test test/novelinha_folhas_test.dart
//   CAPTURAS=1 SO=bocas flutter test ...   (SO = vida | bocas | poses | ciclos)
//
// Sai em build/novelinha/:
//   vida-<esp>-<humor>-<estado>/<i>.png   laço de vida de 120 quadros (×2),
//        semBoca, humor ∈ contente/radiante/sono/saudade, estado ∈
//        normal/susto/festa. O laço FECHA (mesma costura do atlas_vida).
//   vida-tortoise_enc-<humor>-<estado>/   o mesmo laço com o pescoço recolhido
//   vida-tortoise_dorme-sono-normal/      dormindo no casco
//   lado-owl/<i> (30) e cima-owl/<i> (24) a coruja virando o rosto e olhando
//        pro céu (rampas; o motor toca ida e volta)
//   anda|corre|nada|voa|brinca-<esp>/<i>  ciclos de 24 quadros (×2), semBoca (brinca = salto, gata e raposa)
//   boca-<esp>-<humor>/<visema>.png       só a boca (fundo transparente, ×3),
//        humor ∈ contente/radiante/sono/saudade/susto/festa: a diferença entre
//        o bicho com a boca do visema e o mesmo bicho sem boca (abertura 0)
//   ancoras_vida.json                     por folha e quadro: âncora da boca
//        em px da captura [x, y, escala(px/unidade), ângulo(rad)], piscadas;
//        por folha de boca: âncora, escala e recorte de cada visema.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baru_app/data/crescimento.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/widgets/pet.dart';
import 'package:baru_app/widgets/vida/motor_de_vida.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'atlas_anim24_test.dart' as anim;
import 'atlas_vida_test.dart' as vida;

final _ligado = Platform.environment['CAPTURAS'] == '1';
const _pasta = 'build/novelinha';
const _tamanho = Size(260, 220);
const _dVida = 2.0;
const _dBoca = 3.0;
const _n = 120;

const _humores = {
  'contente': Mood.content,
  'radiante': Mood.radiant,
  'sono': Mood.sleepy,
  'saudade': Mood.missingYou,
};
const _estados = ['normal', 'susto', 'festa'];
const _nadam = {Species.capybara, Species.otter, Species.tortoise, Species.penguin, Species.axolotl};

/// Cópia completa de um quadro do motor com alguns campos trocados.
SaidaDaVida _copia(SaidaDaVida s, {double? boca, double? largura, double? lingua, double? dentes, double? pescoco, double? pisca, double? susto, double? festa, bool? semBoca}) =>
    SaidaDaVida(respiro: s.respiro, boia: s.boia, cauda: s.cauda, ciclo: s.ciclo, olhar: s.olhar, inclina: s.inclina, achata: s.achata, desloca: s.desloca, virado: s.virado, balanco: s.balanco, carregado: s.carregado, altura: s.altura, pisca: pisca ?? s.pisca, emburrado: s.emburrado, derretido: s.derretido, passada: s.passada, gingado: s.gingado, andando: s.andando, planando: s.planando, freando: s.freando, deita: s.deita, comendo: s.comendo, reverencia: s.reverencia, giro: s.giro, adormecido: s.adormecido, elastico: s.elastico, dente: s.dente, denteForca: s.denteForca, susto: susto ?? s.susto, festa: festa ?? s.festa, grito: s.grito, riso: s.riso, planeio: s.planeio, freio: s.freio, corrida: s.corrida, poeira: s.poeira, pataEsquerda: s.pataEsquerda, pataDireita: s.pataDireita, virada: s.virada, cabecaAtraso: s.cabecaAtraso, cabecaGiro: s.cabecaGiro, cabecaDesce: s.cabecaDesce, atividadeAtiva: s.atividadeAtiva, corpoLivre: s.corpoLivre, cabecaNoChao: s.cabecaNoChao, mastigando: s.mastigando, forcaDaAtividade: s.forcaDaAtividade, cicloDaAtividade: s.cicloDaAtividade, boca: boca ?? s.boca, largura: largura ?? s.largura, canto: s.canto, lingua: lingua ?? s.lingua, dentes: dentes ?? s.dentes, semBoca: semBoca ?? s.semBoca, pescoco: pescoco ?? s.pescoco, voando: s.voando, faseDoPasso: s.faseDoPasso);

class _Quadro {
  _Quadro(this.pixels, this.largura, this.altura);
  final Uint8List pixels;
  final int largura;
  final int altura;
}

/// A âncora como o painter a entregou: ponto em px da captura, escala
/// (px por unidade da cabeça) e ângulo (rad) da transformação.
List<double> _ancora(Float64List m, Offset o, double d) {
  final px = (m[0] * o.dx + m[4] * o.dy + m[12]) * d;
  final py = (m[1] * o.dx + m[5] * o.dy + m[13]) * d;
  final det = (m[0] * m[5] - m[1] * m[4]).abs();
  return [px, py, d * math.sqrt(det > 0 ? det : 1), math.atan2(m[1], m[0])];
}

Widget _cena(Species sp, Mood humor, QuadroFixo q, {Activity atv = Activity.idle, Color? agua}) => SizedBox(
  width: _tamanho.width,
  height: _tamanho.height,
  child: PetView(species: sp, mood: humor, activity: atv, coat: 0, estagio: EstagioDoBicho.adulto, interativo: false, width: _tamanho.width, height: _tamanho.height, corDaAgua: agua, quadro: q),
);

void _grava(String nome, Uint8List bytes) {
  File('$_pasta/$nome.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);
}

Future<Uint8List> _png(ui.Image img) async => (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pedidas = (Platform.environment['ESPECIES'] ?? 'capybara,otter,tortoise,owl,axolotl,fox').split(',');
  final especies = Species.values.where((s) => pedidas.contains('todas') || pedidas.contains(s.name)).toList();
  final so = Platform.environment['SO'];
  bool quer(String bloco) => so == null || so == bloco;
  final saida = <String, dynamic>{};
  List<double>? ultima;

  /// Desenha, grava o PNG (se `nome` vier) e devolve pixels + âncora da boca.
  Future<(_Quadro, List<double>)> captura(WidgetTester tester, Widget w, String? nome, double d) async {
    ultima = null;
    PetView.aoDesenharBoca = (m, o, _) => ultima = _ancora(m, o, d);
    final chave = GlobalKey();
    await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: Center(child: RepaintBoundary(key: chave, child: w))));
    final b = chave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    late _Quadro q;
    await tester.runAsync(() async {
      final img = await b.toImage(pixelRatio: d);
      final raw = await img.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      q = _Quadro(raw!.buffer.asUint8List(), img.width, img.height);
      if (nome != null) _grava(nome, await _png(img));
      img.dispose();
    });
    expect(ultima, isNotNull, reason: '$nome: a boca não foi desenhada (âncora)');
    return (q, ultima!);
  }

  /// Grava uma sequência de quadros do motor como folha de vida com âncoras.
  Future<void> folha(WidgetTester tester, String nome, Species sp, Mood humor, List<SaidaDaVida> seq, {Activity atv = Activity.idle, Color? agua, AcaoDoBicho? acao, bool cicloDaAcao = false, List<double>? respiros}) async {
    final qs = <List<double>>[];
    final piscas = <int>[];
    for (var i = 0; i < seq.length; i++) {
      final s = seq[i];
      if (s.pisca > 0.15) piscas.add(i);
      final q = QuadroFixo(respiro: respiros != null ? respiros[i] : s.respiro, pisca: s.pisca, acao: acao, ciclo: cicloDaAcao ? i / seq.length : 0, vida: s);
      final (_, a) = await captura(tester, _cena(sp, humor, q, atv: atv, agua: agua), '$nome/$i', _dVida);
      qs.add(a.map((x) => double.parse(x.toStringAsFixed(2))).toList());
    }
    saida[nome] = {'d': _dVida, 'quadro': [(_tamanho.width * _dVida).round(), (_tamanho.height * _dVida).round()], 'q': qs, 'piscas': piscas};
  }

  MotorDeVida motor(Species sp) => MotorDeVida(semente: sp.index * 31 + 7)
    ..podeAndar = false
    ..energia = 0.75
    ..periodoRespiro = 2.0
    ..repertorio = const {}
    ..medianaDoPiscar = 2.2
    ..jeito = jeitoDaEspecie(sp);

  List<SaidaDaVida> lacoDe(Species sp) {
    final m = motor(sp);
    for (var i = 0; i < 90; i++) {
      m.passo(1 / 30);
    }
    final seq = [for (var i = 0; i < 360; i++) m.passo(1 / 30)];
    final (quadros, emenda, comeco) = vida.laco(seq);
    saida['laco-${sp.name}'] = {'comeco': comeco, 'emenda_sobre_media': double.parse(emenda.toStringAsFixed(2))};
    return quadros;
  }

  Future<void> salva() async {
    final arquivo = File('$_pasta/ancoras_vida.json');
    final anterior = arquivo.existsSync() ? jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic> : <String, dynamic>{};
    arquivo
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode({...anterior, ...saida}));
  }

  testWidgets('laços de vida sem boca por humor × estado, com âncoras (x2)', skip: !_ligado || !quer('vida'), (tester) async {
    for (final sp in especies) {
      final quadros = lacoDe(sp);
      for (final h in _humores.entries) {
        for (final est in _estados) {
          final seq = [for (final s in quadros) _copia(s, boca: 0, semBoca: true, susto: est == 'susto' ? 1 : 0, festa: est == 'festa' ? 1 : 0)];
          await folha(tester, 'vida-${sp.name}-${h.key}-$est', sp, h.value, seq);
          if (sp == Species.tortoise) {
            await folha(tester, 'vida-tortoise_enc-${h.key}-$est', sp, h.value, [for (final s in seq) _copia(s, pescoco: -4.2)]);
          }
        }
      }
      if (sp == Species.tortoise) {
        await folha(tester, 'vida-tortoise_dorme-sono-normal', sp, Mood.sleepy, [for (final s in quadros) _copia(s, boca: 0, semBoca: true, pescoco: -4.2)]);
      }
    }
    PetView.aoDesenharBoca = null;
    await salva();
  });

  testWidgets('poses da coruja: de lado e olhando pro céu (x2)', skip: !_ligado || !quer('poses') || !especies.contains(Species.owl), (tester) async {
    final m = motor(Species.owl);
    for (var i = 0; i < 90; i++) {
      m.passo(1 / 30);
    }
    final lado = <SaidaDaVida>[];
    for (var i = 0; i < 30; i++) {
      final s = m.passo(1 / 30);
      final k = i / 29, e = k * k * (3 - 2 * k);
      lado.add(SaidaDaVida(respiro: s.respiro, olhar: Offset(1.3 * e, -0.1 * e), virada: Offset(1.0 * e, 0), cabecaGiro: 0.5 * e, semBoca: true));
    }
    await folha(tester, 'lado-owl', Species.owl, Mood.content, lado);
    final cima = <SaidaDaVida>[];
    for (var i = 0; i < 24; i++) {
      final k = i / 23, e = k * k * (3 - 2 * k);
      cima.add(SaidaDaVida(olhar: Offset(1.0 * e, -1.0 * e), susto: 0.35 * e, semBoca: true));
    }
    await folha(tester, 'cima-owl', Species.owl, Mood.content, cima);
    PetView.aoDesenharBoca = null;
    await salva();
  });

  testWidgets('ciclos anda/corre/nada/voa sem boca, com âncoras (x2)', skip: !_ligado || !quer('ciclos'), (tester) async {
    for (final sp in especies) {
      for (final correndo in [false, true]) {
        final seq = [for (var i = 0; i < anim.n; i++) _copia(anim.passoNa(i / anim.n, especie: sp, correndo: correndo), semBoca: true)];
        await folha(tester, '${correndo ? 'corre' : 'anda'}-${sp.name}', sp, Mood.content, seq, acao: AcaoDoBicho.ocioso);
      }
      if (_nadam.contains(sp)) {
        final seq = [
          for (var i = 0; i < anim.n; i++)
            SaidaDaVida(atividadeAtiva: true, corpoLivre: false, cicloDaAtividade: i / anim.n, forcaDaAtividade: 1, boia: -math.cos(i / anim.n * 2 * math.pi), inclina: -0.13, cabecaAtraso: const Offset(-5, 0), virado: true, olhar: const Offset(-0.6, 0), virada: const Offset(-0.5, 0), semBoca: true),
        ];
        await folha(tester, 'nada-${sp.name}', sp, Mood.content, seq, atv: Activity.swim, agua: const Color(0xFF7FC0D6), acao: AcaoDoBicho.nado, cicloDaAcao: true);
      }
      if (sp == Species.cat || sp == Species.fox) {
        // O salto (agacha, voa, pousa): a brincadeira do app, que o motor usa como pose de 'salta'.
        final seq = [for (var i = 0; i < anim.n; i++) _copia(anim.brincaNa(i / anim.n), semBoca: true)];
        await folha(tester, 'brinca-${sp.name}', sp, Mood.content, seq, acao: AcaoDoBicho.brincadeira, cicloDaAcao: true);
      }
      if (sp == Species.owl) {
        final seq = [
          for (var i = 0; i < anim.n; i++)
            SaidaDaVida(voando: true, atividadeAtiva: true, corpoLivre: false, cicloDaAtividade: i / anim.n, forcaDaAtividade: 1, altura: 30, desloca: Offset(0, -math.sin(i / anim.n * 2 * math.pi) * 4.5), semBoca: true),
        ];
        await folha(tester, 'voa-owl', Species.owl, Mood.content, seq, atv: Activity.swim, acao: AcaoDoBicho.voo, cicloDaAcao: true);
      }
    }
    PetView.aoDesenharBoca = null;
    await salva();
  });

  testWidgets('bocas dos 7 visemas por humor, susto e festa (x3, fundo transparente)', skip: !_ligado || !quer('bocas'), (tester) async {
    const humoresBoca = {...(_humores), 'susto': Mood.content, 'festa': Mood.radiant};
    for (final sp in especies) {
      for (final h in humoresBoca.entries) {
        final susto = h.key == 'susto' ? 1.0 : 0.0, festa = h.key == 'festa' ? 1.0 : 0.0;
        // O corpo sem boca, em repouso (abertura 0): a base sobre a qual o
        // motor compõe. A camada de cada visema é a diferença para ele, e por
        // isso carrega o queixo que desce com a boca aberta.
        final (corpo, ac) = await captura(tester, _cena(sp, h.value, QuadroFixo(vida: SaidaDaVida(semBoca: true, susto: susto, festa: festa))), null, _dBoca);
        final vs = <String, dynamic>{};
        for (final v in Visema.values) {
          final (com, a) = await captura(tester, _cena(sp, h.value, QuadroFixo.visema(v, susto: susto, festa: festa)), null, _dBoca);
          final w = com.largura, hh = com.altura;
          var x0 = w, y0 = hh, x1 = -1, y1 = -1;
          final camada = Uint8List(com.pixels.length);
          for (var y = 0; y < hh; y++) {
            for (var x = 0; x < w; x++) {
              final i = (y * w + x) * 4;
              if (com.pixels[i] == corpo.pixels[i] && com.pixels[i + 1] == corpo.pixels[i + 1] && com.pixels[i + 2] == corpo.pixels[i + 2] && com.pixels[i + 3] == corpo.pixels[i + 3]) continue;
              camada.setRange(i, i + 4, com.pixels, i);
              if (x < x0) x0 = x;
              if (x > x1) x1 = x;
              if (y < y0) y0 = y;
              if (y > y1) y1 = y;
            }
          }
          if (x1 < 0) {
            x0 = a[0].round() - 1;
            x1 = x0 + 1;
            y0 = a[1].round() - 1;
            y1 = y0 + 1;
          }
          final rx0 = (x0 - 2).clamp(0, w - 1), ry0 = (y0 - 2).clamp(0, hh - 1), rx1 = (x1 + 3).clamp(rx0 + 1, w), ry1 = (y1 + 3).clamp(ry0 + 1, hh);
          final rw = rx1 - rx0, rh = ry1 - ry0;
          final recorte = Uint8List(rw * rh * 4);
          for (var y = 0; y < rh; y++) {
            recorte.setRange(y * rw * 4, (y + 1) * rw * 4, camada, ((ry0 + y) * w + rx0) * 4);
          }
          await tester.runAsync(() async {
            final feito = Completer<ui.Image>();
            ui.decodeImageFromPixels(recorte, rw, rh, ui.PixelFormat.rgba8888, feito.complete);
            final img = await feito.future;
            _grava('boca-${sp.name}-${h.key}/${v.name}', await _png(img));
            img.dispose();
          });
          vs[v.name] = {'p': [a[0], a[1]], 'escala': a[2], 'ang': a[3], 'recorte': [rx0, ry0, rx1, ry1]};
        }
        saida['boca-${sp.name}-${h.key}'] = {'d': _dBoca, 'quadro': [corpo.largura, corpo.altura], 'corpo': {'p': [ac[0], ac[1]], 'escala': ac[2], 'ang': ac[3]}, 'v': vs};
      }
    }
    PetView.aoDesenharBoca = null;
    await salva();
  });
}
