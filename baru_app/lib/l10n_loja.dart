import 'l10n.dart';
import 'models.dart';

/// Os textos da loja.
///
/// Ficam aqui, e não em `lib/l10n.dart`, por dois motivos:
///
/// **Colisão.** `l10n.dart` tem quatro mapas gigantes e é onde qualquer
/// trabalho em paralelo bate de frente. `T.registra` existe para isto.
///
/// **O nome do item por id.** O catálogo principal guarda os nomes numa
/// lista indexada pela posição em `shopItems` — já foi `RangeError` uma vez,
/// quando a loja passou de oito para dezessete itens e a lista de nomes
/// ficou para trás. Os itens novos resolvem o nome por id (`lojaItem_<id>`),
/// que não tem posição para errar. Os dezessete antigos continuam saindo do
/// catálogo principal, onde já estavam traduzidos: duplicar tradução é a
/// forma mais barata de as duas versões divergirem.
const textosDaLoja = <String, Map<String, String>>{
  'pt': {
    // --- nomes dos objetos novos, por id ---
    'lojaItem_juncos': 'Juncos da margem',
    'lojaItem_cogumelos': 'Cogumelos',
    'lojaItem_samambaia': 'Samambaia',
    'lojaItem_folhas_de_outono': 'Folhas de outono',
    'lojaItem_pedras_do_riacho': 'Pedras do riacho',
    'lojaItem_cardume': 'Cardume',
    'lojaItem_nuvens': 'Nuvens',
    'lojaItem_tronco_caido': 'Tronco caído',
    'lojaItem_casa_de_passaro': 'Casa de passarinho',
    'lojaItem_vagalumes': 'Vaga-lumes',
    'lojaItem_neve': 'Neve',
    'lojaItem_varal_de_luzes': 'Varal de luzes',
    'lojaItem_fogueira': 'Fogueira',
    'lojaItem_cerejeira': 'Cerejeira',
    // --- prateleiras ---
    'lojaColecao_agua': "Beira d'água",
    'lojaColecaoSub_agua': 'O que só existe porque ali tem um lago.',
    'lojaColecao_mata': 'Mata',
    'lojaColecaoSub_mata': 'O verde de terra firme: o que cresce e o que cai.',
    'lojaColecao_noite': 'Noite',
    'lojaColecaoSub_noite': 'Luz própria. Fica melhor com o céu escuro.',
    'lojaColecao_estacoes': 'Estações',
    'lojaColecaoSub_estacoes': 'O tempo passando pela cena.',
    // --- o que cada cenário faz com o mundo ---
    'lojaCenario_entardecer': 'A luz de fim de tarde, a qualquer hora.',
    'lojaCenario_noite_estrelada': 'Céu índigo e lua, mesmo às duas da tarde.',
    'lojaCenario_chuva':
        'Cinza-azulado e água parada. O dia lá fora não importa.',
    'lojaCenario_neblina': 'Tudo mais claro e mais macio, como manhã cedo.',
    // --- vitrine ---
    'lojaFiltroTudo': 'Tudo',
    'lojaFiltroPosso': 'Dá para levar',
    'lojaFiltroMeus': 'Meus itens',
    'lojaSeu': 'Seu',
    'lojaProgresso': '{n}/{t}',
    'lojaDestaqueAgora': 'DÁ PARA LEVAR AGORA',
    'lojaDestaqueProximo': 'O PRÓXIMO',
    'lojaDestaqueFalta': 'Faltam {n} folhas.',
    'lojaDestaquePronto': 'Você já tem as folhas deste.',
    'lojaTudoSeu': 'Tudo o que existe aqui já é seu.',
    'lojaVazioMeusT': 'Nada seu por aqui ainda',
    'lojaVazioMeusB': 'Cada sessão de foco rende folhas. Volte com elas.',
    'lojaVazioPossoT': 'Nada ao seu alcance ainda',
    'lojaVazioPossoB': 'O mais barato daqui custa {n} folhas.',
    'lojaVerTudo': 'Ver a loja inteira',
  },
  'en': {
    'lojaItem_juncos': 'Shore reeds',
    'lojaItem_cogumelos': 'Mushrooms',
    'lojaItem_samambaia': 'Fern',
    'lojaItem_folhas_de_outono': 'Autumn leaves',
    'lojaItem_pedras_do_riacho': 'Creek stones',
    'lojaItem_cardume': 'School of fish',
    'lojaItem_nuvens': 'Clouds',
    'lojaItem_tronco_caido': 'Fallen log',
    'lojaItem_casa_de_passaro': 'Birdhouse',
    'lojaItem_vagalumes': 'Fireflies',
    'lojaItem_neve': 'Snowfall',
    'lojaItem_varal_de_luzes': 'String lights',
    'lojaItem_fogueira': 'Campfire',
    'lojaItem_cerejeira': 'Cherry tree',
    'lojaColecao_agua': 'Waterside',
    'lojaColecaoSub_agua': "Only there because there's a lake.",
    'lojaColecao_mata': 'Woods',
    'lojaColecaoSub_mata': 'Dry-land green: what grows and what falls.',
    'lojaColecao_noite': 'Night',
    'lojaColecaoSub_noite': 'Light of their own. Better under a dark sky.',
    'lojaColecao_estacoes': 'Seasons',
    'lojaColecaoSub_estacoes': 'Time passing through the scene.',
    'lojaCenario_entardecer': 'Late afternoon light, at any hour.',
    'lojaCenario_noite_estrelada': 'Indigo sky and moon, even at 2pm.',
    'lojaCenario_chuva':
        'Blue-grey and still water. Never mind the day outside.',
    'lojaCenario_neblina': 'Everything paler and softer, like early morning.',
    'lojaFiltroTudo': 'All',
    'lojaFiltroPosso': 'Within reach',
    'lojaFiltroMeus': 'Yours',
    'lojaSeu': 'Yours',
    'lojaProgresso': '{n}/{t}',
    'lojaDestaqueAgora': 'WITHIN REACH',
    'lojaDestaqueProximo': 'UP NEXT',
    'lojaDestaqueFalta': '{n} leaves to go.',
    'lojaDestaquePronto': 'You already have the leaves for this one.',
    'lojaTudoSeu': 'Everything here is already yours.',
    'lojaVazioMeusT': 'Nothing of yours here yet',
    'lojaVazioMeusB': 'Every focus session earns leaves. Come back with them.',
    'lojaVazioPossoT': 'Nothing within reach yet',
    'lojaVazioPossoB': 'The cheapest one here costs {n} leaves.',
    'lojaVerTudo': 'See the whole shop',
  },
  'es': {
    'lojaItem_juncos': 'Juncos de la orilla',
    'lojaItem_cogumelos': 'Setas',
    'lojaItem_samambaia': 'Helecho',
    'lojaItem_folhas_de_outono': 'Hojas de otoño',
    'lojaItem_pedras_do_riacho': 'Piedras del arroyo',
    'lojaItem_cardume': 'Banco de peces',
    'lojaItem_nuvens': 'Nubes',
    'lojaItem_tronco_caido': 'Tronco caído',
    'lojaItem_casa_de_passaro': 'Casita de pájaros',
    'lojaItem_vagalumes': 'Luciérnagas',
    'lojaItem_neve': 'Nieve',
    'lojaItem_varal_de_luzes': 'Guirnalda de luces',
    'lojaItem_fogueira': 'Fogata',
    'lojaItem_cerejeira': 'Cerezo',
    'lojaColecao_agua': 'La orilla',
    'lojaColecaoSub_agua': 'Solo existe porque ahí hay un lago.',
    'lojaColecao_mata': 'El monte',
    'lojaColecaoSub_mata':
        'El verde de tierra firme: lo que crece y lo que cae.',
    'lojaColecao_noite': 'Noche',
    'lojaColecaoSub_noite': 'Luz propia. Mejor con el cielo oscuro.',
    'lojaColecao_estacoes': 'Estaciones',
    'lojaColecaoSub_estacoes': 'El tiempo pasando por la escena.',
    'lojaCenario_entardecer': 'La luz del atardecer, a cualquier hora.',
    'lojaCenario_noite_estrelada':
        'Cielo índigo y luna, aun a las dos de la tarde.',
    'lojaCenario_chuva':
        'Gris azulado y agua quieta. No importa el día de afuera.',
    'lojaCenario_neblina': 'Todo más claro y más suave, como temprano.',
    'lojaFiltroTudo': 'Todo',
    'lojaFiltroPosso': 'A tu alcance',
    'lojaFiltroMeus': 'Tuyos',
    'lojaSeu': 'Tuyo',
    'lojaProgresso': '{n}/{t}',
    'lojaDestaqueAgora': 'A TU ALCANCE',
    'lojaDestaqueProximo': 'EL SIGUIENTE',
    'lojaDestaqueFalta': 'Faltan {n} hojas.',
    'lojaDestaquePronto': 'Ya tienes las hojas de este.',
    'lojaTudoSeu': 'Todo lo que hay aquí ya es tuyo.',
    'lojaVazioMeusT': 'Todavía no tienes nada',
    'lojaVazioMeusB': 'Cada sesión de foco da hojas. Vuelve con ellas.',
    'lojaVazioPossoT': 'Nada a tu alcance todavía',
    'lojaVazioPossoB': 'Lo más barato de aquí cuesta {n} hojas.',
    'lojaVerTudo': 'Ver toda la tienda',
  },
  'zh': {
    'lojaItem_juncos': '岸边芦苇',
    'lojaItem_cogumelos': '蘑菇',
    'lojaItem_samambaia': '蕨叶',
    'lojaItem_folhas_de_outono': '秋叶',
    'lojaItem_pedras_do_riacho': '溪石',
    'lojaItem_cardume': '鱼群',
    'lojaItem_nuvens': '云',
    'lojaItem_tronco_caido': '倒木',
    'lojaItem_casa_de_passaro': '鸟屋',
    'lojaItem_vagalumes': '萤火虫',
    'lojaItem_neve': '落雪',
    'lojaItem_varal_de_luzes': '灯串',
    'lojaItem_fogueira': '篝火',
    'lojaItem_cerejeira': '樱花树',
    'lojaColecao_agua': '水边',
    'lojaColecaoSub_agua': '因为有湖，才有这些。',
    'lojaColecao_mata': '林间',
    'lojaColecaoSub_mata': '陆地上的绿意：生长的，和落下的。',
    'lojaColecao_noite': '夜晚',
    'lojaColecaoSub_noite': '自带光亮，夜空下更好看。',
    'lojaColecao_estacoes': '四季',
    'lojaColecaoSub_estacoes': '时间从场景里走过。',
    'lojaCenario_entardecer': '任何时候都是黄昏的光。',
    'lojaCenario_noite_estrelada': '靛蓝的天和月亮，哪怕是下午两点。',
    'lojaCenario_chuva': '灰蓝与静水，外面是什么天气都不要紧。',
    'lojaCenario_neblina': '一切更淡、更柔，像清晨。',
    'lojaFiltroTudo': '全部',
    'lojaFiltroPosso': '买得起',
    'lojaFiltroMeus': '已拥有',
    'lojaSeu': '已有',
    'lojaProgresso': '{n}/{t}',
    'lojaDestaqueAgora': '现在就能带走',
    'lojaDestaqueProximo': '下一个',
    'lojaDestaqueFalta': '还差 {n} 片叶子。',
    'lojaDestaquePronto': '你的叶子已经够买它了。',
    'lojaTudoSeu': '这里的一切都已经是你的了。',
    'lojaVazioMeusT': '这里还没有你的东西',
    'lojaVazioMeusB': '每次专注都会长出叶子，带着它们回来。',
    'lojaVazioPossoT': '还没有买得起的',
    'lojaVazioPossoB': '这里最便宜的要 {n} 片叶子。',
    'lojaVerTudo': '查看整个商店',
  },
};

