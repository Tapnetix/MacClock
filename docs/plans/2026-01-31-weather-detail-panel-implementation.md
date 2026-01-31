# Weather Detail Panel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a click-to-toggle weather detail dropdown showing extended forecast (feels like, humidity, hourly, daily) with configurable sections.

**Architecture:** Extend WeatherData model with forecast data, update WeatherService to fetch additional Open-Meteo fields, create WeatherDetailPanel view as dropdown overlay, add settings toggles for each section.

**Tech Stack:** Swift, SwiftUI, Open-Meteo API, Swift Testing

---

### Task 1: Extend WeatherData Model with Forecast Types

**Files:**
- Modify: `MacClock/Models/WeatherData.swift`
- Test: `MacClockTests/WeatherDataTests.swift`

**Step 1: Write the failing tests**

Add to `MacClockTests/WeatherDataTests.swift`:

```swift
@Test func decodeExtendedOpenMeteoResponse() throws {
    let json = """
    {
        "current": {
            "temperature_2m": 6.5,
            "weather_code": 61,
            "apparent_temperature": 4.2,
            "relative_humidity_2m": 85
        },
        "daily": {
            "sunrise": ["2026-01-31T07:32"],
            "sunset": ["2026-01-31T17:45"],
            "temperature_2m_max": [8.0, 9.0, 11.0],
            "temperature_2m_min": [3.0, 4.0, 5.0],
            "weather_code": [61, 3, 0]
        },
        "hourly": {
            "time": ["2026-01-31T10:00", "2026-01-31T11:00", "2026-01-31T12:00", "2026-01-31T13:00", "2026-01-31T14:00", "2026-01-31T15:00"],
            "temperature_2m": [5.0, 6.0, 6.5, 7.0, 7.5, 7.0],
            "weather_code": [61, 61, 3, 3, 2, 2]
        }
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
    #expect(response.current.apparentTemperature == 4.2)
    #expect(response.current.humidity == 85)
    #expect(response.daily.maxTemps.count == 3)
    #expect(response.daily.minTemps.count == 3)
    #expect(response.daily.weatherCodes.count == 3)
    #expect(response.hourly.times.count == 6)
    #expect(response.hourly.temperatures.count == 6)
}

@Test func hourlyWeatherStoresData() {
    let weather = HourlyWeather(
        time: Date(),
        temperature: 6.5,
        condition: .rain
    )
    #expect(weather.temperature == 6.5)
    #expect(weather.condition == .rain)
}

@Test func dailyForecastStoresData() {
    let forecast = DailyForecast(
        date: Date(),
        highTemp: 8.0,
        lowTemp: 3.0,
        condition: .cloudy
    )
    #expect(forecast.highTemp == 8.0)
    #expect(forecast.lowTemp == 3.0)
}
```

**Step 2: Run tests to verify they fail**

Run: `swift test --filter WeatherDataTests`
Expected: FAIL - types don't exist

**Step 3: Extend WeatherData.swift**

Replace contents of `MacClock/Models/WeatherData.swift`:

