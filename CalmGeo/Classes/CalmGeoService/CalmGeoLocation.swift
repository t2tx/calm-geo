import CoreLocation

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

@available(iOS 15.0, *)
public struct CalmGeoLocation: Codable, Identifiable {
  enum Event: String, Codable {
    case motionchange
  }

  public var id: String
  public var timestamp: String
  public var isMoving: Bool
  public var coords: CalmGeoCoords

  var event: Event?
}
