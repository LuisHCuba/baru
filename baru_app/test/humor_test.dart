import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_humor.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/home_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fala do humor: todo humor tem de dizer **a causa, com o número medido**.
///
/// O defeito que originou este arquivo: "{n} sentiu sua falta." cabia em duas
/// causas opostas — sumir três dias e desistir de uma sessão hoje — e não
/// dizia nenhuma das duas. O teste que faltava era o que exige o fato na
/// tela, não só que a tela abra.
///
/// A armadilha coberta aqui: `moodCap`/`moodSub` **degradam para vazio** numa
/// busca por id que não existe, e `T.s` devolve a própria chave. Nas duas, um
/// texto faltando some ou vira lixo em vez de estourar. Por isso os testes de
/// catálogo abaixo exigem a chave no mapa cru, e não só que o acessor
/// devolva algo.

/// Todo id de fala que a regra pode escolher. É especificação, não espelho:
/// está escrito à mão para que um id novo sem texto quebre aqui.
const _idsEsperados = <String>{
  // missing_you
  'ausenciaComRaiz',
  'ausencia',
  'desistencia',
  'desistenciaSemMinutos',
  'saudade',
  // radiant
  'radianteRecorde',
  'radianteVolta',
  'radianteSemMedicao',
  'radianteAbaixo',
  'radiante',
  // content
  'contenteVolta',
  'contenteSemMedicao',
  'contenteAcima',
  'contenteNaMeta',
  'contenteAbaixo',
  'contente',
  // neutral
  'neutroNaMeta',
  'neutroAcima',
  'neutro',
  // sleepy
  'soneDispersivo',
  'soneAcima',
  'sone',
};

/// As falas que **só** o `overrideMood` do painel de depuração alcança: a
/// regra do §3 nunca produz fatos que caiam nelas. Existem para que um humor
/// forçado não cite número que não explica nada.
const _soPorOverride = <String>{
  'saudade',
  'radiante',
  'contente',
  'neutro',
  'sone',
};

const _idiomas = ['pt', 'en', 'es', 'zh'];

FatosDoHumor _fatos({
  required Mood humor,
  bool medicao = true,
  int tela = 0,
  int meta = 150,
  int sessoes = 0,
  int foco = 0,
  bool desistiu = false,
  int? minDesistencia,
  int diasFora = 0,
  int raiz = 0,
  int maiorRaiz = 0,
  int folhas = 0,
  int? dispersivo,
}) =>
    FatosDoHumor(
      humor: humor,
      nomeDoPet: 'Baru',
      temMedicaoDeTela: medicao,
      minutosDeTela: tela,
      meta: meta,
      sessoesHoje: sessoes,
      minutosDeFocoHoje: foco,
      desistiuHoje: desistiu,
      minutosDaDesistencia: minDesistencia,
      diasFora: diasFora,
      raiz: raiz,
      maiorRaiz: maiorRaiz,
      folhas: folhas,
      minutosDispersivos: dispersivo,
    );

FalaDoHumor _fala(FatosDoHumor f, [String lang = 'pt']) =>
    escolheAFala(f, T(lang));

/// O que a tela mostra de verdade: título e linha de baixo, já com pronome e
/// números resolvidos.
String _naTela(FalaDoHumor f, {String lang = 'pt', Sexo sexo = Sexo.naoDito}) {
  final t = T(lang);
  return '${t.comPronome(t.humorCap(f), sexo, f.valores)} '
      '${t.comPronome(t.humorSub(f), sexo, f.valores)}';
}

