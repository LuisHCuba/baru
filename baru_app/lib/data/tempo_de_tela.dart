/// Contabilidade de tempo de tela.
///
/// O app somava `totalTimeInForeground` de todo pacote que o sistema
/// reportava. Isso conta launcher, system UI e — o caso que quebra a
/// credibilidade inteira — Spotify tocando com o celular no bolso.
///
/// Aqui o tempo é **reconstruído por par de eventos**: só conta o intervalo em
/// que a tela estava ligada, o aparelho desbloqueado e um app contável em
/// primeiro plano.
library;

/// Categoria de produto de um app.
///
/// Não é taxonomia de loja: é o que o app significa para a meta do usuário.
enum CategoriaDeApp {
  /// Rola sozinho e come a hora: social, vídeo curto, jogo.
  dispersivo,

  /// Uso legítimo que ainda é tela: mensagem, navegador, mapa.
  neutro,

  /// Leitura, estudo, trabalho.
  produtivo,

  /// Áudio. Tela ligada com música tocando é tela, mas não é dispersão.
  passivo,
}

/// Tipos de evento do `UsageEvents.Event` do Android.
///
/// Os valores são os inteiros públicos da plataforma; o plugin os entrega como
/// texto. Ficam nomeados aqui para o algoritmo abaixo ser auditável sem abrir
/// a documentação do Android.
class TipoDeEvento {
  const TipoDeEvento._();

  static const atividadeRetomada = 1; // ACTIVITY_RESUMED
  static const atividadePausada = 2; // ACTIVITY_PAUSED
  static const atividadeParada = 23; // ACTIVITY_STOPPED
  static const telaLigada = 15; // SCREEN_INTERACTIVE
  static const telaDesligada = 16; // SCREEN_NON_INTERACTIVE
  static const bloqueioMostrado = 17; // KEYGUARD_SHOWN
  static const bloqueioEscondido = 18; // KEYGUARD_HIDDEN
  static const aparelhoDesligado = 26; // DEVICE_SHUTDOWN
  static const aparelhoLigado = 27; // DEVICE_STARTUP
}

/// Categoria a partir do nome guardado. Nome desconhecido devolve `null`, e
/// quem chama descarta o ajuste em vez de adivinhar.
CategoriaDeApp? categoriaPorNome(String nome) {
  for (final c in CategoriaDeApp.values) {
    if (c.name == nome) return c;
  }
  return null;
}

/// Um evento cru do sistema.
class EventoDeUso {
  const EventoDeUso({
    required this.tipo,
    required this.quando,
    required this.pacote,
  });

  final int tipo;
  final DateTime quando;
  final String pacote;

  @override
  String toString() => 'EventoDeUso($tipo, $pacote, $quando)';
}

/// Um trecho em que um app esteve em primeiro plano, com tela ligada e
/// aparelho desbloqueado.
class IntervaloDeUso {
  const IntervaloDeUso({
    required this.pacote,
    required this.inicio,
    required this.fim,
  });

  final String pacote;
  final DateTime inicio;
  final DateTime fim;

  Duration get duracao => fim.difference(inicio);

  @override
  String toString() => 'IntervaloDeUso($pacote, $inicio -> $fim)';
}

/// Pacotes que nunca contam como tempo de tela do usuário.
///
/// Nenhum deles é "uso": são a moldura do sistema, ou o próprio Baru — contar
/// o tempo que a pessoa passa **no app que mede o tempo** seria absurdo.
class ExclusoesDeContagem {
  const ExclusoesDeContagem({this.proprioPacote = 'com.lhcx.baru_app'});

  final String proprioPacote;

  static const _exatos = {
    'android',
    'com.android.systemui',
    'com.android.settings',
    'com.android.permissioncontroller',
    'com.google.android.permissioncontroller',
    'com.android.intentresolver',
    'com.google.android.packageinstaller',
    'com.android.packageinstaller',
    'com.android.dialer', // discador em chamada
    'com.google.android.dialer',
    'com.samsung.android.incallui',
    'com.android.incallui',
  };

  /// Fragmentos que identificam launcher e teclado em qualquer fabricante.
  static const _fragmentos = [
    'launcher',
    'inputmethod',
    '.ime',
    'honeyboard', // teclado Samsung
    'trebuchet', // launcher LineageOS
    'systemui',
  ];

  bool excluido(String pacote) {
    final p = pacote.toLowerCase();
    if (p == proprioPacote.toLowerCase()) return true;
    if (_exatos.contains(p)) return true;
    for (final f in _fragmentos) {
      if (p.contains(f)) return true;
    }
    return false;
  }
}

/// Classificação embutida dos apps mais comuns.
///
/// O que não estiver aqui entra como [CategoriaDeApp.neutro] — o padrão que
/// menos mente: não acusa o usuário de dispersão que não mediu, nem lhe dá
/// crédito de produtividade que não conferiu.
class ClassificacaoPadrao {
  const ClassificacaoPadrao();

