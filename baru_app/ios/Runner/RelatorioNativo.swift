// Mostra dentro do Flutter o relatório do dia que a extensão BaruRelatorio
// desenha (tempo real de cada app, só visível na tela — regra da Apple).
import DeviceActivity
import Flutter
import SwiftUI
import UIKit

@available(iOS 16.0, *)
final class RelatorioFabrica: NSObject, FlutterPlatformViewFactory {
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    RelatorioVista(frame: frame)
  }
}

@available(iOS 16.0, *)
final class RelatorioVista: NSObject, FlutterPlatformView {
  private let hospede: UIHostingController<DeviceActivityReport>

  init(frame: CGRect) {
    let hoje = Calendar.current.dateInterval(of: .day, for: Date())!
    let filtro = DeviceActivityFilter(segment: .daily(during: hoje), users: .all, devices: .init([.iPhone, .iPad]))
    hospede = UIHostingController(rootView: DeviceActivityReport(DeviceActivityReport.Context("dia"), filter: filtro))
    hospede.view.backgroundColor = .clear
    hospede.view.frame = frame
    super.init()
  }

  func view() -> UIView { hospede.view }
}
