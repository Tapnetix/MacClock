import Foundation

extension URLSession {
    /// Standard configured session for app network calls:
    /// 30s request timeout, 60s resource timeout.
    ///
    /// All app-level network services (`WeatherService`, `ICalService`,
    /// `NewsService`, `FeedDiscoveryService`, …) should share this instance
    /// rather than building their own configured session — the timeouts
    /// here are the only customisation any of them apply, so duplicating
    /// the block in each service has no benefit.
    static let standardConfigured: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
}
