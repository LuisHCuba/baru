import 'package:flutter/material.dart';

import '../models.dart';
import '../data/quiz.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';
import '../widgets/pet_profile.dart';

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
        return _perm(app);
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
    return Column(
      children: [
        PrimaryButton(
          label: app.t.permAllow,
          onTap: () => app.requestUsageAccessFromOnboarding(),
        ),
        TextAction(label: app.t.permLater, onTap: app.skipUsage),
      ],
    );
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
          style: nunito(size: 30, weight: FontWeight.w800, height: 1.15, letterSpacing: -0.6),
        ),
        const SizedBox(height: 12),
        Text(
          app.t.langSub,
          style: nunito(size: 15, height: 1.5, color: AppColors.inkA(0.68)),
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
                color: app.lang == l.id ? AppColors.greenA(0.14) : AppColors.inkA(0.05),
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
                      weight: app.lang == l.id ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (app.lang == l.id) ...[
                    const AppIcon(Icons.check_rounded, size: 18, color: AppColors.green),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    l.tag,
                    style: nunito(
                      size: 13,
                      weight: FontWeight.w700,
                      color: app.lang == l.id ? AppColors.green : AppColors.inkA(0.4),
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
          style: nunito(size: 29, weight: FontWeight.w800, height: 1.15, letterSpacing: -0.6),
        ),
        const SizedBox(height: 14),
        Text(
          app.t.promiseB,
          textAlign: TextAlign.center,
          style: nunito(size: 15.5, height: 1.5, color: AppColors.inkA(0.7)),
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
          style: nunito(size: 25, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
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
                style: nunito(size: 38, weight: FontWeight.w800, letterSpacing: -1, height: 1.1),
              ),
              const SizedBox(height: 6),
              Text(
                app.t.goalNote,
                style: nunito(size: 13.5, height: 1.5, color: AppColors.inkA(0.65)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _perm(AppState app) {
    return ListView(
      padding: const EdgeInsets.only(top: 34),
      children: [
        Text(
          app.frase(app.t.permT),
          style: nunito(size: 25, weight: FontWeight.w800, height: 1.2, letterSpacing: -0.4),
        ),
        const SizedBox(height: 10),
        Text(
          app.frase(app.t.permB),
          style: nunito(size: 14.5, height: 1.5, color: AppColors.inkA(0.65)),
        ),
        const SizedBox(height: 22),
        for (final line in [
          app.t.perm1,
          app.t.perm2,
          app.frase(app.t.perm3),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(line, style: nunito(size: 14.5, height: 1.45)),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.inkA(0.05),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            app.t.permTech,
            style: nunito(size: 12.5, height: 1.5, color: AppColors.inkA(0.6)).copyWith(
              fontFamily: 'Menlo',
            ),
          ),
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
