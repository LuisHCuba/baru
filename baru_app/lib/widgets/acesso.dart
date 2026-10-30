import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../cobranca.dart';
import '../l10n.dart';
import '../theme.dart';
import 'componentes.dart';

/// Quanto tempo de graça ainda há, e por onde se assina.
///
/// O app sabia disso e não dizia: `acessoLiberado()` devolvia um booleano e
/// jogava o prazo fora, e o cartão de plano em "Sua conta" estava atrás de
/// `cobrancaNaLoja`, que é `false`. Resultado: ninguém via a contagem, e a
/// primeira notícia do fim do teste era a tela neutra.
///
/// O prazo mostrado é **o do servidor** (`baru_meu_acesso`), nunca uma conta
/// de relógio local: data de aparelho se muda nos ajustes.

/// Abre a página inicial do site. Não é um checkout: é a porta de entrada.
Future<void> abreOSite() => launchUrl(
  Uri.parse(siteDoBaru),
  mode: LaunchMode.externalApplication,
);

/// Cartão de "Sua conta": estado do acesso em uma linha, com o caminho do site.
class CartaoDoAcesso extends StatelessWidget {
  const CartaoDoAcesso({super.key, required this.t, this.aoAbrirSite});

  static const chave = Key('acesso-cartao');

  final T t;
  final VoidCallback? aoAbrirSite;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MeuAcesso?>(
    valueListenable: acessoAtual,
    builder: (context, acesso, _) {
      // Sem resposta do servidor ainda, ou cobrança não ligada: não há prazo
      // nenhum para anunciar, e inventar um seria mentir.
      if (acesso == null) return const SizedBox.shrink();

      final String titulo;
      final String corpo;
      if (acesso.pagando) {
        titulo = t.acessoPagoT;
        corpo = t.fill(t.acessoPagoB, {'d': t.formatLongDate(acesso.pagoAte)});
      } else if (acesso.noTeste) {
        final dias = acesso.diasDeTeste();
        titulo = dias <= 0
            ? t.acessoTesteHojeT
            : t.fill(t.acessoTesteT, {'n': dias});
        corpo = t.fill(t.acessoTesteB, {
          'd': t.formatLongDate(acesso.testeAte),
        });
      } else if (!acesso.liberado) {
        titulo = t.testeFimT;
        corpo = t.acessoSemB;
      } else {
        return const SizedBox.shrink();
      }

      return CartaoBaru(
        key: chave,
        cor: Cores.primariaA(0.10),
        elevado: false,
        onTap: aoAbrirSite ?? abreOSite,
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              size: 20,
              color: Cores.primariaEscura,
            ),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: estilo(Tipo.subtitulo)),
                  Text(
                    corpo,
                    style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.acessoSite,
                    style: estilo(
                      Tipo.corpoPequeno,
                      color: Cores.primariaEscura,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Cores.primariaEscura,
            ),
          ],
        ),
      );
    },
  );
}

/// Faixa discreta na home, só na reta final do teste.
///
/// Aparece a partir de três dias para o fim: antes disso é ruído diário, e no
/// dia seguinte ao vencimento já não é a home que a pessoa vê.
class FaixaDoTeste extends StatelessWidget {
  const FaixaDoTeste({super.key, required this.t, this.aoAbrirSite});

  static const chave = Key('acesso-faixa');
  static const diasParaAvisar = 3;

  final T t;
  final VoidCallback? aoAbrirSite;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MeuAcesso?>(
    valueListenable: acessoAtual,
    builder: (context, acesso, _) {
      if (acesso == null || !acesso.noTeste) return const SizedBox.shrink();
      final dias = acesso.diasDeTeste();
      if (dias > diasParaAvisar) return const SizedBox.shrink();

      return Padding(
        key: chave,
        padding: const EdgeInsets.only(bottom: Espaco.sm),
        child: GestureDetector(
          onTap: aoAbrirSite ?? abreOSite,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Espaco.md,
              vertical: Espaco.sm,
            ),
            decoration: BoxDecoration(
              color: Cores.primariaA(0.12),
              borderRadius: BorderRadius.circular(Raio.chip),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 16,
                  color: Cores.primariaEscura,
                ),
                const SizedBox(width: Espaco.sm),
                Expanded(
                  child: Text(
                    dias <= 0
                        ? t.acessoFaixaHoje
                        : t.fill(t.acessoFaixa, {'n': dias}),
                    style: estilo(
                      Tipo.corpoPequeno,
                      color: Cores.primariaEscura,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Cores.primariaEscura,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
