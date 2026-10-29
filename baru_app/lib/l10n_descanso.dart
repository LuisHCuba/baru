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
import 'data/recados.dart';
import 'l10n.dart';
import 'services/notification_service.dart';

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
        'Faltam {d} dias para o marco de {m}. A raiz quebra à meia-noite.',
    'raizCongelaTitulo': 'Seu congelamento entra hoje',
    'raizCongelaCorpo':
        'A raiz de {n} dias continua. É o único congelamento da semana.',
    'descansoLembrete2Titulo': '{n} achou uma sombra boa',
    'descansoLembrete2Corpo': 'Que tal {m} minutos longe da tela?',
    'descansoLembrete3Titulo': 'Um respiro longe da tela?',
    'descansoLembrete3Corpo': '{n} está esperando para descansar com você.',
    'raizRisco2Titulo': 'Sua raiz de {n} dias ainda cresce hoje',
    'raizRisco2Corpo': 'Uma sessão de foco basta.',
    'raizRisco3Titulo': '{p} deixou a terra regada',
    'raizRisco3Corpo': 'Falta só o seu foco de hoje para a raiz de {n} dias.',
    'raizAmanhaTitulo': '{p} guardou um lugar para você',
    'raizAmanhaCorpo': 'Uma sessão de foco hoje faz a raiz crescer.',
    'descansoLembrete4Titulo': '{n} guardou um cantinho tranquilo',
    'descansoLembrete4Corpo': '{m} minutos longe da tela e o dia fica mais leve.',
    'descansoLembrete5Titulo': 'Hora de esticar as pernas?',
    'descansoLembrete5Corpo': 'Uma pausa de {m} minutos, e {n} descansa junto.',
    'despedidaTitulo': 'Vou ficar quietinho',
    'despedidaCorpo':
        'Não mando mais lembretes. Quando quiser voltar, {n} vai estar aqui.',
    'canalNomeFim': 'Sessão concluída',
    'canalNomeRaiz': 'Raiz',
    'canalNomeConvite': 'Convite do dia',
    'canalNomeRelatorio': 'Relatório da noite',
    'canalNomeVolta': 'Quando você está longe',
    'canalNomeConta': 'Conta e assinatura',
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
        '{d} days to the {m}-day mark. The roots break at midnight.',
    'raizCongelaTitulo': 'Your freeze covers today',
    'raizCongelaCorpo':
        'The {n}-day roots hold. It is the only freeze this week.',
    'descansoLembrete2Titulo': '{n} found a nice shady spot',
    'descansoLembrete2Corpo': 'How about {m} minutes away from the screen?',
    'descansoLembrete3Titulo': 'A breather away from the screen?',
    'descansoLembrete3Corpo': '{n} is waiting to rest with you.',
    'raizRisco2Titulo': 'Your {n}-day roots can still grow today',
    'raizRisco2Corpo': 'One focus session is enough.',
    'raizRisco3Titulo': '{p} watered the soil',
    'raizRisco3Corpo': 'All your {n}-day roots need now is your focus today.',
    'raizAmanhaTitulo': '{p} saved you a spot',
    'raizAmanhaCorpo': 'One focus session today makes your roots grow.',
    'descansoLembrete4Titulo': '{n} saved a quiet corner',
    'descansoLembrete4Corpo':
        '{m} minutes away from the screen and the day feels lighter.',
    'descansoLembrete5Titulo': 'Time to stretch your legs?',
    'descansoLembrete5Corpo': 'A {m}-minute break, and {n} rests with you.',
    'despedidaTitulo': "I'll keep quiet now",
    'despedidaCorpo':
        'No more reminders from me. Whenever you want to come back, {n} will '
            'be here.',
    'canalNomeFim': 'Session finished',
    'canalNomeRaiz': 'Roots',
    'canalNomeConvite': 'Daily invite',
    'canalNomeRelatorio': 'Evening report',
    'canalNomeVolta': 'When you\'re away',
    'canalNomeConta': 'Account and subscription',
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
        'Faltan {d} días para el hito de {m}. La raíz se rompe a medianoche.',
    'raizCongelaTitulo': 'Tu congelamiento entra hoy',
    'raizCongelaCorpo':
        'La raíz de {n} días sigue. Es el único congelamiento de la semana.',
    'descansoLembrete2Titulo': '{n} encontró una buena sombra',
    'descansoLembrete2Corpo': '¿Qué tal {m} minutos lejos de la pantalla?',
    'descansoLembrete3Titulo': '¿Un respiro lejos de la pantalla?',
    'descansoLembrete3Corpo': '{n} te espera para descansar juntos.',
    'raizRisco2Titulo': 'Tu raíz de {n} días todavía crece hoy',
    'raizRisco2Corpo': 'Basta una sesión de foco.',
    'raizRisco3Titulo': '{p} dejó la tierra regada',
    'raizRisco3Corpo': 'Solo falta tu foco de hoy para la raíz de {n} días.',
    'raizAmanhaTitulo': '{p} te guardó un lugar',
    'raizAmanhaCorpo': 'Una sesión de foco hoy hace crecer tu raíz.',
    'descansoLembrete4Titulo': '{n} guardó un rincón tranquilo',
    'descansoLembrete4Corpo':
        '{m} minutos lejos de la pantalla y el día se vuelve más ligero.',
    'descansoLembrete5Titulo': '¿Hora de estirar las piernas?',
    'descansoLembrete5Corpo': 'Una pausa de {m} minutos, y {n} descansa contigo.',
    'despedidaTitulo': 'Me quedo calladito',
    'despedidaCorpo':
        'No mando más recordatorios. Cuando quieras volver, {n} estará aquí.',
    'canalNomeFim': 'Sesión terminada',
    'canalNomeRaiz': 'Raíz',
    'canalNomeConvite': 'Invitación del día',
    'canalNomeRelatorio': 'Informe de la noche',
    'canalNomeVolta': 'Cuando estás lejos',
    'canalNomeConta': 'Cuenta y suscripción',
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
    'raizRiscoMarco': '距离 {m} 天的里程碑还差 {d} 天。根会在午夜断掉。',
    'raizCongelaTitulo': '今天会用掉一次冻结',
    'raizCongelaCorpo': '{n} 天的根还在。这是本周唯一一次冻结。',
    'descansoLembrete2Titulo': '{n} 找到了一片好树荫',
    'descansoLembrete2Corpo': '离开屏幕 {m} 分钟怎么样？',
    'descansoLembrete3Titulo': '离开屏幕歇一会儿？',
    'descansoLembrete3Corpo': '{n} 在等你一起休息。',
    'raizRisco2Titulo': '你的 {n} 天根今天还能长',
    'raizRisco2Corpo': '一次专注就够了。',
    'raizRisco3Titulo': '{p} 已经浇好了土',
    'raizRisco3Corpo': '{n} 天的根只差你今天的一次专注。',
    'raizAmanhaTitulo': '{p} 给你留了个位置',
    'raizAmanhaCorpo': '今天专注一次，根就会长。',
    'descansoLembrete4Titulo': '{n} 留了一个安静的角落',
    'descansoLembrete4Corpo': '离开屏幕 {m} 分钟，一天都会轻松些。',
    'descansoLembrete5Titulo': '起来活动一下？',
    'descansoLembrete5Corpo': '休息 {m} 分钟，{n} 陪你一起。',
    'despedidaTitulo': '我先安静一会儿',
    'despedidaCorpo': '我不再发提醒了。想回来的时候，{n} 一直在这里。',
    'canalNomeFim': '专注完成',
    'canalNomeRaiz': '根',
    'canalNomeConvite': '每日邀请',
    'canalNomeRelatorio': '晚间报告',
    'canalNomeVolta': '你不在的时候',
    'canalNomeConta': '账户与订阅',
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
  String get descansoLembrete2Titulo => s('descansoLembrete2Titulo');
  String get descansoLembrete2Corpo => s('descansoLembrete2Corpo');
  String get descansoLembrete3Titulo => s('descansoLembrete3Titulo');
  String get descansoLembrete3Corpo => s('descansoLembrete3Corpo');
  String get raizRisco2Titulo => s('raizRisco2Titulo');
  String get raizRisco2Corpo => s('raizRisco2Corpo');
  String get raizRisco3Titulo => s('raizRisco3Titulo');
  String get raizRisco3Corpo => s('raizRisco3Corpo');
  String get raizAmanhaTitulo => s('raizAmanhaTitulo');
  String get raizAmanhaCorpo => s('raizAmanhaCorpo');
  String get descansoLembrete4Titulo => s('descansoLembrete4Titulo');
  String get descansoLembrete4Corpo => s('descansoLembrete4Corpo');
  String get descansoLembrete5Titulo => s('descansoLembrete5Titulo');
  String get descansoLembrete5Corpo => s('descansoLembrete5Corpo');
  String get despedidaTitulo => s('despedidaTitulo');
  String get despedidaCorpo => s('despedidaCorpo');
  String get canalNomeFim => s('canalNomeFim');
  String get canalNomeRaiz => s('canalNomeRaiz');
  String get canalNomeConvite => s('canalNomeConvite');
  String get canalNomeRelatorio => s('canalNomeRelatorio');
  String get canalNomeVolta => s('canalNomeVolta');
  String get canalNomeConta => s('canalNomeConta');
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
  DateTime? dia,
  HistoricoDeRecados? historico,
}) {
  garanteTextosDoDescanso();
  // Um texto por dia, girando: o mesmo recado todo dia é o que ensina a
  // ignorar recado (laudo 01, §9.5 — a penalidade de recência do Duolingo,
  // na versão que cabe no aparelho e não manda nada para servidor).
  final giro = _giroDoDia(dia ?? DateTime.now());
  final mapa = <TipoDeLembrete, TextoDeLembrete>{
    TipoDeLembrete.descanso: _escolheUm(
      modelosDoConvite(
        t,
        nomeDoPet: nomeDoPet,
        minutosDeDescanso: minutosDeDescanso,
      ),
      historico,
      dia ?? DateTime.now(),
      giro,
    ),
  };

  if (risco != null) {
    if (risco.vaiQuebrar) {
      mapa[TipoDeLembrete.raizEmRisco] = _escolheUm(
        modelosDaRaiz(t, nomeDoPet: nomeDoPet, risco: risco),
        historico,
        dia ?? DateTime.now(),
        giro,
      );
    } else {
      mapa[TipoDeLembrete.raizEmRisco] = TextoDeLembrete(
        titulo: t.raizCongelaTitulo,
        corpo: t.fill(t.raizCongelaCorpo, {'n': risco.dias}),
        modelo: 'raizCongela',
      );
    }
  }

  return mapa;
}

