import XCTest
@testable import MaraCore

final class CountdownFormatTests: XCTestCase {

    // MARK: - label: 올림(ceiling) 의미론

    func testLabel_exactBoundary5h() {
        // 정확 경계: 18000초 → g=300(coarse), ceil(18000/300)=60 → 60*300=18000 → "5h"
        XCTAssertEqual(CountdownFormat.label(remaining: 5 * 3600), "5h")
    }

    func testLabel_justAfterBoundary5h() {
        // 경계 직후에도 5h 유지: 4h59m59s = 17999초 → ceil(17999/300)=60 → 18000 → "5h"
        XCTAssertEqual(CountdownFormat.label(remaining: 4 * 3600 + 59 * 60 + 59), "5h")
    }

    func testLabel_next5minBoundary() {
        // 4h55m 경계 도달 순간: 4h55m = 17700초 → ceil(17700/300)=59 → 17700 → "4h55m"
        XCTAssertEqual(CountdownFormat.label(remaining: 4 * 3600 + 55 * 60), "4h55m")
    }

    func testLabel_6min_coarseRoundup() {
        // 6분(360초) → 360>300 → g=300 → ceil(360/300)=2 → 600 → "10m"
        // 올림 의미론: 5m~10m 구간에서는 "10m"이 표시된다(UX가 다소 거칠지만 명세상 올바름)
        XCTAssertEqual(CountdownFormat.label(remaining: 6 * 60), "10m")
    }

    func testLabel_exactBoundary5m() {
        // 경계: 300초 → 300>300 false → g=60(fine) → ceil(300/60)=5 → 300 → "5m"
        XCTAssertEqual(CountdownFormat.label(remaining: 5 * 60), "5m")
    }

    func testLabel_4min30sec_fineRoundup() {
        // ≤5m → fine 단위: 4m30s = 270초 → g=60 → ceil(270/60)=5 → 300 → "5m"
        XCTAssertEqual(CountdownFormat.label(remaining: 4 * 60 + 30), "5m")
    }

    func testLabel_3min_fine() {
        // 3분(180초) → g=60 → ceil(180/60)=3 → 180 → "3m"
        XCTAssertEqual(CountdownFormat.label(remaining: 3 * 60), "3m")
    }

    func testLabel_59sec_fineRoundup() {
        // 59초 → g=60 → ceil(59/60)=1 → 60 → "1m"
        XCTAssertEqual(CountdownFormat.label(remaining: 59), "1m")
    }

    func testLabel_zero() {
        XCTAssertEqual(CountdownFormat.label(remaining: 0), "0m")
    }

    func testLabel_negative() {
        XCTAssertEqual(CountdownFormat.label(remaining: -5), "0m")
    }

    func testLabel_nan() {
        XCTAssertEqual(CountdownFormat.label(remaining: .nan), "0m")
    }

    // MARK: - nextTick: 경계 정렬

    func testNextTick_exactBoundary5h() {
        // 정확 경계 → next = (60-1)*300 = 17700 → tick = 18000-17700 = 300
        XCTAssertEqual(CountdownFormat.nextTick(remaining: 5 * 3600), 300, accuracy: 0.001)
    }

    func testNextTick_4h57min() {
        // 4h57m = 17820초 → g=300 → ceil(17820/300)=60 → next=(60-1)*300=17700 → tick=17820-17700=120
        XCTAssertEqual(CountdownFormat.nextTick(remaining: 4 * 3600 + 57 * 60), 120, accuracy: 0.001)
    }

    func testNextTick_exactBoundary5m() {
        // 300초(경계, fine 영역) → g=60 → ceil(300/60)=5 → next=(5-1)*60=240 → tick=300-240=60
        XCTAssertEqual(CountdownFormat.nextTick(remaining: 5 * 60), 60, accuracy: 0.001)
    }

    func testNextTick_3min30sec() {
        // 3m30s = 210초 → g=60 → ceil(210/60)=4 → next=(4-1)*60=180 → tick=210-180=30
        XCTAssertEqual(CountdownFormat.nextTick(remaining: 3 * 60 + 30), 30, accuracy: 0.001)
    }

    func testNextTick_zeroOrNegative() {
        // 비정상 입력 → fine(60) 반환
        XCTAssertEqual(CountdownFormat.nextTick(remaining: 0), 60, accuracy: 0.001)
        XCTAssertEqual(CountdownFormat.nextTick(remaining: -1), 60, accuracy: 0.001)
    }
}
