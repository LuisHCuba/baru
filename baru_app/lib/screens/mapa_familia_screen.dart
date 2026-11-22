import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../data/familia.dart';
import '../l10n.dart';
import '../l10n_familia.dart';
import '../services/foto_de_perfil.dart';
import '../services/localizacao.dart';
import '../theme.dart';

/// "Há quanto tempo", curto: agora mesmo, 5 min, 2 h, 3 d.
String haQuanto(T t, DateTime em, {DateTime? agora}) {
  final d = (agora ?? DateTime.now()).difference(em);
  if (d.inMinutes < 1) return t.s('locAgoraMesmo');
  final v = d.inMinutes < 60
      ? t.fill(t.s('locMin'), {'n': d.inMinutes})
      : d.inHours < 24
          ? t.fill(t.s('locH'), {'n': d.inHours})
          : t.fill(t.s('locD'), {'n': d.inDays});
  return t.fill(t.s('locHa'), {'t': v});
}

/// Uma linha sobre onde a criança está: "Em Escola · há 5 min · bateria 80%".
String linhaDoLocal(T t, PosicaoDaCrianca p, {DateTime? agora}) => [
      p.lugar != null ? t.fill(t.s('locEm'), {'l': p.lugar!}) : t.s('locFora'),
      haQuanto(t, p.em, agora: agora),
      if (p.bateria != null && p.bateria! >= 0) t.fill(t.s('locBateria'), {'n': p.bateria!}),
    ].join(' · ');

/// Por que a posição da criança falta ou está velha, para o responsável saber
/// o que fazer. Nulo quando está tudo certo (posição recente).
///
/// A ordem importa: primeiro o que impede de vez (celular não conectado,
/// sem permissão), depois o que é passageiro (sem sinal, pedido a caminho).
String? diagnosticoDoLocal(T t, CriancaNoMapa c, {DateTime? agora}) {
  if (!c.localizacao) return null;
  final hoje = agora ?? DateTime.now();
  final n = {'n': c.apelido};
  final ap = c.aparelho;
  if (ap == null) return t.fill(t.s('locDiagSemAparelho'), n);
  switch (ap.localEstado) {
    case 'negada':
    case 'nao_pedida':
      return t.fill(t.s('locDiagNegada'), n);
    case 'desligada':
      return t.fill(t.s('locDiagDesligada'), n);
    case 'quando_usa':
      return t.fill(t.s('locDiagQuandoUsa'), n);
  }
  final ultima = c.atual?.em;
  final pedido = c.pedidoEm;
  if (pedido != null && hoje.difference(pedido).inMinutes < 10 && (ultima == null || ultima.isBefore(pedido))) {
    return t.fill(t.s('locDiagAguardando'), {...n, 't': haQuanto(t, pedido, agora: hoje)});
  }
  if (ap.localEstado == null) return t.fill(t.s('locDiagVersao'), n);
  final sinal = [ultima, ap.vistoEm].whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
  if (sinal == null || hoje.difference(sinal).inHours >= 3) {
    return t.fill(t.s('locDiagSemSinal'), {...n, 't': sinal == null ? '' : haQuanto(t, sinal, agora: hoje)}).replaceAll('  ', ' ');
  }
  return null;
}

/// Mapa da família (só o responsável): onde cada criança está, os lugares
/// combinados e o caminho das últimas 24 horas ou 7 dias.
///
/// Mapa do OpenStreetMap, sem chave. Tocar e segurar no mapa marca um lugar.
class MapaFamiliaScreen extends StatefulWidget {
  const MapaFamiliaScreen({
    super.key,
    required this.familiaId,
    required this.t,
    required this.repo,
    this.focoCriancaId,
    this.semMapa = false,
    this.principal = false,
    this.titulo,
    this.avisosNoTopo = const [],
    this.detalheDaPessoa,
    this.acoesDaFolha = const [],
    this.aoAdicionar,
    this.recarga = 0,
    this.foco,
  });

  /// Quem está fora pede para o mapa ir até uma pessoa (ex.: o aviso de SOS).
  final ValueNotifier<String?>? foco;

  /// Muda quando a tela de fora mudou algo (localização ligada, criança nova): relê o mapa.
  final int recarga;

  /// Aba Família do responsável: o mapa é a tela (sem voltar, ninguém
  /// escolhido de início, todos à vista).
  final bool principal;

  /// Título da folha (o nome da família, na aba).
  final String? titulo;

  /// Avisos por cima do mapa (SOS recente, notificações desligadas).
  final List<Widget> avisosNoTopo;

  /// O que mostrar da pessoa escolhida além do lugar (tempo de tela, regras).
  final Widget Function(BuildContext context, String criancaId)? detalheDaPessoa;

