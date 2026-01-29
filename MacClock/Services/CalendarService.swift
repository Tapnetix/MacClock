import Foundation
import EventKit

@Observable
final class CalendarService {
    private let eventStore = EKEventStore()
    private(set) var authorizationStatus: EKAuthorizationStatus = .notDetermined
    private(set) var availableCalendars: [EKCalendar] = []

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if authorizationStatus == .fullAccess || authorizationStatus == .authorized {
            loadCalendars()
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                authorizationStatus = granted ? .fullAccess : .denied
                if granted {
                    loadCalendars()
                }
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    private func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
    }

    func fetchTodayEvents(from calendarIDs: [String]) -> [CalendarEvent] {
        guard authorizationStatus == .fullAccess || authorizationStatus == .authorized else {
            return []
        }

        let calendars = availableCalendars.filter { calendarIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else { return [] }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)
        return events
            .map { CalendarEvent(from: $0) }
            .sorted { $0.startDate < $1.startDate }
    }

    func fetchNextEvent(from calendarIDs: [String]) -> CalendarEvent? {
        let now = Date()
        return fetchTodayEvents(from: calendarIDs)
            .first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }
    }
}
