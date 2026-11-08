/// O companheiro do Baru.
///
/// Duas coisas moram aqui e nenhuma é opcional para o produto:
///
/// **Forma.** Cada espécie tem silhueta própria, desenhada com `Path` e curvas
/// de Bézier, em camadas de anatomia — corpo, barriga, membros, cauda, cabeça,
/// orelhas, focinho, olhos. A versão anterior empilhava retângulos
/// arredondados: a lontra era uma barra com uma bola em cima, e os tufos da
/// coruja flutuavam soltos, desencaixados da cabeça.
///
/// **Movimento.** Um rig simples ([_Pose]) calcula o deslocamento de cada
/// parte a cada quadro. O bicho respira, pisca — às vezes duas vezes seguidas
/// —, mexe as orelhas, balança a cauda, rema quando nada, mastiga quando
/// pasta, e **olha para onde você tocou**.
///
/// **Atividade.** Além do contínuo, cada atividade tem um laço próprio
/// ([_ciclo]): a braçada, a batida de asa, a mastigada, o salto. O contínuo
/// diz que ele está vivo; o laço diz o que ele está fazendo. Eram a mesma
/// coisa antes, e por isso "nadando" e "parado" saíam quase idênticos na
/// tela — o corpo só boiava mais forte.
///
/// Com "reduzir movimento" ligado o contínuo e o laço param e a pose fica
/// neutra, mas o toque continua respondendo, com amplitude menor. A pose
/// neutra de cada atividade continua sendo diferente das outras: quem pediu
/// menos movimento perde a animação, não a informação.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../data/crescimento.dart';
import '../models.dart';
import '../services/som_service.dart';
import '../theme.dart';
import 'comida.dart';
import 'vida/deformador.dart';
import 'vida/motor_de_vida.dart';

/// Um gesto de ocioso: o que o bicho faz quando ninguém está pedindo nada.
///
/// Sem isso o repouso é só a respiração em laço, e laço curto o olho pega em
/// segundos — passa a impressão de sprite, não de bicho.
enum GestoOcioso {
  nenhum,
  espreguica,
  sacode,
  olhaEmVolta,
  coca,
  fareja,
  saltinho,
}

/// O que a espécie **de fato** faz quando a cena pede uma atividade.
///
/// [Activity] nasce do humor (`state.dart`) e é a mesma para as oito
/// espécies. Isso basta para "está descansando" e não basta para "está
/// nadando": coruja não nada, pinguim não pasta, gata não entra na água.
/// Aqui a atividade pedida vira a ação daquele bicho — e é a ação que o
/// desenho **e a legenda** seguem. Se a tela diz que ele está voando, ele
/// tem de estar voando.
///
/// A alternativa descartada foi acrescentar valores a [Activity]: ela é
/// persistida indiretamente pelo humor e lida por `habitat.dart` e
/// `state.dart`, arquivos de outra frente. A tradução mora aqui, onde o
/// desenho está, e nada mais no app precisa saber dela.
enum AcaoDoBicho {
  /// À toa, no chão, sem tarefa.
  ocioso,

  /// Dormindo.
  cochilo,

  /// Nadando de verdade, com o corpo na linha d'água.
  nado,

  /// Voando: só a coruja.
  voo,

  /// Pastando: cabeça no chão, mastiga embaixo.
  pasto,

  /// Petiscando: pega no chão e mastiga com a cabeça erguida.
  petisco,

  /// Brincando na beira: agacha, salta, cai.
  brincadeira,
}

/// Traduz a atividade da cena para o que **esta** espécie faz.
///
/// As decisões, uma a uma:
///
/// - **Nada:** capivara, lontra, pinguim, axolote e tartaruga. A tartaruga do
///   app é de orelha vermelha (a listra está desenhada em `_tartaruga`), que
///   é aquática — ela nada tanto quanto a lontra.
/// - **Coruja no lugar do nado: voa.** É o que o dono do produto pediu em
///   palavras — "está falando que ele está voando? tem que estar voando".
/// - **Gata e raposa no lugar do nado: brincam.** Nenhuma das duas entra na
///   água por vontade própria. Desenhá-las nadando seria bonito e falso; o
///   salto na beira entrega a mesma energia da atividade de humor radiante.
/// - **Pasta:** capivara e tartaruga, as duas herbívoras de pastagem. As
///   outras sete **petiscam**: a lontra abre um molusco, o pinguim engole um
///   peixe, a coruja come no poleiro, a gata e a raposa comem o que
///   caçaram, o buldogue come o que lhe serviram, o axolote suga do fundo.
///   Mecanicamente é o mesmo laço; o que muda é onde a mastigação acontece —
///   no chão ou com a cabeça erguida.
AcaoDoBicho acaoDoBicho(Species especie, Activity atividade) {
  // O axolote é inteiramente aquático: nunca sai da água (ADW, SDZ;
  // pesquisa 22). Come, espera e brinca nadando; só o sono é à parte.
  if (especie == Species.axolotl && atividade != Activity.nap) {
    return AcaoDoBicho.nado;
  }
  switch (atividade) {
    case Activity.nap:
      return AcaoDoBicho.cochilo;
    case Activity.idle:
      return AcaoDoBicho.ocioso;
    case Activity.swim:
      switch (especie) {
        case Species.capybara:
        case Species.otter:
        case Species.penguin:
        case Species.axolotl:
        case Species.tortoise:
          return AcaoDoBicho.nado;
        // A coruja-buraqueira é de chão: corre, salta e caça no capim, e
        // não paira sobre a água (laudo 07, R4).
        case Species.owl:
          return AcaoDoBicho.brincadeira;
        case Species.cat:
        case Species.fox:
        // Buldogue francês **não nada**, e não é opinião: focinho achatado,
        // tronco denso e patas curtas fazem o cão braquicefálico afundar de
        // frente. Criador nenhum solta um sem colete. Desenhá-lo nadando
        // seria bonito e falso — ele brinca na beira, como a gata e a
        // raposa.
        case Species.frenchie:
          return AcaoDoBicho.brincadeira;
      }
    case Activity.graze:
      switch (especie) {
        case Species.capybara:
        case Species.tortoise:
          return AcaoDoBicho.pasto;
        case Species.otter:
        case Species.owl:
        case Species.axolotl:
        case Species.penguin:
        case Species.cat:
        case Species.fox:
        case Species.frenchie:
          return AcaoDoBicho.petisco;
      }
  }
}

/// Quem mergulha em vez de boiar.
///
/// Capivara e tartaruga nadam com o dorso fora da água e a cabeça alta — o
/// corpo é o flutuador. Lontra, pinguim e axolote são torpedos: afundam
/// menos o corpo e mais a linha do dorso, e o que os move é a ondulação,
/// não a remada das patas. Desenhar os cinco iguais faria a lontra parecer
/// uma capivara de outra cor.
bool _mergulhador(Species especie) =>
    especie == Species.otter ||
    especie == Species.penguin ||
    especie == Species.axolotl;

/// O jeito de cada espécie se deslocar e perseguir: o tipo de passo e a
/// cadência (laudo 34 R3), a cauda à toa (MOV-16) e a espreita do bote
/// (pesquisa 20, mecânica 9: o cão corre direto; o gato encara, rebola e
/// dá o bote; a tartaruga vai no tempo dela). É a tabela única que o app e
/// as folhas da série usam.
JeitoDeCacar jeitoDaEspecie(Species especie) => switch (especie) {
  Species.cat => const JeitoDeCacar(
    espreita: 0.8,
    velocidade: 50,
    locomocao: Locomocao.saltito,
    passosPorSegundo: 2.0,
    passosCorrendo: 4.0,
    // Parada, varredura lenta e preguiçosa; o chicote é irritação.
    cauda: JeitoDaCauda(frequencia: 0.3, amplitude: 0.08, f: 1.5, zeta: 0.65),
  ),
  Species.fox => const JeitoDeCacar(
    espreita: 0.8,
    velocidade: 50,
    locomocao: Locomocao.saltito,
    passosPorSegundo: 2.2,
    passosCorrendo: 4.0,
    cauda: JeitoDaCauda(frequencia: 0.5, amplitude: 0.15, f: 2, zeta: 0.5),
  ),
  Species.owl => const JeitoDeCacar(
    espreita: 0.4,
    velocidade: 46,
    locomocao: Locomocao.saltinhos,
    passosPorSegundo: 2.5,
    passosCorrendo: 4.0,
  ),
  Species.tortoise => const JeitoDeCacar(
    velocidade: 12,
    locomocao: Locomocao.arrasto,
    passosPorSegundo: 0.6,
    passosCorrendo: 1.0,
  ),
  Species.penguin => const JeitoDeCacar(
    velocidade: 30,
    locomocao: Locomocao.gingado,
    passosPorSegundo: 1.8,
    passosCorrendo: 2.5,
  ),
  Species.frenchie => const JeitoDeCacar(
    velocidade: 58,
    locomocao: Locomocao.bamboleio,
    passosPorSegundo: 2.0,
    passosCorrendo: 3.0,
    // O cão abana em rajadas quando feliz; parado, quase nada.
    cauda: JeitoDaCauda(frequencia: 0.6, amplitude: 0.1, f: 4, zeta: 0.4),
  ),
  Species.otter => const JeitoDeCacar(
    velocidade: 58,
    locomocao: Locomocao.saltito,
    passosPorSegundo: 2.4,
    passosCorrendo: 4.0,
    cauda: JeitoDaCauda(frequencia: 0.5, amplitude: 0.2, f: 2.5, zeta: 0.4),
  ),
  Species.capybara => const JeitoDeCacar(
    locomocao: Locomocao.galopePesado,
    passosPorSegundo: 2.0,
    passosCorrendo: 3.5,
  ),
  Species.axolotl => const JeitoDeCacar(
    locomocao: Locomocao.ondulacao,
    passosPorSegundo: 0.8,
    passosCorrendo: 1.2,
    cauda: JeitoDaCauda(frequencia: 0.5, amplitude: 0.2, f: 2, zeta: 0.4),
  ),
};

/// As marcações de pelagem do buldogue francês.
///
/// Só esta espécie tem: nas outras oito a paleta é uma escada de tons do
/// mesmo pelo, e trocar de índice é trocar de intensidade. No buldogue as
/// entradas são pelos de registro diferentes — fulvo, tigrado, pied — e cada
/// um vem com um desenho junto. Ignorar isso deixava as seis opções da loja
/// sendo o mesmo cão em seis tintas.
enum _MarcaDoBuldogue {
  /// Fulvo: a frente da cara escura, subindo em dois lobos até os olhos.
  mascara,

  /// Pied: peito, patas e uma faixa no meio da cara em branco.
  pied,

  /// Tigrado: listras verticais no corpo e na cabeça.
  tigrado,

  /// Blue e preto: pelo liso. É o que o padrão da raça dá para eles.
  solida,
}

// --- ritmos das atividades ---------------------------------------------
//
// Ficam aqui, e não em `design/motion.dart`, pelo mesmo motivo dos outros
// tempos deste arquivo: são cadências de anatomia, não de interface. Cada
// número é a resposta a um defeito visto na tela, anotado ao lado.

/// Uma braçada. Mais lento não lê como nado, lê como boia à deriva.
const _cicloDoNado = Duration(milliseconds: 1150);

/// Uma batida de asa. Curta: asa lenta é planeio, e planeio parece parado.
const _cicloDoVoo = Duration(milliseconds: 820);

/// Abaixa, mastiga, levanta, olha em volta. Longo de propósito — é um
/// ritmo, não um tique. Abaixo de uns 4 s vira mordida nervosa.
const _cicloDoPasto = Duration(milliseconds: 5600);

/// Agacha, salta, cai, assenta.
const _cicloDaBrincadeira = Duration(milliseconds: 1900);

/// À toa: a troca de apoio de pé. Lento a ponto de não se notar de propósito
/// — o que se nota é a ausência dela.
const _cicloDoOcio = Duration(milliseconds: 7400);

/// Dormindo, o laço só carrega a folha que desceu nele.
const _cicloDoSono = Duration(milliseconds: 13000);

/// Respiração de quem dorme: quase o dobro do período normal, e mais funda.
const _respiracaoDormindo = Duration(milliseconds: 6400);

/// Respiração de quem está se esforçando — nadando, voando, brincando.
const _respiracaoNoEsforco = Duration(milliseconds: 2200);

/// As pontas da pálpebra e da sobrancelha de um olho, no espaço da cabeça.
///
/// "Dentro" é a ponta virada para o meio da cara (x = 0). Na tristeza a
/// ponta de dentro fica **acima** da de fora nos dois olhos — espelhado. Era
/// essa a regra quebrada que fazia a saudade ler como raiva; o teste
/// `test/humor_geometria_test.dart` a trava.
@visibleForTesting
({
  Offset palpebraDentro,
  Offset palpebraFora,
  Offset sobrancelhaDentro,
  Offset sobrancelhaFora,
})
geometriaDoOlho(Offset o, double r, {required bool triste}) {
  final dentro = o.dx < 0 ? 1.0 : -1.0;
  // Neutro: só um toque de peso (−0,78·r). A 0,42·r a pálpebra cortava a
  // íris e o neutro lia como tédio ou desdém (MEL-08, LUME-10).
  // A sobrancelha da saudade encosta na pálpebra caída (TOCO-18): a 1,85·r
  // ela flutuava quase no topo da cabeça, solta do olho.
  return (
    palpebraDentro: Offset(
      o.dx + dentro * r * 1.05,
      o.dy - r * (triste ? 1.0 : 0.78),
    ),
    palpebraFora: Offset(
      o.dx - dentro * r * 1.05,
      o.dy - r * (triste ? 0.52 : 0.78),
    ),
    sobrancelhaDentro: o + Offset(dentro * r * 0.35, -r * 1.30),
    sobrancelhaFora: o + Offset(-dentro * r * 0.95, -r * 0.90),
  );
}

/// A íris da espécie (laudo 33, R1): disco escuro, fenda vertical da gata
/// sobre íris âmbar, ou oval da raposa.
enum EstiloDoOlho { redondo, fenda, oval }

/// A ação da espécie, corrigida pelo estágio de vida.
///
/// No ovo e no ninho não há atividade: ovo não nada e recém-nascido não
/// pasta. O ninho dorme; o ovo fica. E filhote não voa: a corujinha ainda
/// não tem pena de voo — onde a adulta voaria, ela fica no poleiro.
///
/// Pública porque a tela da sessão escreve o que o bicho está fazendo, e o
/// texto tem de bater com o desenho ("Nina está voando" num ovo era o que
/// a auditoria da Onda 2 achou).
AcaoDoBicho acaoNoEstagio(
  Species especie,
  Activity atividade,
  EstagioDoBicho estagio,
) {
  if (estagio == EstagioDoBicho.inicio) {
    return Crescimento.botaOvo(especie)
        ? AcaoDoBicho.ocioso
        : AcaoDoBicho.cochilo;
  }
  final acao = acaoDoBicho(especie, atividade);
  if (acao == AcaoDoBicho.voo && estagio == EstagioDoBicho.filhote) {
    return AcaoDoBicho.ocioso;
  }
  return acao;
}

class PetView extends StatefulWidget {
  const PetView({
    super.key,
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
    this.scale = 1,
    this.width = 200,
    this.height = 150,
    this.alignment = Alignment.center,
    this.interativo = true,
    this.aoCarinho,
    this.roupas = const {},
    this.roupaDeCabeca,
    this.quadro,
    this.estagio = EstagioDoBicho.adulto,
    this.olharExterno,
    this.cutucadas,
    this.areaDeAndar = 0,
    this.sombra = false,
    this.corDaAgua,
    this.interesse,
    this.aoAlcancar,
    this.ausenciaAoAbrir,
    this.comemora = false,
    this.aoMudarDeLugar,
    this.limites,
    this.destino,
    this.chamadoPelaAgua = false,
    this.naAgua = false,
    this.posicao,
    this.topoNaTela,
  });

  /// No mundo da home: onde ele pode andar agora (terra ou lagoa) e onde o
  /// momento pede que ele esteja, em unidades do desenho relativas ao
  /// centro da caixa. Ver `MotorDeVida.limiteEsquerdo` e `destino`.
  final (double, double)? limites;
  final (double, double)? destino;

  /// O humor pede nadar: chegando à beira, ele entra.
  final bool chamadoPelaAgua;

  /// Está na água agora (no mundo da home). É o que diz se a beira chama
  /// para entrar ou para sair — o modo não diz: dormindo na água o modo é
  /// "dormir", e ele pulava na água em que já estava.
  final bool naAgua;

  /// Escrito a cada quadro: onde ele está (unidades), para a câmera do
  /// mundo e a zona.
  final ValueNotifier<double>? posicao;

  /// Escrito a cada quadro: o alto da cabeça dele, em coordenadas globais.
  /// É onde o balão de fala da home para, sem cobrir o rosto, pule ou voe
  /// ele, na terra ou na água, do tamanho que estiver.
  final ValueNotifier<Offset?>? topoNaTela;

  /// Ele quer ir para a água (true) ou para a margem (false), por conta
  /// própria. Nulo: não troca de lugar (fora da home, ou quem não nada).
  final void Function(bool agua)? aoMudarDeLugar;

  /// Quanto tempo a pessoa ficou fora, para a saudação da primeira vez que
  /// ele aparece no processo (ver `MotorDeVida.saudacao`). Nulo: não saúda.
  /// A volta do app em segundo plano ele mede sozinho.
  final Duration? ausenciaAoAbrir;

  /// Está comemorando (a tela de resultado de uma sessão concluída): festeja
  /// ao aparecer e de novo de tempos em tempos.
  final bool comemora;

  /// Para as capturas da novelinha: chamado ao desenhar a boca (ou o bico),
  /// com a transformação do canvas naquele instante e a origem e a largura
  /// da boca no espaço local da cabeça. É a âncora da camada de boca: a
  /// série desenha o corpo uma vez e troca só a boca, por cima, no lugar
  /// certo de cada quadro. Nulo fora das capturas.
  static void Function(
    Float64List transformacao,
    Offset origem,
    double largura,
  )?
  aoDesenharBoca;

  /// Já saudou nesta abertura do app: a home remontada não festeja de novo.
  @visibleForTesting
  static bool saudouNaAbertura = false;

  /// Quando o app foi para o fundo, para medir a ausência na volta.
  static DateTime? _saiuEm;

  /// A bolinha ou o petisco da cena, em unidades do desenho relativas ao
  /// ponto de repouso do corpo. Ele olha, quer, persegue (com [areaDeAndar]).
  final ValueListenable<InteresseDoBicho?>? interesse;

  /// Chegou no [interesse]: a cena chuta a bola ou tira o petisco que ele
  /// está comendo. [xDoBicho] é onde ele está, nas mesmas unidades.
  final void Function(TipoDeInteresse tipo, double xDoBicho)? aoAlcancar;

  /// Quanto ele pode passear para cada lado, em unidades do desenho. Com
  /// mais que zero ele anda pelo habitat sozinho, em pulinhos, e pode ser
  /// carregado para outro lugar. A caixa [width] precisa ter essa folga.
  final double areaDeAndar;

  /// Sombra no chão, embaixo dele, que encolhe quando ele pula ou é
  /// carregado. O habitat desenhava uma fixa no centro; com o bicho andando
  /// ela tem de ir junto.
  final bool sombra;

  /// A cor da lagoa do mundo: o corpo debaixo d'água some nela, mais quanto
  /// mais fundo. Nula: o tom fixo de antes (o cartão do habitat).
  final Color? corDaAgua;

  /// Para onde ele olha, mandado de fora (-1..1 nos dois eixos): o dedo
  /// passeando pela cena da sessão, longe dele, e ele acompanhando.
  final Offset? olharExterno;

  /// Cada vez que muda, ele reage como a um toque — o pulinho, a orelha.
  /// Para a cena reagir a um toque que caiu fora do bicho.
  final ValueListenable<int>? cutucadas;

  final Species species;
  final Mood mood;
  final Activity activity;
  final int coat;
  final double scale;
  final double width;
  final double height;
  final Alignment alignment;

  /// Responde ao toque. Desligado em miniaturas e capturas.
  final bool interativo;

  /// Um afago completo: o dedo percorreu o bicho até ele ficar satisfeito.
  /// Dispara uma vez por gesto.
  final VoidCallback? aoCarinho;

  /// O que ele está vestindo, por lugar do corpo.
  final Map<Vestimenta, Color> roupas;

  /// O id da peça de cabeça, que muda o desenho.
  final String? roupaDeCabeca;

  /// Um quadro parado, para rasterizar o bicho fora da tela.
  ///
  /// Com ele o bicho não liga relógio nenhum: nada de `repeat`, nada de
  /// piscar agendado. É o que a sobreposição usa para levar o desenho real
  /// para o Android, quadro a quadro (ver `QuadrosDoBicho`).
  final QuadroFixo? quadro;

  /// Em que ponto da vida o bicho está (`Crescimento`).
  ///
  /// Adulto por padrão: é o desenho de vitrine — o seletor de espécie, a
  /// loja, o paywall mostram a espécie como ela é. Só o bicho **da pessoa**
  /// passa o estágio dele.
  final EstagioDoBicho estagio;

  /// Quanto o dedo precisa percorrer para encher a satisfação.
  ///
  /// Curto demais e o carinho vira um toque; longo demais e ninguém chega ao
  /// fim. 520 px é da ordem de três passadas no corpo inteiro.
  static const percursoDoAfago = 520.0;

  /// A cada tanto de percurso, um clique — o ronronar.
  static const passoDoRonrom = 26.0;

  /// Chave da camada que o teste captura para provar que o desenho mudou.
  static const cenaKey = Key('pet-cena');

  /// Onde a lâmina d'água cruza o quadro do bicho, para uma dada altura.
  ///
  /// Público porque quem desenha água atrás dele precisa desenhar **na mesma
  /// linha**: duas lâminas em alturas diferentes leem como defeito, não como
  /// cena. Sai da posição do corpo (`altura/2 + 10`) mais os 2 px que o
  /// painter usa — ver a nota em `_PetPainter.paint`.
  static double linhaDaguaEm(double altura) => altura / 2 + 12;

  /// Espelha o gesto de ocioso em curso, para o teste poder afirmar que ele
  /// aconteceu. Nulo em produção — o gesto é sorteado por um `Timer` e não há
  /// como observá-lo de fora sem esta costura.
  @visibleForTesting
  static ValueNotifier<GestoOcioso>? observadorDeGesto;

  /// Fixa qual gesto será sorteado. Nulo em produção — existe porque uma
  /// captura de evidência do bocejo não pode depender de um dado de três
  /// faces cair no lado certo.
  @visibleForTesting
  static GestoOcioso? gestoForcado;

  /// Onde está o corpo do bicho que passeia, em coordenadas globais. Nulo
  /// em produção — o teste precisa tocar nele depois que ele andou.
  @visibleForTesting
  static ValueNotifier<Offset?>? observadorDoCentro;

  /// Onde o rastro do afago está sendo desenhado, levado de volta para a
  /// caixa do gesto. Nulo em produção — o teste confere que ele cai
  /// embaixo do dedo, em qualquer escala.
  @visibleForTesting
  static ValueNotifier<Offset?>? observadorDoDedo;

  /// O episódio do motor de vida a cada quadro. Nulo em produção — existe
  /// para a filmagem de revisão recortar cada comportamento (pesquisa 24).
  @visibleForTesting
  static ValueNotifier<String>? observadorDeEpisodio;

  @override
  State<PetView> createState() => _PetViewState();
}

