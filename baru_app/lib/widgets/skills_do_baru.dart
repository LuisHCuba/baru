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
  MinhasSkills? novo;
  // A folha modal não recebe a margem da barra do sistema: vai na mão.
  final baixo = MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
  // O painel da home sai da frente enquanto a folha está aberta.
  await app.comFolhaDaHome(() async {
    novo = await showModalBottomSheet<MinhasSkills>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: Cores.superficie,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => AppScope(state: app, child: _FolhaDeRegistro(t: t, repo: _repo, antes: antes, baixo: baixo)),
    );
  });
  final novo0 = novo;
  if (novo0 == null) return;
  skillsAtuais.value = novo0;
  if (!context.mounted) return;
  await _aplica(context, app, antes, novo0);
}

Future<void> _aplica(BuildContext context, AppState app, MinhasSkills antes, MinhasSkills novo) async {
  final t = app.t;
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

/// Registrar em três toques, sem teclado: o que fez, quanto (botões de
/// atalho e ajuste fino com − e +) e salvar. Mostra o XP antes de salvar.
class _FolhaDeRegistro extends StatefulWidget {
  const _FolhaDeRegistro({required this.t, required this.repo, required this.antes, this.baixo = 0});
  final T t;
  final SkillsRepo repo;
  final MinhasSkills antes;

  /// A altura da barra do sistema embaixo.
  final double baixo;

  @override
  State<_FolhaDeRegistro> createState() => _FolhaDeRegistroState();
}

class _Atividade {
  const _Atividade(this.id, this.icone);
  final String id;
  final IconData icone;
}

class _FolhaDeRegistroState extends State<_FolhaDeRegistro> {
  static const _mente = [_Atividade('leitura', Icons.menu_book_rounded), _Atividade('estudo', Icons.school_rounded)];
  static const _corpo = [
    _Atividade('corrida', Icons.directions_run_rounded),
    _Atividade('luta', Icons.sports_martial_arts_rounded),
    _Atividade('academia', Icons.fitness_center_rounded),
    _Atividade('outro', Icons.sports_soccer_rounded),
  ];

  String? _atividade;
  String _unidade = 'paginas';
  int _quanto = 0;
  double _km = 0;
  bool _ocupado = false;
  bool _verRecentes = false;
  late MinhasSkills _skills = widget.antes;

  T get t => widget.t;
  Skill get _skill => _atividade == 'leitura' || _atividade == 'estudo' ? Skill.inteligente : Skill.forte;
  bool get _emPaginas => _atividade == 'leitura' && _unidade == 'paginas';

  List<int> get _atalhos => _emPaginas ? const [10, 20, 30, 50] : const [15, 30, 45, 60];
  int get _passo => _emPaginas ? 5 : 5;

  String _rotulo(String a) => t.s('sk${a[0].toUpperCase()}${a.substring(1)}');

  /// O mesmo cálculo do servidor (baru_xp_bruto), com o teto do dia.
  int get _xpPrevisto {
    final bruto = _emPaginas ? _quanto : (_quanto ~/ 5) * 2;
    final cabe = 200 - _skills.de(_skill).hoje;
    return bruto.clamp(0, cabe < 0 ? 0 : cabe);
  }

  void _escolhe(String a) => setState(() {
        final antes = _atividade;
        _atividade = a;
        _unidade = a == 'leitura' ? 'paginas' : 'minutos';
        if (antes == null || (antes == 'leitura') != (a == 'leitura')) _quanto = _atalhos[1];
        if (a != 'corrida') _km = 0;
      });

  Future<void> _salvar() async {
    if (_atividade == null || _quanto <= 0) return;
    setState(() => _ocupado = true);
    final m = ScaffoldMessenger.maybeOf(context);
    try {
      final antes = _skills.de(_skill).xp;
      final novo = await widget.repo.registra(
        skill: _skill,
        atividade: _atividade!,
        quantidade: _quanto.toDouble(),
        unidade: _skill == Skill.forte ? 'minutos' : _unidade,
        distanciaKm: _km > 0 ? _km : null,
      );
      final ganho = novo.de(_skill).xp - antes;
      HapticFeedback.mediumImpact();
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

  Widget _grupo(String titulo, Skill skill, List<_Atividade> itens) {
    final cor = corDaSkill(skill);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(iconeDaSkill(skill), size: 16, color: cor),
        const SizedBox(width: 6),
        Text('$titulo · ${nomeDaSkill(t, skill)}', style: estilo(Tipo.rotulo, color: Cores.tinta700)),
      ]),
      const SizedBox(height: Espaco.xs),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: Espaco.xs,
        crossAxisSpacing: Espaco.xs,
        childAspectRatio: 0.95,
        children: [
          for (final a in itens)
            _Bloco(
              chave: Key('sk-atividade-${a.id}'),
              icone: a.icone,
              rotulo: _rotulo(a.id),
              cor: cor,
              escolhido: _atividade == a.id,
              aoTocar: () => _escolhe(a.id),
            ),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final escolhida = _atividade != null;
    final cor = escolhida ? corDaSkill(_skill) : AppColors.green;
    final unidade = t.s(_emPaginas ? 'skPaginas' : 'skMinutos').toLowerCase();
    final recentes = _skills.registros.take(8).toList();
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(Espaco.lg, 0, Espaco.lg, Espaco.lg + widget.baixo),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Text(t.s('skOQue'), style: estilo(Tipo.titulo)),
          const SizedBox(height: Espaco.md),
          _grupo(t.s('skMente'), Skill.inteligente, _mente),
          const SizedBox(height: Espaco.md),
          _grupo(t.s('skCorpo'), Skill.forte, _corpo),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: !escolhida
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Espaco.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (_atividade == 'leitura')
                        Padding(
                          padding: const EdgeInsets.only(bottom: Espaco.sm),
                          child: SegmentedButton<String>(
                            key: const Key('sk-unidade'),
                            showSelectedIcon: false,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith(
                                  (e) => e.contains(WidgetState.selected) ? cor : Colors.transparent),
                              foregroundColor: WidgetStateProperty.resolveWith(
                                  (e) => e.contains(WidgetState.selected) ? Colors.white : Cores.tinta),
                              side: WidgetStatePropertyAll(BorderSide(color: cor.withValues(alpha: 0.5))),
                            ),
                            segments: [
                              ButtonSegment(value: 'paginas', label: Text(t.s('skPaginas'))),
                              ButtonSegment(value: 'minutos', label: Text(t.s('skMinutos'))),
                            ],
                            selected: {_unidade},
                            onSelectionChanged: (v) => setState(() {
                              _unidade = v.first;
                              _quanto = _atalhos[1];
                            }),
                          ),
                        ),
                      // Quanto: número grande, − e +, e atalhos.
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: Espaco.sm, horizontal: Espaco.xs),
                        decoration: BoxDecoration(color: cor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                        child: Column(children: [
                          Row(children: [
                            _Redondo(
                              chave: const Key('sk-menos'),
                              icone: Icons.remove_rounded,
                              cor: cor,
                              aoTocar: _quanto > _passo ? () => setState(() => _quanto -= _passo) : null,
                            ),
                            Expanded(
                              child: Column(children: [
                                Text('$_quanto', key: const Key('sk-quanto'),
                                    style: estilo(Tipo.numeroGrande, color: Cores.tinta)),
                                Text(unidade, style: estilo(Tipo.rotulo, color: Cores.tinta700)),
                              ]),
                            ),
                            _Redondo(
                              chave: const Key('sk-mais'),
                              icone: Icons.add_rounded,
                              cor: cor,
                              aoTocar: _quanto < 1440 ? () => setState(() => _quanto += _passo) : null,
                            ),
                          ]),
                          const SizedBox(height: Espaco.sm),
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            for (final n in _atalhos)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  key: Key('sk-atalho-$n'),
                                  selectedColor: cor,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: cor.withValues(alpha: 0.35)),
                                  labelStyle: estilo(Tipo.corpoForte, color: Cores.tinta),
                                  label: Text('$n', style: estilo(Tipo.corpoForte, color: _quanto == n ? Colors.white : Cores.tinta)),
                                  selected: _quanto == n,
                                  showCheckmark: false,
                                  onSelected: (_) => setState(() => _quanto = n),
                                ),
                              ),
                          ]),
                        ]),
                      ),
                      if (_atividade == 'corrida') ...[
                        const SizedBox(height: Espaco.sm),
                        Row(children: [
                          Text(t.s('skKmCurto'), style: estilo(Tipo.rotulo, color: Cores.tinta700)),
                          const SizedBox(width: Espaco.xs),
                          Expanded(
                            child: Wrap(spacing: 6, children: [
                              for (final k in const [0.0, 2.0, 5.0, 10.0])
                                ChoiceChip(
                                  key: Key('sk-km-${k.toInt()}'),
                                  selectedColor: cor,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: cor.withValues(alpha: 0.35)),
                                  labelStyle: estilo(Tipo.corpoForte, color: Cores.tinta),
                                  label: Text(k == 0 ? '—' : '${k.toInt()} km',
                                      style: estilo(Tipo.corpoForte, color: _km == k ? Colors.white : Cores.tinta)),
                                  selected: _km == k,
                                  showCheckmark: false,
                                  onSelected: (_) => setState(() => _km = k),
                                ),
                            ]),
                          ),
                        ]),
                      ],
                      const SizedBox(height: Espaco.md),
                      FilledButton(
                        key: const Key('sk-salvar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cor,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: _ocupado || _quanto <= 0 ? null : _salvar,
                        child: _ocupado
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Text(
                                _xpPrevisto > 0
                                    ? t.fill(t.s('skSalvarXp'), {'x': _xpPrevisto, 's': nomeDaSkill(t, _skill)})
                                    : t.s('skSalvar'),
                                style: estilo(Tipo.subtitulo, color: Colors.white)),
                      ),
                      if (_xpPrevisto == 0 && _quanto > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: Espaco.xs),
                          child: Text(
                              _skills.de(_skill).hoje >= 200
                                  ? t.fill(t.s('skTeto'), {'s': nomeDaSkill(t, _skill)})
                                  : t.s('skRegraXp'),
                              textAlign: TextAlign.center,
                              style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                        ),
                    ]),
                  ),
          ),
          if (recentes.isNotEmpty) ...[
            const SizedBox(height: Espaco.md),
            TextButton.icon(
              key: const Key('sk-ver-recentes'),
              onPressed: () => setState(() => _verRecentes = !_verRecentes),
              icon: Icon(_verRecentes ? Icons.expand_less_rounded : Icons.history_rounded),
              label: Text(t.s('skRecentes')),
            ),
            if (_verRecentes)
              for (final r in recentes)
                ListTile(
                  key: Key('sk-registro-${r.id}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(iconeDaSkill(r.skill), color: corDaSkill(r.skill)),
                  title: Text(_descreve(r), style: estilo(Tipo.corpo)),
                  subtitle: Text('+${r.xp} XP · ${t.formatLongDate(r.dia)}',
                      style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                  trailing: r.editavel
                      ? IconButton(
                          tooltip: t.s('skApagar'),
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _apagar(r),
                        )
                      : null,
                ),
          ],
        ]),
      ),
    );
  }
}

/// Um bloco grande e tocável para escolher a atividade.
class _Bloco extends StatelessWidget {
  const _Bloco({required this.chave, required this.icone, required this.rotulo, required this.cor,
      required this.escolhido, required this.aoTocar});
  final Key chave;
  final IconData icone;
  final String rotulo;
  final Color cor;
  final bool escolhido;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Material(
        key: chave,
        color: escolhido ? cor : cor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icone, size: 28, color: escolhido ? Colors.white : cor),
              const SizedBox(height: 4),
              Text(rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.rotuloPequeno, color: escolhido ? Colors.white : Cores.tinta)),
            ]),
          ),
        ),
      );
}

class _Redondo extends StatelessWidget {
  const _Redondo({required this.chave, required this.icone, required this.cor, required this.aoTocar});
  final Key chave;
  final IconData icone;
  final Color cor;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) => Material(
        key: chave,
        color: aoTocar == null ? Cores.tintaA(0.06) : Colors.white,
        shape: const CircleBorder(),
        elevation: aoTocar == null ? 0 : 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: aoTocar == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  aoTocar!();
                },
          child: SizedBox(width: 52, height: 52, child: Icon(icone, size: 28, color: aoTocar == null ? Cores.tinta500 : cor)),
        ),
      );
}
