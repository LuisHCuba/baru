import 'package:flutter/material.dart';

import '../data/auth_errors.dart';
import '../data/supabase_gateway.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onAuthenticated,
    this.lang = 'pt',
  });

  final Future<void> Function() onAuthenticated;
  final String lang;

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

  T get t => T(widget.lang);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      setState(() => _error = t.authAttachFail);
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
        await BaruSupabase.instance.signUp(
          email: email,
          password: password,
        );
        if (!BaruSupabase.instance.hasSession) {
          setState(() => _error = t.authConfirmEmail);
          return;
        }
      }
      if (!BaruSupabase.instance.isEmailUser) {
        setState(() => _error = t.authConfirmEmail);
        return;
      }
      await widget.onAuthenticated();
    } catch (e) {
      if (mounted) {
        setState(() => _error = translateAuthError(e, widget.lang));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == AuthMode.login;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                isLogin ? t.authLoginTitle : t.authSignupTitle,
                style: nunito(
                  size: 27,
                  weight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isLogin ? t.authLoginSub : t.authSignupSub,
                style: nunito(size: 15.5, height: 1.5, color: AppColors.inkA(0.62)),
              ),
              const SizedBox(height: 28),
              _field(
                label: t.authEmail,
                controller: _email,
                keyboard: TextInputType.emailAddress,
                autocorrect: false,
              ),
              const SizedBox(height: 14),
              _field(
                label: t.authPassword,
                controller: _password,
                obscure: true,
              ),
              if (!isLogin) ...[
                const SizedBox(height: 14),
                _field(
                  label: t.authPasswordConfirm,
                  controller: _confirm,
                  obscure: true,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: AppColors.orangeA(0.14),
                    borderRadius: BorderRadius.circular(AppRadii.chip),
                  ),
                  child: Text(
                    _error!,
                    style: nunito(size: 13.5, height: 1.45, color: AppColors.orangeText),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _loading
                    ? t.authLoading
                    : (isLogin ? t.authSignIn : t.authSignUp),
                onTap: _loading ? null : _submit,
                enabled: !_loading,
                shadow: true,
              ),
              const SizedBox(height: 12),
              TextAction(
                label: isLogin ? t.authCreateAccount : t.authBackToLogin,
                onTap: _loading
                    ? () {}
                    : () {
                        setState(() {
                          _mode =
                              isLogin ? AuthMode.signup : AuthMode.login;
                          _error = null;
                          _confirm.clear();
                        });
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    bool autocorrect = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            label,
            style: nunito(size: 13, weight: FontWeight.w700, color: AppColors.inkA(0.55)),
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          autocorrect: autocorrect,
          enableSuggestions: !obscure,
          style: nunito(size: 16, weight: FontWeight.w600),
          decoration: InputDecoration(hintText: label),
          onSubmitted: (_) => _loading ? null : _submit(),
        ),
      ],
    );
  }
}
