import CoreLocation
import Foundation
import os

let TIME_TO_SLEEP = 120.0
let TIME_TO_STILL = 60.0

@available(iOS 15.0, *)
typealias Listener = (_ location: CalmGeoLocation) -> Void

@available(iOS 17.0, *)
class CalmGeoLocationManager: NSObject, CLLocationManagerDelegate {
  private var manager: CLLocationManager = CLLocationManager()
  private var backgroundActivity: CLBackgroundActivitySession?

  private var updateTask: Task<Void, Error>?
  private var updateStamp: Date = Date()

  private var monitor: StillMonitorProviderProtocol?

  private var refLoca: CLLocation?
  private var isMoving: Bool = false
  private var listener: Listener?

  private var config: CalmGeoLocationConfigType

  init(config: CalmGeoLocationConfigType) {
    self.config = config
    super.init()
    self.config(config)

    backgroundActivity = CLBackgroundActivitySession()
  }

  var isRunning: Bool {
    return updateTask != nil || (monitor?.isRunning ?? false)
  }

  func config(_ config: CalmGeoLocationConfigType) {
    self.config = config

    self.manager.delegate = self
    manager.desiredAccuracy = config.desiredAccuracy
    manager.activityType = .otherNavigation
    manager.pausesLocationUpdatesAutomatically = true
    manager.allowsBackgroundLocationUpdates = true
  }

  var currentLocation: CalmGeoLocation? {
    if let location = manager.location {
      let loca = buildMovingLocation(location)
      if let listener {
        listener(loca)
      }
      return loca
    }
    return nil
  }

  func requestWhenInUseAuthorization() {
    manager.requestWhenInUseAuthorization()
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Logger.standard.info("Auth")

    switch manager.authorizationStatus {
    case .notDetermined, .authorizedWhenInUse:
      manager.requestAlwaysAuthorization()
    default:
      break
    }
  }

  func requestAlwaysAuthorization() {
    let state = manager.authorizationStatus
    if state == .authorizedAlways {
      return
    } else if state == .notDetermined || state == .authorizedWhenInUse {
      manager.requestAlwaysAuthorization()
    } else {
      fatalError("Not authenticated")
    }
  }

  func monitorDistance() {
    self.monitor?.stop()
    
    do {
      try monitor!.start(base: CalmGeoCoords(from: self.refLoca ?? CLLocation())) {
        if let location = self.manager.location, let listener = self.listener {
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
  

  @available(iOS 17.0, *)
  func startLiveUpdates(_ listener: @escaping (_ location: CalmGeoLocation) -> Void)
    -> AsyncFilterSequence<CLLocationUpdate.Updates>
  {
    return CLLocationUpdate.liveUpdates(.otherNavigation).filter {
      [weak self] update in
      guard let self = self else { return false }
      guard let refLoca = self.refLoca else {
        self.refLoca = update.location
        return true
      }

      if self.monitor?.isRunning ?? false {
        return true
      }

      if let loca = update.location {
        let distance = loca.distance(from: refLoca)

        let config = self.config
        let judge =
          config.disableSpeedMultiplier
          ? Double(config.distanceFilter)
          : max(
            (round(loca.speed / 5.0)) * config.speedMultiplier
              * Double(config.distanceFilter), Double(config.distanceFilter))

        Logger.standard.info("Distance: \(judge) \(distance) \(loca.timestamp.ISO8601Format())")

        if distance > judge {
          self.refLoca = update.location
          return true
        }

        if let diff = self.refLoca?.timestamp.timeIntervalSinceNow {
          if abs(diff) > TIME_TO_STILL && isMoving {
            self.refLoca = loca
            if distance < Double(config.distanceFilter) {
              Logger.standard.info("motionchange: Still")
              listener(
                buildMotionChangeLocation(loca, isMoving: false))
              isMoving = false
            }
          }

          let diffPast = abs(self.updateStamp.timeIntervalSinceNow)
          if abs(diff) > TIME_TO_SLEEP && diffPast > TIME_TO_SLEEP {
            if isMoving {
              Logger.standard.info("motionchange: Still")
              listener(
                buildMotionChangeLocation(loca, isMoving: false))
              isMoving = false
            }

            Logger.standard.info("Should Stop Listen")
            self.switchToMonitor()
          }
        }
      }

      return false
    }
  }

  func listenToLocation(_ listener: @escaping (_ location: CalmGeoLocation) -> Void) {
    Logger.standard.info("listenToLocation in")

    self.updateTask?.cancel()
    self.listener = listener
    self.updateTask = Task {
      do {
        if self.monitor == nil {
          let inner = await CLMonitor(UUID().uuidString.split(separator: "-").joined())
          monitor = StillMonitorProvider(config:config, monitor: inner)
        }

        self.updateStamp = Date()
        let updates = startLiveUpdates(listener)

        Logger.standard.info("updated")

        for try await update in updates {
          if self.monitor?.isRunning ?? false {
            break
          }

          if let stamp = update.location?.timestamp {
            Logger.standard.info("Current Location is \(stamp.ISO8601Format())")
          }
          Logger.standard.info("\(update.isStationary)")

          // Call the listener
          if let location = update.location {
            if self.isMoving {
              listener(buildMovingLocation(location))
            } else {
              Logger.standard.info("motionchange: Moving")
              isMoving = true
              listener(
                buildMotionChangeLocation(location, isMoving: true)
              )
            }
          }
        }
      } catch {
        Logger.standard.info("Some error")
        debugPrint("Some Error Occured")
      }
    }
  }

  func stopWatch() {
    Logger.standard.info("Stop Watch \(Date().ISO8601Format())")
    self.monitor?.stop()
    self.monitor = nil
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

    if let _ = self.updateTask {
      Logger.standard.info("Clear Update")
      self.updateTask = nil
    }
  }

  func switchToMonitor() {
    stopListen()
    monitorDistance()
  }

  func stop() {
    Logger.standard.info("Stop \(Date().ISO8601Format())")

    self.manager.stopUpdatingLocation()

    self.updateTask?.cancel()
    self.updateTask = nil

    stopWatch()
  }
}

@available(iOS 15.0, *)
func buildMovingLocation(_ location: CLLocation) -> CalmGeoLocation {
  let stamp = (location.timestamp as Date?) ?? Date.now

  return CalmGeoLocation(
    id: UUID().uuidString, timestamp: stamp.iso8601Stamp, isMoving: true,
    coords: CalmGeoCoords(from: location))
}

@available(iOS 15.0, *)
func buildMotionChangeLocation(_ location: CLLocation, isMoving: Bool) -> CalmGeoLocation {
  let stamp = (location.timestamp as Date?) ?? Date.now

  return CalmGeoLocation(
    id: UUID().uuidString, timestamp: stamp.iso8601Stamp, isMoving: isMoving,
    coords: CalmGeoCoords(from: location), event: CalmGeoLocation.Event.motionchange
  )
}

extension Date {
  var iso8601Stamp: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions.insert(.withFractionalSeconds)
    return formatter.string(from: self)
  }
}
