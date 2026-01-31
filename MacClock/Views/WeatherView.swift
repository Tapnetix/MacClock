import SwiftUI

struct WeatherView: View {
    let weather: WeatherData?
    let useCelsius: Bool
    var theme: ColorTheme = .classicWhite

    var body: some View {
        if let weather = weather {
            HStack(spacing: 6) {
                Image(systemName: weather.condition.sfSymbol)
                    .font(.system(size: 18))
                    .foregroundStyle(theme.primaryColor.opacity(0.9))

                Text(temperatureString(weather.temperature))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(theme.primaryColor)

                Text(weather.locationName)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.accentColor)
            }
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 18))
                Text("—")
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundStyle(theme.primaryColor.opacity(0.6))
        }
    }

    private func temperatureString(_ temp: Double) -> String {
        let rounded = Int(temp.rounded())
        return "\(rounded)°\(useCelsius ? "C" : "F")"
    }
}

#Preview {
    WeatherView(
        weather: WeatherData(
            temperature: 72,
            condition: .clear,
            locationName: "San Francisco",
            sunrise: Date(),
            sunset: Date(),
            feelsLike: 70,
            humidity: 65,
            highTemp: 75,
            lowTemp: 62,
            hourlyForecast: [],
            dailyForecast: []
        ),
        useCelsius: false
    )
    .padding()
    .background(.black)
}
