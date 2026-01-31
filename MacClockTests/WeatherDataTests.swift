import Foundation
import Testing
@testable import MacClock

@Test func decodeOpenMeteoResponse() throws {
    let json = """
    {
        "current": {
            "temperature_2m": 72.5,
            "weather_code": 1,
            "apparent_temperature": 70.0,
            "relative_humidity_2m": 50
        },
        "daily": {
            "sunrise": ["2026-01-28T06:45"],
            "sunset": ["2026-01-28T17:30"],
            "temperature_2m_max": [75.0],
            "temperature_2m_min": [65.0],
            "weather_code": [1]
        },
        "hourly": {
            "time": ["2026-01-28T12:00"],
            "temperature_2m": [72.5],
            "weather_code": [1]
        }
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
    #expect(response.current.temperature == 72.5)
    #expect(response.current.weatherCode == 1)
    #expect(response.daily.sunrise.first == "2026-01-28T06:45")
}

@Test func weatherCodeToSFSymbol() {
    #expect(WeatherCondition.fromCode(0).sfSymbol == "sun.max.fill")
    #expect(WeatherCondition.fromCode(3).sfSymbol == "cloud.fill")
    #expect(WeatherCondition.fromCode(61).sfSymbol == "cloud.rain.fill")
    #expect(WeatherCondition.fromCode(71).sfSymbol == "cloud.snow.fill")
}

@Test func decodeExtendedOpenMeteoResponse() throws {
    let json = """
    {
        "current": {
            "temperature_2m": 6.5,
            "weather_code": 61,
            "apparent_temperature": 4.2,
            "relative_humidity_2m": 85
        },
        "daily": {
            "sunrise": ["2026-01-31T07:32"],
            "sunset": ["2026-01-31T17:45"],
            "temperature_2m_max": [8.0, 9.0, 11.0],
            "temperature_2m_min": [3.0, 4.0, 5.0],
            "weather_code": [61, 3, 0]
        },
        "hourly": {
            "time": ["2026-01-31T10:00", "2026-01-31T11:00", "2026-01-31T12:00", "2026-01-31T13:00", "2026-01-31T14:00", "2026-01-31T15:00"],
            "temperature_2m": [5.0, 6.0, 6.5, 7.0, 7.5, 7.0],
            "weather_code": [61, 61, 3, 3, 2, 2]
        }
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
    #expect(response.current.apparentTemperature == 4.2)
    #expect(response.current.humidity == 85)
    #expect(response.daily.maxTemps.count == 3)
    #expect(response.daily.minTemps.count == 3)
    #expect(response.daily.weatherCodes.count == 3)
    #expect(response.hourly.times.count == 6)
    #expect(response.hourly.temperatures.count == 6)
}

@Test func hourlyWeatherStoresData() {
    let weather = HourlyWeather(
        time: Date(),
        temperature: 6.5,
        condition: .rain
    )
    #expect(weather.temperature == 6.5)
    #expect(weather.condition == .rain)
}

@Test func dailyForecastStoresData() {
    let forecast = DailyForecast(
        date: Date(),
        highTemp: 8.0,
        lowTemp: 3.0,
        condition: .cloudy
    )
    #expect(forecast.highTemp == 8.0)
    #expect(forecast.lowTemp == 3.0)
}
