/// As peças de vitrine da loja.
///
/// A loja era uma grade de quadrados com um recorte do item no meio de cada
/// um. O problema não era o tamanho do quadrado: era o **fundo**. Um objeto
/// de cena desenhado sobre bege não diz nada — a pessoa não compra um
/// retângulo verde, compra o que o lago fica sendo depois dele.
///
/// Então a miniatura aqui pinta a cena de verdade — o mesmo céu, a mesma
/// colina, a mesma água do habitat — e coloca o item **no lugar exato onde
/// ele vai ficar**, com um zoom em volta. É a diferença entre um catálogo de
/// peças e uma vitrine.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'habitat.dart';
import 'pet.dart';

/// A cena do habitat, em miniatura.
///
/// Repete a geometria de `_FundoDaCena` (céu, astro, duas colinas, água,
/// margem, brilhos). Repetir não é de graça: se a cena mudar lá, muda-se
/// aqui também. A alternativa era pintar um gradiente inventado atrás do
/// item — e aí a miniatura mentiria sobre onde o item vai parar, que é a
/// única coisa que ela tem para dizer.
class CenaEmMiniatura extends CustomPainter {
  const CenaEmMiniatura({
    required this.luz,
    required this.recorte,
    this.pecas = const [],
  });

  final LuzDaCena luz;

  /// O pedaço da cena que cabe na caixa, em coordenadas de
  /// `HabitatScene.design`. A cena inteira é `Rect.fromLTWH(0, 0, 372, 296)`.
  final Rect recorte;

  /// As peças do item, nas coordenadas da cena.
  final List<ShapePart> pecas;

  /// O tamanho da cena de origem. Igual a `HabitatScene.design`.
  static const cena = Size(372, 296);

  /// A linha d'água, na cena de origem.
  static const alturaDaAgua = 118.0;

  /// O recorte que enquadra um item.
  ///
  /// Centraliza no item e sobra mundo em volta — sem a sobra, a miniatura
  /// vira o mesmo quadrado de antes, só que maior. O fator 2,1 foi escolhido
  /// para o item ocupar cerca de metade da largura: menos que isso e ele
  /// some no cenário, mais e o cenário deixa de aparecer.
  ///
  /// Item pequeno demais (um cogumelo tem 26 px) ganha um mínimo, senão o
  /// zoom fica tão fechado que a cena atrás vira uma mancha de cor.
  static Rect recorteDe(List<ShapePart> pecas, double proporcao) {
    if (pecas.isEmpty) return Offset.zero & cena;

    var e = double.infinity, t = double.infinity;
    var d = -double.infinity, b = -double.infinity;
    for (final p in pecas) {
      e = math.min(e, p.x);
      t = math.min(t, p.y);
      d = math.max(d, p.x + p.w);
      b = math.max(b, p.y + p.h);
    }
    final centro = Offset((e + d) / 2, (t + b) / 2);

    var largura = math.max(d - e, 46) * 2.1;
    var altura = largura / proporcao;
    // O item também não pode transbordar na vertical: mato é alto e estreito.
    final minimoVertical = (b - t) * 1.6;
    if (altura < minimoVertical) {
      altura = minimoVertical;
      largura = altura * proporcao;
    }
    // Nunca maior que a cena — recorte maior que o mundo mostra vazio.
    if (largura > cena.width) {
      largura = cena.width;
      altura = largura / proporcao;
    }
    if (altura > cena.height) {
      altura = cena.height;
      largura = altura * proporcao;
    }
    return Rect.fromLTWH(
      (centro.dx - largura / 2).clamp(0.0, cena.width - largura),
      (centro.dy - altura / 2).clamp(0.0, cena.height - altura),
      largura,
      altura,
    );
  }

