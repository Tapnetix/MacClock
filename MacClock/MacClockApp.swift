import SwiftUI
import CoreText
import AppKit

@main
struct MacClockApp: App {
    @State private var settings = AppSettings()
    @State private var locationService = LocationService()
    @State private var backgroundManager = BackgroundManager()
    @State private var showSettings = false

    private let weatherService = WeatherService()

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow

    init() {
        registerFonts()
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
}

// MARK: - Theme Change Modifier

struct ThemeChangeModifier: ViewModifier {
    let settings: AppSettings
    let dimManager: DimManager
    let sunrise: Date?
    let sunset: Date?

    func body(content: Content) -> some View {
        content
            .onChange(of: settings.autoDimEnabled) { _, _ in update() }
            .onChange(of: settings.autoDimMode) { _, _ in update() }
            .onChange(of: settings.autoDimLevel) { _, _ in update() }
            .onChange(of: settings.autoThemeEnabled) { _, _ in update() }
            .onChange(of: settings.autoThemeMode) { _, _ in update() }
            .onChange(of: settings.dayTheme) { _, _ in update() }
            .onChange(of: settings.nightThemeAuto) { _, _ in update() }
            .onChange(of: settings.colorTheme) { _, _ in update() }
            .onChange(of: settings.nightTheme) { _, _ in update() }
    }

