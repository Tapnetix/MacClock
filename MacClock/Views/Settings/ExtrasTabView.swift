import SwiftUI

// MARK: - Extras Tab

struct ExtrasTabView: View {
    @Bindable var settings: AppSettings
    @Binding var showAlarmPanel: Bool

    var body: some View {
        SettingsSection(title: "Alarms & Timers") {
            Button("Open Alarms, Timer & Stopwatch") {
                showAlarmPanel = true
            }
        }
    }
}
