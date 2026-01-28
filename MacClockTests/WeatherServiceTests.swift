import Testing
@testable import MacClock

@Test func buildWeatherURL() async {
    let service = WeatherService()
    let url = await service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: false)

    #expect(url.absoluteString.contains("latitude=37.7749"))
    #expect(url.absoluteString.contains("longitude=-122.4194"))
    #expect(url.absoluteString.contains("temperature_unit=fahrenheit"))
}

@Test func buildWeatherURLCelsius() async {
    let service = WeatherService()
    let url = await service.buildURL(latitude: 37.7749, longitude: -122.4194, useCelsius: true)

    #expect(url.absoluteString.contains("temperature_unit=celsius"))
}
