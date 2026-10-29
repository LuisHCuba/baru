/// Quando chamar e qual recado mandar (pesquisa 26).
///
/// Três regras do Duolingo, na versão que cabe no aparelho:
///
/// * **O horário vem da pessoa.** O lembrete do dia seguinte sai 23,5 h
///   depois da *primeira* prática do dia — a variante que "continua
///   ganhando" nos testes deles (Jackson Shuttleworth, líder de Retenção,
///   no podcast Sub Club). Horário fixo escolhido no projeto falha porque a
///   chance de a pessoa estar livre sempre na mesma hora "é zero".
/// * **O recado que chega é o que funciona com esta pessoa, e não o mesmo
///   de ontem.** O bandit do paper (Yancey & Settles, KDD 2020) dá a cada
///   modelo a taxa de sucesso dele — prática em até 2 h — menos uma
///   penalidade de recência γ·0,5^(d/h), com meia-vida de 15 dias: modelo
///   repetido perde a novidade, e repetir sempre o melhor piorou o
///   resultado deles.
/// * **Insistência tem fim.** Os lembretes de prática param depois de 7
///   dias sem uso, com um último recado avisando que vão parar (Shuttleworth;
///   von Ahn conta 5 dias). Quem desliga a notificação não volta a ligar:
///   o canal é o que se protege.
///
/// Diferenças assumidas: o sucesso aqui é **abrir o app** em até 3 h do
/// horário marcado (o alarme inexato do Android chega até 1 h depois, e o
/// app não sabe a hora exata da entrega); e o histórico fica só neste
/// aparelho — nada sai dele.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'descanso_retencao.dart';

/// Um recado candidato: id estável (é por ele que se aprende) e o texto.
class ModeloDeRecado {
  const ModeloDeRecado(this.id, this.texto);

  final String id;
  final TextoDeLembrete texto;

  @override
  String toString() => 'ModeloDeRecado($id)';
}

/// O que este aparelho sabe de um modelo.
class ContaDoModelo {
  ContaDoModelo({this.envios = 0, this.acertos = 0, this.ultimoUso});

  int envios;
  int acertos;
  DateTime? ultimoUso;

  Map<String, Object?> toJson() => {
    'e': envios,
    'a': acertos,
    'u': ultimoUso?.millisecondsSinceEpoch,
  };

  static ContaDoModelo fromJson(Map<String, dynamic> j) => ContaDoModelo(
    envios: (j['e'] as num?)?.toInt() ?? 0,
    acertos: (j['a'] as num?)?.toInt() ?? 0,
    ultimoUso: j['u'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((j['u'] as num).toInt()),
  );
}

/// Um recado que está agendado e ainda não se sabe se tocou.
class RecadoAgendado {
  const RecadoAgendado(this.modelo, this.quando);

  final String modelo;
  final DateTime quando;

  Map<String, Object> toJson() => {
    'm': modelo,
    'q': quando.millisecondsSinceEpoch,
  };

  static RecadoAgendado fromJson(Map<String, dynamic> j) => RecadoAgendado(
    j['m'] as String,
    DateTime.fromMillisecondsSinceEpoch((j['q'] as num).toInt()),
  );
}

/// O caderno dos recados: o que foi enviado, o que funcionou, o que está
/// marcado.
class HistoricoDeRecados {
  HistoricoDeRecados({
    Map<String, ContaDoModelo>? contas,
    List<RecadoAgendado>? pendentes,
  }) : contas = contas ?? {},
       pendentes = pendentes ?? [];

  final Map<String, ContaDoModelo> contas;
  List<RecadoAgendado> pendentes;

  /// Até quanto depois do horário marcado abrir o app conta como acerto.
  /// 2 h do paper + 1 h que o alarme inexato pode atrasar.
  static const janelaDeAcerto = Duration(hours: 3);

  /// Peso da penalidade de recência. O paper usa 0,017 sobre taxas globais
  /// de milhões de envios; aqui as taxas vêm de dezenas de envios de uma
  /// pessoa só, e o ruído delas é dessa ordem — com 0,017 o "melhor" de
  /// três envios repetiria todo dia. 0,15 faz o recado de ontem perder para
  /// um equivalente até que os dados digam, com folga, que ele é melhor.
  static const gama = 0.15;

  /// Meia-vida da penalidade, como no paper.
  static const meiaVidaEmDias = 15.0;

  /// Fecha a conta dos recados que já tocaram.
  ///
  /// Chamado quando o app está de pé (abertura, fim de sessão): o que tinha
  /// horário até [agora] foi entregue; se [agora] cai na janela de acerto,
  /// funcionou. O que tinha horário depois de [agora] não tocou — vai ser
  /// cancelado e reagendado — e não conta para ninguém.
  void fecha(DateTime agora) {
    for (final p in pendentes) {
      if (p.modelo.isEmpty || p.quando.isAfter(agora)) continue;
      final c = contas.putIfAbsent(p.modelo, ContaDoModelo.new);
      c.envios++;
      if (agora.difference(p.quando) <= janelaDeAcerto) c.acertos++;
      if (c.ultimoUso == null || p.quando.isAfter(c.ultimoUso!)) {
        c.ultimoUso = p.quando;
      }
    }
    pendentes = [];
  }

  /// A nota de um modelo para um envio em [quando].
  ///
  /// Taxa de acerto com prior de 1 em 2 — modelo novo começa no meio, nem
  /// condenado nem favorito — menos a penalidade de recência.
  double nota(String id, DateTime quando, {DateTime? ultimoUso}) {
    final c = contas[id];
    final taxa = ((c?.acertos ?? 0) + 1) / ((c?.envios ?? 0) + 2);
    final uso = ultimoUso ?? c?.ultimoUso;
    if (uso == null) return taxa;
    final dias = quando.difference(uso).inMinutes / (60 * 24);
    return taxa - gama * math.pow(0.5, math.max(0, dias) / meiaVidaEmDias);
  }

