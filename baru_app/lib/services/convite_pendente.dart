import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Convite de laço que chegou por link (`baru://convite/CÓDIGO`, aberto pela
/// página meubaru.com/convite). Fica guardado até a pessoa entrar (ou
/// recusar): quem ainda não tinha conta faz login e o convite continua lá.
class ConvitePendente {
  ConvitePendente._();

  static const _chave = 'baru_convite_pendente';
  static final codigo = ValueNotifier<String?>(null);

  /// Só letras e números, 6 a 8 caracteres (o formato dos códigos).
  static String? limpa(String? bruto) {
    final c = (bruto ?? '').trim().toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    return c.length >= 6 && c.length <= 8 ? c : null;
  }

  /// O código de um endereço de convite, ou null se não for um.
  static String? doEndereco(Uri uri) {
    if (uri.host == 'convite') {
      final seg = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      return limpa(seg.isNotEmpty ? seg.first : uri.queryParameters['c']);
    }
    if (uri.path.startsWith('/convite')) return limpa(uri.queryParameters['c']);
    return null;
  }

  static Future<void> guarda(String c) async {
    codigo.value = c;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave, c);
    } catch (_) {}
  }

  static Future<void> carrega() async {
    if (codigo.value != null) return;
    try {
      final p = await SharedPreferences.getInstance();
      codigo.value = limpa(p.getString(_chave));
    } catch (_) {}
  }

  static Future<void> esquece() async {
    codigo.value = null;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_chave);
    } catch (_) {}
  }
}
