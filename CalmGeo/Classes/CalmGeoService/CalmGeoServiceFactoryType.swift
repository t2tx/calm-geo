import CoreLocation

@available(iOS 15.0, *)
protocol CalmGeoServiceFactoryType {
  static func createGeoService(config: CalmGeoConfigType?) -> CalmGeoServiceType
}

@available(iOS 15.0, *)
public typealias CalmGeoLocationListener = (_ location: CalmGeoLocation) -> Void

public enum CalmGeoServiceState {
  case running
  case stopped
}

@available(iOS 15.0, *)
public protocol CalmGeoServiceType {
  func restart(config: CalmGeoConfigType)
  func start()
  func stop()

  func clearAllLocations()

  func getGeoData() -> CalmGeoLocation?
  func getStoredLocations() -> [CalmGeoLocation]
  func getStoredCount() -> Int
  func sync()

  func registerLocationListener(_ listener: @escaping CalmGeoLocationListener)
  func unregisterLocationListener()

  func getSyncState() -> CalmGeoSyncState?

  var state: CalmGeoServiceState { get }
}

public struct CalmGeoSyncState {
  public var timestamp: Date
  public var tried: Int
  public var wait: TimeInterval
}
