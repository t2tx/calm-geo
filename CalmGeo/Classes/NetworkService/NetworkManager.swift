import Combine
import Foundation

public enum Decoders {
  static let Decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    return decoder

  }()
}

final class NetworkManager: NetworkManagerProtocol {
  func buildRequest(
    url: String,
    parameters: [String: Any]? = nil,
    headers: [String: String]? = nil,
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
