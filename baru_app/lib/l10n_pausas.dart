/// Os textos das pausas ao longo do dia (`data/momentos_de_pausa.dart`).
///
/// Mapa próprio, registrado sob demanda, pelo mesmo motivo do
/// `l10n_descanso.dart`: `lib/l10n.dart` é o ponto de colisão de qualquer
/// trabalho em paralelo — ver `T.registra`.
///
/// **O tom.** A pausa chega no meio do feed, então ela não pode soar como
/// bronca: nada de "de novo?", nada de número de horas perdidas. Ela diz o
/// padrão que o aparelho viu e oferece o bicho como companhia. E todo corpo
/// diz o que o toque faz — o toque já começa o descanso.
library;

import 'data/momentos_de_pausa.dart';
import 'data/recados.dart';
import 'data/descanso_retencao.dart';
import 'l10n.dart';

const textosDasPausas = <String, Map<String, String>>{
  'pt': {
    'pausa1Titulo': '{n} reparou numa coisa',
    'pausa1Corpo':
        'Por volta das {h}h você costuma passar {x} min na tela. Toque e eu conto uma pausa.',
    'pausa2Titulo': 'Que tal uma pausa?',
    'pausa2Corpo':
        'Solta o telefone um pouquinho. {n} descansa junto e conta o tempo.',
    'pausa3Titulo': '{n} está bocejando',
    'pausa3Corpo':
        'Uns minutos longe da tela já mudam o dia. Toque para começar.',
    'pausa4Titulo': 'Hora de respirar',
    'pausa4Corpo':
        'É o horário em que a tela costuma te prender. Toque e comece uma pausa com {n}.',
    'canalNomePausa': 'Pausas ao longo do dia',
  },
  'en': {
    'pausa1Titulo': '{n} noticed something',
    'pausa1Corpo':
        'Around {h}:00 you usually spend {x} min on screen. Tap and I\'ll time a break.',
    'pausa2Titulo': 'How about a break?',
    'pausa2Corpo':
        'Put the phone down for a bit. {n} rests with you and keeps the time.',
    'pausa3Titulo': '{n} is yawning',
    'pausa3Corpo':
        'A few minutes away from the screen changes the day. Tap to start.',
    'pausa4Titulo': 'Time to breathe',
    'pausa4Corpo':
        'This is when the screen usually holds on to you. Tap and take a break with {n}.',
    'canalNomePausa': 'Breaks during the day',
  },
  'es': {
    'pausa1Titulo': '{n} notó algo',
    'pausa1Corpo':
        'Hacia las {h}h sueles pasar {x} min en la pantalla. Toca y cuento una pausa.',
    'pausa2Titulo': '¿Qué tal una pausa?',
    'pausa2Corpo':
        'Suelta el teléfono un ratito. {n} descansa contigo y cuenta el tiempo.',
    'pausa3Titulo': '{n} está bostezando',
    'pausa3Corpo':
        'Unos minutos lejos de la pantalla ya cambian el día. Toca para empezar.',
    'pausa4Titulo': 'Hora de respirar',
    'pausa4Corpo':
        'Es la hora en que la pantalla suele atraparte. Toca y empieza una pausa con {n}.',
    'canalNomePausa': 'Pausas durante el día',
  },
  'zh': {
    'pausa1Titulo': '{n} 发现了一件事',
    'pausa1Corpo': '每天 {h} 点左右，你通常会在屏幕上花 {x} 分钟。点一下，我来为你计时休息。',
    'pausa2Titulo': '休息一下吧？',
    'pausa2Corpo': '把手机放下一会儿。{n} 陪你休息，帮你计时。',
    'pausa3Titulo': '{n} 在打哈欠',
    'pausa3Corpo': '离开屏幕几分钟，一天就会不一样。点一下开始。',
    'pausa4Titulo': '该喘口气了',
    'pausa4Corpo': '这是屏幕最容易抓住你的时候。点一下，和 {n} 一起休息。',
    'canalNomePausa': '白天的休息提醒',
  },
};

void garanteTextosDasPausas() => T.registra(textosDasPausas);

extension TextosDasPausas on T {
  String get pausa1Titulo => s('pausa1Titulo');
  String get pausa1Corpo => s('pausa1Corpo');
  String get pausa2Titulo => s('pausa2Titulo');
  String get pausa2Corpo => s('pausa2Corpo');
  String get pausa3Titulo => s('pausa3Titulo');
  String get pausa3Corpo => s('pausa3Corpo');
  String get pausa4Titulo => s('pausa4Titulo');
  String get pausa4Corpo => s('pausa4Corpo');
  String get canalNomePausa => s('canalNomePausa');
}

/// Os modelos da pausa para um momento: o mesmo id em todos os momentos, o
/// texto com a hora e os minutos daquele momento.
List<ModeloDeRecado> modelosDaPausa(
  T t, {
  required String nomeDoPet,
  required MomentoDePausa momento,
}) {
  garanteTextosDasPausas();
  final valores = {
    'n': nomeDoPet,
    'h': momento.quando.hour,
    'x': momento.minutosNaHora,
  };
  final variantes = [
    (t.pausa1Titulo, t.pausa1Corpo),
    (t.pausa2Titulo, t.pausa2Corpo),
    (t.pausa3Titulo, t.pausa3Corpo),
    (t.pausa4Titulo, t.pausa4Corpo),
  ];
  return [
    for (var i = 0; i < variantes.length; i++)
      ModeloDeRecado(
        '${HistoricoDeRecados.prefixoDaPausa}${i + 1}',
        TextoDeLembrete(
          titulo: t.fill(variantes[i].$1, valores),
          corpo: t.fill(variantes[i].$2, valores),
          modelo: '${HistoricoDeRecados.prefixoDaPausa}${i + 1}',
        ),
      ),
  ];
}

/// Um texto para cada momento, escolhido pelo caderno de recados.
///
/// O caderno escolhe os ids com a recência simulada entre os momentos (três
/// pausas no mesmo dia não saem com o mesmo texto); o texto de cada um é
/// montado com os números do próprio momento.
List<TextoDeLembrete> textosDasPausasDoDia(
  T t, {
  required String nomeDoPet,
  required List<MomentoDePausa> momentos,
  HistoricoDeRecados? historico,
}) {
  if (momentos.isEmpty) return const [];
  final porMomento = [
    for (final m in momentos)
      modelosDaPausa(t, nomeDoPet: nomeDoPet, momento: m),
  ];
  final ids = historico == null
      ? [
          for (var i = 0; i < momentos.length; i++)
            porMomento[i][i % porMomento[i].length].id,
        ]
      : [
          for (final m in historico.escolhe(
            porMomento.first,
            [for (final m in momentos) m.quando],
          ))
            m.id,
        ];
  return [
    for (var i = 0; i < momentos.length; i++)
      porMomento[i].firstWhere((m) => m.id == ids[i]).texto,
  ];
}
