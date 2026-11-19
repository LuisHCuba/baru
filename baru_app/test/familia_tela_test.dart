import 'package:baru_app/data/familia.dart';
import 'package:baru_app/l10n_familia.dart';
import 'package:baru_app/screens/familia_screen.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Banco falso: devolve o que o teste mandar e anota as chamadas.
class _RepoFalso extends FamiliaRepo {
  _RepoFalso(this.estado);

  MinhaFamilia estado;
  final chamadas = <String>[];

  @override
  Future<MinhaFamilia> minha() async => estado;

  @override
  Future<String> criar(String nome) async {
    chamadas.add('criar:$nome');
    estado = MinhaFamilia.doMapa({
      'souCrianca': false,
      'familias': [
        {'id': 'f1', 'nome': nome, 'meuPapel': 'responsavel', 'responsaveis': [], 'criancas': [], 'eventos': []},
      ],
    });
    return 'f1';
  }

  @override
  Future<ConviteDaFamilia> convidar(String familiaId, {bool crianca = true, String? apelido}) async {
    chamadas.add('convidar:$familiaId:$crianca:$apelido');
    return ConviteDaFamilia(codigo: 'AB2CD3', expiraEm: DateTime.now().add(const Duration(minutes: 30)), papel: crianca ? 'crianca' : 'responsavel');
  }

  @override
  Future<RegrasDaFamilia> tempoExtra(String criancaId, int minutos) async {
    chamadas.add('extra:$criancaId:$minutos');
    return const RegrasDaFamilia();
  }

  @override
  Future<MinhaFamilia> entrar(String codigo, {required String plataforma}) async {
    chamadas.add('entrar:${codigo.toUpperCase()}');
    return estado;
  }
}

