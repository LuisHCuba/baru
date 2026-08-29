import 'dart:io';

import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/row_codec.dart';
import 'package:baru_app/data/supabase_gateway.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// **A ida e a volta inteira, e o teste que impede o próximo buraco.**
///
/// O defeito que se repetiu três vezes neste projeto: alguém acrescenta um
/// campo ao [AppSnapshot], o app grava e lê do disco sem problema, e a
/// sincronização simplesmente não leva o campo — porque `BaruRowCodec` não
/// ganhou a linha correspondente. Não quebra nada, não avisa nada, e o dado
/// some quando a pessoa troca de aparelho. Foi assim com `missoes_resgatadas`
/// e com os totais da trilha (migration 10), e depois com `som` e os
/// contadores de missão.
///
/// Aqui a lista de campos não é escrita à mão em cada `expect`: ela sai do
/// próprio `toJson()`. Campo novo aparece sozinho e **quebra** o primeiro
/// teste até alguém decidir de que lado ele fica — sincroniza, ou fica no
/// aparelho com uma razão escrita.

const _codec = BaruRowCodec();

/// Campos que **têm** de sobreviver à ida e volta pelas linhas do banco.
const _sincronizados = <String>{
  // baru_profiles
  'screen', 'onb', 'lang', 'companionshipStarted', 'lastOpenDate',
  // baru_pets
  'species', 'petName', 'color', 'sexo',
  // baru_onboarding_answers
  'q0', 'q1', 'q2', 'respostasDoQuiz',
  // baru_wallets
  'leaves',
  // baru_inventory_items
  'owned', 'equipados',
  // baru_settings
  'evening', 'eveningHour', 'eveningMinute', 'missed', 'usageAccess', 'dur',
  'som',
  // baru_screen_time
  'usage', 'goal', 'avg',
  // baru_streaks + baru_week_calendar
  'streak', 'todayIndex', 'freezesLeft', 'daysAway', 'week',
  // baru_daily_progress
  'completedToday', 'abandonedToday',
  // baru_subscriptions
  'trial', 'payPlan', 'trialStartedAt',
  // baru_app_categories
  'ajustesDeCategoria',
  // baru_sessions
  'sessions',
  // baru_progression
  'xp', 'afeto', 'carinhosHoje', 'nivelCelebrado', 'sessoesConcluidas',
  'melhorSequencia', 'diasAbaixoDaMeta', 'marcosResgatados',
  'missoesResgatadas', 'diasAbaixoNaSemana',
  // recalculados de baru_sessions — sem coluna de propósito
  'minutosDeFocoHoje', 'maiorSessaoHoje', 'sessoesNaSemana', 'minutosNaSemana',
};

/// Campos que ficam no aparelho, e a razão de cada um.
///
/// A razão é parte do teste: quem acrescentar um campo aqui tem de saber
/// dizer por que ele não é do usuário-entre-aparelhos.
const _locaisPorDesenho = <String, String>{
  'sessionStartedAt': 'sessão de foco não continua em outro aparelho',
  'sessionEndsAt': 'sessão de foco não continua em outro aparelho',
  'sessionDur': 'sessão de foco não continua em outro aparelho',
  'descansoComecouEm': 'a tentativa de descanso é do aparelho que está na mão',
  'descansoTelaNoInicio': 'medida de tela do aparelho que está na mão',
  'descansoNoAppSegundos': 'medida de tela do aparelho que está na mão',
  'melhorDescansoMinutos': 'zera à meia-noite; não faz sentido no servidor',
};

final _agora = DateTime.now();
final _hoje = DateTime(_agora.year, _agora.month, _agora.day);

DateTime _hojeAs(int hora, int minuto) =>
    DateTime(_hoje.year, _hoje.month, _hoje.day, hora, minuto);

