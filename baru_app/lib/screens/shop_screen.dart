import 'package:flutter/material.dart';

import '../l10n.dart';
import '../l10n_loja.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/habitat.dart';
import '../widgets/loja_vitrine.dart';

/// A loja do habitat.
///
/// Três coisas a definem, e as três nasceram de um defeito anterior:
///
/// **Ter não é o mesmo que usar.** Cada item comprado tem "Colocar" e
/// "Tirar". O habitat é do usuário; ele decide o que fica.
///
/// **Há três naturezas de item.** Objeto de cena (quantos quiser), cenário
/// (um por vez, muda o mundo) e roupa (uma peça por lugar do corpo). Cada
/// seção diz a sua regra — regra escondida vira bug na cabeça de quem usa.
///
/// **Não é uma grade.** Com oito objetos, dois quadrados por linha eram a
/// loja inteira; com vinte e dois, viram planilha — tudo do mesmo tamanho,
/// tudo com o mesmo peso, nada convidando a nada. Agora há um destaque, os
/// objetos moram em **prateleiras por coleção** que correm para fora da
/// margem, e cada miniatura mostra o item dentro da cena, no lugar onde ele
/// vai ficar. Vitrine, não catálogo de peças.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  static const chaveSaldo = Key('loja-saldo');
  static const chaveFiltros = Key('loja-filtros');
  static const chaveDestaque = Key('loja-destaque');

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

/// O que a pessoa quer ver agora.
///
/// Com dezessete itens dava para rolar tudo; com trinta e um, "o que eu já
/// consigo levar" e "o que já é meu" são as duas perguntas que a rolagem
/// deixou de responder sozinha.
enum _Filtro { tudo, posso, meus }

class _ShopScreenState extends State<ShopScreen> {
  _Filtro _filtro = _Filtro.tudo;

