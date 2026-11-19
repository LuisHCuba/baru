// Extensão DeviceActivityReport: o único lugar onde o iPhone entrega o tempo
// real de cada app. Ela roda isolada pela Apple: desenha a lista, mas não
// consegue mandar esses números para o app nem para a internet.
import DeviceActivity
import SwiftUI

@main
struct RelatorioDoBaru: DeviceActivityReportExtension {
  var body: some DeviceActivityReportScene {
    RelatorioDoDia { resumo in ListaDoDia(resumo: resumo) }
  }
}

extension DeviceActivityReport.Context {
  static let dia = Self("dia")
}

struct ResumoDoDia {
  var total: TimeInterval = 0
  var apps: [(nome: String, tempo: TimeInterval)] = []
}

struct RelatorioDoDia: DeviceActivityReportScene {
  let context: DeviceActivityReport.Context = .dia
  let content: (ResumoDoDia) -> ListaDoDia

  func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> ResumoDoDia {
    var porApp: [String: TimeInterval] = [:]
    var total: TimeInterval = 0
    for await dado in data {
      for await segmento in dado.activitySegments {
        total += segmento.totalActivityDuration
        for await categoria in segmento.categories {
          for await app in categoria.applications {
            let nome = app.application.localizedDisplayName ?? app.application.bundleIdentifier ?? "App"
            porApp[nome, default: 0] += app.totalActivityDuration
          }
        }
      }
    }
    let apps = porApp.map { (nome: $0.key, tempo: $0.value) }.sorted { $0.tempo > $1.tempo }
    return ResumoDoDia(total: total, apps: Array(apps.prefix(30)))
  }
}

private let tinta = Color(red: 0.24, green: 0.20, blue: 0.16)
private let suave = Color(red: 0.40, green: 0.35, blue: 0.30)
private let folha = Color(red: 0.26, green: 0.51, blue: 0.19)
private let trilho = Color(red: 0.91, green: 0.87, blue: 0.81)

private func formata(_ s: TimeInterval) -> String {
  let m = Int(s / 60)
  return m >= 60 ? "\(m / 60)h\(m % 60 > 0 ? String(format: "%02d", m % 60) : "")" : "\(m)min"
}

struct ListaDoDia: View {
  let resumo: ResumoDoDia

  var body: some View {
    let maior = resumo.apps.first?.tempo ?? 1
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text(formata(resumo.total))
          .font(.system(size: 40, weight: .heavy, design: .rounded))
          .foregroundColor(tinta)
        ForEach(Array(resumo.apps.enumerated()), id: \.offset) { _, app in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(app.nome).font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(tinta).lineLimit(1)
              Spacer()
              Text(formata(app.tempo)).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(suave)
            }
            GeometryReader { g in
              ZStack(alignment: .leading) {
                Capsule().fill(trilho)
                Capsule().fill(folha).frame(width: max(4, g.size.width * app.tempo / max(maior, 1)))
              }
            }.frame(height: 8)
          }
        }
      }
      .padding(.vertical, 8)
    }
  }
}
