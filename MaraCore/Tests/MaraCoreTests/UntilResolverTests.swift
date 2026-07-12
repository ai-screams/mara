import XCTest
@testable import MaraCore

final class UntilResolverTests: XCTestCase {
    // 결정적 테스트: 고정 달력(UTC)로 DST/로컬 타임존 변수를 제거한다.
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: mo, day: d, hour: h, minute: mi))!
    }

    func testFutureTimeResolvesToday() {
        // now 10:00, 목표 시:분 14:30 → 같은 날 14:30 (timeOfDay의 날짜 부분은 무시).
        let result = UntilResolver.resolve(timeOfDay: date(2000, 1, 1, 14, 30),
                                           now: date(2026, 3, 1, 10, 0),
                                           calendar: cal)
        XCTAssertEqual(result, date(2026, 3, 1, 14, 30))
    }

    func testPastTimeRollsToTomorrow() {
        // now 16:00, 목표 09:00 → 이미 지남 → 다음 날 09:00.
        let result = UntilResolver.resolve(timeOfDay: date(2000, 1, 1, 9, 0),
                                           now: date(2026, 3, 1, 16, 0),
                                           calendar: cal)
        XCTAssertEqual(result, date(2026, 3, 2, 9, 0))
    }

    func testRolloverAcrossMonthEnd() {
        // now 3/31 16:00, 목표 09:00 → 4/1 09:00 (달 경계).
        let result = UntilResolver.resolve(timeOfDay: date(2000, 1, 1, 9, 0),
                                           now: date(2026, 3, 31, 16, 0),
                                           calendar: cal)
        XCTAssertEqual(result, date(2026, 4, 1, 9, 0))
    }

    func testResultAlwaysStrictlyFuture() {
        let now = date(2026, 6, 15, 23, 59)
        for (h, m) in [(0, 0), (6, 30), (12, 0), (23, 58), (23, 59)] {
            let r = UntilResolver.resolve(timeOfDay: date(2000, 1, 1, h, m), now: now, calendar: cal)
            XCTAssertGreaterThan(r, now, "time \(h):\(m) should resolve to a future instant")
        }
    }
}
