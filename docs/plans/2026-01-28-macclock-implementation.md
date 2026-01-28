# MacClock Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native macOS clock app with digital time display, weather, and scenic backgrounds.

**Architecture:** SwiftUI app with MVVM-ish structure. Services handle data fetching (weather, location), models store state with UserDefaults persistence, views render the UI. Window level controlled via NSWindow APIs.

**Tech Stack:** Swift, SwiftUI, CoreLocation, Open-Meteo API, DSEG font

---

## Task 1: Create Xcode Project

**Files:**
- Create: Xcode project `MacClock.xcodeproj`
- Create: `MacClock/MacClockApp.swift`

**Step 1: Create the Xcode project via command line**

```bash
cd /Users/jjb/Work/Projects/MacClock
mkdir -p MacClock
```

Create `MacClock/MacClockApp.swift`:
```swift
import SwiftUI

@main
struct MacClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("MacClock")
            .frame(width: 480, height: 320)
    }
}
```

**Step 2: Create the Xcode project file**

Use Xcode to create project OR create Package.swift for SPM-based approach:

```swift
// Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacClock",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacClock",
            path: "MacClock"
        ),
        .testTarget(
            name: "MacClockTests",
            dependencies: ["MacClock"],
            path: "MacClockTests"
        )
    ]
)
```

**Step 3: Verify it builds**

Run: `swift build` or open in Xcode and build (Cmd+B)
Expected: Build succeeds

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: initial Xcode project setup"
```

---

## Task 2: Add DSEG Font

**Files:**
- Create: `MacClock/Resources/Fonts/DSEG7Classic-Bold.ttf`
- Modify: Info.plist to register font

**Step 1: Download DSEG font**

Download from: https://github.com/keshikan/DSEG/releases
Extract `DSEG7Classic-Bold.ttf` (the 7-segment bold variant)

```bash
mkdir -p MacClock/Resources/Fonts
# Copy downloaded font to MacClock/Resources/Fonts/DSEG7Classic-Bold.ttf
```

**Step 2: Register font in Info.plist**

Add to Info.plist (or create if using SPM):
```xml
<key>ATSApplicationFontsPath</key>
<string>Resources/Fonts</string>
```

For SPM, create `MacClock/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ATSApplicationFontsPath</key>
    <string>Resources/Fonts</string>
</dict>
</plist>
```

**Step 3: Verify font loads**

Update ContentView temporarily:
```swift
struct ContentView: View {
    var body: some View {
        Text("12:34")
            .font(.custom("DSEG7Classic-Bold", size: 72))
            .frame(width: 480, height: 320)
    }
}
```

Run app, verify LCD-style digits appear.

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add DSEG7 LCD font"
```

---

## Task 3: Create AppSettings Model

**Files:**
- Create: `MacClock/Models/AppSettings.swift`
- Create: `MacClockTests/AppSettingsTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/AppSettingsTests.swift`:
```swift
import Testing
@testable import MacClock

@Test func defaultSettings() {
    let settings = AppSettings()
    #expect(settings.use24Hour == false)
    #expect(settings.showSeconds == true)
    #expect(settings.useCelsius == false)
    #expect(settings.windowLevel == .normal)
    #expect(settings.useAutoLocation == true)
}

@Test func settingsPersistence() {
    let defaults = UserDefaults(suiteName: "test")!
    defaults.removePersistentDomain(forName: "test")

    var settings = AppSettings(defaults: defaults)
    settings.use24Hour = true
    settings.showSeconds = false

    let reloaded = AppSettings(defaults: defaults)
    #expect(reloaded.use24Hour == true)
    #expect(reloaded.showSeconds == false)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsTests`
Expected: FAIL - module not found

**Step 3: Write minimal implementation**

