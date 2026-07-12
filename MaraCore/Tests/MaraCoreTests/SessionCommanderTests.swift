import XCTest
@testable import MaraCore

@MainActor
final class SessionCommanderTests: XCTestCase {
    private func make(scope: KeepAwakeScope = .systemOnly, now: Date = Date(timeIntervalSince1970: 1000))
        -> (SessionCommander, SessionManager, MockClock) {
        let clock = MockClock(now)
        let sm = SessionManager(engine: SleepEngine(provider: MockPowerAssertionProvider()),
                                scheduler: MockScheduler(), clock: clock)
        let cmd = SessionCommander(session: sm, scope: { scope }, clock: clock)
        return (cmd, sm, clock)
    }

    // MARK: - start

    func test_start_nilDuration_startsIndefiniteManual() {
        let (cmd, sm, _) = make()
        cmd.startKeepAwake(duration: nil)
        guard case let .active(cfg, expiresAt) = sm.state else { return XCTFail() }
        XCTAssertEqual(cfg.origin, .manual)
        XCTAssertEqual(cfg.duration, .indefinite)
        XCTAssertNil(expiresAt)
    }

    func test_start_usesInjectedScope() {
        let (cmd, sm, _) = make(scope: .displayAndSystem)
        cmd.startKeepAwake(duration: nil)
        guard case let .active(cfg, _) = sm.state else { return XCTFail() }
        XCTAssertEqual(cfg.scope, .displayAndSystem)
    }

    func test_start_finiteDuration_setsExpiry() {
        let (cmd, sm, clock) = make()
        cmd.startKeepAwake(duration: 900)   // 15분
        guard case let .active(cfg, expiresAt) = sm.state else { return XCTFail() }
        XCTAssertEqual(cfg.duration, .duration(900))
        XCTAssertEqual(expiresAt, clock.now.addingTimeInterval(900))
    }

    func test_start_clampsAbove24h() {
        let (cmd, sm, _) = make()
        cmd.startKeepAwake(duration: 999 * 3600)   // 999시간 → 24h로 클램프
        guard case let .active(cfg, _) = sm.state else { return XCTFail() }
        XCTAssertEqual(cfg.duration, .duration(SessionCommander.maxDuration))
    }

    func test_start_clampsNegativeToZero_thenExpiresImmediately() {
        // 음수는 0으로 클램프 → duration(0). SessionManager는 즉시 만료 스케줄(테스트 스케줄러는 수동 발화).
        let (cmd, sm, _) = make()
        cmd.startKeepAwake(duration: -60)
        guard case let .active(cfg, _) = sm.state else { return XCTFail() }
        XCTAssertEqual(cfg.duration, .duration(0))
    }

    func test_start_whileActive_replaces() {
        let (cmd, sm, _) = make()
        cmd.startKeepAwake(duration: 900)
        cmd.startKeepAwake(duration: nil)   // 교체
        guard case let .active(cfg, expiresAt) = sm.state else { return XCTFail() }
        XCTAssertEqual(cfg.duration, .indefinite)
        XCTAssertNil(expiresAt)
    }

    // MARK: - stop

    func test_stop_endsSession_asManual() {
        let (cmd, sm, _) = make()
        cmd.startKeepAwake(duration: nil)
        cmd.stopKeepAwake()
        XCTAssertFalse(sm.state.isActive)
        XCTAssertEqual(sm.recentEvents.last?.kind, .stopped(.manual))
    }

    func test_stop_whenInactive_isNoOp() {
        let (cmd, sm, _) = make()
        cmd.stopKeepAwake()   // 비활성에서 stop → 무기록·무크래시(멱등)
        XCTAssertFalse(sm.state.isActive)
        XCTAssertTrue(sm.recentEvents.isEmpty)
    }

    // MARK: - status

    func test_status_inactive() {
        let (cmd, _, _) = make()
        XCTAssertEqual(cmd.status(), KeepAwakeStatus(isActive: false, remaining: nil, isTriggered: false))
    }

    func test_status_indefiniteManual() {
        let (cmd, _, _) = make()
        cmd.startKeepAwake(duration: nil)
        XCTAssertEqual(cmd.status(), KeepAwakeStatus(isActive: true, remaining: nil, isTriggered: false))
    }

    func test_status_finiteRemaining_countsDown() {
        let (cmd, _, clock) = make()
        cmd.startKeepAwake(duration: 900)
        clock.now = clock.now.addingTimeInterval(300)   // 5분 경과 → 남은 600
        XCTAssertEqual(cmd.status(), KeepAwakeStatus(isActive: true, remaining: 600, isTriggered: false))
    }

    func test_status_remainingClampedNonNegative_afterExpiryInstant() {
        // clock이 만료를 지나도 remaining은 음수가 아니라 0 (스케줄러 미발화 상황 방어).
        let (cmd, _, clock) = make()
        cmd.startKeepAwake(duration: 900)
        clock.now = clock.now.addingTimeInterval(1200)
        XCTAssertEqual(cmd.status().remaining, 0)
    }

    func test_status_isTriggered_whenSessionOriginIsTrigger() {
        let (cmd, sm, _) = make()
        // 트리거 기인 세션을 직접 주입(트리거 엔진 없이 origin만 검증)
        sm.start(SessionConfig(scope: .systemOnly, duration: .indefinite, origin: .trigger))
        XCTAssertEqual(cmd.status(), KeepAwakeStatus(isActive: true, remaining: nil, isTriggered: true))
    }
}
