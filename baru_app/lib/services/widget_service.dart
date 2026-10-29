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
import 'dart:math' show Random;

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
  /// A raiz já cresceu hoje: dourado de festa.
  feito(Mood.radiant, Activity.idle, Color(0xFFFFB627), Color(0xFFF07C1B)),

  /// Céu de manhã.
  manha(Mood.content, Activity.idle, Color(0xFF4FB6E3), Color(0xFF2A7FBF)),

  /// Folha de tarde.
  tarde(Mood.neutral, Activity.idle, Color(0xFF63B05E), Color(0xFF2F6F3E)),

  /// Anoitecer: roxo.
  noite(Mood.sleepy, Activity.idle, Color(0xFF8A5BE0), Color(0xFF4A2C96)),

  /// Noite funda, com lua e estrelas.
  madrugada(Mood.sleepy, Activity.nap, Color(0xFF2C3A75), Color(0xFF111735));

  const MomentoDoWidget(this.humor, this.atividade, this.cimo, this.fundo);

  final Mood humor;
  final Activity atividade;

  /// O degradê da cena, de cima para baixo. Cores fortes de propósito: no
  /// widget do Duolingo a cor é o estado — reconhece-se de longe.
  final Color cimo;
  final Color fundo;
}

/// Os dois formatos do widget.
///
/// Uma imagem por formato, e não uma só esticada: a cena do 2×2 é quadrada
/// e a do 4×2 deixa a esquerda livre para o número e a semana. Os dois
/// tamanhos ficam abaixo de 200 mil pixels — o teto do Binder (ver
/// [WidgetService.tamanhoDoPng]).
enum FormatoDoWidget {
  quadrado(Size(336, 336), 'q'),
  largo(Size(600, 280), 'l');

  const FormatoDoWidget(this.tamanho, this.sufixo);

  final Size tamanho;
  final String sufixo;
}

/// A semana do widget no dia [hoje], a partir da gravada em [escritaEm].
///
/// O app grava os 7 dias (do mais antigo até o dia da gravação) como letras:
/// `p` presente, `f` congelado, `t` o dia em curso, `e` vazio. Com o app
/// fechado os dias andam: a semana desliza, o dia em curso que passou sem
/// presença vira vazio, e hoje é `p` se a raiz já cresceu. Espelho exato de
/// `BaruWidget.semanaNoDia` (Kotlin).
String semanaNoDia(
  String codigos,
  DateTime escritaEm,
  DateTime? presenteEm,
  DateTime hoje,
) {
  DateTime dia(DateTime d) => DateTime(d.year, d.month, d.day);
  final h = dia(hoje);
  final desloca = h.difference(dia(escritaEm)).inDays.clamp(0, 7);
  final out = StringBuffer();
  for (var i = 0; i < 7; i++) {
    final data = h.subtract(Duration(days: 6 - i));
    if (presenteEm != null && dia(presenteEm) == data) {
      out.write('p');
      continue;
    }
    if (i == 6) {
      out.write('t');
      continue;
    }
    final j = i + desloca;
    final c = j < codigos.length ? codigos[j] : 'e';
    out.write(c == 't' ? 'e' : c);
  }
  return out.toString();
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
    this.semana = 'eeeeeet',
    this.letras = const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'],
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

  /// Os 7 dias até hoje, do mais antigo, nas letras de [semanaNoDia].
  final String semana;

  /// As iniciais dos dias, de segunda a domingo, no idioma da pessoa.
  final List<String> letras;
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
      other.semana == semana &&
      listEquals(other.letras, letras) &&
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
          for (final f in FormatoDoWidget.values) {
            desenhos++;
            final chave = 'baru_png_${m.name}_${f.sufixo}';
            final caminho = await (rasteriza ?? _rasterizaDeVerdade)(
              _CenaDoWidget(estado: e, momento: m, formato: f),
              chave,
              f.tamanho,
            );
            await grava(chave, caminho);
          }
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
      await grava('baru_semana', e.semana);
      await grava('baru_semana_em', diaIso(DateTime.now()));
      await grava('baru_letras', e.letras.join());
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

  /// A cor de fundo do widget, igual à de `baru_widget_fundo.xml`.
  static const fundoDoWidget = Color(0xFFF6EFE2);

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

/// O que vira PNG: a cena inteira do widget, de ponta a ponta.
///
/// Como o widget do Duolingo (e o do Fito): o fundo é a cor do momento, o
/// bicho é grande e sai pela borda de baixo, e o canto de cima à esquerda
/// fica livre — é onde o Kotlin escreve o número da raiz e a frase, em
/// texto de verdade (nítido, e lido pelo leitor de tela).
class _CenaDoWidget extends StatelessWidget {
  const _CenaDoWidget({
    required this.estado,
    required this.momento,
    required this.formato,
  });

  final EstadoDoWidget estado;
  final MomentoDoWidget momento;
  final FormatoDoWidget formato;

  @override
  Widget build(BuildContext context) {
    final t = formato.tamanho;
    final largo = formato == FormatoDoWidget.largo;
    // O bicho grande, saindo pela borda de baixo, como nas referências.
    final lado = t.height * (largo ? 1.35 : 1.18);
    return SizedBox(
      width: t.width,
      height: t.height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [momento.cimo, momento.fundo],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _CeuDoMomento(momento, largo)),
          ),
          Positioned(
            // No 2×2 o alto à esquerda é do número e da frase: o bicho
            // desce e vai para a direita, com a cabeça abaixo do texto.
            right: largo ? -t.width * 0.02 : -t.width * 0.24,
            bottom: largo ? -lado * 0.22 : -lado * 0.34,
            width: lado,
            height: lado,
            child: PetView(
              species: estado.especie,
              mood: momento.humor,
              activity: momento.atividade,
              coat: estado.pelagem,
              estagio: estado.estagio,
              interativo: false,
              width: lado,
              height: lado,
              scale: lado / 190,
            ),
          ),
        ],
      ),
    );
  }
}

