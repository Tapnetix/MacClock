import Foundation
import CoreGraphics

actor ICalService {
    private let session = URLSession.standardConfigured
    private let cacheKey = "cachedICalEvents"
    private let cacheDateKey = "cachedICalEventsDate"
    private let defaults = UserDefaults.standard

    /// Load cached events from UserDefaults
    nonisolated func loadCachedEvents() -> [CalendarEvent] {
        // Check if cache is from today
        if let cacheDate = defaults.object(forKey: cacheDateKey) as? Date {
            let today = Calendar.current.startOfDay(for: Date())
            let cacheDay = Calendar.current.startOfDay(for: cacheDate)
            if cacheDay != today {
                // Cache is stale (from a different day)
                return []
            }
        } else {
            return []
        }

        guard let data = defaults.data(forKey: cacheKey),
              let events = try? JSONDecoder().decode([CalendarEvent].self, from: data) else {
            return []
        }

        // Filter to only return events that haven't ended yet
        let now = Date()
        return events.filter { $0.endDate > now }
    }

    /// Save events to cache
    nonisolated func cacheEvents(_ events: [CalendarEvent]) {
        if let data = try? JSONEncoder().encode(events) {
            defaults.set(data, forKey: cacheKey)
            defaults.set(Date(), forKey: cacheDateKey)
        }
    }

    /// Clear the event cache (call when feed URLs change)
    nonisolated func clearCache() {
        defaults.removeObject(forKey: cacheKey)
        defaults.removeObject(forKey: cacheDateKey)
    }

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

    /// Parse ICS content into CalendarEvent array, expanding recurring events for today
    nonisolated func parseICS(_ content: String, feedName: String, colorHex: String) -> [CalendarEvent] {
        var events: [CalendarEvent] = []

        // Unfold lines: ICS continuation lines start with space or tab
        let unfoldedContent = content
            .replacingOccurrences(of: "\r\n ", with: "")
            .replacingOccurrences(of: "\r\n\t", with: "")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")

        let lines = unfoldedContent.components(separatedBy: .newlines)

        // First pass: collect all RECURRENCE-ID dates for today
        // These are dates where the original RRULE occurrence was modified/moved
        var recurrenceIdDates: Set<String> = [] // Key: "UID_date" to track which UID+date combos are overridden
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today.addingTimeInterval(86400)

        var inEvent = false
        var currentEvent: [String: String] = [:]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
            } else if trimmed == "END:VEVENT" {
                if inEvent, let recurrenceId = currentEvent["RECURRENCE-ID"], let uid = currentEvent["UID"] {
                    // Parse the RECURRENCE-ID date (the original date being replaced)
                    let recurrenceIdParams = currentEvent["RECURRENCE-ID_PARAMS"] ?? ""
                    let tzid = extractTZID(from: recurrenceIdParams)
                    if let originalDate = parseDateTime(recurrenceId, tzid: tzid) ?? parseDate(recurrenceId) {
                        let originalDay = Calendar.current.startOfDay(for: originalDate)
                        if originalDay == today {
                            // Extract base UID (remove _R... suffix if present)
                            let baseUid = uid.components(separatedBy: "_R").first ?? uid
                            recurrenceIdDates.insert("\(baseUid)_\(Int(today.timeIntervalSince1970))")
                        }
                    }
                }
                inEvent = false
            } else if inEvent {
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let keyPart = String(trimmed[..<colonIndex])
                    let value = String(trimmed[trimmed.index(after: colonIndex)...])
                    let key = keyPart.components(separatedBy: ";").first ?? keyPart
                    currentEvent[key] = value
                    currentEvent[key + "_PARAMS"] = keyPart
                }
            }
        }

        // Second pass: process events
        inEvent = false
        currentEvent = [:]

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = [:]
            } else if trimmed == "END:VEVENT" {
                if inEvent {
                    // RECURRENCE-ID events are modified instances - show directly if they match today
                    if currentEvent["RECURRENCE-ID"] != nil {
                        if let event = createEvent(from: currentEvent, feedName: feedName, colorHex: colorHex) {
                            if event.startDate >= today && event.startDate < tomorrow {
                                events.append(event)
                            }
                        }
                    } else if let rrule = currentEvent["RRULE"] {
                        // Check if this UID has a RECURRENCE-ID override for today
                        let uid = currentEvent["UID"] ?? ""
                        let baseUid = uid.components(separatedBy: "_R").first ?? uid
                        let overrideKey = "\(baseUid)_\(Int(today.timeIntervalSince1970))"

                        if !recurrenceIdDates.contains(overrideKey) {
                            // No override exists - expand the RRULE
                            let expandedEvents = expandRecurringEvent(properties: currentEvent, rrule: rrule, feedName: feedName, colorHex: colorHex)
                            events.append(contentsOf: expandedEvents)
                        }
                        // If override exists, skip RRULE expansion - the RECURRENCE-ID event will be used instead
                    } else if let event = createEvent(from: currentEvent, feedName: feedName, colorHex: colorHex) {
                        events.append(event)
                    }
                }
                inEvent = false
            } else if inEvent {
                if let colonIndex = trimmed.firstIndex(of: ":") {
                    let keyPart = String(trimmed[..<colonIndex])
                    let value = String(trimmed[trimmed.index(after: colonIndex)...])
                    let key = keyPart.components(separatedBy: ";").first ?? keyPart
                    currentEvent[key] = value
                    currentEvent[key + "_PARAMS"] = keyPart
                    if keyPart.contains("VALUE=DATE") && !keyPart.contains("VALUE=DATE-TIME") {
                        currentEvent[key + "_ALLDAY"] = "true"
                    }
                }
            }
        }

        // Deduplicate: when both a RECURRENCE-ID event and RRULE-generated event
        // exist for the same time, keep the RECURRENCE-ID one (it's the override)
        // RECURRENCE-ID events have IDs without underscore+timestamp suffix
        // RRULE-expanded events have IDs like "uid_timestamp"

        // Sort so RECURRENCE-ID events come first (they don't have _ in ID from expansion)
        let sortedEvents = events.sorted { e1, e2 in
            let e1IsRecurrenceId = !e1.id.contains("_\(Int(e1.startDate.timeIntervalSince1970))")
            let e2IsRecurrenceId = !e2.id.contains("_\(Int(e2.startDate.timeIntervalSince1970))")
            if e1IsRecurrenceId && !e2IsRecurrenceId { return true }
            if !e1IsRecurrenceId && e2IsRecurrenceId { return false }
            return false
        }

        var seen = Set<String>()
        var deduped: [CalendarEvent] = []

        for event in sortedEvents {
            let key = "\(event.title)_\(Int(event.startDate.timeIntervalSince1970 / 60))"
            if !seen.contains(key) {
                seen.insert(key)
                deduped.append(event)
            }
        }

        return deduped
    }

    /// Expand a recurring event for today based on RRULE
    private nonisolated func expandRecurringEvent(properties: [String: String], rrule: String, feedName: String, colorHex: String) -> [CalendarEvent] {
        guard let baseEvent = createEvent(from: properties, feedName: feedName, colorHex: colorHex) else {
            return []
        }

        // Parse RRULE components
        var rruleDict: [String: String] = [:]
        for component in rrule.components(separatedBy: ";") {
            let parts = component.components(separatedBy: "=")
            if parts.count == 2 {
                rruleDict[parts[0]] = parts[1]
            }
        }

        guard let freq = rruleDict["FREQ"] else { return [baseEvent] }

        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return [baseEvent]
        }

        // Parse UNTIL date if present
        var untilDate: Date? = nil
        if let until = rruleDict["UNTIL"] {
            untilDate = parseDate(String(until.prefix(8))) ?? parseDateTime(until)
        }

        // Check if recurrence has ended
        if let until = untilDate, until < today {
            return []
        }

        // Parse COUNT if present (maximum number of occurrences)
        let count = Int(rruleDict["COUNT"] ?? "0")

        // Parse BYDAY for weekly events
        let byDay = rruleDict["BYDAY"]?.components(separatedBy: ",") ?? []

        // Parse interval (default 1)
        let interval = Int(rruleDict["INTERVAL"] ?? "1") ?? 1

        // Parse EXDATE (exception dates - when event does NOT occur)
        var exDates: Set<Date> = []
        if let exdateStr = properties["EXDATE"] {
            // EXDATE can have multiple dates separated by comma
            for dateStr in exdateStr.components(separatedBy: ",") {
                let cleanDate = dateStr.trimmingCharacters(in: .whitespaces)
                if let date = parseDate(String(cleanDate.prefix(8))) {
                    exDates.insert(Calendar.current.startOfDay(for: date))
                } else if let date = parseDateTime(cleanDate) {
                    exDates.insert(Calendar.current.startOfDay(for: date))
                }
            }
        }

        // Check if today is an exception date
        if exDates.contains(today) {
            return []
        }

        let eventDuration = baseEvent.endDate.timeIntervalSince(baseEvent.startDate)
        let baseStartOfDay = Calendar.current.startOfDay(for: baseEvent.startDate)
        let timeOfDay = baseEvent.startDate.timeIntervalSince(baseStartOfDay)

        var events: [CalendarEvent] = []

        switch freq {
        case "DAILY":
            // Check if today is a valid occurrence
            let daysSinceStart = Calendar.current.dateComponents([.day], from: baseStartOfDay, to: today).day ?? 0

            // Check COUNT limit
            if let maxCount = count, maxCount > 0 {
                let occurrenceNumber = (daysSinceStart / interval) + 1
                if occurrenceNumber > maxCount {
                    break
                }
            }

            if daysSinceStart >= 0 && daysSinceStart % interval == 0 {
                let occurrenceStart = today.addingTimeInterval(timeOfDay)
                if occurrenceStart >= today && occurrenceStart < tomorrow {
                    events.append(CalendarEvent(
                        id: baseEvent.id + "_\(today.timeIntervalSince1970)",
                        title: baseEvent.title,
                        startDate: occurrenceStart,
                        endDate: occurrenceStart.addingTimeInterval(eventDuration),
                        calendarTitle: feedName,
                        calendarColor: baseEvent.calendarColor,
                        isAllDay: baseEvent.isAllDay
                    ))
                }
            }

        case "WEEKLY":
            let todayWeekday = Calendar.current.component(.weekday, from: today)
            let weekdayMap = ["SU": 1, "MO": 2, "TU": 3, "WE": 4, "TH": 5, "FR": 6, "SA": 7]

            // Determine which weekday(s) the event recurs on
            var targetWeekdays: [Int] = []
            if !byDay.isEmpty {
                for day in byDay {
                    // Handle "1MO" style (first Monday) - just extract weekday part
                    let weekdayPart = day.filter { $0.isLetter }
                    if let weekdayNum = weekdayMap[weekdayPart] {
                        targetWeekdays.append(weekdayNum)
                    }
                }
            } else {
                // No BYDAY - recurs on same day of week as original
                let originalWeekday = Calendar.current.component(.weekday, from: baseEvent.startDate)
                targetWeekdays = [originalWeekday]
            }

            // Check if today matches any target weekday
            guard targetWeekdays.contains(todayWeekday) else { break }

            // Event must have started (today >= first occurrence date)
            guard today >= baseStartOfDay else { break }

            // Calculate weeks since start using actual days elapsed
            let daysSinceStart = Calendar.current.dateComponents([.day], from: baseStartOfDay, to: today).day ?? 0
            let weeksSinceStart = daysSinceStart / 7

            // Check COUNT limit - occurrence number is (weeksSinceStart / interval) + 1
            if let maxCount = count, maxCount > 0 {
                let occurrenceNumber = (weeksSinceStart / interval) + 1
                if occurrenceNumber > maxCount {
                    break // Exceeded COUNT limit
                }
            }

            // Check interval
            if weeksSinceStart % interval == 0 {
                let occurrenceStart = today.addingTimeInterval(timeOfDay)
                events.append(CalendarEvent(
                    id: baseEvent.id + "_\(today.timeIntervalSince1970)",
                    title: baseEvent.title,
                    startDate: occurrenceStart,
                    endDate: occurrenceStart.addingTimeInterval(eventDuration),
                    calendarTitle: feedName,
                    calendarColor: baseEvent.calendarColor,
                    isAllDay: baseEvent.isAllDay
                ))
            }

        case "MONTHLY":
            let weekdayMap = ["SU": 1, "MO": 2, "TU": 3, "WE": 4, "TH": 5, "FR": 6, "SA": 7]
            var matchesToday = false

            if !byDay.isEmpty {
                // BYDAY specified - handle patterns like "1FR" (first Friday), "2MO" (second Monday)
                let todayWeekday = Calendar.current.component(.weekday, from: today)
                let todayWeekOfMonth = (Calendar.current.component(.day, from: today) - 1) / 7 + 1

                for day in byDay {
                    let weekdayPart = day.filter { $0.isLetter }
                    let weekNumPart = day.filter { $0.isNumber || $0 == "-" }

                    guard let targetWeekday = weekdayMap[weekdayPart] else { continue }

                    // Check if weekday matches
                    if targetWeekday != todayWeekday { continue }

                    // Check week number if specified (e.g., "1" for first, "2" for second, "-1" for last)
                    if weekNumPart.isEmpty {
                        // No week number - matches any occurrence of this weekday
                        matchesToday = true
                    } else if let weekNum = Int(weekNumPart) {
                        if weekNum > 0 {
                            // Positive: nth occurrence (1 = first, 2 = second)
                            if todayWeekOfMonth == weekNum {
                                matchesToday = true
                            }
                        } else {
                            // Negative: from end of month (-1 = last)
                            // Calculate if today is the last occurrence of this weekday
                            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: today)?.count ?? 30
                            let todayDayNum = Calendar.current.component(.day, from: today)
                            let daysRemaining = daysInMonth - todayDayNum
                            // If less than 7 days remain, this is the last occurrence
                            if weekNum == -1 && daysRemaining < 7 {
                                matchesToday = true
                            }
                        }
                    }
                }
            } else {
                // No BYDAY - recurs on same day of month
                let todayDay = Calendar.current.component(.day, from: today)
                let originalDay = Calendar.current.component(.day, from: baseEvent.startDate)
                matchesToday = (todayDay == originalDay)
            }

            if matchesToday {
                let monthsSinceStart = Calendar.current.dateComponents([.month], from: baseStartOfDay, to: today).month ?? 0

                // Check COUNT limit
                if let maxCount = count, maxCount > 0 {
                    let occurrenceNumber = (monthsSinceStart / interval) + 1
                    if occurrenceNumber > maxCount {
                        break
                    }
                }

                if monthsSinceStart >= 0 && monthsSinceStart % interval == 0 {
                    let occurrenceStart = today.addingTimeInterval(timeOfDay)
                    events.append(CalendarEvent(
                        id: baseEvent.id + "_\(today.timeIntervalSince1970)",
                        title: baseEvent.title,
                        startDate: occurrenceStart,
                        endDate: occurrenceStart.addingTimeInterval(eventDuration),
                        calendarTitle: feedName,
                        calendarColor: baseEvent.calendarColor,
                        isAllDay: baseEvent.isAllDay
                    ))
                }
            }

        default:
            // For unsupported frequencies, just return base event if it's today
            if baseEvent.startDate >= today && baseEvent.startDate < tomorrow {
                events.append(baseEvent)
            }
        }

        return events
    }

    private nonisolated func createEvent(from properties: [String: String], feedName: String, colorHex: String) -> CalendarEvent? {
        guard let dtstart = properties["DTSTART"] else { return nil }

        let uid = properties["UID"] ?? UUID().uuidString
        let summary = unescapeICSString(properties["SUMMARY"] ?? "Untitled")
        let isAllDay = properties["DTSTART_ALLDAY"] == "true"

        let startDate: Date
        let endDate: Date

        // Extract TZID from params if present
        let startParams = properties["DTSTART_PARAMS"] ?? ""
        let endParams = properties["DTEND_PARAMS"] ?? ""
        let startTzid = extractTZID(from: startParams)
        let endTzid = extractTZID(from: endParams)

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
            guard let start = parseDateTime(dtstart, tzid: startTzid) else { return nil }
            startDate = start
            if let dtend = properties["DTEND"], let end = parseDateTime(dtend, tzid: endTzid) {
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

    private nonisolated func extractTZID(from params: String) -> String? {
        // Extract TZID from params like "DTSTART;TZID=America/New_York"
        guard let tzidRange = params.range(of: "TZID=") else { return nil }
        let afterTzid = params[tzidRange.upperBound...]
        // TZID value ends at ; or end of string
        if let semicolonIndex = afterTzid.firstIndex(of: ";") {
            return String(afterTzid[..<semicolonIndex])
        }
        return String(afterTzid)
    }

    private nonisolated func unescapeICSString(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }

    private nonisolated func parseDate(_ string: String) -> Date? {
        // Format: 20260129
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }

    private nonisolated func parseDateTime(_ string: String, tzid: String? = nil) -> Date? {
        var dateString = string

        // Handle timezone suffix
        let isUTC = dateString.hasSuffix("Z")
        if isUTC {
            dateString = String(dateString.dropLast())
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Determine timezone: UTC > explicit TZID > local
        if isUTC {
            formatter.timeZone = TimeZone(identifier: "UTC")
        } else if let tzid = tzid, let tz = TimeZone(identifier: tzid) {
            formatter.timeZone = tz
        } else {
            formatter.timeZone = TimeZone.current
        }

        return formatter.date(from: dateString)
    }

    private nonisolated func colorFromHex(_ hex: String) -> CGColor {
        let rgba = HexColor.parse(hex) ?? (0, 0, 0, 1)
        return CGColor(
            red: CGFloat(rgba.red),
            green: CGFloat(rgba.green),
            blue: CGFloat(rgba.blue),
            alpha: CGFloat(rgba.alpha)
        )
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
