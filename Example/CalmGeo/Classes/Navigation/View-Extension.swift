import SwiftUI

extension View {
  func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
    self.environment(\.navigate, NavigateAction(action: action))
  }
}
