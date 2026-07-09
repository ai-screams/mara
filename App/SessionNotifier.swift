import Combine
import MaraCore

/// 세션 이벤트 → 알림 매핑. 원칙: 사용자가 직접 하지 않은 일만 알린다 —
/// 트리거 자동 시작, 그리고 자동 종료(타이머/저배터리/트리거 해제). 수동·교체는 침묵.
@MainActor
final class SessionNotifier {
    private var cancellable: AnyCancellable?

    init(session: SessionManager, isEnabled: @escaping () -> Bool, service: NotificationService) {
        cancellable = session.events.sink { event in
            MainActor.assumeIsolated {
                guard isEnabled(), let c = Self.content(for: event) else { return }
                service.post(title: c.title, body: c.body)
            }
        }
    }

    /// nil = 알리지 않는 이벤트. 문구는 App 전용(영어) — Core enum에는 문자열이 없다.
    static func content(for event: SessionEvent) -> (title: String, body: String)? {
        switch event.kind {
        case .started(let cfg) where cfg.origin == .trigger:
            return ("Mara is keeping your Mac awake", "Started automatically by a trigger.")
        case .stopped(.timerExpired):
            return ("Keep-awake ended", "Timer expired.")
        case .stopped(.lowBattery(let percent)):
            return ("Keep-awake ended", "Low battery (\(percent)%) — session ended safely.")
        case .stopped(.triggerCleared):
            return ("Keep-awake ended", "Automation trigger cleared.")
        case .started, .stopped(.manual), .stopped(.replacedByNewSession), .scopeChanged:
            return nil
        }
    }
}
