import CalmGeo

public class GeoService: GeoServiceType {
  init(config: CalmGeoConfigType?) {
    self._geoService = createCalmGeo(config: config)
  }

  public var currentLocation: CalmGeoLocation? {
    return _geoService?.getGeoData()
  }

  public var locationCount: Int? {
    return _geoService?.getStoredCount()
  }

  public var locations: [CalmGeoLocation] {
    return _geoService?.getStoredLocations() ?? []
  }

  public var syncState: CalmGeoSyncState? {
    return _geoService?.getSyncState()
  }

  public var isRunning: Bool {
    return _geoService?.state == .running
  }

  public func clearAll() {
    _geoService?.clearAllLocations()
  }

  public func listenToLocation(_ listener: @escaping CalmGeoLocationListener) {
    _geoService?.registerLocationListener { location in
      listener(location)
    }
  }
  public func stopListen() {
    _geoService?.unregisterLocationListener()
  }

  public func stop() {
    Logger.standard.info("Stop: GeoService")
    _geoService?.stop()
  }

  public func start() {
    Logger.standard.info("Start: GeoService")
    _geoService?.start()
  }

  public func restart(config: CalmGeoConfigType) {
    _geoService?.restart(config: config)
  }

  public func sync() {
    _geoService?.sync()
  }

  private var _geoService: CalmGeoServiceType?
}
