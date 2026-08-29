/// A fala do humor: **por que** o companheiro está assim, com o número real.
///
/// Existe porque `moodCap`/`moodSub` diziam o sentimento e escondiam o fato.
/// "{n} sentiu sua falta." não informa se a pessoa sumiu três dias ou se
/// desistiu de uma sessão hoje — duas causas muito diferentes que caíam na
/// mesma frase. Um companheiro que reage sem dizer a quê vira decoração, e a
/// pessoa não aprende nada com a reação.
///
/// Duas coisas moram aqui, e de propósito:
///
/// 1. **A regra** que escolhe qual fala cabe nos fatos de hoje ([escolheAFala]).
///    É pura: recebe [FatosDoHumor], devolve [FalaDoHumor]. Testável sem
///    `AppState`, sem `pumpWidget` e sem relógio.
/// 2. **Os textos**, nos quatro idiomas, num catálogo de módulo registrado com
///    `T.registra`. `lib/l10n.dart` tem quatro mapas gigantes e é o ponto de
///    colisão de qualquer trabalho em paralelo; o próprio arquivo recomenda
///    esta saída. Todas as chaves nascem prefixadas com `humor` e nenhuma
///    disputa nome com o catálogo principal, que sempre ganha.
///
/// O `enum Mood` **não** cresceu. A cena (`lib/widgets/pet.dart`) faz
/// `switch` exaustivo sobre ele em dois pontos, e um valor novo quebraria o
/// desenho do bicho. O enriquecimento é uma camada de fala sobre os mesmos
/// cinco humores: a cena continua com cinco estados, as palavras passam a ter
/// vinte e dois. Isso também respeita a precedência do §3 do contrato, que
/// segue sendo a única dona de qual humor é qual.
///
/// **Regra dura: nunca inventar número.** Cada fala só cita o que o app
/// mediu. Sem a permissão de uso não há tempo de tela — e aí a fala diz
/// justamente isso, em vez de estimar.
library;

import 'l10n.dart';
import 'models.dart';

/// A chave de texto de um humor. Igual à do catálogo principal — é ela que
/// `moodCap`/`moodSub` indexam, e a fala usa a mesma para poder cair de volta
/// no texto antigo se algum id novo ficar sem tradução.
String chaveDoHumor(Mood m) => switch (m) {
      Mood.radiant => 'radiant',
      Mood.content => 'content',
      Mood.neutral => 'neutral',
      Mood.sleepy => 'sleepy',
      Mood.missingYou => 'missing_you',
    };

/// Os fatos medidos que explicam o humor de hoje.
///
/// Tudo aqui é medição ou contagem que o app já mantém. Nada é estimado: os
/// campos que dependem de permissão são anuláveis ou vêm acompanhados de
/// [temMedicaoDeTela], e a regra que não tem o dado escolhe outra fala em vez
/// de chutar um número.
class FatosDoHumor {
  const FatosDoHumor({
    required this.humor,
    required this.nomeDoPet,
    required this.temMedicaoDeTela,
    required this.minutosDeTela,
    required this.meta,
    required this.sessoesHoje,
    required this.minutosDeFocoHoje,
    required this.desistiuHoje,
    required this.minutosDaDesistencia,
    required this.diasFora,
    required this.raiz,
    required this.maiorRaiz,
    required this.folhas,
    required this.minutosDispersivos,
  });

  /// O humor já decidido pelo contrato §3. A fala não redecide humor: ela
  /// explica o que foi decidido. Se as duas coisas divergissem, a cena e a
  /// legenda diriam coisas diferentes na mesma tela.
  final Mood humor;

  final String nomeDoPet;

  /// Há permissão de uso — o mesmo portão que o `mood` usa para olhar o
  /// tempo de tela. Deliberadamente **não** exige `resumoTela != null`:
  /// `usage` e `usageAccess` são persistidos juntos, e exigir o resumo faria
  /// a legenda dizer "não medi" enquanto o humor já tinha sido derivado do
  /// número medido. Duas versões do mesmo dia na mesma tela.
  final bool temMedicaoDeTela;

