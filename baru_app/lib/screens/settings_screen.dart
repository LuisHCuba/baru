import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

import '../widgets/legal_sheet.dart';
import '../widgets/pet_profile.dart';

/// Ajustes.
///
/// A versão anterior era uma coluna única e longa: todo controle sempre
/// aberto, quatro idiomas em chips, oito metas em chips, seis links soltos —
/// o usuário rolava por tudo para achar qualquer coisa.
///
/// Aqui cada assunto é um cartão fechado com o **valor atual à direita**;
/// o que é longo (idioma, meta, horário, sexo) abre numa folha. Fica curta o
/// bastante para caber quase inteira numa tela.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const chaveMeta = Key('ajustes-meta');
  static const chaveHorario = Key('ajustes-horario');
  static const chaveSexo = Key('ajustes-sexo');

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espaco.margemTela,
        Espaco.md,
        Espaco.margemTela,
        Espaco.xxl,
      ),
      children: [
        Text(t.setT, style: estilo(Tipo.display)),
        const SizedBox(height: Espaco.md),

        // --- companheiro ---------------------------------------------------
        const CompanionCard(completo: false),
        const SizedBox(height: Espaco.sm),
        _Grupo(
          children: [
            _Linha(
              chave: chaveSexo,
              icone: Icons.wc_rounded,
              rotulo: t.setSexo,
              valor: _rotuloDoSexo(t, app.sexo),
              aoTocar: () => _abreSexo(context, app),
            ),
            _Linha(
              chave: null,
              icone: Icons.pets_rounded,
              rotulo: t.revealKicker,
              valor: t.animalName(app.species.name),
              aoTocar: () => _abreEspecie(context, app),
            ),
            _Linha(
              chave: null,
              icone: Icons.palette_outlined,
              rotulo: t.coat,
              valor: '${app.color + 1}',
              aoTocar: () => _abreAparencia(context, app),
            ),
          ],
        ),

        // --- meta ----------------------------------------------------------
        const SizedBox(height: Espaco.md),
        _Grupo(
          children: [
            _Linha(
              chave: chaveMeta,
              icone: Icons.flag_outlined,
              rotulo: t.setMetaLivre,
              valor: app.fmt(app.goal),
              aoTocar: () => _abreMeta(context, app),
            ),
            _Linha(
              chave: null,
              icone: Icons.timer_outlined,
              rotulo: t.setDuracao,
              valor: '${app.dur} min',
              aoTocar: () => _abreDuracao(context, app),
            ),
          ],
        ),

        // --- notificações ---------------------------------------------------
        const SizedBox(height: Espaco.md),
        _Grupo(
          children: [
            _Chave(
              rotulo: t.setEvening,
              detalhe: t.fill(t.setEveningSub, {
                'h': _hhmm(app.eveningHour, app.eveningMinute),
              }),
              ligado: app.evening,
              aoTocar: app.toggleEvening,
            ),
            if (app.evening)
              _Linha(
                chave: chaveHorario,
                icone: Icons.schedule_rounded,
                rotulo: t.setHorario,
                valor: _hhmm(app.eveningHour, app.eveningMinute),
                aoTocar: () => _abreHorario(context, app),
              ),
            _Chave(
              rotulo: t.setSom,
              detalhe: t.setSomSub,
              ligado: app.som,
              aoTocar: app.toggleSom,
            ),
            _Chave(
              rotulo: t.setMissed,
              detalhe: t.setMissedSub,
              ligado: app.missed,
              aoTocar: app.toggleMissed,
            ),
          ],
        ),

        // --- permissão e idioma ---------------------------------------------
        const SizedBox(height: Espaco.md),
        _Grupo(
          children: [
            _Chave(
              rotulo: t.permAllow,
              detalhe: app.usageAccess ? t.setUsageOn : t.setUsageOff,
              ligado: app.usageAccess,
              aoTocar: app.toggleUsageAccess,
            ),
            _Linha(
              chave: null,
              icone: Icons.language_rounded,
              rotulo: t.setLang,
              valor: langs.firstWhere((l) => l.id == app.lang).label,
              aoTocar: () => _abreIdioma(context, app),
            ),
          ],
        ),

        // --- plano -----------------------------------------------------------
        const SizedBox(height: Espaco.md),
        CartaoBaru(
          cor: Cores.primariaA(0.10),
          elevado: false,
          onTap: () => app.go(AppScreen.paywall),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.trial
                          ? t.fill(t.planTrial, {'n': app.trialDaysLeft})
                          : t.planNone,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: estilo(Tipo.subtitulo),
                    ),
                    const SizedBox(height: Espaco.xxs),
                    Text(
                      app.trial
                          ? t.fill(t.planTrialSub, {
                              'd': t.formatLongDate(app.paidPlanStart),
                            })
                          : t.planNoneSub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: estilo(
                        Tipo.corpoPequeno,
                        color: Cores.tintaA(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                t.setManage,
                style: estilo(Tipo.rotulo, color: Cores.primariaEscura),
              ),
            ],
          ),
        ),

        // --- sobre ------------------------------------------------------------
        const SizedBox(height: Espaco.md),
        _Grupo(
          children: [
            _Linha(
              chave: null,
              icone: Icons.restore_rounded,
              rotulo: t.setRestore,
              aoTocar: app.restorePurchases,
            ),
            _Linha(
              chave: null,
              icone: Icons.shield_outlined,
              rotulo: t.setPrivacy,
              aoTocar: () => showLegalSheet(
                context,
                title: t.setPrivacy,
                body: t.privacyBody,
                close: t.shareDone,
              ),
            ),
            _Linha(
              chave: null,
              icone: Icons.article_outlined,
              rotulo: t.setTerms,
              aoTocar: () => showLegalSheet(
                context,
                title: t.setTerms,
                body: t.termsBody,
                close: t.shareDone,
              ),
            ),
            _Linha(
              chave: null,
              icone: Icons.replay_rounded,
              rotulo: t.setReplay,
              apagado: true,
              aoTocar: app.restartOnboarding,
            ),
            if (app.canSignOut)
              _Linha(
                chave: null,
                icone: Icons.logout_rounded,
                rotulo: t.authSignOut,
                apagado: true,
                aoTocar: app.signOut,
              ),
          ],
        ),
      ],
    );
  }

  static String _hhmm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  static String _rotuloDoSexo(T t, Sexo s) => switch (s) {
        Sexo.naoDito => t.setSexoNao,
        Sexo.macho => t.setSexoM,
        Sexo.femea => t.setSexoF,
      };

  // --- folhas --------------------------------------------------------------

  void _abreSexo(BuildContext context, AppState app) {
    final t = app.t;
    _folha(
      context,
      t.setSexo,
      (fechar) => Column(
        children: [
          for (final s in Sexo.values)
            _Opcao(
              rotulo: _rotuloDoSexo(t, s),
              marcada: app.sexo == s,
              aoTocar: () {
                app.setSexo(s);
                fechar();
              },
            ),
        ],
      ),
    );
  }

  void _abreIdioma(BuildContext context, AppState app) {
    _folha(
      context,
      app.t.setLang,
      (fechar) => Column(
        children: [
          for (final l in langs)
            _Opcao(
              rotulo: l.label,
              marcada: app.lang == l.id,
              aoTocar: () {
                app.setLang(l.id);
                fechar();
              },
            ),
        ],
      ),
    );
  }

  void _abreDuracao(BuildContext context, AppState app) {
    _folha(
      context,
      app.t.setDuracao,
      (fechar) => Column(
        children: [
          for (final d in durations)
            _Opcao(
              rotulo: '$d min',
              marcada: app.dur == d,
              aoTocar: () {
                app.pickDur(d);
                fechar();
              },
            ),
        ],
      ),
    );
  }

  void _abreEspecie(BuildContext context, AppState app) {
    final t = app.t;
    _folha(
      context,
      t.revealKicker,
      (fechar) => Column(
        children: [
          for (final e in Species.values)
            _Opcao(
              rotulo: t.animalName(e.name),
              marcada: app.species == e,
              aoTocar: () {
                app.pickSpecies(e);
                fechar();
              },
            ),
        ],
      ),
    );
  }

  void _abreAparencia(BuildContext context, AppState app) {
    _folha(
      context,
      app.t.coat,
      (fechar) => CoatPicker(
        selected: app.color,
        onPick: app.setColor,
        label: app.t.coat,
        especie: app.species,
      ),
    );
  }

  /// A meta deixou de ser quatro chips fixos.
  ///
  /// Chips cobriam 90/120/150/180 e mais nada: quem quisesse 75 ou 240 não
  /// tinha como pedir. Agora é um passo de 15 minutos entre 30 e 480, com os
  /// valores comuns como atalho.
  void _abreMeta(BuildContext context, AppState app) {
    final t = app.t;
    _folha(
      context,
      t.setMetaLivre,
      (fechar) => StatefulBuilder(
        builder: (context, setSheetState) {
          void muda(int passos) {
            app.ajustaMeta(passos);
            setSheetState(() {});
          }

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Passo(
                    icone: Icons.remove_rounded,
                    ativo: app.goal > metaMinima,
                    aoTocar: () => muda(-1),
                  ),
                  Text(
                    app.fmt(app.goal),
                    style: estilo(
                      Tipo.displayGrande,
                      color: Cores.primariaEscura,
                      tabular: true,
                    ),
                  ),
                  _Passo(
                    icone: Icons.add_rounded,
                    ativo: app.goal < metaMaxima,
                    aoTocar: () => muda(1),
                  ),
                ],
              ),
              const SizedBox(height: Espaco.sm),
              Text(
                t.fill(t.setMetaAjuda, {
                  'p': metaPasso,
                  'a': app.fmt(metaMinima),
                  'b': app.fmt(metaMaxima),
                }),
                textAlign: TextAlign.center,
                style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.5)),
              ),
              const SizedBox(height: Espaco.md),
              Wrap(
                spacing: Espaco.xs,
                runSpacing: Espaco.xs,
                alignment: WrapAlignment.center,
                children: [
                  for (final g in goalOptions)
                    SelectChip(
                      label: app.fmt(g),
                      selected: app.goal == g,
                      onTap: () {
                        app.pickGoal(g);
                        setSheetState(() {});
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: Espaco.md,
                        vertical: Espaco.sm,
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// O relatório da noite chegava sempre às 21h, fixo no código.
  void _abreHorario(BuildContext context, AppState app) {
    final t = app.t;
    _folha(
      context,
      t.setHorario,
      (fechar) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            children: [
              Text(
                t.setHorarioSub,
                textAlign: TextAlign.center,
                style: estilo(Tipo.corpoPequeno, color: Cores.tintaA(0.55)),
              ),
              const SizedBox(height: Espaco.md),
              Wrap(
                spacing: Espaco.xs,
                runSpacing: Espaco.xs,
                alignment: WrapAlignment.center,
                children: [
                  for (final h in const [18, 19, 20, 21, 22, 23])
                    for (final m in const [0, 30])
                      SelectChip(
                        label: _hhmm(h, m),
                        selected:
                            app.eveningHour == h && app.eveningMinute == m,
                        onTap: () {
                          app.setEveningTime(h, m);
                          setSheetState(() {});
                        },
                        padding: const EdgeInsets.symmetric(
                          horizontal: Espaco.md,
                          vertical: Espaco.sm,
                        ),
                      ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _folha(
    BuildContext context,
    String titulo,
    Widget Function(VoidCallback fechar) corpo,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Cores.superficie,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Raio.folha)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espaco.margemTela,
            Espaco.md,
            Espaco.margemTela,
            Espaco.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Cores.tintaA(0.14),
                    borderRadius: Raio.todos(Raio.pilula),
                  ),
                ),
              ),
              const SizedBox(height: Espaco.md),
              Text(titulo, style: estilo(Tipo.titulo)),
              const SizedBox(height: Espaco.md),
              corpo(() => Navigator.of(sheetContext).pop()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CartaoBaru(
      padding: const EdgeInsets.symmetric(horizontal: Espaco.md),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Cores.tintaA(0.07)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.chave,
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
    this.valor,
    this.apagado = false,
  });

  /// Chave para o teste apontar a linha certa. Nula quando a linha não é
  /// alvo de nenhum teste.
  final Key? chave;
  final IconData icone;
  final String rotulo;
  final String? valor;
  final VoidCallback aoTocar;
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final cor = apagado ? Cores.tintaA(0.5) : Cores.tinta;
    return Semantics(
      key: chave,
      button: true,
      label: valor == null ? rotulo : '$rotulo, $valor',
      child: GestureDetector(
        onTap: aoTocar,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Toque.minimo),
          child: Row(
            children: [
              Icon(icone, size: 19, color: cor),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Text(
                  rotulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: estilo(Tipo.corpo, color: cor),
                ),
              ),
              if (valor != null)
                Text(
                  valor!,
                  style: estilo(Tipo.rotulo, color: Cores.tintaA(0.55)),
                ),
              const SizedBox(width: Espaco.xxs),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Cores.tintaA(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chave extends StatelessWidget {
  const _Chave({
    required this.rotulo,
    required this.detalhe,
    required this.ligado,
    required this.aoTocar,
  });

  final String rotulo;
  final String detalhe;
  final bool ligado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Toque.minimo),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estilo(Tipo.corpo),
                  ),
                  Text(
                    detalhe,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: estilo(
                      Tipo.corpoPequeno,
                      color: Cores.tintaA(0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Espaco.sm),
            AppToggle(on: ligado, onTap: aoTocar),
          ],
        ),
      ),
    );
  }
}

class _Opcao extends StatelessWidget {
  const _Opcao({
    required this.rotulo,
    required this.marcada,
    required this.aoTocar,
  });

  final String rotulo;
  final bool marcada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: marcada,
      child: GestureDetector(
        onTap: aoTocar,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Toque.minimo),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  rotulo,
                  style: estilo(
                    Tipo.corpo,
                    color: marcada ? Cores.primariaEscura : Cores.tinta,
                  ),
                ),
              ),
              if (marcada)
                const Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: Cores.primaria,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({
    required this.icone,
    required this.ativo,
    required this.aoTocar,
  });

  final IconData icone;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: ativo,
      child: GestureDetector(
        onTap: ativo ? aoTocar : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: Toque.minimo,
          height: Toque.minimo,
          decoration: BoxDecoration(
            color: ativo ? Cores.primariaA(0.14) : Cores.tintaA(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icone,
            size: 22,
            color: ativo ? Cores.primariaEscura : Cores.tintaA(0.25),
          ),
        ),
      ),
    );
  }
}
