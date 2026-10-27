/// O motor de vida do bicho: o que faz ele parecer vivo, quadro a quadro.
///
/// **Por que existe.** O bicho era um conjunto de laços de período fixo —
/// respiração 3,4 s, boia 4,7 s, cauda 2,6 s — e cada quadro era função do
/// relógio. O dono do produto viu na hora: "o mesmo movimento a cada
/// milésimo de segundo", "engessado", "sem fluidez". Laço não vive.
///
/// **Como funciona.** Um único passo por quadro ([passo]) integra, em
/// camadas (docs/pesquisa/21-animacao-fluida.md):
///
/// 1. **Ruído** para o ocioso: a respiração muda de ritmo e de fundura; o
///    peso troca de pé; a cauda ora abana, ora descansa. Nada se repete.
/// 2. **Olhar em dois tempos**: o olho **salta** para o alvo (uma sacada dura
///    dezenas de ms) e a cabeça vem atrás, devagar, só com o que o olho não
///    cobre. Piscadas com intervalo log-normal, amarradas às trocas grandes
///    de olhar — piscar só no relógio "pareceu robótico" até no Rive.
/// 3. **Molas** para tudo que tem massa: achatar ao pousar, esticar no ar,
///    o corpo pendurado pelo dedo, a cauda que atrasa.
/// 4. **Física** de salto e queda, com gravidade.
/// 5. **Um cérebro** ([_decide]) que escolhe o que fazer por pesos, tempo
///    de espera e hora do dia — e é interrompido por qualquer toque.
/// 6. **Reações** (docs/pesquisa/20-interacao-com-o-bicho.md): cutucões em
///    escalada (susto, cócegas, bufo, emburrar), toque no nariz que às vezes
///    vira espirro, carinho com zona favorita e zona que ele não gosta,
///    carinho rápido demais que ele esquiva.
///
/// O motor não desenha nada: entrega números ([SaidaDaVida]) e eventos
/// ([EventoDaVida]) que o pintor do bicho aplica. Assim o mesmo desenho das
/// nove espécies ganha vida sem ser redesenhado.
library;

import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'dinamica.dart';

/// O que o bicho está fazendo por conta própria.
enum IntencaoDoBicho {
  /// Parado, respirando, olhando por aí.
  estar,

  /// Olhando de um ponto a outro, com a cabeça acompanhando.
  observar,

  /// Indo para outro lugar do habitat, em pulinhos.
  passear,

  /// Cabeça baixa, cheirando o chão, passinhos curtos.
  farejar,

  /// Olha para a pessoa, inclina a cabeça, espera.
  chamar,

  /// Sentado, respirando fundo, piscando devagar.
  descansar,

  /// Pulinhos de alegria no lugar.
  festejar,
}

/// Algo que o desenho faz uma vez, com a coreografia que já tem.
enum EventoDaVida {
  /// Sacudir o corpo (depois de cair do colo, depois de um espirro).
  sacode,

  /// Espreguiçar (de manhã, depois de descansar).
  espreguica,

  /// Coçar.
  coca,
}

/// Onde o dedo está no corpo, para o carinho.
enum ZonaDoCorpo { cabeca, costas, barriga, nariz }

/// Uma coisa do habitat que prende a atenção dele.
enum TipoDeInteresse { bola, comida }

/// O jeito de perseguir de cada espécie (pesquisa 20, mecânica 9: o cão
/// corre direto; o gato encara, rebola e dá o bote).
class JeitoDeCacar {
  const JeitoDeCacar({this.espreita = 0, this.velocidade = 44});

  /// Segundos parado rebolando antes do bote (0 = vai direto).
  final double espreita;

  /// Andando, em unidades do desenho por segundo. Correndo atrás de alguma
  /// coisa, quase o dobro.
  final double velocidade;
}

/// Onde está a coisa, em unidades do desenho relativas ao repouso do corpo.
class InteresseDoBicho {
  const InteresseDoBicho(
    this.onde,
    this.tipo, {
    this.noAr = false,
    this.convite = false,
  });

  final Offset onde;
  final TipoDeInteresse tipo;

  /// É ele quem quer brincar (pesquisa 20, mecânica 7): olha para a pessoa,
  /// vai até a bola, empurra para ela e fica esperando.
  final bool convite;

  /// Sendo arrastada pelo dedo: ele olha e quer, mas não vai buscar.
  final bool noAr;
}

/// Os números de um quadro. Tudo em unidades do desenho do bicho (a caixa de
/// 200 × 150 em que ele é pintado).
class SaidaDaVida {
  const SaidaDaVida({
    this.respiro = 0,
    this.boia = 0,
    this.cauda = 0,
    this.ciclo = 0,
    this.olhar = Offset.zero,
    this.inclina = 0,
    this.achata = 0,
    this.desloca = Offset.zero,
    this.virado = false,
    this.balanco = 0,
    this.carregado = false,
    this.altura = 0,
    this.pisca = 0,
    this.emburrado = false,
    this.derretido = 0,
    this.passada = 0,
  });

  /// -1..1: as patas andando, uma para a frente e a outra para trás.
  final double passada;

  /// -1..1: o peito.
  final double respiro;

  /// -1..1: o corpo subindo e descendo à toa.
  final double boia;

  /// -1..1: a cauda.
  final double cauda;

  /// 0..1 dando a volta: a fase do laço da atividade (nado, pasto…), com
  /// cadência que varia.
  final double ciclo;

  /// -1..1 nos dois eixos: para onde as pupilas olham.
  final Offset olhar;

  /// Radianos: o corpo inteiro inclinando (cabeça seguindo o olhar,
  /// curiosidade, balanço no colo, o ceder ao carinho).
  final double inclina;

  /// -1..1: positivo achata (pouso, toque), negativo estica (salto, colo).
  final double achata;

  /// Deslocamento do corpo na caixa: passeio (x) e salto/colo (y, negativo
  /// sobe).
  final Offset desloca;

  /// Olhando para a esquerda (desenho espelhado).
  final bool virado;

