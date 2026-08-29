import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import 'app_snapshot.dart';
import 'baru_env.dart';
import 'remote_result.dart';
import 'row_codec.dart';

/// Client Supabase: auth email/senha + sync por domínio (tabelas normalizadas).
/// Falha → fallback local com erro visível. Nunca service_role.
/// O schema do projeto remoto está atrás do repositório: uma tabela que o app
/// escreve não existe lá.
///
/// Merece um tipo próprio porque **não é falha de rede**: tentar de novo não
/// resolve, e a mensagem genérica de sincronização ("tente mais tarde")
/// mente. A correção é aplicar a migração que falta.
class TabelaAusenteNoRemoto implements Exception {
  const TabelaAusenteNoRemoto(this.tabela);

  final String tabela;

  /// O PostgREST responde 404 com `PGRST205` quando a tabela não está no
  /// cache de schema — que é o que acontece com migração não aplicada.
  static const codigo = 'PGRST205';

  static TabelaAusenteNoRemoto? de(Object erro) {
    if (erro is! PostgrestException) return null;
    if (erro.code != codigo) return null;
    final m = RegExp(r"'public\.([a-z_]+)'").firstMatch(erro.message);
    return TabelaAusenteNoRemoto(m?.group(1) ?? 'desconhecida');
  }

  @override
  String toString() => 'TabelaAusenteNoRemoto($tabela)';
}

/// Uma coluna que o app escreve e o banco remoto ainda não tem.
///
/// Acontece toda vez que o repositório anda antes de a migração ser aplicada.
/// **Não é falha de rede e não é fatal**: a coluna nova costuma ser um
/// acréscimo, e insistir nela sacrifica tudo o que ia junto na mesma escrita.
class ColunaAusenteNoRemoto implements Exception {
  const ColunaAusenteNoRemoto(this.coluna);

  final String coluna;

  /// O nome vem em quatro gramáticas, e as quatro acontecem.
  ///
  /// O PostgREST usa aspas simples; o Postgres usa aspas duplas no `insert` e
  /// **nenhuma aspa** no `select`. Só a primeira estava reconhecida, então
  /// toda coluna recusada numa leitura virava "desconhecida" — e quem degrada
  /// decide pelo nome se a coluna era mesmo opcional. Sem o nome, ou se
  /// degradava por qualquer erro, ou não se degradava nunca.
  static final _gramaticas = <RegExp>[
    RegExp(r"Could not find the '([a-z0-9_]+)' column"),
    RegExp(r'column "([a-z0-9_]+)" of relation'),
    RegExp(r'column (?:[a-z0-9_]+\.)?([a-z0-9_]+) does not exist'),
    RegExp(r"'([a-z0-9_]+)'"),
  ];

  /// `PGRST204` é o PostgREST sem a coluna no cache de schema; `42703` é o
  /// Postgres dizendo que ela não existe.
  static ColunaAusenteNoRemoto? de(Object erro) {
    if (erro is! PostgrestException) return null;
    if (erro.code != 'PGRST204' && erro.code != '42703') return null;
    for (final g in _gramaticas) {
      final m = g.firstMatch(erro.message);
      if (m != null) return ColunaAusenteNoRemoto(m.group(1)!);
    }
    return const ColunaAusenteNoRemoto('desconhecida');
  }

  @override
  String toString() => 'ColunaAusenteNoRemoto($coluna)';
}

class BaruSupabase {
  BaruSupabase._();
  static final BaruSupabase instance = BaruSupabase._();

  static const _codec = BaruRowCodec();
  static const _deviceKey = 'baru_device_id';

  bool _attached = false;
  bool _ready = false;
  StreamSubscription<AuthState>? _authSub;
  String _deviceId = '';
  String? attachError;

  String get url => BaruEnv.supabaseUrl;
  String get anonKey => BaruEnv.supabaseAnonKey;
  bool get supabaseEnabled => BaruEnv.supabaseEnabled;
  bool get attached => _attached;
  bool get ready => _ready;

  SupabaseClient? get _client {
    if (!_attached) return null;
    return Supabase.instance.client;
  }

  bool get hasSession => _client?.auth.currentSession != null;