Create `MacClock/Models/AppSettings.swift`:
```swift
import Foundation
import SwiftUI

enum WindowLevel: String, CaseIterable {
    case normal = "Normal"
    case floating = "Floating"
    case desktop = "Desktop"
}

@Observable
final class AppSettings {
    private let defaults: UserDefaults

    var use24Hour: Bool {
        didSet { defaults.set(use24Hour, forKey: "use24Hour") }
    }

    var showSeconds: Bool {
        didSet { defaults.set(showSeconds, forKey: "showSeconds") }
    }

    var useCelsius: Bool {
        didSet { defaults.set(useCelsius, forKey: "useCelsius") }
    }

    var windowLevel: WindowLevel {
        didSet { defaults.set(windowLevel.rawValue, forKey: "windowLevel") }
    }

    var useAutoLocation: Bool {
        didSet { defaults.set(useAutoLocation, forKey: "useAutoLocation") }
    }

    var manualLocationName: String {
        didSet { defaults.set(manualLocationName, forKey: "manualLocationName") }
    }

    var manualLatitude: Double {
        didSet { defaults.set(manualLatitude, forKey: "manualLatitude") }
    }

    var manualLongitude: Double {
        didSet { defaults.set(manualLongitude, forKey: "manualLongitude") }
    }

    var customBackgroundPath: String? {
        didSet { defaults.set(customBackgroundPath, forKey: "customBackgroundPath") }
    }

    var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: "launchAtLogin") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.use24Hour = defaults.bool(forKey: "use24Hour")
        self.showSeconds = defaults.object(forKey: "showSeconds") as? Bool ?? true
        self.useCelsius = defaults.bool(forKey: "useCelsius")
        self.windowLevel = WindowLevel(rawValue: defaults.string(forKey: "windowLevel") ?? "") ?? .normal
        self.useAutoLocation = defaults.object(forKey: "useAutoLocation") as? Bool ?? true
        self.manualLocationName = defaults.string(forKey: "manualLocationName") ?? ""
        self.manualLatitude = defaults.double(forKey: "manualLatitude")
        self.manualLongitude = defaults.double(forKey: "manualLongitude")
        self.customBackgroundPath = defaults.string(forKey: "customBackgroundPath")
        self.launchAtLogin = defaults.bool(forKey: "launchAtLogin")
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/AppSettings.swift MacClockTests/AppSettingsTests.swift
git commit -m "feat: add AppSettings model with UserDefaults persistence"
```

---

## Task 4: Create WeatherData Model

**Files:**
- Create: `MacClock/Models/WeatherData.swift`
- Create: `MacClockTests/WeatherDataTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/WeatherDataTests.swift`:
```swift
import Testing
@testable import MacClock

@Test func decodeOpenMeteoResponse() throws {
    let json = """
    {
        "current": {
            "temperature_2m": 72.5,
            "weather_code": 1
        },
        "daily": {
            "sunrise": ["2026-01-28T06:45"],
            "sunset": ["2026-01-28T17:30"]
        }
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
    #expect(response.current.temperature == 72.5)
    #expect(response.current.weatherCode == 1)
    #expect(response.daily.sunrise.first == "2026-01-28T06:45")
}

@Test func weatherCodeToSFSymbol() {
    #expect(WeatherCondition.fromCode(0).sfSymbol == "sun.max.fill")
    #expect(WeatherCondition.fromCode(3).sfSymbol == "cloud.fill")
    #expect(WeatherCondition.fromCode(61).sfSymbol == "cloud.rain.fill")
    #expect(WeatherCondition.fromCode(71).sfSymbol == "cloud.snow.fill")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WeatherDataTests`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `MacClock/Models/WeatherData.swift`:
```swift
import Foundation

struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weatherCode: Int

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
    }
}

struct DailyWeather: Codable {
    let sunrise: [String]
    let sunset: [String]
}

struct WeatherData {
    let temperature: Double
    let condition: WeatherCondition
    let locationName: String
    let sunrise: Date
    let sunset: Date
}

enum WeatherCondition {
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

**Step 4: Run test to verify it passes**

Run: `swift test --filter WeatherDataTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/WeatherData.swift MacClockTests/WeatherDataTests.swift
git commit -m "feat: add WeatherData model with Open-Meteo response parsing"
```

---

## Task 5: Create WeatherService

**Files:**
- Create: `MacClock/Services/WeatherService.swift`
- Create: `MacClockTests/WeatherServiceTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/WeatherServiceTests.swift`:
```swift
import Testing
@testable import MacClock

@Test func buildWeatherURL() {
    let service = WeatherService()
    let url = service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: false)

    #expect(url.absoluteString.contains("latitude=37.7749"))
    #expect(url.absoluteString.contains("longitude=-122.4194"))
    #expect(url.absoluteString.contains("temperature_unit=fahrenheit"))
}