  /// Ações no fim da folha, sem ninguém escolhido (adicionar, convidar).
  final List<Widget> acoesDaFolha;

  /// Botão "+" no canto do mapa.
  final VoidCallback? aoAdicionar;

  final String familiaId;
  final T t;
  final FamiliaRepo repo;
  final String? focoCriancaId;

  /// Para os testes: não baixa os quadrinhos do mapa.
  final bool semMapa;

  @override
  State<MapaFamiliaScreen> createState() => _MapaFamiliaScreenState();
}

class _MapaFamiliaScreenState extends State<MapaFamiliaScreen> {
  final _mapa = MapController();
  MapaDaFamilia _dados = MapaDaFamilia.vazio;
  List<PosicaoDaCrianca> _rastro = const [];
  String? _selecionada;
  int _horas = 24;
  String? _erro;
  bool _carregou = false;
  Timer? _relogio;

  /// Estilo do OpenFreeMap (grátis, sem chave, uso comercial permitido).
  /// Lido uma vez por sessão; sem rede, fica o OpenStreetMap simples.
  static Future<Style>? _estiloCache;
  Style? _estilo;

  /// Satélite por padrão; o botão do canto troca para o mapa desenhado.
  bool _satelite = true;

  /// Câmera e altura da folha: as bolinhas de quem saiu da tela vão na borda.
  final _camera = ValueNotifier<MapCamera?>(null);
  final _folha = DraggableScrollableController();
  final _alturaDaFolha = ValueNotifier<double>(0.32);

  /// Botões e avisos do topo: as bolinhas da borda ficam abaixo deles.
  final _topoKey = GlobalKey();

  T get t => widget.t;

  @override
  void initState() {
    super.initState();
    garanteTextosDaFamilia();
    _selecionada = widget.focoCriancaId;
    if (!widget.semMapa) {
      _estiloCache ??= StyleReader(uri: 'https://tiles.openfreemap.org/styles/liberty').read();
      _estiloCache!.then((e) {
        if (mounted) setState(() => _estilo = e);
      }).catchError((Object _) {
        _estiloCache = null;
      });
    }
    widget.foco?.addListener(_vaiParaOFoco);
    unawaited(_carrega(centraliza: true).then((_) => _mandaMinhaPosicao()));
    // Posição nova chega sozinha (pedido do responsável, mudança de lugar).
    // A minha vai a cada 5 minutos enquanto o mapa está aberto.
    var ticks = 0;
    _relogio = Timer.periodic(const Duration(seconds: 30), (_) {
      if (++ticks % 10 == 0) unawaited(_mandaMinhaPosicao());
      _carrega();
    });
  }

  void _vaiParaOFoco() {
    final id = widget.foco?.value;
    final c = _dados.criancas.where((x) => x.id == id).firstOrNull;
    if (c != null) _seleciona(c);
    widget.foco?.value = null;
  }

