import SwiftUI

struct MainScreen: View {
  @EnvironmentObject private var model: LocationModel
  @Environment(\.navigate) private var navigate

  var prettyLocation: String {
    guard let location = model.currentLocation else {
      return "no location"
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let data = try! encoder.encode(location)
    return String(data: data, encoding: .utf8)!
  }

  var syncState: String {
    guard let state = model.syncState else {
      return "no state"
    }

    return "stamp: \(state.timestamp.ISO8601Format()) / tried: \(state.tried) / wait: \(state.wait)"
  }

  var body: some View {
    VStack {
      HStack {
        Button("Sync") {
          model.forceSync()
        }.buttonStyle(.borderedProminent)
        Button("Clear") {
          model.clearAll()
        }.buttonStyle(.borderedProminent)
        Button("Setting...") {
          navigate(.push(.setting))
        }.buttonStyle(.borderedProminent).frame(
          maxWidth: /*@START_MENU_TOKEN@*/ .infinity /*@END_MENU_TOKEN@*/, alignment: .trailing)
      }.frame(maxWidth: .infinity, alignment: .leading)

      HStack {
        Button(action: model.startGpsService) {
          Text("Start")
        }.buttonStyle(.borderedProminent).disabled(model.isRunning)
        Button(action: model.stopGpsService) {
          Text("Stop")
        }.buttonStyle(.borderedProminent).disabled(!model.isRunning)
      }.frame(maxWidth: .infinity, alignment: .trailing)

      LabeledContent("COUNT") {
        Text("\(model.locationCount)").padding().font(.largeTitle)
      }

      Text("同期状態").font(.title2).frame(maxWidth: .infinity, alignment: .leading)
      VStack {
        LabeledContent("stamp") {
          Text("\(model.syncState?.timestamp.ISO8601Format() ?? "-")")
        }
        LabeledContent("tried") {
          Text("\(model.syncState?.tried ?? -3)")
        }
        LabeledContent("waiting") {
          Text("\(model.syncState?.wait ?? -3)")
        }
      }.padding()

      Text("Pretty").font(.title2).frame(maxWidth: .infinity, alignment: .leading)

      ScrollView {
        Text("\(prettyLocation)").font(.footnote).frame(maxWidth: .infinity).padding(.vertical)
          .background(.gray.opacity(0.3)).textSelection(.enabled)
      }
    }.padding().frame(alignment: .leading)
  }
}
