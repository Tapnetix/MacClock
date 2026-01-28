import SwiftUI
import CoreText

@main
struct MacClockApp: App {
    @State private var settings = AppSettings()
    @State private var locationService = LocationService()
    @State private var backgroundManager = BackgroundManager()

    private let weatherService = WeatherService()

    init() {
        registerFonts()
    }

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
