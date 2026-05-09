# MacClock — Project Context for Claude

A native macOS desktop clock app: digital/analog/flip-clock displays, weather, calendar, alarms, world clocks, news ticker, dynamic backgrounds.

## Stack

- **Swift 5.9, SwiftUI, macOS 14+**
- **Swift Package Manager** — `Package.swift` is the source of truth for sources/resources of the app
- **Xcode project (XcodeGen-generated)** — minimal `MacClock.xcodeproj` exists *only* to host an `XCUITest` target; it folder-references the same `MacClock/` directory SPM uses
- **Zero external dependencies** — only Apple frameworks
- **Testing**: Swift Testing (`@Test`, `#expect`, `@Suite`) for unit/snapshot tests; **XCTest/XCUITest** for UI interaction tests
- **AppKit interop** for window level/style, dock icon, NSWorkspace, audio device selection

## Commands

```bash
swift build              # Debug build (SPM)
swift build -c release   # Release build (SPM)
swift test               # Run unit + snapshot tests (Swift Testing, 229+ tests)
./build-app.sh           # Build .app bundle (release + copy resources + Info.plist)
swift run                # Run from terminal (sometimes useful for logs)

make xcodeproj           # (Re)generate MacClock.xcodeproj from project.yml via XcodeGen
make test-ui             # Run XCUITest suite (13 tests) via xcodebuild
```

## Build systems

This project uses **two build systems** intentionally:

- **`Package.swift` (SPM)** — source of truth for the app target's sources and resources. Build with `swift build`. Run unit/snapshot tests with `swift test`.
- **`MacClock.xcodeproj` (XcodeGen)** — generated from `project.yml` via `xcodegen generate`. Two targets: the `MacClock` app (folder-references the same `MacClock/` directory SPM uses) and `MacClockUITests` (XCUITest). Build with `xcodebuild -scheme MacClock -destination 'platform=macOS' build`. Run UI tests with `make test-ui`.

The Xcode project exists because XCUITest is Xcode-only. Sources don't fork: adding a Swift file to `MacClock/` is picked up by both build systems automatically (SPM via `Package.swift`'s implicit globbing, Xcode via XcodeGen folder reference + regenerate).

`MacClock.xcodeproj/` is **gitignored** — only `project.yml` is checked in. After cloning, run `make xcodeproj` (or `xcodegen generate`) to produce the project. After editing `project.yml`, regenerate.

A small `Bundle.module` shim in `MacClock/Utilities/BundleCompat.swift` (guarded by `#if !SWIFT_PACKAGE`) lets code that uses `Bundle.module` for resource lookup compile under both build systems. Under SPM, the synthesised `Bundle.module` points at the resource bundle. Under Xcode, the shim aliases it to `Bundle.main`.

The UITests use a `--test-mode` launch argument (handled in `MacClockApp.makeUserDefaults()`) that swaps in a throwaway `UserDefaults(suiteName: "com.tapnetix.MacClock.UITests")` and clears it on each launch, so tests never collide with the developer's saved settings.

## Layout

```
MacClock/
  MacClockApp.swift        @main entry. WindowGroup + Settings window. Hosts MainClockView.
  Models/                  Plain value types (AppSettings, WeatherData, Alarm, ICalFeed, ...)
  Services/                Network, location, calendar, audio, dock icon, dimming
  Views/                   SwiftUI views — clock styles, weather, alarms, settings, ticker
  Resources/Backgrounds/   Bundled JPEGs for time-of-day backgrounds
  Resources/Fonts/         DSEG7 LCD font (registered at app start via CTFontManager)
MacClockTests/             Swift Testing suites
build-app.sh               Wraps swift build -c release into a .app bundle
```

`AppSettings` (`@Observable`) is the central state container — persisted to UserDefaults, observed throughout the view tree.

## Conventions (load-bearing — don't regress)

These are settled patterns from a March 2026 code review pass. Violating them reintroduces the exact bugs that pass fixed.

### Periodic UI updates

Use `TimelineView` with `.periodic(from: .now, by: 1.0)` for 1Hz updates and `.animation` for continuous (e.g. analog second hand). **Never** `Timer.publish(...).autoconnect()` — it leaks because the publisher never disconnects on view removal. All four clock views (`ClockView`, `AnalogClockView`, `FlipClockView`, `WorldClockItem`) follow this pattern.

When a TimelineView needs to track previous-state across ticks (e.g. flip animation), use `let _ = updateState(context.date)` inside the closure and update `@State` from `updateState`. The `let _ =` discard is intentional.

### DateFormatter caching

Cache as `private static let` on the view/service. **Never** create one inside `body`, `var someStringProperty`, or per-tick — they're expensive (~ms each) and re-creating one every second is a measurable CPU drain.

### Concurrency

- `@MainActor` on `@Observable` services that mutate UI-bound state from AppKit/audio callbacks (`AlarmService`, `DockIconRenderer`). Without it, Timer/Audio callbacks race with the UI.
- Wrap raw Timer callbacks with `Task { @MainActor in ... }` when the enclosing type isn't `@MainActor`.
- `LocationService` continuations: nil out the reference **before** `resume()` to prevent double-resume crashes if both `didUpdateLocations` and `didFailWithError` fire.

### Networking

All app network services share a single configured session:

```swift
private let session = URLSession.standardConfigured
```

`URLSession.standardConfigured` (in `MacClock/Services/URLSession+Configured.swift`) builds a session with `timeoutIntervalForRequest = 30` and `timeoutIntervalForResource = 60`. Never use `URLSession.shared` — it has no timeout and hangs forever on slow servers. Applies to `WeatherService`, `ICalService`, `NewsService`, `FeedDiscoveryService`, `NatureBackgroundService`. New services should use the same factory rather than re-declaring an inline config block.

