import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models.dart';

/// As poses ilustradas de um bicho.
///
/// O desenho por formas geométricas no código chegou ao teto: cada pose
/// nova (em pé, deitado) deformava o bicho ou o deixava com cara de boneco
/// de papel. A arte agora é ilustração — uma folha de poses do mesmo
/// personagem, vetorizada para ficar nítida, sem fundo — e o código só faz
/// o que faz bem: escolher a pose do momento, passar de uma a outra sem
/// salto, piscar, respirar e levar o bicho pelo cenário. É o princípio da
/// coruja voando: corpo inteiro, partes que se movem.
class PoseIlustrada {
  const PoseIlustrada(
    this.arquivo, {
    required this.tamanho,
    this.olhos = const [],
    this.olho = const Size(37, 54),
    this.olhaParaEsquerda = false,
    this.cabeca,
    this.larguraDaCabeca = 0,
  });

  final String arquivo;

  /// O tamanho da imagem, em pixels. Todas as poses de um bicho estão na
  /// mesma escala: o que muda de uma para outra é só o desenho.
  final Size tamanho;

  /// O centro de cada olho aberto, em pixels da imagem, para piscar.
  final List<Offset> olhos;
  final Size olho;

  /// A pose olha para a esquerda (andando, comendo de lado). O código anda
  /// com o bicho olhando para +x, então estas são espelhadas.
  final bool olhaParaEsquerda;

  /// O centro e a largura da cabeça, em pixels, para vestir os acessórios.
  final Offset? cabeca;
  final double larguraDaCabeca;
}

/// As poses de cada bicho que já tem ilustração.
enum NomeDaPose { sentada, andar1, andar2, deitada, dormindo, comendo }

class Ilustracoes {
  Ilustracoes._();

  /// Unidades do desenho por pixel da imagem: a capivara sentada fica com
  /// 132 unidades de altura, a mesma do desenho antigo.
  static const unidadesPorPixel = 132 / 671;

  static const _capivara = {
    NomeDaPose.sentada: PoseIlustrada(
      'assets/bichos/capivara/sentada.png',
      tamanho: Size(463, 671),
      olhos: [Offset(136, 127), Offset(328, 128)],
      cabeca: Offset(231, 150),
      larguraDaCabeca: 290,
    ),
    NomeDaPose.andar1: PoseIlustrada(
      'assets/bichos/capivara/andar1.png',
      tamanho: Size(792, 665),
      olhos: [Offset(236, 132)],
      olho: Size(47, 47),
      olhaParaEsquerda: true,
      cabeca: Offset(200, 160),
      larguraDaCabeca: 260,
    ),
    NomeDaPose.andar2: PoseIlustrada(
      'assets/bichos/capivara/andar2.png',
      tamanho: Size(823, 663),
      olhos: [Offset(236, 134)],
      olho: Size(47, 50),
      olhaParaEsquerda: true,
      cabeca: Offset(200, 160),
      larguraDaCabeca: 260,
    ),
    NomeDaPose.deitada: PoseIlustrada(
      'assets/bichos/capivara/deitada.png',
      tamanho: Size(814, 621),
      olhos: [Offset(448, 130), Offset(650, 130)],
      olho: Size(40, 55),
      cabeca: Offset(549, 155),
      larguraDaCabeca: 300,
    ),
    NomeDaPose.dormindo: PoseIlustrada(
      'assets/bichos/capivara/dormindo.png',
      tamanho: Size(788, 454),
      cabeca: Offset(680, 280),
      larguraDaCabeca: 210,
    ),
    NomeDaPose.comendo: PoseIlustrada(
      'assets/bichos/capivara/comendo.png',
      tamanho: Size(578, 672),
      olhaParaEsquerda: true,
      cabeca: Offset(175, 150),
      larguraDaCabeca: 280,
    ),
  };

  /// As poses do bicho, ou nulo se ele ainda é desenhado no código.
  static Map<NomeDaPose, PoseIlustrada>? poses(Species s) => switch (s) {
    Species.capybara => _capivara,
    _ => null,
  };

  static final _imagens = <Species, Map<NomeDaPose, ui.Image>>{};
  static final _carregando = <Species, Future<void>>{};

  /// As imagens já decodificadas, ou nulo para quem não tem ilustração (e
  /// enquanto não carregaram). O `main` carrega todas antes do primeiro
  /// quadro; sem elas o bicho segue desenhado no código.
  static Map<NomeDaPose, ui.Image>? imagens(Species s) => _imagens[s];

  /// Carrega as poses uma vez por processo.
  static Future<void> carrega(Species s) {
    final poses = Ilustracoes.poses(s);
    if (poses == null) return Future.value();
    return _carregando.putIfAbsent(s, () async {
      final prontas = <NomeDaPose, ui.Image>{};
      for (final e in poses.entries) {
        final dados = await rootBundle.load(e.value.arquivo);
        final codec = await ui.instantiateImageCodec(
          dados.buffer.asUint8List(),
        );
        prontas[e.key] = (await codec.getNextFrame()).image;
      }
      _imagens[s] = prontas;
    });
  }

  /// Só para teste: esquece o que carregou.
  @visibleForTesting
  static void limpa() {
    _imagens.clear();
    _carregando.clear();
  }
}
