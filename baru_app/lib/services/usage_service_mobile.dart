import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

import '../data/tempo_de_tela.dart';
import 'tempo_de_tela_ios.dart';

/// Tempo de tela nativo: Usage Access real no Android; iOS honesto (sem API
/// pública).
class UsageService {
  UsageService._();

  static final UsageService instance = UsageService._();

  static const _contabilidade = ContabilidadeDeTela();

  /// Android: UsageStats. iPhone (iOS 16+): Tempo de Uso da Apple (Family
  /// Controls, entitlement aprovado) — o app não recebe minutos por app, só
  /// os limiares da meta que a extensão BaruMonitor registra.
  bool get platformSupportsUsage => Platform.isAndroid || Platform.isIOS;

  Future<bool> hasUsageAccess() async {
    if (Platform.isIOS) return (await TempoDeTelaIos.estado()).autorizado;
    if (!Platform.isAndroid) return false;
    return await UsageStats.checkUsagePermission() ?? false;
  }

  /// iPhone: a meta do app vira o monitoramento do Tempo de Uso. Numa
  /// família, quem manda é a meta do responsável (FamiliaSync), não esta.
  Future<void> sincronizaMetaIos(int metaMin) async {
    if (!Platform.isIOS) return;
    final e = await TempoDeTelaIos.estado();
    if (!e.autorizado || !e.temEscolha || e.modo == 'crianca') return;
    if (e.metaMin != metaMin) await TempoDeTelaIos.definirMeta(metaMin);
  }

  /// Android: abre a tela nativa "Acesso ao uso" (PACKAGE_USAGE_STATS).
  /// iOS: abre Ajustes do app — não há como conceder leitura de Screen Time
  /// aqui.
  Future<bool> requestUsageAccess() async {
    if (Platform.isAndroid) {
      await UsageStats.grantUsagePermission();
      return hasUsageAccess();
    }
    if (Platform.isIOS) {
      // O pedido da Apple aparece dentro do app; depois, os apps que contam.
      var e = await TempoDeTelaIos.estado();
      if (!e.suportado) {
        await openAppSettings();
        return false;
      }
      if (!e.autorizado) {
        try {
          e = await TempoDeTelaIos.pedirAutorizacao();
        } catch (_) {
          return false;
        }
      }
      if (e.autorizado && !e.temEscolha) e = await TempoDeTelaIos.escolherApps();
      return e.autorizado;
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
    if (Platform.isIOS) {
      // Só o piso: o maior limiar da meta já atingido hoje nos apps escolhidos.
      final e = await TempoDeTelaIos.estado();
      if (!e.autorizado) return null;
      final uso = Duration(minutes: e.minutosAoMenos);
      return ResumoDeTela(
        porApp: e.minutosAoMenos > 0 ? {'Tempo de Uso': uso} : const {},
        porCategoria: {CategoriaDeApp.dispersivo: uso},
      );
    }
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

  /// Os trechos de uso dos últimos [dias] dias inteiros, até [agora].
  ///
  /// É o material do perfil das pausas (`momentos_de_pausa.dart`): o
  /// mesmo par de eventos do tempo de tela, só que por mais dias. O Android
  /// guarda os eventos crus por cerca de uma semana; pedir mais não traz
  /// nada e só deixa a consulta lenta.
  Future<List<IntervaloDeUso>> intervalosDosUltimosDias({
    int dias = 7,
    DateTime? agora,
  }) async {
    if (!Platform.isAndroid || !await hasUsageAccess()) return const [];

    final fim = agora ?? DateTime.now();
    final inicio = DateTime(fim.year, fim.month, fim.day - dias);
    final crus = await UsageStats.queryEvents(
      inicio.subtract(ReconstrutorDeUso.janelaDeAquecimento),
      fim,
    );
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
    return _contabilidade.reconstrutor.intervalos(
      eventos,
      de: inicio,
      ate: fim,
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
