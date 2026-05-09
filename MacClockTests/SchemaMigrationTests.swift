import Foundation
import Testing
@testable import MacClock

@Suite("Schema migrations")
struct SchemaMigrationTests {
    private func freshDefaults(name: String = #function) -> UserDefaults {
        let suiteName = "schema-test-\(name)-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suiteName)!
        d.removePersistentDomain(forName: suiteName)
        return d
    }

    @Test("Missing version is treated as v1 and stamped to current")
    func missingVersionStamped() throws {
        let d = freshDefaults()
        try MigrationRunner.run(defaults: d)
        #expect(d.integer(forKey: SchemaVersion.key) == SchemaVersion.current)
    }

    @Test("Saved version equal to current is a no-op")
    func currentVersionNoOp() throws {
        let d = freshDefaults()
        d.set(SchemaVersion.current, forKey: SchemaVersion.key)
        try MigrationRunner.run(defaults: d)
        #expect(d.integer(forKey: SchemaVersion.key) == SchemaVersion.current)
    }

    @Test("Future saved version throws")
    func futureVersionThrows() {
        let d = freshDefaults()
        d.set(SchemaVersion.current + 5, forKey: SchemaVersion.key)
        #expect(throws: MigrationError.self) {
            try MigrationRunner.run(defaults: d)
        }
    }

    @Test("v1ToV2 placeholder doesn't mutate defaults")
    func v1ToV2PlaceholderIsNoOp() throws {
        let d = freshDefaults()
        d.set("retained", forKey: "someExistingKey")
        try migrateV1ToV2(d)
        #expect(d.string(forKey: "someExistingKey") == "retained")
    }

    /// Documents the workflow when a real v1->v2 migration is added.
    /// This test will be edited (not deleted) at that point — the
    /// stamping behavior is what stays true.
    @Test("Runner brings stale v1 data to current")
    func runnerWalksFromV1() throws {
        let d = freshDefaults()
        d.set(1, forKey: SchemaVersion.key)
        try MigrationRunner.run(defaults: d)
        #expect(d.integer(forKey: SchemaVersion.key) == SchemaVersion.current)
    }
}
