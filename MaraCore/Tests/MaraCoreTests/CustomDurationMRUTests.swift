import XCTest
@testable import MaraCore

final class CustomDurationMRUTests: XCTestCase {
    func testInsertsNewValueAtFront() {
        XCTAssertEqual(CustomDurationMRU.inserting(60, into: [300, 120]), [60, 300, 120])
    }

    func testDuplicateMovesToFront() {
        XCTAssertEqual(CustomDurationMRU.inserting(300, into: [120, 300, 60]), [300, 120, 60])
    }

    func testCapsAtDefaultThree() {
        XCTAssertEqual(CustomDurationMRU.inserting(60, into: [300, 120, 90]), [60, 300, 120])
    }

    func testCustomCap() {
        XCTAssertEqual(CustomDurationMRU.inserting(60, into: [300, 120], cap: 2), [60, 300])
    }

    func testIgnoresNonPositive() {
        XCTAssertEqual(CustomDurationMRU.inserting(0, into: [300]), [300])
        XCTAssertEqual(CustomDurationMRU.inserting(-5, into: [300]), [300])
    }

    func testIgnoresNonFinite() {
        // Swift의 min/max처럼 NaN을 흘리지 않도록: isFinite 가드가 NaN/∞를 거른다.
        XCTAssertEqual(CustomDurationMRU.inserting(.nan, into: [300]), [300])
        XCTAssertEqual(CustomDurationMRU.inserting(.infinity, into: [300]), [300])
    }

    func testInsertIntoEmpty() {
        XCTAssertEqual(CustomDurationMRU.inserting(60, into: []), [60])
    }

    func testSanitizingFiltersInvalidAndCaps() {
        XCTAssertEqual(CustomDurationMRU.sanitizing([60, -1, .nan, 120, 0, 300, 90]), [60, 120, 300])
    }

    func testSanitizingPreservesOrder() {
        XCTAssertEqual(CustomDurationMRU.sanitizing([300, 60, 120]), [300, 60, 120])
    }

    func testSanitizingEmpty() {
        XCTAssertEqual(CustomDurationMRU.sanitizing([]), [])
    }
}
