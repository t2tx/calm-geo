import CoreLocation
import MMKV

struct LatestFail {
  var timestamp: Date
  var tried: Int
  var wait: TimeInterval {
    // 連続失敗時、最大 10 分間待機
    max(-600.0, -(Double(pow(2.0, Float(tried))) - 1))
  }
}

@available(iOS 15.0, *)
class MMKVManager {
  private var _mmkv: MMKV?

  private var _latestFail: LatestFail
  private var _config: CalmGeoSyncConfigType

  init(id: String, config: CalmGeoSyncConfigType) {
    _latestFail = LatestFail(timestamp: Date.now, tried: 0)

    MMKV.initialize(rootDir: nil, logLevel: .warning)
    self._mmkv = MMKV.init(mmapID: id, mode: .singleProcess)
    self._mmkv?.enableAutoKeyExpire(expiredInSeconds: MMKVExpireDuration.never.rawValue)

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
    if let mmkv = self._mmkv {
      let encoder = JSONEncoder()
      do {
        let data = try encoder.encode(location)
        mmkv.set(
          data, forKey: location.id,
          expireDuration: _config.maxDaysToPersist * 24 * 60 * 60)

        if needSync(location: location) {
          sync()
        }

      } catch {
        Logger.standard.error("\(error.localizedDescription)")
      }
    }
  }

  func needSync(location: CalmGeoLocation) -> Bool {
    if !_config.autoSync {
      return false
    }

    guard let _ = _config.url else {
      return false
    }

    guard let mmkv = _mmkv else {
      return false
    }

    let interval = _latestFail.timestamp.timeIntervalSinceNow
    let wait = _latestFail.wait

    Logger.standard.info("WAIT: \(interval) \(wait) \(self._latestFail.tried)")

    if interval > wait {
      return false
    }

    return mmkv.count() >= max(1, _config.syncThreshold) || location.event != nil
  }

  func remove(key: String) {
    _mmkv?.removeValue(forKey: key)
  }

  func count() -> Int {
    return _mmkv?.allKeys().count ?? 0
  }

  func getAllData() -> [CalmGeoLocation] {
    guard let mmkv = _mmkv else {
      return []
    }

    var result: [CalmGeoLocation] = []
    for key in mmkv.allKeys() {
      let data = mmkv.data(forKey: key as! String)
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
    _mmkv?.clearAll()
  }

  func hanldUploadError() {
    _latestFail.timestamp = Date.now
    _latestFail.tried += 1
  }

  func syncTrunk(chunk: [CalmGeoLocation], request: URLRequest) {
    // upload
    do {
      let data = try JSONEncoder().encode(chunk)
      let task = URLSession.shared.uploadTask(with: request, from: data) {
        [weak self] data, response, error in
        if let error = error {
          Logger.standard.error("\(error.localizedDescription)")
          self?.hanldUploadError()
        } else {
          if let res = response as? HTTPURLResponse {
            if res.statusCode == 200 {
              // remove local
              self?._mmkv?.removeValues(
                forKeys: chunk.map({ location in
                  location.id
                }))
              self?._latestFail.tried = 0
              Logger.standard.info("Remove Chunk \(chunk.count)")
              return
            }
            Logger.standard.error("RESPONSE: \(res.statusCode)")
          }
          self?.hanldUploadError()
        }
      }
      task.resume()
    } catch {
      Logger.standard.info("Sync Error: \(error)")
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
      let request = NetworkManager().buildRequest(
        url: url, headers: headers, method: _config.method)
    else {
      return
    }

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
