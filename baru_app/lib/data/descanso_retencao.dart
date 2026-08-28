/// Retenção diária: o que faz a pessoa voltar amanhã.
///
/// Três decisões vivem aqui, todas como função pura, porque todas são
/// julgamento de produto e nenhuma precisa de plataforma para ser provada:
///
/// * **em que horário chamar** — no horário em que a pessoa costuma usar o
///   app, e não num número fixo que alguém escolheu no projeto;
/// * **quando avisar que a raiz está em risco** — antes de ela quebrar, que
///   é a única hora em que o aviso serve para alguma coisa;
/// * **o que dar a quem voltou** — recompensa por voltar, não por performar.
///
/// E uma quarta, que é a que impede as outras três de virarem praga: quantas
/// mensagens um dia comporta.
library;

import 'missoes.dart';

/// O horário em que a pessoa costuma usar o app.
class HorarioDoHabito {
  const HorarioDoHabito({required this.hora, required this.amostras});

  final int hora;

  /// Quantas evidências sustentam esse horário. A tela pode dizer "aprendi
  /// com 12 sessões"; um número inventado não teria o que dizer.
  final int amostras;

  @override
  String toString() => 'HorarioDoHabito($hora h, $amostras amostras)';
}

/// Descobre o horário do hábito a partir do que a pessoa já fez.
///
/// **Por que não um horário fixo.** Um lembrete às 21h é útil para quem usa
/// o app às 21h e é interrupção para todo o resto — e interrupção é o que
/// faz a pessoa desligar a notificação, que é a única forma de perdê-la de
/// vez. O horário sai do comportamento dela.
///
/// **Por que peso por recência.** O hábito muda; quem focava de manhã e
/// passou a focar à noite não pode continuar sendo chamado de manhã por
/// causa de um mês antigo. Os últimos sete dias pesam três, a segunda
/// semana pesa dois, a terceira pesa um.
///
/// Devolve `null` quando não há evidência suficiente. Quem chama cai para o
/// horário configurado — inventar um hábito a partir de duas sessões seria
/// a mesma mentira que o ADR-009 tirou do tempo de tela.
HorarioDoHabito? horarioDoHabito(
  Iterable<DateTime> usos, {
  required DateTime agora,
  int minimoDeAmostras = 4,
  int janelaEmDias = 21,
}) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final limite = hoje.subtract(Duration(days: janelaEmDias - 1));

  final peso = List<int>.filled(24, 0);
  var amostras = 0;

  for (final u in usos) {
    // Registro do futuro só existe com relógio mexido, e ele envenenaria o
    // histograma inteiro com um horário que nunca aconteceu.
    if (u.isAfter(agora)) continue;
    final dia = DateTime(u.year, u.month, u.day);
    if (dia.isBefore(limite)) continue;

    final distancia = hoje.difference(dia).inDays;
    peso[u.hour] += distancia < 7
        ? 3
        : distancia < 14
            ? 2
            : 1;
    amostras += 1;
  }

  if (amostras < minimoDeAmostras) return null;

  var melhor = 0;
  for (var h = 1; h < 24; h++) {
    // `>=` e não `>`: no empate fica a hora mais tarde. Um lembrete às 20h
    // ainda deixa a noite para agir; o mesmo lembrete às 8h já foi
    // esquecido quando a noite chega.
    if (peso[h] >= peso[melhor]) melhor = h;
  }
  if (peso[melhor] <= 0) return null;

  return HorarioDoHabito(hora: melhor, amostras: amostras);
}

/// O que acontece com a raiz se o dia terminar assim.
enum GrauDoRisco {
  /// Há congelamento na semana: a falta é absorvida e a raiz continua.
  congelamento,

  /// Não há congelamento: a raiz quebra à meia-noite.
  quebra,
}

/// A raiz prestes a sofrer alguma coisa.
class RaizEmRisco {
  const RaizEmRisco({
    required this.dias,
    required this.grau,
    this.proximoMarco,
  });

  final int dias;
  final GrauDoRisco grau;

  /// O próximo marco da raiz desenhada (`RaizViva.marcos`), se houver.
  ///
  /// Entra por parâmetro, e não por `import`, para esta camada continuar
  /// sem Flutter: `raiz.dart` é widget, e arrastar `material.dart` para
  /// dentro de `lib/data` inverteria as camadas e deixaria o teste de
  /// domínio dependente de árvore de widget.
  final int? proximoMarco;