  final int minutosDeTela;
  final int meta;
  final int sessoesHoje;
  final int minutosDeFocoHoje;
  final bool desistiuHoje;

  /// A duração da sessão que parou no meio hoje. `null` quando não há
  /// registro dela — e aí a fala omite o número em vez de inventar um.
  final int? minutosDaDesistencia;

  final int diasFora;
  final int raiz;
  final int maiorRaiz;
  final int folhas;

  /// Minutos em apps dispersivos hoje. `null` sem detalhamento — o resumo por
  /// categoria só existe depois de uma leitura de verdade do sistema.
  final int? minutosDispersivos;
}

/// A fala escolhida: o id do texto e os valores que entram nele.
class FalaDoHumor {
  const FalaDoHumor({
    required this.id,
    required this.humor,
    required this.valores,
  });

  final String id;
  final Mood humor;

  /// Os buracos do texto já formatados. Nomes longos (`{tela}`, `{dias}`) de
  /// propósito: `comPronome` injeta `{p}`, `{P}` e `{d}` **por cima** das
  /// variáveis, então um `{d}` de "dias fora" viraria "dele" na tela.
  final Map<String, Object> valores;

  String get chave => chaveDoHumor(humor);
}

/// Escolhe a fala a partir dos fatos. Primeira regra que casa vence.
///
/// A ordem dentro de cada humor vai do fato mais específico ao mais geral, e
/// cada humor termina numa fala **sem número**. Essa última é o degrau
/// obrigatório da escada: a função tem de devolver alguma coisa, e um dia
/// cujos fatos não caem em nenhuma regra específica não pode virar uma frase
/// que cita medida. Nenhum dia real chega nela hoje — `test/humor_test.dart`
/// varre o espaço de fatos e exige que continue assim —, mas apagá-la
/// trocaria uma fala vaga e verdadeira por um número inventado no dia em que
/// um fato novo aparecer.
FalaDoHumor escolheAFala(FatosDoHumor f, T t) => switch (f.humor) {
      Mood.missingYou => _saudade(f, t),
      Mood.radiant => _radiante(f, t),
      Mood.content => _contente(f, t),
      Mood.neutral => _neutro(f, t),
      Mood.sleepy => _sonolento(f, t),
    };

FalaDoHumor _saudade(FatosDoHumor f, T t) {
  // A ausência ganha da desistência quando as duas valem. Faltar três dias é
  // o fato maior — ele descreve o dia inteiro; a desistência é um momento
  // dentro dele. Dizer o menor primeiro esconderia o maior.
  if (f.diasFora >= 2) {
    // A raiz só entra na frase quando sobreviveu. Depois de uma ausência sem
    // congelamento ela zera, e afirmar que "segurou" seria falso.
    if (f.raiz > 0) {
      return _fala('ausenciaComRaiz', f, {'dias': f.diasFora, 'raiz': f.raiz});
    }
    return _fala('ausencia', f, {'dias': f.diasFora, 'folhas': f.folhas});
  }
  if (f.desistiuHoje) {
    final min = f.minutosDaDesistencia;
    if (min == null) return _fala('desistenciaSemMinutos', f, const {});
    return _fala('desistencia', f, {'min': _min(min, t)});
  }
  return _fala('saudade', f, const {});
}

