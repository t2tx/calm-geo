import SwiftUI

struct MainNavigationStack: View {
  @State private var routes: [Route] = []

  var body: some View {
    NavigationStack(path: $routes) {
      MainScreen().navigationDestination(for: Route.self) { route in
        switch route {
        case .setting:
          SettingScreen()
        default:
          fatalError("Never")
        }
      }
    }.onNavigate { navType in
      switch navType {
      case .push(let route):
        self.routes.append(route)
      case .unwind(let route):
        if route == .main {
          self.routes = []
        } else {
          guard let index = self.routes.firstIndex(where: { $0 == route }) else {
            return
          }
          self.routes = Array(self.routes.prefix(upTo: index + 1))
        }
      }
    }
  }
}