```swift
import Foundation

struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
    let hourly: HourlyWeatherResponse
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weatherCode: Int
    let apparentTemperature: Double
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case apparentTemperature = "apparent_temperature"
        case humidity = "relative_humidity_2m"
    }
}

struct DailyWeather: Codable {
    let sunrise: [String]
    let sunset: [String]
    let maxTemps: [Double]
    let minTemps: [Double]
    let weatherCodes: [Int]

    enum CodingKeys: String, CodingKey {
        case sunrise
        case sunset
        case maxTemps = "temperature_2m_max"
        case minTemps = "temperature_2m_min"
        case weatherCodes = "weather_code"
    }
}

struct HourlyWeatherResponse: Codable {
    let times: [String]
    let temperatures: [Double]
    let weatherCodes: [Int]

    enum CodingKeys: String, CodingKey {
        case times = "time"
        case temperatures = "temperature_2m"
        case weatherCodes = "weather_code"
    }
}

struct HourlyWeather {
    let time: Date
    let temperature: Double
    let condition: WeatherCondition
}

struct DailyForecast {
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let condition: WeatherCondition
}

struct WeatherData {
    let temperature: Double
    let condition: WeatherCondition
    let locationName: String
    let sunrise: Date
    let sunset: Date
    let feelsLike: Double
    let humidity: Int
    let highTemp: Double
    let lowTemp: Double
    let hourlyForecast: [HourlyWeather]
    let dailyForecast: [DailyForecast]
}

enum WeatherCondition: Equatable {
    case clear
    case partlyCloudy
    case cloudy
    case foggy
    case drizzle
    case rain
    case snow
    case thunderstorm
    case unknown

    var sfSymbol: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    static func fromCode(_ code: Int) -> WeatherCondition {
        switch code {
        case 0: return .clear
        case 1, 2: return .partlyCloudy
        case 3: return .cloudy
        case 45, 48: return .foggy
        case 51, 53, 55, 56, 57: return .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: return .rain
        case 71, 73, 75, 77, 85, 86: return .snow
        case 95, 96, 99: return .thunderstorm
        default: return .unknown
        }
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter WeatherDataTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/WeatherData.swift MacClockTests/WeatherDataTests.swift
git commit -m "feat(weather): extend WeatherData model with forecast types"
```

---

### Task 2: Update WeatherService to Fetch Extended Data

**Files:**
- Modify: `MacClock/Services/WeatherService.swift`
- Test: `MacClockTests/WeatherServiceTests.swift`

**Step 1: Write the failing test**

Add to `MacClockTests/WeatherServiceTests.swift`:

```swift
@Test func buildURLIncludesExtendedParams() {
    let service = WeatherService()
    let url = service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: true)
    let urlString = url.absoluteString

    #expect(urlString.contains("apparent_temperature"))
    #expect(urlString.contains("relative_humidity_2m"))
    #expect(urlString.contains("temperature_2m_max"))
    #expect(urlString.contains("temperature_2m_min"))
    #expect(urlString.contains("hourly="))
    #expect(urlString.contains("forecast_days=3"))
    #expect(urlString.contains("forecast_hours=6"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WeatherServiceTests`
Expected: FAIL - URL doesn't contain new params

**Step 3: Update WeatherService.swift**

Replace `MacClock/Services/WeatherService.swift`:

```swift
import Foundation

actor WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private var cachedWeather: WeatherData?
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 30 * 60 // 30 minutes

    nonisolated func buildURL(latitude: Double, longitude: Double, useCelsius: Bool) -> URL {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,apparent_temperature,relative_humidity_2m"),
            URLQueryItem(name: "daily", value: "sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "temperature_unit", value: useCelsius ? "celsius" : "fahrenheit"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "3"),
            URLQueryItem(name: "forecast_hours", value: "6")
        ]
        return components.url!
    }

    func fetchWeather(latitude: Double, longitude: Double, locationName: String, useCelsius: Bool) async throws -> WeatherData {
        // Return cached if fresh
        if let cached = cachedWeather,
           let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheInterval {
            return cached
        }

        let url = buildURL(latitude: latitude, longitude: longitude, useCelsius: useCelsius)
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        // Parse hourly forecast (next 6 hours)
        var hourlyForecast: [HourlyWeather] = []
        let now = Date()
        for i in 0..<min(6, response.hourly.times.count) {
            if let time = isoFormatter.date(from: response.hourly.times[i]), time > now {
                hourlyForecast.append(HourlyWeather(
                    time: time,
                    temperature: response.hourly.temperatures[i],
                    condition: WeatherCondition.fromCode(response.hourly.weatherCodes[i])
                ))
            }
            if hourlyForecast.count >= 6 { break }
        }

        // Parse daily forecast (3 days)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var dailyForecast: [DailyForecast] = []
        for i in 0..<min(3, response.daily.maxTemps.count) {
            let dateString = String(response.daily.sunrise[i].prefix(10))
            let date = dateFormatter.date(from: dateString) ?? now
            dailyForecast.append(DailyForecast(
                date: date,
                highTemp: response.daily.maxTemps[i],
                lowTemp: response.daily.minTemps[i],
                condition: WeatherCondition.fromCode(response.daily.weatherCodes[i])
            ))
        }

        let weather = WeatherData(
            temperature: response.current.temperature,
            condition: WeatherCondition.fromCode(response.current.weatherCode),
            locationName: locationName,
            sunrise: isoFormatter.date(from: response.daily.sunrise.first ?? "") ?? Date(),
            sunset: isoFormatter.date(from: response.daily.sunset.first ?? "") ?? Date(),
            feelsLike: response.current.apparentTemperature,
            humidity: response.current.humidity,
            highTemp: response.daily.maxTemps.first ?? response.current.temperature,
            lowTemp: response.daily.minTemps.first ?? response.current.temperature,
            hourlyForecast: hourlyForecast,
            dailyForecast: dailyForecast
        )

        cachedWeather = weather
        lastFetch = Date()

        return weather
    }

    func clearCache() {
        cachedWeather = nil
        lastFetch = nil
    }
}
```

