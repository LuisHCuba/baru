import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

/// A pergunta antes de fechar o app.
///
/// O voltar na home fechava o app na hora. Num app cujo produto é companhia,
/// esse é justamente o gesto que a companhia não faz — e some sem dizer que
/// nada foi perdido, que é a promessa central do Baru (§ "o usuário nunca
/// perde nada").
class FolhaDeSaida extends StatefulWidget {
  const FolhaDeSaida({super.key});

  static const chave = Key('folha-de-saida');

  @override
  State<FolhaDeSaida> createState() => _FolhaDeSaidaState();
}

class _FolhaDeSaidaState extends State<FolhaDeSaida>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Tempo.tela,
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    return Positioned.fill(
      key: FolhaDeSaida.chave,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final f = Curvas.padrao.transform(_c.value);
          return Stack(
            children: [
              // Toque fora fecha: a saída não pode virar armadilha.
              GestureDetector(
                onTap: app.cancelaSaida,
                child: ColoredBox(
                  color: Cores.tintaA(0.55 * f),
                  child: const SizedBox.expand(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, (1 - f) * 220),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      Espaco.margemTela,
                      Espaco.lg,
                      Espaco.margemTela,
                      Espaco.xl,
                    ),
                    decoration: const BoxDecoration(
                      color: Cores.superficie,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(Raio.folha),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // O bicho aparece: é dele que a pergunta fala.
                          SizedBox(
                            height: 104,
                            child: PetView(
                              species: app.species,
                              mood: app.mood,
                              activity: app.activity,
                              coat: app.color,
                              scale: 0.9,
                              interativo: false,
                            ),
                          ),
                          const SizedBox(height: Espaco.sm),
                          Text(
                            t.sairT,
                            textAlign: TextAlign.center,
                            style: estilo(Tipo.tituloGrande),
                          ),
                          const SizedBox(height: Espaco.xs),
                          Text(
                            app.frase(t.sairB),
                            textAlign: TextAlign.center,
                            style: estilo(
                              Tipo.corpo,
                              color: Cores.tintaA(0.65),
                            ),
                          ),
                          const SizedBox(height: Espaco.lg),
                          PrimaryButton(
                            label: t.sairFicar,
                            onTap: app.cancelaSaida,
                          ),
                          const SizedBox(height: Espaco.xs),
                          GhostButton(
                            label: t.sairSair,
                            onTap: () {
                              app.cancelaSaida();
                              SystemNavigator.pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