  /// -1..1: o quanto o corpo balança (no colo, no ar).
  final double balanco;

  /// Pendurado pelo dedo.
  final bool carregado;

  /// Altura acima do chão, ≥ 0: a sombra encolhe com ela.
  final double altura;

  /// 0..1: o quanto o olho está fechado agora (piscada, olho de sono,
  /// cara de emburrado).
  final double pisca;

  /// Emburrado: ignorando cutucões por um tempo.
  final bool emburrado;

  /// 0..1: derretendo de carinho na zona favorita.
  final double derretido;
}

class MotorDeVida {
  MotorDeVida({int semente = 0, this.areaDeAndar = 0})
      : _sorte = math.Random(semente == 0 ? null : semente),
        _rRespiro = Ruido(semente + 11),
        _rFundura = Ruido(semente + 23),
        _rBoia = Ruido(semente + 37),
        _rPeso = Ruido(semente + 41),
        _rCauda = Ruido(semente + 53),
        _rCadencia = Ruido(semente + 67),
        _rMicro = Ruido(semente + 79) {
    // Cada bicho nasce com uma zona favorita e uma de que não gosta.
    final r = math.Random(semente + 97);
    const zonas = [ZonaDoCorpo.cabeca, ZonaDoCorpo.costas, ZonaDoCorpo.barriga];
    zonaFavorita = zonas[r.nextInt(3)];
    zonaRuim = zonas.where((z) => z != zonaFavorita).toList()[r.nextInt(2)];
  }

  /// Quanto ele pode andar para cada lado, em unidades do desenho. Zero
  /// mantém o bicho no lugar (miniaturas, sessão).
  double areaDeAndar;

  late final ZonaDoCorpo zonaFavorita;
  late final ZonaDoCorpo zonaRuim;

  /// Chamado quando o desenho deve fazer um gesto da coreografia dele.
  void Function(EventoDaVida)? aoEvento;

  final math.Random _sorte;
  final Ruido _rRespiro, _rFundura, _rBoia, _rPeso, _rCauda, _rCadencia;
  final Ruido _rMicro;

  double _t = 0;

  // --- fases que dão a volta, com velocidade variável -------------------
  double _faseRespiro = 0;
  double _faseCiclo = 0;
  double _faseAbano = 0;

  /// Duração-base da respiração e do laço da atividade (s).
  double periodoRespiro = 3.2;
  double periodoCiclo = 7.0;

  /// Mediana do intervalo entre piscadas (s). Desenho lê melhor com mais
  /// piscadas que o bicho real (cão ~9 s, gato ~15 s).
  double medianaDoPiscar = 3.5;

  /// Se o bicho pode sair do lugar agora.
  bool podeAndar = true;

  /// Movimento reduzido: amplitudes baixas, nada de passeio.
  bool reduzido = false;

  /// A atividade ocupa o corpo (sono, voo): só respira e reage a toque.
  bool ocupado = false;

  /// Dormindo: fôlego mais fundo, olho fechado.
  bool dormindo = false;

  /// Na água: passeia deslizando, sem pulinhos.
  bool nadando = false;

  /// A postura é livre (ócio, ou ele saiu da atividade para andar).
  bool posturaLivre = true;

  /// A hora do dia (0–23): muda os pesos do cérebro.
  int hora = 12;

  /// A bola ou o petisco no habitat. Nulo: nada chamando a atenção.
  InteresseDoBicho? interesse;

  /// Como ele persegue (por espécie).
  JeitoDeCacar jeito = const JeitoDeCacar();

  /// Chegou na coisa: a cena decide (chutar a bola, comer o petisco).
  void Function(TipoDeInteresse)? aoAlcancar;

  double _espreitandoDesde = -1;
  double _olhouAntesDeIr = -1;

  /// Quando ele pediu para brincar (-1: não pediu ou já foi atendido).
  double _pediuEm = -1;

  /// O pescoço esticando para a comida na mão (inclinação extra).
  double _estica = 0;
  double _ultimoAlcance = -100;

  /// Perseguindo ou de olho em alguma coisa.
  bool get interessado => interesse != null && !noColo;

  // --- olhar ------------------------------------------------------------
  final _pupila = Mola2(f: 11, zeta: 0.88);
  final _cabeca = Mola2(f: 1.6, zeta: 1);
  Offset _alvoDoOlhar = Offset.zero;
  Offset _fixacao = Offset.zero;
  double _proximaSacada = 0.6;
  double _proximoInteresse = 0;

  // --- piscar -----------------------------------------------------------
  double _proximaPiscada = 2;
  double _piscadaT = -1;
  bool _piscadaLenta = false;
  bool _piscadaDupla = false;

  // --- o corpo ------------------------------------------------------------
  // Amortecimento crítico (zeta 1) em tudo que é corpo: chega no lugar sem
  // passar do ponto e voltar. Balanço de mola, o corpo indo e vindo depois
  // de um toque, lê como gelatina, não como bicho. Só a cauda e o corpo
  // pendurado pelo dedo guardam um resto de embalo, que é o deles.
  final _inclina = Mola(f: 1.2, zeta: 1);
  final _achata = Mola(f: 3, zeta: 1);
  final _cauda = Mola(f: 3, zeta: 0.75);
  final _colo = Mola2(f: 2.8, zeta: 0.9);
  final _balancoNoColo = Mola(f: 1.6, zeta: 0.6);

  // --- andar ------------------------------------------------------------
  // Ele anda: acelera, mantém o passo e freia antes de chegar, com as patas
  // alternando no ritmo da distância percorrida. Nada de pulinho para ir de
  // um lado ao outro.
  double _px = 0;
  double _vx = 0;
  double _alvoX = 0;
  bool _correndo = false;
  double _faseDoPasso = 0;
  double _rebola = 0;