  int? get faltaParaOMarco {
    final m = proximoMarco;
    return m == null ? null : m - dias;
  }

  /// Um galho novo a poucos dias dói mais que um marco distante — e é o que
  /// justifica interromper a pessoa hoje à noite.
  bool get vesperaDeMarco {
    final falta = faltaParaOMarco;
    return falta != null && falta > 0 && falta <= 3;
  }

  bool get vaiQuebrar => grau == GrauDoRisco.quebra;
}

/// A raiz está em risco agora?
///
/// **Antes, não depois.** "Sua sequência acabou" é uma lápide: chega quando
/// não há mais nada a fazer, e a única coisa que ensina é que o app avisa
/// tarde. O aviso tem de caber num dia em que ainda dá para agir.
///
/// Devolve `null` quando não há o que avisar — e é isso que impede o aviso
/// diário: quem já esteve presente hoje não ouve nada.
RaizEmRisco? avaliaRaizEmRisco({
  required int dias,
  required bool presenteHoje,
  required int congelamentos,
  int? proximoMarco,
}) {
  if (presenteHoje) return null;
  // Raiz de zero dia não é raiz: é semente. Avisar que ela pode quebrar
  // seria avisar sobre uma perda que não existe.
  if (dias <= 0) return null;

  return RaizEmRisco(
    dias: dias,
    grau: congelamentos > 0 ? GrauDoRisco.congelamento : GrauDoRisco.quebra,
    proximoMarco: proximoMarco,
  );
}

/// A que horas avisar sobre a raiz.
///
/// Depois do horário do hábito — avisar antes seria cobrar de quem ainda ia
/// aparecer — e cedo o suficiente para uma sessão de 25 minutos ainda caber
/// na noite.
int horaDoAvisoDaRaiz(
  HorarioDoHabito? habito, {
  int minima = 19,
  int maxima = 22,
  int semHabito = 21,
}) {
  final base = habito == null ? semHabito : habito.hora + 1;
  if (base < minima) return minima;
  if (base > maxima) return maxima;
  return base;
}

/// A recompensa de quem voltou.
class VoltaAoNinho {
  const VoltaAoNinho({
    required this.diasFora,
    required this.folhas,
    required this.devolveCongelamento,
    required this.chave,
  });

  final int diasFora;
  final int folhas;

  /// Devolve o congelamento da semana.
  ///
  /// Quem volta depois de três dias volta com a raiz zerada e sem rede: a
  /// primeira falta seguinte quebraria de novo, e a segunda desistência é a
  /// definitiva. O congelamento é a rede — não desfaz nada do passado, só
  /// dá margem ao recomeço.
  final bool devolveCongelamento;

  /// `volta@2026-08-28`. Mesmo formato das missões, pelo mesmo motivo:
  /// creditar duas vezes é dinheiro impresso.
  final String chave;
}

/// O id do crédito de retorno dentro do conjunto de resgates.
const idDaVolta = 'volta';

/// Avalia o retorno de quem sumiu.
///
/// **Recompensa por voltar, não por performar.** Todo o resto do app paga
/// desempenho: sessão concluída, dia abaixo da meta, missão batida. Quem
/// sumiu três dias volta com a sequência zerada, o habitat parado e nada a
/// resgatar — ou seja, volta para o pior dia possível. Fazer o reencontro
/// custar mais que a ausência é a forma mais rápida de transformar uma
/// recaída em desinstalação.
///
/// Um dia fora não conta: a semana normal de qualquer pessoa tem buracos, e
/// pagar por eles ensinaria a sumir.
VoltaAoNinho? avaliaVolta({
  required int diasFora,
  required DateTime hoje,
  Set<String> jaCreditadas = const {},
}) {
  if (diasFora < 2) return null;

  final chave = QuadroDeMissoes.chaveDoDia(idDaVolta, hoje);
  if (jaCreditadas.contains(chave)) return null;

  // A escala sobe com a ausência porque quanto mais longe a pessoa foi,
  // mais o retorno custou a ela. Nenhum degrau chega perto do que ela
  // deixou de ganhar estando fora: isto é acolhimento, não atalho.
  final int folhas;
  if (diasFora >= 7) {
    folhas = 40;
  } else if (diasFora >= 3) {
    folhas = 25;
  } else {
    folhas = 12;
  }

  return VoltaAoNinho(
    diasFora: diasFora,
    folhas: folhas,
    devolveCongelamento: diasFora >= 3,
    chave: chave,
  );
}

