class T {
  T(this.lang) : _m = catalog[lang] ?? catalog['pt']!;

  final String lang;
  final Map<String, Object> _m;

  String s(String key) => _m[key] as String;

  String fill(String tpl, Map<String, Object> vals) {
    return tpl.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
      return '${vals[m[1]] ?? m[0]}';
    });
  }

  List<String> get quizQ => List<String>.from(_m['quizQ'] as List);
  List<List<String>> get quizO =>
      (_m['quizO'] as List).map((e) => List<String>.from(e as List)).toList();
  List<String> get items => List<String>.from(_m['items'] as List);
  List<String> get days => List<String>.from(_m['days'] as List);
  List<String> get tabs => List<String>.from(_m['tabs'] as List);
  List<String> species(String id) =>
      List<String>.from((_m['species'] as Map)[id] as List);
  String animalName(String id) =>
      '${(_m['animalNames'] as Map)[id] ?? id}';
  String moodCap(String mood) => (_m['moodCap'] as Map)[mood] as String;
  String moodSub(String mood) => (_m['moodSub'] as Map)[mood] as String;
  String moodLbl(String mood) => (_m['moodLbl'] as Map)[mood] as String;

  String freezeNote(int left) {
    if (left <= 0) return repFreeze0;
    if (left == 1) return fill(s('repFreeze'), {'n': 1});
    return fill(s('repFreezeMany'), {'n': left});
  }

  String streakLabel(int n) => n == 1 ? streakOne : fill(streak, {'n': n});

  String formatLongDate([DateTime? raw]) {
    final d = raw ?? DateTime.now();
    final mo = _monthLong[lang]![d.month - 1];
    if (lang == 'zh') return '$mo${d.day}日';
    if (lang == 'en') return '${d.day} $mo';
    return '${d.day} de $mo';
  }

  String formatReportDate([DateTime? raw]) {
    final d = raw ?? DateTime.now();
    final wd = _weekdayLong[lang]![d.weekday - 1];
    final mo = _monthLong[lang]![d.month - 1];
    if (lang == 'zh') return '${d.month}月${d.day}日 $wd';
    if (lang == 'en') return '$wd, ${d.day} $mo';
    return '$wd, ${d.day} de $mo';
  }

  String get langTitle => s('langTitle');
  String get langSub => s('langSub');
  String get cont => s('cont');
  String get start => s('start');
  String get promiseT => s('promiseT');
  String get promiseB => s('promiseB');
  String get quizT => s('quizT');
  String get quizB => s('quizB');
  String get quizCta => s('quizCta');
  String get quizWait => s('quizWait');
  String get revealKicker => s('revealKicker');
  String get coat => s('coat');
  String get revealCta => s('revealCta');
  String get goalT => s('goalT');
  String get goalB => s('goalB');
  String get goalSug => s('goalSug');
  String get goalNote => s('goalNote');
  String get goalCta => s('goalCta');
  String get permT => s('permT');
  String get permB => s('permB');
  String get perm1 => s('perm1');
  String get perm2 => s('perm2');
  String get perm3 => s('perm3');
  String get permTech => s('permTech');
  String get permAllow => s('permAllow');
  String get permLater => s('permLater');
  String get payT => s('payT');
  String get payB => s('payB');
  String get payAnnual => s('payAnnual');
  String get payMonthly => s('payMonthly');
  String get payAnnualNote => s('payAnnualNote');
  String get payMonthlyNote => s('payMonthlyNote');
  String get payBest => s('payBest');
  String get payCta => s('payCta');
  String get payCtaActive => s('payCtaActive');
  String get priceA => s('priceA');
  String get priceM => s('priceM');
  String get questsT => s('questsT');
  String get quest1 => s('quest1');
  String get quest2 => s('quest2');
  String get weekT => s('weekT');
  String get level => s('level');
  String get unlock => s('unlock');
  String get unlockDone => s('unlockDone');
  String get reportReady => s('reportReady');
  String get payRemind => s('payRemind');
  String get payRestore => s('payRestore');
  String get payTerms => s('payTerms');
  String get payPrivacy => s('payPrivacy');
  String get custom => s('custom');
  String get streak => s('streak');
  String get usageOf => s('usageOf');
  String get usageLeft => s('usageLeft');
  String get usageOver => s('usageOver');
  String get usageEven => s('usageEven');
  String get sesLabel => s('sesLabel');
  String get activityLine => s('activityLine');
  String get give => s('give');
  String get quitTitle => s('quitTitle');
  String get quitSub => s('quitSub');
  String get stay => s('stay');
  String get leave => s('leave');
  String get resWon => s('resWon');
  String get resWonSub => s('resWonSub');
  String get resLost => s('resLost');
  String get resLostSub => s('resLostSub');
  String get reward => s('reward');
  String get leavesLbl => s('leavesLbl');
  String get presentLbl => s('presentLbl');
  String get shareBtn => s('shareBtn');
  String get back => s('back');
  String get repTitle => s('repTitle');
  String get repDate => formatReportDate();
  String get repUsed => s('repUsed');
  String get repGoal => s('repGoal');
  String get repUnder => s('repUnder');
  String get repOver => s('repOver');
  String get repEven => s('repEven');
  String get repFreeze0 => s('repFreeze0');
  String get repSessions => s('repSessions');
  String get repBonus => s('repBonus');
  String get repPresent => s('repPresent');
  String get repFreeze => s('repFreeze');
  String get shopT => s('shopT');
  String get shopOwned => s('shopOwned');
  String get shopNote => s('shopNote');
  String get setT => s('setT');
  String get planNone => s('planNone');
  String get planNoneSub => s('planNoneSub');
  String get planTrial => s('planTrial');
  String get planTrialSub => s('planTrialSub');
  String get setManage => s('setManage');
  String get setLang => s('setLang');
  String get setGoal => s('setGoal');
  String get setNotif => s('setNotif');
  String get setEvening => s('setEvening');
  String get setEveningSub => s('setEveningSub');
  String get setMissed => s('setMissed');
  String get setMissedSub => s('setMissedSub');
  String get setAbout => s('setAbout');
  String get setRestore => s('setRestore');
  String get setPrivacy => s('setPrivacy');
  String get setTerms => s('setTerms');
  String get setReplay => s('setReplay');
  String get shareMeta => s('shareMeta');
  String get shareNote => s('shareNote');
  String get shareDone => s('shareDone');
  String get shareFail => s('shareFail');
  String get streakOne => s('streakOne');
  String get repFreezeMany => s('repFreezeMany');
  String get privacyBody => s('privacyBody');
  String get termsBody => s('termsBody');
  String get setUsage => s('setUsage');
  String get setUsageOn => s('setUsageOn');
  String get setUsageOff => s('setUsageOff');
  String get setUsageHint => s('setUsageHint');
  String get permUsageGranted => s('permUsageGranted');
  String get permUsageDenied => s('permUsageDenied');
  String get permIosLimit => s('permIosLimit');
  String get notifDenied => s('notifDenied');
  String get notifWebUnsupported => s('notifWebUnsupported');
  String get notifEveningTitle => s('notifEveningTitle');
  String get notifEveningBody => s('notifEveningBody');
  String get notifMissedTitle => s('notifMissedTitle');
  String get notifMissedBody => s('notifMissedBody');
  String get setPet => s('setPet');
  String get setSpecies => s('setSpecies');
  String get authLoginTitle => s('authLoginTitle');
  String get authLoginSub => s('authLoginSub');
  String get authSignupTitle => s('authSignupTitle');
  String get authSignupSub => s('authSignupSub');
  String get authEmail => s('authEmail');
  String get authPassword => s('authPassword');
  String get authPasswordConfirm => s('authPasswordConfirm');
  String get authSignIn => s('authSignIn');
  String get authSignUp => s('authSignUp');
  String get authCreateAccount => s('authCreateAccount');
  String get authBackToLogin => s('authBackToLogin');
  String get authLoading => s('authLoading');
  String get authEmailInvalid => s('authEmailInvalid');
  String get authPasswordShort => s('authPasswordShort');
  String get authPasswordMismatch => s('authPasswordMismatch');
  String get authSignOut => s('authSignOut');
  String get authConfirmEmail => s('authConfirmEmail');
  String get authAttachFail => s('authAttachFail');
  String get authBootstrapLoading => s('authBootstrapLoading');
  String get syncFail => s('syncFail');
  String get bootstrapOffline => s('bootstrapOffline');


  static const _weekdayLong = {
  'pt': ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'],
  'en': ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  'es': ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'],
  'zh': ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'],
  };

  static const _monthLong = {
  'pt': [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ],
  'en': [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ],
  'es': [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ],
  'zh': [
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月',
  ],
  };

  static const catalog = <String, Map<String, Object>>{
    'pt': _pt,
    'en': _en,
    'es': _es,
    'zh': _zh,
  };
}

