import SwiftUI

struct BackgroundContainer<Content: View>: View {
    let settings: AppSettings
    let backgroundManager: BackgroundManager
    let weather: WeatherData?
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
