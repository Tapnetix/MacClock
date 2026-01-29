import Foundation

struct CitySearchResult: Identifiable {
    let id = UUID()
    let cityName: String
    let countryName: String
    let timezoneIdentifier: String

    var displayName: String {
        "\(cityName), \(countryName)"
    }
}

actor CitySearchService {
    // Common cities with their timezones
    private let cities: [CitySearchResult] = [
        CitySearchResult(cityName: "New York", countryName: "USA", timezoneIdentifier: "America/New_York"),
        CitySearchResult(cityName: "Los Angeles", countryName: "USA", timezoneIdentifier: "America/Los_Angeles"),
        CitySearchResult(cityName: "Chicago", countryName: "USA", timezoneIdentifier: "America/Chicago"),
        CitySearchResult(cityName: "London", countryName: "UK", timezoneIdentifier: "Europe/London"),
        CitySearchResult(cityName: "Paris", countryName: "France", timezoneIdentifier: "Europe/Paris"),
        CitySearchResult(cityName: "Berlin", countryName: "Germany", timezoneIdentifier: "Europe/Berlin"),
        CitySearchResult(cityName: "Tokyo", countryName: "Japan", timezoneIdentifier: "Asia/Tokyo"),
        CitySearchResult(cityName: "Sydney", countryName: "Australia", timezoneIdentifier: "Australia/Sydney"),
        CitySearchResult(cityName: "Dubai", countryName: "UAE", timezoneIdentifier: "Asia/Dubai"),
        CitySearchResult(cityName: "Singapore", countryName: "Singapore", timezoneIdentifier: "Asia/Singapore"),
        CitySearchResult(cityName: "Hong Kong", countryName: "China", timezoneIdentifier: "Asia/Hong_Kong"),
        CitySearchResult(cityName: "Mumbai", countryName: "India", timezoneIdentifier: "Asia/Kolkata"),
        CitySearchResult(cityName: "Moscow", countryName: "Russia", timezoneIdentifier: "Europe/Moscow"),
        CitySearchResult(cityName: "São Paulo", countryName: "Brazil", timezoneIdentifier: "America/Sao_Paulo"),
        CitySearchResult(cityName: "Toronto", countryName: "Canada", timezoneIdentifier: "America/Toronto"),
        CitySearchResult(cityName: "Vancouver", countryName: "Canada", timezoneIdentifier: "America/Vancouver"),
        CitySearchResult(cityName: "Amsterdam", countryName: "Netherlands", timezoneIdentifier: "Europe/Amsterdam"),
        CitySearchResult(cityName: "Stockholm", countryName: "Sweden", timezoneIdentifier: "Europe/Stockholm"),
        CitySearchResult(cityName: "Seoul", countryName: "South Korea", timezoneIdentifier: "Asia/Seoul"),
        CitySearchResult(cityName: "Bangkok", countryName: "Thailand", timezoneIdentifier: "Asia/Bangkok"),
        CitySearchResult(cityName: "Cairo", countryName: "Egypt", timezoneIdentifier: "Africa/Cairo"),
        CitySearchResult(cityName: "Johannesburg", countryName: "South Africa", timezoneIdentifier: "Africa/Johannesburg"),
        CitySearchResult(cityName: "Auckland", countryName: "New Zealand", timezoneIdentifier: "Pacific/Auckland"),
        CitySearchResult(cityName: "Denver", countryName: "USA", timezoneIdentifier: "America/Denver"),
        CitySearchResult(cityName: "Phoenix", countryName: "USA", timezoneIdentifier: "America/Phoenix"),
    ]

    func search(query: String) -> [CitySearchResult] {
        guard !query.isEmpty else { return [] }
        let lowercased = query.lowercased()
        return cities.filter {
            $0.cityName.lowercased().contains(lowercased) ||
            $0.countryName.lowercased().contains(lowercased)
        }
    }

    func allCities() -> [CitySearchResult] {
        cities
    }
}