  static const _mapa = <String, CategoriaDeApp>{
    // --- dispersivo -------------------------------------------------------
    'com.instagram.android': CategoriaDeApp.dispersivo,
    'com.zhiliaoapp.musically': CategoriaDeApp.dispersivo, // TikTok
    'com.ss.android.ugc.trill': CategoriaDeApp.dispersivo,
    'com.facebook.katana': CategoriaDeApp.dispersivo,
    'com.facebook.lite': CategoriaDeApp.dispersivo,
    'com.twitter.android': CategoriaDeApp.dispersivo,
    'com.x.android': CategoriaDeApp.dispersivo,
    'com.google.android.youtube': CategoriaDeApp.dispersivo,
    'com.snapchat.android': CategoriaDeApp.dispersivo,
    'com.reddit.frontpage': CategoriaDeApp.dispersivo,
    'com.pinterest': CategoriaDeApp.dispersivo,
    'com.netflix.mediaclient': CategoriaDeApp.dispersivo,
    'tv.twitch.android.app': CategoriaDeApp.dispersivo,
    'com.kwai.video': CategoriaDeApp.dispersivo,
    'com.linkedin.android': CategoriaDeApp.dispersivo,
    'com.shopee.br': CategoriaDeApp.dispersivo,
    'com.mercadolibre': CategoriaDeApp.dispersivo,
    'com.einnovation.temu': CategoriaDeApp.dispersivo,

    // --- neutro -----------------------------------------------------------
    'com.whatsapp': CategoriaDeApp.neutro,
    'com.whatsapp.w4b': CategoriaDeApp.neutro,
    'org.telegram.messenger': CategoriaDeApp.neutro,
    'com.facebook.orca': CategoriaDeApp.neutro,
    'com.google.android.gm': CategoriaDeApp.neutro,
    'com.android.chrome': CategoriaDeApp.neutro,
    'org.mozilla.firefox': CategoriaDeApp.neutro,
    'com.google.android.apps.maps': CategoriaDeApp.neutro,
    'com.google.android.calendar': CategoriaDeApp.neutro,
    'com.google.android.deskclock': CategoriaDeApp.neutro,
    'com.android.camera': CategoriaDeApp.neutro,
    'com.google.android.apps.photos': CategoriaDeApp.neutro,
    'com.nu.production': CategoriaDeApp.neutro,
    'com.itau': CategoriaDeApp.neutro,
    'br.com.bb.android': CategoriaDeApp.neutro,
    'com.ubercab': CategoriaDeApp.neutro,
    'com.ifood.ifood': CategoriaDeApp.neutro,

    // --- produtivo --------------------------------------------------------
    'com.amazon.kindle': CategoriaDeApp.produtivo,
    'com.google.android.apps.docs.editors.docs': CategoriaDeApp.produtivo,
    'com.google.android.apps.docs': CategoriaDeApp.produtivo,
    'notion.id': CategoriaDeApp.produtivo,
    'md.obsidian': CategoriaDeApp.produtivo,
    'com.duolingo': CategoriaDeApp.produtivo,
    'com.anydo': CategoriaDeApp.produtivo,
    'com.todoist': CategoriaDeApp.produtivo,
    'com.microsoft.teams': CategoriaDeApp.produtivo,
    'com.Slack': CategoriaDeApp.produtivo,
    'com.microsoft.office.outlook': CategoriaDeApp.produtivo,

    // --- passivo (áudio) --------------------------------------------------
    'com.spotify.music': CategoriaDeApp.passivo,
    'com.google.android.apps.youtube.music': CategoriaDeApp.passivo,
    'deezer.android.app': CategoriaDeApp.passivo,
    'com.aspiro.tidal': CategoriaDeApp.passivo,
    'com.soundcloud.android': CategoriaDeApp.passivo,
    'com.audible.application': CategoriaDeApp.passivo,
    'com.google.android.apps.podcasts': CategoriaDeApp.passivo,
    'fm.castbox.audiobook.radio.podcast': CategoriaDeApp.passivo,
    'com.apple.android.music': CategoriaDeApp.passivo,
  };

  CategoriaDeApp de(String pacote) =>
      _mapa[pacote] ?? CategoriaDeApp.neutro;

