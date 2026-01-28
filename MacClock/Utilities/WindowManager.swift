import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let windowLevel: WindowLevel
    let onWindow: ((NSWindow) -> Void)?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                applyWindowLevel(window)
                onWindow?(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                applyWindowLevel(window)
            }
        }
    }

    private func applyWindowLevel(_ window: NSWindow) {
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
    }
}

extension View {
    func windowLevel(_ level: WindowLevel, onWindow: ((NSWindow) -> Void)? = nil) -> some View {
        background(WindowAccessor(windowLevel: level, onWindow: onWindow))
    }
}
