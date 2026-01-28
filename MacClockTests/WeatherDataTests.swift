import Foundation
import Testing
@testable import MacClock

@Test func decodeOpenMeteoResponse() throws {
    let json = """
    {
        "current": {
            "temperature_2m": 72.5,
            "weather_code": 1
        },
        "daily": {
            "sunrise": ["2026-01-28T06:45"],
            "sunset": ["2026-01-28T17:30"]
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