  @override
  Widget build(BuildContext context) {
    // Preguiçoso de propósito: texto de módulo não deve custar nada a quem
    // nunca abre o módulo.
    garanteTextosDaLoja();

    final app = AppScope.of(context);
    final t = app.t;

    // A mesma luz do habitat — inclusive o cenário comprado. A loja vista às
    // 22h, ou com "chuva" em uso, mostra os itens no mundo em que eles vão
    // parar, e não num dia ensolarado que a pessoa talvez nunca veja.
    final luz = LuzDaCena.doCenario(app.cenarioAtivo?.id) ??
        LuzDaCena.de(periodoDe(DateTime.now()));

    final visiveis = shopItems.where((i) => _passa(app, i)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(titulo: t.shopT, aoVoltar: app.voltar),
        Expanded(
          child: ListView(
            // Sem margem lateral na lista: são as prateleiras que precisam
            // sangrar para fora da tela, e cartão cortado pela borda é o que
            // diz "tem mais para o lado" sem escrever isso.
            padding: const EdgeInsets.only(
              top: Espaco.sm,
              bottom: Espaco.xxl,
            ),
            children: [
              _comMargem(_Saldo(app: app)),
              const SizedBox(height: Espaco.md),
              _comMargem(
                _Filtros(
                  key: ShopScreen.chaveFiltros,
                  t: t,
                  atual: _filtro,
                  aoTrocar: (f) => setState(() => _filtro = f),
                ),
              ),
              const SizedBox(height: Espaco.lg),
              if (_filtro == _Filtro.tudo) ...[
                _comMargem(_Destaque(app: app, luz: luz)),
                const SizedBox(height: Espaco.xl),
              ],
              if (visiveis.isEmpty)
                _vazio(app)
              else ...[
                _secaoDeObjetos(app, luz, visiveis),
                _secaoSimples(
                  app: app,
                  luz: luz,
                  visiveis: visiveis,
                  categoria: CategoriaDeItem.roupa,
                  titulo: t.lojaRoupas,
                  subtitulo: t.lojaSubRoupas,
                ),
                _secaoDeCenarios(app, luz, visiveis),
              ],
              const SizedBox(height: Espaco.md),
              _comMargem(
                Text(
                  t.shopNote,
                  style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.45)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// A margem lateral, item a item. Ver o `padding` da lista.
  Widget _comMargem(Widget filho) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.margemTela),
        child: filho,
      );

  bool _passa(AppState app, ShopItemDef item) => switch (_filtro) {
        _Filtro.tudo => true,
        _Filtro.meus => app.owned.contains(item.id),
        _Filtro.posso =>
          !app.owned.contains(item.id) && app.leaves >= item.price,
      };

  Widget _secaoDeObjetos(
    AppState app,
    LuzDaCena luz,
    List<ShopItemDef> visiveis,
  ) {
    final t = app.t;
    final daSecao =
        visiveis.where((i) => i.categoria == CategoriaDeItem.objeto).toList();
    if (daSecao.isEmpty) return const SizedBox.shrink();

    final todos = itensDaCategoria(CategoriaDeItem.objeto);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _comMargem(
          _CabecalhoDeSecao(
            titulo: t.lojaObjetos,
            subtitulo: t.lojaSubObjetos,
            possuidos: todos.where((i) => app.owned.contains(i.id)).length,
            total: todos.length,
          ),
        ),
        const SizedBox(height: Espaco.md),
        for (final colecao in Colecao.values)
          _Prateleira(
            app: app,
            luz: luz,
            titulo: t.nomeDaColecao(colecao),
            subtitulo: t.subtituloDaColecao(colecao),
            itens: itensDaColecao(colecao)
                .where((i) => daSecao.contains(i))
                .toList(),
          ),
        const SizedBox(height: Espaco.sm),
      ],
    );
  }

  /// Seção de uma prateleira só — é o caso das roupas, que não têm coleção.
  Widget _secaoSimples({
    required AppState app,
    required LuzDaCena luz,
    required List<ShopItemDef> visiveis,
    required CategoriaDeItem categoria,
    required String titulo,
    required String subtitulo,
  }) {
    final daSecao = visiveis.where((i) => i.categoria == categoria).toList();
    if (daSecao.isEmpty) return const SizedBox.shrink();
    final todos = itensDaCategoria(categoria);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _comMargem(
          _CabecalhoDeSecao(
            titulo: titulo,
            subtitulo: subtitulo,
            possuidos: todos.where((i) => app.owned.contains(i.id)).length,
            total: todos.length,
          ),
        ),
        const SizedBox(height: Espaco.sm),
        _Prateleira(app: app, luz: luz, itens: daSecao),
        const SizedBox(height: Espaco.sm),
      ],
    );
  }

  /// Cenário não cabe em cartão de prateleira: o que se compra é o mundo
  /// inteiro, e mundo inteiro precisa de largura.
  Widget _secaoDeCenarios(
    AppState app,
    LuzDaCena luz,
    List<ShopItemDef> visiveis,
  ) {
    final t = app.t;
    final daSecao =
        visiveis.where((i) => i.categoria == CategoriaDeItem.cenario).toList();
    if (daSecao.isEmpty) return const SizedBox.shrink();
    final todos = itensDaCategoria(CategoriaDeItem.cenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _comMargem(
          _CabecalhoDeSecao(
            titulo: t.lojaCenarios,
            subtitulo: t.lojaSubCenarios,
            possuidos: todos.where((i) => app.owned.contains(i.id)).length,
            total: todos.length,
          ),
        ),
        const SizedBox(height: Espaco.md),
        for (final item in daSecao)
          Padding(
            padding: const EdgeInsets.only(bottom: Espaco.sm),
            child: _comMargem(
              _CartaoDeCenario(app: app, item: item, luzPadrao: luz),
            ),
          ),
      ],
    );
  }

  Widget _vazio(AppState app) {
    final t = app.t;
    final naoTem = shopItems.where((i) => !app.owned.contains(i.id));
    final maisBarato = naoTem.isEmpty
        ? 0
        : naoTem.map((i) => i.price).reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.xl),
      child: EstadoVazio(
        icone: _filtro == _Filtro.meus
            ? Icons.inventory_2_outlined
            : Icons.eco_outlined,
        titulo:
            _filtro == _Filtro.meus ? t.lojaVazioMeusT : t.lojaVazioPossoT,
        corpo: _filtro == _Filtro.meus
            ? t.lojaVazioMeusB
            : t.fill(t.lojaVazioPossoB, {'n': maisBarato}),
        acao: () => setState(() => _filtro = _Filtro.tudo),
        rotuloAcao: t.lojaVerTudo,
      ),
    );
  }
}

