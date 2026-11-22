import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/skills.dart';
import '../l10n.dart';
import '../l10n_skills.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

/// As três barras das skills (Saudável, Inteligente, Forte) e o botão Registrar.
///
/// Saudável sobe sozinho: quando o tempo de tela está liberado e o dia de
/// hoje (depois das 21h) ou o de ontem fechou dentro da meta, o app avisa o
/// servidor, que dá 20 XP uma vez por dia.
class SkillsDoBaru extends StatefulWidget {
  const SkillsDoBaru({super.key, required this.app, this.repo});
  final AppState app;
  final SkillsRepo? repo;

  @override
  State<SkillsDoBaru> createState() => _SkillsDoBaruState();
}

class _SkillsDoBaruState extends State<SkillsDoBaru> {
  MinhasSkills _skills = MinhasSkills.vazio;
  bool _carregou = false;
  late final SkillsRepo _repo = widget.repo ?? SkillsRepo();

  T get t => widget.app.t;

  @override
  void initState() {
    super.initState();
    garanteTextosDasSkills();
    _carrega();
  }

  Future<void> _carrega() async {
    try {
      var s = await _repo.minhas();
      if (_deveDarSaudavel()) s = await _repo.saudavelDeHoje();
      if (mounted) setState(() => (_skills = s, _carregou = true));
    } catch (_) {
      if (mounted) setState(() => _carregou = true);
    }
  }

  bool _deveDarSaudavel() {
    final app = widget.app;
    if (!app.usageAccess || !app.underGoal) return false;
    return DateTime.now().hour >= 21;
  }

  Future<void> _registrar() async {
    final novo = await showModalBottomSheet<MinhasSkills>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FolhaDeRegistro(t: t, repo: _repo, antes: _skills),
    );
    if (novo == null || !mounted) return;
    final antes = _skills;
    setState(() => _skills = novo);
    for (final s in Skill.values) {
      final n = novo.de(s).nivel;
      if (n > antes.de(s).nivel) _comemora(s, n);
    }
  }

  void _comemora(Skill s, int nivel) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        key: const Key('skills-subiu'),
        icon: Icon(iconeDaSkill(s), size: 48, color: corDaSkill(s)),
        title: Text(t.fill(t.s('skSubiu'), {'s': nomeDaSkill(t, s), 'n': nivel}), textAlign: TextAlign.center),
        actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      key: const Key('skills-do-baru'),
      padding: const EdgeInsets.all(Espaco.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final s in Skill.values) ...[
          _BarraDaSkill(t: t, estado: _skills.de(s), carregando: !_carregou),
          const SizedBox(height: Espaco.sm),
        ],
        Text(t.s('skComoSaudavel'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
        const SizedBox(height: Espaco.sm),
        BotaoBaru(
          key: const Key('skills-registrar'),
          rotulo: t.s('skRegistrar'),
          icone: const Icon(Icons.add_rounded),
          ativo: _carregou,
          aoTocar: _registrar,
        ),
      ]),
    );
  }
}

String nomeDaSkill(T t, Skill s) => t.s(switch (s) {
      Skill.saudavel => 'skSaudavel',
      Skill.inteligente => 'skInteligente',
      Skill.forte => 'skForte',
    });

IconData iconeDaSkill(Skill s) => switch (s) {
      Skill.saudavel => Icons.favorite_rounded,
      Skill.inteligente => Icons.menu_book_rounded,
      Skill.forte => Icons.fitness_center_rounded,
    };

Color corDaSkill(Skill s) => switch (s) {
      Skill.saudavel => const Color(0xFF3FA34D),
      Skill.inteligente => const Color(0xFF4A7BD0),
      Skill.forte => const Color(0xFFE0782F),
    };

class _BarraDaSkill extends StatelessWidget {
  const _BarraDaSkill({required this.t, required this.estado, required this.carregando});
  final T t;
  final EstadoDaSkill estado;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final cor = corDaSkill(estado.skill);
    return Column(
      key: Key('skill-${estado.skill.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Icon(iconeDaSkill(estado.skill), size: 18, color: cor),
          const SizedBox(width: 6),
          Text(nomeDaSkill(t, estado.skill), style: estilo(Tipo.corpoForte)),
          const SizedBox(width: 6),
          Text(t.fill(t.s('skNivel'), {'n': estado.nivel}), style: estilo(Tipo.rotulo, color: cor)),
          const Spacer(),
          if (estado.hoje > 0)
            Text(t.fill(t.s('skHoje'), {'x': estado.hoje}), style: estilo(Tipo.rotulo, color: Cores.tinta700)),
        ]),
        const SizedBox(height: 4),
        TrackFill(pct: carregando ? 0 : estado.progresso, color: cor, height: 8),
        const SizedBox(height: 2),
        Text(
          t.fill(t.s('skFalta'), {'x': estado.xpProximo - estado.xp, 'n': estado.nivel + 1}),
          style: estilo(Tipo.corpoPequeno, color: Cores.tinta500),
        ),
      ],
    );
  }
}

/// Registrar em no máximo três toques: atividade, quantidade, salvar.
class _FolhaDeRegistro extends StatefulWidget {
  const _FolhaDeRegistro({required this.t, required this.repo, required this.antes});
  final T t;
  final SkillsRepo repo;
  final MinhasSkills antes;

  @override
  State<_FolhaDeRegistro> createState() => _FolhaDeRegistroState();
}