/// Um texto dentre os candidatos: pelo caderno de recados, se houver; senão
/// pelo giro do dia (teste, primeira abertura).
TextoDeLembrete _escolheUm(
  List<ModeloDeRecado> modelos,
  HistoricoDeRecados? historico,
  DateTime quando,
  int giro,
) {
  if (historico == null) return modelos[giro % modelos.length].texto;
  return historico.escolhe(modelos, [quando]).single.texto;
}

/// Os modelos do aviso da raiz que vai quebrar.
///
/// Na véspera de um marco o corpo diz qual é: são modelos à parte
/// (`raizMarco…`), elegíveis só nesses dias — o braço "dormente" do paper,
/// que não é penalizado nem premiado pelos dias em que não podia sair.
List<ModeloDeRecado> modelosDaRaiz(
  T t, {
  required String nomeDoPet,
  required RaizEmRisco risco,
}) {
  garanteTextosDoDescanso();
  final marco = risco.proximoMarco;
  final falta = risco.faltaParaOMarco;
  final noMarco = risco.vesperaDeMarco && marco != null && falta != null;
  final raiz = {'n': risco.dias, 'p': nomeDoPet};
  final variantes = [
    (t.raizRiscoTitulo, t.raizRiscoCorpo),
    (t.raizRisco2Titulo, t.raizRisco2Corpo),
    (t.raizRisco3Titulo, t.raizRisco3Corpo),
  ];
  return [
    for (var i = 0; i < variantes.length; i++)
      ModeloDeRecado(
        noMarco ? 'raizMarco${i + 1}' : 'raiz${i + 1}',
        TextoDeLembrete(
          titulo: t.fill(variantes[i].$1, raiz),
          corpo: noMarco
              ? t.fill(t.raizRiscoMarco, {'d': falta, 'm': marco})
              : t.fill(variantes[i].$2, raiz),
          modelo: noMarco ? 'raizMarco${i + 1}' : 'raiz${i + 1}',
        ),
      ),
  ];
}

