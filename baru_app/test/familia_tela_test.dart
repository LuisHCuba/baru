import 'package:baru_app/data/familia.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_familia.dart';
import 'package:baru_app/l10n_local.dart';
import 'package:baru_app/screens/mapa_familia_screen.dart';
import 'package:baru_app/screens/familia_screen.dart';
import 'package:baru_app/services/localizacao.dart';
import 'package:baru_app/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Banco falso: devolve o que o teste mandar e anota as chamadas.
class _RepoFalso extends FamiliaRepo {
  _RepoFalso(this.estado);

  MinhaFamilia estado;
  final chamadas = <String>[];

  @override
  Future<MinhaFamilia> minha() async => estado;

  @override
  Future<String> criar(String nome, {String tipo = 'familia'}) async {
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

  /// Quando o teste precisa de posições, ele define o mapa; senão, o mapa sai das crianças da família.
  MapaDaFamilia? mapaFalso;

  @override
  Future<MapaDaFamilia> mapa(String familiaId) async => mapaFalso ?? _mapaDe(estado, familiaId);

  MapaDaFamilia _mapaDe(MinhaFamilia m, String familiaId) {
    final f = m.familias.where((x) => x.id == familiaId).firstOrNull;
    return MapaDaFamilia(criancas: [
      for (final c in f?.criancas ?? const <CriancaNaFamilia>[])
        CriancaNoMapa(id: c.id, apelido: c.apelido ?? '—', plataforma: c.plataforma, localizacao: c.regras.localizacao),
    ]);
  }

  @override
  Future<List<PosicaoDaCrianca>> rastro(String criancaId, {int horas = 24}) async => const [];

  @override
  Future<RegrasDaFamilia> localizacao(String criancaId, {required bool ligada}) async {
    chamadas.add('local:$criancaId:$ligada');
    return RegrasDaFamilia(localizacao: ligada);
  }

  @override
  Future<void> pedirLocal(String criancaId) async => chamadas.add('pedir:$criancaId');

  @override
  Future<LugarDaFamilia> salvarLugar(String familiaId, {String? id, required String nome, required double lat, required double lng, int raioM = 150}) async {
    chamadas.add('lugar:$nome:$raioM');
    return LugarDaFamilia(id: 'l1', nome: nome, lat: lat, lng: lng, raioM: raioM);
  }

  @override
  Future<MinhaFamilia> entrar(String codigo, {required String plataforma}) async {
    chamadas.add('entrar:${codigo.toUpperCase()}');
    return estado;
  }
}

Future<_RepoFalso> _abre(WidgetTester tester, MinhaFamilia estado, {bool comConta = true, bool notificacoes = true}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final repo = _RepoFalso(estado);
  final app = AppState();
  addTearDown(app.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: AppScope(state: app, child: FamiliaScreen(repo: repo, comConta: comConta, semMapa: true, sondaSobreposicao: () async => true, sondaFiltro: () async => true, sondaNotificacoes: () async => notificacoes))),
  ));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    garanteTextosDaFamilia();
    LocalNativo.sonda = (metodo, [args]) async => metodo == 'estado' ? 'quando_usa' : null;
  });
  tearDown(() => LocalNativo.sonda = null);

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
    // Quem cria vira responsável: vê o mapa com o nome da família e ainda sem crianças.
    expect(find.text('Casa Cuba'), findsOneWidget);
    expect(find.text(textosDaFamilia['pt']!['famSemCriancasCorpo']!), findsOneWidget);
    expect(find.byKey(const Key('familia-gerar')), findsOneWidget);
  });

  testWidgets('o código digitado vai em maiúsculas', (tester) async {
    final repo = await _abre(tester, MinhaFamilia.vazia);
    await tester.enterText(find.byType(TextField).last, 'ab2cd3');
    await tester.ensureVisible(find.byKey(FamiliaScreen.chaveEntrar));
    await tester.tap(find.byKey(FamiliaScreen.chaveEntrar));
    await tester.pumpAndSettle();
    expect(repo.chamadas, ['entrar:AB2CD3']);
  });

  testWidgets('responsável com notificações desligadas vê o alerta no topo', (tester) async {
    final familia = MinhaFamilia.doMapa({
      'souCrianca': false,
      'familias': [
        {
          'id': 'f1',
          'nome': 'Casa',
          'meuPapel': 'responsavel',
          'responsaveis': [],
          'criancas': [
            {'id': 'c1', 'apelido': 'Nina', 'regras': {'meta_min': 60}, 'semana': []},
          ],
          'eventos': [],
        },
      ],
    });
    await _abre(tester, familia, notificacoes: false);
    expect(find.byKey(const Key('familia-notif-desligadas')), findsOneWidget);
    expect(find.text(textosDaFamilia['pt']!['famNotifOffBotao']!), findsOneWidget);
  });

  testWidgets('com notificações ligadas não há alerta', (tester) async {
    final familia = MinhaFamilia.doMapa({
      'souCrianca': false,
      'familias': [
        {'id': 'f1', 'nome': 'Casa', 'meuPapel': 'responsavel', 'responsaveis': [], 'criancas': [], 'eventos': []},
      ],
    });
    await _abre(tester, familia);
    expect(find.byKey(const Key('familia-notif-desligadas')), findsNothing);
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
    // Na folha, Nina aparece na lista e a atividade do dia vem logo abaixo.
    expect(find.text('Nina'), findsOneWidget);
    expect(find.text('Nina usou 75% da meta'), findsOneWidget);
    // Escolhendo a Nina, aparece o uso de hoje.
    await tester.tap(find.text('Nina'));
    await tester.pumpAndSettle();
    expect(find.textContaining('45min de 1h'), findsOneWidget);
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
    await tester.tap(find.byTooltip(textosDaFamilia['pt']!['famAddCrianca']!));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('familia-apelido')), 'Nina');
    // A folha do mapa também tem o botão "familia-gerar" por trás do diálogo: vale o do diálogo.
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byKey(const Key('familia-gerar'))));
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
    await tester.tap(find.byTooltip(textosDaFamilia['pt']!['famAddCrianca']!));
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
    await tester.tap(find.text('Nina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+15 min'));
    await tester.pumpAndSettle();
    expect(repo.chamadas, ['extra:c1:15']);
    await tester.tap(find.byTooltip(textosDaFamilia['pt']!['famEditarRegras']!));
    await tester.pumpAndSettle();
    expect(find.text(textosDaFamilia['pt']!['famMetaUteis']!), findsOneWidget);
    expect(find.text(textosDaFamilia['pt']!['famAvisosT']!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  MinhaFamilia comNina({bool local = false}) => MinhaFamilia.doMapa({
        'souCrianca': false,
        'familias': [
          {
            'id': 'f1', 'nome': 'Casa', 'meuPapel': 'responsavel', 'responsaveis': [],
            'criancas': [
              {'id': 'c1', 'apelido': 'Nina', 'regras': {'meta_min': 60, 'localizacao': local}, 'semana': []},
            ],
            'eventos': [
              {'em': DateTime.now().toIso8601String(), 'tipo': 'chegou', 'crianca_id': 'c1', 'detalhe': {'lugar': 'Escola'}},
              {'em': DateTime.now().toIso8601String(), 'tipo': 'sos', 'crianca_id': 'c1'},
            ],
          },
        ],
      });

  testWidgets('ligar a localização pede o consentimento do responsável', (tester) async {
    final repo = await _abre(tester, comNina());
    expect(find.text('Nina chegou em Escola'), findsOneWidget);
    expect(find.text('Nina pediu ajuda (SOS)'), findsOneWidget);
    await tester.tap(find.text('Nina'));
    await tester.pumpAndSettle();
    expect(find.text('Ver onde Nina está'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('local-c1')));
    await tester.tap(find.byKey(const Key('local-c1')));
    await tester.pumpAndSettle();
    expect(find.text('Ligar a localização de Nina?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('local-consentir')));
    await tester.pumpAndSettle();
    expect(repo.chamadas, ['local:c1:true']);
  });

  testWidgets('com a localização ligada mostra onde está e pede posição nova', (tester) async {
    final repo = _RepoFalso(comNina(local: true))
      ..mapaFalso = MapaDaFamilia.doMapa({
        'lugares': [],
        'criancas': [
          {'id': 'c1', 'apelido': 'Nina', 'localizacao': true,
           'atual': {'lat': -23.5, 'lng': -46.6, 'em': DateTime.now().subtract(const Duration(minutes: 5)).toUtc().toIso8601String(), 'bateria': 80, 'lugar': 'Escola', 'motivo': 'periodico'}},
        ],
      });
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final app = AppState();
    addTearDown(app.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppScope(state: app,
        child: FamiliaScreen(repo: repo, comConta: true, semMapa: true, sondaSobreposicao: () async => true, sondaFiltro: () async => true)))));
    await tester.pumpAndSettle();
    // Na lista da folha, a linha da Nina mostra onde ela está; o botão "Atualizar" fica nela.
    // (O de cima do mapa tem a mesma dica, então o procura só dentro da folha.)
    expect(find.text('Em Escola · há 5 min · bateria 80%'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byTooltip(textosDoLocal['pt']!['locAtualizar']!),
    ));
    await tester.pumpAndSettle();
    expect(repo.chamadas, ['pedir:c1']);
  });

  testWidgets('criança com localização ligada vê o aviso, a permissão e o SOS', (tester) async {
    await _abre(
      tester,
      MinhaFamilia.doMapa({
        'souCrianca': true,
        'minhasRegras': {'meta_min': 90, 'localizacao': true},
        'familias': [
          {'id': 'f1', 'nome': 'Casa', 'meuPapel': 'crianca', 'responsaveis': [{'email': 'mae@exemplo.com'}], 'criancas': [{'apelido': 'Nina'}]},
        ],
      }),
    );
    expect(find.text('Sua família vê onde você está'), findsOneWidget);
    expect(find.text('Permitir "sempre"'), findsOneWidget);
    expect(find.byKey(const Key('familia-sos')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('familia-sos')));
    await tester.longPress(find.byKey(const Key('familia-sos')));
    await tester.pumpAndSettle();
    expect(find.text('Pedir ajuda?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('localização ligada sem permissão: aviso em destaque antes de pedir', (tester) async {
    final pedidos = <String>[];
    LocalNativo.sonda = (metodo, [args]) async {
      pedidos.add(metodo);
      return metodo == 'estado' ? 'nao_pedida' : null;
    };
    await _abre(
      tester,
      MinhaFamilia.doMapa({
        'souCrianca': true,
        'minhasRegras': {'meta_min': 90, 'localizacao': true},
        'familias': [
          {'id': 'f1', 'nome': 'Casa', 'meuPapel': 'crianca', 'responsaveis': [{'email': 'mae@exemplo.com'}], 'criancas': [{'apelido': 'Nina'}]},
        ],
      }),
    );
    expect(find.text(textosDoLocal['pt']!['locDiscT']!), findsOneWidget);
    expect(pedidos, isNot(contains('pedir')), reason: 'não pede antes do aviso');
    await tester.tap(find.byKey(const Key('local-aviso-nao')));
    await tester.pumpAndSettle();
    expect(pedidos, isNot(contains('pedir')), reason: '"Agora não" não pede');
  });

  testWidgets('no mapa, segurar marca um lugar com nome e raio', (tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final repo = _RepoFalso(MinhaFamilia.vazia);
    await tester.pumpWidget(MaterialApp(home: MapaFamiliaScreen(familiaId: 'f1', t: T('pt'), repo: repo, semMapa: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(textosDoLocal['pt']!['locSemLugares']!), findsOneWidget);
  });

  test('há quanto tempo, curto', () {
    garanteTextosDaFamilia();
    final t = T('pt');
    final agora = DateTime(2026, 11, 19, 12);
    expect(haQuanto(t, agora, agora: agora), 'agora mesmo');
    expect(haQuanto(t, agora.subtract(const Duration(minutes: 7)), agora: agora), 'há 7 min');
    expect(haQuanto(t, agora.subtract(const Duration(hours: 3)), agora: agora), 'há 3 h');
    expect(haQuanto(t, agora.subtract(const Duration(days: 2)), agora: agora), 'há 2 d');
  });

  test('os textos da localização existem nos quatro idiomas', () {
    final pt = textosDoLocal['pt']!.keys.toSet();
    for (final l in ['en', 'es', 'zh']) {
      expect(textosDoLocal[l]!.keys.toSet(), pt, reason: l);
    }
  });

  test('os quatro idiomas têm as mesmas chaves', () {
    final pt = textosDaFamilia['pt']!.keys.toSet();
    for (final l in ['en', 'es', 'zh']) {
      expect(textosDaFamilia[l]!.keys.toSet(), pt, reason: l);
    }
  });
}
