/// Os textos das permissões e da sobreposição, nos quatro idiomas.
///
/// **Por que não estão em `lib/l10n.dart`.** Aquele arquivo tem quatro mapas
/// gigantes e é o ponto onde qualquer trabalho em paralelo colide: duas
/// frentes escrevendo texto batem de frente na mesma linha. O próprio
/// `l10n.dart` abriu a porta para isto com `T.registra`, e este módulo a usa.
///
/// O registro é **preguiçoso**: acontece em [garanteTextosDaSobreposicao],
/// chamado no início do `build` de quem mostra o texto e no ponto onde o mapa
/// pacote→fala é montado. Registrar no topo do arquivo faria um `import` ter
/// efeito colateral, e um teste que só quisesse a tabela de apps já pagaria
/// por isso.
///
/// A ordem manda: o catálogo principal ganha. Um módulo não sequestra chave
/// que já existe, então todas as chaves daqui nascem com o prefixo `sob`.
library;

import 'data/tempo_de_tela.dart';
import 'l10n.dart';
import 'services/overlay_service.dart';

/// Os textos deste módulo, no formato que [T.registra] espera.
const textosDaSobreposicao = <String, Map<String, String>>{
  'pt': {
    // --- a tela de permissões -------------------------------------------
    'sobPermT': 'Permissões',
    'sobPermSub':
        'O que {n} precisa para te acompanhar. Você decide uma por uma, e '
            'pode mudar de ideia depois.',
    'sobPermPasso': 'Permissão {i} de {total}',
    'sobPermPermitir': 'Permitir',
    'sobPermDeNovo': 'Pedir de novo',
    'sobPermPular': 'Agora não',
    'sobPermConcluir': 'Concluir',
    'sobPermLigada': 'Concedida',
    'sobPermFalta': 'Não concedida',
    'sobPermSemIsso': 'Sem ela:',
    'sobPermResumo': '{q} de {total} concedidas',
    'sobPermTudo': 'Tudo pronto. {n} já pode te acompanhar.',
    'sobPermRevisita':
        'Nada aqui é definitivo. Você revê tudo em Ajustes › Sobre outros '
            'apps.',

    // --- cada permissão --------------------------------------------------
    'sobPermUsoT': 'Acesso ao uso',
    'sobPermUsoQue':
        'Ler quanto tempo o aparelho passou em cada app. Só o total do dia '
            '— nunca o que você faz dentro deles.',
    'sobPermUsoSem':
        'O humor de {n} passa a vir só das suas sessões de foco, e o '
            'relatório do dia fica vazio.',
    'sobPermJanelaT': 'Aparecer sobre outros apps',
    'sobPermJanelaQue':
        'Deixar {n} dar um oi num cantinho da tela enquanto você está em '
            'outro app. Ele não trava nada, não fecha nada.',
    'sobPermJanelaSem':
        'É esta que costuma faltar. Sem ela {n} vê você sair e não '
            'consegue aparecer — o app parece quebrado, e não está.',
    'sobPermNotifT': 'Notificações',
    'sobPermNotifQue':
        'A sessão de foco na barra, o aviso de fim e o lembrete do dia.',
    'sobPermNotifSem':
        'A sessão corre sem contador na barra e você não é avisado quando '
            'ela termina.',
    'sobPermAlarmeT': 'Alarme exato',
    'sobPermAlarmeQue':
        'Avisar na hora marcada, e não alguns minutos depois, quando o '
            'aparelho está economizando bateria.',
    'sobPermAlarmeSem':
        'O aviso de fim da sessão pode atrasar. A sessão em si não se '
            'perde: o relógio reconcilia quando você volta.',

    // --- o catálogo de apps ----------------------------------------------
    'sobAppsT': 'Apps que puxam seu tempo',
    'sobAppsSub':
        '{n} conhece {q} apps e tem uma fala para cada um. Discorda de '
            'alguma categoria? Toque e mude.',
    'sobAppsVerTodos': 'Ver os {q}',
    'sobAppsVerMenos': 'Ver menos',

    // --- a fala, por família de app --------------------------------------
    'sobFalaVideoCurto':
        'Mais um vídeo e você volta, né? O {app} é assim mesmo. Bora '
            'respirar um pouco?',
    'sobFalaVideoLongo':
        'O {app} de novo? Ele sempre tem um próximo. A gente estava '
            'focando junto.',
    'sobFalaSocial':
        'O feed do {app} não acaba — mas o seu dia acaba. Volta comigo?',
    'sobFalaForum':
        'Mais um fio no {app}? Eles não param nunca. Bora voltar.',
    'sobFalaStreaming':
        'Mais um episódio no {app}? Ele te espera. Eu também, mas menos.',
    'sobFalaJogo':
        'Mais uma partida no {app}? A próxima sempre puxa outra. Bora?',
    'sobFalaCompras':
        'A vitrine do {app} não tem fim. Volta que a gente continua.',
    'sobFalaMensagem':
        'Responde e volta? A gente estava focando junto — o {app} espera.',
  },
  'en': {
    'sobPermT': 'Permissions',
    'sobPermSub':
        'What {n} needs to keep you company. You decide one at a time, and '
            'you can change your mind later.',
    'sobPermPasso': 'Permission {i} of {total}',
    'sobPermPermitir': 'Allow',
    'sobPermDeNovo': 'Ask again',
    'sobPermPular': 'Not now',
    'sobPermConcluir': 'Done',
    'sobPermLigada': 'Granted',
    'sobPermFalta': 'Not granted',
    'sobPermSemIsso': 'Without it:',
    'sobPermResumo': '{q} of {total} granted',
    'sobPermTudo': 'All set. {n} can keep you company now.',
    'sobPermRevisita':
        'Nothing here is final. You can review it all in Settings › Over '
            'other apps.',
    'sobPermUsoT': 'Usage access',
    'sobPermUsoQue':
        'Read how long the phone spent in each app. Only the daily total — '
            'never what you do inside them.',
    'sobPermUsoSem':
        "{n}'s mood then comes only from your focus sessions, and the daily "
            'report stays empty.',
    'sobPermJanelaT': 'Draw over other apps',
    'sobPermJanelaQue':
        'Let {n} say hi in a corner of the screen while you are in another '
            'app. Nothing gets blocked, nothing gets closed.',
    'sobPermJanelaSem':
        'This is the one usually missing. Without it {n} sees you leave and '
            'cannot show up — the app looks broken, and it is not.',
    'sobPermNotifT': 'Notifications',
    'sobPermNotifQue':
        'The focus session in the status bar, the finish alert and the '
            'daily reminder.',
    'sobPermNotifSem':
        'The session runs with no countdown in the bar, and nothing tells '
            'you when it ends.',
    'sobPermAlarmeT': 'Exact alarm',
    'sobPermAlarmeQue':
        'Ring at the exact minute instead of a few minutes later, when the '
            'phone is saving battery.',
    'sobPermAlarmeSem':
        'The end-of-session alert may be late. The session itself is not '
            'lost: the clock reconciles it when you come back.',
    'sobAppsT': 'Apps that eat your time',
    'sobAppsSub':
        '{n} knows {q} apps and has something to say about each one. '
            'Disagree with a category? Tap and change it.',
    'sobAppsVerTodos': 'See all {q}',
    'sobAppsVerMenos': 'See less',
    'sobFalaVideoCurto':
        'One more video and you are back, right? That is {app} for you. '
            'How about a breath?',
    'sobFalaVideoLongo':
        '{app} again? There is always a next one. We were focusing '
            'together.',
    'sobFalaSocial':
        'The {app} feed never ends — but your day does. Come back with me?',
    'sobFalaForum':
        'One more thread on {app}? They never stop. Let us go back.',
    'sobFalaStreaming':
        'One more episode on {app}? It will wait for you. So will I, but '
            'less patiently.',
    'sobFalaJogo':
        'One more match on {app}? The next one always pulls another. '
            'Shall we?',
    'sobFalaCompras':
        'The {app} shelf has no end. Come back and we keep going.',
    'sobFalaMensagem':
        'Reply and come back? We were focusing together — {app} can wait.',
  },
  'es': {
    'sobPermT': 'Permisos',
    'sobPermSub':
        'Lo que {n} necesita para acompañarte. Decides uno por uno, y '
            'puedes cambiar de idea después.',
    'sobPermPasso': 'Permiso {i} de {total}',
    'sobPermPermitir': 'Permitir',
    'sobPermDeNovo': 'Pedir de nuevo',
    'sobPermPular': 'Ahora no',
    'sobPermConcluir': 'Listo',
    'sobPermLigada': 'Concedido',
    'sobPermFalta': 'No concedido',
    'sobPermSemIsso': 'Sin él:',
    'sobPermResumo': '{q} de {total} concedidos',
    'sobPermTudo': 'Todo listo. {n} ya puede acompañarte.',
    'sobPermRevisita':
        'Nada de esto es definitivo. Puedes revisarlo en Ajustes › Sobre '
            'otras apps.',
    'sobPermUsoT': 'Acceso al uso',
    'sobPermUsoQue':
        'Leer cuánto tiempo estuvo el teléfono en cada app. Solo el total '
            'del día, nunca lo que haces dentro.',
    'sobPermUsoSem':
        'El ánimo de {n} vendrá solo de tus sesiones de foco, y el informe '
            'del día se queda vacío.',
    'sobPermJanelaT': 'Mostrarse sobre otras apps',
    'sobPermJanelaQue':
        'Dejar que {n} salude en una esquina de la pantalla mientras estás '
            'en otra app. No bloquea nada ni cierra nada.',
    'sobPermJanelaSem':
        'Es la que suele faltar. Sin ella {n} te ve salir y no puede '
            'aparecer — la app parece rota, y no lo está.',
    'sobPermNotifT': 'Notificaciones',
    'sobPermNotifQue':
        'La sesión de foco en la barra, el aviso de fin y el recordatorio '
            'del día.',
    'sobPermNotifSem':
        'La sesión corre sin cuenta atrás en la barra y nadie te avisa '
            'cuando termina.',
    'sobPermAlarmeT': 'Alarma exacta',
    'sobPermAlarmeQue':
        'Avisar en el minuto exacto y no unos minutos después, cuando el '
            'teléfono ahorra batería.',
    'sobPermAlarmeSem':
        'El aviso de fin puede retrasarse. La sesión no se pierde: el reloj '
            'la reconcilia cuando vuelves.',
    'sobAppsT': 'Apps que se comen tu tiempo',
    'sobAppsSub':
        '{n} conoce {q} apps y tiene algo que decir de cada una. ¿No estás '
            'de acuerdo con una categoría? Tócala y cámbiala.',
    'sobAppsVerTodos': 'Ver las {q}',
    'sobAppsVerMenos': 'Ver menos',
    'sobFalaVideoCurto':
        '¿Un video más y vuelves? {app} es así. ¿Respiramos un poco?',
    'sobFalaVideoLongo':
        '¿{app} otra vez? Siempre hay uno más. Estábamos concentrados '
            'juntos.',
    'sobFalaSocial':
        'El feed de {app} no se acaba, pero tu día sí. ¿Vuelves conmigo?',
    'sobFalaForum':
        '¿Otro hilo en {app}? No paran nunca. Vamos, volvemos.',
    'sobFalaStreaming':
        '¿Otro episodio en {app}? Él te espera. Yo también, pero menos.',
    'sobFalaJogo':
        '¿Otra partida en {app}? La siguiente siempre trae otra. ¿Vamos?',
    'sobFalaCompras':
        'El escaparate de {app} no tiene fin. Vuelve y seguimos.',
    'sobFalaMensagem':
        '¿Respondes y vuelves? Estábamos concentrados — {app} puede '
            'esperar.',
  },
  'zh': {
    'sobPermT': '权限',
    'sobPermSub': '{n} 需要这些才能陪着你。一个一个来，之后也随时可以改。',
    'sobPermPasso': '第 {i} 项，共 {total} 项',
    'sobPermPermitir': '允许',
    'sobPermDeNovo': '再请求一次',
    'sobPermPular': '暂时不用',
    'sobPermConcluir': '完成',
    'sobPermLigada': '已允许',
    'sobPermFalta': '未允许',
    'sobPermSemIsso': '不给的话：',
    'sobPermResumo': '已允许 {q} / {total}',
    'sobPermTudo': '都准备好了。{n} 可以陪你了。',
    'sobPermRevisita': '这里没有一项是定死的。你可以在「设置 › 显示在其他应用上层」里重新看。',
    'sobPermUsoT': '使用情况访问',
    'sobPermUsoQue': '读取手机在每个应用上停留了多久。只看每天的总时长，绝不看你在里面做了什么。',
    'sobPermUsoSem': '{n} 的心情只能靠你的专注时段来判断，当天的报告会是空的。',
    'sobPermJanelaT': '显示在其他应用上层',
    'sobPermJanelaQue': '让 {n} 在你用别的应用时，从屏幕角落跟你打个招呼。它不锁任何东西，也不关掉任何东西。',
    'sobPermJanelaSem': '缺的往往就是这一项。没有它，{n} 看着你离开却出不来 —— 应用看起来像坏了，其实没有。',
    'sobPermNotifT': '通知',
    'sobPermNotifQue': '状态栏里的专注时段、结束提醒和每天的提醒。',
    'sobPermNotifSem': '专注时段在状态栏里没有倒计时，结束时也没有人提醒你。',
    'sobPermAlarmeT': '精确闹钟',
    'sobPermAlarmeQue': '在约定的那一分钟提醒，而不是手机省电时晚几分钟才响。',
    'sobPermAlarmeSem': '结束提醒可能会迟到。时段本身不会丢：你回来时会按时钟对齐。',
    'sobAppsT': '吃掉你时间的应用',
    'sobAppsSub': '{n} 认识 {q} 个应用，对每一个都有话说。不同意某个分类？点一下就能改。',
    'sobAppsVerTodos': '查看全部 {q} 个',
    'sobAppsVerMenos': '收起',
    'sobFalaVideoCurto': '再看一条就回来，对吧？{app} 就是这样。要不要喘口气？',
    'sobFalaVideoLongo': '又是 {app}？它永远有下一个。我们本来在一起专注呢。',
    'sobFalaSocial': '{app} 的信息流没有尽头，可你的一天有。跟我回来好吗？',
    'sobFalaForum': '{app} 上再看一贴？它们永远刷不完。我们回去吧。',
    'sobFalaStreaming': '{app} 上再看一集？它会等你的。我也会，只是没那么有耐心。',
    'sobFalaJogo': '{app} 上再来一局？下一局总会牵出又一局。走吧？',
    'sobFalaCompras': '{app} 的货架没有尽头。回来我们继续。',
    'sobFalaMensagem': '回完就回来？我们本来在一起专注 —— {app} 等得起。',
  },
};