  void _andar(double dt) {
    final falta = _alvoX - _px;
    final base = jeito.velocidade;
    final vmax = nadando
        ? base * 0.8
        : _correndo
            ? base * 1.8
            : base;
    const freio = 140.0;
    final desejada = falta.abs() < 0.3
        ? 0.0
        : falta.sign * math.min(vmax, math.sqrt(2 * freio * falta.abs()));
    // No ar não se muda o embalo: o bote vai até onde o pulo levar.
    final acel = _noChao || nadando ? 220.0 : 0.0;
    _vx += (desejada - _vx).clamp(-acel * dt, acel * dt);
    _px += _vx * dt;
    if (_px.abs() > areaDeAndar) {
      _px = _px.clamp(-areaDeAndar, areaDeAndar);
      _vx = 0;
    }
    _faseDoPasso += _vx.abs() * dt / 15;
  }

  // --- salto e queda ----------------------------------------------------
  double _y = 0;
  double _vy = 0;
  bool _noChao = true;
  bool _veioDoColo = false;
  static const _gravidade = 900.0;

  // --- cérebro ----------------------------------------------------------
  IntencaoDoBicho _intencao = IntencaoDoBicho.estar;
  double _fimDaIntencao = 2;
  double _destinoX = 0;
  double _proximoPulo = 0;
  bool _virado = false;
  double _desviraEm = -1;
  final Map<IntencaoDoBicho, double> _ultimaVez = {};
  final Map<EventoDaVida, double> _ultimoEvento = {};

  // --- dedo -------------------------------------------------------------
  Offset? _olharDeFora;
  Offset? _dedoNoColo;
  Offset? _colado;
  double _ultimaInteracao = -100;
  double _agitacao = 0;
  final List<double> _toques = [];
  double _emburradoAte = -1;
  double _derretido = 0;
  double _naZonaFavorita = 0;
  double _ultimaQueixa = -100;
  double _espirroEm = -1;

  IntencaoDoBicho get intencao => _intencao;
  bool get noColo => _dedoNoColo != null;
  double get xAtual => _px;
  bool get emburrado => _t < _emburradoAte;

  /// A caminho de outro lugar (ainda não chegou).
  bool get andando =>
      (_intencao == IntencaoDoBicho.passear &&
          ((_destinoX - _px).abs() > 4 || !_noChao)) ||
      (interessado && (!_noChao || _vx.abs() > 2));

  /// O olhar mandado de fora (a borboleta, o dedo longe dele). Nulo = dele.
  set olharDeFora(Offset? o) => _olharDeFora = o;

  // ======================================================================
  // Entradas
  // ======================================================================

  /// A zona do corpo de um ponto relativo (-1..1 no corpo).
  static ZonaDoCorpo zonaDe(Offset onde) {
    if (onde.dy < -0.15 && onde.dy > -0.6 && onde.dx.abs() < 0.22) {
      return ZonaDoCorpo.nariz;
    }
    if (onde.dy < -0.2) return ZonaDoCorpo.cabeca;
    if (onde.dy > 0.25 && onde.dx.abs() < 0.45) return ZonaDoCorpo.barriga;
    return ZonaDoCorpo.costas;
  }

  /// Um toque no corpo. [onde] em -1..1 relativo ao corpo.
  ///
  /// Os toques se somam numa janela de 1,5 s e a reação escala — como bicho
  /// de verdade, que acha graça até cansar.
  void tocado(Offset onde) {
    final zona = zonaDe(onde);
    _olhaPara(
      Offset(onde.dx.clamp(-1.0, 1.0), onde.dy.clamp(-1.0, 1.0)),
      pisca: false,
    );
    if (emburrado) {
      // Emburrado não reage: só um muxoxo da cauda.
      _cauda.empurra(-6);
      return;
    }
    _interagiu();
    _toques
      ..removeWhere((t) => _t - t > 1.5)
      ..add(_t);
    final n = _toques.length;

    if (zona == ZonaDoCorpo.nariz && n <= 2) {
      // O nariz: recua, e às vezes espirra (com antecipação de 0,4 s).
      _achata.empurra(-4);
      _inclina.empurra(0.9);
      if (_sorte.nextDouble() < 0.35) _espirroEm = _t + 0.4;
      return;
    }

    if (n == 1) {
      // Achata no toque e volta balançando; a cauda dá um tranco.
      _achata.empurra(6);
      _inclina.empurra(-onde.dx * 1.6);
      _cauda.empurra(14);
    } else if (n == 2) {
      // Susto: um pulinho.
      _achata.empurra(4);
      pula(150);
    } else if (n <= 4) {
      // Cócegas: tremidinha rápida, olhinho apertado, cauda a mil.
      _agitacao = 1;
      _piscaAgora(lenta: false);
      _cauda.empurra(20);
    } else if (n <= 6) {
      // Bufa e vira de costas.
      _achata.empurra(-6);
      _virado = !_virado;
      _desviraEm = _t + 1.4;
      _ultimaQueixa = _t;
    } else {
      // Cansou: emburra por 8 s.
      _emburradoAte = _t + 8;
      _toques.clear();
      _virado = onde.dx < 0;
      _desviraEm = _t + 8;
    }
    // Raríssimo: espirro do nada.
    if (_sorte.nextDouble() < 0.02) _espirroEm = _t + 0.4;
  }

  /// O dedo passando por cima (afago). [velocidade] em unidades/s.
  void afagado(Offset onde, Offset velocidade) {
    _interagiu();
    final zona = zonaDe(onde);
    _olhaPara(
      Offset(onde.dx.clamp(-1.0, 1.0), onde.dy.clamp(-1.0, 1.0)),
      pisca: false,
    );
    final v = velocidade.distance;

    // Rápido demais: "ei!" — esquiva para o lado oposto ao dedo.
    if (v > 2200 && _t - _ultimaQueixa > 1.2) {
      _ultimaQueixa = _t;
      _achata.empurra(-5);
      _inclina.empurra(-velocidade.dx.sign * 2.5);
      if (podeAndar && areaDeAndar > 12) {
        _alvoX = (_px - velocidade.dx.sign * 18)
            .clamp(-areaDeAndar, areaDeAndar);
      }
      return;
    }

    if (zona == zonaRuim && _t - _ultimaQueixa > 2) {
      // Não gosta aqui: encolhe e a cauda chicoteia.
      _ultimaQueixa = _t;
      _achata.empurra(-4);
      _cauda.empurra(-24);
      _inclina.empurra(onde.dx.sign * 1.4);
      return;
    }

    // O corpo cede na direção da mão: leve, contínuo.
    _inclina.alvo = (velocidade.dx / 900).clamp(-0.1, 0.1);
    _achata.alvo = 0.15 + 0.2 * _derretido;
    _cauda.empurra(v / 140);
    _agitacao = math.min(0.6, _agitacao + v / 14000);
    if (zona == zonaFavorita) _naZonaFavorita += 1 / 60;
  }

