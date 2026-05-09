import SwiftUI

struct DimContainer<Content: View>: View {
    let settings: AppSettings
    let weather: WeatherData?
    let dimManager: DimManager
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
    }
}
