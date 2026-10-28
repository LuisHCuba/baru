part of 'motor_de_vida.dart';

/// O que a atividade pede do bicho. Era um laço de período fixo (a cabeça
/// descia no mesmo ponto da volta, catorze mordidas por volta, para sempre)
/// e numa medição de 3 minutos ele passava 93% do tempo nesse laço, sem um
/// gesto sequer. Agora a atividade é um **modo**: muda quais episódios ele
/// escolhe, não o que ele faz a cada instante.
enum ModoDaAtividade { livre, pastar, petiscar, nadar, brincar, dormir }

/// Um trecho de comportamento com começo, meio e fim, de duração e contagem
/// sorteadas. Etologia chama de "bout": um animal pastando alterna bocadas,
/// mastigação de cabeça erguida, vigilância e deslocamento até outro tufo.
enum Episodio {
  // pastar / petiscar
  comer,
  mastigar,
  vigiar,
  irAoTufo,
  // nadar
  remar,
  deslizar,
  boiar,
  // brincar
  bote,
  disparada,
  reverencia,
  rodopio,
  pulinhos,
  // dormir
  sono,
  suspiro,
  sonho,
  ajeita,
  // em qualquer modo: o corpo livre, com os gestos de ócio
  pausa,

  // --- do repertório de cada espécie (pesquisa 22, etograma) -----------
  /// Gata: olha para a pessoa e fecha os olhos devagar (Humphrey 2020).
  piscadaLenta,

  /// Gata: amassa pãozinho, patas alternando, olhos semicerrados.
  amassar,

  /// Raposa: congela escutando o chão e dá o salto de caça.
  escutar,

  /// Coruja: balança a cabeça para cima e para baixo, mirando algo.
  balancarCabeca,

  /// Coruja: gira a cabeça para um lado e para o outro, devagar.
  girarCabeca,

  /// Cão: inclina a cabeça, sempre para o mesmo lado.
  inclinarCabeca,

  /// Capivara: deita de barriga com a cabeça erguida.
  deitar,

  /// Pinguim, coruja, lontra, gata: cuidar do pelo ou das penas.
  alisar,

  /// Pinguim: cochilos de segundos, de pé.
  microcochilo,

  /// Pinguim: o display extático, bico para o céu.
  zurro,

  /// Tartaruga: recolhe a cabeça e depois espia.
  recolher,

  /// Tartaruga, capivara: banho de sol de olhos fechados.
  tomarSol,

  /// Na água — lontra: rola; lontra e pinguim: espia; axolote: sobe para
  /// pegar ar; pinguim: salta.
  rolar,
  espiar,
  respirar,
  saltoNaAgua,

  /// Dormindo — cão, gata, raposa: sonha remando as patas.
  sonhoDePatinhas,

  /// Coruja: decola, cruza o habitat baixo, paira mirando o chão e pousa
  /// (voos curtos e baixos entre poleiros, e o pairar de caça: Cornell,
  /// ADW).
  voar,

  /// Quem nada: da margem para a água e da água para a margem, por conta
  /// própria (capivara, tartaruga, lontra, pinguim — ADW, SDZ).
  entrarNaAgua,
  sairDaAgua,

  /// Quem come na água (lontra, pinguim, tartaruga, axolote): o bote
  /// rápido — no axolote, a sucção — e a mastigação.
  comerNaAgua,

  /// Ir até a zona que o momento pede (a toca para dormir, a beira para
  /// entrar na água, o canto dos brinquedos para brincar).
  irParaZona,
}

/// Onde cada episódio do repertório pode acontecer.
const _naTerra = {
  Episodio.entrarNaAgua,
  Episodio.voar,
  Episodio.piscadaLenta,
  Episodio.amassar,
  Episodio.escutar,
  Episodio.balancarCabeca,
  Episodio.girarCabeca,
  Episodio.inclinarCabeca,
  Episodio.deitar,
  Episodio.alisar,
  Episodio.microcochilo,
  Episodio.zurro,
  Episodio.recolher,
  Episodio.tomarSol,
};
const _naAgua = {
  Episodio.comerNaAgua,
  Episodio.sairDaAgua,
  Episodio.rolar,
  Episodio.espiar,
  Episodio.respirar,
  Episodio.saltoNaAgua,
};
const _noSono = {Episodio.sonhoDePatinhas};

/// Os episódios em que o desenho é o do corpo livre (não o da atividade).
const _desenhoLivre = {..._naTerra, Episodio.pausa, Episodio.irParaZona};

