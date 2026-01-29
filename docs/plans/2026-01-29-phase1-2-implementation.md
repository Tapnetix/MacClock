# MacClock Phase 1 & 2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add color themes, auto-dim, background crossfade (Phase 1), and analog/flip clock styles with auto theme switching (Phase 2).

**Architecture:** Extend AppSettings with new theme/dim properties. Create ColorTheme model for preset themes. Add ClockStyle enum and create AnalogClockView/FlipClockView as alternatives to current digital. Use SwiftUI animations for crossfade and dim transitions.

**Tech Stack:** SwiftUI, Combine (for timer-based animations), CoreGraphics (for analog clock drawing)

---

## Phase 1: Core Enhancements

---

### Task 1: Create ColorTheme Model

**Files:**
- Create: `MacClock/Models/ColorTheme.swift`
- Test: `MacClockTests/ColorThemeTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/ColorThemeTests.swift`:

```swift
import Testing
@testable import MacClock

@Suite("ColorTheme Tests")
struct ColorThemeTests {

    @Test("All preset themes exist")
    func allPresetsExist() {
        let themes = ColorTheme.allCases
        #expect(themes.count == 6)
        #expect(themes.contains(.classicWhite))
        #expect(themes.contains(.neonBlue))
        #expect(themes.contains(.warmAmber))
        #expect(themes.contains(.matrixGreen))
        #expect(themes.contains(.sunsetRed))
        #expect(themes.contains(.minimalGray))
    }

    @Test("Classic white has correct colors")
    func classicWhiteColors() {
        let theme = ColorTheme.classicWhite
        #expect(theme.primaryHex == "#FFFFFF")
        #expect(theme.accentHex == "#AAAAAA")
    }

    @Test("Theme display names are correct")
    func displayNames() {
        #expect(ColorTheme.classicWhite.rawValue == "Classic White")
        #expect(ColorTheme.neonBlue.rawValue == "Neon Blue")
        #expect(ColorTheme.warmAmber.rawValue == "Warm Amber")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter ColorThemeTests 2>&1 | head -20`
Expected: FAIL with "cannot find 'ColorTheme' in scope"

**Step 3: Write minimal implementation**

Create `MacClock/Models/ColorTheme.swift`:

```swift
import SwiftUI

enum ColorTheme: String, CaseIterable, Codable {
    case classicWhite = "Classic White"
    case neonBlue = "Neon Blue"
    case warmAmber = "Warm Amber"
    case matrixGreen = "Matrix Green"
    case sunsetRed = "Sunset Red"
    case minimalGray = "Minimal Gray"

    var primaryHex: String {
        switch self {
        case .classicWhite: return "#FFFFFF"
        case .neonBlue: return "#00FFFF"
        case .warmAmber: return "#FFA500"
        case .matrixGreen: return "#00FF00"
        case .sunsetRed: return "#FF6B6B"
        case .minimalGray: return "#CCCCCC"
        }
    }

    var accentHex: String {
        switch self {
        case .classicWhite: return "#AAAAAA"
        case .neonBlue: return "#0066FF"
        case .warmAmber: return "#FFD700"
        case .matrixGreen: return "#006600"
        case .sunsetRed: return "#FF69B4"
        case .minimalGray: return "#888888"
        }
    }

    var primaryColor: Color {
        Color(hex: primaryHex)
    }

    var accentColor: Color {
        Color(hex: accentHex)
    }

    var secondaryOpacity: Double {
        switch self {
        case .classicWhite, .minimalGray: return 0.7
        default: return 0.8
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter ColorThemeTests`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add MacClock/Models/ColorTheme.swift MacClockTests/ColorThemeTests.swift
git commit -m "feat: add ColorTheme model with 6 preset themes"
```

---

### Task 2: Add Theme Setting to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`
- Test: `MacClockTests/AppSettingsTests.swift`

**Step 1: Write the failing test**

Add to `MacClockTests/AppSettingsTests.swift`:

```swift
@Test("Theme defaults to classic white")
func themeDefault() {
    let defaults = UserDefaults(suiteName: "test-theme")!
    defaults.removePersistentDomain(forName: "test-theme")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.colorTheme == .classicWhite)
}

@Test("Theme persists to UserDefaults")
func themePersistence() {
    let defaults = UserDefaults(suiteName: "test-theme-persist")!
    defaults.removePersistentDomain(forName: "test-theme-persist")
    let settings = AppSettings(defaults: defaults)
    settings.colorTheme = .neonBlue
    #expect(defaults.string(forKey: "colorTheme") == "Neon Blue")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsTests 2>&1 | head -20`
Expected: FAIL with "value of type 'AppSettings' has no member 'colorTheme'"

**Step 3: Write minimal implementation**

Add to `MacClock/Models/AppSettings.swift` after `windowOpacity`:

