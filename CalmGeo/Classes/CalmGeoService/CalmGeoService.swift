import CoreLocation
import MMKV

@available(iOS 17.0, *)
class CalmGeoService: CalmGeoServiceType {
  private var _mmkv: MMKVManager?
  private var _locationManager: CalmGeoLocationManager?
  private var _locationListener: CalmGeoLocationListener?

  init(config: CalmGeoConfigType) {
    restart(config: config)
  }

  func restart(config: CalmGeoConfigType) {
    if let mmkv = _mmkv {
      mmkv.config = config
    } else {
      self._mmkv = MMKVManager(id: "calmgeo", config: config)
    }

    if let manager = _locationManager {
      manager.config(config)
    } else {
      self._locationManager = CalmGeoLocationManager(config: config)
    }

    start()
  }

  func getGeoData() -> CalmGeoLocation? {
    return _locationManager?.currentLocation
  }

  func getStoredLocations() -> [CalmGeoLocation] {
    guard let mmkv = _mmkv else {
      return []
    }
    return mmkv.getAllData()
  }

  func clearAllLocations() {
    _mmkv?.clearAll()
  }

  func getStoredCount() -> Int {
    return _mmkv?.count() ?? 0
  }

  func sync() {
    _mmkv?.sync()
  }

  func registerLocationListener(_ listener: @escaping CalmGeoLocationListener) {
    self._locationListener = listener
  }

  func unregisterLocationListener() {
    self._locationListener = nil
  }

  func start() {
    if let manager = self._locationManager {

      manager.requestWhenInUseAuthorization()

      manager.listenToLocation { [weak self] location in
        if let mmkv = self?._mmkv {
          mmkv.append(location: location)

          if let listener = self?._locationListener {
            listener(location)
          }
        }
      }
    }
  }

  func stop() {
    Logger.standard.info("Stop: CalmGeoService")
    self._locationManager?.stop()
  }

  func getSyncState() -> CalmGeoSyncState? {
    guard let inner = _mmkv?.syncState else {
      return nil
    }

    return CalmGeoSyncState(timestamp: inner.timestamp, tried: inner.tried, wait: inner.wait)
  }

  var state: CalmGeoServiceState {
    return (self._locationManager?.isRunning ?? false) ? .running : .stopped
  }
}