class _Saldo extends StatelessWidget {
  const _Saldo({required this.app});

  final AppState app;

  @override
  Widget build(BuildContext context) {
    return CartaoBaru(
      key: ShopScreen.chaveSaldo,
      cor: Cores.primariaA(0.10),
      elevado: false,
      onTap: () => app.go(AppScreen.folhas),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, size: 24, color: Cores.primaria),
          const SizedBox(width: Espaco.sm),
          ContadorAnimado(
            valor: app.leaves,
            estiloTexto: estilo(
              Tipo.tituloGrande,
              color: Cores.primariaEscura,
              tabular: true,
            ),
          ),
          const Spacer(),
          Text(
            app.t.leavesLbl,
            style: estilo(Tipo.rotulo, color: Cores.primariaEscura),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Cores.primariaEscura,
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({
    super.key,
    required this.t,
    required this.atual,
    required this.aoTrocar,
  });

  final T t;
  final _Filtro atual;
  final ValueChanged<_Filtro> aoTrocar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final f in _Filtro.values) ...[
          SelectChip(
            label: switch (f) {
              _Filtro.tudo => t.lojaFiltroTudo,
              _Filtro.posso => t.lojaFiltroPosso,
              _Filtro.meus => t.lojaFiltroMeus,
            },
            selected: atual == f,
            onTap: () => aoTrocar(f),
            expand: true,
            height: 38,
            size: 13,
          ),
          if (f != _Filtro.values.last) const SizedBox(width: Espaco.xs),
        ],
      ],
    );
  }
}

/// O cartão de cima: um item só, grande, com o caminho até ele.
///
/// Existe porque uma loja que abre com trinta e uma opções não abre com
/// nenhuma. O escolhido é **o mais caro que o saldo já alcança** — é o que
/// transforma folhas guardadas em vontade de gastar; se nada alcança, é o
/// mais barato que falta, que vira a próxima meta.
class _Destaque extends StatelessWidget {
  const _Destaque({required this.app, required this.luz});

  final AppState app;
  final LuzDaCena luz;

  static ShopItemDef? escolhe(AppState app) {
    final faltando =
        shopItems.where((i) => !app.owned.contains(i.id)).toList();
    if (faltando.isEmpty) return null;
    final alcance = faltando.where((i) => i.price <= app.leaves).toList();
    if (alcance.isNotEmpty) {
      alcance.sort((a, b) => b.price.compareTo(a.price));
      return alcance.first;
    }
    faltando.sort((a, b) => a.price.compareTo(b.price));
    return faltando.first;
  }

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final item = escolhe(app);

    if (item == null) {
      return CartaoBaru(
        key: ShopScreen.chaveDestaque,
        cor: Cores.primariaA(0.10),
        elevado: false,
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 22,
              color: Cores.primariaEscura,
            ),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Text(
                t.lojaTudoSeu,
                style: estilo(Tipo.corpoForte, color: Cores.primariaEscura),
              ),
            ),
          ],
        ),
      );
    }

    final podeComprar = app.leaves >= item.price;
    final falta = item.price - app.leaves;

    return CartaoBaru(
      key: ShopScreen.chaveDestaque,
      elevado: true,
      padding: const EdgeInsets.all(Espaco.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 124,
                child: MiniaturaDaLoja(item: item, luz: luz, altura: 92),
              ),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: Espaco.xxs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podeComprar
                            ? t.lojaDestaqueAgora
                            : t.lojaDestaqueProximo,
                        style: estilo(
                          Tipo.rotuloPequeno,
                          color: Cores.primariaEscura,
                        ),
                      ),
                      const SizedBox(height: Espaco.xxs),
                      Text(
                        t.nomeDoItemDaLoja(item.id),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(Tipo.titulo),
                      ),
                      const SizedBox(height: Espaco.xxs),
                      Text(
                        podeComprar
                            ? t.lojaDestaquePronto
                            : t.fill(t.lojaDestaqueFalta, {'n': falta}),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(
                          Tipo.corpoPequeno,
                          color: Cores.tintaA(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.sm),
          // A barra só aparece quando falta — cheia, ela não informa nada.
          if (!podeComprar) ...[
            BarraAnimada(
              fracao: (app.leaves / item.price).clamp(0.0, 1.0),
              cor: Cores.primaria,
              fundo: Cores.primariaA(0.16),
            ),
            const SizedBox(height: Espaco.sm),
          ],
          _AcaoDoItem(app: app, item: item),
        ],
      ),
    );
  }
}

