import Foundation
import CoreLocation

@Observable
final class LocationService: NSObject {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    var currentLocation: CLLocation?
    var locationName: String = ""
    var error: Error?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    func reverseGeocode(location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.first?.locality ?? placemarks.first?.name ?? "Unknown"
    }

    func geocodeCity(name: String) async throws -> (latitude: Double, longitude: Double, name: String) {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(name)
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw LocationError.notFound
        }
        let displayName = placemark.locality ?? placemark.name ?? name
        return (location.coordinate.latitude, location.coordinate.longitude, displayName)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location
        continuation?.resume(returning: location)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Trigger UI update via @Observable
    }
}

enum LocationError: Error {
    case notFound
    case permissionDenied
}
