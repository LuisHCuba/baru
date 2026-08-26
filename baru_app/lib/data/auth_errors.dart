import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduz erros comuns do Supabase Auth para pt/en/es/zh.
String translateAuthError(Object error, String lang) {
  final code = error is AuthException ? error.code?.toLowerCase() : null;
  final msg = error is AuthException
      ? (error.message).toLowerCase()
      : error.toString().toLowerCase();

  String pick(Map<String, String> m) => m[lang] ?? m['pt']!;

  if (code == 'invalid_credentials' ||
      msg.contains('invalid login credentials')) {
    return pick({
      'pt': 'E-mail ou senha incorretos.',
      'en': 'Incorrect email or password.',
      'es': 'Correo o contraseña incorrectos.',
      'zh': '邮箱或密码不正确。',
    });
  }
  if (code == 'user_already_registered' ||
      msg.contains('already registered') ||
      msg.contains('user already registered')) {
    return pick({
      'pt': 'Este e-mail já tem conta. Entre ou use outro e-mail.',
      'en': 'This email is already registered. Sign in or use another email.',
      'es': 'Este correo ya está registrado. Inicia sesión u usa otro.',
      'zh': '该邮箱已注册。请登录或换邮箱。',
    });
  }
  if (code == 'email_not_confirmed' ||
      msg.contains('email not confirmed') ||
      msg.contains('email_not_confirmed')) {
    return pick({
      'pt': 'Confirme seu e-mail antes de entrar. Depois use Entrar.',
      'en': 'Confirm your email before signing in.',
      'es': 'Confirma tu correo antes de entrar.',
      'zh': '请先确认邮箱后再登录。',
    });
  }
  if (code == 'weak_password' ||
      msg.contains('password') && msg.contains('least')) {
    return pick({
      'pt': 'A senha precisa ter pelo menos 6 caracteres.',
      'en': 'Password must be at least 6 characters.',
      'es': 'La contraseña debe tener al menos 6 caracteres.',
      'zh': '密码至少需要 6 个字符。',
    });
  }
  if (msg.contains('invalid email') || code == 'validation_failed') {
    return pick({
      'pt': 'Informe um e-mail válido.',
      'en': 'Enter a valid email address.',
      'es': 'Introduce un correo válido.',
      'zh': '请输入有效的邮箱。',
    });
  }
  if (msg.contains('network') || msg.contains('socket')) {
    return pick({
      'pt': 'Sem conexão. Verifique a internet e tente de novo.',
      'en': 'No connection. Check your network and try again.',
      'es': 'Sin conexión. Revisa tu red e inténtalo de nuevo.',
      'zh': '无网络连接。请检查网络后重试。',
    });
  }
  return pick({
    'pt': 'Não foi possível concluir. Tente de novo.',
    'en': 'Could not complete. Please try again.',
    'es': 'No se pudo completar. Inténtalo de nuevo.',
    'zh': '无法完成。请重试。',
  });
}
