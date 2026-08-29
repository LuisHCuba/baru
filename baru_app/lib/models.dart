import 'package:flutter/material.dart';

import 'data/loja_paleta.dart';
import 'theme.dart';

enum AppScreen {
  onb,
  paywall,
  home,
  session,
  result,
  report,
  shop,
  profile,
  tempo,
  trilha,
  missoes,
  folhas,
  sequencia,
  conta,
  sobreposicao,
}

/// As espécies do Baru.
///
/// As quatro primeiras saem do quiz do onboarding; as demais se desbloqueiam
/// na trilha. A ordem importa: é ela que dá a ordem na tela de escolha e a
/// ordem dos nomes no catálogo.
///
/// **`frenchie` e não `frenchBulldog` nem `bulldog`.** O nome do valor vira
/// nome de arquivo de recurso do Android — `ic_frente_${sp.name}.png`, gerado
/// por `test/gera_icone_test.dart` —, e o `aapt` recusa recurso com maiúscula
/// no nome ("file name must contain only lowercase a-z, 0-9, or _"): o build
/// de release quebraria, e só ele. `bulldog` sozinho seria o buldogue inglês,
/// que tem outra silhueta — orelha dobrada, cara mais pesada — e é o desenho
/// errado com o nome certo pela metade.
enum Species {
  capybara,
  otter,
  tortoise,
  owl,
  axolotl,
  penguin,
  cat,
  fox,
  frenchie,
}

enum Mood { radiant, content, neutral, sleepy, missingYou }

enum Activity { idle, nap, swim, graze }

enum WeekDayKind { present, frozen, today, empty }

/// Momento do dia. O habitat às 22h não pode ser igual ao das 9h.
enum PeriodoDoDia { amanhecer, dia, entardecer, noite }

/// Fatias escolhidas para que a cena mude de luz nos horários em que o
/// usuário efetivamente abre o app: de manhã cedo, ao longo do dia, no fim da
/// tarde (quando chega o relatório) e à noite.
PeriodoDoDia periodoDe(DateTime agora) {
  final h = agora.hour;
  if (h >= 5 && h < 9) return PeriodoDoDia.amanhecer;
  if (h >= 9 && h < 17) return PeriodoDoDia.dia;
  if (h >= 17 && h < 20) return PeriodoDoDia.entardecer;
  return PeriodoDoDia.noite;
}

enum PayPlan { annual, monthly }

class LangDef {
  const LangDef(this.id, this.label, this.tag);
  final String id;
  final String label;
  final String tag;
}

const langs = [
  LangDef('pt', 'Português', 'pt-BR'),
  LangDef('en', 'English', 'en'),
  LangDef('es', 'Español', 'es'),
  LangDef('zh', '中文', 'zh-Hans'),
];

const petNames = {
  Species.capybara: 'Baru',
  Species.otter: 'Rio',
  Species.tortoise: 'Toco',
  Species.owl: 'Nina',
  Species.axolotl: 'Lume',
  Species.penguin: 'Nino',
  Species.cat: 'Mel',
  Species.fox: 'Faísca',
  // Bolota: duas sílabas, do mesmo vocabulário vegetal do resto do app
  // (folha, raiz, Lume) e descreve o bicho — compacto e redondo. "Pipoca" e
  // "Brioche" foram descartados por serem piada de raça: o nome padrão é o
  // que a pessoa vê antes de escolher o dela, e ele apresenta o bicho em vez
  // de fazer graça com ele.
  Species.frenchie: 'Bolota',
};

const durations = [25, 50, 90, 45];
const avgOptions = [180, 240, 300, 360];
const goalOptions = [90, 120, 150, 180];

/// Limites da meta quando ela é ajustada à mão.
///
/// Meta de 10 minutos não é meta, é frustração programada; acima de 8 horas
/// ela para de significar alguma coisa.
const metaMinima = 30;
const metaMaxima = 480;
const metaPasso = 15;

/// O sexo do companheiro.
///
/// Não muda o desenho — muda como o app fala dele. Em português e espanhol
/// isso é gramática, não enfeite: "ele te esperou" e "ela te esperou" são
/// frases diferentes, e chamar a bicha de "ele" o tempo todo é o app errando
/// o nome dela.
enum Sexo { naoDito, macho, femea }

