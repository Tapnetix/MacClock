import SwiftUI

struct WeatherContainer<Content: View>: View {
    let settings: AppSettings
    let weatherService: WeatherService
    let locationService: LocationService
    @Binding var weather: WeatherData?
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
