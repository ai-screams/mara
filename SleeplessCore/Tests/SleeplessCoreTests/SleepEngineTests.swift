import XCTest
@testable import SleeplessCore

final class PowerAssertionContractTests: XCTestCase {
    func test_create_thenRelease_leavesNoLiveAssertions() {
        let p = MockPowerAssertionProvider()
        let t = p.create(type: .preventSystemSleep, name: "x")
        XCTAssertNotNil(t)
        XCTAssertEqual(p.live.count, 1)
        p.release(t!)
        XCTAssertEqual(p.live.count, 0)
    }
}
