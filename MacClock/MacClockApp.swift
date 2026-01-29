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
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
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

struct MainClockView: View {
    let settings: AppSettings
    let weatherService: WeatherService
    let locationService: LocationService
    let backgroundManager: BackgroundManager
    @Binding var showSettings: Bool

    @State private var weather: WeatherData?
    @State private var natureService = NatureBackgroundService()
    @State private var currentNatureImage: NSImage?
    @State private var backgroundTimer: Timer?
    @State private var weatherTimer: Timer?

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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - constrained to window size
                if let image = displayedBackgroundImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
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
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, locationService: locationService)
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
        }
        .onDisappear {
            weatherTimer?.invalidate()
            backgroundTimer?.invalidate()
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
                currentNatureImage = await natureService.getNextImage()
            }
        }
    }
}