  void soltouAfago() {
    _inclina.alvo = 0;
    _achata.alvo = 0;
    _naZonaFavorita = 0;
    // Satisfeito: a piscada lenta de confiança.
    if (_derretido > 0.3) _piscaAgora(lenta: true);
  }

  /// O dedo pegou o bicho. [onde] em unidades do desenho, relativo ao centro
  /// do corpo.
  void pegou(Offset onde) {
    _interagiu();
    _emburradoAte = -1;
    _colado = onde;
    // O corpo começa onde está; o dedo é que vai levá-lo.
    _dedoNoColo = Offset(_px, -_y);
    _colo.fixa(Offset(_px, -_y));
    _noChao = false;
    _intencao = IntencaoDoBicho.estar;
    _achata.empurra(-10);
    _piscaAgora(lenta: false);
  }

  /// O dedo carregando, em unidades do desenho relativas ao repouso.
  void carrega(Offset dedo) {
    if (_colado == null) return;
    _dedoNoColo = dedo - _colado!;
  }

  /// Soltou: cai com o embalo que tinha.
  void soltou() {
    if (_dedoNoColo == null) return;
    final v = _colo.velocidade;
    final p = _colo.valor;
    _dedoNoColo = null;
    _colado = null;
    final limite = areaDeAndar;
    final x = p.dx.clamp(-limite, limite);
    _px = x;
    _alvoX = x;
    _vx = 0;
    _destinoX = x;
    _y = math.max(0, -p.dy);
    _vy = -v.dy;
    _noChao = false;
    _veioDoColo = true;
    _inclina.empurra(-v.dx / 260);
    _interagiu();
  }

  /// Acordou com o toque: olho entreaberto por 0,8 s antes de abrir.
  void acordando() {
    _sonolento = 0.8;
    _interagiu();
    _olhaPara(const Offset(0, -0.2), pisca: false);
    if (_festaGuardada > 0) {
      // Dormia quando a pessoa voltou: a alegria vem dobrada, depois do
      // olho abrir.
      _festaEm = _t + 0.9;
      _duracaoDaFesta = _festaGuardada >= 24 ? 3.2 : 1.6;
      _festaGuardada = 0;
    }
  }

  double _sonolento = 0;

  /// A pessoa voltou depois de [horas] fora (pesquisa 20, mecânica 6),
  /// sem punição nenhuma: quanto mais tempo, maior a festa.
  ///
  /// - menos de 1 h: olha para ela e abana a cauda;
  /// - até um dia: dois pulinhos;
  /// - mais de um dia: uma pausa de 0,6 s ("é você?") e festa longa.
  ///
  /// Dormindo, guarda a festa para quando acordar com o toque.
  void saudacao(double horas) {
    if (dormindo || ocupado) {
      _festaGuardada = math.max(_festaGuardada, horas);
      return;
    }
    _interagiu();
    _olhaPara(const Offset(0, -0.25), pisca: horas >= 1);
    _cauda.empurra(horas < 1 ? 14 : 22);
    _agitacao = math.max(_agitacao, horas < 1 ? 0.5 : 1);
    if (horas < 1) return;
    _festaEm = _t + (horas >= 24 ? 0.6 : 0.15);
    _duracaoDaFesta = horas >= 24 ? 2.4 : 1.0;
  }

  double _festaGuardada = 0;
  double _festaEm = -1;
  double _duracaoDaFesta = 0;

  /// Terminou de comer: satisfeito, a piscada lenta.
  void comeu() {
    _ultimaInteracao = _t;
    _agitacao = 1;
    _derretido = math.max(_derretido, 0.7);
    _inclina.alvo = 0;
    _piscaAgora(lenta: true);
  }

  /// Um pulo daqui (velocidade inicial, unidades/s).
  void pula(double v) {
    if (!_noChao || reduzido) return;
    _achata.empurra(5); // agacha antes: antecipação
    _vy = v;
    _noChao = false;
  }

  void _interagiu() {
    _ultimaInteracao = _t;
    if (_intencao == IntencaoDoBicho.passear ||
        _intencao == IntencaoDoBicho.farejar ||
        _intencao == IntencaoDoBicho.descansar) {
      _mudaPara(IntencaoDoBicho.estar, 2.5);
    }
  }

  void _evento(EventoDaVida e, {double espera = 0}) {
    final ultimo = _ultimoEvento[e];
    if (ultimo != null && _t - ultimo < espera) return;
    _ultimoEvento[e] = _t;
    aoEvento?.call(e);
  }

  // ======================================================================
  // O passo
  // ======================================================================

  /// Avança [dt] segundos. Quadro longo (app voltando, teste avançando o
  /// relógio de uma vez) é dividido em passos de 1/30 s: as molas ficam
  /// estáveis e o tempo do bicho não atrasa em relação ao relógio.
  SaidaDaVida passo(double dt) {
    var resta = dt.clamp(0.0, 2.0);
    var saida = _quadro;
    if (resta == 0) return saida;
    while (resta > 1e-6) {
      final d = math.min(resta, 1 / 30);
      saida = _passo(d);
      resta -= d;
    }
    return _quadro = saida;
  }

  SaidaDaVida _quadro = const SaidaDaVida();

