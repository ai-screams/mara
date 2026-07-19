public struct SleepEngineFailure: Error, Equatable, Sendable {
    /// Primary operation failure followed by any rollback failures.
    public let failures: [PowerAssertionFailure]

    init(_ failures: [PowerAssertionFailure]) {
        self.failures = failures
    }
}

@MainActor
public final class SleepEngine {
    private let provider: PowerAssertionProviding
    private let name: String
    private var displayToken: PowerAssertionToken?
    private var systemToken: PowerAssertionToken?

    public init(provider: PowerAssertionProviding, name: String = "Mara") {
        self.provider = provider
        self.name = name
    }

    public var isDisplayHeld: Bool { displayToken != nil }
    public var isSystemHeld: Bool { systemToken != nil }

    /// 멱등·트랜잭션: 필요한 토큰을 모두 취득한 뒤 상태를 확정한다.
    /// 부분 취득 실패 시 이번 호출에서 새로 만든 토큰만 rollback한다.
    @discardableResult
    public func apply(display: Bool, system: Bool) -> Result<Void, SleepEngineFailure> {
        var nextDisplay = displayToken
        var nextSystem = systemToken
        var created: [(type: PowerAssertionType, token: PowerAssertionToken)] = []

        if system, nextSystem == nil {
            switch provider.create(type: .preventSystemSleep, name: name) {
            case .success(let token):
                nextSystem = token
                created.append((.preventSystemSleep, token))
            case .failure(let failure):
                return rollback(created, after: failure)
            }
        }
        if display, nextDisplay == nil {
            switch provider.create(type: .preventDisplaySleep, name: name) {
            case .success(let token):
                nextDisplay = token
                created.append((.preventDisplaySleep, token))
            case .failure(let failure):
                return rollback(created, after: failure)
            }
        }

        displayToken = nextDisplay
        systemToken = nextSystem

        var failures: [PowerAssertionFailure] = []
        if !display, let token = displayToken {
            switch provider.release(token) {
            case .success: displayToken = nil
            case .failure(let failure): failures.append(failure)
            }
        }
        if !system, let token = systemToken {
            switch provider.release(token) {
            case .success: systemToken = nil
            case .failure(let failure): failures.append(failure)
            }
        }
        return failures.isEmpty ? .success(()) : .failure(SleepEngineFailure(failures))
    }

    @discardableResult
    public func releaseAll() -> Result<Void, SleepEngineFailure> {
        apply(display: false, system: false)
    }

    private func rollback(_ tokens: [(type: PowerAssertionType, token: PowerAssertionToken)],
                          after primary: PowerAssertionFailure) -> Result<Void, SleepEngineFailure> {
        var failures = [primary]
        for item in tokens.reversed() {
            if case .failure(let rollbackFailure) = provider.release(item.token) {
                failures.append(rollbackFailure)
                // rollback도 실패했으면 토큰을 잃지 않는다. 이후 releaseAll이 재시도한다.
                switch item.type {
                case .preventDisplaySleep: displayToken = item.token
                case .preventSystemSleep: systemToken = item.token
                }
            }
        }
        return .failure(SleepEngineFailure(failures))
    }

    // 의도적으로 deinit이 없다. 정리는 실패를 호출자에게 돌려줄 수 있는 명시적 releaseAll
    // 경계에서만 수행한다(deinit은 실패를 전파 못 함). 프로세스 비정상 종료 시 남은 assertion은
    // IOKit이 프로세스 수명과 함께 회수한다.
    //
    // ⚠️ 전제: SleepEngine은 App 수명 동안 사는 단일 인스턴스(AppEnvironment 소유)다.
    // 이 전제에서만 "deinit 없음"이 안전하다 — 단명 인스턴스를 새로 만들면 소유자가
    // 놓기 전에 반드시 releaseAll()을 호출해야 assertion이 프로세스 종료까지 새지 않는다.
    // (형제 OS 어댑터들은 재생성될 수 있어 deinit에서 best-effort 정리를 하는 것과 다른 이유.)
}