@Test func buildWeatherURLCelsius() {
    let service = WeatherService()
    let url = service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: true)

    #expect(url.absoluteString.contains("temperature_unit=celsius"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WeatherServiceTests`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `MacClock/Services/WeatherService.swift`:
```swift
import Foundation

actor WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private var cachedWeather: WeatherData?
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 30 * 60 // 30 minutes

    func buildURL(latitude: Double, longitude: Double, useCelsius: Bool) -> URL {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "sunrise,sunset"),
            URLQueryItem(name: "temperature_unit", value: useCelsius ? "celsius" : "fahrenheit"),
            URLQueryItem(name: "timezone", value: "auto")
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

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        let weather = WeatherData(
            temperature: response.current.temperature,
            condition: WeatherCondition.fromCode(response.current.weatherCode),
            locationName: locationName,
            sunrise: formatter.date(from: response.daily.sunrise.first ?? "") ?? Date(),
            sunset: formatter.date(from: response.daily.sunset.first ?? "") ?? Date()
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

**Step 4: Run test to verify it passes**

Run: `swift test --filter WeatherServiceTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Services/WeatherService.swift MacClockTests/WeatherServiceTests.swift
git commit -m "feat: add WeatherService for Open-Meteo API"
```

---

## Task 6: Create LocationService

**Files:**
- Create: `MacClock/Services/LocationService.swift`

**Step 1: Create the LocationService**

Create `MacClock/Services/LocationService.swift`:
```swift
import Foundation
import CoreLocation

@Observable
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    var currentLocation: CLLocation?
    var locationName: String = ""
    var error: Error?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    func reverseGeocode(location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.first?.locality ?? placemarks.first?.name ?? "Unknown"
    }

    func geocodeCity(name: String) async throws -> (latitude: Double, longitude: Double, name: String) {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(name)
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw LocationError.notFound
        }
        let displayName = placemark.locality ?? placemark.name ?? name
        return (location.coordinate.latitude, location.coordinate.longitude, displayName)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Trigger UI update via @Observable
    }
}

enum LocationError: Error {
    case notFound
    case permissionDenied
}
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Services/LocationService.swift
git commit -m "feat: add LocationService for CoreLocation integration"
```

---

## Task 7: Create BackgroundManager

**Files:**
- Create: `MacClock/Services/BackgroundManager.swift`
- Create: `MacClockTests/BackgroundManagerTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/BackgroundManagerTests.swift`:
```swift
import Testing
@testable import MacClock

@Test func timeOfDayCalculation() {
    let calendar = Calendar.current
    let sunrise = calendar.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!
    let sunset = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!

    let manager = BackgroundManager()

    // Test dawn (5:45 - before sunrise)
    let dawnTime = calendar.date(bySettingHour: 5, minute: 50, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: dawnTime, sunrise: sunrise, sunset: sunset) == .dawn)

    // Test day (12:00)
    let dayTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: dayTime, sunrise: sunrise, sunset: sunset) == .day)

    // Test dusk (17:45 - after sunset but within 1 hour)
    let duskTime = calendar.date(bySettingHour: 17, minute: 45, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: duskTime, sunrise: sunrise, sunset: sunset) == .dusk)

    // Test night (22:00)
    let nightTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
    #expect(manager.timeOfDay(at: nightTime, sunrise: sunrise, sunset: sunset) == .night)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter BackgroundManagerTests`
Expected: FAIL

**Step 3: Write minimal implementation**

