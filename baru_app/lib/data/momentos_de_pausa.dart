/// As pausas ao longo do dia: chamar a pessoa **na hora em que ela costuma
/// estar presa na tela**, e não no horário em que ela usa o Baru.
///
/// O convite do dia (`descanso_retencao.dart`) sai no horário do hábito,
/// que é aprendido das sessões de foco — quando a pessoa já está no app.
/// Ele não alcança o momento que importa para a missão: as 22h no feed,
/// o almoço que vira meia hora de vídeo curto. Esse momento já está medido:
/// os eventos crus do Android (ADR-009) dizem, hora a hora, quando o
/// telefone fica ligado num app que conta para a meta.
///
/// Três decisões vivem aqui, como função pura:
///
/// * **o perfil** — quantos minutos contáveis cada hora do dia costuma ter,
///   separando dia útil de fim de semana, e a que horas costumam começar as
///   maratonas (uso contínuo de 20 min ou mais);
/// * **os momentos** — as horas de pico, com distância entre elas e dos
///   outros recados, dentro da janela do dia;
/// * **a fadiga** — hora que foi chamada e ignorada perde peso
///   (`HistoricoDeRecados.receptividadeDaHora`), e quem ignora todas passa
///   a receber uma só.
///
/// **Sem evidência, sem pausa.** Sem acesso ao uso não há perfil, e um
/// horário de pico inventado seria a mesma mentira que o ADR-009 tirou do
/// tempo de tela.
library;

import 'tempo_de_tela.dart';

/// Quanto uso cada hora do dia costuma ter.
class PerfilDeUso {
  PerfilDeUso({
    required List<double> minutosUteis,
    required List<double> minutosFimDeSemana,
    required List<int> maratonasUteis,
    required List<int> maratonasFimDeSemana,
    required this.diasUteis,
    required this.diasFimDeSemana,
  })  : _minutosUteis = List.unmodifiable(minutosUteis),
        _minutosFimDeSemana = List.unmodifiable(minutosFimDeSemana),
        _maratonasUteis = List.unmodifiable(maratonasUteis),
        _maratonasFimDeSemana = List.unmodifiable(maratonasFimDeSemana);

  /// Minutos somados em cada hora (0 a 23), nos dias observados.
  final List<double> _minutosUteis;
  final List<double> _minutosFimDeSemana;

  /// Maratonas que **começaram** em cada hora.
  final List<int> _maratonasUteis;
  final List<int> _maratonasFimDeSemana;

  final int diasUteis;
  final int diasFimDeSemana;

  int get dias => diasUteis + diasFimDeSemana;
  bool get vazio => dias == 0;

  /// Com menos que isto de um tipo de dia, vale o perfil inteiro: dois
  /// sábados não fazem um padrão de fim de semana.
  static const minimoDeDiasPorTipo = 2;

