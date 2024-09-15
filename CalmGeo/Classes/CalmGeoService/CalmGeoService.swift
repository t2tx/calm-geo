import CoreLocation
import MMKV

@available(iOS 17.0, *)
class CalmGeoService: CalmGeoServiceType {
  private var _mmkv: MMKVManager?
  private var _locationManager: CalmGeoLocationManager?
  private var _locationListener: CalmGeoLocationListener?
  private var _motionManager: MotionManager?
  private var _config: CalmGeoConfigType?

  init(config: CalmGeoConfigType) {
    restart(config: config)
  }

  func restart(config: CalmGeoConfigType) {
    _config = config
    if let mmkv = _mmkv {
      mmkv.config = config
    } else {
      self._mmkv = MMKVManager(id: "calmgeo", config: config, network: NetworkManager())
    }

    if let manager = _locationManager {
      manager.config(config)
    } else {
      self._locationManager = CalmGeoLocationManager(config: config)
    }

    if config.fetchActivity {
      if _motionManager == nil {
        self._motionManager = MotionManager()
      }
    } else {
      self._motionManager?.stop()
      self._motionManager = nil
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
    if _config?.fetchActivity == true {
      self._motionManager?.start(nil)
    } else {
      self._motionManager?.stop()
    }

    if let manager = self._locationManager {

      manager.requestWhenInUseAuthorization()

      manager.listenToLocation { [weak self] location in
        if let mmkv = self?._mmkv {
          var work = location
          if self?._config?.fetchActivity == true {
            work.activity = self?._motionManager?.currentActivity ?? CalmGeoActivity.standard
          }
          mmkv.append(location: work)

          if let listener = self?._locationListener {
            listener(work)
          }
        }
      }
    }
  }

  func stop() {
    Logger.standard.info("Stop: CalmGeoService")
    self._locationManager?.stop()
    self._motionManager?.stop()
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
