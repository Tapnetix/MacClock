import SwiftUI
import AppKit

/// Owns the background image rendering, the nature-cycling crossfade, and the
/// timer for periodic image rotation. The container renders the background
/// directly (background image is the bottom layer of the parent ZStack).
struct BackgroundContainer: View {
    let settings: AppSettings
    let backgroundManager: BackgroundManager
    let weather: WeatherData?
    let geometry: GeometryProxy

    @State private var natureService = NatureBackgroundService()
    @State private var currentNatureImage: NSImage?
    @State private var previousBackgroundImage: NSImage?
    @State private var backgroundOpacity: Double = 1.0
    @State private var backgroundTimer: Timer?

    private var displayedBackgroundImage: NSImage? {
        switch settings.backgroundMode {
        case .nature:
            return currentNatureImage
        case .custom:
            return backgroundManager.currentImage
        case .timeOfDay:
            return backgroundManager.currentImage
        }
    }

    var body: some View {
        ZStack {
            // Previous background (for crossfade)
            if let prevImage = previousBackgroundImage {
                Image(nsImage: prevImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }

            // Current background
            if let image = displayedBackgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(backgroundOpacity)
            } else {
                Color.black
            }
        }
        .onAppear {
            loadInitialBackground()
            setupBackgroundTimer()
        }
        .onDisappear {
            backgroundTimer?.invalidate()
            backgroundTimer = nil
        }
        .onChange(of: settings.backgroundMode) { _, _ in
            loadInitialBackground()
            setupBackgroundTimer()
        }
        .onChange(of: settings.backgroundCycleInterval) { _, _ in
            setupBackgroundTimer()
        }
        .onChange(of: settings.customBackgroundBookmark) { _, newBookmark in
            if settings.backgroundMode == .custom {
                let sunrise = weather?.sunrise ?? Constants.defaultSunriseToday()
                let sunset = weather?.sunset ?? Constants.defaultSunsetToday()
                backgroundManager.updateBackground(
                    sunrise: sunrise,
                    sunset: sunset,
                    customBookmark: newBookmark
                )
            }
        }
    }

    private func loadInitialBackground() {
        switch settings.backgroundMode {
        case .nature:
            Task {
                currentNatureImage = await natureService.getNextImage()
            }
        case .timeOfDay, .custom:
            let sunrise = weather?.sunrise ?? Constants.defaultSunriseToday()
            let sunset = weather?.sunset ?? Constants.defaultSunsetToday()
            backgroundManager.updateBackground(
                sunrise: sunrise,
                sunset: sunset,
                customBookmark: settings.backgroundMode == .custom ? settings.customBackgroundBookmark : nil
            )
        }
    }

    private func setupBackgroundTimer() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil

        guard settings.backgroundMode == .nature else { return }

        backgroundTimer = Timer.scheduledTimer(withTimeInterval: settings.backgroundCycleInterval, repeats: true) { _ in
            Task {
                let newImage = await natureService.getNextImage()
                await MainActor.run {
                    transitionToNewBackground(newImage)
                }
            }
        }
    }

    private func transitionToNewBackground(_ newImage: NSImage?) {
        guard let newImage = newImage else { return }

        // Store current as previous
        previousBackgroundImage = currentNatureImage

        // Set new image immediately but invisible
        currentNatureImage = newImage
        backgroundOpacity = 0.0

        // Animate fade in
        withAnimation(.easeInOut(duration: 1.5)) {
            backgroundOpacity = 1.0
        }

        // Clear previous after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            previousBackgroundImage = nil
        }
    }
}
