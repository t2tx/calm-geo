import Foundation
import os

@available(iOS 17.0, *)
class MotionManager: NSObject {
  private var provider: MotionProviderProtocol
  private var ref: CalmGeoActivity?
  private var listener: ActivityListener?

  init(provider: MotionProviderProtocol) {
    self.provider = provider
  }

  var currentActivity: CalmGeoActivity {
    provider.currentActivity
  }

  @available(iOS 17.0, *)
  func start(_ listener: ActivityListener?) {
    provider.start(listener)
  }

  func stop() {
    Logger.standard.info("Stop Activity \(Date().ISO8601Format())")
    provider.stop()
  }
}
