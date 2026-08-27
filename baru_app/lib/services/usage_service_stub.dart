import '../data/tempo_de_tela.dart';

/// Stub para web/desktop — sem APIs de tempo de tela.
///
/// Devolve `null`, não zero: "não sei" é diferente de "não usou". A tela mostra
/// estado vazio honesto em vez de um número inventado.
class UsageService {
  UsageService._();

  static final UsageService instance = UsageService._();

  /// Android lê UsageStats; iOS exige entitlement Family Controls da Apple.
  bool get platformSupportsUsage => false;

  Future<bool> hasUsageAccess() async => false;

  Future<bool> requestUsageAccess() async => false;

  Future<ResumoDeTela?> resumoDeHoje({
    Map<String, CategoriaDeApp> ajustes = const {},
    DateTime? agora,
  }) async =>
      null;

  Future<int?> todayScreenTimeMinutes({
    Map<String, CategoriaDeApp> ajustes = const {},
  }) async =>
      null;
}
