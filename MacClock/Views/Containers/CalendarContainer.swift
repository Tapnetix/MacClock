import SwiftUI

/// Owns calendar event aggregation across local (EventKit) and iCal feeds.
/// Exposes (nextEvent, todayEvents) to its content closure so the parent
/// can render CalendarCountdownView (top bar) and CalendarAgendaView (side
/// panel) without owning the underlying services or timer.
struct CalendarContainer<Content: View>: View {
    let settings: AppSettings
    @ViewBuilder let content: (CalendarEvent?, [CalendarEvent]) -> Content

    @State private var calendarService = CalendarService()
    @State private var iCalService = ICalService()
    @State private var nextEvent: CalendarEvent?
    @State private var todayEvents: [CalendarEvent] = []
    @State private var iCalEvents: [CalendarEvent] = []
    @State private var iCalTimer: Timer?

    var body: some View {
        content(nextEvent, todayEvents)
            .onAppear {
                if settings.calendarEnabled {
                    loadCalendarEvents()
                }
                // Setup iCal refresh timer (every 15 minutes)
                iCalTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { _ in
                    loadCalendarEvents()
                }
            }
            .onDisappear {
                iCalTimer?.invalidate()
                iCalTimer = nil
            }
            .onChange(of: settings.calendarEnabled) { _, enabled in
                if enabled {
                    loadCalendarEvents()
                }
            }
            .onChange(of: settings.iCalFeeds) { _, _ in
                // Clear cache when feeds change (URL updated, feed added/removed)
                iCalService.clearCache()
                loadCalendarEvents()
            }
    }

    private func loadCalendarEvents() {
        // Local calendar events - show immediately, filter out ended events
        let now = Date()
        let localEvents = calendarService.fetchTodayEvents(from: settings.selectedCalendarIDs)
            .filter { $0.endDate > now }

        // Load cached iCal events for immediate display
        let cachedEvents = iCalService.loadCachedEvents()

        // Merge local and cached events for immediate display
        var allEvents = localEvents + cachedEvents
        allEvents = deduplicateEvents(allEvents)
        todayEvents = allEvents.sorted { $0.startDate < $1.startDate }

        // Update next event
        nextEvent = todayEvents.first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }

        // Fetch fresh iCal events asynchronously
        guard !settings.iCalFeeds.isEmpty else { return }

        Task {
            var fetchedEvents: [CalendarEvent] = []
            let today = Calendar.current.startOfDay(for: Date())
            guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else { return }

            for feed in settings.iCalFeeds where feed.isEnabled {
                do {
                    let events = try await iCalService.fetchEvents(from: feed)
                    // Filter to today's events that haven't ended yet
                    let now = Date()
                    let todayEventsFetched = events.filter { $0.startDate >= today && $0.startDate < tomorrow && $0.endDate > now }
                    fetchedEvents.append(contentsOf: todayEventsFetched)
                } catch {
                    print("Failed to fetch iCal feed \(feed.name): \(error)")
                }
            }

            // Cache the fetched events
            iCalService.cacheEvents(fetchedEvents)

            await MainActor.run {
                iCalEvents = fetchedEvents
                // Merge local and fresh iCal events
                var allEvents = localEvents + fetchedEvents
                allEvents = deduplicateEvents(allEvents)
                todayEvents = allEvents.sorted { $0.startDate < $1.startDate }
                // Update next event
                let now = Date()
                nextEvent = todayEvents.first { $0.startDate > now || ($0.startDate <= now && $0.endDate > now) }
            }
        }
    }

    private func deduplicateEvents(_ events: [CalendarEvent]) -> [CalendarEvent] {
        var seen = Set<String>()
        return events.filter { event in
            let key = "\(event.title)_\(Int(event.startDate.timeIntervalSince1970 / 60))"
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}
