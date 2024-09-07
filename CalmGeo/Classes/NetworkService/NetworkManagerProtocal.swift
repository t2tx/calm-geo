import Combine
import Foundation

public enum RequestMethod: String, Codable, CaseIterable, Identifiable {
  case GET
  case POST
  case DELETE
  case PUT
  public var id: Self { self }
}

protocol NetworkManagerProtocol {
  func buildRequest(
    url: String,
    parameters: [String: Any]?,
    headers: [String: String]?,
    method: RequestMethod
  ) -> URLRequest?
}