  bool get isEmailUser {
    final user = _client?.auth.currentUser;
    if (user == null || !hasSession) return false;
    final mail = user.email;
    return mail != null && mail.isNotEmpty;
  }

  String? get currentUserEmail => _client?.auth.currentUser?.email;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  Future<void> attach() async {
    if (!supabaseEnabled) return;
    attachError = null;
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      _attached = true;
      _deviceId = await _ensureDeviceId();
      await _refreshReady();
      // Sessão expirada ou logout em outra aba não pode deixar `_ready` preso
      // em true: o push seguiria tentando escrever sem credencial válida.
      _authSub?.cancel();
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        (_) => _refreshReady(),
      );
    } catch (e, st) {
      attachError = e.toString();
      debugPrint('Baru: supabase indisponível ($e)\n$st');
      _attached = false;
      _ready = false;
    }
  }

  Future<void> _refreshReady() async {
    _ready = isEmailUser;
  }

  void _ensureAttached() {
    if (_client == null) {
      throw const AuthException('Supabase não inicializado');
    }
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _ensureAttached();
    final resp = await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (resp.session == null) {
      throw const AuthException('email_not_confirmed');
    }
    _deviceId = await _ensureDeviceId();
    await _refreshReady();
    return resp;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    _ensureAttached();
    final resp = await _client!.auth.signUp(
      email: email.trim(),
      password: password,
    );
    _deviceId = await _ensureDeviceId();
    await _refreshReady();
    return resp;
  }

  /// Colunas que o app escreve e um banco atrasado pode não ter.
  ///
  /// O repositório anda na frente da migração — é o normal deste projeto, e
  /// já custou uma vez com `equipped`. Uma coluna nova não pode derrubar a
  /// linha inteira: o resto dela é dado que o usuário acabou de produzir, e
  /// sacrificá-lo para insistir num acréscimo troca muito por pouco.
  ///
  /// Entra aqui **só** o que veio depois das tabelas base. Coluna que sempre
  /// existiu fica de fora de propósito: se ela sumir, é defeito de schema e
  /// tem de estourar em vez de virar dado silenciosamente perdido.
  static const colunasOpcionais = <String, Set<String>>{
    // migration 9
    'baru_pets': {'sexo'},
    // migration 13
    'baru_onboarding_answers': {'respostas'},
    // migrations 9 e 14
    'baru_settings': {'evening_hour', 'evening_minute', 'som'},
    // migrations 10 e 15
    'baru_progression': {
      'sessoes_concluidas',
      'melhor_sequencia',
      'dias_abaixo_da_meta',
      'missoes_resgatadas',
      'dias_abaixo_na_semana',
      'semana_de',
    },
    // migration 11
    'baru_inventory_items': {'equipped'},
  };

  static const _equipped = 'baru_inventory_items.equipped';

  /// Colunas que este banco recusou nesta sessão, como `tabela.coluna`.
  ///
  /// Lembrar evita repetir, a cada gravação, a tentativa que já se sabe que
  /// falha — e evita a ida e volta que ela custa. Vale para leitura também:
  /// uma recusa na escrita já ensina o `select` a não pedir a coluna.
  final Set<String> _colunasSemRemoto = {};

  /// O corpo da gravação sem as colunas que este banco já recusou.
  ///
  /// Separado da chamada de rede porque é aqui que mora a promessa: **o resto
  /// da linha sobe**. Uma coluna recusada tira uma chave do mapa e nada mais.
  @visibleForTesting
  static Map<String, dynamic> semAsAusentes(
    String tabela,
    Map<String, dynamic> linha,
    Set<String> ausentes,
  ) =>
      {
        for (final e in linha.entries)
          if (!ausentes.contains('$tabela.${e.key}')) e.key: e.value,
      };

  /// Grava uma linha tolerando coluna que este banco ainda não tem.
  ///
  /// Tira a coluna recusada e tenta de novo, uma por vez — o PostgREST só
  /// nomeia uma por resposta. Só degrada pelo que está em [colunasOpcionais],
  /// e no máximo tantas vezes quantas forem as opcionais daquela tabela:
  /// erro de verdade continua estourando, e um servidor que reclamasse
  /// sempre da mesma coluna não viraria laço infinito.
  Future<void> _upsertTolerante(
    String tabela,
    Map<String, dynamic> linha,
  ) async {
    final client = _client!;
    final opcionais = colunasOpcionais[tabela] ?? const <String>{};
    var restantes = opcionais.length;
    while (true) {
      try {
        await client
            .from(tabela)
            .upsert(semAsAusentes(tabela, linha, _colunasSemRemoto));
        return;
      } catch (e) {
        final ausente = ColunaAusenteNoRemoto.de(e);
        if (ausente == null ||
            !opcionais.contains(ausente.coluna) ||
            restantes-- <= 0) {
          rethrow;
        }
        _colunasSemRemoto.add('$tabela.${ausente.coluna}');
        debugPrint(
          'Baru: `${ausente.coluna}` não existe em $tabela — a gravação segue '
          'sem ela até a migração ser aplicada.',
        );
      }
    }
  }

  /// Todas as tabelas que guardam dado do usuário.
  ///
  /// A lista vive aqui, ao lado de quem escreve nelas: uma tabela nova que
  /// entre no `push` e não entre aqui vira dado que o usuário não consegue
  /// apagar.
  ///
  /// `baru_daily_quests` continua aqui **mesmo sem escritor**: o app parou de
  /// gravar nela (ver a migration 16), mas as linhas de quem já usou o app
  /// continuam lá, e apagar a conta tem de alcançar todas.
  static const tabelasDoUsuario = [
    'baru_sessions',
    'baru_inventory_items',
    'baru_week_calendar',
    'baru_daily_quests',
    'baru_app_categories',
    'baru_progression',
    'baru_daily_progress',
    'baru_streaks',
    'baru_screen_time',
    'baru_settings',
    'baru_subscriptions',
    'baru_onboarding_answers',
    'baru_wallets',
    'baru_pets',
    'baru_profiles',
  ];

  /// Apaga tudo o que é do usuário no remoto.
  ///
  /// A RLS já garante o escopo — a política de `delete` é
  /// `auth.uid() = user_id` —, então isto não consegue tocar em dado de
  /// outra pessoa nem por engano.
  ///
  /// Devolve o nome das tabelas que falharam. Vazio quer dizer limpo.
  Future<List<String>> apagaTudoDoUsuario() async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) {
      return const ['sem_sessao'];
    }
    final falharam = <String>[];
    for (final tabela in tabelasDoUsuario) {
      try {
        await client.from(tabela).delete().eq('user_id', uid);
      } catch (e) {
        debugPrint('Baru: nao apagou $tabela — $e');
        falharam.add(tabela);
      }
    }
    return falharam;
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
    _ready = false;
  }

  /// Troca o e-mail da conta.
  ///
  /// O Supabase **não** troca na hora: manda um link de confirmação para o
  /// endereço novo, e só depois de clicado o login passa a ser por ele. Quem
  /// chama tem de dizer isso ao usuário, senão parece que não funcionou.
  Future<void> trocaEmail(String novo) async {
    _ensureAttached();
    await _client!.auth.updateUser(UserAttributes(email: novo.trim()));
  }

  /// Troca a senha da sessão atual. Vale imediatamente.
  Future<void> trocaSenha(String nova) async {
    _ensureAttached();
    await _client!.auth.updateUser(UserAttributes(password: nova));
  }

  /// Manda o e-mail de recuperação de senha.
  Future<void> recuperaSenha(String email) async {
    _ensureAttached();
    await _client!.auth.resetPasswordForEmail(email.trim());
  }

  /// Quando a conta foi criada. Nulo quando não há sessão.
  DateTime? get contaCriadaEm {
    final iso = _client?.auth.currentUser?.createdAt;
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// O e-mail está confirmado?
  bool get emailConfirmado =>
      _client?.auth.currentUser?.emailConfirmedAt != null;

  @visibleForTesting
  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
  }

  Future<String> _ensureDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await prefs.setString(_deviceKey, id);
    return id;
  }

  String? get _uid => _client?.auth.currentUser?.id;

  Future<RemotePushResult> pushSnapshot(AppSnapshot snapshot) async {
    if (!_ready) {
      return const RemotePushResult(ok: false, error: 'offline');
    }
    final uid = _uid;
    if (uid == null) {
      return const RemotePushResult(ok: false, error: 'no_session');
    }
    try {
      await pushAccount(snapshot);
      await pushPet(snapshot);
      await pushShop(snapshot);
      await pushSettings(snapshot);
      await pushStreak(snapshot);
      await pushSubscription(snapshot);
      // Faltava aqui. O caminho de produção sobe domínio a domínio e chama
      // `pushProgression` pelo `_syncProgresso`, então isto não custou dado
      // a ninguém — mas um método chamado "sobe o snapshot" que deixa XP,
      // vínculo, marcos e missões resgatadas em terra é uma armadilha para
      // quem confiar no nome.
      await pushProgression(snapshot);
      await pushSessions(snapshot.sessions);
      return const RemotePushResult(ok: true);
    } catch (e) {
      debugPrint('Baru: sync remoto falhou ($e)');
      return RemotePushResult(ok: false, error: e.toString());
    }
  }

  Future<void> pushAccount(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await _upsertTolerante(
      'baru_profiles',
      _codec.profileRow(userId: uid, deviceId: _deviceId, s: snapshot),
    );
    await _upsertTolerante(
      'baru_onboarding_answers',
      _codec.onboardingRow(userId: uid, s: snapshot),
    );
  }

  Future<void> pushPet(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await _upsertTolerante('baru_pets', _codec.petRow(userId: uid, s: snapshot));
  }

  Future<void> pushShop(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await _upsertTolerante(
      'baru_wallets',
      _codec.walletRow(userId: uid, s: snapshot),
    );
    // Só ids conhecidos da loja: o banco tem CHECK, mas um snapshot
    // corrompido não deveria chegar a montar filtro com lixo dentro.
    final conhecidos = shopItems.map((i) => i.id).toSet();
    final owned = snapshot.owned.where(conhecidos.contains).toSet().toList();

    // Some com o que saiu do inventário numa chamada só, em vez de ler tudo e
    // apagar item a item.
    final apaga =
        client.from('baru_inventory_items').delete().eq('user_id', uid);
    if (owned.isEmpty) {
      await apaga;
    } else {
      final lista = owned.map((id) => '"$id"').join(',');
      await apaga.not('item_id', 'in', '($lista)');
    }

    final rows = _codec.inventoryRows(userId: uid, s: snapshot);
    if (rows.isEmpty) return;

    // Duas escritas de propósito.
    //
    // A primeira cria o que é novo com `ignoreDuplicates`, que preserva o
    // `acquired_at` de quem já estava lá — sem isso, todo push reescrevia a
    // data de compra com "agora" e embaralhava a ordem em que o habitat foi
    // montado.
    //
    // Mas `ignoreDuplicates` também **não atualiza nada** numa linha que já
    // existe: colocar e tirar um item já comprado nunca chegaria ao remoto.
    // Daí a segunda, que manda só `equipped` — o upsert atualiza apenas as
    // colunas presentes no corpo, então `acquired_at` continua intacto.
    await client.from('baru_inventory_items').upsert(
          [
            for (final r in rows)
              {
                'user_id': r['user_id'],
                'item_id': r['item_id'],
                'acquired_at': r['acquired_at'],
              },
          ],
          ignoreDuplicates: true,
        );

    if (_colunasSemRemoto.contains(_equipped)) return;
    try {
      await client.from('baru_inventory_items').upsert([
        for (final r in rows)
          {
            'user_id': r['user_id'],
            'item_id': r['item_id'],
            'equipped': r['equipped'],
          },
      ]);
    } catch (e) {
      // Coluna nova, banco antigo: o app anda antes da migração. Degrada em
      // vez de derrubar a gravação inteira — o inventário já subiu acima, e
      // o "em uso" fica guardado no aparelho até a migração ser aplicada.
      final ausente = ColunaAusenteNoRemoto.de(e);
      if (ausente == null) rethrow;
      _colunasSemRemoto.add(_equipped);
      debugPrint(
        'Baru: sem `equipped` no remoto — o item em uso só fica no aparelho '
        'até a migração 11 ser aplicada.',
      );
    }
  }

  Future<void> pushSettings(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await _upsertTolerante(
      'baru_settings',
      _codec.settingsRow(userId: uid, s: snapshot),
    );
    await _upsertTolerante(
      'baru_screen_time',
      _codec.screenTimeRow(userId: uid, s: snapshot),
    );

    // Reclassificações de app. Some do remoto o que o usuário desfez.
    final ajustes = snapshot.ajustesDeCategoria;
    final apaga =
        client.from('baru_app_categories').delete().eq('user_id', uid);
    if (ajustes.isEmpty) {
      await apaga;
    } else {
      final lista = ajustes.keys.map((p) => '"$p"').join(',');
      await apaga.not('package_name', 'in', '($lista)');
      await client.from('baru_app_categories').upsert(
            _codec.appCategoryRows(userId: uid, s: snapshot),
          );
    }
  }

  Future<void> pushStreak(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await _upsertTolerante(
      'baru_streaks',
      _codec.streakRow(userId: uid, s: snapshot),
    );
    await client.from('baru_week_calendar').upsert(
          _codec.weekRows(userId: uid, s: snapshot),
        );
    await _upsertTolerante(
      'baru_daily_progress',
      _codec.dailyProgressRow(userId: uid, s: snapshot),
    );
    // `baru_daily_quests` **não** é gravada aqui, e é de propósito.
    //
    // Escrevia dois booleanos derivados — "houve foco hoje" e "o dia está
    // abaixo da meta" — que já estão em `baru_daily_progress` e
    // `baru_screen_time`, e ninguém no app jamais leu de volta. Custava uma
    // viagem de rede por fim de sessão para acumular linha que não é lida.
    // O registro de missão que o app usa é `baru_progression.missoes_
    // resgatadas`, com o período dentro da chave; o `check` daquela tabela
    // ainda só aceita duas das 17 missões que existem hoje. Ver migration 16.
  }

  Future<void> pushProgression(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await _upsertTolerante(
      'baru_progression',
      _codec.progressionRow(userId: uid, s: snapshot),
    );
  }

  Future<void> pushSubscription(AppSnapshot snapshot) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    await _upsertTolerante(
      'baru_subscriptions',
      _codec.subscriptionRow(userId: uid, s: snapshot),
    );
  }

  Future<void> pushSessions(List<SessionRecord> sessions) async {
    final uid = _uid;
    final client = _client;
    if (!_ready || uid == null || client == null) return;
    if (sessions.isEmpty) return;
    // Uma chamada, não uma por sessão: o snapshot guarda até 80.
    await client.from('baru_sessions').upsert(
          sessions.map((s) => _codec.sessionRow(userId: uid, s: s)).toList(),
        );
  }

  Future<RemotePullResult> pullSnapshotResult() async {
    if (!_ready) {
      return const RemotePullResult(error: 'offline');
    }
    final uid = _uid;
    final client = _client;
    if (uid == null || client == null) {
      return const RemotePullResult(error: 'no_session');
    }
    try {
      final profile = await client
          .from('baru_profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (profile == null) return const RemotePullResult();

      final profileMap = Map<String, dynamic>.from(profile);

      if (profileMap.containsKey('species') || profileMap.containsKey('leaves')) {
        final legacy = await _pullLegacy(uid, profileMap);
        return RemotePullResult(snapshot: legacy);
      }

      // Onze consultas independentes: em série, o login esperava a soma de
      // todas as latências. Nenhuma depende do resultado da outra.
      final linhas = await Future.wait([
        _maybeSingle('baru_pets', uid),
        _maybeSingle('baru_onboarding_answers', uid),
        _maybeSingle('baru_wallets', uid),
        _maybeSingle('baru_settings', uid),
        _maybeSingle('baru_screen_time', uid),
        _maybeSingle('baru_streaks', uid),
        _maybeSingle('baru_daily_progress', uid),
        _maybeSingle('baru_subscriptions', uid),
        _maybeSingle('baru_progression', uid),
      ]);
      final pet = linhas[0];
      final onboarding = linhas[1];
      final wallet = linhas[2];
      final settings = linhas[3];
      final screenTime = linhas[4];
      final streak = linhas[5];
      final daily = linhas[6];
      final subscription = linhas[7];
      final progresso = linhas[8];

      final listas = await Future.wait([
        _lerInventario(uid),
        client
            .from('baru_week_calendar')
            .select('day_index, kind')
            .eq('user_id', uid)
            .order('day_index'),
        client
            .from('baru_app_categories')
            .select('package_name, category')
            .eq('user_id', uid),
      ]);
      final inventory = _mapas(listas[0]);
      final week = _mapas(listas[1]);
      final categorias = _mapas(listas[2]);

      final sessions = await _pullSessions(uid);

      return RemotePullResult(
        snapshot: _codec.fromRows(
          profile: profileMap,
          pet: pet,
          onboarding: onboarding,
          wallet: wallet,
          settings: settings,
          screenTime: screenTime,
          streak: streak,
          daily: daily,
          subscription: subscription,
          progresso: progresso,
          inventory: inventory,
          week: week,
          sessions: sessions,
          appCategories: categorias,
        ),
      );
    } catch (e) {
      debugPrint('Baru: leitura remota falhou ($e)');
      return RemotePullResult(error: e.toString());
    }
  }

  Future<AppSnapshot?> pullSnapshot() async {
    final r = await pullSnapshotResult();
    return r.snapshot;
  }

  Future<AppSnapshot?> _pullLegacy(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    final client = _client!;
    final rawSessions = await client
        .from('baru_sessions')
        .select()
        .eq('user_id', uid)
        .order('started_at');
    final sessions = (rawSessions as List)
        .whereType<Map>()
        .map((e) => _codec.sessionFromRow(Map<String, dynamic>.from(e)))
        .toList();
    return _codec.fromLegacyProfile(profile, sessions);
  }

  /// Lê o inventário **com** o `equipped`, e sem ele contra banco atrasado.
  ///
  /// A leitura pedia só `item_id`. Com a chave ausente do mapa, o codec caía
  /// na regra "nulo também vale por em uso" — escrita para linha antiga, não
  /// para coluna não pedida — e devolvia **todo** item possuído como em uso.
  /// Como o remoto ganha do local quando vem não-vazio, tirar um item do
  /// habitat não sobrevivia ao arranque seguinte: `equipped` era escrito e
  /// nunca lido.
  ///
  /// A queda para `item_id` mantém o app funcionando contra um banco sem a
  /// migration 11 — ali o "em uso" continua só no aparelho, que é o
  /// comportamento que a escrita já tinha.
  Future<List<Map<String, dynamic>>> _lerInventario(String uid) async {
    final client = _client!;
    Future<List<Map<String, dynamic>>> pede(String colunas) async {
      final r = await client
          .from('baru_inventory_items')
          .select(colunas)
          .eq('user_id', uid)
          .order('acquired_at');
      return _mapas(r);
    }

    if (_colunasSemRemoto.contains(_equipped)) return pede('item_id');
    try {
      return await pede('item_id, equipped');
    } catch (e) {
      final ausente = ColunaAusenteNoRemoto.de(e);
      if (ausente?.coluna != 'equipped') rethrow;
      _colunasSemRemoto.add(_equipped);
      debugPrint(
        'Baru: sem `equipped` no remoto — o inventário volta inteiro, o "em '
        'uso" fica com o aparelho até a migração 11 ser aplicada.',
      );
      return pede('item_id');
    }
  }

  List<Map<String, dynamic>> _mapas(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>?> _maybeSingle(String table, String uid) async {
    final row = await _client!
        .from(table)
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return Map<String, dynamic>.from(row);
  }

  Future<List<SessionRecord>> _pullSessions(String uid) async {
    final rawSessions = await _client!
        .from('baru_sessions')
        .select()
        .eq('user_id', uid)
        .order('started_at');
    return (rawSessions as List)
        .whereType<Map>()
        .map((e) => _codec.sessionFromRow(Map<String, dynamic>.from(e)))
        .toList();
  }
}
