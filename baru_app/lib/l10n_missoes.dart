/// Os textos da **tela** de missões: a hierarquia e os tipos novos.
///
/// Ficam num mapa próprio, e não em `lib/l10n.dart`, pelo mesmo motivo de
/// `l10n_descanso.dart` e `l10n_loja.dart`: o catálogo principal são quatro
/// mapas gigantes e é o ponto onde duas frentes simultâneas batem de frente.
/// `T.registra` existe para isso, e o catálogo principal ganha de qualquer
/// chave daqui — então nenhuma chave abaixo disputa nome com o que já existe.
///
/// **Este arquivo substitui o catálogo de módulo que morava no fim de
/// `missoes_screen.dart`.** Aquele declarava `msDescanso`/`comoDescanso`,
/// que ninguém lia: os textos do descanso são os de `l10n_descanso.dart`
/// (`descansoTitulo`, `descansoComo`), escritos pela frente dona do assunto.
/// Duas frases para a mesma missão é a receita para as duas divergirem.
library;

import 'l10n.dart';

const textosDeMissoes = <String, Map<String, String>>{
  'pt': {
    // --- a hierarquia da tela -------------------------------------------
    //
    // Os rótulos dizem **o que fazer com o grupo**, não o ritmo dele.
    // "HOJE" e "ESTA SEMANA" descreviam o prazo e deixavam a pessoa
    // escolher sozinha entre cinco cartões iguais; a queixa foi exatamente
    // essa. Um grupo por decisão: colher, fazer agora, deixar correr.
    'mqPrincipal': 'A PRINCIPAL DE HOJE',
    'mqColher': 'PRONTAS PARA COLHER',
    'mqAgora': 'PARA FAZER HOJE',
    'mqSemana': 'A SEMANA, SEM PRESSA',
    'mqEspera': 'ESPERANDO O ACESSO AO USO',
    'mqFeitas': 'JÁ COLHIDAS',
    'mqDescansoParar': 'Parar por agora',
    'mqQuantasColher': '{n} para colher',

    // --- os tipos novos --------------------------------------------------
    'msFocoGanha': 'Mais foco do que rolagem hoje',
    'comoFocoGanha': 'Some minutos de foco até passarem o tempo de hoje nos '
        'apps dispersivos.',
    'msDiaCompleto': 'Feche o dia inteiro: um foco e a meta',
    'comoDiaCompleto': 'Duas coisas, uma vez cada: uma sessão de foco e '
        'terminar o dia abaixo da meta.',
    'msSemanaDescanso': 'Colha o descanso em {n} dias desta semana',
    'comoSemanaDescanso': 'O dia entra quando você abre a toca do descanso '
        'daquele dia.',
    'msSemanaProfundo': 'Média de {n} min por sessão nesta semana',
    'comoSemanaProfundo': 'Vale a média, não o total: sessões mais longas '
        'puxam para cima.',
    'mqRetomada': 'VOLTA POR CIMA',
    'msCarinho': 'Faça carinho em {p} {n} vezes hoje',
    'comoCarinho': 'Toque nele na tela inicial. Esta não pede nada além de '
        'estar junto.',
    'msFaixas': 'Foque em {n} períodos diferentes do dia',
    'comoFaixas': 'Manhã, tarde e noite contam separado. Uma sessão só não '
        'fecha esta, por mais longa que seja.',
    'msProdutivo': 'Some {n} min em apps que constroem',
    'comoProdutivo': 'Leitura, estudo e trabalho. Aqui o telefone joga a '
        'seu favor, e o tempo conta.',
    'msFatia': 'Menos da metade da tela em rolagem',
    'comoFatia': 'Conta a proporção do dia, não o total. A barra só começa '
        'depois de meia hora de tela medida.',
    'msRetomada': 'Você voltou: faça um foco hoje',
    'comoRetomada': 'Um dia fora não cobra nada. Uma sessão e a raiz volta '
        'a andar de onde parou.',
  },
  'en': {
    'mqPrincipal': "TODAY'S MAIN ONE",
    'mqColher': 'READY TO COLLECT',
    'mqAgora': 'TO DO TODAY',
    'mqSemana': 'THE WEEK, NO RUSH',
    'mqEspera': 'WAITING FOR USAGE ACCESS',
    'mqFeitas': 'ALREADY COLLECTED',
    'mqDescansoParar': 'Stop for now',
    'mqQuantasColher': '{n} to collect',
    'msFocoGanha': 'More focus than scrolling today',
    'comoFocoGanha': "Stack up focus minutes until they pass today's time in "
        'distracting apps.',
    'msDiaCompleto': 'Close the whole day: one focus and the goal',
    'comoDiaCompleto': 'Two things, once each: one focus session and ending '
        'the day under your goal.',
    'msSemanaDescanso': 'Collect the rest on {n} days this week',
    'comoSemanaDescanso': "A day counts once you open that day's rest burrow.",
    'msSemanaProfundo': 'Average {n} min per session this week',
    'comoSemanaProfundo': 'The average counts, not the total: longer sessions '
        'pull it up.',
    'mqRetomada': 'BACK ON YOUR FEET',
    'msCarinho': 'Pet {p} {n} times today',
    'comoCarinho': 'Tap them on the home screen. This one asks for nothing '
        'but being around.',
    'msFaixas': 'Focus in {n} different parts of the day',
    'comoFaixas': 'Morning, afternoon and night count separately. One '
        'session will not close this, however long it runs.',
    'msProdutivo': 'Spend {n} min in apps that build something',
    'comoProdutivo': 'Reading, studying, working. Here the phone is on your '
        'side, and the time counts.',
    'msFatia': 'Less than half your screen on scrolling',
    'comoFatia': "It is the day's proportion, not the total. The bar starts "
        'after half an hour of measured screen time.',
    'msRetomada': 'You came back: focus once today',
    'comoRetomada': 'A day away costs nothing. One session and the roots '
        'start growing again.',
  },
  'es': {
    'mqPrincipal': 'LA PRINCIPAL DE HOY',
    'mqColher': 'LISTAS PARA RECOGER',
    'mqAgora': 'PARA HACER HOY',
    'mqSemana': 'LA SEMANA, SIN PRISA',
    'mqEspera': 'ESPERANDO EL ACCESO AL USO',
    'mqFeitas': 'YA RECOGIDAS',
    'mqDescansoParar': 'Parar por ahora',
    'mqQuantasColher': '{n} para recoger',
    'msFocoGanha': 'Más enfoque que scroll hoy',
    'comoFocoGanha': 'Suma minutos de enfoque hasta pasar el tiempo de hoy en '
        'apps dispersivas.',
    'msDiaCompleto': 'Cierra el día entero: un enfoque y la meta',
    'comoDiaCompleto': 'Dos cosas, una vez cada una: una sesión de enfoque y '
        'terminar el día bajo la meta.',
    'msSemanaDescanso': 'Recoge el descanso en {n} días de esta semana',
    'comoSemanaDescanso': 'El día entra cuando abres la madriguera del '
        'descanso de ese día.',
    'msSemanaProfundo': 'Promedio de {n} min por sesión esta semana',
    'comoSemanaProfundo': 'Cuenta el promedio, no el total: las sesiones más '
        'largas lo suben.',
    'mqRetomada': 'VUELTA POR ARRIBA',
    'msCarinho': 'Acaricia a {p} {n} veces hoy',
    'comoCarinho': 'Tócalo en la pantalla de inicio. Esta no pide nada más '
        'que estar cerca.',
    'msFaixas': 'Enfócate en {n} momentos distintos del día',
    'comoFaixas': 'Mañana, tarde y noche cuentan aparte. Una sola sesión no '
        'cierra esta, por larga que sea.',
    'msProdutivo': 'Suma {n} min en apps que construyen',
    'comoProdutivo': 'Lectura, estudio y trabajo. Aquí el teléfono juega a '
        'tu favor, y el tiempo cuenta.',
    'msFatia': 'Menos de la mitad de la pantalla en scroll',
    'comoFatia': 'Cuenta la proporción del día, no el total. La barra '
        'empieza tras media hora de pantalla medida.',
    'msRetomada': 'Volviste: haz un enfoque hoy',
    'comoRetomada': 'Un día fuera no cobra nada. Una sesión y la raíz vuelve '
        'a crecer.',
  },
  'zh': {
    'mqPrincipal': '今天的主线',
    'mqColher': '可以收下了',
    'mqAgora': '今天要做的',
    'mqSemana': '本周，慢慢来',
    'mqEspera': '等待使用权限',
    'mqFeitas': '已经收下',
    'mqDescansoParar': '先停下',
    'mqQuantasColher': '{n} 项可收',
    'msFocoGanha': '今天专注多过刷手机',
    'comoFocoGanha': '累积专注分钟数，直到超过今天在消遣类应用上的时间。',
    'msDiaCompleto': '把一天补完整：一次专注加上达标',
    'comoDiaCompleto': '两件事各做一次：完成一次专注，并让全天用量低于目标。',
    'msSemanaDescanso': '本周有 {n} 天收下休息的奖励',
    'comoSemanaDescanso': '要先打开那天的休息洞穴，这一天才算数。',
    'msSemanaProfundo': '本周每次专注平均 {n} 分钟',
    'comoSemanaProfundo': '算的是平均，不是总数：越长的专注越能把它拉高。',
    'mqRetomada': '重新站起来',
    'msCarinho': '今天摸一摸 {p} {n} 次',
    'comoCarinho': '在主页上轻触它。这一项只要求你在它身边。',
    'msFaixas': '在一天的 {n} 个不同时段专注',
    'comoFaixas': '早上、下午、晚上分开算。再长的一次专注也完成不了这一项。',
    'msProdutivo': '在有产出的应用里累积 {n} 分钟',
    'comoProdutivo': '阅读、学习、工作。这时手机站在你这边，时间算数。',
    'msFatia': '刷手机不到屏幕时间的一半',
    'comoFatia': '算的是一天的比例，不是总数。屏幕时间满半小时后进度条才开始走。',
    'msRetomada': '你回来了：今天专注一次',
    'comoRetomada': '离开一天不会被追究。一次专注，根就会接着长。',
  },
};

