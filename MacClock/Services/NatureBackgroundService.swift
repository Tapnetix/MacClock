import Foundation
import AppKit

actor NatureBackgroundService {
    private let cacheDirectory: URL
    private var cachedImages: [URL] = []

    // Curated nature/landscape image URLs from Unsplash (free to use)
    private let natureImageURLs = [
        // Mountains & Peaks
        "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&q=80",  // Alpine mountains
        "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1920&q=80",  // Mountain peak
        "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1920&q=80",  // Snowy mountain night
        "https://images.unsplash.com/photo-1454496522488-7a8e488e8606?w=1920&q=80",  // Himalayan peaks

        // Forests & Trees
        "https://images.unsplash.com/photo-1448375240586-882707db888b?w=1920&q=80",  // Misty forest
        "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1920&q=80",  // Sunlit forest
        "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?w=1920&q=80",  // Forest path
        "https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=1920&q=80",  // Tall trees

        // Lakes & Water
        "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=1920&q=80",  // Mountain lake
        "https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=1920&q=80",  // Waterfall
        "https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=1920&q=80",  // Lake reflection
        "https://images.unsplash.com/photo-1505765050516-f72dcac9c60e?w=1920&q=80",  // Autumn lake

        // Fields & Valleys
        "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1920&q=80",  // Green hills
        "https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=1920&q=80",  // Valley sunset
        "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1920&q=80",  // Foggy mountains
        "https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?w=1920&q=80",  // Rolling hills

        // Ocean & Coast
        "https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=1920&q=80",  // Tropical beach
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1920&q=80",  // Sandy beach
        "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=1920&q=80",  // Ocean waves
        "https://images.unsplash.com/photo-1484291470158-b8f8d608850d?w=1920&q=80",  // Coastal cliffs

        // Sky & Aurora
        "https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=1920&q=80",  // Northern lights
        "https://images.unsplash.com/photo-1475274047050-1d0c0975c63e?w=1920&q=80",  // Starry night
        "https://images.unsplash.com/photo-1532767153582-b1a0e5145009?w=1920&q=80",  // Pink sunset
        "https://images.unsplash.com/photo-1494548162494-384bba4ab999?w=1920&q=80",  // Golden sunrise
    ]

    private var currentIndex = 0
    private var hasLoadedCache = false

    init() {
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachePath.appendingPathComponent("MacClock/NatureBackgrounds", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func loadCachedImagesIfNeeded() {
        guard !hasLoadedCache else { return }
        hasLoadedCache = true

        if let contents = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            cachedImages = contents.filter { $0.pathExtension == "jpg" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }
    }

    func getNextImage() async -> NSImage? {
        // Ensure cache is loaded
        loadCachedImagesIfNeeded()

        // First try to get a cached image
        if !cachedImages.isEmpty {
            let imageURL = cachedImages[currentIndex % cachedImages.count]
            currentIndex += 1

            // Start downloading more in background if we don't have all
            if cachedImages.count < natureImageURLs.count {
                Task { await downloadNextImage() }
            }

            return NSImage(contentsOf: imageURL)
        }

        // No cached images - download one now
        if let image = await downloadNextImage() {
            return image
        }

        return nil
    }

    func getCurrentImage() async -> NSImage? {
        loadCachedImagesIfNeeded()

        if cachedImages.isEmpty {
            return await downloadNextImage()
        }

        let index = max(0, (currentIndex - 1)) % cachedImages.count
        return NSImage(contentsOf: cachedImages[index])
    }

    @discardableResult
    private func downloadNextImage() async -> NSImage? {
        let downloadIndex = cachedImages.count
        guard downloadIndex < natureImageURLs.count else { return nil }

        let urlString = natureImageURLs[downloadIndex]
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = NSImage(data: data) else { return nil }

            // Save to cache
            let filename = String(format: "nature_%02d.jpg", downloadIndex + 1)
            let fileURL = cacheDirectory.appendingPathComponent(filename)
            try data.write(to: fileURL)

            cachedImages.append(fileURL)
            cachedImages.sort { $0.lastPathComponent < $1.lastPathComponent }

            return image
        } catch {
            print("Failed to download nature image: \(error)")
            return nil
        }
    }

    func preloadImages(count: Int = 3) async {
        for _ in 0..<count {
            if cachedImages.count >= natureImageURLs.count { break }
            await downloadNextImage()
        }
    }

    var imageCount: Int {
        natureImageURLs.count
    }

    var cachedCount: Int {
        cachedImages.count
    }
}
