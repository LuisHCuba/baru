import 'package:flutter/material.dart';

import 'theme.dart';

enum AppScreen {
  onb,
  paywall,
  home,
  session,
  result,
  report,
  shop,
  profile,
  tempo,
  trilha,
  missoes,
  folhas,
  sequencia,
  conta,
}

enum Species { capybara, otter, tortoise, owl }

enum Mood { radiant, content, neutral, sleepy, missingYou }

enum Activity { idle, nap, swim, graze }

enum WeekDayKind { present, frozen, today, empty }

/// Momento do dia. O habitat às 22h não pode ser igual ao das 9h.
enum PeriodoDoDia { amanhecer, dia, entardecer, noite }

/// Fatias escolhidas para que a cena mude de luz nos horários em que o
/// usuário efetivamente abre o app: de manhã cedo, ao longo do dia, no fim da
/// tarde (quando chega o relatório) e à noite.
PeriodoDoDia periodoDe(DateTime agora) {
  final h = agora.hour;
  if (h >= 5 && h < 9) return PeriodoDoDia.amanhecer;
  if (h >= 9 && h < 17) return PeriodoDoDia.dia;
  if (h >= 17 && h < 20) return PeriodoDoDia.entardecer;
  return PeriodoDoDia.noite;
}

enum PayPlan { annual, monthly }

class LangDef {
  const LangDef(this.id, this.label, this.tag);
  final String id;
  final String label;
  final String tag;
}

const langs = [
  LangDef('pt', 'Português', 'pt-BR'),
  LangDef('en', 'English', 'en'),
  LangDef('es', 'Español', 'es'),
  LangDef('zh', '中文', 'zh-Hans'),
];

const petNames = {
  Species.capybara: 'Baru',
  Species.otter: 'Rio',
  Species.tortoise: 'Toco',
  Species.owl: 'Nina',
};

const durations = [25, 50, 90, 45];
const avgOptions = [180, 240, 300, 360];
const goalOptions = [90, 120, 150, 180];

/// Limites da meta quando ela é ajustada à mão.
///
/// Meta de 10 minutos não é meta, é frustração programada; acima de 8 horas
/// ela para de significar alguma coisa.
const metaMinima = 30;
const metaMaxima = 480;
const metaPasso = 15;

/// O sexo do companheiro.
///
/// Não muda o desenho — muda como o app fala dele. Em português e espanhol
/// isso é gramática, não enfeite: "ele te esperou" e "ela te esperou" são
/// frases diferentes, e chamar a bicha de "ele" o tempo todo é o app errando
/// o nome dela.
enum Sexo { naoDito, macho, femea }

const weekPattern = [
  WeekDayKind.present,
  WeekDayKind.present,
  WeekDayKind.frozen,
  WeekDayKind.present,
  WeekDayKind.present,
  WeekDayKind.today,
  WeekDayKind.empty,
];

/// Segunda = 0 … domingo = 6, igual ao `days` do design.
int weekdayIndex([DateTime? now]) => (now ?? DateTime.now()).weekday - 1;

List<WeekDayKind> freshWeek([DateTime? now]) {
  final today = weekdayIndex(now);
  return List<WeekDayKind>.generate(
    7,
    (i) => i == today ? WeekDayKind.today : WeekDayKind.empty,
  );
}

/// Melhor idioma do Baru para um locale de sistema.
///
/// Usado antes do onboarding, quando o usuário ainda não escolheu: a tela de
/// login não deveria falar português com quem tem o aparelho em chinês.
String langFromLocale(Locale locale) {
  final code = locale.languageCode.toLowerCase();
  for (final l in langs) {
    if (l.id == code) return l.id;
  }
  return 'pt';
}

Locale localeFor(String lang) {
  switch (lang) {
    case 'en':
      return const Locale('en');
    case 'es':
      return const Locale('es');
    case 'zh':
      return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    default:
      return const Locale('pt');
  }
}

