import Combine
import Foundation

public enum Decoders {
  static let Decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder

  }()
}

final class NetworkManager: NetworkManagerProtocol {
  func upload(
    request: URLRequest,
    from data: Codable,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    let encoder: JSONEncoder = JSONEncoder()
    do {
      let jsonData = try encoder.encode(data)
      let task = URLSession.shared.uploadTask(with: request, from: jsonData) {
        _, response, error in
        if let error = error {
          completion(.failure(error))
        } else {
          if let res = response as? HTTPURLResponse {
            if res.statusCode == 200 {
              // remove local
              completion(.success(()))
              return
            }
            Logger.standard.error("RESPONSE: \(res.statusCode)")
            completion(.failure(NetworkError.httpError(statusCode: res.statusCode)))
          }
        }
      }
      task.resume()
    } catch {
      completion(.failure(error))
    }
  }

  func buildRequest(
    url: String,
    headers: [String: String]?,
    method: RequestMethod = .POST
  ) -> URLRequest? {

    guard let url = URL(string: url) else { return nil }
    var request = URLRequest(url: url)

    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let requestHeaders = headers {
      for (field, value) in requestHeaders {
        request.setValue(value, forHTTPHeaderField: field)
      }
    }
    return request
  }
}