```swift
var colorTheme: ColorTheme {
    didSet { defaults.set(colorTheme.rawValue, forKey: "colorTheme") }
}
```

Add to `init()` after `windowOpacity` initialization:

```swift
self.colorTheme = ColorTheme(rawValue: defaults.string(forKey: "colorTheme") ?? "") ?? .classicWhite
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/AppSettings.swift MacClockTests/AppSettingsTests.swift
git commit -m "feat: add colorTheme setting to AppSettings"
```

---

### Task 3: Apply Theme Colors to ClockView

**Files:**
- Modify: `MacClock/Views/ClockView.swift`

**Step 1: Update ClockView to use theme colors**

Replace hardcoded `.white` colors with theme colors in `MacClock/Views/ClockView.swift`:

```swift
import SwiftUI

struct ClockView: View {
    let settings: AppSettings

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var theme: ColorTheme {
        settings.colorTheme
    }

    private var secondaryFontSize: CGFloat {
        settings.clockFontSize / 3.0
    }

    private var dateFontSize: CGFloat {
        max(14, settings.clockFontSize / 4.8)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Time display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(timeString)
                    .font(.custom("DSEG7Classic-Bold", size: settings.clockFontSize))
                    .foregroundStyle(theme.primaryColor)

                // AM/PM and seconds stacked vertically to the right
                VStack(alignment: .leading, spacing: 0) {
                    if !settings.use24Hour {
                        Text(amPmString)
                            .font(.custom("DSEG7Classic-Bold", size: secondaryFontSize))
                            .foregroundStyle(theme.primaryColor)
                    }

                    if settings.showSeconds {
                        Text(secondsString)
                            .font(.custom("DSEG7Classic-Bold", size: secondaryFontSize))
                            .foregroundStyle(theme.primaryColor.opacity(theme.secondaryOpacity))
                    }
                }
                .alignmentGuide(.lastTextBaseline) { d in d[.lastTextBaseline] }
            }

            // Date display
            Text(dateString)
                .font(.system(size: dateFontSize, weight: .medium))
                .foregroundStyle(theme.accentColor)
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
        formatter.dateFormat = "ss"
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

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/ClockView.swift
git commit -m "feat: apply color theme to ClockView"
```

---

### Task 4: Apply Theme Colors to WeatherView

**Files:**
- Modify: `MacClock/Views/WeatherView.swift`

**Step 1: Read current WeatherView**

First examine the current file to understand its structure.

**Step 2: Update WeatherView to accept theme**

Modify `MacClock/Views/WeatherView.swift` to accept and use ColorTheme:

```swift
import SwiftUI

struct WeatherView: View {
    let weather: WeatherData?
    let useCelsius: Bool
    var theme: ColorTheme = .classicWhite

    var body: some View {
        if let weather = weather {
            HStack(spacing: 8) {
                Image(systemName: weather.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(theme.primaryColor.opacity(0.9))

                Text(temperatureString)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.primaryColor)

                Text(weather.locationName)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accentColor)
            }
        }
    }

    private var temperatureString: String {
        let temp = useCelsius ? weather?.temperatureCelsius : weather?.temperatureFahrenheit
        let unit = useCelsius ? "°C" : "°F"
        if let temp = temp {
            return "\(Int(temp))\(unit)"
        }
        return "--\(unit)"
    }
}
```

**Step 3: Update MainClockView to pass theme to WeatherView**

In `MacClock/MacClockApp.swift`, update the WeatherView call (around line 112):

```swift
WeatherView(weather: weather, useCelsius: settings.useCelsius, theme: settings.colorTheme)
```

**Step 4: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add MacClock/Views/WeatherView.swift MacClock/MacClockApp.swift
git commit -m "feat: apply color theme to WeatherView"
```

---

### Task 5: Add Theme Picker to SettingsView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add theme picker to Display section**

In `MacClock/Views/SettingsView.swift`, add after the "Clock Size" slider in the Display section:

```swift
Picker("Theme", selection: $settings.colorTheme) {
    ForEach(ColorTheme.allCases, id: \.self) { theme in
        Text(theme.rawValue).tag(theme)
    }
}
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: Theme picker appears in Settings, changing it updates clock colors

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat: add theme picker to SettingsView"
```

---

### Task 6: Add Auto-Dim Settings to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`
- Test: `MacClockTests/AppSettingsTests.swift`

**Step 1: Write the failing test**

Add to `MacClockTests/AppSettingsTests.swift`:

```swift
@Test("Auto-dim defaults to off")
func autoDimDefault() {
    let defaults = UserDefaults(suiteName: "test-autodim")!
    defaults.removePersistentDomain(forName: "test-autodim")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.autoDimEnabled == false)
    #expect(settings.autoDimLevel == 0.5)
    #expect(settings.autoDimMode == .sunriseSunset)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsTests 2>&1 | head -20`
Expected: FAIL

