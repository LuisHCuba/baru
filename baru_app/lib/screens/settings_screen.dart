import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import '../data/progressao.dart';
import '../l10n_ajustes.dart';
import '../l10n_familia.dart';
import '../l10n_trilha.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
  static const chaveConta = Key('ajustes-conta');

  /// iPhone: a permissão é o Tempo de Uso, e não há "sobre outros apps".
  static bool get noIphone => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final t = app.t;
    garanteTextosDaFamilia();
    garanteTextosDosAjustes();

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

        // --- conta (no topo, como nos Ajustes do sistema) --------------------
        _Grupo(
          children: [
            _Linha(
              chave: chaveConta,
              icone: Icons.account_circle_outlined,
              rotulo: app.emailDaConta.isNotEmpty ? app.emailDaConta : t.contaT,
              valor: null,
              detalhe: t.s('ajContaLinha'),
              aoTocar: () => app.go(AppScreen.conta),
            ),
          ],
        ),

        // --- foco e tempo de tela -------------------------------------------
        _Secao(t.s('ajSecFoco')),
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
              valor: app.fmt(app.dur),
              aoTocar: () => _abreDuracao(context, app),
            ),
          ],
        ),

        // --- notificações: o que o Baru manda de volta ----------------------
        _Secao(t.s('ajSecNotif')),
        _Grupo(
          children: [
            _Chave(
              icone: Icons.nights_stay_outlined,
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
              icone: Icons.favorite_border_rounded,
              rotulo: t.setMissed,
              detalhe: t.setMissedSub,
              ligado: app.missed,
              aoTocar: app.toggleMissed,
            ),
          ],
        ),

        // --- som -------------------------------------------------------------
        _Secao(t.s('ajSecSom')),
        _Grupo(
          children: [
            _Chave(
              icone: Icons.volume_up_outlined,
              rotulo: t.setSom,
              detalhe: t.setSomSub,
              ligado: app.som,
              aoTocar: app.toggleSom,
            ),
          ],
        ),

        // --- permissões do celular ------------------------------------------
        _Secao(t.s('ajSecPermissoes')),
        _Grupo(
          children: [
            _Chave(
              icone: Icons.hourglass_empty_rounded,
              rotulo: noIphone ? t.s('ajTempoDeUsoIos') : t.permAllow,
              detalhe: app.usageAccess ? t.setUsageOn : t.setUsageOff,
              ligado: app.usageAccess,
              aoTocar: app.toggleUsageAccess,
            ),
            if (!noIphone)
              _Linha(
                chave: null,
                icone: Icons.layers_outlined,
                rotulo: t.sobreT,
                aoTocar: () => app.go(AppScreen.sobreposicao),
              ),
          ],
        ),

        // --- geral -----------------------------------------------------------
        _Secao(t.s('ajSecGeral')),
        _Grupo(
          children: [
            _Linha(
              chave: null,
              icone: Icons.language_rounded,
              rotulo: t.setLang,
              valor: langs.firstWhere((l) => l.id == app.lang).label,
              aoTocar: () => _abreIdioma(context, app),
            ),
          ],
        ),
      ],
    );
  }

  static String _hhmm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  static String rotuloDoSexo(T t, Sexo s) => switch (s) {
    Sexo.naoDito => t.setSexoNao,
    Sexo.macho => t.setSexoM,
    Sexo.femea => t.setSexoF,
  };

  // --- folhas --------------------------------------------------------------

  /// Sexo do companheiro. Público para a tela que o hospedar no futuro.
  static void abreSexo(BuildContext context, AppState app) {
    final t = app.t;
    _folha(
      context,
      t.setSexo,
      (fechar) => Column(
        children: [
          for (final s in Sexo.values)
            _Opcao(
              rotulo: rotuloDoSexo(t, s),
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

  static void _abreIdioma(BuildContext context, AppState app) {
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

  static void _abreDuracao(BuildContext context, AppState app) {
    _folha(
      context,
      app.t.setDuracao,
      (fechar) => Column(
        children: [
          for (final d in duracoesEmOrdem)
            _Opcao(
              rotulo: app.fmt(d),
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

  /// Espécie do Baru. Público para a tela que o hospedar no futuro.
  static void abreEspecie(BuildContext context, AppState app) {
    // A frase "Abre no passo N" mora no catálogo da trilha; sem registrar,
    // `s()` devolveria a própria chave na tela.
    garanteTextosDaTrilha();
    final t = app.t;
    _folha(
      context,
      t.revealKicker,
      (fechar) => Column(
        children: [
          // Travada mostra o passo que a abre. Sumir com ela esconderia
          // metade do elenco e o motivo de subir a trilha; deixá-la
          // tocável sem efeito faria a pessoa achar que o app quebrou.
          // As abertas primeiro; as travadas na ordem em que a trilha as
          // abre — na ordem do enum saía "passo 7, 8, 17, 13, 16…".
          for (final e in [...Species.values]..sort((a, b) {
            int ordem(Species x) => app.especiesEscolhiveis.contains(x)
                ? -1
                : ProgressoDaTrilha.passoQueAbre(x) ?? 999;
            return ordem(a).compareTo(ordem(b));
          }))
            if (app.especiesEscolhiveis.contains(e))
              _Opcao(
                rotulo: t.animalName(e.name),
                marcada: app.species == e,
                aoTocar: () {
                  app.pickSpecies(e);
                  fechar();
                },
              )
            else
              _OpcaoTravada(
                rotulo: t.animalName(e.name),
                detalhe: t.fill(t.s('trilhaAbreNoPasso'), {
                  'n': ProgressoDaTrilha.passoQueAbre(e) ?? 0,
                }),
              ),
        ],
      ),
    );
  }

  /// Pelagem do Baru. Público para a tela que o hospedar no futuro.
  static void abreAparencia(BuildContext context, AppState app) {
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
  static void _abreMeta(BuildContext context, AppState app) {
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
                style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
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
  static void _abreHorario(BuildContext context, AppState app) {
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
                style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
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

  static void _folha(
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

/// Título de uma seção dos Ajustes.
class _Secao extends StatelessWidget {
  const _Secao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.xs, Espaco.lg, Espaco.xs, Espaco.xs),
        child: Text(titulo.toUpperCase(),
            style: estilo(Tipo.rotuloPequeno, color: Cores.tinta700).copyWith(letterSpacing: 0.8)),
      );
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
    this.detalhe,
  });

  /// Segunda linha, menor (ex.: o que há dentro de "Sua conta").
  final String? detalhe;

  /// Chave para o teste apontar a linha certa. Nula quando a linha não é
  /// alvo de nenhum teste.
  final Key? chave;
  final IconData icone;
  final String rotulo;
  final String? valor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    const cor = Cores.tinta;
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
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: detalhe == null ? 0 : Espaco.xs),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estilo(Tipo.corpo, color: cor),
                    ),
                    if (detalhe != null)
                      Text(detalhe!, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: estilo(Tipo.corpoPequeno, color: Cores.tinta700)),
                  ]),
                ),
              ),
              if (valor != null)
                Text(
                  valor!,
                  style: estilo(Tipo.rotulo, color: Cores.tinta700),
                ),
              const SizedBox(width: Espaco.xxs),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Cores.tinta500,
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
    required this.icone,
    required this.rotulo,
    required this.detalhe,
    required this.ligado,
    required this.aoTocar,
  });

  /// Mesmo ícone à esquerda das outras linhas: sem ele, o texto das chaves
  /// começava fora do alinhamento do resto dos Ajustes.
  final IconData icone;
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
            Icon(icone, size: 19, color: Cores.tinta),
            const SizedBox(width: Espaco.sm),
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
                    style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
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
                  color: Cores.folha600,
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

/// Uma espécie que a trilha ainda não abriu.
///
/// Aparece de propósito, e com o passo que a destrava: esconder o que falta
/// tira o motivo de subir, e deixá-la tocável sem efeito faz a pessoa achar
/// que o app quebrou.
class _OpcaoTravada extends StatelessWidget {
  const _OpcaoTravada({required this.rotulo, required this.detalhe});

  final String rotulo;
  final String detalhe;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      enabled: false,
      label: '$rotulo. $detalhe',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Toque.minimo),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Espaco.xs),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Cores.tinta500,
              ),
              const SizedBox(width: Espaco.sm),
              Expanded(
                child: Text(
                  rotulo,
                  style: estilo(Tipo.corpo, color: Cores.tinta700),
                ),
              ),
              Text(
                detalhe,
                style: estilo(Tipo.corpoPequeno, color: Cores.tinta700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
