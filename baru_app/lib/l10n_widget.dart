/// As frases do widget da tela inicial, uma por momento do dia.
///
/// O widget troca de momento sozinho, com o app fechado (pesquisa 26): o
/// Kotlin escolhe qual frase mostrar pela hora, mas **não escreve** nenhuma
/// — todas saem daqui já traduzidas, como na barra de notificações.
///
/// Sem número de dias fora do "feito": a frase de amanhã de manhã é gravada
/// hoje, e um número gravado hoje pode estar errado amanhã.
library;

import 'l10n.dart';

const textosDoWidget = <String, Map<String, String>>{
  'pt': {
    'widgetFeito': 'A raiz cresceu hoje ✓',
    'widgetManha': 'Bom dia! 10 min fazem a raiz crescer.',
    'widgetTarde': '{p} guardou um lugar para você.',
    'widgetNoite': 'Ainda dá tempo: 10 min hoje.',
    'widgetMadrugada': '{p} está dormindo.',
  },
  'en': {
    'widgetFeito': 'Your roots grew today ✓',
    'widgetManha': 'Good morning! 10 min grow your roots.',
    'widgetTarde': '{p} saved you a spot.',
    'widgetNoite': 'Still time: 10 min today.',
    'widgetMadrugada': '{p} is asleep.',
  },
  'es': {
    'widgetFeito': 'La raíz creció hoy ✓',
    'widgetManha': '¡Buen día! 10 min hacen crecer la raíz.',
    'widgetTarde': '{p} te guardó un lugar.',
    'widgetNoite': 'Aún hay tiempo: 10 min hoy.',
    'widgetMadrugada': '{p} está durmiendo.',
  },
  'zh': {
    'widgetFeito': '今天根长大了 ✓',
    'widgetManha': '早上好！专注 10 分钟，根就会长大。',
    'widgetTarde': '{p} 给你留了个位置。',
    'widgetNoite': '还来得及：今天 10 分钟。',
    'widgetMadrugada': '{p} 睡着了。',
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
