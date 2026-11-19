import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/baru_env.dart';
import '../data/familia.dart';
import '../l10n_familia.dart';
import '../state.dart';
import 'tempo_de_tela_ios.dart';

/// No celular da criança: manda o dia para a família e aplica as regras que
/// o responsável definiu. Chamado ao abrir a tela Família e ao voltar ao app.
///
/// Silencioso por desenho: sem conta, sem rede ou fora de uma família, não
/// faz nada. Nunca trava o app por causa do modo família.
class FamiliaSync {
  FamiliaSync._();
  static final instance = FamiliaSync._();

  DateTime? _ultimo;
  bool? _autorizadoAntes;

  /// Avisa o responsável só quando a autorização cai, não a cada envio.
  Future<void> _autorizacao(FamiliaRepo repo, bool ativa) async {
    if (!ativa && _autorizadoAntes != false) await repo.avisarAutorizacao(ativa: false);
    _autorizadoAntes = ativa;
  }
  bool _rodando = false;

  /// Intervalo mínimo entre dois envios, para o "voltar ao app" não virar
  /// uma chamada por desbloqueio.
  static const intervalo = Duration(minutes: 3);

  static const _canal = MethodChannel('baru/overlay');

  /// O que o guarda do Android (GuardaDaFamilia.kt) precisa, com os textos
  /// já no idioma da criança.
  static const _chaveGuardada = 'baru_familia_chave_aparelho';

  /// Chave própria deste aparelho, para o guarda do Android ler as regras
  /// sozinho. Pedida uma vez e guardada; sem a função no banco, fica nula.
  static Future<String?> _chaveDoAparelho(SupabaseClient client) async {
    final prefs = await SharedPreferences.getInstance();
    final salva = prefs.getString(_chaveGuardada);
    if (salva != null && salva.length == 64) return salva;
    try {
      final nova = await client.rpc('baru_familia_chave_do_aparelho');
      if (nova is String && nova.length == 64) {
        await prefs.setString(_chaveGuardada, nova);
        return nova;
      }
    } catch (e) {
      debugPrint('Baru: chave do aparelho indisponível — $e');
    }
    return null;
  }

  static String _regrasParaOGuarda(AppState app, RegrasDaFamilia r, {String? chave}) {
    garanteTextosDaFamilia();
    final t = app.t;
    return jsonEncode({
      'horarios': r.horariosSemTela.map((h) => h.paraMapa()).toList(),
      'pausaAteMs': r.pausaAte?.millisecondsSinceEpoch ?? 0,
      'metaMin': r.metaDe(DateTime.now()),
      'pausarAoEstourar': r.pausarAoEstourar,
      'titulo': t.s('famGuardaTitulo'),
      'corpoPausa': t.s('famGuardaPausa'),
      'corpoHorario': t.s('famGuardaHorario'),
      'corpoMeta': t.s('famGuardaMeta'),
      'botao': t.s('famGuardaBotao'),
      'notifTitulo': 'Baru',
      'notifCorpo': t.s('famGuardaNotif'),
      if (chave != null) 'chave': chave,
      'url': BaruEnv.supabaseUrl,
      'anon': BaruEnv.supabaseAnonKey,
    });
  }

  /// Filtro de sites (VPN só de DNS). Se a criança desligou a VPN, o
  /// responsável fica sabendo como "permissão tirada".
  Future<void> _filtroAndroid(bool ligado, FamiliaRepo repo) async {
    try {
      await _canal.invokeMethod('filtroLiga', {'ligado': ligado});
      if (ligado && await _canal.invokeMethod<bool>('filtroRevogado') == true) {
        await repo.avisarAutorizacao(ativa: false);
      }
    } catch (e) {
      debugPrint('Baru: filtro de sites não respondeu — $e');
    }
  }

  /// O Android já deixou ligar a VPN do filtro?
  static Future<bool> filtroPreparado() async {
    try {
      return await _canal.invokeMethod<bool>('filtroPreparado') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre o pedido do Android para permitir a VPN do filtro.
  static Future<void> pedeFiltro() async {
    try {
      await _canal.invokeMethod('filtroPede');
    } catch (_) {}
  }

  Future<void> _guardaAndroid(String? json) async {
    try {
      await _canal.invokeMethod('familiaRegras', {'json': json});
    } catch (e) {
      debugPrint('Baru: guarda da família não respondeu — $e');
    }
  }

  Future<void> envia(AppState app, {bool forcar = true}) async {
    if (kIsWeb || _rodando) return;
    final agora = DateTime.now();
    if (!forcar && _ultimo != null && agora.difference(_ultimo!) < intervalo) return;
    final SupabaseClient client;
    try {
      client = Supabase.instance.client;
    } catch (_) {
      return; // Supabase desligado (modo offline).
    }
    if (client.auth.currentSession == null) return;
    _rodando = true;
    try {
      final repo = FamiliaRepo(client);
      final minha = await repo.minha();
      if (!minha.souCrianca) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await _guardaAndroid(null);
          try {
            await _canal.invokeMethod('filtroLiga', {'ligado': false});
          } catch (_) {}
          (await SharedPreferences.getInstance()).remove(_chaveGuardada);
        }
        return;
      }
      _ultimo = agora;
      final regras = minha.minhasRegras ?? const RegrasDaFamilia();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        var tela = await TempoDeTelaIos.estado();
        if (!tela.suportado) return;
        // Para o push silencioso: o iPhone busca as regras sozinho.
        await TempoDeTelaIos.guardaChave(
          chave: await _chaveDoAparelho(client),
          url: BaruEnv.supabaseUrl,
          anon: BaruEnv.supabaseAnonKey,
          sandbox: kDebugMode,
        );
        await _autorizacao(repo, tela.autorizado);
        if (!tela.autorizado) return;
        // As regras do responsável valem neste aparelho.
        final metaHoje = regras.metaDe(DateTime.now());
        if (tela.metaMin != metaHoje && tela.temEscolha) {
          tela = await TempoDeTelaIos.definirMeta(metaHoje);
        }
        tela = await TempoDeTelaIos.aplicarRegras(
          horarios: regras.horariosSemTela.map((h) => h.paraMapa()).toList(),
          pausaAte: regras.pausaAte,
          filtro: regras.filtroSites,
        );
        if (tela.escudoAoEstourar != regras.pausarAoEstourar) {
          tela = await TempoDeTelaIos.definirEscudo(ativo: regras.pausarAoEstourar);
        }
        await repo.registrarDia(
          plataforma: 'ios',
          limiarMaxMin: tela.minutosAoMenos,
          focos: app.completedToday,
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        await _guardaAndroid(_regrasParaOGuarda(app, regras, chave: await _chaveDoAparelho(client)));
        await _filtroAndroid(regras.filtroSites, repo);
        await _autorizacao(repo, app.usageAccess);
        if (!app.usageAccess) {
          await repo.registrarDia(plataforma: 'android', focos: app.completedToday);
          return;
        }
        await repo.registrarDia(
          plataforma: 'android',
          minutos: app.usage,
          focos: app.completedToday,
        );
      }
    } catch (e) {
      debugPrint('Baru: família não sincronizou — $e');
    } finally {
      _rodando = false;
    }
  }
}
