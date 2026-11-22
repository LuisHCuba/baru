/// Títulos das seções de Ajustes e de Sua conta, nos quatro idiomas.
library;

import 'l10n.dart';

void garanteTextosDosAjustes() => T.registra(textosDosAjustes);

const textosDosAjustes = <String, Map<String, String>>{
  'pt': {
    'ajSecBaru': 'Seu Baru',
    'ajSecFoco': 'Foco e tempo de tela',
    'ajSecAvisos': 'Avisos e sons',
    'ajSecPermissoes': 'Permissões do celular',
    'ajSecGeral': 'Geral',
    'ajContaLinha': 'Conta, privacidade e termos',
    'ajTempoDeUsoIos': 'Tempo de Uso',
    'contaSecSobre': 'Sobre o Baru',
    'contaSecSair': 'Sair e apagar',
  },
  'en': {
    'ajSecBaru': 'Your Baru',
    'ajSecFoco': 'Focus and screen time',
    'ajSecAvisos': 'Notifications and sounds',
    'ajSecPermissoes': 'Phone permissions',
    'ajSecGeral': 'General',
    'ajContaLinha': 'Account, privacy and terms',
    'ajTempoDeUsoIos': 'Screen Time',
    'contaSecSobre': 'About Baru',
    'contaSecSair': 'Sign out and delete',
  },
  'es': {
    'ajSecBaru': 'Tu Baru',
    'ajSecFoco': 'Enfoque y tiempo de pantalla',
    'ajSecAvisos': 'Avisos y sonidos',
    'ajSecPermissoes': 'Permisos del móvil',
    'ajSecGeral': 'General',
    'ajContaLinha': 'Cuenta, privacidad y términos',
    'ajTempoDeUsoIos': 'Tiempo en pantalla',
    'contaSecSobre': 'Sobre Baru',
    'contaSecSair': 'Cerrar sesión y borrar',
  },
  'zh': {
    'ajSecBaru': '你的 Baru',
    'ajSecFoco': '专注与屏幕时间',
    'ajSecAvisos': '通知与声音',
    'ajSecPermissoes': '手机权限',
    'ajSecGeral': '通用',
    'ajContaLinha': '账户、隐私与条款',
    'ajTempoDeUsoIos': '屏幕使用时间',
    'contaSecSobre': '关于 Baru',
    'contaSecSair': '退出与删除',
  },
};
