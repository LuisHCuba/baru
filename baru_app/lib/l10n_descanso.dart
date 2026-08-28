/// Os textos da missão do descanso e da retenção diária.
///
/// Ficam num mapa próprio, registrado sob demanda, porque `lib/l10n.dart` é
/// o ponto de colisão de qualquer trabalho em paralelo — ver `T.registra`.
/// O catálogo principal ganha de qualquer chave daqui, então todas são
/// prefixadas e nenhuma disputa nome com o que já existe.
library;

import 'data/descanso_do_dia.dart';
import 'data/descanso_retencao.dart';
import 'data/missoes.dart';
import 'l10n.dart';

const textosDoDescanso = <String, Map<String, String>>{
  'pt': {
    'descansoTitulo': 'Descanse {n} minutos seguidos',
    'descansoComo': 'Largue o telefone. Eu conto o tempo por você.',
    'descansoComecar': 'Começar o descanso',
    'descansoCorrendo': 'Descansando · {n} de {a} min',
    'descansoVoltou':
        'Você ficou {n} min em outro app. O descanso não correu nesse tempo.',
    'descansoRompeu':
        'Este descanso acabou aos {n} min. Comece outro quando quiser — o melhor de hoje fica guardado.',
    'descansoFeito': '{n} minutos longe do telefone. Missão do dia cumprida.',
    'descansoMelhor': 'Melhor de hoje: {n} min',
    'descansoSemUso':
        'Sem o acesso ao uso eu não sei se o telefone ficou parado. Conceda para o descanso valer.',
    'descansoVigiaFala': 'Seu descanso parou aqui.',
    'descansoVigiaTitulo': '{n} está descansando com você',
    'descansoVigiaCorpo': 'O tempo só corre com o telefone parado.',
    'descansoLembreteTitulo': 'Hora do descanso',
    'descansoLembreteCorpo': '{n} separou {m} minutos longe da tela.',
    'raizRiscoTitulo': 'Sua raiz de {n} dias',
    'raizRiscoCorpo': 'Ela quebra à meia-noite. Uma sessão curta segura.',
    'raizRiscoMarco':
        'Faltam {d} dias para o marco de {m}. Ela quebra à meia-noite.',
    'raizCongelaTitulo': 'Seu congelamento entra hoje',
    'raizCongelaCorpo':
        'A raiz de {n} dias continua. É o único congelamento da semana.',
    'voltaTitulo': 'Você voltou',
    'voltaCorpo': '{d} dias fora. Guardei seu lugar. +{k} folhas.',
    'voltaCongelamento': 'E devolvi o congelamento da semana.',
  },
  'en': {
    'descansoTitulo': 'Rest for {n} minutes straight',
    'descansoComo': 'Put the phone down. I will keep the time.',
    'descansoComecar': 'Start resting',
    'descansoCorrendo': 'Resting · {n} of {a} min',
    'descansoVoltou':
        'You spent {n} min in another app. Rest did not run during that.',
    'descansoRompeu':
        'This rest ended at {n} min. Start another whenever — today\'s best is kept.',
    'descansoFeito':
        '{n} minutes away from the phone. Today\'s mission is done.',
    'descansoMelhor': 'Best today: {n} min',
    'descansoSemUso':
        'Without usage access I cannot tell whether the phone was idle. Grant it to make rest count.',
    'descansoVigiaFala': 'Your rest stopped here.',
    'descansoVigiaTitulo': '{n} is resting with you',
    'descansoVigiaCorpo': 'Time only runs while the phone is down.',
    'descansoLembreteTitulo': 'Time to rest',
    'descansoLembreteCorpo': '{n} set aside {m} minutes away from the screen.',
    'raizRiscoTitulo': 'Your {n}-day roots',
    'raizRiscoCorpo': 'They break at midnight. A short session holds them.',
    'raizRiscoMarco':
        '{d} days to the {m}-day mark. They break at midnight.',
    'raizCongelaTitulo': 'Your freeze covers today',
    'raizCongelaCorpo':
        'The {n}-day roots hold. It is the only freeze this week.',
    'voltaTitulo': 'You came back',
    'voltaCorpo': '{d} days away. I kept your spot. +{k} leaves.',
    'voltaCongelamento': 'And your weekly freeze is back.',
  },
  'es': {
    'descansoTitulo': 'Descansa {n} minutos seguidos',
    'descansoComo': 'Suelta el teléfono. Yo llevo el tiempo.',
    'descansoComecar': 'Empezar el descanso',
    'descansoCorrendo': 'Descansando · {n} de {a} min',
    'descansoVoltou':
        'Pasaste {n} min en otra app. El descanso no corrió en ese tiempo.',
    'descansoRompeu':
        'Este descanso terminó a los {n} min. Empieza otro cuando quieras: lo mejor de hoy queda guardado.',
    'descansoFeito':
        '{n} minutos lejos del teléfono. Misión del día cumplida.',
    'descansoMelhor': 'Mejor de hoy: {n} min',
    'descansoSemUso':
        'Sin acceso al uso no sé si el teléfono quedó quieto. Concédelo para que el descanso cuente.',
    'descansoVigiaFala': 'Tu descanso se detuvo aquí.',
    'descansoVigiaTitulo': '{n} está descansando contigo',
    'descansoVigiaCorpo': 'El tiempo solo corre con el teléfono quieto.',
    'descansoLembreteTitulo': 'Hora de descansar',
    'descansoLembreteCorpo':
        '{n} apartó {m} minutos lejos de la pantalla.',
    'raizRiscoTitulo': 'Tu raíz de {n} días',
    'raizRiscoCorpo': 'Se rompe a medianoche. Una sesión corta la sostiene.',
    'raizRiscoMarco':
        'Faltan {d} días para el hito de {m}. Se rompe a medianoche.',
    'raizCongelaTitulo': 'Tu congelamiento entra hoy',
    'raizCongelaCorpo':
        'La raíz de {n} días sigue. Es el único congelamiento de la semana.',
    'voltaTitulo': 'Volviste',
    'voltaCorpo': '{d} días fuera. Te guardé el lugar. +{k} hojas.',
    'voltaCongelamento': 'Y te devolví el congelamiento de la semana.',
  },
  'zh': {
    'descansoTitulo': '连续休息 {n} 分钟',
    'descansoComo': '放下手机，时间我来记。',
    'descansoComecar': '开始休息',
    'descansoCorrendo': '休息中 · {n}/{a} 分钟',
    'descansoVoltou': '你在别的应用里待了 {n} 分钟，这段时间不计入休息。',
    'descansoRompeu': '这次休息在 {n} 分钟处结束了。随时可以再来一次，今天的最好成绩会保留。',
    'descansoFeito': '远离手机 {n} 分钟。今天的任务完成了。',
    'descansoMelhor': '今天最好：{n} 分钟',
    'descansoSemUso': '没有使用权限，我无法判断手机是否放下了。授权后休息才算数。',
    'descansoVigiaFala': '你的休息在这里停住了。',
    'descansoVigiaTitulo': '{n} 正在陪你休息',
    'descansoVigiaCorpo': '只有手机放下时，时间才会走。',
    'descansoLembreteTitulo': '该休息了',
    'descansoLembreteCorpo': '{n} 为你留出了 {m} 分钟远离屏幕的时间。',
    'raizRiscoTitulo': '你的 {n} 天根',
    'raizRiscoCorpo': '它会在午夜断掉。一次短专注就能保住。',
    'raizRiscoMarco': '距离 {m} 天的里程碑还差 {d} 天。它会在午夜断掉。',
    'raizCongelaTitulo': '今天会用掉一次冻结',
    'raizCongelaCorpo': '{n} 天的根还在。这是本周唯一一次冻结。',
    'voltaTitulo': '你回来了',
    'voltaCorpo': '离开了 {d} 天。我给你留着位置。+{k} 片叶子。',
    'voltaCongelamento': '本周的冻结也还给你了。',
  },
};

