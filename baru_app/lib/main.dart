import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'auth_gate.dart';
import 'data/baru_env.dart';
import 'data/repositories.dart';
import 'data/supabase_gateway.dart';
import 'models.dart';
import 'theme.dart';
import 'widgets/ilustracao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    tz.initializeTimeZones();
    // O layout é desenhado para 412x892 em retrato; sem travar, girar o
    // aparelho passava do breakpoint de largura e o app desenhava a moldura
    // de desktop em volta de si mesmo.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  // As poses ilustradas carregam junto com o resto: sem isso o primeiro
  // quadro mostrava o desenho antigo e logo trocava pela ilustração.
  final ilustracoes = Future.wait([
    for (final s in Species.values) Ilustracoes.carrega(s),
  ]);
  await BaruEnv.load();
  final repos = BaruRepositories.local();
  await repos.init();
  await ilustracoes;
  await BaruSupabase.instance.attach();
  runApp(AuthGate(repos: repos));
}
