import 'package:flutter/material.dart';

import '../l10n.dart';
import '../share/habitat_share.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'raiz.dart';

/// O cartão da raiz, feito para sair do app.
///
/// **Por que uma imagem própria e não uma captura de tela.** Captura leva
/// junto a barra de status, a hora, a bateria e o resto da interface — e o
/// que a pessoa quer mostrar é o que ela construiu, não o print do celular
/// dela. Uma imagem desenhada também sai legível em qualquer aparelho, sem
/// depender da densidade da tela de quem compartilhou.
///
/// **Por que compartilhar importa aqui.** A raiz é a única coisa do app que
/// só o tempo constrói: não dá para comprar nem acelerar. É o que faz dela
/// a peça que vale mostrar — e mostrar é o que traz gente nova.
class CartaoDaRaiz extends StatelessWidget {
  const CartaoDaRaiz({
    super.key,
    required this.dias,
    required this.nomeDoPet,
    required this.lang,
  });

  final int dias;
  final String nomeDoPet;
  final String lang;

  static const chave = Key('cartao-da-raiz');

  /// Proporção de retrato, que é como as redes mostram imagem sem cortar.
  static const largura = 360.0;
  static const altura = 540.0;

  @override
  Widget build(BuildContext context) {
    garanteTextosDoCartaoDaRaiz();
    final t = T(lang);
    return RepaintBoundary(
      key: chave,
      child: SizedBox(
        width: largura,
        height: altura,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Cores.superficie, Color(0xFFEFE4D2)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t.raizCartaoTitulo,
                  textAlign: TextAlign.center,
                  style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.5)),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dias',
                  textAlign: TextAlign.center,
                  style: estilo(
                    Tipo.numeroHeroi,
                    color: Cores.primariaEscura,
                    tabular: true,
                  ),
                ),
                Text(
                  t.fill(t.raizCartaoDias, {'n': dias}),
                  textAlign: TextAlign.center,
                  style: estilo(Tipo.corpo, color: Cores.tintaA(0.6)),
                ),
                const SizedBox(height: 8),
                // A raiz ocupa o resto: ela é o assunto do cartão, não um
                // enfeite ao lado do número.
                Expanded(
                  child: RaizViva(
                    dias: dias,
                    cor: Cores.primariaEscura,
                    corDaTerra: const Color(0x14000000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.fill(t.raizCartaoRodape, {'a': nomeDoPet}),
                  textAlign: TextAlign.center,
                  style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.45)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Os textos do cartão.
///
/// Ficam num mapa próprio, registrado sob demanda, porque `lib/l10n.dart` é
/// o ponto de colisão de qualquer trabalho em paralelo — ver `T.registra`.
const textosDoCartaoDaRaiz = <String, Map<String, String>>{
  'pt': {
    'raizCompartilhar': 'Compartilhar minha raiz',
    'raizCartaoTitulo': 'MINHA RAIZ',
    'raizCartaoDias': '{n} dias presente',
    'raizCartaoRodape': 'Construída com {a}, no Baru.',
  },
  'en': {
    'raizCompartilhar': 'Share my roots',
    'raizCartaoTitulo': 'MY ROOTS',
    'raizCartaoDias': '{n} days present',
    'raizCartaoRodape': 'Grown with {a}, on Baru.',
  },
  'es': {
    'raizCompartilhar': 'Compartir mi raíz',
    'raizCartaoTitulo': 'MI RAÍZ',
    'raizCartaoDias': '{n} días presente',
    'raizCartaoRodape': 'Construida con {a}, en Baru.',
  },
  'zh': {
    'raizCompartilhar': '分享我的根',
    'raizCartaoTitulo': '我的根',
    'raizCartaoDias': '已出现 {n} 天',
    'raizCartaoRodape': '和 {a} 一起，在 Baru 养成。',
  },
};

void garanteTextosDoCartaoDaRaiz() => T.registra(textosDoCartaoDaRaiz);

/// Os acessos, como getters.
///
/// `t.s('chave')` funcionaria, mas erro de digitação só apareceria na tela
/// da pessoa. Extensão dá o erro no compilador, que é onde ele custa
/// barato — e é o padrão que os módulos com catálogo próprio seguem.
extension TextosDoCartaoDaRaiz on T {
  String get raizCompartilhar => s('raizCompartilhar');
  String get raizCartaoTitulo => s('raizCartaoTitulo');
  String get raizCartaoDias => s('raizCartaoDias');
  String get raizCartaoRodape => s('raizCartaoRodape');
}

/// Compartilhar a raiz.
///
/// Gera um cartão próprio em vez de capturar a tela: print leva junto barra
/// de status, hora e bateria, e o que a pessoa quer mostrar é o que ela
/// construiu. O cartão é montado fora da tela, num `Offstage`, porque ele
/// tem proporção de retrato e apareceria deformado no meio da lista.
class BotaoDeCompartilharRaiz extends StatefulWidget {
  const BotaoDeCompartilharRaiz({super.key, required this.app});

  final AppState app;

  @override
  State<BotaoDeCompartilharRaiz> createState() => BotaoDeCompartilharRaizRaizState();
}

class BotaoDeCompartilharRaizRaizState extends State<BotaoDeCompartilharRaiz> {
  final _borda = GlobalKey();
  bool _ocupado = false;

  Future<void> _compartilha() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final t = widget.app.t;
    final ok = await HabitatShare.share(
      boundaryKey: _borda,
      text: t.fill(t.raizCartaoRodape, {'a': widget.app.displayName}),
    );
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (!ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.shareFail)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    if (app.streak <= 0) {
      // Raiz que ainda não existe não se mostra. Oferecer o botão no dia
      // zero seria convidar a pessoa a exibir um número que ela ainda não
      // tem.
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        // Fora da tela, mas montado: `RepaintBoundary` só rasteriza o que
        // foi realmente desenhado, e `Visibility(visible: false)` não
        // desenha.
        Positioned(
          left: -CartaoDaRaiz.largura * 2,
          child: CartaoDaRaiz(
            dias: app.streak,
            nomeDoPet: app.displayName,
            lang: app.lang,
          ),
        ),
        TextAction(
          key: const Key('raiz-compartilhar'),
          label: _ocupado ? app.t.authLoading : app.t.raizCompartilhar,
          onTap: _compartilha,
        ),
      ],
    );
  }
}
