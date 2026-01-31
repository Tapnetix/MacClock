import Foundation

actor WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private var cachedWeather: WeatherData?
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 30 * 60 // 30 minutes

    nonisolated func buildURL(latitude: Double, longitude: Double, useCelsius: Bool) -> URL {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,apparent_temperature,relative_humidity_2m"),
            URLQueryItem(name: "daily", value: "sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "temperature_unit", value: useCelsius ? "celsius" : "fahrenheit"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "3"),
            URLQueryItem(name: "forecast_hours", value: "6")
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

        // Parse hourly forecast - filter to future times, max 6 entries
        let now = Date()
        var hourlyForecast: [HourlyWeather] = []
        for i in 0..<min(response.hourly.times.count, response.hourly.temperatures.count, response.hourly.weatherCodes.count) {
            if let time = formatter.date(from: response.hourly.times[i]), time > now {
                hourlyForecast.append(HourlyWeather(
                    time: time,
                    temperature: response.hourly.temperatures[i],
                    condition: WeatherCondition.fromCode(response.hourly.weatherCodes[i])
                ))
                if hourlyForecast.count >= 6 {
                    break
                }
            }
        }

        // Parse daily forecast - create 3 days
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        var dailyForecast: [DailyForecast] = []
        for i in 0..<min(3, response.daily.maxTemps.count, response.daily.minTemps.count, response.daily.weatherCodes.count) {
            // Daily dates come from sunrise which contains full datetime
            let dateString = String(response.daily.sunrise[i].prefix(10))
            if let date = dayFormatter.date(from: dateString) {
                dailyForecast.append(DailyForecast(
                    date: date,
                    highTemp: response.daily.maxTemps[i],
                    lowTemp: response.daily.minTemps[i],
                    condition: WeatherCondition.fromCode(response.daily.weatherCodes[i])
                ))
            }
        }

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
            hourlyForecast: hourlyForecast,
            dailyForecast: dailyForecast
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
