import CoreLocation
import Foundation
import os

let TIME_TO_SLEEP = 120.0
let TIME_TO_STILL = 60.0

@available(iOS 15.0, *)
typealias Listener = (_ location: CalmGeoLocation) -> Void

@available(iOS 17.0, *)
class CalmGeoLocationManager: NSObject, CLLocationManagerDelegate {
  private var updateStamp: Date = Date()

  private var monitor: StillMonitorProviderProtocol
  private var location: LocationProviderProtocol

  private var refLoca: CalmGeoCoords?
  private var isMoving: Bool = false
  private var listener: Listener?

  private var config: CalmGeoLocationConfigType

  init(
    config: CalmGeoLocationConfigType, monitor: StillMonitorProviderProtocol,
    location: LocationProviderProtocol
  ) {
    self.monitor = monitor
    self.location = location
    self.config = config
    super.init()
    self.config(config)
  }

  var isRunning: Bool {
    return location.isRunning || monitor.isRunning
  }

  func config(_ config: CalmGeoLocationConfigType) {
    self.config = config
    self.location.config(config)
  }

  var currentLocation: CalmGeoLocation? {
    if let location = location.currentLocation {
      let loca = buildMovingLocation(location)
      if let listener {
        listener(loca)
      }
      return loca
    }
    return nil
  }

  func requestWhenInUseAuthorization() {
    location.requestAuthorization()
  }

  func monitorDistance() {
    self.monitor.stop()

    do {
      try monitor.start(
        base: self.refLoca ?? CalmGeoCoords(from: CLLocation()), radius: config.stationaryRadius
      ) {
        if let location = self.location.currentLocation, let listener = self.listener {
          // start move
          Logger.standard.info("motionchange: Moving")
          self.isMoving = true
          listener(
            buildMotionChangeLocation(location, isMoving: true))
        }
        self.switchToListen()
      }
    } catch {
      Logger.standard.info("Some error")
      debugPrint("Some Error Occured")
    }
  }

  func filterLocation(_ location: CalmGeoCoords?) -> Bool {
    guard let refLoca = self.refLoca else {
      self.refLoca = location
      return true
    }

    if self.monitor.isRunning {
      return true
    }

    if let location {
      let distance = location.distance(from: refLoca)

      let config = self.config
      let judge =
        config.disableSpeedMultiplier
        ? Double(config.distanceFilter)
        : max(
          (round(location.speed / 5.0)) * config.speedMultiplier
            * Double(config.distanceFilter), Double(config.distanceFilter))

      Logger.standard.info(
        "Distance: \(judge) \(distance) \(location.timestamp?.ISO8601Format() ?? "")")

      if distance > judge {
        self.refLoca = location
        return true
      }

      if let diff = self.refLoca?.timestamp?.timeIntervalSinceNow {
        if abs(diff) > TIME_TO_STILL && isMoving {
          self.refLoca = location
          if distance < Double(config.distanceFilter) {
            Logger.standard.info("motionchange: Still")
            listener?(
              buildMotionChangeLocation(location, isMoving: false))
            isMoving = false
          }
        }

        let diffPast = abs(self.updateStamp.timeIntervalSinceNow)
        if abs(diff) > TIME_TO_SLEEP && diffPast > TIME_TO_SLEEP {
          if isMoving {
            Logger.standard.info("motionchange: Still")
            listener?(
              buildMotionChangeLocation(location, isMoving: false))
            isMoving = false
          }

          Logger.standard.info("Should Stop Listen")
          self.switchToMonitor()
        }
      }
    }

    return false
  }

  func handleLocation(_ location: CalmGeoCoords?) {
    if self.monitor.isRunning {
      return
    }

    if let stamp = location?.timestamp {
      Logger.standard.info("Current Location is \(stamp.ISO8601Format())")
    }

    // Call the listener
    if let location {
      if self.isMoving {
        listener?(buildMovingLocation(location))
      } else {
        Logger.standard.info("motionchange: Moving")
        isMoving = true
        listener?(
          buildMotionChangeLocation(location, isMoving: true)
        )
      }
    }
  }

  func listenToLocation(_ listener: @escaping (_ location: CalmGeoLocation) -> Void) {
    Logger.standard.info("listenToLocation in")

    self.location.stop()
    self.listener = listener

    self.updateStamp = Date()

    self.location.listenToLocation(self.handleLocation, filter: self.filterLocation)
  }

  func stopWatch() {
    Logger.standard.info("Stop Watch \(Date().ISO8601Format())")
    self.monitor.stop()
  }

  func switchToListen() {
    stopWatch()

    if let listener = self.listener {
      listenToLocation(listener)
    } else {
      Logger.standard.info("No Listener!!!")
    }
  }

  func stopListen() {
    Logger.standard.info("Stop Listen \(Date().ISO8601Format())")
    self.location.stop()
  }

  func switchToMonitor() {
    stopListen()
    monitorDistance()
  }

  func stop() {
    Logger.standard.info("Stop \(Date().ISO8601Format())")

    stopListen()
    stopWatch()
  }
}

@available(iOS 15.0, *)
func buildMovingLocation(_ coords: CalmGeoCoords) -> CalmGeoLocation {
  let stamp = (coords.timestamp as Date?) ?? Date.now

  return CalmGeoLocation(
    id: UUID().uuidString, timestamp: stamp.iso8601Stamp, isMoving: true,
    coords: coords)
}

@available(iOS 15.0, *)
func buildMotionChangeLocation(_ coords: CalmGeoCoords, isMoving: Bool) -> CalmGeoLocation {
  let stamp = (coords.timestamp as Date?) ?? Date.now

  return CalmGeoLocation(
    id: UUID().uuidString, timestamp: stamp.iso8601Stamp, isMoving: isMoving,
    coords: coords, event: CalmGeoLocation.Event.motionchange
  )
}

extension Date {
  var iso8601Stamp: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions.insert(.withFractionalSeconds)
    return formatter.string(from: self)
  }
}
