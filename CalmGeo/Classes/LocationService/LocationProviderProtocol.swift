@available(iOS 17.0, *)
public typealias LocationListener = (_ location: CalmGeoCoords?) -> Void

@available(iOS 17.0, *)
public typealias LocationFilter = (_ location: CalmGeoCoords?) -> Bool

@available(iOS 17.0, *)
protocol LocationProviderProtocol {
  var isRunning: Bool { get }
  var currentLocation: CalmGeoCoords? { get }

  func requestAuthorization()

  func config(_ config: CalmGeoLocationConfigType)
  func listenToLocation(_ listener: @escaping LocationListener, filter: LocationFilter?)
  func stop()
}
