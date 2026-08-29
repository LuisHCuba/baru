import 'dart:io';

import 'package:baru_app/app.dart';
import 'package:baru_app/data/app_snapshot.dart';
import 'package:baru_app/data/descanso_do_dia.dart';
import 'package:baru_app/models.dart';
import 'package:baru_app/l10n.dart';
import 'package:baru_app/l10n_descanso.dart';
import 'package:baru_app/l10n_notificacao.dart';
import 'package:baru_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Uma contagem só na barra, e ela anda.**
///
/// O defeito, que este arquivo tranca: durante uma sessão de foco havia
/// **duas** notificações vivas ao mesmo tempo. A do plugin (id 1004, canal
/// `baru_sessao`), com o cronômetro do Android; e a do `VigiaDaSessao`
/// (id 4711, canal `baru_vigia`), que é um serviço em primeiro plano e por
/// isso **obrigatoriamente** tem notificação própria — essa, sem cronômetro
/// nenhum. Ids diferentes não se sobrescrevem: o `NotificationManager`
/// guarda por (pacote, tag, id) e nenhuma das duas usava tag. O resultado
/// eram duas linhas com o mesmo título e o mesmo corpo, e só uma contando —
/// e a que o Android garante manter é justamente a do serviço, a parada.
///
/// O que **não** dá para provar aqui: que o system UI desenha o cronômetro
/// andando. Isso é o sistema operacional, não roda em `flutter test`, e está
/// registrado em BLOCKERS.md.
///
/// O que dá, e é onde os erros moram:
/// 1. os dois lados apontam para o **mesmo** id e o **mesmo** canal;
/// 2. a notificação que o Kotlin desenha carrega o cronômetro;
/// 3. só uma missão fica com a barra por vez;
/// 4. os botões chegam ao app em vez de morrerem no caminho.

/// O Kotlin do vigia, lido como texto.
///
/// Não é elegante, e é o único jeito: o contrato aqui atravessa duas
/// linguagens e `flutter test` não roda Kotlin. Mesma técnica de
/// `manifest_release_test.dart`, pelo mesmo motivo — o que quebra em
/// produção é a **divergência** entre os dois lados, e ela só é visível
/// olhando os dois.
final _vigia = File(
  'android/app/src/main/kotlin/com/lhcx/baru_app/VigiaDaSessao.kt',
).readAsStringSync();

/// Grava o que foi para o lado nativo.
class _CanalEspiao {
  _CanalEspiao(this.nome);

  final String nome;
  final chamadas = <MethodCall>[];

  /// O que o lado nativo devolve para `acaoPendente`.
  String? acaoGuardada;

  MethodChannel arma() {
    final canal = MethodChannel(nome);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (chamada) async {
      chamadas.add(chamada);
      if (chamada.method == 'acaoPendente') return acaoGuardada;
      return null;
    });
    return canal;
  }

  Map<Object?, Object?>? get ultimaContagem {
    for (final c in chamadas.reversed) {
      if (c.method == 'contagem') return c.arguments as Map<Object?, Object?>;
    }
    return null;
  }
}

