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
/// o bicho muda. Por isso [atualiza] compara antes de gravar — rasterizar e
/// escrever em disco a cada `notifyListeners` seria custo por nada.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../data/crescimento.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/pet.dart';

/// Os momentos do widget ao longo do dia (pesquisa 26).
///
/// O widget do Duolingo é "uma série de ilustrações que mostra o humor do
/// Duo em diferentes partes do dia", e troca sozinho, sem o app abrir. O do
/// Baru faz o mesmo com o tom invertido do laudo 01 (U9): o bicho acorda,
/// espera e se aconchega — nunca fica triste nem desesperado.
///
/// A escolha acontece no Kotlin, com o app fechado; [momentoDoWidget] é a
/// mesma regra em Dart, para o teste e para quem lê. As duas têm de bater.
enum MomentoDoWidget {
  /// A raiz já cresceu hoje.
  feito(Mood.radiant, Activity.idle),
  manha(Mood.content, Activity.idle),
  tarde(Mood.neutral, Activity.idle),
  noite(Mood.sleepy, Activity.idle),
  madrugada(Mood.sleepy, Activity.nap);

  const MomentoDoWidget(this.humor, this.atividade);

  final Mood humor;
  final Activity atividade;
}

/// Que momento o widget mostra agora.
///
/// Dia feito vale até a meia-noite; depois dela é outro dia, e o bicho
/// dorme até as 5h. Manhã até 12h, tarde até 18h, noite até 23h.
MomentoDoWidget momentoDoWidget(DateTime? presenteEm, DateTime agora) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  if (presenteEm != null &&
      DateTime(presenteEm.year, presenteEm.month, presenteEm.day) == hoje) {
    return MomentoDoWidget.feito;
  }
  final h = agora.hour;
  if (h < 5 || h >= 23) return MomentoDoWidget.madrugada;
  if (h < 12) return MomentoDoWidget.manha;
  if (h < 18) return MomentoDoWidget.tarde;
  return MomentoDoWidget.noite;
}

/// `2026-10-29`: o formato que o Kotlin compara com `LocalDate.now()`.
String diaIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// O que o widget mostra. Tudo o que muda a imagem ou o texto entra aqui.
@immutable
class EstadoDoWidget {
  const EstadoDoWidget({
    required this.especie,
    required this.pelagem,
    required this.nome,
    required this.raiz,
    required this.usoDoDia,
    required this.meta,
    this.presenteEm,
    this.frases = const {},
    this.estagio = EstagioDoBicho.adulto,
  });

  final Species especie;
  final int pelagem;
  final String nome;
  final int raiz;
  final int usoDoDia;
  final int meta;

  /// O último dia em que a raiz cresceu. É o que decide, no aparelho e sem
  /// o app, entre o bicho feliz e o bicho esperando.
  final DateTime? presenteEm;

  /// Uma frase por momento, já traduzida.
  final Map<MomentoDoWidget, String> frases;
  final EstagioDoBicho estagio;

  /// Só o que exige redesenhar o bicho (os cinco momentos de uma vez).
  String get chaveDaImagem => '${especie.name}-$pelagem-${estagio.name}';

  @override
  bool operator ==(Object other) =>
      other is EstadoDoWidget &&
      other.especie == especie &&
      other.pelagem == pelagem &&
      other.nome == nome &&
      other.raiz == raiz &&
      other.usoDoDia == usoDoDia &&
      other.meta == meta &&
      other.estagio == estagio &&
      other.presenteEm == presenteEm &&
      mapEquals(other.frases, frases);

