import Foundation

struct WorldClock: Identifiable, Codable, Equatable {
    let id: UUID
    var cityName: String
    var timezoneIdentifier: String

    var timezone: TimeZone? {
        TimeZone(identifier: timezoneIdentifier)
    }

    var timezoneAbbreviation: String {
        timezone?.abbreviation() ?? ""
    }

    var dayDifferenceFromLocal: Int {
        guard let tz = timezone else { return 0 }
        let now = Date()
        let localCalendar = Calendar.current
        let remoteCalendar: Calendar = {
            var cal = Calendar.current
            cal.timeZone = tz
            return cal
        }()

        let localDay = localCalendar.component(.day, from: now)
        let remoteDay = remoteCalendar.component(.day, from: now)

        if remoteDay > localDay { return 1 }
        if remoteDay < localDay { return -1 }
        return 0
    }

    func currentTimeString(use24Hour: Bool, at date: Date = Date()) -> String {
        guard let tz = timezone else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    func currentDate() -> Date {
        Date()
    }
}