void garanteTextosDaSobreposicao() => T.registra(textosDaSobreposicao);

/// Os acessos, como getters.
///
/// `t.s('chave')` funcionaria, mas erro de digitação só apareceria na tela da
/// pessoa. Extensão dá o erro no compilador, que é onde ele custa barato.
extension TextosDaSobreposicao on T {
  String get sobPermT => s('sobPermT');
  String get sobPermSub => s('sobPermSub');
  String get sobPermPasso => s('sobPermPasso');
  String get sobPermPermitir => s('sobPermPermitir');
  String get sobPermDeNovo => s('sobPermDeNovo');
  String get sobPermPular => s('sobPermPular');
  String get sobPermConcluir => s('sobPermConcluir');
  String get sobPermLigada => s('sobPermLigada');
  String get sobPermFalta => s('sobPermFalta');
  String get sobPermSemIsso => s('sobPermSemIsso');
  String get sobPermResumo => s('sobPermResumo');
  String get sobPermTudo => s('sobPermTudo');
  String get sobPermRevisita => s('sobPermRevisita');

  String get sobPermUsoT => s('sobPermUsoT');
  String get sobPermUsoQue => s('sobPermUsoQue');
  String get sobPermUsoSem => s('sobPermUsoSem');
  String get sobPermJanelaT => s('sobPermJanelaT');
  String get sobPermJanelaQue => s('sobPermJanelaQue');
  String get sobPermJanelaSem => s('sobPermJanelaSem');
  String get sobPermNotifT => s('sobPermNotifT');
  String get sobPermNotifQue => s('sobPermNotifQue');
  String get sobPermNotifSem => s('sobPermNotifSem');
  String get sobPermAlarmeT => s('sobPermAlarmeT');
  String get sobPermAlarmeQue => s('sobPermAlarmeQue');
  String get sobPermAlarmeSem => s('sobPermAlarmeSem');

