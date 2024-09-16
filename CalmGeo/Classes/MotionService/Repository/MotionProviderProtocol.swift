import CoreMotion
import Foundation
import os

@available(iOS 15.0, *)
public typealias ActivityListener = (_ activity: CalmGeoActivity) -> Void

@available(iOS 17.0, *)
protocol MotionProviderProtocol {
  var currentActivity: CalmGeoActivity { get }
  func start(_ listener: ActivityListener?)
  func stop()
}