class _CabecalhoDeSecao extends StatelessWidget {
  const _CabecalhoDeSecao({
    required this.titulo,
    required this.subtitulo,
    required this.possuidos,
    required this.total,
  });

  final String titulo;
  final String subtitulo;
  final int possuidos;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: estilo(Tipo.subtitulo)),
              const SizedBox(height: Espaco.xxs),
              Text(
                subtitulo,
                style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.5)),
              ),
            ],
          ),
        ),
        const SizedBox(width: Espaco.sm),
        // Quantos dos quantos: é o que dá à seção a cara de coleção em vez
        // de lista de preços.
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$possuidos/$total',
              style: estilo(
                Tipo.rotulo,
                color: Cores.primariaEscura,
                tabular: true,
              ),
            ),
            const SizedBox(height: Espaco.xxs),
            SizedBox(
              width: 54,
              child: BarraAnimada(
                fracao: total == 0 ? 0 : possuidos / total,
                altura: 4,
                cor: Cores.primaria,
                fundo: Cores.primariaA(0.16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Uma prateleira: corre para o lado e sangra na margem.
class _Prateleira extends StatelessWidget {
  const _Prateleira({
    required this.app,
    required this.luz,
    required this.itens,
    this.titulo,
    this.subtitulo,
  });

  final AppState app;
  final LuzDaCena luz;
  final List<ShopItemDef> itens;
  final String? titulo;
  final String? subtitulo;

  /// Altura da faixa. Fixa porque a lista é horizontal e precisa de altura
  /// própria; os cartões se esticam até ela.
  static const altura = 214.0;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (titulo != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Espaco.margemTela,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(titulo!, style: estilo(Tipo.corpoForte)),
                  if (subtitulo != null) ...[
                    const SizedBox(width: Espaco.xs),
                    Expanded(
                      child: Text(
                        subtitulo!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(
                          Tipo.corpoPequeno,
                          color: Cores.tintaA(0.45),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Espaco.xs),
          ],
          SizedBox(
            height: altura,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: Espaco.margemTela,
              ),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(width: Espaco.sm),
              itemBuilder: (context, i) => _CartaoDeItem(
                app: app,
                item: itens[i],
                luz: luz,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoDeItem extends StatelessWidget {
  const _CartaoDeItem({
    required this.app,
    required this.item,
    required this.luz,
  });

  final AppState app;
  final ShopItemDef item;
  final LuzDaCena luz;

  static const largura = 152.0;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final tem = app.owned.contains(item.id);
    final emUso = app.estaEquipado(item.id);

    return SizedBox(
      width: largura,
      child: Container(
        padding: const EdgeInsets.all(Espaco.xs),
        decoration: BoxDecoration(
          color: emUso
              ? Cores.primariaA(0.10)
              : (tem ? Cores.superficieElevada : Cores.tintaA(0.04)),
          borderRadius: Raio.todos(Raio.cartao),
          border: Border.all(
            color: emUso ? Cores.primariaA(0.45) : Cores.tintaA(0.07),
            width: emUso ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                MiniaturaDaLoja(item: item, luz: luz, altura: 96),
                if (tem)
                  Positioned(
                    left: Espaco.xxs,
                    top: Espaco.xxs,
                    child: SeloDaLoja(
                      texto: emUso ? t.lojaEmUso : t.lojaSeu,
                      icone: emUso
                          ? Icons.check_rounded
                          : Icons.inventory_2_outlined,
                      cor: emUso
                          ? Cores.primaria
                          : Cores.tinta.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Espaco.xs),
            Expanded(
              child: Text(
                t.nomeDoItemDaLoja(item.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: estilo(Tipo.corpoForte),
              ),
            ),
            _AcaoDoItem(app: app, item: item),
          ],
        ),
      ),
    );
  }
}

class _CartaoDeCenario extends StatelessWidget {
  const _CartaoDeCenario({
    required this.app,
    required this.item,
    required this.luzPadrao,
  });

  final AppState app;
  final ShopItemDef item;

  /// A luz de agora. A miniatura de cenário acende com a luz do próprio
  /// cenário e só cai nesta se o habitat não souber acender aquele id.
  final LuzDaCena luzPadrao;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final emUso = app.estaEquipado(item.id);
    final tem = app.owned.contains(item.id);
    final descricao = t.descricaoDoCenario(item.id);

    return Container(
      padding: const EdgeInsets.all(Espaco.sm),
      decoration: BoxDecoration(
        color: emUso
            ? Cores.primariaA(0.10)
            : (tem ? Cores.superficieElevada : Cores.tintaA(0.04)),
        borderRadius: Raio.todos(Raio.cartao),
        border: Border.all(
          color: emUso ? Cores.primariaA(0.45) : Cores.tintaA(0.07),
          width: emUso ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              MiniaturaDaLoja(item: item, luz: luzPadrao, altura: 104),
              if (tem)
                Positioned(
                  left: Espaco.xxs,
                  top: Espaco.xxs,
                  child: SeloDaLoja(
                    texto: emUso ? t.lojaEmUso : t.lojaSeu,
                    icone: emUso
                        ? Icons.check_rounded
                        : Icons.inventory_2_outlined,
                    cor: emUso
                        ? Cores.primaria
                        : Cores.tinta.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Espaco.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.nomeDoItemDaLoja(item.id),
                      style: estilo(Tipo.corpoForte),
                    ),
                    if (descricao.isNotEmpty) ...[
                      const SizedBox(height: Espaco.xxs),
                      Text(
                        descricao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: estilo(
                          Tipo.corpoPequeno,
                          color: Cores.tintaA(0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: Espaco.sm),
              SizedBox(
                width: 116,
                child: _AcaoDoItem(app: app, item: item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// O botão de um item, com os quatro estados possíveis.
///
/// Um lugar só para a regra: o cartão de prateleira, o destaque e o cartão de
/// cenário mostravam a mesma coisa com três aparências ligeiramente
/// diferentes quando cada um tinha o seu botão.
class _AcaoDoItem extends StatelessWidget {
  const _AcaoDoItem({required this.app, required this.item});

  final AppState app;
  final ShopItemDef item;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final tem = app.owned.contains(item.id);
    final emUso = app.estaEquipado(item.id);
    final podeComprar = !tem && app.leaves >= item.price;
    final falta = item.price - app.leaves;

    if (!tem) {
      return PilulaDaLoja(
        rotulo: podeComprar
            ? '${item.price}'
            : t.fill(t.lojaFalta, {'n': falta}),
        icone: podeComprar ? Icons.eco_rounded : Icons.lock_outline,
        ativo: podeComprar,
        cor: Cores.primaria,
        aoTocar: () => app.buy(item),
      );
    }
    return PilulaDaLoja(
      rotulo: emUso ? t.lojaTirar : t.lojaColocar,
      icone: emUso
          ? Icons.check_circle_rounded
          : Icons.add_circle_outline_rounded,
      ativo: true,
      cor: emUso ? Cores.tintaA(0.10) : Cores.primaria,
      corTexto: emUso ? Cores.tinta : Cores.superficie,
      aoTocar: () => app.alternaEquipado(item),
    );
  }
}
