import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let windowLevel: WindowLevel
    let windowOpacity: Double
    let onWindow: ((NSWindow) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                applyWindowSettings(window)

                // Activate app and make window key so text fields can receive focus
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)

                onWindow?(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                applyWindowSettings(window)
            }
        }
    }

    private func applyWindowSettings(_ window: NSWindow) {
        // Apply window level
        switch windowLevel {
        case .normal:
            window.level = .normal
            window.collectionBehavior = [.managed, .participatesInCycle]
        case .floating:
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        case .desktop:
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        }

        // Apply opacity
        window.alphaValue = windowOpacity
    }
}

extension View {
    func windowLevel(_ level: WindowLevel, opacity: Double = 1.0, onWindow: ((NSWindow) -> Void)? = nil) -> some View {
        background(WindowAccessor(windowLevel: level, windowOpacity: opacity, onWindow: onWindow))
    }
}
