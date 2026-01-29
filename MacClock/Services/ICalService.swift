import Foundation
import CoreGraphics

actor ICalService {
    private let session = URLSession.shared

    /// Fetch events from an iCal feed URL
    func fetchEvents(from feed: ICalFeed) async throws -> [CalendarEvent] {
        guard feed.isEnabled else { return [] }
        guard let url = URL(string: feed.url) else {
            throw ICalError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        guard let content = String(data: data, encoding: .utf8) else {
            throw ICalError.invalidContent
        }

        return parseICS(content, feedName: feed.name, colorHex: feed.colorHex)
    }

    /// Parse ICS content into CalendarEvent array
    nonisolated func parseICS(_ content: String, feedName: String, colorHex: String) -> [CalendarEvent] {
        var events: [CalendarEvent] = []
        let lines = content.components(separatedBy: .newlines)

        var inEvent = false
        var currentEvent: [String: String] = [:]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
            } else if trimmed == "END:VEVENT" {
                if inEvent {
                    if let event = createEvent(from: currentEvent, feedName: feedName, colorHex: colorHex) {
                        events.append(event)
                    }
                }
                inEvent = false
            } else if inEvent {
                // Parse property:value or property;params:value
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let keyPart = String(trimmed[..<colonIndex])
                    let value = String(trimmed[trimmed.index(after: colonIndex)...])

                    // Handle properties with parameters (e.g., DTSTART;VALUE=DATE:20260129)
                    let key = keyPart.components(separatedBy: ";").first ?? keyPart
                    currentEvent[key] = value

                    // Check for VALUE=DATE parameter (all-day events)
                    if keyPart.contains("VALUE=DATE") {
                        currentEvent[key + "_ALLDAY"] = "true"
                    }
                }
            }
        }

        return events
    }

    private nonisolated func createEvent(from properties: [String: String], feedName: String, colorHex: String) -> CalendarEvent? {
        guard let dtstart = properties["DTSTART"] else { return nil }

        let uid = properties["UID"] ?? UUID().uuidString
        let summary = properties["SUMMARY"] ?? "Untitled"
        let isAllDay = properties["DTSTART_ALLDAY"] == "true"

        let startDate: Date
        let endDate: Date

        if isAllDay {
            // All-day format: 20260129
            guard let start = parseDate(dtstart) else { return nil }
            startDate = start
            if let dtend = properties["DTEND"], let end = parseDate(dtend) {
                endDate = end
            } else {
                endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
            }
        } else {
            // DateTime format: 20260129T100000Z or 20260129T100000
            guard let start = parseDateTime(dtstart) else { return nil }
            startDate = start
            if let dtend = properties["DTEND"], let end = parseDateTime(dtend) {
                endDate = end
            } else {
                endDate = startDate.addingTimeInterval(3600) // Default 1 hour
            }
        }

        let color = colorFromHex(colorHex)

        return CalendarEvent(
            id: uid,
            title: summary,
            startDate: startDate,
            endDate: endDate,
            calendarTitle: feedName,
            calendarColor: color,
            isAllDay: isAllDay
        )
    }

    private nonisolated func parseDate(_ string: String) -> Date? {
        // Format: 20260129
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }

    private nonisolated func parseDateTime(_ string: String) -> Date? {
        var dateString = string

        // Handle timezone suffix
        let isUTC = dateString.hasSuffix("Z")
        if isUTC {
            dateString = String(dateString.dropLast())
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = isUTC ? TimeZone(identifier: "UTC") : TimeZone.current

        return formatter.date(from: dateString)
    }

    private nonisolated func colorFromHex(_ hex: String) -> CGColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        return CGColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

enum ICalError: Error, LocalizedError {
    case invalidURL
    case invalidContent
    case networkError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid calendar URL"
        case .invalidContent: return "Could not read calendar content"
        case .networkError: return "Network error fetching calendar"
        }
    }
}
