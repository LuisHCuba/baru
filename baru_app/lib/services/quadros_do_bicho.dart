/// Os quadros do bicho real para a sobreposição do Android.
///
/// **Por que existe.** A sobreposição aparece quando a pessoa está noutro app
/// — e ali o Flutter não desenha. Até aqui o Kotlin desenhava um bicho
/// genérico de ovais, com orelha de mamífero até no pinguim: não era o bicho
/// da pessoa, era "um bicho". O laudo 05 (§5) comparou três caminhos e
/// escolheu este: o Dart rasteriza o `PetView` de verdade em alguns quadros
/// (respiração e piscada), grava em PNG, e o Kotlin só anima a troca entre
/// eles. Uma fonte de desenho só; nada de portar o painter, nada de segunda
/// engine Flutter rodando em segundo plano.
///
/// **Quando desenha.** Ao sair do app, como o widget da tela inicial: com as
/// animações da tela já paradas, e logo antes de a sobreposição poder
/// aparecer. E só quando a aparência muda — espécie, pelagem, roupa — ou na
/// primeira saída de cada processo, que é como uma atualização do app com
/// desenho novo chega à sobreposição sem número de versão para lembrar.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../data/crescimento.dart';
import '../models.dart';
import '../widgets/pet.dart';

/// O que muda o desenho do bicho na sobreposição.
///
/// O humor fica de fora de propósito: a sobreposição chama a pessoa de volta,
/// e quem chama não faz cara de bravo nem de triste. É sempre o bicho
/// contente (ver o PRODUCT.md, "sem culpa").
@immutable
class AparenciaDoBicho {
  const AparenciaDoBicho({
    required this.especie,
    required this.pelagem,
    this.roupas = const {},
    this.roupaDeCabeca,
    this.estagio = EstagioDoBicho.adulto,
  });

  final Species especie;
  final int pelagem;
  final Map<Vestimenta, Color> roupas;
  final String? roupaDeCabeca;

  /// O bicho cresce, e a sobreposição cresce junto: estágio novo, quadros
  /// novos.
  final EstagioDoBicho estagio;

  /// A identidade do desenho. Igual, os quadros gravados continuam servindo.
  String get chave {
    final pecas = roupas.entries.toList()
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
    final vestido = [
      for (final p in pecas) '${p.key.name}:${p.value.toARGB32()}',
    ].join(',');
    return '${especie.name}|${estagio.name}|$pelagem|'
        '${roupaDeCabeca ?? '-'}|$vestido';
  }

  @override
  bool operator ==(Object other) =>
      other is AparenciaDoBicho && other.chave == chave;

  @override
  int get hashCode => chave.hashCode;
}

class QuadrosDoBicho {
  QuadrosDoBicho._();

  static final QuadrosDoBicho instance = QuadrosDoBicho._();

  /// Quadros da respiração, do peito vazio ao cheio.
  ///
  /// Seis bastam: o Kotlin funde dois vizinhos pela fase, então a subida
  /// sai contínua e não em degraus. Mais quadros seriam memória sem ganho.
  static const quadrosDeRespiro = 6;

  /// O tamanho lógico de cada quadro. Do mesmo feitio do habitat da home.
  static const tamanho = Size(200, 170);

  /// Densidade do PNG. 2× dá ~400×340 px, o tamanho que o bicho ocupa na
  /// sobreposição num aparelho de 3×; quatro bytes por pixel e sete quadros
  /// ficam em menos de 4 MB, e o Kotlin ainda reduz se o aparelho for menor.
  static const densidade = 2.0;

  /// Os valores do peito em cada quadro, de -1 a 1 em passos iguais.
  static List<double> get respiros => [
        for (var i = 0; i < quadrosDeRespiro; i++)
          -1 + 2 * i / (quadrosDeRespiro - 1),
      ];

  static const _canal = MethodChannel('baru/overlay');

  @visibleForTesting
  MethodChannel canal = _canal;

  @visibleForTesting
  Future<String> Function(Widget w, String chave, Size tamanho)? rasteriza;

  /// Quantas vezes desenhou de fato. Para os testes contarem o cache.
  @visibleForTesting
  int desenhos = 0;