extension _Episodios on MotorDeVida {
  /// Transições: de cada episódio, quanto pesa cada próximo. O peso cai
  /// para quem acabou de acontecer ([_recencia]) — sem isso a mesma
  /// sequência voltava em ciclo.
  /// Os episódios da espécie que cabem no modo, com peso.
  Map<Episodio, double> _doRepertorio() {
    final valem = switch (modo) {
      ModoDaAtividade.nadar => _naAgua,
      ModoDaAtividade.dormir => _noSono,
      _ => _naTerra,
    };
    // Trocar de lugar: só quem pode, e depois de um tempo onde está.
    final troca = trocaDeLugar && _t - _ultimaTroca > 40;
    final dia = hora >= 8 && hora < 17;
    return {
      if (troca && valem.contains(Episodio.entrarNaAgua))
        Episodio.entrarNaAgua: 0.8,
      if (troca && valem.contains(Episodio.sairDaAgua))
        Episodio.sairDaAgua: 0.8,
      for (final e in repertorio)
        if (valem.contains(e) && (e != Episodio.tomarSol || dia))
          // Momentos especiais pesam pouco: aparecem, mas não viram cacoete.
          e: switch (e) {
            Episodio.piscadaLenta => 0.45,
            Episodio.zurro => 0.4,
            Episodio.tomarSol || Episodio.saltoNaAgua => 0.5,
            Episodio.amassar || Episodio.deitar || Episodio.microcochilo => 0.7,
            Episodio.escutar || Episodio.respirar => 1.4,
            Episodio.comerNaAgua => 1.5,
            Episodio.balancarCabeca => 1.2,
            Episodio.voar => 1.3,
            Episodio.sonhoDePatinhas => 1.6,
            _ => 0.9,
          },
    };
  }

  Map<Episodio, double> _proximos() => {
    ..._proximosDoModo(),
    // Logo depois de comer não se para para outra coisa: mastiga antes.
    if (_ep != Episodio.comer) ..._doRepertorio(),
  };

  Map<Episodio, double> _proximosDoModo() {
    switch (modo) {
      case ModoDaAtividade.pastar:
      case ModoDaAtividade.petiscar:
        return switch (_ep) {
          Episodio.comer => {
            Episodio.mastigar: 5,
            Episodio.vigiar: 3,
            Episodio.comer: 1.5,
            Episodio.irAoTufo: 1.5,
            Episodio.pausa: 1.2,
          },
          Episodio.mastigar => {
            Episodio.comer: 4,
            Episodio.vigiar: 2,
            Episodio.pausa: 2,
            Episodio.irAoTufo: 1.5,
          },
          Episodio.vigiar => {
            Episodio.comer: 4,
            Episodio.mastigar: 1,
            Episodio.pausa: 2,
            Episodio.irAoTufo: 2,
          },
          Episodio.irAoTufo => {Episodio.comer: 6, Episodio.vigiar: 1},
          _ => {Episodio.comer: 5, Episodio.irAoTufo: 2, Episodio.vigiar: 1},
        };
      case ModoDaAtividade.nadar:
        return switch (_ep) {
          Episodio.remar => {
            Episodio.deslizar: 5,
            Episodio.boiar: 2,
            Episodio.remar: 1,
          },
          Episodio.deslizar => {Episodio.remar: 3, Episodio.boiar: 3},
          _ => {Episodio.remar: 5, Episodio.deslizar: 1},
        };
      case ModoDaAtividade.brincar:
        final gato = jeito.espreita > 0;
        return {
          Episodio.bote: gato ? 4 : 2,
          Episodio.disparada: gato ? 1.5 : 3,
          Episodio.reverencia: gato ? 0.6 : 2.5,
          Episodio.rodopio: 1.5,
          Episodio.pulinhos: 2,
          Episodio.pausa: _ep == Episodio.pausa ? 0 : 3,
        };
      case ModoDaAtividade.dormir:
        return {
          Episodio.sono: 4,
          Episodio.suspiro: 2,
          Episodio.sonho: 1.6,
          Episodio.ajeita: 0.6,
        };
      case ModoDaAtividade.livre:
        return {Episodio.pausa: 4};
    }
  }

  double _recencia(Episodio e) {
    final i = _historico.lastIndexOf(e);
    if (i < 0) return 1;
    final atras = _historico.length - i; // 1 = o último
    return math.min(1, 0.3 + 0.2 * atras);
  }

  void _escolheEpisodio() {
    final opcoes = _proximos();
    var total = 0.0;
    final pesos = <Episodio, double>{};
    for (final MapEntry(key: e, value: p) in opcoes.entries) {
      final w = p * _recencia(e);
      if (w <= 0) continue;
      pesos[e] = w;
      total += w;
    }
    var sorteio = _sorte.nextDouble() * total;
    var escolhido = pesos.keys.first;
    for (final MapEntry(key: e, value: w) in pesos.entries) {
      sorteio -= w;
      if (sorteio <= 0) {
        escolhido = e;
        break;
      }
    }
    _comecaEpisodio(escolhido);
  }

  double _entre(double a, double b) => a + _sorte.nextDouble() * (b - a);