void garanteTextosDoDescanso() => T.registra(textosDoDescanso);

/// Os acessos, como getters.
///
/// `t.s('chave')` funcionaria, mas erro de digitação só apareceria na tela
/// da pessoa. Extensão dá o erro no compilador, que é onde ele custa barato.
extension TextosDoDescanso on T {
  String get descansoTitulo => s('descansoTitulo');
  String get descansoComo => s('descansoComo');
  String get descansoComecar => s('descansoComecar');
  String get descansoCorrendo => s('descansoCorrendo');
  String get descansoVoltou => s('descansoVoltou');
  String get descansoRompeu => s('descansoRompeu');
  String get descansoFeito => s('descansoFeito');
  String get descansoMelhor => s('descansoMelhor');
  String get descansoSemUso => s('descansoSemUso');
  String get descansoVigiaFala => s('descansoVigiaFala');
  String get descansoVigiaTitulo => s('descansoVigiaTitulo');
  String get descansoVigiaCorpo => s('descansoVigiaCorpo');
  String get descansoLembreteTitulo => s('descansoLembreteTitulo');
  String get descansoLembreteCorpo => s('descansoLembreteCorpo');
  String get raizRiscoTitulo => s('raizRiscoTitulo');
  String get raizRiscoCorpo => s('raizRiscoCorpo');
  String get raizRiscoMarco => s('raizRiscoMarco');
  String get raizCongelaTitulo => s('raizCongelaTitulo');
  String get raizCongelaCorpo => s('raizCongelaCorpo');
  String get voltaTitulo => s('voltaTitulo');
  String get voltaCorpo => s('voltaCorpo');
  String get voltaCongelamento => s('voltaCongelamento');
}

