import CalmGeo
import Foundation

final class GeoAssembly {
  static var config: CalmGeoConfigType {
    let config = CalmGeoConfig.standard
    return config
  }
  // app singleton
  static var geo = GeoService(config: config)

  func build() -> any GeoServiceType {
    return GeoAssembly.geo
  }
}