  /// Duração de episódio com cauda longa (lognormal): a maioria curta, de
  /// vez em quando uma longa. É como os episódios de comportamento animal
  /// se distribuem (Minasandra et al., PNAS 2025); uniforme lê como
  /// máquina.
  double _dura(double mediana, {double min = 0.4, double max = 30}) =>
      _logNormal(mediana, 0.5).clamp(min, max);

  void _comecaEpisodio(Episodio e) {
    // O agachado de um episódio não vaza para o seguinte.
    _achata.alvo = 0;
    _ep = e;
    _epInicio = _t;
    _historico.add(e);
    if (_historico.length > 8) _historico.removeAt(0);
    switch (e) {
      case Episodio.comer:
        // Bocadas: cauda longa também (às vezes três, às vezes vinte).
        _mordidasFaltando = _logNormal(
          modo == ModoDaAtividade.pastar ? 7 : 4,
          0.55,
        ).round().clamp(2, 24);
        _proximaMordida = _t + _entre(0.35, 0.6);
        _epFim = double.infinity; // acaba quando as mordidas acabam
      case Episodio.mastigar:
        _ritmoMastiga = _entre(1.8, 2.8);
        _epFim = _t + _dura(2.6, min: 1.2, max: 9);
      case Episodio.vigiar:
        _epFim = _t + _dura(2.6, min: 1.2, max: 10);
        _proximoInteresse = _t;
      case Episodio.irAoTufo:
        final lado = _px > _meio
            ? -1
            : (_px < _meio ? 1 : (_sorte.nextBool() ? 1 : -1));
        final dist =
            _entre(18, 55) * (_sorte.nextDouble() < 0.75 ? lado : -lado);
        _alvoX = (_px + dist).clamp(_min, _max);
        _epFim = _t + 6;
      case Episodio.remar:
        _ritmoRemada = _entre(0.9, 1.5);
        final lado = _sorte.nextBool() ? 1 : -1;
        _alvoX = (_meio + lado * _meiaLargura * _entre(0.2, 0.9)).clamp(
          _min,
          _max,
        );
        _epFim = _t + _ritmoRemada * (3 + _sorte.nextInt(5));
      case Episodio.deslizar:
        _alvoX = (_px + _vx * 0.9).clamp(_min, _max);
        _epFim = _t + _dura(1.8, min: 0.8, max: 5);
      case Episodio.boiar:
        _alvoX = _px;
        _epFim = _t + _dura(4, min: 1.8, max: 14);
      case Episodio.bote:
        _alvoX = _px;
        _epFim = _t + (jeito.espreita > 0 ? _entre(0.7, 1.3) : 0.35) + 1.4;
        _boteSaltou = false;
      case Episodio.disparada:
        _voltasDaDisparada = 2 + _sorte.nextInt(3);
        _alvoX = _px > _meio ? _min : _max;
        _epFim = _t + 9;
      case Episodio.reverencia:
        _alvoX = _px;
        _epFim = _t + _entre(1.4, 2.2);
      case Episodio.rodopio:
        _alvoX = _px;
        _giros = 2 + _sorte.nextInt(3);
        _proximoGiro = _t + 0.15;
        _epFim = _t + 3;
      case Episodio.pulinhos:
        _alvoX = _px;
        _pulosFaltando = 2 + _sorte.nextInt(3);
        _proximoPulo = _t + 0.1;
        _epFim = _t + 4;
      case Episodio.sono:
        _epFim = _t + _dura(5, min: 2.5, max: 20);
      case Episodio.suspiro:
        _suspiroT = 0;
        _epFim = _t + 2.6;
      case Episodio.sonho:
        _proximoTremelique = _t + 0.2;
        _epFim = _t + _entre(1.4, 3);
      case Episodio.ajeita:
        _achata.empurra(-6);
        _inclina.empurra(_virado ? 1.2 : -1.2);
        _virado = !_virado;
        _epFim = _t + 1.6;
      case Episodio.pausa:
        _epFim = _t + _dura(5.5, min: 2.5, max: 20);
        // A pausa devolve o corpo ao cérebro livre: intenção nova.
        _fimDaIntencao = _t;

      // --- repertório -----------------------------------------------------
      case Episodio.piscadaLenta:
        _olhaPara(const Offset(0, -0.25), pisca: false);
        _passosDoEp = 0;
        _epFim = _t + _entre(2.2, 3.2);
      case Episodio.amassar:
        _epFim = _t + _dura(4, min: 2.5, max: 9);
      case Episodio.escutar:
        _passosDoEp = 0;
        _proximoDoEp = _t + _entre(1.0, 2.2);
        _epFim = _proximoDoEp + 1.6;
        _evento(EventoDaVida.orelha);
      case Episodio.balancarCabeca:
        _epFim = _t + _entre(1.0, 1.8);
      case Episodio.girarCabeca:
        _passosDoEp = 0;
        _proximoDoEp = _t;
        _epFim = _t + _entre(2.6, 3.6);
      case Episodio.inclinarCabeca:
        _olhaPara(const Offset(0, -0.2), pisca: false);
        _evento(EventoDaVida.orelha);
        _epFim = _t + _entre(1.4, 2.6);
      case Episodio.deitar:
        _epFim = _t + _dura(6, min: 3, max: 18);
      case Episodio.alisar:
        _passosDoEp = _sorte.nextBool() ? 1 : -1;
        _epFim = _t + _dura(2.6, min: 1.6, max: 6);
      case Episodio.microcochilo:
        _epFim = _t + _entre(1.5, 3.2);
      case Episodio.zurro:
        _epFim = _t + _entre(1.6, 2.6);
      case Episodio.recolher:
        _epFim = _t + _entre(2.6, 4.6);
      case Episodio.tomarSol:
        _epFim = _t + _dura(8, min: 4, max: 20);
      case Episodio.rolar:
        _passosDoEp = 2 + _sorte.nextInt(2);
        _proximoDoEp = _t + 0.1;
        _epFim = _t + 2.2;
      case Episodio.espiar:
        _epFim = _t + _dura(2.8, min: 1.6, max: 6);
      case Episodio.respirar:
        _epFim = _t + 4.2;
      case Episodio.saltoNaAgua:
        final dir = _virado ? -1.0 : 1.0;
        _vx = dir * 50;
        _alvoX = (_px + dir * 25).clamp(_min, _max);
        pula(250);
        _epFim = _t + 1.8;
      case Episodio.sonhoDePatinhas:
        _epFim = _t + _entre(2, 4.5);
      case Episodio.irParaZona:
        final d = destino;
        if (d == null) {
          _epFim = _t;
          break;
        }
        // Para um ponto sorteado dentro da zona, não para a borda.
        _alvoX = (_entre(d.$1, d.$2)).clamp(_min, _max);
        _epFim = _t + 30;
      case Episodio.comerNaAgua:
        final dir = _virado ? -1.0 : 1.0;
        _vx = dir * 50;
        _alvoX = (_px + dir * 16).clamp(_min, _max);
        _faseMastiga = 0;
        _epFim = _t + _entre(2, 3.4);
      case Episodio.entrarNaAgua:
      case Episodio.sairDaAgua:
        _passosDoEp = 0;
        _alvoX = _px;
        _epFim = _t + 4;
      case Episodio.voar:
        if (!podeAndar || _meiaLargura < 20) {
          _epFim = _t; // sem espaço para voar: escolhe outra coisa
          break;
        }
        _voando = true;
        _decolou = false;
        // Agacha antes de subir (antecipação): o impulso vem depois.
        _decolaEm = _t + 0.26;
        _batidas = 0;
        _planaAte = -1;
        _altitude.fixa(_y);
        _altitude.alvo = 0;
        final lado = _px > _meio ? -1.0 : 1.0;
        _alvoX = (_meio + lado * _meiaLargura * _entre(0.5, 1)).clamp(
          _min,
          _max,
        );
        _passosDoEp = 0;
        _epFim = _t + 12; // termina quando pousa
    }
  }

