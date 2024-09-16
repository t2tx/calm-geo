import CoreMotion
import Foundation
import os

@available(iOS 17.0, *)
class MotionProvider: MotionProviderProtocol {
  private var manager: CMMotionActivityManager = CMMotionActivityManager()
  private var ref: CalmGeoActivity?
  private var listener: ActivityListener?

  var currentActivity: CalmGeoActivity {
    if let activity = ref {
      return activity
    }
    return CalmGeoActivity.standard
  }

  func start(_ listener: ActivityListener?) {
    self.listener = listener
    self.manager.startActivityUpdates(to: OperationQueue.main) {
      [weak self] activity in
      guard let self = self else { return }

      if let activity = activity {
        self.ref = CalmGeoActivity.from(
          CalmMotionActivity(
            automotive: activity.automotive,
            cycling: activity.cycling,
            running: activity.running,
            stationary: activity.stationary,
            unknown: activity.unknown,
            walking: activity.walking,
            confidence: activity.confidence
          )
        )

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
