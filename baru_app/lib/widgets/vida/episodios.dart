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
}

extension _Episodios on MotorDeVida {
  /// Transições: de cada episódio, quanto pesa cada próximo. O peso cai
  /// para quem acabou de acontecer ([_recencia]) — sem isso a mesma
  /// sequência voltava em ciclo.
  Map<Episodio, double> _proximos() {
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
          Episodio.sono: 6,
          Episodio.suspiro: 2,
          Episodio.sonho: 1.6,
          Episodio.ajeita: 0.6,
        };
      case ModoDaAtividade.livre:
        return {Episodio.pausa: 1};
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
      final w = p * (e == _ep ? 1 : _recencia(e));
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
        final lado = _px > 0
            ? -1
            : (_px < 0 ? 1 : (_sorte.nextBool() ? 1 : -1));
        final dist =
            _entre(18, 55) * (_sorte.nextDouble() < 0.75 ? lado : -lado);
        _alvoX = (_px + dist).clamp(-areaDeAndar, areaDeAndar);
        _epFim = _t + 6;
      case Episodio.remar:
        _ritmoRemada = _entre(0.9, 1.5);
        final lado = _sorte.nextBool() ? 1 : -1;
        _alvoX = (lado * areaDeAndar * _entre(0.2, 0.9)).clamp(
          -areaDeAndar,
          areaDeAndar,
        );
        _epFim = _t + _ritmoRemada * (3 + _sorte.nextInt(5));
      case Episodio.deslizar:
        _alvoX = (_px + _vx * 0.9).clamp(-areaDeAndar, areaDeAndar);
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
        _alvoX = _px > 0 ? -areaDeAndar : areaDeAndar;
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
        _epFim = _t + _dura(7, min: 3, max: 25);
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
    }
  }

  /// Um passo dos episódios. Devolve se o corpo está livre (a pausa): o
  /// desenho mostra o ócio, com gestos, e o cérebro livre decide.
  bool _passoDosEpisodios(double dt) {
    if (modo == ModoDaAtividade.livre) return true;
    if (_ep == Episodio.pausa && modo == ModoDaAtividade.nadar ||
        _modoAntes != modo) {
      _modoAntes = modo;
      _comecaEpisodio(switch (modo) {
        ModoDaAtividade.pastar || ModoDaAtividade.petiscar => Episodio.comer,
        ModoDaAtividade.nadar => Episodio.remar,
        ModoDaAtividade.brincar => Episodio.pulinhos,
        ModoDaAtividade.dormir => Episodio.sono,
        ModoDaAtividade.livre => Episodio.pausa,
      });
    }
    if (_t >= _epFim) _escolheEpisodio();

    final u = _t - _epInicio;
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
              -areaDeAndar,
              areaDeAndar,
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
          final cabe = dir > 0 ? areaDeAndar - _px : areaDeAndar + _px;
          final salto = math.min(_entre(25, 50), cabe);
          _alvoX = (_px + dir * salto).clamp(-areaDeAndar, areaDeAndar);
          _vx = dir * math.min(160, salto * 3);
          pula(_entre(230, 290));
        } else if (_noChao) {
          // Pegou! Olha para baixo, entre as patas.
          _alvoDoOlhar = Offset(_virado ? -0.3 : 0.3, 1);
        }
      case Episodio.disparada:
        _correndo = true;
        _virado = _alvoX < _px;
        if ((_alvoX - _px).abs() < 3) {
          _voltasDaDisparada -= 1;
          if (_voltasDaDisparada <= 0) {
            _epFim = math.min(_epFim, _t + 0.3);
            _agitacao = 1;
          } else {
            _alvoX = _alvoX > 0 ? -areaDeAndar : areaDeAndar;
          }
        }
      case Episodio.reverencia:
        // Frente baixa, traseira alta, cauda a mil: "vamos brincar?".
        final e = math.sin(math.min(1.0, u / (_epFim - _epInicio)) * math.pi);
        _achata.alvo = 0.45 * e;
        _estica = 0.22 * e;
        _cauda.empurra(1.2);
        _alvoDoOlhar = const Offset(0, -0.2);
        if (u > (_epFim - _epInicio) * 0.8 && _noChao) pula(200);
      case Episodio.rodopio:
        if (_t >= _proximoGiro && _giros > 0) {
          _giros -= 1;
          _virado = !_virado;
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
    }
    _cabecaNoChao.alvo = cabeca;
    _cabecaNoChao.passo(dt);
    _forcaDaAtividade.alvo = forca;
    _forcaDaAtividade.passo(dt);
    _mastigando = mastiga;
    return _ep == Episodio.pausa;
  }
}
