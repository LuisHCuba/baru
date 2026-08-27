import 'package:baru_app/data/tempo_de_tela.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contabilidade de tempo de tela.
///
/// O bug que originou este arquivo: o app somava `totalTimeInForeground` de
/// todo pacote e contava Spotify tocando no bolso como tempo de tela. Um
/// número em que o usuário não confia destrói o produto inteiro, porque a meta
/// diária é comparada contra ele.

final dia = DateTime(2026, 8, 27);
DateTime h(int hora, [int min = 0]) => DateTime(2026, 8, 27, hora, min);

EventoDeUso ev(int tipo, DateTime quando, [String pacote = 'android']) =>
    EventoDeUso(tipo: tipo, quando: quando, pacote: pacote);

EventoDeUso abre(DateTime q, String p) =>
    ev(TipoDeEvento.atividadeRetomada, q, p);
EventoDeUso fecha(DateTime q, String p) =>
    ev(TipoDeEvento.atividadePausada, q, p);
EventoDeUso ligaTela(DateTime q) => ev(TipoDeEvento.telaLigada, q);
EventoDeUso apagaTela(DateTime q) => ev(TipoDeEvento.telaDesligada, q);
EventoDeUso desbloqueia(DateTime q) => ev(TipoDeEvento.bloqueioEscondido, q);
EventoDeUso bloqueia(DateTime q) => ev(TipoDeEvento.bloqueioMostrado, q);

const contabilidade = ContabilidadeDeTela();

ResumoDeTela resumoDe(
  List<EventoDeUso> eventos, {
  Map<String, CategoriaDeApp> ajustes = const {},
  DateTime? ate,
}) =>
    contabilidade.resumo(
      eventos,
      de: dia,
      ate: ate ?? h(23, 59),
      ajustes: ajustes,
    );

