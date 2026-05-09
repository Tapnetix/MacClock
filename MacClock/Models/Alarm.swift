import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: DateComponents  // hour and minute
    var label: String
    var isEnabled: Bool
    var repeatDays: Set<Weekday>
    var soundName: String?  // nil = no sound (default)
    var snoozeDuration: Int  // minutes: 5, 10, or 15

    enum Weekday: Int, Codable, CaseIterable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7

        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }

        static var weekdays: Set<Weekday> {
            [.monday, .tuesday, .wednesday, .thursday, .friday]
        }

        static var weekends: Set<Weekday> {
            [.saturday, .sunday]
        }
    }

    var repeatDescription: String {
        if repeatDays.isEmpty { return "Never" }
        if repeatDays == Weekday.weekdays { return "Weekdays" }
        if repeatDays == Weekday.weekends { return "Weekends" }
        if repeatDays.count == 7 { return "Every day" }
        return repeatDays.sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName }
            .joined(separator: ", ")
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    var timeString: String {
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0
        guard let date = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) else {
            return ""
        }
        return Self.timeFormatter.string(from: date)
    }

    var nextFireDate: Date? {
        guard isEnabled else { return nil }

        let calendar = Calendar.current
        let now = Date()
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0

        // If no repeat days, find next occurrence
        if repeatDays.isEmpty {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = minute
            components.second = 0

            if let candidate = calendar.date(from: components), candidate > now {
                return candidate
            }
            // Tomorrow
            components.day! += 1
            return calendar.date(from: components)
        }

        // Find next matching weekday
        for dayOffset in 0..<8 {
            guard let candidate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = Weekday(rawValue: calendar.component(.weekday, from: candidate))

            if let weekday = weekday, repeatDays.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: candidate)
                components.hour = hour
                components.minute = minute
                components.second = 0

                if let fireDate = calendar.date(from: components), fireDate > now {
                    return fireDate
                }
            }
        }

        return nil
    }
}