const _pt = <String, Object>{
  'authLoginTitle': 'Entrar no Baru',
  'authLoginSub': 'Sua conta guarda o habitat e sincroniza entre aparelhos.',
  'authSignupTitle': 'Criar conta',
  'authSignupSub': 'Comece com habitat vazio. Nada de vitrine.',
  'authEmail': 'E-mail',
  'authPassword': 'Senha',
  'authPasswordConfirm': 'Confirmar senha',
  'authSignIn': 'Entrar',
  'authSignUp': 'Criar conta',
  'authCreateAccount': 'Criar conta',
  'authBackToLogin': 'Já tenho conta',
  'authLoading': 'Aguarde…',
  'authEmailInvalid': 'Informe um e-mail válido.',
  'authPasswordShort': 'A senha precisa ter pelo menos 6 caracteres.',
  'authPasswordMismatch': 'As senhas não coincidem.',
  'authSignOut': 'Sair da conta',
  'authConfirmEmail': 'Conta criada. Confirme o e-mail no link enviado e depois entre.',
  'authAttachFail': 'Não foi possível conectar ao servidor. Verifique a internet ou tente mais tarde.',
  'authBootstrapLoading': 'Carregando seu habitat…',
  'syncFail': 'Não foi possível sincronizar. Seus dados ficam salvos neste aparelho.',
  'bootstrapOffline': 'Conta nova ou sem dados remotos — começando habitat vazio.',
  'langTitle': 'Em que idioma você quer falar com ele?',
  'langSub': 'Pode trocar depois nos ajustes.',
  'cont': 'Continuar',
  'start': 'Começar foco',
  'promiseT': 'Deixe o celular de lado. Alguém aqui fica feliz com isso.',
  'promiseB':
      'Você escolhe um animal, define uma meta de tempo de tela e faz sessões de foco. Ele nunca morre, nunca perde nada e nunca te culpa.',
  'quizT': 'Qual animal você é por dentro?',
  'quizB':
      'Três perguntas. Suas respostas escolhem o animal que você vai cuidar. Dá para trocar depois.',
  'quizQ': [
    'O elemento do seu signo',
    'Quando sua cabeça fica mais clara',
    'O que realmente te acalma',
  ],
  'quizO': [
    ['Água', 'Fogo', 'Terra', 'Ar'],
    ['De manhã cedo', 'À tarde', 'De madrugada', 'Depende do dia'],
    ['Água quente', 'Boa companhia', 'Um quarto silencioso', 'Uma rotina'],
  ],
  'quizCta': 'Ver seu animal',
  'quizWait': 'Responda as três',
  'revealKicker': 'Seu animal interior',
  'coat': 'Pelagem',
  'revealCta': 'Prazer em conhecer',
  'species': {
    'capybara': [
      'Você é uma capivara.',
      'Água morna, companhia fácil. Você desacelera rápido quando se permite.',
    ],
    'otter': [
      'Você é uma lontra.',
      'Inquieta e brincalhona. Você foca melhor em blocos curtos e intensos.',
    ],
    'tortoise': [
      'Você é uma tartaruga.',
      'Constância vence velocidade. Um pouco todo dia é o seu truque.',
    ],
    'owl': [
      'Você é uma coruja.',
      'Mais lúcida depois que escurece. Você precisa de silêncio, não de pressa.',
    ],
  },
  'goalT': 'Quanto tempo de tela num dia comum?',
  'goalB': 'Um chute serve. Só precisamos de um ponto de partida.',
  'goalSug': 'Meta diária sugerida',
  'goalNote':
      '25% abaixo da sua média. Dá para mudar quando quiser nos ajustes.',
  'goalCta': 'Usar esta meta',
  'permT': 'O humor dele acompanha seu tempo de tela.',
  'permB': 'Para isso, ele precisa ler o total do dia no seu telefone.',
  'perm1': 'Só o total do dia. Nunca quais apps, nunca conteúdo.',
  'perm2': 'Lido algumas vezes por dia. Nada sai do aparelho.',
  'perm3': 'Se preferir pular, ele lê seu humor só pelas sessões de foco.',
  'permTech':
      'Android: Acesso ao Uso (PACKAGE_USAGE_STATS). iOS: Screen Time exige entitlement Apple — o app não finge permissão.',
  'permAllow': 'Permitir acesso ao uso',
  'permLater': 'Talvez depois',
  'payT': 'Fique perto de {n}.',
  'payB':
      'Sessões de foco ilimitadas, a loja completa do habitat e o relatório diário.',
  'payAnnual': 'Anual',
  'payMonthly': 'Mensal',
  'payAnnualNote': '7 dias grátis, depois R\$ 179,90 por ano',
  'payMonthlyNote': 'R\$ 34,90 por mês, cancele quando quiser',
  'payBest': 'Melhor valor',
  'payCta': 'Começar 7 dias grátis',
  'payCtaActive': 'Teste ativo — continuar',
  'priceA': 'R\$ 179,90',
  'priceM': 'R\$ 34,90',
  'questsT': 'Hoje',
  'quest1': 'Uma sessão de foco',
  'quest2': 'Fechar o dia abaixo da meta',
  'weekT': 'Esta semana',
  'level': 'Habitat nível {n}',
  'unlock': 'faltam {x} folhas para {i}',
  'unlockDone': 'Habitat completo',
  'reportReady': 'O relatório de hoje está pronto',
  'days': ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'],
  'payRemind': 'Avisamos 24h antes do teste terminar.',
  'payRestore': 'Restaurar',
  'payTerms': 'Termos',
  'payPrivacy': 'Privacidade',
  'custom': 'Livre',
  'streak': '{n} dias presente',
  'usageOf': '{u} de {g}',
  'usageLeft': 'faltam {x}',
  'usageOver': '{x} acima',
  'usageEven': 'na meta',
  'moodCap': {
    'radiant': '{n} está radiante.',
    'content': '{n} está contente.',
    'neutral': '{n} cochila na parte rasa.',
    'sleepy': '{n} está com sono.',
    'missing_you': '{n} sentiu sua falta.',
  },
  'moodSub': {
    'radiant': 'Abaixo da meta e uma sessão na água. O melhor tipo de dia.',
    'content': 'Um dia decente. Uma sessão a mais e ele estaria radiante.',
    'neutral': 'Em cima da meta. Nada para corrigir.',
    'sleepy': 'Dia longo de tela. Amanhã ele topa nadar.',
    'missing_you':
        'Ele te esperou. Nada foi perdido enquanto você esteve fora.',
  },
  'moodLbl': {
    'radiant': 'radiante',
    'content': 'contente',
    'neutral': 'neutro',
    'sleepy': 'sonolento',
    'missing_you': 'com saudade',
  },
  'sesLabel': 'banho de {m} min',
  'activityLine': '{n} está nadando.',
  'give': 'Desistir',
  'quitTitle': '{n} está no meio de um banho.',
  'quitSub': 'Sair agora encerra a sessão sem folhas. Nada mais muda.',
  'stay': 'Ficar com ele',
  'leave': 'Sair mesmo assim',
  'resWon': '{m} minutos concluídos.',
  'resWonSub':
      '{n} nadou bastante e saiu para secar. Bem-vindo de volta.',
  'resLost': '{n} sentiu sua falta.',
  'resLostSub':
      'Sem folhas desta vez, e nada foi perdido. Ele continua aqui.',
  'reward': '+{k} folhas',
  'leavesLbl': 'Folhas',
  'presentLbl': 'Presente',
  'shareBtn': 'Compartilhar o habitat',
  'back': 'Voltar ao habitat',
  'repTitle': 'O dia de {n}',
  'repDate': 'Terça, 26 de agosto',
  'repUsed': 'tempo de tela hoje',
  'repGoal': 'sua meta',
  'repUnder': '{x} abaixo da sua meta.',
  'repOver': '{x} acima da sua meta. Amanhã é outro dia.',
  'repEven': 'Em cima da sua meta.',
  'repSessions': 'Sessões completas',
  'repBonus': 'Bônus por ficar abaixo',
  'repPresent': 'Dias presente',
  'repFreeze':
      'Resta {n} congelamento nesta semana. Se você faltar um dia, ele te espera.',
  'repFreeze0':
      'Sem congelamento nesta semana. Se você faltar um dia, ele te espera.',
  'shopT': 'Habitat',
  'shopOwned': 'No habitat',
  'shopNote':
      'Os itens ocupam um lugar fixo no habitat. Reorganizar vem depois.',
  'items': [
    'Vitórias-régias',
    'Bambuzal',
    'Pedra da fonte',
    'Deque de madeira',
    'Lanterna de papel',
    'Laranjeira',
    'Barquinho',
    'Ponte de pedra',
  ],
  'setT': 'Ajustes',
  'planNone': 'Sem assinatura',
  'planNoneSub': 'Comece 7 dias grátis quando quiser',
  'planTrial': 'Teste · faltam {n} dias',
  'planTrialSub': 'O plano anual começa em {d}',
  'setManage': 'Gerenciar',
  'setLang': 'Idioma',
  'setGoal': 'Meta diária',
  'setNotif': 'Notificações',
  'setEvening': 'Relatório da noite',
  'setEveningSub': 'Todo dia às 21h',
  'setMissed': '"Senti sua falta"',
  'setMissedSub':
      'No máximo uma vez por dia, depois de dois dias longe',
  'setAbout': 'Sobre',
  'setRestore': 'Restaurar compras',
  'setPrivacy': 'Política de privacidade',
  'setTerms': 'Termos de uso',
  'setReplay': 'Refazer o onboarding',
  'setPet': 'Companheiro',
  'setSpecies': 'Animal',
  'setUsage': 'Tempo de tela',
  'setUsageOn': 'Lendo o total do dia',
  'setUsageOff': 'Só pelas sessões de foco',
  'permUsageGranted': 'Acesso ao uso ativado. O humor do pet acompanha seu tempo de tela.',
  'permUsageDenied': 'Acesso ao uso não concedido. Ative nas configurações do sistema.',
  'permIosLimit': 'No iPhone, o Baru ainda não pode ler tempo de tela sem aprovação especial da Apple (Screen Time). Abra Ajustes se quiser conferir.',
  'notifDenied': 'Ative notificações nas configurações do sistema para receber lembretes.',
  'notifWebUnsupported': 'Notificações disponíveis só no app mobile.',
  'notifEveningTitle': 'Relatório da noite',
  'notifEveningBody': '{n} preparou o resumo do seu dia.',
  'notifMissedTitle': 'Senti sua falta',
  'notifMissedBody': '{n} sentiu sua falta hoje. Uma sessão curta já ajuda.',
  'setUsageHint': 'Pode mudar quando quiser. Nada sai do aparelho.',
  'animalNames': {
    'capybara': 'Capivara',
    'otter': 'Lontra',
    'tortoise': 'Tartaruga',
    'owl': 'Coruja',
  },
  'shareMeta': 'Imagem · 402 × 296',
  'shareNote':
      'Folha de compartilhamento nativa. A fase 1 compartilha um screenshot do habitat.',
  'shareDone': 'Pronto',
  'shareFail': 'Não deu para compartilhar agora. Tente de novo.',
  'streakOne': '1 dia presente',
  'repFreezeMany':
      'Restam {n} congelamentos nesta semana. Se você faltar um dia, ele te espera.',
  'privacyBody':
      'O Baru lê só o total de tempo de tela do dia, se você permitir. Nunca quais apps, nunca o conteúdo. Nada disso sai do aparelho nesta fase. Sessões, folhas e o habitat ficam no telefone. A assinatura desta versão é um teste local — a compra pela loja vem depois.',
  'termsBody':
      'Você usa o Baru para sessões de foco e um habitat. Ele nunca morre, nunca perde progresso e nunca te culpa. O teste de 7 dias desta versão não cobra na loja. Restaurar compras só marca o teste local. Trocar o idioma e a meta não apaga o habitat.',
  'tabs': ['Habitat', 'Loja', 'Relatório', 'Ajustes'],
};

