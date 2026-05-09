import SwiftUI
import CoreText
import AppKit
import OSLog

@main
struct MacClockApp: App {
    @State private var settings = AppSettings(defaults: MacClockApp.makeUserDefaults())
    @State private var locationService = LocationService()
    @State private var backgroundManager = BackgroundManager()
    @State private var showSettings = false

    private let weatherService = WeatherService()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    init() {
        Self.migrateFromLegacyBundleID()
        runMigrations()
        ICalService.purgeLegacyUserDefaultsCache()
        registerFonts()
    }

    /// One-shot migration: when the app's CFBundleIdentifier changed from
    /// `com.local.MacClock` to `com.tapnetix.MacClock`, macOS started
    /// reading from a fresh empty preferences plist and the user's saved
    /// alarms/feeds/themes/window frame appeared "lost". They were never
    /// lost — just inaccessible under the new bundle ID. This copies them
    /// across on first launch and sets a flag so it never runs again.
    private static func migrateFromLegacyBundleID() {
        let flag = "bundleIDMigratedFromLocal_v1"
        let standard = UserDefaults.standard
        guard !standard.bool(forKey: flag) else { return }

        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MacClock",
                            category: "Migration")

        // `persistentDomain(forName:)` returns only the keys actually written
        // to the legacy app's own plist file — not the merged global view that
        // `dictionaryRepresentation()` would give us (which includes
        // NSGlobalDomain system keys we don't want to copy).
        guard let legacyDict = standard.persistentDomain(forName: "com.local.MacClock"),
              !legacyDict.isEmpty else {
            standard.set(true, forKey: flag)
            return
        }

        // Don't clobber control keys owned by the new app's own startup logic.
        let preserve: Set<String> = [
            "appSettingsSchemaVersion",
            "iCalLegacyCachePurged_v1",
            flag,
        ]
        var copied = 0
        for (key, value) in legacyDict where !preserve.contains(key) {
            standard.set(value, forKey: key)
            copied += 1
        }
        standard.set(true, forKey: flag)
        logger.info("Migrated \(copied, privacy: .public) keys from com.local.MacClock")
    }

    /// Returns a `UserDefaults` instance for `AppSettings` to back its
    /// state. In normal use this is `.standard`. When the app is launched
    /// with `--test-mode` (used by `MacClockUITests` to keep XCUITest
    /// runs from clobbering a developer's saved settings), a transient
    /// suite-backed defaults is returned and pre-cleared so each test
    /// run starts from a known empty state.
    private static func makeUserDefaults() -> UserDefaults {
        guard CommandLine.arguments.contains("--test-mode") else {
            return .standard
        }
        let suiteName = "com.tapnetix.MacClock.UITests"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func runMigrations() {
        do {
            try MigrationRunner.run()
        } catch {
            // A migration failure shouldn't refuse to launch — log and proceed
            // with whatever state UserDefaults is in. AppSettings has fallbacks
            // for all decode failures, so the user gets a (possibly empty)
            // working UI rather than a silent no-launch.
            let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MacClock", category: "Migration")
            logger.error("Schema migration failed: \(String(describing: error), privacy: .public)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainClockView(
                settings: settings,
                weatherService: weatherService,
                locationService: locationService,
                backgroundManager: backgroundManager,
                showSettings: $showSettings
            )
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 480, height: 320)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    openWindow(id: "settings")
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Window("Settings", id: "settings") {
            SettingsView(settings: settings, locationService: locationService)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private func registerFonts() {
        guard let fontsURL = Bundle.module.url(forResource: "Fonts", withExtension: nil),
              let fontURLs = try? FileManager.default.contentsOfDirectory(
                at: fontsURL,
                includingPropertiesForKeys: nil
              ).filter({ $0.pathExtension == "ttf" }) else {
            return
        }

        for fontURL in fontURLs {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let path = Self.snapshotPath else { return }
        // Wait for the scene + nature-image fetch + first weather/news pulls
        // to settle, then snapshot the main window and exit. Used to generate
        // README screenshots — runs entirely in-process so no Screen Recording
        // TCC permission is required (unlike `screencapture`).
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            Self.captureMainWindowAndExit(to: path)
        }
    }

    private static var snapshotPath: String? {
        CommandLine.arguments
            .first { $0.hasPrefix("--snapshot=") }
            .map { String($0.dropFirst("--snapshot=".count)) }
    }

    @MainActor
    private static func captureMainWindowAndExit(to path: String) {
        defer { NSApp.terminate(nil) }
        // Find the main clock window — biggest visible window that isn't
        // the Settings sheet/window.
        let candidate = NSApp.windows
            .filter { $0.isVisible && $0.contentView != nil && $0.title != "Settings" }
            .max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height })
        guard let window = candidate, let view = window.contentView else { return }
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: URL(fileURLWithPath: path))
    }
}

struct MainClockView: View {
    let settings: AppSettings
    let weatherService: WeatherService
    let locationService: LocationService
    let backgroundManager: BackgroundManager
    @Binding var showSettings: Bool

    @Environment(\.openWindow) private var openWindow
    @State private var weather: WeatherData?
    @State private var dimManager = DimManager()
    @State private var newsService = NewsService()
    @State private var newsItems: [NewsItem] = []
    @State private var showWeatherDetail = false
    @State private var windowMoveObserver: NSObjectProtocol?
    @State private var windowResizeObserver: NSObjectProtocol?

