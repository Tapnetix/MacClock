import SwiftUI
import ServiceManagement

// MARK: - Window Tab

struct WindowTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SettingsSection(title: "Window Behavior") {
            LabeledContent("Window Level") {
                Picker("", selection: $settings.windowLevel) {
                    ForEach(WindowLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            LabeledContent("Opacity") {
                HStack {
                    Slider(value: $settings.windowOpacity, in: 0.2...1.0, step: 0.1)
                        .frame(width: 120)
                    Text("\(Int(settings.windowOpacity * 100))%")
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                }
            }
        }

        SettingsSection(title: "System") {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .onChange(of: settings.launchAtLogin) { _, newValue in
                    updateLaunchAtLogin(newValue)
                }
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Launch at login error: \(error)")
        }
    }
}