  /// O recorte que enquadra o companheiro, para a miniatura de roupa.
  ///
  /// A linha d'água fica a 55% da altura porque é onde ela cai no habitat
  /// com o bicho de pé: a roupa aparece com o mesmo horizonte atrás que ela
  /// vai ter na cena.
  static Rect recorteDoBicho(double proporcao) {
    const altura = 150.0;
    final largura = math.min(altura * proporcao, cena.width);
    return Rect.fromLTWH(
      ((cena.width - largura) / 2).clamp(0.0, cena.width - largura),
      cena.height - alturaDaAgua - altura * 0.55,
      largura,
      altura,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (recorte.width <= 0 || recorte.height <= 0) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(size.width / recorte.width, size.height / recorte.height);
    canvas.translate(-recorte.left, -recorte.top);
    _mundo(canvas);
    _itens(canvas);
    canvas.restore();
  }

  void _mundo(Canvas canvas) {
    const w = 372.0;
    const h = 296.0;
    const tudo = Rect.fromLTWH(0, 0, w, h);

    canvas.drawRect(
      tudo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [luz.ceuAlto, luz.ceuBaixo],
        ).createShader(tudo),
    );

    // Sol ou lua, na mesma altura que o habitat calcula.
    final ay = h * (0.30 - luz.astroAlto * 0.20);
    canvas.drawCircle(Offset(w - 54, ay), 46, Paint()..color = luz.haloAstro);
    canvas.drawCircle(Offset(w - 54, ay), 26, Paint()..color = luz.astro);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(-34, 104, 224, 130),
        topLeft: const Radius.circular(112),
        topRight: const Radius.circular(112),
      ),
      Paint()..color = luz.colina.withValues(alpha: 0.85),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(210, 92, 206, 140),
        topLeft: const Radius.circular(104),
        topRight: const Radius.circular(104),
      ),
      Paint()..color = luz.colina.withValues(alpha: 0.62),
    );

    const topoDaAgua = h - alturaDaAgua;
    const agua = Rect.fromLTWH(0, topoDaAgua, w, alturaDaAgua);
    canvas.drawRect(
      agua,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [luz.agua, luz.aguaFunda],
        ).createShader(agua),
    );

    // A margem é uma curva por cima da água. Reta, ela vira uma tarja.
    final margem = Path()
      ..moveTo(0, topoDaAgua + 10)
      ..cubicTo(
        w * 0.26,
        topoDaAgua - 16,
        w * 0.62,
        topoDaAgua + 14,
        w,
        topoDaAgua - 10,
      )
      ..lineTo(w, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, topoDaAgua - 34, w, 52));
    canvas.drawPath(margem, Paint()..color = luz.areia.withValues(alpha: 0.72));
    canvas.restore();

    _brilho(canvas, const Offset(38, h - 76), 62, luz.brilho);
    _brilho(
      canvas,
      const Offset(w - 102, h - 44),
      46,
      luz.brilho.withValues(alpha: 0.6),
    );

    // A luz ambiente por cima é o que faz a noite pesar; sem ela, o cenário
    // de noite fica só um céu diferente.
    if (luz.sombraAmbiente.a > 0) {
      canvas.drawRect(tudo, Paint()..color = luz.sombraAmbiente);
    }
  }

  void _brilho(Canvas canvas, Offset o, double largura, Color cor) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy, largura, 4),
        const Radius.circular(4),
      ),
      Paint()..color = cor,
    );
  }

  void _itens(Canvas canvas) {
    for (final p in pecas) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x, p.y, p.w, p.h),
        Radius.circular(p.r),
      );
      // A mesma sombra curta do habitat. Sem ela a peça parece adesivo
      // colado no fundo — e na miniatura isso aparece ainda mais.
      canvas.drawRRect(
        r.shift(const Offset(0, 2)),
        Paint()
          ..color = Cores.tintaA(0.13)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(r, Paint()..color = p.c);
    }
  }

  @override
  bool shouldRepaint(covariant CenaEmMiniatura old) =>
      old.luz != luz || old.recorte != recorte || old.pecas != pecas;
}

/// A miniatura de um item da loja, já recortada e arredondada.
class MiniaturaDaLoja extends StatelessWidget {
  const MiniaturaDaLoja({
    super.key,
    required this.item,
    required this.luz,
    required this.altura,
    this.raio = Raio.campo,
  });

  final ShopItemDef item;