class ShapePart {
  const ShapePart(this.x, this.y, this.w, this.h, this.r, this.c);
  final double x, y, w, h, r;
  final Color c;
}

class ShopItemDef {
  const ShopItemDef(this.id, this.price, this.parts);
  final String id;
  final int price;
  final List<ShapePart> parts;
}

const shopItems = [
  ShopItemDef('lily', 40, [
    ShapePart(8, 252, 42, 15, 8, AppColors.green),
    ShapePart(54, 266, 28, 11, 6, AppColors.greenSoft),
  ]),
  ShopItemDef('bamboo', 70, [
    ShapePart(302, 98, 8, 82, 4, AppColors.green),
    ShapePart(316, 116, 8, 64, 4, AppColors.greenSoft),
    ShapePart(290, 130, 7, 50, 4, AppColors.greenHover),
  ]),
  ShopItemDef('rock', 110, [
    ShapePart(252, 254, 66, 30, 15, AppColors.rock),
    ShapePart(268, 244, 34, 16, 9, AppColors.rockLight),
  ]),
  ShopItemDef('dock', 150, [
    ShapePart(2, 192, 68, 11, 6, AppColors.wood),
    ShapePart(12, 203, 8, 20, 4, AppColors.woodDark),
    ShapePart(54, 203, 8, 20, 4, AppColors.woodDark),
  ]),
  ShopItemDef('lantern', 190, [
    ShapePart(52, 30, 28, 36, 13, AppColors.orange),
    ShapePart(64, 8, 3, 24, 2, Color(0x403E2F23)),
  ]),
  ShopItemDef('tree', 240, [
    ShapePart(36, 120, 11, 66, 5, AppColors.woodDark),
    ShapePart(6, 70, 58, 54, 27, AppColors.green),
    ShapePart(34, 92, 10, 10, 5, AppColors.orange),
  ]),
  ShopItemDef('boat', 300, [
    ShapePart(288, 208, 62, 18, 9, AppColors.boat),
    ShapePart(317, 180, 4, 30, 2, AppColors.woodDark),
    ShapePart(321, 182, 20, 18, 3, AppColors.cream),
  ]),
  ShopItemDef('bridge', 400, [
    ShapePart(100, 250, 138, 13, 7, AppColors.rock),
    ShapePart(108, 260, 10, 24, 5, AppColors.rockDark),
    ShapePart(220, 260, 10, 24, 5, AppColors.rockDark),
  ]),
];

const habitats = {
  'empty': <String>[],
  'half': ['lily', 'dock', 'rock'],
  'full': ['lily', 'bamboo', 'rock', 'dock', 'lantern', 'tree', 'boat', 'bridge'],
};

/// Pesos do quiz (3 perguntas × 4 opções), iguais ao design.
const quizWeights = [
  [
    {Species.capybara: 2},
    {Species.otter: 2},
    {Species.tortoise: 2},
    {Species.owl: 2},
  ],
  [
    {Species.tortoise: 1},
    {Species.otter: 1},
    {Species.owl: 2},
    {Species.capybara: 1},
  ],
  [
    {Species.capybara: 2},
    {Species.otter: 1},
    {Species.owl: 1},
    {Species.tortoise: 2},
  ],
];

String fmtMinutes(int min, String lang) {
  final h = min ~/ 60;
  final m = min % 60;
  if (lang == 'zh') {
    if (h == 0) return '$m分';
    return m == 0 ? '$h小时' : '$h小时$m分';
  }
  final u = lang == 'en' ? 'm' : 'min';
  if (h == 0) return '$m$u';
  return m == 0 ? '${h}h' : '${h}h $m$u';
}

int sessionReward(int dur) {
  if (dur == 25) return 10;
  if (dur == 50) return 25;
  if (dur == 90) return 50;
  return (dur * 0.5).floor();
}

int suggestedGoal(int avg) => ((avg * 0.75) / 15).round() * 15;
