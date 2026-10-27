import 'dart:math' as math;

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
    this.compacto = false,
  });

  final String initial;
  final ValueChanged<String> onChanged;

  /// No cartão de Ajustes: alinhado à esquerda, com o lápis que diz que
  /// dá para editar. O campo cinza centralizado parecia botão desligado.
  final bool compacto;

  @override
  State<PetNameField> createState() => _PetNameFieldState();
}

class _PetNameFieldState extends State<PetNameField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

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
    if (widget.compacto) {
      return TextField(
        controller: _c,
        onChanged: widget.onChanged,
        maxLength: 18,
        style: nunito(size: 22, weight: FontWeight.w800),
        cursorColor: AppColors.green,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.cream,
          suffixIcon: Icon(Icons.edit_rounded, size: 18, color: Cores.tinta500),
          border: OutlineInputBorder(
            borderRadius: Raio.todos(Raio.campo),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Espaco.sm,
            vertical: Espaco.xs,
          ),
          counterText: '',
        ),
      );
    }
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espaco.lg,
          vertical: Espaco.md,
        ),
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
        const SizedBox(height: Espaco.sm),
        // Uma linha só: seis bolinhas quebravam em cinco e uma órfã.
        LayoutBuilder(
          builder: (context, c) {
            final n = AppColors.coatDe(especie).length;
            final cela = math.min(60.0, c.maxWidth / n);
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(n, (i) {
                final on = selected == i;
                return Semantics(
                  button: true,
                  selected: on,
                  label: '$label ${i + 1}',
                  child: GestureDetector(
                    onTap: () => onPick(i),
                    child: SizedBox(
                      width: cela,
                      height: cela,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: cela * 0.77,
                            height: cela * 0.77,
                            decoration: BoxDecoration(
                              color: AppColors.coatDe(especie)[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (on)
                            Container(
                              width: cela * 0.93,
                              height: cela * 0.93,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.ink,
                                  width: 2.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
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
        SectionLabel(
          label,
          padding: const EdgeInsets.fromLTRB(0, 0, 0, Espaco.sm),
        ),
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
                    horizontal: Espaco.md,
                    vertical: Espaco.sm,
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
    if (!completo) return _cartaoCompacto(app, sp[0]);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Espaco.lg,
        Espaco.lg,
        Espaco.lg,
        Espaco.lg,
      ),
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
              activity: app.atividadeForaDaAgua,
              coat: app.color,
              estagio: app.estagioVisivel,
              roupas: app.roupasDoBicho,
              roupaDeCabeca: app.roupaDeCabeca,
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
          const SizedBox(height: Espaco.xxs),
          Text(
            app.streakText,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: nunito(
              size: 13,
              weight: FontWeight.w600,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: Espaco.md),
          PetNameField(
            key: ValueKey(app.speciesKey),
            initial: app.displayName,
            onChanged: app.setName,
          ),
          if (completo) ...[
            const SizedBox(height: Espaco.md),
            CoatPicker(
              selected: app.color,
              onPick: app.setColor,
              label: t.coat,
              especie: app.species,
            ),
            const SizedBox(height: Espaco.lg),
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

  /// Ajustes: o bicho numa janelinha do habitat, e ao lado quem ele é.
  Widget _cartaoCompacto(AppState app, String especie) {
    return Container(
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        color: AppColors.greenA(0.10),
        borderRadius: Raio.todos(Raio.cartaoGrande),
      ),
      child: Row(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              borderRadius: Raio.todos(Raio.campo),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF4E6CB),
                  Color(0xFFFAF1E3),
                  Color(0xFFC5D8B6),
                ],
                stops: [0, 0.62, 0.62],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.bottomCenter,
            child: PetView(
              species: app.species,
              mood: app.mood,
              activity: app.atividadeForaDaAgua,
              coat: app.color,
              estagio: app.estagioVisivel,
              roupas: app.roupasDoBicho,
              roupaDeCabeca: app.roupaDeCabeca,
              scale: 0.62,
              alignment: Alignment.bottomCenter,
            ),
          ),
          const SizedBox(width: Espaco.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PetNameField(
                  // Pela espécie, não pelo nome: com o nome na chave o campo
                  // era recriado a cada letra e o teclado fechava.
                  key: ValueKey(app.speciesKey),
                  initial: app.displayName,
                  onChanged: app.setName,
                  compacto: true,
                ),
                const SizedBox(height: Espaco.xs),
                Text(
                  especie,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.corpo, color: Cores.tinta700),
                ),
                const SizedBox(height: Espaco.xxs),
                Text(
                  app.streakText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.rotulo, color: Cores.raiz600),
                ),
              ],
            ),
          ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: Espaco.md,
          vertical: Espaco.sm,
        ),
        decoration: BoxDecoration(
          color: Cores.tintaA(0.05),
          borderRadius: Raio.todos(Raio.pilula),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: Cores.tinta500),
            const SizedBox(width: 6),
            Text(rotulo, style: estilo(Tipo.rotulo, color: Cores.tinta700)),
          ],
        ),
      ),
    );
  }
}
