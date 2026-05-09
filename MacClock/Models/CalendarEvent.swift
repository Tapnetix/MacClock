import Foundation
import EventKit
import CoreGraphics

struct CalendarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarTitle: String
    let isAllDay: Bool

    // Store color as hex string for Codable support
    private let colorHex: String?

    var calendarColor: CGColor? {
        guard let hex = colorHex else { return nil }
        return CGColor.fromHex(hex)
    }

    var timeUntilStart: TimeInterval {
        startDate.timeIntervalSinceNow
    }

    var countdownString: String {
        let interval = timeUntilStart
        if interval < 0 { return "Now" }

        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "in \(minutes) min"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours < 24 {
            return remainingMinutes > 0 ? "in \(hours)h \(remainingMinutes)m" : "in \(hours)h"
        }

        return "Tomorrow"
    }

    init(from event: EKEvent) {
        self.id = event.eventIdentifier ?? UUID().uuidString
        self.title = event.title ?? "Untitled"
        self.startDate = event.startDate
        self.endDate = event.endDate
        self.calendarTitle = event.calendar?.title ?? ""
        self.colorHex = event.calendar?.cgColor?.toHex()
        self.isAllDay = event.isAllDay
    }

    init(id: String, title: String, startDate: Date, endDate: Date, calendarTitle: String, calendarColor: CGColor?, isAllDay: Bool) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarTitle = calendarTitle
        self.colorHex = calendarColor?.toHex()
        self.isAllDay = isAllDay
    }
}

// MARK: - CGColor Hex Conversion

extension CGColor {
    func toHex() -> String? {
        guard let components = self.components, components.count >= 3 else { return nil }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    static func fromHex(_ hex: String) -> CGColor? {
        // Preserve historical behaviour: bad input silently produces black
        // (the function's return type is optional but the previous
        // implementation never returned nil).
        let rgba = HexColor.parse(hex) ?? (0, 0, 0, 1)
        return CGColor(
            red: CGFloat(rgba.red),
            green: CGFloat(rgba.green),
            blue: CGFloat(rgba.blue),
            alpha: CGFloat(rgba.alpha)
        )
    }
}
