import Foundation
import Testing
@testable import MacClock

@Suite("Cache")
struct CacheTests {
    private struct Fixture: Codable, Equatable {
        let id: Int
        let name: String
    }

    private func uniqueCache<T: Codable>(_ type: T.Type, ttl: TimeInterval? = nil) -> (Cache<T>, URL) {
        let filename = "cache-test-\(UUID().uuidString).json"
        let cache = Cache<T>(filename: filename, ttl: ttl)!
        let url = Cache<T>.cacheDirectory()!.appendingPathComponent(filename)
        return (cache, url)
    }

    @Test("Round-trips a Codable value")
    func roundTrip() {
        let (cache, url) = uniqueCache(Fixture.self)
        defer { try? FileManager.default.removeItem(at: url) }

        let value = Fixture(id: 7, name: "hello")
        cache.save(value)
        #expect(cache.load() == value)
    }

    @Test("Missing file returns nil")
    func missingFile() {
        let (cache, url) = uniqueCache(Fixture.self)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(cache.load() == nil)
    }

    @Test("Corrupt file is deleted and nil returned")
    func corruptFile() throws {
        let (cache, url) = uniqueCache(Fixture.self)
        defer { try? FileManager.default.removeItem(at: url) }

        try "this is not json".data(using: .utf8)!.write(to: url)
        #expect(cache.load() == nil)
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
    }

    @Test("TTL: expired entries return nil")
    func ttlExpired() throws {
        let (cache, url) = uniqueCache(Fixture.self, ttl: 0.5)
        defer { try? FileManager.default.removeItem(at: url) }

        cache.save(Fixture(id: 1, name: "x"))
        // Backdate the file's mtime to 10 seconds ago
        let pastDate = Date().addingTimeInterval(-10)
        try FileManager.default.setAttributes([.modificationDate: pastDate], ofItemAtPath: url.path)
        #expect(cache.load() == nil)
    }

    @Test("TTL: fresh entries return value")
    func ttlFresh() {
        let (cache, url) = uniqueCache(Fixture.self, ttl: 60)
        defer { try? FileManager.default.removeItem(at: url) }

        cache.save(Fixture(id: 1, name: "fresh"))
        #expect(cache.load()?.id == 1)
    }

    @Test("Clear removes the file")
    func clearRemovesFile() {
        let (cache, url) = uniqueCache(Fixture.self)
        cache.save(Fixture(id: 2, name: "y"))
        #expect(FileManager.default.fileExists(atPath: url.path))
        cache.clear()
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
    }

    @Test("Concurrent writes don't corrupt the file")
    func concurrentWrites() async {
        let (cache, url) = uniqueCache(Fixture.self)
        defer { try? FileManager.default.removeItem(at: url) }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    cache.save(Fixture(id: i, name: "concurrent-\(i)"))
                }
            }
        }

        // Whichever write won, the file is decodable (no torn write).
        let loaded = cache.load()
        #expect(loaded != nil)
    }

    @Test("Cache directory is created on first use")
    func directoryCreated() {
        let dir = Cache<Fixture>.cacheDirectory()
        #expect(dir != nil)
        #expect(FileManager.default.fileExists(atPath: dir!.path))
    }
}