FalaDoHumor _radiante(FatosDoHumor f, T t) {
  // Sem sessão nenhuma não há `{c}` honesto para escrever, e a regra do §3
  // não produz radiante sem sessão. Sai antes de qualquer fala que conte
  // sessões — `humorSessoes(0)` diria "uma sessão".
  if (f.sessoesHoje < 1) return _fala('radiante', f, const {});
  final c = t.humorSessoes(f.sessoesHoje);

  // Orgulho por recorde: a raiz de hoje empatou com a maior de todas. Vale
  // com ou sem permissão de uso — a sequência é contada pelo próprio app.
  if (f.raiz >= 2 && f.raiz == f.maiorRaiz) {
    return _fala('radianteRecorde', f, {'raiz': f.raiz, 'c': c});
  }
  // Alívio da volta: faltou exatamente um dia. Dois ou mais já teriam virado
  // `missing_you` pelo contrato, então este caso é sempre o reencontro curto.
  if (f.diasFora == 1) return _fala('radianteVolta', f, {'c': c});
  if (!f.temMedicaoDeTela) {
    return _fala('radianteSemMedicao', f, {
      'c': c,
      'min': _min(f.minutosDeFocoHoje, t),
    });
  }
  if (f.minutosDeTela < f.meta) {
    return _fala('radianteAbaixo', f, {
      'tela': _min(f.minutosDeTela, t),
      'delta': _min(f.meta - f.minutosDeTela, t),
      'c': c,
    });
  }
  return _fala('radiante', f, const {});
}

FalaDoHumor _contente(FatosDoHumor f, T t) {
  if (f.diasFora == 1) return _fala('contenteVolta', f, {'folhas': f.folhas});
  // Sem permissão, `content` significa exatamente "nenhuma sessão hoje" — é
  // a outra metade da regra do §3. A fala diz as duas coisas: o que faltou e
  // o que o app não tem como saber.
  if (!f.temMedicaoDeTela) return _fala('contenteSemMedicao', f, const {});

  final tela = _min(f.minutosDeTela, t);
  if (f.sessoesHoje >= 1 && f.minutosDeTela >= f.meta) {
    final c = t.humorSessoes(f.sessoesHoje);
    // Em cima da meta o delta é zero, e "0min acima da meta" é ruído.
    if (f.minutosDeTela == f.meta) {
      return _fala('contenteNaMeta', f, {'tela': tela, 'c': c});
    }
    return _fala('contenteAcima', f, {
      'tela': tela,
      'delta': _min(f.minutosDeTela - f.meta, t),
      'c': c,
    });
  }
  if (f.sessoesHoje < 1 && f.minutosDeTela < f.meta) {
    return _fala('contenteAbaixo', f, {
      'tela': tela,
      'delta': _min(f.meta - f.minutosDeTela, t),
    });
  }
  return _fala('contente', f, const {});
}

FalaDoHumor _neutro(FatosDoHumor f, T t) {
  // `neutral` sem permissão é inalcançável pela regra do §3 (sem medição o
  // humor só vai a `radiant` ou `content`). A guarda fica como degrau: sem
  // ela, um `neutral` sem leitura citaria minutos que não existem.
  if (!f.temMedicaoDeTela) return _fala('neutro', f, const {});
  final tela = _min(f.minutosDeTela, t);
  if (f.minutosDeTela == f.meta) return _fala('neutroNaMeta', f, {'tela': tela});
  if (f.minutosDeTela > f.meta) {
    return _fala('neutroAcima', f, {
      'tela': tela,
      'delta': _min(f.minutosDeTela - f.meta, t),
    });
  }
  return _fala('neutro', f, const {});
}

FalaDoHumor _sonolento(FatosDoHumor f, T t) {
  if (!f.temMedicaoDeTela || f.minutosDeTela <= f.meta) {
    return _fala('sone', f, const {});
  }
  final valores = {
    'tela': _min(f.minutosDeTela, t),
    'delta': _min(f.minutosDeTela - f.meta, t),
  };
  // O detalhamento por categoria é o único jeito de o dia longo virar
  // informação em vez de veredito. Só entra quando existe leitura de verdade.
  final disp = f.minutosDispersivos;
  if (disp != null && disp > 0) {
    return _fala('soneDispersivo', f, {...valores, 'disp': _min(disp, t)});
  }
  return _fala('soneAcima', f, valores);
}

