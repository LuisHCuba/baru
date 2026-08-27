@Tags(['integracao'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/row_codec.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

/// Round-trip real contra um Supabase de verdade.
///
/// Os testes unitários provam a lógica do app; nenhum deles prova que
/// `BaruRowCodec` fala a mesma língua que o schema. Uma coluna renomeada, um
/// CHECK que o app viola, um tipo incompatível — nada disso aparece até o
/// primeiro usuário sincronizar.
///
/// Este arquivo sobe um usuário de verdade pelo endpoint de auth, escreve as
/// 13 tabelas com o token dele (o que também exercita RLS como usuário comum)
/// e reconstrói o snapshot pela leitura.
///
/// Precisa do stack local:
///
///     supabase start
///     flutter test test/integration \
///       --dart-define=BARU_TEST_URL=http://127.0.0.1:54321 \
///       --dart-define=BARU_TEST_KEY=<publishable key do supabase start>
///
/// Sem as duas variáveis, os testes são pulados em vez de falharem — a suíte
/// normal não pode depender de Docker.
const _url = String.fromEnvironment('BARU_TEST_URL');
const _key = String.fromEnvironment('BARU_TEST_KEY');

const _codec = BaruRowCodec();

bool get _configurado => _url.isNotEmpty && _key.isNotEmpty;

late HttpClient _http;

Future<Map<String, dynamic>> _json(
  String metodo,
  String caminho, {
  Object? corpo,
  String? token,
  Map<String, String> extra = const {},
}) async {
  final req = await _http.openUrl(metodo, Uri.parse('$_url$caminho'));
  req.headers.set('apikey', _key);
  req.headers.set('Authorization', 'Bearer ${token ?? _key}');
  req.headers.contentType = ContentType.json;
  extra.forEach(req.headers.set);
  if (corpo != null) req.add(utf8.encode(jsonEncode(corpo)));
  final resp = await req.close();
  final texto = await resp.transform(utf8.decoder).join();
  if (resp.statusCode >= 400) {
    throw HttpException('$metodo $caminho -> ${resp.statusCode}: $texto');
  }
  if (texto.isEmpty) return const {};
  final decodificado = jsonDecode(texto);
  return decodificado is Map<String, dynamic>
      ? decodificado
      : {'lista': decodificado};
}

Future<List<Map<String, dynamic>>> _lista(
  String caminho, {
  required String token,
}) async {
  final r = await _json('GET', caminho, token: token);
  final bruto = r['lista'] as List? ?? const [];
  return bruto
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Future<void> _grava(
  String tabela,
  Object linhas, {
  required String token,
}) =>
    _json(
      'POST',
      '/rest/v1/$tabela',
      corpo: linhas is List ? linhas : [linhas],
      token: token,
      extra: {'Prefer': 'resolution=merge-duplicates'},
    );

/// Um snapshot com valor não-default em cada campo, para que uma coluna
/// esquecida no codec apareça como diferença e não como coincidência.
///
/// Os ids de sessão são sorteados a cada chamada de propósito: `baru_sessions`
/// tem `id` como chave primária **global**, então dois usuários com o mesmo id
/// de sessão colidiriam — o upsert do segundo bate na policy de UPDATE do
/// primeiro e volta 403. Com uuid v4 isso não acontece na prática; o teste
/// reproduzia o cenário por usar ids fixos entre casos.
AppSnapshot _snapshotRico() {
  final s = AppState()
    ..startCompanionship()
    ..lang = 'es'
    ..species = Species.otter
    ..petName = 'Rio'
    ..color = 2
    ..leaves = 137
    ..streak = 9
    ..usage = 84
    ..goal = 120
    ..avg = 300
    ..owned = ['lily', 'bamboo', 'rock']
    ..dur = 50
    ..completedToday = 2
    ..abandonedToday = true
    ..trial = true
    ..evening = false
    ..missed = true
    ..payPlan = PayPlan.monthly
    ..usageAccess = true
    ..freezesLeft = 0
    ..q0 = 'Agua'
    ..q1 = 'Por la tarde'
    ..q2 = 'Una rutina'
    ..onb = 5
    ..go(AppScreen.home)
    ..trialStartedAt = DateTime.utc(2026, 8, 20, 12)
    ..lastOpenDate = DateTime(2026, 8, 26)
    ..todayIndex = 2
    ..week = [
      WeekDayKind.present,
      WeekDayKind.frozen,
      WeekDayKind.today,
      WeekDayKind.empty,
      WeekDayKind.empty,
      WeekDayKind.empty,
      WeekDayKind.empty,
    ]
    ..ajustesDeCategoria = {
      'com.google.android.youtube': CategoriaDeApp.produtivo,
      'com.whatsapp': CategoriaDeApp.dispersivo,
    }
    ..sessions = [
      SessionRecord(
        id: const Uuid().v4(),
        at: DateTime.utc(2026, 8, 26, 9, 30),
        dur: 50,
        completed: true,
        aborted: false,
        reward: 25,
      ),
      SessionRecord(
        id: const Uuid().v4(),
        at: DateTime.utc(2026, 8, 26, 14),
        dur: 25,
        completed: false,
        aborted: true,
        reward: 0,
      ),
    ];
  return s.toSnapshot();
}

void main() {
  if (!_configurado) {
    test('round-trip contra Supabase real', () {}, skip: 'defina BARU_TEST_URL e BARU_TEST_KEY');
    return;
  }

  setUpAll(() {
    // flutter_test bloqueia HTTP real por padrão; aqui a rede é o teste.
    HttpOverrides.global = null;
    _http = HttpClient();
  });

  tearDownAll(() => _http.close(force: true));

  late String token;
  late String uid;
  late AppSnapshot original;

  setUp(() async {
    final marca = DateTime.now().microsecondsSinceEpoch;
    final cadastro = await _json(
      'POST',
      '/auth/v1/signup',
      corpo: {'email': 'baru+$marca@teste.local', 'password': 'senha-de-teste-123'},
    );
    token = '${cadastro['access_token']}';
    uid = '${(cadastro['user'] as Map)['id']}';
    expect(token, isNotEmpty, reason: 'signup não devolveu sessão');
    original = _snapshotRico();
  });

  Future<void> escreveTudo() async {
    await _grava(
      'baru_profiles',
      _codec.profileRow(userId: uid, deviceId: 'teste', s: original),
      token: token,
    );
    await _grava('baru_pets', _codec.petRow(userId: uid, s: original), token: token);
    await _grava('baru_onboarding_answers',
        _codec.onboardingRow(userId: uid, s: original), token: token);
    await _grava('baru_wallets', _codec.walletRow(userId: uid, s: original),
        token: token);
    await _grava('baru_inventory_items',
        _codec.inventoryRows(userId: uid, s: original), token: token);
    await _grava('baru_settings', _codec.settingsRow(userId: uid, s: original),
        token: token);
    await _grava('baru_screen_time',
        _codec.screenTimeRow(userId: uid, s: original), token: token);
    await _grava('baru_streaks', _codec.streakRow(userId: uid, s: original),
        token: token);
    await _grava('baru_week_calendar', _codec.weekRows(userId: uid, s: original),
        token: token);
    await _grava('baru_daily_progress',
        _codec.dailyProgressRow(userId: uid, s: original), token: token);
    await _grava('baru_daily_quests',
        _codec.dailyQuestRows(userId: uid, s: original), token: token);
    await _grava('baru_subscriptions',
        _codec.subscriptionRow(userId: uid, s: original), token: token);
    await _grava(
      'baru_app_categories',
      _codec.appCategoryRows(userId: uid, s: original),
      token: token,
    );
    await _grava(
      'baru_sessions',
      original.sessions.map((e) => _codec.sessionRow(userId: uid, s: e)).toList(),
      token: token,
    );
  }

  Future<AppSnapshot> lerTudo() async {
    Future<Map<String, dynamic>?> um(String t) async {
      final l = await _lista('/rest/v1/$t?user_id=eq.$uid&select=*', token: token);
      return l.isEmpty ? null : l.first;
    }

    return _codec.fromRows(
      profile: (await um('baru_profiles'))!,
      pet: await um('baru_pets'),
      onboarding: await um('baru_onboarding_answers'),
      wallet: await um('baru_wallets'),
      settings: await um('baru_settings'),
      screenTime: await um('baru_screen_time'),
      streak: await um('baru_streaks'),
      daily: await um('baru_daily_progress'),
      subscription: await um('baru_subscriptions'),
      inventory: await _lista(
        '/rest/v1/baru_inventory_items?user_id=eq.$uid&select=item_id&order=acquired_at',
        token: token,
      ),
      week: await _lista(
        '/rest/v1/baru_week_calendar?user_id=eq.$uid&select=day_index,kind&order=day_index',
        token: token,
      ),
      sessions: (await _lista(
        '/rest/v1/baru_sessions?user_id=eq.$uid&select=*&order=started_at',
        token: token,
      ))
          .map(_codec.sessionFromRow)
          .toList(),
      appCategories: await _lista(
        '/rest/v1/baru_app_categories?user_id=eq.$uid&select=package_name,category',
        token: token,
      ),
    );
  }

  test('o snapshot sobrevive à ida e volta pelas 13 tabelas', () async {
    await escreveTudo();
    final volta = await lerTudo();

    expect(volta.lang, original.lang);
    expect(volta.onb, original.onb);
    expect(volta.companionshipStarted, original.companionshipStarted);
    expect(volta.species, original.species);
    expect(volta.petName, original.petName);
    expect(volta.color, original.color);
    expect(volta.q0, original.q0);
    expect(volta.q1, original.q1);
    expect(volta.q2, original.q2);
    expect(volta.leaves, original.leaves);
    expect(volta.owned, original.owned);
    expect(volta.dur, original.dur);
    expect(volta.usage, original.usage);
    expect(volta.goal, original.goal);
    expect(volta.avg, original.avg);
    expect(volta.evening, original.evening);
    expect(volta.missed, original.missed);
    expect(volta.usageAccess, original.usageAccess);
    expect(volta.streak, original.streak);
    expect(volta.todayIndex, original.todayIndex);
    expect(volta.freezesLeft, original.freezesLeft);
    expect(volta.daysAway, original.daysAway);
    expect(volta.week, original.week);
    expect(volta.completedToday, original.completedToday);
    expect(volta.abandonedToday, original.abandonedToday);
    expect(volta.trial, original.trial);
    expect(volta.payPlan, original.payPlan);
    expect(
      volta.trialStartedAt?.toUtc(),
      original.trialStartedAt?.toUtc(),
    );
    expect(
      AppSnapshot.dayString(volta.lastOpenDate),
      AppSnapshot.dayString(original.lastOpenDate),
    );
  });

  test('as reclassificações de app voltam intactas', () async {
    await escreveTudo();
    final volta = await lerTudo();

    expect(volta.ajustesDeCategoria['com.google.android.youtube'], 'produtivo');
    expect(volta.ajustesDeCategoria['com.whatsapp'], 'dispersivo');
    expect(volta.ajustesDeCategoria.length, 2, reason: 'nem a mais nem a menos');
  });

  test('o CHECK recusa categoria fora das quatro', () async {
    await expectLater(
      _grava(
        'baru_app_categories',
        {
          'user_id': uid,
          'package_name': 'com.exemplo',
          'category': 'produtivissimo',
        },
        token: token,
      ),
      throwsA(isA<HttpException>()),
    );
  });

  test('as sessões voltam com id, duração, resultado e recompensa', () async {
    await escreveTudo();
    final volta = await lerTudo();

    expect(volta.sessions.length, 2);
    final completa = volta.sessions.firstWhere((e) => e.completed);
    final abortada = volta.sessions.firstWhere((e) => e.aborted);
    expect(completa.dur, 50);
    expect(completa.reward, 25);
    expect(abortada.dur, 25);
    expect(abortada.reward, 0);
    expect(
      volta.sessions.map((e) => e.id).toSet(),
      original.sessions.map((e) => e.id).toSet(),
    );
  });

  test('reescrever o mesmo estado é idempotente', () async {
    await escreveTudo();
    await escreveTudo();
    final volta = await lerTudo();

    expect(volta.leaves, original.leaves);
    expect(volta.owned, original.owned, reason: 'o inventário não pode duplicar');
    expect(volta.sessions.length, 2, reason: 'as sessões não podem duplicar');
  });

  test('o usuário não enxerga dado de outro usuário', () async {
    await escreveTudo();

    final outro = await _json(
      'POST',
      '/auth/v1/signup',
      corpo: {
        'email': 'baru+intruso${DateTime.now().microsecondsSinceEpoch}@teste.local',
        'password': 'senha-de-teste-123',
      },
    );
    final tokenIntruso = '${outro['access_token']}';

    for (final tabela in [
      'baru_profiles',
      'baru_wallets',
      'baru_sessions',
      'baru_inventory_items',
      'baru_subscriptions',
      'baru_app_categories',
    ]) {
      final visto = await _lista(
        '/rest/v1/$tabela?select=user_id',
        token: tokenIntruso,
      );
      expect(
        visto.where((r) => '${r['user_id']}' == uid),
        isEmpty,
        reason: 'RLS deixou vazar $tabela',
      );
    }
  });

  test('o CHECK do banco recusa valor fora do contrato', () async {
    await _grava(
      'baru_profiles',
      _codec.profileRow(userId: uid, deviceId: 'teste', s: original),
      token: token,
    );
    await expectLater(
      _grava(
        'baru_pets',
        {'user_id': uid, 'species': 'dragao', 'pet_name': 'X', 'coat': 0},
        token: token,
      ),
      throwsA(isA<HttpException>()),
      reason: 'espécie fora das quatro do contrato tem de ser recusada',
    );
  });
}
