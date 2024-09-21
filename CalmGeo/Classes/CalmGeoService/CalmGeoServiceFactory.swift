@available(iOS 17.0, *)
@MainActor
class CalmGeoServiceFactory: CalmGeoServiceFactoryType {
  nonisolated static func createGeoService(config: CalmGeoConfigType?) -> CalmGeoServiceType {
    return CalmGeoService(config: config ?? CalmGeoConfig.standard)
  }
}
