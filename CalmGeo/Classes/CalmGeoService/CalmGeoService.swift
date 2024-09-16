import CoreLocation
import MMKV

@available(iOS 17.0, *)
class CalmGeoService: CalmGeoServiceType {
  private var _storage: StoreManager?
  private var _locationManager: CalmGeoLocationManager?
  private var _locationListener: CalmGeoLocationListener?
  private var _motionManager: MotionManager?
  private var _config: CalmGeoConfigType?

  init(config: CalmGeoConfigType) {
    restart(config: config)
  }

  func restart(config: CalmGeoConfigType) {
    _config = config
    if let _storage {
      _storage.config = config
    } else {
      MMKV.initialize(rootDir: nil, logLevel: .warning)
      var mmkv = MMKV.init(mmapID: "calmgeo", mode: .singleProcess)
      
      if let mmkv {
        mmkv.enableAutoKeyExpire(expiredInSeconds: MMKVExpireDuration.never.rawValue)
        _storage = StoreManager(config: config,  network: NetworkManager(), storage: MMKVStorageProvider(of: mmkv, config: config))
      }
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
    guard let _storage else {
      return []
    }
    return _storage.getAllData()
  }

  func clearAllLocations() {
    _storage?.clearAll()
  }

  func getStoredCount() -> Int {
    return _storage?.count() ?? 0
  }

  func sync() {
    _storage?.sync()
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
        if let storage = self?._storage {
          var work = location
          if self?._config?.fetchActivity == true {
            work.activity = self?._motionManager?.currentActivity ?? CalmGeoActivity.standard
          }
          storage.append(location: work)

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
    guard let inner = _storage?.syncState else {
      return nil
    }

    return CalmGeoSyncState(timestamp: inner.timestamp, tried: inner.tried, wait: inner.wait)
  }

  var state: CalmGeoServiceState {
    return (self._locationManager?.isRunning ?? false) ? .running : .stopped
  }
}