  /// Nomes que a tela mostra. `com.zhiliaoapp.musically` não diz nada a
  /// ninguém; "TikTok" diz.
  static const _nomes = <String, String>{
    'com.instagram.android': 'Instagram',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.ss.android.ugc.trill': 'TikTok',
    'com.facebook.katana': 'Facebook',
    'com.facebook.lite': 'Facebook Lite',
    'com.twitter.android': 'X',
    'com.x.android': 'X',
    'com.google.android.youtube': 'YouTube',
    'com.snapchat.android': 'Snapchat',
    'com.reddit.frontpage': 'Reddit',
    'com.pinterest': 'Pinterest',
    'com.netflix.mediaclient': 'Netflix',
    'tv.twitch.android.app': 'Twitch',
    'com.kwai.video': 'Kwai',
    'com.linkedin.android': 'LinkedIn',
    'com.shopee.br': 'Shopee',
    'com.mercadolibre': 'Mercado Livre',
    'com.einnovation.temu': 'Temu',
    'com.whatsapp': 'WhatsApp',
    'com.whatsapp.w4b': 'WhatsApp Business',
    'org.telegram.messenger': 'Telegram',
    'com.facebook.orca': 'Messenger',
    'com.google.android.gm': 'Gmail',
    'com.android.chrome': 'Chrome',
    'org.mozilla.firefox': 'Firefox',
    'com.google.android.apps.maps': 'Maps',
    'com.google.android.calendar': 'Agenda',
    'com.google.android.deskclock': 'Relógio',
    'com.android.camera': 'Câmera',
    'com.google.android.apps.photos': 'Fotos',
    'com.nu.production': 'Nubank',
    'com.itau': 'Itaú',
    'br.com.bb.android': 'Banco do Brasil',
    'com.ubercab': 'Uber',
    'com.ifood.ifood': 'iFood',
    'com.amazon.kindle': 'Kindle',
    'com.google.android.apps.docs.editors.docs': 'Google Docs',
    'com.google.android.apps.docs': 'Google Drive',
    'notion.id': 'Notion',
    'md.obsidian': 'Obsidian',
    'com.duolingo': 'Duolingo',
    'com.anydo': 'Any.do',
    'com.todoist': 'Todoist',
    'com.microsoft.teams': 'Teams',
    'com.Slack': 'Slack',
    'com.microsoft.office.outlook': 'Outlook',
    'com.spotify.music': 'Spotify',
    'com.google.android.apps.youtube.music': 'YouTube Music',
    'deezer.android.app': 'Deezer',
    'com.aspiro.tidal': 'Tidal',
    'com.soundcloud.android': 'SoundCloud',
    'com.audible.application': 'Audible',
    'com.google.android.apps.podcasts': 'Podcasts',
    'fm.castbox.audiobook.radio.podcast': 'Castbox',
    'com.apple.android.music': 'Apple Music',
  };

  /// Nome legível de um pacote. Desconhecido vira o último segmento com a
  /// primeira letra maiúscula — feio, mas honesto e melhor que o pacote cru.
  String nome(String pacote) {
    final conhecido = _nomes[pacote];
    if (conhecido != null) return conhecido;
    final partes = pacote.split('.');
    final ultimo = partes.isEmpty ? pacote : partes.last;
    if (ultimo.isEmpty) return pacote;
    return ultimo[0].toUpperCase() + ultimo.substring(1);
  }

  /// Quantos apps a tabela embutida conhece.
  static int get conhecidos => _mapa.length;

  static Map<String, CategoriaDeApp> get tabela => Map.unmodifiable(_mapa);
}

/// Reconstrói os intervalos contáveis a partir dos eventos crus.
///
/// Máquina de estados com três chaves: tela ligada, aparelho desbloqueado e
/// app em primeiro plano. Um intervalo só corre quando as três valem.
///
/// Estado inicial é **desligado e bloqueado** de propósito: sem evidência, o
/// algoritmo não conta. Errar para menos é honesto; errar para mais é a
/// mentira que estamos consertando. Quem chama deve pedir eventos de um
/// período anterior ao dia (ver [janelaDeAquecimento]) para que o estado real
/// seja estabelecido antes do recorte.
class ReconstrutorDeUso {
  const ReconstrutorDeUso({
    this.exclusoes = const ExclusoesDeContagem(),
  });

  final ExclusoesDeContagem exclusoes;

  /// Quanto tempo antes do recorte pedir eventos, para descobrir se a tela já
  /// estava ligada quando o dia virou.
  static const janelaDeAquecimento = Duration(hours: 12);