FalaDoHumor _fala(String id, FatosDoHumor f, Map<String, Object> valores) =>
    FalaDoHumor(
      id: id,
      humor: f.humor,
      // `{n}` entra sempre: as falas de reserva usam o nome do bicho, e um
      // buraco não preenchido apareceria cru na tela.
      valores: {'n': f.nomeDoPet, ...valores},
    );

String _min(int minutos, T t) => fmtMinutes(minutos, t.lang);

extension TextosDoHumor on T {
  /// "Uma sessão de foco" / "3 sessões de foco".
  ///
  /// Sempre com inicial maiúscula nos idiomas que a usam: `{c}` só aparece em
  /// começo de frase nos textos, e minúsculo ali ficaria errado. Zero não tem
  /// forma própria porque nenhuma fala com `{c}` é alcançável sem sessão.
  String humorSessoes(int n) => n <= 1
      ? s('humorSessoesUma')
      : fill(s('humorSessoesMuitas'), {'q': n});

  /// O título grande da home.
  String humorCap(FalaDoHumor f) =>
      _humorTexto('humorCap_${f.id}', moodCap(f.chave));

  /// A linha de baixo.
  String humorSub(FalaDoHumor f) =>
      _humorTexto('humorSub_${f.id}', moodSub(f.chave));

  /// Texto faltando cai no do humor base em vez de virar chave crua na tela.
  ///
  /// `T.s` devolve a própria chave quando não acha, então sem esta guarda a
  /// home mostraria `humorCap_ausencia` para o usuário. A reserva é rede de
  /// produção, não licença: `test/humor_test.dart` exige que cada id resolva
  /// nos quatro idiomas **e** seja diferente da reserva, senão a falta
  /// passaria calada — que é exatamente o defeito do `moodCap`, que degrada
  /// para vazio.
  String _humorTexto(String chave, String reserva) {
    final achado = s(chave);
    return achado == chave ? reserva : achado;
  }
}

/// Registra o catálogo. Idempotente — `T.registra` ignora o mapa repetido.
void garanteTextosDoHumor() => T.registra(textosDoHumor);