class _PetViewState extends State<PetView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _respiro = AnimationController(
    vsync: this,
    duration: Tempo.respiracao,
  );

  /// Período diferente do da respiração de propósito: se os dois ciclos
  /// batessem, o movimento pareceria mecânico.
  late final AnimationController _flutua = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4700),
  );

  /// A cauda tem ritmo próprio, mais solto.
  late final AnimationController _cauda = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  /// O laço da atividade: uma volta completa do que ele está fazendo.
  ///
  /// `repeat()` **sem** `reverse`, ao contrário dos outros três. Uma braçada
  /// não é simétrica: a pata puxa e volta por caminhos diferentes, e a
  /// pastagem é abaixa → mastiga → levanta → olha, que de trás para a frente
  /// vira outra coisa. Com `reverse` o bicho desmastigava.
  late final AnimationController _ciclo = AnimationController(
    vsync: this,
    duration: _cicloDoOcio,
  );

  late final AnimationController _pisca = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 170),
  );

  /// Orelha treme rápido e volta.
  late final AnimationController _orelha = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    animationBehavior: AnimationBehavior.preserve,
  );

  /// `preserve` de propósito: com "reduzir movimento" o Flutter encurta a
  /// duração de um controller para 5% — a reação ao toque acabaria antes de
  /// ser vista. Amplitude a gente reduz; o feedback fica.
  late final AnimationController _toque = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Gesto de ocioso: espreguiçar, sacudir a cabeça, olhar em volta.
  late final AnimationController _gesto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
    animationBehavior: AnimationBehavior.preserve,
  );

  final _sorte = math.Random();

  /// O motor de vida: respiração, boia, cauda, olhar, passeio, colo — tudo
  /// que antes era laço de período fixo (ver `vida/motor_de_vida.dart`).
  late final MotorDeVida _vida =
      MotorDeVida(
          // Cada bicho tem a sua: zonas de carinho e jeito próprios, estáveis.
          semente: widget.species.index * 7919 + widget.coat * 31 + 1,
          areaDeAndar: widget.areaDeAndar,
        )
        ..aoEvento = _eventoDaVida
        ..aoAlcancar = _alcancou;

  /// Comendo o petisco: de 0 a 1 ao longo da mastigação; -1 sem comer.
  double _comendo = -1;
  static const _tempoDeComer = 2.4;

  void _alcancou(TipoDeInteresse tipo) {
    if (!mounted) return;
    if (tipo == TipoDeInteresse.comida) {
      _comendo = 0;
      HapticFeedback.lightImpact();
    }
    widget.aoAlcancar?.call(tipo, _vida.xAtual);
  }

  /// O motor pede um gesto da coreografia (sacudir ao cair do colo, depois
  /// de um espirro; espreguiçar ao sair do descanso; coçar).
  void _eventoDaVida(EventoDaVida e) {
    if (!mounted || !_continuoLigado) return;
    // Ir para a água ou sair dela: quem decide o lugar é a cena.
    if (e == EventoDaVida.querAgua || e == EventoDaVida.querTerra) {
      widget.aoMudarDeLugar?.call(e == EventoDaVida.querAgua);
      return;
    }
    // A orelha é independente do resto: mexe vigiando, mexe sonhando.
    if (e == EventoDaVida.orelha) {
      if (!_orelha.isAnimating) {
        _orelha.forward(from: 0).then((_) {
          if (mounted) _orelha.value = 0;
        });
      }
      return;
    }
    if (_gestoAtual != GestoOcioso.nenhum) return;
    if (_acaoDesenhada != AcaoDoBicho.ocioso &&
        e != EventoDaVida.sacode &&
        e != EventoDaVida.fareja) {
      return;
    }
    final gesto = switch (e) {
      EventoDaVida.sacode => GestoOcioso.sacode,
      EventoDaVida.espreguica => GestoOcioso.espreguica,
      EventoDaVida.coca => GestoOcioso.coca,
      EventoDaVida.fareja => GestoOcioso.fareja,
      EventoDaVida.orelha ||
      EventoDaVida.querAgua ||
      EventoDaVida.querTerra => GestoOcioso.nenhum,
    };
    setState(() => _gestoAtual = gesto);
    PetView.observadorDeGesto?.value = gesto;
    _gesto.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _gestoAtual = GestoOcioso.nenhum);
      PetView.observadorDeGesto?.value = GestoOcioso.nenhum;
    });
  }

  late final Ticker _relogio = createTicker(_tique);
  Duration _ultimoTique = Duration.zero;
  final _quadroDaVida = ValueNotifier<SaidaDaVida>(const SaidaDaVida());

  void _tique(Duration agora) {
    final dt = (agora - _ultimoTique).inMicroseconds / 1e6;
    _ultimoTique = agora;
    _acordaPeloBrinquedo(dt);
    final acao = _acao;
    if (_comendo >= 0) {
      _comendo += dt / _tempoDeComer;
      if (_comendo >= 1) {
        _comendo = -1;
        _vida.comeu();
      }
    }
    _vida
      // A cabeça do motor segue tudo que o olho segue: o dedo, o toque, o
      // gesto de olhar em volta. Antes isso ia só para as pupilas, e a
      // cabeça ficava para trás.
      ..energia = switch (widget.mood) {
        Mood.radiant => 1.0,
        Mood.content => 0.6,
        Mood.neutral => 0.4,
        Mood.missingYou => 0.3,
        Mood.sleepy => 0.15,
      }
      ..olharDeFora = _dedo != null || _toque.isAnimating
          ? _olhar
          : _gestoAtual == GestoOcioso.olhaEmVolta
          ? Offset(math.sin(_gesto.value * math.pi * 2), -0.12)
          : widget.olharExterno
      ..interesse = _comendo >= 0 ? null : widget.interesse?.value
      // Dormindo ou voando o corpo é da atividade; o resto deixa ele viver.
      ..ocupado =
          acao == AcaoDoBicho.cochilo ||
          acao == AcaoDoBicho.voo ||
          _comendo >= 0
      ..modo = switch (acao) {
        AcaoDoBicho.pasto => ModoDaAtividade.pastar,
        AcaoDoBicho.petisco => ModoDaAtividade.petiscar,
        AcaoDoBicho.nado => ModoDaAtividade.nadar,
        AcaoDoBicho.brincadeira => ModoDaAtividade.brincar,
        // O recém-nascido no ninho só dorme: sem sonho nem virar de lado.
        AcaoDoBicho.cochilo =>
          widget.estagio == EstagioDoBicho.inicio
              ? ModoDaAtividade.livre
              : ModoDaAtividade.dormir,
        _ => ModoDaAtividade.livre,
      }
      ..trocaDeLugar = widget.aoMudarDeLugar != null
      ..limiteEsquerdo = widget.limites?.$1
      ..limiteDireito = widget.limites?.$2
      ..destino = widget.destino
      ..chamadoPelaAgua = widget.chamadoPelaAgua
      ..naAgua = widget.naAgua
      ..dormindo = acao == AcaoDoBicho.cochilo
      ..sonolento = widget.mood == Mood.sleepy
      // A coruja dorme empoleirada, de pé; o pinguim, meio deitado.
      ..deitaDormindo = switch (widget.species) {
        Species.owl => 0.0,
        Species.penguin => 0.55,
        Species.axolotl => 0.3,
        _ => 1.0,
      }
      ..nadando = acao == AcaoDoBicho.nado
      ..posturaLivre = _acaoDesenhada == AcaoDoBicho.ocioso
      ..podeAndar =
          widget.interativo &&
          (acao == AcaoDoBicho.ocioso ||
              acao == AcaoDoBicho.pasto ||
              acao == AcaoDoBicho.petisco ||
              acao == AcaoDoBicho.nado ||
              acao == AcaoDoBicho.brincadeira);
    _quadroDaVida.value = _vida.passo(dt);
    PetView.observadorDeEpisodio?.value = _vida.episodio.name;
    widget.posicao?.value = _vida.posicao;
    final topo = widget.topoNaTela;
    if (topo != null) {
      final caixa = context.findRenderObject();
      if (caixa is RenderBox && caixa.hasSize && caixa.attached) {
        // Os pés ficam 60 unidades abaixo do centro do corpo, e o alto da
        // cabeça, até ~140 acima deles no adulto (medido nas nove espécies:
        // 124 a 141), no porte do estágio.
        final porte = switch (widget.estagio) {
          EstagioDoBicho.inicio => 0.52,
          EstagioDoBicho.filhote => 0.63,
          EstagioDoBicho.jovem => 0.80 * 1.14,
          EstagioDoBicho.adulto || EstagioDoBicho.pleno => 1.0,
        };
        topo.value = caixa.localToGlobal(
          _naTela(
            _repouso +
                _quadroDaVida.value.desloca +
                Offset(0, 60 - 140 * porte),
          ),
        );
      }
    }
    final observador = PetView.observadorDoCentro;
    if (observador != null && widget.areaDeAndar > 0) {
      final caixa = context.findRenderObject();
      if (caixa is RenderBox && caixa.hasSize) {
        observador.value = caixa.localToGlobal(_centroNaTela);
      }
    }
  }

  Timer? _proximoPiscar;
  Timer? _proximaOrelha;
  Timer? _proximoGesto;
  GestoOcioso _gestoAtual = GestoOcioso.nenhum;
  bool _continuoLigado = false;

  /// Para onde o bicho está olhando, de -1 a 1 em cada eixo.
  Offset _olhar = Offset.zero;
  Timer? _voltaAOlharPraFrente;

  /// Toques seguidos: a partir do terceiro ele se anima de verdade.
  int _toquesSeguidos = 0;
  Timer? _esfriaToques;

  /// A troca de humor: o desenho antigo esmaece enquanto o novo aparece.
  /// Trocar de cara num quadro só parecia um corte de edição.
  late final AnimationController _transicao = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  Mood? _humorAnterior;

  /// O quanto ele está gostando **agora**. Sobe com o dedo andando em cima
  /// dele e desce sozinho quando o dedo sai.
  late final AnimationController _gosto = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Onde o dedo está durante o afago, em coordenadas do widget.
  Offset? _dedo;
  double _percorrido = 0;
  double _desdeORonrom = 0;
  bool _afagoCreditado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.cutucadas?.addListener(_cutucado);
  }

  /// Uma reação de toque sem toque nele: a cena foi tocada e ele percebeu.
  void _cutucado() {
    if (!mounted || widget.quadro != null) return;
    if (_gestoAtual != GestoOcioso.nenhum) {
      _gesto.stop();
      _gestoAtual = GestoOcioso.nenhum;
      PetView.observadorDeGesto?.value = GestoOcioso.nenhum;
    }
    _toque.forward(from: 0);
    if (!_orelha.isAnimating) {
      _orelha.forward(from: 0).then((_) {
        if (mounted) _orelha.value = 0;
      });
    }
  }

  /// Bicho escondido não respira.
  ///
  /// Um `repeat()` pede quadro para sempre. Com o app fora da tela isso é
  /// bateria queimada à toa — e no Flutter web é o que segue pedindo quadro
  /// depois de a view morrer, virando "Trying to render a disposed
  /// EngineFlutterView".
  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (!mounted) return;
    switch (estado) {
      case AppLifecycleState.resumed:
        if (widget.quadro == null && !Movimento.reduzido(context)) {
          _iniciaContinuo();
          final saiu = PetView._saiuEm;
          if (saiu != null && _saudaveis) {
            PetView._saiuEm = null;
            final fora = DateTime.now().difference(saiu);
            if (fora.inMinutes >= 1) {
              _vida.saudacao(fora.inSeconds / 3600);
            }
          }
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_saudaveis) PetView._saiuEm ??= DateTime.now();
        _paraContinuo();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.quadro != null || Movimento.reduzido(context)) {
      _paraContinuo();
    } else {
      _iniciaContinuo();
    }
  }

  /// A atividade mudou debaixo do widget.
  ///
  /// Sem isto o bicho continuava com a cadência da atividade anterior:
  /// entrava na sessão de foco remando no compasso do ócio, sete segundos
  /// por braçada. `didChangeDependencies` não cobre — a dependência não
  /// mudou, o parâmetro é que mudou.
  @override
  void didUpdateWidget(PetView antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.cutucadas != widget.cutucadas) {
      antigo.cutucadas?.removeListener(_cutucado);
      widget.cutucadas?.addListener(_cutucado);
    }
    if (antigo.activity != widget.activity ||
        antigo.species != widget.species ||
        antigo.estagio != widget.estagio) {
      _ajustaRitmo();
    }
    if (antigo.mood != widget.mood &&
        widget.quadro == null &&
        !Movimento.reduzido(context)) {
      _humorAnterior = antigo.mood;
      _transicao.forward(from: 0);
    }
  }

  AcaoDoBicho get _acao {
    final a = acaoNoEstagio(widget.species, widget.activity, widget.estagio);
    // A bola ou a castanha acordam quem cochilava (o recém-nascido não).
    return a == AcaoDoBicho.cochilo && _acordado ? AcaoDoBicho.ocioso : a;
  }

  /// Acordado por um brinquedo: volta a dormir 20 s depois do último.
  bool _acordado = false;
  double _relogioS = 0;
  double _acordadoAte = -1;

  /// Toques no bicho que dorme: o primeiro só mexe a orelha; o segundo,
  /// em até 3 s, acorda devagar (pesquisa 20, mecânica 11).
  int _toquesNoSono = 0;
  double _ultimoToqueNoSono = -100;

  bool get _dormindoDeVerdade =>
      !_acordado &&
      widget.estagio != EstagioDoBicho.inicio &&
      acaoNoEstagio(widget.species, widget.activity, widget.estagio) ==
          AcaoDoBicho.cochilo;

  void _toqueNoSono() {
    if (_relogioS - _ultimoToqueNoSono > 3) _toquesNoSono = 0;
    _ultimoToqueNoSono = _relogioS;
    _toquesNoSono += 1;
    if (_toquesNoSono == 1) {
      HapticFeedback.selectionClick();
      if (!_orelha.isAnimating) {
        _orelha.forward(from: 0).then((_) {
          if (mounted) _orelha.value = 0;
        });
      }
      return;
    }
    _toquesNoSono = 0;
    HapticFeedback.lightImpact();
    _acordadoAte = _relogioS + 20;
    _vida.acordando();
  }

  double _proximaComemoracao = 0.6;

  /// Só o bicho que mora no habitat (anda e responde) saúda.
  bool get _saudaveis => widget.areaDeAndar > 0 && widget.interativo;

  void _acordaPeloBrinquedo(double dt) {
    _relogioS += dt;
    if (widget.comemora && _relogioS >= _proximaComemoracao) {
      _vida.comemora();
      _proximaComemoracao = _relogioS + 6.5;
    }
    final ausencia = widget.ausenciaAoAbrir;
    if (ausencia != null &&
        !PetView.saudouNaAbertura &&
        _saudaveis &&
        _relogioS > 0.8) {
      PetView.saudouNaAbertura = true;
      _vida.saudacao(ausencia.inSeconds / 3600);
    }
    if (widget.estagio != EstagioDoBicho.inicio &&
        widget.interesse?.value != null) {
      _acordadoAte = _relogioS + 20;
    }
    final agora = _relogioS < _acordadoAte;
    if (agora == _acordado) return;
    final dormia =
        acaoNoEstagio(widget.species, widget.activity, widget.estagio) ==
        AcaoDoBicho.cochilo;
    _acordado = agora;
    if (!dormia) return;
    _ajustaRitmo();
    if (agora) _eventoDaVida(EventoDaVida.espreguica);
  }

  /// O que o desenho mostra: a atividade, salvo quando o motor de vida tirou
  /// o bicho dela — andando em pulinhos, festejando, no colo — porque ninguém
  /// pasta de cabeça baixa enquanto pula de um lado a outro.
  AcaoDoBicho get _acaoDesenhada {
    final a = _acao;
    if (a == AcaoDoBicho.nado || a == AcaoDoBicho.cochilo) return a;
    if (_comendo >= 0) return AcaoDoBicho.petisco;
    final q = _quadroDaVida.value;
    if (q.voando) return AcaoDoBicho.voo;
    // Brincar agora é do motor (botes, disparadas, reverências, pulos): o
    // desenho fica no corpo livre. E na pausa entre os episódios de comer,
    // também: é ali que cabem o espreguiçar, o coçar, o farejar.
    if (q.atividadeAtiva &&
        (a == AcaoDoBicho.brincadeira ||
            ((a == AcaoDoBicho.pasto || a == AcaoDoBicho.petisco) &&
                q.corpoLivre))) {
      return AcaoDoBicho.ocioso;
    }
    if (_vida.noColo ||
        _vida.interessado ||
        _vida.intencao == IntencaoDoBicho.festejar ||
        (_vida.intencao == IntencaoDoBicho.passear && _vida.andando)) {
      return AcaoDoBicho.ocioso;
    }
    return a;
  }

  Duration get _duracaoDoCiclo => switch (_acao) {
    AcaoDoBicho.nado => _cicloDoNado,
    AcaoDoBicho.voo => _cicloDoVoo,
    AcaoDoBicho.pasto || AcaoDoBicho.petisco => _cicloDoPasto,
    AcaoDoBicho.brincadeira => _cicloDaBrincadeira,
    AcaoDoBicho.cochilo => _cicloDoSono,
    AcaoDoBicho.ocioso => _cicloDoOcio,
  };

  /// A respiração acompanha o esforço: funda e lenta no sono, curta e rápida
  /// na água. É o sinal mais barato de que a atividade mudou, e o primeiro
  /// que o olho lê mesmo sem prestar atenção.
  Duration get _duracaoDaRespiracao => switch (_acao) {
    AcaoDoBicho.cochilo => _respiracaoDormindo,
    AcaoDoBicho.nado ||
    AcaoDoBicho.voo ||
    AcaoDoBicho.brincadeira => _respiracaoNoEsforco,
    _ => Tempo.respiracao,
  };

  void _ajustaRitmo() {
    _vida
      ..periodoCiclo = _duracaoDoCiclo.inMicroseconds / 1e6
      // O controlador ia e voltava: o fôlego inteiro é o dobro.
      ..periodoRespiro = _duracaoDaRespiracao.inMicroseconds / 1e6 * 2
      ..areaDeAndar = widget.areaDeAndar;
  }

  void _iniciaContinuo() {
    if (_continuoLigado) return;
    _continuoLigado = true;
    _ajustaRitmo();
    _ultimoTique = Duration.zero;
    _vida
      ..hora = DateTime.now().hour
      // O cão corre direto; o gato encara, rebola e dá o bote (Miyamoto,
      // pesquisa 20, mec. 9); a tartaruga vai no tempo dela.
      ..jeito = jeitoDaEspecie(widget.species)
      // O que só esta espécie faz (etograma, pesquisa 22).
      ..repertorio = switch (widget.species) {
        Species.capybara => const {
          Episodio.deitar,
          Episodio.tomarSol,
          Episodio.espiar,
        },
        Species.otter => const {
          Episodio.comerNaAgua,
          Episodio.alisar,
          Episodio.rolar,
          Episodio.espiar,
        },
        Species.tortoise => const {
          Episodio.comerNaAgua,
          Episodio.recolher,
          Episodio.tomarSol,
          Episodio.espiar,
        },
        Species.owl => const {
          Episodio.voar,
          Episodio.balancarCabeca,
          Episodio.girarCabeca,
          Episodio.alisar,
        },
        Species.axolotl => const {Episodio.respirar, Episodio.comerNaAgua},
        Species.penguin => const {
          Episodio.comerNaAgua,
          Episodio.alisar,
          Episodio.microcochilo,
          Episodio.zurro,
          Episodio.saltoNaAgua,
          Episodio.espiar,
        },
        Species.cat => const {
          Episodio.piscadaLenta,
          Episodio.amassar,
          Episodio.alisar,
          Episodio.sonhoDePatinhas,
        },
        Species.fox => const {Episodio.escutar, Episodio.sonhoDePatinhas},
        Species.frenchie => const {
          Episodio.inclinarCabeca,
          Episodio.sonhoDePatinhas,
        },
      }
      // Felinos e a coruja piscam menos; o buldogue, mais.
      ..medianaDoPiscar = switch (widget.species) {
        Species.cat || Species.fox || Species.owl => 4.6,
        Species.frenchie => 3.0,
        _ => 3.6,
      }
      // A coruja nunca passa 3,2 s sem piscar: no laço de 4 s da série ela
      // ficava de olho aberto o tempo todo (NINA-17).
      ..maxIntervaloDoPiscar = widget.species == Species.owl ? 3.2 : 12.0;
    if (!_relogio.isActive) _relogio.start();
    // A piscada é do motor agora (log-normal, amarrada ao olhar); o
    // agendador antigo só serve ao quadro fixo.
    _agendaOrelha();
    _agendaGesto();
  }

  void _paraContinuo() {
    _continuoLigado = false;
    if (_relogio.isActive) _relogio.stop();
    _quadroDaVida.value = const SaidaDaVida();
    _proximoPiscar?.cancel();
    _proximaOrelha?.cancel();
    _proximoGesto?.cancel();
    _gestoAtual = GestoOcioso.nenhum;
    _gesto
      ..stop()
      ..value = 0;
    for (final c in [_respiro, _flutua, _cauda]) {
      c
        ..stop()
        ..value = 0.5;
    }
    // O laço para em zero, não no meio: fase 0 é a pose de repouso de cada
    // atividade — a folha já pousada no bicho que dorme, a cabeça erguida de
    // quem pasta, as patas paradas de quem nada. Congelar em 0.5 deixaria o
    // bicho de "reduzir movimento" com a boca aberta para sempre.
    _ciclo
      ..stop()
      ..value = 0;
    _pisca
      ..stop()
      ..value = 0;
    _orelha
      ..stop()
      ..value = 0;
  }

  void _agendaOrelha() {
    _proximaOrelha?.cancel();
    final espera = Duration(milliseconds: 3200 + _sorte.nextInt(7000));
    _proximaOrelha = Timer(espera, () async {
      if (!mounted || !_continuoLigado) return;
      await _orelha.forward(from: 0);
      if (!mounted) return;
      _orelha.value = 0;
      _agendaOrelha();
    });
  }

  /// Um gesto a cada 5–12 s, sorteado, e só quando ele está à toa.
  ///
  /// Nadando, pastando ou dormindo o corpo já tem o que fazer; empilhar um
  /// gesto por cima vira ruído.
  ///
  /// A espera encurtou junto com o repertório: com três gestos a cada 7–15 s
  /// dava para ficar meio minuto olhando e ver o mesmo bocejo duas vezes. Com
  /// seis e a janela mais curta, a repetição some no ruído.
  void _agendaGesto() {
    _proximoGesto?.cancel();
    final espera = Duration(milliseconds: 5000 + _sorte.nextInt(7000));
    _proximoGesto = Timer(espera, () async {
      if (!mounted || !_continuoLigado) return;
      if (_acaoDesenhada != AcaoDoBicho.ocioso ||
          _toque.isAnimating ||
          _vida.noColo ||
          _vida.intencao == IntencaoDoBicho.passear ||
          _vida.intencao == IntencaoDoBicho.festejar) {
        _agendaGesto();
        return;
      }
      const repertorio = [
        GestoOcioso.espreguica,
        GestoOcioso.sacode,
        GestoOcioso.olhaEmVolta,
        GestoOcioso.coca,
        GestoOcioso.fareja,
        GestoOcioso.saltinho,
      ];
      setState(() {
        _gestoAtual =
            PetView.gestoForcado ??
            repertorio[_sorte.nextInt(repertorio.length)];
      });
      PetView.observadorDeGesto?.value = _gestoAtual;
      await _gesto.forward(from: 0);
      if (!mounted) return;
      setState(() => _gestoAtual = GestoOcioso.nenhum);
      PetView.observadorDeGesto?.value = GestoOcioso.nenhum;
      _agendaGesto();
    });
  }

  void _reageAoToque(TapDownDetails detalhe) {
    if (!widget.interativo) return;
    if (_continuoLigado && _dormindoDeVerdade) {
      _toqueNoSono();
      return;
    }

    _toquesSeguidos += 1;
    _esfriaToques?.cancel();
    _esfriaToques = Timer(const Duration(seconds: 3), () {
      _toquesSeguidos = 0;
    });

    // Atenção repetida anima mais: do terceiro toque em diante a reação é
    // mais forte, como um bicho que percebe que estão brincando com ele.
    if (_toquesSeguidos >= 3) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    unawaited(SomService.instance.toca(SomDoBaru.toque));

    // O corpo reage com peso: cede no toque e volta, sem balançar.
    _vida.tocado(_relativoAoCorpo(detalhe.localPosition));

    // Olha para o dedo.
    setState(() => _olhar = _olharPara(detalhe.localPosition));
    _voltaAOlharPraFrente?.cancel();
    _voltaAOlharPraFrente = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _olhar = Offset.zero);
    });

    // O toque tem prioridade sobre o ocioso: um bicho que está sendo tocado
    // não continua se espreguiçando.
    if (_gestoAtual != GestoOcioso.nenhum) {
      _gesto.stop();
      _gestoAtual = GestoOcioso.nenhum;
      PetView.observadorDeGesto?.value = GestoOcioso.nenhum;
    }

    _toque.forward(from: 0);
    // Sem exigir o contínuo ligado: com "reduzir movimento" o tremor de
    // orelha é parte da resposta ao toque, e o §7 manda reduzir amplitude,
    // não apagar o retorno.
    if (!_orelha.isAnimating) {
      // `.forward` termina em 1.0 e fica lá. A orelha redonda disfarça
      // (`sin(2π) = 0`), mas o tufo da coruja é linear: sem este reset ele
      // ficava torto até o agendador rodar — até dez segundos depois.
      _orelha.forward(from: 0).then((_) {
        if (mounted) _orelha.value = 0;
      });
    }
  }

  // ======================================================================
  // ONDE ESTÁ O CORPO — o bicho anda, e o toque tem de achar ele
  // ======================================================================

  /// O tamanho de verdade: numa lista o bicho é esticado à largura dela, e
  /// o desenho (centrado) vai junto.
  Size get _caixa {
    final s = context.size;
    return s ?? Size(widget.width, widget.height);
  }

  /// O ponto de repouso do corpo, sem escala, na caixa do widget.
  Offset get _repouso => Offset(_caixa.width / 2, _caixa.height / 2 + 10);

  /// O ponto fixo do `Transform.scale` (o alinhamento), na caixa.
  Offset get _pivo => widget.alignment.alongSize(_caixa);

  /// Desenho → tela.
  Offset _naTela(Offset p) => _pivo + (p - _pivo) * widget.scale;

  /// Tela → desenho.
  Offset _noDesenho(Offset tela) => _pivo + (tela - _pivo) / widget.scale;

  /// O centro do corpo agora, na tela.
  Offset get _centroNaTela => _naTela(_repouso + _quadroDaVida.value.desloca);

  /// Um ponto da tela relativo ao corpo, -1..1 (o corpo tem ~70 de raio).
  Offset _relativoAoCorpo(Offset tela) {
    final d = (tela - _centroNaTela) / (70 * widget.scale);
    return Offset(d.dx.clamp(-1.5, 1.5), d.dy.clamp(-1.5, 1.5));
  }

  /// Para onde olhar, -1..1, a partir de um ponto da tela.
  Offset _olharPara(Offset tela) {
    final r = _relativoAoCorpo(tela);
    return Offset(r.dx.clamp(-1.0, 1.0), r.dy.clamp(-1.0, 1.0));
  }

  /// O toque só é dele se cair perto do corpo: com a caixa larga do
  /// passeio, o resto do habitat continua rolando a página.
  bool _tocaNoCorpo(Offset tela) {
    final d = tela - _centroNaTela;
    final rx = 82 * widget.scale, ry = 78 * widget.scale;
    return (d.dx * d.dx) / (rx * rx) + (d.dy * d.dy) / (ry * ry) <= 1;
  }

  // ======================================================================
  // COLO — pegar, carregar e soltar
  // ======================================================================

  bool _noColo = false;

  void _pega(LongPressStartDetails d) {
    if (!widget.interativo || widget.areaDeAndar <= 0) return;
    _gesto.stop();
    _gestoAtual = GestoOcioso.nenhum;
    final noDesenho = _noDesenho(d.localPosition) - _repouso;
    _vida.pegou(noDesenho - _quadroDaVida.value.desloca);
    _noColo = true;
    HapticFeedback.mediumImpact();
    unawaited(SomService.instance.toca(SomDoBaru.toque));
  }

  void _carrega(LongPressMoveUpdateDetails d) {
    if (!_noColo) return;
    _vida.carrega(_noDesenho(d.localPosition) - _repouso);
  }

  void _solta() {
    if (!_noColo) return;
    _noColo = false;
    _vida.soltou();
    HapticFeedback.lightImpact();
  }

  // ======================================================================
  // AFAGO — a mão passando, não o dedo cutucando
  // ======================================================================

  void _comecaAfago(DragStartDetails d) {
    if (!widget.interativo) return;
    _gesto.stop();
    _gestoAtual = GestoOcioso.nenhum;
    _percorrido = 0;
    _desdeORonrom = 0;
    _afagoCreditado = false;
    setState(() => _dedo = _noDesenho(d.localPosition));
    PetView.observadorDoDedo?.value = _naTela(_dedo!);
  }

  void _afaga(DragUpdateDetails d) {
    if (!widget.interativo) return;
    final andou = d.delta.distance;
    _percorrido += andou;
    _desdeORonrom += andou;

    // Ronronar: um clique curto a cada tanto de percurso. Por tempo ficaria
    // igual com o dedo parado — o que não é carinho, é dedo pousado.
    if (_desdeORonrom >= PetView.passoDoRonrom) {
      _desdeORonrom = 0;
      HapticFeedback.selectionClick();
    }

    _gosto.value = (_percorrido / PetView.percursoDoAfago).clamp(0.0, 1.0);
    _vida.afagado(_relativoAoCorpo(d.localPosition), d.delta * 60);

    if (_gosto.value >= 1 && !_afagoCreditado) {
      _afagoCreditado = true;
      HapticFeedback.mediumImpact();
      widget.aoCarinho?.call();
    }

    setState(() {
      // **No desenho, não na tela.** O gesto chega nas coordenadas da caixa
      // sem escala, e o pintor desenha dentro do `Transform.scale`: usar a
      // posição crua punha o rastro do afago longe do dedo — tanto mais
      // longe quanto maior a escala e mais afastado do pivô, e por isso
      // "pulando" de lugar de uma tela para outra.
      _dedo = _noDesenho(d.localPosition);
      // Ele acompanha a mão com o olhar — relativo ao corpo dele, não à
      // caixa, que no mundo é a largura inteira do passeio.
      _olhar = _olharPara(d.localPosition);
    });
    PetView.observadorDoDedo?.value = _naTela(_dedo!);
  }

  void _terminaAfago() {
    if (!widget.interativo) return;
    _vida.soltouAfago();
    setState(() => _dedo = null);
    PetView.observadorDoDedo?.value = null;
    // Desce sozinho: a satisfação não some no instante em que a mão sai.
    if (_gosto.value > 0) _gosto.reverse();
    _voltaAOlharPraFrente?.cancel();
    _voltaAOlharPraFrente = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _olhar = Offset.zero);
    });
  }

  @override
  void dispose() {
    widget.cutucadas?.removeListener(_cutucado);
    WidgetsBinding.instance.removeObserver(this);
    _proximoPiscar?.cancel();
    _proximaOrelha?.cancel();
    _proximoGesto?.cancel();
    _voltaAOlharPraFrente?.cancel();
    _esfriaToques?.cancel();
    _respiro.dispose();
    _flutua.dispose();
    _cauda.dispose();
    _ciclo.dispose();
    _pisca.dispose();
    _orelha.dispose();
    _toque.dispose();
    _gesto.dispose();
    _gosto.dispose();
    _transicao.dispose();
    _relogio.dispose();
    _quadroDaVida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amplitude = Movimento.reduzido(context) ? 0.25 : 1.0;

    final cena = RepaintBoundary(
      key: PetView.cenaKey,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _quadroDaVida,
          _pisca,
          _orelha,
          _toque,
          _gesto,
          _gosto,
          _transicao,
        ]),
        builder: (context, _) {
          final anterior = _humorAnterior;
          if (anterior != null && _transicao.isAnimating) {
            final t = Curves.easeInOut.transform(_transicao.value);
            // Alinhamento sem direção: o bicho também é desenhado fora do app
            // (widget da tela inicial, sobreposição), onde pode não haver
            // `Directionality`.
            //
            // Os dois desenhos têm o **mesmo** corpo, na postura do meio do
            // caminho; só o rosto difere. O de baixo fica opaco: esmaecer os
            // dois deixava o fundo vazar pelo bicho no meio da troca.
            Widget com(Mood rosto) => _pintado(
              rosto,
              amplitude,
              corpoDe: anterior,
              corpoPara: widget.mood,
              mistura: t,
            );
            return Stack(
              alignment: Alignment.topLeft,
              children: [
                com(anterior),
                Opacity(opacity: t, child: com(widget.mood)),
              ],
            );
          }
          return _pintado(widget.mood, amplitude);
        },
      ),
    );

    final corpo = Transform.scale(
      scale: widget.scale,
      alignment: widget.alignment,
      child: SizedBox(width: widget.width, height: widget.height, child: cena),
    );

    if (!widget.interativo) return corpo;
    return _comGestos(corpo);
  }

  /// O bicho num humor, com a pose deste quadro.
  Widget _pintado(
    Mood humor,
    double amplitude, {
    Mood? corpoDe,
    Mood? corpoPara,
    double mistura = 1,
  }) {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: _PetPainter(
        species: widget.species,
        mood: humor,
        corpoDe: corpoDe,
        corpoPara: corpoPara,
        mistura: mistura,
        activity: widget.activity,
        coat: AppColors.pelagemDe(widget.species, widget.coat),
        coatIndex: widget.coat,
        roupas: widget.roupas,
        roupaDeCabeca: widget.roupaDeCabeca,
        estagio: widget.estagio,
        pose:
            widget.quadro?._pose(_acao) ??
            _Pose(
              acao: _acaoDesenhada,
              // Cru, sem curva: o laço da atividade é uma fase que dá a
              // volta. Passá-lo por `easeInOut` como os contínuos criaria
              // um salto na emenda entre 1 e 0 — a braçada travava a cada
              // volta.
              // Comendo, o laço é o da mastigação: a janela de mastigar
              // do petisco (0,26–0,72) esticada nos 2,4 s.
              ciclo: _comendo >= 0
                  ? 0.27 + 0.44 * _comendo
                  : _quadroDaVida.value.atividadeAtiva &&
                        (_acaoDesenhada == AcaoDoBicho.nado ||
                            _quadroDaVida.value.voando)
                  // A remada só anda remando: desliza parada, boia lenta.
                  ? _quadroDaVida.value.cicloDaAtividade
                  : _quadroDaVida.value.ciclo,
              respiro: _quadroDaVida.value.respiro,
              boia: _quadroDaVida.value.boia,
              cauda: _quadroDaVida.value.cauda,
              vida: _quadroDaVida.value,
              sombra: widget.sombra,
              corDaAgua: widget.corDaAgua,
              comendoDaMao: _comendo >= 0,
              pisca: math.max(_pisca.value, _quadroDaVida.value.pisca),
              orelha: _orelha.value,
              toque: _toque.value,
              // O olhar do motor já vem com mola (sacadas, assentamento) e já
              // segue o de fora; o dedo e o gesto de olhar em volta mandam
              // por cima.
              olhar: _dedo != null
                  ? _olhar
                  : _gestoAtual == GestoOcioso.olhaEmVolta
                  // Varredura da cabeça: dois lados e volta ao centro.
                  ? Offset(math.sin(_gesto.value * math.pi * 2), -0.12)
                  : _toque.isAnimating
                  ? _olhar
                  : _quadroDaVida.value.olhar,
              animado: _toquesSeguidos >= 3,
              amplitude: amplitude,
              gesto: _gestoAtual,
              gestoT: _gesto.value,
              dedo: _dedo,
              gosto: _gosto.value,
            ),
      ),
    );
  }

  /// O toque e o afago, por cima do bicho.
  Widget _comGestos(Widget corpo) {
    // `opaque`, não `deferToChild`: um CustomPaint sem filho não responde a
    // hit-test, então deferir ao filho deixaria o toque no bicho sem efeito.
    return _AreaDoBicho(
      contem: _tocaNoCorpo,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          // Segurar e arrastar: carrega o bicho para outro lugar.
          if (widget.areaDeAndar > 0)
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(
                    duration: const Duration(milliseconds: 320),
                  ),
                  (r) => r
                    ..onLongPressStart = _pega
                    ..onLongPressMoveUpdate = _carrega
                    ..onLongPressEnd = ((_) => _solta())
                    ..onLongPressCancel = _solta,
                ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTapDown = _reageAoToque,
              ),
          _AfagoVenceARolagem:
              GestureRecognizerFactoryWithHandlers<_AfagoVenceARolagem>(
                _AfagoVenceARolagem.new,
                (r) => r
                  ..onStart = _comecaAfago
                  ..onUpdate = _afaga
                  ..onEnd = ((_) => _terminaAfago())
                  ..onCancel = _terminaAfago,
              ),
        },
        child: corpo,
      ),
    );
  }
}

/// Só aceita o toque onde o bicho está.
class _AreaDoBicho extends SingleChildRenderObjectWidget {
  const _AreaDoBicho({required this.contem, super.child});

  final bool Function(Offset) contem;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAreaDoBicho(contem);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAreaDoBicho renderObject,
  ) {
    renderObject.contem = contem;
  }
}

class _RenderAreaDoBicho extends RenderProxyBox {
  _RenderAreaDoBicho(this.contem);

  bool Function(Offset) contem;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!contem(position)) return false;
    return super.hitTest(result, position: position);
  }
}

/// O arrasto do afago, que não desiste para a rolagem.
///
/// O bicho mora dentro de uma lista rolável. Na arena de gestos, o
/// `VerticalDragGestureRecognizer` do `Scrollable` ganha do `pan` por
/// padrão: o dedo que ia fazer carinho descia a tela, e acariciar o Baru na
/// home era quase impossível.
///
/// Recusar a derrota resolve. `rejectGesture` normalmente encerra o
/// reconhecedor; aqui ele aceita, e o toque fica com quem está por cima —
/// que é o bicho. A rolagem continua inteira em qualquer outro ponto da
/// tela; só não rouba o dedo de dentro do habitat.
class _AfagoVenceARolagem extends PanGestureRecognizer {
  /// Menor que o `kTouchSlop` de 18 que a rolagem usa, e menor ainda que o
  /// `kPanSlop` de 36 do `pan` padrão. É o número que decide a arena: quem
  /// reivindica primeiro leva.
  static const _limiar = 6.0;

  Offset? _origem;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // Reivindicar já no toque roubaria o tap — e tocar no bicho tem
    // resposta própria. Por isso guarda a origem e espera o dedo andar.
    _origem = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    final origem = _origem;
    if (origem != null &&
        event is PointerMoveEvent &&
        (event.position - origem).distance > _limiar) {
      resolve(GestureDisposition.accepted);
    }
    super.handleEvent(event);
  }
}

/// Uma pose congelada do bicho, fora do relógio das animações.
///
/// Só os dois movimentos que a sobreposição anima do lado nativo: o peito
/// (respiro) e o olho (piscar). O resto fica em repouso — a fase 0 de cada
/// laço, a mesma que o "reduzir movimento" usa.
///
/// [acao], [ciclo] e [vida] servem para fotografar uma pose qualquer do
/// motor de vida — um passo, uma batida de asa, uma braçada — fora do
/// relógio: é assim que o site recebe as mesmas animações do app, quadro a
/// quadro, sem um segundo desenho dos bichos (`test/animacoes_site_test.dart`).
/// Onde fica a boca de cada espécie, no espaço da cabeça (depois de
/// `_rostoVira`): a linha do lábio [origem]; a largura de referência
/// [largura], a mesma dos arcos do humor; quanto a mandíbula desce com a boca
/// toda aberta [hMax]; quanto há entre a linha do lábio e a base do nariz ou
/// da focinheira [folgaNariz] — o topo do vão nunca sobe a menos de 2
/// unidades do nariz; e se a espécie mostra dentes e língua. Nos bicos
/// (coruja, pinguim) a origem e a largura são as do bico, para a âncora da
/// camada de boca, e [hMax] é quanto a ponta da mandíbula de baixo desce.
///
/// Laudo 30, §1.2, §3.1 a §3.4. Diferenças em relação à tabela de lá, todas
/// anotadas no relatório do lote: a capivara abre 12 e não 14, para o vão
/// não passar da base da cabeça (RRect de 74 de altura; com 14 passava 2
/// unidades mesmo com o queixo descendo); o buldogue abre 10, o número da
/// §3.4 ("lábio inferior + dentinhos descem abertura·10"), e não os 12 da
/// §3.2; gata e raposa ficam com a boca onde está (R4 pedia descer 1,5),
/// porque a boca fechada de cada humor tem de continuar igual à de hoje.
@immutable
class BocaDaEspecie {
  const BocaDaEspecie({
    required this.origem,
    required this.largura,
    required this.hMax,
    this.folgaNariz = 99,
    this.labioSobe = 1,
    this.temDentes = false,
    this.temLingua = true,
    this.larguraBase = 0,
  });

  /// O centro da linha do lábio, no espaço da cabeça.
  final Offset origem;

  /// A largura de referência (`w` dos arcos do humor).
  final double largura;

  /// Quanto a mandíbula desce com a boca toda aberta (unidades).
  final double hMax;

  /// Da linha do lábio até a base do nariz ou da focinheira (unidades). Sem
  /// nariz desenhado (axolote), um número grande: não limita nada.
  final double folgaNariz;

  /// Quanto o lábio de cima sobe, no máximo, com a boca toda aberta
  /// (unidades). Zero no buldogue: o beiço pendurado não sobe.
  final double labioSobe;

  /// Mostra linha de dentes no formato B (a capivara, os dois incisivos; o
  /// buldogue, os dentinhos de baixo que já tem).
  final bool temDentes;

  /// Mostra a língua no fundo do vão a partir de 0,45 de abertura.
  final bool temLingua;

  /// Largura de partida somada à pedida: o axolote tem a boca larga.
  final double larguraBase;

  static BocaDaEspecie de(Species sp) => switch (sp) {
    Species.capybara => const BocaDaEspecie(
      origem: Offset(0, 27),
      largura: 26,
      hMax: 12,
      folgaNariz: 7.5,
      // Sem dentes à mostra: o Baru do desenho nunca mostrou os incisivos.
      temDentes: false,
    ),
    Species.otter => const BocaDaEspecie(
      origem: Offset(0, 19),
      largura: 20,
      hMax: 12,
      folgaNariz: 6.5,
    ),
    Species.tortoise => const BocaDaEspecie(
      origem: Offset(0, 16),
      largura: 24,
      hMax: 12,
      folgaNariz: 7.5,
    ),
    Species.owl => const BocaDaEspecie(
      origem: Offset(0, 13),
      largura: 12,
      hMax: 8,
      temLingua: false,
    ),
    Species.axolotl => const BocaDaEspecie(
      origem: Offset(0, 14),
      largura: 22,
      hMax: 14,
      larguraBase: 0.3,
    ),
    Species.penguin => const BocaDaEspecie(
      origem: Offset(0, 11),
      largura: 12,
      hMax: 10,
    ),
    Species.cat => const BocaDaEspecie(
      origem: Offset(0, 17),
      largura: 20,
      hMax: 9,
      folgaNariz: 4.5,
      temDentes: true,
    ),
    Species.fox => const BocaDaEspecie(
      origem: Offset(0, 19),
      largura: 20,
      hMax: 10,
      folgaNariz: 5,
      temDentes: true,
    ),
    // A folga é até o fim do filtro (27); o nariz mesmo acaba em 22,5. O
    // beiço (o flew) não sobe quando a boca abre: o vão cresce só para
    // baixo, entre os lobos.
    Species.frenchie => const BocaDaEspecie(
      origem: Offset(0, 30),
      largura: 30,
      hMax: 10,
      folgaNariz: 3,
      labioSobe: 0,
      temDentes: true,
    ),
  };
}

@immutable
class QuadroFixo {
  const QuadroFixo({
    this.respiro = 0,
    this.pisca = 0,
    this.acao,
    this.ciclo = 0,
    this.vida = const SaidaDaVida(),
  });

  /// Um dos sete formatos de boca da fala (laudo 30, §3.2) com o resto do
  /// bicho em repouso: o quadro que a série captura por visema e humor.
  QuadroFixo.visema(
    Visema v, {
    this.respiro = 0,
    this.pisca = 0,
    double susto = 0,
    double festa = 0,
  }) : acao = null,
       ciclo = 0,
       vida = SaidaDaVida.visema(v, susto: susto, festa: festa);

  /// -1 (vazio) a 1 (cheio), como em `_Pose.respiro`.
  final double respiro;

  /// 0 aberto, 1 fechado.
  final double pisca;

  /// A ação desenhada. Nula, vale a da atividade do bicho.
  final AcaoDoBicho? acao;

  /// 0..1, a fase do laço da ação (a braçada, a batida de asa).
  final double ciclo;

  /// O quadro do motor de vida: passo, gingado, voo, salto.
  final SaidaDaVida vida;

  _Pose _pose(AcaoDoBicho acao) => _Pose(
    acao: this.acao ?? acao,
    ciclo: ciclo,
    respiro: respiro,
    boia: vida.boia,
    cauda: vida.cauda,
    pisca: pisca,
    orelha: 0,
    toque: 0,
    olhar: vida.olhar,
    animado: false,
    amplitude: 1,
    vida: vida,
  );

  @override
  bool operator ==(Object other) =>
      other is QuadroFixo &&
      other.respiro == respiro &&
      other.pisca == pisca &&
      other.acao == acao &&
      other.ciclo == ciclo &&
      identical(other.vida, vida);

  @override
  int get hashCode => Object.hash(respiro, pisca, acao, ciclo);
}

/// Os valores animados de um quadro. O painter não sabe de controllers.
class _Pose {
  const _Pose({
    required this.acao,
    required this.ciclo,
    required this.respiro,
    required this.boia,
    required this.cauda,
    required this.pisca,
    required this.orelha,
    required this.toque,
    required this.olhar,
    required this.animado,
    required this.amplitude,
    this.gesto = GestoOcioso.nenhum,
    this.gestoT = 0,
    this.dedo,
    this.gosto = 0,
    this.vida = const SaidaDaVida(),
    this.sombra = false,
    this.corDaAgua,
    this.comendoDaMao = false,
  });

  /// Comendo a castanha que a pessoa deu: a mastigação é a do laço.
  final bool comendoDaMao;

  /// O quadro do motor de vida: passeio, salto, colo, inclinação,
  /// achatamento. Zerado no quadro fixo e com movimento reduzido.
  final SaidaDaVida vida;

  /// Desenhar a sombra no chão (o habitat).
  final bool sombra;

  /// A cor da água onde ele nada (no mundo da home). Nula: o tom de sempre.
  final Color? corDaAgua;

  /// O que ele está fazendo — já traduzido para a espécie.
  final AcaoDoBicho acao;

  /// 0 a 1 dando a volta: a fase do laço da atividade.
  final double ciclo;

  /// -1 a 1, ida e volta contínua. Enche e esvazia o peito.
  final double respiro;

  /// -1 a 1, período diferente do respiro.
  final double boia;

  /// -1 a 1, ritmo próprio da cauda.
  final double cauda;

  /// 0 a 1, onde 1 é olho fechado.
  final double pisca;

  /// 0 a 1, um tremor rápido de orelha.
  final double orelha;

  /// 0 a 1, um pulso disparado pelo toque.
  final double toque;

  /// Para onde olha, -1 a 1 em cada eixo.
  final Offset olhar;

  /// Muitos toques seguidos: reação mais forte.
  final bool animado;

  /// Fator global (menor quando o sistema pede movimento reduzido).
  final double amplitude;

  /// Gesto de ocioso em andamento, e onde ele está (0 a 1).
  final GestoOcioso gesto;
  final double gestoT;

  /// Onde a mão está, em coordenadas do widget. Nulo quando ninguém está
  /// afagando.
  final Offset? dedo;

  /// 0 a 1: o quanto ele está gostando do afago.
  final double gosto;

  /// Amplitude do toque, com piso próprio.
  ///
  /// O §7 manda **reduzir** amplitude quando se pede menos movimento, não
  /// remover o feedback: com o fator global de 0.25 a reação ficava abaixo de
  /// um pixel, e feedback invisível é feedback que não existe.
  double get amplitudeToque => math.max(amplitude, 0.55);

  /// O toque: o corpo cede, volta passando um fio do ponto, e assenta —
  /// um quique só. Eram três (seno amortecido de 1,5 volta): gelatina.
  double get quique {
    if (toque == 0) return 0;
    return math.sin(toque * math.pi * 2) * math.exp(-toque * 3.5);
  }

  /// Fase de "carinho": alta logo depois do toque, some devagar.
  double get carinho => toque == 0 ? 0 : math.exp(-toque * 2.2);

  /// Sino 0→1→0 ao longo do gesto: entra e sai sem corte.
  double get gestoForca =>
      gesto == GestoOcioso.nenhum ? 0 : math.sin(gestoT * math.pi) * amplitude;

  /// Espreguiçar: o corpo se alonga e sobe um pouco.
  double get estica => gesto == GestoOcioso.espreguica ? gestoForca : 0;

  /// Sacudir: a cabeça vai e volta rápido e a oscilação morre.
  double get sacudida {
    if (gesto != GestoOcioso.sacode) return 0;
    return math.sin(gestoT * math.pi * 6) *
        math.exp(-gestoT * 2.2) *
        0.18 *
        amplitude;
  }

  /// Bocejo: os olhos se fecham no meio do espreguiçar.
  double get bocejo {
    if (gesto != GestoOcioso.espreguica) return 0;
    if (gestoT < 0.18 || gestoT > 0.72) return 0;
    return math.sin(((gestoT - 0.18) / 0.54) * math.pi);
  }

  /// Coçar: a cabeça pende para um lado e treme rápido, morrendo no fim.
  double get cocada {
    if (gesto != GestoOcioso.coca) return 0;
    return math.sin(gestoT * math.pi) *
        math.sin(gestoT * math.pi * 11) *
        0.11 *
        amplitude;
  }

  /// Farejar: duas fungadas curtas com o focinho para baixo. Em pixels.
  double get farejada {
    if (gesto != GestoOcioso.fareja) return 0;
    final envelope = math.sin(gestoT * math.pi);
    final fungada = 0.5 - 0.5 * math.cos(gestoT * math.pi * 4);
    return envelope * fungada * 8 * amplitude;
  }

  /// Um pulinho, em pixels para cima. Um só por gesto: dois seguidos leem
  /// como bug de física, não como bicho contente.
  double get saltinho {
    if (gesto != GestoOcioso.saltinho) return 0;
    return math.max(0.0, math.sin(gestoT * math.pi * 2)) * 12 * amplitude;
  }

  // ======================================================================
  // O LAÇO DA ATIVIDADE
  //
  // Tudo daqui para baixo sai de [ciclo], que anda sozinho e dá a volta. Com
  // "reduzir movimento" ele fica em zero — e zero é, em cada caso, a pose
  // de repouso daquela atividade, não o meio de um movimento.
  // ======================================================================

  bool get nadando => acao == AcaoDoBicho.nado;
  bool get voando => acao == AcaoDoBicho.voo;
  bool get brincando => acao == AcaoDoBicho.brincadeira;
  bool get pastando => acao == AcaoDoBicho.pasto || acao == AcaoDoBicho.petisco;

