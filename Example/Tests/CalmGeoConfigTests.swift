import XCTest

@testable import CalmGeo

final class CalmGeoConfigTests: XCTestCase {
  func testStandardConfig() {
    let config = CalmGeoConfig.standard
    XCTAssertEqual(config.desiredAccuracy, CalmGeoDesiredAccuracy.best.rawValue)
    XCTAssertEqual(config.distanceFilter, 16)
    XCTAssertEqual(config.disableSpeedMultiplier, false)
    XCTAssertEqual(config.speedMultiplier, 3.1)
    XCTAssertEqual(config.stationaryRadius, 25.0)
    XCTAssertEqual(config.httpTimeout, 10000)
    XCTAssertEqual(config.method, .POST)
    XCTAssertEqual(config.autoSync, false)
    XCTAssertEqual(config.syncThreshold, 12)
    XCTAssertEqual(config.maxBatchSize, 250)
    XCTAssertEqual(config.maxDaysToPersist, 7)
    XCTAssertEqual(config.fetchActivity, false)

    XCTAssertEqual(config.url, nil)
    XCTAssertEqual(config.token, nil)
  }
}