    private func update() {
        dimManager.update(settings: settings, sunrise: sunrise, sunset: sunset)
    }
}

extension View {
    func onThemeSettingsChange(settings: AppSettings, dimManager: DimManager, sunrise: Date?, sunset: Date?) -> some View {
        modifier(ThemeChangeModifier(settings: settings, dimManager: dimManager, sunrise: sunrise, sunset: sunset))
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
    @State private var natureService = NatureBackgroundService()
    @State private var currentNatureImage: NSImage?
    @State private var backgroundTimer: Timer?
    @State private var weatherTimer: Timer?
    @State private var dimManager = DimManager()
    @State private var dimTimer: Timer?
    @State private var previousBackgroundImage: NSImage?
    @State private var backgroundOpacity: Double = 1.0
    @State private var newsService = NewsService()
    @State private var newsItems: [NewsItem] = []
    @State private var calendarService = CalendarService()
    @State private var nextEvent: CalendarEvent?
    @State private var todayEvents: [CalendarEvent] = []
    @State private var alarmService = AlarmService()
    @State private var showAlarmPanel = false
    @State private var iCalService = ICalService()
    @State private var iCalEvents: [CalendarEvent] = []
    @State private var iCalTimer: Timer?

    private var displayedBackgroundImage: NSImage? {
        switch settings.backgroundMode {
        case .nature:
            return currentNatureImage
        case .custom:
            return backgroundManager.currentImage
        case .timeOfDay:
            return backgroundManager.currentImage
        }
    }

    private var effectiveTheme: ColorTheme {
        dimManager.effectiveTheme
    }

    var body: some View {
        GeometryReader { geometry in
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

                // Gradient overlay for readability
                LinearGradient(
                    colors: [.black.opacity(0.3), .clear, .black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )

            // Content
            HStack(spacing: 0) {
                // Main content
                VStack {
                    // Top bar: weather + calendar countdown
                    HStack {
                        WeatherView(weather: weather, useCelsius: settings.useCelsius, theme: effectiveTheme)

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
            .opacity(dimManager.currentDimLevel)
            .animation(.easeInOut(duration: 2.0), value: dimManager.currentDimLevel)

                // Settings and alarm buttons (top-right corner)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showAlarmPanel = true
                        } label: {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(effectiveTheme.primaryColor.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        Button {
                            openWindow(id: "settings")
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
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

                // Alarm firing overlay
                if alarmService.isAlarmFiring, let alarm = alarmService.activeAlarm {
                    AlarmFiringView(
                        alarm: alarm,
                        onDismiss: { alarmService.dismissAlarm() },
                        onSnooze: { alarmService.snoozeAlarm() },
                        theme: effectiveTheme
                    )
                }
        }
        }
        .sheet(isPresented: $showAlarmPanel) {
            AlarmPanelView(settings: settings, alarmService: alarmService)
        }
        .windowLevel(settings.windowLevel, opacity: settings.windowOpacity) { window in
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
        .task {
            await loadWeather()
        }
        .onAppear {
            // Load initial background
            loadInitialBackground()

            weatherTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { _ in
                Task { await loadWeather() }
            }

            // Start background cycling timer if in nature mode
            setupBackgroundTimer()

            // Setup dim manager
            dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
            dimTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
            }

            // Load news if enabled
            if settings.newsTickerEnabled {
                Task { await loadNews() }
            }

            // Load calendar events if enabled
            if settings.calendarEnabled {
                loadCalendarEvents()
            }

            // Setup iCal refresh timer (every 15 minutes)
            iCalTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { _ in
                loadCalendarEvents()
            }

            // Start alarm monitoring
            alarmService.startMonitoring(alarms: settings.alarms)
        }
        .onDisappear {
            weatherTimer?.invalidate()
            backgroundTimer?.invalidate()
            dimTimer?.invalidate()
            iCalTimer?.invalidate()
            alarmService.stopMonitoring()
        }
        .onChange(of: settings.backgroundMode) { _, _ in
            loadInitialBackground()
            setupBackgroundTimer()
        }
        .onChange(of: settings.backgroundCycleInterval) { _, _ in
            setupBackgroundTimer()
        }
        .onChange(of: settings.customBackgroundPath) { _, newPath in
            if settings.backgroundMode == .custom {
                let sunrise = weather?.sunrise ?? Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
                let sunset = weather?.sunset ?? Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date())!
                backgroundManager.updateBackground(
                    sunrise: sunrise,
                    sunset: sunset,
                    customPath: newPath
                )
            }
        }
        .onChange(of: settings.manualLocationName) { _, _ in
            // Reload weather when manual location changes
            Task {
                await weatherService.clearCache()
                await loadWeather()
            }
        }
        .onChange(of: settings.useAutoLocation) { _, _ in
            // Reload weather when location mode changes
            Task {
                await weatherService.clearCache()
                await loadWeather()
            }
        }
        .onThemeSettingsChange(settings: settings, dimManager: dimManager, sunrise: weather?.sunrise, sunset: weather?.sunset)
        .onChange(of: settings.newsTickerEnabled) { _, enabled in
            if enabled {
                Task { await loadNews() }
            }
        }
        .onChange(of: settings.calendarEnabled) { _, enabled in
            if enabled {
                loadCalendarEvents()
            }
        }
        .onChange(of: settings.iCalFeeds) { _, _ in
            loadCalendarEvents()
        }
        .onChange(of: settings.alarms) { _, newAlarms in
            alarmService.startMonitoring(alarms: newAlarms)
        }
    }

    private func loadWeather() async {
        do {
            var location: (lat: Double, lon: Double, name: String)

            if settings.useAutoLocation {
                locationService.requestPermission()
                do {
                    let clLocation = try await locationService.requestLocation()
                    let name = try await locationService.reverseGeocode(location: clLocation)
                    location = (clLocation.coordinate.latitude, clLocation.coordinate.longitude, name)
                } catch {
                    // Location failed - fall back to manual location if set, otherwise use default
                    print("Location error: \(error). Falling back to manual/default location.")
                    if !settings.manualLocationName.isEmpty {
                        location = (settings.manualLatitude, settings.manualLongitude, settings.manualLocationName)
                    } else {
                        // Default to San Francisco
                        location = (37.7749, -122.4194, "San Francisco")
                    }
                }
            } else {
                if !settings.manualLocationName.isEmpty {
                    location = (settings.manualLatitude, settings.manualLongitude, settings.manualLocationName)
                } else {
                    // Default to San Francisco
                    location = (37.7749, -122.4194, "San Francisco")
                }
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

    private func loadInitialBackground() {
        switch settings.backgroundMode {
        case .nature:
            Task {
                currentNatureImage = await natureService.getNextImage()
            }
        case .timeOfDay, .custom:
            let sunrise = weather?.sunrise ?? Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())!
            let sunset = weather?.sunset ?? Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date())!
            backgroundManager.updateBackground(
                sunrise: sunrise,
                sunset: sunset,
                customPath: settings.backgroundMode == .custom ? settings.customBackgroundPath : nil
            )
        }
    }

    private func setupBackgroundTimer() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil

        guard settings.backgroundMode == .nature else { return }

        backgroundTimer = Timer.scheduledTimer(withTimeInterval: settings.backgroundCycleInterval, repeats: true) { _ in
            Task {
                let newImage = await natureService.getNextImage()
                await MainActor.run {
                    transitionToNewBackground(newImage)
                }
            }
        }
    }

    private func transitionToNewBackground(_ newImage: NSImage?) {
        guard let newImage = newImage else { return }

        // Store current as previous
        previousBackgroundImage = currentNatureImage

        // Set new image immediately but invisible
        currentNatureImage = newImage
        backgroundOpacity = 0.0

        // Animate fade in
        withAnimation(.easeInOut(duration: 1.5)) {
            backgroundOpacity = 1.0
        }

        // Clear previous after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            previousBackgroundImage = nil
        }
    }

    private func loadNews() async {
        newsItems = await newsService.fetchNews(from: settings.newsFeeds)
    }

    private func loadCalendarEvents() {
        // Local calendar events - show immediately
        let localEvents = calendarService.fetchTodayEvents(from: settings.selectedCalendarIDs)
        todayEvents = localEvents.sorted { $0.startDate < $1.startDate }

        // Update next event from local events first
        let now = Date()
        nextEvent = todayEvents.first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }

        // Fetch iCal events asynchronously and merge
        guard !settings.iCalFeeds.isEmpty else { return }

        Task {
            var fetchedEvents: [CalendarEvent] = []
            let today = Calendar.current.startOfDay(for: Date())
            guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return }

            for feed in settings.iCalFeeds where feed.isEnabled {
                do {
                    let events = try await iCalService.fetchEvents(from: feed)
                    // Filter to today's events
                    let todayEvents = events.filter { $0.startDate >= today && $0.startDate < tomorrow }
                    fetchedEvents.append(contentsOf: todayEvents)
                } catch {
                    print("Failed to fetch iCal feed \(feed.name): \(error)")
                }
            }

            await MainActor.run {
                iCalEvents = fetchedEvents
                // Merge local and iCal events, sorted by start time
                todayEvents = (localEvents + fetchedEvents).sorted { $0.startDate < $1.startDate }
                // Update next event to include iCal events
                let now = Date()
                nextEvent = todayEvents.first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }
            }
        }
    }
}