**Step 3: Write minimal implementation**

Add to `MacClock/Models/AppSettings.swift`:

After `BackgroundMode` enum, add:

```swift
enum AutoDimMode: String, CaseIterable {
    case sunriseSunset = "Sunrise/Sunset"
    case fixedSchedule = "Fixed Schedule"
    case macOSAppearance = "Follow macOS"
}
```

Add properties after `colorTheme`:

```swift
var autoDimEnabled: Bool {
    didSet { defaults.set(autoDimEnabled, forKey: "autoDimEnabled") }
}

var autoDimLevel: Double {
    didSet { defaults.set(autoDimLevel, forKey: "autoDimLevel") }
}

var autoDimMode: AutoDimMode {
    didSet { defaults.set(autoDimMode.rawValue, forKey: "autoDimMode") }
}

var dimStartHour: Int {
    didSet { defaults.set(dimStartHour, forKey: "dimStartHour") }
}

var dimEndHour: Int {
    didSet { defaults.set(dimEndHour, forKey: "dimEndHour") }
}

var nightTheme: ColorTheme? {
    didSet {
        if let theme = nightTheme {
            defaults.set(theme.rawValue, forKey: "nightTheme")
        } else {
            defaults.removeObject(forKey: "nightTheme")
        }
    }
}
```

Add to `init()`:

```swift
self.autoDimEnabled = defaults.bool(forKey: "autoDimEnabled")
self.autoDimLevel = defaults.object(forKey: "autoDimLevel") as? Double ?? 0.5
self.autoDimMode = AutoDimMode(rawValue: defaults.string(forKey: "autoDimMode") ?? "") ?? .sunriseSunset
self.dimStartHour = defaults.object(forKey: "dimStartHour") as? Int ?? 22
self.dimEndHour = defaults.object(forKey: "dimEndHour") as? Int ?? 7
if let nightThemeRaw = defaults.string(forKey: "nightTheme") {
    self.nightTheme = ColorTheme(rawValue: nightThemeRaw)
} else {
    self.nightTheme = nil
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/AppSettings.swift MacClockTests/AppSettingsTests.swift
git commit -m "feat: add auto-dim settings to AppSettings"
```

---

### Task 7: Create DimManager Service

**Files:**
- Create: `MacClock/Services/DimManager.swift`
- Test: `MacClockTests/DimManagerTests.swift`

**Step 1: Write the failing test**

Create `MacClockTests/DimManagerTests.swift`:

```swift
import Testing
import Foundation
@testable import MacClock

@Suite("DimManager Tests")
struct DimManagerTests {

    @Test("Should dim at night with sunrise/sunset mode")
    func dimAtNight() {
        // 11 PM - should be dimmed
        let calendar = Calendar.current
        let nightTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
        let sunrise = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
        let sunset = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: Date())!

        let shouldDim = DimManager.shouldDim(
            at: nightTime,
            mode: .sunriseSunset,
            sunrise: sunrise,
            sunset: sunset,
            dimStartHour: 22,
            dimEndHour: 7
        )
        #expect(shouldDim == true)
    }

    @Test("Should not dim during day with sunrise/sunset mode")
    func noDimDuringDay() {
        let calendar = Calendar.current
        let dayTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let sunrise = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
        let sunset = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: Date())!

        let shouldDim = DimManager.shouldDim(
            at: dayTime,
            mode: .sunriseSunset,
            sunrise: sunrise,
            sunset: sunset,
            dimStartHour: 22,
            dimEndHour: 7
        )
        #expect(shouldDim == false)
    }

    @Test("Should dim with fixed schedule")
    func dimWithFixedSchedule() {
        let calendar = Calendar.current
        let lateNight = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: Date())!

        let shouldDim = DimManager.shouldDim(
            at: lateNight,
            mode: .fixedSchedule,
            sunrise: nil,
            sunset: nil,
            dimStartHour: 22,
            dimEndHour: 7
        )
        #expect(shouldDim == true)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DimManagerTests 2>&1 | head -20`
Expected: FAIL with "cannot find 'DimManager' in scope"

**Step 3: Write minimal implementation**

Create `MacClock/Services/DimManager.swift`:

