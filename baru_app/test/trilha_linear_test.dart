import 'package:baru_app/data/carteira.dart';
import 'package:baru_app/data/progressao.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/screens/trilha_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A trilha é uma corrente.
///
/// O relato do dono do produto foi literal: "não tem como ele ter
/// conquistado, sei lá, o passo 7, 8, sem ter passado pelo 1, 2. Trilha tem
/// que ser linear, um passo de cada vez, não pode simplesmente pular e
/// conquistar os próximos".
///
/// Antes cada marco tinha critério próprio e independente, e os quatro
/// contadores — sessões, dias seguidos, nível, dias abaixo da meta — correm em
/// paralelo medindo coisas de naturezas diferentes. Quem só fazia sessões
/// conquistava o passo 13 sem ter chegado ao 11, e a trilha mostrava ✓
/// salteado com cadeados no meio.
///
/// Aqui se prova o contrário, em quatro frentes: a ordem é obrigatória, o
/// critério continua sendo o que abre o degrau atual, a tela nunca tem buraco,
/// e a virada para o modelo linear não tira nada de quem já jogava.

ProgressoDaTrilha _p({
  int xp = 0,
  int sessoes = 0,
  int seq = 0,
  int abaixo = 0,
  Set<String> entregues = const <String>{},
}) =>
    ProgressoDaTrilha(
      xp: xp,
      sessoesConcluidas: sessoes,
      melhorSequencia: seq,
      diasAbaixoDaMeta: abaixo,
      entregues: entregues,
    );

/// Uma conta que satisfez o critério de **todos** os degraus.
ProgressoDaTrilha _trilhaInteira() => _p(
      xp: Balanco.xpAcumuladoPara(15),
      sessoes: 100,
      seq: 30,
      abaixo: 30,
    );

/// Estados variados o bastante para valer como varredura, não como exemplo.
///
/// Inclui de propósito os formatos que quebravam o modelo antigo: o moedor de
/// sessões sem presença, o presente diário que nunca foca, o nível alto de
/// conta que só ganhou XP de missão, e a conta sem permissão de uso (dias
/// abaixo da meta parados em zero para sempre).
List<ProgressoDaTrilha> _variados() => [
      _p(),
      _p(sessoes: 1),
      _p(sessoes: 4),
      _p(sessoes: 30),
      _p(sessoes: 100),
      _p(seq: 30),
      _p(abaixo: 30),
      _p(xp: 5000),
      _p(xp: 99999, sessoes: 100, seq: 100, abaixo: 100),
      _p(sessoes: 5, abaixo: 2, seq: 2, xp: Balanco.xpAcumuladoPara(3)),
      _p(sessoes: 12, abaixo: 4, seq: 6, xp: Balanco.xpAcumuladoPara(6)),
      _p(sessoes: 40, abaixo: 0, seq: 20, xp: Balanco.xpAcumuladoPara(9)),
      _p(sessoes: 2, abaixo: 30, seq: 1),
      _trilhaInteira(),
    ];

AppState _conta({int sessoes = 0, int abaixo = 0, int seq = 0, int xp = 0}) {
  final s = AppState()..startCompanionship();
  s.sessoesConcluidas = sessoes;
  s.diasAbaixoDaMeta = abaixo;
  s.melhorSequencia = seq;
  s.xp = xp;
  return s;
}

Future<void> _abre(WidgetTester tester, AppState app) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppScope(state: app, child: const TrilhaScreen()),
      ),
    ),
  );
  await tester.pump();
}

/// Rola até o alvo aparecer **na tela**, não só na árvore: o caminho é uma
/// `Stack`, então todo nó existe desde o primeiro quadro e um `Finder` cru
/// encerraria a rolagem sem rolar nada.
Future<void> _rolaAte(WidgetTester tester, Finder alvo) =>
    tester.scrollUntilVisible(
      alvo.hitTestable(),
      160,
      scrollable: find.byType(Scrollable).first,
    );

