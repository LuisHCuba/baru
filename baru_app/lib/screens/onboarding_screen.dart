import 'package:flutter/material.dart';

import '../l10n_sobreposicao.dart';
import '../models.dart';
import '../data/quiz.dart';
import '../services/overlay_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';
import '../widgets/pet_profile.dart';
import 'sobreposicao_screen.dart' show CartaoDePermissao;

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 34),
      child: Column(
        children: [
          OnbDots(
            step: app.onb,
            // No passo do quiz a barra anda pergunta a pergunta: parada por
            // seis telas seguidas, ela sugeria que nada estava acontecendo.
            fracaoDoAtual: app.onb == 2 ? app.fracaoDoQuiz : 1,
          ),
          Expanded(child: _step(app)),
          const SizedBox(height: 8),
          _cta(app),
        ],
      ),
    );
  }

  Widget _step(AppState app) {
    switch (app.onb) {
      case 0:
        return _lang(app);
      case 1:
        return _promise(app);
      case 2:
        return _quiz(app);
      case 3:
        return _reveal(app);
      case 4:
        return _goal(app);
      default:
        return AssistenteDePermissoes(app: app);
    }
  }

  Widget _cta(AppState app) {
    if (app.onb == 0) {
      return PrimaryButton(label: app.t.cont, onTap: app.nextOnb);
    }
    if (app.onb == 1) {
      return PrimaryButton(label: app.t.start, onTap: app.nextOnb);
    }
    if (app.onb == 2) {
      // Escolher já avança. O que sobra embaixo é o caminho de volta e, na
      // última pergunta, o botão de fechar o quiz.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (app.quizDone)
            PrimaryButton(label: app.t.quizCta, onTap: app.nextOnb),
          if (app.perguntaAtual > 0)
            TextAction(label: app.t.quizVoltar, onTap: app.voltaPergunta),
        ],
      );
    }
    if (app.onb == 3) {
      return PrimaryButton(label: app.t.revealCta, onTap: app.nextOnb);
    }
    if (app.onb == 4) {
      return PrimaryButton(label: app.t.goalCta, onTap: app.nextOnb);
    }
    // O passo das permissões traz os próprios botões: eles mudam de rótulo a
    // cada permissão e precisam do estado do assistente, que não existe
    // aqui em cima.
    return const SizedBox.shrink();
  }

  Widget _lang(AppState app) {
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.t.langTitle,
                  style: nunito(
                    size: 30,
                    weight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  app.t.langSub,
                  style: nunito(
                    size: 15,
                    height: 1.5,
                    color: AppColors.inkA(0.68),
                  ),
                ),
                const SizedBox(height: 26),
                for (final l in langs) ...[
                  GestureDetector(
                    onTap: () => app.setLang(l.id),
                    child: Container(
                      height: 60,
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      decoration: BoxDecoration(
                        color: app.lang == l.id
                            ? AppColors.greenA(0.14)
                            : AppColors.inkA(0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: app.lang == l.id
                            ? Border.all(color: AppColors.green, width: 2.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            l.label,
                            style: nunito(
                              size: 18,
                              weight: app.lang == l.id
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (app.lang == l.id) ...[
                            const AppIcon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            l.tag,
                            style: nunito(
                              size: 13,
                              weight: FontWeight.w700,
                              color: app.lang == l.id
                                  ? AppColors.green
                                  : AppColors.inkA(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _promise(AppState app) {
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PetView(
                  species: app.species,
                  mood: Mood.content,
                  activity: Activity.idle,
                  coat: app.color,
                  scale: 1.15,
                ),
                const SizedBox(height: 26),
                Text(
                  app.t.promiseT,
                  textAlign: TextAlign.center,
                  style: nunito(
                    size: 29,
                    weight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  app.t.promiseB,
                  textAlign: TextAlign.center,
                  style: nunito(
                    size: 15.5,
                    height: 1.5,
                    color: AppColors.inkA(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Uma pergunta por tela.
  ///
  /// Seis perguntas empilhadas numa rolagem só viravam formulário — e
  /// formulário no onboarding é onde se desiste. Aqui há uma pergunta grande,
  /// quatro opções grandes, e escolher já leva para a seguinte.
  Widget _quiz(AppState app) {
    final pergunta = app.perguntaDaVez;
    final escolhida = app.respostasDoQuiz[pergunta.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 26),
        Text(
          '${app.perguntaAtual + 1}/${quiz.length}',
          style: nunito(
            size: 12.5,
            weight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.inkA(0.4),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          app.t.perguntaDoQuiz(pergunta.id),
          style: nunito(
            size: 26,
            weight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: ListView(
            children: [
              for (final o in pergunta.opcoes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OpcaoGrande(
                    rotulo: app.t.opcaoDoQuiz(o.id),
                    marcada: escolhida == o.id,
                    aoTocar: () => app.respondeEAvanca(pergunta.id, o.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// A revelação, e o que se decide nela.
  ///
  /// O quiz aponta um bicho; aqui a pessoa confirma ou troca, e escolhe o
  /// resto: sexo, pelagem e nome. Tudo o que define o companheiro num lugar
  /// só, em vez de espalhado entre onboarding e ajustes.
  Widget _reveal(AppState app) {
    final sp = app.t.species(app.speciesKey);
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: [
        SectionLabel(app.t.revealKicker, color: AppColors.green),
        const SizedBox(height: 10),
        Text(
          sp[0],
          textAlign: TextAlign.center,
          style: nunito(
            size: 27,
            weight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          sp[1],
          textAlign: TextAlign.center,
          style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
        ),
        const SizedBox(height: 16),
        Center(
          child: PetView(
            species: app.species,
            mood: Mood.radiant,
            activity: Activity.idle,
            coat: app.color,
            roupas: app.roupasDoBicho,
            roupaDeCabeca: app.roupaDeCabeca,
          ),
        ),
        const SizedBox(height: 18),
        PetNameField(
          key: ValueKey('${app.speciesKey}-${app.color}'),
          initial: app.displayName,
          onChanged: app.setName,
        ),
        const SizedBox(height: 22),
        SectionLabel(app.t.setSexo),
        const SizedBox(height: 9),
        Row(
          children: [
            // Sem `Expanded` por fora: `expand: true` já põe o dele, e dois
            // competindo pelo mesmo RenderObject é assert na hora.
            for (final sexo in Sexo.values) ...[
              if (sexo != Sexo.values.first) const SizedBox(width: 8),
              SelectChip(
                label: _rotuloDoSexo(app, sexo),
                selected: app.sexo == sexo,
                onTap: () => app.setSexo(sexo),
                expand: true,
                height: 48,
                radius: 14,
                size: 13,
              ),
            ],
          ],
        ),
        const SizedBox(height: 22),
        CoatPicker(
          selected: app.color,
          onPick: app.setColor,
          label: app.t.coat,
          especie: app.species,
        ),
        const SizedBox(height: 22),
        SpeciesPicker(
          selected: app.species,
          onPick: app.pickSpecies,
          label: app.t.revealTrocar,
          speciesLabel: (s) => app.t.animalName(s.name),
          // No onboarding as quatro de origem estão abertas; as cinco da
          // trilha aparecem travadas, dizendo onde abrem. Escondê-las tiraria
          // o motivo de subir antes mesmo de a pessoa começar.
          liberadas: app.especiesEscolhiveis,
          rotuloDeTravada: (s) => app.t.animalName(s.name),
        ),
      ],
    );
  }

  static String _rotuloDoSexo(AppState app, Sexo s) => switch (s) {
        Sexo.naoDito => app.t.setSexoNao,
        Sexo.macho => app.t.setSexoM,
        Sexo.femea => app.t.setSexoF,
      };

  Widget _goal(AppState app) {
    return ListView(
      padding: const EdgeInsets.only(top: 40),
      children: [
        Text(
          app.t.goalT,
          style: nunito(
            size: 25,
            weight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          app.t.goalB,
          style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            for (var i = 0; i < avgOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 9),
              SelectChip(
                label: app.fmt(avgOptions[i]),
                selected: app.avg == avgOptions[i],
                onTap: () => app.pickAvg(avgOptions[i]),
                expand: true,
                height: 54,
                radius: 16,
                size: 15,
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.greenA(0.10),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(app.t.goalSug, color: AppColors.green),
              const SizedBox(height: 6),
              Text(
                app.fmt(app.goal),
                style: nunito(
                  size: 38,
                  weight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                app.t.goalNote,
                style: nunito(
                  size: 13.5,
                  height: 1.5,
                  color: AppColors.inkA(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// O último passo do onboarding: as permissões, uma de cada vez.
///
/// **O que estava errado.** O onboarding pedia **uma** permissão — o acesso
/// ao uso — e ia embora. A sobreposição, que é a promessa central do produto
/// ("eu tô no TikTok e ele aparece do ladinho"), nunca era pedida: ficava
/// escondida numa linha de Ajustes que ninguém abre. No aparelho do dono do
/// produto ela estava negada, e o app não avisava. Nada aparecia, e parecia
/// defeito.
///
/// **Uma por tela, com o custo da recusa junto.** Quatro pedidos numa tela só
/// viram um muro de texto que ninguém lê, e um pedido sem dizer o que se
/// perde é um pedido no escuro. Aqui cada permissão tem a sua vez, o que faz
/// e o que deixa de funcionar sem ela.
///
/// **Recusar continua sendo caminho suportado** (contrato de produto §3):
/// "agora não" avança, o onboarding termina, e a tela de Ajustes › Sobre
/// outros apps pede de novo quando a pessoa quiser.
class AssistenteDePermissoes extends StatefulWidget {
  const AssistenteDePermissoes({super.key, required this.app});

  final AppState app;

  static const chaveContinuar = Key('onb-permissao-continuar');
  static const chavePular = Key('onb-permissao-pular');

  @override
  State<AssistenteDePermissoes> createState() =>
      _AssistenteDePermissoesState();
}

class _AssistenteDePermissoesState extends State<AssistenteDePermissoes>
    with WidgetsBindingObserver {
  late final List<PermissaoDoBaru> _fila = Permissoes.daPlataforma();

  int _atual = 0;
  Map<PermissaoDoBaru, bool> _estado = const {};

  /// Já pedimos esta e ainda não veio o sim. Muda "Permitir" para "Pedir de
  /// novo": repetir o mesmo rótulo depois de uma recusa faz parecer que o
  /// toque não funcionou.
  final _pedidas = <PermissaoDoBaru>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confere();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Conceder acontece **fora** do app: numa tela do sistema ou num diálogo
    // do Android. Voltar ao primeiro plano é o único instante em que a
    // resposta existe.
    if (state == AppLifecycleState.resumed) _confere(avancaSeConcedeu: true);
  }

  Future<void> _confere({bool avancaSeConcedeu = false}) async {
    final lidas = <PermissaoDoBaru, bool>{};
    for (final p in _fila) {
      lidas[p] = await Permissoes.concedida(p);
    }
    if (!mounted) return;
    final atual = _fila[_atual];
    setState(() => _estado = lidas);
    // Concedeu: segue sozinho. Fazer a pessoa tocar em "continuar" logo
    // depois de dizer sim é pedir duas vezes a mesma coisa.
    if (avancaSeConcedeu && (lidas[atual] ?? false) && _pedidas.contains(atual)) {
      _avanca();
    }
  }

  Future<void> _pede(PermissaoDoBaru p) async {
    setState(() => _pedidas.add(p));
    if (p == PermissaoDoBaru.usoDoAparelho) {
      // Pelo domínio, não direto pelo serviço: é ele que distingue "a pessoa
      // recusou" de "o Android travou a chave porque o app veio de um
      // arquivo" — e só ele abre o passo a passo dessa segunda.
      try {
        await widget.app.requestUsageAccessFromSettings();
      } catch (_) {
        // Abrir a tela do sistema pode falhar (plataforma sem o plugin, um
        // fabricante sem a Activity). O assistente não pode morrer no
        // primeiro passo por causa disso: as outras três ainda valem.
      }
    } else {
      await Permissoes.pede(p);
    }
    // A resposta pode já estar aqui (diálogo respondido na hora) ou só
    // chegar na retomada. Conferir nos dois pontos cobre os dois caminhos.
    await _confere(avancaSeConcedeu: true);
  }

  void _avanca() {
    if (_atual >= _fila.length - 1) {
      widget.app.nextOnb();
      return;
    }
    setState(() => _atual += 1);
  }

  @override
  Widget build(BuildContext context) {
    garanteTextosDaSobreposicao();
    final app = widget.app;
    final t = app.t;
    final permissao = _fila[_atual];
    final concedida = _estado[permissao] ?? false;
    final ultima = _atual == _fila.length - 1;
    final tudoConcedido =
        _fila.every((p) => _estado[p] ?? false) && _estado.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            // A chave amarra a rolagem à permissão da vez. Sem ela é o mesmo
            // `ListView` do passo anterior: quem rolou até o botão de
            // permitir chegava ao passo seguinte já rolado, com o título
            // fora da tela.
            key: ValueKey(permissao),
            padding: const EdgeInsets.only(top: 26),
            children: [
              Text(
                t.fill(t.sobPermPasso, {
                  'i': _atual + 1,
                  'total': _fila.length,
                }),
                style: nunito(
                  size: 12.5,
                  weight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.inkA(0.4),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.sobPermT,
                style: nunito(
                  size: 26,
                  weight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t.fill(t.sobPermSub, {'n': app.displayName}),
                style: nunito(
                  size: 14.5,
                  height: 1.5,
                  color: AppColors.inkA(0.65),
                ),
              ),
              const SizedBox(height: 20),
              CartaoDePermissao(
                t: t,
                nomeDoPet: app.displayName,
                permissao: permissao,
                concedida: _pedidas.contains(permissao) ? concedida : null,
                aoPedir: () => _pede(permissao),
              ),
              const SizedBox(height: 14),
              if (tudoConcedido)
                Text(
                  t.fill(t.sobPermTudo, {'n': app.displayName}),
                  style: nunito(
                    size: 13.5,
                    height: 1.5,
                    weight: FontWeight.w700,
                    color: AppColors.greenDeep,
                  ),
                )
              else
                Text(
                  t.sobPermRevisita,
                  style: nunito(
                    size: 12.5,
                    height: 1.5,
                    color: AppColors.inkA(0.5),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (concedida)
          PrimaryButton(
            key: AssistenteDePermissoes.chaveContinuar,
            label: ultima ? t.sobPermConcluir : t.cont,
            onTap: _avanca,
          )
        else
          TextAction(
            key: AssistenteDePermissoes.chavePular,
            label: ultima ? t.sobPermConcluir : t.sobPermPular,
            onTap: _avanca,
          ),
      ],
    );
  }
}

/// Uma opção do quiz: alvo grande, um por linha.
///
/// Chip pequeno num Wrap fazia quatro opções caberem em duas linhas e o dedo
/// errar. Uma pergunta por tela deu espaço para o alvo certo.
class _OpcaoGrande extends StatelessWidget {
  const _OpcaoGrande({
    required this.rotulo,
    required this.marcada,
    required this.aoTocar,
  });

  final String rotulo;
  final bool marcada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: marcada,
      label: rotulo,
      child: GestureDetector(
        onTap: aoTocar,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: Tempo.microFeedback,
          curve: Curvas.padrao,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: marcada ? AppColors.green : AppColors.inkA(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: marcada ? AppColors.green : AppColors.inkA(0.08),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rotulo,
                  style: nunito(
                    size: 16,
                    weight: FontWeight.w700,
                    color: marcada ? AppColors.cream : AppColors.ink,
                  ),
                ),
              ),
              if (marcada)
                const AppIcon(
                  Icons.check_rounded,
                  size: 20,
                  color: AppColors.cream,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