**Step 4: Run tests to verify they pass**

Run: `swift test --filter WeatherServiceTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Services/WeatherService.swift MacClockTests/WeatherServiceTests.swift
git commit -m "feat(weather): update WeatherService to fetch extended forecast data"
```

---

### Task 3: Add Weather Detail Settings to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`

**Step 1: Add weather detail properties**

Add after the `useCelsius` property (around line 53) in `MacClock/Models/AppSettings.swift`:

```swift
    var weatherDetailEnabled: Bool {
        didSet { defaults.set(weatherDetailEnabled, forKey: "weatherDetailEnabled") }
    }

    var weatherShowCurrentDetails: Bool {
        didSet { defaults.set(weatherShowCurrentDetails, forKey: "weatherShowCurrentDetails") }
    }

    var weatherShowSunriseSunset: Bool {
        didSet { defaults.set(weatherShowSunriseSunset, forKey: "weatherShowSunriseSunset") }
    }

    var weatherShowHourly: Bool {
        didSet { defaults.set(weatherShowHourly, forKey: "weatherShowHourly") }
    }

    var weatherShowDaily: Bool {
        didSet { defaults.set(weatherShowDaily, forKey: "weatherShowDaily") }
    }
```

**Step 2: Initialize in init()**

Find the `init(defaults:)` method and add after `useCelsius` initialization:

```swift
        self.weatherDetailEnabled = defaults.object(forKey: "weatherDetailEnabled") as? Bool ?? true
        self.weatherShowCurrentDetails = defaults.object(forKey: "weatherShowCurrentDetails") as? Bool ?? true
        self.weatherShowSunriseSunset = defaults.object(forKey: "weatherShowSunriseSunset") as? Bool ?? true
        self.weatherShowHourly = defaults.object(forKey: "weatherShowHourly") as? Bool ?? true
        self.weatherShowDaily = defaults.object(forKey: "weatherShowDaily") as? Bool ?? true
```

**Step 3: Verify build**

Run: `swift build`
Expected: PASS

**Step 4: Commit**

```bash
git add MacClock/Models/AppSettings.swift
git commit -m "feat(weather): add weather detail panel settings to AppSettings"
```

---

### Task 4: Add Weather Settings Section to SettingsView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add Weather section to GeneralTabView**

In `MacClock/Views/SettingsView.swift`, find `GeneralTabView` and add after the "Temperature" SettingsSection:

```swift
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
```

**Step 2: Verify build**

Run: `swift build`
Expected: PASS

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat(weather): add weather detail settings section to GeneralTabView"
```

---

### Task 5: Create WeatherDetailPanel View

**Files:**
- Modify: `MacClock/Views/WeatherView.swift`

**Step 1: Create WeatherDetailPanel struct**

Replace `MacClock/Views/WeatherView.swift` with:

```swift
import SwiftUI

