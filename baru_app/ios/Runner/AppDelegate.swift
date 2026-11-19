import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Push silencioso da família (sem pedir permissão: não mostra nada).
    application.registerForRemoteNotifications()
    // Localização da família: o iOS relança o Baru fechado numa mudança de lugar.
    LocalDaFamilia.shared.retoma()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if #available(iOS 16.0, *) { RegrasRemotas.guardaToken(deviceToken) }
    LocalDaFamilia.shared.guardaToken(deviceToken)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  /// O responsável mudou uma regra: busca e aplica com o app em segundo plano.
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    guard (userInfo["baru"] as? String) == "regras", #available(iOS 16.0, *) else {
      super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
      return
    }
    RegrasRemotas.buscaEAplica { mudou in completionHandler(mudou ? .newData : .noData) }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TempoDeTelaPlugin") {
      TempoDeTelaPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LocalDaFamilia") {
      LocalDaFamilia.register(with: registrar.messenger())
    }
  }
}
