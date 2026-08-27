import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/overlay_service.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

/// Aparecer sobre outros apps.
///
/// Pedir `SYSTEM_ALERT_WINDOW` sem explicar é o jeito mais rápido de o usuário
/// negar: é a mesma permissão que malware usa. Então esta tela **mostra**
/// antes de pedir — a pré-visualização é o argumento.
class SobreposicaoScreen extends StatefulWidget {
  const SobreposicaoScreen({super.key});

  static const chavePreview = Key('sobreposicao-preview');

  @override
  State<SobreposicaoScreen> createState() => _SobreposicaoScreenState();
}

class _SobreposicaoScreenState extends State<SobreposicaoScreen>
    with WidgetsBindingObserver {
  bool? _permitido;

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
    // Voltar da tela do sistema é exatamente quando a resposta mudou.
    if (state == AppLifecycleState.resumed) _confere();
  }

  Future<void> _confere() async {
    final v = await OverlayService.instance.temPermissao();
    if (mounted) setState(() => _permitido = v);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final ehAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(
          titulo: t.sobreT,
          subtitulo: t.fill(t.sobreSub, {'n': app.displayName}),
          aoVoltar: app.voltar,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.sm,
              Espaco.margemTela,
              Espaco.xxl,
            ),
            children: [
              Text(
                t.sobrePreview.toUpperCase(),
                style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
              ),
              const SizedBox(height: Espaco.sm),
              _Previa(app: app),
              const SizedBox(height: Espaco.lg),
              if (!ehAndroid)
                _Nota(texto: t.sobreSoAndroid, cor: Cores.neutro)
              else ...[
                CartaoBaru(
                  child: Row(
                    children: [
                      Icon(
                        _permitido == true
                            ? Icons.check_circle_rounded
                            : Icons.layers_outlined,
                        size: 22,
                        color: _permitido == true
                            ? Cores.primaria
                            : Cores.tintaA(0.4),
                      ),
                      const SizedBox(width: Espaco.sm),
                      Expanded(
                        child: Text(
                          _permitido == true
                              ? t.sobreLigado
                              : t.sobreDesligado,
                          style: estilo(Tipo.subtitulo),
                        ),
                      ),
                      if (_permitido != true)
                        GestureDetector(
                          onTap: () async {
                            await OverlayService.instance.pedePermissao();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Espaco.sm,
                              vertical: Espaco.xs,
                            ),
                            child: Text(
                              t.sobreLigar,
                              style: estilo(
                                Tipo.rotulo,
                                color: Cores.primariaEscura,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Espaco.sm),
                _Nota(texto: t.sobreComo, cor: Cores.tintaA(0.45)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A pré-visualização: o balão como ele aparece sobre o outro app.
///
/// Desenhada com os mesmos tokens e o mesmo `PetView` do app — o que se vê
/// aqui é o que o overlay nativo reproduz em `Canvas`.
class _Previa extends StatelessWidget {
  const _Previa({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    return ClipRRect(
      key: SobreposicaoScreen.chavePreview,
      borderRadius: Raio.todos(Raio.cartao),
      child: Container(
        height: 300,
        color: const Color(0xFF1C1A19),
        child: Stack(
          children: [
            // O "outro app" atrás: barras cinzas, sem imitar marca nenhuma.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(Espaco.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final altura in [18.0, 96.0, 14.0, 70.0])
                      Padding(
                        padding: const EdgeInsets.only(bottom: Espaco.sm),
                        child: Container(
                          height: altura,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: Raio.todos(Raio.campo),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: Espaco.sm,
              bottom: Espaco.sm,
              child: _Balao(app: app, fala: t.sobreFala1),
            ),
          ],
        ),
      ),
    );
  }
}

class _Balao extends StatelessWidget {
  const _Balao({required this.app, required this.fala});

  final AppState app;
  final String fala;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 224,
          padding: const EdgeInsets.all(Espaco.md),
          decoration: BoxDecoration(
            color: Cores.superficie,
            borderRadius: Raio.todos(Raio.cartao),
            boxShadow: Elevacao.cartaoElevado,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fala, style: estilo(Tipo.corpoForte)),
              const SizedBox(height: Espaco.sm),
              Row(
                children: [
                  Expanded(
                    child: _BotaoFalso(
                      rotulo: t.sobreFechar,
                      cor: Cores.primaria,
                      texto: Cores.superficie,
                    ),
                  ),
                  const SizedBox(width: Espaco.xs),
                  Expanded(
                    child: _BotaoFalso(
                      rotulo: t.sobreMais,
                      cor: Cores.tintaA(0.08),
                      texto: Cores.tinta,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Rabicho apontando para o bicho.
        Padding(
          padding: const EdgeInsets.only(right: 34),
          child: CustomPaint(
            size: const Size(22, 12),
            painter: _Rabicho(),
          ),
        ),
        SizedBox(
          width: 120,
          height: 92,
          child: PetView(
            species: app.species,
            mood: app.mood,
            activity: Activity.idle,
            coat: app.color,
            scale: 0.62,
            interativo: false,
          ),
        ),
      ],
    );
  }
}

class _BotaoFalso extends StatelessWidget {
  const _BotaoFalso({
    required this.rotulo,
    required this.cor,
    required this.texto,
  });

  final String rotulo;
  final Color cor;
  final Color texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cor,
        borderRadius: Raio.todos(Raio.pilula),
      ),
      child: Text(
        rotulo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: estilo(Tipo.corpoPequeno, color: texto),
      ),
    );
  }
}

class _Rabicho extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.55, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = Cores.superficie,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _Nota extends StatelessWidget {
  const _Nota({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: cor),
        const SizedBox(width: Espaco.xs),
        Expanded(
          child: Text(
            texto,
            style: estilo(Tipo.corpoPequeno, color: cor),
          ),
        ),
      ],
    );
  }
}