  List<IntervaloDeUso> intervalos(
    List<EventoDeUso> eventos, {
    required DateTime de,
    required DateTime ate,
  }) {
    final ordenados = [...eventos]
      ..sort((a, b) => a.quando.compareTo(b.quando));

    var telaLigada = false;
    var desbloqueado = false;
    String? appAtual;
    DateTime? abertoEm;

    final saida = <IntervaloDeUso>[];

    bool contavel() {
      final app = appAtual;
      return telaLigada && desbloqueado && app != null && !exclusoes.excluido(app);
    }

    void fecha(DateTime quando) {
      final aberto = abertoEm;
      final app = appAtual;
      if (aberto == null || app == null) return;
      final inicio = aberto.isBefore(de) ? de : aberto;
      final fim = quando.isAfter(ate) ? ate : quando;
      if (fim.isAfter(inicio)) {
        saida.add(IntervaloDeUso(pacote: app, inicio: inicio, fim: fim));
      }
      abertoEm = null;
    }

    void abre(DateTime quando) {
      if (!contavel()) return;
      abertoEm = quando;
    }

    for (final e in ordenados) {
      if (e.quando.isAfter(ate)) break;

      final estavaContavel = contavel();
      if (estavaContavel) fecha(e.quando);

      switch (e.tipo) {
        case TipoDeEvento.atividadeRetomada:
          appAtual = e.pacote;
        case TipoDeEvento.atividadePausada:
        case TipoDeEvento.atividadeParada:
          // Só apaga se for o app que estava na frente: em troca rápida, o
          // "pausado" do anterior chega depois do "retomado" do novo.
          if (appAtual == e.pacote) appAtual = null;
        case TipoDeEvento.telaLigada:
          telaLigada = true;
        case TipoDeEvento.telaDesligada:
          telaLigada = false;
        case TipoDeEvento.bloqueioMostrado:
          desbloqueado = false;
        case TipoDeEvento.bloqueioEscondido:
          desbloqueado = true;
          // Desbloquear implica tela acesa, mesmo que o evento de tela não
          // tenha vindo — acontece em alguns fabricantes.
          telaLigada = true;
        case TipoDeEvento.aparelhoDesligado:
          telaLigada = false;
          desbloqueado = false;
          appAtual = null;
        case TipoDeEvento.aparelhoLigado:
          telaLigada = false;
          desbloqueado = false;
          appAtual = null;
      }

      abre(e.quando);
    }

    // O último trecho ainda estava aberto quando a consulta terminou.
    if (contavel() && abertoEm != null) fecha(ate);

    return saida;
  }
}

/// O que o usuário vê: total, quebra por categoria e por app.
class ResumoDeTela {
  const ResumoDeTela({
    required this.porApp,
    required this.porCategoria,
  });

  const ResumoDeTela.vazio()
      : porApp = const {},
        porCategoria = const {};

  final Map<String, Duration> porApp;
  final Map<CategoriaDeApp, Duration> porCategoria;

  Duration _cat(CategoriaDeApp c) => porCategoria[c] ?? Duration.zero;

  Duration get dispersivo => _cat(CategoriaDeApp.dispersivo);
  Duration get neutro => _cat(CategoriaDeApp.neutro);
  Duration get produtivo => _cat(CategoriaDeApp.produtivo);
  Duration get passivo => _cat(CategoriaDeApp.passivo);

  /// Tudo que passou na tela.
  Duration get total =>
      porCategoria.values.fold(Duration.zero, (a, b) => a + b);

  /// **O que a meta compara.** Passivo e produtivo ficam de fora: ouvir
  /// música ou ler não é o que o usuário quer reduzir.
  Duration get contabilizado => dispersivo + neutro;

  int get minutosContabilizados => contabilizado.inMinutes;
  int get minutosTotais => total.inMinutes;

  bool get vazio => porApp.isEmpty;

  /// Apps do maior para o menor tempo.
  List<MapEntry<String, Duration>> get appsPorTempo {
    final l = porApp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return l;
  }
}

/// Junta reconstrução e classificação.
class ContabilidadeDeTela {
  const ContabilidadeDeTela({
    this.reconstrutor = const ReconstrutorDeUso(),
    this.padrao = const ClassificacaoPadrao(),
  });

  final ReconstrutorDeUso reconstrutor;
  final ClassificacaoPadrao padrao;

  /// [ajustes] são as reclassificações que o usuário fez à mão; elas ganham
  /// da tabela embutida.
  ResumoDeTela resumo(
    List<EventoDeUso> eventos, {
    required DateTime de,
    required DateTime ate,
    Map<String, CategoriaDeApp> ajustes = const {},
  }) {
    final intervalos = reconstrutor.intervalos(eventos, de: de, ate: ate);
    final porApp = <String, Duration>{};
    final porCategoria = <CategoriaDeApp, Duration>{};

    for (final i in intervalos) {
      porApp[i.pacote] = (porApp[i.pacote] ?? Duration.zero) + i.duracao;
    }
    for (final e in porApp.entries) {
      final c = categoriaDe(e.key, ajustes);
      porCategoria[c] = (porCategoria[c] ?? Duration.zero) + e.value;
    }
    return ResumoDeTela(porApp: porApp, porCategoria: porCategoria);
  }

  CategoriaDeApp categoriaDe(
    String pacote,
    Map<String, CategoriaDeApp> ajustes,
  ) =>
      ajustes[pacote] ?? padrao.de(pacote);
}