  /// A fase do laço em radianos.
  double get _volta => ciclo * math.pi * 2;

  /// Trapézio: sobe em [entra], fica em 1, desce em [sai], zero fora da
  /// janela. É o que dá fases com começo, meio e fim dentro de um laço — um
  /// seno só daria vaivém, e pastar não é vaivém.
  static double _fase(
    double p,
    double inicio,
    double entra,
    double sai,
    double fim,
  ) {
    if (p <= inicio || p >= fim) return 0;
    if (p < inicio + entra) {
      return Curves.easeInOut.transform((p - inicio) / entra);
    }
    if (p > fim - sai) return Curves.easeInOut.transform((fim - p) / sai);
    return 1;
  }

  /// Patas: o passo do repouso vira remada na água e impulso na brincadeira.
  ///
  /// Sempre em torno de -1 a 1 para as espécies continuarem multiplicando
  /// pelo próprio alcance. Na água a excursão passa de 1 de propósito:
  /// remada curta lê como tremor, não como braçada.
  double get pernas => switch (acao) {
    AcaoDoBicho.nado => math.sin(_volta) * 2.4 * _forcaDoNado,
    AcaoDoBicho.brincadeira => math.sin(_volta) * 1.6,
    // Andando, as patas **levantam** (ver [_pata]); de lado elas só
    // deslizavam, e o andar virava arrastar.
    _ => boia,
  };

  /// Asas e nadadeiras. Voando, batem; nadando, varrem meio ciclo atrás da
  /// remada; no resto, só acompanham a respiração como sempre acompanharam.
  double get asa => switch (acao) {
    AcaoDoBicho.voo => math.sin(_volta) * 3.6,
    AcaoDoBicho.nado => math.sin(_volta - math.pi / 2) * 1.7 * _forcaDoNado,
    _ => respiro,
  };

  /// Remando forte, 1; deslizando, as patas param; boiando, mal mexem.
  double get _forcaDoNado =>
      vida.atividadeAtiva ? 0.15 + 0.85 * vida.forcaDaAtividade : 1;

  /// O corpo sobe na batida de asa — e sobe **atrasado** em relação a ela.
  /// Em fase, a coruja parecia um elevador; atrasada, ela voa.
  double get impulsoDoVoo =>
      voando ? math.sin(_volta - math.pi * 0.35) * amplitude : 0;

  /// A brincadeira: agacha na primeira metade do laço, salta na segunda.
  /// Em pixels para cima.
  double get pulo =>
      brincando ? math.max(0.0, math.sin(_volta)) * 16 * amplitude : 0;

  /// O agachamento que antecede o salto, em pixels para baixo.
  ///
  /// Os 4 px fixos são postura, não movimento — bicho brincando fica baixo,
  /// pronto para saltar —, e por isso não passam por [amplitude]: é o que
  /// mantém a brincadeira diferente do ócio para quem desligou a animação.
  double get agacha =>
      brincando ? 4 + math.max(0.0, -math.sin(_volta)) * 5 * amplitude : 0;

  /// O quanto a cabeça desce, em pixels.
  ///
  /// Quem pasta enfia a cabeça no chão e mastiga lá embaixo; quem petisca
  /// abaixa só para pegar e volta a mastigar em cima. É a diferença entre
  /// uma capivara e uma lontra comendo, e é ela que evita o desenho de um
  /// pinguim de bico na grama.
  /// A parcela **postural** é constante e não passa por [amplitude]: quem
  /// come anda de cabeça baixa mesmo parado, e é ela que mantém `graze`
  /// diferente de `idle` para quem pediu menos movimento. A parcela animada
  /// é que reduz.
  double get cabecaDesce => switch (acao) {
    // Em episódios, o motor diz onde está a cabeça (bocada, mastigar de
    // cabeça erguida, vigiar); o laço fica para o quadro fixo.
    // Sentado e de frente, comer é um aceno de cabeça até o capim, e não
    // a cabeça inteira afundada no peito: descendo 32, ela engolia o corpo
    // e o bicho virava uma cabeça com patas.
    // Pastando a cabeça vai ao capim (16 u; `cabecaNoChao` pode passar de
    // 1: a folha da série pede 1,25, a bocada de 19 u do MOV-08; no app o
    // motor limita a 1,2). Quem petisca pega e come em cima: aceno curto.
    AcaoDoBicho.pasto when vida.atividadeAtiva && !comendoDaMao =>
      3 + vida.cabecaNoChao * 13 * amplitude,
    AcaoDoBicho.petisco when vida.atividadeAtiva && !comendoDaMao =>
      2 + vida.cabecaNoChao * 5 * amplitude,
    AcaoDoBicho.pasto =>
      3 + _fase(ciclo, 0.04, 0.12, 0.14, 0.66) * 10 * amplitude,
    AcaoDoBicho.petisco =>
      2 + _fase(ciclo, 0.04, 0.10, 0.10, 0.30) * 8 * amplitude,
    _ => 0.0,
  };

  /// Mastigar: 0 a 1, a boca abrindo e fechando na janela de comer.
  double get mastiga {
    if ((pastando || nadando) && vida.atividadeAtiva && !comendoDaMao) {
      return vida.mastigando * amplitude;
    }
    final janela = switch (acao) {
      AcaoDoBicho.pasto => _fase(ciclo, 0.16, 0.06, 0.06, 0.62),
      AcaoDoBicho.petisco => _fase(ciclo, 0.26, 0.06, 0.08, 0.72),
      _ => 0.0,
    };
    if (janela <= 0) return 0;
    // Catorze aberturas por laço de 5,6 s: ~2,5 mordidas por segundo, que é
    // o ritmo de um bicho comendo. Mais devagar vira bocejo.
    final abre = 0.5 - 0.5 * math.cos(ciclo * math.pi * 2 * 14);
    return janela * abre * amplitude;
  }

  /// A varredura de cabeça de quem levantou do pasto e olha em volta.
  double get olhadaDoPasto {
    // Em episódios a vigilância é do olhar do motor (a virada da cabeça).
    if (!pastando || vida.atividadeAtiva) return 0;
    final janela = _fase(ciclo, 0.70, 0.08, 0.10, 0.94);
    if (janela <= 0) return 0;
    return math.sin((ciclo - 0.70) / 0.24 * math.pi * 2) * janela * amplitude;
  }

  /// À toa ele troca o apoio de um pé para o outro. Em pixels.
  double get pesoNoPe =>
      acao == AcaoDoBicho.ocioso ? math.sin(_volta) * 2.2 * amplitude : 0;
}

/// A boca como uma curva: os cantos em (±[xCanto], [yCanto]), o lábio de
/// cima passando por (0, [topo]) e um só parâmetro de forma, [bico] — 0 deixa
/// os cantos redondos (uma elipse), 1 os afina em ponta (uma lente). O lábio
/// de baixo é a mesma curva passando pelo fundo que [caminho] pedir; quando o
/// fundo é o próprio topo, a boca está fechada e sobra só a linha.
class _CurvaDaBoca {
  const _CurvaDaBoca({
    required this.xCanto,
    required this.yCanto,
    required this.topo,
    required this.bico,
  });

  final double xCanto;
  final double yCanto;
  final double topo;
  final double bico;

  static _CurvaDaBoca lerp(_CurvaDaBoca a, _CurvaDaBoca b, double t) =>
      _CurvaDaBoca(
        xCanto: a.xCanto + (b.xCanto - a.xCanto) * t,
        yCanto: a.yCanto + (b.yCanto - a.yCanto) * t,
        topo: a.topo + (b.topo - a.topo) * t,
        bico: a.bico + (b.bico - a.bico) * t,
      );

  /// A mesma curva com os cantos em outra altura.
  _CurvaDaBoca cantosEm(double y) =>
      _CurvaDaBoca(xCanto: xCanto, yCanto: y, topo: topo, bico: bico);

  /// O lábio de cima, do canto esquerdo ao direito, [desce] unidades abaixo
  /// do lugar dele. Um cúbico só, com os dois controles na mesma altura: o
  /// meio cai exatamente em [topo].
  Path labio(double cx, {double desce = 0}) {
    final yc = yCanto + desce;
    final yT = (4 * (topo + desce) - yc) / 3;
    final xi = xCanto * (1 - bico);
    return Path()
      ..moveTo(cx - xCanto, yc)
      ..cubicTo(cx - xi, yT, cx + xi, yT, cx + xCanto, yc);
  }

  /// O contorno fechado do vão: o lábio de cima até o canto direito e o de
  /// baixo, por (0, [fundo]), de volta ao esquerdo.
  Path caminho(double cx, double fundo) {
    final yB = (4 * fundo - yCanto) / 3;
    final xi = xCanto * (1 - bico);
    return labio(cx)
      ..cubicTo(cx + xi, yB, cx - xi, yB, cx - xCanto, yCanto)
      ..close();
  }
}

class _PetPainter extends CustomPainter {
  _PetPainter({
    required this.species,
    required this.mood,
    required this.activity,
    required this.coat,
    required this.coatIndex,
    required this.pose,
    this.roupas = const {},
    this.roupaDeCabeca,
    this.estagio = EstagioDoBicho.adulto,
    this.corpoDe,
    this.corpoPara,
    this.mistura = 1,
  });

  final Species species;

  /// O humor do **rosto**: olhos, boca, sobrancelha, lágrima.
  final Mood mood;

  /// O humor do **corpo** durante uma troca: postura, cabeça, orelhas e
  /// cauda vão de [corpoDe] a [corpoPara] por [mistura], num desenho só.
  /// Fora da troca, os dois são o próprio [mood].
  ///
  /// A troca esmaecia dois bichos inteiros, e com a postura mudando com o
  /// humor apareciam duas cabeças e quatro orelhas no meio do caminho
  /// (auditoria da Onda 3, 11a-M1). Agora o corpo anda; só o rosto esmaece.
  final Mood? corpoDe;
  final Mood? corpoPara;
  final double mistura;

  /// A escala do fôlego deste quadro, (largura, altura).
  (double, double) _folego = (1, 1);

  /// O traço do olho fechado: tinta, ou creme sobre o pelo escuro, onde a
  /// tinta sumia (buldogue preto, lontra escura dormindo).
  Color get _tracoDoOlho => pelo.computeLuminance() < 0.16
      ? Color.lerp(Cores.superficie, pelo, 0.30)!
      : Cores.tinta;

  /// Desfaz o fôlego no espaço da cabeça: o peito respira, o rosto não.
  void _cabecaSemFolego(Canvas canvas) {
    canvas.scale(1 / _folego.$1, 1 / (_folego.$2 * _feitio));
  }

  /// Um valor do corpo que depende do humor, já interpolado na troca.
  double _porHumor(double Function(Mood m) f) {
    final de = f(corpoDe ?? mood);
    final para = f(corpoPara ?? mood);
    return de + (para - de) * mistura;
  }

  final Activity activity;
  final Color coat;

  /// Ovo/ninho, filhote, jovem, adulto ou pleno. Muda porte, proporção e
  /// detalhe — o crescimento tem de ser visto de longe, não lido numa barra.
  final EstagioDoBicho estagio;

  /// Qual entrada da paleta da espécie foi escolhida.
  ///
  /// O painter recebia só a **cor** resolvida, e cor não basta para o
  /// buldogue: fulvo, tigrado e pied não são o mesmo pelo em intensidades
  /// diferentes — são marcações diferentes, e a marcação é metade do que faz
  /// alguém reconhecer a raça. Sem o índice o desenho não tem como saber se
  /// pinta máscara escura, manchas brancas ou listras. Nas outras oito
  /// espécies a paleta é uma escada de tons do mesmo pelo e o índice não
  /// muda desenho nenhum — por isso ele só é lido em [_buldogue].
  final int coatIndex;

  final _Pose pose;

  /// A cor da peça em cada lugar do corpo. Vazio: o bicho está pelado.
  final Map<Vestimenta, Color> roupas;

  /// Qual peça de cabeça — chapéu, gorro ou coroa mudam o desenho.
  final String? roupaDeCabeca;

  // --- estado derivado ----------------------------------------------------

  /// A ação já traduzida para a espécie. O painter nunca olha [activity]
  /// direto para decidir desenho: quem faz a tradução é [acaoDoBicho], e ela
  /// é a única fonte — senão a coruja voaria na legenda e nadaria no traço.
  AcaoDoBicho get acao => pose.acao;

  bool get dormindo => acao == AcaoDoBicho.cochilo || mood == Mood.sleepy;

  // --- estágio ------------------------------------------------------------
  //
  // Os números do crescimento. O filhote tem o "esquema de bebê" de Lorenz
  // (laudo 05, §4): corpo menor, cabeça e olhos proporcionalmente maiores. O
  // porte encolhe pelos pés, para o filhote ficar no chão do habitat.

  /// Escala do bicho inteiro.
  ///
  /// O adulto fica no tamanho de sempre: é o desenho de vitrine e o que os
  /// testes de anatomia medem. O pleno se distingue pelo detalhe, não por
  /// passar da caixa — a ponta do tufo da coruja já mora a poucos pixels do
  /// topo do quadro.
  double get _porte => switch (estagio) {
    EstagioDoBicho.inicio => 0.52,
    EstagioDoBicho.filhote => 0.63,
    EstagioDoBicho.jovem => 0.80,
    EstagioDoBicho.adulto || EstagioDoBicho.pleno => 1.0,
  };

  /// O feitio do corpo, por cima do porte: quanto ele estica na altura.
  ///
  /// Filhote e jovem eram o mesmo desenho 10% maior — e com a cabeça do
  /// filhote compensada, as duas cabeças saíam quase do mesmo tamanho
  /// (simulador da Fase 4, alto 5). Agora a silhueta conta a idade: o
  /// filhote é atarracado e cabeçudo, o jovem é espichado, de pernas e
  /// tronco compridos, como todo adolescente. A cabeça desfaz o esticão em
  /// [_cabecaSemFolego] e não deforma.
  double get _feitio => switch (estagio) {
    EstagioDoBicho.filhote => 0.95,
    EstagioDoBicho.jovem => 1.14,
    _ => 1.0,
  };

  /// Escala da cabeça, por cima do porte.
  double get _cabecaDoEstagio => switch (estagio) {
    EstagioDoBicho.inicio || EstagioDoBicho.filhote => 1.30,
    EstagioDoBicho.jovem => 1.04,
    EstagioDoBicho.adulto || EstagioDoBicho.pleno => 1.0,
  };

  /// Escala do olho, por cima da cabeça.
  double get _olhoDoEstagio => switch (estagio) {
    EstagioDoBicho.inicio || EstagioDoBicho.filhote => 1.20,
    EstagioDoBicho.jovem => 1.04,
    EstagioDoBicho.adulto || EstagioDoBicho.pleno => 1.0,
  };

  /// Onde ficam os pés, no espaço do corpo. É o pivô do porte.
  static const _pes = 60.0;
  bool get triste => mood == Mood.missingYou;
  bool get feliz =>
      mood == Mood.radiant ||
      pose.carinho > 0.35 ||
      pose.gosto > 0.25 ||
      pose.vida.festa > 0.5 ||
      pose.vida.riso > 0;
  bool get nadando => acao == AcaoDoBicho.nado;
  bool get pastando => pose.pastando;

  /// Nada mergulhando (lontra, pinguim, axolote) em vez de boiando.
  bool get mergulha => _mergulhador(species);

  /// O quanto o corpo afunda na lâmina d'água, em pixels.
  ///
  /// Quem boia mostra o dorso e a cabeça; quem mergulha some quase todo. Foi
  /// **este** número que faltava: sem ele o bicho ficava em cima da água como
  /// um adesivo, e o que o dono viu foi um bicho parado com uns círculos
  /// embaixo.
  double get afunda {
    if (!nadando) return 0;
    // A capivara boia com o dorso rente e só olhos, orelhas e narinas de
    // fora (laudo 31 R8): a lâmina passa logo abaixo do nariz.
    final base = mergulha
        ? 20.0
        : species == Species.capybara
        ? 27.0
        : 13.0;
    // O axolote não sai da água, então a atividade dele é a altura em que
    // fica nela: comendo, mais fundo, junto ao fundo; à toa, mais à tona.
    if (species == Species.axolotl) {
      return switch (activity) {
        Activity.graze => base + 5,
        Activity.idle => base - 8,
        _ => base,
      };
    }
    return base;
  }

  /// Olho fechado por sono, por piscada, por bocejo ou de contentamento.
  ///
  /// O afago fecha aos poucos: os olhos apertam conforme ele vai gostando,
  /// e o arco de pálpebra virado para cima é a carinha de quem está gostando.
  double get fechamento {
    // Com sono e ainda de pé, as pálpebras pesam, mas ele enxerga para onde
    // vai; deitado, fecha. Fechado o tempo todo, andava e ficava sentado de
    // olhos fechados, "dormindo" sentado.
    // Com sono mas acordado (o quadro fixo da série, o humor sono sem o
    // motor): pálpebra pesada, não olho fechado — fechado só com
    // `adormecido` ou cochilando (MEL-07, TOCO-05).
    if (acao == AcaoDoBicho.cochilo ||
        (pose.vida.adormecido ?? (acao == AcaoDoBicho.cochilo))) {
      return 1.0;
    }
    if (dormindo) {
      return math.max(0.6, math.max(pose.pisca, pose.bocejo)).clamp(0.0, 1.0);
    }
    final derrete = ((pose.gosto - 0.34) / 0.16).clamp(0.0, 1.0);
    return math.max(math.max(pose.pisca, pose.bocejo), derrete).clamp(0.0, 1.0);
  }

  // --- paleta -------------------------------------------------------------

  /// O pelo do humor, passado pela penugem do estágio.
  ///
  /// Filhote tem penugem: mais clara e mais fosca. Nas aves e no pinguim a
  /// penugem tem cor própria — o filhote de pinguim é cinza e fofo, a
  /// corujinha é quase branca —, nas outras espécies é o mesmo pelo mais
  /// claro.
  Color get pelo {
    final base = _peloDoHumor;
    final t = switch (estagio) {
      EstagioDoBicho.inicio || EstagioDoBicho.filhote => 1.0,
      EstagioDoBicho.jovem => 0.45,
      EstagioDoBicho.adulto || EstagioDoBicho.pleno => 0.0,
    };
    if (t == 0) return base;
    final penugem = switch (species) {
      Species.penguin => Color.lerp(base, const Color(0xFF9DA5AA), 0.62 * t)!,
      Species.owl => Color.lerp(base, const Color(0xFFE9E1D3), 0.55 * t)!,
      _ => Color.lerp(base, Cores.superficie, 0.16 * t)!,
    };
    return penugem;
  }

  Color get _peloDoHumor {
    switch (mood) {
      case Mood.radiant:
        return Color.lerp(coat, Cores.superficie, 0.10)!;
      // Escurecer o pelo lia como bicho doente ou largado; a saudade e o sono
      // se dizem pelo rosto e pela postura, não pela cor.
      case Mood.sleepy:
        return Color.lerp(coat, Cores.tinta, 0.04)!;
      case Mood.missingYou:
        return coat;
      case Mood.neutral:
        return Color.lerp(coat, Cores.tinta, 0.05)!;
      case Mood.content:
        return coat;
    }
  }

  Color get sombra => Color.lerp(pelo, Cores.tinta, 0.30)!;
  Color get sombraForte => Color.lerp(pelo, Cores.tinta, 0.46)!;
  Color get claro => Color.lerp(pelo, Cores.superficie, 0.30)!;
  Color get barriga => Color.lerp(pelo, Cores.superficie, 0.26)!;
  Color get luz => Color.lerp(pelo, Colors.white, 0.30)!;

