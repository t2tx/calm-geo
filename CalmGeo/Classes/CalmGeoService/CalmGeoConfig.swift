import CoreLocation

public enum CalmGeoDesiredAccuracy: Double, Codable {
  case bestForNavigation
  case best
  case tenMeters
  case hundredMeters
  case kilometer
  case threeKilometer

  public var rawValue: Double {
    switch self {
    case .bestForNavigation:
      return kCLLocationAccuracyBestForNavigation
    case .best:
      return kCLLocationAccuracyBest
    case .tenMeters:
      return kCLLocationAccuracyNearestTenMeters
    case .hundredMeters:
      return kCLLocationAccuracyHundredMeters
    case .kilometer:
      return kCLLocationAccuracyKilometer
    case .threeKilometer:
      return kCLLocationAccuracyThreeKilometers
    }
  }
}

public protocol CalmGeoLocationConfigType: Codable {
  var desiredAccuracy: Double { get set }
  var distanceFilter: Int { get set }
  var disableSpeedMultiplier: Bool { get set }
  var speedMultiplier: Double { get set }
  var stationaryRadius: Double { get set }
  var fetchActivity: Bool { get set }
}

public protocol CalmGeoSyncConfigType: Codable {
  var url: String? { get set }
  var token: String? { get set }

  var httpTimeout: Int { get set }
  var method: RequestMethod { get set }

  var autoSync: Bool { get set }
  var syncThreshold: Int { get set }
  var maxBatchSize: Int { get set }
  var maxDaysToPersist: UInt32 { get set }
}

public protocol CalmGeoConfigType: CalmGeoLocationConfigType, CalmGeoSyncConfigType, Codable {}

public struct CalmGeoConfig: CalmGeoConfigType {
  public static var standard: CalmGeoConfigType = {
    return CalmGeoConfig(
      desiredAccuracy: CalmGeoDesiredAccuracy.best.rawValue,
      distanceFilter: 16,
      disableSpeedMultiplier: false,
      speedMultiplier: 3.1,
      stationaryRadius: 25.0,

      httpTimeout: 10000,
      method: .POST,

      autoSync: false,
      syncThreshold: 12,
      maxBatchSize: 250,
      maxDaysToPersist: 7,
      fetchActivity: false
    )
  }()

  public var desiredAccuracy: Double
  public var distanceFilter: Int
  public var disableSpeedMultiplier: Bool
  public var speedMultiplier: Double
  public var stationaryRadius: Double

  public var url: String?
  public var token: String?
  public var httpTimeout: Int
  public var method: RequestMethod

  public var autoSync: Bool
  public var syncThreshold: Int
  public var maxBatchSize: Int
  public var maxDaysToPersist: UInt32

  public var fetchActivity: Bool
}
