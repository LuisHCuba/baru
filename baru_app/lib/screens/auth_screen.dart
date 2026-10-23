import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_errors.dart';
import '../data/biometria.dart';
import '../data/cofre.dart';
import '../data/supabase_gateway.dart';
import '../l10n.dart';
import '../l10n_codigo.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/pet.dart';

enum AuthMode { login, signup }

/// Como a tela abre.
///
/// Com credencial guardada ela **não** abre num formulário vazio: abre
/// dizendo quem é e oferecendo o desbloqueio do aparelho. Digitar continua a
/// um toque de distância — o caminho manual nunca some.
enum _Entrada { formulario, desbloqueio }

/// De que e-mail veio o código que a pessoa vai digitar.
enum _Codigo { senha, cadastro }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    this.lang = 'pt',
    this.cofre,
    this.biometria,
  });

  final Future<void> Function() onAuthenticated;
  final String lang;

  /// Injetáveis para o teste. Em produção ficam nulos e a tela monta os de
  /// verdade — nenhum teste toca no Keystore nem abre diálogo do sistema.
  final Cofre? cofre;
  final Biometria? biometria;

  static const chaveLembrar = Key('auth-lembrar');
  static const chaveBiometria = Key('auth-biometria');
  static const chaveDigitar = Key('auth-digitar');
  static const chaveOutraConta = Key('auth-outra-conta');
  static const chaveEsqueci = Key('auth-esqueci');
  static const chaveReenviar = Key('auth-reenviar');

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _recado;

  /// Tela do código de e-mail: nula = fora dela.
  _Codigo? _codigo;
  final _campoCodigo = TextEditingController();

  late final Cofre _cofre = widget.cofre ?? CofreSeguro();
  late final Biometria _bio = widget.biometria ?? BiometriaDoAparelho();

  _Entrada _entrada = _Entrada.formulario;
  CredencialLembrada? _guardada;

  /// Ligado por padrão. Quem chega para entrar quer entrar de novo amanhã;
  /// desligar é um toque, e o texto embaixo diz onde o dado fica.
  bool _lembrar = true;
  bool _podeBiometria = false;
  bool _pedindoBiometria = false;

  T get t => T(widget.lang);

  @override
  void initState() {
    super.initState();
    _abre();
  }

  /// O que a tela descobre antes de se desenhar.
  Future<void> _abre() async {
    final guardada = await _cofre.le();
    final pode = await _bio.disponivel();
    if (!mounted) return;
    setState(() {
      _guardada = guardada;
      _podeBiometria = pode;
      if (guardada != null) {
        _email.text = guardada.email;
        _lembrar = true;
        _entrada = _Entrada.desbloqueio;
      }
    });
    // Pedir sozinho só quando a pessoa aceitou a biometria. Abrir o diálogo
    // do sistema sem ela ter pedido é assustador, e ela ainda não sabe por
    // que o aparelho está perguntando.
    if (guardada != null && guardada.comBiometria && pode) {
      await _desbloqueia();
    }
  }

  /// Prova quem é pelo aparelho e entra com o que está no cofre.
  Future<void> _desbloqueia() async {
    final guardada = _guardada;
    if (guardada == null || _pedindoBiometria || _loading) return;
    setState(() {
      _pedindoBiometria = true;
      _error = null;
    });
    final ok = await _bio.confirma(t.authBiometriaMotivo);
    if (!mounted) return;
    setState(() => _pedindoBiometria = false);
    if (!ok) {
      // Cancelar não é erro em vermelho: é a pessoa escolhendo digitar.
      setState(() {
        _entrada = _Entrada.formulario;
        _password.clear();
      });
      return;
    }
    _password.text = guardada.senha;
    await _submit(doCofre: true);
  }

  /// Larga a credencial guardada e volta ao formulário limpo.
  Future<void> _outraConta() async {
    await _cofre.esquece();
    if (!mounted) return;
    setState(() {
      _guardada = null;
      _entrada = _Entrada.formulario;
      _mode = AuthMode.login;
      _email.clear();
      _password.clear();
      _error = null;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _campoCodigo.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// [doCofre] diz que a senha veio do cofre, não do teclado.
  ///
  /// Muda o que acontece quando o Supabase recusa: senha digitada errada é
  /// erro para corrigir ali mesmo; senha **guardada** errada é credencial
  /// velha — trocada em outro aparelho — e insistir na digital nunca vai
  /// funcionar. Nesse caso a tela cai no formulário e o cofre é esvaziado,
  /// senão a pessoa fica presa repetindo um desbloqueio inútil.
  Future<void> _submit({bool doCofre = false}) async {
    final email = _email.text.trim();
    final password = _password.text;
    setState(() => _error = null);

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = t.authEmailInvalid);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = t.authPasswordShort);
      return;
    }
    if (_mode == AuthMode.signup && password != _confirm.text) {
      setState(() => _error = t.authPasswordMismatch);
      return;
    }

    if (!BaruSupabase.instance.attached) {
      // Vindo do cofre, mostrar o erro e ficar no desbloqueio deixaria a
      // pessoa repetindo a digital sem saída. O cofre fica: app sem
      // configuração não diz nada sobre a senha.
      setState(() {
        _error = t.authAttachFail;
        if (doCofre) {
          _entrada = _Entrada.formulario;
          _password.clear();
        }
      });
      return;
    }

    setState(() => _loading = true);
    try {
      if (_mode == AuthMode.login) {
        await BaruSupabase.instance.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await BaruSupabase.instance.signUp(email: email, password: password);
        if (!BaruSupabase.instance.hasSession) {
          // Conta criada, falta confirmar: o código do e-mail entra aqui mesmo.
          _abreCodigo(_Codigo.cadastro);
          return;
        }
      }
      if (!BaruSupabase.instance.isEmailUser) {
        setState(() => _error = t.authConfirmEmail);
        return;
      }
      // Só depois de o login dar certo. Guardar antes seria guardar uma
      // senha errada e oferecer biometria que nunca funcionaria.
      await aplicaLembranca(
        _cofre,
        lembrar: _lembrar,
        email: email,
        senha: password,
        // Com o aparelho sem bloqueio de tela, lembrar continua valendo —
        // só não há o que destravar.
        comBiometria: _podeBiometria,
      );
      // Fecha o contexto de preenchimento: o Android oferece salvar a senha.
      TextInput.finishAutofillContext();
      await widget.onAuthenticated();
    } catch (e) {
      if (!mounted) return;
      if (doCofre) {
        // Sem rede ou sem configuração não se apaga nada: o erro não diz
        // nada sobre a senha, e perdê-la aí seria perder o que estava
        // certo. Voltar ao formulário, porém, vale nos dois casos — é o
        // caminho que a pessoa tem para seguir.
        final recusada = credencialRecusada(e);
        if (recusada) await _cofre.esquece();
        if (!mounted) return;
        setState(() {
          if (recusada) _guardada = null;
          _entrada = _Entrada.formulario;
          _password.clear();
        });
      }
      // Senha certa mas e-mail sem confirmar: em vez de só avisar, manda um
      // código novo e abre o campo para digitá-lo.
      if (!doCofre && _mode == AuthMode.login && _emailSemConfirmar(e)) {
        try {
          await BaruSupabase.instance.reenviaConfirmacao(email);
        } catch (_) {
          // O código do e-mail anterior continua valendo; a tela abre igual.
        }
        if (!mounted) return;
        _abreCodigo(_Codigo.cadastro);
        return;
      }
      setState(() => _error = translateAuthError(e, widget.lang));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static bool _emailSemConfirmar(Object e) {
    final texto = '$e'.toLowerCase();
    return texto.contains('email_not_confirmed') ||
        texto.contains('email not confirmed');
  }

  void _abreCodigo(_Codigo tipo) {
    setState(() {
      _codigo = tipo;
      _error = null;
      _recado = null;
      _campoCodigo.clear();
      _password.clear();
      _confirm.clear();
    });
  }

  void _fechaCodigo() {
    setState(() {
      _codigo = null;
      _error = null;
      _recado = null;
      _campoCodigo.clear();
      _password.clear();
      _confirm.clear();
      _mode = AuthMode.login;
    });
  }

  /// Valida o código; na recuperação grava a senha nova antes de entrar.
  Future<void> _confirmaCodigo() async {
    final email = _email.text.trim();
    final codigo = _campoCodigo.text.replaceAll(RegExp(r'\D'), '');
    final senha = _password.text;
    setState(() {
      _error = null;
      _recado = null;
    });
    if (codigo.length < 6) {
      setState(() => _error = t.s('codCurto'));
      return;
    }
    if (_codigo == _Codigo.senha) {
      if (senha.length < 6) {
        setState(() => _error = t.authPasswordShort);
        return;
      }
      if (senha != _confirm.text) {
        setState(() => _error = t.authPasswordMismatch);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      await BaruSupabase.instance.verificaCodigo(
        email: email,
        codigo: codigo,
        recuperacao: _codigo == _Codigo.senha,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = t.s('codInvalido');
          _loading = false;
        });
      }
      return;
    }
    try {
      if (_codigo == _Codigo.senha) {
        await BaruSupabase.instance.trocaSenha(senha);
        await aplicaLembranca(
          _cofre,
          lembrar: _lembrar,
          email: email,
          senha: senha,
          comBiometria: _podeBiometria,
        );
      }
      // Fecha o contexto de preenchimento: o Android oferece salvar a senha.
      TextInput.finishAutofillContext();
      await widget.onAuthenticated();
    } catch (e) {
      if (mounted) setState(() => _error = translateAuthError(e, widget.lang));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reenviaCodigo() async {
    final email = _email.text.trim();
    setState(() {
      _error = null;
      _recado = null;
      _loading = true;
    });
    try {
      if (_codigo == _Codigo.senha) {
        await BaruSupabase.instance.recuperaSenha(email);
      } else {
        await BaruSupabase.instance.reenviaConfirmacao(email);
      }
      if (mounted) {
        setState(() => _recado = t.fill(t.s('codReenviado'), {'e': email}));
      }
    } catch (e) {
      if (mounted) setState(() => _error = translateAuthError(e, widget.lang));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Onde entra o código de 8 dígitos do e-mail (cadastro ou senha).
  Widget _corpoCodigo() {
    garanteTextosDoCodigo();
    final senha = _codigo == _Codigo.senha;
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalho(
            titulo: t.s(senha ? 'codTituloSenha' : 'codTituloCadastro'),
            sub: t.fill(t.s('codSub'), {'e': _email.text.trim()}),
          ),
          _field(
            label: t.s('codCampo'),
            controller: _campoCodigo,
            icone: Icons.pin_outlined,
            keyboard: TextInputType.number,
            autocorrect: false,
            autofill: const [AutofillHints.oneTimeCode],
            acao: senha ? TextInputAction.next : TextInputAction.done,
            aoEnviar: senha ? null : _confirmaCodigo,
          ),
          if (senha) ...[
            const SizedBox(height: 12),
            _field(
              label: t.s('codNovaSenha'),
              controller: _password,
              icone: Icons.lock_outline_rounded,
              obscure: true,
              autofill: const [AutofillHints.newPassword],
              acao: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _field(
              label: t.s('codConfirmaSenha'),
              controller: _confirm,
              icone: Icons.lock_outline_rounded,
              obscure: true,
              autofill: const [AutofillHints.newPassword],
              acao: TextInputAction.done,
              aoEnviar: _confirmaCodigo,
            ),
          ],
          if (_error != null) ...[const SizedBox(height: 16), _aviso(_error!)],
          if (_recado != null) ...[
            const SizedBox(height: 16),
            _recadoOk(_recado!),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _loading
                ? t.authLoading
                : t.s(senha ? 'codBotaoSenha' : 'codBotaoCadastro'),
            onTap: _loading ? null : _confirmaCodigo,
            enabled: !_loading,
            shadow: true,
          ),
          const SizedBox(height: 12),
          TextAction(
            key: AuthScreen.chaveReenviar,
            label: t.s('codReenviar'),
            onTap: _loading ? () {} : _reenviaCodigo,
          ),
          TextAction(
            label: t.s('codVoltar'),
            onTap: _loading ? () {} : _fechaCodigo,
          ),
        ],
      ),
    );
  }

  /// "Esqueci a senha" na porta de entrada: quem esqueceu não consegue
  /// chegar em Sua conta, onde o mesmo pedido já existia. Usa o e-mail
  /// digitado e abre a tela do código, onde a senha nova é escolhida.
  Future<void> _recuperar() async {
    final email = _email.text.trim();
    setState(() {
      _error = null;
      _recado = null;
    });
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = t.authEmailInvalid);
      return;
    }
    if (!BaruSupabase.instance.attached) {
      setState(() => _error = t.authAttachFail);
      return;
    }
    setState(() => _loading = true);
    try {
      await BaruSupabase.instance.recuperaSenha(email);
      if (!mounted) return;
      _abreCodigo(_Codigo.senha);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = translateAuthError(e, widget.lang));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 34),
          child: _codigo != null
              ? _corpoCodigo()
              : _entrada == _Entrada.desbloqueio
              ? _corpoDesbloqueio()
              : _corpoFormulario(),
        ),
      ),
    );
  }

  /// A volta de quem já entrou aqui.
  Widget _corpoDesbloqueio() {
    final email = _guardada?.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cabecalho(
          titulo: t.authOla,
          sub: _podeBiometria ? t.authBiometriaSub : t.authLembrarSub,
          humor: Mood.radiant,
        ),
        Text(
          email,
          textAlign: TextAlign.center,
          style: nunito(
            size: 16,
            weight: FontWeight.w800,
            color: AppColors.greenDeep,
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 16), _aviso(_error!)],
        const SizedBox(height: 28),
        if (_podeBiometria)
          PrimaryButton(
            key: AuthScreen.chaveBiometria,
            label: _pedindoBiometria || _loading
                ? t.authLoading
                : t.authBiometria,
            onTap: _pedindoBiometria || _loading ? null : _desbloqueia,
            enabled: !_pedindoBiometria && !_loading,
            shadow: true,
          ),
        if (_podeBiometria) const SizedBox(height: 12),
        TextAction(
          key: AuthScreen.chaveDigitar,
          label: t.authVoltar,
          onTap: () => setState(() {
            _entrada = _Entrada.formulario;
            _password.clear();
            _error = null;
          }),
        ),
        TextAction(
          key: AuthScreen.chaveOutraConta,
          label: t.authOutraConta,
          onTap: _outraConta,
        ),
      ],
    );
  }

  /// Confirmação neutra (não é erro): mesmo formato do aviso, em tinta.
  Widget _recadoOk(String texto) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.inkA(0.06),
      borderRadius: BorderRadius.circular(AppRadii.chip),
    ),
    child: Text(
      texto,
      style: nunito(size: 13.5, height: 1.45, color: AppColors.inkA(0.8)),
    ),
  );

  Widget _aviso(String texto) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: BoxDecoration(
      color: AppColors.orangeA(0.14),
      borderRadius: BorderRadius.circular(AppRadii.chip),
    ),
    child: Text(
      texto,
      style: nunito(size: 13.5, height: 1.45, color: AppColors.orangeText),
    ),
  );

  /// Topo comum das telas de entrada: o companheiro, o título e uma linha.
  ///
  /// Antes era só texto num fundo creme — a porta do app não tinha nada do
  /// app. O bicho é o mesmo `PetView` da casa, parado, no humor da tela.
  Widget _cabecalho({
    required String titulo,
    required String sub,
    Mood humor = Mood.content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Center(
          child: SizedBox(
            height: 132,
            child: PetView(
              species: Species.capybara,
              mood: humor,
              activity: Activity.idle,
              coat: 0,
              scale: 0.82,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: nunito(
            size: 26,
            weight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: nunito(size: 15, height: 1.45, color: AppColors.inkA(0.6)),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _corpoFormulario() {
    garanteTextosDoCodigo();
    final isLogin = _mode == AuthMode.login;
    void trocaModo() {
      if (_loading) return;
      setState(() {
        _mode = isLogin ? AuthMode.signup : AuthMode.login;
        _error = null;
        _recado = null;
        _confirm.clear();
      });
    }

    // AutofillGroup: o gerenciador de senhas do Google oferece e guarda o
    // login. Sem ele a pessoa digitava tudo à mão toda vez.
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cabecalho(
            titulo: isLogin ? t.authLoginTitle : t.authSignupTitle,
            sub: t.s(isLogin ? 'codLoginSub' : 'codCadastroSub'),
          ),
          _field(
            label: t.authEmail,
            controller: _email,
            icone: Icons.mail_outline_rounded,
            keyboard: TextInputType.emailAddress,
            autocorrect: false,
            autofill: const [AutofillHints.email, AutofillHints.username],
            acao: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _field(
            label: t.authPassword,
            controller: _password,
            icone: Icons.lock_outline_rounded,
            obscure: true,
            autofill: [
              isLogin ? AutofillHints.password : AutofillHints.newPassword,
            ],
            acao: isLogin ? TextInputAction.done : TextInputAction.next,
            aoEnviar: isLogin ? _submit : null,
          ),
          if (isLogin)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: AuthScreen.chaveEsqueci,
                onPressed: _loading ? null : _recuperar,
                child: Text(
                  t.s('codEsqueci'),
                  style: nunito(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.greenDeep,
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            _field(
              label: t.authPasswordConfirm,
              controller: _confirm,
              icone: Icons.lock_outline_rounded,
              obscure: true,
              autofill: const [AutofillHints.newPassword],
              acao: TextInputAction.done,
              aoEnviar: _submit,
            ),
            const SizedBox(height: 8),
          ],
          // Lembrar é escolha explícita e reversível. O subtítulo diz onde o
          // dado fica — sem isso a pessoa tem que adivinhar se a senha foi
          // para algum servidor.
          _LinhaLembrar(
            key: AuthScreen.chaveLembrar,
            rotulo: t.s('codLembrar'),
            detalhe: _podeBiometria ? t.s('codLembrarSub') : t.authLembrarSub,
            ligado: _lembrar,
            aoTocar: () => setState(() => _lembrar = !_lembrar),
          ),
          if (_error != null) ...[const SizedBox(height: 14), _aviso(_error!)],
          if (_recado != null) ...[
            const SizedBox(height: 14),
            _recadoOk(_recado!),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: _loading
                ? t.authLoading
                : (isLogin ? t.authSignIn : t.authSignUp),
            onTap: _loading ? null : _submit,
            enabled: !_loading,
            shadow: true,
          ),
          if (_guardada != null && isLogin) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: AuthScreen.chaveDigitar,
              onPressed: () => setState(() => _entrada = _Entrada.desbloqueio),
              icon: const Icon(Icons.fingerprint_rounded, size: 22),
              label: Text(
                t.authBiometria,
                style: nunito(size: 15.5, weight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.greenDeep,
                minimumSize: const Size.fromHeight(52),
                side: BorderSide(color: AppColors.greenA(0.45), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          // Trocar entre entrar e criar conta numa linha só, no rodapé: era
          // um texto cinza solto no meio de outros dois iguais.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                t.s(isLogin ? 'codSemConta' : 'codComConta'),
                style: nunito(size: 15, color: AppColors.inkA(0.6)),
              ),
              TextButton(
                onPressed: _loading ? null : trocaModo,
                child: Text(
                  isLogin ? t.authCreateAccount : t.authSignIn,
                  style: nunito(
                    size: 15,
                    weight: FontWeight.w800,
                    color: AppColors.greenDeep,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Controladores de senha que estão à mostra (o olho do campo).
  final _senhasVisiveis = <TextEditingController>{};

  /// Campo de entrada no visual do app: cartão claro, ícone, um rótulo só
  /// (antes o rótulo aparecia duas vezes, em cima e dentro do campo) e o
  /// olho para conferir a senha digitada.
  Widget _field({
    required String label,
    required TextEditingController controller,
    IconData? icone,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    bool autocorrect = true,
    Iterable<String>? autofill,
    TextInputAction acao = TextInputAction.done,
    Future<void> Function()? aoEnviar,
  }) {
    final escondida = obscure && !_senhasVisiveis.contains(controller);
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: BorderSide(color: AppColors.inkA(0.10)),
    );
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: escondida,
      autocorrect: autocorrect && !obscure,
      enableSuggestions: !obscure,
      autofillHints: autofill,
      textInputAction: acao,
      style: nunito(size: 16, weight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: nunito(size: 15, color: AppColors.inkA(0.5)),
        floatingLabelStyle: nunito(
          size: 14,
          weight: FontWeight.w700,
          color: AppColors.greenDeep,
        ),
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIcon: icone == null
            ? null
            : Icon(icone, color: AppColors.inkA(0.45), size: 22),
        suffixIcon: !obscure
            ? null
            : IconButton(
                tooltip: t.s(escondida ? 'codMostrar' : 'codEsconder'),
                icon: Icon(
                  escondida
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.inkA(0.45),
                ),
                onPressed: () => setState(() {
                  if (escondida) {
                    _senhasVisiveis.add(controller);
                  } else {
                    _senhasVisiveis.remove(controller);
                  }
                }),
              ),
        border: borda,
        enabledBorder: borda,
        focusedBorder: borda.copyWith(
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
      ),
      onSubmitted: aoEnviar == null || _loading ? null : (_) => aoEnviar(),
    );
  }
}

/// A linha do "lembrar meus dados".
///
/// Mesma forma da linha de ajustes — rótulo, explicação embaixo e a chave à
/// direita —, porque é a mesma promessa: um interruptor que a pessoa
/// entende sem abrir nada.
class _LinhaLembrar extends StatelessWidget {
  const _LinhaLembrar({
    super.key,
    required this.rotulo,
    required this.detalhe,
    required this.ligado,
    required this.aoTocar,
  });

  final String rotulo;
  final String detalhe;
  final bool ligado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: ligado,
      label: rotulo,
      child: GestureDetector(
        onTap: aoTocar,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rotulo,
                      style: nunito(size: 15.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalhe,
                      style: nunito(
                        size: 12.5,
                        height: 1.35,
                        color: AppColors.inkA(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              AppToggle(on: ligado, onTap: aoTocar),
            ],
          ),
        ),
      ),
    );
  }
}