```swift
import Foundation
import AppKit

@Observable
final class DimManager {
    private(set) var isDimmed: Bool = false
    private(set) var currentDimLevel: Double = 1.0

    private var appearanceObserver: NSObjectProtocol?

    init() {
        setupAppearanceObserver()
    }

    deinit {
        if let observer = appearanceObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    private func setupAppearanceObserver() {
        appearanceObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange
        }
    }

    func update(
        settings: AppSettings,
        sunrise: Date?,
        sunset: Date?
    ) {
        guard settings.autoDimEnabled else {
            isDimmed = false
            currentDimLevel = 1.0
            return
        }

        let shouldDimNow = Self.shouldDim(
            at: Date(),
            mode: settings.autoDimMode,
            sunrise: sunrise,
            sunset: sunset,
            dimStartHour: settings.dimStartHour,
            dimEndHour: settings.dimEndHour
        )

        isDimmed = shouldDimNow
        currentDimLevel = shouldDimNow ? settings.autoDimLevel : 1.0
    }

    static func shouldDim(
        at date: Date,
        mode: AutoDimMode,
        sunrise: Date?,
        sunset: Date?,
        dimStartHour: Int,
        dimEndHour: Int
    ) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)

        switch mode {
        case .sunriseSunset:
            guard let sunrise = sunrise, let sunset = sunset else {
                return false
            }
            // Dim if before sunrise or after sunset
            return date < sunrise || date > sunset

        case .fixedSchedule:
            // Handle overnight schedule (e.g., 22:00 - 07:00)
            if dimStartHour > dimEndHour {
                return hour >= dimStartHour || hour < dimEndHour
            } else {
                return hour >= dimStartHour && hour < dimEndHour
            }

        case .macOSAppearance:
            let appearance = NSApp.effectiveAppearance
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter DimManagerTests`
Expected: PASS (3 tests)

**Step 5: Commit**

```bash
git add MacClock/Services/DimManager.swift MacClockTests/DimManagerTests.swift
git commit -m "feat: add DimManager service for auto-dim logic"
```

---

### Task 8: Integrate DimManager into MainClockView

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add DimManager state and apply dimming**

In `MacClock/MacClockApp.swift`:

Add state in MainClockView:

```swift
@State private var dimManager = DimManager()
@State private var dimTimer: Timer?
```

Add computed property for effective theme:

```swift
private var effectiveTheme: ColorTheme {
    if dimManager.isDimmed, let nightTheme = settings.nightTheme {
        return nightTheme
    }
    return settings.colorTheme
}
```

Update the content VStack to apply dim level:

```swift
// Content
VStack {
    // Top bar: weather + settings
    HStack {
        WeatherView(weather: weather, useCelsius: settings.useCelsius, theme: effectiveTheme)
        Spacer()
        Button {
            showSettings.toggle()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18))
                .foregroundStyle(effectiveTheme.primaryColor.opacity(0.7))
        }
        .buttonStyle(.plain)
    }
    .padding()

    Spacer()

    // Clock
    ClockView(settings: settings, theme: effectiveTheme)

    Spacer()
}
.opacity(dimManager.currentDimLevel)
.animation(.easeInOut(duration: 2.0), value: dimManager.currentDimLevel)
```

Update ClockView to accept theme parameter (in ClockView.swift, change init):

```swift
let settings: AppSettings
var theme: ColorTheme = .classicWhite
```

And update the preview and all usages.

In onAppear, add dim timer setup:

```swift
// Update dim state every minute
dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
dimTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
    dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
}
```

In onDisappear, invalidate:

```swift
dimTimer?.invalidate()
```

Add onChange for settings that affect dimming:

```swift
.onChange(of: settings.autoDimEnabled) { _, _ in
    dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
}
.onChange(of: settings.autoDimMode) { _, _ in
    dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/MacClockApp.swift MacClock/Views/ClockView.swift
git commit -m "feat: integrate DimManager for auto-dim functionality"
```

---

### Task 9: Add Auto-Dim Settings UI

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add Appearance section with auto-dim controls**

In `MacClock/Views/SettingsView.swift`, add a new section after "Display":

```swift
Section("Appearance") {
    Toggle("Auto-Dim", isOn: $settings.autoDimEnabled)

    if settings.autoDimEnabled {
        Picker("Trigger", selection: $settings.autoDimMode) {
            ForEach(AutoDimMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }

        if settings.autoDimMode == .fixedSchedule {
            Picker("Dim at", selection: $settings.dimStartHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(formatHour(hour)).tag(hour)
                }
            }

            Picker("Brighten at", selection: $settings.dimEndHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(formatHour(hour)).tag(hour)
                }
            }
        }

        VStack(alignment: .leading) {
            Text("Dim Level: \(Int(settings.autoDimLevel * 100))%")
            Slider(value: $settings.autoDimLevel, in: 0.2...0.8, step: 0.1)
        }

        Picker("Night Theme", selection: Binding(
            get: { settings.nightTheme ?? .warmAmber },
            set: { settings.nightTheme = $0 }
        )) {
            Text("None").tag(Optional<ColorTheme>.none)
            ForEach(ColorTheme.allCases, id: \.self) { theme in
                Text(theme.rawValue).tag(Optional(theme))
            }
        }
    }
}
```

Add helper function:

```swift
private func formatHour(_ hour: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h a"
    let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
    return formatter.string(from: date)
}
```

Update frame height to accommodate new section:

