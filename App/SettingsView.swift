import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs: PrefsStore

    var body: some View {
        Form {
            Toggle("Keep display awake by default", isOn: $prefs.defaultKeepDisplayAwake)
            Stepper("Low-battery auto-off: \(prefs.lowBatteryThreshold)%",
                    value: $prefs.lowBatteryThreshold, in: 5...50, step: 5)
            Text("배터리(AC 미연결) 잔량이 임계 이하로 떨어지면 세션을 안전하게 종료합니다.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 380)
    }
}