void garanteTextosDeMissoes() => T.registra(textosDeMissoes);

/// Os acessos, como getters.
///
/// `t.s('chave')` funcionaria, mas erro de digitação só apareceria na tela da
/// pessoa. Extensão dá o erro no compilador, que é onde ele custa barato.
extension TextosDeMissoes on T {
  String get mqPrincipal => s('mqPrincipal');
  String get mqColher => s('mqColher');
  String get mqAgora => s('mqAgora');
  String get mqSemana => s('mqSemana');
  String get mqEspera => s('mqEspera');
  String get mqFeitas => s('mqFeitas');
  String get mqDescansoParar => s('mqDescansoParar');
  String get mqQuantasColher => s('mqQuantasColher');
  String get msFocoGanha => s('msFocoGanha');
  String get comoFocoGanha => s('comoFocoGanha');
  String get msDiaCompleto => s('msDiaCompleto');
  String get comoDiaCompleto => s('comoDiaCompleto');
  String get msSemanaDescanso => s('msSemanaDescanso');
  String get comoSemanaDescanso => s('comoSemanaDescanso');
  String get msSemanaProfundo => s('msSemanaProfundo');
  String get comoSemanaProfundo => s('comoSemanaProfundo');
  String get mqRetomada => s('mqRetomada');
  String get msCarinho => s('msCarinho');
  String get comoCarinho => s('comoCarinho');
  String get msFaixas => s('msFaixas');
  String get comoFaixas => s('comoFaixas');
  String get msProdutivo => s('msProdutivo');
  String get comoProdutivo => s('comoProdutivo');
  String get msFatia => s('msFatia');
  String get comoFatia => s('comoFatia');
  String get msRetomada => s('msRetomada');
  String get comoRetomada => s('comoRetomada');
}
