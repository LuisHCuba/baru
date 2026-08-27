import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

/// A loja do habitat.
///
/// Antes eram oito objetos numa grade, e comprar era a mesma coisa que
/// colocar: o item caía na cena e ficava lá para sempre. Duas coisas mudaram:
///
/// **Ter deixou de ser o mesmo que usar.** Cada item comprado tem "Colocar" e
/// "Tirar". O habitat é do usuário; ele decide o que fica.
///
/// **Há três naturezas de item.** Objeto de cena (quantos quiser), cenário
/// (um por vez, muda o mundo) e roupa (uma peça por lugar do corpo). Cada
/// seção diz a sua regra — regra escondida vira bug na cabeça de quem usa.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const chaveSaldo = Key('loja-saldo');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(titulo: t.shopT, aoVoltar: app.voltar),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.sm,
              Espaco.margemTela,
              Espaco.xxl,
            ),
            children: [
              _Saldo(app: app),
              const SizedBox(height: Espaco.lg),
              _Secao(
                app: app,
                titulo: t.lojaObjetos,
                subtitulo: t.lojaSubObjetos,
                categoria: CategoriaDeItem.objeto,
              ),
              _Secao(
                app: app,
                titulo: t.lojaRoupas,
                subtitulo: t.lojaSubRoupas,
                categoria: CategoriaDeItem.roupa,
              ),
              _Secao(
                app: app,
                titulo: t.lojaCenarios,
                subtitulo: t.lojaSubCenarios,
                categoria: CategoriaDeItem.cenario,
              ),
              const SizedBox(height: Espaco.md),
              Text(
                t.shopNote,
                style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.45)),
              ),
            ],
          ),
        ),
      ],
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

class _Secao extends StatelessWidget {
  const _Secao({
    required this.app,
    required this.titulo,
    required this.subtitulo,
    required this.categoria,
  });

  final AppState app;
  final String titulo;
  final String subtitulo;
  final CategoriaDeItem categoria;

  @override
  Widget build(BuildContext context) {
    final itens =
        shopItems.where((i) => i.categoria == categoria).toList();
    if (itens.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Espaco.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
          ),
          const SizedBox(height: Espaco.xxs),
          Text(
            subtitulo,
            style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.5)),
          ),
          const SizedBox(height: Espaco.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itens.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: Espaco.sm,
              mainAxisSpacing: Espaco.sm,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) =>
                _Cartao(app: app, item: itens[i]),
          ),
        ],
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.app, required this.item});

  final AppState app;
  final ShopItemDef item;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final tem = app.owned.contains(item.id);
    final emUso = app.estaEquipado(item.id);
    final podeComprar = !tem && app.leaves >= item.price;
    final falta = item.price - app.leaves;

    return Container(
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        color: emUso ? Cores.primariaA(0.10) : Cores.tintaA(0.04),
        borderRadius: Raio.todos(Raio.cartao),
        border: emUso
            ? Border.all(color: Cores.primariaA(0.35), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: _Miniatura(app: app, item: item))),
          const SizedBox(height: Espaco.xs),
          Text(
            _nome(t, item.id),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: estilo(Tipo.corpoForte),
          ),
          const SizedBox(height: Espaco.xs),
          if (!tem)
            _Botao(
              rotulo: podeComprar
                  ? '${item.price}'
                  : t.fill(t.lojaFalta, {'n': falta}),
              icone: podeComprar ? Icons.eco_rounded : Icons.lock_outline,
              ativo: podeComprar,
              cor: Cores.primaria,
              aoTocar: () => app.buy(item),
            )
          else
            _Botao(
              rotulo: emUso ? t.lojaTirar : t.lojaColocar,
              icone: emUso
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              ativo: true,
              cor: emUso ? Cores.tintaA(0.10) : Cores.primaria,
              corTexto: emUso ? Cores.tinta : Cores.superficie,
              aoTocar: () => app.alternaEquipado(item),
            ),
        ],
      ),
    );
  }

  static String _nome(T t, String id) =>
      t.nomeDoItem(id, shopItems.map((e) => e.id).toList());
}

/// A miniatura.
///
/// Cada natureza mostra o que importa: o objeto mostra as peças que vão para
/// a cena, o cenário mostra a luz, a roupa mostra **o bicho vestindo**. Um
/// quadradinho colorido não vende roupa.
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.app, required this.item});

  final AppState app;
  final ShopItemDef item;

  @override
  Widget build(BuildContext context) {
    switch (item.categoria) {
      case CategoriaDeItem.objeto:
        return SizedBox(
          height: 62,
          child: ItemSwatch(item, maxW: 96, maxH: 58),
        );

      case CategoriaDeItem.cenario:
        final cor = item.cor ?? Cores.habitat;
        return Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: Raio.todos(Raio.campo),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cor,
                Color.lerp(cor, Cores.superficie, 0.55)!,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              _icone(item.id),
              size: 24,
              color: Cores.superficie.withValues(alpha: 0.9),
            ),
          ),
        );

      case CategoriaDeItem.roupa:
        return SizedBox(
          height: 74,
          child: PetView(
            species: app.species,
            mood: Mood.content,
            activity: Activity.idle,
            coat: app.color,
            scale: 0.52,
            interativo: false,
            roupas: {item.vestimenta!: item.cor!},
            roupaDeCabeca: item.id,
          ),
        );
    }
  }

  static IconData _icone(String id) => switch (id) {
        'chuva' => Icons.water_drop_outlined,
        'noite_estrelada' => Icons.nights_stay_outlined,
        'neblina' => Icons.foggy,
        _ => Icons.wb_twilight,
      };
}

class _Botao extends StatelessWidget {
  const _Botao({
    required this.rotulo,
    required this.icone,
    required this.ativo,
    required this.cor,
    required this.aoTocar,
    this.corTexto,
  });

  final String rotulo;
  final IconData icone;
  final bool ativo;
  final Color cor;
  final Color? corTexto;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = corTexto ?? (ativo ? Cores.superficie : Cores.tintaA(0.45));
    return Semantics(
      button: true,
      enabled: ativo,
      label: rotulo,
      child: GestureDetector(
        onTap: ativo ? aoTocar : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ativo ? cor : Cores.tintaA(0.06),
            borderRadius: Raio.todos(Raio.pilula),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 15, color: texto),
              const SizedBox(width: Espaco.xxs),
              Flexible(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.rotulo, color: texto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
