@available(iOS 15.0, *)
protocol StorageProviderProtocol {
  func append(location: CalmGeoLocation) throws
  func remove(key: String)
  func removeValues(keys: [String])
  func count() -> Int
  func getAllData() -> [CalmGeoLocation]
  func clearAll()
}
