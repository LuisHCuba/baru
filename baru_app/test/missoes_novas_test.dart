import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/missoes.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_missoes.dart';
import 'package:baru_app/screens/missoes_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Os tipos de missão que este turno acrescentou.
///
/// A regra que atravessa o arquivo é a mesma do `missoes_test.dart`: **missão
/// que anuncia prêmio tem de pagar**. Aqui isso é levado ao pé da letra — cada
/// tipo novo é levado do contador cru do `AppState` até a folha na carteira,
/// pelo caminho que o app usa de verdade (sorteio determinístico incluído), e
/// não por um `Missao` montado à mão que provaria só que a aritmética fecha.

const quadro = QuadroDeMissoes();

DefinicaoDeMissao _def(String id) =>
    todasAsDefinicoes.firstWhere((d) => d.id == id);

ResumoDeTela _tela({
  int dispersivo = 0,
  int neutro = 0,
  int produtivo = 0,
}) =>
    ResumoDeTela(
      porApp: {'com.exemplo.feed': Duration(minutes: dispersivo)},
      porCategoria: {
        CategoriaDeApp.dispersivo: Duration(minutes: dispersivo),
        CategoriaDeApp.neutro: Duration(minutes: neutro),
        CategoriaDeApp.produtivo: Duration(minutes: produtivo),
      },
    );

SessionRecord _foco(DateTime quando, {bool concluida = true}) => SessionRecord(
      id: 'sessao-${quando.toIso8601String()}',
      at: quando,
      dur: 25,
      completed: concluida,
      aborted: !concluida,
      reward: 10,
    );

AppState _conta() => AppState()
  ..startCompanionship()
  ..leaves = 0;

/// Um dia em que o sorteio determinístico entrega [id].
///
/// O sorteio é por conta e data (ADR-010), então não dá para "pedir" uma
/// missão: dá para procurar o dia em que ela sai. É o que faz este arquivo
/// provar o caminho inteiro — se o tipo novo nunca entrasse no pool, ou se o
/// pool tivesse ficado grande demais para ele aparecer, a busca falharia aqui
/// em vez de passar despercebida.
DateTime _diaComAMissao(AppState s, String id) {
  for (var i = 0; i < 730; i++) {
    final dia = DateTime(2026, 1, 5 + i);
    s.lastOpenDate = dia;
    if (s.missoes.any((m) => m.id == id)) return dia;
  }
  fail('o sorteio nunca entregou "$id" em dois anos de datas');
}

/// Leva [id] do contador do app até a folha creditada, e prova que o segundo
/// toque não paga de novo.
void _provaOCredito(
  String id, {
  required void Function(AppState s, DateTime dia) prepara,
}) {
  final s = _conta();
  addTearDown(s.dispose);
  final dia = _diaComAMissao(s, id);
  prepara(s, dia);

  final alvo = s.missoes.firstWhere((m) => m.id == id);
  expect(
    alvo.resgatavel,
    isTrue,
    reason: '$id: ${alvo.progresso}/${alvo.alvo} — o contador do app não '
        'chegou a fechar a missão',
  );

  final folhasAntes = s.leaves;
  final xpAntes = s.xp;
  s.resgataMissao(alvo);
  expect(s.leaves, folhasAntes + alvo.folhas, reason: '$id não pagou');
  expect(s.xp, greaterThanOrEqualTo(xpAntes + alvo.xp), reason: '$id sem XP');

  final pago = s.leaves;
  s.resgataMissao(alvo);
  s.resgataMissao(s.missoes.firstWhere((m) => m.id == id));
  expect(s.leaves, pago, reason: '$id: toque duplo imprimiu folhas');
}