/// O título da missão, em linguagem de ação.
String tituloDoDescanso(T t, MissaoDoDescanso m) {
  garanteTextosDoDescanso();
  return t.fill(t.descansoTitulo, {'n': m.alvo});
}

/// O "como" — o que fazer, sem abrir nada.
String comoDoDescanso(T t) {
  garanteTextosDoDescanso();
  return t.descansoComo;
}

/// A linha de estado da missão.
///
/// **É aqui que a perda é comunicada** (D-02). O progresso parar enquanto a
/// pessoa está fora não serve de nada se ela voltar e vir a mesma frase de
/// antes: sem esta linha, o custo de escapar é invisível, e um custo
/// invisível não é custo. Nenhuma das versões acusa — dizem o que aconteceu
/// com o relógio, não o que a pessoa deveria ter feito.
String recadoDoDescanso(T t, MissaoDoDescanso m) {
  garanteTextosDoDescanso();
  if (!m.disponivel) return t.descansoSemUso;

  final leitura = m.emCurso;
  if (leitura == null) {
    return m.melhorDoDia > Duration.zero
        ? t.fill(t.descansoMelhor, {'n': m.progresso})
        : t.descansoComo;
  }

  switch (leitura.fase) {
    case FaseDoDescanso.completo:
      return t.fill(t.descansoFeito, {'n': leitura.minutos});
    case FaseDoDescanso.rompido:
      return t.fill(t.descansoRompeu, {'n': leitura.minutos});
    case FaseDoDescanso.expirado:
      return t.fill(t.descansoMelhor, {'n': m.progresso});
    case FaseDoDescanso.emAndamento:
      if (leitura.houveFuga) {
        return t.fill(t.descansoVoltou, {'n': leitura.minutosDeFuga});
      }
      return t.fill(t.descansoCorrendo, {
        'n': leitura.minutos,
        'a': leitura.minutosDeAlvo,
      });
  }
}

/// Os textos dos lembretes do dia, prontos para o agendamento.
///
/// [risco] decide entre as duas vozes do aviso da raiz: perder a sequência e
/// gastar o congelamento da semana são coisas diferentes, e dizer "sua raiz
/// vai quebrar" a quem tem congelamento seria mentira. Quando o marco está
/// perto, o aviso diz qual é — a mesma raiz a dois dias de um galho novo dói
/// mais que a dez.
Map<TipoDeLembrete, TextoDeLembrete> textosDosLembretes(
  T t, {
  required String nomeDoPet,
  required int minutosDeDescanso,
  RaizEmRisco? risco,
}) {
  garanteTextosDoDescanso();
  final mapa = <TipoDeLembrete, TextoDeLembrete>{
    TipoDeLembrete.descanso: TextoDeLembrete(
      titulo: t.descansoLembreteTitulo,
      corpo: t.fill(t.descansoLembreteCorpo, {
        'n': nomeDoPet,
        'm': minutosDeDescanso,
      }),
    ),
  };

  if (risco != null) {
    final marco = risco.proximoMarco;
    final falta = risco.faltaParaOMarco;
    mapa[TipoDeLembrete.raizEmRisco] = risco.vaiQuebrar
        ? TextoDeLembrete(
            titulo: t.fill(t.raizRiscoTitulo, {'n': risco.dias}),
            corpo: risco.vesperaDeMarco && marco != null && falta != null
                ? t.fill(t.raizRiscoMarco, {'d': falta, 'm': marco})
                : t.raizRiscoCorpo,
          )
        : TextoDeLembrete(
            titulo: t.raizCongelaTitulo,
            corpo: t.fill(t.raizCongelaCorpo, {'n': risco.dias}),
          );
  }

  return mapa;
}

/// O recado de quem voltou (RD-03).
String recadoDaVolta(T t, VoltaAoNinho volta) {
  garanteTextosDoDescanso();
  final base = t.fill(t.voltaCorpo, {
    'd': volta.diasFora,
    'k': volta.folhas,
  });
  return volta.devolveCongelamento
      ? '$base ${t.voltaCongelamento}'
      : base;
}