/// Um snapshot com valor **não-padrão** em cada campo sincronizado.
///
/// Valor padrão dos dois lados passaria por coincidência: uma coluna
/// esquecida devolveria o mesmo zero que o original tinha, e o teste diria
/// que o round-trip funcionou.
AppSnapshot _cheio() => AppSnapshot(
      screen: AppScreen.trilha,
      onb: 5,
      lang: 'es',
      species: Species.fox,
      q0: 'a_rio',
      q1: 'a_tarde',
      q2: 'a_rotina',
      leaves: 137,
      streak: 9,
      usage: 84,
      goal: 120,
      avg: 300,
      petName: 'Rio',
      color: 3,
      owned: const ['lily', 'bamboo', 'rock'],
      equipados: const ['lily', 'rock'],
      dur: 50,
      completedToday: 2,
      abandonedToday: true,
      daysAway: 4,
      trial: true,
      evening: false,
      eveningHour: 22,
      eveningMinute: 30,
      sexo: Sexo.femea,
      som: false,
      respostasDoQuiz: const {'q_agua': 'a_rio', 'q_hora': 'a_tarde'},
      missed: false,
      payPlan: PayPlan.monthly,
      usageAccess: true,
      companionshipStarted: true,
      week: const [
        WeekDayKind.present,
        WeekDayKind.frozen,
        WeekDayKind.today,
        WeekDayKind.empty,
        WeekDayKind.present,
        WeekDayKind.empty,
        WeekDayKind.empty,
      ],
      todayIndex: 2,
      freezesLeft: 0,
      // Local, e não `DateTime.utc`: é o que `DateTime.now()` produz no app,
      // e é justamente o caso em que o instante se perdia na escrita.
      trialStartedAt: DateTime(2026, 8, 20, 9, 15),
      lastOpenDate: _hoje,
      sessions: [
        SessionRecord(
          id: '11111111-1111-1111-1111-111111111111',
          at: _hojeAs(9, 30),
          dur: 50,
          completed: true,
          aborted: false,
          reward: 25,
        ),
        SessionRecord(
          id: '22222222-2222-2222-2222-222222222222',
          at: _hojeAs(14, 0),
          dur: 25,
          completed: true,
          aborted: false,
          reward: 12,
        ),
        // Abortada: não pode entrar em contador de missão nenhum.
        SessionRecord(
          id: '33333333-3333-3333-3333-333333333333',
          at: _hojeAs(16, 0),
          dur: 45,
          completed: false,
          aborted: true,
          reward: 0,
        ),
      ],
      ajustesDeCategoria: const {
        'com.google.android.youtube': 'produtivo',
        'com.whatsapp': 'dispersivo',
      },
      xp: 420,
      afeto: 63,
      carinhosHoje: 3,
      sessoesConcluidas: 31,
      melhorSequencia: 12,
      diasAbaixoDaMeta: 18,
      marcosResgatados: const ['primeiro_foco', 'nivel_3'],
      nivelCelebrado: 4,
      // As contas que as três sessões acima obrigam: 50 + 25, a maior é 50, e
      // a abortada de 45 min não conta em nenhuma.
      minutosDeFocoHoje: 75,
      maiorSessaoHoje: 50,
      sessoesNaSemana: 2,
      minutosNaSemana: 75,
      diasAbaixoNaSemana: 2,
      missoesResgatadas: const [
        'um_foco@2026-08-26',
        'semana_dez_focos@2026-W35',
      ],
      // Locais por desenho: entram preenchidos para provar que **não** voltam.
      sessionStartedAt: _hojeAs(20, 0),
      sessionEndsAt: _hojeAs(20, 50),
      sessionDur: 50,
      descansoComecouEm: _hojeAs(19, 0),
      descansoTelaNoInicio: 77,
      descansoNoAppSegundos: 120,
      melhorDescansoMinutos: 41,
    );

/// A volta: decompõe em linhas como o push faz, e remonta como o pull faz.
AppSnapshot _daIdaEVolta(AppSnapshot s, {DateTime? agora}) {
  const uid = '11111111-1111-1111-1111-111111111111';
  return _codec.fromRows(
    profile: _codec.profileRow(userId: uid, deviceId: 'dev', s: s),
    pet: _codec.petRow(userId: uid, s: s),
    onboarding: _codec.onboardingRow(userId: uid, s: s),
    wallet: _codec.walletRow(userId: uid, s: s),
    settings: _codec.settingsRow(userId: uid, s: s),
    screenTime: _codec.screenTimeRow(userId: uid, s: s),
    streak: _codec.streakRow(userId: uid, s: s),
    daily: _codec.dailyProgressRow(userId: uid, s: s),
    subscription: _codec.subscriptionRow(userId: uid, s: s),
    progresso: _codec.progressionRow(userId: uid, s: s),
    inventory: _codec.inventoryRows(userId: uid, s: s),
    week: _codec.weekRows(userId: uid, s: s),
    appCategories: _codec.appCategoryRows(userId: uid, s: s),
    sessions: s.sessions
        .map((e) => _codec.sessionFromRow(_codec.sessionRow(userId: uid, s: e)))
        .toList(),
    agora: agora ?? _agora,
  );
}

