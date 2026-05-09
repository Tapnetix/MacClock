import SwiftUI

/// Common interface for tab enums used by TabButton.
/// Any enum with a String rawValue and an SFSymbol icon string can conform.
protocol TabKind: Hashable {
    /// SFSymbol name used as the tab's icon.
    var icon: String { get }
    /// Display title for the tab.
    var title: String { get }
}

/// Generic tab button shared by Settings and AlarmPanel.
/// Replaces the duplicated AlarmTabButton + SettingsTabButton structs.
struct TabButton<T: TabKind>: View {
    let tab: T
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                    .frame(height: 20)
                Text(tab.title)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
    }
}
