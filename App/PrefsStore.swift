import Foundation
import Combine

final class PrefsStore: ObservableObject {
    @Published var defaultKeepDisplayAwake: Bool {
        didSet { UserDefaults.standard.set(defaultKeepDisplayAwake, forKey: Keys.defaultKeepDisplayAwake) }
    }
    @Published var lowBatteryThreshold: Int {
        didSet { UserDefaults.standard.set(lowBatteryThreshold, forKey: Keys.lowBatteryThreshold) }
    }
    private enum Keys {
        static let defaultKeepDisplayAwake = "defaultKeepDisplayAwake"
        static let lowBatteryThreshold = "lowBatteryThreshold"
    }
    init() {
        let d = UserDefaults.standard
        d.register(defaults: [Keys.defaultKeepDisplayAwake: true, Keys.lowBatteryThreshold: 20])
        defaultKeepDisplayAwake = d.bool(forKey: Keys.defaultKeepDisplayAwake)
        lowBatteryThreshold = d.integer(forKey: Keys.lowBatteryThreshold)
    }
}