void main() {
  group('o repertório', () {
    test('todo tipo de missão tem uma definição', () {
      // Um valor de `TipoDeMissao` que nenhuma definição usa é uma missão
      // que o app nunca entrega: código morto se passando por conteúdo.
      // Vale para as sorteadas e para as fixas — `todasAsDefinicoes` junta
      // as duas justamente para que criar um tipo fora do pool não escape
      // desta verificação.
      for (final tipo in TipoDeMissao.values) {
        expect(
          todasAsDefinicoes.any((d) => d.tipo == tipo),
          isTrue,
          reason: '${tipo.name} não tem definição nenhuma',
        );
      }
    });

    test('nenhum id se repete entre as definições', () {
      final ids = todasAsDefinicoes.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('todo tipo tem título e "como" próprios, sem repetir', () {
      final app = _conta();
      addTearDown(app.dispose);
      final titulos = <String>{};
      for (final d in todasAsDefinicoes) {
        final m = Missao(
          definicao: d,
          progresso: 0,
          resgatada: false,
          disponivel: true,
        );
        final titulo = tituloDaMissao(app, m);
        expect(titulo, isNotEmpty, reason: d.id);
        expect(titulo, isNot(d.id), reason: '${d.id}: chave crua na tela');
        expect(comoDaMissao(app, m), isNotEmpty, reason: d.id);
        expect(
          titulos.add(titulo),
          isTrue,
          reason: '${d.id} repete o título de outra missão',
        );
      }
    });
  });

  group('foco acima do dispersivo', () {
    final d = _def('foco_ganha_do_rolar');

    test('à meia-noite, zero contra zero não paga a missão', () {
      // O dia começa com zero de foco e zero de rolagem. Sem o piso, `0 >= 0`
      // entregaria a missão mais cara do pool antes de a pessoa fazer nada.
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(dispersivoHoje: 0)),
        0,
      );
    });

    test('foco maior que a rolagem fecha a missão', () {
      expect(
        quadro.progressoDe(
          d,
          const ContadoresDeMissao(minutosHoje: 50, dispersivoHoje: 30),
        ),
        d.alvo,
      );
    });

    test('foco menor que a rolagem ainda não fecha', () {
      expect(
        quadro.progressoDe(
          d,
          const ContadoresDeMissao(minutosHoje: 20, dispersivoHoje: 90),
        ),
        0,
      );
    });

    test('sem medição de tela não inventa progresso', () {
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(minutosHoje: 200)),
        0,
        reason: 'ADR-009: o app não estima tempo de tela',
      );
    });

    test('paga, saindo do contador do próprio app', () {
      _provaOCredito(
        'foco_ganha_do_rolar',
        prepara: (s, _) => s
          ..usageAccess = true
          ..minutosDeFocoHoje = 65
          ..resumoTela = _tela(dispersivo: 20),
      );
    });
  });

  group('dia completo', () {
    final d = _def('dia_completo');

    test('meia missão é meia barra, não zero', () {
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(sessoesHoje: 1)),
        1,
      );
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(fechouAbaixoHoje: true)),
        1,
      );
    });

    test('as duas metades juntas fecham', () {
      expect(
        quadro.progressoDe(
          d,
          const ContadoresDeMissao(sessoesHoje: 3, fechouAbaixoHoje: true),
        ),
        d.alvo,
      );
    });

    test('paga, saindo do contador do próprio app', () {
      _provaOCredito(
        'dia_completo',
        prepara: (s, _) => s
          ..usageAccess = true
          ..completedToday = 1
          ..usage = 10
          ..goal = 120,
      );
    });
  });

  group('descanso na semana', () {
    final d = _def('semana_descanso');
    final quinta = DateTime(2026, 8, 27);

    Set<String> descansosEm(List<DateTime> dias) =>
        {for (final dia in dias) QuadroDeMissoes.chaveDoDescanso(dia)};

    test('conta os dias desta semana em que a toca foi aberta', () {
      final r = descansosEm([
        DateTime(2026, 8, 24), // segunda
        DateTime(2026, 8, 26), // quarta
      ]);
      expect(quadro.progressoDe(d, const ContadoresDeMissao(),
          dia: quinta, resgatadas: r), 2);
    });

    test('domingo pertence à semana que termina, não à que começa', () {
      // A âncora é a segunda-feira, igual à faixa da home. Um domingo
      // contado na semana seguinte daria à pessoa um dia de brinde toda
      // segunda — e tiraria o dela na véspera.
      final domingo = DateTime(2026, 8, 30);
      final r = descansosEm([domingo]);
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(),
            dia: domingo, resgatadas: r),
        1,
      );
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(),
            dia: DateTime(2026, 8, 31), resgatadas: r),
        0,
        reason: 'segunda abre semana nova',
      );
    });

    test('descanso de outra semana não conta', () {
      final r = descansosEm([DateTime(2026, 8, 17)]);
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(),
            dia: quinta, resgatadas: r),
        0,
      );
    });

    test('resgate de outra missão no mesmo dia não conta como descanso', () {
      final r = {
        QuadroDeMissoes.chaveDeResgate(_def('um_foco'), quinta),
        QuadroDeMissoes.chaveDoDia('volta', quinta),
      };
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(),
            dia: quinta, resgatadas: r),
        0,
      );
    });

    test('paga, saindo do histórico de resgates do próprio app', () {
      _provaOCredito(
        'semana_descanso',
        prepara: (s, dia) {
          final segunda = DateTime(dia.year, dia.month, dia.day - dia.weekday + 1);
          s
            ..usageAccess = true
            ..missoesResgatadas = {
              for (var i = 0; i < 3; i++)
                QuadroDeMissoes.chaveDoDescanso(
                  DateTime(segunda.year, segunda.month, segunda.day + i),
                ),
            };
        },
      );
    });
  });

  group('foco profundo na semana', () {
    final d = _def('semana_foco_profundo');

    test('zero sessões é zero, e não uma divisão por zero', () {
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(minutosNaSemana: 300)),
        0,
      );
    });

    test('é a média por sessão, não o total', () {
      // Trezentos minutos em dez sessões é volume, não profundidade.
      expect(
        quadro.progressoDe(
          d,
          const ContadoresDeMissao(sessoesNaSemana: 10, minutosNaSemana: 300),
        ),
        30,
      );
      expect(
        quadro.progressoDe(
          d,
          const ContadoresDeMissao(sessoesNaSemana: 3, minutosNaSemana: 150),
        ),
        d.alvo,
      );
    });

    test('paga, saindo do contador do próprio app', () {
      _provaOCredito(
        'semana_foco_profundo',
        prepara: (s, _) => s
          ..sessoesNaSemana = 3
          ..minutosNaSemana = 180,
      );
    });
  });

  group('cuidado com o companheiro', () {
    final d = _def('carinho_no_bicho');

    test('o alvo cabe dentro do teto de afagos do dia', () {
      // `recebeCarinho` só incrementa `carinhosHoje` enquanto ele está abaixo
      // de `Balanco.carinhosPorDia`. Um alvo acima do teto seria uma missão
      // que o app conta e nunca deixa fechar.
      expect(d.alvo, lessThanOrEqualTo(Balanco.carinhosPorDia));
    });

    test('não depende de permissão nenhuma', () {
      // É a missão que sobra quando a pessoa recusa o acesso ao uso. Amarrá-la
      // à permissão deixaria o quadro todo travado para quem recusou.
      expect(d.precisaDeUso, isFalse);
    });

    test('o progresso é o afago contado, e não passa do alvo', () {
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(carinhosHoje: 2)),
        2,
      );
      expect(
        quadro.progressoDe(d, const ContadoresDeMissao(carinhosHoje: 99)),
        d.alvo,
      );
    });

    test('paga, e o contador vem do afago de verdade', () {
      _provaOCredito(
        'carinho_no_bicho',
        prepara: (s, _) {
          // Pelo evento de domínio, não pelo campo: é `recebeCarinho` que a
          // tela chama, e é ele que carrega o teto do dia.
          for (var i = 0; i < _def('carinho_no_bicho').alvo; i++) {
            s.recebeCarinho();
          }
        },
      );
    });
  });

  group('variedade de horário', () {
    final dia = DateTime(2026, 8, 27);

    test('os três períodos cobrem as vinte e quatro horas', () {
      // Uma hora sem período seria uma sessão que não conta em lugar nenhum.
      final achados = <PeriodoDoDia>{};
      for (var h = 0; h < 24; h++) {
        achados.add(periodoDe(DateTime(2026, 8, 27, h)));
      }
      expect(achados, PeriodoDoDia.values.toSet());
      expect(
        periodoDe(DateTime(2026, 8, 27, 3)),
        PeriodoDoDia.noite,
        reason: 'a madrugada é noite, não uma quarta faixa',
      );
    });

    test('duas sessões na mesma manhã são um período só', () {
      expect(
        faixasDeFoco(
          [DateTime(2026, 8, 27, 8), DateTime(2026, 8, 27, 10)],
          dia: dia,
        ),
        1,
        reason: 'o que se mede é a distribuição, não a quantidade',
      );
    });

    test('manhã e noite são dois', () {
      expect(
        faixasDeFoco(
          [DateTime(2026, 8, 27, 8), DateTime(2026, 8, 27, 21)],
          dia: dia,
        ),
        2,
      );
    });

    test('foco de ontem não conta para hoje', () {
      expect(
        faixasDeFoco(
          [DateTime(2026, 8, 26, 8), DateTime(2026, 8, 26, 21)],
          dia: dia,
        ),
        0,
      );
    });

    test('o começo da sessão é o que decide o período', () {
      // Uma sessão de 90 min começada às 11h50 é foco da manhã. Contar pelo
      // fim faria a missão depender da duração escolhida, não do horário.
      expect(faixasDeFoco([DateTime(2026, 8, 27, 11, 50)], dia: dia), 1);
      expect(periodoDe(DateTime(2026, 8, 27, 11, 50)), PeriodoDoDia.manha);
    });

    test('só as sessões concluídas viram período', () {
      final s = _conta();
      addTearDown(s.dispose);
      final dia = s.lastOpenDate;
      s.sessions = [
        _foco(DateTime(dia.year, dia.month, dia.day, 9), concluida: false),
        _foco(DateTime(dia.year, dia.month, dia.day, 21), concluida: false),
      ];
      expect(
        s.contadoresDeMissao.faixasDeFocoHoje,
        0,
        reason: 'senão fecharia a missão começando e desistindo três vezes',
      );
    });

    test('paga, saindo do histórico de sessões do próprio app', () {
      _provaOCredito(
        'foco_em_dois_periodos',
        prepara: (s, dia) => s.sessions = [
          _foco(DateTime(dia.year, dia.month, dia.day, 9)),
          _foco(DateTime(dia.year, dia.month, dia.day, 14), concluida: false),
          _foco(DateTime(dia.year, dia.month, dia.day, 21)),
        ],
      );
    });
  });

  group('tempo de tela por categoria', () {
    final produtiva = _def('tela_que_constroi');
    final fatia = _def('fatia_da_rolagem');

    test('sem medição, nenhuma das duas inventa progresso', () {
      expect(quadro.progressoDe(produtiva, const ContadoresDeMissao()), 0);
      expect(quadro.progressoDe(fatia, const ContadoresDeMissao()), 0);
    });

    test('o tempo produtivo é somado, não descontado', () {
      // A primeira missão do app que paga por usar o telefone.
      expect(
        quadro.progressoDe(
          produtiva,
          const ContadoresDeMissao(produtivoHoje: 20),
        ),
        20,
      );
    });

    test('a fatia é proporção: o mesmo total passa ou não', () {
      // Duas horas de tela nos dois casos. O que muda é o que se fez nelas —
      // e nenhuma missão de total sabe a diferença.
      expect(
        quadro.progressoDe(
          fatia,
          const ContadoresDeMissao(
            dispersivoHoje: 30,
            neutroHoje: 30,
            produtivoHoje: 60,
          ),
        ),
        fatia.alvo,
      );
      expect(
        quadro.progressoDe(
          fatia,
          const ContadoresDeMissao(
            dispersivoHoje: 100,
            neutroHoje: 10,
            produtivoHoje: 10,
          ),
        ),
        lessThan(fatia.alvo),
      );
    });

    test('meia hora de tela é pouco para haver proporção', () {
      // Dois minutos num app de leitura dariam 100% fora da rolagem e
      // fechariam a missão às sete da manhã.
      expect(
        quadro.progressoDe(
          fatia,
          const ContadoresDeMissao(
            dispersivoHoje: 0,
            neutroHoje: 0,
            produtivoHoje: 2,
          ),
        ),
        0,
      );
    });

    test('a produtiva paga, saindo do resumo de tela do app', () {
      _provaOCredito(
        'tela_que_constroi',
        prepara: (s, _) => s
          ..usageAccess = true
          ..resumoTela = _tela(dispersivo: 10, produtivo: 45),
      );
    });

    test('a da fatia paga, saindo do resumo de tela do app', () {
      _provaOCredito(
        'fatia_da_rolagem',
        prepara: (s, _) => s
          ..usageAccess = true
          ..resumoTela = _tela(dispersivo: 20, neutro: 20, produtivo: 60),
      );
    });
  });

  group('retomada depois de falhar', () {
    test('não existe no dia de quem não faltou', () {
      final s = _conta();
      addTearDown(s.dispose);
      expect(s.daysAway, 0);
      expect(
        s.missaoDeRetomada,
        isNull,
        reason: 'missão que não cabe no dia não aparece apagada: não existe',
      );
    });

    test('fica fora do sorteio, para não sair num dia comum', () {
      // No pool ela cairia em dias em que a condição não vale, e ficaria em
      // 0/1 para sempre — a missão impossível que o §8C proíbe.
      expect(poolDiario.map((d) => d.id), isNot(contains(defDaRetomada.id)));
      expect(poolSemanal.map((d) => d.id), isNot(contains(defDaRetomada.id)));
    });

    test('aparece no dia em que a pessoa volta depois de faltar', () {
      final s = _conta()..daysAway = 2;
      addTearDown(s.dispose);
      final m = s.missaoDeRetomada;
      expect(m, isNotNull);
      expect(m!.disponivel, isTrue);
      expect(m.progresso, 0);
      expect(m.resgatavel, isFalse);
    });

    test('a sessão que a cumpre não a faz sumir', () {
      // Regressão da armadilha que quase entrou: usar `streak == 0` como
      // porta. `_concluiSessao` sobe a sequência de 0 para 1 na primeira
      // sessão do dia — a porta fecharia no instante exato em que a missão
      // vira resgatável, e o prêmio anunciado nunca seria pago.
      final s = _conta()
        ..daysAway = 2
        ..debugFast = false
        ..dur = 25;
      addTearDown(s.dispose);

      s.startSession();
      s.sessionEndsAt = DateTime.now().subtract(const Duration(seconds: 1));
      s.reconcileSession();

      expect(s.streak, greaterThan(0), reason: 'a sessão mexeu na sequência');
      final m = s.missaoDeRetomada;
      expect(m, isNotNull, reason: 'a missão sumiu no instante em que fechou');
      expect(m!.resgatavel, isTrue);
    });

    test('paga uma vez, e o segundo toque não imprime folha', () {
      final s = _conta()
        ..daysAway = 2
        ..completedToday = 1;
      addTearDown(s.dispose);

      final m = s.missaoDeRetomada!;
      expect(m.resgatavel, isTrue);
      final antes = s.leaves;
      final xpAntes = s.xp;
      s.resgataMissao(m);
      expect(s.leaves, antes + m.folhas);
      expect(s.xp, greaterThanOrEqualTo(xpAntes + m.xp));

      final pago = s.leaves;
      s.resgataMissao(m);
      s.resgataMissao(s.missaoDeRetomada!);
      expect(s.leaves, pago);
      expect(s.missaoDeRetomada!.resgatada, isTrue);
    });

    test('entra na contagem do que há para colher', () {
      // O distintivo da home lê daqui. Sem isto ele diria "nada para colher"
      // com folha parada na tela ao lado, justo no dia da volta.
      final s = _conta()
        ..daysAway = 2
        ..completedToday = 1;
      addTearDown(s.dispose);
      final semARetomada = s.missoes.where((m) => m.resgatavel).length;
      expect(s.missoesResgataveis, semARetomada + 1);
    });

    test('a chave carrega o dia: a de ontem não vale hoje', () {
      final ontem =
          QuadroDeMissoes.chaveDeResgate(defDaRetomada, DateTime(2026, 8, 27));
      final hoje =
          QuadroDeMissoes.chaveDeResgate(defDaRetomada, DateTime(2026, 8, 28));
      expect(ontem, isNot(hoje));
      expect(hoje, 'retomada@2026-08-28');
    });

    test('a chave não colide com a do presente de retorno', () {
      // `avaliaVolta` escreve `volta@<dia>` no mesmo conjunto. São coisas
      // diferentes — um é presente automático, a outra se conquista — e uma
      // colisão faria o presente marcar a missão como já resgatada.
      final dia = DateTime(2026, 8, 28);
      expect(
        QuadroDeMissoes.chaveDeResgate(defDaRetomada, dia),
        isNot(QuadroDeMissoes.chaveDoDia('volta', dia)),
      );
    });
  });

  group('o balanceamento continua fechando com os tipos novos', () {
    test('nenhuma diária paga mais que o descanso', () {
      // Inclui as fixas: `defDaRetomada` não está em pool nenhum e escaparia
      // de uma verificação que só olhasse `poolDiario`.
      final diarias =
          todasAsDefinicoes.where((d) => d.ritmo == RitmoDaMissao.diaria);
      for (final d in diarias) {
        expect(
          d.folhas,
          lessThan(30),
          reason: '${d.id} passaria a principal do dia',
        );
      }
    });

    test('o XP continua vindo da tabela única', () {
      for (final d in poolDiario) {
        expect(d.xp, Balanco.xpMissaoDiaria, reason: d.id);
      }
      for (final d in poolSemanal) {
        expect(d.xp, Balanco.xpMissaoSemanal, reason: d.id);
      }
    });

    test('o pool cresceu sem quebrar o tamanho do sorteio', () {
      expect(poolDiario.length, greaterThanOrEqualTo(QuadroDeMissoes.quantasDiarias));
      expect(
        poolSemanal.length,
        greaterThanOrEqualTo(QuadroDeMissoes.quantasSemanais),
      );
    });
  });

  group('os textos da tela', () {
    setUp(garanteTextosDeMissoes);

    test('os 4 idiomas têm exatamente as mesmas chaves', () {
      final pt = textosDeMissoes['pt']!.keys.toSet();
      expect(textosDeMissoes.keys.toSet(), {'pt', 'en', 'es', 'zh'});
      for (final lang in textosDeMissoes.keys) {
        expect(textosDeMissoes[lang]!.keys.toSet(), pt, reason: lang);
        for (final e in textosDeMissoes[lang]!.entries) {
          expect(e.value.trim(), isNotEmpty, reason: '$lang.${e.key}');
        }
      }
    });

    test('os placeholders sobrevivem à tradução', () {
      final re = RegExp(r'\{(\w+)\}');
      for (final chave in textosDeMissoes['pt']!.keys) {
        final esperado =
            re.allMatches(textosDeMissoes['pt']![chave]!).map((m) => m[1]).toSet();
        for (final lang in textosDeMissoes.keys) {
          expect(
            re.allMatches(textosDeMissoes[lang]![chave]!).map((m) => m[1]).toSet(),
            esperado,
            reason: '$lang.$chave mostraria o token cru ou perderia o valor',
          );
        }
      }
    });

    test('o catálogo do módulo não sequestra chave do principal', () {
      // `T.registra` faz o catálogo principal ganhar. Uma chave repetida aqui
      // não quebraria nada — simplesmente nunca seria lida, e alguém passaria
      // uma tarde traduzindo texto morto.
      final principal = T.catalog['pt']!;
      for (final chave in textosDeMissoes['pt']!.keys) {
        expect(
          principal.containsKey(chave),
          isFalse,
          reason: '$chave já existe em l10n.dart e nunca seria lida daqui',
        );
      }
    });
  });
}
