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

/// A família de um app, para o companheiro ter o que dizer.
///
/// Não é a categoria: a categoria decide o que entra na meta, a família
/// decide **a frase**. "O YouTube de novo?" e "mais um vídeo e você volta,
/// né?" são falas diferentes porque vídeo longo e vídeo curto prendem a
/// pessoa de jeitos diferentes — e era esse o pedido: a fala varia com o
/// app, não é a mesma frase com o nome trocado.
///
/// Quem não tem família cai na fala genérica. Uma família a mais aqui custa
/// uma frase nova em quatro idiomas, então só entra quando a diferença é
/// real.
enum FamiliaDeApp {
  /// Rolagem infinita de vídeo curto: TikTok, Kwai.
  videoCurto,

  /// "Só mais um vídeo": YouTube.
  videoLongo,

  /// Feed e perfil: Instagram, Facebook, X.
  social,

  /// Fio atrás de fio: Reddit, Quora.
  forum,

  /// Episódio atrás de episódio: Netflix, Twitch.
  streaming,

  /// Partida atrás de partida.
  jogo,

  /// Vitrine sem fim: Shopee, Temu.
  compras,

  /// Conversa. Entra pela fala, não pela meta — mensagem continua neutro no
  /// contrato de produto (§8).
  mensagem,
}

/// Um app que a tabela embutida conhece.
///
/// Nome, categoria e família num registro só. Antes eram dois mapas
/// paralelos (categoria e nome) e a terceira dimensão viraria um terceiro:
/// três listas para manter em sincronia à mão é onde nasce o app que tem
/// categoria e não tem nome.
class AppConhecido {
  const AppConhecido(this.nome, this.categoria, [this.familia]);

  final String nome;
  final CategoriaDeApp categoria;

  /// `null` quando o companheiro não tem nada de específico a dizer sobre
  /// ele — banco, câmera, relógio. Aí vale a fala genérica.
  final FamiliaDeApp? familia;
}

/// Classificação embutida dos apps mais comuns.
///
/// O que não estiver aqui entra como [CategoriaDeApp.neutro] — o padrão que
/// menos mente: não acusa o usuário de dispersão que não mediu, nem lhe dá
/// crédito de produtividade que não conferiu.
///
/// **Os identificadores de pacote não foram conferidos num aparelho.** Um id
/// errado não quebra nada: o app simplesmente não casa, cai no padrão neutro
/// e recebe o nome derivado do último segmento. Errar aqui custa uma
/// classificação a menos, nunca um número errado.
class ClassificacaoPadrao {
  const ClassificacaoPadrao();

