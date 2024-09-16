import CoreMotion
import XCTest

@testable import CalmGeo

struct MockMotionActivity: MotionActivity {
  var automotive: Bool = false
  var cycling: Bool = false
  var running: Bool = false
  var stationary: Bool = false
  var unknown: Bool = false
  var walking: Bool = false
}

struct MockMotionActivityType: MotionActivityType {
  var automotive: Bool = false
  var cycling: Bool = false
  var running: Bool = false
  var stationary: Bool = false
  var unknown: Bool = false
  var walking: Bool = false

  var confidence: CMMotionActivityConfidence
}

final class CalmGeoLocationTests: XCTestCase {
  func testActivity() {
    var motion = MockMotionActivity(
      automotive: true, cycling: false, running: false, stationary: false, unknown: false,
      walking: false)

    motion.automotive = true
    XCTAssertEqual(CalmGeoActivity.Activity.from(motion), .in_vehicle)

    motion.automotive = false
    motion.cycling = true
    XCTAssertEqual(CalmGeoActivity.Activity.from(motion), .on_bicycle)

    motion.cycling = false
    motion.running = true
    XCTAssertEqual(CalmGeoActivity.Activity.from(motion), .running)

    motion.running = false
    motion.stationary = true
    XCTAssertEqual(CalmGeoActivity.Activity.from(motion), .still)

    motion.stationary = false
    motion.unknown = true
    XCTAssertEqual(CalmGeoActivity.Activity.from(motion), .unknown)

    motion.unknown = false
    motion.walking = true
    XCTAssertEqual(CalmGeoActivity.Activity.from(motion), .walking)

    motion.walking = false
    XCTAssertEqual(CalmGeoActivity.Activity.from(motion), .unknown)
  }

  func testActivityType() {
    var motion = MockMotionActivityType(

      automotive: true, cycling: false, running: false, stationary: false, unknown: false,
      walking: false,
      confidence: .low)

    XCTAssertEqual(CalmGeoActivity.from(motion).type, .in_vehicle)

    XCTAssertEqual(CalmGeoActivity.from(motion).confidence, 33)

    motion.confidence = .medium
    XCTAssertEqual(CalmGeoActivity.from(motion).confidence, 67)

    motion.confidence = .high
    XCTAssertEqual(CalmGeoActivity.from(motion).confidence, 100)
  }
}