```swift
.frame(width: 350, height: 520)
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: Auto-dim settings appear, toggling shows/hides options

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat: add auto-dim settings UI"
```

---

### Task 10: Add Background Crossfade Animation

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Add crossfade state and animation**

In MainClockView, add state for crossfade:

```swift
@State private var previousBackgroundImage: NSImage?
@State private var backgroundOpacity: Double = 1.0
```

Update `displayedBackgroundImage` to trigger crossfade:

Create a new method to handle background transitions:

```swift
private func transitionToNewBackground(_ newImage: NSImage?) {
    guard let newImage = newImage else { return }

    // Store current as previous
    previousBackgroundImage = displayedBackgroundImage

    // Animate crossfade
    withAnimation(.easeInOut(duration: 1.0)) {
        backgroundOpacity = 0.0
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        // Update to new image
        switch settings.backgroundMode {
        case .nature:
            currentNatureImage = newImage
        default:
            break
        }

        withAnimation(.easeInOut(duration: 1.0)) {
            backgroundOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            previousBackgroundImage = nil
        }
    }
}
```

Update the background ZStack in body:

```swift
ZStack {
    // Previous background (for crossfade)
    if let prevImage = previousBackgroundImage {
        Image(nsImage: prevImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
    }

    // Current background
    if let image = displayedBackgroundImage {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .opacity(backgroundOpacity)
    } else {
        Color.black
    }

    // Gradient overlay...
}
```

Update the nature background timer to use crossfade:

```swift
backgroundTimer = Timer.scheduledTimer(withTimeInterval: settings.backgroundCycleInterval, repeats: true) { _ in
    Task {
        let newImage = await natureService.getNextImage()
        await MainActor.run {
            transitionToNewBackground(newImage)
        }
    }
}
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: Background changes smoothly with crossfade

**Step 3: Commit**

```bash
git add MacClock/MacClockApp.swift
git commit -m "feat: add background crossfade animation"
```

---

## Phase 2: Display Options

---

### Task 11: Add ClockStyle Enum to AppSettings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`
- Test: `MacClockTests/AppSettingsTests.swift`

**Step 1: Write the failing test**

Add to `MacClockTests/AppSettingsTests.swift`:

```swift
@Test("Clock style defaults to digital")
func clockStyleDefault() {
    let defaults = UserDefaults(suiteName: "test-clockstyle")!
    defaults.removePersistentDomain(forName: "test-clockstyle")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.clockStyle == .digital)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsTests 2>&1 | head -20`
Expected: FAIL

**Step 3: Write minimal implementation**

Add enum to `MacClock/Models/AppSettings.swift` after `AutoDimMode`:

```swift
enum ClockStyle: String, CaseIterable {
    case digital = "Digital"
    case analog = "Analog"
    case flip = "Flip Clock"
}
```

Add property after `nightTheme`:

```swift
var clockStyle: ClockStyle {
    didSet { defaults.set(clockStyle.rawValue, forKey: "clockStyle") }
}
```

Add to `init()`:

```swift
self.clockStyle = ClockStyle(rawValue: defaults.string(forKey: "clockStyle") ?? "") ?? .digital
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/AppSettings.swift MacClockTests/AppSettingsTests.swift
git commit -m "feat: add ClockStyle enum to AppSettings"
```

---

### Task 12: Create AnalogClockView

**Files:**
- Create: `MacClock/Views/AnalogClockView.swift`

**Step 1: Create the analog clock view**

Create `MacClock/Views/AnalogClockView.swift`:

```swift
import SwiftUI

struct AnalogClockView: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var clockSize: CGFloat {
        settings.clockFontSize * 2.5
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Clock face
                Circle()
                    .stroke(theme.accentColor.opacity(0.3), lineWidth: 2)
                    .frame(width: clockSize, height: clockSize)

                // Hour markers
                ForEach(0..<12) { index in
                    Rectangle()
                        .fill(theme.accentColor)
                        .frame(width: index % 3 == 0 ? 3 : 1.5,
                               height: index % 3 == 0 ? 12 : 8)
                        .offset(y: -clockSize / 2 + 15)
                        .rotationEffect(.degrees(Double(index) * 30))
                }

                // Hour hand
                ClockHand(
                    length: clockSize * 0.25,
                    width: 4,
                    color: theme.primaryColor
                )
                .rotationEffect(hourAngle)

                // Minute hand
                ClockHand(
                    length: clockSize * 0.35,
                    width: 3,
                    color: theme.primaryColor
                )
                .rotationEffect(minuteAngle)

                // Second hand (if enabled)
                if settings.showSeconds {
                    ClockHand(
                        length: clockSize * 0.4,
                        width: 1,
                        color: theme.accentColor
                    )
                    .rotationEffect(secondAngle)
                }

                // Center dot
                Circle()
                    .fill(theme.primaryColor)
                    .frame(width: 8, height: 8)
            }
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            // Date
            Text(dateString)
                .font(.system(size: max(14, settings.clockFontSize / 4.8), weight: .medium))
                .foregroundStyle(theme.accentColor)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var hourAngle: Angle {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: currentTime) % 12)
        let minute = Double(calendar.component(.minute, from: currentTime))
        return .degrees((hour + minute / 60) * 30)
    }

    private var minuteAngle: Angle {
        let calendar = Calendar.current
        let minute = Double(calendar.component(.minute, from: currentTime))
        let second = Double(calendar.component(.second, from: currentTime))
        return .degrees((minute + second / 60) * 6)
    }

    private var secondAngle: Angle {
        let calendar = Calendar.current
        let second = Double(calendar.component(.second, from: currentTime))
        let nanosecond = Double(calendar.component(.nanosecond, from: currentTime))
        return .degrees((second + nanosecond / 1_000_000_000) * 6)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }
}

struct ClockHand: View {
    let length: CGFloat
    let width: CGFloat
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: width / 2)
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    AnalogClockView(settings: AppSettings())
        .frame(width: 400, height: 400)
        .background(.black)
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/AnalogClockView.swift
git commit -m "feat: add AnalogClockView with smooth sweeping hands"
```

