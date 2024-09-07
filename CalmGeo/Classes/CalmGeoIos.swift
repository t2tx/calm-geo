import Foundation

@available(iOS 15.0, *)
public func startCalmGeo(config: CalmGeoConfigType?) -> CalmGeoServiceType? {
  if #available(iOS 17.0, *) {
    let service = CalmGeoServiceFactory.createGeoService(config: config)
    service.start()
    return service
  }
  return nil
}

@available(iOS 15.0, *)
public func createCalmGeo(config: CalmGeoConfigType?) -> CalmGeoServiceType? {
  if #available(iOS 17.0, *) {
    let service = CalmGeoServiceFactory.createGeoService(config: config)
    return service
  }
  return nil
}