/// Segunda = 0 … domingo = 6, igual ao `days` do design.
int weekdayIndex([DateTime? now]) => (now ?? DateTime.now()).weekday - 1;

List<WeekDayKind> freshWeek([DateTime? now]) {
  final today = weekdayIndex(now);
  return List<WeekDayKind>.generate(
    7,
    (i) => i == today ? WeekDayKind.today : WeekDayKind.empty,
  );
}

/// Melhor idioma do Baru para um locale de sistema.
///
/// Usado antes do onboarding, quando o usuário ainda não escolheu: a tela de
/// login não deveria falar português com quem tem o aparelho em chinês.
String langFromLocale(Locale locale) {
  final code = locale.languageCode.toLowerCase();
  for (final l in langs) {
    if (l.id == code) return l.id;
  }
  return 'pt';
}

Locale localeFor(String lang) {
  switch (lang) {
    case 'en':
      return const Locale('en');
    case 'es':
      return const Locale('es');
    case 'zh':
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    default:
      return const Locale('pt');
  }
}

class ShapePart {
  const ShapePart(this.x, this.y, this.w, this.h, this.r, this.c);
  final double x, y, w, h, r;
  final Color c;
}

/// O que se compra na loja.
///
/// Antes havia só objeto de cena, e comprar era a mesma coisa que colocar:
/// o item caía no habitat e ficava lá para sempre. Agora há três naturezas
/// diferentes, e **ter não é o mesmo que estar usando**.
enum CategoriaDeItem {
  /// Móvel do habitat: pedra, ponte, lampião.
  objeto,

  /// Muda a cena inteira — a luz, o céu, a água.
  cenario,

  /// Vai no bicho.
  roupa,
}

/// Onde a roupa fica. Um lugar, uma peça: dois chapéus na mesma cabeça é
/// bug, não estilo.
enum Vestimenta { cabeca, pescoco, rosto }

/// A que canto do mundo o objeto pertence.
///
/// Existe por causa do tamanho: com oito objetos, uma grade era a loja
/// inteira; com vinte e dois, uma grade é uma planilha. A coleção é o que
/// permite a loja ter prateleiras — e é também o que dá **motivo** ao item.
/// "Cogumelos" solto é enfeite; "Cogumelos" na Mata é o que nasce na sombra
/// da árvore que a pessoa já comprou.
///
/// Só objeto de cena tem coleção: roupa e cenário já são a sua própria
/// seção.
enum Colecao {
  /// A água e a margem molhada — o que só existe porque ali tem um lago.
  agua,

  /// O verde de terra firme: mato, tronco, o que cresce e o que apodrece.
  mata,

  /// O que só faz sentido quando escurece. Luz própria, sempre.
  noite,

  /// O tempo passando pela cena: flor, folha caída, neve, nuvem.
  estacoes,
}

class ShopItemDef {
  const ShopItemDef(
    this.id,
    this.price,
    this.parts, {
    this.categoria = CategoriaDeItem.objeto,
    this.vestimenta,
    this.cor,
    this.colecao,
  });

  final String id;
  final int price;

  /// As peças desenhadas no habitat. Vazio para roupa e cenário, que têm
  /// desenho próprio.
  final List<ShapePart> parts;

  final CategoriaDeItem categoria;

  /// Só para [CategoriaDeItem.roupa].
  final Vestimenta? vestimenta;

  /// Cor principal — a roupa e o cenário usam; o objeto já traz nas peças.
  final Color? cor;

  /// A prateleira do objeto na loja. Nula em roupa e cenário.
  final Colecao? colecao;
}