  SaidaDaVida _passo(double dt) {
    _t += dt;
    final a = reduzido ? 0.25 : 1.0;

    // --- respiração ------------------------------------------------------
    final descansando = _intencao == IntencaoDoBicho.descansar;
    final derretendo = _derretido > 0.4;
    final periodo = periodoRespiro *
        (descansando || derretendo ? 1.3 : 1) *
        (1 + 0.2 * _rRespiro.em(_t * 0.11));
    _faseRespiro += dt / periodo;
    final fundura = dormindo
        ? 1.5 + 0.12 * _rFundura.em(_t * 0.05)
        : 0.8 +
            0.22 * _rFundura.em(_t * 0.07) +
            (descansando ? 0.25 : 0) +
            (_agitacao > 0.5 ? 0.3 : 0);
    final respiro = math.sin(_faseRespiro * 2 * math.pi) * fundura;

    // O laço da atividade: cadência ±15%.
    _faseCiclo += dt / (periodoCiclo * (1 + 0.15 * _rCadencia.em(_t * 0.05)));
    _faseCiclo %= 1;

    final boia =
        posturaLivre ? _rBoia.em(_t * 0.18, oitavas: 3) * 1.1 : 0.0;

    // --- cérebro -----------------------------------------------------------
    if (_festaEm > 0 && _t >= _festaEm && !ocupado) {
      _festaEm = -1;
      _mudaPara(IntencaoDoBicho.festejar, _duracaoDaFesta);
      _proximoPulo = _t;
      _derretido = math.max(_derretido, 0.4);
    }
    _estica = 0;
    _correndo = false;
    _rebola = 0;
    final perseguia = _perseguindo;
    _perseguindo = interessado && !ocupado && podeAndar;
    if (_perseguindo) {
      _persegue();
    } else if (!ocupado) {
      _largaAEspreita();
      _olhouAntesDeIr = -1;
      // Perdeu o interesse no meio do caminho: para onde está.
      if (perseguia) _alvoX = _px;
      _decide();
      _comportamento();
    } else if (_intencao != IntencaoDoBicho.estar) {
      _mudaPara(IntencaoDoBicho.estar, 1);
      _alvoDoOlhar = Offset.zero;
    }
    // Ocupado (comendo, dormindo) ou sem poder andar: os pés ficam.
    if (ocupado || !podeAndar) _alvoX = _px;
    if (_desviraEm > 0 && _t >= _desviraEm) {
      _virado = false;
      _desviraEm = -1;
    }

    // --- espirro (com antecipação) -------------------------------------
    var anteEspirro = 0.0;
    if (_espirroEm > 0) {
      final falta = _espirroEm - _t;
      if (falta > 0) {
        // Puxa o ar: estica e ergue a cabeça.
        anteEspirro = 1 - falta / 0.4;
      } else {
        _espirroEm = -1;
        _achata.alvo = 0;
        _achata.empurra(14);
        _inclina.empurra(-1.8);
        _piscaAgora(lenta: false);
        _evento(EventoDaVida.sacode);
      }
    }

    // --- carinho na zona favorita: derrete -------------------------------
    if (_naZonaFavorita > 1.6) {
      _derretido = math.min(1, _derretido + dt * 0.8);
    } else {
      _derretido = math.max(0, _derretido - dt * 0.35);
    }

    // --- cauda -------------------------------------------------------------
    final vontade = _rCauda.em(_t * 0.09) * 0.5 + 0.5;
    final feliz = _agitacao +
        _derretido +
        (_intencao == IntencaoDoBicho.festejar ? 1 : 0) +
        (_t - _ultimaInteracao < 3 && !emburrado ? 0.6 : 0);
    final abano = (vontade > 0.62 ? (vontade - 0.62) * 2.6 : 0) + feliz;
    _faseAbano += dt * (1.2 + abano * 2.4) * (emburrado ? 0.2 : 1);
    _cauda.alvo = math.sin(_faseAbano * 2 * math.pi) *
            (0.25 + 0.75 * abano.clamp(0.0, 1.0)) -
        _vx * 0.004;
    _cauda.passo(dt);

    _agitacao = math.max(0, _agitacao - dt * 0.6);

    // --- olhar: o olho salta, a cabeça vem atrás ------------------------
    _sacadas();
    final micro = Offset(
      _rMicro.em(_t * 1.3) * 0.015,
      _rMicro.em(_t * 1.3 + 50) * 0.015,
    );
    _pupila.alvo = _naCirculo(_fixacao, 1) + micro;
    _pupila.passo(dt);
    final excesso = _fixacao - _naCirculo(_fixacao, 0.35);
    _cabeca.alvo = excesso * 0.8 + _fixacao * 0.15;
    _cabeca.passo(dt);

    // --- inclinação ----------------------------------------------------
    final curioso = _intencao == IntencaoDoBicho.chamar ? 0.14 : 0.0;
    _inclina.alvo = !posturaLivre
        ? 0
        : (noColo ? 0 : _cabeca.valor.dx * 0.12) +
            curioso * (_virado ? -1 : 1) +
            _rPeso.em(_t * 0.13) * 0.025 -
            anteEspirro * 0.12 +
            _estica;
    _inclina.passo(dt);

    // --- salto, queda, colo ----------------------------------------------
    _andar(dt);
    // O passo: as patas alternam e o corpo sobe um fio a cada apoio.
    final andandoNoChao = _noChao && !nadando && !noColo;
    final intensidade = andandoNoChao ? math.min(1.0, _vx.abs() / 8) : 0.0;
    final onda = math.sin(_faseDoPasso * 2 * math.pi);
    final passada = onda * intensidade + _rebola;
    final sobeNoPasso = onda.abs() * 1.8 * intensidade;
    var desloca = Offset(_px, 0);
    var balanco = 0.0;
    var inclinaNoColo = 0.0;
    if (_dedoNoColo != null) {
      _colo.alvo = _dedoNoColo!;
      final p = _colo.passo(dt);
      final v = _colo.velocidade;
      desloca = p;
      _balancoNoColo.alvo = (-v.dx / 400).clamp(-0.7, 0.7);
      inclinaNoColo = _balancoNoColo.passo(dt);
      balanco = math.sin(_t * 9) * 0.6 + inclinaNoColo;
      _achata.alvo = -0.35;
      _y = math.max(0, -p.dy);
    } else {
      if (!_noChao) {
        _vy -= _gravidade * dt;
        _y += _vy * dt;
        balanco = (_vy / 400).clamp(-1.0, 1.0);
        // No ar, estica com a velocidade.
        _achata.alvo = -(_vy.abs() / 500).clamp(0.0, 1.0) * 0.35;
        if (_y <= 0) {
          _y = 0;
          final impacto = (-_vy / 500).clamp(0.0, 1.6);
          _achata.alvo = 0;
          _achata.empurra(impacto * 6);
          _vy = 0;
          _noChao = true;
          if (_veioDoColo) {
            // Caiu do colo: sacode o corpo e olha para quem soltou.
            _veioDoColo = false;
            _evento(EventoDaVida.sacode);
            _olhaPara(const Offset(0, -0.25), pisca: true);
          }
        }
      } else if (_achata.alvo < 0 && _espirroEm < 0) {
        _achata.alvo = 0;
      }
      desloca = Offset(desloca.dx, -_y - sobeNoPasso);
    }
    if (anteEspirro > 0) _achata.alvo = -anteEspirro * 0.4;
    _achata.passo(dt);

    final pisca = _piscar(dt);

    return SaidaDaVida(
      respiro: respiro * a,
      boia: boia * a,
      cauda: _cauda.valor.clamp(-1.4, 1.4) * (0.4 + 0.6 * a),
      ciclo: _faseCiclo,
      olhar: _pupila.valor,
      inclina: (_inclina.valor + inclinaNoColo * 0.5) * a,
      achata: _achata.valor.clamp(-0.6, 0.6) * a,
      desloca: desloca,
      virado: _virado,
      balanco: balanco * a,
      carregado: noColo,
      altura: _y,
      pisca: pisca,
      emburrado: emburrado,
      derretido: _derretido,
      passada: passada * a,
    );
  }