class _FolhaDeRegistroState extends State<_FolhaDeRegistro> {
  static const _atividades = ['leitura', 'estudo', 'corrida', 'luta', 'academia', 'outro'];
  String _atividade = 'leitura';
  String _unidade = 'paginas';
  final _quanto = TextEditingController();
  final _km = TextEditingController();
  bool _ocupado = false;
  late MinhasSkills _skills = widget.antes;

  T get t => widget.t;
  Skill get _skill => _atividade == 'leitura' || _atividade == 'estudo' ? Skill.inteligente : Skill.forte;

  @override
  void dispose() {
    _quanto.dispose();
    _km.dispose();
    super.dispose();
  }

  String _rotulo(String a) => t.s('sk${a[0].toUpperCase()}${a.substring(1)}');

  double? _numero(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _salvar() async {
    final q = _numero(_quanto);
    if (q == null || q <= 0 || q > 1440) return;
    final km = _skill == Skill.forte ? _numero(_km) : null;
    setState(() => _ocupado = true);
    final m = ScaffoldMessenger.maybeOf(context);
    try {
      final antes = _skills.de(_skill).xp;
      final novo = await widget.repo.registra(
        skill: _skill,
        atividade: _atividade,
        quantidade: q,
        unidade: _skill == Skill.forte ? 'minutos' : _unidade,
        distanciaKm: km != null && km > 0 ? km : null,
      );
      final ganho = novo.de(_skill).xp - antes;
      m?.showSnackBar(SnackBar(
        content: Text(ganho > 0
            ? t.fill(t.s('skPronto'), {'x': ganho, 's': nomeDaSkill(t, _skill)})
            : t.fill(t.s('skTeto'), {'s': nomeDaSkill(t, _skill)})),
      ));
      if (mounted) Navigator.of(context).pop(novo);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      m?.showSnackBar(SnackBar(content: Text(t.s('skFalhou'))));
    }
  }

  Future<void> _apagar(RegistroDeHabito r) async {
    try {
      final novo = await widget.repo.apaga(r.id);
      if (mounted) setState(() => _skills = novo);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.s('skFalhou'))));
    }
  }

  String _descreve(RegistroDeHabito r) {
    if (r.skill == Skill.saudavel) return t.s('skMeta');
    final q = r.quantidade == r.quantidade.roundToDouble() ? r.quantidade.toInt().toString() : r.quantidade.toString();
    final un = t.s(r.unidade == 'paginas' ? 'skPaginas' : 'skMinutos').toLowerCase();
    final km = r.distanciaKm == null ? '' : ' · ${r.distanciaKm} km';
    return '${_rotulo(r.atividade)} · $q $un$km';
  }

  @override
  Widget build(BuildContext context) {
    final recentes = _skills.registros.take(8).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(Espaco.lg, Espaco.md, Espaco.lg, Espaco.lg + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(t.s('skOQue'), style: estilo(Tipo.titulo)),
          const SizedBox(height: Espaco.sm),
          Wrap(spacing: Espaco.xs, runSpacing: Espaco.xs, children: [
            for (final a in _atividades)
              ChoiceChip(
                key: Key('sk-atividade-$a'),
                label: Text(_rotulo(a)),
                selected: _atividade == a,
                onSelected: (_) => setState(() {
                  _atividade = a;
                  if (a != 'leitura') _unidade = 'minutos';
                  if (a == 'leitura') _unidade = 'paginas';
                }),
              ),
          ]),
          const SizedBox(height: Espaco.md),
          if (_skill == Skill.inteligente)
            Padding(
              padding: const EdgeInsets.only(bottom: Espaco.sm),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'paginas', label: Text(t.s('skPaginas'))),
                  ButtonSegment(value: 'minutos', label: Text(t.s('skMinutos'))),
                ],
                selected: {_unidade},
                onSelectionChanged: (v) => setState(() => _unidade = v.first),
              ),
            ),
          TextField(
            key: const Key('sk-quanto'),
            controller: _quanto,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            decoration: InputDecoration(
              labelText: '${t.s('skQuanto')} (${t.s(_skill == Skill.forte || _unidade == 'minutos' ? 'skMinutos' : 'skPaginas').toLowerCase()})',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_skill == Skill.forte)
            TextField(
              key: const Key('sk-km'),
              controller: _km,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')), LengthLimitingTextInputFormatter(5)],
              decoration: InputDecoration(labelText: t.s('skKm')),
            ),
          const SizedBox(height: Espaco.xs),
          Text(t.s('skRegraXp'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta500)),
          const SizedBox(height: Espaco.md),
          BotaoBaru(
            key: const Key('sk-salvar'),
            rotulo: t.s('skSalvar'),
            ativo: !_ocupado && (_numero(_quanto) ?? 0) > 0,
            aoTocar: _salvar,
          ),
          const SizedBox(height: Espaco.lg),
          Text(t.s('skRecentes'), style: estilo(Tipo.subtitulo)),
          const SizedBox(height: Espaco.xs),
          if (recentes.isEmpty)
            Text(t.s('skNada'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta500))
          else
            for (final r in recentes)
              ListTile(
                key: Key('sk-registro-${r.id}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(iconeDaSkill(r.skill), color: corDaSkill(r.skill)),
                title: Text(_descreve(r), style: estilo(Tipo.corpo)),
                subtitle: Text('+${r.xp} XP · ${t.formatLongDate(r.dia)}', style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                trailing: r.editavel
                    ? IconButton(
                        tooltip: t.s('skApagar'),
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () => _apagar(r),
                      )
                    : null,
              ),
        ]),
      ),
    );
  }
}
