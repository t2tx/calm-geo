import CoreLocation
import CoreMotion

@available(iOS 15.0, *)
public struct CalmGeoCoords: Codable {
  init(from location: CLLocation) {
    latitude = location.coordinate.latitude
    longitude = location.coordinate.longitude
    accuracy = location.horizontalAccuracy
    speed = location.speed
    speedAccuracy = location.speedAccuracy
    heading = location.course
    headingAccuracy = location.courseAccuracy
    altitude = location.altitude
    altitudeAccuracy = location.verticalAccuracy
    ellipsoidalAltitude = location.altitude
    mock = location.sourceInformation?.isSimulatedBySoftware
    external = location.sourceInformation?.isProducedByAccessory

    if let floor = location.floor {
      self.floor = Double(floor.level)
    }
  }

  public var latitude: Double
  public var longitude: Double
  public var accuracy: Double
  public var speed: Double
  public var speedAccuracy: Double
  public var heading: Double
  public var headingAccuracy: Double
  public var altitude: Double
  public var altitudeAccuracy: Double
  public var ellipsoidalAltitude: Double
  public var floor: Double?
  public var mock: Bool?
  public var external: Bool?
}

public protocol MotionActivity {
  var automotive: Bool { get }
  var cycling: Bool { get }
  var running: Bool { get }
  var stationary: Bool { get }
  var unknown: Bool { get }
  var walking: Bool { get }
}

public protocol MotionActivityType {
  var activity: MotionActivity { get }
  var confidence: CMMotionActivityConfidence { get }
}

@available(iOS 15.0, *)
public struct CalmGeoActivity: Codable {
  static func from(_ activity: MotionActivityType) -> CalmGeoActivity {
    return CalmGeoActivity(
      type: Activity.from(activity.activity),
      confidence: Int(
        (Double(activity.confidence.rawValue + 1) * 33.3).rounded(.toNearestOrAwayFromZero)))
  }

  static var standard: CalmGeoActivity {
    return CalmGeoActivity(type: .unknown, confidence: 0)
  }

  public enum Activity: String, Codable {
    case still, on_foot, walking, running, in_vehicle, on_bicycle, unknown

    static func from(
      _ activity: MotionActivity
    ) -> Activity {
      if activity.automotive {
        return .in_vehicle
      }
      if activity.cycling {
        return .on_bicycle
      }
      if activity.running {
        return .running
      }
      if activity.stationary {
        return .still
      }
      if activity.unknown {
        return .unknown
      }
      if activity.walking {
        return .walking
      }
      return .unknown
    }
  }

  public var type: Activity
  public var confidence: Int
}

@available(iOS 15.0, *)
public struct CalmGeoLocation: Codable, Identifiable {
  public enum Event: String, Codable {
    case motionchange
  }

  public var id: String
  public var timestamp: String
  public var isMoving: Bool
  public var coords: CalmGeoCoords

  public var activity: CalmGeoActivity?

  public var event: Event?
}
