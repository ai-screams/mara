import SwiftUI
import Combine
import MaraCore

@MainActor
final class AppEnvironment: ObservableObject {
    let session: SessionManager
    let prefs = PrefsStore()
    // 글로벌 핫키 기능 보류(비활성화) — 코드는 보존, 재활성화 시 주석 해제.
    // private var hotkey: HotkeyManager?
    private var cancellables = Set<AnyCancellable>()

    init() {
        let engine = SleepEngine(provider: IOKitPowerAssertionProvider())
        session = SessionManager(
            engine: engine,
            scheduler: DispatchScheduler(queue: .main),
            clock: SystemClock(),
            battery: IOKitBatteryMonitor(),
            lowBatteryThreshold: prefs.lowBatteryThreshold
        )
        prefs.$lowBatteryThreshold
            .sink { [weak self] newValue in self?.session.lowBatteryThreshold = newValue }
            .store(in: &cancellables)
        // installHotkey()  // 글로벌 핫키 보류
    }

    // 글로벌 핫키 기능 보류(비활성화). 삭제하지 않고 보존 — 재활성화하려면 위 호출과
    // 아래 메서드, 그리고 `hotkey` 프로퍼티 주석을 해제하면 된다. HotkeyManager.swift는 그대로 유지.
    // private func installHotkey() {
    //     let hk = HotkeyManager(onToggle: { [weak self] in
    //         Task { @MainActor in
    //             guard let self else { return }
    //             let scope: KeepAwakeScope = self.prefs.defaultKeepDisplayAwake ? .displayAndSystem : .systemOnly
    //             self.session.toggle(SessionConfig(scope: scope, duration: .indefinite, origin: .manual))
    //         }
    //     })
    //     hk.register()
    //     hotkey = hk
    // }
}
