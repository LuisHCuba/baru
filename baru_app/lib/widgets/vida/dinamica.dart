/// A física de que o bicho é feito: molas e ruído.
///
/// O bicho era animado por senos de período fixo — respira, boia, abana —
/// e um seno é um relógio: o mesmo movimento, idêntico, a cada volta. O olho
/// percebe isso em segundos e o bicho vira GIF. Aqui nada é função direta do
/// tempo:
///
/// - **Mola de segunda ordem** ([Mola], [Mola2]): cada parte do corpo
///   *persegue* um alvo com massa — atrasa, passa do ponto e assenta. É o que
///   dá peso, antecipação e o balanço que sobra depois de um movimento
///   (o "follow-through" dos 12 princípios da animação).
/// - **Ruído suave** ([Ruido]): variação contínua e sem repetição para o que
///   é ocioso — a respiração que às vezes é mais funda, o peso que troca de
///   pé, a cauda que ora abana, ora para.
///
/// A mola segue a formulação de "second order dynamics" (frequência `f`,
/// amortecimento `zeta`, resposta inicial `r`), integrada com passo semi-
/// implícito estável para qualquer `dt` de quadro.
library;

import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Uma grandeza que persegue um alvo como um corpo com massa.
///
/// - [f] (Hz): a velocidade da resposta. 1–2 é corpo; 3–6 é orelha e cauda.
/// - [zeta]: amortecimento. < 1 passa do ponto e balança; 1 chega sem
///   balançar; > 1 chega devagar.
/// - [r]: a resposta no instante da mudança. 0 começa parado; > 1 dá um
///   tranco para o lado certo antes; < 0 vai primeiro para o lado oposto —
///   a antecipação.
class Mola {
  Mola({
    required double f,
    required double zeta,
    double r = 0,
    double inicial = 0,
  })  : alvo = inicial,
        _y = inicial,
        _xp = inicial {
    ajusta(f: f, zeta: zeta, r: r);
  }

  late double _k1, _k2, _k3;

  /// O alvo atual.
  double alvo;
  double _y; // posição
  double _xp; // alvo anterior
  double _v = 0; // velocidade

  void ajusta({required double f, required double zeta, double r = 0}) {
    final w = 2 * math.pi * f;
    _k1 = zeta / (math.pi * f);
    _k2 = 1 / (w * w);
    _k3 = r * zeta / w;
  }

  double get valor => _y;
  double get velocidade => _v;

  /// Empurra a mola (um toque, um tranco), sem mexer no alvo.
  void empurra(double impulso) => _v += impulso;

  /// Teleporta: valor, alvo e velocidade.
  void fixa(double v) {
    alvo = v;
    _xp = v;
    _y = v;
    _v = 0;
  }

  double passo(double dt) {
    if (dt <= 0) return _y;
    final xd = (alvo - _xp) / dt;
    _xp = alvo;
    // Garante estabilidade com dt grande (quadro perdido, app voltando).
    final k2 = math.max(_k2, math.max(dt * dt / 2 + dt * _k1 / 2, dt * _k1));
    _y += dt * _v;
    _v += dt * (alvo + _k3 * xd - _y - _k1 * _v) / k2;
    return _y;
  }
}

/// A mesma mola em duas dimensões: o olhar, o corpo carregado pelo dedo.
class Mola2 {
  Mola2({required double f, required double zeta, double r = 0})
      : x = Mola(f: f, zeta: zeta, r: r),
        y = Mola(f: f, zeta: zeta, r: r);

  final Mola x;
  final Mola y;

  Offset get valor => Offset(x.valor, y.valor);
  Offset get velocidade => Offset(x.velocidade, y.velocidade);

  set alvo(Offset o) {
    x.alvo = o.dx;
    y.alvo = o.dy;
  }

  void fixa(Offset o) {
    x.fixa(o.dx);
    y.fixa(o.dy);
  }

  void empurra(Offset i) {
    x.empurra(i.dx);
    y.empurra(i.dy);
  }

  Offset passo(double dt) => Offset(x.passo(dt), y.passo(dt));
}

/// Ruído de valor 1D, suave e sem período, com oitavas.
///
/// Cada instância tem a sua semente: duas partes do corpo nunca andam em
/// passo. A saída fica em -1..1 (aproximadamente).
class Ruido {
  Ruido(int semente) : _tabela = _gera(semente);

  static const _n = 256;
  final List<double> _tabela;

  static List<double> _gera(int semente) {
    final r = math.Random(semente);
    return List.generate(_n, (_) => r.nextDouble() * 2 - 1);
  }

  double _base(double t) {
    final i = t.floor();
    final f = t - i;
    final a = _tabela[i % _n];
    final b = _tabela[(i + 1) % _n];
    // Interpolação quíntica: derivada contínua, sem "quinas" no movimento.
    final u = f * f * f * (f * (f * 6 - 15) + 10);
    return a + (b - a) * u;
  }

  /// [t] em segundos × frequência desejada. [oitavas] somam detalhe fino.
  double em(double t, {int oitavas = 2}) {
    var soma = 0.0, amp = 1.0, freq = 1.0, norma = 0.0;
    for (var o = 0; o < oitavas; o++) {
      soma += _base(t * freq + o * 31.7) * amp;
      norma += amp;
      amp *= 0.5;
      freq *= 2.03;
    }
    return soma / norma;
  }
}
