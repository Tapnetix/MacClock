import Testing
import Foundation
import Observation
@testable import MacClock

// MARK: - Test fixtures

/// A minimal @Observable host that exercises every wrapper specialization.
/// Keys are namespaced with the suite UUID so each test run is hermetic.
@Observable
private final class TestHost: UserDefaultsBacked {
    let userDefaultsStore: UserDefaults

    @ObservationIgnored
    var observationRegistrar: ObservationRegistrar { _$observationRegistrar }

    @ObservationIgnored @UserDefault(key: "use24Hour")
    var use24Hour: Bool = false

    @ObservationIgnored @UserDefault(key: "showSeconds")
    var showSeconds: Bool = true

    @ObservationIgnored @UserDefault(key: "fontSize")
    var fontSize: Double = 96.0

    @ObservationIgnored @UserDefault(key: "selectedIDs")
    var selectedIDs: [String] = []

    @ObservationIgnored @UserDefaultOptional(key: "customPath")
    var customPath: String? = nil

    @ObservationIgnored @UserDefaultOptional(key: "bookmark")
    var bookmark: Data? = nil

    @ObservationIgnored @UserDefaultRaw(key: "clockStyle")
    var clockStyle: ClockStyle = .digital

    @ObservationIgnored @UserDefaultRawOptional(key: "nightTheme")
    var nightTheme: ColorTheme? = nil

    @ObservationIgnored @UserDefaultCodable(key: "alarms")
    var alarms: [Alarm] = []

    @ObservationIgnored @UserDefaultCodable(key: "feeds")
    var feeds: [NewsFeed] = NewsFeed.builtInFeeds

    init(store: UserDefaults) {
        self.userDefaultsStore = store
    }
}

@Suite("UserDefault property wrappers")
struct UserDefaultTests {
    private static func makeStore() -> (UserDefaults, String) {
        let suite = "test.macclock.\(UUID().uuidString)"
        let store = UserDefaults(suiteName: suite)!
        store.removePersistentDomain(forName: suite)
        return (store, suite)
    }

    // MARK: PropertyList raw

    @Test func boolDefaultWhenAbsent() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        #expect(host.use24Hour == false)
        #expect(host.showSeconds == true)
    }

    @Test func boolPersistsWriteAndRead() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        host.use24Hour = true
        #expect(host.use24Hour == true)
        #expect(store.bool(forKey: "use24Hour") == true)
    }

    @Test func boolPersistsAcrossInstances() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host1 = TestHost(store: store)
        host1.use24Hour = true
        host1.fontSize = 144.0
        let host2 = TestHost(store: store)
        #expect(host2.use24Hour == true)
        #expect(host2.fontSize == 144.0)
    }

    @Test func stringArrayRoundTrip() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        #expect(host.selectedIDs.isEmpty)
        host.selectedIDs = ["a", "b", "c"]
        #expect(host.selectedIDs == ["a", "b", "c"])
        let host2 = TestHost(store: store)
        #expect(host2.selectedIDs == ["a", "b", "c"])
    }

    // MARK: Optional PropertyList

    @Test func optionalStringDefaultsToNil() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        #expect(host.customPath == nil)
    }

    @Test func optionalStringWritesAndReads() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        host.customPath = "/tmp/foo.jpg"
        #expect(host.customPath == "/tmp/foo.jpg")
    }

    @Test func optionalNilTriggersRemoveObject() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        host.bookmark = Data([0x01, 0x02])
        #expect(store.object(forKey: "bookmark") != nil)
        host.bookmark = nil
        #expect(store.object(forKey: "bookmark") == nil)
    }

    // MARK: RawRepresentable

    @Test func rawRepresentableEnumRoundTrip() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        #expect(host.clockStyle == .digital)
        host.clockStyle = .analog
        #expect(host.clockStyle == .analog)
        // Stored as rawValue String:
        #expect(store.string(forKey: "clockStyle") == "Analog")
    }

    @Test func rawRepresentableInvalidRawFallsBackToDefault() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        store.set("BogusStyle", forKey: "clockStyle")
        let host = TestHost(store: store)
        #expect(host.clockStyle == .digital)
    }

    // MARK: Optional RawRepresentable

    @Test func optionalRawRepresentableDefaultsToNil() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        #expect(host.nightTheme == nil)
    }

    @Test func optionalRawRepresentableNilRemovesKey() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        host.nightTheme = .warmAmber
        #expect(store.string(forKey: "nightTheme") == "Warm Amber")
        host.nightTheme = nil
        #expect(store.object(forKey: "nightTheme") == nil)
    }

    // MARK: Codable

    @Test func codableArrayDefaultsToEmpty() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        #expect(host.alarms.isEmpty)
    }

    @Test func codableArrayUsesNonEmptyDefaultWhenAbsent() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        #expect(!host.feeds.isEmpty)
        #expect(host.feeds.count == NewsFeed.builtInFeeds.count)
    }

    @Test func codableArrayRoundTrip() {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        let alarm = Alarm(
            id: UUID(),
            time: DateComponents(hour: 7, minute: 30),
            label: "Wake up",
            isEnabled: true,
            repeatDays: [],
            soundName: nil,
            snoozeDuration: 5
        )
        host.alarms = [alarm]
        let host2 = TestHost(store: store)
        #expect(host2.alarms.count == 1)
        #expect(host2.alarms.first?.label == "Wake up")
    }

    // MARK: Observation

    @Test func observationFiresOnRawWrite() async {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        var fired = false
        withObservationTracking {
            _ = host.use24Hour
        } onChange: {
            fired = true
        }
        host.use24Hour = true
        // onChange fires synchronously on mutation under the registrar contract.
        #expect(fired == true)
    }

    @Test func observationFiresOnEnumWrite() async {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        var fired = false
        withObservationTracking {
            _ = host.clockStyle
        } onChange: {
            fired = true
        }
        host.clockStyle = .analog
        #expect(fired == true)
    }

    @Test func observationFiresOnOptionalWrite() async {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        var fired = false
        withObservationTracking {
            _ = host.customPath
        } onChange: {
            fired = true
        }
        host.customPath = "/tmp/x"
        #expect(fired == true)
    }

    @Test func observationFiresOnCodableWrite() async {
        let (store, suite) = Self.makeStore()
        defer { store.removePersistentDomain(forName: suite) }
        let host = TestHost(store: store)
        var fired = false
        withObservationTracking {
            _ = host.alarms
        } onChange: {
            fired = true
        }
        host.alarms = []  // even no-op-ish reassignment should fire
        #expect(fired == true)
    }
}
