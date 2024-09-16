import CoreLocation

struct LatestFail {
  var timestamp: Date
  var tried: Int
  var wait: TimeInterval {
    // 連続失敗時、最大 10 分間待機
    max(-600.0, -(Double(pow(2.0, Float(tried))) - 1))
  }
}

@available(iOS 15.0, *)
class StoreManager {
  private var _storage: StorageProviderProtocol
  private var _network: NetworkManagerProtocol

  private var _latestFail: LatestFail
  private var _config: CalmGeoSyncConfigType

  init(
    config: CalmGeoSyncConfigType, network: NetworkManagerProtocol, storage: StorageProviderProtocol
  ) {
    self._network = network
    self._storage = storage

    _latestFail = LatestFail(timestamp: Date.now, tried: 0)

    self._config = config
  }

  var config: CalmGeoSyncConfigType {
    get { _config }
    set { _config = newValue }
  }

  var syncState: LatestFail {
    return _latestFail
  }

  func append(location: CalmGeoLocation) {
    do {
      try _storage.append(location: location)

      if needSync(location: location) {
        sync()
      }
    } catch {
      Logger.standard.error("\(error.localizedDescription)")
    }
  }

  func needSync(location: CalmGeoLocation) -> Bool {
    if !_config.autoSync {
      return false
    }

    guard let _ = _config.url else {
      return false
    }

    if location.event != nil {
      // event 発生時は即時送信
      return true
    }

    let interval = _latestFail.timestamp.timeIntervalSinceNow
    let wait = _latestFail.wait

    Logger.standard.info("WAIT: \(interval) \(wait) \(self._latestFail.tried)")

    if interval > wait {
      return false
    }

    return _storage.count() >= max(1, _config.syncThreshold)
  }

  func remove(key: String) {
    _storage.remove(key: key)
  }

  func count() -> Int {
    return _storage.count()
  }

  func getAllData() -> [CalmGeoLocation] {
    let raw = _storage.getAllData()
    return raw.sorted(by: { $0.timestamp < $1.timestamp })
  }

  func clearAll() {
    _storage.clearAll()
  }

  func handleUploadError() {
    _latestFail.timestamp = Date.now
    _latestFail.tried += 1
  }

  func syncTrunk(chunk: [CalmGeoLocation], request: URLRequest) {
    // upload
    let _ = _network.upload(request: request, from: chunk) {
      [weak self] result in
      switch result {
      case .success():
        // remove local
        self?._storage.removeValues(
          keys: chunk.map({ location in
            location.id
          }))
        self?._latestFail.tried = 0
      case .failure(let error):
        Logger.standard.error("\(error.localizedDescription)")
        self?.handleUploadError()
      }
    }
  }

  func sync() {
    guard let url = _config.url else {
      return
    }

    let headers = [
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Bearer \(_config.token ?? "")",
    ]

    guard
      var request = _network.buildRequest(
        url: url, headers: headers, method: _config.method)
    else {
      return
    }
    request.timeoutInterval = Double(_config.httpTimeout) / 1000.0

    Logger.standard.info("Sync From MMKV \(self._config.syncThreshold)")
    // get all data
    let rows = getAllData().sorted { lhs, rhs in
      lhs.timestamp < rhs.timestamp
    }

    // chunk
    let chunks = rows.chunked(into: max(1, _config.maxBatchSize))
    for chunk in chunks {
      Logger.standard.info("Upload Chunk \(chunk.count)")
      syncTrunk(chunk: chunk, request: request)
    }
  }
}
