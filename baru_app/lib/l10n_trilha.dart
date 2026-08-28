/// Os textos da trilha, nos quatro idiomas do contrato (§2).
///
/// Não moram em `l10n.dart` de propósito: aquele arquivo tem quatro mapas
/// gigantes e é o ponto de colisão de qualquer trabalho em paralelo. O
/// próprio `T` prevê isto — `T.registra` existe para um módulo declarar os
/// textos dele no arquivo dele.
///
/// O registro é **preguiçoso**: um `const` de nível superior não roda nada
/// sozinho, e um `main()` que registrasse tudo obrigaria toda entrada do app
/// (inclusive teste de widget isolado) a passar por ele. Em vez disso, cada
/// porta de entrada do módulo chama [garanteTextosDaTrilha].
library;

import 'l10n.dart';

/// Registra o catálogo da trilha. Idempotente e barato — `T.registra`
/// ignora o mesmo mapa duas vezes.
///
/// Chamado de dentro de cada função pública do módulo, não só do `build`:
/// `tituloDoMarco` e `premiosDoMarco` são usados fora da tela (celebração,
/// teste de idioma) e mostrariam a chave crua se dependessem de a tela ter
/// sido construída antes. Um flag local de "já registrei" seria pior: o
/// teste chama `T.esqueceOsExtras()` e o flag mentiria depois disso.
void garanteTextosDaTrilha() => T.registra(textosDaTrilha);

const textosDaTrilha = <String, Map<String, String>>{
  'pt': {
    'trilhaPassoDe': 'Passo {n} de {t}',
    'trilhaPassoFim': 'Trilha inteira percorrida',
    'trilhaTravado': 'Travado',
    'trilhaAbreNoPasso': 'Abre no passo {n}',
    'trilhaFaltaSessao1': 'Falta 1 sessão de foco',
    'trilhaFaltaSessoes': 'Faltam {n} sessões de foco',
    'trilhaFaltaAbaixo1': 'Falta 1 dia fechado abaixo da meta',
    'trilhaFaltaAbaixo': 'Faltam {n} dias fechados abaixo da meta',
    'trilhaFaltaSeguido1': 'Falta 1 dia seguido de presença',
    'trilhaFaltaSeguidos': 'Faltam {n} dias seguidos de presença',
    'trilhaFaltaXp': 'Faltam {n} XP para o nível {a}',
    'trilhaJaSeu': 'Já é seu. Nada aqui é retirado.',
    'trilhaHabitatsT': 'Habitats',
    'trilhaHabitatsSub': 'Cada marco abre um lugar novo para {a} morar.',
    'trilhaHabitatEmUso': 'Em uso',
    'trilhaHabitatUsar': 'Morar aqui',
    'trilhaHabitatNovo': 'Novo',
    'premioHabitatNome': 'Habitat: {h}',
    'habLagoa': 'Lagoa',
    'habIgarape': 'Igarapé',
    'habManguezal': 'Manguezal',
    'habSerra': 'Serra',
    'habPraia': 'Praia',
    'habIlha': 'Ilha',
  },
  'en': {
    'trilhaPassoDe': 'Step {n} of {t}',
    'trilhaPassoFim': 'Whole path walked',
    'trilhaTravado': 'Locked',
    'trilhaAbreNoPasso': 'Opens at step {n}',
    'trilhaFaltaSessao1': '1 focus session to go',
    'trilhaFaltaSessoes': '{n} focus sessions to go',
    'trilhaFaltaAbaixo1': '1 more day under your goal',
    'trilhaFaltaAbaixo': '{n} more days under your goal',
    'trilhaFaltaSeguido1': '1 more day in a row',
    'trilhaFaltaSeguidos': '{n} more days in a row',
    'trilhaFaltaXp': '{n} XP to level {a}',
    'trilhaJaSeu': 'It is yours. Nothing here is taken back.',
    'trilhaHabitatsT': 'Habitats',
    'trilhaHabitatsSub': 'Every milestone opens a new place for {a} to live.',
    'trilhaHabitatEmUso': 'In use',
    'trilhaHabitatUsar': 'Move here',
    'trilhaHabitatNovo': 'New',
    'premioHabitatNome': 'Habitat: {h}',
    'habLagoa': 'Lagoon',
    'habIgarape': 'Creek',
    'habManguezal': 'Mangrove',
    'habSerra': 'Highlands',
    'habPraia': 'Shore',
    'habIlha': 'Island',
  },
  'es': {
    'trilhaPassoDe': 'Paso {n} de {t}',
    'trilhaPassoFim': 'Sendero completo',
    'trilhaTravado': 'Bloqueado',
    'trilhaAbreNoPasso': 'Se abre en el paso {n}',
    'trilhaFaltaSessao1': 'Falta 1 sesión de enfoque',
    'trilhaFaltaSessoes': 'Faltan {n} sesiones de enfoque',
    'trilhaFaltaAbaixo1': 'Falta 1 día por debajo de la meta',
    'trilhaFaltaAbaixo': 'Faltan {n} días por debajo de la meta',
    'trilhaFaltaSeguido1': 'Falta 1 día seguido de presencia',
    'trilhaFaltaSeguidos': 'Faltan {n} días seguidos de presencia',
    'trilhaFaltaXp': 'Faltan {n} XP para el nivel {a}',
    'trilhaJaSeu': 'Ya es tuyo. Aquí nada se quita.',
    'trilhaHabitatsT': 'Hábitats',
    'trilhaHabitatsSub': 'Cada hito abre un lugar nuevo donde {a} puede vivir.',
    'trilhaHabitatEmUso': 'En uso',
    'trilhaHabitatUsar': 'Vivir aquí',
    'trilhaHabitatNovo': 'Nuevo',
    'premioHabitatNome': 'Hábitat: {h}',
    'habLagoa': 'Laguna',
    'habIgarape': 'Arroyo',
    'habManguezal': 'Manglar',
    'habSerra': 'Sierra',
    'habPraia': 'Playa',
    'habIlha': 'Isla',
  },
  'zh': {
    'trilhaPassoDe': '第 {n} 步，共 {t} 步',
    'trilhaPassoFim': '整条路已走完',
    'trilhaTravado': '未解锁',
    'trilhaAbreNoPasso': '第 {n} 步解锁',
    'trilhaFaltaSessao1': '还差 1 次专注',
    'trilhaFaltaSessoes': '还差 {n} 次专注',
    'trilhaFaltaAbaixo1': '还差 1 天低于目标',
    'trilhaFaltaAbaixo': '还差 {n} 天低于目标',
    'trilhaFaltaSeguido1': '还差连续 1 天',
    'trilhaFaltaSeguidos': '还差连续 {n} 天',
    'trilhaFaltaXp': '距离 {a} 级还差 {n} XP',
    'trilhaJaSeu': '已经是你的了，这里什么都不会收回。',
    'trilhaHabitatsT': '栖息地',
    'trilhaHabitatsSub': '每个里程碑都会为{a}打开一个新家。',
    'trilhaHabitatEmUso': '使用中',
    'trilhaHabitatUsar': '搬到这里',
    'trilhaHabitatNovo': '新',
    'premioHabitatNome': '栖息地：{h}',
    'habLagoa': '池塘',
    'habIgarape': '溪流',
    'habManguezal': '红树林',
    'habSerra': '山地',
    'habPraia': '海滩',
    'habIlha': '海岛',
  },
};
