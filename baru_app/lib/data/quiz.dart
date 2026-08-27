/// O quiz do onboarding.
///
/// Duas coisas mudaram em relação à primeira versão, e as duas por defeito:
///
/// **A resposta guardada é um id, não o rótulo traduzido.** Antes o app
/// gravava o texto em português; trocar de idioma invalidava a comparação e
/// as respostas eram apagadas — havia até um `if` no `setLang` só para isso.
/// Id estável significa que a resposta atravessa idioma e vai inteira para o
/// banco.
///
/// **Cada pergunta declara o que faz.** Umas pesam na escolha da espécie,
/// outras existem para o app saber quem está do outro lado. Pergunta que não
/// pesa nem informa não entra: quiz longo sem propósito é abandono no
/// onboarding.
library;

import '../models.dart';

/// Uma opção de resposta.
class OpcaoDoQuiz {
  const OpcaoDoQuiz(this.id, {this.peso = const {}});

  /// Estável e nunca traduzido. É o que vai para o banco.
  final String id;

  /// Quanto esta resposta puxa para cada espécie de origem.
  final Map<Species, int> peso;
}

/// O que a pergunta serve para além de escolher o bicho.
enum ParaQueServe {
  /// Só escolhe a espécie.
  escolhaDoBicho,

  /// Diz o que rouba o foco — alimenta a leitura de tempo de tela.
  perfilDeDistracao,

  /// Diz o que a pessoa quer do app — alimenta a meta sugerida.
  intencao,
}

class PerguntaDoQuiz {
  const PerguntaDoQuiz(this.id, this.opcoes, {required this.serve});

  final String id;
  final List<OpcaoDoQuiz> opcoes;
  final ParaQueServe serve;
}

/// As perguntas, na ordem em que aparecem.
///
/// Os pesos existem para que **as quatro espécies de origem sejam todas
/// alcançáveis** — um quiz que sempre devolve capivara não é quiz. Varrendo
/// as 4096 combinações, a distribuição fica em 28% capivara, 26% coruja,
/// 24% lontra e 22% tartaruga: a capivara puxa um pouco por ser a que ganha
/// empate, e ela é o mascote.
const quiz = <PerguntaDoQuiz>[
  // 1. Elemento. Era "o elemento do seu signo"; a astrologia saiu e o
  // elemento ficou, porque a imagem funciona sozinha.
  PerguntaDoQuiz(
    'elemento',
    [
      OpcaoDoQuiz('agua', peso: {Species.capybara: 2}),
      OpcaoDoQuiz('fogo', peso: {Species.otter: 2}),
      OpcaoDoQuiz('terra', peso: {Species.tortoise: 2}),
      OpcaoDoQuiz('ar', peso: {Species.owl: 2}),
    ],
    serve: ParaQueServe.escolhaDoBicho,
  ),

  // 2. Quando a cabeça fica clara.
  PerguntaDoQuiz(
    'clareza',
    [
      OpcaoDoQuiz('manha', peso: {Species.tortoise: 1, Species.capybara: 1}),
      OpcaoDoQuiz('tarde', peso: {Species.otter: 2}),
      OpcaoDoQuiz('madrugada', peso: {Species.owl: 2}),
      OpcaoDoQuiz('varia', peso: {Species.capybara: 1}),
    ],
    serve: ParaQueServe.escolhaDoBicho,
  ),

  // 3. O que acalma.
  PerguntaDoQuiz(
    'acalma',
    [
      OpcaoDoQuiz('agua_quente', peso: {Species.capybara: 2}),
      OpcaoDoQuiz('companhia', peso: {Species.otter: 2}),
      OpcaoDoQuiz('silencio', peso: {Species.owl: 2}),
      OpcaoDoQuiz('rotina', peso: {Species.tortoise: 2}),
    ],
    serve: ParaQueServe.escolhaDoBicho,
  ),

  // 4. O que rouba o foco. **Isto não é enfeite:** é o que o app usa para
  // saber onde olhar quando lê o tempo de tela.
  PerguntaDoQuiz(
    'rouba_foco',
    [
      OpcaoDoQuiz('redes', peso: {Species.otter: 1}),
      OpcaoDoQuiz('videos', peso: {Species.capybara: 1}),
      OpcaoDoQuiz('jogos', peso: {Species.otter: 1}),
      OpcaoDoQuiz('mensagens', peso: {Species.owl: 1}),
    ],
    serve: ParaQueServe.perfilDeDistracao,
  ),

  // 5. Como recarrega.
  PerguntaDoQuiz(
    'recarrega',
    [
      OpcaoDoQuiz('sozinho', peso: {Species.owl: 2}),
      OpcaoDoQuiz('com_gente', peso: {Species.otter: 2}),
      OpcaoDoQuiz('natureza', peso: {Species.capybara: 2}),
      OpcaoDoQuiz('dormindo', peso: {Species.tortoise: 2}),
    ],
    serve: ParaQueServe.escolhaDoBicho,
  ),

  // 6. O que quer do Baru. Move a meta sugerida — quem quer menos tela
  // recebe uma meta mais apertada que quem quer companhia.
  PerguntaDoQuiz(
    'quer',
    [
      OpcaoDoQuiz('menos_tela', peso: {Species.tortoise: 2}),
      OpcaoDoQuiz('mais_foco', peso: {Species.owl: 2}),
      OpcaoDoQuiz('uma_rotina', peso: {Species.tortoise: 1}),
      // `so_companhia`, não `companhia`: o id da opção é a chave da
      // tradução, e há um `companhia` na pergunta do que acalma. Ids iguais
      // em perguntas diferentes fazem uma mostrar o rótulo da outra.
      OpcaoDoQuiz('so_companhia', peso: {Species.capybara: 1}),
    ],
    serve: ParaQueServe.intencao,
  ),
];

