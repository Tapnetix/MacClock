import SwiftUI

// MARK: - Appearance Tab

struct AppearanceTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SettingsSection(title: "Theme") {
            if !settings.autoThemeEnabled {
                LabeledContent("Color Theme") {
                    Picker("", selection: $settings.colorTheme) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
            }

            Toggle("Auto Theme Switching", isOn: $settings.autoThemeEnabled)

            if settings.autoThemeEnabled {
                LabeledContent("Day Theme") {
                    Picker("", selection: $settings.dayTheme) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                LabeledContent("Night Theme") {
                    Picker("", selection: $settings.nightThemeAuto) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                LabeledContent("Switch Based On") {
                    Picker("", selection: $settings.autoThemeMode) {
                        ForEach(AutoDimMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
            }
        }

        SettingsSection(title: "Auto-Dim") {
            Toggle("Enable Auto-Dim", isOn: $settings.autoDimEnabled)

            if settings.autoDimEnabled {
                LabeledContent("Trigger") {
                    Picker("", selection: $settings.autoDimMode) {
                        ForEach(AutoDimMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }

                if settings.autoDimMode == .fixedSchedule {
                    LabeledContent("Dim at") {
                        Picker("", selection: $settings.dimStartHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }

                    LabeledContent("Brighten at") {
                        Picker("", selection: $settings.dimEndHour) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 100)
                    }
                }

                LabeledContent("Dim Level") {
                    HStack {
                        Slider(value: $settings.autoDimLevel, in: 0.2...0.8, step: 0.1)
                            .frame(width: 100)
                        Text("\(Int(settings.autoDimLevel * 100))%")
                            .foregroundStyle(.secondary)
                            .frame(width: 40)
                    }
                }

                LabeledContent("Night Theme") {
                    Picker("", selection: Binding(
                        get: { settings.nightTheme ?? .warmAmber },
                        set: { settings.nightTheme = $0 }
                    )) {
                        Text("None").tag(Optional<ColorTheme>.none)
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(Optional(theme))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
            }
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}
