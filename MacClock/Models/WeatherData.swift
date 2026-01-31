import Foundation

struct OpenMeteoResponse: Codable {
    let current: CurrentWeather
    let daily: DailyWeather
    let hourly: HourlyWeatherResponse
}

struct CurrentWeather: Codable {
    let temperature: Double
    let weatherCode: Int
    let apparentTemperature: Double
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case apparentTemperature = "apparent_temperature"
        case humidity = "relative_humidity_2m"
    }
}

struct DailyWeather: Codable {
    let sunrise: [String]
    let sunset: [String]
    let maxTemps: [Double]
    let minTemps: [Double]
    let weatherCodes: [Int]

    enum CodingKeys: String, CodingKey {
        case sunrise
        case sunset
        case maxTemps = "temperature_2m_max"
        case minTemps = "temperature_2m_min"
        case weatherCodes = "weather_code"
    }
}

struct HourlyWeatherResponse: Codable {
    let times: [String]
    let temperatures: [Double]
    let weatherCodes: [Int]

    enum CodingKeys: String, CodingKey {
        case times = "time"
        case temperatures = "temperature_2m"
        case weatherCodes = "weather_code"
    }
}

struct HourlyWeather {
    let time: Date
    let temperature: Double
    let condition: WeatherCondition
}

struct DailyForecast {
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let condition: WeatherCondition
}

struct WeatherData {
    let temperature: Double
    let condition: WeatherCondition
    let locationName: String
    let sunrise: Date
    let sunset: Date
    let feelsLike: Double
    let humidity: Int
    let highTemp: Double
    let lowTemp: Double
    let hourlyForecast: [HourlyWeather]
    let dailyForecast: [DailyForecast]
}

enum WeatherCondition: Equatable {
    case clear
    case partlyCloudy
    case cloudy
    case foggy
    case drizzle
    case rain
    case snow
    case thunderstorm
    case unknown

    var sfSymbol: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .foggy: return "cloud.fog.fill"
        case .drizzle: return "cloud.drizzle.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    static func fromCode(_ code: Int) -> WeatherCondition {
        switch code {
        case 0: return .clear
        case 1, 2: return .partlyCloudy
        case 3: return .cloudy
        case 45, 48: return .foggy
        case 51, 53, 55, 56, 57: return .drizzle
        case 61, 63, 65, 66, 67, 80, 81, 82: return .rain
        case 71, 73, 75, 77, 85, 86: return .snow
        case 95, 96, 99: return .thunderstorm
        default: return .unknown
        }
    }
}
