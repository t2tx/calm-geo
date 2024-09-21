import XCTest

@testable import CalmGeo

final class NetworkManagerTests: XCTestCase {
  func testbuildRequest() {
    let manager = NetworkManager()

    let badUrl = manager.buildRequest(url: "", headers: nil, method: .POST)
    XCTAssertEqual(badUrl, nil)

    let theDefault = manager.buildRequest(
      url: "https://example.com", headers: nil)
    XCTAssertEqual(theDefault?.httpMethod, "POST")

    let methodPost = manager.buildRequest(
      url: "https://example.com", headers: nil, method: .POST)
    XCTAssertEqual(methodPost?.httpMethod, "POST")

    let methodPut = manager.buildRequest(
      url: "https://example.com", headers: nil, method: .PUT)
    XCTAssertEqual(methodPut?.httpMethod, "PUT")

    let headers = manager.buildRequest(
      url: "https://example.com", headers: ["key": "value", "Content-Type": "application/json"])
    XCTAssertEqual(headers?.value(forHTTPHeaderField: "key"), "value")
    XCTAssertEqual(headers?.value(forHTTPHeaderField: "Content-Type"), "application/json")
  }
}
