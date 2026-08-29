import 'package:flutter/material.dart';

import '../l10n_pet.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/habitat.dart';
import '../widgets/pet.dart';

/// A tela dos 25 minutos.
///
/// O que ela mostra durante todo esse tempo é **o bicho fazendo alguma
/// coisa** — não é decoração, é o produto. O relato que motivou esta versão
/// foi literal: "na hora que eu coloco pra iniciar um foco de 25 minutos ele
/// fica só parado na tela".
///
/// Três decisões, e cada uma responde a um pedaço daquele relato:
///
/// - **A atividade é `swim` e não `app.activity`.** `app.activity` sai do
///   humor e diria "cochilando" para quem passou do tempo de tela — o
///   contrário do que está acontecendo agora. Durante a sessão ele está no
///   banho, que é o vocabulário do próprio app (`sesLabel`: "banho de {m}
///   min"). O que muda por espécie é *o que "banho" quer dizer*: a coruja
///   voa, a gata brinca na beira. Quem traduz é [acaoDoBicho].
/// - **A legenda vem da mesma tradução.** Antes era `activityLine` fixo,
///   "{n} está nadando", para as oito espécies.
/// - **O humor é `radiant`.** Não é enfeite: `radiant` é o humor de quem
///   está indo bem, e quem está no meio de uma sessão está indo bem. Ele
///   acende as faíscas e o sorriso, que é o que faz olhar para a tela valer
///   a pena enquanto o relógio corre.
class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  /// A sessão é o banho do bicho. Ver a nota da classe.
  static const atividade = Activity.swim;

  /// A caixa que o [PetView] ocupa no layout — os valores padrão dele.
  static const caixaDoBicho = Size(200, 150);

  /// Altura da cena.
  ///
  /// Maior que a caixa de propósito. Ampliado por [escalaDoBicho] em torno do
  /// centro, o desenho passa 33 px da caixa em cima e embaixo: com a cena do
  /// tamanho da caixa, a barriga do bicho encostava no contador dos minutos
  /// **e** saía por baixo da lagoa. A conta é 75·escala em cada metade, mais
  /// a folga que sobra: 224 é o menor valor redondo que segura o desenho
  /// inteiro dentro da água.
  static const alturaDaCena = 224.0;

  static const escalaDoBicho = 1.45;

  /// Onde a lâmina d'água da lagoa cai dentro da cena.
  ///
  /// Sai da conta inteira, e não de um número medido na tela: a caixa entra
  /// centrada na cena, o `Transform.scale` amplia em torno do centro dela, e
  /// [PetView.linhaDaguaEm] diz onde a água cruza a caixa. Escrever "117" à
  /// mão faria a lagoa descolar do bicho no dia em que qualquer um dos três
  /// mudasse.
  static double get linhaDagua {
    final meio = caixaDoBicho.height / 2;
    final naCaixa = PetView.linhaDaguaEm(caixaDoBicho.height);
    return (alturaDaCena - caixaDoBicho.height) / 2 +
        meio +
        (naCaixa - meio) * escalaDoBicho;
  }

  @override
  Widget build(BuildContext context) {
    garanteTextosDoPet();
    final app = AppScope.of(context);
    final t = app.t;
    final acao = acaoDoBicho(app.species, atividade);
    final total = app.sessionMinutes * 60;
    final pct = total == 0 ? 0.0 : ((total - app.remaining) / total).clamp(0.0, 1.0);
    final mm = (app.remaining ~/ 60).toString().padLeft(2, '0');
    final ss = (app.remaining % 60).toString().padLeft(2, '0');
    return Stack(
      children: [
        ColoredBox(
          color: AppColors.sessionBg,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 20, 26, 34),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    t
                        .fill(t.petRotuloDaSessao(acao), {'m': app.sessionMinutes})
                        .toUpperCase(),
                    style: nunito(size: 12, weight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.inkA(0.45)),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: alturaDaCena,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // A lagoa só existe para quem entra na água. A
                            // coruja voa e a gata brinca na beira: pôr água
                            // atrás delas seria desenhar as duas afogadas.
                            if (acao == AcaoDoBicho.nado)
                              Positioned.fill(
                                // A água sangra até a borda da tela, por
                                // fora dos 26 px de margem da coluna. Presa
                                // à margem, ela virava um retângulo verde
                                // com dois cantos no meio do nada — adesivo,
                                // não lagoa.
                                child: OverflowBox(
                                  minWidth: MediaQuery.sizeOf(context).width,
                                  maxWidth: MediaQuery.sizeOf(context).width,
                                  child: CustomPaint(
                                    painter: _LagoaDaSessao(
                                      cenario: CenarioDoHabitat.de(
                                        app.habitatAtivo.id,
                                      ),
                                      luz: LuzDaCena.de(
                                        periodoDe(DateTime.now()),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            // 1.45 e não 1.2: aqui o bicho não divide a tela
                            // com habitat nenhum, e é ele que a pessoa vai
                            // olhar por 25 minutos. `Transform.scale` não
                            // muda o espaço ocupado, então a caixa de
                            // 200x150 continua valendo para o layout.
                            Semantics(
                              image: true,
                              label: t.fill(
                                t.petFazendo(acao),
                                {'n': app.displayName},
                              ),
                              child: PetView(
                                species: app.species,
                                mood: Mood.radiant,
                                activity: atividade,
                                coat: app.color,
                                scale: escalaDoBicho,
                                roupas: app.roupasDoBicho,
                                roupaDeCabeca: app.roupaDeCabeca,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      Semantics(
                        liveRegion: true,
                        label: '$mm:$ss',
                        child: Text(
                          '$mm:$ss',
                          style: nunito(size: 66, weight: FontWeight.w800, height: 1, letterSpacing: -2, tabular: true),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.fill(t.petFazendo(acao), {'n': app.displayName}),
                        style: nunito(size: 15.5, color: AppColors.inkA(0.65)),
                      ),
                      const SizedBox(height: 34),
                      TrackFill(pct: pct, height: 8),
                    ],
                  ),
                ),
                TextAction(label: t.give, onTap: app.askQuit, height: 50),
              ],
            ),
          ),
        ),
        if (app.confirming) _QuitSheet(app: app),
      ],
    );
  }
}

