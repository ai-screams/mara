import SwiftUI

final class PrefsStore: ObservableObject {
    @AppStorage("defaultKeepDisplayAwake") var defaultKeepDisplayAwake: Bool = true
    @AppStorage("lowBatteryThreshold") var lowBatteryThreshold: Int = 20
}
