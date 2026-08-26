import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

/// Tempo de tela nativo: Usage Access real no Android; iOS honesto (sem API pública).
class UsageService {
  UsageService._();

  static final UsageService instance = UsageService._();

  /// iOS não expõe tempo de tela total a apps de terceiros sem entitlement Apple
  /// (Family Controls / DeviceActivity). Ver comentário em [requestUsageAccess].
  bool get platformSupportsUsage => Platform.isAndroid;

  Future<bool> hasUsageAccess() async {
    if (!Platform.isAndroid) return false;
    return await UsageStats.checkUsagePermission() ?? false;
  }

  /// Android: abre a tela nativa "Acesso ao uso" (PACKAGE_USAGE_STATS).
  /// iOS: abre Ajustes do app — não há como conceder leitura de Screen Time aqui.
  Future<bool> requestUsageAccess() async {
    if (Platform.isAndroid) {
      await UsageStats.grantUsagePermission();
      return hasUsageAccess();
    }
    await openAppSettings();
    return false;
  }

  /// Soma foreground de todos os apps desde meia-noite local (minutos).
  Future<int?> todayScreenTimeMinutes() async {
    if (!Platform.isAndroid || !await hasUsageAccess()) return null;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final aggregated =
        await UsageStats.queryAndAggregateUsageStats(start, now);
    var totalMs = 0;
    for (final info in aggregated.values) {
      totalMs += int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
    }
    return (totalMs / 60000).round();
  }
}
