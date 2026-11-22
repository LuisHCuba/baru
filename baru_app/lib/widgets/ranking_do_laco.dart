import 'package:flutter/material.dart';

import '../data/ranking.dart';
import '../data/skills.dart';
import '../l10n.dart';
import '../l10n_ranking.dart';
import '../l10n_skills.dart';
import '../theme.dart';
import 'componentes.dart';
import 'skills_do_baru.dart';

const _skills = ['geral', 'inteligente', 'forte', 'saudavel'];

String _nomeDaChave(T t, String k) => k == 'geral' ? t.s('rkGeral') : nomeDaSkill(t, Skill.values.byName(k));
IconData _iconeDaChave(String k) => k == 'geral' ? Icons.emoji_events_rounded : iconeDaSkill(Skill.values.byName(k));
Color _corDaChave(String k) => k == 'geral' ? const Color(0xFFD4A017) : corDaSkill(Skill.values.byName(k));

/// Bloco "Ranking da semana" na aba Laços: os três primeiros no geral; tocar abre tudo.
class RankingDoLaco extends StatefulWidget {
  const RankingDoLaco({super.key, required this.laco, required this.t, required this.aoAssinar, this.repo});
  final String laco;
  final T t;
  final VoidCallback aoAssinar;
  final RankingRepo? repo;

  @override
  State<RankingDoLaco> createState() => _RankingDoLacoState();
}

class _RankingDoLacoState extends State<RankingDoLaco> {
  RankingDaSemana? _r;
  bool _falhou = false;
  late final RankingRepo _repo = widget.repo ?? RankingRepo();
  T get t => widget.t;

  @override
  void initState() {
    super.initState();
    garanteTextosDoRanking();
    garanteTextosDasSkills();
    _carrega();
  }

  @override
  void didUpdateWidget(RankingDoLaco antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.laco != widget.laco) _carrega();
  }

  Future<void> _carrega() async {
    try {
      final r = await _repo.daSemana(widget.laco);
      if (mounted) setState(() => (_r = r, _falhou = false));
    } catch (_) {
      if (mounted) setState(() => _falhou = true);
    }
  }

  Future<void> _abre() async {
    final r = _r;
    if (r == null) return;
    if (r.bloqueado) return widget.aoAssinar();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FolhaDoRanking(t: t, laco: widget.laco, repo: _repo, inicial: r),
    );
    _carrega();
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return CartaoBaru(
      key: const Key('laco-ranking'),
      padding: const EdgeInsets.all(Espaco.md),
      onTap: r == null ? null : _abre,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFD4A017)),
          const SizedBox(width: Espaco.xs),
          Expanded(child: Text(t.s('rkT'), style: estilo(Tipo.subtitulo))),
          if (r?.bloqueado == true) const Icon(Icons.lock_outline_rounded, size: 18, color: Cores.tinta500)
          else const Icon(Icons.chevron_right_rounded, color: Cores.tinta500),
        ]),
        const SizedBox(height: Espaco.xs),
        if (_falhou)
          Text(t.s('rkFalhou'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700))
        else if (r == null)
          const LinearProgressIndicator(minHeight: 2)
        else if (r.bloqueado) ...[
          for (final (i, m) in r.membros.take(3).indexed)
            _LinhaDoRanking(posicao: i + 1, nome: m.apelido, valor: '•••', eu: m.eu, t: t, cor: Cores.tinta500),
          const SizedBox(height: Espaco.xs),
          Text(t.s('rkBloqueado'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(key: const Key('ranking-assinar'), onPressed: widget.aoAssinar, child: Text(t.s('rkAssinar'))),
          ),
        ] else if (r.membros.every((m) => m.total == 0))
          Text(t.s('rkVazio'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700))
        else
          for (final (i, m) in r.por('geral').take(3).indexed)
            _LinhaDoRanking(posicao: i + 1, nome: m.apelido, valor: '${m.total} XP', eu: m.eu, t: t, cor: _corDaChave('geral')),
      ]),
    );
  }
}

