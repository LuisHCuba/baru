import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/app_snapshot.dart';
import 'data/baru_env.dart';
import 'data/repositories.dart';
import 'data/supabase_gateway.dart';
import 'l10n.dart';
import 'models.dart';
import 'screens/auth_screen.dart';
import 'theme.dart';
import 'widgets/common.dart';

/// Exige login email/senha quando Supabase está ligado.
/// Sessão válida → bootstrap remoto/local → app principal.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.repos});

  final BaruRepositories repos;

  @override
  State<AuthGate> createState() => AuthGateState();
}

class AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _authenticated = false;
  AppSnapshot? _snapshot;
  String? _bootstrapNotice;
  String? _attachError;
  StreamSubscription<AuthState>? _authSub;

  bool get _needsAuth => BaruEnv.supabaseEnabled;

  /// Idioma da porta de entrada: o que já estiver salvo, senão o do aparelho.
  /// O passo 1 do onboarding é escolher o idioma — mas o login vem antes dele.
  String _lang = 'pt';

  T get _t => T(_lang);

  @override
  void initState() {
    super.initState();
    _lang = langFromLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
    _init();
  }

  /// Prefere o idioma já escolhido pelo usuário neste aparelho.
  Future<void> _adotaIdiomaSalvo() async {
    final salvo = await widget.repos.loadSnapshot();
    final lang = salvo?.lang;
    if (lang == null || lang == _lang || !mounted) return;
    setState(() => _lang = lang);
  }

  Future<void> _init() async {
    await _adotaIdiomaSalvo();
    if (!_needsAuth) {
      final snap = await _loadOfflineSnapshot();
      if (mounted) {
        setState(() {
          _checking = false;
          _authenticated = true;
          _snapshot = snap;
        });
      }
      return;
    }

    if (!BaruSupabase.instance.attached) {
      final err = BaruSupabase.instance.attachError;
      if (mounted) {
        setState(() {
          _checking = false;
          _attachError = err ?? 'init';
        });
      }
      return;
    }

    _authSub = BaruSupabase.instance.authStateChanges.listen((event) {
      if (!mounted) return;
      if (event.event == AuthChangeEvent.signedOut) {
        setState(() {
          _authenticated = false;
          _snapshot = null;
          _bootstrapNotice = null;
          _checking = false;
        });
        return;
      }
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.tokenRefreshed) {
        if (!_authenticated && BaruSupabase.instance.isEmailUser) {
          _bootstrapAfterAuth(clearLocal: false);
        }
      }
    });

    if (BaruSupabase.instance.isEmailUser) {
      await _bootstrapAfterAuth(clearLocal: false);
    } else if (mounted) {
      setState(() {
        _checking = false;
        _authenticated = false;
      });
    }
  }

  Future<AppSnapshot?> _loadOfflineSnapshot() async {
    final remote = await widget.repos.pullRemote();
    if (remote != null) {
      await widget.repos.saveSnapshot(remote);
      return remote;
    }
    return widget.repos.loadSnapshot();
  }

  Future<void> _bootstrapAfterAuth({required bool clearLocal}) async {
    if (!mounted) return;
    setState(() {
      _checking = true;
      _bootstrapNotice = null;
    });
    if (clearLocal) await widget.repos.clearSnapshot();

    AppSnapshot? snap;
    String? notice;

    if (BaruSupabase.instance.ready) {
      final pull = await widget.repos.pullRemoteResult();
      if (pull.error != null) {
        notice = _t.syncFail;
      } else if (pull.snapshot != null) {
        await widget.repos.saveSnapshot(pull.snapshot!);
        snap = pull.snapshot;
      } else {
        notice = _t.bootstrapOffline;
      }
    }
    snap ??= clearLocal ? null : await widget.repos.loadSnapshot();

    if (mounted) {
      setState(() {
        _snapshot = snap;
        _bootstrapNotice = notice;
        _authenticated = true;
        _checking = false;
      });
    }
  }

  Future<void> _onAuthenticated() async {
    if (!BaruSupabase.instance.isEmailUser) return;
    await _bootstrapAfterAuth(clearLocal: true);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.data,
        locale: localeFor(_lang),
        home: AppFrame(
          child: Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.green),
                  const SizedBox(height: 20),
                  Text(
                    _t.authBootstrapLoading,
                    style: nunito(size: 15, color: AppColors.inkA(0.62)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_attachError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.data,
        locale: localeFor(_lang),
        home: AppFrame(
          child: Scaffold(
            backgroundColor: AppColors.cream,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Text(
                      _t.authAttachFail,
                      textAlign: TextAlign.center,
                      style: nunito(size: 16, height: 1.5, color: AppColors.orangeText),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: _t.authSignIn,
                      onTap: () {
                        setState(() {
                          _attachError = null;
                          _checking = true;
                        });
                        BaruSupabase.instance.attach().then((_) {
                          if (!mounted) return;
                          if (BaruSupabase.instance.attached) {
                            _init();
                          } else {
                            setState(() {
                              _checking = false;
                              _attachError =
                                  BaruSupabase.instance.attachError ?? 'init';
                            });
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_needsAuth && !_authenticated) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.data,
        locale: localeFor(_lang),
        scrollBehavior: const BaruScrollBehavior(),
        home: AppFrame(
          child: AuthScreen(
            lang: _lang,
            onAuthenticated: _onAuthenticated,
          ),
        ),
      );
    }

    return BaruApp(
      repos: widget.repos,
      snapshot: _snapshot,
      bootstrapNotice: _bootstrapNotice,
    );
  }
}
