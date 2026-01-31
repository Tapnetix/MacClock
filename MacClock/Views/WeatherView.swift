import SwiftUI

struct WeatherView: View {
    let weather: WeatherData?
    let useCelsius: Bool
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite
    @Binding var showDetailPanel: Bool

    var body: some View {
        // Main weather display (clickable)
        weatherDisplay
            .contentShape(Rectangle())
            .onTapGesture {
                if settings.weatherDetailEnabled && weather != nil {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDetailPanel.toggle()
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                // Dropdown panel - overlays content below, doesn't shift layout
                if showDetailPanel, let weather = weather {
                    WeatherDetailPanel(
                        weather: weather,
                        useCelsius: useCelsius,
                        settings: settings,
                        theme: theme
                    )
                    .offset(y: 28) // Position below the weather display
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
                }
            }
    }

    @ViewBuilder
    private var weatherDisplay: some View {
        if let weather = weather {
            HStack(spacing: 6) {
                Image(systemName: weather.condition.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundStyle(theme.primaryColor.opacity(0.9))

                Text(temperatureString(weather.temperature))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.primaryColor)

                Text(weather.locationName)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accentColor)

                if settings.weatherDetailEnabled {
                    Image(systemName: showDetailPanel ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.accentColor.opacity(0.6))
                }
            }
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                Text("—")
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundStyle(theme.primaryColor.opacity(0.6))
        }
    }

    private func temperatureString(_ temp: Double) -> String {
        let rounded = Int(temp.rounded())
        return "\(rounded)°\(useCelsius ? "C" : "F")"
    }
}

struct WeatherDetailPanel: View {
    let weather: WeatherData
    let useCelsius: Bool
    let settings: AppSettings
    let theme: ColorTheme

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if settings.weatherShowCurrentDetails {
                currentDetailsSection
                if settings.weatherShowSunriseSunset || settings.weatherShowHourly || settings.weatherShowDaily {
                    Divider().background(theme.accentColor.opacity(0.3))
                }
            }

            if settings.weatherShowSunriseSunset {
                sunriseSunsetSection
                if settings.weatherShowHourly || settings.weatherShowDaily {
                    Divider().background(theme.accentColor.opacity(0.3))
                }
            }

            if settings.weatherShowHourly && !weather.hourlyForecast.isEmpty {
                hourlySection
                if settings.weatherShowDaily {
                    Divider().background(theme.accentColor.opacity(0.3))
                }
            }

            if settings.weatherShowDaily && !weather.dailyForecast.isEmpty {
                dailySection
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(6)
        .padding(.top, 4)
    }

    private var currentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Feels like")
                    .foregroundStyle(theme.accentColor)
                Spacer()
                Text(tempString(weather.feelsLike))
                    .foregroundStyle(theme.primaryColor)
            }
            HStack {
                Text("Humidity")
                    .foregroundStyle(theme.accentColor)
                Spacer()
                Text("\(weather.humidity)%")
                    .foregroundStyle(theme.primaryColor)
            }
            HStack {
                Text("High / Low")
                    .foregroundStyle(theme.accentColor)
                Spacer()
                Text("\(tempString(weather.highTemp)) / \(tempString(weather.lowTemp))")
                    .foregroundStyle(theme.primaryColor)
            }
        }
        .font(.system(size: 12))
    }

    private var sunriseSunsetSection: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "sunrise.fill")
                    .foregroundStyle(.orange)
                Text(timeFormatter.string(from: weather.sunrise))
                    .foregroundStyle(theme.primaryColor)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "sunset.fill")
                    .foregroundStyle(.orange)
                Text(timeFormatter.string(from: weather.sunset))
                    .foregroundStyle(theme.primaryColor)
            }
        }
        .font(.system(size: 12))
    }

    private var hourlySection: some View {
        HStack(spacing: 0) {
            ForEach(Array(weather.hourlyForecast.prefix(6).enumerated()), id: \.offset) { _, hour in
                VStack(spacing: 2) {
                    Text(timeFormatter.string(from: hour.time))
                        .font(.system(size: 9))
                        .foregroundStyle(theme.accentColor)
                    Image(systemName: hour.condition.sfSymbol)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.primaryColor.opacity(0.9))
                    Text(tempString(hour.temperature))
                        .font(.system(size: 10))
                        .foregroundStyle(theme.primaryColor)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(weather.dailyForecast.prefix(3).enumerated()), id: \.offset) { index, day in
                HStack {
                    Text(index == 0 ? "Today" : dayFormatter.string(from: day.date))
                        .frame(width: 45, alignment: .leading)
                        .foregroundStyle(theme.accentColor)
                    Image(systemName: day.condition.sfSymbol)
                        .frame(width: 20)
                        .foregroundStyle(theme.primaryColor.opacity(0.9))
                    Spacer()
                    Text("\(tempString(day.highTemp)) / \(tempString(day.lowTemp))")
                        .foregroundStyle(theme.primaryColor)
                }
                .font(.system(size: 12))
            }
        }
    }

    private func tempString(_ temp: Double) -> String {
        "\(Int(temp.rounded()))°"
    }
}

#Preview {
    WeatherView(
        weather: WeatherData(
            temperature: 6.5,
            condition: .rain,
            locationName: "London",
            sunrise: Date(),
            sunset: Date().addingTimeInterval(8 * 3600),
            feelsLike: 4.2,
            humidity: 85,
            highTemp: 8.0,
            lowTemp: 3.0,
            hourlyForecast: [
                HourlyWeather(time: Date().addingTimeInterval(3600), temperature: 6.0, condition: .rain),
                HourlyWeather(time: Date().addingTimeInterval(7200), temperature: 6.5, condition: .cloudy),
                HourlyWeather(time: Date().addingTimeInterval(10800), temperature: 7.0, condition: .partlyCloudy),
            ],
            dailyForecast: [
                DailyForecast(date: Date(), highTemp: 8.0, lowTemp: 3.0, condition: .rain),
                DailyForecast(date: Date().addingTimeInterval(86400), highTemp: 9.0, lowTemp: 4.0, condition: .cloudy),
                DailyForecast(date: Date().addingTimeInterval(172800), highTemp: 11.0, lowTemp: 5.0, condition: .clear),
            ]
        ),
        useCelsius: true,
        settings: AppSettings(),
        showDetailPanel: .constant(true)
    )
    .padding()
    .background(.black)
    .frame(width: 250)
}