void main() {
  group('nenhum campo do snapshot fica sem decisão', () {
    test('todo campo ou sincroniza, ou tem razão escrita para não sincronizar',
        () {
      final campos = _cheio().toJson().keys.toSet()..remove('v');
      final classificados = {..._sincronizados, ..._locaisPorDesenho.keys};

      expect(
        campos.difference(classificados),
        isEmpty,
        reason: 'campo novo no AppSnapshot sem decisão. Ou entra em '
            '`_sincronizados` — e aí o teste de ida e volta passa a exigir '
            'que ele volte inteiro, o que costuma pedir coluna nova — ou '
            'entra em `_locaisPorDesenho` com a razão de ficar no aparelho.',
      );
      expect(
        classificados.difference(campos),
        isEmpty,
        reason: 'campo classificado que não existe mais no snapshot',
      );
      expect(
        _sincronizados.intersection(_locaisPorDesenho.keys.toSet()),
        isEmpty,
        reason: 'um campo não pode ser as duas coisas',
      );
    });

    test('a fixture não tem valor padrão em campo nenhum', () {
      // Sem isto o round-trip passaria por coincidência: uma coluna esquecida
      // devolveria o mesmo padrão que o original já tinha.
      final cheio = _cheio().toJson();
      final zerado = AppSnapshot.zerado().toJson();
      final iguais = _sincronizados
          .where((k) => '${cheio[k]}' == '${zerado[k]}')
          // `todayIndex` e `lastOpenDate` são do dia de hoje nos dois; não há
          // valor "diferente do padrão" que continue coerente com a semana.
          .where((k) => k != 'todayIndex' && k != 'lastOpenDate')
          .toList();
      expect(iguais, isEmpty, reason: 'campos indistinguíveis do padrão');
    });
  });

  group('a ida e a volta pelas linhas do banco', () {
    test('todo campo sincronizado volta idêntico', () {
      final ida = _cheio();
      final volta = _daIdaEVolta(ida);

      final antes = ida.toJson();
      final depois = volta.toJson();
      for (final campo in _sincronizados) {
        expect(
          depois[campo],
          antes[campo],
          reason: '`$campo` não sobreviveu à ida e volta pelo banco',
        );
      }
    });

    test('o que é local por desenho não volta', () {
      final volta = _daIdaEVolta(_cheio());
      final depois = volta.toJson();
      final zerado = AppSnapshot.zerado().toJson();
      for (final e in _locaisPorDesenho.entries) {
        expect(
          depois[e.key],
          zerado[e.key],
          reason: '`${e.key}` voltou do banco, e não devia: ${e.value}',
        );
      }
    });

    test('o instante vai com fuso explícito na string', () {
      // `DateTime.now()` é local e o ISO dele sai **sem** fuso; o Postgres
      // então assume UTC e o instante escorrega pelo tamanho do fuso de quem
      // focou — o bastante para a sessão cair no dia anterior e sumir das
      // missões do dia.
      //
      // A asserção é sobre a **string**, não sobre o valor: num computador
      // rodando em UTC a diferença some, e o teste passaria sem provar nada.
      final s = _cheio();
      expect(
        '${_codec.sessionRow(userId: 'u', s: s.sessions.first)['started_at']}',
        endsWith('Z'),
      );
      expect(
        '${_codec.subscriptionRow(userId: 'u', s: s)['trial_started_at']}',
        endsWith('Z'),
      );
    });

    test('e volta local, que é com o que o resto do app compara', () {
      final volta = _daIdaEVolta(_cheio());
      final original = _cheio().sessions.first;
      final devolvida = volta.sessions.firstWhere((e) => e.id == original.id);
      expect(devolvida.at, original.at);
      expect(devolvida.at.isUtc, isFalse);
      expect(volta.trialStartedAt, _cheio().trialStartedAt);
      expect(volta.trialStartedAt?.isUtc, isFalse);
    });
  });

  group('os contadores de missão, refeitos das sessões', () {
    SessionRecord sessao(DateTime em, int dur, {bool completed = true}) =>
        SessionRecord(
          id: '$em-$dur-$completed',
          at: em,
          dur: dur,
          completed: completed,
          aborted: !completed,
          reward: 0,
        );

    // Uma quarta-feira: a semana tem dias antes e depois de "hoje".
    final quarta = DateTime(2026, 8, 26, 15);
    final segunda = DateTime(2026, 8, 24, 8);
    final domingoAnterior = DateTime(2026, 8, 23, 20);

    test('só a semana corrente entra, e só o dia de hoje conta como hoje', () {
      final c = BaruRowCodec.contadoresDe(
        [
          sessao(segunda, 30),
          sessao(DateTime(2026, 8, 26, 9), 50),
          sessao(DateTime(2026, 8, 26, 14), 25),
          sessao(domingoAnterior, 90),
        ],
        agora: quarta,
      );
      expect(c.minutosHoje, 75);
      expect(c.maiorSessaoHoje, 50);
      expect(c.sessoesNaSemana, 3, reason: 'segunda e as duas de quarta');
      expect(c.minutosNaSemana, 105);
    });

    test('sessão abortada não conta em nada', () {
      final c = BaruRowCodec.contadoresDe(
        [sessao(DateTime(2026, 8, 26, 9), 50, completed: false)],
        agora: quarta,
      );
      expect(c.minutosHoje, 0);
      expect(c.sessoesNaSemana, 0);
      expect(c.minutosNaSemana, 0);
    });

    test('a janela é a de quem lê: o contador zera sozinho na semana nova', () {
      // A mesma sessão de segunda, lida na segunda seguinte. Nenhum aparelho
      // precisou empurrar o zero.
      final sessoes = [sessao(segunda, 30)];
      expect(
        BaruRowCodec.contadoresDe(sessoes, agora: quarta).sessoesNaSemana,
        1,
      );
      expect(
        BaruRowCodec.contadoresDe(
          sessoes,
          agora: DateTime(2026, 8, 31, 10),
        ).sessoesNaSemana,
        0,
      );
    });

    test('a segunda-feira é a âncora, e domingo ainda é a mesma semana', () {
      expect(BaruRowCodec.segundaDe(quarta), DateTime(2026, 8, 24));
      expect(
        BaruRowCodec.segundaDe(DateTime(2026, 8, 30, 23, 59)),
        DateTime(2026, 8, 24),
        reason: 'domingo fecha a semana que começou na segunda',
      );
      expect(
        BaruRowCodec.segundaDe(DateTime(2026, 8, 31)),
        DateTime(2026, 8, 31),
      );
      expect(
        BaruRowCodec.segundaDe(DateTime(2026, 9, 2)),
        DateTime(2026, 8, 31),
        reason: 'a semana atravessa a virada do mês',
      );
    });
  });

  group('`dias_abaixo_na_semana` só vale para a semana que o carimbou', () {
    Map<String, dynamic> progressoCom(String semanaDe, int dias) => {
          'dias_abaixo_na_semana': dias,
          'semana_de': semanaDe,
        };

    AppSnapshot lido(Map<String, dynamic>? progresso, DateTime agora) =>
        _codec.fromRows(
          profile: const {'screen': 'home', 'onb': 5},
          progresso: progresso,
          agora: agora,
        );

    test('carimbo da semana corrente devolve o número', () {
      final s = lido(progressoCom('2026-08-24', 3), DateTime(2026, 8, 26));
      expect(s.diasAbaixoNaSemana, 3);
    });

    test('carimbo de semana vencida devolve zero', () {
      // A zeragem da segunda acontece no aparelho e não marca sincronização:
      // o remoto continua com o número velho. Sem o carimbo, a semana nova
      // começaria com a missão semanal meio cumprida de graça.
      final s = lido(progressoCom('2026-08-24', 3), DateTime(2026, 8, 31));
      expect(s.diasAbaixoNaSemana, 0);
    });

    test('sem carimbo devolve zero, e não o número solto', () {
      final s = lido(
        const {'dias_abaixo_na_semana': 3},
        DateTime(2026, 8, 26),
      );
      expect(s.diasAbaixoNaSemana, 0);
    });

    test('o carimbo escrito é sempre a segunda-feira de `lastOpenDate`', () {
      final linha = _codec.progressionRow(
        userId: 'u',
        s: _cheio().copyWith(
          lastOpenDate: DateTime(2026, 8, 28),
          diasAbaixoNaSemana: 4,
        ),
      );
      expect(linha['semana_de'], '2026-08-24');
      expect(linha['dias_abaixo_na_semana'], 4);
    });
  });

  group('o app funciona antes de a migração ser aplicada', () {
    test('a coluna recusada sai do corpo, e o resto da linha sobe', () {
      // A promessa da degradação: perder `som` não pode custar a duração
      // padrão, as notificações e a permissão de uso, que iam na mesma
      // escrita e são dado que o usuário acabou de produzir.
      final linha = _codec.settingsRow(userId: 'u', s: _cheio());
      final corpo = BaruSupabase.semAsAusentes(
        'baru_settings',
        linha,
        {'baru_settings.som'},
      );
      expect(corpo.containsKey('som'), isFalse);
      expect(corpo['default_duration_min'], 50);
      expect(corpo['usage_access'], isTrue);
      expect(corpo['evening_hour'], 22);
      expect(corpo['user_id'], 'u');
      expect(corpo.length, linha.length - 1, reason: 'só a recusada sai');
    });

    test('a marca é por tabela: `som` de outra tabela não seria tirada', () {
      final corpo = BaruSupabase.semAsAusentes(
        'baru_settings',
        const {'user_id': 'u', 'som': false},
        {'baru_outra_tabela.som'},
      );
      expect(corpo['som'], isFalse);
    });

    test('sem a coluna `som`, o som fica ligado — nunca desligado sozinho', () {
      final s = _codec.fromRows(
        profile: const {'screen': 'home', 'onb': 5},
        settings: const {'default_duration_min': 50},
        agora: _agora,
      );
      expect(s.som, isTrue);
    });

    test('sem as colunas da semana, o contador vale zero e nada estoura', () {
      final s = _codec.fromRows(
        profile: const {'screen': 'home', 'onb': 5},
        progresso: const {'xp': 10},
        agora: _agora,
      );
      expect(s.diasAbaixoNaSemana, 0);
      expect(s.xp, 10);
    });

    test('leitura sem `equipped` não tem opinião: o "em uso" fica com o local',
        () {
      // Este era o defeito: o `select` pedia só `item_id`, o codec lia a
      // ausência da chave como "em uso", e o remoto — não-vazio — ganhava do
      // local. Tirar um item do habitat não sobrevivia ao arranque seguinte.
      final semColuna = _codec.fromRows(
        profile: const {'screen': 'home', 'onb': 5},
        inventory: const [
          {'item_id': 'lily'},
          {'item_id': 'rock'},
        ],
        agora: _agora,
      );
      expect(semColuna.owned, ['lily', 'rock'], reason: 'o inventário volta');
      expect(
        semColuna.equipados,
        isEmpty,
        reason: 'sem a coluna o remoto não sabe o que está em uso',
      );

      final local = _cheio().copyWith(equipados: const ['rock']);
      expect(
        semColuna.fundeCom(local).equipados,
        ['rock'],
        reason: 'e por isso a fusão mantém o que o aparelho sabia',
      );
    });

    test('com `equipped`, o que foi tirado continua tirado', () {
      final s = _codec.fromRows(
        profile: const {'screen': 'home', 'onb': 5},
        inventory: const [
          {'item_id': 'lily', 'equipped': true},
          {'item_id': 'rock', 'equipped': false},
        ],
        agora: _agora,
      );
      expect(s.owned, ['lily', 'rock']);
      expect(s.equipados, ['lily']);
    });

    test('linha antiga com `equipped` nulo continua valendo por "em uso"', () {
      // É o `default true` da migration 11: quem comprou quando comprar era o
      // mesmo que colocar não pode ver o habitat esvaziar.
      final s = _codec.fromRows(
        profile: const {'screen': 'home', 'onb': 5},
        inventory: const [
          {'item_id': 'lily', 'equipped': null},
          {'item_id': 'rock', 'equipped': false},
        ],
        agora: _agora,
      );
      expect(s.equipados, ['lily']);
    });
  });

  group('a fusão depois que o remoto passou a guardar a janela', () {
    test('reinstalar o app recupera o progresso do dia e da semana', () {
      // O caso que motivou tudo: o aparelho é novo, o local é zero, e as
      // sessões já estão no remoto. "Local sempre ganha" devolvia zero.
      final remoto = _daIdaEVolta(_cheio());
      final local = AppSnapshot.zerado();

      final f = remoto.fundeCom(local);

      expect(f.minutosDeFocoHoje, 75);
      expect(f.maiorSessaoHoje, 50);
      expect(f.sessoesNaSemana, 2);
      expect(f.minutosNaSemana, 75);
      expect(f.diasAbaixoNaSemana, 2);
    });

    test('o aparelho com sessão ainda não empurrada não perde a conta', () {
      final remoto = _daIdaEVolta(_cheio());
      final local = _cheio().copyWith(
        minutosDeFocoHoje: 125,
        maiorSessaoHoje: 50,
        sessoesNaSemana: 3,
        minutosNaSemana: 125,
        diasAbaixoNaSemana: 3,
      );

      final f = remoto.fundeCom(local);

      expect(f.minutosDeFocoHoje, 125);
      expect(f.sessoesNaSemana, 3);
      expect(f.minutosNaSemana, 125);
      expect(f.diasAbaixoNaSemana, 3);
    });

    test('a sessão em curso continua sendo só do aparelho que a roda', () {
      final remoto = _daIdaEVolta(_cheio());
      final local = _cheio();
      final f = remoto.fundeCom(local);
      expect(f.sessionStartedAt, local.sessionStartedAt);
      expect(f.melhorDescansoMinutos, local.melhorDescansoMinutos);
    });
  });

  group('o codec e o schema falam a mesma língua', () {
    /// Toda coluna que alguma migration cria ou acrescenta, por tabela.
    Map<String, Set<String>> colunasDoSchema() {
      final dir = Directory('supabase/migrations');
      final sql = (dir.listSync().whereType<File>().toList()
            ..sort((a, b) => a.path.compareTo(b.path)))
          .map((f) => f.readAsStringSync())
          .join('\n');
      final out = <String, Set<String>>{};

      final criacao = RegExp(
        r'create table if not exists public\.(\w+)\s*\(([\s\S]*?)\n\);',
      );
      for (final m in criacao.allMatches(sql)) {
        final colunas = <String>{};
        for (final linha in m.group(2)!.split('\n')) {
          final n = RegExp(r'^\s{2}(\w+)\s').firstMatch(linha);
          // `primary key (...)` e `check (...)` também começam com dois
          // espaços; nenhum dos dois é nome de coluna.
          if (n != null && !const {'primary', 'check', 'unique', 'foreign'}
              .contains(n.group(1))) {
            colunas.add(n.group(1)!);
          }
        }
        out.putIfAbsent(m.group(1)!, () => <String>{}).addAll(colunas);
      }

      final acrescimo = RegExp(
        r'alter table public\.(\w+)([\s\S]*?);',
      );
      for (final m in acrescimo.allMatches(sql)) {
        final nova = RegExp(r'add column if not exists (\w+)');
        for (final c in nova.allMatches(m.group(2)!)) {
          out.putIfAbsent(m.group(1)!, () => <String>{}).add(c.group(1)!);
        }
      }
      return out;
    }

    /// Toda coluna que o codec escreve, por tabela.
    Map<String, Set<String>> colunasDoCodec() {
      final s = _cheio();
      const uid = 'u';
      final sessao = s.sessions.first;
      return {
        'baru_profiles':
            _codec.profileRow(userId: uid, deviceId: 'd', s: s).keys.toSet(),
        'baru_pets': _codec.petRow(userId: uid, s: s).keys.toSet(),
        'baru_onboarding_answers':
            _codec.onboardingRow(userId: uid, s: s).keys.toSet(),
        'baru_wallets': _codec.walletRow(userId: uid, s: s).keys.toSet(),
        'baru_settings': _codec.settingsRow(userId: uid, s: s).keys.toSet(),
        'baru_screen_time':
            _codec.screenTimeRow(userId: uid, s: s).keys.toSet(),
        'baru_streaks': _codec.streakRow(userId: uid, s: s).keys.toSet(),
        'baru_daily_progress':
            _codec.dailyProgressRow(userId: uid, s: s).keys.toSet(),
        'baru_subscriptions':
            _codec.subscriptionRow(userId: uid, s: s).keys.toSet(),
        'baru_progression':
            _codec.progressionRow(userId: uid, s: s).keys.toSet(),
        'baru_inventory_items':
            _codec.inventoryRows(userId: uid, s: s).first.keys.toSet(),
        'baru_week_calendar':
            _codec.weekRows(userId: uid, s: s).first.keys.toSet(),
        'baru_app_categories':
            _codec.appCategoryRows(userId: uid, s: s).first.keys.toSet(),
        'baru_sessions': _codec.sessionRow(userId: uid, s: sessao).keys.toSet(),
      };
    }

    test('o codec não escreve coluna que migration nenhuma cria', () {
      // O outro lado do defeito: campo que o codec passou a mandar sem
      // migration correspondente derruba a gravação inteira daquele domínio,
      // e só no aparelho de alguém.
      final schema = colunasDoSchema();
      final faltando = <String>[];
      colunasDoCodec().forEach((tabela, colunas) {
        for (final c in colunas.difference(schema[tabela] ?? const {})) {
          faltando.add('$tabela.$c');
        }
      });
      expect(faltando, isEmpty, reason: 'coluna sem migration em nenhum lugar');
    });

    test('toda coluna acrescentada por migration está declarada opcional', () {
      // O app tem de funcionar **antes** de a migração ser aplicada. Coluna
      // que veio depois das tabelas base e não está em `colunasOpcionais` é
      // coluna que, faltando no remoto, derruba a linha inteira em vez de
      // degradar.
      final acrescentadas = <String, Set<String>>{};
      final dir = Directory('supabase/migrations');
      final sql = dir
          .listSync()
          .whereType<File>()
          .map((f) => f.readAsStringSync())
          .join('\n');
      for (final m
          in RegExp(r'alter table public\.(\w+)([\s\S]*?);').allMatches(sql)) {
        for (final c
            in RegExp(r'add column if not exists (\w+)').allMatches(m.group(2)!)) {
          acrescentadas
              .putIfAbsent(m.group(1)!, () => <String>{})
              .add(c.group(1)!);
        }
      }

      final naoDeclaradas = <String>[];
      colunasDoCodec().forEach((tabela, escritas) {
        final depois = escritas.intersection(
          acrescentadas[tabela] ?? const <String>{},
        );
        final declaradas =
            BaruSupabase.colunasOpcionais[tabela] ?? const <String>{};
        for (final c in depois.difference(declaradas)) {
          naoDeclaradas.add('$tabela.$c');
        }
      });
      expect(
        naoDeclaradas,
        isEmpty,
        reason: 'declare em `BaruSupabase.colunasOpcionais` para o push '
            'degradar em vez de falhar contra banco atrasado',
      );
    });

    test('o índice de pelagem cabe no CHECK de `baru_pets.coat`', () {
      // `check (coat >= 0 and coat <= 8)`. O app prende o índice ao tamanho
      // da paleta **da espécie**, então hoje o máximo é 5 e sobram três. Uma
      // paleta de dez tons deixaria `setColor(9)` passar no app e o banco
      // recusaria a linha inteira — nome, espécie e sexo do bicho junto — com
      // um "erro ao sincronizar" que não diz nada.
      const tetoDoCheck = 8;
      for (final e in Species.values) {
        expect(
          AppColors.coatDe(e).length - 1,
          lessThanOrEqualTo(tetoDoCheck),
          reason: 'a paleta de ${e.name} passou do que `coat` aceita: ou a '
              'paleta encolhe, ou entra migration ampliando o CHECK',
        );
      }
    });
  });
}
