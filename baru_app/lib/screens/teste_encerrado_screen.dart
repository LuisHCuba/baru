import 'package:flutter/material.dart';

import '../l10n.dart';
import '../l10n_assinatura.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

/// Fim do teste de 7 dias, sem assinatura paga.
///
/// Neutra de propósito: sem preço nem convite para comprar. Os dados continuam
/// guardados, e o botão só leva à página inicial do site.
class TesteEncerradoScreen extends StatelessWidget {
  const TesteEncerradoScreen({
    super.key,
    required this.lang,
    required this.aoAbrirSite,
    required this.aoVerificar,
    required this.aoSair,
    this.noCelular = false,
  });

  /// No celular o botão abre a assinatura da loja, não o site.
  final bool noCelular;

  final String lang;
  final VoidCallback aoAbrirSite;
  final VoidCallback aoVerificar;
  final VoidCallback aoSair;

  @override
  Widget build(BuildContext context) {
    final t = T(lang);
    garanteTextosDaAssinatura();
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaco.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Espaco.xl),
              Center(
                child: PetView(
                  species: Species.capybara,
                  mood: Mood.sleepy,
                  activity: Activity.nap,
                  coat: 0,
                ),
              ),
              const SizedBox(height: Espaco.lg),
              Text(
                t.testeFimT,
                textAlign: TextAlign.center,
                style: nunito(size: 26, weight: FontWeight.w800, height: 1.2),
              ),
              const SizedBox(height: Espaco.sm),
              Text(
                t.testeFimB,
                textAlign: TextAlign.center,
                style: nunito(size: 15, height: 1.5, color: Cores.tinta700),
              ),
              const SizedBox(height: Espaco.xl),
              BotaoBaru(rotulo: noCelular ? t.s('assT') : t.testeFimSite, aoTocar: aoAbrirSite),
              const SizedBox(height: Espaco.sm),
              TextButton(
                onPressed: aoVerificar,
                child: Text(
                  t.testeFimVerificar,
                  style: nunito(
                    size: 15,
                    weight: FontWeight.w700,
                    color: AppColors.greenDeep,
                  ),
                ),
              ),
              TextButton(
                onPressed: aoSair,
                child: Text(
                  t.authSignOut,
                  style: nunito(size: 15, color: Cores.tinta700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
