import Foundation

actor WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private var cachedWeather: WeatherData?
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 30 * 60 // 30 minutes

    func buildURL(latitude: Double, longitude: Double, useCelsius: Bool) -> URL {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,apparent_temperature,relative_humidity_2m"),
            URLQueryItem(name: "daily", value: "sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code"),
            URLQueryItem(name: "hourly", value: "time,temperature_2m,weather_code"),
            URLQueryItem(name: "temperature_unit", value: useCelsius ? "celsius" : "fahrenheit"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        return components.url!
    }

    func fetchWeather(latitude: Double, longitude: Double, locationName: String, useCelsius: Bool) async throws -> WeatherData {
        // Return cached if fresh
        if let cached = cachedWeather,
           let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheInterval {
            return cached
        }

        let url = buildURL(latitude: latitude, longitude: longitude, useCelsius: useCelsius)
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        let weather = WeatherData(
            temperature: response.current.temperature,
            condition: WeatherCondition.fromCode(response.current.weatherCode),
            locationName: locationName,
            sunrise: formatter.date(from: response.daily.sunrise.first ?? "") ?? Date(),
            sunset: formatter.date(from: response.daily.sunset.first ?? "") ?? Date(),
            feelsLike: response.current.apparentTemperature,
            humidity: response.current.humidity,
            highTemp: response.daily.maxTemps.first ?? response.current.temperature,
            lowTemp: response.daily.minTemps.first ?? response.current.temperature,
            hourlyForecast: [],
            dailyForecast: []
        )

        cachedWeather = weather
        lastFetch = Date()

        return weather
    }

    func clearCache() {
        cachedWeather = nil
        lastFetch = nil
    }
}
