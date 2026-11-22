/// Títulos das seções de Ajustes e de Sua conta, nos quatro idiomas.
library;

import 'l10n.dart';

void garanteTextosDosAjustes() => T.registra(textosDosAjustes);

const textosDosAjustes = <String, Map<String, String>>{
  'pt': {
    'seuBaruT': 'Seu Baru',
    'seuBaruAnimal': 'Animal',
    'contaPrivDados': 'Privacidade e seus dados',
    'ajSecFoco': 'Foco',
    'ajSecNotif': 'Notificações',
    'ajSecSom': 'Som',
    'ajSecPermissoes': 'Permissões do celular',
    'ajSecGeral': 'Geral',
    'ajContaLinha': 'Conta, privacidade e termos',
    'ajTempoDeUsoIos': 'Tempo de Uso',
    'contaSecSobre': 'Sobre o Baru',
    'contaSecSair': 'Sair e apagar',
  },
  'en': {
    'seuBaruT': 'Your Baru',
    'seuBaruAnimal': 'Animal',
    'contaPrivDados': 'Privacy and your data',
    'ajSecFoco': 'Focus',
    'ajSecNotif': 'Notifications',
    'ajSecSom': 'Sound',
    'ajSecPermissoes': 'Phone permissions',
    'ajSecGeral': 'General',
    'ajContaLinha': 'Account, privacy and terms',
    'ajTempoDeUsoIos': 'Screen Time',
    'contaSecSobre': 'About Baru',
    'contaSecSair': 'Sign out and delete',
  },
  'es': {
    'seuBaruT': 'Tu Baru',
    'seuBaruAnimal': 'Animal',
    'contaPrivDados': 'Privacidad y tus datos',
    'ajSecFoco': 'Enfoque',
    'ajSecNotif': 'Notificaciones',
    'ajSecSom': 'Sonido',
    'ajSecPermissoes': 'Permisos del móvil',
    'ajSecGeral': 'General',
    'ajContaLinha': 'Cuenta, privacidad y términos',
    'ajTempoDeUsoIos': 'Tiempo en pantalla',
    'contaSecSobre': 'Sobre Baru',
    'contaSecSair': 'Cerrar sesión y borrar',
  },
  'zh': {
    'seuBaruT': '你的 Baru',
    'seuBaruAnimal': '动物',
    'contaPrivDados': '隐私与你的数据',
    'ajSecFoco': '专注',
    'ajSecNotif': '通知',
    'ajSecSom': '声音',
    'ajSecPermissoes': '手机权限',
    'ajSecGeral': '通用',
    'ajContaLinha': '账户、隐私与条款',
    'ajTempoDeUsoIos': '屏幕使用时间',
    'contaSecSobre': '关于 Baru',
    'contaSecSair': '退出与删除',
  },
};
