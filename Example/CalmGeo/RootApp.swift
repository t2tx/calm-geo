import SwiftUI

@main
struct RootApp: App {
  @State private var selection: RootScreen? = .main

  var body: some Scene {
    WindowGroup {
      RootView(selection: $selection).environmentObject(
        LocationModel(service: GeoAssembly().build()))
    }
  }
}
