import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'pet.dart';

class PetNameField extends StatefulWidget {
  const PetNameField({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<PetNameField> createState() => _PetNameFieldState();
}

class _PetNameFieldState extends State<PetNameField> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(PetNameField old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      onChanged: widget.onChanged,
      maxLength: 18,
      textAlign: TextAlign.center,
      style: nunito(size: 20, weight: FontWeight.w700),
      cursorColor: AppColors.green,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inkA(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        counterText: '',
      ),
    );
  }
}

class CoatPicker extends StatelessWidget {
  const CoatPicker({
    super.key,
    required this.selected,
    required this.onPick,
    required this.label,
    required this.especie,
  });

  final int selected;
  final ValueChanged<int> onPick;
  final String label;

  /// A paleta é da espécie: a tartaruga não escolhe entre marrons.
  final Species especie;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionLabel(label),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(AppColors.coatDe(especie).length, (i) {
            final on = selected == i;
            return Semantics(
              button: true,
              selected: on,
              label: '$label ${i + 1}',
              child: GestureDetector(
                onTap: () => onPick(i),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.coatDe(especie)[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (on)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.ink, width: 2.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class SpeciesPicker extends StatelessWidget {
  const SpeciesPicker({
    super.key,
    required this.selected,
    required this.onPick,
    required this.label,
    required this.speciesLabel,
    this.liberadas,
    this.rotuloDeTravada,
  });

  final Species selected;
  final ValueChanged<Species> onPick;
  final String label;
  final String Function(Species) speciesLabel;

  /// As que a pessoa já pode escolher. Nulo = todas.
  ///
  /// A trilha entrega espécie como recompensa, e o seletor mostrava as nove
  /// como se todas fossem escolhíveis: tocar numa travada não fazia nada e
  /// não dizia por quê. Toque que some em silêncio é pior que porta
  /// visível — a pessoa acha que o app quebrou.
  final Set<Species>? liberadas;

  /// O que dizer na travada. Recebe a espécie e devolve o texto do cadeado.
  final String Function(Species)? rotuloDeTravada;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label, padding: const EdgeInsets.fromLTRB(0, 0, 0, 10)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in Species.values)
              if (liberadas == null || liberadas!.contains(s))
                SelectChip(
                  label: speciesLabel(s),
                  selected: selected == s,
                  onTap: () => onPick(s),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                )
              else
                _EspecieTravada(
                  rotulo: rotuloDeTravada?.call(s) ?? speciesLabel(s),
                ),
          ],
        ),
      ],
    );
  }
}

/// O cartão do companheiro no topo dos ajustes.
///
/// [completo] abre pelagem e espécie ali mesmo — é o que o onboarding
/// precisa. Nos ajustes ele fica fechado: essas duas listas eram o grosso da
/// tela comprida, e agora abrem em folha, a partir de uma linha com o valor
/// atual.
class CompanionCard extends StatelessWidget {
  const CompanionCard({super.key, this.completo = true});

  final bool completo;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final sp = t.species(app.speciesKey);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.greenA(0.10),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: PetView(
              species: app.species,
              mood: app.mood,
              activity: app.activity,
              coat: app.color,
              scale: 1.05,
            ),
          ),
          Text(
            sp[0],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: nunito(size: 16, weight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            app.streakText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nunito(size: 13, weight: FontWeight.w600, color: AppColors.green),
          ),
          const SizedBox(height: 16),
          PetNameField(
            key: ValueKey('${app.speciesKey}-${app.displayName}'),
            initial: app.displayName,
            onChanged: app.setName,
          ),
          if (completo) ...[
            const SizedBox(height: 18),
            CoatPicker(
              selected: app.color,
              onPick: app.setColor,
              label: t.coat,
              especie: app.species,
            ),
            const SizedBox(height: 22),
            SpeciesPicker(
              selected: app.species,
              onPick: app.pickSpecies,
              label: t.revealKicker,
              speciesLabel: (s) => t.animalName(s.name),
            ),
          ],
        ],
      ),
    );
  }
}


/// Uma espécie que a trilha ainda não abriu.
///
/// Aparece de propósito: esconder o que falta tira o motivo de subir. É o
/// mesmo desenho do habitat travado — cadeado, tom apagado, e a frase que
/// diz onde ela abre.
class _EspecieTravada extends StatelessWidget {
  const _EspecieTravada({required this.rotulo});

  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: false,
      label: rotulo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Cores.tintaA(0.05),
          borderRadius: Raio.todos(Raio.pilula),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: Cores.tintaA(0.4)),
            const SizedBox(width: 6),
            Text(
              rotulo,
              style: estilo(Tipo.rotulo, color: Cores.tintaA(0.45)),
            ),
          ],
        ),
      ),
    );
  }
}
