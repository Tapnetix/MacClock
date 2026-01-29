import Foundation
import EventKit

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarTitle: String
    let calendarColor: CGColor?
    let isAllDay: Bool

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
        self.calendarColor = event.calendar?.cgColor
        self.isAllDay = event.isAllDay
    }

    init(id: String, title: String, startDate: Date, endDate: Date, calendarTitle: String, calendarColor: CGColor?, isAllDay: Bool) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendarTitle = calendarTitle
        self.calendarColor = calendarColor
        self.isAllDay = isAllDay
    }
}