  @override
  void didUpdateWidget(MapaFamiliaScreen antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.recarga != widget.recarga) unawaited(_carrega());
  }

  @override
  void dispose() {
    widget.foco?.removeListener(_vaiParaOFoco);
    _relogio?.cancel();
    _camera.dispose();
    _alturaDaFolha.dispose();
    _folha.dispose();
    super.dispose();
  }

  Future<void> _carrega({bool centraliza = false}) async {
    try {
      final d = await widget.repo.mapa(widget.familiaId);
      if (!widget.principal) _selecionada ??= d.criancas.where((c) => c.atual != null).firstOrNull?.id;
      final rastro = _selecionada == null ? const <PosicaoDaCrianca>[] : await widget.repo.rastro(_selecionada!, horas: _horas);
      if (!mounted) return;
      setState(() {
        _dados = d;
        _rastro = rastro;
        _erro = null;
        _carregou = true;
      });
      if (centraliza) _centraliza();
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  void _centraliza() {
    if (widget.semMapa) return;
    final pontos = [
      for (final c in _dados.criancas)
        if (c.atual != null && (_selecionada == null || c.id == _selecionada)) LatLng(c.atual!.lat, c.atual!.lng),
      if (_selecionada == null)
        for (final r in _dados.responsaveis)
          if (r.atual != null) LatLng(r.atual!.lat, r.atual!.lng),
      if (_selecionada == null)
        for (final l in _dados.lugares) LatLng(l.lat, l.lng),
    ];
    if (pontos.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (pontos.length == 1) {
          // No meio da parte do mapa que a folha não cobre.
          final h = MediaQuery.of(context).size.height;
          _mapa.move(pontos.first, 15, offset: Offset(0, -h * _alturaDaFolha.value / 2));
        } else {
          final h = MediaQuery.of(context).size.height;
          _mapa.fitCamera(CameraFit.coordinates(coordinates: pontos, padding: EdgeInsets.fromLTRB(60, 140, 60, 60 + h * _alturaDaFolha.value), maxZoom: 16));
        }
      } catch (_) {}
    });
  }

  Future<void> _pede(CriancaNoMapa c) async {
    try {
      await widget.repo.pedirLocal(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.s('locPedido'))));
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  Future<void> _editaLugar({LatLng? em, LugarDaFamilia? lugar}) async {
    final r = await showDialog<_LugarEditado>(
      context: context,
      builder: (_) => _DialogoDoLugar(t: t, lugar: lugar),
    );
    if (r == null) return;
    try {
      if (r.apagar && lugar != null) {
        await widget.repo.apagarLugar(lugar.id);
      } else {
        final p = em ?? LatLng(lugar!.lat, lugar.lng);
        await widget.repo.salvarLugar(widget.familiaId, id: lugar?.id, nome: r.nome, lat: p.latitude, lng: p.longitude, raioM: r.raio);
      }
      await _carrega();
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  Widget _mapaWidget() {
    final centro = _dados.criancas.where((c) => c.atual != null).map((c) => LatLng(c.atual!.lat, c.atual!.lng)).firstOrNull ??
        _dados.lugares.map((l) => LatLng(l.lat, l.lng)).firstOrNull ??
        const LatLng(-23.5505, -46.6333);
    return FlutterMap(
      mapController: _mapa,
      options: MapOptions(
        initialCenter: centro,
        initialZoom: 14,
        onLongPress: (_, p) => _editaLugar(em: p),
        onMapReady: () => _camera.value = _mapa.camera,
        onPositionChanged: (camera, _) => _camera.value = camera,
      ),
      children: [
        // Mapa limpo do OpenFreeMap; enquanto o estilo carrega (ou sem rede),
        // o OpenStreetMap simples segura a tela.
        if (_satelite) ...[
          // Satélite (Esri World Imagery) com ruas e nomes por cima, como no Life360.
          TileLayer(
            urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'tech.lhcx.baru',
            maxNativeZoom: 19,
            maxZoom: 20,
          ),
          TileLayer(
            urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Transportation/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'tech.lhcx.baru',
            maxNativeZoom: 19,
            maxZoom: 20,
          ),
          TileLayer(
            urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: 'tech.lhcx.baru',
            maxNativeZoom: 19,
            maxZoom: 20,
          ),
        ] else if (_estilo case final e?)
          VectorTileLayer(theme: e.theme, sprites: e.sprites, tileProviders: e.providers, maximumZoom: 19)
        else
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'tech.lhcx.baru',
            maxZoom: 19,
          ),
        CircleLayer(circles: [
          for (final l in _dados.lugares)
            CircleMarker(
              point: LatLng(l.lat, l.lng),
              radius: l.raioM.toDouble(),
              useRadiusInMeter: true,
              color: Cores.primariaA(0.15),
              borderColor: Cores.primariaEscura,
              borderStrokeWidth: 2,
            ),
        ]),
        if (_rastro.length > 1)
          PolylineLayer(polylines: [
            Polyline(points: [for (final p in _rastro) LatLng(p.lat, p.lng)], strokeWidth: 4, color: Cores.folha600.withValues(alpha: 0.7)),
          ]),
        MarkerLayer(markers: [
          for (final l in _dados.lugares)
            Marker(
              // Na borda de cima do círculo: no centro cobriria a criança.
              point: LatLng(l.lat + l.raioM / 111320, l.lng),
              width: 120,
              height: 28,
              child: GestureDetector(
                onTap: () => _editaLugar(lugar: l),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Cores.primariaEscura)),
                    child: Text(l.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo(Tipo.rotuloPequeno)),
                  ),
                ),
              ),
            ),
          for (final c in _dados.criancas)
            if (c.atual != null)
              Marker(
                point: LatLng(c.atual!.lat, c.atual!.lng),
                width: c.id == _selecionada ? 58 : 50,
                height: c.id == _selecionada ? 58 : 50,
                child: GestureDetector(
                  onTap: () => _seleciona(c),
                  // Bolinha com borda branca e sombra, como nos apps de localização.
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.atual!.motivo == 'sos' ? Cores.alerta : Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: FotoOuLetra(
                      dono: c.id,
                      versao: c.foto,
                      nome: c.apelido,
                      raio: (c.id == _selecionada ? 58 : 50) / 2 - 3,
                      cor: c.atual!.motivo == 'sos' ? Cores.alerta : (c.id == _selecionada ? Cores.primariaEscura : Cores.folha600),
                    ),
                  ),
                ),
              ),
          // Responsáveis que escolheram aparecer (você incluído), com borda azul.
          for (final r in _dados.responsaveis)
            if (r.atual != null)
              Marker(
                point: LatLng(r.atual!.lat, r.atual!.lng),
                width: 46,
                height: 46,
                child: GestureDetector(
                  key: Key('resp-${r.id}'),
                  onTap: () => _vaiPara(r.atual!),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2F6FDE),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: FotoOuLetra(dono: r.id, versao: r.foto, nome: r.apelido, raio: 20, cor: const Color(0xFF2F6FDE)),
                  ),
                ),
              ),
        ]),
        RichAttributionWidget(attributions: [
          if (_satelite) const TextSourceAttribution('Esri, Maxar, Earthstar Geographics') else TextSourceAttribution(t.s('locAtribuicao')),
          if (!_satelite && _estilo != null) const TextSourceAttribution('OpenFreeMap'),
        ]),
      ],
    );
  }

  /// O lugar salvo onde a posição cai (o rastro do servidor não traz o nome).
  String? _lugarDe(PosicaoDaCrianca p) {
    if (p.lugar != null) return p.lugar;
    const d = Distance();
    for (final l in _dados.lugares) {
      if (d.as(LengthUnit.Meter, LatLng(l.lat, l.lng), LatLng(p.lat, p.lng)) <= l.raioM) return l.nome;
    }
    return null;
  }

  /// O rastro em trechos: cada lugar (ou "fora") com início e fim, o mais novo primeiro.
  List<_Trecho> _trechos() {
    final out = <_Trecho>[];
    for (final p in _rastro) {
      final lugar = _lugarDe(p);
      final ultimo = out.isEmpty ? null : out.last;
      if (ultimo != null && ultimo.lugar == lugar) {
        ultimo.fim = p.em;
        ultimo.ponto = p;
        ultimo.sos = ultimo.sos || p.motivo == 'sos';
      } else {
        out.add(_Trecho(lugar: lugar, inicio: p.em, fim: p.em, ponto: p, sos: p.motivo == 'sos'));
      }
    }
    return out.reversed.toList();
  }

  void _seleciona(CriancaNoMapa c) {
    setState(() {
      _selecionada = c.id;
      _rastro = const [];
    });
    _carrega(centraliza: true);
    // Sobe a folha o bastante para mostrar a pessoa.
    if (_folha.isAttached && _folha.size < 0.45) {
      _folha.animateTo(0.45, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
  }

  /// Leva o mapa até um ponto, sem abrir ninguém (responsáveis).
  void _vaiPara(PosicaoDaCrianca p) {
    if (widget.semMapa) return;
    final h = MediaQuery.of(context).size.height;
    _mapa.move(LatLng(p.lat, p.lng), 16, offset: Offset(0, -h * _alturaDaFolha.value / 2));
  }

  /// Este celular é de responsável e escolheu aparecer: manda a posição.
  Future<void> _mandaMinhaPosicao() async {
    if (_dados.eu?.ligada != true) return;
    try {
      final p = await LocalNativo.agora();
      if (p == null) return;
      await widget.repo.minhaPosicao(lat: p.lat, lng: p.lng, precisaoM: p.precisaoM, bateria: p.bateria);
    } catch (_) {}
  }

  /// Ligar pede consentimento e a permissão de localização deste celular.
  Future<void> _ligaMeuLocal(bool ligar) async {
    if (ligar) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.s('locEuT')),
          content: Text(t.s('locEuCorpo'), style: estilo(Tipo.corpo)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.s('locCancelar'))),
            TextButton(key: const Key('eu-consentir'), onPressed: () => Navigator.pop(ctx, true), child: Text(t.s('locEuOk'))),
          ],
        ),
      );
      if (ok != true) return;
      var perm = await LocalNativo.estado();
      if (!perm.concedida) perm = await LocalNativo.pedir(sempre: false);
      if (!perm.concedida) {
        if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.s('locEuSemPermissao'))));
        return;
      }
    }
    try {
      await widget.repo.meuLocal(ligada: ligar);
      await _carrega();
      if (ligar) {
        await _mandaMinhaPosicao();
        await _carrega(centraliza: true);
      }
    } catch (e) {
      if (mounted) setState(() => _erro = '$e');
    }
  }

  void _soltaSelecao() {
    setState(() {
      _selecionada = null;
      _rastro = const [];
    });
    _centraliza();
  }

  /// Bolinhas de quem está fora da parte visível do mapa, presas na borda e
  /// apontando para onde a pessoa está. Tocar leva até ela.
  Widget _bolinhasDaBorda(double topo) {
    return AnimatedBuilder(
      animation: Listenable.merge([_camera, _alturaDaFolha]),
      builder: (context, _) {
        final camera = _camera.value;
        if (camera == null) return const SizedBox.shrink();
        return LayoutBuilder(builder: (context, caixa) {
          const r = 24.0;
          final w = caixa.maxWidth, h = caixa.maxHeight;
          // Abaixo dos botões e dos avisos do topo (a altura deles muda).
          final caixaDoTopo = _topoKey.currentContext?.findRenderObject() as RenderBox?;
          final alturaDoTopo = caixaDoTopo != null && caixaDoTopo.hasSize ? caixaDoTopo.size.height : 56.0;
          final cima = topo + alturaDoTopo + r + 8;
          final baixo = h * (1 - _alturaDaFolha.value) - r - 8;
          final esq = r + 8, dir = w - r - 8;
          if (baixo <= cima) return const SizedBox.shrink();
          final filhos = <Widget>[];
          for (final c in _dados.criancas) {
            final p = c.atual;
            if (p == null) continue;
            final o = camera.latLngToScreenOffset(LatLng(p.lat, p.lng));
            if (o.dx >= esq && o.dx <= dir && o.dy >= cima && o.dy <= baixo) continue;
            final x = o.dx.clamp(esq, dir).toDouble(), y = o.dy.clamp(cima, baixo).toDouble();
            final angulo = math.atan2(o.dy - y, o.dx - x);
            filhos.add(Positioned(
              left: x - r,
              top: y - r,
              child: _BolinhaDaBorda(
                key: Key('borda-${c.id}'),
                dono: c.id,
                versao: c.foto,
                nome: c.apelido,
                sos: p.motivo == 'sos',
                angulo: angulo,
                raio: r,
                aoTocar: () => _seleciona(c),
              ),
            ));
          }
          for (final rp in _dados.responsaveis) {
            final p = rp.atual;
            if (p == null) continue;
            final o = camera.latLngToScreenOffset(LatLng(p.lat, p.lng));
            if (o.dx >= esq && o.dx <= dir && o.dy >= cima && o.dy <= baixo) continue;
            final x = o.dx.clamp(esq, dir).toDouble(), y = o.dy.clamp(cima, baixo).toDouble();
            filhos.add(Positioned(
              left: x - r,
              top: y - r,
              child: _BolinhaDaBorda(
                key: Key('borda-${rp.id}'),
                dono: rp.id,
                versao: rp.foto,
                nome: rp.apelido,
                sos: false,
                cor: const Color(0xFF2F6FDE),
                angulo: math.atan2(o.dy - y, o.dx - x),
                raio: r,
                aoTocar: () => _vaiPara(p),
              ),
            ));
          }
          return Stack(children: filhos);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String hm(DateTime d) => TimeOfDay.fromDateTime(d).format(context);
    final selecionada = _dados.criancas.where((c) => c.id == _selecionada).firstOrNull;
    final trechos = _trechos();
    final topo = MediaQuery.of(context).padding.top;
    final pessoas = _dados.criancas;
    final inicial = widget.principal ? 0.32 : 0.30;
    return Scaffold(
      backgroundColor: Cores.canvas,
      body: Stack(children: [
        // O mapa ocupa a tela inteira; a folha sobe por cima.
        Positioned.fill(child: widget.semMapa ? const ColoredBox(color: Cores.trilho) : _mapaWidget()),
        if (!widget.semMapa) Positioned.fill(child: IgnorePointer(ignoring: false, child: _bolinhasDaBorda(topo + Espaco.xs))),
        Positioned(
          top: topo + Espaco.xs,
          left: Espaco.sm,
          right: Espaco.sm,
          child: Column(key: _topoKey, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (!widget.principal)
                _BotaoRedondo(icone: Icons.arrow_back_rounded, dica: MaterialLocalizations.of(context).backButtonTooltip, aoTocar: () => Navigator.of(context).maybePop()),
              const Spacer(),
              _BotaoRedondo(
                icone: _satelite ? Icons.map_outlined : Icons.satellite_alt_rounded,
                dica: t.s(_satelite ? 'locVerMapaDesenhado' : 'locVerSatelite'),
                aoTocar: () => setState(() => _satelite = !_satelite),
              ),
              const SizedBox(width: Espaco.xs),
              _BotaoRedondo(icone: Icons.center_focus_strong_rounded, dica: t.s('locMapaT'), aoTocar: _centraliza),
              const SizedBox(width: Espaco.xs),
              _BotaoRedondo(icone: Icons.refresh_rounded, dica: t.s('locAtualizar'), aoTocar: () => _carrega(centraliza: true)),
              if (widget.aoAdicionar != null) ...[
                const SizedBox(width: Espaco.xs),
                _BotaoRedondo(icone: Icons.person_add_alt_1_rounded, dica: t.s('famAddCrianca'), aoTocar: widget.aoAdicionar!),
              ],
            ]),
            for (final a in widget.avisosNoTopo) ...[const SizedBox(height: Espaco.xs), a],
          ]),
        ),
        NotificationListener<DraggableScrollableNotification>(
          onNotification: (n) {
            _alturaDaFolha.value = n.extent;
            return false;
          },
          child: DraggableScrollableSheet(
            controller: _folha,
            // O mapa é o protagonista: a folha começa baixa, só com as pessoas.
            initialChildSize: inicial,
            minChildSize: 0.14,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: [inicial, 0.60],
            builder: (context, rolagem) => Material(
              color: Cores.canvas,
              elevation: 8,
              surfaceTintColor: Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Raio.folha)),
              child: ListView(controller: rolagem, padding: const EdgeInsets.fromLTRB(Espaco.md, Espaco.xs, Espaco.md, Espaco.xl), children: [
                Center(
                  child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: Espaco.sm),
                      decoration: BoxDecoration(color: Cores.tintaA(0.2), borderRadius: BorderRadius.circular(2))),
                ),
                if (_erro != null) Text(_erro!, style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
                if (!_carregou && _erro == null) const Padding(padding: EdgeInsets.all(Espaco.md), child: Center(child: CircularProgressIndicator())),
                if (selecionada == null) ...[
                  // Todos: uma linha por pessoa.
                  Text(widget.titulo ?? t.s('locMapaT'), style: estilo(Tipo.titulo)),
                  const SizedBox(height: Espaco.xs),
                  for (final c in pessoas)
                    _LinhaDaPessoa(
                      t: t,
                      crianca: c,
                      escolhida: false,
                      aoTocar: () => _seleciona(c),
                      aoAtualizar: c.localizacao ? () => _pede(c) : null,
                    ),
                  if (_dados.responsaveis.isNotEmpty) ...[
                    const SizedBox(height: Espaco.sm),
                    Text(t.s('locResponsaveis').toUpperCase(),
                        style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700).copyWith(letterSpacing: 0.8)),
                    for (final r in _dados.responsaveis)
                      _LinhaDoResponsavel(
                        t: t,
                        responsavel: r,
                        aoTocar: r.atual == null ? null : () => _vaiPara(r.atual!),
                        aoMostrar: r.eu ? _ligaMeuLocal : null,
                      ),
                  ],
                  if (_carregou && pessoas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
                      child: Text(t.s('famSemCriancasCorpo'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                    ),
                  ...widget.acoesDaFolha,
                ] else ...[
                  // Uma pessoa: quem é, onde está, o tempo de tela e o caminho.
                  Row(children: [
                    IconButton(
                      key: const Key('mapa-todos'),
                      tooltip: t.s('locTodos'),
                      onPressed: _soltaSelecao,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(child: Text(t.s('locTodos'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700))),
                  ]),
                  _LinhaDaPessoa(
                    t: t,
                    crianca: selecionada,
                    escolhida: true,
                    aoTocar: _centraliza,
                    aoAtualizar: selecionada.localizacao ? () => _pede(selecionada) : null,
                  ),
                  if (widget.detalheDaPessoa != null) ...[
                    const SizedBox(height: Espaco.sm),
                    widget.detalheDaPessoa!(context, selecionada.id),
                  ],
                  const SizedBox(height: Espaco.md),
                  Row(children: [
                    Expanded(child: Text(t.s('locHistorico'), style: estilo(Tipo.subtitulo))),
                    for (final h in const [24, 168]) ...[
                      const SizedBox(width: Espaco.xxs),
                      ChoiceChip(
                        label: Text(t.s(h == 24 ? 'locRastro24' : 'locRastro7')),
                        selected: _horas == h,
                        onSelected: (_) {
                          setState(() => _horas = h);
                          _carrega();
                        },
                      ),
                    ],
                  ]),
                  const SizedBox(height: Espaco.xs),
                  if (trechos.isEmpty)
                    Text(t.s('locHistoricoVazio'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700))
                  else
                    for (var i = 0; i < trechos.length && i < 40; i++)
                      _LinhaDoTrecho(
                        key: Key('trecho-$i'),
                        titulo: trechos[i].lugar ?? t.s('locForaDosLugares'),
                        horario: i == 0 && DateTime.now().difference(trechos[i].fim).inMinutes < 30
                            ? '${hm(trechos[i].inicio)} – ${t.s('locAte')}'
                            : trechos[i].inicio == trechos[i].fim
                                ? hm(trechos[i].inicio)
                                : '${hm(trechos[i].inicio)} – ${hm(trechos[i].fim)}',
                        dia: DateUtils.isSameDay(trechos[i].inicio, DateTime.now()) ? null : '${trechos[i].inicio.day}/${trechos[i].inicio.month}',
                        conhecido: trechos[i].lugar != null,
                        sos: trechos[i].sos,
                        primeiro: i == 0,
                        ultimo: i == trechos.length - 1 || i == 39,
                        aoTocar: widget.semMapa ? null : () => _mapa.move(LatLng(trechos[i].ponto.lat, trechos[i].ponto.lng), 16),
                      ),
                ],
                const SizedBox(height: Espaco.lg),
                Text(t.s('locLugares'), style: estilo(Tipo.subtitulo)),
                const SizedBox(height: Espaco.xs),
                if (_dados.lugares.isEmpty)
                  Text(t.s('locSemLugares'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700))
                else
                  for (final l in _dados.lugares)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.place_rounded, color: Cores.primariaEscura),
                      title: Text(l.nome),
                      subtitle: Text(t.fill(t.s('locRaio'), {'n': l.raioM})),
                      onTap: () {
                        if (!widget.semMapa) _mapa.move(LatLng(l.lat, l.lng), 16);
                      },
                      trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editaLugar(lugar: l)),
                    ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Um responsável na folha do mapa. O deste celular tem o botão de mostrar.
class _LinhaDoResponsavel extends StatelessWidget {
  const _LinhaDoResponsavel({required this.t, required this.responsavel, this.aoTocar, this.aoMostrar});
  final T t;
  final ResponsavelNoMapa responsavel;
  final VoidCallback? aoTocar;
  final ValueChanged<bool>? aoMostrar;

  @override
  Widget build(BuildContext context) {
    final r = responsavel;
    final nome = r.eu ? t.s('locVoce') : r.apelido;
    final linha = !r.ligada
        ? t.s(r.eu ? 'locEuDesligada' : 'locRespDesligada')
        : r.atual == null
            ? t.s('locEuSemPosicao')
            : linhaDoLocal(t, r.atual!);
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(Raio.cartao),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.xs, vertical: Espaco.sm),
        child: Row(children: [
          FotoOuLetra(dono: r.id, versao: r.foto, nome: r.apelido, raio: 22, cor: const Color(0xFF2F6FDE)),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nome, style: estilo(Tipo.subtitulo)),
              Text(linha, style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            ]),
          ),
          if (aoMostrar != null)
            Switch(key: const Key('eu-mostrar'), value: r.ligada, onChanged: aoMostrar),
        ]),
      ),
    );
  }
}

/// Bolinha presa na borda do mapa, com uma setinha para onde a pessoa está.
class _BolinhaDaBorda extends StatelessWidget {
  const _BolinhaDaBorda({super.key, required this.dono, required this.versao, required this.nome, required this.sos, required this.angulo, required this.raio, required this.aoTocar, this.cor});
  final Color? cor;
  final String dono;
  final DateTime? versao;
  final String nome;
  final bool sos;
  final double angulo;
  final double raio;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = sos ? Cores.alerta : (this.cor ?? Cores.primariaEscura);
    return GestureDetector(
      onTap: aoTocar,
      child: SizedBox(
        width: raio * 2,
        height: raio * 2,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          // Setinha apontando para a pessoa, na borda da bolinha.
          Transform.rotate(
            angle: angulo,
            child: Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(8, 0),
                child: Icon(Icons.play_arrow_rounded, size: 18, color: cor),
              ),
            ),
          ),
          Container(
            width: raio * 2,
            height: raio * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: sos ? Cores.alerta : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.all(3),
            child: FotoOuLetra(dono: dono, versao: versao, nome: nome, raio: raio - 3, cor: cor),
          ),
        ]),
      ),
    );
  }
}

