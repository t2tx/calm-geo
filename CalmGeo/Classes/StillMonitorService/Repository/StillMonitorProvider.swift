import CoreLocation
import Foundation
import os

@available(iOS 17.0, *)
class StillMonitorProvider: StillMonitorProviderProtocol {
  private var watchTask: Task<Void, Error>?
  private var monitor: CLMonitor

  private var config: CalmGeoLocationConfigType?

  init(config: CalmGeoLocationConfigType, monitor: CLMonitor) {
    self.config = config
    self.monitor = monitor
  }

  var isRunning: Bool { watchTask != nil }
  
  func start(base: CalmGeoCoords, handler: @escaping MovingHandler) throws {
    self.watchTask?.cancel()
    self.watchTask = Task {
      print("Set up monitor")

      await monitor.add(
        getCircularGeographicCondition(base: base), identifier: "refLoca", assuming: .satisfied)

      for try await event in await monitor.events {
        if event.state == .unsatisfied || event.state == .unknown {
          Logger.standard.info(
            "MonitorDistance: out \(event.state.rawValue) \(Date().ISO8601Format())")
          await monitor.remove("refLoca")

          handler()
        }
      }
    }
  }

  func stop() {
    Logger.standard.info("Stop Watch \(Date().ISO8601Format())")
    watchTask?.cancel()
    watchTask = nil
  }

  func getCircularGeographicCondition(base: CalmGeoCoords)
    -> CLMonitor.CircularGeographicCondition
  {
    let center = CLLocationCoordinate2D(
      latitude: base.latitude, longitude: base.longitude)

    let result = CLMonitor.CircularGeographicCondition(
      center: center,
      radius: self.config!.stationaryRadius)

    Logger.standard.info("Circlular: \(center.latitude) \(center.longitude)")

    return result
  }
}
