import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/baru_env.dart';
import '../data/familia.dart';
import '../l10n_familia.dart';
import '../state.dart';
import 'localizacao.dart';
import 'tempo_de_tela_ios.dart';

/// No celular da criança: manda o dia para a família e aplica as regras que
/// o responsável definiu. Chamado ao abrir a tela Família e ao voltar ao app.
///
/// Silencioso por desenho: sem conta, sem rede ou fora de uma família, não
/// faz nada. Nunca trava o app por causa do modo família.
/// Guardado para o app abrir já na Família, sem esperar a rede.
const chaveResponsavel = 'baru_familia_sou_responsavel';

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

  /// Chave já conferida com o servidor nesta abertura do app.
  static String? _chaveConferida;

  /// Chave própria deste aparelho, para o guarda do Android ler as regras
  /// sozinho. Pedida uma vez e guardada; sem a função no banco, fica nula.
  static Future<String?> _chaveDoAparelho(SupabaseClient client) async {
    final prefs = await SharedPreferences.getInstance();
    final salva = prefs.getString(_chaveGuardada);
    if (salva != null && salva.length == 64) {
      // A chave guardada pode ter morrido no servidor (a criança saiu e voltou
      // à família, ou o aparelho foi trocado): sem conferir, o celular ficava
      // mudo para sempre — sem regras com o app fechado e sem localização.
      if (_chaveConferida == salva) return salva;
      try {
        final r = await client.rpc('baru_familia_regras_do_aparelho', params: {'p_chave': salva});
        if (r != null) {
          _chaveConferida = salva;
          return salva;
        }
      } catch (_) {
        return salva; // sem rede: fica com a que tem
      }
    }
    try {
      final nova = await client.rpc('baru_familia_chave_do_aparelho', params: {'p_chave_antiga': salva});
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
      'notifCorpoLocal': t.s('famGuardaNotifLocal'),
      'localizacao': r.localizacao,
      'localPedidoMs': r.localPedidoEm?.millisecondsSinceEpoch ?? 0,
      if (chave != null) 'chave': chave,
      'url': BaruEnv.supabaseUrl,
      'anon': BaruEnv.supabaseAnonKey,
    });
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

  static const _chaveDoResponsavel = 'baru_familia_chave_resp';

  /// "Mostrar minha localização" ligado neste celular (adulto do laço).
  static const chaveMeuLocal = 'baru_meu_local';

  /// Celular do responsável: chave própria e textos, para os avisos (SOS,
  /// chegou, saiu, meta) chegarem com o Baru fechado. iPhone: push da Apple;
  /// Android: conferência de 15 em 15 minutos.
  Future<void> _avisosDoResponsavel(AppState app, FamiliaRepo repo, bool souResponsavel) async {
    final prefs = await SharedPreferences.getInstance();
    if (!souResponsavel) {
      if (prefs.getString(_chaveDoResponsavel) != null) {
        await LocalNativo.avisos(null);
        await prefs.remove(_chaveDoResponsavel);
      }
      return;
    }
    var chave = prefs.getString(_chaveDoResponsavel);
    if (chave == null || chave.length != 64) {
      try {
        chave = await repo.chaveDoResponsavel(idioma: app.lang);
      } catch (e) {
        debugPrint('Baru: chave do responsável indisponível — $e');
        return;
      }
      if (chave == null) return;
      await prefs.setString(_chaveDoResponsavel, chave);
    }
    garanteTextosDaFamilia();
    final t = app.t;
    await LocalNativo.avisos(jsonEncode({
      'chave': chave,
      'url': BaruEnv.supabaseUrl,
      'anon': BaruEnv.supabaseAnonKey,
      'idioma': app.lang,
      'sandbox': kDebugMode,
      'canal': t.s('avCanal'),
      'canalSos': t.s('avCanalSos'),
      // Adulto que escolheu aparecer no mapa: o Android manda a posição com o app fechado.
      'meuLocal': prefs.getBool(chaveMeuLocal) ?? false,
      'textos': {
        'sos': [t.s('avSosT'), t.s('avSosC')],
        'chegou': [t.s('avChegouT'), t.s('avChegouC')],
        'saiu_de': [t.s('avSaiuT'), t.s('avSaiuC')],
        'meta_75': [t.s('avMetaT'), t.s('avMeta75C')],
        'meta_batida': [t.s('avMetaT'), t.s('avMetaBatidaC')],
        'meta_passou': [t.s('avMetaT'), t.s('avMetaPassouC')],
        'autorizacao_revogada': [t.s('avAutT'), t.s('avAutC')],
      },
    }));
  }

  /// Celular da criança: liga o envio com o app fechado e manda uma posição
  /// ao abrir o app (se a localização estiver ligada e permitida).
  Future<void> _localizacao(RegrasDaFamilia regras, FamiliaRepo repo, String? chave) async {
    await LocalNativo.configura(
      ligada: regras.localizacao,
      chave: chave,
      url: BaruEnv.supabaseUrl,
      anon: BaruEnv.supabaseAnonKey,
    );
    if (chave == null) return;
    // O pedido de permissão só acontece na tela Família, depois do aviso em
    // destaque (exigência da Google e da Apple): aqui só usa o que já foi dado.
    final permissao = await LocalNativo.estado();
    // O responsável vê a permissão e a versão: sem isso, "sem posição" não
    // tinha explicação no painel.
    try {
      await repo.estadoDoAparelho(chave: chave, local: permissao.noServidor, versao: versaoDoApp);
    } catch (e) {
      debugPrint('Baru: estado do aparelho não enviado — $e');
    }
    if (!regras.localizacao || !permissao.concedida) return;
    final p = await LocalNativo.agora();
    if (p == null) return;
    await repo.enviarPosicao(chave: chave, lat: p.lat, lng: p.lng, precisaoM: p.precisaoM, bateria: p.bateria, motivo: 'abriu');
  }

  /// SOS da criança: posição agora, com aviso imediato para a família.
  /// Devolve falso sem posição (localização desligada ou negada).
  static Future<bool> sos() async {
    try {
      final client = Supabase.instance.client;
      final chave = await _chaveDoAparelho(client);
      if (chave == null) return false;
      var permissao = await LocalNativo.estado();
      if (!permissao.concedida) permissao = await LocalNativo.pedir(sempre: false);
      if (!permissao.concedida) return false;
      final p = await LocalNativo.agora();
      if (p == null) return false;
      await FamiliaRepo(client).enviarPosicao(
          chave: chave, lat: p.lat, lng: p.lng, precisaoM: p.precisaoM, bateria: p.bateria, motivo: 'sos');
      return true;
    } catch (e) {
      debugPrint('Baru: SOS falhou — $e');
      return false;
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
      final souResponsavel = minha.familias.any((f) => f.meuPapel == 'responsavel');
      app.marcaResponsavel(souResponsavel);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(chaveResponsavel, souResponsavel);
      await _avisosDoResponsavel(app, repo, souResponsavel);
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
        final chave = await _chaveDoAparelho(client);
        await _localizacao(regras, repo, chave);
        var tela = await TempoDeTelaIos.estado();
        if (!tela.suportado) return;
        // Para o push silencioso: o iPhone busca as regras sozinho.
        await TempoDeTelaIos.guardaChave(
          chave: chave,
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
        final chave = await _chaveDoAparelho(client);
        await _guardaAndroid(_regrasParaOGuarda(app, regras, chave: chave));
        await _localizacao(regras, repo, chave);
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