  @override
  int get hashCode => Object.hash(
    especie,
    pelagem,
    nome,
    raiz,
    usoDoDia,
    meta,
    estagio,
    presenteEm,
    Object.hashAll(frases.values),
  );
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
      final grava = gravaDado ?? _gravaDeVerdade;
      if (precisaDesenhar) {
        // Os cinco momentos de uma vez: o widget troca de momento com o app
        // fechado, e `renderFlutterWidget` só roda com o app de pé.
        for (final m in MomentoDoWidget.values) {
          desenhos++;
          final caminho = await (rasteriza ?? _rasterizaDeVerdade)(
            _CenaDoWidget(estado: e, momento: m),
            'baru_pet_${m.name}',
            tamanhoDoPng,
          );
          await grava('baru_png_${m.name}', caminho);
        }
        // O rosto para o ícone grande das notificações: quadrado, o bicho
        // de perto — num círculo de 40 dp, a cena inteira vira um borrão.
        desenhos++;
        final rosto = await (rasteriza ?? _rasterizaDeVerdade)(
          _RostoDoBicho(estado: e),
          'baru_rosto',
          tamanhoDoRosto,
        );
        await grava('baru_rosto_png', rosto);
      }
      await grava('baru_nome', e.nome);
      await grava('baru_raiz', e.raiz);
      await grava('baru_uso', e.usoDoDia);
      await grava('baru_meta', e.meta);
      await grava(
        'baru_presente_em',
        e.presenteEm == null ? '' : diaIso(e.presenteEm!),
      );
      for (final m in MomentoDoWidget.values) {
        await grava('baru_frase_${m.name}', e.frases[m] ?? '');
      }
      await (avisaOProvider ?? _avisaDeVerdade)();
    } catch (_) {
      // Sem widget na tela, sem plataforma, aparelho exótico: nada disso
      // pode derrubar o app. O widget é enfeite; a sessão não é.
    }
  }

  /// O tamanho do PNG do bicho, em pixels de verdade.
  ///
  /// **Isto é um teto, não uma preferência.** O `RemoteViews` viaja para o
  /// processo do launcher por Binder, e a transação tem limite prático de
  /// ~1 MB. `setImageViewBitmap` serializa o bitmap **descomprimido**: a
  /// 4 bytes por pixel, 250 mil pixels já encostam no teto.
  ///
  /// A primeira versão pedia 320×280 **lógicos** e deixava o `pixelRatio`
  /// no padrão, que num aparelho 3× vira 960×840 = 3,2 MB. O launcher
  /// descartava a imagem em silêncio e sobrava o quadrado vazio — foi o
  /// relato: "tá com um quadrado dentro dele".
  ///
  /// 360×312 dá 112 mil pixels, ~450 KB: folga confortável, e ainda maior
  /// que qualquer widget 4×2 numa tela comum.
  static const tamanhoDoPng = Size(360, 312);

  /// O rosto das notificações. 192 px é o tamanho de ícone grande que o
  /// Android usa em telas xxxhdpi (48 dp × 4).
  static const tamanhoDoRosto = Size(192, 192);

  /// Onde está o rosto do bicho, se já foi desenhado.
  ///
  /// Só existe depois da primeira ida do app ao segundo plano (é quando o
  /// widget rasteriza). Até lá a notificação sai sem ele.
  Future<String?> caminhoDoRosto() async {
    if (!_armado || kIsWeb) return null;
    try {
      final c = await HomeWidget.getWidgetData<String>('baru_rosto_png');
      if (c == null || c.isEmpty || !File(c).existsSync()) return null;
      return c;
    } catch (_) {
      return null;
    }
  }

  /// `pixelRatio: 1` porque [tamanhoDoPng] já está em pixels finais. Deixar
  /// o padrão multiplicaria pela densidade da tela e devolveria o problema.
  Future<String> _rasterizaDeVerdade(Widget w, String chave, Size t) =>
      HomeWidget.renderFlutterWidget(
        w,
        key: chave,
        logicalSize: t,
        pixelRatio: 1,
      );

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
  const _CenaDoWidget({required this.estado, required this.momento});

  final EstadoDoWidget estado;
  final MomentoDoWidget momento;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Cores.habitat,
      alignment: Alignment.center,
      child: PetView(
        species: estado.especie,
        mood: momento.humor,
        activity: momento.atividade,
        coat: estado.pelagem,
        estagio: estado.estagio,
        interativo: false,
        width: 300,
        height: 260,
        scale: 1.25,
      ),
    );
  }
}

/// O rosto do bicho para a notificação: de perto, contente, fundo opaco.
class _RostoDoBicho extends StatelessWidget {
  const _RostoDoBicho({required this.estado});

  final EstadoDoWidget estado;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Cores.habitat,
      child: OverflowBox(
        // O bicho é maior que o quadro: o rosto fica, o corpo sai por baixo.
        alignment: const Alignment(0, -0.2),
        maxWidth: 260,
        maxHeight: 260,
        child: PetView(
          species: estado.especie,
          mood: Mood.content,
          activity: Activity.idle,
          coat: estado.pelagem,
          estagio: estado.estagio,
          interativo: false,
          width: 220,
          height: 220,
          scale: 1.5,
        ),
      ),
    );
  }
}