  /// O episódio cabe no modo de agora?
  bool _cabeNoModo(Episodio e) =>
      e == Episodio.irParaZona ||
      switch (modo) {
        ModoDaAtividade.nadar =>
          const {
                Episodio.remar,
                Episodio.deslizar,
                Episodio.boiar,
              }.contains(e) ||
              _naAgua.contains(e),
        ModoDaAtividade.dormir =>
          const {
                Episodio.sono,
                Episodio.suspiro,
                Episodio.sonho,
                Episodio.ajeita,
              }.contains(e) ||
              _noSono.contains(e),
        ModoDaAtividade.pastar || ModoDaAtividade.petiscar =>
          const {
                Episodio.comer,
                Episodio.mastigar,
                Episodio.vigiar,
                Episodio.irAoTufo,
                Episodio.pausa,
              }.contains(e) ||
              _naTerra.contains(e),
        ModoDaAtividade.brincar =>
          const {
                Episodio.bote,
                Episodio.disparada,
                Episodio.reverencia,
                Episodio.rodopio,
                Episodio.pulinhos,
                Episodio.pausa,
              }.contains(e) ||
              _naTerra.contains(e),
        ModoDaAtividade.livre => e == Episodio.pausa || _naTerra.contains(e),
      };

  /// Um passo dos episódios. Devolve se o corpo está livre (a pausa): o
  /// desenho mostra o ócio, com gestos, e o cérebro livre decide.
  bool _passoDosEpisodios(double dt) {
    if (_modoAntes != modo || !_cabeNoModo(_ep)) {
      if ((_modoAntes == ModoDaAtividade.nadar) !=
          (modo == ModoDaAtividade.nadar)) {
        _ultimaTroca = _t;
        // Saiu da água: a sacudida do corpo molhado.
        if (_modoAntes == ModoDaAtividade.nadar) {
          _evento(EventoDaVida.sacode, espera: 0);
        }
      }
      _modoAntes = modo;
      _comecaEpisodio(switch (modo) {
        ModoDaAtividade.pastar || ModoDaAtividade.petiscar => Episodio.comer,
        ModoDaAtividade.nadar => Episodio.remar,
        ModoDaAtividade.brincar => Episodio.pulinhos,
        ModoDaAtividade.dormir => Episodio.sono,
        ModoDaAtividade.livre => Episodio.pausa,
      });
    }
    // Fora de onde o momento pede: vai para lá antes de tudo.
    final d = destino;
    if (d != null &&
        _ep != Episodio.irParaZona &&
        _ep != Episodio.entrarNaAgua &&
        _ep != Episodio.sairDaAgua &&
        podeAndar &&
        _noChao &&
        !_voando &&
        (_px < d.$1 - 2 || _px > d.$2 + 2)) {
      _comecaEpisodio(Episodio.irParaZona);
    }
    if (_t >= _epFim) {
      // Chegou à beira e a água chama: entra.
      if (_ep == Episodio.irParaZona && chamadoPelaAgua) {
        // Da terra a água chama para entrar; da água, a terra chama para
        // sair. Sempre "entrar" fazia o nadador ir e voltar à beira para
        // sempre (auditoria de d59006a, 2).
        _comecaEpisodio(naAgua ? Episodio.sairDaAgua : Episodio.entrarNaAgua);
      } else {
        _escolheEpisodio();
      }
    }

    final u = _t - _epInicio;
    _reverencia = 0;
    var cabeca = 0.0;
    var forca = 0.0;
    var mastiga = 0.0;
    switch (_ep) {
      // --- pastar / petiscar ----------------------------------------------
      case Episodio.comer:
        final pasto = modo == ModoDaAtividade.pastar;
        cabeca = pasto
            ? 1
            : (0.5 + 0.5 * math.max(0.0, math.sin(_faseMordida * math.pi)));
        _alvoDoOlhar = Offset(_virado ? -0.25 : 0.25, 0.9);
        if (_t >= _proximaMordida) {
          _mordidasFaltando -= 1;
          _faseMordida = 0;
          _proximaMordida = _t + _entre(0.32, 0.62);
          // Pastando, de vez em quando um passinho com a cabeça no chão.
          if (pasto && _sorte.nextDouble() < 0.18) {
            _alvoX = (_px + _entre(4, 9) * (_virado ? -1 : 1)).clamp(
              _min,
              _max,
            );
          }
          if (_mordidasFaltando <= 0) _epFim = _t + 0.25;
        }
        _faseMordida = math.min(1, _faseMordida + dt / 0.24);
        // A bocada: a boca abre e fecha e a cabeça dá um puxão.
        mastiga = math.sin(_faseMordida * math.pi);
        cabeca += mastiga * 0.08;
      case Episodio.mastigar:
        cabeca = modo == ModoDaAtividade.pastar ? 0.12 : 0;
        _faseMastiga += dt * _ritmoMastiga;
        mastiga = 0.5 - 0.5 * math.cos(_faseMastiga * 2 * math.pi);
        _olharAoAcaso(intervalo: (1.0, 2.6), alcance: 0.5);
      case Episodio.vigiar:
        // Cabeça erguida, varrendo: para, olha, para, olha.
        if (_t >= _proximoInteresse) {
          _olhaPara(
            Offset(_entre(-1, 1), _entre(-0.3, 0.1)),
            pisca: _sorte.nextDouble() < 0.3,
          );
          _proximoInteresse = _t + _entre(0.45, 1.3);
          if (_sorte.nextDouble() < 0.35) _evento(EventoDaVida.orelha);
        }
      case Episodio.irAoTufo:
        cabeca = 0.3;
        _virado = _alvoX < _px;
        _alvoDoOlhar = Offset(_virado ? -0.6 : 0.6, 0.5);
        if ((_alvoX - _px).abs() < 2 && _vx.abs() < 2) {
          _evento(EventoDaVida.fareja, espera: 6);
          _epFim = math.min(_epFim, _t + 0.6);
        }

      // --- nadar ---------------------------------------------------------
      case Episodio.remar:
        forca = 1;
        _faseAtividade += dt / _ritmoRemada;
        // Chegou antes de acabar a remada: segue para o outro lado. Parar no
        // ponto e continuar batendo as patas era remar no lugar — na lagoa
        // do mundo a capivara ficava 20 s no mesmo palmo d'água.
        // Só em água larga: numa estreita todo alvo novo cai a menos de 3
        // e ele virava de lado várias vezes por segundo (auditoria).
        if (_meiaLargura > 12 &&
            (_alvoX - _px).abs() < 3 &&
            _epFim - _t > 1.2) {
          final lado = _px > _meio ? -1 : 1;
          _alvoX = (_meio + lado * _meiaLargura * _entre(0.35, 0.95)).clamp(
            _min,
            _max,
          );
        }
        _virado = _alvoX < _px;
        _alvoDoOlhar = Offset(_virado ? -0.5 : 0.5, 0);
      case Episodio.deslizar:
        forca = math.max(0, 1 - u * 2);
        _faseAtividade += dt / _ritmoRemada * forca;
      case Episodio.boiar:
        forca = 0.18;
        _faseAtividade += dt / 2.6;
        _olharAoAcaso(intervalo: (0.8, 2.2), alcance: 0.9);

      // --- brincar -------------------------------------------------------
      case Episodio.bote:
        final espreita = jeito.espreita > 0 ? _epFim - 1.4 - _epInicio : 0.35;
        if (u < espreita) {
          _achata.alvo = 0.7;
          _rebola = jeito.espreita > 0 ? math.sin(_t * 20) * 0.5 : 0;
          _alvoDoOlhar = Offset(_virado ? -0.7 : 0.7, 0.4);
        } else if (!_boteSaltou) {
          _boteSaltou = true;
          _achata.alvo = 0;
          final dir = _virado ? -1.0 : 1.0;
          final cabe = dir > 0 ? _max - _px : _px - _min;
          final salto = math.min(_entre(25, 50), cabe);
          _alvoX = (_px + dir * salto).clamp(_min, _max);
          _vx = dir * math.min(160, salto * 3);
          pula(_entre(230, 290));
        } else if (_noChao) {
          // Pegou! Olha para baixo, entre as patas.
          _alvoDoOlhar = Offset(_virado ? -0.3 : 0.3, 1);
        }
      case Episodio.disparada:
        _correndo = true;
        // Correndo, a frente abaixa e as patas abrem: corpo esticado para
        // a corrida. Sentado e pulando, a disparada lia como pulinho.
        _reverencia = 0.55;
        _virado = _alvoX < _px;
        if ((_alvoX - _px).abs() < 3) {
          _voltasDaDisparada -= 1;
          if (_voltasDaDisparada <= 0) {
            _epFim = math.min(_epFim, _t + 0.3);
            _agitacao = 1;
          } else {
            _alvoX = _alvoX > _meio ? _min : _max;
          }
        }
      case Episodio.reverencia:
        // Frente baixa, traseira alta, cauda a mil: "vamos brincar?".
        final e = math.sin(math.min(1.0, u / (_epFim - _epInicio)) * math.pi);
        _achata.alvo = 0.45 * e;
        _estica = 0.22 * e;
        _reverencia = e;
        _cauda.empurra(1.2);
        _alvoDoOlhar = const Offset(0, -0.2);
        if (u > (_epFim - _epInicio) * 0.8 && _noChao) pula(200);
      case Episodio.rodopio:
        if (_t >= _proximoGiro && _giros > 0) {
          _giros -= 1;
          // Um giro de verdade: o corpo vira no eixo (ver `giro`), e não
          // só espelha num quadro.
          _giroT = 0.001;
          _achata.empurra(3);
          pula(130);
          _proximoGiro = _t + _entre(0.28, 0.42);
          if (_giros == 0) _epFim = math.min(_epFim, _t + 0.6);
        }
      case Episodio.pulinhos:
        if (_noChao && _t >= _proximoPulo && _pulosFaltando > 0) {
          _pulosFaltando -= 1;
          pula(_entre(170, 300));
          _proximoPulo = _t + _entre(0.42, 0.7);
          if (_pulosFaltando == 0) _epFim = math.min(_epFim, _t + 0.8);
        }
        _alvoDoOlhar = const Offset(0, -0.3);

      // --- dormir --------------------------------------------------------
      case Episodio.sono:
        break;
      case Episodio.suspiro:
        _suspiroT += dt;
      case Episodio.sonho:
        if (_t >= _proximoTremelique) {
          _proximoTremelique = _t + _entre(0.15, 0.45);
          _inclina.empurra(_entre(-0.5, 0.5));
          if (_sorte.nextDouble() < 0.5) _cauda.empurra(_entre(-12, 12));
          if (_sorte.nextDouble() < 0.3) _evento(EventoDaVida.orelha);
          _rebola = _entre(-0.6, 0.6);
        }
      case Episodio.ajeita:
        break;

      case Episodio.pausa:
        break;

      // --- repertório ---------------------------------------------------
      case Episodio.piscadaLenta:
        _alvoDoOlhar = const Offset(0, -0.25);
        _cabecaDoEpisodio = Offset(0.05 * _ladoDoInclinar, 0);
        if (u > 0.5 && _passosDoEp == 0) {
          _passosDoEp = 1;
          _piscaAgora(lenta: true);
          _derretido = math.max(_derretido, 0.35);
        }
      case Episodio.amassar:
        // As patas da frente alternando, devagar; olhos semicerrados.
        _rebola = math.sin(_t * 8) * 0.7;
        _fechaOlhos = 0.6;
        _cabecaDoEpisodio = const Offset(0, 1.5);
      case Episodio.escutar:
        final dir = _virado ? -1.0 : 1.0;
        _alvoX = _px;
        if (_t < _proximoDoEp) {
          // Congela: cabeça erguida, mirando o chão à frente.
          _cabecaDoEpisodio = const Offset(0, -3);
          _alvoDoOlhar = Offset(dir * 0.5, 0.7);
        } else if (_passosDoEp == 0) {
          // O salto de caça: alto, caindo de patas da frente.
          _passosDoEp = 1;
          _alvoX = (_px + dir * 22).clamp(_min, _max);
          _vx = dir * 45;
          pula(340);
        } else {
          _alvoDoOlhar = Offset(dir * 0.2, 1);
          if (_noChao) _cabecaDoEpisodio = const Offset(0, 5);
        }
      case Episodio.balancarCabeca:
        // Para cima e para baixo, rápido: a coruja triangulando.
        _cabecaDoEpisodio = Offset(
          0,
          -math.max(0.0, math.sin(u * math.pi * 2 * 2.8)) * 6,
        );
        _alvoDoOlhar = Offset(_virado ? -0.5 : 0.5, 0.1);
      case Episodio.girarCabeca:
        if (_t >= _proximoDoEp) {
          _passosDoEp += 1;
          final lado = _ladoDoInclinar;
          _olhaPara(switch (_passosDoEp) {
            1 => Offset(lado * 1.3, -0.1),
            2 => Offset(-lado * 1.3, -0.1),
            _ => Offset.zero,
          }, pisca: false);
          _proximoDoEp = _t + _entre(0.8, 1.2);
        }
      case Episodio.inclinarCabeca:
        final e = math.sin(math.min(1.0, u / 0.35) * math.pi / 2);
        _cabecaDoEpisodio = Offset(_ladoDoInclinar * 0.24 * e, -1);
        _alvoDoOlhar = const Offset(0, -0.25);
      case Episodio.deitar:
        _achata.alvo = 0.55;
        _fechaOlhos = 0.3 + 0.25 * math.max(0.0, math.sin(u * 0.8));
        _alvoX = _px;
        _olharAoAcaso(intervalo: (1.5, 4), alcance: 0.6);
      case Episodio.alisar:
        final lado = _passosDoEp.toDouble();
        _alvoDoOlhar = Offset(lado, 0.6);
        _cabecaDoEpisodio = Offset(lado * 0.16, 5);
        _boca = 0.25 + 0.3 * math.sin(_t * 16).abs();
        _fechaOlhos = 0.5;
        if (_t + dt >= _epFim && _sorte.nextDouble() < 0.45) {
          _evento(EventoDaVida.sacode, espera: 10);
        }
      case Episodio.microcochilo:
        final dur = _epFim - _epInicio;
        _fechaOlhos = u < dur - 0.3 ? 1 : 0;
        _cabecaDoEpisodio = Offset(0, 4 * math.min(1.0, u / 0.6));
        if (_t + dt >= _epFim) {
          // Acorda num tranco, como quem cochilou em pé.
          _achata.empurra(5);
          _cabeca.empurra(const Offset(0, -2));
        }
      case Episodio.zurro:
        final dur = _epFim - _epInicio;
        final e = math.sin(math.min(1.0, u / dur) * math.pi);
        _cabecaDoEpisodio = Offset(0, -7 * e);
        _alvoDoOlhar = const Offset(0, -1);
        _boca = e > 0.4 ? 0.6 + 0.4 * math.sin(_t * 22).abs() : 0;
        _achata.alvo = -0.35 * e;
      case Episodio.recolher:
        final dur = _epFim - _epInicio;
        if (u < dur * 0.6) {
          _pescoco = -1;
          _fechaOlhos = 0.8;
        } else {
          _pescoco = 0.25;
          _olharAoAcaso(intervalo: (0.4, 0.9), alcance: 0.9);
        }
      case Episodio.tomarSol:
        _fechaOlhos = 0.85;
        _cabecaDoEpisodio = const Offset(0, -2);
        _pescoco = 0.6;
        _alvoX = _px;
      case Episodio.rolar:
        _sobeNaAgua.alvo = 3;
        if (_t >= _proximoDoEp && _passosDoEp > 0) {
          _passosDoEp -= 1;
          _virado = !_virado;
          _inclina.empurra(_virado ? 1.8 : -1.8);
          _proximoDoEp = _t + 0.45;
        }
      case Episodio.espiar:
        _sobeNaAgua.alvo = 11;
        _olharAoAcaso(intervalo: (0.5, 1.2), alcance: 1.0);
      case Episodio.respirar:
        if (u < 1.9) {
          _sobeNaAgua.alvo = 16;
          _alvoDoOlhar = const Offset(0, -0.6);
          if (u > 1.4) _boca = math.sin((u - 1.4) / 0.5 * math.pi);
        }
      case Episodio.saltoNaAgua:
        break;
      case Episodio.irParaZona:
        _virado = _alvoX < _px;
        _alvoDoOlhar = Offset(_virado ? -0.6 : 0.6, 0.1);
        forca = 1;
        _faseAtividade += dt / 1.1;
        if ((_alvoX - _px).abs() < 2 && _vx.abs() < 3) _epFim = _t;
      case Episodio.comerNaAgua:
        forca = u < 0.5 ? 1 : 0.2;
        _faseAtividade += dt / (u < 0.5 ? 0.5 : 2.4);
        _alvoDoOlhar = Offset(_virado ? -0.6 : 0.6, 0.4);
        if (u > 0.3 && u < 0.55) {
          // O bote: a boca abre de uma vez.
          mastiga = math.sin((u - 0.3) / 0.25 * math.pi);
        } else if (u >= 0.55) {
          _faseMastiga += dt * 2.6;
          mastiga = 0.5 - 0.5 * math.cos(_faseMastiga * 2 * math.pi);
        }
      case Episodio.entrarNaAgua:
      case Episodio.sairDaAgua:
        // Olha para onde vai, agacha, pula — e no alto do pulo a cena o
        // leva para o outro lugar.
        final entra = _ep == Episodio.entrarNaAgua;
        _alvoDoOlhar = Offset(0, entra ? 0.9 : -0.5);
        if (_passosDoEp == 0 && u > 0.8) {
          _passosDoEp = 1;
          _achata.alvo = 0.5;
        } else if (_passosDoEp == 1 && u > 1.2) {
          _passosDoEp = 2;
          _achata.alvo = 0;
          pula(entra ? 230 : 260);
        } else if (_passosDoEp == 2 && _vy < 0) {
          _passosDoEp = 3;
          _evento(entra ? EventoDaVida.querAgua : EventoDaVida.querTerra);
          _epFim = math.min(_epFim, _t + 1);
        }
      case Episodio.voar:
        if (!_decolou) {
          if (_t < _decolaEm) {
            _achata.alvo = 0.45;
          } else {
            _decolou = true;
            _achata.alvo = 0;
            _achata.empurra(-10);
            _altitude.alvo = _entre(80, 115);
          }
        }
        // Batidas: as primeiras, de decolagem, são mais rápidas; depois
        // de três ou quatro ela plana um pouco (batida e planeio).
        if (!_planando) {
          _faseAtividade +=
              dt /
              (_batidas < 2
                  ? 0.26
                  : _passosDoEp == 1
                  ? 0.24
                  : 0.36);
        }
        if (_faseAtividade.floor() != _faseAntes.floor()) {
          _batidas++;
          if (_passosDoEp == 0 && _batidas >= 3 && _sorte.nextDouble() < 0.5) {
            _planaAte = _t + _entre(0.8, 1.4);
          }
        }
        _faseAntes = _faseAtividade;
        // Pende para a frente cruzando; para trás freando.
        final pitch = !_decolou
            ? 0.0
            : _freando
            ? -0.2
            : _passosDoEp == 0
            ? 0.13
            : 0.0;
        _pitchDoVoo += (pitch - _pitchDoVoo) * (1 - math.exp(-dt * 5));
        _virado = _alvoX < _px;
        switch (_passosDoEp) {
          case 0: // cruzando
            _alvoDoOlhar = Offset(_virado ? -0.7 : 0.7, 0.3);
            if ((_alvoX - _px).abs() < 3) {
              _passosDoEp = 1;
              _proximoDoEp = _t + _entre(0.8, 1.6);
            }
          case 1: // pairando, mirando o chão
            // Olhar muito para baixo baixa as pálpebras: de longe ela
            // parecia voar de olhos fechados.
            _alvoDoOlhar = Offset(_virado ? -0.3 : 0.3, 0.45);
            if (_t >= _proximoDoEp) {
              _passosDoEp = 2;
              _altitude.alvo = 0;
            }
          default: // descendo para pousar
            _alvoDoOlhar = Offset(_virado ? -0.3 : 0.3, 0.35);
        }
        if (!_voando) _epFim = math.min(_epFim, _t + 0.5);
      case Episodio.sonhoDePatinhas:
        _rebola = math.sin(_t * 13) * 0.7;
        if (_sorte.nextDouble() < dt * 1.5) _evento(EventoDaVida.orelha);
    }
    _cabecaNoChao.alvo = cabeca;
    _cabecaNoChao.passo(dt);
    _forcaDaAtividade.alvo = forca;
    _forcaDaAtividade.passo(dt);
    _mastigando = mastiga;
    // Indo para a beira pela água ele nada, não anda (auditoria, 11).
    _desenhaLivre =
        _desenhoLivre.contains(_ep) &&
        !(_ep == Episodio.irParaZona && modo == ModoDaAtividade.nadar);
    return _ep == Episodio.pausa;
  }
}
