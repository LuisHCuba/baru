/// Os textos do código de e-mail na porta de entrada, nos quatro idiomas.
///
/// O e-mail de cadastro e o de recuperação de senha trazem um código de 8
/// dígitos ("Ou use este código no app"). Estas telas são onde ele entra:
/// confirmar o cadastro e trocar a senha sem depender do link, que abre no
/// navegador. Prefixo `cod` para não colidir com o catálogo principal.
library;

import 'l10n.dart';

const textosDoCodigo = <String, Map<String, String>>{
  'pt': {
    'codTituloSenha': 'Trocar a senha',
    'codTituloCadastro': 'Confirmar o e-mail',
    'codSub': 'Enviamos um código de 8 dígitos para {e}. Digite aqui.',
    'codCampo': 'Código do e-mail',
    'codNovaSenha': 'Senha nova',
    'codConfirmaSenha': 'Repita a senha nova',
    'codBotaoSenha': 'Trocar senha e entrar',
    'codBotaoCadastro': 'Confirmar e entrar',
    'codInvalido':
        'Código errado ou vencido. Confira o último e-mail ou peça outro.',
    'codCurto': 'O código tem 8 dígitos.',
    'codReenviar': 'Mandar outro código',
    'codReenviado': 'Mandamos outro código para {e}.',
    'codVoltar': 'Voltar para o login',
  },
  'en': {
    'codTituloSenha': 'Change your password',
    'codTituloCadastro': 'Confirm your email',
    'codSub': 'We sent an 8-digit code to {e}. Enter it here.',
    'codCampo': 'Code from the email',
    'codNovaSenha': 'New password',
    'codConfirmaSenha': 'Repeat the new password',
    'codBotaoSenha': 'Change password and sign in',
    'codBotaoCadastro': 'Confirm and sign in',
    'codInvalido':
        'Wrong or expired code. Check the latest email or ask for a new one.',
    'codCurto': 'The code has 8 digits.',
    'codReenviar': 'Send another code',
    'codReenviado': 'We sent another code to {e}.',
    'codVoltar': 'Back to sign in',
  },
  'es': {
    'codTituloSenha': 'Cambiar la contraseña',
    'codTituloCadastro': 'Confirmar el correo',
    'codSub': 'Enviamos un código de 8 dígitos a {e}. Escríbelo aquí.',
    'codCampo': 'Código del correo',
    'codNovaSenha': 'Contraseña nueva',
    'codConfirmaSenha': 'Repite la contraseña nueva',
    'codBotaoSenha': 'Cambiar contraseña y entrar',
    'codBotaoCadastro': 'Confirmar y entrar',
    'codInvalido':
        'Código incorrecto o vencido. Revisa el último correo o pide otro.',
    'codCurto': 'El código tiene 8 dígitos.',
    'codReenviar': 'Enviar otro código',
    'codReenviado': 'Enviamos otro código a {e}.',
    'codVoltar': 'Volver al inicio de sesión',
  },
  'zh': {
    'codTituloSenha': '修改密码',
    'codTituloCadastro': '确认邮箱',
    'codSub': '我们已向 {e} 发送 8 位验证码，请在这里输入。',
    'codCampo': '邮件中的验证码',
    'codNovaSenha': '新密码',
    'codConfirmaSenha': '再次输入新密码',
    'codBotaoSenha': '修改密码并登录',
    'codBotaoCadastro': '确认并登录',
    'codInvalido': '验证码错误或已过期。请查看最新邮件或重新获取。',
    'codCurto': '验证码为 8 位数字。',
    'codReenviar': '重新发送验证码',
    'codReenviado': '已向 {e} 重新发送验证码。',
    'codVoltar': '返回登录',
  },
};

void garanteTextosDoCodigo() => T.registra(textosDoCodigo);
