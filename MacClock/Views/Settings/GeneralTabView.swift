import SwiftUI

// MARK: - General Tab

struct GeneralTabView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        SettingsSection(title: "Clock Display") {
            LabeledContent("Style") {
                Picker("", selection: $settings.clockStyle) {
                    ForEach(ClockStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            LabeledContent("Size") {
                HStack {
                    Slider(value: $settings.clockFontSize, in: 48...200, step: 4)
                        .frame(width: 120)
                    Text("\(Int(settings.clockFontSize))")
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                }
            }

            Toggle("24-Hour Time", isOn: $settings.use24Hour)
            Toggle("Show Seconds", isOn: $settings.showSeconds)
        }

        SettingsSection(title: "Temperature") {
            Picker("", selection: $settings.useCelsius) {
                Text("Fahrenheit (°F)").tag(false)
                Text("Celsius (°C)").tag(true)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
        }

        SettingsSection(title: "Weather Details") {
            Toggle("Enable weather detail panel", isOn: $settings.weatherDetailEnabled)
                .help("Click on temperature to show/hide detailed forecast")

            if settings.weatherDetailEnabled {
                Text("Show in panel:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Toggle("Current conditions (feels like, humidity, high/low)", isOn: $settings.weatherShowCurrentDetails)
                    .padding(.leading, 16)
                Toggle("Sunrise & sunset", isOn: $settings.weatherShowSunriseSunset)
                    .padding(.leading, 16)
                Toggle("Hourly forecast (6 hours)", isOn: $settings.weatherShowHourly)
                    .padding(.leading, 16)
                Toggle("Daily forecast (3 days)", isOn: $settings.weatherShowDaily)
                    .padding(.leading, 16)
            }
        }
    }
}
