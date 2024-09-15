public protocol StorageProviderProtocol {
  func set<T: Codable>(_ value: T, forKey key: String)
  func get<T: Codable>(_ type: T.Type, forKey key: String) -> T?
  func removeValue(forKey key: String)
  func allKeys() -> [String]
}