/// Quantos dias de uso engajado até um critério bater.
///
/// A régua que ordena a trilha, escrita como código para poder ser conferida.
/// Um dia engajado são duas sessões de 25 min, presença, missões e o dia
/// fechado abaixo da meta — cerca de 70 XP.
double _diasAte(Criterio c) => switch (c.tipo) {
      TipoDeMarco.sessoes => c.alvo / 1.5,
      TipoDeMarco.sequencia => c.alvo.toDouble(),
      TipoDeMarco.diasAbaixoDaMeta => c.alvo.toDouble(),
      TipoDeMarco.nivel => Balanco.xpAcumuladoPara(c.alvo) / 70,
    };

void main() {
  group('a ordem é obrigatória', () {
    test('cem sessões sem mais nada param no passo 1', () {
      // O caso que o dono do produto descreveu. Antes: onze degraus com ✓,
      // salteados. Agora: um.
      final p = _p(sessoes: 100);
      expect(p.passosConquistados, 1);
      expect(p.conquistados, 1);
      expect(p.proximoMarco?.id, 'primeiro_dia_abaixo');
    });

    test('o degrau adiante com o critério cumprido fica travado', () {
      final p = _p(sessoes: 100);
      for (final m in trilha.where((m) => m.tipo == TipoDeMarco.sessoes)) {
        if (m.id == 'primeiro_foco') continue;
        expect(p.cumpriuOCriterio(m), isTrue, reason: '${m.id}: cem sessões');
        expect(p.alcancou(m), isFalse, reason: '${m.id} conquistou fora da vez');
        expect(p.esperandoAVez(m), isTrue, reason: m.id);
      }
    });

    test('nenhum estado produz um conquistado depois de um não conquistado',
        () {
      for (final p in _variados()) {
        var viuAberto = false;
        for (final m in trilha) {
          if (!p.alcancou(m)) {
            viuAberto = true;
            continue;
          }
          expect(
            viuAberto,
            isFalse,
            reason: '${m.id} conquistado depois de um degrau em aberto',
          );
        }
      }
    });

    test('conquistar o passo N implica ter conquistado todos os anteriores',
        () {
      for (final p in _variados()) {
        for (var i = 0; i < trilha.length; i++) {
          if (!p.alcancou(trilha[i])) continue;
          for (var j = 0; j < i; j++) {
            expect(
              p.alcancou(trilha[j]),
              isTrue,
              reason: '${trilha[i].id} sem ${trilha[j].id}',
            );
          }
        }
      }
    });

    test('a corrente só anda para a frente quando os contadores sobem', () {
      // Os quatro contadores nunca caem (XP, sessões, melhor sequência, dias
      // abaixo da meta), então o prefixo também não pode cair.
      var anterior = 0;
      for (var passo = 0; passo <= trilha.length; passo++) {
        final ate = trilha.take(passo).toList();
        final p = _p(
          sessoes: ate
              .where((m) => m.tipo == TipoDeMarco.sessoes)
              .fold(0, (a, m) => m.alvo > a ? m.alvo : a),
          seq: ate
              .where((m) => m.tipo == TipoDeMarco.sequencia)
              .fold(0, (a, m) => m.alvo > a ? m.alvo : a),
          abaixo: ate
              .where((m) => m.tipo == TipoDeMarco.diasAbaixoDaMeta)
              .fold(0, (a, m) => m.alvo > a ? m.alvo : a),
          xp: Balanco.xpAcumuladoPara(
            ate
                .where((m) => m.tipo == TipoDeMarco.nivel)
                .fold(1, (a, m) => m.alvo > a ? m.alvo : a),
          ),
        );
        expect(p.passosConquistados, greaterThanOrEqualTo(anterior));
        expect(p.passosConquistados, passo, reason: 'parou antes do passo $passo');
        anterior = p.passosConquistados;
      }
    });
  });

  group('o critério continua valendo', () {
    test('é o critério do degrau atual que faz a corrente andar', () {
      // Passo 1 é "sua primeira sessão de foco". Nada mais abre.
      final antes = _p(xp: 9999, seq: 60, abaixo: 60);
      expect(antes.passosConquistados, 0);

      final depois = _p(xp: 9999, seq: 60, abaixo: 60, sessoes: 1);
      expect(depois.passosConquistados, greaterThan(1), reason: 'destravou');
    });

    test('fechado o degrau que faltava, a corrente anda tudo de uma vez', () {
      // Trinta sessões guardadas atrás do passo 2. Fechado o dia abaixo da
      // meta, a fila anda até o próximo critério que ainda não bateu.
      final travado = _p(sessoes: 30);
      expect(travado.passosConquistados, 1);

      final solto = _p(sessoes: 30, abaixo: 1);
      expect(solto.passosConquistados, 2, reason: 'o passo 3 pede nível 3');

      final comNivel = _p(
        sessoes: 30,
        abaixo: 1,
        xp: Balanco.xpAcumuladoPara(3),
      );
      expect(comNivel.passosConquistados, 4, reason: 'passa o 3 e o 4 juntos');
    });

    test('nada atrás do degrau atual fica pendente', () {
      for (final p in _variados()) {
        final atual = p.proximoMarco;
        if (atual == null) continue;
        for (final m in trilha.take(passoDoMarco(atual) - 1)) {
          expect(p.alcancou(m), isTrue, reason: '${m.id} ficou para trás');
        }
      }
    });
  });

  group('um passo por vez na tela', () {
    test('existe exatamente um VOCÊ ESTÁ AQUI, ou nenhum no fim', () {
      for (final p in _variados()) {
        final atuais =
            trilha.where((m) => p.estadoDe(m) == EstadoNaTrilha.atual).length;
        expect(
          atuais,
          p.passosConquistados >= trilha.length ? 0 : 1,
          reason: 'um caminho tem uma frente só',
        );
      }
    });

    test('antes do atual tudo conquistado, depois tudo travado, sem buraco',
        () {
      for (final p in _variados()) {
        final frente = p.passosConquistados;
        for (var i = 0; i < trilha.length; i++) {
          final esperado = i < frente
              ? EstadoNaTrilha.conquistado
              : i == frente
                  ? EstadoNaTrilha.atual
                  : EstadoNaTrilha.travado;
          expect(p.estadoDe(trilha[i]), esperado, reason: trilha[i].id);
        }
      }
    });

    test('o passo mostrado é a posição do degrau atual', () {
      for (final p in _variados()) {
        expect(p.passoAtual, p.passosConquistados + 1 > trilha.length
            ? trilha.length
            : p.passosConquistados + 1);
        expect(p.totalDePassos, trilha.length);
      }
    });
  });

  group('a ordem dos 22 marcos é uma progressão', () {
    test('o esforço nunca cai de um passo para o seguinte', () {
      // O defeito concreto da ordem antiga: o passo 12 (5 dias abaixo da meta,
      // ~5 dias) vinha depois do passo 11 (nível 6, ~8 dias). Enquanto os
      // marcos eram independentes ninguém via; numa corrente é uma parada.
      var anterior = 0.0;
      for (var i = 0; i < trilha.length; i++) {
        final dias = _diasAte(trilha[i].criterio);
        expect(
          dias,
          greaterThanOrEqualTo(anterior - 0.001),
          reason: 'passo ${i + 1} (${trilha[i].id}) é mais fácil que o anterior',
        );
        anterior = dias;
      }
    });

    test('as recompensas crescem em todos os degraus', () {
      var anterior = 0;
      for (final m in trilha) {
        expect(
          m.recompensa.folhas,
          greaterThan(anterior),
          reason: '${m.id} paga menos que o degrau anterior',
        );
        anterior = m.recompensa.folhas;
      }
    });

    test('os alvos de cada tipo crescem ao longo da trilha', () {
      for (final tipo in TipoDeMarco.values) {
        final alvos =
            trilha.where((m) => m.tipo == tipo).map((m) => m.alvo).toList();
        expect(alvos, [...alvos]..sort(), reason: tipo.name);
      }
      final alts = trilha
          .map((m) => m.alternativa)
          .whereType<Criterio>()
          .map((c) => c.alvo)
          .toList();
      expect(alts, [...alts]..sort(), reason: 'alternativas fora de ordem');
    });

    test('habitat e espécie saem em degraus cada vez mais altos', () {
      var ultimoHabitat = 0;
      for (var i = 0; i < trilha.length; i++) {
        final e = trilha[i].recompensa.estagioDeHabitat;
        if (e == null) continue;
        expect(e, greaterThan(ultimoHabitat), reason: trilha[i].id);
        ultimoHabitat = e;
      }
      expect(ultimoHabitat, habitatsDaTrilha.last.estagio);
    });

    test('a escada de recompensas é a mesma de antes, só trocou de dono', () {
      // Reordenar move a folha junto com a posição. O conjunto dos 22 valores
      // não muda: ninguém ganha nem perde folha na soma da trilha inteira.
      expect(
        trilha.map((m) => m.recompensa.folhas).toList(),
        [
          20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 110,
          120, 140, 160, 180, 200, 220, 260, 300, 340, 400, 500,
        ],
      );
    });

    test('os ids são os mesmos de antes — eles são chave de resgate', () {
      // Renomear um id faria o marco pagar de novo (o antigo continua em
      // `marcosResgatados`) e apagaria a linha dele do extrato da carteira.
      expect(trilha.map((m) => m.id).toSet(), {
        'primeiro_foco',
        'primeiro_dia_abaixo',
        'nivel_3',
        'tres_focos',
        'tres_dias',
        'tres_dias_abaixo',
        'cinco_focos',
        'cinco_dias_abaixo',
        'nivel_5',
        'dez_focos',
        'semana_inteira',
        'nivel_6',
        'vinte_focos',
        'duas_semanas',
        'nivel_8',
        'quinze_dias_abaixo',
        'nivel_10',
        'trinta_dias',
        'trinta_dias_abaixo',
        'cinquenta_focos',
        'nivel_15',
        'cem_focos',
      });
      expect(trilha.length, 22);
    });
  });

  group('recusar a permissão de uso não vira muro', () {
    test('sem medição, a trilha inteira continua caminhável', () {
      // `diasAbaixoDaMeta` só anda com a permissão concedida, e recusar é
      // caminho suportado (§8). Numa corrente, um contador parado travaria
      // tudo no passo 2 — para sempre. O segundo caminho existe por isso.
      final p = _p(
        abaixo: 0,
        sessoes: 100,
        seq: 45,
        xp: Balanco.xpAcumuladoPara(15),
      );
      expect(p.passosConquistados, trilha.length);
    });

    test('o passo 2 abre pela presença quando não há o que medir', () {
      expect(_p(sessoes: 1, seq: 3).passosConquistados, 1);
      expect(_p(sessoes: 1, seq: 4).passosConquistados, greaterThan(1));
    });

    test('o desvio é mais caro que o critério principal', () {
      // Se fosse mais barato, quem concedeu a permissão fecharia o passo pelo
      // desvio e o critério do degrau viraria enfeite.
      for (final m in trilha.where((m) => m.alternativa != null)) {
        expect(
          _diasAte(m.alternativa!),
          greaterThan(_diasAte(m.criterio)),
          reason: m.id,
        );
      }
    });

    test('só os marcos que dependem de permissão têm desvio', () {
      for (final m in trilha) {
        if (m.tipo == TipoDeMarco.diasAbaixoDaMeta) {
          expect(m.alternativa, isNotNull, reason: '${m.id} vira muro');
        } else {
          expect(m.alternativa, isNull, reason: '${m.id} não precisa');
        }
      }
    });
  });

  group('a tela mostra a corrente', () {
    testWidgets('um "VOCÊ ESTÁ AQUI" e um só, com 30 sessões guardadas',
        (tester) async {
      final app = _conta(sessoes: 30);
      await _abre(tester, app);
      expect(find.text(app.t.trilhaAqui), findsOneWidget);
    });

    testWidgets('há um ✓ só, e ele é o passo 1', (tester) async {
      // Era o desenho que o dono do produto viu: ✓ salteado trilha abaixo,
      // nos passos de sessão, com cadeado entre eles. Com 30 sessões agora há
      // exatamente um — e quatro degraus de sessão adiante com ampulheta.
      //
      // O caminho é uma `Stack`: todo nó existe na árvore desde o primeiro
      // quadro, então contar aqui cobre a trilha inteira, rolada ou não.
      final app = _conta(sessoes: 30);
      await _abre(tester, app);
      expect(app.progresso.passosConquistados, 1);
      expect(
        tester.widgetList(find.byIcon(Icons.check_rounded)).length,
        1,
        reason: 'um ✓ por degrau conquistado, e só há um conquistado',
      );
      expect(
        tester.widgetList(find.byIcon(Icons.hourglass_bottom_rounded)).length,
        trilha
            .where((m) => app.progresso.esperandoAVez(m))
            .length,
        reason: 'cumpriu o critério e espera a vez',
      );
    });

    testWidgets('o degrau que já cumpriu diz por que não abriu', (tester) async {
      final app = _conta(sessoes: 30);
      await _abre(tester, app);
      final vinte = trilha.firstWhere((m) => m.id == 'vinte_focos');
      await _rolaAte(tester, find.text(tituloDoMarco(app, vinte)));
      await tester.tap(find.text(tituloDoMarco(app, vinte)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text(
          app.t.fill(app.t.s('trilhaEsperaAVez'), {
            'n': passoDoMarco(vinte) - 1,
          }),
        ),
        findsOneWidget,
      );
      // O placar não estoura: são 30 sessões para um alvo de 20.
      expect(find.text('20/20'), findsOneWidget);
      expect(find.text('30/20'), findsNothing);
    });

    testWidgets('o leitor de tela distingue travado de pronto-esperando',
        (tester) async {
      final app = _conta(sessoes: 30);
      await _abre(tester, app);
      final vinte = trilha.firstWhere((m) => m.id == 'vinte_focos');
      final nivel5 = trilha.firstWhere((m) => m.id == 'nivel_5');
      expect(
        find.bySemanticsLabel(
          '${tituloDoMarco(app, vinte)} · ${app.t.s('trilhaProntoTravado')}',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          '${tituloDoMarco(app, nivel5)} · ${app.t.s('trilhaTravado')}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('o degrau de permissão mostra o segundo caminho no detalhe',
        (tester) async {
      final app = _conta(sessoes: 1);
      await _abre(tester, app);
      final passo2 = trilha.firstWhere((m) => m.id == 'primeiro_dia_abaixo');
      expect(app.progresso.proximoMarco?.id, passo2.id);

      // O nome aparece duas vezes — no cartão do topo e no nó do caminho. Só
      // o do caminho abre o detalhe, e ele nasce abaixo da dobra.
      await _rolaAte(tester, find.text(tituloDoMarco(app, passo2)).last);
      await tester.tap(find.text(tituloDoMarco(app, passo2)).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.textContaining(app.t.s('trilhaOuTambem')),
        findsOneWidget,
        reason: 'quem recusou a permissão precisa ver que há saída',
      );
    });

    testWidgets('o cartão do habitat travado mostra o número do passo inteiro',
        (tester) async {
      // Reordenar empurrou o manguezal do passo 9 para o 11, e o rótulo
      // passou a caber por um caractere de folga que não existia: saía "Abre
      // no passo …", escondendo o número que é a razão de a legenda existir.
      final app = _conta();
      await _abre(tester, app);
      final manguezal =
          habitatsDaTrilha.firstWhere((h) => h.id == 'manguezal');
      final legenda = app.t.fill(app.t.s('trilhaAbreNoPasso'), {
        'n': passoQueAbreOHabitat(manguezal),
      });

      final texto = tester.widget<Text>(find.text(legenda));
      final pintado = tester.renderObject<RenderParagraph>(find.text(legenda));
      expect(texto.overflow, isNot(TextOverflow.ellipsis));
      expect(
        pintado.size.width,
        lessThanOrEqualTo(pintado.constraints.maxWidth + 0.5),
        reason: 'o texto ainda estoura a caixa do cartão',
      );
    });

    testWidgets('os textos novos existem nos 4 idiomas', (tester) async {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final app = _conta(sessoes: 30)..lang = lang;
        final vinte = trilha.firstWhere((m) => m.id == 'vinte_focos');
        final passo2 = trilha.firstWhere((m) => m.id == 'primeiro_dia_abaixo');
        for (final frase in [
          oQueFaltaNoMarco(app, vinte),
          app.t.s('trilhaProntoTravado'),
          app.t.s('trilhaOuTambem'),
          oQueFaltaNoMarco(app, passo2),
        ]) {
          expect(frase, isNotEmpty, reason: lang);
          expect(frase, isNot(contains('{')), reason: lang);
          expect(frase, isNot(startsWith('trilha')), reason: lang);
        }
      }
    });
  });

  group('migração: quem já jogava não perde nada', () {
    /// Uma conta do modelo antigo: marcos salteados, já pagos.
    ///
    /// Trinta sessões e nenhum dia abaixo da meta — o formato que mais
    /// produzia buraco na trilha. O modelo antigo pagou todo marco de sessão.
    AppState legado() {
      final s = AppState()..startCompanionship();
      s.sessoesConcluidas = 30;
      final pagos = trilha
          .where((m) => m.tipo == TipoDeMarco.sessoes && m.alvo <= 30)
          .toList();
      s.marcosResgatados = pagos.map((m) => m.id).toSet();
      s.leaves = pagos.fold(0, (a, m) => a + m.recompensa.folhas);
      return s;
    }

    test('as folhas já creditadas continuam no saldo', () {
      final s = legado();
      final antes = s.leaves;
      s.ganhaXp(1);
      expect(s.leaves, antes, reason: 'a virada não estorna nada');
      expect(
        s.progresso.conquistados,
        lessThan(s.marcosResgatados.length),
        reason: 'a corrente é mais curta que o que já foi pago — é o caso '
            'que este grupo existe para cobrir',
      );
      s.dispose();
    });

    test('o extrato continua listando os marcos já pagos', () {
      // A carteira lê `marcosResgatados`, não a trilha: um degrau que voltou
      // a ficar travado continua no histórico, porque ele **foi** pago.
      final s = legado();
      final carteira = Carteira(s.toSnapshot());
      expect(
        carteira.totalDeMarcos,
        s.leaves,
        reason: 'folha paga sem linha no extrato é folha que sumiu',
      );
      s.dispose();
    });

    test('o marco já pago não paga de novo quando a corrente chega nele', () {
      final s = legado();
      final antes = s.leaves;
      final jaPagos = {...s.marcosResgatados};
      // A corrente anda até o fim: dia abaixo da meta, presença, nível e as
      // sessões que ainda faltavam.
      s.diasAbaixoDaMeta = 30;
      s.melhorSequencia = 30;
      s.sessoesConcluidas = 100;
      s.xp = Balanco.xpAcumuladoPara(15);
      s.ganhaXp(1);

      expect(s.progresso.passosConquistados, trilha.length);
      final soOsNovos = trilha
          .where((m) => !jaPagos.contains(m.id))
          .fold<int>(0, (a, m) => a + m.recompensa.folhas);
      expect(
        s.leaves,
        antes + soOsNovos,
        reason: 'pagar duas vezes seria imprimir folhas',
      );
      s.dispose();
    });

    test('o XP não é tocado pela virada', () {
      final s = legado();
      s.xp = 777;
      final p = s.progresso;
      expect(p.xp, 777);
      expect(s.nivel, Balanco.nivelPara(777));
      s.dispose();
    });

    test('o piso de migração segura a espécie que já era da conta', () {
      // Trinta sessões: o modelo antigo entregou o axolote (passo 13) e a
      // Serra (habitat 4). Pela corrente eles ainda não chegaram.
      const jaEntregues = {'primeiro_foco', 'cinco_focos', 'vinte_focos'};
      final semPiso = _p(sessoes: 30);
      final comPiso = _p(sessoes: 30, entregues: jaEntregues);

      expect(semPiso.especiesLiberadas(Species.capybara), {Species.capybara});
      expect(
        comPiso.especiesLiberadas(Species.capybara),
        containsAll([Species.otter, Species.axolotl]),
        reason: 'tirar de volta um bicho já entregue é punição (§1)',
      );
    });

    test('o piso de migração segura o habitat que já era da conta', () {
      const jaEntregues = {'vinte_focos'};
      expect(_p(sessoes: 30).estagioDoHabitat, 1);
      expect(_p(sessoes: 30, entregues: jaEntregues).estagioDoHabitat, 4);
      expect(
        _p(sessoes: 30, entregues: jaEntregues).habitatLiberado('serra'),
        isTrue,
      );
    });

    test('o piso não devolve o ✓ nem cria buraco no caminho', () {
      // O piso é sobre **posse**, não sobre posição: se ele contasse como
      // conquista, a trilha voltaria a ter degrau marcado no meio do travado.
      final p = _p(sessoes: 30, entregues: const {'vinte_focos'});
      final vinte = trilha.firstWhere((m) => m.id == 'vinte_focos');
      expect(p.alcancou(vinte), isFalse);
      expect(p.estadoDe(vinte), EstadoNaTrilha.travado);
      expect(p.passosConquistados, 1);
    });
  });
}