struct WeatherView: View {
    let weather: WeatherData?
    let useCelsius: Bool
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite
    @Binding var showDetailPanel: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            // Dropdown panel
            if showDetailPanel, let weather = weather {
                WeatherDetailPanel(
                    weather: weather,
                    useCelsius: useCelsius,
                    settings: settings,
                    theme: theme
                )
                .transition(.move(edge: .top).combined(with: .opacity))
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
            // Current details
            if settings.weatherShowCurrentDetails {
                currentDetailsSection
                if settings.weatherShowSunriseSunset || settings.weatherShowHourly || settings.weatherShowDaily {
                    Divider().background(theme.accentColor.opacity(0.3))
                }
            }

            // Sunrise/Sunset
            if settings.weatherShowSunriseSunset {
                sunriseSunsetSection
                if settings.weatherShowHourly || settings.weatherShowDaily {
                    Divider().background(theme.accentColor.opacity(0.3))
                }
            }

            // Hourly forecast
            if settings.weatherShowHourly && !weather.hourlyForecast.isEmpty {
                hourlySection
                if settings.weatherShowDaily {
                    Divider().background(theme.accentColor.opacity(0.3))
                }
            }

            // Daily forecast
            if settings.weatherShowDaily && !weather.dailyForecast.isEmpty {
                dailySection
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
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
```

**Step 2: Verify build**

Run: `swift build`
Expected: FAIL - WeatherView usage in MacClockApp.swift needs updating

**Step 3: Commit partial progress**

```bash
git add MacClock/Views/WeatherView.swift
git commit -m "feat(weather): create WeatherDetailPanel dropdown view"
```

---

### Task 6: Update MainClockView to Support Weather Panel State

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add showWeatherDetail state**

In `MainClockView`, add after other @State properties (around line 125):

```swift
    @State private var showWeatherDetail = false
```

**Step 2: Update WeatherView usage**

Find the WeatherView usage (around line 183) and update to:

```swift
                        WeatherView(
                            weather: weather,
                            useCelsius: settings.useCelsius,
                            settings: settings,
                            theme: effectiveTheme,
                            showDetailPanel: $showWeatherDetail
                        )
```

**Step 3: Close panel when clicking elsewhere**

Add a tap gesture to the main content area to close the panel. Find the main ZStack or content area and add:

```swift
                .onTapGesture {
                    if showWeatherDetail {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showWeatherDetail = false
                        }
                    }
                }
```

This should be on the main background or content area, not on interactive elements.

**Step 4: Verify build**

Run: `swift build`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/MacClockApp.swift
git commit -m "feat(weather): integrate weather detail panel into MainClockView"
```

---

### Task 7: Run All Tests and Final Verification

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 2: Build the app**

Run: `swift build`
Expected: Build successful

**Step 3: Manual testing checklist**

- [ ] Click temperature → panel appears
- [ ] Click temperature again → panel disappears
- [ ] Panel shows feels like, humidity, high/low
- [ ] Panel shows sunrise/sunset times
- [ ] Panel shows 6-hour forecast with icons
- [ ] Panel shows 3-day forecast
- [ ] Settings toggles hide/show each section
- [ ] "Enable weather detail panel" toggle disables click behavior

**Step 4: Final commit if needed**

```bash
git status
# If any uncommitted changes:
git add -A
git commit -m "feat(weather): complete weather detail panel implementation"
```

---

## Summary

This plan implements:
1. Extended WeatherData model with hourly/daily forecast types
2. Updated WeatherService to fetch additional Open-Meteo data
3. Weather detail settings in AppSettings
4. Settings UI with toggles for each section
5. WeatherDetailPanel dropdown view matching world clocks style
6. Click-to-toggle integration in MainClockView
7. Comprehensive tests for new functionality