void main() {
  group('o caso que quebrou a confiança: áudio no bolso', () {
    test('Spotify com a tela apagada não conta nada', () {
      final r = resumoDe([
        desbloqueia(h(8)),
        abre(h(8, 1), 'com.spotify.music'),
        apagaTela(h(8, 2)), // celular no bolso
        // duas horas de música tocando
        ligaTela(h(10, 2)),
        desbloqueia(h(10, 2)),
        fecha(h(10, 3), 'com.spotify.music'),
        apagaTela(h(10, 4)),
      ]);

      expect(
        r.porApp['com.spotify.music']!.inMinutes,
        2,
        reason: 'só o minuto com a tela ligada antes e depois do bolso',
      );
      expect(r.total.inHours, 0, reason: 'as duas horas de bolso sumiram');
    });

    test('mesmo com a tela ligada, áudio não entra na meta', () {
      final r = resumoDe([
        ligaTela(h(9)),
        desbloqueia(h(9)),
        abre(h(9), 'com.spotify.music'),
        fecha(h(10), 'com.spotify.music'),
        apagaTela(h(10)),
      ]);

      expect(r.passivo.inMinutes, 60);
      expect(r.total.inMinutes, 60);
      expect(
        r.contabilizado,
        Duration.zero,
        reason: 'ouvir música não é o que o usuário quer reduzir',
      );
    });

    test('YouTube é dispersivo, YouTube Music é passivo', () {
      const c = ClassificacaoPadrao();
      expect(
        c.de('com.google.android.youtube'),
        CategoriaDeApp.dispersivo,
      );
      expect(
        c.de('com.google.android.apps.youtube.music'),
        CategoriaDeApp.passivo,
      );
    });
  });

  group('o que nunca conta', () {
    const ex = ExclusoesDeContagem();

    test('launcher de qualquer fabricante', () {
      for (final p in [
        'com.google.android.apps.nexuslauncher',
        'com.sec.android.app.launcher',
        'com.miui.home.launcher',
        'org.lineageos.trebuchet',
      ]) {
        expect(ex.excluido(p), isTrue, reason: p);
      }
    });

    test('system UI, teclado e telas do sistema', () {
      for (final p in [
        'com.android.systemui',
        'android',
        'com.google.android.inputmethod.latin',
        'com.samsung.android.honeyboard',
        'com.android.settings',
      ]) {
        expect(ex.excluido(p), isTrue, reason: p);
      }
    });

    test('o próprio Baru', () {
      expect(ex.excluido('com.lhcx.baru_app'), isTrue);
    });

    test('um app de verdade não é excluído', () {
      expect(ex.excluido('com.instagram.android'), isFalse);
      expect(ex.excluido('com.whatsapp'), isFalse);
    });

    test('o tempo no launcher some da contagem', () {
      final r = resumoDe([
        ligaTela(h(9)),
        desbloqueia(h(9)),
        abre(h(9), 'com.sec.android.app.launcher'),
        abre(h(9, 10), 'com.instagram.android'),
        fecha(h(9, 25), 'com.instagram.android'),
        apagaTela(h(9, 25)),
      ]);
      expect(r.porApp.containsKey('com.sec.android.app.launcher'), isFalse);
      expect(r.porApp['com.instagram.android']!.inMinutes, 15);
    });
  });

  group('reconstrução por par de eventos', () {
    test('um app aberto e fechado com a tela ligada', () {
      final r = resumoDe([
        ligaTela(h(14)),
        desbloqueia(h(14)),
        abre(h(14), 'com.instagram.android'),
        fecha(h(14, 30), 'com.instagram.android'),
        apagaTela(h(14, 30)),
      ]);
      expect(r.porApp['com.instagram.android']!.inMinutes, 30);
    });

    test('tela apagada no meio do uso corta o intervalo', () {
      final r = resumoDe([
        ligaTela(h(14)),
        desbloqueia(h(14)),
        abre(h(14), 'com.instagram.android'),
        apagaTela(h(14, 10)), // tela apaga sozinha
        ligaTela(h(14, 40)),
        desbloqueia(h(14, 40)),
        fecha(h(14, 50), 'com.instagram.android'),
        apagaTela(h(14, 50)),
      ]);
      expect(
        r.porApp['com.instagram.android']!.inMinutes,
        20,
        reason: '10 antes de apagar + 10 depois de voltar; os 30 de tela '
            'apagada não contam',
      );
    });

    test('bloqueado não conta, mesmo com a tela acesa', () {
      final r = resumoDe([
        ligaTela(h(7)),
        // tela acesa na lock screen, sem desbloquear
        abre(h(7), 'com.whatsapp'),
        desbloqueia(h(7, 5)),
        fecha(h(7, 15), 'com.whatsapp'),
        bloqueia(h(7, 15)),
      ]);
      expect(r.porApp['com.whatsapp']!.inMinutes, 10);
    });

    test('troca rápida entre apps não perde nem duplica tempo', () {
      final r = resumoDe([
        ligaTela(h(12)),
        desbloqueia(h(12)),
        abre(h(12), 'com.whatsapp'),
        abre(h(12, 5), 'com.instagram.android'),
        // o "pausado" do WhatsApp chega depois do "retomado" do Instagram
        fecha(h(12, 5), 'com.whatsapp'),
        abre(h(12, 9), 'com.whatsapp'),
        fecha(h(12, 9), 'com.instagram.android'),
        fecha(h(12, 20), 'com.whatsapp'),
        apagaTela(h(12, 20)),
      ]);
      expect(r.porApp['com.whatsapp']!.inMinutes, 16);
      expect(r.porApp['com.instagram.android']!.inMinutes, 4);
      expect(r.total.inMinutes, 20, reason: 'nada duplicado');
    });

    test('evento de fechar faltando: o intervalo fecha no fim da janela', () {
      final r = resumoDe(
        [
          ligaTela(h(21)),
          desbloqueia(h(21)),
          abre(h(21), 'com.netflix.mediaclient'),
          // sem pausado, sem tela apagada — o app morreu com o processo
        ],
        ate: h(22),
      );
      expect(r.porApp['com.netflix.mediaclient']!.inMinutes, 60);
    });

    test('uso atravessando a meia-noite é recortado no dia', () {
      // Eventos da véspera estabelecem o estado; o recorte começa à 00h.
      final r = contabilidade.resumo(
        [
          ligaTela(DateTime(2026, 8, 26, 23, 30)),
          desbloqueia(DateTime(2026, 8, 26, 23, 30)),
          abre(DateTime(2026, 8, 26, 23, 30), 'com.reddit.frontpage'),
          fecha(DateTime(2026, 8, 27, 0, 20), 'com.reddit.frontpage'),
          apagaTela(DateTime(2026, 8, 27, 0, 20)),
        ],
        de: dia,
        ate: h(23, 59),
      );
      expect(
        r.porApp['com.reddit.frontpage']!.inMinutes,
        20,
        reason: 'os 30 minutos da véspera pertencem ao dia anterior',
      );
    });

    test('desligar o aparelho encerra tudo', () {
      final r = resumoDe([
        ligaTela(h(16)),
        desbloqueia(h(16)),
        abre(h(16), 'com.instagram.android'),
        ev(TipoDeEvento.aparelhoDesligado, h(16, 10)),
        ev(TipoDeEvento.aparelhoLigado, h(17)),
      ]);
      expect(r.porApp['com.instagram.android']!.inMinutes, 10);
    });

    test('eventos fora de ordem são ordenados antes de contar', () {
      final r = resumoDe([
        fecha(h(11, 30), 'com.whatsapp'),
        abre(h(11), 'com.whatsapp'),
        desbloqueia(h(11)),
        ligaTela(h(11)),
        apagaTela(h(11, 30)),
      ]);
      expect(r.porApp['com.whatsapp']!.inMinutes, 30);
    });

    test('sem nenhum evento o resumo é vazio, não zero inventado', () {
      final r = resumoDe([]);
      expect(r.vazio, isTrue);
      expect(r.total, Duration.zero);
    });

    test('estado inicial desconhecido não conta: erra para menos', () {
      // Sem evento de tela ou desbloqueio, nada é assumido.
      final r = resumoDe([
        abre(h(10), 'com.instagram.android'),
        fecha(h(11), 'com.instagram.android'),
      ]);
      expect(
        r.total,
        Duration.zero,
        reason: 'inventar uso é a mentira que estamos consertando',
      );
    });
  });

  group('a meta compara dispersivo mais neutro', () {
    ResumoDeTela diaTipico() => resumoDe([
          ligaTela(h(8)),
          desbloqueia(h(8)),
          abre(h(8), 'com.whatsapp'), // neutro 30
          abre(h(8, 30), 'com.instagram.android'), // dispersivo 60
          abre(h(9, 30), 'com.amazon.kindle'), // produtivo 40
          abre(h(10, 10), 'com.spotify.music'), // passivo 20
          fecha(h(10, 30), 'com.spotify.music'),
          apagaTela(h(10, 30)),
        ]);

    test('cada categoria recebe o seu tempo', () {
      final r = diaTipico();
      expect(r.neutro.inMinutes, 30);
      expect(r.dispersivo.inMinutes, 60);
      expect(r.produtivo.inMinutes, 40);
      expect(r.passivo.inMinutes, 20);
      expect(r.total.inMinutes, 150);
    });

    test('a meta vê 90, não 150', () {
      expect(diaTipico().minutosContabilizados, 90);
      expect(diaTipico().minutosTotais, 150);
    });

    test('a lista de apps sai do maior para o menor', () {
      final apps = diaTipico().appsPorTempo;
      expect(apps.first.key, 'com.instagram.android');
      expect(apps.last.key, 'com.spotify.music');
    });
  });

  group('reclassificação do usuário', () {
    test('o ajuste manual ganha da tabela embutida', () {
      final eventos = [
        ligaTela(h(20)),
        desbloqueia(h(20)),
        abre(h(20), 'com.google.android.youtube'),
        fecha(h(21), 'com.google.android.youtube'),
        apagaTela(h(21)),
      ];

      final padrao = resumoDe(eventos);
      expect(padrao.dispersivo.inMinutes, 60);

      // "Eu uso o YouTube para estudar."
      final ajustado = resumoDe(
        eventos,
        ajustes: {'com.google.android.youtube': CategoriaDeApp.produtivo},
      );
      expect(ajustado.produtivo.inMinutes, 60);
      expect(ajustado.dispersivo, Duration.zero);
      expect(
        ajustado.contabilizado,
        Duration.zero,
        reason: 'reclassificar muda o que a meta enxerga',
      );
    });

    test('app desconhecido entra como neutro', () {
      const c = ClassificacaoPadrao();
      expect(c.de('com.empresa.appinterno'), CategoriaDeApp.neutro);
    });

    test('a tabela embutida cobre os apps mais comuns', () {
      expect(ClassificacaoPadrao.conhecidos, greaterThan(40));
    });

    test('nenhuma entrada da tabela é um pacote excluído', () {
      const ex = ExclusoesDeContagem();
      for (final p in ClassificacaoPadrao.tabela.keys) {
        expect(
          ex.excluido(p),
          isFalse,
          reason: '$p está classificado e excluído ao mesmo tempo',
        );
      }
    });
  });
}