/// Um estado gravado com uma sessão de foco em curso.
///
/// É o retrato de quem foi morto pelo sistema no meio do foco: a sessão
/// continua valendo (o relógio a reconcilia), e a notificação dela ficou na
/// barra.
AppSnapshot _comSessaoEmCurso() {
  final agora = DateTime.now();
  return AppSnapshot(
    screen: AppScreen.session,
    onb: 9,
    lang: 'pt',
    species: Species.capybara,
    q0: '',
    q1: '',
    q2: '',
    leaves: 0,
    streak: 0,
    usage: 0,
    goal: 150,
    avg: 200,
    petName: 'Baru',
    color: 0,
    owned: const [],
    dur: 25,
    completedToday: 0,
    abandonedToday: false,
    daysAway: 0,
    trial: false,
    evening: false,
    missed: false,
    payPlan: PayPlan.annual,
    usageAccess: false,
    companionshipStarted: true,
    week: freshWeek(agora),
    todayIndex: weekdayIndex(agora),
    freezesLeft: 1,
    trialStartedAt: null,
    lastOpenDate: DateTime(agora.year, agora.month, agora.day),
    sessions: const [],
    sessionStartedAt: agora.subtract(const Duration(minutes: 5)),
    sessionEndsAt: agora.add(const Duration(minutes: 20)),
    sessionDur: 25,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CanalEspiao barra;

  setUp(() {
    barra = _CanalEspiao('baru/barra-teste');
    BaruNotifications.instance
      ..preparaParaTeste()
      ..canalDaBarra = barra.arma();
    // O plugin de notificação é registrado pelo lado nativo no arranque. Em
    // teste, `FlutterLocalNotificationsPlatform.instance` é um `late` sem
    // valor e a primeira chamada a `show` estoura antes de exercitar regra
    // nenhuma. Registrar a implementação Android e dublar o canal dela faz o
    // caminho inteiro rodar sem plataforma.
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      // `initialize` é tipado `bool`; devolver nulo estoura antes de o
      // teste chegar na regra.
      (chamada) async => chamada.method == 'initialize' ? true : null,
    );
    // `hasPermission` consulta o `permission_handler`. Sem plataforma ele
    // estoura; aqui a permissão é concedida (1 = `granted`), que é o caminho
    // em que existe alguma coisa a provar.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (_) async => 1,
    );
    addTearDown(() {
      for (final canal in const [
        MethodChannel('flutter.baseflow.com/permissions/methods'),
        MethodChannel('dexterous.com/flutter/local_notifications'),
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(canal, null);
      }
      BaruNotifications.instance.preparaParaTeste();
    });
  });

  group('os dois lados escrevem na mesma notificação', () {
    test('o Kotlin usa o id e o canal do Dart', () {
      expect(
        _vigia,
        contains('const val ID_PADRAO = ${BaruNotifications.sessaoId}'),
        reason: 'id diferente do lado nativo = uma segunda notificação, '
            'porque o NotificationManager guarda por id',
      );
      expect(
        _vigia,
        contains("const val CANAL_PADRAO = \"${BaruNotifications.canalSessao}\""),
      );
    });

    test('a segunda notificação não existe mais', () {
      // O id e o canal antigos (4711 / `baru_vigia`) ainda aparecem nos
      // comentários, e é bom que apareçam — é a explicação do defeito. O que
      // não pode voltar é **código** com id ou canal próprios.
      expect(
        _vigia,
        isNot(contains('const val ID_NOTIF')),
        reason: 'era a constante do id concorrente',
      );
      expect(
        _vigia,
        isNot(contains(RegExp(r'const val CANAL\s*='))),
        reason: 'era o canal separado que impedia a fusão das duas',
      );
      expect(
        RegExp(r'startForeground\(').allMatches(_vigia).length,
        1,
        reason: 'um `startForeground` só, com um id só',
      );
      expect(
        _vigia,
        contains('startForeground(contagem.id, notificacao(contagem))'),
        reason: 'o id tem de ser o que o Dart mandou, não um do Kotlin',
      );
      expect(
        _vigia,
        contains('NotificationCompat.Builder(this, c.canal)'),
        reason: 'o canal também',
      );
    });

    test('o id e o canal viajam do Dart para o nativo', () async {
      await BaruNotifications.instance.mostraSessao(
        terminaEm: DateTime.now().add(const Duration(minutes: 25)),
        titulo: 'Baru está em foco',
        corpo: 'Volte quando acabar.',
        rotuloDesistir: 'Desistir',
      );

      final args = barra.ultimaContagem;
      expect(args, isNotNull);
      expect(args!['id'], BaruNotifications.sessaoId);
      expect(args['canal'], BaruNotifications.canalSessao);
    });
  });

  group('o rótulo de voltar vem do catálogo, não do Kotlin', () {
    test('a sessão leva o rótulo para o lado nativo', () async {
      // Função e não valor: o idioma muda nos ajustes e a notificação pode
      // ser postada horas depois. Nulo (teste, web) = sem botão, e o toque
      // no corpo continua abrindo o app.
      BaruNotifications.instance.rotuloDeVolta = () => 'Voltar ao Baru';

      await BaruNotifications.instance.mostraSessao(
        terminaEm: DateTime.now().add(const Duration(minutes: 25)),
        titulo: 't',
        corpo: 'c',
        rotuloDesistir: 'Desistir',
      );

      final args = barra.ultimaContagem!;
      expect(args['rotuloVoltar'], 'Voltar ao Baru');
      expect(args['idVoltar'], BaruNotifications.acaoVoltar);
    });

    test('sem quem forneça o rótulo, não vai botão nenhum', () async {
      await BaruNotifications.instance.mostraSessao(
        terminaEm: DateTime.now().add(const Duration(minutes: 25)),
        titulo: 't',
        corpo: 'c',
        rotuloDesistir: 'Desistir',
      );

      expect(
        barra.ultimaContagem!['rotuloVoltar'],
        '',
        reason: 'um botão sem palavra seria o lado nativo inventando uma',
      );
    });
  });

  group('a contagem que o Kotlin desenha', () {
    test('é o cronômetro do sistema, regressivo, até o instante de término', () {
      // É esta configuração que faz a contagem andar com o app morto: quem
      // desenha é o system UI, a partir do timestamp (ADR-011).
      expect(_vigia, contains('.setUsesChronometer(true)'));
      expect(_vigia, contains('.setChronometerCountDown(true)'));
      expect(
        _vigia,
        contains('.setWhen(c.terminaEm)'),
        reason: 'sem `when` no fim real, o cronômetro conta de outro instante',
      );
    });

    test('aparece na tela de bloqueio com o conteúdo à mostra', () {
      // O padrão do Android é `VISIBILITY_PRIVATE`: num bloqueio seguro a
      // linha aparece e o conteúdo vira "conteúdo oculto" — e o conteúdo,
      // aqui, é a contagem.
      expect(_vigia, contains('NotificationCompat.VISIBILITY_PUBLIC'));
      expect(_vigia, contains('NotificationCompat.CATEGORY_STOPWATCH'));
    });

    test('prazo vencido não vira cronômetro', () {
      // `usesChronometer` sem prazo válido mostra um contador subindo a
      // partir de um instante qualquer — um número errado é pior que nenhum.
      expect(_vigia, contains('fun viva(agora: Long): Boolean = terminaEm > agora'));
      expect(_vigia, contains('if (c.viva(System.currentTimeMillis()))'));
    });

    test('desligar o vigia não apaga a contagem de uma sessão que corre', () {
      // O vigia também é desligado quando a **missão do descanso** acaba, e
      // nada impede uma sessão de foco correndo junto. Com a notificação
      // agora sendo a mesma, um `REMOVE` cego tiraria da barra o cronômetro
      // de uma sessão viva — o timer sumindo sozinho.
      expect(_vigia, contains('STOP_FOREGROUND_DETACH'));
      expect(
        _vigia,
        contains('if (aindaConta) STOP_FOREGROUND_DETACH else STOP_FOREGROUND_REMOVE'),
      );
    });
  });

  group('uma missão de cada vez na barra', () {
    final daquiA10 = DateTime.now().add(const Duration(minutes: 10));

    Future<void> comecaOFoco() => BaruNotifications.instance.mostraSessao(
          terminaEm: daquiA10,
          titulo: 'foco',
          corpo: 'c',
          rotuloDesistir: 'Desistir',
        );

    Future<void> comecaODescanso() =>
        BaruNotifications.instance.mostraDescanso(
          terminaEm: daquiA10.add(const Duration(minutes: 5)),
          titulo: 'descanso',
          corpo: 'c',
          rotuloEncerrar: 'Encerrar',
        );

    test('o foco fica com a barra', () async {
      await comecaOFoco();
      expect(BaruNotifications.instance.contagemAtual,
          BaruNotifications.contagemDeFoco);
    });

    test('o descanso não rouba a barra de uma sessão de foco', () async {
      await comecaOFoco();
      barra.chamadas.clear();

      await comecaODescanso();

      expect(
        barra.chamadas,
        isEmpty,
        reason: 'as duas contagens dividem um id só: trocar mostraria o '
            'número errado para quem olha de relance',
      );
      expect(BaruNotifications.instance.contagemAtual,
          BaruNotifications.contagemDeFoco);
    });

    test('encerrar o descanso não apaga a sessão de foco', () async {
      await comecaOFoco();
      barra.chamadas.clear();

      await BaruNotifications.instance.encerraDescanso();

      expect(barra.chamadas, isEmpty);
      expect(BaruNotifications.instance.contagemAtual,
          BaruNotifications.contagemDeFoco);
    });

    test('depois de o processo morrer, o foco continua dono da barra',
        () async {
      // O app foi morto no meio da sessão e renasceu: a notificação
      // sobreviveu, a memória de quem a escreveu não. Quem sabe é o estado.
      await comecaOFoco();
      BaruNotifications.instance.preparaParaTeste(); // processo novo
      BaruNotifications.instance.canalDaBarra = barra.arma();
      barra.chamadas.clear();

      await BaruNotifications.instance.encerraDescanso(focoEmCurso: true);

      expect(
        barra.chamadas,
        isEmpty,
        reason: 'apagaria o cronômetro de uma sessão que continua correndo',
      );
    });

    test('sem foco correndo, a barra velha do descanso sai', () async {
      BaruNotifications.instance.preparaParaTeste();
      BaruNotifications.instance.canalDaBarra = barra.arma();

      await BaruNotifications.instance.encerraDescanso();

      expect(barra.ultimaContagem!['terminaEm'], 0);
    });

    test('acabada a sessão, o descanso pode assumir', () async {
      await comecaOFoco();
      await BaruNotifications.instance.encerraSessao();
      expect(BaruNotifications.instance.contagemAtual, isNull);

      await comecaODescanso();

      expect(BaruNotifications.instance.contagemAtual,
          BaruNotifications.contagemDeDescanso);
      expect(barra.ultimaContagem!['titulo'], 'descanso');
    });

    test('encerrar limpa o prazo do lado nativo', () async {
      await comecaOFoco();
      await BaruNotifications.instance.encerraSessao();

      expect(
        barra.ultimaContagem!['terminaEm'],
        0,
        reason: 'prazo velho guardado é a contagem vencida que o serviço da '
            'próxima sessão desenharia antes de receber a nova',
      );
    });
  });

  group('a contagem do descanso é projetada, não fixa', () {
    // A leitura vem do domínio de verdade: é a conta dele que decide o
    // prazo, e um teste com `Duration` inventado não provaria isso.
    final comecou = DateTime(2026, 8, 28, 10);
    LeituraDoDescanso leitura({
      required int minutosDecorridos,
      int minutosDeTela = 0,
      Duration noApp = Duration.zero,
    }) =>
        leDescanso(
          comecouEm: comecou,
          agora: comecou.add(Duration(minutes: minutosDecorridos)),
          minutosDeTelaNoInicio: 0,
          minutosDeTelaAgora: minutosDeTela,
          noProprioApp: noApp,
        );

    test('telefone parado: a projeção é agora mais o que falta', () {
      // 12 dos 40 minutos feitos, nada descontado.
      final agora = DateTime(2026, 8, 28, 10, 12);
      expect(
        BaruNotifications.contagemDoDescanso(
          leitura(minutosDecorridos: 12),
          agora,
        ),
        agora.add(const Duration(minutes: 28)),
      );
    });

    test('o que a pessoa gastou em outro app empurra o prazo', () {
      // Doze minutos de relógio com dois em outro app são dez de descanso —
      // e um prazo fixo em `começou + 40` teria mentido dois minutos.
      final agora = DateTime(2026, 8, 28, 10, 12);
      expect(
        BaruNotifications.contagemDoDescanso(
          leitura(minutosDecorridos: 12, minutosDeTela: 2),
          agora,
        ),
        agora.add(const Duration(minutes: 30)),
      );
    });

    test('olhar o próprio Baru também não conta como descanso', () {
      final agora = DateTime(2026, 8, 28, 10, 12);
      expect(
        BaruNotifications.contagemDoDescanso(
          leitura(minutosDecorridos: 12, noApp: const Duration(minutes: 3)),
          agora,
        ),
        agora.add(const Duration(minutes: 31)),
      );
    });

    test('tentativa completa não tem mais o que contar', () {
      final l = leitura(minutosDecorridos: 40);
      expect(l.completo, isTrue);
      expect(
        BaruNotifications.contagemDoDescanso(l, DateTime.now()),
        isNull,
        reason: 'contagem que chegou a zero e fica lá diz que a missão '
            'continua quando ela já acabou',
      );
    });

    test('tentativa rompida some da barra', () {
      // Fuga acima da tolerância de 3 min: esta tentativa deixou de ser
      // contínua. Sem punição — só não há mais o que contar.
      final l = leitura(minutosDecorridos: 12, minutosDeTela: 5);
      expect(l.rompido, isTrue);
      expect(BaruNotifications.contagemDoDescanso(l, DateTime.now()), isNull);
    });

    test('sem tentativa, sem contagem', () {
      expect(BaruNotifications.contagemDoDescanso(null, DateTime.now()), isNull);
    });

    test('o descanso chega ao nativo com a própria fala e o próprio botão',
        () async {
      await BaruNotifications.instance.mostraDescanso(
        terminaEm: DateTime.now().add(const Duration(minutes: 40)),
        titulo: 'Baru está descansando com você',
        corpo: 'O tempo só corre com o telefone parado.',
        rotuloEncerrar: 'Encerrar',
      );

      final args = barra.ultimaContagem!;
      expect(args['titulo'], 'Baru está descansando com você');
      expect(args['rotuloDesistir'], 'Encerrar');
      expect(
        args['idDesistir'],
        BaruNotifications.acaoEncerraDescanso,
        reason: 'encerrar o descanso não é desistir do foco: consequências '
            'diferentes, ações diferentes',
      );
    });
  });

  group('os botões da barra chegam ao app', () {
    test('desistir abre o app em vez de morrer num receiver', () {
      final a = BaruNotifications.detalhesDaSessao(
        terminaEm: DateTime(2026, 8, 28, 15),
        rotuloDesistir: 'Desistir',
      ).android!;
      final desistir =
          a.actions!.firstWhere((x) => x.id == BaruNotifications.acaoDesistir);

      expect(
        desistir.showsUserInterface,
        isTrue,
        reason: 'sem isto o plugin manda o toque para um BroadcastReceiver '
            'que precisa de um isolate registrado em '
            '`onDidReceiveBackgroundNotificationResponse` — que o app nunca '
            'registrou. O botão cancelava a notificação e o app não ficava '
            'sabendo: a sessão seguia correndo e o relógio pagava a '
            'recompensa de quem tinha desistido',
      );
    });

    test('o botão de voltar só existe quando há rótulo para ele', () {
      final semRotulo = BaruNotifications.detalhesDaSessao(
        terminaEm: DateTime(2026, 8, 28, 15),
        rotuloDesistir: 'Desistir',
      ).android!;
      expect(semRotulo.actions!.length, 1);

      final comRotulo = BaruNotifications.detalhesDaSessao(
        terminaEm: DateTime(2026, 8, 28, 15),
        rotuloDesistir: 'Desistir',
        rotuloVoltar: 'Voltar ao Baru',
      ).android!;
      expect(comRotulo.actions!.length, 2);
      expect(comRotulo.actions!.last.id, BaruNotifications.acaoVoltar);
      expect(
        comRotulo.actions!.last.cancelNotification,
        isFalse,
        reason: 'voltar não é encerrar: a contagem continua onde estava',
      );
    });

    test('a notificação é legível na tela de bloqueio', () {
      final a = BaruNotifications.detalhesDaSessao(
        terminaEm: DateTime(2026, 8, 28, 15),
        rotuloDesistir: 'x',
      ).android!;
      expect(a.visibility, NotificationVisibility.public);
      expect(a.category, AndroidNotificationCategory.stopwatch);
    });

    test('um toque que chega antes do app existir não se perde', () {
      // O arranque a frio: a activity nasce por causa do toque, e o callback
      // do app só é registrado alguns quadros depois.
      final n = BaruNotifications.instance..preparaParaTeste();
      n.recebeAcaoDaBarra(BaruNotifications.acaoDesistir);

      var desistiu = 0;
      n.aoDesistirPelaBarra = () => desistiu++;

      expect(desistiu, 1);
    });

    test('a ação guardada é entregue uma vez só', () {
      final n = BaruNotifications.instance..preparaParaTeste();
      n.recebeAcaoDaBarra(BaruNotifications.acaoDesistir);

      var desistiu = 0;
      n.aoDesistirPelaBarra = () => desistiu++;
      // Trocar o callback (uma reconstrução do app) não pode reexecutar a
      // ação: desistir duas vezes da mesma sessão.
      n.aoDesistirPelaBarra = () => desistiu++;

      expect(desistiu, 1);
    });

    test('encerrar o descanso não dispara o desistir do foco', () {
      final n = BaruNotifications.instance..preparaParaTeste();
      var desistiu = 0;
      var encerrou = 0;
      n.aoDesistirPelaBarra = () => desistiu++;
      n.aoEncerrarDescansoPelaBarra = () => encerrou++;

      n.recebeAcaoDaBarra(BaruNotifications.acaoEncerraDescanso);

      expect(encerrou, 1);
      expect(desistiu, 0);
    });

    test('o toque do arranque a frio é puxado do nativo', () async {
      // O caminho que o empurrão não cobre: a activity nasce por causa do
      // toque e o canal só ganha ouvinte dentro do `init()`. Quem chega
      // depois pergunta.
      barra.acaoGuardada = BaruNotifications.acaoDesistir;
      final n = BaruNotifications.instance;

      await n.puxaAcaoGuardada();
      var desistiu = 0;
      n.aoDesistirPelaBarra = () => desistiu++;

      expect(desistiu, 1);
    });

    test('o arranque do app é quem puxa', () async {
      // O teste acima prova a regra; este prova que alguém a chama. Sem
      // esta linha no `init()` o toque do arranque a frio fica guardado no
      // lado nativo para sempre.
      barra.acaoGuardada = BaruNotifications.acaoDesistir;
      final n = BaruNotifications.instance..preparaParaTeste(pronto: false);
      n.canalDaBarra = barra.arma();

      await n.init();
      var desistiu = 0;
      n.aoDesistirPelaBarra = () => desistiu++;

      expect(desistiu, 1);
    });

    test('o toque com o app vivo também age', () async {
      // O caminho quente: o plugin devolve a resposta pelo próprio canal
      // dele. É outro caminho que o do arranque a frio, e os dois têm de
      // chegar ao mesmo lugar.
      final n = BaruNotifications.instance..preparaParaTeste(pronto: false);
      n.canalDaBarra = barra.arma();
      await n.init();

      var desistiu = 0;
      n.aoDesistirPelaBarra = () => desistiu++;

      // O que o lado nativo manda quando a pessoa toca a ação.
      await TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'dexterous.com/flutter/local_notifications',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('didReceiveNotificationResponse', {
            'notificationId': BaruNotifications.sessaoId,
            'actionId': BaruNotifications.acaoDesistir,
            'input': null,
            'payload': null,
            'notificationResponseType': 1,
          }),
        ),
        (_) {},
      );

      expect(desistiu, 1);
    });

    test('sem nada guardado, nada acontece', () async {
      barra.acaoGuardada = null;
      final n = BaruNotifications.instance;

      await n.puxaAcaoGuardada();
      var desistiu = 0;
      n.aoDesistirPelaBarra = () => desistiu++;

      expect(desistiu, 0);
    });

    test('voltar ao app não decide nada', () {
      final n = BaruNotifications.instance..preparaParaTeste();
      var desistiu = 0;
      n.aoDesistirPelaBarra = () => desistiu++;

      n.recebeAcaoDaBarra(BaruNotifications.acaoVoltar);

      expect(
        desistiu,
        0,
        reason: 'o botão de voltar só traz a pessoa de volta; se ele '
            'abandonasse a sessão seria uma armadilha',
      );
    });
  });

  group('o app avisa quem é o dono da barra', () {
    testWidgets('ir para o segundo plano não apaga a sessão que sobreviveu',
        (tester) async {
      // O caso real: app morto no meio do foco, reaberto, e a primeira ida
      // ao segundo plano. `contagemAtual` nasceu nulo neste processo — só o
      // estado do app sabe que a sessão continua.
      await tester.pumpWidget(BaruApp(snapshot: _comSessaoEmCurso()));
      await tester.pump();
      BaruNotifications.instance.preparaParaTeste();
      BaruNotifications.instance.canalDaBarra = barra.arma();
      barra.chamadas.clear();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.idle();

      expect(
        barra.chamadas.where((c) => c.method == 'contagem'),
        isEmpty,
        reason: 'limpar a contagem aqui apagaria o cronômetro de uma sessão '
            'que continua correndo',
      );
    });

    testWidgets('o app é quem fornece os rótulos e os botões', (tester) async {
      await tester.pumpWidget(const BaruApp());
      await tester.pump();

      final n = BaruNotifications.instance;
      expect(
        n.rotuloDeVolta?.call(),
        T('pt').notifBarraVoltar,
        reason: 'sem fornecedor, a notificação sai sem o botão de voltar',
      );
      expect(n.aoDesistirPelaBarra, isNotNull);
      expect(
        n.aoEncerrarDescansoPelaBarra,
        isNotNull,
        reason: 'sem isto, encerrar o descanso pela barra não faz nada',
      );
    });

    testWidgets('sem missão nenhuma, ir para o segundo plano limpa a barra',
        (tester) async {
      // A outra metade: **alguém tem de chamar**. É a troca de primeiro
      // plano que sincroniza a barra do descanso, e é ali que a pessoa larga
      // o telefone — o instante em que a notificação passa a ser a única
      // cara da missão.
      await tester.pumpWidget(const BaruApp());
      await tester.pump();
      BaruNotifications.instance.preparaParaTeste();
      BaruNotifications.instance.canalDaBarra = barra.arma();
      barra.chamadas.clear();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      await tester.idle();

      expect(barra.ultimaContagem, isNotNull);
      expect(barra.ultimaContagem!['terminaEm'], 0);
    });
  });

  group('a fala da barra existe nos 4 idiomas', () {
    setUp(() {
      garanteTextosDaNotificacao();
      garanteTextosDoDescanso();
    });

    test('os rótulos novos resolvem em pt, en, es e zh', () {
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final t = T(lang);
        for (final texto in [t.notifBarraVoltar, t.notifDescansoDesistir]) {
          expect(texto, isNotEmpty, reason: lang);
          // `T.s` devolve a própria chave quando o texto falta — e a chave
          // iria para a barra de notificações como se fosse produto.
          expect(texto, isNot(startsWith('notif')), reason: lang);
        }
      }
    });

    test('o catálogo tem as mesmas chaves nos 4 idiomas', () {
      final pt = textosDaNotificacao['pt']!.keys.toSet();
      for (final lang in ['en', 'es', 'zh']) {
        expect(textosDaNotificacao[lang]!.keys.toSet(), pt, reason: lang);
      }
    });

    test('encerrar o descanso não usa a palavra de desistir do foco', () {
      // Desistir do foco custa a recompensa; encerrar o descanso não custa
      // nada — o melhor do dia fica guardado (§1, sem punição).
      for (final lang in ['pt', 'en', 'es', 'zh']) {
        final t = T(lang);
        expect(t.notifDescansoDesistir, isNot(t.notifSessaoDesistir),
            reason: lang);
      }
    });
  });
}