AppState _pet({
  bool usageAccess = true,
  int usage = 0,
  int goal = 150,
  int completedToday = 0,
  bool abandonedToday = false,
  int daysAway = 0,
  int streak = 0,
  int melhorSequencia = 0,
  int leaves = 0,
  int minutosDeFocoHoje = 0,
  Mood? override,
  ResumoDeTela? resumo,
  List<SessionRecord> sessions = const [],
}) {
  final s = AppState()..startCompanionship();
  s.usageAccess = usageAccess;
  s.usage = usage;
  s.goal = goal;
  s.completedToday = completedToday;
  s.abandonedToday = abandonedToday;
  s.daysAway = daysAway;
  s.streak = streak;
  s.melhorSequencia = melhorSequencia;
  s.leaves = leaves;
  s.minutosDeFocoHoje = minutosDeFocoHoje;
  s.overrideMood = override;
  s.resumoTela = resumo;
  s.sessions = List<SessionRecord>.from(sessions);
  return s;
}

void main() {
  setUp(garanteTextosDoHumor);

  group('o humor diz a causa, e ela é a medida', () {
    test('ausência: o número de dias, não só o sentimento', () {
      final f = _fala(_fatos(humor: Mood.missingYou, diasFora: 3, folhas: 137));
      expect(f.id, 'ausencia');
      expect(f.valores['dias'], 3);
      // O fato tem de chegar à tela, não só ao mapa de valores.
      expect(_naTela(f), contains('3 dias'));
      expect(_naTela(f), contains('137'));
    });

    test('ausência que a raiz atravessou fala da raiz, com o número dela', () {
      final f = _fala(
        _fatos(humor: Mood.missingYou, diasFora: 4, raiz: 9, folhas: 40),
      );
      expect(f.id, 'ausenciaComRaiz');
      expect(_naTela(f), contains('4 dias'));
      expect(_naTela(f), contains('9'));
    });

    test('raiz zerada não afirma que a raiz segurou', () {
      final f = _fala(_fatos(humor: Mood.missingYou, diasFora: 4, raiz: 0));
      expect(f.id, 'ausencia');
    });

    test('desistência: a duração da sessão que parou', () {
      final f = _fala(
        _fatos(humor: Mood.missingYou, desistiu: true, minDesistencia: 25),
      );
      expect(f.id, 'desistencia');
      expect(_naTela(f), contains('25min'));
    });

    test('sem registro da sessão, a fala omite o número em vez de inventar',
        () {
      final f = _fala(_fatos(humor: Mood.missingYou, desistiu: true));
      expect(f.id, 'desistenciaSemMinutos');
      expect(_naTela(f), isNot(matches(RegExp(r'\d'))));
    });

    test('ausência e desistência juntas: o fato maior vem primeiro', () {
      final f = _fala(
        _fatos(
          humor: Mood.missingYou,
          diasFora: 3,
          desistiu: true,
          minDesistencia: 50,
          raiz: 2,
        ),
      );
      expect(f.id, 'ausenciaComRaiz');
      expect(_naTela(f), contains('3 dias'));
    });

    test('duas causas diferentes nunca dão o mesmo texto', () {
      // Era exatamente isto o defeito: "sentiu sua falta" para as duas.
      final ausencia = _fala(_fatos(humor: Mood.missingYou, diasFora: 3));
      final desistencia = _fala(
        _fatos(humor: Mood.missingYou, desistiu: true, minDesistencia: 25),
      );
      expect(_naTela(ausencia), isNot(_naTela(desistencia)));
    });
  });

  group('radiante', () {
    test('recorde de raiz vira orgulho, com o número do recorde', () {
      final f = _fala(
        _fatos(humor: Mood.radiant, sessoes: 1, raiz: 7, maiorRaiz: 7),
      );
      expect(f.id, 'radianteRecorde');
      expect(_naTela(f), contains('7'));
    });

    test('raiz abaixo do recorde não se anuncia como recorde', () {
      final f = _fala(
        _fatos(
          humor: Mood.radiant,
          sessoes: 1,
          raiz: 7,
          maiorRaiz: 9,
          tela: 90,
        ),
      );
      expect(f.id, isNot('radianteRecorde'));
    });

    test('um dia só de raiz não é recorde de nada', () {
      final f = _fala(
        _fatos(humor: Mood.radiant, sessoes: 1, raiz: 1, maiorRaiz: 1, tela: 90),
      );
      expect(f.id, isNot('radianteRecorde'));
    });

    test('a volta depois de um dia fora é dita como volta', () {
      final f = _fala(_fatos(humor: Mood.radiant, sessoes: 2, diasFora: 1));
      expect(f.id, 'radianteVolta');
      expect(_naTela(f), contains('2 sessões'));
    });

    test('abaixo da meta cita os dois números', () {
      final f = _fala(
        _fatos(humor: Mood.radiant, sessoes: 1, tela: 96, meta: 150),
      );
      expect(f.id, 'radianteAbaixo');
      expect(_naTela(f), contains('1h 36min'));
      expect(_naTela(f), contains('54min'));
      expect(_naTela(f), contains('Uma sessão de foco'));
    });

    test('a contagem de sessões tem singular e plural', () {
      final uma = _fala(_fatos(humor: Mood.radiant, sessoes: 1, tela: 90));
      final tres = _fala(_fatos(humor: Mood.radiant, sessoes: 3, tela: 90));
      expect(_naTela(uma), contains('Uma sessão de foco'));
      expect(_naTela(tres), contains('3 sessões de foco'));
    });
  });

  group('contente', () {
    test('acima da meta com sessão diz as duas coisas', () {
      final f = _fala(
        _fatos(humor: Mood.content, sessoes: 1, tela: 200, meta: 150),
      );
      expect(f.id, 'contenteAcima');
      expect(_naTela(f), contains('3h 20min'));
      expect(_naTela(f), contains('50min'));
    });

    test('exatamente na meta não escreve "0min acima"', () {
      final f = _fala(
        _fatos(humor: Mood.content, sessoes: 1, tela: 150, meta: 150),
      );
      expect(f.id, 'contenteNaMeta');
      // Nem o valor existe: um `{delta}` de zero na tela seria ruído com cara
      // de medição. ("0min" cru não serve de asserção — "2h 30min" o contém.)
      expect(f.valores.containsKey('delta'), isFalse);
      expect(_naTela(f), isNot(matches(RegExp(r'(^|\s)0min'))));
    });

    test('abaixo da meta sem sessão nomeia o que falta', () {
      final f = _fala(_fatos(humor: Mood.content, tela: 96, meta: 150));
      expect(f.id, 'contenteAbaixo');
      expect(_naTela(f), contains('1h 36min'));
      expect(_naTela(f), contains('54min'));
    });

    test('a volta de um dia fora guarda o lugar, com as folhas contadas', () {
      final f = _fala(_fatos(humor: Mood.content, diasFora: 1, folhas: 88));
      expect(f.id, 'contenteVolta');
      expect(_naTela(f), contains('88'));
    });
  });

  group('neutro e sonolento', () {
    test('em cima da meta é dito como em cima da meta', () {
      final f = _fala(_fatos(humor: Mood.neutral, tela: 150, meta: 150));
      expect(f.id, 'neutroNaMeta');
      expect(_naTela(f), contains('2h 30min'));
    });

    test('pouco acima cita a diferença', () {
      final f = _fala(_fatos(humor: Mood.neutral, tela: 170, meta: 150));
      expect(f.id, 'neutroAcima');
      expect(_naTela(f), contains('20min'));
    });

    test('dia longo com detalhamento aponta o dispersivo, com o número', () {
      final f = _fala(
        _fatos(humor: Mood.sleepy, tela: 300, meta: 150, dispersivo: 120),
      );
      expect(f.id, 'soneDispersivo');
      expect(_naTela(f), contains('2h 30min')); // 300 - 150 acima da meta
      expect(_naTela(f), contains('2h')); // 120 min dispersivos
    });

    test('sem detalhamento não inventa a fatia dispersiva', () {
      for (final disp in [null, 0]) {
        final f = _fala(
          _fatos(humor: Mood.sleepy, tela: 300, meta: 150, dispersivo: disp),
        );
        expect(f.id, 'soneAcima', reason: 'dispersivo $disp');
        expect(f.valores.containsKey('disp'), isFalse);
      }
    });
  });

  group('sem permissão de uso o app não estima', () {
    test('nenhuma fala sem medição carrega número de tela', () {
      for (final humor in Mood.values) {
        for (final sessoes in [0, 1, 3]) {
          for (final tela in [0, 500, 9999]) {
            final f = _fala(
              _fatos(
                humor: humor,
                medicao: false,
                // Um `usage` residual no snapshot não pode virar frase.
                tela: tela,
                meta: 150,
                sessoes: sessoes,
                foco: 50,
                dispersivo: 90,
              ),
            );
            for (final chave in ['tela', 'delta', 'disp']) {
              expect(
                f.valores.containsKey(chave),
                isFalse,
                reason: '${f.id} citou $chave sem medição',
              );
            }
          }
        }
      }
    });

    test('radiante sem medição fala de foco e diz que não mede a tela', () {
      final f = _fala(
        _fatos(humor: Mood.radiant, medicao: false, sessoes: 2, foco: 50),
      );
      expect(f.id, 'radianteSemMedicao');
      expect(_naTela(f), contains('50min'));
      expect(_naTela(f), contains('acesso ao uso'));
    });

    test('contente sem medição nomeia o que falta e o que não dá para saber',
        () {
      final f = _fala(_fatos(humor: Mood.content, medicao: false));
      expect(f.id, 'contenteSemMedicao');
      expect(_naTela(f), contains('acesso ao uso'));
    });
  });

  group('o catálogo, nos quatro idiomas', () {
    test('todo id tem título e legenda em cada idioma', () {
      for (final lang in _idiomas) {
        final mapa = textosDoHumor[lang]!;
        for (final id in _idsEsperados) {
          // No mapa cru: `T.s` devolveria a chave e `moodCap` devolveria
          // vazio, então o acessor sozinho não denuncia a falta.
          expect(
            mapa.containsKey('humorCap_$id'),
            isTrue,
            reason: 'humorCap_$id falta em $lang',
          );
          expect(
            mapa.containsKey('humorSub_$id'),
            isTrue,
            reason: 'humorSub_$id falta em $lang',
          );
        }
      }
    });

    test('nenhum texto sobrando: todo texto pertence a um id alcançável', () {
      final esperadas = {
        'humorSessoesUma',
        'humorSessoesMuitas',
        for (final id in _idsEsperados) ...['humorCap_$id', 'humorSub_$id'],
      };
      for (final lang in _idiomas) {
        expect(
          textosDoHumor[lang]!.keys.toSet(),
          esperadas,
          reason: '$lang tem chave a mais ou a menos',
        );
      }
    });

    test('o acessor resolve, e não devolve a chave nem o texto de reserva',
        () {
      for (final lang in _idiomas) {
        final t = T(lang);
        for (final id in _idsEsperados) {
          for (final chave in ['humorCap_$id', 'humorSub_$id']) {
            final texto = t.s(chave);
            expect(texto, isNot(chave), reason: '$chave em $lang caiu na chave');
            expect(texto.trim(), isNotEmpty, reason: '$chave em $lang vazio');
          }
        }
      }
    });

    test('os placeholders de número batem entre os idiomas', () {
      // Pronome fica de fora: `{P}` é gramática, e inglês e chinês nem sempre
      // precisam dele. Perder um número, não — é o que a fala existe para
      // dizer.
      const pronomes = {'p', 'P', 'd'};
      final pt = textosDoHumor['pt']!;
      for (final lang in _idiomas.where((l) => l != 'pt')) {
        final m = textosDoHumor[lang]!;
        for (final chave in pt.keys) {
          expect(
            _buracos(m[chave]!).difference(pronomes),
            _buracos(pt[chave]!).difference(pronomes),
            reason: 'os valores de $chave divergem em $lang',
          );
        }
      }
    });

    test('nenhuma fala deixa buraco na tela, em nenhum idioma nem sexo', () {
      for (final id in _todosOsIdsAlcancados()) {
        for (final lang in _idiomas) {
          for (final sexo in Sexo.values) {
            final f = FalaDoHumor(
              id: id.$1,
              humor: id.$2,
              valores: id.$3,
            );
            final texto = _naTela(f, lang: lang, sexo: sexo);
            expect(
              texto,
              isNot(contains('{')),
              reason: '${id.$1}/$lang/${sexo.name}',
            );
            expect(texto.trim(), isNotEmpty);
          }
        }
      }
    });
  });

  group('a regra cobre o espaço de fatos, sem buraco e sem texto morto', () {
    test('toda combinação real cai num id conhecido', () {
      final vistos = _idsAlcancadosPeloEstado();
      expect(
        vistos.difference(_idsEsperados),
        isEmpty,
        reason: 'a regra produziu id sem texto',
      );
    });

    test('todo id, menos os do override, sai de fatos reais', () {
      final vistos = _idsAlcancadosPeloEstado();
      expect(
        _idsEsperados.difference(_soPorOverride).difference(vistos),
        isEmpty,
        reason: 'texto que nenhum dia real alcança',
      );
    });

    test('as falas de reserva só existem para o humor forçado', () {
      final vistos = _idsAlcancadosPeloEstado();
      expect(vistos.intersection(_soPorOverride), isEmpty);

      for (final humor in Mood.values) {
        final s = _pet(override: humor, usage: 9999, goal: 150);
        expect(s.mood, humor);
      }
      // E o forçado nunca cita número que os fatos não sustentam.
      final forcado = _pet(override: Mood.radiant, usage: 9999, goal: 150);
      expect(forcado.falaDoHumor.id, 'radiante');
      expect(forcado.falaDoHumor.valores.containsKey('tela'), isFalse);
    });
  });

  group('o AppState monta os fatos a partir do que mediu', () {
    test('a duração citada é a da sessão que parou, não a da última', () {
      // Desistiu de 25 e depois completou 50: `sessionDur` ficaria em 50.
      final hoje = dateOnly(DateTime.now());
      final s = _pet(
        abandonedToday: true,
        completedToday: 1,
        sessions: [
          SessionRecord(
            id: 'a',
            at: hoje.add(const Duration(hours: 9)),
            dur: 25,
            completed: false,
            aborted: true,
            reward: 0,
          ),
          SessionRecord(
            id: 'b',
            at: hoje.add(const Duration(hours: 14)),
            dur: 50,
            completed: true,
            aborted: false,
            reward: 25,
          ),
        ],
      );
      expect(s.mood, Mood.missingYou);
      expect(s.falaDoHumor.id, 'desistencia');
      expect(_naTela(s.falaDoHumor), contains('25min'));
      expect(_naTela(s.falaDoHumor), isNot(contains('50min')));
      s.dispose();
    });

    test('desistência de ontem não vira fato de hoje', () {
      final ontem = dateOnly(DateTime.now()).subtract(const Duration(days: 1));
      final s = _pet(
        abandonedToday: true,
        sessions: [
          SessionRecord(
            id: 'a',
            at: ontem.add(const Duration(hours: 9)),
            dur: 25,
            completed: false,
            aborted: true,
            reward: 0,
          ),
        ],
      );
      expect(s.falaDoHumor.id, 'desistenciaSemMinutos');
      s.dispose();
    });

    test('o dispersivo vem do resumo real, e some sem resumo', () {
      final comResumo = _pet(
        usage: 300,
        goal: 150,
        resumo: const ResumoDeTela(
          porApp: {'com.x': Duration(minutes: 120)},
          porCategoria: {CategoriaDeApp.dispersivo: Duration(minutes: 120)},
        ),
      );
      expect(comResumo.mood, Mood.sleepy);
      expect(comResumo.falaDoHumor.id, 'soneDispersivo');

      final semResumo = _pet(usage: 300, goal: 150);
      expect(semResumo.falaDoHumor.id, 'soneAcima');
      comResumo.dispose();
      semResumo.dispose();
    });

    test('moodKey continua o do contrato — o catálogo antigo depende dele',
        () {
      const esperado = {
        Mood.radiant: 'radiant',
        Mood.content: 'content',
        Mood.neutral: 'neutral',
        Mood.sleepy: 'sleepy',
        Mood.missingYou: 'missing_you',
      };
      for (final e in esperado.entries) {
        final s = _pet(override: e.key);
        expect(s.moodKey, e.value);
        s.dispose();
      }
    });
  });

  group('as fronteiras dos cinco humores, como estão hoje', () {
    test('sleepy é inalcançável com qualquer sessão concluída', () {
      // `content` casa com `usage < goal || completedToday >= 1`, e vem
      // antes. Uma sessão de 25 min num dia de doze horas de tela leva a
      // `content` — que é a regra do §3 e não vai mudar aqui. O que muda é o
      // texto: "Um dia decente" virava mentira, e agora a fala diz as horas.
      for (final uso in [200, 600, 900]) {
        final s = _pet(usage: uso, goal: 150, completedToday: 1);
        expect(s.mood, Mood.content, reason: 'uso $uso');
        expect(s.falaDoHumor.id, 'contenteAcima');
        s.dispose();
      }
    });

    test('neutral só existe entre a meta e meta × 1,2, e sem sessão', () {
      // A tabela do contrato diz "uso ≤ meta × 1,2", mas o piso é implícito:
      // abaixo da meta `content` já casou. A faixa real é [150, 180].
      expect(_pet(usage: 149, goal: 150).mood, Mood.content);
      expect(_pet(usage: 150, goal: 150).mood, Mood.neutral);
      expect(_pet(usage: 180, goal: 150).mood, Mood.neutral);
      expect(_pet(usage: 181, goal: 150).mood, Mood.sleepy);
      expect(_pet(usage: 170, goal: 150, completedToday: 1).mood, Mood.content);
    });

    test('"abaixo da meta" leva "até agora"; "acima" não leva', () {
      // Às nove da manhã todo mundo está abaixo da meta, e a frase ainda pode
      // virar. Acima da meta não desfaz — o dia só soma.
      final abaixo = _fala(_fatos(humor: Mood.content, tela: 96, meta: 150));
      final acima = _fala(
        _fatos(humor: Mood.neutral, tela: 170, meta: 150),
      );
      expect(_naTela(abaixo), contains('até agora'));
      expect(_naTela(acima), isNot(contains('até agora')));
    });
  });

  testWidgets('a home mostra o fato, não só o sentimento', (tester) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = _pet(usage: 116, goal: 150, completedToday: 2, streak: 3);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppScope(state: app, child: const HomeScreen())),
      ),
    );
    await tester.pump();

    final cap = tester.widget<Text>(find.byKey(const Key('home-humor-cap')));
    final sub = tester.widget<Text>(find.byKey(const Key('home-humor-sub')));
    expect(cap.data, contains('1h 56min'));
    expect(cap.data, contains('34min'));
    expect(sub.data, contains('2 sessões de foco'));
    // O que o dono do produto reclamou: sentimento sem fato.
    expect('${cap.data}${sub.data}', isNot(contains('{')));
  });
}

