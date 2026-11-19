import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/familia.dart';
import '../l10n.dart';
import '../l10n_familia.dart';
import '../theme.dart';
import '../widgets/componentes.dart';

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

/// Mapa da família (só o responsável): onde cada criança está, os lugares
/// combinados e o caminho das últimas 24 horas ou 7 dias.
///
/// Mapa do OpenStreetMap, sem chave. Tocar e segurar no mapa marca um lugar.
class MapaFamiliaScreen extends StatefulWidget {
  const MapaFamiliaScreen({super.key, required this.familiaId, required this.t, required this.repo, this.focoCriancaId, this.semMapa = false});

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

  T get t => widget.t;

  @override
  void initState() {
    super.initState();
    garanteTextosDaFamilia();
    _selecionada = widget.focoCriancaId;
    unawaited(_carrega(centraliza: true));
    // Posição nova chega sozinha (pedido do responsável, mudança de lugar).
    _relogio = Timer.periodic(const Duration(seconds: 30), (_) => _carrega());
  }

  @override
  void dispose() {
    _relogio?.cancel();
    super.dispose();
  }

  Future<void> _carrega({bool centraliza = false}) async {
    try {
      final d = await widget.repo.mapa(widget.familiaId);
      _selecionada ??= d.criancas.where((c) => c.atual != null).firstOrNull?.id;
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
        for (final l in _dados.lugares) LatLng(l.lat, l.lng),
    ];
    if (pontos.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (pontos.length == 1) {
          _mapa.move(pontos.first, 15);
        } else {
          _mapa.fitCamera(CameraFit.coordinates(coordinates: pontos, padding: const EdgeInsets.all(60), maxZoom: 16));
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
      ),
      children: [
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
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selecionada = c.id);
                    _carrega(centraliza: true);
                  },
                  child: CircleAvatar(
                    backgroundColor: c.atual!.motivo == 'sos' ? Cores.alerta : (c.id == _selecionada ? Cores.primariaEscura : Cores.folha600),
                    child: Text(c.apelido.characters.first.toUpperCase(), style: estilo(Tipo.subtitulo, color: Colors.white)),
                  ),
                ),
              ),
        ]),
        RichAttributionWidget(attributions: [TextSourceAttribution(t.s('locAtribuicao'))]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Cores.canvas,
      appBar: AppBar(
        title: Text(t.s('locMapaT')),
        backgroundColor: Cores.canvas,
        actions: [
          IconButton(tooltip: t.s('locAtualizar'), icon: const Icon(Icons.refresh_rounded), onPressed: () => _carrega(centraliza: true)),
        ],
      ),
      body: Column(children: [
        Expanded(
          flex: 3,
          child: widget.semMapa ? const ColoredBox(color: Cores.trilho) : _mapaWidget(),
        ),
        Expanded(
          flex: 2,
          child: ListView(padding: const EdgeInsets.all(Espaco.md), children: [
            if (_erro != null) Text(_erro!, style: estilo(Tipo.corpoPequeno, color: Cores.alerta)),
            if (!_carregou && _erro == null) const Center(child: CircularProgressIndicator()),
            for (final c in _dados.criancas.where((c) => c.localizacao || c.atual != null)) ...[
              CartaoBaru(
                onTap: () {
                  setState(() => _selecionada = c.id);
                  _carrega(centraliza: true);
                },
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.person_pin_circle_rounded, color: c.id == _selecionada ? Cores.primariaEscura : Cores.tinta700),
                    const SizedBox(width: Espaco.xs),
                    Expanded(child: Text(c.apelido, style: estilo(Tipo.subtitulo))),
                    TextButton.icon(
                      onPressed: c.localizacao ? () => _pede(c) : null,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: Text(t.s('locAtualizar')),
                    ),
                  ]),
                  Text(
                    c.atual == null ? t.fill(t.s('locSemPosicao'), {'n': c.apelido}) : linhaDoLocal(t, c.atual!),
                    style: estilo(Tipo.corpoPequeno, color: c.atual?.motivo == 'sos' ? Cores.alerta : Cores.tinta700),
                  ),
                  if (c.id == _selecionada) ...[
                    const SizedBox(height: Espaco.xs),
                    Wrap(spacing: Espaco.xs, children: [
                      Text('${t.s('locRastro')}:', style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700)),
                      for (final h in const [24, 168])
                        ChoiceChip(
                          label: Text(t.s(h == 24 ? 'locRastro24' : 'locRastro7')),
                          selected: _horas == h,
                          onSelected: (_) {
                            setState(() => _horas = h);
                            _carrega();
                          },
                        ),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: Espaco.sm),
            ],
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
      ]),
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
