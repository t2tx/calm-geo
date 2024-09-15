import Combine
import Foundation

public enum RequestMethod: String, Codable, CaseIterable, Identifiable {
  case POST
  case PUT
  public var id: Self { self }
}

public enum NetworkError: Error {
  case httpError(statusCode: Int)
}

protocol NetworkManagerProtocol {
  func upload(
    request: URLRequest,
    from data: Codable,
    completion: @escaping (Result<Void, Error>) -> Void
  )

  func buildRequest(
    url: String,
    headers: [String: String]?,
    method: RequestMethod
  ) -> URLRequest?
}