/// O catálogo da loja.
///
/// **A ordem dos dezessete primeiros é intocável.** `l10n.dart` guarda os
/// nomes numa lista indexada por posição (`itemNames`), então trocar dois de
/// lugar renomeia os dois. Item novo entra **no fim da lista** — é por isso
/// que os objetos de cena novos aparecem depois dos cenários aqui embaixo,
/// fora da ordem que a tela mostra. A tela agrupa por categoria e coleção;
/// esta lista é só o registro.
///
/// **A geometria das peças.** Os números são coordenadas na cena de 372×296
/// (`HabitatScene.design`). O que importa saber antes de posicionar um item:
///
/// - a água começa em y≈178 e vai até embaixo;
/// - a margem de areia corre em y≈177 quase toda a largura (y≈188 na ponta
///   esquerda, y≈168 na direita), então objeto de terra apoia a base ali;
/// - o companheiro ocupa o miolo — algo como x 104..268, y 117..240 — e é
///   desenhado **por cima** dos objetos. Item inteiro no meio da tela fica
///   escondido atrás dele; daí os objetos se concentrarem nas laterais, no
///   céu e na água da frente (y > 240).
const shopItems = [
  ShopItemDef('lily', 40, [
    ShapePart(8, 252, 42, 15, 8, AppColors.green),
    ShapePart(54, 266, 28, 11, 6, AppColors.greenSoft),
  ], colecao: Colecao.agua),
  ShopItemDef('bamboo', 70, [
    ShapePart(302, 98, 8, 82, 4, AppColors.green),
    ShapePart(316, 116, 8, 64, 4, AppColors.greenSoft),
    ShapePart(290, 130, 7, 50, 4, AppColors.greenHover),
  ], colecao: Colecao.mata),
  ShopItemDef('rock', 110, [
    ShapePart(252, 254, 66, 30, 15, AppColors.rock),
    ShapePart(268, 244, 34, 16, 9, AppColors.rockLight),
  ], colecao: Colecao.agua),
  ShopItemDef('dock', 150, [
    ShapePart(2, 192, 68, 11, 6, AppColors.wood),
    ShapePart(12, 203, 8, 20, 4, AppColors.woodDark),
    ShapePart(54, 203, 8, 20, 4, AppColors.woodDark),
  ], colecao: Colecao.agua),
  ShopItemDef('lantern', 190, [
    ShapePart(52, 30, 28, 36, 13, AppColors.orange),
    ShapePart(64, 8, 3, 24, 2, Color(0x403E2F23)),
  ], colecao: Colecao.noite),
  ShopItemDef('tree', 240, [
    ShapePart(36, 120, 11, 66, 5, AppColors.woodDark),
    ShapePart(6, 70, 58, 54, 27, AppColors.green),
    ShapePart(34, 92, 10, 10, 5, AppColors.orange),
  ], colecao: Colecao.mata),
  ShopItemDef('boat', 300, [
    ShapePart(288, 208, 62, 18, 9, AppColors.boat),
    ShapePart(317, 180, 4, 30, 2, AppColors.woodDark),
    ShapePart(321, 182, 20, 18, 3, AppColors.cream),
  ], colecao: Colecao.agua),
  ShopItemDef('bridge', 400, [
    ShapePart(100, 250, 138, 13, 7, AppColors.rock),
    ShapePart(108, 260, 10, 24, 5, AppColors.rockDark),
    ShapePart(220, 260, 10, 24, 5, AppColors.rockDark),
  ], colecao: Colecao.agua),

  // --- roupas ------------------------------------------------------------
  // Baratas de propósito: são o que se troca todo dia. Objeto de cena é
  // conquista; roupa é humor.
  ShopItemDef(
    'chapeu_palha',
    60,
    [],
    categoria: CategoriaDeItem.roupa,
    vestimenta: Vestimenta.cabeca,
    cor: Color(0xFFE0BE7A),
  ),
  ShopItemDef(
    'coroa_folhas',
    90,
    [],
    categoria: CategoriaDeItem.roupa,
    vestimenta: Vestimenta.cabeca,
    cor: AppColors.green,
  ),
  ShopItemDef(
    'gorro',
    80,
    [],
    categoria: CategoriaDeItem.roupa,
    vestimenta: Vestimenta.cabeca,
    cor: Color(0xFFD5695A),
  ),
  ShopItemDef(
    'cachecol',
    70,
    [],
    categoria: CategoriaDeItem.roupa,
    vestimenta: Vestimenta.pescoco,
    cor: Color(0xFFC96A86),
  ),
  ShopItemDef(
    'oculos',
    120,
    [],
    categoria: CategoriaDeItem.roupa,
    vestimenta: Vestimenta.rosto,
    cor: Color(0xFF3E2F23),
  ),

  // --- cenários -----------------------------------------------------------
  // Um por vez: cenário é o mundo, e o bicho só mora num.
  ShopItemDef(
    'entardecer',
    200,
    [],
    categoria: CategoriaDeItem.cenario,
    cor: Color(0xFFE8935C),
  ),
  ShopItemDef(
    'noite_estrelada',
    260,
    [],
    categoria: CategoriaDeItem.cenario,
    cor: Color(0xFF3B4A73),
  ),
  ShopItemDef(
    'chuva',
    280,
    [],
    categoria: CategoriaDeItem.cenario,
    cor: Color(0xFF7C93B8),
  ),
  ShopItemDef(
    'neblina',
    220,
    [],
    categoria: CategoriaDeItem.cenario,
    cor: Color(0xFFCBC4B4),
  ),

  // --- objetos de cena, segunda leva --------------------------------------
  //
  // Entram aqui, no fim, e não junto dos outros oito: os nomes do catálogo
  // principal são resolvidos por posição, e inserir no meio renomearia item
  // que a pessoa já comprou. Os nomes destes saem de `l10n_loja.dart`, por
  // id.
  //
  // Cada um tem um lugar próprio na cena e um motivo para existir; o motivo
  // está no comentário, e é o que separa "mais um item" de catálogo inchado.

  /// Junco na beira: o mato que só cresce com o pé na água. É o item barato
  /// que faz a margem deixar de ser uma faixa de areia lisa.
  ShopItemDef('juncos', 90, [
    ShapePart(106, 138, 6, 39, 3, AppColors.green),
    ShapePart(116, 130, 6, 47, 3, AppColors.greenSoft),
    ShapePart(126, 146, 6, 31, 3, AppColors.greenHover),
    ShapePart(113, 122, 9, 15, 4, AppColors.woodDark),
  ], colecao: Colecao.agua),

  /// O que nasce na sombra. Combina de propósito com a árvore antiga — item
  /// que conversa com outro item vale mais que item solto.
  ShopItemDef('cogumelos', 100, [
    ShapePart(55, 173, 6, 9, 3, CoresDaLoja.cogumeloTalo),
    ShapePart(48, 166, 18, 9, 4.5, CoresDaLoja.cogumelo),
    ShapePart(66, 176, 5, 6, 2.5, CoresDaLoja.cogumeloTalo),
    ShapePart(62, 172, 12, 6, 3, CoresDaLoja.cogumelo),
  ], colecao: Colecao.mata),

  /// Samambaia: três frondes em alturas diferentes. Verde de sombra, mais
  /// escuro que o do bambu, senão a margem esquerda vira uma cor só.
  ShopItemDef('samambaia', 120, [
    ShapePart(64, 158, 34, 12, 6, AppColors.greenSoft),
    ShapePart(72, 148, 28, 11, 5, AppColors.green),
    ShapePart(60, 166, 42, 11, 5, AppColors.greenHover),
  ], colecao: Colecao.mata),

  /// Folhas boiando. O outono do app: a cena não tem árvore que perca folha
  /// sozinha, então a estação é uma coisa que se compra.
  ShopItemDef('folhas_de_outono', 130, [
    ShapePart(18, 232, 15, 8, 4, CoresDaLoja.outono),
    ShapePart(44, 244, 13, 7, 3.5, AppColors.orangeText),
    ShapePart(52, 224, 14, 8, 4, CoresDaLoja.outono),
    ShapePart(88, 248, 11, 6, 3, AppColors.orangeText),
  ], colecao: Colecao.estacoes),

  /// Pedras empilhadas na água rasa: o marco de quem passou por ali. Três
  /// tamanhos decrescentes — é o que faz uma pilha parecer equilíbrio e não
  /// entulho.
  ShopItemDef('pedras_do_riacho', 140, [
    ShapePart(74, 232, 34, 13, 6, AppColors.rock),
    ShapePart(79, 222, 24, 11, 5, AppColors.rockLight),
    ShapePart(84, 213, 15, 9, 4, AppColors.rockDark),
  ], colecao: Colecao.agua),

  /// Cardume. Vive na água da frente, abaixo do companheiro, onde não havia
  /// nada — e é a única coisa da loja que sugere que o lago tem fundo.
  ShopItemDef('cardume', 160, [
    ShapePart(324, 252, 8, 5, 2.5, CoresDaLoja.peixe),
    ShapePart(330, 250, 22, 9, 4.5, CoresDaLoja.peixe),
    ShapePart(341, 266, 7, 4, 2, CoresDaLoja.peixeClaro),
    ShapePart(346, 264, 18, 8, 4, CoresDaLoja.peixeClaro),
    ShapePart(326, 274, 15, 7, 3.5, CoresDaLoja.peixe),
  ], colecao: Colecao.agua),

  /// Nuvens. O céu do habitat é um gradiente limpo o dia inteiro; três
  /// nuvens mudam o dia sem mexer na luz.
  ShopItemDef('nuvens', 170, [
    ShapePart(150, 44, 54, 20, 10, CoresDaLoja.nuvem),
    ShapePart(176, 34, 44, 18, 9, CoresDaLoja.nuvemClara),
    ShapePart(214, 50, 40, 16, 8, CoresDaLoja.nuvem),
  ], colecao: Colecao.estacoes),

  /// Tronco caído, deitado na margem direita. A faixa clara em cima é o que
  /// faz um retângulo deitado parecer cilíndrico; sem ela é uma tábua.
  ShopItemDef('tronco_caido', 180, [
    ShapePart(262, 162, 80, 14, 7, AppColors.wood),
    ShapePart(268, 159, 66, 5, 2.5, CoresDaLoja.madeiraClara),
    ShapePart(252, 164, 12, 11, 5, AppColors.woodDark),
  ], colecao: Colecao.mata),

  /// Casa de passarinho num poste. Dá altura à margem direita, que é toda
  /// rasteira, e sugere um bicho que a cena nunca desenha.
  ShopItemDef('casa_de_passaro', 210, [
    ShapePart(280, 140, 7, 36, 3, AppColors.woodDark),
    ShapePart(268, 118, 30, 26, 8, AppColors.wood),
    ShapePart(264, 111, 38, 10, 5, CoresDaLoja.madeiraClara),
    ShapePart(279, 126, 9, 9, 4.5, AppColors.woodDark),
  ], colecao: Colecao.mata),

  /// Vaga-lumes no ar, acima da cabeça do companheiro para não sumirem atrás
  /// dele. Com o cenário de noite estrelada é o item que mais muda a cena
  /// por folha gasta.
  ShopItemDef('vagalumes', 220, [
    ShapePart(88, 72, 7, 7, 3.5, CoresDaLoja.vagalume),
    ShapePart(140, 52, 6, 6, 3, CoresDaLoja.vagalumeForte),
    ShapePart(196, 80, 7, 7, 3.5, CoresDaLoja.vagalume),
    ShapePart(248, 58, 6, 6, 3, CoresDaLoja.vagalumeForte),
    ShapePart(286, 88, 5, 5, 2.5, CoresDaLoja.vagalume),
  ], colecao: Colecao.noite),

  /// Neve no ar. Espalhada em oito flocos de três tamanhos: floco do mesmo
  /// tamanho em grade vira poeira na tela, não neve.
  ShopItemDef('neve', 230, [
    ShapePart(44, 60, 7, 7, 3.5, CoresDaLoja.neve),
    ShapePart(96, 96, 6, 6, 3, CoresDaLoja.neve),
    ShapePart(150, 48, 7, 7, 3.5, CoresDaLoja.neve),
    ShapePart(206, 104, 6, 6, 3, CoresDaLoja.neve),
    ShapePart(262, 66, 7, 7, 3.5, CoresDaLoja.neve),
    ShapePart(312, 108, 6, 6, 3, CoresDaLoja.neve),
    ShapePart(128, 78, 5, 5, 2.5, CoresDaLoja.neve),
    ShapePart(232, 92, 5, 5, 2.5, CoresDaLoja.neve),
  ], colecao: Colecao.estacoes),

  /// Varal de luzes atravessando o céu. O fio é translúcido de propósito —
  /// fio opaco no céu vira risco de caneta.
  ShopItemDef('varal_de_luzes', 260, [
    ShapePart(88, 16, 198, 3, 1.5, CoresDaLoja.fioDeVaral),
    ShapePart(104, 19, 10, 10, 5, CoresDaLoja.lampada),
    ShapePart(144, 25, 10, 10, 5, AppColors.orange),
    ShapePart(188, 21, 10, 10, 5, CoresDaLoja.lampada),
    ShapePart(232, 27, 10, 10, 5, AppColors.orange),
    ShapePart(270, 19, 10, 10, 5, CoresDaLoja.lampada),
  ], colecao: Colecao.noite),

  /// Fogueira na margem esquerda, sob a árvore. A ponta clara sai por cima
  /// da chama: é o que dá a impressão de fogo aceso em vez de mancha
  /// laranja.
  ShopItemDef('fogueira', 280, [
    ShapePart(4, 168, 34, 9, 4, AppColors.woodDark),
    ShapePart(10, 164, 22, 7, 3.5, AppColors.wood),
    ShapePart(13, 144, 16, 22, 8, AppColors.orange),
    ShapePart(17, 148, 8, 12, 4, CoresDaLoja.brasa),
    ShapePart(22, 134, 4, 4, 2, CoresDaLoja.brasa),
  ], colecao: Colecao.noite),

  /// Cerejeira na margem direita, a copa passando por cima da colina. É o
  /// item mais caro dos objetos novos porque é o que muda a silhueta da cena
  /// inteira — a primavera do app.
  ShopItemDef('cerejeira', 340, [
    ShapePart(340, 136, 9, 38, 4, AppColors.woodDark),
    ShapePart(322, 104, 50, 30, 15, CoresDaLoja.cerejaClara),
    ShapePart(330, 94, 38, 24, 12, CoresDaLoja.cereja),
    ShapePart(326, 142, 6, 6, 3, CoresDaLoja.cereja),
    ShapePart(356, 150, 5, 5, 2.5, CoresDaLoja.cerejaClara),
  ], colecao: Colecao.estacoes),
];

