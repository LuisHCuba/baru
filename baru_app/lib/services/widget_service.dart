/// O Baru na tela inicial do aparelho.
///
/// **Por que existe uma camada aqui.** Um widget do Android é `RemoteViews`,
/// que sabe desenhar `TextView`, `ImageView` e pouco mais. Ele **não**
/// executa `CustomPainter` — o bicho do widget não pode ser o mesmo objeto
/// que o bicho da tela. O que dá para fazer é rasterizar o painter num PNG,
/// gravar em disco e apontar o `ImageView` para o arquivo.
///
/// É o mesmo caminho do gerador de ícone, com uma diferença que muda tudo:
/// ali roda uma vez, em tempo de teste; aqui roda no aparelho, toda vez que
/// o humor muda. Por isso [atualiza] compara antes de gravar — rasterizar e
/// escrever em disco a cada `notifyListeners` seria custo por nada.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../models.dart';
import '../theme.dart';
import '../widgets/pet.dart';

/// O que o widget mostra. Tudo o que muda a imagem ou o texto entra aqui.
@immutable
class EstadoDoWidget {
  const EstadoDoWidget({
    required this.especie,
    required this.humor,
    required this.pelagem,
    required this.nome,
    required this.raiz,
    required this.usoDoDia,
    required this.meta,
  });

  final Species especie;
  final Mood humor;
  final int pelagem;
  final String nome;
  final int raiz;
  final int usoDoDia;
  final int meta;

  /// Só o que exige redesenhar o bicho.
  String get chaveDaImagem => '${especie.name}-${humor.name}-$pelagem';

  @override
  bool operator ==(Object other) =>
      other is EstadoDoWidget &&
      other.especie == especie &&
      other.humor == humor &&
      other.pelagem == pelagem &&
      other.nome == nome &&
      other.raiz == raiz &&
      other.usoDoDia == usoDoDia &&
      other.meta == meta;

  @override
  int get hashCode =>
      Object.hash(especie, humor, pelagem, nome, raiz, usoDoDia, meta);
}

class WidgetService {
  WidgetService._();

  static final WidgetService instance = WidgetService._();

  /// Tem de bater com o nome da classe Kotlin do provider.
  static const provider = 'BaruWidget';

  /// Mesmo padrão do som e do vigia: `MethodChannel` exige binding, e o
  /// domínio é testado sem nenhum.
  bool _armado = false;
  void arma() => _armado = true;

  EstadoDoWidget? _ultimo;

  @visibleForTesting
  void zeraParaTeste() {
    _adiado?.cancel();
    _adiado = null;
    _pendente = null;
    _ultimo = null;
    _armado = true;
    espera = Duration.zero;
  }

  /// Quantas vezes o bicho foi rasterizado — para o teste provar que não se
  /// redesenha à toa.
  @visibleForTesting
  int desenhos = 0;

  /// Injetáveis para o teste: sem eles, nada aqui é exercitável sem um
  /// aparelho com widget instalado.
  @visibleForTesting
  Future<void> Function(String chave, Object valor)? gravaDado;
  @visibleForTesting
  Future<String> Function(Widget w, String chave, Size tamanho)? rasteriza;
  @visibleForTesting
  Future<void> Function()? avisaOProvider;

  /// Quanto se espera antes de mexer no widget.
  ///
  /// **Não é otimização, é correção.** Rasterizar monta um `RenderView`
  /// próprio e roda um quadro; feito de dentro do `notifyListeners`, isso
  /// acontecia **no meio das animações da tela** e derrubava o relógio dos
  /// `AnimationController` com `elapsedInSeconds >= 0.0 is not true`. O
  /// estado notifica muitas vezes por segundo durante uma sessão; o widget
  /// só precisa do último valor, e em repouso.
  @visibleForTesting
  Duration espera = const Duration(seconds: 1);

  Timer? _adiado;
  EstadoDoWidget? _pendente;

  /// Manda o estado para o widget. Não faz nada se nada mudou.
  void atualiza(EstadoDoWidget e) {
    if (!_armado || kIsWeb) return;
    if (e == _ultimo) return;
    _pendente = e;
    _adiado?.cancel();
    if (espera == Duration.zero) {
      unawaited(_manda());
      return;
    }
    _adiado = Timer(espera, () => unawaited(_manda()));
  }

  /// Cancela o que estiver esperando.
  ///
  /// Chamado no `dispose` do app. Um `Timer` sobrevivente segura o
  /// desligamento — e em teste vira `!timersPending`, que é o mesmo defeito
  /// visto de outro ângulo.
  void cancela() {
    _adiado?.cancel();
    _adiado = null;
    _pendente = null;
  }

  /// Solta o que estiver pendente agora. Só para o teste.
  @visibleForTesting
  Future<void> descarrega() async {
    _adiado?.cancel();
    await _manda();
  }

  Future<void> _manda() async {
    final e = _pendente;
    if (e == null || e == _ultimo) return;
    final precisaDesenhar = _ultimo?.chaveDaImagem != e.chaveDaImagem;
    _ultimo = e;

    try {
      if (precisaDesenhar) {
        desenhos++;
        // O PNG é grande de propósito: o widget pode ser esticado, e
        // `ImageView` amplia imagem pequena até borrar.
        final caminho = await (rasteriza ?? _rasterizaDeVerdade)(
          _CenaDoWidget(estado: e),
          'baru_pet',
          const Size(320, 280),
        );
        await (gravaDado ?? _gravaDeVerdade)('baru_pet_png', caminho);
      }
      final grava = gravaDado ?? _gravaDeVerdade;
      await grava('baru_nome', e.nome);
      await grava('baru_raiz', e.raiz);
      await grava('baru_uso', e.usoDoDia);
      await grava('baru_meta', e.meta);
      await (avisaOProvider ?? _avisaDeVerdade)();
    } catch (_) {
      // Sem widget na tela, sem plataforma, aparelho exótico: nada disso
      // pode derrubar o app. O widget é enfeite; a sessão não é.
    }
  }

  Future<String> _rasterizaDeVerdade(Widget w, String chave, Size t) =>
      HomeWidget.renderFlutterWidget(w, key: chave, logicalSize: t);

  Future<void> _gravaDeVerdade(String chave, Object valor) =>
      HomeWidget.saveWidgetData<Object>(chave, valor);

  Future<void> _avisaDeVerdade() =>
      HomeWidget.updateWidget(androidName: provider);
}

/// O que vira PNG.
///
/// Fundo opaco: `RemoteViews` desenha o `ImageView` sobre o papel de parede
/// da pessoa, e um bicho com transparência some num fundo claro.
class _CenaDoWidget extends StatelessWidget {
  const _CenaDoWidget({required this.estado});

  final EstadoDoWidget estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Cores.habitat,
      alignment: Alignment.center,
      child: PetView(
        species: estado.especie,
        mood: estado.humor,
        activity: Activity.idle,
        coat: estado.pelagem,
        interativo: false,
        width: 300,
        height: 260,
        scale: 1.25,
      ),
    );
  }
}