/// Que tipo de recado é.
enum TipoDeLembrete {
  /// O chamado do dia, no horário do hábito.
  descanso,

  /// A raiz em risco, à noite.
  raizEmRisco,
}

/// O texto de um lembrete, já traduzido.
///
/// Chega pronto, como a fala do vigia: quem agenda não escreve frase, e o
/// catálogo não sabe a que horas nada acontece.
class TextoDeLembrete {
  const TextoDeLembrete({required this.titulo, required this.corpo});

  final String titulo;
  final String corpo;
}

/// Um lembrete já decidido: tipo, hora e como ele se repete.
class LembreteDoDia {
  const LembreteDoDia({
    required this.tipo,
    required this.hora,
    required this.minuto,
    required this.repeteTodoDia,
    required this.pulaHoje,
  });

  final TipoDeLembrete tipo;
  final int hora;
  final int minuto;

  /// Repete no mesmo horário todo dia.
  ///
  /// Só vale para texto que não envelhece. O aviso da raiz carrega um número
  /// que muda ("sua raiz de 12 dias") e por isso é agendado um dia por vez e
  /// refeito a cada abertura — um agendamento repetido continuaria dizendo
  /// 12 para sempre.
  final bool repeteTodoDia;

  /// Hoje não, a partir de amanhã.
  ///
  /// Quem já descansou hoje não precisa ser chamado hoje. O hábito continua
  /// armado para os próximos dias.
  final bool pulaHoje;

  @override
  String toString() => 'LembreteDoDia(${tipo.name}, ${hora}h)';
}

/// Monta o dia de lembretes.
///
/// **A insistência do Duolingo sem virar praga.** O que faz uma notificação
/// diária funcionar é ser uma; o que faz a pessoa desligar todas é a
/// terceira do mesmo dia. Aqui há um teto por dia, uma distância mínima
/// entre elas, e o relatório da noite — que a pessoa já ligou nos ajustes —
/// conta como ocupação, para dois recados não caírem juntos.
///
/// A ordem de prioridade é fixa: a raiz em risco é a única mensagem do app
/// sobre algo irreversível, então ela entra primeiro.
List<LembreteDoDia> planoDeLembretes({
  required HorarioDoHabito? habito,
  required bool descansoFeitoHoje,
  required RaizEmRisco? risco,
  required bool relatorioLigado,
  required int horaDoRelatorio,
  int horaSemHabito = 19,
  int intervaloMinimoEmHoras = 3,
  int maximoPorDia = 2,
}) {
  final plano = <LembreteDoDia>[];
  final ocupadas = <int>[if (relatorioLigado) horaDoRelatorio];

  bool cabe(int hora) =>
      ocupadas.every((h) => (h - hora).abs() >= intervaloMinimoEmHoras);

  if (risco != null && plano.length < maximoPorDia) {
    final hora = horaDoAvisoDaRaiz(habito);
    // A raiz que vai quebrar entra mesmo colada no relatório da noite. O
    // relatório conta o dia que passou; este avisa que quarenta dias podem
    // acabar em três horas. Se um dos dois tem de tocar duas vezes seguidas,
    // não é o relatório. Já o risco absorvido pelo congelamento não perde
    // nada hoje — esse cede.
    if (cabe(hora) || risco.vaiQuebrar) {
      plano.add(
        LembreteDoDia(
          tipo: TipoDeLembrete.raizEmRisco,
          hora: hora,
          minuto: 0,
          repeteTodoDia: false,
          pulaHoje: false,
        ),
      );
      ocupadas.add(hora);
    }
  }

  if (plano.length < maximoPorDia) {
    // Minuto zero e não o minuto médio do histograma: precisão de quarto de
    // hora sobre algumas dezenas de amostras seria precisão falsa. E um
    // empurrão um pouco antes do hábito é melhor que um no meio dele.
    final hora = habito?.hora ?? horaSemHabito;
    if (cabe(hora)) {
      plano.add(
        LembreteDoDia(
          tipo: TipoDeLembrete.descanso,
          hora: hora,
          minuto: 0,
          repeteTodoDia: true,
          pulaHoje: descansoFeitoHoje,
        ),
      );
      ocupadas.add(hora);
    }
  }

  plano.sort((a, b) => a.hora.compareTo(b.hora));
  return plano;
}
