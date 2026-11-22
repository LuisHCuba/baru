import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/skills.dart';
import '../l10n.dart';
import '../l10n_skills.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';

/// O estado das skills, um só para a home inteira: o placar do topo e a aba
/// Habilidades leem daqui, e qualquer registro atualiza os dois.
final skillsAtuais = ValueNotifier<MinhasSkills?>(null);
SkillsRepo? _repoGlobal;
SkillsRepo get _repo => _repoGlobal ??= SkillsRepo();

/// Para os testes: troca o repositório.
@visibleForTesting
set repoDasSkills(SkillsRepo r) => _repoGlobal = r;

bool _carregando = false;

/// Busca as skills (e dá o Saudável do dia quando cabe). Sem rede, fica como está.
Future<void> carregaSkills(AppState app) async {
  if (_carregando) return;
  _carregando = true;
  try {
    var s = await _repo.minhas();
    if (app.usageAccess && app.underGoal && DateTime.now().hour >= 21) s = await _repo.saudavelDeHoje();
    skillsAtuais.value = s;
  } catch (_) {
    skillsAtuais.value ??= MinhasSkills.vazio;
  } finally {
    _carregando = false;
  }
}

/// O botão "+": abre o registro de leitura, estudo ou exercício.
Future<void> abreRegistroDeHabito(BuildContext context, AppState app) async {
  garanteTextosDasSkills();
  final t = app.t;
  final antes = skillsAtuais.value ?? MinhasSkills.vazio;
  final novo = await showModalBottomSheet<MinhasSkills>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Cores.superficie,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _FolhaDeRegistro(t: t, repo: _repo, antes: antes),
  );
  if (novo == null) return;
  skillsAtuais.value = novo;
  if (!context.mounted) return;
  for (final s in Skill.values) {
    final n = novo.de(s).nivel;
    if (n > antes.de(s).nivel) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          key: const Key('skills-subiu'),
          icon: Icon(iconeDaSkill(s), size: 48, color: corDaSkill(s)),
          title: Text(t.fill(t.s('skSubiu'), {'s': nomeDaSkill(t, s), 'n': n}), textAlign: TextAlign.center),
          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK'))],
        ),
      );
      if (!context.mounted) return;
    }
  }
}

/// Botão "+" redondo e claro, para registrar.
class BotaoRegistrar extends StatelessWidget {
  const BotaoRegistrar({super.key, required this.app, this.tamanho = 44, this.contexto});
  final AppState app;
  final double tamanho;

  /// De onde abrir a folha (o painel da home fica fora do Navigator).
  final BuildContext? Function()? contexto;

  @override
  Widget build(BuildContext context) {
    garanteTextosDasSkills();
    return Semantics(
      button: true,
      label: app.t.s('skRegistrar'),
      child: Material(
        key: const Key('skills-mais'),
        color: AppColors.green,
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            final c = contexto?.call() ?? context;
            abreRegistroDeHabito(c, app);
          },
          child: SizedBox(
            width: tamanho,
            height: tamanho,
            child: Icon(Icons.add_rounded, color: Colors.white, size: tamanho * 0.62),
          ),
        ),
      ),
    );
  }
}

/// O nível de cada skill, para a barra de placar do topo da home.
class NiveisDasSkills extends StatefulWidget {
  const NiveisDasSkills({super.key, required this.app});
  final AppState app;

  @override
  State<NiveisDasSkills> createState() => _NiveisDasSkillsState();
}

class _NiveisDasSkillsState extends State<NiveisDasSkills> {
  @override
  void initState() {
    super.initState();
    if (skillsAtuais.value == null) carregaSkills(widget.app);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MinhasSkills?>(
        valueListenable: skillsAtuais,
        builder: (context, sk, _) => Row(key: const Key('placar-skills'), mainAxisSize: MainAxisSize.min, children: [
          for (final s in Skill.values) ...[
            Icon(iconeDaSkill(s), size: 16, color: corDaSkill(s)),
            const SizedBox(width: 2),
            Text('${(sk ?? MinhasSkills.vazio).de(s).nivel}',
                style: nunito(size: 14, weight: FontWeight.w800, tabular: true)),
            if (s != Skill.forte) const SizedBox(width: 8),
          ],
        ]),
      );
}

/// As três barras das skills (Saudável, Inteligente, Forte) e o botão Registrar.
///
/// Saudável sobe sozinho: quando o tempo de tela está liberado e o dia de
/// hoje (depois das 21h) ou o de ontem fechou dentro da meta, o app avisa o
/// servidor, que dá 20 XP uma vez por dia.
class SkillsDoBaru extends StatefulWidget {
  const SkillsDoBaru({super.key, required this.app});
  final AppState app;

  @override
  State<SkillsDoBaru> createState() => _SkillsDoBaruState();
}

class _SkillsDoBaruState extends State<SkillsDoBaru> {
  T get t => widget.app.t;

  @override
  void initState() {
    super.initState();
    garanteTextosDasSkills();
    carregaSkills(widget.app);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<MinhasSkills?>(
        valueListenable: skillsAtuais,
        builder: (context, sk, _) => SoftCard(
          key: const Key('skills-do-baru'),
          padding: const EdgeInsets.all(Espaco.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(t.s('skT'), style: estilo(Tipo.subtitulo))),
              BotaoRegistrar(app: widget.app, tamanho: 40),
            ]),
            const SizedBox(height: Espaco.sm),
            for (final s in Skill.values) ...[
              _BarraDaSkill(t: t, estado: (sk ?? MinhasSkills.vazio).de(s), carregando: sk == null),
              const SizedBox(height: Espaco.sm),
            ],
            Text(t.s('skComoSaudavel'), style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
          ]),
        ),
      );
}

String nomeDaSkill(T t, Skill s) => t.s(switch (s) {
      Skill.saudavel => 'skSaudavel',
      Skill.inteligente => 'skInteligente',
      Skill.forte => 'skForte',
    });

IconData iconeDaSkill(Skill s) => switch (s) {
      Skill.saudavel => Icons.favorite_rounded,
      Skill.inteligente => Icons.menu_book_rounded,
      Skill.forte => Icons.directions_run_rounded,
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
      padding: EdgeInsets.fromLTRB(Espaco.lg, 0, Espaco.lg, Espaco.lg + MediaQuery.viewInsetsOf(context).bottom),
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
