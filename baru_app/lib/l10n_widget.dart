/// As frases do widget da tela inicial, uma por momento do dia.
///
/// O widget troca de momento sozinho, com o app fechado (pesquisa 26): o
/// Kotlin escolhe qual frase mostrar pela hora, mas **não escreve** nenhuma
/// — todas saem daqui já traduzidas, como na barra de notificações.
///
/// Curtas, como as do Duolingo ("Let's practice!"): o número da raiz fica
/// grande em cima, e a frase é o chamado. Sem número dentro dela — a frase
/// de amanhã de manhã é gravada hoje, e um número gravado hoje pode estar
/// errado amanhã.
library;

import 'l10n.dart';

const textosDoWidget = <String, Map<String, String>>{
  'pt': {
    'widgetFeito': 'Raiz cresceu hoje!',
    'widgetManha': 'Bom dia! Uma pausa?',
    'widgetTarde': '{p} guardou um lugar',
    'widgetNoite': 'Ainda dá tempo hoje',
    'widgetMadrugada': '{p} está dormindo',
  },
  'en': {
    'widgetFeito': 'Roots grew today!',
    'widgetManha': 'Morning! A short break?',
    'widgetTarde': '{p} saved you a spot',
    'widgetNoite': 'Still time today',
    'widgetMadrugada': '{p} is asleep',
  },
  'es': {
    'widgetFeito': '¡La raíz creció hoy!',
    'widgetManha': '¡Buen día! ¿Una pausa?',
    'widgetTarde': '{p} te guardó un lugar',
    'widgetNoite': 'Aún hay tiempo hoy',
    'widgetMadrugada': '{p} está durmiendo',
  },
  'zh': {
    'widgetFeito': '今天根长大了！',
    'widgetManha': '早上好！休息一下？',
    'widgetTarde': '{p} 给你留了位置',
    'widgetNoite': '今天还来得及',
    'widgetMadrugada': '{p} 睡着了',
  },
};

void garanteTextosDoWidget() => T.registra(textosDoWidget);

extension TextosDoWidget on T {
  String get widgetFeito => s('widgetFeito');
  String get widgetManha => s('widgetManha');
  String get widgetTarde => s('widgetTarde');
  String get widgetNoite => s('widgetNoite');
  String get widgetMadrugada => s('widgetMadrugada');
}
