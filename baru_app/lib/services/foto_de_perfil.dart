import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n.dart';
import '../theme.dart';

/// Foto de perfil das pessoas da família (bucket privado "baru-fotos").
///
/// O arquivo é `<user_id>.jpg`; quem pode ver e trocar é decidido no banco
/// (a própria pessoa, a família; a criança também pelo responsável). A
/// "versão" é a hora da última troca: muda a versão, muda a imagem.
class FotoDePerfil {
  FotoDePerfil._();

  static const _bucket = 'baru-fotos';
  static final _urls = <String, ({String url, DateTime ate})>{};

  /// Avisa quem mostra fotos que uma mudou (id da pessoa).
  static final mudou = ValueNotifier<String?>(null);

  /// Versão da minha foto, para a tela da conta.
  static Future<DateTime?> minhaVersao() async {
    final r = await Supabase.instance.client.rpc('baru_minha_foto');
    return r == null ? null : DateTime.tryParse('$r');
  }

  /// Endereço assinado (1 hora) da foto, guardado enquanto vale.
  static Future<String?> url(String dono, DateTime? versao) async {
    if (versao == null) return null;
    final chave = '$dono@${versao.millisecondsSinceEpoch}';
    final pronto = _urls[chave];
    if (pronto != null && pronto.ate.isAfter(DateTime.now())) return pronto.url;
    final u = await Supabase.instance.client.storage.from(_bucket).createSignedUrl('$dono.jpg', 3600);
    _urls[chave] = (url: u, ate: DateTime.now().add(const Duration(minutes: 55)));
    return u;
  }

  static String _tipo(Uint8List b) {
    if (b.length > 4 && b[0] == 0x89 && b[1] == 0x50) return 'image/png';
    if (b.length > 12 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return 'image/webp';
    return 'image/jpeg';
  }

  static Future<DateTime?> envia(String dono, Uint8List bytes) async {
    final db = Supabase.instance.client;
    await db.storage.from(_bucket).uploadBinary('$dono.jpg', bytes,
        fileOptions: FileOptions(upsert: true, contentType: _tipo(bytes), cacheControl: '3600'));
    final r = await db.rpc('baru_foto_marca', params: {'p_dono': dono});
    mudou.value = '$dono@${DateTime.now().millisecondsSinceEpoch}';
    return r == null ? null : DateTime.tryParse('$r');
  }

  static Future<void> remove(String dono) async {
    final db = Supabase.instance.client;
    try {
      await db.storage.from(_bucket).remove(['$dono.jpg']);
    } catch (_) {}
    await db.rpc('baru_foto_marca', params: {'p_dono': dono, 'p_removida': true});
    mudou.value = '$dono@${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Folha com câmera, galeria e remover. Devolve true se mudou.
  static Future<bool> escolhe(BuildContext context, T t, {required String dono, required bool temFoto}) async {
    final m = ScaffoldMessenger.maybeOf(context);
    final acao = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Cores.canvas,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: Text(t.s('fotoT'), style: estilo(Tipo.subtitulo))),
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.s('fotoCamera')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(t.s('fotoGaleria')),
            onTap: () => Navigator.pop(ctx, 'galeria'),
          ),
          if (temFoto)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Cores.alerta),
              title: Text(t.s('fotoRemover'), style: const TextStyle(color: Cores.alerta)),
              onTap: () => Navigator.pop(ctx, 'remover'),
            ),
        ]),
      ),
    );
    if (acao == null) return false;
    try {
      if (acao == 'remover') {
        await remove(dono);
        return true;
      }
      final x = await ImagePicker().pickImage(
        source: acao == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
        preferredCameraDevice: CameraDevice.front,
      );
      if (x == null) return false;
      final bytes = await x.readAsBytes();
      if (bytes.length > 1024 * 1024) throw StateError('grande');
      await envia(dono, bytes);
      m?.showSnackBar(SnackBar(content: Text(t.s('fotoPronta'))));
      return true;
    } catch (e) {
      debugPrint('foto: $e');
      m?.showSnackBar(SnackBar(content: Text(t.s('fotoFalhou'))));
      return false;
    }
  }
}

/// Círculo com a foto da pessoa; sem foto (ou sem rede), a inicial do nome.
class FotoOuLetra extends StatefulWidget {
  const FotoOuLetra({
    super.key,
    required this.dono,
    required this.versao,
    required this.nome,
    this.raio = 20,
    this.cor,
    this.corDaLetra = Colors.white,
  });

  final String dono;
  final DateTime? versao;
  final String nome;
  final double raio;
  final Color? cor;
  final Color corDaLetra;

  @override
  State<FotoOuLetra> createState() => _FotoOuLetraState();
}

class _FotoOuLetraState extends State<FotoOuLetra> {
  String? _url;

  @override
  void initState() {
    super.initState();
    _carrega();
  }

  @override
  void didUpdateWidget(FotoOuLetra antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.dono != widget.dono || antigo.versao != widget.versao) _carrega();
  }

  Future<void> _carrega() async {
    if (widget.versao == null) {
      if (_url != null) setState(() => _url = null);
      return;
    }
    try {
      final u = await FotoDePerfil.url(widget.dono, widget.versao);
      if (mounted) setState(() => _url = u);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final letra = widget.nome.trim().isEmpty ? '?' : widget.nome.trim().characters.first.toUpperCase();
    final fundo = widget.cor ?? Cores.primariaEscura;
    final semFoto = CircleAvatar(
      radius: widget.raio,
      backgroundColor: fundo,
      child: Text(letra, style: estilo(Tipo.subtitulo, color: widget.corDaLetra).copyWith(fontSize: widget.raio * 0.9)),
    );
    final url = _url;
    if (url == null) return semFoto;
    return ClipOval(
      child: Image.network(
        url,
        width: widget.raio * 2,
        height: widget.raio * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => semFoto,
        loadingBuilder: (_, filho, progresso) => progresso == null ? filho : semFoto,
      ),
    );
  }
}
