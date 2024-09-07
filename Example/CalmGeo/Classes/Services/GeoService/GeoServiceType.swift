import CalmGeo
import Foundation

protocol GeoServiceType: ObservableObject, Identifiable {
  var currentLocation: CalmGeoLocation? { get }
  var locationCount: Int? { get }
  var locations: [CalmGeoLocation] { get }
  var syncState: CalmGeoSyncState? { get }
  var isRunning: Bool { get }

  func clearAll()

  func listenToLocation(_ completion: @escaping CalmGeoLocationListener)
  func stopListen()
  func stop()
  func start()

  func restart(config: CalmGeoConfigType)
  func sync()
}
