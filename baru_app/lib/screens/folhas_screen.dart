import 'package:flutter/material.dart';

import '../data/carteira.dart';
import '../l10n.dart';
import '../l10n_loja.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/componentes.dart';

/// Suas folhas.
///
/// O saldo era um número no topo da home que ninguém podia tocar. Ele muda
/// sozinho — sessão concluída, marco alcançado, missão resgatada, item
/// comprado — e o usuário tinha de acreditar. Esta tela mostra a origem de
/// cada folha, e é honesta sobre o que o app **não** guardou: compras e marcos
/// não têm data, e o histórico de sessões para nas últimas 80.
class FolhasScreen extends StatelessWidget {
  const FolhasScreen({super.key});

  static const chaveSaldo = Key('folhas-saldo');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final carteira = Carteira(app.toSnapshot());
    final proximo = carteira.proximoItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(
          titulo: t.folhasT,
          subtitulo: t.folhasSub,
          aoVoltar: app.voltar,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Espaco.margemTela,
              Espaco.sm,
              Espaco.margemTela,
              Espaco.xxl,
            ),
            children: [
              _Saldo(app: app, carteira: carteira, proximo: proximo),
              if (carteira.vazia) ...[
                const SizedBox(height: Espaco.xl),
                EstadoVazio(
                  icone: Icons.eco_rounded,
                  titulo: t.folhasVaziaT,
                  corpo: t.folhasVaziaB,
                ),
              ] else ...[
                const SizedBox(height: Espaco.lg),
                _Bloco(
                  titulo: t.folhasDeOnde,
                  filhos: [
                    if (carteira.totalDeSessoes > 0)
                      LinhaDeValor(
                        icone: Icons.self_improvement_rounded,
                        rotulo: t.folhasSessoes,
                        detalhe: '${carteira.ganhosDeSessao.length}',
                        valor: '+${carteira.totalDeSessoes}',
                        cor: Cores.primariaEscura,
                      ),
                    if (carteira.totalDeMarcos > 0)
                      LinhaDeValor(
                        icone: Icons.flag_rounded,
                        rotulo: t.folhasMarcos,
                        detalhe: '${carteira.ganhosDeMarco.length}',
                        valor: '+${carteira.totalDeMarcos}',
                        cor: Cores.primariaEscura,
                      ),
                    if (carteira.totalDeMissoes > 0)
                      LinhaDeValor(
                        icone: Icons.task_alt_rounded,
                        rotulo: t.folhasMissoes,
                        detalhe: '${carteira.ganhosDeMissao.length}',
                        valor: '+${carteira.totalDeMissoes}',
                        cor: Cores.primariaEscura,
                      ),
                  ],
                  nota: carteira.totalDeSessoes > 0 ? t.folhasNota : null,
                ),
                if (carteira.gastos.isNotEmpty) ...[
                  const SizedBox(height: Espaco.md),
                  _Bloco(
                    titulo: t.folhasGasto,
                    filhos: [
                      for (final g in carteira.gastos)
                        LinhaDeValor(
                          icone: Icons.park_rounded,
                          rotulo: _nomeDoItem(t, g.detalhe!),
                          valor: '${g.valor}',
                          cor: Cores.tintaA(0.55),
                        ),
                    ],
                  ),
                ],
                if (carteira.ganhosDeSessao.isNotEmpty) ...[
                  const SizedBox(height: Espaco.md),
                  _Bloco(
                    titulo: t.folhasUltimas,
                    filhos: [
                      for (final l in carteira.ganhosDeSessao.take(8))
                        LinhaDeValor(
                          icone: Icons.eco_rounded,
                          rotulo: t.fill(
                            t.folhasSessaoLinha,
                            {'m': int.parse(l.detalhe!)},
                          ),
                          detalhe: _dia(l.quando!),
                          valor: '+${l.valor}',
                          cor: Cores.primariaEscura,
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _dia(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}';

  /// O nome do item vem do catálogo por **posição**, então o id tem de ser
  /// resolvido para o índice de `shopItems`.
  /// Resolve por id, não por posição.
  ///
  /// A lista posicional tinha os nomes dos 17 itens antigos; com 31 no
  /// catálogo, os novos voltavam como id cru na tela.
  static String _nomeDoItem(T t, String id) => t.nomeDoItemDaLoja(id);
}

class _Saldo extends StatelessWidget {
  const _Saldo({
    required this.app,
    required this.carteira,
    required this.proximo,
  });

  final AppState app;
  final Carteira carteira;
  final ShopItemDef? proximo;

  @override
  Widget build(BuildContext context) {
    final t = app.t;
    final falta = proximo == null ? 0 : (proximo!.price - app.leaves);
    return CartaoBaru(
      key: FolhasScreen.chaveSaldo,
      cor: Cores.primariaA(0.10),
      elevado: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.eco_rounded, size: 30, color: Cores.primaria),
              const SizedBox(width: Espaco.sm),
              ContadorAnimado(
                valor: app.leaves,
                estiloTexto: estilo(
                  Tipo.display,
                  color: Cores.primariaEscura,
                  tabular: true,
                ),
              ),
            ],
          ),
          if (proximo != null) ...[
            const SizedBox(height: Espaco.md),
            BarraAnimada(
              fracao: (app.leaves / proximo!.price).clamp(0.0, 1.0),
              cor: Cores.primaria,
              fundo: Cores.primariaA(0.16),
            ),
            const SizedBox(height: Espaco.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    falta > 0
                        ? t.fill(t.folhasProximo, {
                            'x': falta,
                            'i': FolhasScreen._nomeDoItem(t, proximo!.id),
                          })
                        : t.fill(t.folhasPodeComprar, {
                            'i': FolhasScreen._nomeDoItem(t, proximo!.id),
                          }),
                    style: estilo(
                      Tipo.corpoPequeno,
                      color: Cores.primariaEscura,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => app.go(AppScreen.shop),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.folhasVerLoja,
                          style: estilo(
                            Tipo.rotulo,
                            color: Cores.primariaEscura,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Cores.primariaEscura,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.titulo, required this.filhos, this.nota});

  final String titulo;
  final List<Widget> filhos;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    if (filhos.isEmpty) return const SizedBox.shrink();
    return CartaoBaru(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: estilo(Tipo.rotuloPequeno, color: Cores.tintaA(0.45)),
          ),
          const SizedBox(height: Espaco.xs),
          ...filhos,
          if (nota != null) ...[
            const SizedBox(height: Espaco.xs),
            Text(
              nota!,
              style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.45)),
            ),
          ],
        ],
      ),
    );
  }
}