const _en = <String, Object>{
  'authLoginTitle': 'Sign in to Baru',
  'authLoginSub': 'Your account saves the habitat and syncs across devices.',
  'authSignupTitle': 'Create account',
  'authSignupSub': 'Start with an empty habitat. No demo data.',
  'authEmail': 'Email',
  'authPassword': 'Password',
  'authPasswordConfirm': 'Confirm password',
  'authSignIn': 'Sign in',
  'authSignUp': 'Create account',
  'authCreateAccount': 'Create account',
  'authBackToLogin': 'I already have an account',
  'authLoading': 'Please wait…',
  'authEmailInvalid': 'Enter a valid email address.',
  'authPasswordShort': 'Password must be at least 6 characters.',
  'authPasswordMismatch': 'Passwords do not match.',
  'authSignOut': 'Sign out',
  'authConfirmEmail': 'Account created. Confirm your email with the link we sent, then sign in.',
  'authAttachFail': 'Could not reach the server. Check your connection or try again later.',
  'authBootstrapLoading': 'Loading your habitat…',
  'syncFail': 'Could not sync. Your data stays saved on this device.',
  'bootstrapOffline': 'New account or no remote data — starting with an empty habitat.',
  'langTitle': 'Which language should we speak?',
  'langSub': 'You can change it later in settings.',
  'cont': 'Continue',
  'start': 'Start focus',
  'promiseT': 'Put the phone down. Someone here is glad about it.',
  'promiseB':
      'You pick an animal, set a screen-time goal, and run focus sessions. It never dies, never loses anything, and never blames you.',
  'quizT': 'Which animal are you on the inside?',
  'quizB':
      'Three questions. Your answers pick the animal you will look after. You can change it later.',
  'quizQ': [
    "Your sign's element",
    'When is your head clearest',
    'What actually calms you down',
  ],
  'quizO': [
    ['Water', 'Fire', 'Earth', 'Air'],
    ['Early morning', 'Afternoon', 'Late night', 'Depends on the day'],
    ['Warm water', 'Good company', 'A quiet room', 'A routine'],
  ],
  'quizCta': 'See your animal',
  'quizWait': 'Answer all three',
  'revealKicker': 'Your inner animal',
  'coat': 'Coat',
  'revealCta': 'Nice to meet you',
  'species': {
    'capybara': [
      "You're a capybara.",
      'Warm water, easy company. You settle fast once you let yourself stop.',
    ],
    'otter': [
      "You're an otter.",
      'Restless and playful. You focus best in short, bright bursts.',
    ],
    'tortoise': [
      "You're a tortoise.",
      'Steady beats fast. A small distance every day is your whole trick.',
    ],
    'owl': [
      "You're an owl.",
      'Clearest after dark. You need quiet more than you need speed.',
    ],
  },
  'goalT': 'How much screen time on an average day?',
  'goalB': 'A rough guess is fine. We only need a starting point.',
  'goalSug': 'Suggested daily goal',
  'goalNote': '25% below your average. You can move it any time in settings.',
  'goalCta': 'Use this goal',
  'permT': 'Its mood follows your screen time.',
  'permB': 'To do that, it needs to read the daily total from your phone.',
  'perm1': 'Only the daily total. Never which apps, never content.',
  'perm2': 'Read a few times a day. Nothing leaves your device.',
  'perm3': 'Skip it and it reads your mood from focus sessions alone.',
  'permTech':
      'Android: Usage Access settings sheet. iOS: Screen Time request behind a feature flag until the entitlement lands.',
  'permAllow': 'Allow usage access',
  'permLater': 'Maybe later',
  'payT': 'Keep {n} company.',
  'payB': 'Unlimited focus sessions, the full habitat shop, and daily reports.',
  'payAnnual': 'Annual',
  'payMonthly': 'Monthly',
  'payAnnualNote': '7 days free, then \$34.99 a year',
  'payMonthlyNote': 'Billed every month',
  'payBest': 'Best value',
  'payCta': 'Start 7-day free trial',
  'payCtaActive': 'Trial active — continue',
  'priceA': '\$34.99',
  'priceM': '\$6.99',
  'questsT': 'Today',
  'quest1': 'One focus session',
  'quest2': 'Finish the day under your goal',
  'weekT': 'This week',
  'level': 'Habitat level {n}',
  'unlock': '{x} leaves to {i}',
  'unlockDone': 'Habitat complete',
  'reportReady': "Today's report is ready",
  'days': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  'payRemind': "We'll remind you 24h before your trial ends.",
  'payRestore': 'Restore',
  'payTerms': 'Terms',
  'payPrivacy': 'Privacy',
  'custom': 'Custom',
  'streak': '{n} days present',
  'usageOf': '{u} of {g}',
  'usageLeft': '{x} left',
  'usageOver': '{x} over',
  'usageEven': 'on goal',
  'moodCap': {
    'radiant': '{n} is radiant.',
    'content': '{n} is content.',
    'neutral': '{n} is dozing in the shallows.',
    'sleepy': '{n} is sleepy.',
    'missing_you': '{n} missed you.',
  },
  'moodSub': {
    'radiant': 'Under your goal and a session in the water. Best kind of day.',
    'content': 'A decent day. One more session and it would be beaming.',
    'neutral': 'Right around your goal. Nothing to fix.',
    'sleepy': 'A long screen day. It will be up for a swim tomorrow.',
    'missing_you': 'It waited for you. Nothing was lost while you were gone.',
  },
  'moodLbl': {
    'radiant': 'radiant',
    'content': 'content',
    'neutral': 'neutral',
    'sleepy': 'sleepy',
    'missing_you': 'missing you',
  },
  'sesLabel': '{m} minute swim',
  'activityLine': '{n} is swimming.',
  'give': 'Give up',
  'quitTitle': '{n} is in the middle of a swim.',
  'quitSub':
      'Leaving now ends the session with no leaves. Nothing else changes.',
  'stay': 'Stay with it',
  'leave': 'Leave anyway',
  'resWon': '{m} minutes done.',
  'resWonSub':
      '{n} had a long swim and came out to dry off. Welcome back.',
  'resLost': '{n} missed you.',
  'resLostSub':
      "No leaves this time, and nothing taken away. It's still here.",
  'reward': '+{k} leaves',
  'leavesLbl': 'Leaves',
  'presentLbl': 'Present',
  'shareBtn': 'Share the habitat',
  'back': 'Back to habitat',
  'repTitle': "{n}'s day",
  'repDate': 'Tuesday, 26 August',
  'repUsed': 'screen time today',
  'repGoal': 'your goal',
  'repUnder': '{x} under your goal.',
  'repOver': '{x} over your goal. Tomorrow is a new day.',
  'repEven': 'Right on your goal.',
  'repSessions': 'Sessions completed',
  'repBonus': 'Under-goal bonus',
  'repPresent': 'Days present',
  'repFreeze':
      '{n} freeze left this week. If you miss a day, it waits for you.',
  'repFreeze0':
      'No freeze left this week. If you miss a day, it waits for you.',
  'shopT': 'Habitat',
  'shopOwned': 'In habitat',
  'shopNote':
      'Items land in a fixed spot in the habitat. Rearranging comes later.',
  'items': [
    'Lily Pads',
    'Bamboo Cluster',
    'Hot Spring Rock',
    'Wooden Dock',
    'Paper Lantern',
    'Orange Tree',
    'Little Boat',
    'Stone Bridge',
  ],
  'setT': 'Settings',
  'planNone': 'No subscription',
  'planNoneSub': 'Start a 7-day free trial any time',
  'planTrial': 'Trial · {n} days left',
  'planTrialSub': 'Annual plan starts {d}',
  'setManage': 'Manage',
  'setLang': 'Language',
  'setGoal': 'Daily goal',
  'setNotif': 'Notifications',
  'setEvening': 'Evening report',
  'setEveningSub': 'Every day at 9:00 PM',
  'setMissed': '"Missed you"',
  'setMissedSub': 'At most once a day, after two days away',
  'setAbout': 'About',
  'setRestore': 'Restore purchases',
  'setPrivacy': 'Privacy policy',
  'setTerms': 'Terms of service',
  'setReplay': 'Replay onboarding',
  'setPet': 'Companion',
  'setSpecies': 'Animal',
  'setUsage': 'Screen time',
  'setUsageOn': 'Reading the daily total',
  'setUsageOff': 'Focus sessions only',
  'permUsageGranted': 'Usage access enabled. Your pet mood now follows screen time.',
  'permUsageDenied': 'Usage access not granted. Enable it in system settings.',
  'permIosLimit': "On iPhone, Baru cannot read screen time without Apple's Family Controls entitlement. Opening Settings.",
  'notifDenied': 'Enable notifications in system settings to get reminders.',
  'notifWebUnsupported': 'Notifications are only available in the mobile app.',
  'notifEveningTitle': 'Evening report',
  'notifEveningBody': '{n} has your daily summary ready.',
  'notifMissedTitle': 'Missed you',
  'notifMissedBody': '{n} missed you today. A short focus session helps.',
  'setUsageHint': 'Change any time. Nothing leaves your device.',
  'animalNames': {
    'capybara': 'Capybara',
    'otter': 'Otter',
    'tortoise': 'Tortoise',
    'owl': 'Owl',
  },
  'shareMeta': 'Image · 402 × 296',
  'shareNote':
      'Native share sheet. Phase 1 shares a screenshot of the habitat.',
  'shareDone': 'Done',
  'shareFail': "Couldn't share just now. Try again.",
  'streakOne': '1 day present',
  'repFreezeMany':
      '{n} freezes left this week. If you miss a day, it waits for you.',
  'privacyBody':
      'Baru reads only the daily screen-time total, if you allow it. Never which apps, never content. Nothing leaves your device in this phase. Sessions, leaves, and the habitat stay on the phone. The subscription here is a local trial — store billing comes later.',
  'termsBody':
      'You use Baru for focus sessions and a habitat. It never dies, never loses progress, and never blames you. The 7-day trial in this build does not charge through the store. Restore purchases only marks the local trial. Changing language or goal does not wipe the habitat.',
  'tabs': ['Habitat', 'Shop', 'Report', 'Settings'],
};