final _reBuraco = RegExp(r'\{(\w+)\}');

Set<String> _buracos(String texto) =>
    _reBuraco.allMatches(texto).map((m) => m.group(1)!).toSet();

/// Varre um espaço de dias plausíveis e devolve os ids que a regra escolhe.
///
/// Passa pelo `AppState` de propósito: é a precedência do §3 que decide o
/// humor, e um teste que replicasse essa tabela aqui deixaria de detectar o
/// dia em que as duas discordassem.
Set<String> _idsAlcancadosPeloEstado() {
  final vistos = <String>{};
  for (final acesso in [true, false]) {
    // 170 é o único valor dentro da faixa estreita do `neutral`: acima da
    // meta e até meta × 1,2, que com meta 150 é ]150, 180]. Sem um valor ali
    // dentro, metade do humor fica invisível para a varredura.
    for (final uso in [0, 90, 150, 170, 200, 400]) {
      for (final sessoes in [0, 1, 2]) {
        // `null` cobre a desistência sem registro na lista de sessões: é o
        // caso em que a fala tem de omitir o número em vez de inventar.
        for (final desistiu in [false, true]) {
          for (final fora in [0, 1, 2, 5]) {
            for (final raiz in [0, 3, 7]) {
              for (final resumo in [null, _resumoDispersivo]) {
                for (final registrada in [true, false]) {
                  final s = _pet(
                    usageAccess: acesso,
                    usage: uso,
                    completedToday: sessoes,
                    abandonedToday: desistiu,
                    daysAway: fora,
                    streak: raiz,
                    melhorSequencia: 7,
                    minutosDeFocoHoje: sessoes * 25,
                    resumo: resumo,
                    sessions: desistiu && registrada
                        ? [_desistenciaDeHoje]
                        : const [],
                  );
                  vistos.add(s.falaDoHumor.id);
                  s.dispose();
                }
              }
            }
          }
        }
      }
    }
  }
  return vistos;
}

