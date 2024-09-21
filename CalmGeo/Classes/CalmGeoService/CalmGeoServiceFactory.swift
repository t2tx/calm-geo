@available(iOS 17.0, *)
class CalmGeoServiceFactory: CalmGeoServiceFactoryType {
  static func createGeoService(config: CalmGeoConfigType?) -> CalmGeoServiceType {
    return CalmGeoService(config: config ?? CalmGeoConfig.standard)
  }
}