const _es = <String, Object>{
  'authLoginTitle': 'Entrar en Baru',
  'authLoginSub': 'Tu cuenta guarda el hábitat y sincroniza entre dispositivos.',
  'authSignupTitle': 'Crear cuenta',
  'authSignupSub': 'Empieza con hábitat vacío. Sin datos de demo.',
  'authEmail': 'Correo',
  'authPassword': 'Contraseña',
  'authPasswordConfirm': 'Confirmar contraseña',
  'authSignIn': 'Entrar',
  'authSignUp': 'Crear cuenta',
  'authCreateAccount': 'Crear cuenta',
  'authBackToLogin': 'Ya tengo cuenta',
  'authLoading': 'Espera…',
  'authEmailInvalid': 'Introduce un correo válido.',
  'authPasswordShort': 'La contraseña debe tener al menos 6 caracteres.',
  'authPasswordMismatch': 'Las contraseñas no coinciden.',
  'authSignOut': 'Cerrar sesión',
  'authConfirmEmail': 'Cuenta creada. Confirma tu correo con el enlace que enviamos y luego entra.',
  'authAttachFail': 'No se pudo conectar al servidor. Revisa tu conexión o inténtalo más tarde.',
  'authBootstrapLoading': 'Cargando tu hábitat…',
  'syncFail': 'No se pudo sincronizar. Tus datos quedan guardados en este dispositivo.',
  'bootstrapOffline': 'Cuenta nueva o sin datos remotos: empezamos con un hábitat vacío.',
  'langTitle': '¿En qué idioma quieres hablarle?',
  'langSub': 'Puedes cambiarlo después en ajustes.',
  'cont': 'Continuar',
  'start': 'Empezar enfoque',
  'promiseT': 'Deja el móvil. Aquí alguien se alegra.',
  'promiseB':
      'Eliges un animal, defines una meta de tiempo de pantalla y haces sesiones de enfoque. Nunca muere, nunca pierde nada y nunca te culpa.',
  'quizT': '¿Qué animal eres por dentro?',
  'quizB':
      'Tres preguntas. Tus respuestas eligen el animal que vas a cuidar. Puedes cambiarlo después.',
  'quizQ': [
    'El elemento de tu signo',
    'Cuándo tienes la cabeza más clara',
    'Qué te calma de verdad',
  ],
  'quizO': [
    ['Agua', 'Fuego', 'Tierra', 'Aire'],
    ['Temprano', 'Por la tarde', 'De madrugada', 'Depende del día'],
    ['Agua caliente', 'Buena compañía', 'Un cuarto en silencio', 'Una rutina'],
  ],
  'quizCta': 'Ver tu animal',
  'quizWait': 'Responde las tres',
  'revealKicker': 'Tu animal interior',
  'coat': 'Pelaje',
  'revealCta': 'Un placer',
  'species': {
    'capybara': [
      'Eres un carpincho.',
      'Agua tibia, buena compañía. Te calmas rápido cuando te lo permites.',
    ],
    'otter': [
      'Eres una nutria.',
      'Inquieta y juguetona. Te concentras mejor en ráfagas cortas.',
    ],
    'tortoise': [
      'Eres una tortuga.',
      'La constancia gana a la velocidad. Un poco cada día es tu truco.',
    ],
    'owl': [
      'Eres un búho.',
      'Más lúcido de noche. Necesitas silencio, no prisa.',
    ],
  },
  'goalT': '¿Cuánto tiempo de pantalla en un día normal?',
  'goalB': 'Una estimación basta. Solo necesitamos un punto de partida.',
  'goalSug': 'Meta diaria sugerida',
  'goalNote':
      '25% por debajo de tu promedio. Puedes cambiarlo cuando quieras.',
  'goalCta': 'Usar esta meta',
  'permT': 'Su ánimo sigue tu tiempo de pantalla.',
  'permB': 'Para eso necesita leer el total diario de tu teléfono.',
  'perm1': 'Solo el total del día. Nunca qué apps ni el contenido.',
  'perm2': 'Se lee unas veces al día. Nada sale del dispositivo.',
  'perm3': 'Si prefieres, usa solo tus sesiones de enfoque.',
  'permTech':
      'Android: pantalla de Acceso al Uso. iOS: permiso de Tiempo de Uso tras un feature flag hasta que llegue el entitlement.',
  'permAllow': 'Permitir acceso al uso',
  'permLater': 'Quizá después',
  'payT': 'Acompaña a {n}.',
  'payB':
      'Sesiones ilimitadas, la tienda completa del hábitat y el informe diario.',
  'payAnnual': 'Anual',
  'payMonthly': 'Mensual',
  'payAnnualNote': '7 días gratis, luego US\$ 34,99 al año',
  'payMonthlyNote': 'Cobro mensual',
  'payBest': 'Mejor valor',
  'payCta': 'Empezar 7 días gratis',
  'payCtaActive': 'Prueba activa — continuar',
  'priceA': '\$34.99',
  'priceM': '\$6.99',
  'questsT': 'Hoy',
  'quest1': 'Una sesión de enfoque',
  'quest2': 'Terminar el día debajo de la meta',
  'weekT': 'Esta semana',
  'level': 'Hábitat nivel {n}',
  'unlock': 'faltan {x} hojas para {i}',
  'unlockDone': 'Hábitat completo',
  'reportReady': 'El informe de hoy está listo',
  'days': ['L', 'M', 'X', 'J', 'V', 'S', 'D'],
  'payRemind': 'Te avisamos 24 h antes de que termine la prueba.',
  'payRestore': 'Restaurar',
  'payTerms': 'Términos',
  'payPrivacy': 'Privacidad',
  'custom': 'Libre',
  'streak': '{n} días presente',
  'usageOf': '{u} de {g}',
  'usageLeft': 'faltan {x}',
  'usageOver': '{x} de más',
  'usageEven': 'en la meta',
  'moodCap': {
    'radiant': '{n} está radiante.',
    'content': '{n} está contento.',
    'neutral': '{n} dormita en la orilla.',
    'sleepy': '{n} tiene sueño.',
    'missing_you': '{n} te echó de menos.',
  },
  'moodSub': {
    'radiant':
        'Por debajo de la meta y una sesión en el agua. El mejor tipo de día.',
    'content': 'Un día decente. Una sesión más y estaría radiante.',
    'neutral': 'Justo en la meta. Nada que corregir.',
    'sleepy': 'Día largo de pantalla. Mañana se anima a nadar.',
    'missing_you':
        'Te esperó. Nada se perdió mientras estuviste fuera.',
  },
  'moodLbl': {
    'radiant': 'radiante',
    'content': 'contento',
    'neutral': 'neutral',
    'sleepy': 'somnoliento',
    'missing_you': 'te echa de menos',
  },
  'sesLabel': 'baño de {m} min',
  'activityLine': '{n} está nadando.',
  'give': 'Rendirse',
  'quitTitle': '{n} está en medio de un baño.',
  'quitSub': 'Salir ahora termina la sesión sin hojas. Nada más cambia.',
  'stay': 'Quedarme',
  'leave': 'Salir igual',
  'resWon': '{m} minutos completados.',
  'resWonSub': '{n} nadó a gusto y salió a secarse. Bienvenido de vuelta.',
  'resLost': '{n} te echó de menos.',
  'resLostSub': 'Sin hojas esta vez, y nada se perdió. Sigue aquí.',
  'reward': '+{k} hojas',
  'leavesLbl': 'Hojas',
  'presentLbl': 'Presente',
  'shareBtn': 'Compartir el hábitat',
  'back': 'Volver al hábitat',
  'repTitle': 'El día de {n}',
  'repDate': 'Martes, 26 de agosto',
  'repUsed': 'tiempo de pantalla hoy',
  'repGoal': 'tu meta',
  'repUnder': '{x} por debajo de tu meta.',
  'repOver': '{x} por encima de tu meta. Mañana es otro día.',
  'repEven': 'Justo en tu meta.',
  'repSessions': 'Sesiones completas',
  'repBonus': 'Bono por estar debajo',
  'repPresent': 'Días presente',
  'repFreeze':
      'Queda {n} congelamiento esta semana. Si faltas un día, te espera.',
  'repFreeze0':
      'Sin congelamiento esta semana. Si faltas un día, te espera.',
  'shopT': 'Hábitat',
  'shopOwned': 'En el hábitat',
  'shopNote':
      'Los objetos van a un lugar fijo del hábitat. Reordenar vendrá después.',
  'items': [
    'Nenúfares',
    'Cañas de bambú',
    'Piedra termal',
    'Muelle de madera',
    'Farol de papel',
    'Naranjo',
    'Barquita',
    'Puente de piedra',
  ],
  'setT': 'Ajustes',
  'planNone': 'Sin suscripción',
  'planNoneSub': 'Empieza 7 días gratis cuando quieras',
  'planTrial': 'Prueba · quedan {n} días',
  'planTrialSub': 'El plan anual empieza el {d}',
  'setManage': 'Gestionar',
  'setLang': 'Idioma',
  'setGoal': 'Meta diaria',
  'setNotif': 'Notificaciones',
  'setEvening': 'Informe de la noche',
  'setEveningSub': 'Todos los días a las 21:00',
  'setMissed': '"Te echo de menos"',
  'setMissedSub':
      'Como máximo una vez al día, tras dos días sin abrir',
  'setAbout': 'Acerca de',
  'setRestore': 'Restaurar compras',
  'setPrivacy': 'Política de privacidad',
  'setTerms': 'Términos del servicio',
  'setReplay': 'Repetir la introducción',
  'setPet': 'Compañero',
  'setSpecies': 'Animal',
  'setUsage': 'Tiempo de pantalla',
  'setUsageOn': 'Lee el total del día',
  'setUsageOff': 'Solo sesiones de enfoque',
  'permUsageGranted': 'Acceso al uso activado. El ánimo sigue tu tiempo de pantalla.',
  'permUsageDenied': 'Acceso al uso no concedido. Actívalo en ajustes del sistema.',
  'permIosLimit': 'En iPhone, Baru no puede leer tiempo de pantalla sin el entitlement de Apple (Tiempo en pantalla). Abriendo Ajustes.',
  'notifDenied': 'Activa las notificaciones en ajustes del sistema para recibir avisos.',
  'notifWebUnsupported': 'Las notificaciones solo están en la app móvil.',
  'notifEveningTitle': 'Informe de la noche',
  'notifEveningBody': '{n} tiene listo el resumen del día.',
  'notifMissedTitle': 'Te echo de menos',
  'notifMissedBody': '{n} te echó de menos hoy. Una sesión corta ayuda.',
  'setUsageHint': 'Puedes cambiarlo cuando quieras. Nada sale del dispositivo.',
  'animalNames': {
    'capybara': 'Carpincho',
    'otter': 'Nutria',
    'tortoise': 'Tortuga',
    'owl': 'Búho',
  },
  'shareMeta': 'Imagen · 402 × 296',
  'shareNote':
      'Hoja de compartir nativa. La fase 1 comparte una captura del hábitat.',
  'shareDone': 'Listo',
  'shareFail': 'No se pudo compartir ahora. Inténtalo de nuevo.',
  'streakOne': '1 día presente',
  'repFreezeMany':
      'Quedan {n} congelamientos esta semana. Si faltas un día, te espera.',
  'privacyBody':
      'Baru solo lee el total diario de tiempo de pantalla, si lo permites. Nunca qué apps ni el contenido. Nada sale del aparato en esta fase. Sesiones, hojas y el hábitat quedan en el teléfono. La suscripción de esta versión es una prueba local — el cobro en la tienda llega después.',
  'termsBody':
      'Usas Baru para sesiones de enfoque y un hábitat. Nunca muere, nunca pierde progreso y nunca te culpa. La prueba de 7 días de esta versión no cobra en la tienda. Restaurar compras solo marca la prueba local. Cambiar idioma o meta no borra el hábitat.',
  'tabs': ['Hábitat', 'Tienda', 'Informe', 'Ajustes'],
};