  /// A luz de agora — a mesma do habitat. **Um cenário ignora esta luz e
  /// acende com a sua**: a miniatura de "noite estrelada" com o sol das
  /// cinco da tarde vende a coisa errada, e foi o que aconteceu na primeira
  /// captura desta tela.
  final LuzDaCena luz;
  final double altura;
  final double raio;

  @override
  Widget build(BuildContext context) {
    final luzDoCartao = item.categoria == CategoriaDeItem.cenario
        ? (LuzDaCena.doCenario(item.id) ?? luz)
        : luz;
    return ClipRRect(
      borderRadius: Raio.todos(raio),
      child: SizedBox(
        height: altura,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, c) {
            // A proporção sai da caixa medida, não de um palpite: recorte com
            // proporção errada distorce a cena.
            final proporcao = c.maxWidth <= 0 || c.maxHeight <= 0
                ? 1.0
                : c.maxWidth / c.maxHeight;
            final recorte = switch (item.categoria) {
              // O cenário é o mundo inteiro: mostrar um pedaço dele seria
              // mostrar justamente o que ele não é.
              CategoriaDeItem.cenario => const Rect.fromLTWH(0, 0, 372, 296),
              CategoriaDeItem.roupa =>
                CenaEmMiniatura.recorteDoBicho(proporcao),
              CategoriaDeItem.objeto =>
                CenaEmMiniatura.recorteDe(item.parts, proporcao),
            };
            return CustomPaint(
              painter: CenaEmMiniatura(
                luz: luzDoCartao,
                recorte: recorte,
                pecas: item.parts,
              ),
              child: item.categoria == CategoriaDeItem.roupa
                  ? _BichoVestido(item: item)
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/// A roupa mostrada **no bicho**. Um quadradinho colorido não vende roupa —
/// e a espécie é a do usuário, porque é nela que a peça vai ficar.
class _BichoVestido extends StatelessWidget {
  const _BichoVestido({required this.item});

  final ShopItemDef item;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Center(
      child: PetView(
        species: app.species,
        mood: Mood.content,
        activity: Activity.idle,
        coat: app.color,
        scale: 0.46,
        width: 148,
        height: 96,
        interativo: false,
        roupas: {item.vestimenta!: item.cor!},
        roupaDeCabeca: item.id,
      ),
    );
  }
}

/// O botão de um item: preço, cadeado, colocar ou tirar.
///
/// Pílula e não retângulo, e sempre com ícone: numa prateleira de doze
/// cartões, a pessoa lê a **forma** antes de ler a palavra.
class PilulaDaLoja extends StatelessWidget {
  const PilulaDaLoja({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.ativo,
    required this.cor,
    required this.aoTocar,
    this.corTexto,
    this.altura = 36,
  });

  final String rotulo;
  final IconData icone;
  final bool ativo;
  final Color cor;
  final Color? corTexto;
  final VoidCallback aoTocar;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final texto = corTexto ?? (ativo ? Cores.superficie : Cores.tintaA(0.45));
    return Semantics(
      button: true,
      enabled: ativo,
      label: rotulo,
      child: GestureDetector(
        onTap: ativo ? aoTocar : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: altura,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: Espaco.xs),
          decoration: BoxDecoration(
            color: ativo ? cor : Cores.tintaA(0.06),
            borderRadius: Raio.todos(Raio.pilula),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, size: 15, color: texto),
              const SizedBox(width: Espaco.xxs),
              Flexible(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.rotulo, color: texto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A etiqueta que fica no canto da miniatura: "Seu", "Em uso".
class SeloDaLoja extends StatelessWidget {
  const SeloDaLoja({
    super.key,
    required this.texto,
    required this.icone,
    required this.cor,
  });

  final String texto;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espaco.xs,
        vertical: Espaco.xxs,
      ),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: Raio.todos(Raio.pilula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: Cores.superficie),
          const SizedBox(width: 3),
          Text(
            texto,
            style: estilo(Tipo.rotuloPequeno, color: Cores.superficie),
          ),
        ],
      ),
    );
  }
}
