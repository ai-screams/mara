import SwiftUI
import SleeplessCore

@main
struct SleeplessApp: App {
    @StateObject private var env = AppEnvironment()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(session: env.session)
        } label: {
            Image(systemName: env.session.state.isActive ? "cup.and.saucer.fill" : "cup.and.saucer")
        }
        .menuBarExtraStyle(.menu)
    }
}
