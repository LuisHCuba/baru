import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

import '../data/tempo_de_tela.dart';

/// Tempo de tela nativo: Usage Access real no Android; iOS honesto (sem API
/// pública).
class UsageService {
  UsageService._();

  static final UsageService instance = UsageService._();

  static const _contabilidade = ContabilidadeDeTela();

  /// iOS não expõe tempo de tela total a apps de terceiros sem entitlement
  /// Apple (Family Controls / DeviceActivity). Ver comentário em
  /// [requestUsageAccess].
  bool get platformSupportsUsage => Platform.isAndroid;

  Future<bool> hasUsageAccess() async {
    if (!Platform.isAndroid) return false;
    return await UsageStats.checkUsagePermission() ?? false;
  }

  /// Android: abre a tela nativa "Acesso ao uso" (PACKAGE_USAGE_STATS).
  /// iOS: abre Ajustes do app — não há como conceder leitura de Screen Time
  /// aqui.
  Future<bool> requestUsageAccess() async {
    if (Platform.isAndroid) {
      await UsageStats.grantUsagePermission();
      return hasUsageAccess();
    }
    await openAppSettings();
    return false;
  }

  /// Detalhamento do dia: por app e por categoria.
  ///
  /// Usa `queryEvents` — os eventos crus do sistema — e **não**
  /// `queryAndAggregateUsageStats`. O agregado do Android soma tempo de
  /// primeiro plano de todo pacote, inclusive com a tela apagada: era ele que
  /// contava Spotify no bolso como tempo de tela.
  Future<ResumoDeTela?> resumoDeHoje({
    Map<String, CategoriaDeApp> ajustes = const {},
    DateTime? agora,
  }) async {
    if (!Platform.isAndroid || !await hasUsageAccess()) return null;

    final fim = agora ?? DateTime.now();
    final inicioDoDia = DateTime(fim.year, fim.month, fim.day);

    // Pede eventos de antes da meia-noite para descobrir se a tela já estava
    // ligada quando o dia virou. Sem isso, uso que atravessa a meia-noite
    // começaria "no escuro" e seria perdido.
    final aquecimento =
        inicioDoDia.subtract(ReconstrutorDeUso.janelaDeAquecimento);

    final crus = await UsageStats.queryEvents(aquecimento, fim);
    final eventos = <EventoDeUso>[];
    for (final e in crus) {
      final tipo = int.tryParse(e.eventType ?? '');
      final ms = int.tryParse(e.timeStamp ?? '');
      final pacote = e.packageName;
      if (tipo == null || ms == null || pacote == null) continue;
      eventos.add(
        EventoDeUso(
          tipo: tipo,
          quando: DateTime.fromMillisecondsSinceEpoch(ms),
          pacote: pacote,
        ),
      );
    }

    return _contabilidade.resumo(
      eventos,
      de: inicioDoDia,
      ate: fim,
      ajustes: ajustes,
    );
  }

  /// Minutos que a meta compara: dispersivo + neutro.
  ///
  /// `null` quer dizer "não sei" — sem permissão o app não estima.
  Future<int?> todayScreenTimeMinutes({
    Map<String, CategoriaDeApp> ajustes = const {},
  }) async {
    final r = await resumoDeHoje(ajustes: ajustes);
    return r?.minutosContabilizados;
  }
}
