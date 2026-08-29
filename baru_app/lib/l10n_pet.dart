/// Os textos que dependem do **que o bicho está fazendo**.
///
/// Existe por dois motivos, nesta ordem:
///
/// 1. `lib/l10n.dart` tem `activityLine` = "{n} está nadando." fixo, e a
///    tela de sessão o usava para as oito espécies. A coruja lia "está
///    nadando" enquanto voava. Legenda e desenho têm de dizer a mesma coisa
///    — foi exatamente esse o defeito relatado.
/// 2. Aquele arquivo é o ponto de colisão de qualquer trabalho em paralelo, e
///    `T.registra` existe para um módulo declarar os seus próprios textos.
///
/// O catálogo principal ganha de qualquer chave daqui, então todas nascem
/// prefixadas com `pet` e nenhuma disputa nome com o que já existe.
library;

import 'l10n.dart';
import 'widgets/pet.dart';

const textosDoPet = <String, Map<String, String>>{
  'pt': {
    'petFazendo_nado': '{n} está nadando.',
    'petFazendo_voo': '{n} está voando.',
    'petFazendo_brincadeira': '{n} está brincando na beira.',
    'petFazendo_pasto': '{n} está pastando.',
    'petFazendo_petisco': '{n} está petiscando.',
    'petFazendo_cochilo': '{n} está dormindo.',
    'petFazendo_ocioso': '{n} está por aí.',
    'petSessao_nado': 'banho de {m} min',
    'petSessao_voo': 'voo de {m} min',
    'petSessao_brincadeira': 'brincadeira de {m} min',
    'petSessao_foco': 'foco de {m} min',
  },
  'en': {
    'petFazendo_nado': '{n} is swimming.',
    'petFazendo_voo': '{n} is flying.',
    'petFazendo_brincadeira': '{n} is playing by the water.',
    'petFazendo_pasto': '{n} is grazing.',
    'petFazendo_petisco': '{n} is having a snack.',
    'petFazendo_cochilo': '{n} is sleeping.',
    'petFazendo_ocioso': '{n} is hanging around.',
    'petSessao_nado': '{m} minute swim',
    'petSessao_voo': '{m} minute flight',
    'petSessao_brincadeira': '{m} minutes of play',
    'petSessao_foco': '{m} minutes of focus',
  },
  'es': {
    'petFazendo_nado': '{n} está nadando.',
    'petFazendo_voo': '{n} está volando.',
    'petFazendo_brincadeira': '{n} está jugando en la orilla.',
    'petFazendo_pasto': '{n} está pastando.',
    'petFazendo_petisco': '{n} está picando algo.',
    'petFazendo_cochilo': '{n} está durmiendo.',
    'petFazendo_ocioso': '{n} anda por ahí.',
    'petSessao_nado': 'baño de {m} min',
    'petSessao_voo': 'vuelo de {m} min',
    'petSessao_brincadeira': 'juego de {m} min',
    'petSessao_foco': 'foco de {m} min',
  },
  'zh': {
    'petFazendo_nado': '{n} 正在游泳。',
    'petFazendo_voo': '{n} 正在飞翔。',
    'petFazendo_brincadeira': '{n} 正在水边玩耍。',
    'petFazendo_pasto': '{n} 正在吃草。',
    'petFazendo_petisco': '{n} 正在吃点心。',
    'petFazendo_cochilo': '{n} 正在睡觉。',
    'petFazendo_ocioso': '{n} 就在旁边。',
    'petSessao_nado': '{m} 分钟游泳',
    'petSessao_voo': '{m} 分钟飞翔',
    'petSessao_brincadeira': '{m} 分钟玩耍',
    'petSessao_foco': '{m} 分钟专注',
  },
};

/// Registra o catálogo. Idempotente — `T.registra` ignora o mapa repetido.
void garanteTextosDoPet() => T.registra(textosDoPet);

extension TextosDoPet on T {
  /// "{n} está nadando." — a frase que acompanha a cena.
  ///
  /// O sufixo é o nome do valor do enum, então acrescentar uma ação nova
  /// quebra na tela e não no compilador. É o preço de indexar por enum; em
  /// troca, uma ação sem texto devolve a própria chave em vez de derrubar o
  /// app, que é o contrato de `T.s`.
  String petFazendo(AcaoDoBicho acao) => s('petFazendo_${acao.name}');

  /// O rótulo da sessão de foco: "banho de 25 min", "voo de 25 min".
  ///
  /// Só três ações podem ser a sessão (ver `acaoDoBicho` com `Activity.swim`).
  /// As outras caem em "foco de {m} min": genérico de propósito, porque uma
  /// sessão nunca é pasto nem cochilo, e inventar rótulo para um caso
  /// impossível é convidar o texto errado a aparecer um dia.
  String petRotuloDaSessao(AcaoDoBicho acao) => switch (acao) {
        AcaoDoBicho.nado => s('petSessao_nado'),
        AcaoDoBicho.voo => s('petSessao_voo'),
        AcaoDoBicho.brincadeira => s('petSessao_brincadeira'),
        _ => s('petSessao_foco'),
      };
}