---

### Task 13: Create FlipClockView

**Files:**
- Create: `MacClock/Views/FlipClockView.swift`

**Step 1: Create the flip clock view**

Create `MacClock/Views/FlipClockView.swift`:

```swift
import SwiftUI

struct FlipClockView: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    @State private var currentTime = Date()
    @State private var previousTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var digitSize: CGFloat {
        settings.clockFontSize * 0.9
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                // Hours
                FlipDigitPair(
                    value: hourString,
                    previousValue: previousHourString,
                    size: digitSize,
                    theme: theme
                )

                // Colon
                Text(":")
                    .font(.system(size: digitSize * 0.6, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.primaryColor)
                    .offset(y: -digitSize * 0.05)

                // Minutes
                FlipDigitPair(
                    value: minuteString,
                    previousValue: previousMinuteString,
                    size: digitSize,
                    theme: theme
                )

                // Seconds (if enabled)
                if settings.showSeconds {
                    Text(":")
                        .font(.system(size: digitSize * 0.4, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.primaryColor.opacity(0.7))

                    FlipDigitPair(
                        value: secondString,
                        previousValue: previousSecondString,
                        size: digitSize * 0.6,
                        theme: theme
                    )
                }
            }

            // Date
            Text(dateString)
                .font(.system(size: max(14, settings.clockFontSize / 4.8), weight: .medium))
                .foregroundStyle(theme.accentColor)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .onReceive(timer) { _ in
            previousTime = currentTime
            currentTime = Date()
        }
    }

    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.use24Hour ? "HH" : "hh"
        return formatter.string(from: currentTime)
    }

    private var previousHourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.use24Hour ? "HH" : "hh"
        return formatter.string(from: previousTime)
    }

    private var minuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter.string(from: currentTime)
    }

    private var previousMinuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter.string(from: previousTime)
    }

    private var secondString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: currentTime)
    }

    private var previousSecondString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: previousTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }
}

struct FlipDigitPair: View {
    let value: String
    let previousValue: String
    let size: CGFloat
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 4) {
            FlipDigit(
                digit: String(value.prefix(1)),
                previousDigit: String(previousValue.prefix(1)),
                size: size,
                theme: theme
            )
            FlipDigit(
                digit: String(value.suffix(1)),
                previousDigit: String(previousValue.suffix(1)),
                size: size,
                theme: theme
            )
        }
    }
}

struct FlipDigit: View {
    let digit: String
    let previousDigit: String
    let size: CGFloat
    let theme: ColorTheme

    @State private var isFlipping = false

    var body: some View {
        ZStack {
            // Background card
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.8), Color.black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.65, height: size * 0.9)

            // Split line
            Rectangle()
                .fill(Color.black)
                .frame(width: size * 0.65, height: 2)

            // Digit
            Text(digit)
                .font(.system(size: size * 0.7, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryColor)
        }
        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
        .onChange(of: digit) { oldValue, newValue in
            if oldValue != newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlipping = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFlipping = false
                }
            }
        }
        .rotation3DEffect(
            .degrees(isFlipping ? -10 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
    }
}

#Preview {
    FlipClockView(settings: AppSettings())
        .frame(width: 500, height: 300)
        .background(.black)
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/FlipClockView.swift
git commit -m "feat: add FlipClockView with flip animation"
```

---

### Task 14: Create ClockStyleContainer to Switch Between Styles

**Files:**
- Create: `MacClock/Views/ClockStyleContainer.swift`

**Step 1: Create container view that switches between clock styles**

Create `MacClock/Views/ClockStyleContainer.swift`:

