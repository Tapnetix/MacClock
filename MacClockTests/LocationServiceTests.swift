import Testing
import Foundation
import CoreLocation
@testable import MacClock

@Suite("LocationService Tests")
struct LocationServiceTests {

    @Test("requestLocation resumes when didUpdateLocations fires")
    func requestLocationSuccess() async throws {
        let service = LocationService()
        let expected = CLLocation(latitude: 37.7749, longitude: -122.4194)

        // Kick off the request, then drive the delegate callback on a Task.
        async let result = service.requestLocation()
        // Give the continuation a moment to attach
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        service.locationManager(CLLocationManager(), didUpdateLocations: [expected])

        let location = try await result
        #expect(location.coordinate.latitude == expected.coordinate.latitude)
        #expect(location.coordinate.longitude == expected.coordinate.longitude)
    }

    @Test("requestLocation throws when didFailWithError fires")
    func requestLocationFailure() async {
        let service = LocationService()
        let expectedError = NSError(domain: kCLErrorDomain, code: CLError.denied.rawValue)

        async let result = service.requestLocation()
        try? await Task.sleep(nanoseconds: 50_000_000)
        service.locationManager(CLLocationManager(), didFailWithError: expectedError)

        do {
            _ = try await result
            Issue.record("Expected requestLocation() to throw")
        } catch {
            #expect((error as NSError).code == CLError.denied.rawValue)
        }
    }

    @Test("Calling both delegate methods does not crash (CR-6 regression)")
    func bothDelegateCallbacksDoNotCrash() async throws {
        let service = LocationService()
        let location = CLLocation(latitude: 0, longitude: 0)
        let error = NSError(domain: kCLErrorDomain, code: CLError.network.rawValue)

        async let result = service.requestLocation()
        try await Task.sleep(nanoseconds: 50_000_000)

        // First callback: success
        service.locationManager(CLLocationManager(), didUpdateLocations: [location])
        // Second callback after first already resumed — must not crash.
        service.locationManager(CLLocationManager(), didFailWithError: error)

        let resolved = try await result
        #expect(resolved.coordinate.latitude == 0)
    }

    @Test("didUpdateLocations with empty array does not resume continuation")
    func emptyLocationsArrayIgnored() async throws {
        let service = LocationService()
        async let result = service.requestLocation()
        try await Task.sleep(nanoseconds: 50_000_000)

        // Empty array — the guard in didUpdateLocations bails early.
        service.locationManager(CLLocationManager(), didUpdateLocations: [])
        // Continuation is still pending; resume it so the test completes.
        let real = CLLocation(latitude: 1, longitude: 2)
        service.locationManager(CLLocationManager(), didUpdateLocations: [real])

        let resolved = try await result
        #expect(resolved.coordinate.latitude == 1)
    }
}
