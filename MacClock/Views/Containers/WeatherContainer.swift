import SwiftUI

/// Owns the weather refresh lifecycle: 30-min polling timer, location-aware
/// fetch, and onChange handlers for manualLocationName / useAutoLocation.
///
/// `weather` itself stays as @State in MainClockView (passed via Binding) so
/// sibling containers (BackgroundContainer, DimContainer) read the same value
/// within one frame and avoid one-frame lag from SwiftUI's top-down render.
struct WeatherContainer<Content: View>: View {
    let settings: AppSettings
    let weatherService: WeatherService
    let locationService: LocationService
    let backgroundManager: BackgroundManager
    @Binding var weather: WeatherData?
    @ViewBuilder let content: () -> Content

    @State private var weatherTimer: Timer?

    var body: some View {
        content()
            .task {
                await loadWeather()
            }
            .onAppear {
                weatherTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { _ in
                    Task { await loadWeather() }
                }
            }
            .onDisappear {
                weatherTimer?.invalidate()
                weatherTimer = nil
            }
            .onChange(of: settings.manualLocationName) { _, _ in
                Task {
                    await weatherService.clearCache()
                    await loadWeather()
                }
            }
            .onChange(of: settings.useAutoLocation) { _, _ in
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
                        location = (Constants.defaultLatitude, Constants.defaultLongitude, Constants.defaultLocationName)
                    }
                }
            } else {
                if !settings.manualLocationName.isEmpty {
                    location = (settings.manualLatitude, settings.manualLongitude, settings.manualLocationName)
                } else {
                    location = (Constants.defaultLatitude, Constants.defaultLongitude, Constants.defaultLocationName)
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
                    customBookmark: settings.customBackgroundBookmark
                )
            }
        } catch {
            print("Weather error: \(error)")
        }
    }
}
