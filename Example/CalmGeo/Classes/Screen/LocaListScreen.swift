import SwiftUI
import UniformTypeIdentifiers

struct JsonDocument: FileDocument {
  static var readableContentTypes: [UTType] { [.json] }

  var json: Data

  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else {
      throw fatalError("No data")
    }
    self.json = data
  }

  init(json: Data) {
    self.json = json
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: self.json)
  }
}

struct LocaListScreen: View {
  @State var isShow = false
  @EnvironmentObject private var model: LocationModel

  var locaData: Data {
    do {
      return try JSONEncoder().encode(model.locations)
    } catch {
      fatalError("Error")
    }
  }

  var document: JsonDocument {
    return JsonDocument(json: locaData)
  }

  var body: some View {
    VStack {
      HStack {
        HStack {
          Button("接続") {
            model.attach()
          }.buttonStyle(.borderedProminent).disabled(model.isAttatched)

          Button("切断") {
            model.detatch()
          }.disabled(!model.isAttatched)
        }.frame(maxWidth: .infinity, alignment: .leading)

        HStack {
          Button(action: {
            self.isShow = true
          }) {
            Text("SaveJSON...")
          }.buttonStyle(.borderedProminent)
            .fileExporter(
              isPresented: $isShow,
              document: document,
              contentType: .json,
              defaultFilename: "Loca",
              onCompletion: { result in Logger.standard.log("Result") }
            )

          Button(action: {
            model.getRealLocation()
          }) {
            Text("現在地")
          }
        }.frame(maxWidth: .infinity, alignment: .trailing)
      }.padding()

      VStack {
        LabeledContent("現在地LNG") { Text("\(model.realLocation?.coords.longitude ?? -2)") }
        LabeledContent("現在地LAT") { Text("\(model.realLocation?.coords.latitude ?? -2)") }
        LabeledContent("現在地SPEED") { Text("\(model.realLocation?.coords.speed ?? -2)") }
        LabeledContent("現在地HEADING") { Text("\(model.realLocation?.coords.heading ?? -2)") }
        LabeledContent("現在地stamp") { Text("\(model.realLocation?.timestamp ?? "-")") }
        LabeledContent("mock") { Text("\(model.realLocation?.coords.mock ?? nil)") }
        LabeledContent("external") { Text("\(model.realLocation?.coords.external ?? nil)") }
      }.padding()

      Text("COUNT: \(model.locationCount)")
        .padding()

      List(
        model.locations.sorted(by: { lhs, rhs in
          lhs.timestamp > rhs.timestamp
        })
      ) { location in
        LabeledContent("\(location.timestamp)") {
          HStack {
            Text("\(location.coords.longitude)")
            Text("\(location.coords.latitude)")
          }
        }.font(.footnote)
      }
    }
  }
}

struct LocaListScreenPreviews: PreviewProvider {
  static var previews: some View {
    return LocaListScreen()
  }
}
