/// A medida do descanso.
///
/// A missão principal do dia é ficar um tempo contínuo longe do telefone.
/// Medir isso **não** é ligar um `Timer`: com o app em segundo plano o
/// Flutter não executa (ADR-014), e um contador que só anda com a tela do
/// Baru aberta mediria exatamente o contrário do que a missão pede — quanto
/// mais a pessoa descansa, menos ele contaria.
///
/// O que se mede aqui é uma **subtração**, e as duas parcelas já existem no
/// app: o relógio de parede desde o começo da tentativa, e o tempo de tela
/// que o Android registrou nesse meio (ADR-009). O que sobra é o tempo em
/// que o telefone ficou parado. Nada novo é pedido ao sistema, nenhum
/// serviço extra fica de pé, e a conta continua valendo com o app morto.
///
/// **Nada aqui bloqueia coisa nenhuma** (ADR-016). A fuga não é impedida:
/// ela é medida, e a medida é o que a pessoa vê.
library;

/// Os números da missão do descanso.
class Descanso {
  const Descanso._();

  /// Quanto tempo a missão pede.
  ///
  /// Quarenta minutos porque é o que o dono do produto pediu e porque é
  /// mais longo que a sessão de foco média (25 min): descansar não pode ser
  /// a missão barata do dia, ou vira o atalho para fechar o quadro.
  static const alvo = Duration(minutes: 40);

  /// Quanta fuga uma tentativa suporta antes de deixar de ser contínua.
  ///
  /// Não é zero de propósito. Um descanso que morre porque a pessoa olhou
  /// quem ligou não mede descanso, mede sorte — e transformaria a missão
  /// numa armadilha. Três minutos dão para ver uma mensagem e não dão para
  /// entrar num feed.
  static const tolerancia = Duration(minutes: 3);

  /// O que a missão paga.
  ///
  /// Acima de `foco_longo` (20) porque é a missão principal do dia, e abaixo
  /// das semanais porque continua sendo diária.
  static const folhas = 30;

  /// O id do resgate. Entra na chave com a data, como as outras missões.
  static const id = 'descanso';
}

/// Em que pé está uma tentativa de descanso.
enum FaseDoDescanso {
  /// Correndo. O relógio da tentativa só anda com o telefone parado.
  emAndamento,

  /// O alvo foi batido sem que a fuga passasse da tolerância.
  completo,

  /// A fuga passou da tolerância: esta tentativa deixou de ser contínua.
  /// **Não é punição** — o melhor do dia continua guardado, e outra
  /// tentativa pode começar agora.
  rompido,

  /// O dia virou por baixo da tentativa.
  expirado,
}

/// O retrato de uma tentativa num instante.
class LeituraDoDescanso {
  const LeituraDoDescanso({
    required this.fase,
    required this.descansado,
    required this.fuga,
    required this.noProprioApp,
    required this.decorrido,
    required this.alvo,
  });

  final FaseDoDescanso fase;

  /// O que conta: relógio de parede menos tela.
  final Duration descansado;

  /// Tempo em **outro** app. É isto que rompe a tentativa.
  final Duration fuga;

  /// Tempo olhando o próprio Baru.
  ///
  /// Não conta como descanso — olhar o bicho também é olhar a tela — mas
  /// **não rompe** a tentativa. Se rompesse, conferir quanto falta acabaria
  /// com o que se estava conferindo, e o app viraria uma armadilha contra
  /// quem confia nele.
  final Duration noProprioApp;

  final Duration decorrido;
  final Duration alvo;

  /// Minutos inteiros — a unidade em que a missão fala.
  int get minutos => descansado.inMinutes;
  int get minutosDeAlvo => alvo.inMinutes;
  int get minutosDeFuga => fuga.inMinutes;

  Duration get falta {
    final resto = alvo - descansado;
    return resto.isNegative ? Duration.zero : resto;
  }

  double get fracao => alvo.inSeconds <= 0
      ? 1
      : (descansado.inSeconds / alvo.inSeconds).clamp(0.0, 1.0);

  bool get emAndamento => fase == FaseDoDescanso.emAndamento;
  bool get completo => fase == FaseDoDescanso.completo;
  bool get rompido => fase == FaseDoDescanso.rompido;

