/// Stub para web/desktop — sem APIs de tempo de tela.
class UsageService {
  UsageService._();

  static final UsageService instance = UsageService._();

  /// Android lê UsageStats; iOS exige entitlement Family Controls da Apple.
  bool get platformSupportsUsage => false;

  Future<bool> hasUsageAccess() async => false;

  Future<bool> requestUsageAccess() async => false;

  Future<int?> todayScreenTimeMinutes() async => null;
}
