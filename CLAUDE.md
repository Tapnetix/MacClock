# MacClock — Project Context for Claude

A native macOS desktop clock app: digital/analog/flip-clock displays, weather, calendar, alarms, world clocks, news ticker, dynamic backgrounds.

## Stack

- **Swift 5.9, SwiftUI, macOS 14+**
- **Swift Package Manager** (no Xcode project — `Package.swift` is authoritative)
- **Zero external dependencies** — only Apple frameworks
- **Swift Testing** (`@Test`, `#expect`, `@Suite`) — not XCTest
- **AppKit interop** for window level/style, dock icon, NSWorkspace, audio device selection

## Commands

```bash
swift build              # Debug build
swift build -c release   # Release build
swift test               # Run all 54+ tests (Swift Testing)
./build-app.sh           # Build .app bundle (release + copy resources + Info.plist)
swift run                # Run from terminal (sometimes useful for logs)
```

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

Swift Testing — `@Test func someTest() { #expect(...) }`. Test files mirror source structure. Tests run via `swift test` and are fast (whole suite < 1s). When fixing a bug, add a regression test to the corresponding `*Tests.swift` file.

## Git

- **Default branch is `main`** (remote: `Tapnetix/MacClock` on GitHub).
- Local branch is named `master` historically; it tracks `origin/main`.
- Commit style: `type: short subject` then a body explaining the *why*. Reference CR-N codes when fixing items from the March 2026 code review (`docs/plans/2026-03-29-code-review-and-improvements.md`, local-only).

## Local-only paths (in `.gitignore`)

`docs/plans/`, `docs/superpowers/`, `icon-mockups/`, `diagnose_ical.swift`, `Screenshot*.png`, `MacClock.app/`, `.build/`. These exist as working materials but never get pushed.

## Common gotchas

- **`Bundle.module` returns nil in unit tests** unless the test target has its own resources or `@testable import MacClock` is used and the resource is declared on the `MacClock` target. Most tests don't need bundled resources.
- **Sound playback with custom audio device**: `AlarmService` uses `AudioObjectGetPropertyData` (CoreAudio) to enumerate devices; `AVAudioPlayer` doesn't directly support device selection, so the alarm sets the default output device temporarily.
- **iCal RFC 5545 parsing**: implemented in-house in `ICalService` (no third-party lib). Be careful with line folding (continuation lines start with whitespace) and the various date forms (`DTSTART:20260101T100000Z` vs `DTSTART;TZID=America/New_York:20260101T100000`).
- **Open-Meteo API** is the weather backend — no API key required, but rate-limited. `WeatherService` caches responses for 30 minutes.
