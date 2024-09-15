import CalmGeo
import SwiftUI

let DistanceFilter = [
  10,
  16,
  20,
  30,
  50,
  100,
]

let SpeedMultiplier = [
  1.0,
  1.5,
  2.0,
  2.5,
  3.0,
  3.1,
  3.5,
  4.0,
  4.5,
  5.0,
]

let StationaryRadius = [
  10.0,
  25.0,
  50.0,
  100.0,
  200.0,
]

struct SettingScreen: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @EnvironmentObject private var model: LocationModel

  @State private var formUrl = ""
  @State private var formToken = ""

  var body: some View {
    VStack {
      Form {
        Section("位置情報関連") {
          Picker("位置情報の取得間隔", selection: $model.config.distanceFilter) {
            ForEach(DistanceFilter.indices, id: \.self) {
              Text("\(DistanceFilter[$0])m").tag(DistanceFilter[$0])
            }
          }
          Toggle("速度により間隔補正を無効に", isOn: $model.config.disableSpeedMultiplier)
          Picker("速度補正係数", selection: $model.config.speedMultiplier) {
            ForEach(SpeedMultiplier.indices, id: \.self) {
              Text(String(format: "%.1f", SpeedMultiplier[$0])).tag(SpeedMultiplier[$0])
            }
          }
        }

        Section("身体活動関連") {
          Toggle("身体活動の取得", isOn: $model.config.fetchActivity)
        }

        Section("休止・再開関連") {
          Picker("再開移動距離", selection: $model.config.stationaryRadius) {
            ForEach(StationaryRadius.indices, id: \.self) {
              Text(String(format: "%.1f", StationaryRadius[$0]) + "m").tag(StationaryRadius[$0])
            }
          }
        }

        Section("サーバ同期関連") {
          Toggle("自動同期", isOn: $model.config.autoSync)

          TextField("URL", text: $formUrl).task { formUrl = model.config.url ?? "" }
          TextField("トークン", text: $formToken).task { formToken = model.config.token ?? "" }
          TextField("HTTPタイムアウト (ms)", value: $model.config.httpTimeout, format: .number)
            .keyboardType(
              .decimalPad)
          Picker("METHOD", selection: $model.config.method) {
            ForEach(RequestMethod.allCases) {
              method in Text(method.rawValue).tag(method.rawValue)
            }
          }
          TextField("最小同期記録数", value: $model.config.syncThreshold, format: .number).keyboardType(
            .decimalPad)
          TextField("1回送信の最大記録数", value: $model.config.maxBatchSize, format: .number).keyboardType(
            .decimalPad)
        }
      }.navigationTitle("設定").toolbar {
        Button("適用") {
          var work = model.config
          work.url = formUrl.isEmpty ? nil : formUrl
          work.token = formToken.isEmpty ? nil : formToken
          model.applyConfig(config: work)

          self.presentationMode.wrappedValue.dismiss()
        }.buttonStyle(.borderedProminent).frame(
          maxWidth: .infinity, alignment: .trailing)
      }
    }
  }
}

struct SettingScreenPreviews: PreviewProvider {
  static var previews: some View {
    SettingScreen()
  }
}