  static bool fimDeSemana(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  ({double minutos, int maratonas, int dias}) _doTipo(int hora, DateTime dia) {
    final fds = fimDeSemana(dia);
    final diasDoTipo = fds ? diasFimDeSemana : diasUteis;
    if (diasDoTipo >= minimoDeDiasPorTipo) {
      return fds
          ? (
              minutos: _minutosFimDeSemana[hora],
              maratonas: _maratonasFimDeSemana[hora],
              dias: diasDoTipo,
            )
          : (
              minutos: _minutosUteis[hora],
              maratonas: _maratonasUteis[hora],
              dias: diasDoTipo,
            );
    }
    return (
      minutos: _minutosUteis[hora] + _minutosFimDeSemana[hora],
      maratonas: _maratonasUteis[hora] + _maratonasFimDeSemana[hora],
      dias: dias,
    );
  }

  /// Minutos contáveis que [hora] costuma ter num dia como [dia].
  double mediaNaHora(int hora, DateTime dia) {
    if (vazio) return 0;
    final d = _doTipo(hora, dia);
    return d.minutos / d.dias;
  }

  /// Em que fração dos dias como [dia] uma maratona começou em [hora].
  double maratonasNaHora(int hora, DateTime dia) {
    if (vazio) return 0;
    final d = _doTipo(hora, dia);
    return d.maratonas / d.dias;
  }

  @override
  String toString() => 'PerfilDeUso($diasUteis úteis, $diasFimDeSemana fds)';
}

/// Uso contínuo a partir de quanto conta como maratona.
const duracaoDeMaratona = Duration(minutes: 20);

/// Quanto silêncio entre dois trechos ainda conta como o mesmo uso. Olhar
/// a notificação e voltar para o feed não encerra a maratona.
const folgaDaMaratona = Duration(minutes: 2);

/// Monta o perfil dos últimos dias inteiros.
///
/// [conta] diz se um pacote entra: o que conta para a meta (dispersivo e
/// neutro). Ouvir música e ler não são o que a pausa quer interromper.
///
/// **Hoje fica de fora.** O dia pela metade pesaria a manhã contra a noite
/// que ainda não aconteceu. Os dias contam do primeiro dia com algum uso
/// até ontem: um aparelho que só tem três dias de eventos tem três dias de
/// perfil, não sete com quatro zerados.
PerfilDeUso perfilDeUso(
  Iterable<IntervaloDeUso> intervalos, {
  required bool Function(String pacote) conta,
  required DateTime agora,
  int janelaEmDias = 7,
}) {
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final inicio = DateTime(hoje.year, hoje.month, hoje.day - janelaEmDias);

  final minutosUteis = List<double>.filled(24, 0);
  final minutosFds = List<double>.filled(24, 0);
  final maratonasUteis = List<int>.filled(24, 0);
  final maratonasFds = List<int>.filled(24, 0);

  final contaveis = [
    for (final i in intervalos)
      if (conta(i.pacote) && i.fim.isAfter(inicio) && i.inicio.isBefore(hoje))
        IntervaloDeUso(
          pacote: i.pacote,
          inicio: i.inicio.isBefore(inicio) ? inicio : i.inicio,
          fim: i.fim.isAfter(hoje) ? hoje : i.fim,
        ),
  ]..sort((a, b) => a.inicio.compareTo(b.inicio));

  if (contaveis.isEmpty) {
    return PerfilDeUso(
      minutosUteis: minutosUteis,
      minutosFimDeSemana: minutosFds,
      maratonasUteis: maratonasUteis,
      maratonasFimDeSemana: maratonasFds,
      diasUteis: 0,
      diasFimDeSemana: 0,
    );
  }

  // Os minutos, hora a hora. Um trecho que atravessa a virada da hora é
  // repartido: 21h50 às 22h20 são dez minutos das 21h e vinte das 22h.
  for (final i in contaveis) {
    var cursor = i.inicio;
    while (cursor.isBefore(i.fim)) {
      final virada = DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        cursor.hour + 1,
      );
      final ate = virada.isBefore(i.fim) ? virada : i.fim;
      final minutos = ate.difference(cursor).inSeconds / 60;
      if (PerfilDeUso.fimDeSemana(cursor)) {
        minutosFds[cursor.hour] += minutos;
      } else {
        minutosUteis[cursor.hour] += minutos;
      }
      cursor = ate;
    }
  }

  // As maratonas: trechos colados (folga de até 2 min) somando 20 min ou
  // mais. Conta a hora em que começaram — é ali que a pausa ainda corta.
  DateTime? comeco;
  DateTime? fimDoBloco;
  void fechaBloco() {
    final c = comeco;
    final f = fimDoBloco;
    if (c == null || f == null) return;
    if (f.difference(c) >= duracaoDeMaratona) {
      if (PerfilDeUso.fimDeSemana(c)) {
        maratonasFds[c.hour] += 1;
      } else {
        maratonasUteis[c.hour] += 1;
      }
    }
  }

  for (final i in contaveis) {
    final f = fimDoBloco;
    if (f != null && i.inicio.difference(f) <= folgaDaMaratona) {
      if (i.fim.isAfter(f)) fimDoBloco = i.fim;
      continue;
    }
    fechaBloco();
    comeco = i.inicio;
    fimDoBloco = i.fim;
  }
  fechaBloco();

  var diasUteis = 0;
  var diasFds = 0;
  final primeiro = contaveis.first.inicio;
  for (var d = DateTime(primeiro.year, primeiro.month, primeiro.day);
      d.isBefore(hoje);
      d = DateTime(d.year, d.month, d.day + 1)) {
    if (PerfilDeUso.fimDeSemana(d)) {
      diasFds++;
    } else {
      diasUteis++;
    }
  }

  return PerfilDeUso(
    minutosUteis: minutosUteis,
    minutosFimDeSemana: minutosFds,
    maratonasUteis: maratonasUteis,
    maratonasFimDeSemana: maratonasFds,
    diasUteis: diasUteis,
    diasFimDeSemana: diasFds,
  );
}

