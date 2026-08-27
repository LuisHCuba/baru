import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Sua conta.
///
/// O app criava conta no onboarding e depois nunca mais falava dela: não
/// havia como ver qual e-mail estava logado, trocar de e-mail, mudar a senha
/// ou chegar ao plano sem passar por Ajustes. Sair era o único botão.
///
/// Cada operação aqui diz **o que realmente acontece**. Trocar e-mail no
/// Supabase não troca na hora: manda um link para o endereço novo e o login
/// só muda depois do clique. Esconder isso faz parecer que não funcionou.
class ContaScreen extends StatefulWidget {
  const ContaScreen({super.key});

  static const chaveEmail = Key('conta-email');

  @override
  State<ContaScreen> createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen> {
  String? _aviso;
  bool _avisoEhErro = false;
  bool _ocupado = false;

  void _diz(String texto, {bool erro = false}) {
    if (!mounted) return;
    setState(() {
      _aviso = texto;
      _avisoEhErro = erro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    final temConta = app.canSignOut && app.emailDaConta.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecalhoDeDetalhe(
          titulo: t.contaT,
          subtitulo: t.contaSub,
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
              if (!temConta)
                EstadoVazio(
                  icone: Icons.person_outline_rounded,
                  titulo: t.contaSemConta,
                  // Não repete o subtítulo do cartão de plano logo abaixo:
                  // a mesma frase duas vezes na tela lê como bug.
                  corpo: t.contaSub,
                )
              else ...[
                CartaoBaru(
                  key: ContaScreen.chaveEmail,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.contaEmail.toUpperCase(),
                        style: estilo(
                          Tipo.rotuloPequeno,
                          color: Cores.tintaA(0.45),
                        ),
                      ),
                      const SizedBox(height: Espaco.xxs),
                      Text(app.emailDaConta, style: estilo(Tipo.subtitulo)),
                      if (!app.emailConfirmado) ...[
                        const SizedBox(height: Espaco.xxs),
                        Etiqueta(
                          texto: t.contaEmailNaoConfirmado,
                          cor: Cores.acento,
                          icone: Icons.mark_email_unread_outlined,
                        ),
                      ],
                      if (app.contaCriadaEm != null) ...[
                        const SizedBox(height: Espaco.sm),
                        Text(
                          '${t.contaDesde} '
                          '${t.formatLongDate(app.contaCriadaEm!)}',
                          style: estilo(
                            Tipo.corpoPequeno,
                            color: Cores.tintaA(0.55),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Espaco.md),
                CartaoBaru(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espaco.md,
                  ),
                  child: Column(
                    children: [
                      _Acao(
                        icone: Icons.alternate_email_rounded,
                        rotulo: t.contaTrocarEmail,
                        ativo: !_ocupado,
                        aoTocar: () => _pedeTexto(
                          context,
                          app,
                          titulo: t.contaTrocarEmail,
                          campo: t.contaNovoEmail,
                          nota: t.contaTrocarEmailAviso,
                          senha: false,
                          acao: app.trocaEmail,
                        ),
                      ),
                      Divider(height: 1, color: Cores.tintaA(0.07)),
                      _Acao(
                        icone: Icons.key_rounded,
                        rotulo: t.contaTrocarSenha,
                        ativo: !_ocupado,
                        aoTocar: () => _pedeTexto(
                          context,
                          app,
                          titulo: t.contaTrocarSenha,
                          campo: t.contaNovaSenha,
                          nota: null,
                          senha: true,
                          acao: app.trocaSenha,
                        ),
                      ),
                      Divider(height: 1, color: Cores.tintaA(0.07)),
                      _Acao(
                        icone: Icons.mail_outline_rounded,
                        rotulo: t.contaRecuperar,
                        ativo: !_ocupado,
                        aoTocar: () async {
                          setState(() => _ocupado = true);
                          final erro = await app.recuperaSenha();
                          setState(() => _ocupado = false);
                          _diz(
                            erro ??
                                t.fill(t.contaRecuperarOk, {
                                  'e': app.emailDaConta,
                                }),
                            erro: erro != null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              if (_aviso != null) ...[
                const SizedBox(height: Espaco.sm),
                _Aviso(texto: _aviso!, erro: _avisoEhErro),
              ],
              const SizedBox(height: Espaco.md),
              CartaoBaru(
                cor: Cores.primariaA(0.10),
                elevado: false,
                onTap: () => app.go(AppScreen.paywall),
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
                          Text(
                            app.trial
                                ? t.fill(t.planTrial, {'n': app.trialDaysLeft})
                                : t.planNone,
                            style: estilo(Tipo.subtitulo),
                          ),
                          Text(
                            app.trial
                                ? t.fill(t.planTrialSub, {
                                    'd': t.formatLongDate(app.paidPlanStart),
                                  })
                                : t.planNoneSub,
                            style: estilo(
                              Tipo.corpoPequeno,
                              color: Cores.tintaA(0.6),
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
              ),
              if (temConta) ...[
                const SizedBox(height: Espaco.md),
                CartaoBaru(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Espaco.md,
                  ),
                  child: _Acao(
                    icone: Icons.logout_rounded,
                    rotulo: t.authSignOut,
                    apagado: true,
                    ativo: !_ocupado,
                    aoTocar: app.signOut,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pedeTexto(
    BuildContext context,
    AppState app, {
    required String titulo,
    required String campo,
    required String? nota,
    required bool senha,
    required Future<String?> Function(String) acao,
  }) async {
    final t = app.t;
    final controlador = TextEditingController();
    final valor = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Espaco.margemTela),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(titulo, style: estilo(Tipo.titulo)),
                const SizedBox(height: Espaco.md),
                TextField(
                  controller: controlador,
                  autofocus: true,
                  obscureText: senha,
                  keyboardType: senha
                      ? TextInputType.text
                      : TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: campo,
                    filled: true,
                    fillColor: Cores.tintaA(0.04),
                    border: OutlineInputBorder(
                      borderRadius: Raio.todos(Raio.campo),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (v) => Navigator.of(sheetContext).pop(v),
                ),
                if (nota != null) ...[
                  const SizedBox(height: Espaco.sm),
                  Text(
                    nota,
                    style: estilo(
                      Tipo.corpoPequeno,
                      color: Cores.tintaA(0.55),
                    ),
                  ),
                ],
                const SizedBox(height: Espaco.md),
                PrimaryButton(
                  label: t.contaSalvar,
                  onTap: () =>
                      Navigator.of(sheetContext).pop(controlador.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controlador.dispose();
    if (valor == null || valor.trim().isEmpty) return;

    setState(() => _ocupado = true);
    final erro = await acao(valor);
    if (!mounted) return;
    setState(() => _ocupado = false);
    _diz(erro ?? (nota ?? t.contaOk), erro: erro != null);
  }
}

class _Acao extends StatelessWidget {
  const _Acao({
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
    this.ativo = true,
    this.apagado = false,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback aoTocar;
  final bool ativo;
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final cor = apagado ? Cores.tintaA(0.5) : Cores.tinta;
    return Semantics(
      button: true,
      enabled: ativo,
      child: GestureDetector(
        onTap: ativo ? aoTocar : null,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Toque.minimo),
          child: Row(
            children: [
              Icon(icone, size: 19, color: cor),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Text(rotulo, style: estilo(Tipo.corpo, color: cor)),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Cores.tintaA(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.erro});

  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final cor = erro ? Cores.dispersivo : Cores.primaria;
    return Container(
      padding: const EdgeInsets.all(Espaco.md),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: Raio.todos(Raio.cartao),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            erro ? Icons.error_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: cor,
          ),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Text(texto, style: estilo(Tipo.corpoPequeno, color: cor)),
          ),
        ],
      ),
    );
  }
}
