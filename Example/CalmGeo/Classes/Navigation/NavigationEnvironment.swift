import SwiftUI

struct NavigateEnvironmentKey: EnvironmentKey {
  static var defaultValue: NavigateAction = NavigateAction(action: { _ in })
}

extension EnvironmentValues {
  var navigate: (NavigateAction) {
    get { self[NavigateEnvironmentKey.self] }
    set { self[NavigateEnvironmentKey.self] = newValue }
  }
}