/// Os modelos do convite do dia (o chamado do descanso).
List<ModeloDeRecado> modelosDoConvite(
  T t, {
  required String nomeDoPet,
  required int minutosDeDescanso,
}) {
  garanteTextosDoDescanso();
  final valores = {'n': nomeDoPet, 'm': minutosDeDescanso};
  final variantes = [
    (t.descansoLembreteTitulo, t.descansoLembreteCorpo),
    (t.descansoLembrete2Titulo, t.descansoLembrete2Corpo),
    (t.descansoLembrete3Titulo, t.descansoLembrete3Corpo),
    (t.descansoLembrete4Titulo, t.descansoLembrete4Corpo),
    (t.descansoLembrete5Titulo, t.descansoLembrete5Corpo),
  ];
  return [
    for (var i = 0; i < variantes.length; i++)
      ModeloDeRecado(
        'convite${i + 1}',
        TextoDeLembrete(
          titulo: t.fill(variantes[i].$1, valores),
          corpo: t.fill(variantes[i].$2, valores),
          modelo: 'convite${i + 1}',
        ),
      ),
  ];
}

/// O último recado da escada: avisa que os lembretes param (pesquisa 26).
///
/// O do Duolingo ("estes lembretes não parecem estar funcionando") trouxe
/// muita gente de volta porque soava como desistência — culpa. Este diz o
/// mesmo fato sem culpa: para, e deixa a porta aberta.
TextoDeLembrete despedidaDosLembretes(T t, {required String nomeDoPet}) {
  garanteTextosDoDescanso();
  return TextoDeLembrete(
    titulo: t.despedidaTitulo,
    corpo: t.fill(t.despedidaCorpo, {'n': nomeDoPet}),
    modelo: 'despedida',
  );
}

