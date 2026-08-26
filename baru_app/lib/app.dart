import 'package:flutter/material.dart';

import 'data/app_snapshot.dart';
import 'data/repositories.dart';
import 'models.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/report_screen.dart';
import 'screens/result_screen.dart';
import 'screens/session_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/debug_panel.dart';
import 'widgets/share_sheet.dart';

class BaruApp extends StatefulWidget {
  const BaruApp({
    super.key,
    this.repos,
    this.snapshot,
    this.bootstrapNotice,
  });

  final BaruRepositories? repos;
  final AppSnapshot? snapshot;
  final String? bootstrapNotice;

  @override
  State<BaruApp> createState() => _BaruAppState();
}

class _BaruAppState extends State<BaruApp> with WidgetsBindingObserver {
  late final AppState state = AppState(
    repos: widget.repos,
    snapshot: widget.snapshot,
    onSyncError: _onSyncError,
    onUserMessage: _onUserMessage,
  );
  final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    state.initPlatformServices();
    if (widget.bootstrapNotice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(widget.bootstrapNotice!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  void _onSyncError(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onUserMessage(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      state.applyCalendar(DateTime.now());
      state.syncPermissionsFromOs();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return MaterialApp(
            title: 'Baru',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.data,
            locale: localeFor(state.lang),
            scrollBehavior: const BaruScrollBehavior(),
            scaffoldMessengerKey: _scaffoldKey,
            home: const AppFrame(child: _Shell()),
          );
        },
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      backgroundColor:
          app.screen == AppScreen.session ? AppColors.sessionBg : AppColors.cream,
      body: SafeArea(
        bottom: !app.showTabs,
        child: Stack(
          children: [
            _body(app),
            if (app.sharing) const ShareSheet(),
          ],
        ),
      ),
      bottomNavigationBar: app.showTabs ? const BottomTabs() : null,
      floatingActionButton: const DebugFab(),
    );
  }

  Widget _body(AppState app) {
    switch (app.screen) {
      case AppScreen.onb:
        return const OnboardingScreen();
      case AppScreen.paywall:
        return const PaywallScreen();
      case AppScreen.home:
        return const HomeScreen();
      case AppScreen.session:
        return const SessionScreen();
      case AppScreen.result:
        return const ResultScreen();
      case AppScreen.report:
        return const ReportScreen();
      case AppScreen.shop:
        return const ShopScreen();
      case AppScreen.profile:
        return const SettingsScreen();
    }
  }
}
