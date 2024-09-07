enum NavigationType: Hashable {
  case push(Route)
  case unwind(Route)
}

struct NavigateAction {
  typealias Action = (NavigationType) -> Void
  let action: Action
  func callAsFunction(_ navigationType: NavigationType) {
    action(navigationType)
  }
}
