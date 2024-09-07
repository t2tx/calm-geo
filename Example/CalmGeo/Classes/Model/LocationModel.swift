import CalmGeo
import SwiftUI

let CONFIG_KEY = "geo"

class LocationModel: ObservableObject {
  private var service: any GeoServiceType

  @Published var currentLocation: CalmGeoLocation?
  @Published var realLocation: CalmGeoLocation?
  @Published var locationCount: Int = 0
  @Published var isRunning: Bool = false
  @Published var locations: [CalmGeoLocation] = []
  @Published var isAttatched: Bool = false

  @Published var config: CalmGeoConfigType =
    UserDefaults.standard.calmGeoConfig(forKey: CONFIG_KEY) ?? CalmGeoConfig.standard

  init(service: any GeoServiceType) {
    self.service = service

    self.service.listenToLocation { [weak self] location in
      DispatchQueue.main.async {
        self?.currentLocation = location
        self?.locationCount = self?.service.locationCount ?? -1

        if self?.isAttatched == true {
          self?.locations = service.locations
        }
      }
    }

    self.service.restart(config: config)

    refresh()
  }

  func stopGpsService() {
    Logger.standard.info("Stop: ViewState")
    service.stop()

    refresh()
  }

  func startGpsService() {
    Logger.standard.info("Start: ViewState")
    service.start()

    refresh()
  }

  var syncState: CalmGeoSyncState? {
    return service.syncState
  }

  func getRealLocation() {
    realLocation = service.currentLocation
  }

  func clearAll() {
    service.clearAll()
    refresh()
  }

  func detatch() {
    isAttatched = false
  }

  func attach() {
    isAttatched = true
    refresh()
  }

  func applyConfig(config: CalmGeoConfigType) {
    self.config = config
    UserDefaults.standard.set(config, forKey: CONFIG_KEY)

    service.restart(config: config)

    refresh()
  }

  func forceSync() {
    service.sync()
  }

  // -------- private --------
  private func refresh() {
    self.isRunning = service.isRunning
    self.locationCount = service.locationCount ?? -1

    if self.isAttatched == true {
      self.locations = service.locations
    }
  }
}