/// Cada id com um jogo de valores que o alcança — para checar buraco de
/// texto em todos os idiomas e sexos.
List<(String, Mood, Map<String, Object>)> _todosOsIdsAlcancados() {
  final saida = <(String, Mood, Map<String, Object>)>[];
  for (final fatos in _amostraDeFatos) {
    final f = _fala(fatos);
    saida.add((f.id, f.humor, f.valores));
  }
  return saida;
}

final _amostraDeFatos = <FatosDoHumor>[
  _fatos(humor: Mood.missingYou, diasFora: 3, raiz: 4),
  _fatos(humor: Mood.missingYou, diasFora: 3, folhas: 40),
  _fatos(humor: Mood.missingYou, desistiu: true, minDesistencia: 25),
  _fatos(humor: Mood.missingYou, desistiu: true),
  _fatos(humor: Mood.missingYou),
  _fatos(humor: Mood.radiant, sessoes: 1, raiz: 5, maiorRaiz: 5),
  _fatos(humor: Mood.radiant, sessoes: 1, diasFora: 1),
  _fatos(humor: Mood.radiant, sessoes: 2, medicao: false, foco: 50),
  _fatos(humor: Mood.radiant, sessoes: 1, tela: 96),
  _fatos(humor: Mood.radiant),
  _fatos(humor: Mood.content, diasFora: 1, folhas: 12),
  _fatos(humor: Mood.content, medicao: false),
  _fatos(humor: Mood.content, sessoes: 1, tela: 200),
  _fatos(humor: Mood.content, sessoes: 1, tela: 150),
  _fatos(humor: Mood.content, tela: 96),
  _fatos(humor: Mood.content, sessoes: 1, tela: 96),
  _fatos(humor: Mood.neutral, tela: 150),
  _fatos(humor: Mood.neutral, tela: 170),
  _fatos(humor: Mood.neutral, medicao: false),
  _fatos(humor: Mood.sleepy, tela: 300, dispersivo: 120),
  _fatos(humor: Mood.sleepy, tela: 300),
  _fatos(humor: Mood.sleepy, medicao: false),
];

const _resumoDispersivo = ResumoDeTela(
  porApp: {'com.exemplo': Duration(minutes: 90)},
  porCategoria: {CategoriaDeApp.dispersivo: Duration(minutes: 90)},
);

final _desistenciaDeHoje = SessionRecord(
  id: 'x',
  at: dateOnly(DateTime.now()).add(const Duration(hours: 10)),
  dur: 25,
  completed: false,
  aborted: true,
  reward: 0,
);