Future<_RepoFalso> _abre(WidgetTester tester, MinhaFamilia estado, {bool comConta = true}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final repo = _RepoFalso(estado);
  final app = AppState();
  addTearDown(app.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AppScope(state: app, child: FamiliaScreen(repo: repo, comConta: comConta, sondaSobreposicao: () async => true, sondaFiltro: () async => true))),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUp(garanteTextosDaFamilia);

  testWidgets('sem conta, pede para entrar', (tester) async {
    await _abre(tester, MinhaFamilia.vazia, comConta: false);
    expect(find.text(textosDaFamilia['pt']!['famSemConta']!), findsOneWidget);
  });

  testWidgets('sem família, oferece criar e entrar; criar vira responsável', (tester) async {
    final repo = await _abre(tester, MinhaFamilia.vazia);
    expect(find.text(textosDaFamilia['pt']!['famSouResp']!), findsOneWidget);
    expect(find.text(textosDaFamilia['pt']!['famSouCrianca']!), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Casa Cuba');
    await tester.ensureVisible(find.byKey(FamiliaScreen.chaveCriar));
    await tester.tap(find.byKey(FamiliaScreen.chaveCriar));
    await tester.pumpAndSettle();
    expect(repo.chamadas, ['criar:Casa Cuba']);
    expect(find.text('Casa Cuba'), findsOneWidget);
    expect(find.text(textosDaFamilia['pt']!['famSemCriancas']!), findsOneWidget);
  });

  testWidgets('o código digitado vai em maiúsculas', (tester) async {
    final repo = await _abre(tester, MinhaFamilia.vazia);
    await tester.enterText(find.byType(TextField).last, 'ab2cd3');
    await tester.ensureVisible(find.byKey(FamiliaScreen.chaveEntrar));
    await tester.tap(find.byKey(FamiliaScreen.chaveEntrar));
    await tester.pumpAndSettle();
    expect(repo.chamadas, ['entrar:AB2CD3']);
  });

  testWidgets('responsável vê a criança, o uso de hoje e os avisos', (tester) async {
    await _abre(
      tester,
      MinhaFamilia.doMapa({
        'souCrianca': false,
        'familias': [
          {
            'id': 'f1',
            'nome': 'Casa',
            'meuPapel': 'responsavel',
            'responsaveis': [],
            'criancas': [
              {
                'id': 'c1',
                'apelido': 'Nina',
                'plataforma': 'android',
                'regras': {'meta_min': 60},
                'hoje': {'dia': '2026-11-18', 'minutos': 45, 'focos': 2, 'pausas': 0},
                'semana': [],
              },
            ],
            'eventos': [
              {'em': DateTime.now().toIso8601String(), 'tipo': 'meta_75', 'crianca_id': 'c1'},
            ],
          },
        ],
      }),
    );
    expect(find.text('Nina'), findsOneWidget);
    expect(find.textContaining('45min de 1h'), findsOneWidget);
    expect(find.text('Nina usou 75% da meta'), findsOneWidget);
  });

  testWidgets('criança vê a meta da família', (tester) async {
    await _abre(
      tester,
      MinhaFamilia.doMapa({
        'souCrianca': true,
        'minhasRegras': {'meta_min': 90, 'horarios_sem_tela': []},
        'familias': [
          {'id': 'f1', 'nome': 'Casa', 'meuPapel': 'crianca', 'responsaveis': [{'email': 'mae@exemplo.com'}], 'criancas': [{'apelido': 'Nina'}]},
        ],
      }),
    );
    expect(find.text('Família Casa'), findsOneWidget);
    expect(find.text('Quem cuida: mae@exemplo.com'), findsOneWidget);
    expect(find.text(textosDaFamilia['pt']!['famMinhaMeta']!.toUpperCase()), findsOneWidget);
  });

  testWidgets('adicionar criança mostra o código sem quebrar a tela', (tester) async {
    final repo = await _abre(
      tester,
      MinhaFamilia.doMapa({
        'souCrianca': false,
        'familias': [
          {'id': 'f1', 'nome': 'Casa', 'meuPapel': 'responsavel', 'responsaveis': [], 'criancas': [], 'eventos': []},
        ],
      }),
    );
    await tester.tap(find.text(textosDaFamilia['pt']!['famAddCrianca']!).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('familia-apelido')), 'Nina');
    await tester.tap(find.byKey(const Key('familia-gerar')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repo.chamadas, ['convidar:f1:true:Nina']);
    expect(find.byKey(const Key('familia-codigo')), findsOneWidget);
    expect(find.text('AB2CD3'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar o apelido não gera código', (tester) async {
    final repo = await _abre(
      tester,
      MinhaFamilia.doMapa({
        'souCrianca': false,
        'familias': [
          {'id': 'f1', 'nome': 'Casa', 'meuPapel': 'responsavel', 'responsaveis': [], 'criancas': [], 'eventos': []},
        ],
      }),
    );
    await tester.tap(find.text(textosDaFamilia['pt']!['famAddCrianca']!).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(textosDaFamilia['pt']!['famCancelar']!));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(repo.chamadas, isEmpty);
  });

  testWidgets('responsável dá tempo extra e abre as regras', (tester) async {
    final repo = await _abre(
      tester,
      MinhaFamilia.doMapa({
        'souCrianca': false,
        'familias': [
          {
            'id': 'f1', 'nome': 'Casa', 'meuPapel': 'responsavel', 'responsaveis': [], 'eventos': [],
            'criancas': [
              {'id': 'c1', 'apelido': 'Nina', 'regras': {'meta_min': 60, 'horarios_sem_tela': []}, 'semana': []},
            ],
          },
        ],
      }),
    );
    await tester.tap(find.text(textosDaFamilia['pt']!['famMais15']!));
    await tester.pumpAndSettle();
    expect(repo.chamadas, ['extra:c1:15']);
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(find.text(textosDaFamilia['pt']!['famMetaUteis']!), findsOneWidget);
    expect(find.text(textosDaFamilia['pt']!['famAvisosT']!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('os quatro idiomas têm as mesmas chaves', () {
    final pt = textosDaFamilia['pt']!.keys.toSet();
    for (final l in ['en', 'es', 'zh']) {
      expect(textosDaFamilia[l]!.keys.toSet(), pt, reason: l);
    }
  });
}