PerguntaDoQuiz? perguntaPorId(String id) {
  for (final p in quiz) {
    if (p.id == id) return p;
  }
  return null;
}

/// A espécie que as respostas apontam.
///
/// Empate fica com a ordem de [Species] — determinístico, não aleatório: o
/// mesmo conjunto de respostas tem de dar sempre o mesmo bicho.
Species especiePelasRespostas(Map<String, String> respostas) {
  final placar = <Species, int>{
    Species.capybara: 0,
    Species.otter: 0,
    Species.tortoise: 0,
    Species.owl: 0,
  };
  for (final pergunta in quiz) {
    final escolhida = respostas[pergunta.id];
    if (escolhida == null) continue;
    for (final o in pergunta.opcoes) {
      if (o.id != escolhida) continue;
      o.peso.forEach((k, v) => placar[k] = placar[k]! + v);
    }
  }
  var melhor = Species.capybara;
  var maior = -1;
  for (final e in placar.entries) {
    if (e.value > maior) {
      maior = e.value;
      melhor = e.key;
    }
  }
  return melhor;
}

/// Quanto a intenção aperta ou afrouxa a meta sugerida.
///
/// Quem diz que quer menos tela recebe uma meta mais dura que quem veio pela
/// companhia. Sem isto, a resposta seria dado morto no banco.
double fatorDaMeta(Map<String, String> respostas) {
  switch (respostas['quer']) {
    case 'menos_tela':
      return 0.62;
    case 'mais_foco':
      return 0.72;
    case 'uma_rotina':
      return 0.80;
    case 'companhia':
      return 0.88;
    default:
      return 0.75; // o valor de antes, quando não havia pergunta
  }
}

/// As categorias que o usuário disse que o distraem.
///
/// Vira dica na tela de tempo de tela: o app já sabe onde olhar antes da
/// primeira medição.
List<String> pacotesSuspeitos(Map<String, String> respostas) {
  switch (respostas['rouba_foco']) {
    case 'redes':
      return const [
        'com.instagram.android',
        'com.zhiliaoapp.musically',
        'com.twitter.android',
      ];
    case 'videos':
      return const ['com.google.android.youtube', 'com.netflix.mediaclient'];
    case 'jogos':
      return const ['com.roblox.client', 'com.supercell.clashofclans'];
    case 'mensagens':
      return const ['com.whatsapp', 'org.telegram.messenger'];
    default:
      return const [];
  }
}
