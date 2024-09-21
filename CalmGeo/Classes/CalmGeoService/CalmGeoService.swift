import CoreLocation
import MMKV

@available(iOS 17.0, *)
class CalmGeoService: CalmGeoServiceType {
  private let _lock = NSRecursiveLock()

  private var _storage: StoreManager?
  private var _backgroundSession: BackgroundSessionProtocol?
  private var _motionManager: MotionManager?

  private var _locationManager: CalmGeoLocationManager?
  private var _locationListener: CalmGeoLocationListener?

  private var _config: CalmGeoConfigType?

  init(config: CalmGeoConfigType) {
    _backgroundSession = BackgroundSession()
    restart(config: config)
  }

  func restart(config: CalmGeoConfigType) {
    self._config = config
    if let _storage = self._storage {
      _storage.config = config
    } else {
      MMKV.initialize(rootDir: nil, logLevel: .warning)
      let mmkv = MMKV.init(mmapID: "calmgeo", mode: .singleProcess)

      if let mmkv {
        mmkv.enableAutoKeyExpire(expiredInSeconds: MMKVExpireDuration.never.rawValue)
        self._storage = StoreManager(
          config: config, network: NetworkManager(),
          storage: MMKVStorageProvider(of: mmkv, config: config))
      }
    }

    if config.fetchActivity {
      if self._motionManager == nil {
        self._motionManager = MotionManager(provider: MotionProvider())
      }
    } else {
      self._motionManager?.stop()
      self._motionManager = nil
    }

    _lock.lock()
    if let manager = self._locationManager {
      defer {
        _lock.unlock()
      }
      manager.config(config)
      start()
    } else {
      Task {
        let monitor = await StillMonitorProvider()
        await MainActor.run {
          defer {
            _lock.unlock()
          }
          self._locationManager = CalmGeoLocationManager(
            config: config,
            monitor: monitor,
            location: LocationProvider(config: config))
        }
        self.start()
      }
    }
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