/// O céu de cada momento: o brilho do sol, a lua, as estrelas, os
/// confetes do dia feito, e um morro embaixo para o bicho pisar.
class _CeuDoMomento extends CustomPainter {
  _CeuDoMomento(this.momento, this.largo);

  final MomentoDoWidget momento;
  final bool largo;

  @override
  void paint(Canvas canvas, Size s) {
    final sorte = Random(momento.index * 13 + (largo ? 7 : 3));
    final branco = Paint()..color = Colors.white;
    switch (momento) {
      case MomentoDoWidget.manha:
        canvas.drawCircle(
          Offset(s.width * 0.86, s.height * 0.12),
          s.height * 0.42,
          Paint()
            ..shader =
                RadialGradient(
                  colors: [
                    const Color(0xFFFFF1B8).withValues(alpha: 0.75),
                    const Color(0xFFFFF1B8).withValues(alpha: 0),
                  ],
                ).createShader(
                  Rect.fromCircle(
                    center: Offset(s.width * 0.86, s.height * 0.12),
                    radius: s.height * 0.42,
                  ),
                ),
        );
      case MomentoDoWidget.tarde:
        for (var i = 0; i < 3; i++) {
          final c = Offset(
            s.width * (0.45 + 0.22 * i),
            s.height * (0.12 + 0.06 * (i % 2)),
          );
          final p = Paint()..color = Colors.white.withValues(alpha: 0.18);
          canvas.drawOval(
            Rect.fromCenter(
              center: c,
              width: s.height * 0.34,
              height: s.height * 0.1,
            ),
            p,
          );
        }
      case MomentoDoWidget.noite:
      case MomentoDoWidget.madrugada:
        final n = momento == MomentoDoWidget.madrugada ? 26 : 14;
        for (var i = 0; i < n; i++) {
          final o = Offset(
            sorte.nextDouble() * s.width,
            sorte.nextDouble() * s.height * 0.6,
          );
          canvas.drawCircle(
            o,
            0.8 + sorte.nextDouble() * 1.8,
            branco
              ..color = Colors.white.withValues(
                alpha: 0.35 + sorte.nextDouble() * 0.5,
              ),
          );
        }
        if (momento == MomentoDoWidget.madrugada) {
          // No 2×2 a frase atravessa o alto: a lua vai para o canto.
          final c = largo
              ? Offset(s.width * 0.8, s.height * 0.2)
              : Offset(s.width * 0.88, s.height * 0.11);
          final r = s.height * (largo ? 0.09 : 0.065);
          canvas.drawCircle(
            c,
            r * 2.4,
            Paint()..color = Colors.white.withValues(alpha: 0.06),
          );
          canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFF3C4));
          canvas.drawCircle(
            c + Offset(r * 0.45, -r * 0.25),
            r * 0.9,
            Paint()..color = momento.cimo,
          );
        }
      case MomentoDoWidget.feito:
        const cores = [
          Color(0xFFFFFFFF),
          Color(0xFFFFE08A),
          Color(0xFFB8F0A0),
          Color(0xFFFF9EC4),
        ];
        for (var i = 0; i < 22; i++) {
          final o = Offset(
            sorte.nextDouble() * s.width,
            sorte.nextDouble() * s.height * 0.75,
          );
          canvas.save();
          canvas.translate(o.dx, o.dy);
          canvas.rotate(sorte.nextDouble() * 3.14);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(-4, -1.6, 8, 3.2),
              const Radius.circular(1.6),
            ),
            Paint()..color = cores[i % cores.length].withValues(alpha: 0.85),
          );
          canvas.restore();
        }
    }
    // O morro: o chão do bicho, uma faixa mais escura e curva embaixo.
    final morro = Path()
      ..moveTo(0, s.height * 0.86)
      ..quadraticBezierTo(
        s.width * 0.5,
        s.height * 0.74,
        s.width,
        s.height * 0.84,
      )
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(
      morro,
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(_CeuDoMomento old) =>
      old.momento != momento || old.largo != largo;
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
