import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'auth_gate.dart';
import 'data/baru_env.dart';
import 'data/repositories.dart';
import 'data/supabase_gateway.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    tz.initializeTimeZones();
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  await BaruEnv.load();
  final repos = BaruRepositories.local();
  await repos.init();
  await BaruSupabase.instance.attach();
  runApp(AuthGate(repos: repos));
}