### Closures and references

- `NotificationCenter.addObserver` closures: capture references with `[weak settings, weak window]`, then `guard let` inside.
- Timer callbacks that capture `self`: use `[weak self]` unless the timer's lifetime is bounded.

### Force-unwrap policy

- URLs from `URLComponents`: return `URL?`, propagate optionality, throw a domain error (`WeatherError.invalidURL`) at the public boundary.
- `Calendar.current.date(bySettingHour:...)` / `date(byAdding:...)`: end with `?? Date()` (or another safe fallback). Never `!`.
- `URLComponents(string: literalConstant)` is still a code smell — guard it.

### Accessibility

Every interactive element gets `.accessibilityLabel(...)`. Buttons get verb-style labels ("Snooze alarm for 5 minutes"), display areas get content-style labels ("Weather: 18°, San Francisco"). VoiceOver is a hard requirement.

## Resources & Bundling

- Fonts/backgrounds loaded via `Bundle.module.url(forResource:withExtension:)` — only works because they're declared in `Package.swift`'s `resources:`. If you add a resource directory, add it there.
- DSEG7 LCD font is registered at app start in `MacClockApp.registerFonts()` via `CTFontManagerRegisterFontsForURL` — no Info.plist UIAppFonts needed for a standalone executable.
- App icon: `MacClock/Resources/AppIcon.icns` is referenced via `CFBundleIconFile=AppIcon` in `Info.plist` and is copied into the bundle by `build-app.sh`.

## Window management

`MainClockView` uses a custom `.windowLevel(_:opacity:onSetup:)` modifier (in `Views/`) that runs an `onSetup` closure with the live `NSWindow`. This is where window frame restoration and resize/move observers are wired. Window frame is persisted to `AppSettings.windowFrame`.

## Settings persistence

`AppSettings` properties annotated with `@ObservationIgnored` are excluded from observation. The settings window is a separate `Window("Settings", id: "settings")` scene — opened via `openWindow(id:)`.

## Schema migrations

`UserDefaults` data has a version: `SchemaVersion.current` in `MacClock/Models/SchemaMigration.swift`. `MigrationRunner.run()` is called once at app startup (before `AppSettings(...)` evaluates) and walks the saved version forward to current.

To add a schema change:

1. Implement the migration: edit `migrateV1ToV2` (or add `migrateV2ToV3`, etc.) to read old-shape data from `UserDefaults`, transform it, and write the new shape. Migrations must be idempotent.
2. Bump `SchemaVersion.current`.
3. If you added a new function, register it in `MigrationRunner.migration(from:)`.
4. Add a test in `SchemaMigrationTests` that pre-populates the old shape, runs the runner, and asserts the new shape.

Do *not* bump `SchemaVersion.current` for cosmetic reasons. The version is tied to *data shape*, not app version.

The cache file at `~/Library/Caches/<bundle-id>/icalEvents.json` is *not* covered by this versioning — it's transient, and the `Cache<T>` helper deletes it on decode failure rather than migrating.

## Test conventions

**Unit / snapshot tests** — Swift Testing — `@Test func someTest() { #expect(...) }`. Test files mirror source structure under `MacClockTests/`. Run via `swift test`; fast (whole 229-test suite < 1s). When fixing a bug, add a regression test to the corresponding `*Tests.swift` file.

**UI interaction tests** — XCUITest, under `MacClockUITests/`. Three suites: `MacClockSmokeTests` (3), `SettingsUITests` (5), `AlarmUITests` (5) = 13 tests. Run via `make test-ui` or:

```bash
xcodebuild -project MacClock.xcodeproj -scheme MacClock \
           -destination 'platform=macOS' test
```

Selectors are accessibility labels (CR-12) — buttons "Settings", "Alarms"; settings tabs "General", "Appearance", etc.; alarm-panel tabs "Alarms", "Timer", "Stopwatch". If a test fails because an element isn't found, that's usually a real accessibility regression, not test breakage. The test runner (Xcode/Terminal) needs **Accessibility permission** (System Settings → Privacy & Security → Accessibility) to interact with the UI; grant it once.

## Git

- **Default branch is `main`** (remote: `Tapnetix/MacClock` on GitHub).
- Local branch is named `master` historically; it tracks `origin/main`.
- Commit style: `type: short subject` then a body explaining the *why*. Reference CR-N codes when fixing items from the March 2026 code review (`docs/plans/2026-03-29-code-review-and-improvements.md`, local-only).

## Local-only paths (in `.gitignore`)

`docs/plans/`, `docs/superpowers/`, `icon-mockups/`, `diagnose_ical.swift`, `Screenshot*.png`, `MacClock.app/`, `.build/`, `MacClock.xcodeproj/` (regenerate from `project.yml` via `make xcodeproj`), `DerivedData/`, `*.xcuserstate`. These exist as working materials but never get pushed.

## Common gotchas

- **`Bundle.module` returns nil in unit tests** unless the test target has its own resources or `@testable import MacClock` is used and the resource is declared on the `MacClock` target. Most tests don't need bundled resources.
- **Sound playback with custom audio device**: `AlarmService` uses `AudioObjectGetPropertyData` (CoreAudio) to enumerate devices; `AVAudioPlayer` doesn't directly support device selection, so the alarm sets the default output device temporarily.
- **iCal RFC 5545 parsing**: implemented in-house in `ICalService` (no third-party lib). Be careful with line folding (continuation lines start with whitespace) and the various date forms (`DTSTART:20260101T100000Z` vs `DTSTART;TZID=America/New_York:20260101T100000`).
- **Open-Meteo API** is the weather backend — no API key required, but rate-limited. `WeatherService` caches responses for 30 minutes.
