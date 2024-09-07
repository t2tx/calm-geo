import SwiftUI

enum RootScreen: Hashable, Identifiable, CaseIterable {
  case main
  case locaList

  var id: RootScreen { self }
}

extension RootScreen {
  @ViewBuilder
  var label: some View {
    switch self {
    case .main:
      Label("Main", systemImage: "house")
    case .locaList:
      Label("LocaList", systemImage: "list.bullet")
    }
  }

  @ViewBuilder
  var destination: some View {
    switch self {
    case .main:
      MainNavigationStack()
    case .locaList:
      LocaListScreen()
    }
  }
}

struct RootView: View {
  @Binding var selection: RootScreen?

  var body: some View {
    TabView(selection: $selection) {
      ForEach(RootScreen.allCases) { screen in
        screen.destination
          .tag(screen as RootScreen?)
          .tabItem { screen.label }
      }
    }
  }
}