class _LinhaDoRanking extends StatelessWidget {
  const _LinhaDoRanking({required this.posicao, required this.nome, required this.valor, required this.eu, required this.t,
      required this.cor, this.detalhe, this.selos = 0});
  final int posicao;
  final String nome;
  final String valor;
  final String? detalhe;
  final bool eu;
  final T t;
  final Color cor;
  final int selos;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(
            width: 28,
            child: Text(posicao <= 3 ? ['🥇', '🥈', '🥉'][posicao - 1] : '$posicao',
                style: estilo(Tipo.corpoForte), textAlign: TextAlign.center),
          ),
          const SizedBox(width: Espaco.xs),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eu ? '$nome (${t.s('rkVoce')})' : nome,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: estilo(eu ? Tipo.corpoForte : Tipo.corpo)),
              if (detalhe != null || selos > 0)
                Text([
                  if (detalhe != null) detalhe!,
                  if (selos > 0) selos == 1 ? t.s('rkSelo1') : t.fill(t.s('rkSelos'), {'n': selos}),
                ].join(' · '), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            ]),
          ),
          Text(valor, style: estilo(Tipo.corpoForte, color: cor)),
        ]),
      );
}

class _FolhaDoRanking extends StatefulWidget {
  const _FolhaDoRanking({required this.t, required this.laco, required this.repo, required this.inicial});
  final T t;
  final String laco;
  final RankingRepo repo;
  final RankingDaSemana inicial;

  @override
  State<_FolhaDoRanking> createState() => _FolhaDoRankingState();
}

class _FolhaDoRankingState extends State<_FolhaDoRanking> {
  late RankingDaSemana _r = widget.inicial;
  String _skill = 'geral';
  T get t => widget.t;

  Future<void> _participar(bool v) async {
    try {
      await widget.repo.participar(widget.laco, v);
      final r = await widget.repo.daSemana(widget.laco);
      if (mounted) setState(() => _r = r);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.s('rkFalhou'))));
    }
  }

  String? _detalhe(PosicaoNoRanking m) => switch (_skill) {
        'inteligente' when m.paginas > 0 => t.fill(t.s('rkPaginas'), {'n': m.paginas}),
        'forte' when m.minutos > 0 => t.fill(t.s('rkMinutos'), {'n': m.minutos}),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final lista = _r.por(_skill);
    final semanas = <DateTime, List<SeloDaSemana>>{};
    for (final s in _r.historico) {
      semanas.putIfAbsent(s.semana, () => []).add(s);
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, rolagem) => ListView(
        controller: rolagem,
        padding: const EdgeInsets.fromLTRB(Espaco.lg, Espaco.md, Espaco.lg, Espaco.xl),
        children: [
          Text(t.s('rkT'), style: estilo(Tipo.titulo)),
          Text(t.s('rkFecha'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
          const SizedBox(height: Espaco.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final k in _skills)
                Padding(
                  padding: const EdgeInsets.only(right: Espaco.xs),
                  child: ChoiceChip(
                    key: Key('ranking-skill-$k'),
                    avatar: Icon(_iconeDaChave(k), size: 16, color: _corDaChave(k)),
                    label: Text(_nomeDaChave(t, k)),
                    selected: _skill == k,
                    onSelected: (_) => setState(() => _skill = k),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: Espaco.sm),
          if (lista.every((m) => m.xpDe(_skill) == 0))
            Text(t.s('rkVazio'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700))
          else
            for (final (i, m) in lista.indexed)
              _LinhaDoRanking(
                posicao: i + 1,
                nome: m.apelido,
                valor: '${m.xpDe(_skill)} XP',
                detalhe: _detalhe(m),
                selos: _skill == 'geral' ? m.selos : 0,
                eu: m.eu,
                t: t,
                cor: _corDaChave(_skill),
              ),
          const SizedBox(height: Espaco.lg),
          Text(t.s('rkHistorico'), style: estilo(Tipo.subtitulo)),
          const SizedBox(height: Espaco.xs),
          if (semanas.isEmpty)
            Text(t.s('rkSemHistorico'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta500))
          else
            for (final e in semanas.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Espaco.sm),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.fill(t.s('rkSemanaDe'), {'d': t.formatLongDate(e.key)}), style: estilo(Tipo.rotulo, color: Cores.tinta700)),
                  Wrap(spacing: Espaco.xs, runSpacing: 4, children: [
                    for (final s in e.value)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(_iconeDaChave(s.skill), size: 14, color: _corDaChave(s.skill)),
                        label: Text('${_nomeDaChave(t, s.skill)}: ${_r.nomeDe(s.id)}'),
                      ),
                  ]),
                ]),
              ),
          const Divider(height: Espaco.lg),
          SwitchListTile(
            key: const Key('ranking-participar'),
            contentPadding: EdgeInsets.zero,
            title: Text(t.s('rkParticipar'), style: estilo(Tipo.corpoForte)),
            subtitle: Text(t.s('rkParticiparNota'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
            value: !_r.euFora,
            onChanged: _participar,
          ),
        ],
      ),
    );
  }
}