  String get sobAppsT => s('sobAppsT');
  String get sobAppsSub => s('sobAppsSub');
  String get sobAppsVerTodos => s('sobAppsVerTodos');
  String get sobAppsVerMenos => s('sobAppsVerMenos');

  /// O nome de uma permissão, como a pessoa a encontra na tela do sistema.
  String tituloDaPermissao(PermissaoDoBaru p) => s(switch (p) {
        PermissaoDoBaru.usoDoAparelho => 'sobPermUsoT',
        PermissaoDoBaru.sobreOutrosApps => 'sobPermJanelaT',
        PermissaoDoBaru.notificacoes => 'sobPermNotifT',
        PermissaoDoBaru.alarmeExato => 'sobPermAlarmeT',
      });

  /// O que a permissão faz. Molde: pode trazer `{n}`, o nome do bicho.
  String oQueFazAPermissao(PermissaoDoBaru p) => s(switch (p) {
        PermissaoDoBaru.usoDoAparelho => 'sobPermUsoQue',
        PermissaoDoBaru.sobreOutrosApps => 'sobPermJanelaQue',
        PermissaoDoBaru.notificacoes => 'sobPermNotifQue',
        PermissaoDoBaru.alarmeExato => 'sobPermAlarmeQue',
      });

  /// O que **deixa de funcionar** sem ela. É a metade que faltava: pedir sem
  /// dizer o custo da recusa é pedir no escuro, e negar no escuro é o que
  /// aconteceu com a sobreposição.
  String semAPermissao(PermissaoDoBaru p) => s(switch (p) {
        PermissaoDoBaru.usoDoAparelho => 'sobPermUsoSem',
        PermissaoDoBaru.sobreOutrosApps => 'sobPermJanelaSem',
        PermissaoDoBaru.notificacoes => 'sobPermNotifSem',
        PermissaoDoBaru.alarmeExato => 'sobPermAlarmeSem',
      });

