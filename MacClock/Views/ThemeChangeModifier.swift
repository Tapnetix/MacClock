import SwiftUI

// MARK: - Theme Change Modifier

struct ThemeChangeModifier: ViewModifier {
    let settings: AppSettings
    let dimManager: DimManager
    let sunrise: Date?
    let sunset: Date?

    func body(content: Content) -> some View {
        content
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
        dimManager.update(settings: settings, sunrise: sunrise, sunset: sunset)
    }
}

extension View {
    func onThemeSettingsChange(settings: AppSettings, dimManager: DimManager, sunrise: Date?, sunset: Date?) -> some View {
        modifier(ThemeChangeModifier(settings: settings, dimManager: dimManager, sunrise: sunrise, sunset: sunset))
    }
}
