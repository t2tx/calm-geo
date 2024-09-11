import CoreMotion
import Foundation
import os

@available(iOS 15.0, *)
typealias ActivityListener = (_ activity: CalmGeoActivity) -> Void

@available(iOS 17.0, *)
class MotionManager: NSObject {
  private var manager: CMMotionActivityManager = CMMotionActivityManager()
  private var ref: CalmGeoActivity?
  private var listener: ActivityListener?

  var currentActivity: CalmGeoActivity {
    if let activity = ref {
      return activity
    }
    return CalmGeoActivity.standard
  }

  @available(iOS 17.0, *)
  func start(_ listener: ActivityListener?) {
    self.listener = listener
    self.manager.startActivityUpdates(to: OperationQueue.main) {
      [weak self] activity in
      guard let self = self else { return }

      if let activity = activity {
        self.ref = CalmGeoActivity(
          type: CalmGeoActivity.Activity.from(activity),
          confidence: activity.confidence.rawValue * 33)
        self.listener?(self.ref!)
      }
    }
  }

  func stop() {
    Logger.standard.info("Stop Activity \(Date().ISO8601Format())")
    manager.stopActivityUpdates()
    ref = nil
    listener = nil
  }
}
