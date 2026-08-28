import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onde o e-mail e a senha lembrados ficam guardados.
///
/// **Por que não `shared_preferences`.** O snapshot do app já mora lá, em
/// texto puro; qualquer backup do aparelho leva junto. Senha não pode ir por
/// esse caminho. Aqui o `flutter_secure_storage` cifra o valor com uma
/// chave que vive no Keystore do Android (Keychain no iOS): a chave não sai
/// do aparelho, não vai em backup de nuvem e some se o bloqueio de tela for
/// removido.
///
/// **Por que lembrar a senha, e não só a sessão do Supabase.** A sessão
/// expira e o refresh token é revogado ao sair; depois disso a única forma
/// de entrar sem digitar é ter a credencial. É o que o app do banco faz
/// quando oferece digital: guarda o segredo no enclave e o desbloqueia com
/// a biometria.
///
/// **Lembrar é escolha, e é reversível.** Nada é gravado sem o interruptor
/// ligado, e sair da conta ou apagar os dados esvazia o cofre.
abstract class Cofre {
  /// O que está guardado, ou `null` se não há nada.
  Future<CredencialLembrada?> le();

  /// Guarda. Sobrescreve o que houver.
  Future<void> guarda(CredencialLembrada c);

  /// Esquece tudo. Chamado ao sair da conta e ao apagar os dados.
  Future<void> esquece();
}

@immutable
class CredencialLembrada {
  const CredencialLembrada({
    required this.email,
    required this.senha,
    required this.comBiometria,
  });

  final String email;
  final String senha;

  /// A pessoa pediu para entrar com a digital/rosto do aparelho.
  ///
  /// Separado de "tem credencial guardada" de propósito: dá para lembrar o
  /// e-mail e a senha sem aceitar a biometria, e o contrário nunca acontece
  /// — sem credencial não há o que a biometria destrave.
  final bool comBiometria;

  Map<String, dynamic> toJson() => {
        'email': email,
        'senha': senha,
        'bio': comBiometria,
      };

  static CredencialLembrada? fromJson(Map<String, dynamic> j) {
    final email = j['email'];
    final senha = j['senha'];
    if (email is! String || senha is! String) return null;
    if (email.isEmpty || senha.isEmpty) return null;
    return CredencialLembrada(
      email: email,
      senha: senha,
      comBiometria: j['bio'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CredencialLembrada &&
      other.email == email &&
      other.senha == senha &&
      other.comBiometria == comBiometria;

  @override
  int get hashCode => Object.hash(email, senha, comBiometria);
}

/// O que fazer com o cofre depois de um login que deu certo.
///
/// Mora aqui, e não dentro da tela, porque a tela só chega neste ponto com
/// Supabase de pé — e então a regra "desligado não grava" ficaria sem
/// teste, provada só por leitura. Sendo função pura de um `Cofre`, o teste
/// chama direto.
Future<void> aplicaLembranca(
  Cofre cofre, {
  required bool lembrar,
  required String email,
  required String senha,
  required bool comBiometria,
}) async {
  if (!lembrar) {
    // Desligar o interruptor não é só "não gravar agora": é apagar o que
    // estava guardado de antes.
    await cofre.esquece();
    return;
  }
  await cofre.guarda(
    CredencialLembrada(
      email: email,
      senha: senha,
      comBiometria: comBiometria,
    ),
  );
}

/// O cofre de verdade.
class CofreSeguro implements Cofre {
  CofreSeguro([FlutterSecureStorage? cofre])
      : _cofre = cofre ?? const FlutterSecureStorage();

  static const _chave = 'baru_credencial_v1';

  final FlutterSecureStorage _cofre;

  @override
  Future<CredencialLembrada?> le() async {
    try {
      final cru = await _cofre.read(key: _chave);
      if (cru == null || cru.isEmpty) return null;
      final j = jsonDecode(cru);
      if (j is! Map<String, dynamic>) return null;
      return CredencialLembrada.fromJson(j);
    } catch (_) {
      // Keystore inacessível (aparelho recém-restaurado, chave invalidada
      // por troca de bloqueio de tela). Não é erro de produto: é como se
      // não houvesse nada guardado, e a pessoa digita.
      return null;
    }
  }

  @override
  Future<void> guarda(CredencialLembrada c) async {
    try {
      await _cofre.write(key: _chave, value: jsonEncode(c.toJson()));
    } catch (_) {
      // Falhar em guardar não pode derrubar o login que acabou de dar certo.
    }
  }

  @override
  Future<void> esquece() async {
    try {
      await _cofre.delete(key: _chave);
    } catch (_) {}
  }
}

/// O cofre dos testes.
class CofreDeMentira implements Cofre {
  CofreDeMentira([this._guardada]);

  CredencialLembrada? _guardada;

  /// Quantas vezes `guarda` foi chamado — para provar que "não lembrar" não
  /// grava nada.
  int gravacoes = 0;
  int apagamentos = 0;

  CredencialLembrada? get atual => _guardada;

  @override
  Future<CredencialLembrada?> le() async => _guardada;

  @override
  Future<void> guarda(CredencialLembrada c) async {
    gravacoes++;
    _guardada = c;
  }

  @override
  Future<void> esquece() async {
    apagamentos++;
    _guardada = null;
  }
}