```swift
import SwiftUI

struct ClockStyleContainer: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    var body: some View {
        switch settings.clockStyle {
        case .digital:
            ClockView(settings: settings, theme: theme)
        case .analog:
            AnalogClockView(settings: settings, theme: theme)
        case .flip:
            FlipClockView(settings: settings, theme: theme)
        }
    }
}

#Preview("Digital") {
    let settings = AppSettings()
    settings.clockStyle = .digital
    return ClockStyleContainer(settings: settings)
        .frame(width: 480, height: 320)
        .background(.black)
}

#Preview("Analog") {
    let settings = AppSettings()
    settings.clockStyle = .analog
    return ClockStyleContainer(settings: settings)
        .frame(width: 480, height: 400)
        .background(.black)
}

#Preview("Flip") {
    let settings = AppSettings()
    settings.clockStyle = .flip
    return ClockStyleContainer(settings: settings)
        .frame(width: 500, height: 300)
        .background(.black)
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 3: Commit**

```bash
git add MacClock/Views/ClockStyleContainer.swift
git commit -m "feat: add ClockStyleContainer to switch between clock styles"
```

---

### Task 15: Integrate ClockStyleContainer into MainClockView

**Files:**
- Modify: `MacClock/MacClockApp.swift`

**Step 1: Replace ClockView with ClockStyleContainer**

In `MacClock/MacClockApp.swift`, replace:

```swift
// Clock
ClockView(settings: settings, theme: effectiveTheme)
```

With:

```swift
// Clock
ClockStyleContainer(settings: settings, theme: effectiveTheme)
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: App runs with current clock style

**Step 3: Commit**

```bash
git add MacClock/MacClockApp.swift
git commit -m "feat: integrate ClockStyleContainer into MainClockView"
```

---

### Task 16: Add Clock Style Picker to SettingsView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add style picker to Display section**

In `MacClock/Views/SettingsView.swift`, add at the beginning of the Display section:

```swift
Picker("Clock Style", selection: $settings.clockStyle) {
    ForEach(ClockStyle.allCases, id: \.self) { style in
        Text(style.rawValue).tag(style)
    }
}
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: Style picker appears, changing it switches clock display

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat: add clock style picker to SettingsView"
```

---

### Task 17: Add Auto Theme Switching Settings

**Files:**
- Modify: `MacClock/Models/AppSettings.swift`
- Test: `MacClockTests/AppSettingsTests.swift`

**Step 1: Write the failing test**

Add to `MacClockTests/AppSettingsTests.swift`:

```swift
@Test("Auto theme defaults to disabled")
func autoThemeDefault() {
    let defaults = UserDefaults(suiteName: "test-autotheme")!
    defaults.removePersistentDomain(forName: "test-autotheme")
    let settings = AppSettings(defaults: defaults)
    #expect(settings.autoThemeEnabled == false)
    #expect(settings.dayTheme == .classicWhite)
    #expect(settings.nightThemeAuto == .warmAmber)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppSettingsTests 2>&1 | head -20`
Expected: FAIL

**Step 3: Write minimal implementation**

Add properties to `MacClock/Models/AppSettings.swift` after `clockStyle`:

```swift
var autoThemeEnabled: Bool {
    didSet { defaults.set(autoThemeEnabled, forKey: "autoThemeEnabled") }
}

var dayTheme: ColorTheme {
    didSet { defaults.set(dayTheme.rawValue, forKey: "dayTheme") }
}

var nightThemeAuto: ColorTheme {
    didSet { defaults.set(nightThemeAuto.rawValue, forKey: "nightThemeAuto") }
}

var autoThemeMode: AutoDimMode {
    didSet { defaults.set(autoThemeMode.rawValue, forKey: "autoThemeMode") }
}
```

Add to `init()`:

```swift
self.autoThemeEnabled = defaults.bool(forKey: "autoThemeEnabled")
self.dayTheme = ColorTheme(rawValue: defaults.string(forKey: "dayTheme") ?? "") ?? .classicWhite
self.nightThemeAuto = ColorTheme(rawValue: defaults.string(forKey: "nightThemeAuto") ?? "") ?? .warmAmber
self.autoThemeMode = AutoDimMode(rawValue: defaults.string(forKey: "autoThemeMode") ?? "") ?? .sunriseSunset
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppSettingsTests`
Expected: PASS

**Step 5: Commit**

```bash
git add MacClock/Models/AppSettings.swift MacClockTests/AppSettingsTests.swift
git commit -m "feat: add auto theme switching settings to AppSettings"
```

---

### Task 18: Implement Auto Theme Logic in DimManager

**Files:**
- Modify: `MacClock/Services/DimManager.swift`

**Step 1: Add theme calculation to DimManager**

Add to `DimManager`:

