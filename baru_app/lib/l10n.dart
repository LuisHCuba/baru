import 'models.dart';

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

  /// O título de uma pergunta do quiz, pelo id estável.
  String perguntaDoQuiz(String id) =>
      '${(_m['quizPerguntas'] as Map)[id] ?? id}';

  /// O rótulo de uma opção, pelo id estável.
  String opcaoDoQuiz(String id) => '${(_m['quizOpcoes'] as Map)[id] ?? id}';
  /// Nomes dos itens da loja, **na ordem de `shopItems`**.
  ///
  /// `items` tinha oito nomes e a loja passou a ter dezessete: indexar por
  /// posição de `shopItems` estourava a lista. Use [nomeDoItem], que resolve
  /// pelo id e nunca sai da faixa.
  List<String> get items => List<String>.from(_m['items'] as List);

  String nomeDoItem(String id, List<String> ordemDosIds) {
    final i = ordemDosIds.indexOf(id);
    final nomes = itemNames;
    return i < 0 || i >= nomes.length ? id : nomes[i];
  }
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
  String get quizVoltar => s('quizVoltar');
  String get revealTrocar => s('revealTrocar');
  String get contaApagar => s('contaApagar');
  String get contaApagarSub => s('contaApagarSub');
  String get contaApagarConfirma => s('contaApagarConfirma');
  String get contaApagarBotao => s('contaApagarBotao');
  String get contaApagarOk => s('contaApagarOk');
  String get contaApagarFalhou => s('contaApagarFalhou');
  String get contaApagarCancelar => s('contaApagarCancelar');
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
  String get notifTrialTitle => s('notifTrialTitle');
  String get notifTrialBody => s('notifTrialBody');
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
  String get syncSchemaFail => s('syncSchemaFail');

  /// O pronome do companheiro, em minúscula e com inicial maiúscula.
  ///
  /// Em português e espanhol isto é gramática: "ele te esperou" e "ela te
  /// esperou" são frases diferentes. Em inglês o neutro serve para os três;
  /// em chinês o pronome não aparece nessas frases.
  String pronome(Sexo sexo) {
    final m = _m['pronome'] as Map;
    return m[sexo.name] as String;
  }

  /// Preenche `{p}` e `{P}` com o pronome do companheiro, junto do resto.
  String comPronome(
    String texto,
    Sexo sexo, [
    Map<String, Object> vars = const {},
  ]) {
    final p = pronome(sexo);
    final capital =
        p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}';
    final d = (_m['possessivo'] as Map)[sexo.name] as String;
    return fill(texto, {...vars, 'p': p, 'P': capital, 'd': d});
  }
  String get folhasT => s('folhasT');
  String get folhasSub => s('folhasSub');
  String get folhasDeOnde => s('folhasDeOnde');
  String get folhasSessoes => s('folhasSessoes');
  String get folhasMarcos => s('folhasMarcos');
  String get folhasMissoes => s('folhasMissoes');
  String get folhasGasto => s('folhasGasto');
  String get folhasNota => s('folhasNota');
  String get folhasUltimas => s('folhasUltimas');
  String get folhasVaziaT => s('folhasVaziaT');
  String get folhasVaziaB => s('folhasVaziaB');
  String get folhasProximo => s('folhasProximo');
  String get folhasVerLoja => s('folhasVerLoja');
  String get folhasPodeComprar => s('folhasPodeComprar');
  String get setSexo => s('setSexo');
  String get setSexoNao => s('setSexoNao');
  String get setSexoM => s('setSexoM');
  String get setSexoF => s('setSexoF');
  String get setHorario => s('setHorario');
  String get setHorarioSub => s('setHorarioSub');
  String get setMetaLivre => s('setMetaLivre');
  String get setMetaAjuda => s('setMetaAjuda');
  String get setCompanheiro => s('setCompanheiro');
  String get setSecoes => s('setSecoes');
  String get setDuracao => s('setDuracao');
  String get setSom => s('setSom');
  String get setSomSub => s('setSomSub');
  String get trilhaAqui => s('trilhaAqui');
  String get lojaObjetos => s('lojaObjetos');
  String get lojaCenarios => s('lojaCenarios');
  String get lojaRoupas => s('lojaRoupas');
  String get lojaColocar => s('lojaColocar');
  String get lojaTirar => s('lojaTirar');
  String get lojaEmUso => s('lojaEmUso');
  String get lojaFalta => s('lojaFalta');
  String get lojaSubObjetos => s('lojaSubObjetos');
  String get lojaSubCenarios => s('lojaSubCenarios');
  String get lojaSubRoupas => s('lojaSubRoupas');
  List<String> get itemNames => List<String>.from(_m['itemNames'] as List);
  String get sobreT => s('sobreT');
  String get sobreSub => s('sobreSub');
  String get sobreLigar => s('sobreLigar');
  String get sobreLigado => s('sobreLigado');
  String get sobreDesligado => s('sobreDesligado');
  String get sobreComo => s('sobreComo');
  String get sobrePreview => s('sobrePreview');
  String get sobreFechar => s('sobreFechar');
  String get sobreMais => s('sobreMais');
  String get sobreFala1 => s('sobreFala1');
  String get sobreFala2 => s('sobreFala2');
  String get sobreFala3 => s('sobreFala3');
  String get sobreSoAndroid => s('sobreSoAndroid');
  String get contaT => s('contaT');
  String get contaSub => s('contaSub');
  String get contaEmail => s('contaEmail');
  String get contaEmailNaoConfirmado => s('contaEmailNaoConfirmado');
  String get contaTrocarEmail => s('contaTrocarEmail');
  String get contaTrocarEmailAviso => s('contaTrocarEmailAviso');
  String get contaSenha => s('contaSenha');
  String get contaTrocarSenha => s('contaTrocarSenha');
  String get contaRecuperar => s('contaRecuperar');
  String get contaRecuperarOk => s('contaRecuperarOk');
  String get contaEmailInvalido => s('contaEmailInvalido');
  String get contaSenhaCurta => s('contaSenhaCurta');
  String get contaSemConta => s('contaSemConta');
  String get contaDesde => s('contaDesde');
  String get contaPlano => s('contaPlano');
  String get contaSalvar => s('contaSalvar');
  String get contaOk => s('contaOk');
  String get contaNovoEmail => s('contaNovoEmail');
  String get contaNovaSenha => s('contaNovaSenha');
  String get sairT => s('sairT');
  String get sairB => s('sairB');
  String get sairFicar => s('sairFicar');
  String get sairSair => s('sairSair');
  String get seqT => s('seqT');
  String get seqSub => s('seqSub');
  String get seqAtual => s('seqAtual');
  String get seqMelhor => s('seqMelhor');
  String get seqCongelamentos => s('seqCongelamentos');
  String get seqCongelamentoAjuda => s('seqCongelamentoAjuda');
  String get seqSemana => s('seqSemana');
  String get seqSessoes => s('seqSessoes');
  String get seqDiasAbaixo => s('seqDiasAbaixo');
  String get seqProximo => s('seqProximo');
  String get seqVaziaT => s('seqVaziaT');
  String get seqVaziaB => s('seqVaziaB');
  String get folhasSessaoLinha => s('folhasSessaoLinha');
  String get bootstrapOffline => s('bootstrapOffline');
  String get bonusUnderGoal => s('bonusUnderGoal');
  String get telaT => s('telaT');
  String get telaSub => s('telaSub');
  String get telaTotal => s('telaTotal');
  String get telaContado => s('telaContado');
  String get telaForaDaMeta => s('telaForaDaMeta');
  String get telaVazioT => s('telaVazioT');
  String get telaVazioB => s('telaVazioB');
  String get telaSemPermissaoT => s('telaSemPermissaoT');
  String get telaSemPermissaoB => s('telaSemPermissaoB');
  String get telaPorApp => s('telaPorApp');
  String get telaComoContamos => s('telaComoContamos');
  String get catDispersivo => s('catDispersivo');
  String get catNeutro => s('catNeutro');
  String get catProdutivo => s('catProdutivo');
  String get catPassivo => s('catPassivo');
  String get telaMudarCategoria => s('telaMudarCategoria');
  String get telaMudado => s('telaMudado');
  String get trilhaT => s('trilhaT');
  String get trilhaSub => s('trilhaSub');
  String get trilhaProximo => s('trilhaProximo');
  String get trilhaFeito => s('trilhaFeito');
  String get trilhaAgora => s('trilhaAgora');
  String get trilhaBloqueado => s('trilhaBloqueado');
  String get nivelRotulo => s('nivelRotulo');
  String get nivelFalta => s('nivelFalta');
  String get nivelMax => s('nivelMax');
  String get marcoSessao1 => s('marcoSessao1');
  String get marcoSessoes => s('marcoSessoes');
  String get marcoSequencia => s('marcoSequencia');
  String get marcoNivel => s('marcoNivel');
  String get marcoAbaixo1 => s('marcoAbaixo1');
  String get marcoAbaixo => s('marcoAbaixo');
  String get premioFolhas => s('premioFolhas');
  String get premioEspecie => s('premioEspecie');
  String get premioHabitat => s('premioHabitat');
  String get celebNivel => s('celebNivel');
  String get celebNivelSub => s('celebNivelSub');
  String get celebMarco => s('celebMarco');
  String get trilhaVaziaT => s('trilhaVaziaT');
  String get trilhaVaziaB => s('trilhaVaziaB');
  String get xpRotulo => s('xpRotulo');
  String get vinculoRotulo => s('vinculoRotulo');
  String get vinculoSub => s('vinculoSub');
  String get vinculoTeto => s('vinculoTeto');
  String get missoesT => s('missoesT');
  String get missoesSub => s('missoesSub');
  String get missoesDiarias => s('missoesDiarias');
  String get missoesSemanais => s('missoesSemanais');
  String get missaoResgatar => s('missaoResgatar');
  String get missaoResgatada => s('missaoResgatada');
  String get missaoConcluida => s('missaoConcluida');
  String get missaoPrecisaPermissao => s('missaoPrecisaPermissao');
  String get missaoExpiraHoje => s('missaoExpiraHoje');
  String get missaoExpiraSemana => s('missaoExpiraSemana');
  String get missoesVaziaT => s('missoesVaziaT');
  String get missoesVaziaB => s('missoesVaziaB');
  String get missoesTodasFeitas => s('missoesTodasFeitas');
  String get msSessoes1 => s('msSessoes1');
  String get msSessoes => s('msSessoes');
  String get msMinutos => s('msMinutos');
  String get msSessaoLonga => s('msSessaoLonga');
  String get msAbaixo => s('msAbaixo');
  String get msDispersivo => s('msDispersivo');
  String get msSemanaSessoes => s('msSemanaSessoes');
  String get msSemanaMinutos => s('msSemanaMinutos');
  String get msSemanaAbaixo => s('msSemanaAbaixo');
  String get missaoGanhou => s('missaoGanhou');
  String get notifSessaoTitulo => s('notifSessaoTitulo');
  String get notifSessaoCorpo => s('notifSessaoCorpo');
  String get notifSessaoDesistir => s('notifSessaoDesistir');
  String get notifFimTitulo => s('notifFimTitulo');
  String get notifFimCorpo => s('notifFimCorpo');


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
  'syncFail': 'Não foi possível sincronizar ({q}). Seus dados ficam salvos neste aparelho.',
  'syncSchemaFail': 'O banco na nuvem está desatualizado: falta a tabela {t}. Seus dados ficam salvos neste aparelho.',
  'bootstrapOffline': 'Conta nova ou sem dados remotos — começando habitat vazio.',
  'bonusUnderGoal': 'Ontem você fechou abaixo da meta. +{k} folhas para o habitat.',
  'telaT': 'Seu tempo de tela',
  'telaSub': '{d} de {t} contam para a meta',
  'telaTotal': 'na tela hoje',
  'telaContado': 'conta para a meta',
  'telaForaDaMeta': 'fora da meta',
  'telaVazioT': 'Nada medido ainda hoje',
  'telaVazioB': 'Assim que você usar o celular, o detalhamento aparece aqui.',
  'telaSemPermissaoT': 'Sem acesso ao uso',
  'telaSemPermissaoB': 'Sem a permissão o Baru não estima nem inventa número. Conceda para ver onde seu tempo foi.',
  'telaPorApp': 'Por aplicativo',
  'telaComoContamos': 'Só conta o tempo com a tela ligada e o aparelho desbloqueado. Música com a tela apagada não entra. Leitura e áudio ficam fora da meta.',
  'catDispersivo': 'Dispersivo',
  'catNeutro': 'Neutro',
  'catProdutivo': 'Produtivo',
  'catPassivo': 'Áudio',
  'telaMudarCategoria': 'Mudar categoria',
  'telaMudado': '{a} agora conta como {c}.',
  'trilhaT': 'Sua trilha',
  'trilhaSub': 'Um passo por vez. Nada aqui expira.',
  'trilhaProximo': 'PRÓXIMO PASSO',
  'trilhaFeito': 'Conquistado',
  'trilhaAgora': 'Agora',
  'trilhaBloqueado': 'A caminho',
  'nivelRotulo': 'Nível {n}',
  'contaT': 'Sua conta',
  'contaSub': 'E-mail, senha e plano.',
  'contaEmail': 'E-mail',
  'contaEmailNaoConfirmado': 'ainda não confirmado',
  'contaTrocarEmail': 'Trocar e-mail',
  'contaTrocarEmailAviso': 'Enviamos um link para o endereço novo. O login só muda depois que você clicar nele.',
  'contaSenha': 'Senha',
  'contaTrocarSenha': 'Trocar senha',
  'contaRecuperar': 'Esqueci a senha',
  'contaRecuperarOk': 'Link de recuperação enviado para {e}.',
  'contaEmailInvalido': 'Esse e-mail não parece certo.',
  'contaSenhaCurta': 'A senha precisa de pelo menos 6 caracteres.',
  'contaSemConta': 'Você ainda não tem conta neste aparelho.',
  'contaDesde': 'Companheiro desde',
  'contaPlano': 'Plano',
  'contaSalvar': 'Salvar',
  'contaOk': 'Pronto.',
  'contaNovoEmail': 'Novo e-mail',
  'contaNovaSenha': 'Nova senha',
  'sairT': 'Já vai?',
  'sairB': '{P} fica aqui te esperando. Nada se perde — nem as folhas, nem a sequência, nem o habitat.',
  'sairFicar': 'Ficar mais um pouco',
  'sairSair': 'Sair',
  'setSexo': 'Sexo',
  'setSexoNao': 'Não dizer',
  'setSexoM': 'Macho',
  'setSexoF': 'Fêmea',
  'setHorario': 'Horário do relatório',
  'setHorarioSub': 'A que horas o resumo do dia chega',
  'setMetaLivre': 'Meta de tempo de tela',
  'setMetaAjuda': 'Ajuste de {p} em {p} minutos, entre {a} e {b}.',
  'setCompanheiro': 'Companheiro',
  'setSecoes': 'Ajustes',
  'setDuracao': 'Duração da sessão',
  'setSom': 'Som',
  'trilhaAqui': 'VOCÊ ESTÁ AQUI',
  'lojaObjetos': 'NO HABITAT',
  'lojaCenarios': 'CENÁRIOS',
  'lojaRoupas': 'PARA VESTIR',
  'lojaColocar': 'Colocar',
  'lojaTirar': 'Tirar',
  'lojaEmUso': 'Em uso',
  'lojaFalta': 'Faltam {n}',
  'lojaSubObjetos': 'Coisas que moram na cena. Pode ter todas ao mesmo tempo.',
  'lojaSubCenarios': 'Muda o mundo inteiro. Um por vez.',
  'lojaSubRoupas': 'Uma peça por lugar do corpo.',
  'itemNames': ['Vitórias-régias', 'Bambuzal', 'Pedra da fonte', 'Deque de madeira', 'Lampião', 'Árvore antiga', 'Barquinho', 'Ponte de pedra', 'Chapéu de palha', 'Coroa de folhas', 'Gorro de lã', 'Cachecol', 'Óculos redondos', 'Entardecer', 'Noite estrelada', 'Chuva mansa', 'Neblina da manhã'],
  'sobreT': 'Sobre outros apps',
  'sobreSub': 'Quando o tempo estourar, {n} dá um oi no canto da tela — sem travar nada.',
  'sobreLigar': 'Permitir',
  'sobreLigado': 'Ligado',
  'sobreDesligado': 'Desligado',
  'sobreComo': 'O Android exige que você ligue na tela do sistema. No máximo 4 vezes por dia, com 25 minutos entre uma e outra.',
  'sobrePreview': 'Assim que vai aparecer',
  'sobreFechar': 'Fechar o app',
  'sobreMais': '+5 min',
  'sobreFala1': 'Ei! Já deu um tempão aí. Que tal uma pausinha comigo?',
  'sobreFala2': 'Psiu… o app não vai fugir. Bora respirar um pouco?',
  'sobreFala3': 'Seu tempo de tela de hoje acabou. Sem culpa — só um lembrete de amigo.',
  'sobreSoAndroid': 'Por enquanto só no Android. No iPhone a Apple não deixa um app desenhar por cima de outro.',
  'setSomSub': 'Sons curtos nas conquistas e no toque',
  'pronome': {'naoDito': 'ele', 'macho': 'ele', 'femea': 'ela'},
  'possessivo': {'naoDito': 'dele', 'macho': 'dele', 'femea': 'dela'},
  'folhasT': 'Suas folhas',
  'folhasSub': 'De onde elas vêm e para onde vão.',
  'folhasDeOnde': 'DE ONDE VIERAM',
  'folhasSessoes': 'Sessões de foco',
  'folhasMarcos': 'Marcos da trilha',
  'folhasMissoes': 'Missões resgatadas',
  'folhasGasto': 'NO HABITAT',
  'folhasNota': 'O histórico guarda as últimas 80 sessões, então a soma pode ficar abaixo do saldo.',
  'folhasUltimas': 'ÚLTIMAS QUE VOCÊ GANHOU',
  'folhasVaziaT': 'Nenhuma folha ainda',
  'folhasVaziaB': 'Termine uma sessão de foco e as primeiras folhas caem aqui.',
  'folhasProximo': 'Faltam {x} para {i}',
  'folhasVerLoja': 'Ver a loja',
  'folhasPodeComprar': 'Dá para comprar {i} agora',
  'folhasSessaoLinha': 'Sessão de {m} min',
  'seqT': 'Sua sequência',
  'seqSub': 'Um dia presente é um dia em que você apareceu.',
  'seqAtual': 'SEQUÊNCIA ATUAL',
  'seqMelhor': 'Melhor sequência',
  'seqCongelamentos': 'Congelamentos',
  'seqCongelamentoAjuda': 'Um congelamento salva a sequência num dia em que você faltar. Volta a cada segunda.',
  'seqSemana': 'ESTA SEMANA',
  'seqSessoes': 'Sessões concluídas',
  'seqDiasAbaixo': 'Dias abaixo da meta',
  'seqProximo': 'Faltam {x} dias para {m}',
  'seqVaziaT': 'Sua sequência começa hoje',
  'seqVaziaB': 'Apareça amanhã e ela vira dois.',
  'vinculoRotulo': 'Vínculo',
  'vinculoSub': '{n} afagos',
  'vinculoTeto': '{P} já recebeu carinho de sobra hoje',
  'nivelFalta': '{x} XP para o nível {n}',
  'nivelMax': 'Nível máximo',
  'marcoSessao1': 'Sua primeira sessão de foco',
  'marcoSessoes': '{n} sessões de foco',
  'marcoSequencia': '{n} dias seguidos presente',
  'marcoNivel': 'Chegar ao nível {n}',
  'marcoAbaixo1': 'Fechar um dia abaixo da meta',
  'marcoAbaixo': 'Fechar {n} dias abaixo da meta',
  'premioFolhas': '+{n} folhas',
  'premioEspecie': '{a} entra no habitat',
  'premioHabitat': 'O habitat cresce',
  'celebNivel': 'Nível {n}',
  'celebNivelSub': '{a} está mais em casa.',
  'celebMarco': 'Marco alcançado',
  'trilhaVaziaT': 'A trilha começa amanhã',
  'trilhaVaziaB': 'Termine o onboarding e o primeiro passo aparece aqui.',
  'xpRotulo': 'XP',
  'missoesT': 'Missões',
  'missoesSub': 'Ritmo para hoje, amplitude para a semana.',
  'missoesDiarias': 'HOJE',
  'missoesSemanais': 'ESTA SEMANA',
  'missaoResgatar': 'Resgatar',
  'missaoResgatada': 'Resgatada',
  'missaoConcluida': 'Concluída',
  'missaoPrecisaPermissao': 'Precisa do acesso ao uso',
  'missaoExpiraHoje': 'até meia-noite',
  'missaoExpiraSemana': 'até domingo',
  'missoesVaziaT': 'As missões começam amanhã',
  'missoesVaziaB': 'Termine o onboarding e as três primeiras aparecem aqui.',
  'missoesTodasFeitas': 'Tudo feito por hoje. O próximo passo da trilha te espera.',
  'msSessoes1': 'Faça uma sessão de foco',
  'msSessoes': 'Faça {n} sessões de foco',
  'msMinutos': 'Some {n} min de foco',
  'msSessaoLonga': 'Faça um foco de {n} min',
  'msAbaixo': 'Feche o dia abaixo da meta',
  'msDispersivo': 'Fique abaixo de {n} min em apps dispersivos',
  'msSemanaSessoes': '{n} sessões nesta semana',
  'msSemanaMinutos': '{n} min de foco nesta semana',
  'msSemanaAbaixo': '{n} dias abaixo da meta nesta semana',
  'missaoGanhou': '+{n} folhas',
  'notifSessaoTitulo': '{n} está em foco',
  'notifSessaoCorpo': 'Deixe o telefone de lado. Volte quando acabar.',
  'notifSessaoDesistir': 'Desistir',
  'notifFimTitulo': 'Sessão concluída',
  'notifFimCorpo': '{m} min de foco. +{k} folhas para o habitat.',
  'langTitle': 'Em que idioma você quer falar com ele?',
  'langSub': 'Pode trocar depois nos ajustes.',
  'cont': 'Continuar',
  'start': 'Começar foco',
  'promiseT': 'Deixe o celular de lado. Alguém aqui fica feliz com isso.',
  'promiseB':
      'Você escolhe um animal, define uma meta de tempo de tela e faz sessões de foco. Ele nunca morre, nunca perde nada e nunca te culpa.',
  'quizT': 'Qual animal você é por dentro?',
  'quizB':
      'Seis perguntas rápidas. Suas respostas escolhem o animal que você vai cuidar. Dá para trocar depois.',
  'quizPerguntas': {
    'elemento': 'Com qual elemento você se parece',
    'clareza': 'Quando sua cabeça fica mais clara',
    'acalma': 'O que realmente te acalma',
    'rouba_foco': 'O que mais rouba seu foco',
    'recarrega': 'Como você recarrega',
    'quer': 'O que você quer do Baru',
  },
  'quizOpcoes': {
    'agua': 'Água',
    'fogo': 'Fogo',
    'terra': 'Terra',
    'ar': 'Ar',
    'manha': 'De manhã cedo',
    'tarde': 'À tarde',
    'madrugada': 'De madrugada',
    'varia': 'Depende do dia',
    'agua_quente': 'Água quente',
    'companhia': 'Boa companhia',
    'so_companhia': 'Só companhia',
    'silencio': 'Um quarto silencioso',
    'rotina': 'Uma rotina',
    'redes': 'Redes sociais',
    'videos': 'Vídeos',
    'jogos': 'Jogos',
    'mensagens': 'Mensagens e grupos',
    'sozinho': 'Sozinho, em silêncio',
    'com_gente': 'Com gente que eu gosto',
    'natureza': 'Perto da natureza',
    'dormindo': 'Dormindo',
    'menos_tela': 'Menos tempo de tela',
    'mais_foco': 'Mais foco',
    'uma_rotina': 'Uma rotina que eu mantenha',
  },
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
  'quizWait': 'Faltam {n}',
  'quizVoltar': 'Voltar uma',
  'revealTrocar': 'Prefere outro?',
  'contaApagar': 'Apagar meus dados',
  'contaApagarSub': 'Some com tudo: sessões, folhas, habitat, trilha e respostas. Aqui e no servidor.',
  'contaApagarConfirma': 'Isso não tem volta. Tudo o que você construiu com {n} vai embora, deste aparelho e da nuvem.',
  'contaApagarBotao': 'Apagar tudo',
  'contaApagarCancelar': 'Cancelar',
  'contaApagarOk': 'Pronto. Não sobrou nada.',
  'contaApagarFalhou': 'Não deu para apagar tudo ({q}). Tente de novo.',
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
  'permT': 'O humor do seu companheiro acompanha seu tempo de tela.',
  'permB': 'Para isso, o Baru precisa ler o total do dia no seu telefone.',
  'perm1': 'Só o total do dia. Nunca quais apps, nunca conteúdo.',
  'perm2': 'Lido algumas vezes por dia. Nada sai do aparelho.',
  'perm3': 'Se preferir pular, o Baru lê seu humor só pelas sessões de foco.',
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
    'content': 'Um dia decente. Uma sessão a mais e {p} estaria radiante.',
    'neutral': 'Em cima da meta. Nada para corrigir.',
    'sleepy': 'Dia longo de tela. Amanhã {p} topa nadar.',
    'missing_you':
        '{P} te esperou. Nada foi perdido enquanto você esteve fora.',
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
      'Sem folhas desta vez, e nada foi perdido. {P} continua aqui.',
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
  'setEveningSub': 'Todo dia às {h}',
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
  'notifTrialTitle': 'Seu teste termina amanhã',
  'notifTrialBody': 'Mais 24h de teste. {n} continua aqui de qualquer forma.',
  'setUsageHint': 'Pode mudar quando quiser. Nada sai do aparelho.',
  'animalNames': {
    'capybara': 'Capivara',
    'otter': 'Lontra',
    'tortoise': 'Tartaruga',
    'owl': 'Coruja',
    'axolotl': 'Axolote',
    'penguin': 'Pinguim',
    'cat': 'Gata',
    'fox': 'Raposa',
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
  'tabs': ['Habitat', 'Trilha', 'Missões', 'Ajustes'],
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
  'syncFail': 'Could not sync ({q}). Your data stays saved on this device.',
  'syncSchemaFail': 'The cloud database is out of date: table {t} is missing. Your data stays saved on this device.',
  'bootstrapOffline': 'New account or no remote data — starting with an empty habitat.',
  'bonusUnderGoal': 'You finished yesterday under your goal. +{k} leaves for the habitat.',
  'telaT': 'Your screen time',
  'telaSub': '{d} of {t} count toward your goal',
  'telaTotal': 'on screen today',
  'telaContado': 'counts toward the goal',
  'telaForaDaMeta': 'outside the goal',
  'telaVazioT': 'Nothing measured yet today',
  'telaVazioB': 'As soon as you use your phone, the breakdown shows up here.',
  'telaSemPermissaoT': 'No usage access',
  'telaSemPermissaoB': 'Without the permission Baru will not estimate or invent a number. Grant it to see where your time went.',
  'telaPorApp': 'By app',
  'telaComoContamos': 'Only time with the screen on and the phone unlocked counts. Music with the screen off does not. Reading and audio stay out of the goal.',
  'catDispersivo': 'Distracting',
  'catNeutro': 'Neutral',
  'catProdutivo': 'Productive',
  'catPassivo': 'Audio',
  'telaMudarCategoria': 'Change category',
  'telaMudado': '{a} now counts as {c}.',
  'trilhaT': 'Your path',
  'trilhaSub': 'One step at a time. Nothing here expires.',
  'trilhaProximo': 'NEXT STEP',
  'trilhaFeito': 'Earned',
  'trilhaAgora': 'Now',
  'trilhaBloqueado': 'Ahead',
  'nivelRotulo': 'Level {n}',
  'contaT': 'Your account',
  'contaSub': 'Email, password and plan.',
  'contaEmail': 'Email',
  'contaEmailNaoConfirmado': 'not confirmed yet',
  'contaTrocarEmail': 'Change email',
  'contaTrocarEmailAviso': 'We sent a link to the new address. Sign-in only changes after you click it.',
  'contaSenha': 'Password',
  'contaTrocarSenha': 'Change password',
  'contaRecuperar': 'Forgot password',
  'contaRecuperarOk': 'Recovery link sent to {e}.',
  'contaEmailInvalido': 'That email doesn\'t look right.',
  'contaSenhaCurta': 'Password needs at least 6 characters.',
  'contaSemConta': 'You have no account on this device yet.',
  'contaDesde': 'Companion since',
  'contaPlano': 'Plan',
  'contaSalvar': 'Save',
  'contaOk': 'Done.',
  'contaNovoEmail': 'New email',
  'contaNovaSenha': 'New password',
  'sairT': 'Leaving already?',
  'sairB': '{P} will be right here waiting. Nothing is lost — not the leaves, not the streak, not the habitat.',
  'sairFicar': 'Stay a bit longer',
  'sairSair': 'Leave',
  'setSexo': 'Sex',
  'setSexoNao': 'Prefer not to say',
  'setSexoM': 'Male',
  'setSexoF': 'Female',
  'setHorario': 'Report time',
  'setHorarioSub': 'When the day summary arrives',
  'setMetaLivre': 'Screen time goal',
  'setMetaAjuda': 'Adjust in {p}-minute steps, between {a} and {b}.',
  'setCompanheiro': 'Companion',
  'setSecoes': 'Settings',
  'setDuracao': 'Session length',
  'setSom': 'Sound',
  'trilhaAqui': 'YOU ARE HERE',
  'lojaObjetos': 'IN THE HABITAT',
  'lojaCenarios': 'SCENERY',
  'lojaRoupas': 'TO WEAR',
  'lojaColocar': 'Place',
  'lojaTirar': 'Remove',
  'lojaEmUso': 'In use',
  'lojaFalta': '{n} to go',
  'lojaSubObjetos': 'Things that live in the scene. You can have them all at once.',
  'lojaSubCenarios': 'Changes the whole world. One at a time.',
  'lojaSubRoupas': 'One piece per spot.',
  'itemNames': ['Water lilies', 'Bamboo grove', 'Spring stone', 'Wooden deck', 'Lantern', 'Old tree', 'Little boat', 'Stone bridge', 'Straw hat', 'Leaf crown', 'Wool beanie', 'Scarf', 'Round glasses', 'Sunset', 'Starry night', 'Gentle rain', 'Morning mist'],
  'sobreT': 'Over other apps',
  'sobreSub': 'When time runs out, {n} says hi in the corner — without blocking anything.',
  'sobreLigar': 'Allow',
  'sobreLigado': 'On',
  'sobreDesligado': 'Off',
  'sobreComo': 'Android requires you to turn this on in system settings. At most 4 times a day, 25 minutes apart.',
  'sobrePreview': 'How it will look',
  'sobreFechar': 'Close the app',
  'sobreMais': '+5 min',
  'sobreFala1': 'Hey! That was a long stretch. How about a little break with me?',
  'sobreFala2': 'Psst… the app is not going anywhere. Shall we breathe a bit?',
  'sobreFala3': 'Today\'s screen time is up. No guilt — just a friendly nudge.',
  'sobreSoAndroid': 'Android only for now. On iPhone, Apple does not let an app draw over another.',
  'setSomSub': 'Short sounds on wins and taps',
  'pronome': {'naoDito': 'they', 'macho': 'he', 'femea': 'she'},
  'possessivo': {'naoDito': 'their', 'macho': 'his', 'femea': 'her'},
  'folhasT': 'Your leaves',
  'folhasSub': 'Where they come from and where they go.',
  'folhasDeOnde': 'WHERE THEY CAME FROM',
  'folhasSessoes': 'Focus sessions',
  'folhasMarcos': 'Trail milestones',
  'folhasMissoes': 'Quests claimed',
  'folhasGasto': 'IN THE HABITAT',
  'folhasNota': 'History keeps the last 80 sessions, so the total can fall short of your balance.',
  'folhasUltimas': 'MOST RECENT EARNINGS',
  'folhasVaziaT': 'No leaves yet',
  'folhasVaziaB': 'Finish a focus session and your first leaves land here.',
  'folhasProximo': '{x} to go for {i}',
  'folhasVerLoja': 'Open the shop',
  'folhasPodeComprar': 'You can buy {i} right now',
  'folhasSessaoLinha': '{m} min session',
  'seqT': 'Your streak',
  'seqSub': 'A day present is a day you showed up.',
  'seqAtual': 'CURRENT STREAK',
  'seqMelhor': 'Best streak',
  'seqCongelamentos': 'Freezes',
  'seqCongelamentoAjuda': 'A freeze saves your streak on a day you miss. It comes back every Monday.',
  'seqSemana': 'THIS WEEK',
  'seqSessoes': 'Sessions completed',
  'seqDiasAbaixo': 'Days under goal',
  'seqProximo': '{x} days to go for {m}',
  'seqVaziaT': 'Your streak starts today',
  'seqVaziaB': 'Show up tomorrow and it becomes two.',
  'vinculoRotulo': 'Bond',
  'vinculoSub': '{n} cuddles',
  'vinculoTeto': '{P} have had plenty of love today',
  'nivelFalta': '{x} XP to level {n}',
  'nivelMax': 'Max level',
  'marcoSessao1': 'Your first focus session',
  'marcoSessoes': '{n} focus sessions',
  'marcoSequencia': '{n} days in a row',
  'marcoNivel': 'Reach level {n}',
  'marcoAbaixo1': 'Finish a day under your goal',
  'marcoAbaixo': 'Finish {n} days under your goal',
  'premioFolhas': '+{n} leaves',
  'premioEspecie': '{a} joins the habitat',
  'premioHabitat': 'The habitat grows',
  'celebNivel': 'Level {n}',
  'celebNivelSub': '{a} feels more at home.',
  'celebMarco': 'Milestone reached',
  'trilhaVaziaT': 'The path starts tomorrow',
  'trilhaVaziaB': 'Finish onboarding and the first step shows up here.',
  'xpRotulo': 'XP',
  'missoesT': 'Missions',
  'missoesSub': 'Rhythm for today, breadth for the week.',
  'missoesDiarias': 'TODAY',
  'missoesSemanais': 'THIS WEEK',
  'missaoResgatar': 'Claim',
  'missaoResgatada': 'Claimed',
  'missaoConcluida': 'Done',
  'missaoPrecisaPermissao': 'Needs usage access',
  'missaoExpiraHoje': 'until midnight',
  'missaoExpiraSemana': 'until Sunday',
  'missoesVaziaT': 'Missions start tomorrow',
  'missoesVaziaB': 'Finish onboarding and the first three show up here.',
  'missoesTodasFeitas': 'All done for today. The next step on your path is waiting.',
  'msSessoes1': 'Do one focus session',
  'msSessoes': 'Do {n} focus sessions',
  'msMinutos': 'Add up {n} min of focus',
  'msSessaoLonga': 'Do a {n} min focus session',
  'msAbaixo': 'Finish the day under your goal',
  'msDispersivo': 'Stay under {n} min in distracting apps',
  'msSemanaSessoes': '{n} sessions this week',
  'msSemanaMinutos': '{n} min of focus this week',
  'msSemanaAbaixo': '{n} days under your goal this week',
  'missaoGanhou': '+{n} leaves',
  'notifSessaoTitulo': '{n} is focusing',
  'notifSessaoCorpo': 'Put the phone down. Come back when it ends.',
  'notifSessaoDesistir': 'Give up',
  'notifFimTitulo': 'Session complete',
  'notifFimCorpo': '{m} min of focus. +{k} leaves for the habitat.',
  'langTitle': 'Which language should we speak?',
  'langSub': 'You can change it later in settings.',
  'cont': 'Continue',
  'start': 'Start focus',
  'promiseT': 'Put the phone down. Someone here is glad about it.',
  'promiseB':
      'You pick an animal, set a screen-time goal, and run focus sessions. It never dies, never loses anything, and never blames you.',
  'quizT': 'Which animal are you on the inside?',
  'quizB':
      'Six quick questions. Your answers pick the animal you will look after. You can change it later.',
  'quizPerguntas': {
    'elemento': 'Which element feels like you',
    'clareza': 'When your head is clearest',
    'acalma': 'What actually calms you',
    'rouba_foco': 'What steals your focus most',
    'recarrega': 'How you recharge',
    'quer': 'What you want from Baru',
  },
  'quizOpcoes': {
    'agua': 'Water',
    'fogo': 'Fire',
    'terra': 'Earth',
    'ar': 'Air',
    'manha': 'Early morning',
    'tarde': 'Afternoon',
    'madrugada': 'Late at night',
    'varia': 'Depends on the day',
    'agua_quente': 'Warm water',
    'companhia': 'Good company',
    'so_companhia': 'Just company',
    'silencio': 'A quiet room',
    'rotina': 'A routine',
    'redes': 'Social media',
    'videos': 'Videos',
    'jogos': 'Games',
    'mensagens': 'Messages and groups',
    'sozinho': 'Alone, in silence',
    'com_gente': 'With people I like',
    'natureza': 'Close to nature',
    'dormindo': 'Sleeping',
    'menos_tela': 'Less screen time',
    'mais_foco': 'More focus',
    'uma_rotina': 'A routine I keep',
  },
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
  'quizWait': '{n} to go',
  'quizVoltar': 'Back one',
  'revealTrocar': 'Prefer another?',
  'contaApagar': 'Delete my data',
  'contaApagarSub': 'Wipes everything: sessions, leaves, habitat, trail and answers. Here and on the server.',
  'contaApagarConfirma': 'There is no undo. Everything you built with {n} goes, from this device and from the cloud.',
  'contaApagarBotao': 'Delete everything',
  'contaApagarCancelar': 'Cancel',
  'contaApagarOk': 'Done. Nothing left.',
  'contaApagarFalhou': 'Could not delete everything ({q}). Try again.',
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
    'content': 'A decent day. One more session and {p} would be beaming.',
    'neutral': 'Right around your goal. Nothing to fix.',
    'sleepy': 'A long screen day. Tomorrow {p} is up for a swim.',
    'missing_you': '{P} waited for you. Nothing was lost while you were gone.',
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
      'No leaves this time, and nothing taken away. {P} is still here.',
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
  'setEveningSub': 'Every day at {h}',
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
  'notifTrialTitle': 'Your trial ends tomorrow',
  'notifTrialBody': '24h of trial left. {n} stays here either way.',
  'setUsageHint': 'Change any time. Nothing leaves your device.',
  'animalNames': {
    'capybara': 'Capybara',
    'otter': 'Otter',
    'tortoise': 'Tortoise',
    'owl': 'Owl',
    'axolotl': 'Axolotl',
    'penguin': 'Penguin',
    'cat': 'Cat',
    'fox': 'Fox',
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
  'tabs': ['Habitat', 'Path', 'Missions', 'Settings'],
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
  'syncFail': 'No se pudo sincronizar ({q}). Tus datos quedan guardados en este dispositivo.',
  'syncSchemaFail': 'La base en la nube está desactualizada: falta la tabla {t}. Tus datos quedan guardados en este dispositivo.',
  'bootstrapOffline': 'Cuenta nueva o sin datos remotos: empezamos con un hábitat vacío.',
  'bonusUnderGoal': 'Ayer cerraste por debajo de tu meta. +{k} hojas para el hábitat.',
  'telaT': 'Tu tiempo de pantalla',
  'telaSub': '{d} de {t} cuentan para la meta',
  'telaTotal': 'en pantalla hoy',
  'telaContado': 'cuenta para la meta',
  'telaForaDaMeta': 'fuera de la meta',
  'telaVazioT': 'Nada medido aún hoy',
  'telaVazioB': 'En cuanto uses el móvil, el desglose aparece aquí.',
  'telaSemPermissaoT': 'Sin acceso al uso',
  'telaSemPermissaoB': 'Sin el permiso Baru no estima ni inventa un número. Concédelo para ver a dónde fue tu tiempo.',
  'telaPorApp': 'Por aplicación',
  'telaComoContamos': 'Solo cuenta el tiempo con la pantalla encendida y el móvil desbloqueado. La música con la pantalla apagada no entra. Lectura y audio quedan fuera de la meta.',
  'catDispersivo': 'Dispersivo',
  'catNeutro': 'Neutro',
  'catProdutivo': 'Productivo',
  'catPassivo': 'Audio',
  'telaMudarCategoria': 'Cambiar categoría',
  'telaMudado': '{a} ahora cuenta como {c}.',
  'trilhaT': 'Tu camino',
  'trilhaSub': 'Un paso a la vez. Nada aquí caduca.',
  'trilhaProximo': 'SIGUIENTE PASO',
  'trilhaFeito': 'Conseguido',
  'trilhaAgora': 'Ahora',
  'trilhaBloqueado': 'Por venir',
  'nivelRotulo': 'Nivel {n}',
  'contaT': 'Tu cuenta',
  'contaSub': 'Correo, contraseña y plan.',
  'contaEmail': 'Correo',
  'contaEmailNaoConfirmado': 'aún sin confirmar',
  'contaTrocarEmail': 'Cambiar correo',
  'contaTrocarEmailAviso': 'Enviamos un enlace a la dirección nueva. El acceso solo cambia después de que hagas clic.',
  'contaSenha': 'Contraseña',
  'contaTrocarSenha': 'Cambiar contraseña',
  'contaRecuperar': 'Olvidé la contraseña',
  'contaRecuperarOk': 'Enlace de recuperación enviado a {e}.',
  'contaEmailInvalido': 'Ese correo no parece correcto.',
  'contaSenhaCurta': 'La contraseña necesita al menos 6 caracteres.',
  'contaSemConta': 'Todavía no tienes cuenta en este dispositivo.',
  'contaDesde': 'Compañero desde',
  'contaPlano': 'Plan',
  'contaSalvar': 'Guardar',
  'contaOk': 'Listo.',
  'contaNovoEmail': 'Nuevo correo',
  'contaNovaSenha': 'Nueva contraseña',
  'sairT': '¿Ya te vas?',
  'sairB': '{P} se queda aquí esperándote. Nada se pierde: ni las hojas, ni la racha, ni el hábitat.',
  'sairFicar': 'Quedarme un poco más',
  'sairSair': 'Salir',
  'setSexo': 'Sexo',
  'setSexoNao': 'Prefiero no decir',
  'setSexoM': 'Macho',
  'setSexoF': 'Hembra',
  'setHorario': 'Hora del informe',
  'setHorarioSub': 'Cuándo llega el resumen del día',
  'setMetaLivre': 'Meta de tiempo de pantalla',
  'setMetaAjuda': 'Ajuste de {p} en {p} minutos, entre {a} y {b}.',
  'setCompanheiro': 'Compañero',
  'setSecoes': 'Ajustes',
  'setDuracao': 'Duración de la sesión',
  'setSom': 'Sonido',
  'trilhaAqui': 'ESTÁS AQUÍ',
  'lojaObjetos': 'EN EL HÁBITAT',
  'lojaCenarios': 'ESCENARIOS',
  'lojaRoupas': 'PARA VESTIR',
  'lojaColocar': 'Poner',
  'lojaTirar': 'Quitar',
  'lojaEmUso': 'En uso',
  'lojaFalta': 'Faltan {n}',
  'lojaSubObjetos': 'Cosas que viven en la escena. Puedes tenerlas todas a la vez.',
  'lojaSubCenarios': 'Cambia el mundo entero. Uno a la vez.',
  'lojaSubRoupas': 'Una pieza por lugar.',
  'itemNames': ['Nenúfares', 'Bambudal', 'Piedra del manantial', 'Muelle de madera', 'Farol', 'Árbol antiguo', 'Barquito', 'Puente de piedra', 'Sombrero de paja', 'Corona de hojas', 'Gorro de lana', 'Bufanda', 'Gafas redondas', 'Atardecer', 'Noche estrellada', 'Lluvia suave', 'Niebla de la mañana'],
  'sobreT': 'Sobre otras apps',
  'sobreSub': 'Cuando el tiempo se acabe, {n} saluda en la esquina — sin bloquear nada.',
  'sobreLigar': 'Permitir',
  'sobreLigado': 'Activado',
  'sobreDesligado': 'Desactivado',
  'sobreComo': 'Android exige activarlo en los ajustes del sistema. Máximo 4 veces al día, con 25 minutos entre una y otra.',
  'sobrePreview': 'Así se verá',
  'sobreFechar': 'Cerrar la app',
  'sobreMais': '+5 min',
  'sobreFala1': '¡Ey! Ya fue un buen rato. ¿Y si hacemos una pausita?',
  'sobreFala2': 'Psst… la app no se va a escapar. ¿Respiramos un poco?',
  'sobreFala3': 'Tu tiempo de pantalla de hoy se acabó. Sin culpa — solo un recordatorio de amigo.',
  'sobreSoAndroid': 'Por ahora solo en Android. En iPhone, Apple no permite que una app dibuje sobre otra.',
  'setSomSub': 'Sonidos cortos en logros y toques',
  'pronome': {'naoDito': 'él', 'macho': 'él', 'femea': 'ella'},
  'possessivo': {'naoDito': 'de él', 'macho': 'de él', 'femea': 'de ella'},
  'folhasT': 'Tus hojas',
  'folhasSub': 'De dónde vienen y adónde van.',
  'folhasDeOnde': 'DE DÓNDE VINIERON',
  'folhasSessoes': 'Sesiones de enfoque',
  'folhasMarcos': 'Hitos del camino',
  'folhasMissoes': 'Misiones reclamadas',
  'folhasGasto': 'EN EL HÁBITAT',
  'folhasNota': 'El historial guarda las últimas 80 sesiones, así que la suma puede quedar por debajo del saldo.',
  'folhasUltimas': 'LO ÚLTIMO QUE GANASTE',
  'folhasVaziaT': 'Todavía no hay hojas',
  'folhasVaziaB': 'Termina una sesión de enfoque y las primeras hojas caen aquí.',
  'folhasProximo': 'Faltan {x} para {i}',
  'folhasVerLoja': 'Ver la tienda',
  'folhasPodeComprar': 'Ya puedes comprar {i}',
  'folhasSessaoLinha': 'Sesión de {m} min',
  'seqT': 'Tu racha',
  'seqSub': 'Un día presente es un día en que apareciste.',
  'seqAtual': 'RACHA ACTUAL',
  'seqMelhor': 'Mejor racha',
  'seqCongelamentos': 'Congelaciones',
  'seqCongelamentoAjuda': 'Una congelación salva la racha un día que faltes. Vuelve cada lunes.',
  'seqSemana': 'ESTA SEMANA',
  'seqSessoes': 'Sesiones completadas',
  'seqDiasAbaixo': 'Días bajo la meta',
  'seqProximo': 'Faltan {x} días para {m}',
  'seqVaziaT': 'Tu racha empieza hoy',
  'seqVaziaB': 'Aparece mañana y serán dos.',
  'vinculoRotulo': 'Vínculo',
  'vinculoSub': '{n} mimos',
  'vinculoTeto': '{P} ya recibió cariño de sobra hoy',
  'nivelFalta': '{x} XP para el nivel {n}',
  'nivelMax': 'Nivel máximo',
  'marcoSessao1': 'Tu primera sesión de enfoque',
  'marcoSessoes': '{n} sesiones de enfoque',
  'marcoSequencia': '{n} días seguidos',
  'marcoNivel': 'Llegar al nivel {n}',
  'marcoAbaixo1': 'Cerrar un día bajo tu meta',
  'marcoAbaixo': 'Cerrar {n} días bajo tu meta',
  'premioFolhas': '+{n} hojas',
  'premioEspecie': '{a} entra en el hábitat',
  'premioHabitat': 'El hábitat crece',
  'celebNivel': 'Nivel {n}',
  'celebNivelSub': '{a} se siente más en casa.',
  'celebMarco': 'Hito alcanzado',
  'trilhaVaziaT': 'El camino empieza mañana',
  'trilhaVaziaB': 'Termina el onboarding y el primer paso aparece aquí.',
  'xpRotulo': 'XP',
  'missoesT': 'Misiones',
  'missoesSub': 'Ritmo para hoy, amplitud para la semana.',
  'missoesDiarias': 'HOY',
  'missoesSemanais': 'ESTA SEMANA',
  'missaoResgatar': 'Reclamar',
  'missaoResgatada': 'Reclamada',
  'missaoConcluida': 'Hecha',
  'missaoPrecisaPermissao': 'Necesita acceso al uso',
  'missaoExpiraHoje': 'hasta medianoche',
  'missaoExpiraSemana': 'hasta el domingo',
  'missoesVaziaT': 'Las misiones empiezan mañana',
  'missoesVaziaB': 'Termina el onboarding y las tres primeras aparecen aquí.',
  'missoesTodasFeitas': 'Todo hecho por hoy. El siguiente paso del camino te espera.',
  'msSessoes1': 'Haz una sesión de enfoque',
  'msSessoes': 'Haz {n} sesiones de enfoque',
  'msMinutos': 'Suma {n} min de enfoque',
  'msSessaoLonga': 'Haz un enfoque de {n} min',
  'msAbaixo': 'Cierra el día bajo tu meta',
  'msDispersivo': 'Quédate bajo {n} min en apps dispersivas',
  'msSemanaSessoes': '{n} sesiones esta semana',
  'msSemanaMinutos': '{n} min de enfoque esta semana',
  'msSemanaAbaixo': '{n} días bajo tu meta esta semana',
  'missaoGanhou': '+{n} hojas',
  'notifSessaoTitulo': '{n} está enfocado',
  'notifSessaoCorpo': 'Deja el móvil. Vuelve cuando termine.',
  'notifSessaoDesistir': 'Rendirse',
  'notifFimTitulo': 'Sesión completada',
  'notifFimCorpo': '{m} min de enfoque. +{k} hojas para el hábitat.',
  'langTitle': '¿En qué idioma quieres hablarle?',
  'langSub': 'Puedes cambiarlo después en ajustes.',
  'cont': 'Continuar',
  'start': 'Empezar enfoque',
  'promiseT': 'Deja el móvil. Aquí alguien se alegra.',
  'promiseB':
      'Eliges un animal, defines una meta de tiempo de pantalla y haces sesiones de enfoque. Nunca muere, nunca pierde nada y nunca te culpa.',
  'quizT': '¿Qué animal eres por dentro?',
  'quizB':
      'Seis preguntas rápidas. Tus respuestas eligen el animal que vas a cuidar. Puedes cambiarlo después.',
  'quizPerguntas': {
    'elemento': 'Con qué elemento te pareces',
    'clareza': 'Cuándo tu cabeza está más clara',
    'acalma': 'Qué te calma de verdad',
    'rouba_foco': 'Qué te roba más el foco',
    'recarrega': 'Cómo recargas',
    'quer': 'Qué quieres de Baru',
  },
  'quizOpcoes': {
    'agua': 'Agua',
    'fogo': 'Fuego',
    'terra': 'Tierra',
    'ar': 'Aire',
    'manha': 'Temprano',
    'tarde': 'Por la tarde',
    'madrugada': 'De madrugada',
    'varia': 'Depende del día',
    'agua_quente': 'Agua caliente',
    'companhia': 'Buena compañía',
    'so_companhia': 'Solo compañía',
    'silencio': 'Un cuarto en silencio',
    'rotina': 'Una rutina',
    'redes': 'Redes sociales',
    'videos': 'Videos',
    'jogos': 'Juegos',
    'mensagens': 'Mensajes y grupos',
    'sozinho': 'Solo, en silencio',
    'com_gente': 'Con gente que quiero',
    'natureza': 'Cerca de la naturaleza',
    'dormindo': 'Durmiendo',
    'menos_tela': 'Menos tiempo de pantalla',
    'mais_foco': 'Más foco',
    'uma_rotina': 'Una rutina que mantenga',
  },
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
  'quizWait': 'Faltan {n}',
  'quizVoltar': 'Volver una',
  'revealTrocar': '¿Prefieres otro?',
  'contaApagar': 'Borrar mis datos',
  'contaApagarSub': 'Borra todo: sesiones, hojas, hábitat, camino y respuestas. Aquí y en el servidor.',
  'contaApagarConfirma': 'Esto no tiene vuelta. Todo lo que construiste con {n} se va, de este dispositivo y de la nube.',
  'contaApagarBotao': 'Borrar todo',
  'contaApagarCancelar': 'Cancelar',
  'contaApagarOk': 'Listo. No quedó nada.',
  'contaApagarFalhou': 'No se pudo borrar todo ({q}). Inténtalo de nuevo.',
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
    'content': 'Un día decente. Una sesión más y {p} estaría radiante.',
    'neutral': 'Justo en la meta. Nada que corregir.',
    'sleepy': 'Día largo de pantalla. Mañana {p} se anima a nadar.',
    'missing_you':
        '{P} te esperó. Nada se perdió mientras estuviste fuera.',
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
  'resLostSub': 'Sin hojas esta vez, y nada se perdió. {P} sigue aquí.',
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
  'setEveningSub': 'Todos los días a las {h}',
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
  'notifTrialTitle': 'Tu prueba termina mañana',
  'notifTrialBody': 'Quedan 24 h de prueba. {n} sigue aquí de todos modos.',
  'setUsageHint': 'Puedes cambiarlo cuando quieras. Nada sale del dispositivo.',
  'animalNames': {
    'capybara': 'Carpincho',
    'otter': 'Nutria',
    'tortoise': 'Tortuga',
    'owl': 'Búho',
    'axolotl': 'Ajolote',
    'penguin': 'Pingüino',
    'cat': 'Gata',
    'fox': 'Zorro',
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
  'tabs': ['Hábitat', 'Camino', 'Misiones', 'Ajustes'],
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
  'syncFail': '同步失败（{q}）。你的数据已保存在本机。',
  'syncSchemaFail': '云端数据库版本过旧：缺少数据表 {t}。你的数据已保存在本机。',
  'bootstrapOffline': '新账号或没有云端数据 — 从空的栖息地开始。',
  'bonusUnderGoal': '昨天你的用时低于目标。栖息地 +{k} 片叶子。',
  'telaT': '你的屏幕时间',
  'telaSub': '{t} 中有 {d} 计入目标',
  'telaTotal': '今天的屏幕时间',
  'telaContado': '计入目标',
  'telaForaDaMeta': '不计入目标',
  'telaVazioT': '今天还没有测量到',
  'telaVazioB': '你开始使用手机后，明细就会出现在这里。',
  'telaSemPermissaoT': '没有使用权限',
  'telaSemPermissaoB': '没有权限，Baru 不会估算也不会编造数字。授权后即可看到时间去了哪里。',
  'telaPorApp': '按应用',
  'telaComoContamos': '只统计屏幕点亮且已解锁的时间。息屏听音乐不计入。阅读和音频不计入目标。',
  'catDispersivo': '分心',
  'catNeutro': '中性',
  'catProdutivo': '高效',
  'catPassivo': '音频',
  'telaMudarCategoria': '更改类别',
  'telaMudado': '{a} 现在按{c}计算。',
  'trilhaT': '你的路径',
  'trilhaSub': '一步一步来。这里的一切都不会过期。',
  'trilhaProximo': '下一步',
  'trilhaFeito': '已达成',
  'trilhaAgora': '现在',
  'trilhaBloqueado': '即将到来',
  'nivelRotulo': '等级 {n}',
  'contaT': '你的账号',
  'contaSub': '邮箱、密码与套餐。',
  'contaEmail': '邮箱',
  'contaEmailNaoConfirmado': '尚未验证',
  'contaTrocarEmail': '更换邮箱',
  'contaTrocarEmailAviso': '我们已向新邮箱发送链接。点击之后登录邮箱才会更改。',
  'contaSenha': '密码',
  'contaTrocarSenha': '更改密码',
  'contaRecuperar': '忘记密码',
  'contaRecuperarOk': '找回链接已发送至 {e}。',
  'contaEmailInvalido': '这个邮箱看起来不对。',
  'contaSenhaCurta': '密码至少需要 6 个字符。',
  'contaSemConta': '这台设备上还没有账号。',
  'contaDesde': '相伴自',
  'contaPlano': '套餐',
  'contaSalvar': '保存',
  'contaOk': '好了。',
  'contaNovoEmail': '新邮箱',
  'contaNovaSenha': '新密码',
  'sairT': '这就走了？',
  'sairB': '{P}会在这里等你。什么都不会丢——叶子、连续天数、栖息地，都还在。',
  'sairFicar': '再待一会儿',
  'sairSair': '退出',
  'setSexo': '性别',
  'setSexoNao': '不想说',
  'setSexoM': '雄性',
  'setSexoF': '雌性',
  'setHorario': '报告时间',
  'setHorarioSub': '每日总结的送达时间',
  'setMetaLivre': '屏幕时间目标',
  'setMetaAjuda': '以 {p} 分钟为一档，范围 {a} 到 {b}。',
  'setCompanheiro': '伙伴',
  'setSecoes': '设置',
  'setDuracao': '专注时长',
  'setSom': '声音',
  'trilhaAqui': '你在这里',
  'lojaObjetos': '栖息地',
  'lojaCenarios': '场景',
  'lojaRoupas': '穿戴',
  'lojaColocar': '放置',
  'lojaTirar': '取下',
  'lojaEmUso': '使用中',
  'lojaFalta': '还差 {n}',
  'lojaSubObjetos': '住在场景里的东西，可以同时拥有。',
  'lojaSubCenarios': '改变整个世界，一次一个。',
  'lojaSubRoupas': '每个部位一件。',
  'itemNames': ['睡莲', '竹林', '泉边石', '木栈道', '灯笼', '老树', '小船', '石桥', '草帽', '叶冠', '毛线帽', '围巾', '圆框眼镜', '黄昏', '星夜', '细雨', '晨雾'],
  'sobreT': '显示在其他应用之上',
  'sobreSub': '时间用完时，{n} 会在屏幕角落打个招呼——不会挡住任何操作。',
  'sobreLigar': '允许',
  'sobreLigado': '已开启',
  'sobreDesligado': '已关闭',
  'sobreComo': 'Android 要求你在系统设置里开启。每天最多 4 次，间隔 25 分钟。',
  'sobrePreview': '显示效果预览',
  'sobreFechar': '关闭该应用',
  'sobreMais': '+5 分钟',
  'sobreFala1': '嘿！已经看了好一会儿了。要不要和我一起歇一下？',
  'sobreFala2': '嘘……应用不会跑掉。一起喘口气好吗？',
  'sobreFala3': '今天的屏幕时间用完了。别自责——只是朋友的提醒。',
  'sobreSoAndroid': '目前仅支持 Android。在 iPhone 上，苹果不允许应用覆盖其他应用。',
  'setSomSub': '成就与轻触时的短音效',
  'pronome': {'naoDito': '它', 'macho': '它', 'femea': '它'},
  'possessivo': {'naoDito': '它的', 'macho': '它的', 'femea': '它的'},
  'folhasT': '你的叶子',
  'folhasSub': '它们从哪来，又去了哪。',
  'folhasDeOnde': '来源',
  'folhasSessoes': '专注时段',
  'folhasMarcos': '旅程里程碑',
  'folhasMissoes': '已领取的任务',
  'folhasGasto': '花在栖息地',
  'folhasNota': '历史只保留最近 80 次专注，所以合计可能低于余额。',
  'folhasUltimas': '最近的收入',
  'folhasVaziaT': '还没有叶子',
  'folhasVaziaB': '完成一次专注，第一批叶子就会落在这里。',
  'folhasProximo': '距离{i}还差 {x}',
  'folhasVerLoja': '去商店',
  'folhasPodeComprar': '现在就能买{i}',
  'folhasSessaoLinha': '{m} 分钟专注',
  'seqT': '你的连续天数',
  'seqSub': '出现的每一天，都算一天。',
  'seqAtual': '当前连续',
  'seqMelhor': '最佳连续',
  'seqCongelamentos': '冻结次数',
  'seqCongelamentoAjuda': '冻结可以在你缺席的那天保住连续。每周一恢复。',
  'seqSemana': '本周',
  'seqSessoes': '已完成专注',
  'seqDiasAbaixo': '低于目标的天数',
  'seqProximo': '距离{m}还差 {x} 天',
  'seqVaziaT': '你的连续从今天开始',
  'seqVaziaB': '明天再来，就是两天。',
  'vinculoRotulo': '羁绊',
  'vinculoSub': '{n} 次抚摸',
  'vinculoTeto': '今天{P}已经收获了满满的爱',
  'nivelFalta': '还差 {x} XP 到等级 {n}',
  'nivelMax': '已满级',
  'marcoSessao1': '你的第一次专注',
  'marcoSessoes': '{n} 次专注',
  'marcoSequencia': '连续 {n} 天',
  'marcoNivel': '达到等级 {n}',
  'marcoAbaixo1': '有一天低于目标',
  'marcoAbaixo': '有 {n} 天低于目标',
  'premioFolhas': '+{n} 片叶子',
  'premioEspecie': '{a} 加入栖息地',
  'premioHabitat': '栖息地成长了',
  'celebNivel': '等级 {n}',
  'celebNivelSub': '{a} 更有家的感觉了。',
  'celebMarco': '达成里程碑',
  'trilhaVaziaT': '路径明天开始',
  'trilhaVaziaB': '完成引导后，第一步就会出现在这里。',
  'xpRotulo': 'XP',
  'missoesT': '任务',
  'missoesSub': '今天有节奏，本周有广度。',
  'missoesDiarias': '今天',
  'missoesSemanais': '本周',
  'missaoResgatar': '领取',
  'missaoResgatada': '已领取',
  'missaoConcluida': '已完成',
  'missaoPrecisaPermissao': '需要使用权限',
  'missaoExpiraHoje': '到午夜',
  'missaoExpiraSemana': '到周日',
  'missoesVaziaT': '任务明天开始',
  'missoesVaziaB': '完成引导后，前三个任务会出现在这里。',
  'missoesTodasFeitas': '今天都完成了。路径上的下一步在等你。',
  'msSessoes1': '完成一次专注',
  'msSessoes': '完成 {n} 次专注',
  'msMinutos': '累计 {n} 分钟专注',
  'msSessaoLonga': '完成一次 {n} 分钟的专注',
  'msAbaixo': '今天的用时低于目标',
  'msDispersivo': '分心应用少于 {n} 分钟',
  'msSemanaSessoes': '本周 {n} 次专注',
  'msSemanaMinutos': '本周 {n} 分钟专注',
  'msSemanaAbaixo': '本周 {n} 天低于目标',
  'missaoGanhou': '+{n} 片叶子',
  'notifSessaoTitulo': '{n} 正在专注',
  'notifSessaoCorpo': '把手机放下，结束后再回来。',
  'notifSessaoDesistir': '放弃',
  'notifFimTitulo': '专注完成',
  'notifFimCorpo': '专注 {m} 分钟。栖息地 +{k} 片叶子。',
  'langTitle': '你想用哪种语言？',
  'langSub': '之后可以在设置里更改。',
  'cont': '继续',
  'start': '开始专注',
  'promiseT': '放下手机。这里有人会因此开心。',
  'promiseB': '选一只动物，设定每日屏幕时间目标，开始专注时段。它不会死，不会丢东西，也不会责怪你。',
  'quizT': '你内心是哪种动物？',
  'quizB': '三个问题。答案决定你要照顾的动物，之后可以更改。',
  'quizPerguntas': {
    'elemento': '你更像哪种元素',
    'clareza': '什么时候头脑最清醒',
    'acalma': '什么真正让你平静',
    'rouba_foco': '什么最常偷走你的专注',
    'recarrega': '你怎么充电',
    'quer': '你想从 Baru 得到什么',
  },
  'quizOpcoes': {
    'agua': '水',
    'fogo': '火',
    'terra': '土',
    'ar': '风',
    'manha': '清晨',
    'tarde': '下午',
    'madrugada': '深夜',
    'varia': '看当天',
    'agua_quente': '温水',
    'companhia': '好的陪伴',
    'so_companhia': '只要陪伴',
    'silencio': '安静的房间',
    'rotina': '固定的节奏',
    'redes': '社交软件',
    'videos': '视频',
    'jogos': '游戏',
    'mensagens': '消息和群聊',
    'sozinho': '独处，安静',
    'com_gente': '和喜欢的人在一起',
    'natureza': '靠近自然',
    'dormindo': '睡觉',
    'menos_tela': '更少的屏幕时间',
    'mais_foco': '更专注',
    'uma_rotina': '能坚持的节奏',
  },
  'quizQ': ['你星座的元素', '什么时候头脑最清醒', '什么真的能让你平静'],
  'quizO': [
    ['水', '火', '土', '风'],
    ['清晨', '下午', '深夜', '看当天'],
    ['温水', '有人陪', '安静的房间', '固定的节奏'],
  ],
  'quizCta': '看看你的动物',
  'quizWait': '还差 {n} 个',
  'quizVoltar': '返回上一题',
  'revealTrocar': '想换一个？',
  'contaApagar': '删除我的数据',
  'contaApagarSub': '清空全部：专注记录、叶子、栖息地、旅程和答案。本机和服务器都清。',
  'contaApagarConfirma': '无法撤销。你和{n}一起建立的一切都会消失，本机和云端都是。',
  'contaApagarBotao': '全部删除',
  'contaApagarCancelar': '取消',
  'contaApagarOk': '完成，什么都没剩下。',
  'contaApagarFalhou': '没能全部删除（{q}）。请再试一次。',
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
    'content': '还不错的一天。再来一次专注，{p}就会神采飞扬。',
    'neutral': '刚好在目标附近。没什么要改的。',
    'sleepy': '屏幕时间很长的一天。明天{p}还愿意去游泳。',
    'missing_you': '{P}一直在等你。你离开的时候，什么都没有丢。',
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
  'resLostSub': '这次没有叶子，但也没有任何损失。{P}还在。',
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
  'setEveningSub': '每天 {h}',
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
  'notifTrialTitle': '你的试用明天结束',
  'notifTrialBody': '试用还剩 24 小时。无论如何，{n} 都在这里。',
  'setUsageHint': '随时可改。数据不离开你的设备。',
  'animalNames': {
    'capybara': '水豚',
    'otter': '水獭',
    'tortoise': '乌龟',
    'owl': '猫头鹰',
    'axolotl': '六角恐龙',
    'penguin': '企鹅',
    'cat': '猫',
    'fox': '狐狸',
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
  'tabs': ['栖息地', '路径', '任务', '设置'],
};
