import CoreLocation
import Foundation
import os

@available(iOS 17.0, *)
class LocationProvider: NSObject, LocationProviderProtocol, CLLocationManagerDelegate {
  private var manager: CLLocationManager
  private var updateTask: Task<Void, Error>?
  private var updateStamp: Date = Date()

  private var refLoca: CLLocation?
  private var listener: LocationListener?

  private var config: CalmGeoLocationConfigType

  init(config: CalmGeoLocationConfigType) {
    print("Main thread: \(Thread.isMainThread ? "YES" : "NO")")

    self.manager = CLLocationManager()
    self.config = config
    super.init()
    self.config(config)
  }

  var isRunning: Bool {
    return updateTask != nil
  }

  func config(_ config: CalmGeoLocationConfigType) {
    self.config = config

    self.manager.delegate = self
    manager.desiredAccuracy = config.desiredAccuracy
    manager.activityType = .otherNavigation
    manager.pausesLocationUpdatesAutomatically = true
    manager.allowsBackgroundLocationUpdates = true
  }

  var currentLocation: CalmGeoCoords? {
    if let location = manager.location {
      if let listener {
        listener(CalmGeoCoords(from: location))
      }
      return CalmGeoCoords(from: location)
    } else {
      manager.requestLocation()
    }

    return nil
  }

  func requestAuthorization() {
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

  func locationManager(
    _ manager: CLLocationManager,
    didUpdateLocations locations: [CLLocation]
  ) {
    Logger.standard.info("didUpdateLocations")
    if let location = locations.last {
      refLoca = location
      if let listener {
        listener(CalmGeoCoords(from: location))
      }
    }
  }

  func locationManager(
    _ manager: CLLocationManager,
    didFailWithError error: any Error
  ) {
    Logger.standard.info("didFailWithError \(error.localizedDescription)")
  }

  @available(iOS 17.0, *)
  func startLiveUpdates(_ listener: @escaping LocationListener, filter: LocationFilter?)
    -> AsyncFilterSequence<CLLocationUpdate.Updates>
  {
    return CLLocationUpdate.liveUpdates(.otherNavigation).filter {
      [weak self] update in
      guard let self = self else { return false }
      if self.refLoca == nil {
        self.refLoca = update.location
        return true
      }

      if let filter {
        if let location = update.location {
          return filter(CalmGeoCoords(from: location))
        } else {
          return filter(nil)
        }
      }

      return true
    }
  }

  func listenToLocation(_ listener: @escaping LocationListener, filter: LocationFilter?) {
    Logger.standard.info("listenToLocation in")
    manager.requestLocation()

    self.updateTask?.cancel()
    self.listener = listener
    self.updateTask = Task {
      do {
        self.updateStamp = Date()
        let updates = startLiveUpdates(listener, filter: filter)

        Logger.standard.info("updated")

        for try await update in updates {
          if let stamp = update.location?.timestamp {
            Logger.standard.info("Current Location is \(stamp.ISO8601Format())")
          }
          Logger.standard.info("\(update.isStationary)")

          // Call the listener
          if let location = update.location {
            listener(CalmGeoCoords(from: location))
          }
        }
      } catch {
        Logger.standard.info("Some error")
        debugPrint("Some Error Occured")
      }
    }
  }

  func stop() {
    Logger.standard.info("Stop \(Date().ISO8601Format())")

    self.manager.stopUpdatingLocation()

    self.updateTask?.cancel()
    self.updateTask = nil
  }
}
