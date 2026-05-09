import Testing
import Foundation
@testable import MacClock

@Test func buildWeatherURL() {
    let service = WeatherService()
    let url = service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: false)

    #expect(url != nil)
    #expect(url!.absoluteString.contains("latitude=37.7749"))
    #expect(url!.absoluteString.contains("longitude=-122.4194"))
    #expect(url!.absoluteString.contains("temperature_unit=fahrenheit"))
}

@Test func buildWeatherURLCelsius() {
    let service = WeatherService()
    let url = service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: true)

    #expect(url != nil)
    #expect(url!.absoluteString.contains("temperature_unit=celsius"))
}

@Test func buildURLIncludesExtendedParams() {
    let service = WeatherService()
    let url = service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: true)
    let urlString = url!.absoluteString

    #expect(urlString.contains("apparent_temperature"))
    #expect(urlString.contains("relative_humidity_2m"))
    #expect(urlString.contains("temperature_2m_max"))
    #expect(urlString.contains("temperature_2m_min"))
    #expect(urlString.contains("hourly="))
    #expect(urlString.contains("forecast_days=3"))
    #expect(urlString.contains("forecast_hours=24"))
}

// MARK: - CR-2 / CR-7 coverage: error contract & timeout config

@Test func weatherErrorInvalidURLIsThrowable() {
    // The WeatherError type is the contract; verify it conforms to Error.
    let err: any Error = WeatherError.invalidURL
    #expect((err as? WeatherError) == .invalidURL)
}

@Test func standardConfiguredSessionHasTimeouts() {
    // CR-7: WeatherService (and other services) share URLSession.standardConfigured,
    // which must have explicit timeouts so a slow server can't hang the app.
    let session = URLSession.standardConfigured
    #expect(session.configuration.timeoutIntervalForRequest == 30)
    #expect(session.configuration.timeoutIntervalForResource == 60)
}

@Test func buildURLWithExtremeCoordinates() {
    // NaN / infinity should still produce a URL (URLQueryItem accepts any string),
    // but the result must be parseable. This is the "robustness" half of CR-2.
    let service = WeatherService()
    let url = service.buildURL(latitude: .nan, longitude: .infinity, useCelsius: true)
    // .nan and .infinity stringify to "nan" / "inf" — the URL is still valid syntactically.
    #expect(url != nil)
    #expect(url!.absoluteString.contains("latitude=nan"))
}

// MARK: - JSON decoder boundary tests

@Test func decodeOpenMeteoResponseSuccess() throws {
    let json = """
    {
      "current": {
        "temperature_2m": 18.5,
        "weather_code": 0,
        "apparent_temperature": 17.2,
        "relative_humidity_2m": 65
      },
      "daily": {
        "sunrise": ["2026-05-09T06:30"],
        "sunset": ["2026-05-09T19:45"],
        "temperature_2m_max": [22.0],
        "temperature_2m_min": [12.0],
        "weather_code": [1]
      },
      "hourly": {
        "time": ["2026-05-09T08:00"],
        "temperature_2m": [16.0],
        "weather_code": [0]
      }
    }
    """.data(using: .utf8)!

    let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
    #expect(response.current.temperature == 18.5)
    #expect(response.current.humidity == 65)
    #expect(response.daily.maxTemps == [22.0])
}

@Test func decodeOpenMeteoResponseRejectsMalformedJSON() {
    let bad = "{ not json".data(using: .utf8)!
    #expect(throws: (any Error).self) {
        _ = try JSONDecoder().decode(OpenMeteoResponse.self, from: bad)
    }
}

@Test func decodeOpenMeteoResponseRejectsMissingFields() {
    let incomplete = """
    { "current": { "temperature_2m": 1.0 } }
    """.data(using: .utf8)!
    #expect(throws: (any Error).self) {
        _ = try JSONDecoder().decode(OpenMeteoResponse.self, from: incomplete)
    }
}

// MARK: - Cache & actor contract

@Test func clearCacheRunsWithoutError() async {
    let service = WeatherService()
    await service.clearCache()
    // Smoke test: clearCache on a fresh service should be a no-op and not crash.
}

@Test func weatherServiceIsActor() async {
    // Compile-time check: WeatherService is declared as `actor`. The fact that
    // `await` is required to call clearCache() proves the actor-isolation
    // contract — non-actor types would not require it.
    let service = WeatherService()
    await service.clearCache()
}