  static const _catalogo = <String, AppConhecido>{
    // --- vídeo curto ------------------------------------------------------
    'com.zhiliaoapp.musically': AppConhecido(
        'TikTok', CategoriaDeApp.dispersivo, FamiliaDeApp.videoCurto),
    'com.ss.android.ugc.trill': AppConhecido(
        'TikTok', CategoriaDeApp.dispersivo, FamiliaDeApp.videoCurto),
    'com.ss.android.ugc.aweme': AppConhecido(
        'Douyin', CategoriaDeApp.dispersivo, FamiliaDeApp.videoCurto),
    'com.kwai.video':
        AppConhecido('Kwai', CategoriaDeApp.dispersivo, FamiliaDeApp.videoCurto),
    'com.smile.gifmaker': AppConhecido(
        'Kuaishou', CategoriaDeApp.dispersivo, FamiliaDeApp.videoCurto),

    // --- vídeo longo ------------------------------------------------------
    'com.google.android.youtube': AppConhecido(
        'YouTube', CategoriaDeApp.dispersivo, FamiliaDeApp.videoLongo),

    // --- social -----------------------------------------------------------
    'com.instagram.android': AppConhecido(
        'Instagram', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.instagram.lite': AppConhecido(
        'Instagram Lite', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.instagram.barcelona': AppConhecido(
        'Threads', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.facebook.katana': AppConhecido(
        'Facebook', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.facebook.lite': AppConhecido(
        'Facebook Lite', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.twitter.android':
        AppConhecido('X', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.x.android':
        AppConhecido('X', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.snapchat.android': AppConhecido(
        'Snapchat', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.pinterest': AppConhecido(
        'Pinterest', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.linkedin.android': AppConhecido(
        'LinkedIn', CategoriaDeApp.dispersivo, FamiliaDeApp.social),
    'com.tumblr':
        AppConhecido('Tumblr', CategoriaDeApp.dispersivo, FamiliaDeApp.social),

    // --- fórum ------------------------------------------------------------
    'com.reddit.frontpage':
        AppConhecido('Reddit', CategoriaDeApp.dispersivo, FamiliaDeApp.forum),
    'com.quora.android':
        AppConhecido('Quora', CategoriaDeApp.dispersivo, FamiliaDeApp.forum),

    // --- streaming --------------------------------------------------------
    'com.netflix.mediaclient': AppConhecido(
        'Netflix', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),
    'tv.twitch.android.app': AppConhecido(
        'Twitch', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),
    'com.disney.disneyplus': AppConhecido(
        'Disney+', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),
    'com.amazon.avod.thirdpartyclient': AppConhecido(
        'Prime Video', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),
    'com.hbo.hbonow':
        AppConhecido('Max', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),
    'com.globo.globotv': AppConhecido(
        'Globoplay', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),
    'com.crunchyroll.crunchyroid': AppConhecido(
        'Crunchyroll', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),
    'com.google.android.videos': AppConhecido(
        'Google TV', CategoriaDeApp.dispersivo, FamiliaDeApp.streaming),

    // --- jogos ------------------------------------------------------------
    'com.dts.freefireth':
        AppConhecido('Free Fire', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.dts.freefiremax': AppConhecido(
        'Free Fire MAX', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.roblox.client':
        AppConhecido('Roblox', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.supercell.clashroyale': AppConhecido(
        'Clash Royale', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.supercell.clashofclans': AppConhecido(
        'Clash of Clans', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.supercell.brawlstars': AppConhecido(
        'Brawl Stars', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.king.candycrushsaga': AppConhecido(
        'Candy Crush', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.mojang.minecraftpe': AppConhecido(
        'Minecraft', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.activision.callofduty.shooter': AppConhecido(
        'Call of Duty Mobile', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.tencent.ig': AppConhecido(
        'PUBG Mobile', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.mobile.legends': AppConhecido(
        'Mobile Legends', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.miniclip.eightballpool': AppConhecido(
        '8 Ball Pool', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.ea.gp.fifamobile': AppConhecido(
        'EA FC Mobile', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.riotgames.league.wildrift': AppConhecido(
        'Wild Rift', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.innersloth.spacemafia': AppConhecido(
        'Among Us', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.playrix.homescapes': AppConhecido(
        'Homescapes', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.playrix.gardenscapes': AppConhecido(
        'Gardenscapes', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.nianticlabs.pokemongo': AppConhecido(
        'Pokémon GO', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),
    'com.epicgames.fortnite': AppConhecido(
        'Fortnite', CategoriaDeApp.dispersivo, FamiliaDeApp.jogo),

    // --- compras ----------------------------------------------------------
    'com.shopee.br':
        AppConhecido('Shopee', CategoriaDeApp.dispersivo, FamiliaDeApp.compras),
    'com.mercadolibre': AppConhecido(
        'Mercado Livre', CategoriaDeApp.dispersivo, FamiliaDeApp.compras),
    'com.einnovation.temu':
        AppConhecido('Temu', CategoriaDeApp.dispersivo, FamiliaDeApp.compras),
    'com.alibaba.aliexpresshd': AppConhecido(
        'AliExpress', CategoriaDeApp.dispersivo, FamiliaDeApp.compras),
    'com.zzkko':
        AppConhecido('SHEIN', CategoriaDeApp.dispersivo, FamiliaDeApp.compras),
    'com.amazon.mShop.android.shopping': AppConhecido(
        'Amazon', CategoriaDeApp.dispersivo, FamiliaDeApp.compras),

    // --- mensagem ---------------------------------------------------------
    // Neutro na meta — o contrato de produto §8 põe mensagem em neutro, e
    // mudar isso exige ADR, não um turno de sobreposição. Mas com fala
    // própria: o pedido citava Telegram, e quem sai do foco para responder
    // alguém merece uma frase que não o trate como disperso.
    'com.whatsapp':
        AppConhecido('WhatsApp', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'com.whatsapp.w4b': AppConhecido(
        'WhatsApp Business', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'org.telegram.messenger':
        AppConhecido('Telegram', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'org.thunderdog.challegram': AppConhecido(
        'Telegram X', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'com.facebook.orca':
        AppConhecido('Messenger', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'com.discord':
        AppConhecido('Discord', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'com.google.android.apps.messaging': AppConhecido(
        'Mensagens', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'com.samsung.android.messaging': AppConhecido(
        'Mensagens Samsung', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'com.viber.voip':
        AppConhecido('Viber', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'jp.naver.line.android':
        AppConhecido('LINE', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),
    'com.tencent.mm':
        AppConhecido('WeChat', CategoriaDeApp.neutro, FamiliaDeApp.mensagem),

    // --- neutro -----------------------------------------------------------
    'com.google.android.gm': AppConhecido('Gmail', CategoriaDeApp.neutro),
    'com.android.chrome': AppConhecido('Chrome', CategoriaDeApp.neutro),
    'org.mozilla.firefox': AppConhecido('Firefox', CategoriaDeApp.neutro),
    'com.microsoft.emmx': AppConhecido('Edge', CategoriaDeApp.neutro),
    'com.opera.browser': AppConhecido('Opera', CategoriaDeApp.neutro),
    'com.brave.browser': AppConhecido('Brave', CategoriaDeApp.neutro),
    'com.sec.android.app.sbrowser':
        AppConhecido('Samsung Internet', CategoriaDeApp.neutro),
    'com.google.android.googlequicksearchbox':
        AppConhecido('Google', CategoriaDeApp.neutro),
    'com.google.android.apps.maps': AppConhecido('Maps', CategoriaDeApp.neutro),
    'com.waze': AppConhecido('Waze', CategoriaDeApp.neutro),
    'com.google.android.calendar':
        AppConhecido('Agenda', CategoriaDeApp.neutro),
    'com.google.android.deskclock':
        AppConhecido('Relógio', CategoriaDeApp.neutro),
    'com.android.camera': AppConhecido('Câmera', CategoriaDeApp.neutro),
    'com.google.android.apps.photos':
        AppConhecido('Fotos', CategoriaDeApp.neutro),
    'com.google.android.apps.translate':
        AppConhecido('Tradutor', CategoriaDeApp.neutro),
    'com.android.vending': AppConhecido('Play Store', CategoriaDeApp.neutro),
    'com.nu.production': AppConhecido('Nubank', CategoriaDeApp.neutro),
    'com.itau': AppConhecido('Itaú', CategoriaDeApp.neutro),
    'br.com.bb.android':
        AppConhecido('Banco do Brasil', CategoriaDeApp.neutro),
    'com.bradesco': AppConhecido('Bradesco', CategoriaDeApp.neutro),
    'com.picpay': AppConhecido('PicPay', CategoriaDeApp.neutro),
    'com.mercadopago.wallet':
        AppConhecido('Mercado Pago', CategoriaDeApp.neutro),
    'com.ubercab': AppConhecido('Uber', CategoriaDeApp.neutro),
    'com.ubercab.eats': AppConhecido('Uber Eats', CategoriaDeApp.neutro),
    'com.ifood.ifood': AppConhecido('iFood', CategoriaDeApp.neutro),

    // --- produtivo --------------------------------------------------------
    'com.amazon.kindle': AppConhecido('Kindle', CategoriaDeApp.produtivo),
    'com.google.android.apps.docs.editors.docs':
        AppConhecido('Google Docs', CategoriaDeApp.produtivo),
    'com.google.android.apps.docs.editors.sheets':
        AppConhecido('Google Planilhas', CategoriaDeApp.produtivo),
    'com.google.android.apps.docs':
        AppConhecido('Google Drive', CategoriaDeApp.produtivo),
    'com.google.android.keep':
        AppConhecido('Google Keep', CategoriaDeApp.produtivo),
    'notion.id': AppConhecido('Notion', CategoriaDeApp.produtivo),
    'md.obsidian': AppConhecido('Obsidian', CategoriaDeApp.produtivo),
    'com.evernote': AppConhecido('Evernote', CategoriaDeApp.produtivo),
    'com.duolingo': AppConhecido('Duolingo', CategoriaDeApp.produtivo),
    'com.anydo': AppConhecido('Any.do', CategoriaDeApp.produtivo),
    'com.todoist': AppConhecido('Todoist', CategoriaDeApp.produtivo),
    'com.microsoft.teams': AppConhecido('Teams', CategoriaDeApp.produtivo),
    'com.Slack': AppConhecido('Slack', CategoriaDeApp.produtivo),
    'com.microsoft.office.outlook':
        AppConhecido('Outlook', CategoriaDeApp.produtivo),
    'com.microsoft.office.word': AppConhecido('Word', CategoriaDeApp.produtivo),
    'com.microsoft.office.excel':
        AppConhecido('Excel', CategoriaDeApp.produtivo),
    'us.zoom.videomeetings': AppConhecido('Zoom', CategoriaDeApp.produtivo),
    'com.google.android.apps.tachyon':
        AppConhecido('Google Meet', CategoriaDeApp.produtivo),
    'com.google.android.apps.classroom':
        AppConhecido('Google Sala de Aula', CategoriaDeApp.produtivo),
    'com.khanacademy.android':
        AppConhecido('Khan Academy', CategoriaDeApp.produtivo),
    'com.coursera.android': AppConhecido('Coursera', CategoriaDeApp.produtivo),
    'com.udemy.android': AppConhecido('Udemy', CategoriaDeApp.produtivo),
    'com.dropbox.android': AppConhecido('Dropbox', CategoriaDeApp.produtivo),
    'com.adobe.reader':
        AppConhecido('Adobe Acrobat', CategoriaDeApp.produtivo),
    'com.github.android': AppConhecido('GitHub', CategoriaDeApp.produtivo),

    // --- passivo (áudio) --------------------------------------------------
    'com.spotify.music': AppConhecido('Spotify', CategoriaDeApp.passivo),
    'com.spotify.lite': AppConhecido('Spotify Lite', CategoriaDeApp.passivo),
    'com.google.android.apps.youtube.music':
        AppConhecido('YouTube Music', CategoriaDeApp.passivo),
    'deezer.android.app': AppConhecido('Deezer', CategoriaDeApp.passivo),
    'com.aspiro.tidal': AppConhecido('Tidal', CategoriaDeApp.passivo),
    'com.soundcloud.android':
        AppConhecido('SoundCloud', CategoriaDeApp.passivo),
    'com.audible.application': AppConhecido('Audible', CategoriaDeApp.passivo),
    'com.google.android.apps.podcasts':
        AppConhecido('Podcasts', CategoriaDeApp.passivo),
    'fm.castbox.audiobook.radio.podcast':
        AppConhecido('Castbox', CategoriaDeApp.passivo),
    'com.apple.android.music':
        AppConhecido('Apple Music', CategoriaDeApp.passivo),
    'com.amazon.mp3': AppConhecido('Amazon Music', CategoriaDeApp.passivo),
    'com.pandora.android': AppConhecido('Pandora', CategoriaDeApp.passivo),
    'tunein.player': AppConhecido('TuneIn', CategoriaDeApp.passivo),
  };

  CategoriaDeApp de(String pacote) =>
      _catalogo[pacote]?.categoria ?? CategoriaDeApp.neutro;

  /// A família do app, ou `null` quando ele não tem fala própria.
  FamiliaDeApp? familia(String pacote) => _catalogo[pacote]?.familia;

  /// Nome legível de um pacote. Desconhecido vira o último segmento com a
  /// primeira letra maiúscula — feio, mas honesto e melhor que o pacote cru.
  String nome(String pacote) {
    final conhecido = _catalogo[pacote]?.nome;
    if (conhecido != null) return conhecido;
    final partes = pacote.split('.');
    final ultimo = partes.isEmpty ? pacote : partes.last;
    if (ultimo.isEmpty) return pacote;
    return ultimo[0].toUpperCase() + ultimo.substring(1);
  }

  /// Quantos apps a tabela embutida conhece.
  static int get conhecidos => _catalogo.length;

  static final Map<String, CategoriaDeApp> tabela = Map.unmodifiable(
    _catalogo.map((p, a) => MapEntry(p, a.categoria)),
  );

  /// Os pacotes com fala própria. É a partir daqui que se monta o mapa
  /// pacote→fala que viaja para o vigia.
  static final List<String> comFala = _ordenadosPorNome(
    _catalogo.keys.where((p) => _catalogo[p]!.familia != null),
  );

  /// O catálogo inteiro, ordenado pelo nome que a pessoa lê — ela procura
  /// "TikTok", não `com.zhiliaoapp.musically`.
  ///
  /// A tela de permissões lista isto para a pessoa poder discordar da
  /// classificação de um app que ela **ainda não abriu hoje**. Sem isso, só
  /// dava para reclassificar o que já tinha aparecido no relatório do dia.
  static final List<String> porNome = _ordenadosPorNome(_catalogo.keys);

  static List<String> _ordenadosPorNome(Iterable<String> pacotes) =>
      pacotes.toList()
        ..sort((a, b) => _catalogo[a]!.nome.compareTo(_catalogo[b]!.nome));
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