/// Um momento escolhido para chamar a pausa.
class MomentoDePausa {
  const MomentoDePausa({required this.quando, required this.minutosNaHora});

  final DateTime quando;

  /// Quantos minutos contáveis essa hora costuma ter. Vai para o texto:
  /// "por volta das 22h você costuma passar 35 min na tela" é um recado que
  /// só este aparelho podia escrever.
  final int minutosNaHora;

  @override
  String toString() => 'MomentoDePausa($quando, $minutosNaHora min)';
}

/// As horas de pico de [dia] em que vale chamar a pausa.
///
/// **A nota da hora** é a média de minutos contáveis dela mais dez pontos
/// por maratona-por-dia: meia hora espalhada em vinte desbloqueios é menos
/// interrompível do que vinte minutos seguidos no mesmo feed. A nota é
/// multiplicada pela [receptividade] da hora — a hora ignorada vai cedendo
/// lugar.
///
/// **O que a escolha respeita:**
/// * só horas com uso de verdade ([minimoDeMinutos] na média, ou maratona
///   em pelo menos [minimoDeMaratonas] dos dias);
/// * a janela de [primeiraHora] a [ultimaHora] — a pausa não toca antes do
///   dia começar nem na hora de dormir;
/// * [distanciaEntrePausas] entre duas pausas e [distanciaDosOutros] dos
///   [ocupados] (convite, raiz, relatório): recados colados viram um borrão
///   na gaveta;
/// * nada antes de [agora] nem de [naoAntesDe] — sessão em curso, descanso
///   recém-feito.
///
/// O recado sai aos [minuto] minutos da hora: quem entrou no feed às 22h
/// está nele há um quarto de hora, que é quando "só mais um" começa.
List<MomentoDePausa> momentosDePausa(
  PerfilDeUso perfil, {
  required DateTime dia,
  required DateTime agora,
  Iterable<DateTime> ocupados = const [],
  DateTime? naoAntesDe,
  double Function(int hora)? receptividade,
  int maximo = 3,
  int primeiraHora = 9,
  // 21h: o alarme inexato do Android 12+ pode chegar até uma hora depois, e
  // 22h15 já é a hora de dormir (laudo 01, §9.3).
  int ultimaHora = 21,
  int minuto = 15,
  double minimoDeMinutos = 8,
  double minimoDeMaratonas = 0.3,
  Duration distanciaEntrePausas = const Duration(hours: 3),
  Duration distanciaDosOutros = const Duration(hours: 2),
}) {
  if (perfil.vazio || maximo <= 0) return const [];

  final candidatos = <({int hora, double nota, double media})>[];
  for (var h = primeiraHora; h <= ultimaHora; h++) {
    final media = perfil.mediaNaHora(h, dia);
    final maratonas = perfil.maratonasNaHora(h, dia);
    if (media < minimoDeMinutos && maratonas < minimoDeMaratonas) continue;

    final quando = DateTime(dia.year, dia.month, dia.day, h, minuto);
    if (!quando.isAfter(agora)) continue;
    final limite = naoAntesDe;
    if (limite != null && quando.isBefore(limite)) continue;

    final peso = receptividade?.call(h) ?? 1;
    final nota = (media + 10 * maratonas) * peso;
    // Hora que foi chamada e ignorada até a nota cair abaixo do mínimo
    // deixa de ser chamada.
    if (nota < minimoDeMinutos) continue;
    candidatos.add((hora: h, nota: nota, media: media));
  }

  // A melhor nota primeiro; no empate, a hora mais cedo — ainda sobra dia
  // para a pausa render.
  candidatos.sort((a, b) {
    final c = b.nota.compareTo(a.nota);
    return c != 0 ? c : a.hora.compareTo(b.hora);
  });

  final escolhidos = <MomentoDePausa>[];
  for (final c in candidatos) {
    if (escolhidos.length >= maximo) break;
    final quando = DateTime(dia.year, dia.month, dia.day, c.hora, minuto);
    final longeDasPausas = escolhidos.every(
      (e) => e.quando.difference(quando).abs() >= distanciaEntrePausas,
    );
    final longeDosOutros = ocupados.every(
      (o) => o.difference(quando).abs() >= distanciaDosOutros,
    );
    if (!longeDasPausas || !longeDosOutros) continue;
    escolhidos.add(
      MomentoDePausa(quando: quando, minutosNaHora: c.media.round()),
    );
  }

  escolhidos.sort((a, b) => a.quando.compareTo(b.quando));
  return escolhidos;
}
