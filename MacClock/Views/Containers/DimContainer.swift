import SwiftUI

/// Wraps content with the auto-dim opacity modifier and owns the 60s tick
/// timer that re-evaluates the DimManager. Also owns the 9 theme/dim
/// onChange handlers that previously lived in ThemeChangeModifier, plus
/// reactive updates when weather sunrise/sunset changes.
///
/// `dimManager` is owned by `MainClockView` (so views outside the dimmed
/// region — alarm overlay, buttons, news ticker — can read `effectiveTheme`
/// at full opacity). DimContainer only owns the timer + lifecycle plumbing.
struct DimContainer<Content: View>: View {
    let settings: AppSettings
    let weather: WeatherData?
    let dimManager: DimManager
    @ViewBuilder let content: () -> Content

    @State private var dimTimer: Timer?

    var body: some View {
        content()
            .opacity(dimManager.currentDimLevel)
            .animation(.easeInOut(duration: 2.0), value: dimManager.currentDimLevel)
            .onAppear {
                update()
                dimTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    update()
                }
            }
            .onDisappear {
                dimTimer?.invalidate()
                dimTimer = nil
            }
            .onChange(of: weather?.sunrise) { _, _ in update() }
            .onChange(of: weather?.sunset) { _, _ in update() }
            .onChange(of: settings.autoDimEnabled) { _, _ in update() }
            .onChange(of: settings.autoDimMode) { _, _ in update() }
            .onChange(of: settings.autoDimLevel) { _, _ in update() }
            .onChange(of: settings.autoThemeEnabled) { _, _ in update() }
            .onChange(of: settings.autoThemeMode) { _, _ in update() }
            .onChange(of: settings.dayTheme) { _, _ in update() }
            .onChange(of: settings.nightThemeAuto) { _, _ in update() }
            .onChange(of: settings.colorTheme) { _, _ in update() }
            .onChange(of: settings.nightTheme) { _, _ in update() }
    }

    private func update() {
        dimManager.update(settings: settings, sunrise: weather?.sunrise, sunset: weather?.sunset)
    }
}