Create `MacClock/Services/BackgroundManager.swift`:
```swift
import Foundation
import SwiftUI
import AppKit

enum TimeOfDay: String, CaseIterable {
    case dawn
    case day
    case dusk
    case night

    var defaultImageName: String {
        switch self {
        case .dawn: return "bg_dawn"
        case .day: return "bg_day"
        case .dusk: return "bg_dusk"
        case .night: return "bg_night"
        }
    }
}

@Observable
final class BackgroundManager {
    var currentTimeOfDay: TimeOfDay = .day
    var currentImage: NSImage?

    private var customImagePath: String?
    private var customFolderImages: [URL] = []

    func timeOfDay(at date: Date, sunrise: Date, sunset: Date) -> TimeOfDay {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute

        let sunriseHour = calendar.component(.hour, from: sunrise)
        let sunriseMinute = calendar.component(.minute, from: sunrise)
        let sunriseMinutes = sunriseHour * 60 + sunriseMinute

        let sunsetHour = calendar.component(.hour, from: sunset)
        let sunsetMinute = calendar.component(.minute, from: sunset)
        let sunsetMinutes = sunsetHour * 60 + sunsetMinute

        // Dawn: 1 hour before sunrise to sunrise
        if currentMinutes >= sunriseMinutes - 60 && currentMinutes < sunriseMinutes {
            return .dawn
        }
        // Day: sunrise to 1 hour before sunset
        if currentMinutes >= sunriseMinutes && currentMinutes < sunsetMinutes - 60 {
            return .day
        }
        // Dusk: 1 hour before sunset to 1 hour after sunset
        if currentMinutes >= sunsetMinutes - 60 && currentMinutes < sunsetMinutes + 60 {
            return .dusk
        }
        // Night: everything else
        return .night
    }

    func updateBackground(sunrise: Date, sunset: Date, customPath: String?) {
        currentTimeOfDay = timeOfDay(at: Date(), sunrise: sunrise, sunset: sunset)

        if let path = customPath, !path.isEmpty {
            loadCustomImage(from: path)
        } else {
            loadBundledImage(for: currentTimeOfDay)
        }
    }

    private func loadCustomImage(from path: String) {
        let url = URL(fileURLWithPath: path)
        var isDirectory: ObjCBool = false

        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Load random image from folder
                loadRandomImageFromFolder(url)
            } else {
                // Load single image
                currentImage = NSImage(contentsOf: url)
            }
        }
    }

    private func loadRandomImageFromFolder(_ folderURL: URL) {
        let imageExtensions = ["jpg", "jpeg", "png", "heic"]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil
        ) else { return }

        let images = contents.filter { imageExtensions.contains($0.pathExtension.lowercased()) }
        if let randomImage = images.randomElement() {
            currentImage = NSImage(contentsOf: randomImage)
        }
    }

    private func loadBundledImage(for timeOfDay: TimeOfDay) {
        // Load from asset catalog or bundled resources
        if let image = NSImage(named: timeOfDay.defaultImageName) {
            currentImage = image
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter BackgroundManagerTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Services/BackgroundManager.swift MacClockTests/BackgroundManagerTests.swift
git commit -m "feat: add BackgroundManager for time-based backgrounds"
```

---

## Task 8: Create ClockView

**Files:**
- Create: `MacClock/Views/ClockView.swift`

**Step 1: Create ClockView**

Create `MacClock/Views/ClockView.swift`:
```swift
import SwiftUI

struct ClockView: View {
    let settings: AppSettings

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            // Time display
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(timeString)
                    .font(.custom("DSEG7Classic-Bold", size: 96))
                    .foregroundStyle(.white)

                Text(amPmString)
                    .font(.custom("DSEG7Classic-Bold", size: 32))
                    .foregroundStyle(.white)
                    .padding(.leading, 8)
            }

            if settings.showSeconds {
                Text(secondsString)
                    .font(.custom("DSEG7Classic-Bold", size: 36))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Date display
            Text(dateString)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.use24Hour ? "HH:mm" : "h:mm"
        return formatter.string(from: currentTime)
    }

    private var amPmString: String {
        if settings.use24Hour { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: currentTime)
    }

    private var secondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = ":ss"
        return formatter.string(from: currentTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    ClockView(settings: AppSettings())
        .frame(width: 480, height: 320)
        .background(.black)
}
```

**Step 2: Verify it compiles and preview works**

Run: `swift build`
Open in Xcode, check preview renders correctly.

**Step 3: Commit**

```bash
git add MacClock/Views/ClockView.swift
git commit -m "feat: add ClockView with digital time display"
```

---

## Task 9: Create WeatherView

**Files:**
- Create: `MacClock/Views/WeatherView.swift`

**Step 1: Create WeatherView**

Create `MacClock/Views/WeatherView.swift`:
```swift
import SwiftUI

struct WeatherView: View {
    let weather: WeatherData?
    let useCelsius: Bool

    var body: some View {
        if let weather = weather {
            HStack(spacing: 6) {
                Image(systemName: weather.condition.sfSymbol)
                    .font(.system(size: 18))

                Text(temperatureString(weather.temperature))
                    .font(.system(size: 18, weight: .medium))

                Text(weather.locationName)
                    .font(.system(size: 14))
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                Text("—")
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func temperatureString(_ temp: Double) -> String {
        let rounded = Int(temp.rounded())
        return "\(rounded)°\(useCelsius ? "C" : "F")"
    }
}

#Preview {
    WeatherView(
        weather: WeatherData(
            temperature: 72,
            condition: .clear,
            locationName: "San Francisco",
            sunrise: Date(),
            sunset: Date()
        ),
        useCelsius: false
    )
    .padding()
    .background(.black)
}
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/WeatherView.swift
git commit -m "feat: add WeatherView component"
```