/// A lagoa atrás do bicho que nada.
///
/// Sem ela o corpo submerso ficava com o tom da água **e mais nada em
/// volta**: metade de um bicho boiando num fundo bege, que lia como erro de
/// desenho. A água é o que faz a cena existir.
///
/// As cores vêm do habitat que a pessoa conquistou na trilha e da hora do
/// dia, as mesmas duas fontes da cena da home: a sessão acontece no lugar
/// dela, não num lugar genérico.
class _LagoaDaSessao extends CustomPainter {
  const _LagoaDaSessao({required this.cenario, required this.luz});

  final CenarioDoHabitat cenario;
  final LuzDaCena luz;

  @override
  void paint(Canvas canvas, Size size) {
    final y = SessionScreen.linhaDagua;
    final agua = Rect.fromLTRB(0, y, size.width, size.height);
    if (agua.isEmpty) return;

    // O fundo se dissolve em vez de terminar numa linha reta: a lagoa não
    // tem borda de baixo, ela some. Com o corte duro sobrava uma tarja, e a
    // tarja denunciava que ali não havia lugar nenhum.
    final funda = cenario.aguaFundaCom(luz.aguaFunda);
    canvas.drawRect(
      agua,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cenario.aguaCom(luz.agua),
            funda,
            funda.withValues(alpha: 0),
          ],
          stops: const [0, 0.62, 1],
        ).createShader(agua),
    );

    // Duas listras claras logo abaixo da superfície: é o reflexo que impede
    // a água de virar um retângulo chapado.
    final reflexo = Paint()
      ..color = Cores.superficie.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final linha in [
      (0.16, 0.44, 10.0),
      (0.60, 0.86, 22.0),
    ]) {
      canvas.drawLine(
        Offset(size.width * linha.$1, y + linha.$3),
        Offset(size.width * linha.$2, y + linha.$3),
        reflexo,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LagoaDaSessao old) =>
      old.cenario.id != cenario.id || old.luz.agua != luz.agua;
}

class _QuitSheet extends StatelessWidget {
  const _QuitSheet({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.ink.withValues(alpha: 0.42),
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(26, 32, 26, 40),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Continua fazendo a mesma coisa da tela de trás: é justamente
              // o que a folha está perguntando — "ele está no meio disso,
              // tem certeza?". Um bicho parado aqui contradiria a pergunta.
              PetView(
                species: app.species,
                mood: Mood.radiant,
                activity: SessionScreen.atividade,
                coat: app.color,
                roupas: app.roupasDoBicho,
                roupaDeCabeca: app.roupaDeCabeca,
              ),
              const SizedBox(height: 16),
              Text(
                app.t.fill(app.t.quitTitle, {'n': app.displayName}),
                textAlign: TextAlign.center,
                style: nunito(size: 23, weight: FontWeight.w800, height: 1.25, letterSpacing: -0.3),
              ),
              const SizedBox(height: 8),
              Text(
                app.t.quitSub,
                textAlign: TextAlign.center,
                style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
              ),
              const SizedBox(height: 22),
              PrimaryButton(label: app.t.stay, onTap: app.resume),
              TextAction(label: app.t.leave, onTap: app.abandon),
            ],
          ),
        ),
      ),
    );
  }
}