/// O índice do dia no ano, para girar os textos.
int _giroDoDia(DateTime d) =>
    d.difference(DateTime(d.year)).inDays + d.year * 7;

/// O aviso de amanhã para quem **não** sabe ainda como estará a raiz.
///
/// Sem número: amanhã a raiz pode ter crescido, segurado no congelamento ou
/// recomeçado, e afirmar "raiz de 12 dias" seria apostar (laudo 01, A6).
TextoDeLembrete textoDeAmanhaSemNumero(T t, {required String nomeDoPet}) {
  garanteTextosDoDescanso();
  return TextoDeLembrete(
    titulo: t.fill(t.raizAmanhaTitulo, {'p': nomeDoPet}),
    corpo: t.raizAmanhaCorpo,
    modelo: 'raizAmanha',
  );
}

/// Os nomes dos canais de recado, no idioma da pessoa.
Map<String, String> nomesDosCanais(T t) {
  garanteTextosDoDescanso();
  return {
    BaruNotifications.canalFim: t.canalNomeFim,
    BaruNotifications.canalRaiz: t.canalNomeRaiz,
    BaruNotifications.canalConvite: t.canalNomeConvite,
    BaruNotifications.canalRelatorio: t.canalNomeRelatorio,
    BaruNotifications.canalVolta: t.canalNomeVolta,
    BaruNotifications.canalConta: t.canalNomeConta,
  };
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
