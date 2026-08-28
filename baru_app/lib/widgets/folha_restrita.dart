import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n.dart';
import '../theme.dart';
import 'common.dart';

/// O passo a passo para destravar a permissão de uso.
///
/// A partir do Android 13, uma permissão sensível como
/// `PACKAGE_USAGE_STATS` fica bloqueada quando o app foi instalado **por
/// arquivo**, fora de uma loja. O sistema mostra o aviso sobre dados
/// pessoais e financeiros e simplesmente não deixa ligar a chave — nenhuma
/// tentativa do app resolve, porque o bloqueio é do sistema e depende de um
/// gesto que só a pessoa pode fazer.
///
/// O aviso antigo ("ative nas configurações do sistema") mandava a pessoa
/// exatamente para a tela onde o botão está travado. Aqui estão os quatro
/// toques que destravam, e um atalho para a tela de onde eles começam.
///
/// Some sozinho quando o Baru vier da Play Store.
class FolhaRestrita extends StatelessWidget {
  const FolhaRestrita({super.key, required this.lang});

  final String lang;

  static const chave = Key('folha-restrita');
  static const chaveAbrir = Key('folha-restrita-abrir');

  /// Abre a folha. Devolve quando ela fecha.
  static Future<void> mostra(BuildContext context, String lang) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
      ),
      builder: (_) => FolhaRestrita(lang: lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = T(lang);
    final passos = [t.restrito1, t.restrito2, t.restrito3, t.restrito4];

    return SafeArea(
      key: chave,
      child: Padding(
        padding: const EdgeInsets.all(Espaco.margemTela),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.restritoT, style: estilo(Tipo.titulo)),
            const SizedBox(height: Espaco.sm),
            Text(
              t.restritoPor,
              style: estilo(Tipo.corpo, color: Cores.tintaA(0.65)),
            ),
            const SizedBox(height: Espaco.lg),
            for (var i = 0; i < passos.length; i++) ...[
              _Passo(numero: i + 1, texto: passos[i]),
              if (i < passos.length - 1) const SizedBox(height: Espaco.sm),
            ],
            const SizedBox(height: Espaco.lg),
            PrimaryButton(
              key: chaveAbrir,
              label: t.restritoAbrir,
              onTap: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
            const SizedBox(height: Espaco.xxs),
            TextAction(
              label: t.restritoDepois,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Cores.primariaClara,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$numero',
            style: estilo(Tipo.rotuloPequeno, color: Cores.primariaEscura),
          ),
        ),
        const SizedBox(width: Espaco.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(texto, style: estilo(Tipo.corpo)),
          ),
        ),
      ],
    );
  }
}