  // ======================================================================
  // Olhar e piscar
  // ======================================================================

  static Offset _naCirculo(Offset o, double r) {
    final d = o.distance;
    return d <= r ? o : o / d * r;
  }

  /// Muda o alvo do olhar já: o olho salta no próximo quadro.
  void _olhaPara(Offset alvo, {required bool pisca}) {
    _alvoDoOlhar = alvo;
    _fixacao = alvo;
    _proximaSacada = _t + 0.8 + _sorte.nextDouble() * 0.8;
    _proximoInteresse = _t + 1.2;
    if (pisca) _piscaAgora(lenta: false);
  }

  /// Pequenas sacadas em torno do alvo: o olho nunca fica cravado num ponto.
  void _sacadas() {
    final alvo = _olharDeFora ?? _alvoDoOlhar;
    final grande = (alvo - _fixacao).distance > 0.35;
    if (grande || _t >= _proximaSacada) {
      final disco = _olharDeFora != null ? 0.05 : 0.14;
      final ang = _sorte.nextDouble() * math.pi * 2;
      final r = math.sqrt(_sorte.nextDouble()) * disco;
      _fixacao = alvo + Offset(math.cos(ang), math.sin(ang)) * r;
      // Fixações de 0,3–0,9 s quando atento; mediana ~1,1 s à toa.
      _proximaSacada = _t +
          (_olharDeFora != null
              ? 0.3 + _sorte.nextDouble() * 0.6
              : _logNormal(1.1, 0.5).clamp(0.4, 3.5));
      // Piscar junto de uma troca grande de olhar.
      if (grande && _sorte.nextDouble() < 0.4) _piscaAgora(lenta: false);
    }
  }

