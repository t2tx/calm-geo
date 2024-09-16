import Foundation
import os

@available(iOS 15.0, *)
public typealias MovingHandler = () -> Void

@available(iOS 17.0, *)
protocol MonitorProviderProtocol {
  func start(base: CalmGeoCoords, handler: @escaping MovingHandler) throws
  func stop()
}
