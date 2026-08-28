import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// O desbloqueio pelo aparelho.
///
/// O que o app pede é "prove que é você para este aparelho" — e quem decide
/// como é o aparelho: digital, rosto, PIN, padrão. Por isso
/// `biometricOnly: false`: exigir só biometria deixaria de fora quem não
/// cadastrou digital e quem usa aparelho sem sensor, e essas pessoas
/// perderiam o recurso sem motivo.
///
/// O app **nunca vê** a digital. O Android devolve sim ou não; a senha real
/// continua no cofre, e é ela que entra no Supabase.
abstract class Biometria {
  /// Dá para pedir desbloqueio neste aparelho agora.
  Future<bool> disponivel();

  /// Pede. `true` se a pessoa provou quem é.
  Future<bool> confirma(String motivo);
}

class BiometriaDoAparelho implements Biometria {
  BiometriaDoAparelho([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> disponivel() async {
    try {
      // As duas perguntas: `isDeviceSupported` diz se há hardware/tela de
      // bloqueio, `canCheckBiometrics` diz se há sensor. Basta a primeira
      // ser verdadeira, porque o PIN também serve.
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> confirma(String motivo) async {
    try {
      // Na 3.x os parâmetros são diretos: o `AuthenticationOptions` virou
      // detalhe interno do plugin.
      return await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      // Cancelado, bloqueado por tentativas, sem fragment activity: nada
      // disso é erro a mostrar em vermelho. A pessoa digita a senha.
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// A biometria dos testes.
class BiometriaDeMentira implements Biometria {
  BiometriaDeMentira({this.temSuporte = true, this.aceita = true});

  bool temSuporte;
  bool aceita;
  int pedidos = 0;
  String? ultimoMotivo;

  @override
  Future<bool> disponivel() async => temSuporte;

  @override
  Future<bool> confirma(String motivo) async {
    pedidos++;
    ultimoMotivo = motivo;
    return aceita;
  }
}