  double _gauss() {
    final u1 = math.max(1e-9, _sorte.nextDouble());
    final u2 = _sorte.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  double _logNormal(double mediana, double sigma) =>
      math.exp(math.log(mediana) + sigma * _gauss());

  void _piscaAgora({required bool lenta}) {
    if (_piscadaT >= 0) return;
    _piscadaT = 0;
    _piscadaLenta = lenta;
    _piscadaDupla = !lenta && _sorte.nextDouble() < 0.12;
  }

  /// 0..1 de olho fechado. Fecha em ~80 ms e abre em ~170 ms: a abertura é
  /// a fase mais lenta. A lenta (confiança): 220 / 300 / 400 ms.
  double _piscar(double dt) {
    if (dormindo) return 0; // o desenho do sono já tem os olhos fechados
    var base = 0.0;
    if (emburrado) base = 0.4;
    if (_derretido > 0) base = math.max(base, _derretido * 0.85);
    if (_sonolento > 0) {
      _sonolento = math.max(0, _sonolento - dt);
      base = math.max(base, 0.55 + 0.4 * (_sonolento / 0.8));
    }
    if (_piscadaT < 0) {
      if (_t >= _proximaPiscada) _piscaAgora(lenta: false);
      if (_piscadaT < 0) return base;
    }
    _piscadaT += dt;
    final fecha = _piscadaLenta ? 0.22 : 0.08;
    final segura = _piscadaLenta ? 0.30 : 0.03;
    final abre = _piscadaLenta ? 0.40 : 0.17;
    double v;
    if (_piscadaT < fecha) {
      final u = _piscadaT / fecha;
      v = u * u;
    } else if (_piscadaT < fecha + segura) {
      v = 1;
    } else if (_piscadaT < fecha + segura + abre) {
      final u = (_piscadaT - fecha - segura) / abre;
      v = (1 - u) * (1 - u);
    } else {
      v = 0;
      _piscadaT = -1;
      if (_piscadaDupla) {
        _piscadaDupla = false;
        _proximaPiscada = _t + 0.12 + _sorte.nextDouble() * 0.1;
      } else {
        _proximaPiscada =
            _t + _logNormal(medianaDoPiscar, 0.55).clamp(1.0, 12.0);
      }
    }
    return math.max(base, v);
  }

  // ======================================================================
  // O cérebro
  // ======================================================================

  void _mudaPara(IntencaoDoBicho i, double duracao) {
    _intencao = i;
    _fimDaIntencao = _t + duracao;
    _ultimaVez[i] = _t;
  }

  /// Escolhe a próxima intenção quando a atual acaba.
  ///
  /// Pesos por hora do dia, com espera para não repetir a mesma coisa em
  /// seguida (ver 21-animacao-fluida.md, §3.2).
  void _decide() {
    if (noColo || _t < _fimDaIntencao) return;
    if (_pediuEm > 0 && _intencao == IntencaoDoBicho.chamar) {
      // Ninguém veio: um suspiro, e tudo bem. Sem cobrança.
      _pediuEm = -1;
      _achata.empurra(-6);
      _inclina.empurra(-0.5);
      _mudaPara(IntencaoDoBicho.descansar, 4);
      return;
    }
    final semInteracao = _t - _ultimaInteracao;
    final manha = hora >= 6 && hora < 11;
    final tarde = hora >= 11 && hora < 18;
    final noite = hora >= 21 || hora < 6;
    final anda = podeAndar && !reduzido && areaDeAndar > 12;
    final opcoes = <(IntencaoDoBicho, double)>[
      (IntencaoDoBicho.estar, 2.6),
      (IntencaoDoBicho.observar, 3),
      if (anda) (IntencaoDoBicho.passear, tarde ? 3.6 : noite ? 1.2 : 2.8),
      if (podeAndar && !reduzido && !nadando) (IntencaoDoBicho.farejar, 1.6),
      (IntencaoDoBicho.chamar, semInteracao > 25 ? 2.2 : 0.5),
      (IntencaoDoBicho.descansar, noite ? 2.8 : manha ? 0.6 : 1.0),
      if (podeAndar && !reduzido && !nadando)
        (IntencaoDoBicho.festejar, tarde ? 0.7 : 0.35),
    ];
    var total = 0.0;
    final pesos = <double>[];
    for (final (i, p) in opcoes) {
      final ultima = _ultimaVez[i];
      final fator = i == _intencao
          ? 0.25
          : ultima == null
              ? 1.0
              : (math.min(1.0, (_t - ultima) / 20)).clamp(0.2, 1.0);
      final peso = p * fator;
      pesos.add(peso);
      total += peso;
    }
    var sorteio = _sorte.nextDouble() * total;
    var escolhida = opcoes.first.$1;
    for (var k = 0; k < opcoes.length; k++) {
      sorteio -= pesos[k];
      if (sorteio <= 0) {
        escolhida = opcoes[k].$1;
        break;
      }
    }
    final dura = switch (escolhida) {
      IntencaoDoBicho.estar => 2.0 + _sorte.nextDouble() * 3,
      IntencaoDoBicho.observar => 3.0 + _sorte.nextDouble() * 3,
      IntencaoDoBicho.passear => nadando ? 9.0 : 6.0,
      IntencaoDoBicho.farejar => 3.0 + _sorte.nextDouble() * 2,
      IntencaoDoBicho.chamar => 2.6 + _sorte.nextDouble() * 1.5,
      IntencaoDoBicho.descansar => 5.0 + _sorte.nextDouble() * 4,
      IntencaoDoBicho.festejar => 1.6,
    };
    final antes = _intencao;
    _mudaPara(escolhida, dura);
    if (escolhida == IntencaoDoBicho.passear) {
      final lado = _px > 0 ? -1 : 1;
      _destinoX = (lado * (areaDeAndar * (0.35 + _sorte.nextDouble() * 0.6)))
          .clamp(-areaDeAndar, areaDeAndar);
    }
    if (escolhida == IntencaoDoBicho.festejar) _proximoPulo = _t;
    if (escolhida == IntencaoDoBicho.chamar) _piscaAgora(lenta: true);
    // Ao sair do descanso, ou de manhã, um espreguiçar; às vezes, coçar.
    if (antes == IntencaoDoBicho.descansar ||
        (manha && _sorte.nextDouble() < 0.3)) {
      _evento(EventoDaVida.espreguica, espera: 40);
    } else if (escolhida == IntencaoDoBicho.estar &&
        _sorte.nextDouble() < 0.15) {
      _evento(EventoDaVida.coca, espera: 40);
    }
  }

  /// O que a intenção faz a cada quadro: alvos de olhar, pulinhos, passos.
  void _comportamento() {
    if (noColo) return;
    switch (_intencao) {
      case IntencaoDoBicho.estar:
        _olharAoAcaso(intervalo: (1.6, 4.0), alcance: 0.45);
      case IntencaoDoBicho.observar:
        _olharAoAcaso(intervalo: (0.5, 1.6), alcance: 0.95);
      case IntencaoDoBicho.passear:
        final falta = _destinoX - _px;
        _virado = falta < 0;
        _alvoDoOlhar = Offset(falta.sign * 0.7, 0.05);
        if (falta.abs() < 4) {
          _mudaPara(IntencaoDoBicho.estar, 1.5 + _sorte.nextDouble() * 2);
          _olhaPara(Offset(_virado ? 0.3 : -0.3, 0), pisca: true);
          _virado = false;
        } else {
          _alvoX = _destinoX;
        }
      case IntencaoDoBicho.farejar:
        if (_t >= _proximoInteresse) {
          _alvoDoOlhar = Offset(
            (_sorte.nextDouble() * 2 - 1) * 0.6,
            0.7 + _sorte.nextDouble() * 0.3,
          );
          _proximoInteresse = _t + 0.5 + _sorte.nextDouble() * 0.9;
          if (podeAndar && areaDeAndar > 12 && _sorte.nextDouble() < 0.35) {
            _alvoX = (_px + (_sorte.nextDouble() * 2 - 1) * 10)
                .clamp(-areaDeAndar, areaDeAndar);
          }
        }
      case IntencaoDoBicho.chamar:
        _alvoDoOlhar = const Offset(0, -0.25);
        if (_t >= _proximoInteresse) {
          _proximoInteresse = _t + 1.2;
          _cauda.empurra(10);
        }
      case IntencaoDoBicho.descansar:
        _olharAoAcaso(intervalo: (3.0, 6.0), alcance: 0.25);
      case IntencaoDoBicho.festejar:
        _alvoDoOlhar = const Offset(0, -0.2);
        if (_noChao && _t >= _proximoPulo) {
          pula(160 + _sorte.nextDouble() * 40);
          _proximoPulo = _t + 0.75;
        }
    }
  }

  /// Saiu da espreita sem dar o bote: desagacha.
  void _largaAEspreita() {
    if (_espreitandoDesde >= 0) _achata.alvo = 0;
    _espreitandoDesde = -1;
    _deuOBote = false;
  }

  bool _perseguindo = false;

  /// Já espreitou e saltou nesta perseguição: depois do bote, corre.
  bool _deuOBote = false;

  /// A bola rolando, o petisco no dedo: tudo o mais espera.
  void _persegue() {
    final i = interesse!;
    // Pediu e a pessoa atendeu: festa curta antes de correr.
    if (!i.convite && _pediuEm > 0) {
      if (_t - _pediuEm < 10) {
        pula(170);
        _agitacao = 1;
        _cauda.empurra(24);
      }
      _pediuEm = -1;
    }
    // O convite começa com 1,2 s olhando para a pessoa.
    if (i.convite) {
      if (_olhouAntesDeIr < 0) {
        _olhouAntesDeIr = _t;
        _olhaPara(const Offset(0, -0.25), pisca: true);
      }
      if (_t - _olhouAntesDeIr < 1.2) {
        _alvoDoOlhar = const Offset(0, -0.25);
        return;
      }
    }
    // Olha para a coisa (o corpo tem ~70 de raio: normaliza por ele).
    final rel = i.onde - Offset(_px, -_y - 20);
    _alvoDoOlhar = Offset(
      (rel.dx / 90).clamp(-1.0, 1.0),
      (rel.dy / 90).clamp(-1.0, 1.0),
    );
    _proximoInteresse = _t + 0.5;
    if (_intencao != IntencaoDoBicho.festejar) {
      _intencao = IntencaoDoBicho.observar;
      _fimDaIntencao = _t + 1.5;
    }
    _ultimaInteracao = _t;
    _agitacao = math.max(_agitacao, 0.5);

    if (i.noAr) {
      _largaAEspreita();
      // No dedo: inclina na direção e dá pulinhos de vontade.
      _virado = rel.dx < 0;
      // Encostou na boca: come da mão (Pokémon-Amie, pesquisa 20, mec. 10).
      if (i.tipo == TipoDeInteresse.comida &&
          rel.distance < 48 &&
          _t - _ultimoAlcance > 0.8) {
        _ultimoAlcance = _t;
        aoAlcancar?.call(i.tipo);
        return;
      }
      // Perto da boca: o pescoço estica na direção da comida.
      if (i.tipo == TipoDeInteresse.comida && rel.distance < 130) {
        // Virado, o desenho é espelhado: positivo é sempre "para a frente".
        _estica = (rel.dx.abs() / 130).clamp(0.0, 1.0) * 0.22;
      }
      // Fica onde está, de olho: quem segura a comida é que vem até ele.
      _alvoX = _px;
      return;
    }

    final falta = i.onde.dx - _px;
    _virado = falta < 0;
    final perto = falta.abs() < 14 && i.onde.dy > -40;
    if (perto && _noChao) {
      _alvoX = _px;
      if (_t - _ultimoAlcance > 0.8) {
        _ultimoAlcance = _t;
        _espreitandoDesde = -1;
        _achata.empurra(5);
        aoAlcancar?.call(i.tipo);
        if (i.convite) {
          // Empurrou a bola para a pessoa: agora espera, olhando para ela.
          _pediuEm = _t;
          _olhouAntesDeIr = -1;
          _mudaPara(IntencaoDoBicho.chamar, 6);
          _olhaPara(const Offset(0, -0.25), pisca: false);
        }
      }
      return;
    }
    // O bote do gato: perto, para, agacha e rebola a traseira; depois salta
    // em cima. Uma vez por perseguição.
    if (jeito.espreita > 0 &&
        !_deuOBote &&
        i.tipo == TipoDeInteresse.bola &&
        falta.abs() < 70 &&
        _noChao) {
      if (_espreitandoDesde < 0) _espreitandoDesde = _t;
      _alvoX = _px;
      final esperou = _t - _espreitandoDesde;
      if (esperou < jeito.espreita) {
        _achata.alvo = 0.8; // agachado
        _rebola = math.sin(_t * 20) * 0.5;
        return;
      }
      _achata.alvo = 0;
      _deuOBote = true;
      _espreitandoDesde = -1;
      _alvoX = (_px + falta).clamp(-areaDeAndar, areaDeAndar);
      _vx = falta.sign * math.min(170, falta.abs() * 3);
      pula(240);
      return;
    }
    // Corre atrás: o destino é a coisa, a velocidade é a de corrida.
    _correndo = true;
    _alvoX = i.onde.dx.clamp(-areaDeAndar, areaDeAndar);
  }

  void _olharAoAcaso({
    required (double, double) intervalo,
    required double alcance,
  }) {
    if (_t < _proximoInteresse) return;
    final r = _sorte.nextDouble();
    _alvoDoOlhar = r < 0.25
        ? Offset.zero
        : r < 0.4
            ? const Offset(0, -0.2)
            : Offset(
                (_sorte.nextDouble() * 2 - 1) * alcance,
                (_sorte.nextDouble() * 2 - 1) * alcance * 0.5,
              );
    _proximoInteresse = _t +
        intervalo.$1 +
        _sorte.nextDouble() * (intervalo.$2 - intervalo.$1);
  }
}