  /// O molde da fala de uma família, ainda com `{app}` por preencher.
  String moldeDaFala(FamiliaDeApp f) => s(switch (f) {
        FamiliaDeApp.videoCurto => 'sobFalaVideoCurto',
        FamiliaDeApp.videoLongo => 'sobFalaVideoLongo',
        FamiliaDeApp.social => 'sobFalaSocial',
        FamiliaDeApp.forum => 'sobFalaForum',
        FamiliaDeApp.streaming => 'sobFalaStreaming',
        FamiliaDeApp.jogo => 'sobFalaJogo',
        FamiliaDeApp.compras => 'sobFalaCompras',
        FamiliaDeApp.mensagem => 'sobFalaMensagem',
      });

  /// A fala pronta para um pacote, ou `null` quando ele não tem família e,
  /// portanto, nada de específico a dizer.
  String? falaDoApp(String pacote) {
    // Este acesso não passa pelo `build` de tela nenhuma — quem o chama é o
    // caminho da sobreposição. Sem o registro aqui, a fala sairia como a
    // própria chave: `sobFalaVideoCurto` em cima do TikTok.
    garanteTextosDaSobreposicao();
    const padrao = ClassificacaoPadrao();
    final familia = padrao.familia(pacote);
    if (familia == null) return null;
    return fill(moldeDaFala(familia), {'app': padrao.nome(pacote)});
  }
}

/// O mapa pacote→fala que viaja para o vigia, **já traduzido**.
///
/// Montado no Dart de propósito: o lado nativo não escreve texto de produto.
/// Ele recebe o dicionário pronto, olha quem está na frente e escolhe a
/// linha — nenhuma frase nasce em Kotlin.
///
/// Só entram os pacotes com família. Todo o resto cai na fala padrão que já
/// acompanha a chamada, e um app que ninguém classificou continua recebendo
/// um oi genérico em vez de silêncio.
Map<String, String> falasPorPacote(T t) {
  // Este é o caminho que **não** passa pelo `build` de tela nenhuma: se o
  // registro não acontecesse aqui, a fala de cada app sairia como a própria
  // chave — `sobFalaVideoCurto` em cima do TikTok.
  garanteTextosDaSobreposicao();
  final out = <String, String>{};
  for (final pacote in ClassificacaoPadrao.comFala) {
    final fala = t.falaDoApp(pacote);
    if (fala != null) out[pacote] = fala;
  }
  return out;
}