const _zh = <String, Object>{
  'authLoginTitle': '登录 Baru',
  'authLoginSub': '账号保存栖息地并在设备间同步。',
  'authSignupTitle': '创建账号',
  'authSignupSub': '从空栖息地开始，没有演示数据。',
  'authEmail': '邮箱',
  'authPassword': '密码',
  'authPasswordConfirm': '确认密码',
  'authSignIn': '登录',
  'authSignUp': '创建账号',
  'authCreateAccount': '创建账号',
  'authBackToLogin': '已有账号',
  'authLoading': '请稍候…',
  'authEmailInvalid': '请输入有效的邮箱。',
  'authPasswordShort': '密码至少需要 6 个字符。',
  'authPasswordMismatch': '两次密码不一致。',
  'authSignOut': '退出登录',
  'authConfirmEmail': '账号已创建。请点击我们发送的链接确认邮箱，然后登录。',
  'authAttachFail': '无法连接服务器。请检查网络或稍后重试。',
  'authBootstrapLoading': '正在加载你的栖息地…',
  'syncFail': '同步失败。你的数据已保存在本机。',
  'bootstrapOffline': '新账号或没有云端数据 — 从空的栖息地开始。',
  'langTitle': '你想用哪种语言？',
  'langSub': '之后可以在设置里更改。',
  'cont': '继续',
  'start': '开始专注',
  'promiseT': '放下手机。这里有人会因此开心。',
  'promiseB': '选一只动物，设定每日屏幕时间目标，开始专注时段。它不会死，不会丢东西，也不会责怪你。',
  'quizT': '你内心是哪种动物？',
  'quizB': '三个问题。答案决定你要照顾的动物，之后可以更改。',
  'quizQ': ['你星座的元素', '什么时候头脑最清醒', '什么真的能让你平静'],
  'quizO': [
    ['水', '火', '土', '风'],
    ['清晨', '下午', '深夜', '看当天'],
    ['温水', '有人陪', '安静的房间', '固定的节奏'],
  ],
  'quizCta': '看看你的动物',
  'quizWait': '请回答三个问题',
  'revealKicker': '你的内在动物',
  'coat': '毛色',
  'revealCta': '很高兴认识你',
  'species': {
    'capybara': ['你是水豚。', '温水，轻松的陪伴。一旦允许自己停下，你会很快安定。'],
    'otter': ['你是水獭。', '好动又爱玩。你在短而密集的时段里最专注。'],
    'tortoise': ['你是乌龟。', '稳比快好。每天走一点点，就是你的全部诀窍。'],
    'owl': ['你是猫头鹰。', '入夜后最清醒。你需要安静，而不是速度。'],
  },
  'goalT': '平常一天用多久手机？',
  'goalB': '大概就行，我们只需要一个起点。',
  'goalSug': '建议的每日目标',
  'goalNote': '比你的平均少 25%。随时可在设置中调整。',
  'goalCta': '使用这个目标',
  'permT': '它的心情跟着你的屏幕时间。',
  'permB': '为此，它需要读取手机上的每日总时长。',
  'perm1': '只读每日总时长，不看具体应用，也不看内容。',
  'perm2': '每天读取几次。数据不离开你的设备。',
  'perm3': '跳过也可以，它就只根据专注时段判断。',
  'permTech':
      'Android：使用情况访问设置页。iOS：屏幕使用时间权限在功能开关之后，等待 Apple 授权。',
  'permAllow': '允许读取使用情况',
  'permLater': '以后再说',
  'payT': '陪着 {n}。',
  'payB': '无限专注时段、完整的栖息地商店和每日报告。',
  'payAnnual': '年付',
  'payMonthly': '月付',
  'payAnnualNote': '7 天免费，之后每年 34.99 美元',
  'payMonthlyNote': '按月收费',
  'payBest': '最划算',
  'payCta': '开始 7 天免费试用',
  'payCtaActive': '试用中 — 继续',
  'priceA': '\$34.99',
  'priceM': '\$6.99',
  'questsT': '今天',
  'quest1': '完成一次专注',
  'quest2': '今天低于目标',
  'weekT': '本周',
  'level': '栖息地 {n} 级',
  'unlock': '再 {x} 片叶子解锁{i}',
  'unlockDone': '栖息地已完成',
  'reportReady': '今天的报告已生成',
  'days': ['一', '二', '三', '四', '五', '六', '日'],
  'payRemind': '试用结束前 24 小时我们会提醒你。',
  'payRestore': '恢复购买',
  'payTerms': '条款',
  'payPrivacy': '隐私',
  'custom': '自定义',
  'streak': '已陪伴 {n} 天',
  'usageOf': '{u} / {g}',
  'usageLeft': '还剩 {x}',
  'usageOver': '超出 {x}',
  'usageEven': '刚好达标',
  'moodCap': {
    'radiant': '{n} 神采飞扬。',
    'content': '{n} 很满足。',
    'neutral': '{n} 在浅水里打瞌睡。',
    'sleepy': '{n} 困了。',
    'missing_you': '{n} 有点想你。',
  },
  'moodSub': {
    'radiant': '低于目标，还完成了一次专注。这是最好的一天。',
    'content': '还不错的一天。再来一次专注，它就会神采飞扬。',
    'neutral': '刚好在目标附近。没什么要改的。',
    'sleepy': '屏幕时间很长的一天。明天它还愿意去游泳。',
    'missing_you': '它一直在等你。你离开的时候，什么都没有丢。',
  },
  'moodLbl': {
    'radiant': '神采飞扬',
    'content': '满足',
    'neutral': '平静',
    'sleepy': '困了',
    'missing_you': '有点想你',
  },
  'sesLabel': '{m} 分钟',
  'activityLine': '{n} 正在游泳。',
  'give': '放弃',
  'quitTitle': '{n} 正游到一半。',
  'quitSub': '现在离开会结束这次专注，没有叶子。其他什么都不会变。',
  'stay': '再陪一会儿',
  'leave': '仍然离开',
  'resWon': '完成 {m} 分钟。',
  'resWonSub': '{n} 游了很久，上岸晒干了。欢迎回来。',
  'resLost': '{n} 有点想你。',
  'resLostSub': '这次没有叶子，但也没有任何损失。它还在。',
  'reward': '+{k} 片叶子',
  'leavesLbl': '叶子',
  'presentLbl': '陪伴',
  'shareBtn': '分享栖息地',
  'back': '回到栖息地',
  'repTitle': '{n} 的一天',
  'repDate': '8月26日 星期二',
  'repUsed': '今日屏幕时间',
  'repGoal': '你的目标',
  'repUnder': '比目标少 {x}。',
  'repOver': '超出目标 {x}。明天又是新的一天。',
  'repEven': '刚好在目标上。',
  'repSessions': '完成的专注',
  'repBonus': '达标奖励',
  'repPresent': '陪伴天数',
  'repFreeze': '本周还有 {n} 次冻结。如果你缺一天，它会等你。',
  'repFreeze0': '本周没有冻结次数了。如果你缺一天，它会等你。',
  'shopT': '栖息地',
  'shopOwned': '已放置',
  'shopNote': '物品会放在固定位置。自由摆放稍后支持。',
  'items': ['睡莲', '竹丛', '温泉石', '木栈桥', '纸灯笼', '橘子树', '小船', '石桥'],
  'setT': '设置',
  'planNone': '未订阅',
  'planNoneSub': '随时可开始 7 天免费试用',
  'planTrial': '试用 · 还剩 {n} 天',
  'planTrialSub': '年付计划将于 {d} 开始',
  'setManage': '管理',
  'setLang': '语言',
  'setGoal': '每日目标',
  'setNotif': '通知',
  'setEvening': '晚间报告',
  'setEveningSub': '每天 21:00',
  'setMissed': '“有点想你”',
  'setMissedSub': '最多每天一次，且离开两天后',
  'setAbout': '关于',
  'setRestore': '恢复购买',
  'setPrivacy': '隐私政策',
  'setTerms': '服务条款',
  'setReplay': '重看引导',
  'setPet': '伙伴',
  'setSpecies': '动物',
  'setUsage': '屏幕时间',
  'setUsageOn': '读取每日总时长',
  'setUsageOff': '仅根据专注时段',
  'permUsageGranted': '已开启使用情况访问，宠物心情会跟随屏幕时间。',
  'permUsageDenied': '未授予使用情况访问，请在系统设置中开启。',
  'permIosLimit': '在 iPhone 上，Baru 无法读取屏幕时间，除非获得 Apple 的 Family Controls 授权。正在打开设置。',
  'notifDenied': '请在系统设置中开启通知以接收提醒。',
  'notifWebUnsupported': '通知仅在移动应用中可用。',
  'notifEveningTitle': '晚间报告',
  'notifEveningBody': '{n} 准备好了今天的总结。',
  'notifMissedTitle': '有点想你',
  'notifMissedBody': '{n} 今天有点想你。来一次短专注吧。',
  'setUsageHint': '随时可改。数据不离开你的设备。',
  'animalNames': {
    'capybara': '水豚',
    'otter': '水獭',
    'tortoise': '乌龟',
    'owl': '猫头鹰',
  },
  'shareMeta': '图片 · 402 × 296',
  'shareNote': '系统分享面板。第一阶段分享栖息地截图。',
  'shareDone': '完成',
  'shareFail': '现在无法分享。请再试一次。',
  'streakOne': '已陪伴 1 天',
  'repFreezeMany': '本周还有 {n} 次冻结。如果你缺一天，它会等你。',
  'privacyBody':
      '如果你允许，Baru 只读取当天的屏幕总时长。不看具体应用，也不看内容。这一阶段数据不离开你的设备。专注时段、叶子和栖息地都留在手机上。这里的订阅是本地试用，商店扣款稍后才会接入。',
  'termsBody':
      '你用 Baru 做专注时段、照料栖息地。它不会死，不会丢掉进度，也不会责怪你。这个版本的 7 天试用不会通过商店扣款。恢复购买只标记本地试用。改语言或目标不会清空栖息地。',
  'tabs': ['栖息地', '商店', '报告', '设置'],
};