/// Os objetos que moram no habitat, na ordem da loja.
List<ShopItemDef> get itensDeCena =>
    shopItems.where((i) => i.categoria == CategoriaDeItem.objeto).toList();

/// Os itens de uma categoria, na ordem do catálogo.
List<ShopItemDef> itensDaCategoria(CategoriaDeItem c) =>
    shopItems.where((i) => i.categoria == c).toList();

/// Os objetos de uma prateleira, do mais barato ao mais caro.
///
/// Ordenado por preço e não pela ordem do catálogo porque a ordem do
/// catálogo é ordem de chegada — os itens novos entraram todos no fim da
/// lista. Numa prateleira, o barato primeiro é o que deixa a pessoa ver o
/// que ela já alcança antes de ver o que ela não alcança.
List<ShopItemDef> itensDaColecao(Colecao c) =>
    shopItems.where((i) => i.colecao == c).toList()
      ..sort((a, b) => a.price.compareTo(b.price));

ShopItemDef? itemPorId(String id) {
  for (final i in shopItems) {
    if (i.id == id) return i;
  }
  return null;
}

/// Pesos do quiz (3 perguntas × 4 opções), iguais ao design.
const quizWeights = [
  [
    {Species.capybara: 2},
    {Species.otter: 2},
    {Species.tortoise: 2},
    {Species.owl: 2},
  ],
  [
    {Species.tortoise: 1},
    {Species.otter: 1},
    {Species.owl: 2},
    {Species.capybara: 1},
  ],
  [
    {Species.capybara: 2},
    {Species.otter: 1},
    {Species.owl: 1},
    {Species.tortoise: 2},
  ],
];

String fmtMinutes(int min, String lang) {
  final h = min ~/ 60;
  final m = min % 60;
  if (lang == 'zh') {
    if (h == 0) return '$m分';
    return m == 0 ? '$h小时' : '$h小时$m分';
  }
  final u = lang == 'en' ? 'm' : 'min';
  if (h == 0) return '$m$u';
  return m == 0 ? '${h}h' : '${h}h $m$u';
}

int sessionReward(int dur) {
  if (dur == 25) return 10;
  if (dur == 50) return 25;
  if (dur == 90) return 50;
  return (dur * 0.5).floor();
}

int suggestedGoal(int avg) => metaSugerida(avg, 0.75);

/// A meta sugerida a partir da média, com o aperto que a intenção pede.
///
/// O 0,75 fixo tratava quem quer largar a tela igual a quem veio pela
/// companhia. Ver `fatorDaMeta` em `data/quiz.dart`.
int metaSugerida(int avg, double fator) {
  final bruto = ((avg * fator) / 15).round() * 15;
  return bruto.clamp(metaMinima, metaMaxima);
}
