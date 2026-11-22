import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../cobranca.dart';
import '../l10n_ajustes.dart';
import '../l10n.dart';
import '../l10n_assinatura.dart';
import '../l10n_foto.dart';
import '../services/foto_de_perfil.dart';
import '../services/compra_loja.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/acesso.dart';
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
  static const chaveApagar = Key('conta-apagar');
  static const chavePrivacidade = Key('conta-privacidade');
  static const chaveAssinatura = Key('conta-assinatura');

  @override
  State<ContaScreen> createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen> {
  String? _aviso;
  bool _avisoEhErro = false;
  bool _ocupado = false;

  /// Versão da minha foto de perfil (nula: sem foto).
  DateTime? _minhaFoto;

  String? get _meuId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null; // testes sem Supabase
    }
  }

  @override
  void initState() {
    super.initState();
    garanteTextosDaFoto();
    if (_meuId != null) {
      FotoDePerfil.minhaVersao().then((v) {
        if (mounted) setState(() => _minhaFoto = v);
      }).catchError((Object _) {});
    }
  }

  Future<void> _trocaFoto(T t) async {
    final id = _meuId;
    if (id == null) return;
    if (await FotoDePerfil.escolhe(context, t, dono: id, temFoto: _minhaFoto != null)) {
      final v = await FotoDePerfil.minhaVersao().catchError((Object _) => null);
      if (mounted) setState(() => _minhaFoto = v);
    }
  }

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
    garanteTextosDosAjustes();
    garanteTextosDaAssinatura();
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
                  corpo: t.contaSemContaCorpo,
                )
              else ...[
                CartaoBaru(
                  key: ContaScreen.chaveEmail,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Foto de perfil: é ela que aparece no mapa da família.
                  if (_meuId != null) ...[
                    Semantics(
                      button: true,
                      label: t.s('fotoTrocar'),
                      child: GestureDetector(
                        key: const Key('conta-foto'),
                        onTap: () => _trocaFoto(t),
                        child: Stack(clipBehavior: Clip.none, children: [
                          FotoOuLetra(dono: _meuId!, versao: _minhaFoto, nome: app.displayName, raio: 30,
                              cor: Cores.primariaA(0.14), corDaLetra: Cores.primariaEscura),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Cores.primariaEscura, shape: BoxShape.circle),
                              child: const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: Espaco.md),
                  ],
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.contaEmail.toUpperCase(),
                        style: estilo(
                          Tipo.rotuloPequeno,
                          color: Cores.tinta700,
                        ),
                      ),
                      const SizedBox(height: Espaco.xxs),
                      Text(app.emailDaConta, style: estilo(Tipo.subtitulo)),
                      if (!app.emailConfirmado) ...[
                        const SizedBox(height: Espaco.xxs),
                        Etiqueta(
                          texto: t.contaEmailNaoConfirmado,
                          cor: Cores.alerta,
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
                            color: Cores.tinta700,
                          ),
                        ),
                      ],
                    ],
                  )),
                  ]),
                ),
                const SizedBox(height: Espaco.md),
                CartaoBaru(
                  padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
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
              // O estado do acesso é do servidor e aparece sempre: é aqui que
              // a pessoa descobre quantos dias de teste faltam.
              const SizedBox(height: Espaco.md),
              CartaoDoAcesso(t: t),
              if (cobrancaNaLoja) ...[
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
                                  ? t.fill(t.planTrial, {
                                      'n': app.trialDaysLeft,
                                    })
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
                                color: Cores.tinta700,
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
              ],
              const SizedBox(height: Espaco.md),
              // A assinatura pela loja do celular (no site é pelo painel).
              if (CompraLoja.temLoja) ...[
                CartaoBaru(
                  padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
                  child: _Acao(
                    key: ContaScreen.chaveAssinatura,
                    icone: Icons.workspace_premium_outlined,
                    rotulo: t.s('assT'),
                    ativo: true,
                    aoTocar: () => app.go(AppScreen.paywall),
                  ),
                ),
                const SizedBox(height: Espaco.xs),
              ],
              // Sobre o Baru: o que é da conta e do contrato fica aqui, não
              // espalhado nos Ajustes.
              Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.xs, Espaco.sm, Espaco.xs, Espaco.xs),
                child: Text(t.s('contaSecSobre').toUpperCase(),
                    style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700).copyWith(letterSpacing: 0.8)),
              ),
              CartaoBaru(
                padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
                child: Column(
                  children: [
                    if (cobrancaNaLoja) ...[
                      _Acao(
                        icone: Icons.restore_rounded,
                        rotulo: t.setRestore,
                        ativo: !_ocupado,
                        aoTocar: app.restorePurchases,
                      ),
                      Divider(height: 1, color: Cores.tintaA(0.07)),
                    ],
                    _Acao(
                      key: ContaScreen.chavePrivacidade,
                      icone: Icons.shield_outlined,
                      rotulo: t.s('contaPrivDados'),
                      ativo: true,
                      aoTocar: () => _abrePrivacidade(context, app),
                    ),
                    Divider(height: 1, color: Cores.tintaA(0.07)),
                    _Acao(
                      icone: Icons.article_outlined,
                      rotulo: t.setTerms,
                      ativo: true,
                      aoTocar: () => _abreTermos(context, app),
                    ),
                  ],
                ),
              ),
              // Sair é uso normal e fica sozinho no fim. Apagar dados e refazer
              // a apresentação moram dentro de Privacidade e Termos: ninguém
              // deve tocar neles sem querer.
              if (temConta) ...[
                const SizedBox(height: Espaco.lg),
                CartaoBaru(
                  padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
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

  /// Folha com o texto legal e, no fim, uma ação discreta.
  Future<void> _folhaLegal(
    BuildContext context, {
    required String titulo,
    required String corpo,
    required String fechar,
    required Widget discreto,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
      ),
      builder: (folha) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(folha).size.height * 0.85),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(Espaco.margemTela),
            children: [
              Text(titulo, style: estilo(Tipo.titulo)),
              const SizedBox(height: Espaco.md),
              Text(corpo, style: estilo(Tipo.corpo, color: Cores.tinta700)),
              const SizedBox(height: Espaco.lg),
              BotaoBaru(rotulo: fechar, aoTocar: () => Navigator.of(folha).pop()),
              const SizedBox(height: Espaco.xl),
              Divider(height: 1, color: Cores.tintaA(0.07)),
              const SizedBox(height: Espaco.sm),
              Center(child: discreto),
            ],
          ),
        ),
      ),
    );
  }

  void _abrePrivacidade(BuildContext context, AppState app) {
    final t = app.t;
    _folhaLegal(
      context,
      titulo: t.setPrivacy,
      corpo: t.privacyBody,
      fechar: t.shareDone,
      discreto: TextButton(
        key: ContaScreen.chaveApagar,
        onPressed: _ocupado
            ? null
            : () {
                Navigator.of(context).pop();
                _confirmaApagar(context, app);
              },
        child: Text(t.contaApagar, style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
      ),
    );
  }

  void _abreTermos(BuildContext context, AppState app) {
    final t = app.t;
    _folhaLegal(
      context,
      titulo: t.setTerms,
      corpo: t.termsBody,
      fechar: t.shareDone,
      discreto: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          app.restartOnboarding();
        },
        child: Text(t.setReplay, style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
      ),
    );
  }

  /// Apagar não pode ser um toque só.
  Future<void> _confirmaApagar(BuildContext context, AppState app) async {
    final t = app.t;
    final confirmou = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espaco.margemTela),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.contaApagar, style: estilo(Tipo.titulo)),
              const SizedBox(height: Espaco.sm),
              Text(
                t.fill(t.contaApagarConfirma, {'n': app.displayName}),
                style: estilo(Tipo.corpo, color: Cores.tinta700),
              ),
              const SizedBox(height: Espaco.lg),
              BotaoBaru(
                rotulo: t.contaApagarCancelar,
                aoTocar: () => Navigator.of(sheetContext).pop(false),
              ),
              const SizedBox(height: Espaco.xs),
              BotaoBaru(
                rotulo: t.contaApagarBotao,
                aoTocar: () => Navigator.of(sheetContext).pop(true),
                papel: PapelDoBotao.destrutivo,
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmou != true) return;

    setState(() => _ocupado = true);
    final erro = await app.apagaMeusDados();
    if (!mounted) return;
    setState(() => _ocupado = false);
    _diz(erro ?? t.contaApagarOk, erro: erro != null);
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
                    style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
                  ),
                ],
                const SizedBox(height: Espaco.md),
                BotaoBaru(
                  rotulo: t.contaSalvar,
                  aoTocar: () => Navigator.of(sheetContext).pop(controlador.text),
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
    super.key,
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
    final cor = apagado ? Cores.tinta500 : Cores.tinta;
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
                color: Cores.tinta500,
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
    final cor = erro ? Cores.alerta : Cores.folha600;
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