  Paint _p(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint _traco(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  // --- helpers de forma ---------------------------------------------------

  /// Uma "bolha" fechada por quatro curvas de Bézier — a base de quase tudo
  /// aqui. Muito mais orgânica que um retângulo arredondado, e os fatores por
  /// lado permitem achatar uma ponta sem virar outra forma.
  Path _bolha(
    Rect r, {
    double topo = 1,
    double base = 1,
    double esq = 1,
    double dir = 1,
  }) {
    final cx = r.center.dx;
    final cy = r.center.dy;
    final rx = r.width / 2;
    final ry = r.height / 2;
    const k = 0.5523;
    return Path()
      ..moveTo(cx, cy - ry * topo)
      ..cubicTo(
        cx + rx * k * dir,
        cy - ry * topo,
        cx + rx * dir,
        cy - ry * k,
        cx + rx * dir,
        cy,
      )
      ..cubicTo(
        cx + rx * dir,
        cy + ry * k * base,
        cx + rx * k * base,
        cy + ry * base,
        cx,
        cy + ry * base,
      )
      ..cubicTo(
        cx - rx * k * base,
        cy + ry * base,
        cx - rx * esq,
        cy + ry * k * base,
        cx - rx * esq,
        cy,
      )
      ..cubicTo(
        cx - rx * esq,
        cy - ry * k,
        cx - rx * k * esq,
        cy - ry * topo,
        cx,
        cy - ry * topo,
      )
      ..close();
  }

  void _oval(Canvas c, Rect r, Color cor) => c.drawOval(r, _p(cor));

  // --- entrada ------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    if (estagio == EstagioDoBicho.inicio && Crescimento.botaOvo(species)) {
      _ovo(canvas, Offset(cx, cy + _pes - 2));
      return;
    }
    final noNinho = estagio == EstagioDoBicho.inicio;
    if (noNinho) _ninho(canvas, Offset(cx, cy + _pes - 2), frente: false);

    final amp = pose.amplitude;
    final sopro = pose.respiro * amp;
    final boia = pose.boia * amp;

    // A lâmina d'água, em coordenadas do **widget** e não do corpo: água que
    // sobe e desce junto com o bicho não é água, é adesivo. Fica dois pixels
    // abaixo do centro do corpo porque é ali que a lâmina do habitat cruza a
    // caixa do bicho — ele é posicionado a 34 unidades do fundo de uma cena
    // cuja água começa em 118, o que cai em y ≈ 87 numa caixa de 150.
    final linhaDagua = PetView.linhaDaguaEm(size.height);

    // Cada atividade tem o seu jeito de ocupar o espaço.
    final balanco = switch (acao) {
      // Na água o corpo sobe e desce com a braçada, não com a boia: é a
      // remada que levanta o dorso, e o atraso de meia fase é o que dá peso.
      AcaoDoBicho.nado =>
        afunda +
            math.sin(pose.ciclo * math.pi * 2 - 0.9) *
                3.4 *
                amp *
                pose._forcaDoNado,
      AcaoDoBicho.voo => -14 - pose.impulsoDoVoo * 7,
      AcaoDoBicho.cochilo => 6 + sopro * 2.6,
      AcaoDoBicho.pasto || AcaoDoBicho.petisco => boia * 1.2,
      AcaoDoBicho.brincadeira => pose.agacha - pose.pulo,
      // O radiante dá pulinhos de vez em quando: três por volta do ócio,
      // só a parte de cima do seno, para pousar e não afundar.
      // Os pulinhos do radiante eram um laço: hop, hop a cada volta do
      // ócio, sempre iguais. A alegria agora pula quando tem motivo (o
      // motor de vida: festa na volta da pessoa, brincadeira).
      AcaoDoBicho.ocioso => boia * 1.2,
    };

    if (nadando) _rastro(canvas, size, linhaDagua);

    // O corpo inteiro vai para uma camada quando ele está na água: o tom da
    // água precisa cair **só sobre o bicho**, e `srcATop` garante isso. Um
    // retângulo translúcido por cima pintaria o habitat junto, e a caixa do
    // bicho apareceria como um quadrado mais escuro dentro da cena.
    //
    // Os limites da camada são folgados de propósito. `saveLayer` recorta no
    // retângulo que recebe, e o bicho **passa** da própria caixa: no habitat
    // ele fica a 34 unidades do fundo da cena e as patas caem abaixo disso.
    // Com `Offset.zero & size` as patas do bicho nadando eram cortadas numa
    // linha reta no meio da água.
    final folga = Rect.fromLTRB(
      -size.width,
      -size.height,
      size.width * 2,
      size.height * 3,
    );
    if (nadando) canvas.saveLayer(folga, Paint());

    final vida = pose.vida;
    // A sombra fica no chão: anda com ele, encolhe e clareia quando ele sobe.
    if (pose.sombra && !nadando) {
      final alto = (vida.altura / 120).clamp(0.0, 1.0);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + vida.desloca.dx, cy + _pes - 1),
          width: 88 * (1 - alto * 0.45) * _porte,
          height: 11 * (1 - alto * 0.45),
        ),
        Paint()..color = Cores.tintaA(0.15 * (1 - alto * 0.6)),
      );
    }
    // A poeira da corrida fica onde a pata bateu: cresce, sobe um fio e
    // some.
    if (!nadando) {
      for (final p in vida.poeira) {
        final idade = p.dy.clamp(0.0, 1.0);
        // Pequena e rasteira: grande e redonda, lia como mancha na tela.
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(cx + p.dx, cy + _pes - 2 - idade * 4),
            width: (6 + idade * 10) * _porte,
            height: (3 + idade * 4) * _porte,
          ),
          Paint()..color = _corDaPoeira.withValues(alpha: 0.32 * (1 - idade)),
        );
      }
    }

    canvas.save();
    final corpoY =
        cy +
        balanco +
        pose.quique * 7 * pose.amplitudeToque -
        pose.estica * 4 -
        pose.saltinho;
    canvas.translate(cx + pose.pesoNoPe, corpoY);

    // O motor de vida, por cima de tudo que a atividade já faz: o passeio e
    // o salto movem o corpo; a inclinação gira pelos pés (ou pelo cangote,
    // no colo).
    canvas.translate(vida.desloca.dx, vida.desloca.dy);
    if (vida.virado) canvas.scale(-1, 1);
    // O giro (rodopio, lontra rolando): o contorno não muda. O rosto
    // desliza para um lado e sai ([_virada]); de costas, o tom do dorso
    // cobre rosto e barriga aos poucos; e o rosto volta pelo outro lado.
    // Antes o corpo encolhia para uma fatia de 12% da largura, como uma
    // folha de papel: deformava o bicho inteiro.
    final dorso = vida.giro > 0
        ? Curves.easeInOut.transform(
            ((0.35 - math.cos(vida.giro * 2 * math.pi)) / 0.7).clamp(0.0, 1.0),
          )
        : 0.0;
    final deCostas = dorso > 0;
    if (deCostas) {
      canvas.saveLayer(
        folga,
        Paint()
          ..colorFilter = ColorFilter.mode(
            sombra.withValues(alpha: dorso),
            BlendMode.srcATop,
          ),
      );
    }
    // O gingado gira pelo pé que está no chão.
    if (vida.gingado != 0) {
      final apoio = Offset(vida.gingado > 0 ? 22 : -22, _pes);
      canvas.translate(apoio.dx, apoio.dy);
      canvas.rotate(vida.gingado);
      canvas.translate(-apoio.dx, -apoio.dy);
    }
    if (vida.inclina != 0) {
      final pivoDaInclinacao = vida.carregado ? -40.0 : _pes;
      canvas.translate(0, pivoDaInclinacao);
      canvas.rotate(vida.inclina);
      canvas.translate(0, -pivoDaInclinacao);
    }
    // Deitado, o corpo não achata: desce inteiro e o que passa do chão
    // some, como patas recolhidas sob a barriga. A proporção do desenho
    // fica a mesma (antes ele achatava 32%, e o bicho deformava).
    final d = vida.deita;
    if (d > 0) {
      // A base é redonda, como uma barriga apoiada no chão; um corte reto
      // parecia o bicho atrás de um muro.
      canvas.clipPath(
        Path()
          ..addRect(Rect.fromLTRB(-400, -400, 400, _pes - 12))
          ..addOval(
            Rect.fromCenter(
              center: const Offset(0, _pes - 12),
              width: 106,
              height: 26,
            ),
          ),
      );
      canvas.translate(0, _afundaDeitado * d);
    }
    // Um amassado pequeno no pouso, pelos pés. A cabeça desfaz a escala no
    // ponto em que se apoia ([_posicionaCabeca]).
    final (ax, ay) = _achataDoCorpo;
    if (ay != 1) {
      canvas.translate(0, _pes);
      canvas.scale(ax, ay);
      canvas.translate(0, -_pes);
    }

    final giro = switch (acao) {
      AcaoDoBicho.cochilo => -0.16,
      // Rola de um lado para o outro na braçada — é a ondulação do nado.
      // Quem mergulha rola mais: o corpo dele é o remo.
      // (A postura de nado — pender para onde vai com a cabeça à frente,
      // MOV-06 — é do motor, em `inclina`/`cabecaAtraso`, que já sabe o
      // sentido; aqui só o rolar da braçada.)
      AcaoDoBicho.nado =>
        -0.04 +
            math.sin(pose.ciclo * math.pi * 2) *
                (mergulha ? 0.08 : 0.045) *
                amp *
                pose._forcaDoNado,
      AcaoDoBicho.voo => math.sin(pose.ciclo * math.pi * 2) * 0.05 * amp,
      // A inclinação acompanha a cabeça: quanto mais baixa, mais o corpo
      // vai junto. Cabeça descendo com o corpo reto lê como pescoço quebrado.
      AcaoDoBicho.pasto ||
      AcaoDoBicho.petisco => 0.01 + pose.cabecaDesce * 0.003,
      // O -0.05 é a mesma postura do agachamento: o peito baixa na frente.
      AcaoDoBicho.brincadeira =>
        -0.05 + math.sin(pose.ciclo * math.pi * 2) * 0.09 * amp,
      AcaoDoBicho.ocioso =>
        triste ? 0.02 : boia * 0.012 + pose.pesoNoPe * 0.006,
    };
    // O porte do estágio. Em terra, pelos pés: o filhote fica no chão. Na
    // água, pela linha d'água: encolher pelos pés afundava o filhote, que
    // ficava com a água nos olhos (auditoria da Onda 2, 6.1). Pela linha,
    // o que estava acima dela continua acima.
    final porte = _porte;
    final feitio = _feitio;
    if (porte != 1 || feitio != 1) {
      final pivo = nadando ? linhaDagua - corpoY : _pes;
      canvas.translate(0, pivo);
      canvas.scale(porte, porte * feitio);
      canvas.translate(0, -pivo);
    }
    // O novo estágio é visto boiando, não afogado: o filhote e o jovem
    // boiam mais alto, com o corpo à vista (simulador da Fase 4, alto 5).
    if (nadando && feitio != 1) canvas.translate(0, -9);
    canvas.rotate(giro);

    // Respiração como squash/stretch, mais o quique do toque e o alongamento
    // do espreguiçar. Dormindo a respiração é quase o dobro de funda: é o
    // sinal que faz o sono ser visto sem depender de nenhum símbolo.
    final q = pose.quique * pose.amplitudeToque;
    final e = pose.estica;
    // 1,5 e não 2,1 no sono: a 2,1 o corpo variava 14% de pico a pico e a
    // cara se esmagava (auditoria da Onda 3, 11a-M3).
    // 1,15 no sono: a 1,5 o topo subia 12 u e o corpo enchia de um lado só
    // como balão (MOV-09); o fôlego do sono se vê pelo ritmo, não pelo
    // tamanho.
    final fundura = dormindo ? 1.15 : 1.0;
    // A postura do humor, pelos pés.
    final (px, py) = _posturaDoHumor;
    if (px != 1 || py != 1) {
      canvas.translate(0, _pes);
      canvas.scale(px, py);
      canvas.translate(0, -_pes);
    }
    // O quique do toque e o espreguiçar: o bicho inteiro.
    canvas.scale(1 + q * 0.04 + e * 0.04, 1 - q * 0.04 + e * 0.02);
    // O fôlego quase dobrou: a 1,8% ele não se via (laudo 05, R4); a 3,4% o
    // peito sobe e desce sem virar pulo. Pelos pés, que não saem do chão, e
    // só no tronco: a cabeça desfaz a escala em [_cabecaSemFolego] e é
    // levada pelo peito, em vez de achatar junto com ele.
    // O susto estica o tronco com volume (laudo 31 R3): +9 % de altura,
    // −9 % de largura, pelos pés; a cabeça desfaz a escala e sobe junto.
    final estirao = 0.09 * vida.susto.clamp(0.0, 1.0);
    _folego = (
      (1 + sopro * 0.034 * fundura) * (1 - estirao),
      (1 - sopro * 0.026 * fundura) * (1 + estirao),
    );
    canvas.translate(0, _pes);
    canvas.scale(_folego.$1, _folego.$2);
    canvas.translate(0, -_pes);

    // Os ossos do corpo neste quadro: o contorno inteiro se dobra por eles
    // (ver [CanvasDeformavel]) — o tronco verga para onde vai, a cintura
    // incha no pouso, o peito enche, o quadril balança no passo.
    final ossos = OssosDoCorpo(
      // Verga para onde vai e, parado, um pouco para onde olha: o corpo
      // acompanha a cabeça, em vez de ela girar sobre um tronco duro.
      verga:
          ((vida.andando * 0.55 +
                      vida.corrida * 0.45 +
                      _virada.dx * 0.22 * (1 - vida.andando)) *
                  amp)
              .clamp(-1.0, 1.0),
      // (O estirão do susto é escala com volume, em [_folego]; aqui só
      // chega a agachada de antecipação, pelo `achata` do motor.)
      achata: ((vida.achata * 1.6 + vida.elastico) * amp).clamp(-1.0, 1.0),
      folego: (sopro * fundura).clamp(-1.0, 1.0),
      // Andando, o quadril vai com o passo; parado, ele se acomoda devagar
      // de um lado para o outro, o peso mudando de pata.
      quadril:
          ((vida.passada * vida.andando +
                      math.sin(pose.ciclo * math.pi * 2) *
                          0.3 *
                          (1 - vida.andando) +
                      // Festejando, rebola entre os saltos.
                      math.sin(pose.ciclo * math.pi * 14) * 0.7 * vida.festa) *
                  amp)
              .clamp(-1.0, 1.0),
      ladoEsquerdo: vida.pataEsquerda * amp,
      ladoDireito: vida.pataDireita * amp,
      pes: _pes,
      // Nadando, o corpo ondula no ritmo da braçada, por espécie (laudo 31
      // R8, 34 R10): o axolote de lado, crescendo até a cauda; a lontra
      // com o dorso subindo e descendo; capivara e tartaruga, pouco. Em
      // terra, o axolote anda ondulando pela fase do passo (MOV-04).
      ondula: nadando
          ? (amp *
                    pose._forcaDoNado *
                    switch (species) {
                      Species.axolotl => 1.0,
                      Species.otter => 0.3,
                      Species.penguin => 0.5,
                      _ => 0.55,
                    })
                .clamp(0.0, 1.0)
          : species == Species.axolotl
          ? (vida.andando * 0.5 * amp).clamp(0.0, 1.0)
          : 0,
      faseDaOnda: nadando
          ? pose.ciclo * math.pi * 2
          : vida.faseDoPasso * math.pi * 2,
      ondaVertical: nadando && species == Species.otter
          ? (amp * pose._forcaDoNado).clamp(0.0, 1.0)
          : 0,
      ondaNaCauda: species == Species.axolotl,
      // O corpo é espelhado quando ele vira; o dedo, não.
      dente: Offset(
        vida.virado ? -vida.dente.dx : vida.dente.dx,
        vida.dente.dy,
      ),
      denteForca: vida.denteForca,
    );
    // A tartaruga não: casco é rígido, e dobrá-lo é anatomia errada.
    final corpo =
        ossos.parado || species == Species.tortoise || !CanvasDeformavel.ligado
        ? canvas
        : CanvasDeformavel(canvas, ossos.deforma);

    switch (species) {
      case Species.capybara:
        _capivara(corpo);
      case Species.otter:
        _lontra(corpo);
      case Species.tortoise:
        _tartaruga(corpo);
      case Species.owl:
        _coruja(corpo);
      case Species.axolotl:
        _axolote(corpo);
      case Species.penguin:
        _pinguim(corpo);
      case Species.cat:
        _gata(corpo);
      case Species.fox:
        _raposa(corpo);
      case Species.frenchie:
        _buldogue(corpo);
    }
    if (deCostas) canvas.restore();
    canvas.restore();
    if (noNinho) _ninho(canvas, Offset(cx, cy + _pes - 2), frente: true);

    if (nadando) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(folga.left, linhaDagua, folga.right, folga.bottom),
      );
      // No mundo a água tem a cor da lagoa e engrossa com a profundidade:
      // com o tom fixo a 44% o corpo inteiro aparecia, em pé, como numa
      // caixa esverdeada.
      final agua = pose.corDaAgua;
      canvas.drawRect(
        folga,
        agua == null
            ? (Paint()
                ..color = _tomDaAgua
                ..blendMode = BlendMode.srcATop)
            : (Paint()
                ..blendMode = BlendMode.srcATop
                ..shader = _sombraDaAgua(agua, linhaDagua, size.width)),
      );
      canvas.restore();
      canvas.restore(); // fecha a camada do corpo
      _lamina(canvas, size, linhaDagua);
    }

    if (dormindo && !noNinho && fechamento >= 1) {
      _zzz(canvas, size);
      _folhaDoSono(canvas, size);
    }
    // Na festa os brilhos só depois do pouso (laudo 31 R4): no ar, o corpo
    // é que comemora.
    if (feliz && !(pose.vida.festa > 0 && pose.vida.altura > 0.5)) {
      _brilhos(canvas, size);
    }
    if (pose.animado && pose.toque > 0) _coracoes(canvas, size);
    if (pose.gosto > 0) _afago(canvas, size);
  }

  /// O afago, desenhado em coordenadas do widget — não do corpo — porque a
  /// mão está por cima dele, não presa à anatomia.
  void _afago(Canvas canvas, Size size) {
    final g = pose.gosto;
    final dedo = pose.dedo;

    // Pelo levantado sob a mão: dois arcos curtos, como um rastro.
    if (dedo != null) {
      final risco = _traco(luz.withValues(alpha: 0.30 + g * 0.35), 2.4);
      for (var i = 0; i < 2; i++) {
        final r = 11.0 + i * 7;
        canvas.drawArc(
          Rect.fromCircle(center: dedo, radius: r),
          math.pi * 1.15,
          math.pi * 0.7,
          false,
          risco,
        );
      }
    }

    // Coraçõezinhos contínuos: a partir da metade da satisfação eles sobem
    // sem parar, e ficam mais fortes até encher.
    if (g < 0.45) return;
    final base = dedo ?? Offset(size.width * 0.5, size.height * 0.42);
    final fase = (pose.respiro + 1) / 2;
    for (var i = 0; i < 3; i++) {
      final f = (fase + i / 3) % 1.0;
      final a = math.sin(f * math.pi) * ((g - 0.45) / 0.55).clamp(0.0, 1.0);
      if (a <= 0.03) continue;
      _coracao(
        canvas,
        Offset(
          base.dx + math.sin(f * math.pi * 2 + i * 2.1) * 13,
          base.dy - 12 - f * 40,
        ),
        3.6 + a * 3.6,
        Cores.acento.withValues(alpha: a * 0.9),
      );
    }
  }

  /// Carinho insistente: três coraçõezinhos que sobem e somem.
  ///
  /// `pose.animado` já existia — era calculado a cada toque seguido e nunca
  /// chegava à tela. O háptico ficava mais forte e nada mudava visualmente.
  void _coracoes(Canvas canvas, Size size) {
    final t = pose.toque;
    if (t >= 1) return;
    final amp = pose.amplitudeToque;
    const partidas = [(0.34, 0.0), (0.52, 0.18), (0.66, 0.38)];
    for (final (fx, atraso) in partidas) {
      final f = ((t - atraso) / (1 - atraso)).clamp(0.0, 1.0);
      if (f <= 0) continue;
      final a = math.sin(f * math.pi).clamp(0.0, 1.0);
      if (a <= 0.02) continue;
      final deriva = math.sin(f * math.pi * 2 + atraso * 9) * 5 * amp;
      _coracao(
        canvas,
        Offset(size.width * fx + deriva, size.height * 0.40 - f * 34 * amp),
        4.2 + a * 3.4,
        Cores.acento.withValues(alpha: a * 0.85),
      );
    }
  }

  void _coracao(Canvas canvas, Offset o, double s, Color cor) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy + s * 0.75)
        ..cubicTo(
          o.dx - s * 1.35,
          o.dy - s * 0.15,
          o.dx - s * 0.72,
          o.dy - s * 1.25,
          o.dx,
          o.dy - s * 0.42,
        )
        ..cubicTo(
          o.dx + s * 0.72,
          o.dy - s * 1.25,
          o.dx + s * 1.35,
          o.dy - s * 0.15,
          o.dx,
          o.dy + s * 0.75,
        )
        ..close(),
      _p(cor),
    );
  }

  /// Deslocamento do olhar aplicado às pupilas.
  ///
  /// A varredura do pasto entra aqui também: cabeça que gira com a pupila
  /// parada no meio lê como boneco, não como bicho conferindo se está tudo
  /// bem antes de voltar a comer.
  Offset get _olhoDesvio => Offset(
    // 4,5 e não 3 (RIO-25): a 3 o olhar era 36 % do raio e no tamanho da
    // home não se via para onde ele olhava. O limite para a íris não sair
    // do olho fica em [_olho].
    _espelho * pose.olhar.dx * 4.5 * pose.amplitudeToque +
        pose.olhadaDoPasto * 2.2,
    pose.olhar.dy * 3.0 * pose.amplitudeToque,
  );

  /// Para onde a cabeça está virada (-1..1): o motor de vida, mais a
  /// varredura de quem levanta a cabeça do pasto.
  Offset get _virada => Offset(
    // Andando, a cara vai para onde ele vai: no desenho (já espelhado
    // por `virado`) isso é sempre +x.
    (_espelho * pose.vida.virada.dx +
            pose.olhadaDoPasto +
            pose.vida.andando * 0.7 +
            // No giro o rosto dá a volta: vai até a beira de um lado e volta
            // pelo outro; no meio da volta o dorso cobre.
            math.sin(pose.vida.giro * 2 * math.pi))
        // Passando de 1, o rosto saía do contorno da cabeça (a máscara da
        // raposa ficava para fora).
        .clamp(-1.0, 1.0),
    pose.vida.virada.dy.clamp(-1.0, 1.0),
  );

  /// O olhar e a virada vêm do motor no sentido da cena; o desenho é
  /// espelhado quando ele está virado para a esquerda. Sem desfazer o
  /// espelho, ele andava para um lado olhando para o outro.
  double get _espelho => pose.vida.virado ? -1.0 : 1.0;

  /// O rosto deslizando dentro do contorno da cabeça: é assim que um
  /// desenho 2D vira a cabeça (parallax de rosto, como nos rigs do Rive e
  /// do Spine). Olhos, focinho e boca andam juntos; o contorno anda bem
  /// menos ([_posicionaCabeca]); a sombra do queixo, para o outro lado.
  Offset get _rosto =>
      Offset(_virada.dx * (_ehCoruja ? 12.0 : 8.5), _virada.dy * 3.5) *
      pose.amplitudeToque;

  /// A coruja vira a cabeça inteira (olho tubular, preso na órbita): o
  /// rosto desliza mais e encurta mais (laudo 32 R3, NINA-07).
  bool get _ehCoruja => species == Species.owl;

  // Virando, o rosto também encurta na horizontal: os olhos se aproximam,
  // como num três quartos. Só deslizando, o olho de trás escorregava até a
  // borda da cabeça e parecia cair para fora (pesquisa 24).
  double get _encurtaRosto =>
      1 -
      (_ehCoruja ? 0.24 : 0.14) *
          _virada.dx.abs().clamp(0.0, 1.0) *
          pose.amplitudeToque;

  void _rostoVira(Canvas c) {
    c.translate(_rosto.dx, _rosto.dy);
    c.scale(_encurtaRosto, 1);
  }

  void _rostoVolta(Canvas c) {
    c.scale(1 / _encurtaRosto, 1);
    c.translate(-_rosto.dx, -_rosto.dy);
  }

  /// O contorno da cabeça acompanha um pouco a virada, e a inclinação gira
  /// pelo pescoço — o queixo fica, o alto da cabeça vai. Girando pelo
  /// centro, o queixo escorregava por cima do corpo.
  void _posicionaCabeca(Canvas c, double giro, {double pescoco = 30}) {
    final vida = pose.vida;
    // A cabeça não amassa com o corpo: só desce junto com ele.
    final (ax, ay) = _achataDoCorpo;
    if (ay != 1) c.scale(1 / ax, 1 / ay);
    // Atrasada em relação ao corpo, e com o gesto de cabeça da vez.
    c.translate(
      vida.cabecaAtraso.dx +
          _virada.dx * (_ehCoruja ? 6.4 : 3.2) * pose.amplitudeToque,
      vida.cabecaAtraso.dy + vida.cabecaDesce + _cabecaDaExpressao,
    );
    c.translate(0, pescoco);
    c.rotate(giro + vida.cabecaGiro);
    c.translate(0, -pescoco);
  }

  /// Quanto a cabeça sobe (negativo) ou desce com as assinaturas do rosto:
  /// no susto recua (a lontra encolhe o pescoço: desce), no grito vai 6
  /// unidades para trás, no riso 4 (laudo 30 §3.5, laudo 31 R3).
  double get _cabecaDaExpressao {
    final vida = pose.vida;
    final susto = vida.susto.clamp(0.0, 1.0);
    final grito = vida.grito.clamp(0.0, 1.0);
    final riso = (vida.riso / 0.12).clamp(0.0, 1.0);
    // (O estirão do corpo já leva a cabeça ~8 para cima; mais que isso
    // abria pescoço entre cabeça e tronco e a silhueta crescia 5 %.)
    final doSusto = switch (species) {
      Species.otter => 6.0,
      Species.tortoise => 0.0, // dobra de lado, em [_tartaruga]
      Species.owl || Species.penguin => -2.0,
      _ => -1.0,
    };
    return doSusto * susto - 6 * grito - 4 * riso;
  }

  static const _corDaPoeira = Color(0xFFB8A27A);

  /// Quem anda aos saltinhos (ver `JeitoDeCacar.saltita`).
  bool get _saltita => jeitoDaEspecie(species).saltita;

  /// Quanto o corpo desce deitado: o bastante para as patas da frente
  /// sumirem sob ele.
  static const _afundaDeitado = 20.0;

  /// A escala do corpo achatado (largura, altura), com volume preservado.
  (double, double) get _achataDoCorpo {
    final vida = pose.vida;
    final a = vida.achata;
    if (a == 0) return (1, 1);
    // No máximo 4%: o bicho tem anatomia, não é uma bola de borracha.
    final sy = (1 - a * 0.12).clamp(0.96, 1.04);
    return (1 / math.sqrt(sy), sy);
  }

  /// A sombra que a cabeça faz no corpo, logo abaixo do queixo. É o que
  /// separa as duas massas: sem ela, cabeça e corpo da mesma cor viravam
  /// uma coisa só, e a cabeça parecia colada na frente.
  void _sombraDoQueixo(Canvas c, double largura, double altura) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(-_rosto.dx * 0.3, altura / 2 - 2),
        width: largura * 0.6,
        height: 15,
      ),
      Paint()
        ..color = Cores.tintaA(0.17)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5),
    );
  }

  /// A cabeça acompanha um pouco o olhar, e varre ao levantar do pasto.
  double get _cabecaGiro =>
      _inclinaDoHumor +
      pose.sacudida +
      pose.cocada +
      // Encosta a cabeça na mão.
      (pose.dedo == null ? 0 : pose.gosto * 0.06 * pose.amplitudeToque) +
      // Um fio de inclinação junto da virada; o grosso da virada é o rosto
      // deslizando ([_rosto]). Antes a cabeça **tombava** 0,09 rad para o
      // lado do olhar e o pasto varria tombando 0,16: um adesivo girando
      // por cima do corpo, não uma cabeça virando.
      _virada.dx * 0.025;

  /// O quanto a cabeça desce, em pixels — pastando ou farejando.
  ///
  /// Somado ao `translate` da cabeça de cada espécie. Fica num getter só
  /// porque a alternativa era repetir a mesma soma em oito lugares e
  /// esquecer de um.
  double get _cabecaDesce =>
      pose.cabecaDesce +
      // A cabeça acompanha cada mastigada, e desce na reverência.
      pose.mastiga * 2.4 +
      pose.vida.reverencia * 10 +
      pose.farejada +
      _cabecaDoHumor +
      // O axolote comendo: cabeça baixa, mirando o fundo.
      (species == Species.axolotl && nadando && activity == Activity.graze
          ? 5
          : 0);

  // --- humor no corpo -------------------------------------------------------
  //
  // O humor era só olho e boca: contente e saudade mudavam 2–3% dos pixels
  // (laudo 06, rec. 6). Um bicho com saudade baixa a cabeça e a inclina, o
  // corpo murcha; o radiante ergue a cabeça e o peito. São posturas, não
  // movimento: valem com "reduzir movimento" também.

  /// Quanto a cabeça desce pelo humor (negativo sobe).
  double get _cabecaDoHumor => _porHumor(
    (m) => switch (m) {
      Mood.radiant => -3,
      Mood.content => 0,
      Mood.neutral => 2,
      Mood.sleepy => 5,
      Mood.missingYou => 7,
    },
  );

  /// A inclinação da cabeça pelo humor: o "pidão" de lado na saudade.
  double get _inclinaDoHumor => _porHumor(
    (m) => switch (m) {
      Mood.radiant => -0.05,
      Mood.content => 0,
      Mood.neutral => 0,
      Mood.sleepy => 0.06,
      Mood.missingYou => 0.12,
    },
  );

  /// A postura do tronco: (largura, altura). Murcho na saudade e no sono,
  /// esticado no radiante. Pivô nos pés.
  (double, double) get _posturaDoHumor {
    (double, double) de(Mood m) => switch (m) {
      Mood.radiant => (0.98, 1.04),
      Mood.content => (1.0, 1.0),
      Mood.neutral => (1.0, 0.98),
      Mood.sleepy => (1.03, 0.94),
      Mood.missingYou => (1.03, 0.93),
    };
    return (_porHumor((m) => de(m).$1), _porHumor((m) => de(m).$2));
  }

  // ======================================================================
  // CAPIVARA — de frente: cabeça grande e chata, focinho rombudo, corpo baixo
  //
  // Antes era de perfil: um corpo-ovo comprido com uma cabeça-ovo colada na
  // ponta. Duas elipses sobrepostas não fazem pescoço nem bochecha, e o
  // resultado lia como batata. De frente a cara domina — que é o que faz um
  // personagem funcionar, e é por isso que a coruja já funcionava.
  // ======================================================================

  void _capivara(Canvas canvas) {
    final amp = pose.amplitude;
    final passo = pose.pernas * amp;

    // Patas da frente, apoiadas. Sobem e descem alternadas ao boiar — e
    // remam de verdade quando ele está na água (ver [_pata]).
    // Em y 55 (era 51): o pé sai 4 u abaixo da barriga e se vê levantar no
    // galope; a 51 ficava escondido atrás do corpo e o passo não lia.
    _pata(canvas, const Offset(-23, 55), 27, 17, sombra, passo * 1.6, rema: -1);
    _pata(canvas, const Offset(23, 55), 27, 17, sombra, -passo * 1.6, rema: 1);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 18), width: 92, height: 80),
      topo: 0.86,
      base: 1.02,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 32), width: 64, height: 62),
        topo: 0.9,
      ),
      _p(barriga),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -30 + pose.respiro * amp * 0.7 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    // Um fio de giro sempre (0,06 rad): a cabeça-bloco perfeitamente reta
    // era a mais "gêmea" do elenco (laudo 31 R11).
    _posicionaCabeca(canvas, _cabecaGiro * 0.9 + 0.06, pescoco: 38);
    canvas.scale(_cabecaDoEstagio);
    _sombraDoQueixo(canvas, 94, 78);

    // Orelhas antes da cabeça: nascem atrás dela, então a base some sob o
    // contorno em vez de ficar boiando em cima.
    // Orelhas pequenas e afastadas: na capivara elas são dois botõezinhos
    // nos cantos de cima. Grandes e altas, ela vira urso.
    _orelhaRedonda(canvas, const Offset(-40, -19), 16, 14, -0.34);
    _orelhaRedonda(canvas, const Offset(40, -19), 16, 14, 0.34);

    // Cabeça larga e de topo baixo: a capivara é quadradona, não redonda.
    // Cabeça quase retangular. É a marca da capivara: um bloco com cantos
    // arredondados, não uma bola. Com `_bolha` ela virava um urso.
    canvas.drawPath(
      Path()..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(-47, -35, 47, 39 + _queixoDesce),
          topLeft: const Radius.circular(34),
          topRight: const Radius.circular(34),
          bottomLeft: const Radius.circular(26),
          bottomRight: const Radius.circular(26),
        ),
      ),
      _p(pelo),
    );

    // Focinho: uma faixa larga e **baixa**, encostada no queixo, com o topo
    // suave. Como oval isolado no meio da cara, lia como máscara colada.
    canvas.save();
    canvas.clipPath(
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(-47, -35, 47, 39 + _queixoDesce),
          const Radius.circular(30),
        ),
      ),
    );
    _rostoVira(canvas);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 27), width: 74, height: 44),
        topo: 0.74,
      ),
      _p(claro),
    );
    canvas.restore();
    _rostoVira(canvas);

    // Focinheira: o bloco escuro em cima do focinho, entre as narinas.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 12), width: 26, height: 15),
        base: 1.12,
      ),
      _p(sombraForte),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5, 9), width: 7, height: 4),
      _p(luz.withValues(alpha: 0.4)),
    );

    _boca(canvas);
    if (feliz) {
      _bochecha(canvas, const Offset(-34, 18), const Offset(34, 18));
    }

    // Olhos altos e afastados: na capivara eles ficam quase na linha das
    // orelhas, para o bicho olhar em volta com o corpo na água.
    _olho(canvas, const Offset(-26, -13), 7.5);
    _olho(canvas, const Offset(26, -13), 7.5);
    _rostoVolta(canvas);
    _veste(canvas, 96, 78);

    canvas.restore();
  }

  // ======================================================================
  // LONTRA — cabeça redonda, focinho claro, bigodes dos dois lados, cauda
  // ======================================================================

  void _lontra(Canvas canvas) {
    final amp = pose.amplitude;
    final rema = pose.pernas * amp;
    // A cauda da lontra é o leme, e na água ela bate no compasso da braçada
    // em vez de balançar no ritmo solto dela. Sem isto o corpo nadava e a
    // cauda ficava vadiando atrás, em outro tempo.
    final sustoDaLontra = pose.vida.susto.clamp(0.0, 1.0);
    final festaDaLontra = pose.vida.festa.clamp(0.0, 1.0);
    // Nadando, a cauda chicoteia para cima 2–3 quadros depois do dorso, com
    // o dobro da amplitude (laudo 31 R8): ela é o remo. Festejando ela
    // chicoteia em dobro (laudo 31 R4).
    final balanca =
        (pose.nadando
            ? math.sin(pose.ciclo * math.pi * 2 - 0.9) *
                  2.6 *
                  amp *
                  pose._forcaDoNado
            : pose.cauda * amp) *
        (1 + festaDaLontra);
    // No susto a cauda levanta rígida, ponta 20 acima (laudo 31 R3).
    final levanta = 20 * sustoDaLontra;

    // Cauda grossa saindo por trás, para um lado, afinando na ponta.
    canvas.drawPath(
      Path()
        ..moveTo(26, 34)
        ..cubicTo(
          58 + balanca * 5,
          40 - levanta * 0.3,
          74 + balanca * 8,
          24 + balanca * 4 - levanta * 0.7,
          78 + balanca * 9,
          6 + balanca * 6 - levanta,
        )
        ..cubicTo(
          70 + balanca * 6,
          12 + balanca * 3 - levanta * 0.8,
          58 + balanca * 3,
          30 - levanta * 0.3,
          26,
          50,
        )
        ..close(),
      _p(sombraForte),
    );

    // Na água as patas da frente ficam paradas junto ao peito (ver [_pata]).
    final sobeDesce = pose.nadando ? 0.0 : rema * 1.6;
    _patinha(canvas, Offset(-20, 50 + sobeDesce), sombra, rema: -1);
    _patinha(canvas, Offset(20, 50 - sobeDesce), sombra, rema: 1);

    final corpo = _bolha(
      // Comprida e estreita, não um barril: a silhueta de lontra e a de
      // capivara se sobrepunham em 83% (laudo 06, rec. 5).
      Rect.fromCenter(center: const Offset(0, 14), width: 66, height: 90),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 26), width: 44, height: 66),
        topo: 0.9,
      ),
      _p(barriga),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -34 + pose.respiro * amp * 0.7 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    _posicionaCabeca(canvas, _cabecaGiro * 0.9, pescoco: 31);
    canvas.scale(_cabecaDoEstagio);
    _sombraDoQueixo(canvas, 78, 62);

    // Orelhas pequenas e altas: na lontra elas quase somem na cabeça.
    // Orelhas pequenas e baixas, quase no lado da cabeça chata.
    _orelhaRedonda(canvas, const Offset(-31, -16), 11, 9, -0.30);
    _orelhaRedonda(canvas, const Offset(31, -16), 11, 9, 0.30);

    canvas.drawPath(
      _bolha(
        // Cabeça chata e larga, mais baixa que a da capivara.
        Rect.fromCenter(center: Offset.zero, width: 78, height: 62),
        base: 1.02 + _queixoDesce / 31,
      ),
      _p(pelo),
    );
    _rostoVira(canvas);

    // Máscara clara do focinho, larga e baixa.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 14), width: 50, height: 34),
        topo: 0.9,
      ),
      _p(claro),
    );

    // Bigodes presos na borda do focinho, dos dois lados.
    _bigodes(canvas, const Offset(-22, 12));
    _bigodes(canvas, const Offset(22, 12), lado: 1);

    // Focinheira escura, o traço que faz ler "lontra" e não "gato".
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 6), width: 19, height: 13),
        base: 1.1,
      ),
      _p(sombraForte),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-3.5, 3), width: 6, height: 3.5),
      _p(luz.withValues(alpha: 0.45)),
    );

    _boca(canvas);
    if (feliz) {
      _bochecha(canvas, const Offset(-30, 11), const Offset(30, 11));
    }
    // A lontra come segurando a comida com as duas patas da frente, junto
    // da boca, e a leva à boca a cada mordida (pesquisa 24: lontras comem
    // com as mãos, e na água rolam de costas para comer).
    if (_comComida) {
      final sobe = pose.mastiga * 4;
      final c = pose.comendoDaMao ? petiscoDe(species) : comidaDe(species);
      pintaComida(canvas, c, Offset(0, 30 - sobe), 13, angulo: 0.1);
      for (final lado in [-1.0, 1.0]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(lado * 9, 34 - sobe),
            width: 13,
            height: 10,
          ),
          _p(sombraForte),
        );
      }
    }

    _olho(canvas, const Offset(-21, -12), 7.5);
    _olho(canvas, const Offset(21, -12), 7.5);
    _rostoVolta(canvas);
    _veste(canvas, 84, 74);

    canvas.restore();
  }

  // ======================================================================
  // TARTARUGA — de frente: casco em cúpula, cabeça grande saindo por cima
  //
  // De perfil o casco virava uma meia-lua com uma cabecinha espetada na
  // ponta. De frente a cúpula sustenta a cara, que é o que a gente olha.
  // ======================================================================

  void _tartaruga(Canvas canvas) {
    final amp = pose.amplitude;
    // A cabeça recolhe e estica de leve ao respirar, e sai mais quando fazem
    // carinho — é o gesto que todo mundo reconhece numa tartaruga.
    // Nadando ela estica o pescoço para manter o focinho fora d'água — o
    // corpo afundou 13 px e sem isto a cabeça entraria junto, o que numa
    // tartaruga é afogamento, não nado.
    // Susto e festa da espécie (laudo 31 R3/R4): assustado, o tracajá
    // recolhe — a cabeça desce 10 e dobra de lado, as patas entram 6 sob o
    // casco; festejando, o pescoço sai todo (+14).
    final sustoDoToco = pose.vida.susto.clamp(0.0, 1.0);
    final festaDoToco = pose.vida.festa.clamp(0.0, 1.0);
    final estica =
        (pose.boia * 2.4 * amp) +
        pose.carinho * 7 +
        (nadando ? 11 : 0) +
        // Recolhendo a cabeça (−) ou esticando o pescoço ao sol (+).
        pose.vida.pescoco * 9 * amp -
        10 * sustoDoToco +
        14 * festaDoToco;

    // Patas: saem por baixo do casco, nos cantos. Na água elas viram remos —
    // a tartaruga-de-orelha-vermelha nada com as quatro.
    // Em y 56 (era 52): os pés tocam o chão, abaixo do plastrão (TOCO-08),
    // e é a pata que se vê alternar no arrasto.
    _pata(
      canvas,
      Offset(-47 + 6 * sustoDoToco, 56),
      25,
      22,
      sombra,
      pose.pernas * amp * 1.4,
      rema: -1,
    );
    _pata(
      canvas,
      Offset(47 - 6 * sustoDoToco, 56),
      25,
      22,
      sombra,
      -pose.pernas * amp * 1.4,
      rema: 1,
    );

    // --- casco, atrás da cabeça -------------------------------------------
    //
    // O casco fica **atrás**: desenhado por cima, ele engolia o queixo e o
    // bicho parecia dentro de uma panela. Atrás, lê como carapaça nas costas.
    final casco = _bolha(
      Rect.fromCenter(center: const Offset(0, 26), width: 102, height: 78),
      topo: 0.94,
      base: 0.94,
    );
    // O casco é queratina, não pele: puxa para o oliva-amarronzado, senão
    // fica um verde chapado igual ao da cabeça.
    final corDoCasco = Color.lerp(sombra, const Color(0xFF6B5334), 0.32)!;
    canvas.drawPath(casco, _p(corDoCasco));

    canvas.save();
    canvas.clipPath(casco);
    // Escudos: precisam de contraste de verdade. Verde sobre verde some, e o
    // casco vira uma bolha lisa.
    final linha = _traco(Cores.tintaA(0.32), 2.6);

    // Fileira central mais clara: é ela que dá a cúpula.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 32), width: 62, height: 60),
        topo: 0.92,
      ),
      _p(Color.lerp(corDoCasco, Cores.superficie, 0.16)!),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-31, 62)
        ..cubicTo(-31, 4, 31, 4, 31, 62),
      linha,
    );
    // Fileira marginal: o anel de baixo.
    canvas.drawPath(
      Path()
        ..moveTo(-52, 48)
        ..cubicTo(-30, 32, 30, 32, 52, 48),
      linha,
    );
    for (final x in [-17.0, 0.0, 17.0]) {
      canvas.drawLine(Offset(x, 4), Offset(x * 1.1, 34), linha);
    }
    for (final x in [-42.0, -22.0, 22.0, 42.0]) {
      canvas.drawLine(Offset(x, 34), Offset(x * 1.08, 64), linha);
    }
    // Plastrão: a faixa clara da barriga, na frente do casco.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 54), width: 68, height: 42),
        topo: 0.9,
      ),
      _p(barriga),
    );
    canvas.restore();

    // --- cabeça, na frente ------------------------------------------------
    canvas.save();
    // No susto a cabeça dobra de lado (16 para o lado da cauda, −0,35 rad):
    // é a leitura do susto numa tartaruga, não o olho arregalado. E 3° de
    // giro no repouso (laudo 31 R11), para o pescoço não ser um eixo.
    canvas.translate(16 * sustoDoToco, -36 - estica + _cabecaDesce);
    _cabecaSemFolego(canvas);
    _posicionaCabeca(
      canvas,
      _cabecaGiro * 0.8 + 0.052 - 0.35 * sustoDoToco,
      pescoco: 30,
    );
    canvas.scale(_cabecaDoEstagio);

    // Pescoço: sai da cabeça e entra no casco. É ele que faz a cabeça
    // **sair** do casco em vez de ficar apoiada nele como um chapéu.
    //
    // E ele estica junto. Com comprimento fixo, levantar a cabeça 11 px para
    // fora d'água abria um buraco entre a cabeça e a carapaça: a tartaruga
    // ficava com a cara boiando solta. O 38 + 1.34·estica mantém a ponta do
    // pescoço sempre uns 5 px **dentro** do casco, em qualquer esticada.
    final pescoco = 38 + estica * 1.34;
    canvas.drawPath(
      Path()
        ..moveTo(-17, 6)
        ..cubicTo(-19, pescoco, 19, pescoco, 17, 6)
        ..cubicTo(9, 14, -9, 14, -17, 6)
        ..close(),
      _p(claro),
    );

    // Cabeça menor que o casco: numa tartaruga a carapaça é o corpo.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: 66, height: 60),
        base: 1.04 + _queixoDesce / 30,
      ),
      _p(pelo),
    );

    // A listra vermelha atrás do olho — é dela que vem o nome
    // "tartaruga-de-orelha-vermelha", e é o que tira a cabeça de "bola
    // verde". Antes era um oval lavado que ninguém via.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(lado * 22, -10)
          ..cubicTo(lado * 29, -10, lado * 32, -6, lado * 32, 0)
          ..cubicTo(lado * 29, 4, lado * 24, 3, lado * 22, -1)
          ..close(),
        _p(Color.lerp(Cores.acento, Cores.terracotaDaArte, 0.35)!),
      );
    }

    // As listras ficam no contorno (são do lado da cabeça); o rosto vira.
    _rostoVira(canvas);
    _narina(canvas, const Offset(-6, 6));
    _narina(canvas, const Offset(6, 6));
    _boca(canvas);
    // Sem bochecha rosada: réptil não cora, e sobre o verde a mancha rosa
    // ficava um adesivo colado.

    // Sem sobrancelha: a tartaruga não tem (TOCO-18) — a saudade e o susto
    // ficam na pálpebra e na cabeça.
    _olho(canvas, const Offset(-14, -9), 7, sobrancelha: false);
    _olho(canvas, const Offset(14, -9), 7, sobrancelha: false);
    _rostoVolta(canvas);
    _veste(canvas, 66, 60);

    canvas.restore();
  }

  // ======================================================================
  // CORUJA — disco facial, tufos presos à cabeça, asas dobradas no corpo
  // ======================================================================

  /// As asas da coruja em voo, vistas de frente (pesquisa 24).
  ///
  /// Antes eram dois remos de forma fixa que só giravam para cima e para
  /// baixo, como asa de brinquedo. Agora seguem o ciclo de batida da
  /// coruja: asas largas e arredondadas, a descida é o golpe de força (asa
  /// aberta inteira, primárias abertas) e a subida é recolhida (a asa
  /// dobra no punho e encolhe); a ponta vem atrasada em relação ao punho; e
  /// a ponta desenha um "U" visto de frente. Planando, ficam abertas num
  /// leve V; freando para pousar, sobem.
  void _asasDeVoo(Canvas canvas, Color cor) {
    final vida = pose.vida;
    final phi = pose.ciclo % 1.0;
    const descida = 0.58;
    const alto = 0.95; // rad: asa no alto da batida
    const baixo = -0.62; // rad: no fim da descida
    double theta, abre, atraso;
    if (phi < descida) {
      final u = phi / descida;
      final e = Curves.easeInOutSine.transform(u);
      theta = alto + (baixo - alto) * e;
      abre = 1;
      // Descendo, a ponta fica para trás (para cima) e as penas abrem.
      atraso = 0.26 * math.sin(math.pi * u);
    } else {
      final u = (phi - descida) / (1 - descida);
      final e = Curves.easeInOut.transform(u);
      theta = baixo + (alto - baixo) * e;
      // Subindo, a asa dobra no punho e encolhe: subida sem resistência.
      abre = 1 - 0.42 * math.sin(math.pi * u);
      atraso = -0.5 * math.sin(math.pi * u);
    }
    var penasAbertas = phi < descida ? 1.0 : 0.25;
    // Planeio e freio são poses que a batida vai alcançando, e não trocas
    // secas: cada uma entra pelo seu fator suave.
    double mistura(double de, double para, double k) => de + (para - de) * k;
    final pl = vida.planeio.clamp(0.0, 1.0);
    theta = mistura(
      theta,
      0.16 + math.sin(pose.ciclo * math.pi * 4) * 0.02,
      pl,
    );
    abre = mistura(abre, 1, pl);
    atraso = mistura(atraso, 0.1, pl);
    penasAbertas = mistura(penasAbertas, 0.6, pl);
    final fr = vida.freio.clamp(0.0, 1.0);
    theta = mistura(
      theta,
      1.15 + math.sin(pose.ciclo * math.pi * 2) * 0.08,
      fr,
    );
    abre = mistura(abre, 0.95, fr);
    atraso = mistura(atraso, 0.3, fr);
    penasAbertas = mistura(penasAbertas, 0.6, fr);
    for (final lado in [-1.0, 1.0]) {
      final ombro = Offset(lado * 24, -24);
      Offset em(Offset de, double ang, double r) =>
          de + Offset(lado * math.cos(ang) * r, -math.sin(ang) * r);
      // Asa larga e redonda, maior que o corpo de cada lado: é a asa da
      // coruja, de muita área para pouco peso.
      final punho = em(ombro, theta, 44 * abre);
      final angPonta = theta + atraso;
      final ponta = em(punho, angPonta, 56 * (0.55 + 0.45 * abre));
      final costas = Offset(lado * 20, 12);
      final asa = Path()
        ..moveTo(ombro.dx, ombro.dy)
        ..quadraticBezierTo(
          (ombro.dx + punho.dx) / 2,
          math.min(ombro.dy, punho.dy) - 9 * abre,
          punho.dx,
          punho.dy,
        )
        ..quadraticBezierTo(
          (punho.dx + ponta.dx) / 2 + lado * 3,
          (punho.dy + ponta.dy) / 2 - 6,
          ponta.dx,
          ponta.dy,
        );
      // Borda de fuga recortada: a ponta de cada pena, da ponta da asa de
      // volta às costas, numa curva que desce abaixo da linha reta (a asa
      // tem fundura). As primárias, perto da ponta, abrem no golpe.
      final baixo = em(Offset.zero, angPonta - math.pi / 2, 1);
      final fundura = 26 * abre;
      const penas = 6;
      var antes = ponta;
      for (var i = 1; i <= penas; i++) {
        final t = i / penas;
        final barriga = math.sin(math.pi * t);
        final p = Offset.lerp(ponta, costas, t)! + baixo * (fundura * barriga);
        // A pena: o meio do arco sai um pouco mais (o recorte).
        final meio =
            Offset.lerp(antes, p, 0.5)! +
            baixo * (5 + 4 * penasAbertas * (1 - t));
        asa.quadraticBezierTo(meio.dx, meio.dy, p.dx, p.dy);
        antes = p;
      }
      asa.close();
      canvas.drawPath(asa, _p(cor));
      // Dentro da asa (recortado nela): as primárias como sulcos curtos e o
      // claro das coberteiras.
      canvas.save();
      canvas.clipPath(asa);
      final risco = _traco(Cores.tintaA(0.18), 1.6);
      for (var i = 0; i < 4; i++) {
        final de = Offset.lerp(punho, ponta, 0.2 + i * 0.12)!;
        final ang = angPonta - math.pi / 2 - 0.25 * penasAbertas;
        canvas.drawLine(de, em(de, ang, 16), risco);
      }
      canvas.drawPath(
        Path()
          ..moveTo(ombro.dx, ombro.dy + 4)
          ..quadraticBezierTo(
            (ombro.dx + punho.dx) / 2,
            (ombro.dy + punho.dy) / 2 + 2,
            punho.dx,
            punho.dy + 6,
          ),
        _traco(Colors.white.withValues(alpha: 0.10), 7),
      );
      canvas.restore();
    }
  }

  void _coruja(Canvas canvas) {
    final amp = pose.amplitude;
    final asa = pose.asa * amp;

    // Pés: pousados no repouso, recolhidos no voo.
    //
    // Coruja voando com as garras esticadas para baixo é coruja atacando, e
    // o que a cena diz é que ela está indo a algum lugar. Recolhidos contra
    // o corpo, o desenho lê como voo de deslocamento — que é a atividade
    // dela na sessão de foco.
    //
    // Pernas longas e claras: a buraqueira fica de pé no chão, alta sobre
    // as pernas — é o traço que a separa das corujas de galho.
    //
    // No voo os pés ficam recolhidos contra a barriga, dedos fechados e
    // menores (60 %): de pé num chão invisível ela lia como coruja parada
    // batendo asa. Freando para pousar, as pernas estendem 10 u para baixo
    // (o flare, laudo 34 R12). No chão, as pernas alternam no passo: a
    // livre dobra e sobe (NINA-09: dois palitos rígidos saindo juntos).
    final freio = pose.vida.freio.clamp(0.0, 1.0);
    final recolhe = pose.voando ? 14.0 * (1 - freio) - 10.0 * freio : 0.0;
    final fecha = pose.voando ? 1 - 0.6 * (1 - freio) : 0.0;
    final garra = _traco(const Color(0xFFCDBB9C), 4.2)
      ..strokeJoin = StrokeJoin.round;
    for (final x in [-15.0, 15.0]) {
      final noAr = pose.voando
          ? 0.0
          : (x < 0 ? pose.vida.pataEsquerda : pose.vida.pataDireita) * amp;
      // A perna livre sobe 8 u e dobra no joelho, para trás.
      final sobe = noAr * 8;
      final joelho = Offset(
        x + (x < 0 ? 1 : -1) * noAr * 5,
        42 - recolhe * 0.7 - sobe * 0.6,
      );
      final pe = Offset(x, 52 - recolhe - sobe);
      canvas.drawPath(
        Path()
          ..moveTo(x, 30 - recolhe * 0.4)
          ..quadraticBezierTo(joelho.dx, joelho.dy, pe.dx, pe.dy),
        garra,
      );
      final escala = 1 - 0.4 * fecha;
      for (final dedo in [-1.0, 0.0, 1.0]) {
        final d = dedo * (1 - 0.7 * fecha);
        canvas.drawPath(
          Path()
            ..moveTo(pe.dx, pe.dy)
            ..cubicTo(
              pe.dx + d * 7 * escala,
              pe.dy + 3 * escala,
              pe.dx + d * 10 * escala,
              pe.dy + 5 * escala,
              pe.dx + d * 11 * escala,
              pe.dy + 7 * escala,
            ),
          garra,
        );
      }
    }

    // As asas abertas nascem nas costas: atrás do corpo, de frente.
    if (pose.voando) _asasDeVoo(canvas, sombraForte);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, -6), width: 90, height: 84),
      topo: 0.84,
      base: 1.02,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 10), width: 60, height: 60),
        topo: 0.9,
      ),
      _p(barriga),
    );
    // Peito barrado de marrom, como o da buraqueira.
    final penas = _traco(sombra.withValues(alpha: 0.32), 2);
    for (var linha = 0; linha < 3; linha++) {
      final y = 4.0 + linha * 12;
      for (var i = -1; i <= 1; i++) {
        final x = i * 17.0 + (linha.isOdd ? 8 : 0);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 17, height: 12),
          math.pi,
          math.pi,
          false,
          penas,
        );
      }
    }
    canvas.restore();

    // Asas dobradas, encostadas no corpo — abrem de leve ao respirar.
    // Mais escuras e mais largas que antes: encostadas no corpo com a mesma
    // cor, elas sumiam.
    // Assustada as penas sobem (as asas dobradas abrem 6, NINA-03); na festa
    // as três batidas de asa dobrada (+8, laudo 32 R12).
    final sustoDaNina = pose.vida.susto.clamp(0.0, 1.0);
    final festaDaNina = pose.vida.festa.clamp(0.0, 1.0);
    for (final lado in pose.voando ? const <double>[] : const [-1.0, 1.0]) {
      // ≤ 0,8 u com a respiração (MOV-10); susto e festa abrem mais.
      final abre = (asa * 0.6 + 4 * sustoDaNina + 8 * festaDaNina) * lado;
      // Borda externa quase no limite do corpo (±47): a asa fica **dobrada**
      // sobre ele e só se afasta ao respirar. Chegando a ±56 no repouso ela
      // virava um halo escuro atrás do bicho em vez de asa.
      final asaPath = Path()
        ..moveTo(lado * 32, -28)
        ..cubicTo(lado * (47 + abre), -8, lado * (45 + abre), 22, lado * 28, 34)
        ..cubicTo(lado * 23, 10, lado * 25, -14, lado * 32, -28)
        ..close();
      canvas.drawPath(asaPath, _p(sombraForte));

      // Penas recortadas na própria asa: soltas, os riscos vazavam a
      // silhueta e pareciam arranhões no fundo.
      canvas.save();
      canvas.clipPath(asaPath);
      final risco = _traco(Cores.tintaA(0.18), 1.8);
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(lado * 24, 4 + i * 9),
          Offset(lado * (46 + abre), 12 + i * 9),
          risco,
        );
      }
      canvas.restore();
    }

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    // -28 e não -32: a ponta do tufo ficava a 3 px do topo do quadro, e ao
    // se espreguiçar (corpo 7% maior e 4 px acima) ela era cortada.
    canvas.translate(0, -28 + pose.respiro * amp * 0.6 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    _posicionaCabeca(canvas, _cabecaGiro * 0.8, pescoco: 32);
    canvas.scale(_cabecaDoEstagio);
    _sombraDoQueixo(canvas, 84, 68);

    // Sem tufos: a coruja-buraqueira, a nossa coruja de chão, tem a cabeça
    // redonda e lisa (laudo 07, R4). O tufo era da coruja de galho.
    final cabeca = _bolha(
      Rect.fromCenter(center: Offset.zero, width: 84, height: 68),
      base: 0.96,
    );
    canvas.drawPath(cabeca, _p(pelo));

    // As pintas claras da cabeça.
    canvas.save();
    canvas.clipPath(cabeca);
    for (final (x, y) in const [
      (-26.0, -24.0),
      (-12.0, -28.0),
      (2.0, -30.0),
      (16.0, -27.0),
      (28.0, -22.0),
      (-34.0, -12.0),
      (35.0, -10.0),
    ]) {
      canvas.drawCircle(Offset(x, y), 1.9, _p(claro));
    }
    canvas.restore();

    // O rosto da coruja ocupa a cabeça inteira: ao virar, os discos
    // passariam da borda. Ele vira dentro do contorno, recortado nele.
    canvas.save();
    canvas.clipPath(cabeca);
    _rostoVira(canvas);

    // O disco facial, mais claro que o pelo.
    final disco = Color.lerp(pelo, Cores.superficie, 0.32)!;
    for (final lado in [-1.0, 1.0]) {
      _oval(
        canvas,
        Rect.fromCenter(center: Offset(lado * 19, 3), width: 42, height: 44),
        disco,
      );
    }

    // As sobrancelhas brancas e o queixo branco: a cara da buraqueira.
    //
    // A mancha branca **é** a sobrancelha dela, e é por ela que o humor
    // passa. Com a ponta de dentro mais baixa que a de fora ela formava um
    // V, e na saudade, com a sobrancelha de tristeza pintada por cima, a
    // coruja lia como desconfiada (auditoria da Onda 3, 11b-M2). Agora a
    // ponta de dentro sobe na tristeza e no sono, e fica reta no resto.
    final branco = Color.lerp(Cores.superficie, pelo, 0.04)!;
    final ergue = switch (mood) {
      Mood.missingYou => 1.0,
      Mood.sleepy => 0.4,
      _ => 0.0,
    };
    // No susto e no grito as duas sobrancelhas sobem 5 (NINA-03).
    canvas.save();
    canvas.translate(
      0,
      -5 * math.max(pose.vida.susto, pose.vida.grito).clamp(0.0, 1.0),
    );
    for (final lado in [-1.0, 1.0]) {
      final dentroY = -11 - 7 * ergue;
      final foraY = -10 + 5 * ergue;
      canvas.drawPath(
        Path()
          ..moveTo(lado * 4, dentroY)
          ..quadraticBezierTo(lado * 16, -18 - 2 * ergue, lado * 34, foraY)
          ..quadraticBezierTo(lado * 18, -13 + 2 * ergue, lado * 4, dentroY + 5)
          ..close(),
        _p(branco),
      );
    }
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(-14, 20)
        ..quadraticBezierTo(0, 30, 14, 20)
        ..quadraticBezierTo(0, 25, -14, 20)
        ..close(),
      _p(branco),
    );

    // Sem a sobrancelha de tristeza por cima: a branca já faz esse papel.
    _olho(canvas, const Offset(-19, 2), 9, coruja: true, sobrancelha: false);
    _olho(canvas, const Offset(19, 2), 9, coruja: true, sobrancelha: false);

    // Bico claro, amarelado, entre os discos. A mandíbula de baixo gira na
    // articulação (0..25°) com a abertura; a de cima fica (ver [_bico]).
    _bico(
      canvas,
      cor: const Color(0xFFD9C79A),
      base: 7,
      ponta: 19,
      anguloMax: 25,
    );
    _naBoca(canvas, const Offset(0, 16), 20);

    if (feliz) _bochecha(canvas, const Offset(-34, 17), const Offset(34, 17));
    canvas.restore();
    _veste(canvas, 86, 70);
    canvas.restore();
  }

  // ======================================================================
  // AXOLOTE — guelras que balançam, a marca da espécie
  // ======================================================================

  void _axolote(Canvas canvas) {
    final amp = pose.amplitude;
    final rema = pose.pernas * amp;
    // As guelras têm ritmo próprio e abrem mais quando ele está na água.
    // Nadando elas vão no compasso da braçada: guelra é respiração, e quem
    // se esforça respira no ritmo do esforço.
    final abana = pose.nadando
        ? pose.pernas * amp * 1.2
        : (pose.cauda * amp) * 0.8;

    // A cauda longa com a barbatana clara por cima e por baixo: sem ela o
    // axolote não é axolote (laudo 07, R5). Nasce atrás do corpo e balança
    // no ritmo próprio da cauda.
    // Nadando, a cauda é o motor: onda de enguia com a ponta varrendo
    // ≥ 13 u (laudo 32 R7); à toa, só o balanço lento.
    final varre = pose.nadando
        ? math.sin(pose.ciclo * math.pi * 2 - 1.2) *
              14 *
              amp *
              pose._forcaDoNado
        : pose.cauda * amp * 6;
    final cauda = Path()
      ..moveTo(16, 30)
      ..cubicTo(40, 44, 62 + varre * 0.5, 40, 82 + varre, 22 + varre * 0.6)
      ..cubicTo(64 + varre * 0.5, 30, 44, 30, 20, 18)
      ..close();
    final barbatana = Path()
      ..moveTo(22, 24)
      ..cubicTo(42, 14, 66 + varre * 0.5, 10, 84 + varre, 16 + varre * 0.6)
      ..cubicTo(70 + varre * 0.5, 48, 44, 52, 22, 42)
      ..close();
    canvas.drawPath(barbatana, _p(Color.lerp(claro, Cores.superficie, 0.35)!));
    canvas.drawPath(cauda, _p(pelo));

    _pata(
      canvas,
      Offset(-20, 49 + rema * 1.4),
      16,
      12,
      sombra,
      0,
      dedos: false,
      rema: -1,
    );
    _pata(
      canvas,
      Offset(20, 49 - rema * 1.4),
      16,
      12,
      sombra,
      0,
      dedos: false,
      rema: 1,
    );

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 20), width: 82, height: 71),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 31), width: 56, height: 55),
        topo: 0.9,
      ),
      _p(claro),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -28 + pose.respiro * amp * 0.7 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    _posicionaCabeca(canvas, _cabecaGiro * 0.9, pescoco: 36);
    canvas.scale(_cabecaDoEstagio);
    _sombraDoQueixo(canvas, 86, 74);

    // Guelras antes da cabeça: três ramos de cada lado, cada um uma haste
    // com filamentos — as "penas" que fazem o axolote (laudo 07, R5). Eram
    // três folhas lisas, que liam como orelhas de enfeite. Os filamentos
    // crescem com o estágio.
    final corDaGuelra = Color.lerp(pelo, Cores.acento, 0.34)!;
    final corDoFilamento = Color.lerp(corDaGuelra, Cores.superficie, 0.18)!;
    final filamentos = switch (estagio) {
      EstagioDoBicho.inicio || EstagioDoBicho.filhote => 3,
      EstagioDoBicho.jovem => 4,
      EstagioDoBicho.adulto => 6,
      EstagioDoBicho.pleno => 7,
    };
    final haste = _traco(corDaGuelra, 4.2)..strokeCap = StrokeCap.round;
    final fio = _traco(corDoFilamento, 2.6)..strokeCap = StrokeCap.round;
    // Susto: guelras para trás (fecham 18 % e sobem, laudo 32 R12); festa:
    // abertas.
    final sustoDoLume = pose.vida.susto.clamp(0.0, 1.0);
    final festaDoLume = pose.vida.festa.clamp(0.0, 1.0);
    canvas.save();
    canvas.scale(1 - 0.18 * sustoDoLume + 0.08 * festaDoLume, 1);
    for (final lado in [-1.0, 1.0]) {
      final l = lado;
      final a = (abana * 3 - 7 * sustoDoLume + 4 * festaDoLume) * l;
      final ramos = [
        Path()
          ..moveTo(l * 32, -16)
          ..cubicTo(l * 44, -28 + a, l * 54, -33 + a, l * 62, -32 + a),
        Path()
          ..moveTo(l * 36, -1)
          ..cubicTo(l * 48, -4 - a, l * 56, -2 - a, l * 63, 3 - a),
        Path()
          ..moveTo(l * 33, 13)
          ..cubicTo(l * 44, 16 + a, l * 51, 21 + a, l * 56, 28 + a),
      ];
      for (final ramo in ramos) {
        canvas.drawPath(ramo, haste);
        for (final m in ramo.computeMetrics()) {
          for (var k = 0; k < filamentos; k++) {
            final d =
                m.length * (0.25 + 0.72 * k / math.max(1, filamentos - 1));
            final t = m.getTangentForOffset(d);
            if (t == null) continue;
            // Filamento para fora da haste, inclinado para a ponta.
            final normal = Offset(-t.vector.dy, t.vector.dx) * -l;
            final dir = (normal + t.vector * 0.6) / 1.17;
            canvas.drawLine(t.position, t.position + dir * 7.5, fio);
          }
        }
      }
    }
    canvas.restore();

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 0.7), width: 86, height: 73),
        base: 1.04 + _queixoDesce / 36.5,
      ),
      _p(pelo),
    );
    _rostoVira(canvas);

    _boca(canvas);
    if (feliz) _bochecha(canvas, const Offset(-30, 6), const Offset(30, 6));

    _olho(canvas, const Offset(-20, -6), 7.5);
    _olho(canvas, const Offset(20, -6), 7.5);
    _rostoVolta(canvas);
    _veste(canvas, 86, 73);

    canvas.restore();
  }

  // ======================================================================
  // PINGUIM — barriga clara, nadadeiras coladas, pés laranja
  // ======================================================================

  /// O pé do magalhães: escuro, com manchas rosadas.
  Color get _peDoPinguim => Color.lerp(sombraForte, Cores.tinta, 0.35)!;
  Color get _manchaDoPe => const Color(0xFFD9A5A3);

  void _pinguim(Canvas canvas) {
    final amp = pose.amplitude;
    final asa = pose.asa * amp;
    final passo = pose.pernas * amp;

    // Pés do pinguim-de-magalhães: escuros com manchas rosadas, e não
    // laranja — laranja de bico e pé é pinguim de desenho genérico, e o
    // bico igual ao da coruja apagava a espécie (laudo 07, R6). Na água não
    // caminham: ficam esticados atrás como leme, e quem move o pinguim são
    // as nadadeiras. Um pinguim que rema com o pé é um pato.
    final leme = pose.nadando ? 7.0 : 0.0;
    for (final lado in [-1.0, 1.0]) {
      final desloca = lado * passo * 1.4;
      canvas.save();
      canvas.translate(lado * (17 + leme * 0.6) + desloca, 50 + leme);
      canvas.drawPath(
        _bolha(
          Rect.fromCenter(center: Offset.zero, width: 20, height: 13),
          base: 0.86,
        ),
        _p(_peDoPinguim),
      );
      for (final (dx, dy) in const [(-4.5, -1.0), (3.0, 1.5), (5.5, -2.5)]) {
        canvas.drawCircle(Offset(dx, dy), 1.8, _p(_manchaDoPe));
      }
      final dedo = _traco(Color.lerp(_peDoPinguim, Cores.tinta, 0.4)!, 1.5);
      for (final dx in [-4.4, 0.0, 4.4]) {
        canvas.drawLine(Offset(dx, 3.2), Offset(dx, 6.3), dedo);
      }
      canvas.restore();
    }

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 12), width: 90, height: 91),
      topo: 0.9,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    // Barriga: quase branca, é ela que faz ler "pinguim".
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 17), width: 60, height: 82),
        topo: 0.9,
      ),
      _p(Color.lerp(claro, Cores.superficie, 0.62)!),
    );
    // As duas faixas escuras do peito — a marca do magalhães. Só no adulto:
    // o filhote e o jovem ainda não as têm, e elas chegando é um sinal de
    // crescimento que se vê de longe.
    if (estagio.index >= EstagioDoBicho.adulto.index) {
      final faixa = _traco(sombraForte, 4.5)..strokeCap = StrokeCap.butt;
      canvas.drawPath(
        Path()
          ..moveTo(-34, -2)
          ..quadraticBezierTo(0, 10, 34, -2),
        faixa,
      );
      canvas.drawPath(
        Path()
          ..moveTo(-30, 30)
          ..quadraticBezierTo(-26, 12, 0, 12)
          ..quadraticBezierTo(26, 12, 30, 30),
        faixa,
      );
    }
    canvas.restore();

    // Nadadeiras: coladas no corpo, abrem de leve ao respirar — e **remam**
    // quando ele está na água, uma subindo enquanto a outra desce.
    //
    // O pinguim "voa" embaixo d'água: é a nadadeira que o empurra, e ela
    // alterna. Abrindo as duas juntas, como no repouso, ele parecia estar
    // dando de ombros.
    // Nadando ele "voa" embaixo d'água: batida BILATERAL, as duas descem
    // juntas para fora e para baixo e sobem recolhendo (laudo 32 R11);
    // alternadas liam como dar de ombros. Em repouso abrem ≤ 0,8 u com a
    // respiração (MOV-10: a 3 u era uma asa abanando a cada fôlego).
    for (final lado in [-1.0, 1.0]) {
      final alterna = pose.nadando ? lado : 1.0;
      // Susto: nadadeiras abertas (NINO-06); festa: erguidas, a exibição
      // extática do magalhães (laudo 32 R9).
      final sustoDoNino = pose.vida.susto.clamp(0.0, 1.0);
      final festaDoNino = pose.vida.festa.clamp(0.0, 1.0);
      final abre =
          (pose.nadando ? asa * 3 : asa * 0.8) * lado * alterna +
          (8 * sustoDoNino + 14 * festaDoNino) * lado;
      final sobe =
          (pose.nadando ? asa * 5 * lado : 0.0) -
          4 * sustoDoNino -
          22 * festaDoNino;
      // Borda externa em ±44 num corpo de ±45: a nadadeira fica **dentro**
      // do contorno. Passando dele, sobrava uma fresta do fundo entre as
      // duas, que lia como risco branco no bicho.
      canvas.drawPath(
        Path()
          ..moveTo(lado * 30, -14 + sobe)
          ..cubicTo(
            lado * (44 + abre),
            0 + sobe,
            lado * (43 + abre),
            24 + sobe,
            lado * 26,
            36 + sobe,
          )
          ..cubicTo(
            lado * 22,
            14 + sobe,
            lado * 23,
            -4 + sobe,
            lado * 30,
            -14 + sobe,
          )
          ..close(),
        _p(sombraForte),
      );
    }

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -34 + pose.respiro * amp * 0.6 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    _posicionaCabeca(canvas, _cabecaGiro * 0.9, pescoco: 30);
    canvas.scale(_cabecaDoEstagio);
    _sombraDoQueixo(canvas, 72, 60);

    canvas.drawPath(
      _bolha(Rect.fromCenter(center: Offset.zero, width: 72, height: 60)),
      _p(pelo),
    );

    // A faixa branca em C: nasce acima do olho, contorna a bochecha e fecha
    // no queixo. É o desenho da cabeça do magalhães, e o olho fica inteiro
    // no escuro, dentro da curva.
    canvas.save();
    canvas.clipPath(
      _bolha(Rect.fromCenter(center: Offset.zero, width: 72, height: 60)),
    );
    _rostoVira(canvas);
    final branco = _p(Color.lerp(claro, Cores.superficie, 0.70)!);
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(lado * 11, -22)
          ..cubicTo(lado * 30, -27, lado * 41, -4, lado * 28, 16)
          ..quadraticBezierTo(lado * 16, 29, 0, 30)
          ..lineTo(0, 25.5)
          ..quadraticBezierTo(lado * 13, 25, lado * 23, 13)
          ..cubicTo(lado * 33, -2, lado * 26, -18, lado * 12, -17.5)
          ..close(),
        branco,
      );
      // A pele rosada entre o olho e o bico. No auge ela cresce e aviva,
      // como na época de ninho: é a marca real do adulto pleno.
      final auge = estagio == EstagioDoBicho.pleno;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lado * 8, 2),
          width: auge ? 10 : 7,
          height: auge ? 7 : 5,
        ),
        _p(auge ? const Color(0xFFEE8E8B) : const Color(0xFFE7A3A0)),
      );
    }
    canvas.restore();
    _rostoVira(canvas);

    _olho(canvas, const Offset(-15, -3), 7);
    _olho(canvas, const Offset(15, -3), 7);

    // Bico escuro e robusto, com a faixa clara perto da ponta do
    // magalhães — o único traço reto do bicho. A mandíbula de baixo gira na
    // articulação (0..30°) com a abertura (ver [_bico]); o remendo terracota
    // dentro do bico fechado, que fazia as vezes de "aberto", saiu.
    final bico = Color.lerp(sombraForte, Cores.tinta, 0.55)!;
    _bico(
      canvas,
      cor: bico,
      base: 5,
      ponta: 17,
      anguloMax: 30,
      faixa: Color.lerp(bico, Cores.superficie, 0.45)!,
      faixaEm: 12,
      lingua: true,
    );
    _naBoca(canvas, const Offset(0, 12), 18);
    _rostoVolta(canvas);
    _veste(canvas, 72, 60);

    canvas.restore();
  }

  // ======================================================================
  // GATA — orelhas triangulares, focinho em coração, bigodes longos
  // ======================================================================

  void _gata(Canvas canvas) {
    final amp = pose.amplitude;
    // Brincando, a cauda chicoteia no compasso do salto. É o rabo que
    // denuncia o bicho animado; no ritmo solto de sempre ele parecia
    // distraído no meio do pulo.
    final sustoDaMel = pose.vida.susto.clamp(0.0, 1.0);
    final festaDaMel = pose.vida.festa.clamp(0.0, 1.0);
    final balanca =
        (pose.brincando ? pose.pernas * amp * 1.5 : pose.cauda * amp) *
        (1 + festaDaMel);

    // Cauda tubular, na cor do pelo, com anéis: a cunha escura de antes lia
    // como castor (laudo 08, R6). O humor decide a forma — em pé com a
    // ponta em gancho é o cumprimento do gato ao humano (radiante); baixa e
    // enrolada nos pés na saudade e no sono.
    (double, double, double) formaDoRabo(Mood m) => switch (m) {
      Mood.radiant => (52.0, -34.0, 1.0),
      Mood.content => (60.0, -14.0, 0.5),
      Mood.neutral => (64.0, 4.0, 0.2),
      Mood.sleepy => (40.0, 52.0, 0.0),
      Mood.missingYou => (46.0, 50.0, 0.0),
    };
    final topoX = _porHumor((m) => formaDoRabo(m).$1);
    // Susto: cauda em pé e arrepiada; festa: em pé (MEL-10, MEL-11).
    final topoY =
        _porHumor((m) => formaDoRabo(m).$2) - 20 * sustoDaMel - 12 * festaDaMel;
    final gancho = _porHumor((m) => formaDoRabo(m).$3);
    final rabo = Path()
      ..moveTo(26, 40)
      ..cubicTo(
        50 + balanca * 3,
        44,
        topoX + 6 + balanca * 6,
        (40 + topoY) / 2 + balanca * 4,
        topoX + balanca * 8,
        topoY + balanca * 6,
      )
      ..relativeQuadraticBezierTo(
        -6 * gancho,
        -10 * gancho,
        -14 * gancho,
        -6 * gancho,
      );
    canvas.drawPath(
      rabo,
      _traco(pelo, 11 * (1 + 0.15 * sustoDaMel))..strokeCap = StrokeCap.round,
    );
    // Os anéis do tabby: poucos, curtos e suaves, da metade para a ponta.
    // Compridos e juntos eles viravam uma escada.
    final anel = _traco(sombra.withValues(alpha: 0.7), 3)
      ..strokeCap = StrokeCap.round;
    for (final m in rabo.computeMetrics()) {
      for (var d = m.length * 0.45; d < m.length - 6; d += 13) {
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        final n = Offset(-t.vector.dy, t.vector.dx) * 3.4;
        canvas.drawLine(t.position - n, t.position + n, anel);
      }
    }

    _pata(canvas, const Offset(-19, 49), 16, 12, sombra, pose.pernas * amp);
    _pata(canvas, const Offset(19, 49), 16, 12, sombra, -pose.pernas * amp);

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 20), width: 80, height: 70),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 31), width: 54, height: 53),
        topo: 0.9,
      ),
      _p(claro),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -28 + pose.respiro * amp * 0.7 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    _posicionaCabeca(canvas, _cabecaGiro * 0.9, pescoco: 34);
    canvas.scale(_cabecaDoEstagio);
    _sombraDoQueixo(canvas, 82, 69);

    // Orelhas triangulares de ponta fina, com a concha por dentro. Antes da
    // cabeça: a base some sob o contorno. O humor as gira para os lados —
    // nunca para trás, que no gato é medo (laudo 08, R4).
    final abre = _porHumor(
      (m) => switch (m) {
        Mood.radiant => -0.04,
        Mood.content => 0.0,
        Mood.neutral => 0.10,
        Mood.sleepy => 0.30,
        Mood.missingYou => 0.40,
      },
    );
    for (final lado in [-1.0, 1.0]) {
      final treme = pose.orelha * 0.6 * lado;
      canvas.save();
      canvas.translate(lado * 24, -16);
      // Achatadas para os lados no susto, um fio para a frente na festa, e
      // a direita 0,1 rad diferente da esquerda (laudo 31 R11, MEL-22).
      canvas.rotate(
        lado * (abre + 0.5 * sustoDaMel - 0.08 * festaDaMel) +
            (lado > 0 ? 0.1 : 0.0),
      );
      canvas.translate(-lado * 24, 16);
      canvas.drawPath(
        Path()
          ..moveTo(lado * 34, -14)
          ..cubicTo(
            lado * 40,
            -32,
            lado * (35 + treme * 6),
            -46,
            lado * (27 + treme * 8),
            -50,
          )
          ..cubicTo(lado * 20, -37, lado * 16, -28, lado * 14, -20)
          ..cubicTo(lado * 20, -16, lado * 28, -13, lado * 34, -14)
          ..close(),
        _p(pelo),
      );
      canvas.drawPath(
        Path()
          ..moveTo(lado * 30, -19)
          ..cubicTo(
            lado * 33,
            -29,
            lado * (31 + treme * 5),
            -36,
            lado * (25 + treme * 6),
            -38,
          )
          ..cubicTo(lado * 21, -32, lado * 19, -26, lado * 18, -21)
          ..cubicTo(lado * 22, -19, lado * 27, -18, lado * 30, -19)
          ..close(),
        _p(Color.lerp(sombra, Cores.acento, 0.30)!),
      );
      canvas.restore();
    }

    final cabeca = _bolha(
      Rect.fromCenter(center: const Offset(0.7, 0.7), width: 82, height: 69),
      base: 1 + _queixoDesce / 34.5,
    );
    canvas.drawPath(cabeca, _p(pelo));

    // O "M" da testa do tabby e as listras das têmporas: o que faz ler
    // "gata" e não "urso".
    canvas.save();
    canvas.clipPath(cabeca);
    final listra = _traco(sombra.withValues(alpha: 0.6), 2.8)
      ..strokeJoin = StrokeJoin.round;
    // O "M" é do meio da testa: vira com o rosto. As listras das têmporas
    // são dos lados: ficam com o contorno.
    _rostoVira(canvas);
    canvas.drawPath(
      Path()
        ..moveTo(-12, -16)
        ..lineTo(-9, -30)
        ..lineTo(0, -20)
        ..lineTo(9, -30)
        ..lineTo(12, -16),
      listra,
    );
    _rostoVolta(canvas);
    for (final lado in [-1.0, 1.0]) {
      for (final y in [-8.0, -1.0]) {
        canvas.drawLine(Offset(lado * 40, y), Offset(lado * 31, y + 2), listra);
      }
    }
    canvas.restore();
    _rostoVira(canvas);

    // Focinheira clara e larga.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 15), width: 34, height: 20),
        topo: 0.86,
      ),
      _p(claro),
    );

    _bigodes(canvas, const Offset(-19, 11));
    _bigodes(canvas, const Offset(19, 11), lado: 1);

    // Nariz em coração invertido — a marca do felino.
    canvas.drawPath(
      Path()
        ..moveTo(-4, 7.5)
        ..cubicTo(-4, 5.8, 4, 5.8, 4, 7.5)
        ..cubicTo(4, 10.5, 1, 12.5, 0, 12.5)
        ..cubicTo(-1, 12.5, -4, 10.5, -4, 7.5)
        ..close(),
      _p(const Color(0xFFD67F74)),
    );

    _boca(canvas);
    if (feliz) _bochecha(canvas, const Offset(-30, 12), const Offset(30, 12));

    _olho(canvas, const Offset(-19, -6), 7.5);
    _olho(canvas, const Offset(19, -6), 7.5);
    _rostoVolta(canvas);
    _veste(canvas, 82, 69);

    canvas.restore();
  }

  // ======================================================================
  // RAPOSA — orelhas grandes de ponta escura, cauda de ponta clara
  // ======================================================================

  /// O branco da raposa: um creme quase branco, com um fio do pelo para não
  /// parecer recortado.
  Color get _brancoDaRaposa => Color.lerp(Cores.superficie, pelo, 0.06)!;

  void _raposa(Canvas canvas) {
    final amp = pose.amplitude;
    // Mesma razão da gata: no salto a pluma acompanha o corpo. Na festa,
    // chicoteia (RAP-11).
    final sustoDaFaisca = pose.vida.susto.clamp(0.0, 1.0);
    final festaDaFaisca = pose.vida.festa.clamp(0.0, 1.0);
    final balanca =
        (pose.brincando ? pose.pernas * amp * 1.5 : pose.cauda * amp) *
        (1 + 1.5 * festaDaFaisca);

    // Cauda em pluma, **na cor do pelo** e com a ponta branca: a cauda
    // escura com ponta bege era a do panda-vermelho, e foi como ela lia
    // (laudo 08, R5). Sai baixa, atrás do corpo, e engrossa até a ponta.
    // O humor mexe nela: sobe no radiante, cai e encosta no chão na saudade
    // (laudo 08, R4 — a cauda é o canal que a raposa mais usa).
    // Susto: cauda baixa; festa: alta (RAP-03, RAP-11).
    final ergue =
        _porHumor(
          (m) => switch (m) {
            Mood.radiant => -12.0,
            Mood.content => 0.0,
            Mood.neutral => 4.0,
            Mood.sleepy => 12.0,
            Mood.missingYou => 16.0,
          },
        ) +
        12 * sustoDaFaisca -
        20 * festaDaFaisca;
    final pontaX = 74 + balanca * 6;
    final pontaY = 2 + balanca * 7 + ergue;
    final cauda = Path()
      ..moveTo(18, 44)
      ..cubicTo(48, 50, 70 + balanca * 4, 34 + ergue * 0.4, pontaX, pontaY)
      ..cubicTo(80, -12 + ergue, 62, -16 + ergue, 54, -2 + ergue * 0.8)
      ..cubicTo(46, 14 + ergue * 0.5, 34, 26, 14, 30)
      ..close();
    canvas.drawPath(cauda, _p(pelo));
    canvas.save();
    canvas.clipPath(cauda);
    // A barriga da cauda, um tom abaixo: dá volume à pluma.
    canvas.drawPath(
      Path()
        ..moveTo(18, 48)
        ..cubicTo(50, 54, 74, 40 + ergue * 0.4, pontaX + 6, pontaY + 8)
        ..lineTo(pontaX + 20, pontaY + 30)
        ..lineTo(10, 60)
        ..close(),
      _p(sombra),
    );
    // Ponta branca: é ela que nomeia a raposa. Um disco grande, senão some.
    canvas.drawCircle(Offset(pontaX - 3, pontaY - 3), 16, _p(_brancoDaRaposa));
    canvas.restore();

    _pata(
      canvas,
      const Offset(-19, 49),
      16,
      12,
      sombraForte,
      pose.pernas * amp,
    );
    _pata(
      canvas,
      const Offset(19, 49),
      16,
      12,
      sombraForte,
      -pose.pernas * amp,
    );

    final corpo = _bolha(
      Rect.fromCenter(center: const Offset(0, 20), width: 78, height: 70),
      topo: 0.88,
    );
    canvas.drawPath(corpo, _p(pelo));

    canvas.save();
    canvas.clipPath(corpo);
    // O peito branco, em ponta para baixo: o babador da raposa.
    canvas.drawPath(
      Path()
        ..moveTo(-24, -6)
        ..quadraticBezierTo(0, 4, 24, -6)
        ..quadraticBezierTo(20, 30, 0, 50)
        ..quadraticBezierTo(-20, 30, -24, -6)
        ..close(),
      _p(_brancoDaRaposa),
    );
    canvas.restore();

    // --- cabeça -----------------------------------------------------------
    canvas.save();
    canvas.translate(0, -28 + pose.respiro * amp * 0.7 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    _posicionaCabeca(canvas, _cabecaGiro * 0.9, pescoco: 34);
    canvas.scale(_cabecaDoEstagio);
    _sombraDoQueixo(canvas, 80, 70);

    // Orelhas grandes, em três camadas: pelo, concha branca e ponta escura.
    // O humor as abre para os lados: "orelha de avião" na saudade, quase
    // deitadas no sono, em pé no radiante.
    final abre = _porHumor(
      (m) => switch (m) {
        Mood.radiant => -0.05,
        Mood.content => 0.0,
        Mood.neutral => 0.12,
        Mood.sleepy => 0.38,
        Mood.missingYou => 0.48,
      },
    );
    for (final lado in [-1.0, 1.0]) {
      final treme = pose.orelha * 0.6 * lado;
      final t = treme * 7;
      canvas.save();
      canvas.translate(lado * 26, -14);
      // Para trás no susto, em pé na festa; a direita 0,1 rad diferente
      // (laudo 31 R11).
      canvas.rotate(
        lado * (abre + 0.4 * sustoDaFaisca - 0.15 * festaDaFaisca) +
            (lado > 0 ? 0.1 : 0.0),
      );
      canvas.translate(-lado * 26, 14);
      canvas.drawPath(
        Path()
          ..moveTo(lado * 38, -10)
          ..cubicTo(lado * 46, -28, lado * (42 + t), -44, lado * (30 + t), -48)
          ..cubicTo(lado * 22, -38, lado * 16, -26, lado * 14, -16)
          ..cubicTo(lado * 22, -12, lado * 32, -10, lado * 38, -10)
          ..close(),
        _p(pelo),
      );
      canvas.drawPath(
        Path()
          ..moveTo(lado * 32, -16)
          ..cubicTo(lado * 36, -26, lado * (33 + t), -34, lado * (27 + t), -37)
          ..cubicTo(lado * 23, -30, lado * 20, -24, lado * 19, -19)
          ..cubicTo(lado * 24, -16, lado * 29, -15, lado * 32, -16)
          ..close(),
        _p(claro),
      );
      canvas.drawPath(
        Path()
          ..moveTo(lado * 37, -27)
          ..cubicTo(lado * 41, -38, lado * (38 + t), -45, lado * (30 + t), -47)
          ..cubicTo(lado * 26, -42, lado * 23, -36, lado * 21, -31)
          ..cubicTo(lado * 26, -28, lado * 33, -26, lado * 37, -27)
          ..close(),
        _p(sombraForte),
      );
      canvas.restore();
    }

    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 3), width: 80, height: 66),
        base: 1 + _queixoDesce / 33,
      ),
      _p(pelo),
    );

    // A máscara branca: bochechas e queixo, subindo em V até o focinho.
    // É o branco da cara que separa raposa de panda-vermelho e de gata.
    canvas.save();
    canvas.clipPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 3), width: 80, height: 66),
        base: 1 + _queixoDesce / 33,
      ),
    );
    _rostoVira(canvas);
    canvas.drawPath(
      Path()
        ..moveTo(-42, 7)
        ..quadraticBezierTo(-22, 4, -10, 11)
        ..quadraticBezierTo(0, 6, 10, 11)
        ..quadraticBezierTo(22, 4, 42, 7)
        ..lineTo(42, 40)
        ..lineTo(-42, 40)
        ..close(),
      _p(_brancoDaRaposa),
    );
    canvas.restore();
    _rostoVira(canvas);
    // Focinho em V, que afina para a ponta.
    canvas.drawPath(
      Path()
        ..moveTo(-16, 6)
        ..quadraticBezierTo(0, 2, 16, 6)
        ..quadraticBezierTo(10, 22, 0, 28)
        ..quadraticBezierTo(-10, 22, -16, 6)
        ..close(),
      _p(_brancoDaRaposa),
    );

    // Nariz escuro na ponta.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 9), width: 13, height: 10),
        base: 1.1,
      ),
      _p(Color.lerp(sombraForte, Cores.tinta, 0.45)!),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-2.4, 7.4), width: 5, height: 3),
      _p(luz.withValues(alpha: 0.45)),
    );

    _boca(canvas);
    if (feliz) _bochecha(canvas, const Offset(-30, 14), const Offset(30, 14));

    _olho(canvas, const Offset(-19, -4), 7.5);
    _olho(canvas, const Offset(19, -4), 7.5);
    _rostoVolta(canvas);
    _veste(canvas, 80, 66);

    canvas.restore();
  }

  // ======================================================================
  // BULDOGUE FRANCÊS
  //
  // As oito espécies anteriores são bichos silvestres e o vocabulário delas é
  // o mesmo: focinho que projeta, cabeça mais alta que larga, silhueta que
  // afina para baixo. O buldogue é o contrário nos três, e é isso que o torna
  // reconhecível de longe — não a cor.
  //
  // A primeira tentativa foi um urso claro com duas orelhas redondas: nada
  // ali dizia "buldogue francês". A segunda acertou a orelha ereta e errou o
  // resto — orelha de balão, cara lisa, corpo redondo. O que faltava, e está
  // aqui, são **seis** traços, cada um respondendo a um defeito que dava para
  // apontar com o dedo na captura:
  //
  // 1. **Orelha de morcego, e não de rato nem de pastor-alemão.** Base de 34
  //    no alto do crânio, bordas quase retas, altura de 46 e uma calota de 24
  //    fechando o topo — sobe **sem afinar** e termina em arco. Duas
  //    tentativas erradas vieram antes: uma estufava no meio (borda de fora
  //    em 56 com a base em 44) e virava pá de remo; a outra fechava o topo em
  //    14 e virava orelha em ponta. Ver [_orelhaDeMorcego].
  // 2. **Cara achatada de verdade.** Nariz grande e alto, quase entre os
  //    olhos, sobre uma focinheira larga e **rasa** que não avança nada.
  //    Braquicefálico em desenho é isto: a frente da cara é um plano, não uma
  //    ponta.
  // 3. **Rugas que são dobras, e não riscos.** Cada vinco sai de [_dobraDaPele]
  //    — sombra embaixo, luz um fio acima. Um traço escuro sozinho lê como
  //    arranhão; o par lê como pele dobrada, que é o que a raça tem na testa,
  //    entre os olhos e sobre o focinho.
  // 4. **Papada e beiço.** O crânio é um caminho só que **alarga embaixo**
  //    (±46 no topo, ±48 na bochecha) em vez de afinar como o do resto do
  //    elenco, e o lábio superior cai em dois lobos dos lados do focinho, com
  //    os dentinhos de baixo aparecendo no meio. É o terço inferior da cara,
  //    e sem ele sobra um filhote de focinho curto.
  // 5. **Corpo de pera invertida.** Peito largo no ombro (±53) afinando até a
  //    cintura (±30), com duas pernas dianteiras grossas e curtas descendo por
  //    baixo do peito. A bolha simétrica de antes dava um bicho macio; o
  //    buldogue é compacto e musculoso, e músculo em desenho chapado é
  //    **silhueta**, não sombreado. A cabeça subiu de -24 para -29 por causa
  //    disto: a -24 o queixo cobria o ombro inteiro e a pera não aparecia.
  // 6. **Marcação de pelagem.** Máscara escura no fulvo, peito e patas brancos
  //    com manchas escuras no pied, listras no tigrado. Sem elas as seis
  //    entradas da paleta eram o mesmo cão em seis tintas.
  //
  // Sem cauda, de propósito. A da raça é um toco de três centímetros que de
  // frente não aparece; a pluma da raposa ou a curva da gata dariam outro
  // cachorro, e um toco solto no flanco lê como defeito de traço.
  // ======================================================================

  /// O que a pelagem escolhida **desenha**, além de tingir.
  ///
  /// A paleta do buldogue é a única do elenco que troca de pigmento em vez de
  /// trocar de tom (ver `Cores.pelagemBuldogue`), e pigmento de cão vem com
  /// marcação junto: fulvo vem com máscara, creme é a base do pied, tigrado é
  /// listrado por definição. Tratar as seis como seis tintas era desperdiçar
  /// a metade da pelagem que o olho de fato usa para reconhecer a raça.
  _MarcaDoBuldogue get _marca => switch (coatIndex) {
    0 || 1 => _MarcaDoBuldogue.mascara,
    2 => _MarcaDoBuldogue.pied,
    3 => _MarcaDoBuldogue.tigrado,
    // Blue e preto saem lisos. É o que o padrão da raça dá: são cores de
    // pelo, não desenhos. Forçar mancha neles seria inventar um cão.
    _ => _MarcaDoBuldogue.solida,
  };

  /// O branco do pied: peito, patas e focinho.
  Color get _brancoDoPied => Color.lerp(Cores.superficie, pelo, 0.06)!;

  /// A **mancha** do pied — orelhas, um dos olhos e a sela do dorso.
  ///
  /// O pied não é um cão branco com detalhes brancos, e foi assim que a
  /// primeira versão saiu: base creme com manchas quase brancas por cima, que
  /// contra creme não aparecem de jeito nenhum. Pied é o contrário — o cão é
  /// claro e as **manchas é que são escuras**. Invertida, a pelagem passou de
  /// a mais apagada das seis à mais reconhecível.
  Color get _manchaDoPied => Color.lerp(pelo, Cores.tinta, 0.52)!;

  /// O tom da máscara: o pelo levado quase à tinta.
  ///
  /// Sai de [pelo] e não de uma cor fixa porque a máscara tem de continuar
  /// sendo *aquele* cão mais escuro — uma cor absoluta ficaria roxa no blue e
  /// preta no fulvo, e as duas leriam como buraco na cara.
  ///
  /// 0,45 e não 0,55: na primeira tentativa a máscara ficava tão escura que
  /// engolia nariz, boca e vinco — restavam dois olhos e dois dentes flutuando
  /// num borrão marrom. Máscara é sombra na cara, não buraco nela.
  Color get _tomDaMascara => Color.lerp(pelo, Cores.tinta, 0.45)!;

  /// O quanto a orelha tomba, de 0 (ereta) a 1 (deitada de lado).
  ///
  /// É o sinal de humor mais barato que um cão tem, e o mais legível de
  /// longe: orelha em pé é atenção, orelha caída para os lados é o que todo
  /// mundo chama de "orelha de avião" e lê como abatimento antes de qualquer
  /// boca ou sobrancelha. Num bicho cuja marca registrada **é** a orelha,
  /// desperdiçá-la como enfeite fixo seria jogar fora o melhor canal.
  double get _orelhaTomba {
    final doHumor = _porHumor(
      (m) => switch (m) {
        Mood.radiant => 0.0,
        Mood.content => 0.05,
        Mood.neutral => 0.18,
        Mood.sleepy => 0.58,
        Mood.missingYou => 0.82,
      },
    );
    // Cochilando ela cai mesmo com humor alegre: o bicho está dormindo, e
    // orelha ereta num bicho de olhos fechados lê como bicho fingindo.
    return math.max(doHumor, acao == AcaoDoBicho.cochilo ? 0.62 : 0.0);
  }

  void _buldogue(Canvas canvas) {
    final amp = pose.amplitude;
    final passo = pose.pernas * amp;

    _buldogueCorpo(canvas, passo);

    // --- cabeça -----------------------------------------------------------
    //
    // Presa a -29, contra os -28 do resto do elenco, e num crânio baixo. Os
    // dois números servem à mesma coisa, e não é só abrir espaço para a
    // orelha: com a cabeça a -24 o queixo descia até a altura 22 do corpo e
    // **cobria o ombro inteiro**. Sobrava do tronco só a cintura, então a
    // pera invertida — o traço que faz o bicho parecer compacto e musculoso —
    // não aparecia em pixel nenhum. Cinco pixels acima e o ombro sai de trás
    // da cabeça dos dois lados.
    //
    // O teto é o quadro: 150 px de altura, e a ponta da orelha não pode
    // passar de uns 9 px do topo — foi o que cortou o tufo da coruja.
    canvas.save();
    canvas.translate(0, -29 + pose.respiro * amp * 0.7 + _cabecaDesce);
    _cabecaSemFolego(canvas);
    // A inclinação de cabeça do cão que não entende por que você sumiu. Meio
    // grau só; mais que isso e ele fica tonto em vez de sentido.
    _posicionaCabeca(
      canvas,
      _cabecaGiro * 0.9 + (triste ? 0.05 : 0),
      pescoco: 40,
    );
    canvas.scale(_cabecaDoEstagio);

    _buldogueCabeca(canvas);

    canvas.restore();
  }

  // --- corpo --------------------------------------------------------------

  /// Peito largo, cintura estreita, pernas grossas e curtas.
  void _buldogueCorpo(Canvas canvas, double passo) {
    final pied = _marca == _MarcaDoBuldogue.pied;

    // O tronco em pera invertida. Não sai de [_bolha] como o dos outros oito:
    // aquela primitiva é simétrica no eixo vertical e o que precisa acontecer
    // aqui é o contrário dela — largo em cima, estreito embaixo. Ombro em
    // ±53 na altura 10, cintura em ±30 na altura 54.
    final tronco = Path()
      ..moveTo(0, -17)
      ..cubicTo(30, -17, 52, -5, 53, 13)
      ..cubicTo(54, 31, 43, 47, 30, 54)
      ..cubicTo(19, 61, -19, 61, -30, 54)
      ..cubicTo(-43, 47, -54, 31, -53, 13)
      ..cubicTo(-52, -5, -30, -17, 0, -17)
      ..close();
    canvas.drawPath(tronco, _p(pelo));

    canvas.save();
    canvas.clipPath(tronco);

    // A sela do pied: a mancha escura no dorso e nos ombros. É ela que faz o
    // resto do corpo ler como branco, e não como "creme sem nada".
    if (pied) {
      canvas.drawPath(
        Path()
          ..moveTo(-56, -6)
          ..cubicTo(-40, -22, 40, -22, 56, -6)
          ..cubicTo(50, 14, 30, 4, 8, 10)
          ..cubicTo(-14, 16, -40, 12, -56, -6)
          ..close(),
        _p(_manchaDoPied),
      );
    }

    // O tigrado **antes** do peito, e não depois. Com as listras por cima, a
    // barriga clara saía com um código de barras no meio: rajado é pelo de
    // dorso e de flanco, e o peito de um brindle é justamente onde ele
    // clareia.
    if (_marca == _MarcaDoBuldogue.tigrado) _tigradoDoCorpo(canvas);

    // O peito. No pied é mancha de pelagem e precisa de borda visível; nas
    // outras é só o ventre mais claro, como nas oito espécies antigas.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 30), width: 46, height: 58),
        topo: 0.82,
      ),
      _p(pied ? _brancoDoPied : barriga),
    );

    // O vinco do ombro, um de cada lado. É o que dá o "musculoso": a linha
    // onde a perna da frente encontra o peito. Uma sombra chapada no topo do
    // corpo daria volume mas não daria anatomia — o que lê como força é o
    // traço que mostra onde um músculo acaba e o outro começa.
    //
    // Curto e alto, colado no ombro. Descendo até a cintura, como na primeira
    // versão, ele virava um risco solto no flanco — e o elenco inteiro tem
    // pouquíssimo traço interno, então cada linha a mais aqui destoa.
    for (final lado in [-1.0, 1.0]) {
      _dobraDaPele(
        canvas,
        Path()
          ..moveTo(lado * 30, -11)
          ..cubicTo(lado * 44, -3, lado * 47, 8, lado * 44, 19),
        forca: 0.7,
      );
    }
    canvas.restore();

    // Pernas dianteiras: colunas curtas e grossas, saindo por baixo do peito.
    // Antes só havia as patas, e um corpo sem perna nenhuma boiando sobre
    // dois pés é o que fazia a silhueta ler como bolha macia. Ficam **depois**
    // do recorte do tronco de propósito: elas passam da linha dele embaixo,
    // que é exatamente onde uma perna dianteira aparece num cão sentado de
    // frente.
    //
    // Separadas do peito por **tom**, não por traço. Dois riscos a mais na
    // barriga era o que mais destoava do resto do elenco, onde membro se
    // separa de tronco pela cor e nunca por contorno.
    for (final lado in [-1.0, 1.0]) {
      final desloca = passo * 0.9 * lado;
      final x = lado * 31 + desloca;
      final perna = _bolha(
        Rect.fromCenter(center: Offset(x, 39), width: 21, height: 42),
        // Topo quase reto: a perna sobe e some sob o peito. Com o topo
        // redondo ela virava uma bola encostada no corpo, e o bicho ficava
        // com duas almofadas em vez de duas pernas.
        topo: 0.34,
      );
      canvas.drawPath(perna, _p(Color.lerp(pelo, Cores.tinta, 0.13)!));
      // A meia branca do pied. Desenhada como parte da perna, e não pintando
      // a perna inteira: perna branca inteira somava com o peito branco e o
      // terço de baixo do bicho virava uma mancha só, sem forma.
      if (pied) {
        canvas.save();
        canvas.clipPath(perna);
        canvas.drawRect(
          Rect.fromLTRB(x - 14, 38, x + 14, 62),
          _p(_brancoDoPied),
        );
        canvas.restore();
      }
    }

    // Patas largas e bem afastadas — mais que as de qualquer outro daqui. O
    // buldogue apoia em base ampla, e é isso que o faz parecer plantado no
    // chão em vez de equilibrado sobre as pernas.
    //
    // Depois das pernas, e não antes como nas outras espécies: aqui existe
    // perna, e pé atrás da perna some quase todo.
    //
    // Sem `rema`: ele nunca nada (ver [acaoDoBicho]), e passar o parâmetro
    // seria deixar no código a promessa de um movimento que não acontece.
    final corDaPata = pied ? _brancoDoPied : sombra;
    _pata(canvas, const Offset(-31, 55), 27, 15, corDaPata, passo * 0.9);
    _pata(canvas, const Offset(31, 55), 27, 15, corDaPata, -passo * 0.9);
  }

  /// As listras do tigrado no tronco.
  ///
  /// Verticais e tortas, do dorso para a barriga, afinando embaixo — é como
  /// o brindle corre num cão de verdade, e listra horizontal daria zebra.
  /// Recortadas pelo tronco por quem chama: sem o recorte elas passariam da
  /// silhueta e o bicho ficaria riscado por fora.
  void _tigradoDoCorpo(Canvas canvas) {
    final tinta = _p(Color.lerp(pelo, Cores.tinta, 0.30)!);
    for (var i = 0; i < 13; i++) {
      final x = -50.0 + i * 8.2;
      // A largura oscila de listra para listra. Todas iguais leem como
      // padrão de tecido; o brindle de um cão é irregular.
      final largura = 3.4 + (i % 3) * 1.1;
      canvas.drawPath(
        Path()
          ..moveTo(x, -20)
          ..cubicTo(x + 5, 0, x + 3, 24, x + 8, 48)
          ..lineTo(x + 8 + largura, 48)
          ..cubicTo(x + 3 + largura, 24, x + 5 + largura, 0, x + largura, -20)
          ..close(),
        tinta,
      );
    }
  }

  // --- cabeça -------------------------------------------------------------

  void _buldogueCabeca(Canvas canvas) {
    final tomba = _orelhaTomba;

    // Orelhas antes da cabeça: a base some sob o contorno, como nas outras.
    // Susto: mais eretas e abertas (tomba −0,15, BOL-B6); festa: tremendo;
    // a direita um fio diferente (laudo 31 R11).
    for (final lado in [-1.0, 1.0]) {
      _orelhaDeMorcego(
        canvas,
        lado,
        (tomba -
                0.15 * pose.vida.susto.clamp(0.0, 1.0) +
                (lado > 0 ? 0.06 : 0.0))
            .clamp(0.0, 1.0),
      );
    }

    // O crânio, **com a papada dentro do mesmo contorno**: topo largo e
    // achatado, laterais quase retas e a maior largura lá embaixo, na altura
    // da bochecha (±48 em y=26 contra ±44 em y=2). É a proporção invertida do
    // resto do elenco, onde a cabeça afina para o queixo; aqui ela alarga,
    // porque o peso do buldogue está na mandíbula.
    //
    // Não sai de [_bolha] e a papada não é mais desenhada à parte. A primeira
    // versão empilhava duas bolhas de bochecha por fora de um crânio oval, e
    // o contorno resultante tinha três calombos de cada lado — de longe lia
    // como cabeça inchada, não como papada. Papada é a **linha** da cabeça
    // descendo e abrindo, e linha só sai de um caminho só.
    // A boca bem aberta desce o queixo (ver [_queixoDesce]): a papada
    // alonga, o resto do contorno fica.
    final q = _queixoDesce;
    final cabeca = Path()
      ..moveTo(0, -21)
      ..cubicTo(31, -21, 45, -13, 46, 5)
      ..cubicTo(48, 20, 46, 30 + q * 0.3, 40, 36 + q * 0.6)
      ..cubicTo(32, 44 + q * 0.9, 16, 46 + q, 0, 46 + q)
      ..cubicTo(-16, 46 + q, -32, 44 + q * 0.9, -40, 36 + q * 0.6)
      ..cubicTo(-46, 30 + q * 0.3, -48, 20, -46, 6)
      ..cubicTo(-44, -12, -25, -20, 0, -20)
      ..close();

    _sombraDoQueixo(canvas, 92, 92);
    canvas.drawPath(cabeca, _p(pelo));

    canvas.save();
    canvas.clipPath(cabeca);
    // Marca e rugas são da cara: viram com ela. As pregas da papada são do
    // contorno: ficam.
    _rostoVira(canvas);
    _marcaDaCabeca(canvas);
    _rugasDaCabeca(canvas);
    _rostoVolta(canvas);

    // A prega que separa a papada da bochecha, uma de cada lado. Dentro do
    // recorte porque a papada agora é parte do contorno da cabeça: solta, ela
    // vazava pela borda e virava um risco no ar ao lado do queixo.
    for (final lado in [-1.0, 1.0]) {
      _dobraDaPele(
        canvas,
        Path()
          ..moveTo(lado * 27, 11)
          ..cubicTo(lado * 39, 17, lado * 42, 29, lado * 34, 40),
        forca: 0.85,
      );
    }
    canvas.restore();
    _rostoVira(canvas);

    _focinhoDoBuldogue(canvas);

    if (feliz) {
      _bochecha(canvas, const Offset(-37, 22), const Offset(37, 22));
    }

    // Olhos grandes, redondos e bem afastados — 8,6 de raio, o maior do
    // elenco fora a coruja. Os ±27 num crânio de 96 são o que separa o
    // buldogue do resto, onde os olhos vivem a menos de um quarto da largura
    // do centro: juntos, eles empurravam a cara para o meio e o bicho ficava
    // com cara de filhote genérico.
    //
    // `sobrancelha: false` porque ele tem o par próprio, logo abaixo.
    _olho(canvas, const Offset(-27, 2), 8.6, sobrancelha: false);
    _olho(canvas, const Offset(27, 2), 8.6, sobrancelha: false);
    for (final lado in [-1.0, 1.0]) {
      _sobrancelhaDoBuldogue(canvas, lado);
    }

    _rostoVolta(canvas);
    _veste(canvas, 96, 64);
  }

  /// A orelha de morcego: base larga no alto do crânio, bordas convergindo,
  /// topo estreito e arredondado.
  ///
  /// [tomba] de 0 a 1 deita a orelha para fora, girando-a em torno da própria
  /// base e encolhendo-a um pouco — orelha que tomba sem encurtar parece
  /// orelha quebrada, não orelha relaxada.
  void _orelhaDeMorcego(Canvas canvas, double lado, double tomba) {
    // O tremor de escuta some conforme a orelha cai: cão de orelha deitada
    // não está prestando atenção em nada, e o tremor ali viraria tique.
    final treme = pose.orelha * 0.6 * lado * (1 - tomba);
    final t = treme * 7;

    canvas.save();
    // Gira em torno da base, não do centro: o ponto fixo de uma orelha é onde
    // ela prende no crânio.
    canvas.translate(lado * 27, -6);
    canvas.rotate(lado * tomba * 0.95);
    canvas.scale(1, 1 - tomba * 0.20);
    canvas.translate(-lado * 27, 6);

    // As medidas que fazem a orelha ler como "de morcego": base de 34 num
    // crânio de 96 — mais de um terço da cabeça de cada lado —, altura de 46,
    // e uma **calota larga** fechando o topo. A razão de 1,35 entre altura e
    // base é a do padrão da raça.
    //
    // Duas tentativas erradas ficaram no caminho e valem a nota. A primeira
    // estufava no meio (borda de fora em 56 com a base em 44): virava pá de
    // remo. A segunda afinava o topo para 14: virava orelha de
    // pastor-alemão. O que faz a orelha do buldogue é ela subir **sem
    // afinar** e terminar em arco largo.
    canvas.drawPath(
      Path()
        ..moveTo(lado * 46, 0)
        ..cubicTo(lado * 49, -14, lado * (48 + t), -30, lado * (40 + t), -41)
        ..cubicTo(lado * (34 + t), -49, lado * (21 + t), -49, lado * 16, -38)
        ..cubicTo(lado * 13, -25, lado * 12, -12, lado * 12, 0)
        ..close(),
      _p(_marca == _MarcaDoBuldogue.pied ? _manchaDoPied : pelo),
    );

    // A concha, por dentro, e larga: ela ocupa quase toda a orelha, como o
    // pavilhão de verdade ocupa. Uma fresta fina no meio lia como vinco, não
    // como ouvido.
    //
    // Sai de `sombraForte`, e não de `sombra`: partindo do tom médio ela
    // ficava mais **clara** que o pelo depois da mistura com o acento, e a
    // orelha lia ao contrário — o miolo saltando à frente da borda.
    canvas.drawPath(
      Path()
        ..moveTo(lado * 41, -1)
        ..cubicTo(lado * 43, -14, lado * (42 + t), -27, lado * (36 + t), -36)
        ..cubicTo(lado * (31 + t), -43, lado * (22 + t), -43, lado * 19, -34)
        ..cubicTo(lado * 17, -23, lado * 17, -11, lado * 17, -1)
        ..close(),
      _p(Color.lerp(sombraForte, Cores.acento, 0.28)!),
    );
    canvas.restore();
  }

  /// A marcação da pelagem na cara: máscara, blaze do pied ou listras.
  ///
  /// Chamada **dentro** do recorte do crânio por quem a usa, e por isso não
  /// salva o canvas: quem recorta é quem chama.
  void _marcaDaCabeca(Canvas canvas) {
    switch (_marca) {
      case _MarcaDoBuldogue.mascara:
        // A máscara do fulvo: escurece a frente da cara e sobe em dois lobos
        // para envolver os olhos. Um retângulo escuro no terço de baixo
        // daria barba de bode; o que faz ler "máscara" é ela **subir** até
        // os olhos e parar ali.
        //
        // Largura ±31 num crânio de ±49: ela para bem antes da borda, e é
        // essa faixa de fulvo que sobra na bochecha que a faz ler como
        // máscara. Cobrindo até a borda (±40, como na primeira tentativa) o
        // bicho virava um cão escuro de testa clara.
        //
        // O topo é **um arco só**. A segunda tentativa subia em dois lobos
        // para envolver os olhos e o vão entre eles desenhava um "W" bem em
        // cima do nariz: com as sobrancelhas por perto, a cara saía de macaco
        // zangado em todos os cinco humores. A máscara do buldogue é a frente
        // do focinho escura passando **por baixo** dos olhos, e é só isso.
        canvas.drawPath(
          Path()
            ..moveTo(-31, 13)
            ..cubicTo(-30, 0, -17, -6, 0, -6)
            ..cubicTo(17, -6, 30, 0, 31, 13)
            ..cubicTo(33, 31, 26, 42, 0, 42)
            ..cubicTo(-26, 42, -33, 31, -31, 13)
            ..close(),
          _p(_tomDaMascara),
        );
      case _MarcaDoBuldogue.pied:
        // A mancha de um olho só. É **assimétrica de propósito**: o pied de
        // verdade é assim, e é essa quebra que faz o desenho parecer um cão
        // específico em vez de um decalque. Simétrica ela viraria máscara de
        // bandido, que é outra coisa e já é o desenho do fulvo.
        //
        // Fica na esquerda de quem olha porque é o lado onde a cara tem menos
        // acontecendo: o talo do petisco sai pelo canto direito da boca.
        canvas.drawPath(
          Path()
            ..moveTo(-46, -6)
            ..cubicTo(-42, -20, -22, -22, -13, -12)
            ..cubicTo(-8, -4, -10, 12, -18, 20)
            ..cubicTo(-30, 28, -44, 18, -46, -6)
            ..close(),
          _p(_manchaDoPied),
        );
      case _MarcaDoBuldogue.tigrado:
        // Listras da cara: muitas, finas e tortas. Poucas e grossas — seis de
        // 9 px, como saiu da primeira vez — não leem como tigrado: leem como
        // uniforme listrado. O brindle de um cão é rajado, quase textura, e
        // textura se faz com repetição.
        //
        // Param em y = 12, antes do focinho: cruzando a focinheira elas
        // riscavam o nariz e a boca, que são as duas formas que a cara tem
        // para trabalhar. Listra é fundo, nunca por cima do desenho.
        final tinta = _p(Color.lerp(pelo, Cores.tinta, 0.26)!);
        for (var i = 0; i < 11; i++) {
          final x = -44.0 + i * 8.4;
          if (x.abs() < 9) continue; // deixa o meio da testa livre
          canvas.drawPath(
            Path()
              ..moveTo(x, -24)
              ..cubicTo(x + 3, -12, x + 2, 0, x + 5, 12)
              ..lineTo(x + 8.6, 12)
              ..cubicTo(x + 5.6, 0, x + 6.6, -12, x + 3.6, -24)
              ..close(),
            tinta,
          );
        }
      case _MarcaDoBuldogue.solida:
        break;
    }
  }

  /// Os vincos da cara. Três, e cada um responde a uma pergunta diferente.
  void _rugasDaCabeca(Canvas canvas) {
    // Ruga da testa, entre as sobrancelhas. Arqueada para **cima**, porque a
    // ruga do buldogue nasce do nariz e sobe. Para baixo ela lê como testa
    // franzida, e o bicho fica bravo o tempo todo — inclusive quando a
    // legenda diz que ele está radiante.
    //
    // Ela **funde** com o humor: some quase toda no radiante e aprofunda no
    // sentindo falta, que é o que a testa de um cão de fato faz.
    final vinco = switch (mood) {
      Mood.radiant => 0.35,
      Mood.content => 0.6,
      Mood.neutral => 0.9,
      Mood.sleepy => 0.5,
      Mood.missingYou => 1.0,
    };
    _dobraDaPele(
      canvas,
      Path()
        ..moveTo(-17, -11)
        ..quadraticBezierTo(0, -15 - vinco * 2, 17, -11),
      forca: vinco,
    );

    // O sulco do stop: a depressão vertical entre os olhos, marca da cara
    // achatada. É o que impede a testa de virar uma placa lisa entre dois
    // olhos. Para antes do nariz: descendo até ele o traço encostava na
    // mancha escura e os dois viravam um borrão só.
    _dobraDaPele(
      canvas,
      Path()
        ..moveTo(0, -6)
        ..lineTo(0, -1),
      forca: 0.6,
    );

    // A corda do nariz: a dobra que cruza a ponte, logo acima do focinho. É
    // o vinco mais característico da raça — a única ruga que uma pessoa
    // descreve em palavras ao falar de um buldogue francês.
    //
    // Esta é a única que **não** é um traço: é um rolo cheio, com sombra por
    // baixo. As outras duas são vincos na pele e um par de linhas basta; esta
    // é pele **sobrando**, e sobra de pele tem volume. Como par de linhas ela
    // saía igual à ruga da testa, e a cara ficava com duas listras paralelas
    // em vez de uma testa vincada e um rolo sobre o nariz.
    final fundoDoRolo = _marca == _MarcaDoBuldogue.mascara
        ? _tomDaMascara
        : pelo;
    // Elipse, e não uma calota de base reta: com `base: 0.5` a borda de baixo
    // saía uma linha horizontal atravessando a cara, e de perto o rolo lia
    // como esparadrapo colado no nariz.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 2), width: 40, height: 12),
      ),
      _p(Color.lerp(fundoDoRolo, luz, 0.26)!),
    );
    canvas.drawPath(
      Path()
        ..moveTo(-19, 4)
        ..cubicTo(-11, 9, 11, 9, 19, 4),
      _traco(sombraForte.withValues(alpha: 0.30), 1.7),
    );
  }

  /// Focinheira rasa, nariz grande, beiço caído e os dentinhos de baixo.
  void _focinhoDoBuldogue(Canvas canvas) {
    // No fulvo mascarado a focinheira é **escura** — é ela o centro da
    // máscara —, no pied é branca, e nas outras é o pelo levemente clareado.
    // Pintar sempre de claro furava um buraco no meio da máscara.
    final corDoFocinho = switch (_marca) {
      _MarcaDoBuldogue.mascara => Color.lerp(_tomDaMascara, pelo, 0.34)!,
      _MarcaDoBuldogue.pied => _brancoDoPied,
      // `claro` (30% para o creme) é o que as outras oito espécies usam, e
      // num pelo preto ele devolve um cinza pálido: de perto o bicho parecia
      // usar focinheira de plástico. Cão preto tem focinho preto; 18% chega
      // para a forma existir sem clarear o pelo.
      _ => Color.lerp(pelo, Cores.superficie, 0.18)!,
    };

    // A focinheira: larga (56 num crânio de 96) e **rasa**. Nas outras
    // espécies ela projeta — a raposa tem 52×26 puxada para a frente. Aqui
    // ela não avança nada, que é o que "braquicefálico" quer dizer em
    // desenho.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 27), width: 56, height: 26),
        topo: 0.70,
      ),
      _p(corDoFocinho),
    );

    // O beiço: o lábio superior caindo em dois lobos, um de cada lado do
    // focinho, com a linha da boca entre eles. Desenhá-lo como um traço só
    // dava um sorriso de gato numa cara que não tem nada de gato — o que a
    // raça tem é lábio pendurado, e lábio pendurado é volume, não linha.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        _bolha(
          Rect.fromCenter(center: Offset(lado * 16, 30), width: 33, height: 25),
          topo: 0.86,
        ),
        _p(Color.lerp(corDoFocinho, sombra, 0.14)!),
      );
    }

    // Nariz enorme, e alto: quase entre os olhos. Mais que o dobro do da
    // raposa (27×17 contra 13×10). Num focinho que não projeta é o nariz que
    // precisa carregar a frente da cara sozinho.
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: const Offset(0, 14), width: 27, height: 17),
        base: 1.12,
      ),
      _p(Color.lerp(sombraForte, Cores.tinta, 0.62)!),
    );
    // Narinas em vírgula, viradas para fora. Dois furos redondos e simétricos
    // leem como tomada elétrica.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(lado * 3.5, 11)
          ..cubicTo(lado * 9, 10, lado * 11, 14, lado * 9, 17.5)
          ..cubicTo(lado * 7, 16.5, lado * 4.5, 14, lado * 3.5, 11)
          ..close(),
        _p(Cores.tinta),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-5.5, 9), width: 8, height: 4),
      _p(luz.withValues(alpha: 0.42)),
    );

    // O filtro: o sulco que desce do nariz até a linha da boca, separando os
    // dois lobos do beiço. É de graça e é ele que impede os lobos de leem
    // como duas bolhas encostadas.
    canvas.drawPath(
      Path()
        ..moveTo(0, 22)
        ..lineTo(0, 27),
      _traco(sombra.withValues(alpha: 0.45), 1.8),
    );

    // Tinta cheia na boca, não `sombraForte`: ver a nota em [_boca]. A boca
    // abre atrás do beiço: o vão escuro aparece entre os lobos, que não
    // mudam, e os dentinhos de baixo descem com a mandíbula (laudo 30,
    // §3.4) — [_boca] os desenha, para saírem junto na camada de boca.
    _boca(canvas, cor: Color.lerp(Cores.tinta, corDoFocinho, 0.18)!);

    // A língua **depois** dos dentes: ela cai por fora do lábio, e é a
    // primeira coisa que fica na frente de tudo. Desenhada antes, os dois
    // dentinhos ficavam pousados em cima dela.
    _linguaDoBuldogue(canvas);
  }

  /// Um bico de frente (laudo 30, §3.3, R5). A mandíbula de cima é o
  /// triângulo de sempre e não se move; a de baixo é uma peça própria que
  /// gira na articulação, atrás da comissura, de 0 a [anguloMax] graus com a
  /// abertura — na vista de frente a ponta dela desce
  /// `hMax · sin θ / sin θmax`, a projeção do giro de uma alavanca que vai da
  /// articulação, dentro da cabeça, à ponta do bico. Entre as duas aparece o
  /// vão escuro, em cunha: mais largo no meio e fechando nas comissuras.
  /// Bico não arredonda: com `largura` negativa (os formatos E e F) ele abre
  /// como C.
  ///
  /// Fechado, o desenho é o de antes, pixel a pixel: a mandíbula de baixo e
  /// o vão só entram com abertura maior que zero. [faixa] é a listra clara do
  /// pinguim; [lingua], a língua pequena que só ele mostra no zurro.
  void _bico(
    Canvas canvas, {
    required Color cor,
    required double base,
    required double ponta,
    required double anguloMax,
    Color? faixa,
    double faixaEm = 0,
    bool lingua = false,
  }) {
    final e = BocaDaEspecie.de(species);
    PetView.aoDesenharBoca?.call(canvas.getTransform(), e.origem, e.largura);
    final vida = pose.vida;
    if (vida.semBoca) return;
    var a = _abertura;
    if (a > 0 && vida.largura < 0) a = math.max(a, 0.45);
    if (a > 0) {
      final rad = anguloMax * math.pi / 180;
      final desce = e.hMax * math.sin(a * rad) / math.sin(rad);
      // A face de fora da mandíbula de baixo, um tom diferente da de cima
      // para as duas peças se lerem (mais escura no bico claro da coruja,
      // mais clara no bico escuro do pinguim).
      final sombreada = cor.computeLuminance() < 0.15
          ? Color.lerp(cor, Cores.superficie, 0.12)!
          : Color.lerp(cor, Cores.tinta, 0.14)!;
      canvas.drawPath(
        Path()
          ..moveTo(-6, base)
          ..lineTo(6, base)
          ..lineTo(0, ponta + desce)
          ..close(),
        _p(sombreada),
      );
      // O vão, com a parede da mandíbula de baixo (1,3) em volta.
      final vao = Path()
        ..moveTo(-4.7, base)
        ..lineTo(4.7, base)
        ..lineTo(0, ponta + desce - 1.6)
        ..close();
      canvas.drawPath(vao, _p(Color.lerp(Cores.tinta, cor, 0.3)!));
      if (lingua && e.temLingua && vida.lingua > 0 && a > 0.45) {
        final mostra =
            ((a - 0.45) / 0.1).clamp(0.0, 1.0) * vida.lingua.clamp(0.0, 1.0);
        canvas.save();
        canvas.clipPath(vao);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, ponta + desce * 0.25),
            width: 2.8,
            height: 1.8,
          ),
          _p(_corDaLingua.withValues(alpha: mostra)),
        );
        canvas.restore();
      }
    }
    canvas.drawPath(
      Path()
        ..moveTo(-6, base)
        ..lineTo(6, base)
        ..lineTo(0, ponta)
        ..close(),
      _p(cor),
    );
    if (faixa != null) {
      canvas.drawLine(
        Offset(-2.6, faixaEm),
        Offset(2.6, faixaEm),
        _traco(faixa, 1.2),
      );
    }
  }

  /// A língua de fora — só quando ele está de fato alegre.
  ///
  /// É o gesto que o dono do produto reconhece de imediato num cão, e o que
  /// mais separa o buldogue radiante do contente. Fica fora dos outros três
  /// humores de propósito: língua pendurada num bicho que está sentindo sua
  /// falta viraria um cão ofegante, que é outra coisa.
  void _linguaDoBuldogue(Canvas canvas) {
    if (mood != Mood.radiant && pose.gosto < 0.5) return;
    // Falando, a língua não fica pendurada: ela volta para dentro da boca
    // (a de dentro, de [_boca]). Pendurada durante a fala, cobria os dentes
    // e o queixo e a boca não lia.
    if (_abertura > 0.02) return;
    // Na camada de corpo da série (sem boca) ela não entra: lá a boca é
    // outra camada que abre e fecha, e a língua do corpo ficava pendurada
    // debaixo da boca aberta.
    if (pose.vida.semBoca || PetView.aoDesenharBoca != null) return;   // na série (camadas capturadas) a língua não fica para fora
    // Ela cresce com a alegria em vez de aparecer inteira de uma vez: um
    // apêndice que liga e desliga entre dois quadros lê como falha de
    // desenho.
    final quanto = mood == Mood.radiant
        ? 1.0
        : ((pose.gosto - 0.5) / 0.5).clamp(0.0, 1.0);
    // Balança de leve com a respiração. Língua parada é língua de plástico.
    final oscila = pose.respiro * pose.amplitude * 1.6;
    // Pendurada no lábio de baixo: desce com a mandíbula quando a boca abre.
    final desce = _abertura * BocaDaEspecie.de(species).hMax;
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(
          center: Offset(oscila, 35 + desce + quanto * 4),
          width: 19,
          height: 9 + quanto * 14,
        ),
        topo: 0.4,
      ),
      _p(_corDaLingua),
    );
    // O sulco do meio: sem ele a língua é uma gota rosa e pode ler como
    // qualquer outra coisa pendurada na boca.
    canvas.drawLine(
      Offset(oscila, 35 + desce + quanto * 2),
      Offset(oscila, 35 + desce + quanto * 11),
      _traco(Color.lerp(Cores.acento, Cores.tinta, 0.35)!, 1.3),
    );
  }

  /// A sobrancelha, que é onde o humor de um cão mora.
  ///
  /// Buldogue francês tem a marca da sobrancelha visível no pelo acima do
  /// olho, e é ela — não a boca — que um humano lê primeiro num cachorro. Os
  /// dois números por humor são a altura da ponta de dentro e a da ponta de
  /// fora, em pixels a partir da linha de base; negativo sobe.
  ///
  /// O par que carrega o desenho todo é o do `missingYou`: ponta interna alta
  /// e externa baixa é a cara de pena, e é anatomicamente o que o músculo
  /// elevador da sobrancelha interna faz num cão pedindo alguma coisa.
  void _sobrancelhaDoBuldogue(Canvas canvas, double lado) {
    final (dentro, fora) = switch (mood) {
      Mood.radiant => (-3.5, -3.0),
      Mood.content => (-1.5, -1.5),
      Mood.neutral => (0.0, 0.0),
      Mood.sleepy => (1.5, 3.0),
      Mood.missingYou => (-5.5, 2.5),
    };
    // Dormindo ela relaxa junto com o resto da cara, qualquer que seja o
    // humor: a sobrancelha erguida de quem está de olhos fechados lê como
    // bicho fingindo que dorme.
    final sono = acao == AcaoDoBicho.cochilo ? 1.0 : 0.0;
    // Susto e grito: as duas sobem 6 (BOL-B6, laudo 30 §3.5).
    final sobe = 6 * math.max(pose.vida.susto, pose.vida.grito).clamp(0.0, 1.0);
    final a = -10.0 + dentro * (1 - sono) + sono * 1.5 - sobe;
    final b = -10.0 + fora * (1 - sono) + sono * 3.0 - sobe;
    canvas.drawPath(
      Path()
        ..moveTo(lado * 18, a)
        ..quadraticBezierTo(lado * 27, math.min(a, b) - 1.6, lado * 36, b),
      _traco(sombraForte.withValues(alpha: 0.6), 2.4),
    );
  }

  /// Uma dobra de pele: sombra embaixo, luz um fio acima.
  ///
  /// O par é o ponto todo. Um traço escuro sozinho lê como arranhão; com a
  /// linha clara logo acima ele vira a aresta de uma prega — a pele de cima
  /// pegando luz, a de baixo na sombra dela. É com esta função que a testa,
  /// o stop, a corda do nariz, a papada e o ombro são desenhados, e é por
  /// isso que a paleta do buldogue precisa de tons escuros: num pelo claro
  /// demais a metade escura da dobra desaparece e sobra só o brilho.
  void _dobraDaPele(Canvas canvas, Path linha, {double forca = 1}) {
    // 1,2 px de afastamento e traços de 1,5/1,8. A primeira versão usava 1,5
    // e 1,9/2,2, o que dava uma faixa de quase 4 px: numa cabeça de 66 px de
    // altura a ruga da testa saía do tamanho de uma sobrancelha e a cara
    // ficava com uma grade entre as orelhas.
    canvas.save();
    canvas.translate(0, -1.2);
    canvas.drawPath(linha, _traco(luz.withValues(alpha: 0.30 * forca), 1.5));
    canvas.restore();
    canvas.drawPath(
      linha,
      _traco(sombraForte.withValues(alpha: 0.40 * forca), 1.8),
    );
  }

  // ======================================================================
  // ROUPA
  // ======================================================================

  /// Veste o que o usuário colocou.
  ///
  /// Desenhado **dentro do sistema de coordenadas da cabeça** de cada
  /// espécie, e escalado pelo tamanho dela: a mesma peça serve na capivara
  /// larga e na tartaruga pequena sem código por espécie.
  void _veste(Canvas canvas, double larguraDaCabeca, double alturaDaCabeca) {
    final w = larguraDaCabeca / 2;
    final h = alturaDaCabeca / 2;
    // Toda espécie chama isto já no espaço da cabeça: é o lugar certo para o
    // que o estágio põe nela.
    _marcasDoEstagio(canvas, w, h);
    if (roupas.isEmpty) return;

    // Pescoço primeiro: fica atrás do queixo.
    final pescoco = roupas[Vestimenta.pescoco];
    if (pescoco != null) _cachecol(canvas, w, h, pescoco);

    final rosto = roupas[Vestimenta.rosto];
    if (rosto != null) _oculos(canvas, w, h, rosto);

    final cabeca = roupas[Vestimenta.cabeca];
    if (cabeca != null) _naCabeca(canvas, w, h, cabeca);
  }

  /// O que o estágio desenha na cabeça, por cima de tudo menos a roupa.
  ///
  /// - **Filhote:** um topete de penugem no alto da cabeça. É o traço que
  ///   mais diz "bebê" depois do tamanho.
  /// - **Pleno:** o adulto no auge — o porte cheio, e o detalhe de cada um
  ///   onde ele existe de verdade: o passarinho que pousa na capivara (o
  ///   "táxi" das aves no Pantanal); nas outras, o detalhe natural de cada
  ///   uma (ver o `switch`). Nada disso se compra.
  void _marcasDoEstagio(Canvas canvas, double w, double h) {
    final topo = -h + 2;
    // Penugem é de ave e de mamífero: o tracajá e o axolote nascem lisos.
    final temPenugem =
        species != Species.tortoise && species != Species.axolotl;
    if (estagio == EstagioDoBicho.filhote && temPenugem) {
      final tinta = _p(pelo);
      for (final (dx, alto, inclina) in const [
        (-5.0, 9.0, -0.35),
        (0.0, 12.0, 0.0),
        (5.0, 9.0, 0.35),
      ]) {
        canvas.save();
        canvas.translate(dx, topo + 3);
        canvas.rotate(inclina);
        canvas.drawPath(
          Path()
            ..moveTo(-3, 0)
            ..quadraticBezierTo(-2.5, -alto * 0.7, 0, -alto)
            ..quadraticBezierTo(2.5, -alto * 0.7, 3, 0)
            ..close(),
          tinta,
        );
        canvas.restore();
      }
      return;
    }
    if (estagio != EstagioDoBicho.pleno) return;

    final temChapeu = roupas[Vestimenta.cabeca] != null;
    switch (species) {
      case Species.capybara:
        if (!temChapeu) _passarinho(canvas, Offset(w * 0.30, topo - 1));
      // A buraqueira já tem a sobrancelha branca de sempre: o auge dela é um
      // visitante, como o dos bichos de terra.
      case Species.owl:
        _borboleta(canvas, Offset(w * 0.58, topo - 2), const Color(0xFFF2C94C));
      // As outras ganham o que o auge delas tem de natural: a lontra traz
      // a flor do lago presa ao pelo, o tracajá uma florzinha de margem, o
      // axolote as guelras que brilham, o pinguim a crista dourada, e os
      // três de terra um visitante — borboleta ou joaninha — que só pousa
      // em quem está tranquilo.
      case Species.otter:
        _flor(
          canvas,
          Offset(-w * 0.62, topo + 9),
          Colors.white,
          const Color(0xFFF2C14E),
          5.5,
        );
      case Species.tortoise:
        _flor(
          canvas,
          Offset(w * 0.55, topo + 7),
          const Color(0xFFF2C14E),
          const Color(0xFFE08A3C),
          5,
        );
      case Species.axolotl:
        for (final lado in [-1.0, 1.0]) {
          for (final (dx, dy) in const [
            (1.08, -0.15),
            (1.0, -0.55),
            (0.88, 0.2),
          ]) {
            final p = Offset(lado * w * dx, h * dy);
            canvas.drawCircle(
              p,
              5.5,
              _p(const Color(0xFFD8FFFB).withValues(alpha: 0.85))
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
            );
            canvas.drawCircle(p, 1.6, _p(Colors.white));
          }
        }
      case Species.penguin:
        // O magalhães não tem crista: a dourada de antes era de outro
        // pinguim (auditoria da Onda 3, 11b-M3). No auge, a pele rosa entre
        // o olho e o bico fica maior e mais viva, como na época de ninho —
        // desenhada na própria cabeça ([_pinguim]).
        break;
      case Species.cat:
        _borboleta(canvas, Offset(w * 0.62, topo - 4), const Color(0xFFE9A0C4));
      case Species.fox:
        _joaninha(canvas, Offset(-w * 0.35, topo + 2));
      case Species.frenchie:
        _borboleta(
          canvas,
          Offset(-w * 0.62, topo - 2),
          const Color(0xFF8EC5E8),
        );
    }
  }

  /// Uma flor de cinco pétalas, vista de frente.
  void _flor(Canvas canvas, Offset o, Color petala, Color miolo, double r) {
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      canvas.drawCircle(
        o + Offset(math.cos(a), math.sin(a)) * r * 0.75,
        r * 0.55,
        _p(petala),
      );
    }
    canvas.drawCircle(o, r * 0.4, _p(miolo));
  }

  /// Uma borboleta pousada, de asas abertas.
  void _borboleta(Canvas canvas, Offset o, Color asa) {
    final escura = Color.lerp(asa, Cores.tinta, 0.35)!;
    for (final lado in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: o + Offset(lado * 4.5, -2.5),
          width: 8,
          height: 9,
        ),
        _p(asa),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: o + Offset(lado * 3.6, 3.2),
          width: 6,
          height: 6.5,
        ),
        _p(escura),
      );
    }
    final corpo = _traco(Cores.tinta, 1.4);
    final antena = _traco(Cores.tinta, 0.8);
    canvas.drawLine(o + const Offset(0, -4), o + const Offset(0, 5), corpo);
    canvas.drawLine(
      o + const Offset(0, -4),
      o + const Offset(-2.5, -8),
      antena,
    );
    canvas.drawLine(o + const Offset(0, -4), o + const Offset(2.5, -8), antena);
  }

  /// Uma joaninha: cúpula vermelha, cabeça preta, pintas.
  void _joaninha(Canvas canvas, Offset o) {
    canvas.drawCircle(o + const Offset(0, -4.2), 2.6, _p(Cores.tinta));
    canvas.drawOval(
      Rect.fromCenter(center: o, width: 10, height: 9),
      _p(const Color(0xFFD9473A)),
    );
    canvas.drawLine(
      o + const Offset(0, -4.4),
      o + const Offset(0, 4.4),
      _traco(Cores.tinta, 0.9),
    );
    for (final d in const [
      Offset(-2.4, -1),
      Offset(2.4, -1),
      Offset(-2.2, 2.2),
      Offset(2.2, 2.2),
    ]) {
      canvas.drawCircle(o + d, 1.1, _p(Cores.tinta));
    }
  }

  /// O passarinho que pousa na capivara plena. Pequeno, de perfil, olhando
  /// para frente — um anu ou um suiriri, sem pretensão de espécie.
  void _passarinho(Canvas canvas, Offset pe) {
    final corpo = const Color(0xFFF2C14E);
    final asa = const Color(0xFF8A6A3A);
    canvas.save();
    canvas.translate(pe.dx, pe.dy);
    // Patinhas.
    canvas.drawLine(
      const Offset(-2, 0),
      const Offset(-2, -4),
      _traco(Cores.tinta, 1.2),
    );
    canvas.drawLine(
      const Offset(2, 0),
      const Offset(2, -4),
      _traco(Cores.tinta, 1.2),
    );
    // Corpo e cauda.
    canvas.drawPath(
      Path()
        ..moveTo(-10, -9)
        ..lineTo(-15, -12)
        ..lineTo(-13, -7)
        ..close(),
      _p(asa),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-1, -9), width: 17, height: 11),
      _p(corpo),
    );
    canvas.drawCircle(const Offset(6, -15), 5.2, _p(corpo));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-3, -10), width: 9, height: 6),
      _p(asa),
    );
    // Bico e olho.
    canvas.drawPath(
      Path()
        ..moveTo(10.5, -16)
        ..lineTo(14.5, -14.6)
        ..lineTo(10.5, -13.4)
        ..close(),
      _p(const Color(0xFFE08A3C)),
    );
    canvas.drawCircle(const Offset(7.4, -16), 1.3, _p(Cores.tinta));
    canvas.restore();
  }

  /// O começo de quem bota ovo: o ovo, no lugar onde aquela espécie o põe.
  ///
  /// - Coruja: ovo branco, quase redondo, num ninho de gravetos.
  /// - Pinguim: ovo creme num anel de pedrinhas (o pinguim-de-magalhães faz
  ///   ninho em toca rasa e o forra).
  /// - Tartaruga: ovo branco meio enterrado na areia — a tartaruga cava e vai
  ///   embora; o sol choca.
  /// - Axolote: um cacho de ovos gelatinosos preso numa folha d'água, cada um
  ///   com o embrião escuro à vista.
  ///
  /// Ele está vivo: balança com o fôlego e dá um tranco de vez em quando (o
  /// mesmo relógio irregular da orelha). Quem olha tem de achar que tem
  /// alguém ali dentro.
  void _ovo(Canvas canvas, Offset chao) {
    final amp = pose.amplitude;
    final tranco = math.sin(pose.orelha * math.pi * 4) * 0.10 * amp;
    final balanco = pose.respiro * 0.025 * amp + tranco;

    switch (species) {
      case Species.axolotl:
        _ovosDoAxolote(canvas, chao, balanco);
        return;
      case Species.tortoise:
        // Areia atrás.
        canvas.drawOval(
          Rect.fromCenter(
            center: chao + const Offset(0, -4),
            width: 120,
            height: 34,
          ),
          _p(const Color(0xFFE6CC9A)),
        );
      case Species.owl:
        _ninho(canvas, chao, frente: false);
      case Species.penguin:
        for (var i = 0; i < 9; i++) {
          final a = math.pi + i / 8 * math.pi;
          canvas.drawOval(
            Rect.fromCenter(
              center: chao + Offset(math.cos(a) * 44, -6 + math.sin(a) * 9),
              width: 16,
              height: 11,
            ),
            _p(
              Color.lerp(
                const Color(0xFF9A9389),
                Colors.white,
                (i % 3) * 0.12,
              )!,
            ),
          );
        }
      case Species.capybara ||
          Species.otter ||
          Species.cat ||
          Species.fox ||
          Species.frenchie:
        break;
    }

    final casca = switch (species) {
      Species.penguin => const Color(0xFFF1EBDD),
      Species.tortoise => const Color(0xFFF7F3EA),
      _ => const Color(0xFFF5F1E8),
    };
    final (largura, altura) = switch (species) {
      Species.tortoise => (40.0, 42.0),
      Species.owl => (44.0, 52.0),
      _ => (46.0, 58.0),
    };
    final base = chao + const Offset(0, -6);

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(balanco);
    final ovo = Path()
      ..moveTo(0, -altura)
      ..cubicTo(largura * 0.62, -altura, largura * 0.56, 0, 0, 0)
      ..cubicTo(-largura * 0.56, 0, -largura * 0.62, -altura, 0, -altura)
      ..close();
    canvas.drawPath(ovo, _p(casca));
    canvas.save();
    canvas.clipPath(ovo);
    // Sombra do lado de baixo e da direita: volume, não adesivo.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(largura * 0.32, -altura * 0.30),
        width: largura,
        height: altura,
      ),
      _p(Color.lerp(casca, Cores.tinta, 0.10)!),
    );
    if (species == Species.penguin) {
      final sorte = math.Random(7);
      for (var i = 0; i < 9; i++) {
        canvas.drawCircle(
          Offset(
            (sorte.nextDouble() - 0.5) * largura * 0.8,
            -altura * (0.2 + sorte.nextDouble() * 0.7),
          ),
          1 + sorte.nextDouble() * 1.4,
          _p(const Color(0xFFB9AE98)),
        );
      }
    }
    canvas.restore();
    // O brilho.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-largura * 0.18, -altura * 0.70),
        width: 9,
        height: 14,
      ),
      _p(Colors.white.withValues(alpha: 0.85)),
    );
    canvas.drawPath(ovo, _traco(Color.lerp(casca, Cores.tinta, 0.22)!, 1.4));
    canvas.restore();

    switch (species) {
      case Species.tortoise:
        // Areia na frente: o ovo está enterrado até a metade.
        canvas.drawPath(
          Path()
            ..moveTo(chao.dx - 62, chao.dy + 4)
            ..quadraticBezierTo(
              chao.dx - 30,
              chao.dy - 18,
              chao.dx,
              chao.dy - 12,
            )
            ..quadraticBezierTo(
              chao.dx + 30,
              chao.dy - 18,
              chao.dx + 62,
              chao.dy + 4,
            )
            ..close(),
          _p(const Color(0xFFDDBE85)),
        );
        for (final d in const [
          Offset(-30, -6),
          Offset(14, -9),
          Offset(36, -2),
        ]) {
          canvas.drawCircle(chao + d, 1.4, _p(const Color(0xFFC4A266)));
        }
      case Species.owl:
        _ninho(canvas, chao, frente: true);
      case Species.penguin:
        for (var i = 0; i < 7; i++) {
          final a = i / 6 * math.pi;
          canvas.drawOval(
            Rect.fromCenter(
              center: chao + Offset(math.cos(a) * 46, -4 + math.sin(a) * 7),
              width: 17,
              height: 12,
            ),
            _p(
              Color.lerp(
                const Color(0xFF8C857B),
                Colors.white,
                (i % 3) * 0.14,
              )!,
            ),
          );
        }
      case Species.axolotl ||
          Species.capybara ||
          Species.otter ||
          Species.cat ||
          Species.fox ||
          Species.frenchie:
        break;
    }
  }

  /// O cacho de ovos do axolote, numa folha d'água.
  void _ovosDoAxolote(Canvas canvas, Offset chao, double balanco) {
    // A folha onde a mãe prendeu os ovos.
    canvas.drawPath(
      Path()
        ..moveTo(chao.dx - 8, chao.dy)
        ..quadraticBezierTo(
          chao.dx - 30,
          chao.dy - 50,
          chao.dx + 4,
          chao.dy - 78,
        )
        ..quadraticBezierTo(chao.dx + 18, chao.dy - 40, chao.dx - 8, chao.dy)
        ..close(),
      _p(const Color(0xFF6E9B6A)),
    );
    canvas.save();
    canvas.translate(chao.dx, chao.dy - 38);
    canvas.rotate(balanco * 0.6);
    canvas.scale(1.3);
    const ovos = [
      Offset(-14, -14),
      Offset(4, -20),
      Offset(18, -8),
      Offset(-20, 4),
      Offset(0, 0),
      Offset(16, 10),
      Offset(-6, 16),
    ];
    for (var i = 0; i < ovos.length; i++) {
      final o = ovos[i];
      canvas.drawCircle(
        o,
        10.5,
        _p(const Color(0xFFD7EEE6).withValues(alpha: 0.78)),
      );
      canvas.drawCircle(o, 10.5, _traco(const Color(0xFF9CC7BA), 1.1));
      // O embrião: um grão escuro que vira vírgula conforme o ovo amadurece.
      final gira = i * 1.3 + pose.respiro * 0.2;
      canvas.drawCircle(
        o + Offset(math.cos(gira) * 1.5, math.sin(gira) * 1.5),
        3.4,
        _p(const Color(0xFF5B4A44)),
      );
      canvas.drawCircle(
        o + const Offset(-3.5, -4),
        2,
        _p(Colors.white.withValues(alpha: 0.8)),
      );
    }
    canvas.restore();
  }

  /// O ninho: bacia de gravetos e capim. Desenhado em duas metades — o fundo
  /// antes de quem está dentro, a borda da frente depois —, para o filhote
  /// ficar **dentro** dele e não colado por cima.
  void _ninho(Canvas canvas, Offset chao, {required bool frente}) {
    const marrom = Color(0xFF8B6440);
    final escuro = Color.lerp(marrom, Cores.tinta, 0.35)!;
    final claro = Color.lerp(marrom, const Color(0xFFE8D2A6), 0.45)!;
    if (!frente) {
      canvas.drawOval(
        Rect.fromCenter(
          center: chao + const Offset(0, -14),
          width: 104,
          height: 34,
        ),
        _p(escuro),
      );
      return;
    }
    final borda = Path()
      ..moveTo(chao.dx - 56, chao.dy - 16)
      ..quadraticBezierTo(chao.dx, chao.dy - 2, chao.dx + 56, chao.dy - 16)
      ..quadraticBezierTo(chao.dx + 50, chao.dy + 8, chao.dx, chao.dy + 9)
      ..quadraticBezierTo(chao.dx - 50, chao.dy + 8, chao.dx - 56, chao.dy - 16)
      ..close();
    canvas.drawPath(borda, _p(marrom));
    // Gravetos e fios de capim cruzando a borda.
    final sorte = math.Random(species.index + 11);
    for (var i = 0; i < 16; i++) {
      final x = (sorte.nextDouble() - 0.5) * 104;
      final y = -10 + sorte.nextDouble() * 14;
      final a = (sorte.nextDouble() - 0.5) * 0.9;
      final c = math.cos(a) * 13;
      final d = math.sin(a) * 13;
      canvas.drawLine(
        chao + Offset(x - c, y - d),
        chao + Offset(x + c, y + d),
        _traco(i.isEven ? claro : escuro, 1.6),
      );
    }
  }

  void _cachecol(Canvas canvas, double w, double h, Color cor) {
    final y = h * 0.94;
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.62, y - h * 0.10)
        ..cubicTo(
          -w * 0.30,
          y + h * 0.16,
          w * 0.30,
          y + h * 0.16,
          w * 0.62,
          y - h * 0.10,
        )
        ..cubicTo(
          w * 0.58,
          y + h * 0.22,
          -w * 0.58,
          y + h * 0.22,
          -w * 0.62,
          y - h * 0.10,
        )
        ..close(),
      _p(cor),
    );
    // A ponta caindo de um lado.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.30, y + h * 0.06)
        ..lineTo(w * 0.50, y + h * 0.62)
        ..lineTo(w * 0.26, y + h * 0.60)
        ..close(),
      _p(Color.lerp(cor, Cores.tinta, 0.18)!),
    );
  }

  void _oculos(Canvas canvas, double w, double h, Color cor) {
    final r = w * 0.20;
    final y = -h * 0.16;
    final aro = _traco(cor, w * 0.045);
    for (final lado in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(lado * w * 0.30, y), r, aro);
    }
    canvas.drawLine(Offset(-w * 0.10, y), Offset(w * 0.10, y), aro);
    // Hastes indo para trás da cabeça.
    for (final lado in [-1.0, 1.0]) {
      canvas.drawLine(
        Offset(lado * (w * 0.30 + r), y),
        Offset(lado * w * 0.96, y - h * 0.06),
        aro,
      );
    }
  }

  void _naCabeca(Canvas canvas, double w, double h, Color cor) {
    switch (roupaDeCabeca) {
      case 'gorro':
        // Gorro: cobre o topo e tem uma pompom.
        canvas.save();
        canvas.clipPath(
          _bolha(
            Rect.fromCenter(center: Offset.zero, width: w * 2, height: h * 2),
          ),
        );
        // Para em -0.50h: os olhos ficam por volta de -0.33h da cabeça em
        // todas as espécies, e um gorro que os cobre não é gorro, é venda.
        canvas.drawRect(Rect.fromLTRB(-w, -h, w, -h * 0.50), _p(cor));
        canvas.restore();
        // Barra e pompom saem por fora do recorte.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(-w * 0.94, -h * 0.64, w * 0.94, -h * 0.46),
            Radius.circular(h * 0.09),
          ),
          _p(Color.lerp(cor, Cores.superficie, 0.30)!),
        );
        canvas.drawCircle(
          Offset(0, -h * 1.08),
          w * 0.13,
          _p(Color.lerp(cor, Cores.superficie, 0.30)!),
        );

      case 'coroa_folhas':
        // Coroa: folhinhas em volta do topo.
        for (var i = -2; i <= 2; i++) {
          final a = i * 0.34;
          canvas.save();
          canvas.translate(math.sin(a) * w * 0.72, -math.cos(a) * h * 0.82);
          canvas.rotate(a);
          canvas.drawPath(
            _bolha(
              Rect.fromCenter(
                center: Offset.zero,
                width: w * 0.20,
                height: h * 0.34,
              ),
            ),
            _p(i.isEven ? cor : Color.lerp(cor, Cores.superficie, 0.24)!),
          );
          canvas.restore();
        }

      default:
        // Chapéu de palha: aba larga e copa baixa. É o padrão.
        // Aba em -0.74h: mais baixa que isso e ela passa na frente dos
        // olhos, que ficam por volta de -0.33h.
        canvas.drawPath(
          _bolha(
            Rect.fromCenter(
              center: Offset(0, -h * 0.92),
              width: w * 1.02,
              height: h * 0.56,
            ),
            base: 0.4,
          ),
          _p(cor),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(0, -h * 0.76),
            width: w * 2.04,
            height: h * 0.34,
          ),
          _p(Color.lerp(cor, Cores.superficie, 0.16)!),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, -h * 0.88),
              width: w * 1.04,
              height: h * 0.14,
            ),
            Radius.circular(h * 0.07),
          ),
          _p(Color.lerp(cor, Cores.tinta, 0.30)!),
        );
    }
  }

  // ======================================================================
  // PARTES COMPARTILHADAS
  // ======================================================================

  /// Pata com dedinhos, não um retângulo.
  ///
  /// [rema] diz de que lado do corpo esta pata está (-1 ou 1). Na água ela
  /// deixa de andar para a frente e para trás e passa a **descrever uma
  /// elipse** — puxa embaixo, volta em cima —, meio ciclo defasada da outra.
  /// Em fase as duas subiam juntas e o bicho parecia pular, não nadar.
  void _pata(
    Canvas canvas,
    Offset o,
    double w,
    double h,
    Color cor,
    double desloca, {
    bool dedos = true,
    double? rema,
  }) {
    var pos = Offset(o.dx + desloca, o.dy);
    // No passo, a pata do lado levanta num arco e vai um pouco à frente.
    final noAr = o.dx < 0 ? pose.vida.pataEsquerda : pose.vida.pataDireita;
    // Na reverência as patas da frente abrem para os lados.
    pos = pos + Offset((o.dx < 0 ? -1 : 1) * 7 * pose.vida.reverencia, 0);
    // A pata no ar LEVANTA num arco e recolhe (laudo 34 R7): o ponto mais
    // baixo dela sobe ≥ 10 % da altura do corpo, sem deslizar de lado. Quem
    // saltita sobe 6 u (o corpo já sobe 7); a capivara, de galope pesado,
    // sobe a pata 9 u porque o corpo quase não sobe; quem ginga sobe 8 e
    // vai um fio à frente. Pendurada para baixo (o +6 de antes) ela
    // cancelava a subida do corpo e o pé ficava grudado no chão (MOV-01).
    final sobeAPata = switch (species) {
      Species.capybara => 9.0,
      Species.frenchie => 6.0,
      _ => _saltita ? 6.0 : 8.0,
    };
    var giraAPata = 0.0;
    if (noAr > 0) {
      pos = pos + Offset(noAr * 2, -noAr * sobeAPata);
      // Os dedos viram para trás ao recolher.
      giraAPata = (o.dx < 0 ? 1 : -1) * 0.3 * noAr;
    }
    if (rema != null && pose.nadando) {
      final a = (pose.ciclo + (rema < 0 ? 0.0 : 0.5)) * math.pi * 2;
      // O -9 recolhe a pata para debaixo do peito. Bicho nadando não deixa a
      // perna esticada onde ela fica de pé: ela puxa embaixo do corpo. E era
      // o que a fazia sair pela borda de baixo do quadro, já que o corpo
      // inteiro afundou.
      //
      // A lontra rema só com as de trás: as da frente ficam paradas junto
      // ao peito (laudo 31 R8). A remada visível (12 × 10) sai da água no
      // retorno (MOV-06).
      pos = species == Species.otter
          ? o + const Offset(0, -9)
          : o +
                Offset(
                  math.cos(a) * 12 * pose.amplitude,
                  math.sin(a) * 10 * pose.amplitude - 9,
                );
    }
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (giraAPata != 0) canvas.rotate(giraAPata);
    canvas.drawPath(
      _bolha(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        base: 0.82,
      ),
      _p(cor),
    );
    if (dedos) {
      final dedo = _traco(Color.lerp(cor, Cores.tinta, 0.35)!, 1.4);
      for (final dx in [-w * 0.22, 0.0, w * 0.22]) {
        canvas.drawLine(Offset(dx, h * 0.16), Offset(dx, h * 0.38), dedo);
      }
    }
    canvas.restore();
  }

  void _patinha(Canvas canvas, Offset o, Color cor, {double? rema}) =>
      _pata(canvas, o, 16, 13, cor, 0, rema: rema);

  /// Orelha com concha interna, e um tremor rápido quando o bicho escuta algo.
  void _orelhaRedonda(
    Canvas canvas,
    Offset o,
    double w,
    double h,
    double giroBase,
  ) {
    final treme = math.sin(pose.orelha * math.pi * 2) * 0.24 * pose.amplitude;
    final susto = pose.vida.susto.clamp(0.0, 1.0);
    final festa = pose.vida.festa.clamp(0.0, 1.0);
    final lado = o.dx < 0 ? -1.0 : 1.0;
    // Susto: em pé (giram 0,45 rad para dentro, sobem 3) e tremendo no
    // repique da mola; festa: para cima e para fora (CAP-05, CAP-21). E
    // uma orelha 0,1 rad diferente da outra no repouso (laudo 31 R11):
    // orelhas gêmeas denunciam o procedural.
    final tremor = math.sin(susto * math.pi * 7) * 0.10 * susto;
    final giro =
        giroBase -
        lado * 0.45 * susto +
        lado * 0.30 * festa +
        (lado > 0 ? 0.1 : 0.0) +
        tremor;
    canvas.save();
    canvas.translate(o.dx, o.dy - 3 * susto - 2 * festa);
    canvas.rotate(giro + treme);
    _oval(
      canvas,
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      sombra,
    );
    _oval(
      canvas,
      Rect.fromCenter(center: Offset.zero, width: w * 0.52, height: h * 0.52),
      Color.lerp(sombraForte, Cores.acento, 0.28)!,
    );
    canvas.restore();
  }

  /// Olho: esclera, íris, pupila e dois brilhos — e, por cima, a **pálpebra**.
  ///
  /// A piscada é uma pálpebra que desce: um segmento de círculo na cor do
  /// pelo recortado no disco do olho, com a borda em arco raso seguindo o
  /// contorno. Íris e brilhos ficam redondos e são ocluídos. Antes o olho
  /// inteiro era escalado na vertical (`canvas.scale(1, 1 − f)`) com uma
  /// barra reta no meio: a íris virava uma lente achatada e a meia piscada —
  /// que o sono, o derretido e o emburrado seguram por segundos — lia como
  /// olho riscado (CAP-03, RIO-14, TOCO-05, NINA-05, MEL-06, RAP-04, BOL-O1).
  ///
  /// O susto arregala (1,25·r, pupila 0,30·r, pálpebra pesada some,
  /// sobrancelha sobe 0,4·r — laudo 31 R3); o grito aperta 0,3; o riso fecha
  /// 0,6 em arco feliz (laudo 30 §3.5).
  ///
  /// [sobrancelha] desliga o risco de tristeza que este método desenha por
  /// conta própria. Existe por causa do buldogue: ele tem par de
  /// sobrancelhas desenhado à parte, que muda de ângulo nos cinco humores, e
  /// as duas coisas empilhadas viravam quatro traços em cima de dois olhos.
  ///
  /// [estilo] é a íris da espécie (laudo 33 R1): a gata tem íris âmbar com
  /// pupila em fenda vertical, a raposa íris âmbar com pupila oval; as outras
  /// o disco escuro de sempre.
  void _olho(
    Canvas canvas,
    Offset o,
    double r, {
    bool coruja = false,
    bool sobrancelha = true,
    EstiloDoOlho estilo = EstiloDoOlho.redondo,
  }) {
    final vida = pose.vida;
    final susto = vida.susto.clamp(0.0, 1.0);
    final grito = vida.grito.clamp(0.0, 1.0);
    final rindo = vida.riso > 0;
    // Olho um pouco maior na saudade: é o olhar pidão que pede, não fecha.
    // No susto, arregalado.
    r *= _olhoDoEstagio * (triste ? 1.1 : 1.0) * (1 + 0.25 * susto);
    var f = fechamento;
    // Olhar para baixo pesa a pálpebra de cima (RIO-25).
    final olharBaixo = (pose.olhar.dy * pose.amplitudeToque).clamp(0.0, 1.0);
    f = math.max(f, 0.15 * olharBaixo);
    // O susto abre o olho: as pálpebras pesadas (sono, emburrado, derretido)
    // somem; só uma piscada de verdade continua fechando.
    if (f < 0.94) f *= 1 - susto;
    final alegre = feliz || rindo;
    final corDaPalpebra = coruja
        ? Color.lerp(pelo, Cores.superficie, 0.22)!
        : pelo;

    if (f > 0.94) {
      _olhoFechado(canvas, o, r, alegre: alegre);
    } else {
      _olhoAberto(
        canvas,
        o,
        r,
        f,
        coruja: coruja,
        estilo: estilo,
        susto: susto,
        corDaPalpebra: corDaPalpebra,
      );
    }

    // --- sobrancelhas: fora do caminho do olho fechado (RAP-17) -----------
    final g = geometriaDoOlho(o, r, triste: triste);
    if (triste && sobrancelha && susto < 0.3) {
      // A sobrancelha "pidona": a ponta de dentro sobe, a de fora desce — o
      // que o músculo da testa faz num cão pedindo alguma coisa (AU1+AU4 no
      // FACS). Encostada na pálpebra caída (TOCO-18): longe dela, flutuava.
      final dentro = o.dx < 0 ? 1.0 : -1.0;
      canvas.drawPath(
        Path()
          ..moveTo(g.sobrancelhaDentro.dx, g.sobrancelhaDentro.dy)
          ..quadraticBezierTo(
            o.dx - dentro * r * 0.25,
            o.dy - r * 1.35,
            g.sobrancelhaFora.dx,
            g.sobrancelhaFora.dy,
          ),
        _traco(sombraForte, 2.0),
      );
    }
    // Susto e grito: as sobrancelhas sobem 0,4·r, em arco, sem a curva
    // pidona (laudo 31 R3, laudo 30 §3.5).
    final ergue = math.max(susto, grito);
    if (ergue > 0.05 && sobrancelha) {
      final y = o.dy - r * (1.25 + 0.4 * ergue);
      canvas.drawPath(
        Path()
          ..moveTo(o.dx - r * 0.85, y + r * 0.12)
          ..quadraticBezierTo(
            o.dx,
            y - r * 0.25,
            o.dx + r * 0.85,
            y + r * 0.12,
          ),
        _traco(sombraForte.withValues(alpha: ergue), 1.8),
      );
    }
  }

  /// O olho fechado: só a linha da pálpebra, onde ela encontra a de baixo.
  ///
  /// Três traços: ∩ alto quando está contente (o arco feliz), ⌣ raso para o
  /// sono e o derretido, e quase reto com um fio de ∩ para a piscada rápida
  /// (CAP-12: o ∪ pendurado no centro do olho lampejava "olhinho dormindo"
  /// em cada piscada). A linha fica em +0,78·r, onde a pálpebra que desce
  /// termina (TOCO-16, RAP-17): sem salto entre a fenda e o fechado.
  void _olhoFechado(Canvas canvas, Offset o, double r, {required bool alegre}) {
    final t = _traco(_tracoDoOlho, 2.2);
    if (alegre) {
      canvas.drawArc(
        Rect.fromCircle(center: o, radius: r * 0.95),
        math.pi + 0.3,
        math.pi - 0.6,
        false,
        t,
      );
      return;
    }
    final sono = dormindo || pose.gosto > 0.34;
    final y = o.dy + r * (sono ? 0.66 : 0.78);
    final controle = o.dy + r * (sono ? 1.0 : 0.72);
    canvas.drawPath(
      Path()
        ..moveTo(o.dx - r * 0.9, y)
        ..quadraticBezierTo(o.dx, controle, o.dx + r * 0.9, y),
      t,
    );
  }

  /// O olho aberto (ou meio fechado): disco, íris, brilhos e as pálpebras.
  void _olhoAberto(
    Canvas canvas,
    Offset o,
    double r,
    double f, {
    required bool coruja,
    required EstiloDoOlho estilo,
    required double susto,
    required Color corDaPalpebra,
  }) {
    // A coruja-buraqueira tem o olho amarelo inteiro, sem branco à vista.
    canvas.drawCircle(
      o,
      r,
      _p(coruja ? const Color(0xFFF2C94C) : Cores.superficie),
    );

    // A íris: encolhe no susto (pupila ponto), cresce na saudade.
    final raioDaIris =
        r *
        (coruja
            ? ((triste ? 0.50 : 0.42) - 0.12 * susto)
            : switch (estilo) {
                EstiloDoOlho.fenda => 0.62 - 0.10 * susto,
                EstiloDoOlho.oval => 0.52 - 0.18 * susto,
                EstiloDoOlho.redondo =>
                  (triste ? 0.58 : (feliz ? 0.56 : 0.50)) * (1 - 0.4 * susto),
              });

    // Na saudade o olhar sobe para quem chegou, grande e marejado: o "olhar
    // pidão". Olhando para baixo, com a boca virada, ele lia como emburrado —
    // e um bicho emburrado depois de uma desistência é cobrança.
    //
    // A coruja tem o olho tubular, preso na órbita: a pupila quase não anda
    // (0,25), o olhar vai na cabeça (NINA-07, laudo 32 R2). E a íris nunca
    // sai da esclera (RIO-25): o desvio para com uma folga de 0,6 da borda.
    var desvio =
        _olhoDesvio * (coruja ? 0.25 : 1.0) +
        (triste ? const Offset(0.4, -0.7) : Offset.zero);
    final maxDesvio = math.max(0.0, r - raioDaIris - 0.6);
    if (desvio.distance > maxDesvio) {
      desvio = desvio / desvio.distance * maxDesvio;
    }
    final iris = o + desvio;

    switch (estilo) {
      case EstiloDoOlho.redondo:
        canvas.drawCircle(iris, raioDaIris, _p(Cores.tinta));
      case EstiloDoOlho.fenda:
        // Gata: íris âmbar e pupila em fenda vertical, que arredonda no
        // susto (MEL-09, laudo 33 R1).
        canvas.drawCircle(iris, raioDaIris, _p(const Color(0xFFD9A441)));
        canvas.drawOval(
          Rect.fromCenter(
            center: iris,
            width: r * (0.22 + 0.26 * susto),
            height: r * 0.56,
          ),
          _p(Cores.tinta),
        );
      case EstiloDoOlho.oval:
        // Raposa: anel âmbar e pupila oval (RAP-23).
        canvas.drawCircle(iris, raioDaIris, _p(const Color(0xFFD79A3C)));
        canvas.drawOval(
          Rect.fromCenter(
            center: iris,
            width: raioDaIris * 1.2,
            height: raioDaIris * 1.38,
          ),
          _p(Cores.tinta),
        );
    }

    // Brilhos. Na coruja, dentro da pupila (NINA-06): é o ponto de luz no
    // olho escuro que faz "olho de coruja". Nos outros, reflexo de
    // superfície: acompanham a íris pela metade (RIO-25), não colados nela.
    if (coruja) {
      canvas.drawCircle(
        iris + Offset(-0.42, -0.42) * raioDaIris,
        raioDaIris * 0.32,
        _p(Colors.white),
      );
      canvas.drawCircle(
        iris + Offset(0.35, 0.30) * raioDaIris,
        raioDaIris * 0.16,
        _p(Colors.white70),
      );
    } else {
      final brilho = o + desvio * 0.5;
      canvas.drawCircle(
        brilho + Offset(-r * 0.30, -r * 0.32),
        r * (triste ? 0.25 : 0.20),
        _p(Colors.white),
      );
      canvas.drawCircle(
        brilho + Offset(r * 0.20, r * 0.16),
        r * (triste ? 0.13 : 0.10),
        _p(Colors.white70),
      );
    }
    if (triste) {
      // O brilho de baixo, em meia-lua: olho úmido, não fechado.
      canvas.drawArc(
        Rect.fromCircle(center: iris, radius: raioDaIris * 0.72),
        0.5,
        math.pi - 1.0,
        false,
        _traco(Colors.white.withValues(alpha: 0.75), r * 0.09),
      );
    }

    // --- pálpebras --------------------------------------------------------
    //
    // Tudo recortado em r + 0,8: no raio exato da esclera sobrava a franja
    // antisserrilhada dela por cima, um aro fantasma (CAP-10, RIO-13,
    // TOCO-23, NINA-20, RAP-18).
    final disco = Path()..addOval(Rect.fromCircle(center: o, radius: r + 0.8));
    const curva = 2.5; // raio do arco da borda da pálpebra, em r

    // Pálpebra caída quando neutro ou triste, **espelhada por olho**.
    //
    // O lado de dentro é o que fica virado para o meio da cara. Triste é a
    // ponta de **fora** caída e a de dentro erguida; neutro é uma pálpebra
    // reta, só um toque de peso (−0,78·r: a 0,42 cortava a íris e lia como
    // tédio, MEL-08, LUME-10). No susto ela some.
    if ((mood == Mood.neutral || triste) && susto < 0.95) {
      final g = geometriaDoOlho(o, r, triste: triste);
      final sobe = coruja ? -r * 0.30 : 0.0;
      final caida = Path()
        ..moveTo(g.palpebraDentro.dx, g.palpebraDentro.dy + sobe)
        ..lineTo(g.palpebraFora.dx, g.palpebraFora.dy + sobe)
        ..lineTo(g.palpebraFora.dx, o.dy - r * 1.35)
        ..lineTo(g.palpebraDentro.dx, o.dy - r * 1.35)
        ..close();
      final cor = corDaPalpebra.withValues(alpha: 1 - susto);
      canvas.drawPath(
        Path.combine(PathOperation.intersect, disco, caida),
        _p(cor),
      );
      if (coruja) {
        // Na coruja a pálpebra tem quase a cor do disco: a linha de cílios
        // é o que a faz ler como pálpebra, não como olho achatado.
        canvas.save();
        canvas.clipPath(disco);
        canvas.drawLine(
          Offset(g.palpebraDentro.dx, g.palpebraDentro.dy + sobe),
          Offset(g.palpebraFora.dx, g.palpebraFora.dy + sobe),
          _traco(sombraForte.withValues(alpha: 0.6 * (1 - susto)), 1.4),
        );
        canvas.restore();
      }
    }

    if (f <= 0.02) return;

    // A pálpebra que fecha. De cima: a borda desce de −r a +0,79·r com f e
    // a de baixo sobe um fio (RIO-14) — a esclera visível vira uma lente. A
    // coruja dormindo fecha de baixo para cima (laudo 32 R2).
    final deBaixo = coruja && dormindo;
    final tinta = _p(corDaPalpebra);
    // A linha de cílios: sombra do pelo (creme no pelo escuro), não tinta —
    // em tinta ela voltava a ler como a barra preta de antes.
    final cilio = _traco(
      (pelo.computeLuminance() < 0.16 ? _tracoDoOlho : sombraForte).withValues(
        alpha: 0.85,
      ),
      1.3,
    );
    // A pálpebra desce com f² (não linear): em f = 0,5 cobre um quarto do
    // olho e a íris continua inteira (RIO-14, MEL-06); em 0,94 chega a
    // +0,73·r, onde a linha do olho fechado fica (TOCO-16).
    final desce = f * f * 1.96;
    // A borda de cada pálpebra segue o contorno do olho: a de cima é um
    // arco mais alto no meio (o topo de um círculo grande **abaixo** dela),
    // a de baixo um arco mais baixo no meio (o fundo de um círculo grande
    // **acima**). Com a curva ao contrário a meia piscada lia como cara de
    // bravo: era a pálpebra descendo mais no meio do olho.
    Rect circulo(double centroY) =>
        Rect.fromCircle(center: Offset(o.dx, centroY), radius: r * curva);
    Path foraDo(double centroY) => Path.combine(
      PathOperation.difference,
      disco,
      Path()..addOval(circulo(centroY)),
    );
    void cilioEm(double yBorda) {
      if (f < 0.2) return;
      final meia = math.sqrt(math.max(0.0, r * r - math.pow(yBorda - o.dy, 2)));
      final ang = math.asin((meia / (r * curva)).clamp(0.0, 1.0));
      canvas.drawArc(
        circulo(yBorda + r * curva),
        3 * math.pi / 2 - ang,
        2 * ang,
        false,
        cilio,
      );
    }

    if (deBaixo) {
      // A de baixo subindo: o que fica abaixo do fundo do círculo de cima.
      final yBorda = o.dy + r - r * desce;
      canvas.drawPath(foraDo(yBorda - r * curva), tinta);
      return;
    }
    // A de cima: o que fica acima do topo do círculo de baixo.
    final yCima = o.dy - r + r * desce;
    canvas.drawPath(foraDo(yCima + r * curva), tinta);
    cilioEm(yCima);
    // A de baixo, discreta: sobe 0,06·2r.
    final yBaixo = o.dy + r - 2 * r * f * 0.06;
    canvas.drawPath(foraDo(yBaixo - r * curva), tinta);
  }

  void _narina(Canvas canvas, Offset o) {
    canvas.drawOval(
      Rect.fromCenter(center: o, width: 7.5, height: 5),
      _p(sombraForte),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: o + const Offset(-0.7, -0.9),
        width: 3,
        height: 2,
      ),
      _p(luz.withValues(alpha: 0.5)),
    );
  }

  /// A boca: em repouso, a linha do humor; abrindo, a mandíbula que desce.
  ///
  /// Era binária — qualquer `boca > 0,3` virava a mesma meia-elipse de 9
  /// unidades, sem largura, cavidade, língua nem dentes (laudo 30, §1.1) —
  /// e é daí que vinha o "mouth flapping" da série: seis níveis de abertura
  /// davam dois desenhos. Agora (laudo 30, §3.1, R2 a R4):
  ///
  /// - a **abertura** é contínua: o topo do vão fica na linha do lábio (sobe
  ///   no máximo 1 unidade e nunca a menos de 2 do nariz ou da focinheira,
  ///   [BocaDaEspecie.folgaNariz]) e a mandíbula desce `hMax · abertura`;
  /// - a **largura** vem de `w·(0,44 + 0,16·abertura)`, esticada até +30 %
  ///   com `largura` positiva; negativa, a boca arredonda e a largura passa a
  ///   acompanhar a altura (o "o" e o "u" são quase círculos). O máximo é
  ///   0,60·w: boca pequena, cara de bicho fofo (laudo 31, R1);
  /// - o interior é cavidade (`lerp(tinta, pelo, 0,25)`), não terracota
  ///   chapada; o contorno é o traço do lábio em volta inteira, inclusive no
  ///   topo; a língua aparece a partir de 0,45 de abertura e a linha de
  ///   dentes nas espécies que têm;
  /// - os **cantos** somam o humor (radiante +0,6, contente +0,3, saudade
  ///   −0,4) ao que o motor pedir.
  ///
  /// Em repouso (abertura, largura e canto zerados) o desenho é o mesmo de
  /// antes, arco por arco, para a cara do app não mudar: o formato aberto
  /// nasce dos cantos e da curva da boca do humor e chega à forma
  /// paramétrica nos primeiros 30 % de abertura. Com `largura` sem abrir, os
  /// lábios se apertam numa linha mais grossa (o A de p, b, m) ou franzem.
  ///
  /// [cor] troca a tinta do traço. Existe por causa do buldogue: a boca dele
  /// cai sobre a focinheira e, nas pelagens escuras, `sombraForte` sobre pelo
  /// já escuro somem uma na outra — sobravam dois dentinhos brancos flutuando
  /// sem boca nenhuma em volta. Nas outras oito o padrão continua valendo.
  void _boca(Canvas canvas, {Color? cor}) {
    final e = BocaDaEspecie.de(species);
    final o = e.origem;
    final w = e.largura;
    PetView.aoDesenharBoca?.call(canvas.getTransform(), o, w);
    final vida = pose.vida;

    // A comida não é a boca: fica no corpo mesmo quando a camada de boca
    // sai (`semBoca`).
    _naBoca(canvas, o, w);
    if (vida.semBoca) return;

    final tinta = cor ?? sombraForte;
    final a = _abertura;
    // A emoção manda na boca antes do motor: o "o" do susto, o D da festa,
    // o grito e o riso (laudo 30 §3.5).
    final emo = _emocaoDaBoca;
    final larguraPedida = emo?.largura ?? vida.largura;
    final cantoPedido = emo?.canto ?? vida.canto;
    final linguaPedida = emo?.lingua ?? vida.lingua;
    final dentesPedidos = emo?.dentes ?? vida.dentes;
    if (a == 0 && larguraPedida == 0 && cantoPedido == 0) {
      _bocaDoHumor(canvas, o, w, _traco(tinta, 1.9));
      if (species == Species.frenchie) {
        final h = _curvaDoHumor(o, w);
        _dentinhosDoBuldogue(canvas, o.dx, h.topo, h.xCanto);
      }
      return;
    }

    // --- o alvo aberto ----------------------------------------------------
    final larg = (larguraPedida + e.larguraBase).clamp(-1.0, 1.0);
    final k = Curves.easeInOut.transform((a / 0.3).clamp(0.0, 1.0));
    final canto = (cantoPedido + (emo == null ? _cantoDoHumor : 0) * k).clamp(
      -1.0,
      1.0,
    );
    final sobe = math.min(a * e.labioSobe, e.folgaNariz - 2).clamp(0.0, 1.0);
    final vao = a * e.hMax + sobe;
    final base = w * (0.44 + 0.16 * a);
    // Arredondando, a largura vai da fórmula para 0,8 da altura — um
    // círculo um pouco mais alto que largo — depressa (expoente 0,4): o E
    // (largura -0,5) já tem de ler como "o" também no buldogue, de boca
    // larga (w = 30), e no axolote, que parte de +0,3.
    final larguraAberta = larg >= 0
        ? base * (1 + 0.3 * larg)
        : base + (vao * 0.8 - base) * math.pow(-larg, 0.4);
    final aberta = _CurvaDaBoca(
      xCanto: larguraAberta / 2,
      yCanto: o.dy - canto * (1.5 + 0.25 * vao),
      topo: o.dy - sobe,
      bico: larg >= 0 ? 0.55 + 0.3 * larg : 0.55 * (1 + larg),
    );

    // --- o repouso: a boca do humor, apertada ou franzida pela largura ---
    final t = (larguraPedida.abs() / 0.35).clamp(0.0, 1.0);
    final humor = _curvaDoHumor(o, w);
    final apertada = _CurvaDaBoca(
      xCanto: w * (0.35 + 0.15 * larguraPedida.clamp(-1.0, 1.0)),
      yCanto: o.dy - cantoPedido * 1.5,
      topo: o.dy,
      bico: 0.6,
    );
    final fechada = _CurvaDaBoca.lerp(
      humor.cantosEm(humor.yCanto - cantoPedido * 1.5),
      apertada,
      t,
    );

    final curva = _CurvaDaBoca.lerp(fechada, aberta, k);
    final fundo = curva.topo + vao;
    final caminho = curva.caminho(o.dx, fundo);
    // O traço primeiro e a cavidade por cima: o lábio fica com a metade de
    // fora do traço e o vão fica inteiro. Com o traço por cima, a fresta do
    // B (2 unidades) sumia dentro das 1,9 do contorno.
    canvas.drawPath(caminho, _traco(tinta, 1.9 + 0.5 * t * (1 - k)));
    if (vao > 0) {
      canvas.drawPath(caminho, _p(Color.lerp(Cores.tinta, pelo, 0.25)!));
      canvas.save();
      canvas.clipPath(caminho);
      if (e.temDentes && dentesPedidos > 0 && species != Species.frenchie) {
        _dentes(canvas, o.dx, curva, dentesPedidos.clamp(0.0, 1.0));
      }
      if (e.temLingua && linguaPedida > 0 && a > 0.45 && !_linguaDeFora) {
        final mostra =
            ((a - 0.45) / 0.1).clamp(0.0, 1.0) * linguaPedida.clamp(0.0, 1.0);
        final alta = vao * 0.32;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(o.dx, fundo - alta * 0.45),
            width: curva.xCanto,
            height: alta,
          ),
          _p(_corDaLingua.withValues(alpha: mostra)),
        );
      }
      canvas.restore();
    }
    if (species == Species.frenchie) {
      _dentinhosDoBuldogue(canvas, o.dx, fundo, curva.xCanto);
    }
  }

  /// A cor da língua — a mesma que o buldogue já punha para fora.
  static final _corDaLingua = Color.lerp(Cores.acento, Cores.superficie, 0.28)!;

  /// 0..1: quanto a boca (ou o bico) está aberta — o maior entre o bocejo, o
  /// carinho, a mastigada e o que o motor de vida pede (`vida.boca`).
  ///
  /// O carinho entra com zona morta: o controlador do toque para em 1 e fica
  /// lá, onde `carinho` vale e^-2,2 ≈ 0,11. O limiar binário de antes (0,4)
  /// escondia isso; com a abertura contínua, sem a zona morta a boca ficava
  /// um fio aberta para sempre depois do primeiro toque
  /// (`pet_vivo_test`: "depois do toque nada fica preso na pose").
  double get _abertura {
    final afago = ((pose.carinho - 0.12) / 0.88).clamp(0.0, 1.0) * 0.6;
    final emocao = _emocaoDaBoca?.abertura ?? 0;
    return math
        .max(
          math.max(math.max(pose.bocejo, afago), emocao),
          math.max(pose.mastiga, pose.vida.boca),
        )
        .clamp(0.0, 1.0);
  }

  /// A boca das assinaturas do rosto (laudo 30 §3.5), por prioridade:
  ///
  /// - **grito**: D inteiro mais alto que largo (largura −0,45), sem canto;
  /// - **riso**: a abertura pulsa 0,5↔0,9 com a fase que o motor manda em
  ///   `riso`, cantos +0,8, mais larga;
  /// - **susto** sem fala: o "o" do visema E, franzido até ficar redondo
  ///   (B03: o vão mais alto que largo), entrando entre 0,3 e 0,7 de susto;
  /// - **festa** sem fala: D a 0,6 com cantos para cima e língua (CAP-21).
  ///
  /// Nulo quando nenhuma delas está ligada: a boca segue o motor.
  ({
    double abertura,
    double largura,
    double canto,
    double lingua,
    double dentes,
  })?
  get _emocaoDaBoca {
    final v = pose.vida;
    if (v.grito > 0.05) {
      final g = v.grito.clamp(0.0, 1.0);
      return (abertura: g, largura: -0.45 * g, canto: 0, lingua: 1, dentes: 0);
    }
    if (v.riso > 0) {
      final fase = v.riso.clamp(0.0, 1.0);
      return (
        abertura: 0.5 + 0.4 * fase,
        largura: 0.4,
        canto: 0.8,
        lingua: 1,
        dentes: 0,
      );
    }
    final fala = v.boca > 0.08;
    if (v.susto > 0.3 && !fala) {
      final k = ((v.susto - 0.3) / 0.4).clamp(0.0, 1.0);
      final e = bocaDoVisema(Visema.e);
      return (
        abertura: e.abertura * k,
        largura: -(0.6 + 0.4 * k),
        canto: 0,
        lingua: 0,
        dentes: 0,
      );
    }
    if (v.festa > 0.3 && !fala) {
      final k = ((v.festa - 0.3) / 0.4).clamp(0.0, 1.0);
      return (
        abertura: 0.6 * k,
        largura: 0.2,
        canto: 0.8 * k,
        lingua: 1,
        dentes: 0,
      );
    }
    return null;
  }

  /// O que o humor faz com os cantos da boca aberta (laudo 30, §3.1 e §3.5).
  double get _cantoDoHumor => switch (mood) {
    Mood.radiant => 0.6,
    Mood.content => 0.3,
    Mood.neutral => 0.0,
    Mood.sleepy => 0.0,
    Mood.missingYou => -0.4,
  };

  /// Quanto o queixo (a base da bolha da cabeça) desce com a boca bem
  /// aberta: `3 + 4·abertura` a partir de 0,5 (laudo 31, R1), entrando
  /// suave entre 0,5 e 0,75 para não dar um salto.
  double get _queixoDesce {
    // Nas capturas da série a boca vira uma camada à parte, composta sobre o
    // corpo sem boca: o queixo não pode descer, senão a camada leva junto um
    // pedaço do contorno da cabeça (o "fantasma" em volta da boca da Rio).
    if (PetView.aoDesenharBoca != null) return 0;
    final a = _abertura;
    if (a <= 0.5) return 0;
    return ((a - 0.5) / 0.25).clamp(0.0, 1.0) * (3 + 4 * a);
  }

  /// A língua está para fora (o buldogue alegre): a de dentro não entra, ou
  /// o bicho ficava com duas.
  bool get _linguaDeFora =>
      species == Species.frenchie &&
      (mood == Mood.radiant || pose.gosto >= 0.5) &&
      _abertura <= 0.02;

  /// A linha de dentes de cima, pendurada no lábio dentro do vão — o B da
  /// fala ("ligeiramente aberta, dentes cerrados"). A capivara mostra os dois
  /// incisivos; gata e raposa, a linha.
  void _dentes(Canvas canvas, double cx, _CurvaDaBoca curva, double quanto) {
    final cor = Cores.superficie.withValues(alpha: quanto);
    if (species == Species.capybara) {
      for (final lado in [-1.0, 1.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx + lado * 1.7 - 1.5, curva.topo + 0.3, 3, 4),
            const Radius.circular(0.8),
          ),
          _p(cor),
        );
      }
      return;
    }
    canvas.drawPath(curva.labio(cx, desce: 1.0), _traco(cor, 1.2));
  }

  /// Prognatismo: dois dentinhos de baixo aparecendo por cima do lábio. É o
  /// traço do padrão da raça que ninguém desenha e todo mundo reconhece —
  /// sem ele a cara achatada fica com um sorriso de gato.
  ///
  /// Desenhados **depois** do vão de propósito: com a boca aberta eles caem
  /// sobre o escuro, que é onde os dentes de baixo de fato ficam. São da
  /// mandíbula: descem com ela — metade do que o lábio de baixo desce, para
  /// continuarem apontando para dentro do vão em vez de sumirem sob o lábio.
  ///
  /// Recém-nascido e filhote não mostram: cachorro nasce sem dente, e os
  /// de leite só despontam pela terceira semana.
  void _dentinhosDoBuldogue(
    Canvas canvas,
    double cx,
    double labioDeBaixo,
    double meiaLargura,
  ) {
    if (estagio.index < EstagioDoBicho.jovem.index) return;
    // Presos ao lábio de baixo (a mandíbula): apoiados nele, apontando para
    // cima, e sempre dentro da largura da boca. Numa posição fixa do rosto
    // eles flutuavam abaixo da boca fechada e se descolavam dela quando a
    // boca abria.
    final x = math.min(4.2, meiaLargura * 0.42);
    for (final lado in [-1.0, 1.0]) {
      canvas.drawPath(
        _bolha(
          Rect.fromCenter(
            center: Offset(cx + lado * x, labioDeBaixo - 1.6),
            width: 5.0,
            height: 5.2,
          ),
          topo: 0.8,
        ),
        _p(Cores.superficie),
      );
    }
  }


  /// A boca do humor como curva paramétrica, para o formato aberto nascer
  /// dela. São aproximações, com um cúbico só, dos arcos de [_bocaDoHumor]:
  /// coincidem nos cantos e no meio e diferem por menos de meio pixel no
  /// resto — por isso o repouso exato continua sendo desenhado pelos arcos.
  _CurvaDaBoca _curvaDoHumor(Offset o, double w) => switch (mood) {
    Mood.radiant => _CurvaDaBoca(
      xCanto: w * 0.5 * math.cos(0.18),
      yCanto: o.dy + w * 0.36 * math.sin(0.18),
      topo: o.dy + w * 0.36,
      bico: 0.05,
    ),
    Mood.content => _CurvaDaBoca(
      xCanto: w * 0.4 * math.cos(0.3),
      yCanto: o.dy + w * 0.25 * math.sin(0.3),
      topo: o.dy + w * 0.25,
      bico: 0.08,
    ),
    Mood.neutral => _CurvaDaBoca(
      xCanto: w * 0.3,
      yCanto: o.dy,
      topo: o.dy,
      bico: 0.6,
    ),
    Mood.sleepy => _CurvaDaBoca(
      xCanto: w * 0.25 * math.cos(0.2),
      yCanto: o.dy + 2 + 3 * math.sin(0.2),
      topo: o.dy + 5,
      bico: 0.05,
    ),
    Mood.missingYou => _CurvaDaBoca(
      xCanto: w * 0.23 * math.cos(0.45),
      yCanto: o.dy + 5 - w * 0.13 * math.sin(0.45),
      topo: o.dy + 5 - w * 0.13,
      bico: 0.12,
    ),
  };

  /// Os cinco arcos de repouso, um por humor — os mesmos de sempre, traço
  /// por traço (o X da fala é "a boca do humor atual").
  void _bocaDoHumor(Canvas canvas, Offset o, double w, Paint t) {
    switch (mood) {
      case Mood.radiant:
        canvas.drawArc(
          Rect.fromCenter(center: o, width: w, height: w * 0.72),
          0.18,
          math.pi - 0.36,
          false,
          t,
        );
      case Mood.content:
        canvas.drawArc(
          Rect.fromCenter(center: o, width: w * 0.8, height: w * 0.5),
          0.3,
          math.pi - 0.6,
          false,
          t,
        );
      case Mood.neutral:
        canvas.drawLine(o + Offset(-w * 0.3, 0), o + Offset(w * 0.3, 0), t);
      case Mood.sleepy:
        canvas.drawArc(
          Rect.fromCenter(
            center: o + const Offset(0, 2),
            width: w * 0.5,
            height: 6,
          ),
          0.2,
          math.pi - 0.4,
          false,
          t,
        );
      case Mood.missingYou:
        // Boquinha pequena e pouco curva: saudade, não bronca. A boca larga
        // virada para baixo era o que fechava a cara.
        canvas.drawArc(
          Rect.fromCenter(
            center: o + const Offset(0, 5),
            width: w * 0.46,
            height: w * 0.26,
          ),
          math.pi + 0.45,
          math.pi - 0.9,
          false,
          t,
        );
    }
  }

  /// O que ele está comendo, saindo do canto da boca.
  ///
  /// Um talo verde é o que separa "abriu a boca" de "está comendo". Fica
  /// numa função própria porque as duas espécies de bico (coruja e pinguim)
  /// não passam por [_boca] — elas desenham o bico à mão — e mesmo assim
  /// petiscam.
  /// Segurando comida na boca: na refeição inteira (o motor diz), na mão da
  /// pessoa, ou no laço do quadro fixo quando a boca abre. Com carinho ele
  /// para de comer — a comida cobria a cara enquanto ele gostava.
  bool get _comComida =>
      pose.carinho < 0.4 &&
      (pose.comendoDaMao ||
          (pose.vida.atividadeAtiva ? pose.vida.comendo : pose.mastiga > 0.05));

  void _naBoca(Canvas canvas, Offset o, double w) {
    if (!_comComida) return;
    // A lontra come com as mãos: a comida vai nas patas (ver [_lontra]).
    if (species == Species.otter) return;
    // O que ele come de verdade (ver `comida.dart`); da mão, o petisco.
    final c = pose.comendoDaMao ? petiscoDe(species) : comidaDe(species);
    // Do tamanho de uma bocada, saindo da boca: com 30% da boca ela era
    // um risco verde que ninguém via.
    pintaComida(
      canvas,
      c,
      Offset(o.dx + w * 0.3, o.dy + 2),
      w * 0.46,
      angulo: -0.35 + pose.mastiga * 0.24,
    );
  }

  void _bochecha(Canvas canvas, Offset a, Offset b) {
    // Desligadas no susto (laudo 31 R3); meia força na festa (CAP-21).
    final susto = pose.vida.susto.clamp(0.0, 1.0);
    final festa = pose.vida.festa.clamp(0.0, 1.0);
    final cor = Cores.acento.withValues(
      alpha: (0.24 + pose.carinho * 0.20 + 0.26 * festa) * (1 - susto),
    );
    for (final o in [a, b]) {
      canvas.drawOval(
        Rect.fromCenter(center: o, width: 14, height: 8),
        _p(cor),
      );
    }
  }

  /// Bigodes. [lado] -1 aponta para a esquerda, 1 para a direita — de frente
  /// o bicho tem os dois.
  void _bigodes(Canvas canvas, Offset o, {double lado = -1}) {
    final t = _traco(sombraForte.withValues(alpha: 0.5), 1.2);
    // Os bigodes acompanham a respiração de leve.
    final abre = pose.respiro * pose.amplitude * 1.1;
    // No susto vão para a frente (lontra, laudo 31 R3) — para trás na gata
    // (MEL-10): 0,3 rad em volta da raiz.
    final susto = pose.vida.susto.clamp(0.0, 1.0);
    final vira = (species == Species.cat ? 0.2 : -0.3) * lado * susto;
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(vira);
    canvas.translate(-o.dx, -o.dy);
    for (var i = 0; i < 3; i++) {
      final dy = (i - 1) * 3.5;
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy + dy)
          ..cubicTo(
            o.dx + lado * 7,
            o.dy + dy - 1 - abre,
            o.dx + lado * 13,
            o.dy + dy - 2 - abre * 1.3,
            o.dx + lado * 19,
            o.dy + dy - 3 - abre * 1.5,
          ),
        t,
      );
    }
    canvas.restore();
  }

  // --- efeitos de cena ----------------------------------------------------

  /// O tom que a água põe sobre o que está submerso.
  ///
  /// Verde de igarapé, não azul de piscina: é a cor da água do habitat
  /// (`0xFFC9DCC0` na superfície, `0xFFAECBA3` no fundo), escurecida. Azul
  /// aqui brigaria com a cena inteira.
  static const _tomDaAgua = Color(0x704E7A63);

  // O degradê da água no mundo, guardado: muda só com a cor da lagoa e o
  // tamanho do quadro, e nadando ele era refeito a cada quadro.
  static Shader? _sombra;
  static (Color, double, double)? _chaveDaSombra;

  static Shader _sombraDaAgua(Color agua, double y, double largura) {
    final chave = (agua, y, largura);
    final pronta = _sombra;
    if (pronta != null && _chaveDaSombra == chave) return pronta;
    _chaveDaSombra = chave;
    return _sombra = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      // Água turva: o corpo some a poucos palmos da superfície. Só a cabeça
      // e o dorso ficam à vista, como num bicho que nada deitado.
      colors: [agua.withValues(alpha: 0.7), agua],
    ).createShader(Rect.fromLTRB(0, y, largura, y + 22));
  }

  /// O rastro: o que a água faz **por causa** do bicho.
  ///
  /// Três coisas, e nenhuma é decorativa. Os anéis dizem que ele se move; as
  /// gotas, que ele bate na água; as bolhas, que há corpo embaixo. Sem elas
  /// o corpo submerso vira uma mancha e o nado some.
  void _rastro(Canvas canvas, Size size, double y) {
    final amp = pose.amplitude;
    final cx = size.width / 2;
    final c = Offset(cx, y + 6);

    // --- anéis abrindo, cada um numa fase ---------------------------------
    // Presos ao laço da braçada, não à boia: é a remada que empurra a água.
    const aneis = [
      (150.0, 19.0, 0.20),
      (112.0, 14.0, 0.15),
      (76.0, 10.0, 0.12),
    ];
    for (var i = 0; i < aneis.length; i++) {
      final (w, h, a) = aneis[i];
      final fase = (pose.ciclo + i * 0.33) % 1.0;
      final cresce = 1 + fase * 0.30 * amp;
      final some = (1 - fase * 0.75).clamp(0.10, 1.0);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * cresce, height: h * cresce),
        _traco(Cores.superficie.withValues(alpha: a * some), 2.4),
      );
    }

    // --- gotas: uma salva por braçada, do lado que puxou -------------------
    final lado = pose.ciclo < 0.5 ? -1.0 : 1.0;
    final f = (pose.ciclo % 0.5) / 0.5;
    final vida = math.sin(f * math.pi);
    if (vida > 0.05 && amp > 0.3) {
      for (var i = 0; i < 3; i++) {
        final espalha = (i - 1) * 6.0;
        final alto = vida * (11 + i * 3) * amp;
        canvas.drawCircle(
          Offset(cx + lado * (30 + i * 5) + espalha * lado, y - alto),
          1.7 + i * 0.4,
          _p(Cores.superficie.withValues(alpha: vida * 0.7)),
        );
      }
    }

    // --- bolhas subindo do corpo submerso ---------------------------------
    for (var i = 0; i < 3; i++) {
      final b = (pose.ciclo * 0.6 + i * 0.37) % 1.0;
      final r = 1.4 + i * 0.7;
      canvas.drawCircle(
        Offset(
          cx + math.sin(b * math.pi * 2 + i) * (14 + i * 7),
          size.height - 6 - b * (size.height - 6 - y),
        ),
        r,
        _p(Cores.superficie.withValues(alpha: (1 - b) * 0.30)),
      );
    }
  }

  /// A lâmina d'água por cima do corpo — o menisco.
  ///
  /// Só na largura do bicho, e apagando nas pontas. Uma linha atravessando o
  /// quadro inteiro competiria com a lâmina do habitat, que fica a poucos
  /// pixels dali e muda de altura com o cenário; limitada ao corpo, ela lê
  /// como a água encostando **nele**, que é o que precisa ser dito.
  void _lamina(Canvas canvas, Size size, double y) {
    final amp = pose.amplitude;
    final cx = size.width / 2;
    final r = Rect.fromCenter(center: Offset(cx, y), width: 178, height: 10);
    final onda = Path();
    for (var x = r.left; x <= r.right; x += 5) {
      final yy =
          y + math.sin((x - cx) / 21 + pose.ciclo * math.pi * 2) * 2.1 * amp;
      if (x == r.left) {
        onda.moveTo(x, yy);
      } else {
        onda.lineTo(x, yy);
      }
    }
    canvas.drawPath(
      onda,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..shader = const LinearGradient(
          colors: [
            Color(0x00FAF1E3),
            Color(0xCCFAF1E3),
            Color(0xCCFAF1E3),
            Color(0x00FAF1E3),
          ],
          stops: [0, 0.24, 0.76, 1],
        ).createShader(r),
    );
  }

  /// Zzz subindo, cada letra numa fase.
  ///
  /// Preso ao laço do sono, que é longo: no ritmo da boia as letras subiam
  /// depressa demais para quem está dormindo.
  void _zzz(Canvas canvas, Size size) {
    final base = Offset(size.width * 0.70, size.height * 0.30);
    for (var i = 0; i < 3; i++) {
      final f = (pose.ciclo * 3 + i * 0.33) % 1.0;
      final opacidade = (1 - f) * 0.55;
      if (opacidade <= 0.02) continue;
      _letraZ(
        canvas,
        base + Offset(i * 9.0 + f * 5, -f * 22 * pose.amplitude - i * 6.0),
        5.0 + i * 2.0,
        Cores.tintaA(opacidade),
      );
    }
  }

  /// A folha que desceu e pousou nele.
  ///
  /// O Zzz sozinho é o clichê — e é o que já existia. A folha vem do
  /// vocabulário do próprio app: a moeda do Baru é folha, o habitat é
  /// vegetal, e o §10 do roteiro proíbe "poção" exatamente para nada sair da
  /// natureza. Inventar um símbolo novo (uma lua, uma estrela) seria trazer
  /// para dentro algo que o app não tem.
  ///
  /// O detalhe que faz a coisa funcionar não é a queda: é o que acontece
  /// depois. Pousada, ela **sobe e desce com a respiração dele**. É isso que
  /// lê como "dormindo" em vez de "parado de olhos fechados".
  void _folhaDoSono(Canvas canvas, Size size) {
    final amp = pose.amplitude;
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    // Pousa no flanco, e não em cima da cabeça: a 8 px do centro ela caía
    // no focinho de quase toda espécie, o que lê como folha grudada na
    // cara. É também a posição da fase zero, para quem desligou o movimento
    // ver a folha **em cima dele**, e não parada no ar.
    final pouso = Offset(cx - 26, cy + 26);

    // A queda ocupa a última parte do laço; o resto do tempo ela descansa.
    const comeca = 0.62;
    final caindo = pose.ciclo > comeca && amp > 0.3;
    final Offset onde;
    final double giro;
    if (caindo) {
      final t = (pose.ciclo - comeca) / (1 - comeca);
      final partida = Offset(cx + 40, cy - 78);
      onde = Offset(
        // Bamboleia na descida: folha que cai reta é pedra.
        partida.dx +
            (pouso.dx - partida.dx) * t +
            math.sin(t * math.pi * 3) * 9,
        partida.dy + (pouso.dy - partida.dy) * Curves.easeIn.transform(t),
      );
      giro = t * math.pi * 1.6;
    } else {
      onde = pouso + Offset(0, pose.respiro * amp * 1.6);
      giro = -0.5;
    }

    canvas.save();
    canvas.translate(onde.dx, onde.dy);
    canvas.rotate(giro);
    final corpo = Path()
      ..moveTo(-9, 0)
      ..quadraticBezierTo(0, -7, 9, 0)
      ..quadraticBezierTo(0, 7, -9, 0)
      ..close();
    canvas.drawPath(corpo, _p(Cores.primariaClara.withValues(alpha: 0.9)));
    canvas.drawLine(
      const Offset(-8, 0),
      const Offset(8, 0),
      _traco(Cores.primariaEscura.withValues(alpha: 0.55), 1.1),
    );
    canvas.restore();
  }

  void _letraZ(Canvas canvas, Offset o, double s, Color cor) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy)
        ..lineTo(o.dx + s, o.dy)
        ..lineTo(o.dx, o.dy + s)
        ..lineTo(o.dx + s, o.dy + s),
      _traco(cor, 1.8),
    );
  }

  /// Faíscas de alegria: quatro estrelinhas pulsando fora de fase.
  void _brilhos(Canvas canvas, Size size) {
    final fase01 = (pose.respiro + 1) / 2;
    final pontos = [
      (Offset(size.width * 0.26, size.height * 0.22), 5.0, 0.0),
      (Offset(size.width * 0.74, size.height * 0.18), 4.0, 0.35),
      (Offset(size.width * 0.84, size.height * 0.42), 3.2, 0.70),
      (Offset(size.width * 0.17, size.height * 0.44), 3.0, 0.50),
    ];
    for (final (o, s, atraso) in pontos) {
      final f = (fase01 + atraso) % 1.0;
      final pulso = 0.5 + math.sin(f * math.pi * 2) * 0.5;
      final forca = (0.35 + pulso * 0.45 + pose.carinho * 0.3).clamp(0.0, 1.0);
      _estrela(
        canvas,
        o,
        s * (0.7 + pulso * 0.5),
        Cores.acento.withValues(alpha: forca),
      );
    }
  }

  void _estrela(Canvas canvas, Offset o, double s, Color cor) {
    const k = 0.22;
    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - s)
        ..cubicTo(
          o.dx + s * k,
          o.dy - s * k,
          o.dx + s * k,
          o.dy - s * k,
          o.dx + s,
          o.dy,
        )
        ..cubicTo(
          o.dx + s * k,
          o.dy + s * k,
          o.dx + s * k,
          o.dy + s * k,
          o.dx,
          o.dy + s,
        )
        ..cubicTo(
          o.dx - s * k,
          o.dy + s * k,
          o.dx - s * k,
          o.dy + s * k,
          o.dx - s,
          o.dy,
        )
        ..cubicTo(
          o.dx - s * k,
          o.dy - s * k,
          o.dx - s * k,
          o.dy - s * k,
          o.dx,
          o.dy - s,
        )
        ..close(),
      _p(cor),
    );
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) {
    return old.species != species ||
        old.pose.corDaAgua != pose.corDaAgua ||
        old.mood != mood ||
        old.corpoDe != corpoDe ||
        old.corpoPara != corpoPara ||
        old.mistura != mistura ||
        old.activity != activity ||
        old.pose.acao != pose.acao ||
        old.pose.ciclo != pose.ciclo ||
        old.coat != coat ||
        old.coatIndex != coatIndex ||
        old.pose.respiro != pose.respiro ||
        old.pose.boia != pose.boia ||
        old.pose.cauda != pose.cauda ||
        old.pose.pisca != pose.pisca ||
        old.pose.orelha != pose.orelha ||
        old.pose.toque != pose.toque ||
        old.pose.olhar != pose.olhar ||
        old.pose.animado != pose.animado ||
        old.pose.gesto != pose.gesto ||
        old.pose.gestoT != pose.gestoT ||
        old.roupas.length != roupas.length ||
        old.roupaDeCabeca != roupaDeCabeca ||
        old.pose.dedo != pose.dedo ||
        old.pose.gosto != pose.gosto ||
        old.pose.amplitude != pose.amplitude;
  }
}