    private var effectiveTheme: ColorTheme {
        dimManager.effectiveTheme
    }

    var body: some View {
        WeatherContainer(
            settings: settings,
            weatherService: weatherService,
            locationService: locationService,
            backgroundManager: backgroundManager,
            weather: $weather
        ) {
        AlarmContainer(settings: settings, theme: effectiveTheme) { showAlarmPanel in
        GeometryReader { geometry in
            ZStack {
                BackgroundContainer(
                    settings: settings,
                    backgroundManager: backgroundManager,
                    weather: weather,
                    geometry: geometry
                )

                // Gradient overlay for readability
                LinearGradient(
                    colors: [.black.opacity(0.3), .clear, .black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Tap-to-dismiss layer for weather detail panel
                if showWeatherDetail {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showWeatherDetail = false
                            }
                        }
                }

            // Content (dimmable region) — calendar values flow in via CalendarContainer
            CalendarContainer(settings: settings) { nextEvent, todayEvents in
                DimContainer(settings: settings, weather: weather, dimManager: dimManager) {
                    HStack(spacing: 0) {
                        // Main content
                        VStack {
                            // Top bar: weather + calendar countdown
                            HStack {
                                WeatherView(
                                    weather: weather,
                                    useCelsius: settings.useCelsius,
                                    settings: settings,
                                    theme: effectiveTheme,
                                    showDetailPanel: $showWeatherDetail
                                )

                                if settings.calendarEnabled && settings.calendarShowCountdown {
                                    CalendarCountdownView(event: nextEvent, theme: effectiveTheme)
                                }

                                Spacer()
                            }
                            .padding()

                            Spacer()

                            // Clock
                            ClockStyleContainer(settings: settings, theme: effectiveTheme)

                            Spacer()

                            // World Clocks (bottom)
                            if settings.worldClocksEnabled && settings.worldClocksPosition == .bottom && !settings.worldClocks.isEmpty {
                                WorldClocksView(settings: settings, theme: effectiveTheme)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        // World Clocks (side panel)
                        if settings.worldClocksEnabled && settings.worldClocksPosition == .side && !settings.worldClocks.isEmpty {
                            WorldClocksView(settings: settings, theme: effectiveTheme)
                        }

                        // Calendar Agenda (side panel)
                        if settings.calendarEnabled && settings.calendarShowAgenda && settings.calendarAgendaPosition == .side {
                            CalendarAgendaView(events: todayEvents, theme: effectiveTheme)
                                .frame(width: 150)
                        }
                    }
                }
            }

                // Weather detail panel - rendered on top of all content
                if showWeatherDetail, let weather = weather {
                    VStack {
                        HStack {
                            WeatherDetailPanel(
                                weather: weather,
                                useCelsius: settings.useCelsius,
                                settings: settings,
                                theme: effectiveTheme
                            )
                            .frame(width: 220) // Fixed width to fit hourly times
                            .padding(.top, 44) // Below weather display
                            .padding(.leading, 16)
                            Spacer()
                        }
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
                }

                // Settings and alarm buttons (top-right corner)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showAlarmPanel.wrappedValue = true
                        } label: {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(effectiveTheme.primaryColor.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Alarms")
                        Button {
                            openWindow(id: "settings")
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Settings")
                    }
                    .padding()
                    Spacer()
                }

                // News Ticker
                if settings.newsTickerEnabled && !newsItems.isEmpty {
                    VStack {
                        Spacer()
                        NewsTickerView(settings: settings, theme: effectiveTheme, newsItems: newsItems)
                    }
                }

                // Dock icon lifecycle (zero-sized invisible sibling)
                DockContainer(settings: settings)

        }
        }
        }
        .windowLevel(settings.windowLevel, opacity: settings.windowOpacity) { window in
            // Restore saved frame
            let savedFrame = settings.windowFrame
            if savedFrame != .zero {
                window.setFrame(savedFrame, display: true)
            }

            // Save frame on move/resize. Tokens stored in @State so
            // .onDisappear can remove the observers.
            windowMoveObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: window,
                queue: .main
            ) { [weak settings, weak window] _ in
                guard let settings, let window else { return }
                settings.windowFrame = window.frame
            }

            windowResizeObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { [weak settings, weak window] _ in
                guard let settings, let window else { return }
                settings.windowFrame = window.frame
            }
        }
        .onAppear {
            // Load news if enabled
            if settings.newsTickerEnabled {
                Task { await loadNews() }
            }
        }
        .onDisappear {
            if let token = windowMoveObserver {
                NotificationCenter.default.removeObserver(token)
                windowMoveObserver = nil
            }
            if let token = windowResizeObserver {
                NotificationCenter.default.removeObserver(token)
                windowResizeObserver = nil
            }
        }
        .onChange(of: settings.newsTickerEnabled) { _, enabled in
            if enabled {
                Task { await loadNews() }
            }
        }
        .onChange(of: settings.newsMaxAgeDays) { _, _ in
            Task { await loadNews() }
        }
        }
    }

    private func loadNews() async {
        let allItems = await newsService.fetchNews(from: settings.newsFeeds)
        let maxAge = settings.newsMaxAgeDays
        if maxAge > 0, let cutoff = Calendar.current.date(byAdding: .day, value: -maxAge, to: Date()) {
            newsItems = allItems.filter { item in
                guard let date = item.publishedDate else { return false }
                return date >= cutoff
            }
        } else {
            newsItems = allItems
        }
    }

}