  /// Escolhe um recado para cada horário em [quandos], em ordem.
  ///
  /// A escolha de um dia entra na recência do seguinte: agendar a semana de
  /// uma vez não pode dar o mesmo texto sete vezes. Empate se desfaz pela
  /// posição na lista — os primeiros são os textos de sempre.
  List<ModeloDeRecado> escolhe(
    List<ModeloDeRecado> elegiveis,
    List<DateTime> quandos,
  ) {
    if (elegiveis.isEmpty) return const [];
    final usoSimulado = <String, DateTime>{};
    final escolhidos = <ModeloDeRecado>[];
    for (final q in quandos) {
      ModeloDeRecado? melhor;
      var notaMelhor = double.negativeInfinity;
      for (final m in elegiveis) {
        final n = nota(m.id, q, ultimoUso: usoSimulado[m.id]);
        if (n > notaMelhor + 1e-9) {
          melhor = m;
          notaMelhor = n;
        }
      }
      escolhidos.add(melhor!);
      usoSimulado[melhor.id] = q;
    }
    return escolhidos;
  }

  String toJsonString() => jsonEncode({
    'c': {for (final e in contas.entries) e.key: e.value.toJson()},
    'p': [for (final p in pendentes) p.toJson()],
  });

  static HistoricoDeRecados fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return HistoricoDeRecados();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final c = (j['c'] as Map<String, dynamic>? ?? {}).map(
        (k, v) =>
            MapEntry(k, ContaDoModelo.fromJson(v as Map<String, dynamic>)),
      );
      final p = [
        for (final x in (j['p'] as List? ?? const []))
          RecadoAgendado.fromJson(x as Map<String, dynamic>),
      ];
      return HistoricoDeRecados(contas: c, pendentes: p);
    } catch (_) {
      // Caderno corrompido: começa de novo. Perder o aprendizado é melhor
      // que não mandar recado nenhum.
      return HistoricoDeRecados();
    }
  }
}

/// O começo do primeiro foco concluído do último dia em que houve foco.
///
/// O registro guarda o **fim** da sessão (`at`) e a duração (`dur`, em
/// minutos); o começo é a diferença.
DateTime? primeiraPraticaDoUltimoDia(
  Iterable<({DateTime at, int dur, bool completed})> sessoes,
) {
  DateTime? ultimoDia;
  DateTime? primeira;
  for (final s in sessoes) {
    if (!s.completed) continue;
    final comeco = s.at.subtract(Duration(minutes: s.dur));
    final dia = DateTime(comeco.year, comeco.month, comeco.day);
    if (ultimoDia == null || dia.isAfter(ultimoDia)) {
      ultimoDia = dia;
      primeira = comeco;
    } else if (dia == ultimoDia && comeco.isBefore(primeira!)) {
      primeira = comeco;
    }
  }
  return primeira;
}

/// A que horas chamar amanhã: 23,5 h depois da primeira prática.
///
/// [primeiraPratica] é o começo do primeiro foco do último dia com foco.
/// Só vale se esse dia foi há no máximo 3 dias: hábito de uma semana atrás
/// não diz quando a pessoa está livre hoje. Sem ela, cai no horário
/// aprendido ([habito]) ou no padrão. Sempre dentro de 8h–21h: quem foca
/// às 6h não quer o telefone tocando às 5h30, e o alarme inexato ainda
/// pode chegar uma hora depois.
({int hora, int minuto}) horaDoConvite({
  DateTime? primeiraPratica,
  required DateTime agora,
  HorarioDoHabito? habito,
  int semHabito = 17,
}) {
  ({int hora, int minuto}) dentro(int minutos) {
    final m = minutos.clamp(8 * 60, 21 * 60);
    return (hora: m ~/ 60, minuto: m % 60);
  }

  if (primeiraPratica != null) {
    final dia = DateTime(
      primeiraPratica.year,
      primeiraPratica.month,
      primeiraPratica.day,
    );
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (hoje.difference(dia).inDays <= 3) {
      final menos = primeiraPratica.subtract(const Duration(minutes: 30));
      // Se os 30 min atravessarem a meia-noite, fica no começo da janela.
      final minutos = menos.day == primeiraPratica.day
          ? menos.hour * 60 + menos.minute
          : 0;
      return dentro(minutos);
    }
  }
  return dentro((habito?.hora ?? semHabito) * 60);
}

/// Os dias da escada de convites, a partir de hoje.
///
/// Um convite por dia de ausência, de hoje (se ainda não foi cumprido e o
/// horário está à frente) até o 6º dia; no 7º, a despedida. Tudo isso é
/// cancelado e refeito a cada vez que o app abre — só toca para quem sumiu.
({List<DateTime> convites, DateTime despedida}) escadaDeConvites({
  required DateTime agora,
  required int hora,
  required int minuto,
  required bool pulaHoje,
  int dias = 6,
}) {
  final hoje = DateTime(agora.year, agora.month, agora.day, hora, minuto);
  final convites = <DateTime>[
    if (!pulaHoje && hoje.isAfter(agora)) hoje,
    for (var d = 1; d <= dias; d++)
      DateTime(agora.year, agora.month, agora.day + d, hora, minuto),
  ];
  return (
    convites: convites,
    despedida: DateTime(
      agora.year,
      agora.month,
      agora.day + dias + 1,
      hora,
      minuto,
    ),
  );
}