```swift
private(set) var effectiveTheme: ColorTheme = .classicWhite

func update(
    settings: AppSettings,
    sunrise: Date?,
    sunset: Date?
) {
    // Handle auto-dim
    guard settings.autoDimEnabled else {
        isDimmed = false
        currentDimLevel = 1.0
    }

    if settings.autoDimEnabled {
        let shouldDimNow = Self.shouldDim(
            at: Date(),
            mode: settings.autoDimMode,
            sunrise: sunrise,
            sunset: sunset,
            dimStartHour: settings.dimStartHour,
            dimEndHour: settings.dimEndHour
        )

        isDimmed = shouldDimNow
        currentDimLevel = shouldDimNow ? settings.autoDimLevel : 1.0
    }

    // Handle auto-theme
    if settings.autoThemeEnabled {
        let isNight = Self.shouldDim(
            at: Date(),
            mode: settings.autoThemeMode,
            sunrise: sunrise,
            sunset: sunset,
            dimStartHour: settings.dimStartHour,
            dimEndHour: settings.dimEndHour
        )
        effectiveTheme = isNight ? settings.nightThemeAuto : settings.dayTheme
    } else {
        effectiveTheme = settings.colorTheme
    }
}
```

**Step 2: Update MainClockView to use effectiveTheme from DimManager**

In `MacClock/MacClockApp.swift`, update `effectiveTheme` computed property:

```swift
private var effectiveTheme: ColorTheme {
    dimManager.effectiveTheme
}
```

And update the onChange handlers to also trigger on theme settings:

```swift
.onChange(of: settings.autoThemeEnabled) { _, _ in
    dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
}
.onChange(of: settings.colorTheme) { _, _ in
    dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
}
```

**Step 3: Build to verify**

Run: `swift build`
Expected: Build succeeds

**Step 4: Commit**

```bash
git add MacClock/Services/DimManager.swift MacClock/MacClockApp.swift
git commit -m "feat: implement auto theme switching logic in DimManager"
```

---

### Task 19: Add Auto Theme UI to SettingsView

**Files:**
- Modify: `MacClock/Views/SettingsView.swift`

**Step 1: Add auto theme controls to Appearance section**

In the Appearance section of `MacClock/Views/SettingsView.swift`, add after auto-dim controls:

```swift
Divider()

Toggle("Auto Theme Switching", isOn: $settings.autoThemeEnabled)

if settings.autoThemeEnabled {
    Picker("Day Theme", selection: $settings.dayTheme) {
        ForEach(ColorTheme.allCases, id: \.self) { theme in
            Text(theme.rawValue).tag(theme)
        }
    }

    Picker("Night Theme", selection: $settings.nightThemeAuto) {
        ForEach(ColorTheme.allCases, id: \.self) { theme in
            Text(theme.rawValue).tag(theme)
        }
    }

    Picker("Switch at", selection: $settings.autoThemeMode) {
        ForEach(AutoDimMode.allCases, id: \.self) { mode in
            Text(mode.rawValue).tag(mode)
        }
    }
}
```

Also hide the manual theme picker when auto theme is enabled:

```swift
if !settings.autoThemeEnabled {
    Picker("Theme", selection: $settings.colorTheme) {
        ForEach(ColorTheme.allCases, id: \.self) { theme in
            Text(theme.rawValue).tag(theme)
        }
    }
}
```

Update frame height:

```swift
.frame(width: 350, height: 600)
```

**Step 2: Build and test manually**

Run: `swift build && swift run`
Expected: Auto theme controls appear, work correctly

**Step 3: Commit**

```bash
git add MacClock/Views/SettingsView.swift
git commit -m "feat: add auto theme switching UI to SettingsView"
```

---

### Task 20: Final Integration Test and Cleanup

**Step 1: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 2: Build release and test manually**

Run: `./build-app.sh && open MacClock.app`

Test the following:
- [ ] All 6 color themes work
- [ ] Auto-dim works with sunrise/sunset
- [ ] Auto-dim works with fixed schedule
- [ ] Auto-dim works with macOS appearance
- [ ] Background crossfade animation works
- [ ] Digital clock style works
- [ ] Analog clock style works with smooth hands
- [ ] Flip clock style works with flip animation
- [ ] Clock style switching works
- [ ] Auto theme switching works

**Step 3: Commit any final fixes**

```bash
git add -A
git commit -m "chore: phase 1 & 2 complete - themes, auto-dim, clock styles"
```

---

## Summary

**Phase 1 (Tasks 1-10):**
- ColorTheme model with 6 presets
- Theme applied to ClockView and WeatherView
- Theme picker in Settings
- Auto-dim with 3 trigger modes
- DimManager service
- Background crossfade animation

**Phase 2 (Tasks 11-20):**
- ClockStyle enum (digital, analog, flip)
- AnalogClockView with smooth sweeping hands
- FlipClockView with flip animation
- ClockStyleContainer for switching
- Auto theme switching with day/night themes
- All settings UI integrated