  /// A tentativa acabou, de um jeito ou de outro: quem chama tem de fechá-la.
  bool get acabou => fase != FaseDoDescanso.emAndamento;

  /// Vale gravar no melhor do dia?
  ///
  /// Uma tentativa expirada atravessou a meia-noite, e a conta dela usa um
  /// contador de tela que zerou no meio — o número não descreve nada.
  bool get valeContar => fase != FaseDoDescanso.expirado;

  /// A pessoa saiu para outro app e voltou: houve perda a comunicar (D-02).
  bool get houveFuga => fuga > Duration.zero;
}

/// Lê uma tentativa de descanso.
///
/// [minutosDeTelaNoInicio] e [minutosDeTelaAgora] são o **total** de tempo de
/// tela do dia — não o contabilizado da meta. A meta compara dispersivo +
/// neutro porque ouvir música e ler não é o que se quer reduzir (ADR-009);
/// o descanso pergunta outra coisa, que é se a tela ficou apagada. Ler no
/// Kindle é tela. Usar aqui o número da meta deixaria uma hora de leitura
/// passar como descanso.
///
/// [noProprioApp] é quanto tempo o Baru esteve em primeiro plano desde
/// [comecouEm]. Precisa vir de fora porque o próprio Baru é excluído da
/// contabilidade de tela (`ExclusoesDeContagem`) — o app não aparece no
/// número que ele mesmo mede. Quem sabe disso é o ciclo de vida do app.
LeituraDoDescanso leDescanso({
  required DateTime comecouEm,
  required DateTime agora,
  required int minutosDeTelaNoInicio,
  required int minutosDeTelaAgora,
  Duration noProprioApp = Duration.zero,
  Duration alvo = Descanso.alvo,
  Duration tolerancia = Descanso.tolerancia,
}) {
  final bruto = agora.difference(comecouEm);
  // Relógio andando para trás (fuso, ajuste manual, NTP) não pode virar
  // descanso negativo nem descanso gigante. Sem evidência, zero.
  final decorrido = bruto.isNegative ? Duration.zero : bruto;

  final viradaDeDia = !_mesmoDia(comecouEm, agora);

  // O piso em zero não é zelo: o contador de tela anda para trás sempre que
  // a janela de medição muda — na virada do dia, principalmente. Uma fuga
  // negativa seria **somada** ao descanso, e o app daria de graça o que
  // veio de um erro de medição.
  final fuga = _limita(
    Duration(minutes: minutosDeTelaAgora - minutosDeTelaNoInicio),
    Duration.zero,
    decorrido,
  );
  final noApp = _limita(noProprioApp, Duration.zero, decorrido - fuga);
  final descansado = decorrido - fuga - noApp;

  final FaseDoDescanso fase;
  if (viradaDeDia) {
    fase = FaseDoDescanso.expirado;
  } else if (fuga > tolerancia) {
    // A ruptura vem antes da conclusão: uma tentativa que já tinha deixado
    // de ser contínua não vira missão cumprida só porque o relógio andou.
    fase = FaseDoDescanso.rompido;
  } else if (descansado >= alvo) {
    fase = FaseDoDescanso.completo;
  } else {
    fase = FaseDoDescanso.emAndamento;
  }

  return LeituraDoDescanso(
    fase: fase,
    descansado: descansado,
    fuga: fuga,
    noProprioApp: noApp,
    decorrido: decorrido,
    alvo: alvo,
  );
}

/// O melhor descanso do dia, depois de uma leitura nova.
///
/// **Só sobe.** O contrato de produto proíbe decaimento de progresso (§1), e
/// uma barra que anda para trás porque a pessoa foi ver uma mensagem seria
/// exatamente isso. O padrão é o mesmo de `maiorSessaoHoje` e o da trilha,
/// que lê a melhor sequência e não a atual.
Duration melhorDescanso(Duration melhorAtual, LeituraDoDescanso leitura) {
  if (!leitura.valeContar) return melhorAtual;
  return leitura.descansado > melhorAtual ? leitura.descansado : melhorAtual;
}

bool _mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Duration _limita(Duration v, Duration min, Duration max) {
  if (max < min) return min;
  if (v < min) return min;
  if (v > max) return max;
  return v;
}
