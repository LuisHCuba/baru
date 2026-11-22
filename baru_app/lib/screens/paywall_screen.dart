import 'package:flutter/material.dart';

import '../data/supabase_gateway.dart';
import '../state.dart';
import 'assinatura_screen.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  /// Assinatura pela loja do celular (uma só, mensal). Depois de confirmada,
  /// o acesso é lido de novo do servidor.
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return AssinaturaScreen(
      t: app.t,
      aoVoltar: app.voltar,
      aoLiberado: () {
        BaruSupabase.instance.meuAcesso();
        app.voltar();
      },
    );
  }
}