/// Registra o catálogo. Idempotente — `T.registra` ignora o mapa repetido.
///
/// Chamada no `build` da loja, e não num `main()` qualquer, porque texto de
/// módulo não deve custar nada a quem nunca abre o módulo.
void garanteTextosDaLoja() => T.registra(textosDaLoja);

/// Os acessos, como getters.
///
/// `t.s('chave')` funcionaria, mas erro de digitação só apareceria na tela da
/// pessoa — e chave faltando volta como a própria chave, que é o pior tipo de
/// defeito: o que não quebra a tela, só a enfeia.
extension TextosDaLoja on T {
  String get lojaFiltroTudo => s('lojaFiltroTudo');
  String get lojaFiltroPosso => s('lojaFiltroPosso');
  String get lojaFiltroMeus => s('lojaFiltroMeus');
  String get lojaSeu => s('lojaSeu');
  String get lojaProgresso => s('lojaProgresso');
  String get lojaDestaqueAgora => s('lojaDestaqueAgora');
  String get lojaDestaqueProximo => s('lojaDestaqueProximo');
  String get lojaDestaqueFalta => s('lojaDestaqueFalta');
  String get lojaDestaquePronto => s('lojaDestaquePronto');
  String get lojaTudoSeu => s('lojaTudoSeu');
  String get lojaVazioMeusT => s('lojaVazioMeusT');
  String get lojaVazioMeusB => s('lojaVazioMeusB');
  String get lojaVazioPossoT => s('lojaVazioPossoT');
  String get lojaVazioPossoB => s('lojaVazioPossoB');
  String get lojaVerTudo => s('lojaVerTudo');

  /// O nome do item, por id.
  ///
  /// Tenta primeiro o catálogo da loja; se o id não estiver lá, cai no
  /// catálogo principal, que resolve **por posição** e cobre os dezessete
  /// primeiros. A ordem é essa e não a inversa porque a posicional é a que
  /// erra: ela devolve o id cru para qualquer item fora da faixa, e id cru é
  /// um nome que passa no `isNotEmpty` e reprova aos olhos.
  String nomeDoItemDaLoja(String id) {
    const prefixo = 'lojaItem_';
    final achado = s('$prefixo$id');
    if (achado != '$prefixo$id') return achado;
    return nomeDoItem(id, shopItems.map((e) => e.id).toList());
  }

  /// A linha que diz o que o cenário faz com o mundo. Vazia quando não há —
  /// aí o cartão simplesmente não mostra linha nenhuma.
  String descricaoDoCenario(String id) {
    const prefixo = 'lojaCenario_';
    final achado = s('$prefixo$id');
    return achado == '$prefixo$id' ? '' : achado;
  }

  String nomeDaColecao(Colecao c) => s('lojaColecao_${c.name}');
  String subtituloDaColecao(Colecao c) => s('lojaColecaoSub_${c.name}');
}