---

## Task 10: Create Main ContentView

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Update MacClockApp with full ContentView**

Update `MacClock/MacClockApp.swift`:
```swift
import SwiftUI

@main
struct MacClockApp: App {
    @State private var settings = AppSettings()
    @State private var weatherService = WeatherService()
    @State private var locationService = LocationService()
    @State private var backgroundManager = BackgroundManager()

    var body: some Scene {
        WindowGroup {
            MainClockView(
                settings: settings,
                weatherService: weatherService,
                locationService: locationService,
                backgroundManager: backgroundManager
            )
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 320)
    }
}

struct MainClockView: View {
    let settings: AppSettings
    let weatherService: WeatherService
    let locationService: LocationService
    let backgroundManager: BackgroundManager

    @State private var weather: WeatherData?
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Background
            if let image = backgroundManager.currentImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.black
            }

            // Gradient overlay for readability
            LinearGradient(
                colors: [.black.opacity(0.3), .clear, .black.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            VStack {
                // Top bar: weather + settings
                HStack {
                    WeatherView(weather: weather, useCelsius: settings.useCelsius)
                    Spacer()
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Spacer()

                // Clock
                ClockView(settings: settings)

                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, locationService: locationService)
        }
        .task {
            await loadWeather()
        }
    }

    private func loadWeather() async {
        do {
            let location: (lat: Double, lon: Double, name: String)

            if settings.useAutoLocation {
                locationService.requestPermission()
                let clLocation = try await locationService.requestLocation()
                let name = try await locationService.reverseGeocode(location: clLocation)
                location = (clLocation.coordinate.latitude, clLocation.coordinate.longitude, name)
            } else {
                location = (settings.manualLatitude, settings.manualLongitude, settings.manualLocationName)
            }

            weather = try await weatherService.fetchWeather(
                latitude: location.lat,
                longitude: location.lon,
                locationName: location.name,
                useCelsius: settings.useCelsius
            )

            if let weather = weather {
                backgroundManager.updateBackground(
                    sunrise: weather.sunrise,
                    sunset: weather.sunset,
                    customPath: settings.customBackgroundPath
                )
            }
        } catch {
            print("Weather error: \(error)")
        }
    }
}
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: Build succeeds (SettingsView placeholder needed)

**Step 3: Commit**

```bash
git add MacClock/MacClockApp.swift
git commit -m "feat: integrate all components in MainClockView"
```

---

## Task 11: Create SettingsView

**Files:**
- Create: `MacClock/Views/SettingsView.swift`

**Step 1: Create SettingsView**

Create `MacClock/Views/SettingsView.swift`:
```swift
import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let locationService: LocationService
    @Environment(\.dismiss) private var dismiss

    @State private var citySearch = ""
    @State private var searchError: String?

    var body: some View {
        Form {
            Section("Display") {
                Toggle("24-Hour Time", isOn: $settings.use24Hour)
                Toggle("Show Seconds", isOn: $settings.showSeconds)
                Picker("Temperature", selection: $settings.useCelsius) {
                    Text("°F").tag(false)
                    Text("°C").tag(true)
                }
                .pickerStyle(.segmented)
            }

            Section("Window") {
                Picker("Behavior", selection: $settings.windowLevel) {
                    ForEach(WindowLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section("Location") {
                Toggle("Auto-detect Location", isOn: $settings.useAutoLocation)

                if !settings.useAutoLocation {
                    HStack {
                        TextField("City name", text: $citySearch)
                            .textFieldStyle(.roundedBorder)

                        Button("Search") {
                            Task { await searchCity() }
                        }
                    }

                    if !settings.manualLocationName.isEmpty {
                        Text("Current: \(settings.manualLocationName)")
                            .foregroundStyle(.secondary)
                    }

                    if let error = searchError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }

            Section("Background") {
                HStack {
                    Text(settings.customBackgroundPath ?? "Default (time-based)")
                        .foregroundStyle(settings.customBackgroundPath == nil ? .secondary : .primary)

                    Spacer()

                    Button("Choose...") {
                        selectCustomBackground()
                    }

                    if settings.customBackgroundPath != nil {
                        Button("Reset") {
                            settings.customBackgroundPath = nil
                        }
                    }
                }
            }

            Section("System") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 450)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func searchCity() async {
        do {
            searchError = nil
            let result = try await locationService.geocodeCity(name: citySearch)
            settings.manualLatitude = result.latitude
            settings.manualLongitude = result.longitude
            settings.manualLocationName = result.name
            citySearch = ""
        } catch {
            searchError = "City not found"
        }
    }

    private func selectCustomBackground() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .folder]

        if panel.runModal() == .OK {
            settings.customBackgroundPath = panel.url?.path
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

#Preview {
    SettingsView(settings: AppSettings(), locationService: LocationService())
}
```

**Step 2: Verify it compiles**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat: add SettingsView with all preferences"
```

---

## Task 12: Add WindowManager for Window Level Control

**Files:**
- Create: `MacClock/Utilities/WindowManager.swift`
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Create WindowManager**

Create `MacClock/Utilities/WindowManager.swift`:
```swift
import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let windowLevel: WindowLevel
    let onWindow: ((NSWindow) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                applyWindowLevel(window)
                onWindow?(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                applyWindowLevel(window)
            }
        }
    }

    private func applyWindowLevel(_ window: NSWindow) {
        switch windowLevel {
        case .normal:
            window.level = .normal
            window.collectionBehavior = [.managed, .participatesInCycle]
        case .floating:
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        case .desktop:
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        }
    }
}

extension View {
    func windowLevel(_ level: WindowLevel, onWindow: ((NSWindow) -> Void)? = nil) -> some View {
        background(WindowAccessor(windowLevel: level, onWindow: onWindow))
    }
}
```

**Step 2: Apply to MainClockView**

Update MainClockView in `MacClock/MacClockApp.swift`, add after `.sheet`:
```swift
.windowLevel(settings.windowLevel)
```

**Step 3: Verify it compiles and window level changes**

Run the app, change window level in settings, verify behavior changes.

**Step 4: Commit**

```bash
git add MacClock/Utilities/WindowManager.swift MacClock/MacClockApp.swift
git commit -m "feat: add configurable window level support"
```

---

## Task 13: Add Bundled Background Images

**Files:**
- Create: `MacClock/Resources/Backgrounds/bg_dawn.jpg`
- Create: `MacClock/Resources/Backgrounds/bg_day.jpg`
- Create: `MacClock/Resources/Backgrounds/bg_dusk.jpg`
- Create: `MacClock/Resources/Backgrounds/bg_night.jpg`
- Modify: Asset catalog or resource bundle

**Step 1: Source royalty-free images**

Download from Unsplash/Pexels:
- Dawn: Soft sunrise colors, pink/orange sky
- Day: Blue sky with landscape (like the Alarm Clock HD screenshot)
- Dusk: Sunset colors, warm orange/red
- Night: Dark sky with stars or city lights

Save to `MacClock/Resources/Backgrounds/`

**Step 2: Add to Xcode project / Asset catalog**

For SPM, ensure resources are copied:
```swift
// In Package.swift, update target:
.executableTarget(
    name: "MacClock",
    resources: [
        .copy("Resources/Backgrounds"),
        .copy("Resources/Fonts"),
        .copy("Info.plist")
    ],
    path: "MacClock"
)
```

**Step 3: Update BackgroundManager to load bundled images**

Update `loadBundledImage` in BackgroundManager:
```swift
private func loadBundledImage(for timeOfDay: TimeOfDay) {
    let imageName = timeOfDay.defaultImageName
    if let url = Bundle.main.url(forResource: imageName, withExtension: "jpg", subdirectory: "Backgrounds"),
       let image = NSImage(contentsOf: url) {
        currentImage = image
    } else if let image = NSImage(named: imageName) {
        currentImage = image
    }
}
```

**Step 4: Verify backgrounds load correctly**

Run app at different simulated times, verify correct backgrounds appear.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add bundled time-based background images"
```

---

## Task 14: Add Window Position Persistence

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`
- Modify: `MacClock/Utilities/WindowManager.swift`

**Step 1: Add window frame to AppSettings**

Add to `AppSettings.swift`:
```swift
var windowFrame: NSRect {
    get {
        let x = defaults.double(forKey: "windowX")
        let y = defaults.double(forKey: "windowY")
        let w = defaults.double(forKey: "windowWidth")
        let h = defaults.double(forKey: "windowHeight")
        if w > 0 && h > 0 {
            return NSRect(x: x, y: y, width: w, height: h)
        }
        return .zero
    }
    set {
        defaults.set(newValue.origin.x, forKey: "windowX")
        defaults.set(newValue.origin.y, forKey: "windowY")
        defaults.set(newValue.width, forKey: "windowWidth")
        defaults.set(newValue.height, forKey: "windowHeight")
    }
}
```

**Step 2: Save/restore in WindowAccessor**

Update WindowAccessor's `onWindow` callback usage in MainClockView:
```swift
.windowLevel(settings.windowLevel) { window in
    // Restore saved frame
    let savedFrame = settings.windowFrame
    if savedFrame != .zero {
        window.setFrame(savedFrame, display: true)
    }

    // Save frame on move/resize
    NotificationCenter.default.addObserver(
        forName: NSWindow.didMoveNotification,
        object: window,
        queue: .main
    ) { _ in
        settings.windowFrame = window.frame
    }

    NotificationCenter.default.addObserver(
        forName: NSWindow.didResizeNotification,
        object: window,
        queue: .main
    ) { _ in
        settings.windowFrame = window.frame
    }
}
```

**Step 3: Verify position persists**

Move/resize window, restart app, verify it restores position.

**Step 4: Commit**

```bash
git add MacClock/Models/AppSettings.swift MacClock/MacClockApp.swift
git commit -m "feat: persist window position and size"
```

---

## Task 15: Add Weather Refresh Timer

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add periodic weather refresh**

In MainClockView, add a timer for weather refresh:
```swift
@State private var weatherTimer: Timer?

// In body, after .task:
.onAppear {
    weatherTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { _ in
        Task { await loadWeather() }
    }
}
.onDisappear {
    weatherTimer?.invalidate()
}
```

**Step 2: Verify weather refreshes**

Run app, check weather updates (can temporarily shorten interval for testing).

**Step 3: Commit**

```bash
git add MacClock/MacClockApp.swift
git commit -m "feat: add periodic weather refresh every 30 minutes"
```

---

## Task 16: Final Polish and Testing

**Step 1: Run full test suite**

Run: `swift test`
Expected: All tests pass

**Step 2: Manual testing checklist**

- [ ] Clock displays and updates every second
- [ ] 12/24 hour toggle works
- [ ] Seconds show/hide toggle works
- [ ] Weather displays with icon and temperature
- [ ] °F/°C toggle works
- [ ] Location auto-detect works (with permission)
- [ ] Manual city search works
- [ ] Background changes based on time of day
- [ ] Custom background selection works
- [ ] Window level (normal/floating/desktop) works
- [ ] Window position persists across restarts
- [ ] Launch at login toggle works
- [ ] Settings gear opens settings panel

**Step 3: Fix any issues found**

Address bugs discovered during manual testing.

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: final polish and testing complete"
```

---

## Summary

| Task | Description | Files |
|------|-------------|-------|
| 1 | Create Xcode project | MacClockApp.swift, Package.swift |
| 2 | Add DSEG font | Resources/Fonts, Info.plist |
| 3 | AppSettings model | Models/AppSettings.swift |
| 4 | WeatherData model | Models/WeatherData.swift |
| 5 | WeatherService | Services/WeatherService.swift |
| 6 | LocationService | Services/LocationService.swift |
| 7 | BackgroundManager | Services/BackgroundManager.swift |
| 8 | ClockView | Views/ClockView.swift |
| 9 | WeatherView | Views/WeatherView.swift |
| 10 | MainClockView integration | MacClockApp.swift |
| 11 | SettingsView | Views/SettingsView.swift |
| 12 | WindowManager | Utilities/WindowManager.swift |
| 13 | Bundled backgrounds | Resources/Backgrounds/ |
| 14 | Window position persistence | AppSettings, WindowManager |
| 15 | Weather refresh timer | MacClockApp.swift |
| 16 | Final testing | All files |