/// Os textos, nos quatro idiomas do §2.
///
/// Regras de escrita, na ordem: o fato primeiro, o sentimento depois se
/// couber; nunca culpar (a sessão "parou no meio", ninguém "desistiu"); e
/// "até agora" só nas falas de abaixo da meta — estar abaixo às nove da manhã
/// é verdade que ainda pode virar, estar acima já não desfaz.
const textosDoHumor = <String, Map<String, String>>{
  'pt': {
    'humorSessoesUma': 'Uma sessão de foco',
    'humorSessoesMuitas': '{q} sessões de foco',

    'humorCap_ausenciaComRaiz': '{dias} dias sem você por aqui.',
    'humorSub_ausenciaComRaiz':
        'Sua raiz de {raiz} dias segurou. {P} ficou no habitat, e nada saiu '
            'do lugar.',
    'humorCap_ausencia': '{dias} dias sem você por aqui.',
    'humorSub_ausencia':
        '{P} ficou no habitat esperando. Suas {folhas} folhas e tudo que '
            'você montou continuam aí.',
    'humorCap_desistencia': 'Uma sessão de {min} parou no meio hoje.',
    'humorSub_desistencia':
        'Sem folhas por essa, e nada além disso. {P} espera a próxima.',
    'humorCap_desistenciaSemMinutos':
        'Uma sessão de foco parou no meio hoje.',
    'humorSub_desistenciaSemMinutos':
        'Sem folhas por essa, e nada além disso. {P} espera a próxima.',
    'humorCap_saudade': '{n} sentiu sua falta.',
    'humorSub_saudade':
        '{P} te esperou. Nada foi perdido enquanto você esteve fora.',

    'humorCap_radianteRecorde': '{raiz} dias seguidos, a sua maior raiz.',
    'humorSub_radianteRecorde':
        '{c} hoje. Nenhuma raiz sua chegou tão longe.',
    'humorCap_radianteVolta': 'Você voltou depois de um dia fora.',
    'humorSub_radianteVolta': '{c} logo na volta. {P} se animou na hora.',
    'humorCap_radianteSemMedicao': '{c} hoje, {min} no total.',
    'humorSub_radianteSemMedicao':
        'Sem o acesso ao uso eu não meço a sua tela: hoje eu leio o dia só '
            'pelo foco.',
    'humorCap_radianteAbaixo':
        '{tela} de tela até agora, {delta} abaixo da meta.',
    'humorSub_radianteAbaixo': '{c} hoje. É o melhor tipo de dia.',
    'humorCap_radiante': '{n} está radiante.',
    'humorSub_radiante': 'O dia está indo do jeito que vocês dois queriam.',

    'humorCap_contenteVolta': 'Você voltou depois de um dia fora.',
    'humorSub_contenteVolta':
        '{P} guardou o seu lugar. Suas {folhas} folhas continuam aí.',
    'humorCap_contenteSemMedicao': 'Ainda não houve sessão de foco hoje.',
    'humorSub_contenteSemMedicao':
        'E sem o acesso ao uso eu não meço a sua tela, então hoje eu leio o '
            'dia só pelo foco.',
    'humorCap_contenteAcima': '{tela} de tela, {delta} acima da meta.',
    'humorSub_contenteAcima':
        '{c} entrou no dia mesmo assim. Isso conta.',
    'humorCap_contenteNaMeta': '{tela} de tela, exatamente a meta de hoje.',
    'humorSub_contenteNaMeta': '{c} entrou no dia. Isso conta.',
    'humorCap_contenteAbaixo':
        '{tela} de tela até agora, {delta} abaixo da meta.',
    'humorSub_contenteAbaixo':
        'Nenhuma sessão de foco ainda. Uma e o dia fica completo.',
    'humorCap_contente': '{n} está contente.',
    'humorSub_contente': 'Um dia dentro do comum.',

    'humorCap_neutroNaMeta': '{tela} de tela, exatamente a meta de hoje.',
    'humorSub_neutroNaMeta': 'Nem acima, nem abaixo. Nada para corrigir.',
    'humorCap_neutroAcima': '{tela} de tela, {delta} acima da meta.',
    'humorSub_neutroAcima':
        'Sem sessão de foco hoje. {P} tirou um cochilo esperando.',
    'humorCap_neutro': '{n} está cochilando.',
    'humorSub_neutro': 'Nada fora do lugar por aqui.',

    'humorCap_soneDispersivo': '{tela} de tela, {delta} acima da meta.',
    'humorSub_soneDispersivo':
        '{disp} disso em apps que dispersam. Amanhã começa em zero.',
    'humorCap_soneAcima': '{tela} de tela, {delta} acima da meta.',
    'humorSub_soneAcima':
        'Sem sessão de foco hoje. Amanhã começa em zero.',
    'humorCap_sone': '{n} está com sono.',
    'humorSub_sone': 'Foi um dia longo de tela.',
  },
  'en': {
    'humorSessoesUma': 'One focus session',
    'humorSessoesMuitas': '{q} focus sessions',

    'humorCap_ausenciaComRaiz': '{dias} days without you here.',
    'humorSub_ausenciaComRaiz':
        'Your {raiz}-day roots held. {P} stayed in the habitat, and nothing '
            'moved.',
    'humorCap_ausencia': '{dias} days without you here.',
    'humorSub_ausencia':
        '{P} stayed in the habitat, waiting. Your {folhas} leaves and '
            'everything you built are still there.',
    'humorCap_desistencia': 'A {min} session stopped halfway today.',
    'humorSub_desistencia':
        'No leaves for that one, and nothing beyond it. {P} will wait for '
            'the next.',
    'humorCap_desistenciaSemMinutos':
        'A focus session stopped halfway today.',
    'humorSub_desistenciaSemMinutos':
        'No leaves for that one, and nothing beyond it. {P} will wait for '
            'the next.',
    'humorCap_saudade': '{n} missed you.',
    'humorSub_saudade':
        '{P} waited for you. Nothing was lost while you were gone.',

    'humorCap_radianteRecorde': '{raiz} days in a row, your longest roots.',
    'humorSub_radianteRecorde':
        '{c} today. No roots of yours ever ran this long.',
    'humorCap_radianteVolta': 'You came back after a day away.',
    'humorSub_radianteVolta':
        '{c} right on the day you came back. {P} perked up at once.',
    'humorCap_radianteSemMedicao': '{c} today, {min} in all.',
    'humorSub_radianteSemMedicao':
        'Without usage access I cannot measure your screen: today I read the '
            'day from focus alone.',
    'humorCap_radianteAbaixo':
        '{tela} of screen so far, {delta} under your goal.',
    'humorSub_radianteAbaixo': '{c} today. Best kind of day.',
    'humorCap_radiante': '{n} is radiant.',
    'humorSub_radiante': 'The day is going the way you both wanted.',

    'humorCap_contenteVolta': 'You came back after a day away.',
    'humorSub_contenteVolta':
        '{P} kept your spot. Your {folhas} leaves are still there.',
    'humorCap_contenteSemMedicao': 'No focus session yet today.',
    'humorSub_contenteSemMedicao':
        'And without usage access I cannot measure your screen, so today I '
            'read the day from focus alone.',
    'humorCap_contenteAcima': '{tela} of screen, {delta} over your goal.',
    'humorSub_contenteAcima': '{c} went in anyway. That counts.',
    'humorCap_contenteNaMeta': '{tela} of screen, exactly today\'s goal.',
    'humorSub_contenteNaMeta': '{c} went in. That counts.',
    'humorCap_contenteAbaixo':
        '{tela} of screen so far, {delta} under your goal.',
    'humorSub_contenteAbaixo':
        'No focus session yet. One, and the day is complete.',
    'humorCap_contente': '{n} is content.',
    'humorSub_contente': 'An ordinary day.',

    'humorCap_neutroNaMeta': '{tela} of screen, exactly today\'s goal.',
    'humorSub_neutroNaMeta': 'Not over, not under. Nothing to fix.',
    'humorCap_neutroAcima': '{tela} of screen, {delta} over your goal.',
    'humorSub_neutroAcima':
        'No focus session today. {P} took a nap while waiting.',
    'humorCap_neutro': '{n} is dozing.',
    'humorSub_neutro': 'Nothing out of place here.',

    'humorCap_soneDispersivo': '{tela} of screen, {delta} over your goal.',
    'humorSub_soneDispersivo':
        '{disp} of that in apps that scatter you. Tomorrow starts at zero.',
    'humorCap_soneAcima': '{tela} of screen, {delta} over your goal.',
    'humorSub_soneAcima':
        'No focus session today. Tomorrow starts at zero.',
    'humorCap_sone': '{n} is sleepy.',
    'humorSub_sone': 'It was a long screen day.',
  },
  'es': {
    'humorSessoesUma': 'Una sesión de foco',
    'humorSessoesMuitas': '{q} sesiones de foco',

    'humorCap_ausenciaComRaiz': '{dias} días sin ti por aquí.',
    'humorSub_ausenciaComRaiz':
        'Tu raíz de {raiz} días aguantó. {P} se quedó en el hábitat, y nada '
            'se movió.',
    'humorCap_ausencia': '{dias} días sin ti por aquí.',
    'humorSub_ausencia':
        '{P} se quedó en el hábitat esperando. Tus {folhas} hojas y todo lo '
            'que armaste siguen ahí.',
    'humorCap_desistencia': 'Una sesión de {min} se cortó a la mitad hoy.',
    'humorSub_desistencia':
        'Sin hojas por esa, y nada más. {P} espera la próxima.',
    'humorCap_desistenciaSemMinutos':
        'Una sesión de foco se cortó a la mitad hoy.',
    'humorSub_desistenciaSemMinutos':
        'Sin hojas por esa, y nada más. {P} espera la próxima.',
    'humorCap_saudade': '{n} te echó de menos.',
    'humorSub_saudade':
        '{P} te esperó. Nada se perdió mientras estuviste fuera.',

    'humorCap_radianteRecorde': '{raiz} días seguidos, tu raíz más larga.',
    'humorSub_radianteRecorde':
        '{c} hoy. Ninguna raíz tuya llegó tan lejos.',
    'humorCap_radianteVolta': 'Volviste después de un día fuera.',
    'humorSub_radianteVolta':
        '{c} el mismo día de la vuelta. {P} se animó al instante.',
    'humorCap_radianteSemMedicao': '{c} hoy, {min} en total.',
    'humorSub_radianteSemMedicao':
        'Sin el acceso al uso no puedo medir tu pantalla: hoy leo el día '
            'solo por el foco.',
    'humorCap_radianteAbaixo':
        '{tela} de pantalla hasta ahora, {delta} por debajo de la meta.',
    'humorSub_radianteAbaixo': '{c} hoy. El mejor tipo de día.',
    'humorCap_radiante': '{n} está radiante.',
    'humorSub_radiante': 'El día va como los dos querían.',

    'humorCap_contenteVolta': 'Volviste después de un día fuera.',
    'humorSub_contenteVolta':
        '{P} te guardó el lugar. Tus {folhas} hojas siguen ahí.',
    'humorCap_contenteSemMedicao': 'Todavía no hubo sesión de foco hoy.',
    'humorSub_contenteSemMedicao':
        'Y sin el acceso al uso no puedo medir tu pantalla, así que hoy leo '
            'el día solo por el foco.',
    'humorCap_contenteAcima':
        '{tela} de pantalla, {delta} por encima de la meta.',
    'humorSub_contenteAcima': '{c} entró igual. Eso cuenta.',
    'humorCap_contenteNaMeta':
        '{tela} de pantalla, justo la meta de hoy.',
    'humorSub_contenteNaMeta': '{c} entró en el día. Eso cuenta.',
    'humorCap_contenteAbaixo':
        '{tela} de pantalla hasta ahora, {delta} por debajo de la meta.',
    'humorSub_contenteAbaixo':
        'Todavía ninguna sesión de foco. Una y el día queda completo.',
    'humorCap_contente': '{n} está contento.',
    'humorSub_contente': 'Un día dentro de lo común.',

    'humorCap_neutroNaMeta': '{tela} de pantalla, justo la meta de hoy.',
    'humorSub_neutroNaMeta':
        'Ni por encima ni por debajo. Nada que corregir.',
    'humorCap_neutroAcima':
        '{tela} de pantalla, {delta} por encima de la meta.',
    'humorSub_neutroAcima':
        'Sin sesión de foco hoy. {P} se echó una siesta esperando.',
    'humorCap_neutro': '{n} está dormitando.',
    'humorSub_neutro': 'Nada fuera de lugar por aquí.',

    'humorCap_soneDispersivo':
        '{tela} de pantalla, {delta} por encima de la meta.',
    'humorSub_soneDispersivo':
        '{disp} de eso en apps que dispersan. Mañana empieza en cero.',
    'humorCap_soneAcima':
        '{tela} de pantalla, {delta} por encima de la meta.',
    'humorSub_soneAcima':
        'Sin sesión de foco hoy. Mañana empieza en cero.',
    'humorCap_sone': '{n} tiene sueño.',
    'humorSub_sone': 'Fue un día largo de pantalla.',
  },
  'zh': {
    'humorSessoesUma': '一次专注',
    'humorSessoesMuitas': '{q} 次专注',

    'humorCap_ausenciaComRaiz': '{dias} 天没见到你了。',
    'humorSub_ausenciaComRaiz':
        '你 {raiz} 天的根撑住了。{P}一直待在栖息地，什么都没动过。',
    'humorCap_ausencia': '{dias} 天没见到你了。',
    'humorSub_ausencia':
        '{P}一直在栖息地等你。你的 {folhas} 片叶子和你搭起来的一切都还在。',
    'humorCap_desistencia': '今天有一次 {min} 的专注停在了半路。',
    'humorSub_desistencia': '这一次没有叶子，也仅此而已。{P}会等下一次。',
    'humorCap_desistenciaSemMinutos': '今天有一次专注停在了半路。',
    'humorSub_desistenciaSemMinutos': '这一次没有叶子，也仅此而已。{P}会等下一次。',
    'humorCap_saudade': '{n} 有点想你。',
    'humorSub_saudade': '{P}一直在等你。你离开的时候，什么都没有丢。',

    'humorCap_radianteRecorde': '连续 {raiz} 天，你最长的根。',
    'humorSub_radianteRecorde': '今天{c}。你的根从来没有这么长过。',
    'humorCap_radianteVolta': '离开一天之后，你回来了。',
    'humorSub_radianteVolta': '回来的当天就{c}。{P}一下子精神起来了。',
    'humorCap_radianteSemMedicao': '今天{c}，一共 {min}。',
    'humorSub_radianteSemMedicao':
        '没有使用权限，我量不到你的屏幕时间：今天只按专注来读这一天。',
    'humorCap_radianteAbaixo': '目前 {tela} 屏幕时间，比目标少 {delta}。',
    'humorSub_radianteAbaixo': '今天还{c}。这是最好的一天。',
    'humorCap_radiante': '{n} 神采飞扬。',
    'humorSub_radiante': '这一天正照着你们两个想要的样子在走。',

    'humorCap_contenteVolta': '离开一天之后，你回来了。',
    'humorSub_contenteVolta': '{P}给你留着位置。你的 {folhas} 片叶子都还在。',
    'humorCap_contenteSemMedicao': '今天还没有专注。',
    'humorSub_contenteSemMedicao':
        '而且没有使用权限，我量不到你的屏幕时间，所以今天只按专注来读这一天。',
    'humorCap_contenteAcima': '{tela} 屏幕时间，比目标多 {delta}。',
    'humorSub_contenteAcima': '不过今天还是{c}。这也算数。',
    'humorCap_contenteNaMeta': '{tela} 屏幕时间，刚好是今天的目标。',
    'humorSub_contenteNaMeta': '今天{c}。这也算数。',
    'humorCap_contenteAbaixo': '目前 {tela} 屏幕时间，比目标少 {delta}。',
    'humorSub_contenteAbaixo': '今天还没有专注。来一次，这一天就完整了。',
    'humorCap_contente': '{n} 很满足。',
    'humorSub_contente': '平常的一天。',

    'humorCap_neutroNaMeta': '{tela} 屏幕时间，刚好是今天的目标。',
    'humorSub_neutroNaMeta': '不多也不少。没什么要改的。',
    'humorCap_neutroAcima': '{tela} 屏幕时间，比目标多 {delta}。',
    'humorSub_neutroAcima': '今天没有专注。{P}打了个盹等着你。',
    'humorCap_neutro': '{n} 在打盹。',
    'humorSub_neutro': '这里没什么不对劲。',

    'humorCap_soneDispersivo': '{tela} 屏幕时间，比目标多 {delta}。',
    'humorSub_soneDispersivo':
        '其中 {disp} 花在让人分心的应用上。明天从零开始。',
    'humorCap_soneAcima': '{tela} 屏幕时间，比目标多 {delta}。',
    'humorSub_soneAcima': '今天没有专注。明天从零开始。',
    'humorCap_sone': '{n} 困了。',
    'humorSub_sone': '这是屏幕时间很长的一天。',
  },
};