class _Trecho {
  _Trecho({required this.lugar, required this.inicio, required this.fim, required this.ponto, required this.sos});
  final String? lugar;
  final DateTime inicio;
  DateTime fim;
  PosicaoDaCrianca ponto;
  bool sos;
}

class _BotaoRedondo extends StatelessWidget {
  const _BotaoRedondo({required this.icone, required this.dica, required this.aoTocar});
  final IconData icone;
  final String dica;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        child: IconButton(tooltip: dica, icon: Icon(icone, color: Cores.tinta), onPressed: aoTocar),
      );
}

/// Uma pessoa na folha do mapa: inicial, onde está, há quanto tempo, bateria.
class _LinhaDaPessoa extends StatelessWidget {
  const _LinhaDaPessoa({required this.t, required this.crianca, required this.escolhida, required this.aoTocar, this.aoAtualizar});
  final T t;
  final CriancaNoMapa crianca;
  final bool escolhida;
  final VoidCallback aoTocar;
  final VoidCallback? aoAtualizar;

  @override
  Widget build(BuildContext context) {
    final c = crianca;
    final sos = c.atual?.motivo == 'sos';
    return Material(
      color: escolhida ? Cores.primariaA(0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(Raio.cartao),
      child: InkWell(
        borderRadius: BorderRadius.circular(Raio.cartao),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Espaco.xs, vertical: Espaco.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FotoOuLetra(
              dono: c.id,
              versao: c.foto,
              nome: c.apelido,
              raio: 22,
              cor: sos ? Cores.alerta : (escolhida ? Cores.primariaEscura : Cores.folha600),
            ),
            const SizedBox(width: Espaco.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.apelido, style: estilo(Tipo.subtitulo)),
                Text(
                  c.atual == null ? t.fill(t.s('locSemPosicao'), {'n': c.apelido}) : linhaDoLocal(t, c.atual!),
                  style: estilo(Tipo.corpoPequeno, color: sos ? Cores.alerta : Cores.tinta700),
                ),
                if (diagnosticoDoLocal(t, c) case final motivo?)
                  Text(motivo, key: Key('mapa-motivo-${c.id}'), style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
              ]),
            ),
            IconButton(
              tooltip: t.s('locAtualizar'),
              onPressed: aoAtualizar,
              icon: const Icon(Icons.my_location_rounded, color: Cores.primariaEscura),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Um trecho do histórico, numa linha do tempo vertical.
class _LinhaDoTrecho extends StatelessWidget {
  const _LinhaDoTrecho({
    super.key,
    required this.titulo,
    required this.horario,
    required this.conhecido,
    required this.sos,
    required this.primeiro,
    required this.ultimo,
    this.dia,
    this.aoTocar,
  });
  final String titulo;
  final String horario;
  final String? dia;
  final bool conhecido;
  final bool sos;
  final bool primeiro;
  final bool ultimo;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final cor = sos ? Cores.alerta : (conhecido ? Cores.primariaEscura : Cores.tinta500);
    return InkWell(
      onTap: aoTocar,
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
            width: 28,
            child: Column(children: [
              Expanded(child: Container(width: 2, color: primeiro ? Colors.transparent : Cores.tintaA(0.15))),
              Icon(sos ? Icons.sos_rounded : (conhecido ? Icons.place_rounded : Icons.circle), size: conhecido || sos ? 20 : 10, color: cor),
              Expanded(child: Container(width: 2, color: ultimo ? Colors.transparent : Cores.tintaA(0.15))),
            ]),
          ),
          const SizedBox(width: Espaco.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titulo, style: estilo(conhecido || sos ? Tipo.corpoForte : Tipo.corpo, color: sos ? Cores.alerta : Cores.tinta)),
                Text([if (dia != null) dia!, horario].join(' · '), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LugarEditado {
  const _LugarEditado(this.nome, this.raio, {this.apagar = false});
  final String nome;
  final int raio;
  final bool apagar;
}

class _DialogoDoLugar extends StatefulWidget {
  const _DialogoDoLugar({required this.t, this.lugar});
  final T t;
  final LugarDaFamilia? lugar;

  @override
  State<_DialogoDoLugar> createState() => _DialogoDoLugarState();
}

class _DialogoDoLugarState extends State<_DialogoDoLugar> {
  late final _nome = TextEditingController(text: widget.lugar?.nome ?? '');
  late double _raio = (widget.lugar?.raioM ?? 150).toDouble();

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return AlertDialog(
      title: Text(widget.lugar == null ? t.s('locNovoLugar') : widget.lugar!.nome),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          key: const Key('lugar-nome'),
          controller: _nome,
          autofocus: widget.lugar == null,
          maxLength: 40,
          decoration: InputDecoration(labelText: t.s('locNomeLugar'), hintText: t.s('locNomeDica')),
        ),
        Text(t.fill(t.s('locRaio'), {'n': _raio.round()})),
        Slider(value: _raio, min: 50, max: 1000, divisions: 19, onChanged: (v) => setState(() => _raio = v)),
      ]),
      actions: [
        if (widget.lugar != null)
          TextButton(
            onPressed: () => Navigator.pop(context, _LugarEditado('', 0, apagar: true)),
            child: Text(t.s('locApagar'), style: const TextStyle(color: Cores.alerta)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.s('locCancelar'))),
        TextButton(
          key: const Key('lugar-salvar'),
          onPressed: () {
            final n = _nome.text.trim();
            if (n.isEmpty) return;
            Navigator.pop(context, _LugarEditado(n, _raio.round()));
          },
          child: Text(t.s('locSalvar')),
        ),
      ],
    );
  }
}
