import SwiftUI
import SleeplessCore

@MainActor
final class AppEnvironment: ObservableObject {
    let session: SessionManager

    init() {
        let engine = SleepEngine(provider: IOKitPowerAssertionProvider())
        session = SessionManager(
            engine: engine,
            scheduler: DispatchScheduler(queue: .main),
            clock: SystemClock(),
            battery: IOKitBatteryMonitor(),
            lowBatteryThreshold: 20
        )
    }
}