  String? _ultimaChave;
  Future<void>? _emCurso;

  @visibleForTesting
  void zeraParaTeste() {
    _ultimaChave = null;
    _emCurso = null;
    desenhos = 0;
  }

  /// O bicho de cada quadro. Público para os testes compararem com a home.
  static Widget cena(AparenciaDoBicho a, QuadroFixo quadro) => SizedBox(
        width: tamanho.width,
        height: tamanho.height,
        child: PetView(
          species: a.especie,
          mood: Mood.content,
          activity: Activity.idle,
          coat: a.pelagem,
          roupas: a.roupas,
          roupaDeCabeca: a.roupaDeCabeca,
          estagio: a.estagio,
          interativo: false,
          width: tamanho.width,
          height: tamanho.height,
          quadro: quadro,
        ),
      );

  /// Garante que os quadros gravados são os desta aparência.
  ///
  /// Nunca lança: sem quadros, a sobreposição usa o desenho de reserva, e
  /// isso é bem melhor do que um erro derrubando a saída do app.
  Future<void> atualiza(AparenciaDoBicho a) {
    if (!_ehAndroid && rasteriza == null) return Future.value();
    if (a.chave == _ultimaChave) return Future.value();
    // Uma de cada vez: sair e voltar rápido não pode pôr duas levas
    // escrevendo nos mesmos arquivos.
    final anterior = _emCurso ?? Future<void>.value();
    final esta = anterior.then((_) => _desenha(a));
    _emCurso = esta;
    return esta;
  }

  Future<void> _desenha(AparenciaDoBicho a) async {
    if (a.chave == _ultimaChave) return;
    try {
      // O Android já tem estes quadros (e da mesma versão do app)? Então
      // não há o que desenhar. Sem esta pergunta, a primeira saída de cada
      // processo redesenhava sempre — justo na hora em que a sobreposição
      // pode aparecer.
      final atual = await canal.invokeMethod<String>('quadrosChave');
      if (atual == a.chave) {
        _ultimaChave = a.chave;
        return;
      }
      final desenha = rasteriza ?? _rasterizaDeVerdade;
      // Nomes por aparência: os arquivos novos nunca sobrescrevem os que a
      // sobreposição pode estar lendo (auditoria da Onda 2, 5.1). O Android
      // troca para eles só depois de existirem, e apaga os velhos.
      // O instante entra no nome para nem o redesenho da mesma aparência
      // (depois de uma atualização do app) tocar nos arquivos em uso.
      final prefixo = 'baru_bicho_'
          '${impressao('${a.chave}|${DateTime.now().microsecondsSinceEpoch}')}';
      final respiro = <String>[];
      final valores = respiros;
      for (var i = 0; i < valores.length; i++) {
        respiro.add(await desenha(
          cena(a, QuadroFixo(respiro: valores[i])),
          '${prefixo}_$i',
          tamanho,
        ));
      }
      // A piscada no meio do fôlego: o Kotlin a mostra por um instante só,
      // e no meio a diferença para qualquer quadro vizinho é invisível.
      final piscar = await desenha(
        cena(a, const QuadroFixo(pisca: 1)),
        '${prefixo}_pisca',
        tamanho,
      );
      desenhos++;
      final ok = await canal.invokeMethod<bool>('quadros', {
        'chave': a.chave,
        'respiro': respiro,
        'piscar': piscar,
      });
      if (ok ?? false) _ultimaChave = a.chave;
    } catch (e) {
      debugPrint('Baru: quadros da sobreposição falharam ($e)');
    }
  }

  Future<String> _rasterizaDeVerdade(Widget w, String chave, Size t) =>
      HomeWidget.renderFlutterWidget(
        w,
        key: chave,
        logicalSize: t,
        pixelRatio: densidade,
      );

  /// FNV-1a de 32 bits, em hexadecimal: um nome curto e estável para os
  /// arquivos de cada aparência. `String.hashCode` não promete ser o mesmo
  /// entre execuções. Também dá nome às cenas dos recados animados.
  static String impressao(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  bool get _ehAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
