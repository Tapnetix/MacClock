import SwiftUI

/// Lifecycle-only sibling that drives DockIconRenderer. Renders a zero-sized
/// invisible view so it participates in onAppear/onDisappear without
/// affecting layout (an EmptyView is not guaranteed to drive lifecycle on
/// every SwiftUI release).
struct DockContainer: View {
    let settings: AppSettings

    @State private var dockIconRenderer = DockIconRenderer()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                dockIconRenderer.use24Hour = settings.use24Hour
                dockIconRenderer.startUpdating()
            }
            .onDisappear {
                dockIconRenderer.stopUpdating()
            }
            .onChange(of: settings.use24Hour) { _, newValue in
                dockIconRenderer.use24Hour = newValue
            }
    }
}
