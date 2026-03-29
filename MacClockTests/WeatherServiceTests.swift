import Testing
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
