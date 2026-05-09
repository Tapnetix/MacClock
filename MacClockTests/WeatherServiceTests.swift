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
