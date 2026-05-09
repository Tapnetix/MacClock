import Foundation
import OSLog

/// Schema version for everything `AppSettings` reads from `UserDefaults`.
/// Bump this *and* add a corresponding `migrateVNToVN+1` function whenever
/// you change the on-disk shape of any persisted value.
///
/// Conventions:
/// - Version 0 = no version key written = "fresh install or pre-migration build".
///   Treated as v1 (the data shape at the time this runner was introduced).
/// - Each migration takes UserDefaults and is *idempotent on UserDefaults*
///   so re-running it on already-migrated data is a no-op.
enum SchemaVersion {
    static let current: Int = 1
    static let key = "appSettingsSchemaVersion"
}

enum MigrationError: Error {
    /// Saved version is newer than `current`. Almost certainly means the user
    /// downgraded the app. We refuse to silently re-shape future-version data.
    case savedVersionFromFuture(saved: Int, current: Int)
}

struct MigrationRunner {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MacClock", category: "Migration")

    /// Read the saved version, run migrations until we reach `current`, write
    /// the new version. Throws if the saved version is from the future.
    /// Logs and re-throws on individual migration failures.
    ///
    /// Concurrency: this is single-threaded — call it once at app startup
    /// (from `MacClockApp.init()`) before any other code reads the affected
    /// UserDefaults keys. No locks needed.
    static func run(defaults: UserDefaults = .standard) throws {
        var saved = defaults.object(forKey: SchemaVersion.key) as? Int ?? 0
        if saved == 0 {
            // No version recorded. Either a fresh install (no saved data)
            // or an existing install from before this runner shipped. Either
            // way, today's data shape *is* v1, so just stamp it.
            saved = 1
        }

        if saved > SchemaVersion.current {
            throw MigrationError.savedVersionFromFuture(saved: saved, current: SchemaVersion.current)
        }

        while saved < SchemaVersion.current {
            let next = saved + 1
            logger.info("Running schema migration v\(saved) -> v\(next)")
            try Self.migration(from: saved)(defaults)
            saved = next
        }

        defaults.set(saved, forKey: SchemaVersion.key)
    }

    /// Dispatch table. Adding a new migration:
    /// 1. Bump `SchemaVersion.current`.
    /// 2. Add a `migrateVNToVN+1(_:)` function below.
    /// 3. Add a case here.
    /// 4. Add a SchemaMigrationTests case.
    private static func migration(from version: Int) -> (UserDefaults) throws -> Void {
        switch version {
        case 1: return migrateV1ToV2
        default:
            // Should be unreachable given the loop bound; assertion guards
            // against a future contributor bumping `current` without adding
            // a case here.
            return { _ in
                assertionFailure("No migration registered for v\(version) -> v\(version + 1)")
            }
        }
    }
}

/// Placeholder no-op migration. Exists so the *infrastructure* is in place;
/// the next real schema change replaces this body.
///
/// To add a future migration, e.g. v2 -> v3:
/// 1. Bump `SchemaVersion.current` to 3.
/// 2. Add `func migrateV2ToV3(_ defaults: UserDefaults) throws { ... }`.
/// 3. Add `case 2: return migrateV2ToV3` to MigrationRunner.migration(from:).
/// 4. Add a test in SchemaMigrationTests that pre-populates v2-shaped data,
///    runs the runner, and asserts the v3 shape.
func migrateV1ToV2(_ defaults: UserDefaults) throws {
    // Intentional no-op. See file header.
    _ = defaults
}
