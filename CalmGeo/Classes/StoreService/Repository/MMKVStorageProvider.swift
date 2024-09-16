import MMKV

@available(iOS 15.0, *)
class MMKVStorageProvider: StorageProviderProtocol {
  private var _mmkv: MMKV
  private var _config: CalmGeoSyncConfigType

  init(of mmkv: MMKV, config: CalmGeoSyncConfigType) {
    self._mmkv = mmkv
    self._config = config
  }

  func append(location: CalmGeoLocation) throws {
    let encoder = JSONEncoder()
    let data = try encoder.encode(location)
    _mmkv.set(
      data, forKey: location.id,
      expireDuration: _config.maxDaysToPersist * 24 * 60 * 60)
  }

  func remove(key: String) {
    _mmkv.removeValue(forKey: key)
  }

  func removeValues(keys: [String]) {
    _mmkv.removeValues(forKeys: keys)
  }

  func count() -> Int {
    return _mmkv.allKeys().count
  }

  func getAllData() -> [CalmGeoLocation] {
    var result: [CalmGeoLocation] = []
    for key in _mmkv.allKeys() {
      let data = _mmkv.data(forKey: key as! String)
      let decoder = JSONDecoder()
      do {
        let location = try decoder.decode(CalmGeoLocation.self, from: data!)
        result.append(location)
      } catch {
        Logger.standard.error("\(error.localizedDescription)")
      }
    }
    return result.sorted(by: { $0.timestamp < $1.timestamp })
  }

  func clearAll() {
    _mmkv.clearAll()
  }
}
