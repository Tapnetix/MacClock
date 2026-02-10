import SwiftUI

struct WorldClocksView: View {
    let settings: AppSettings
    let theme: ColorTheme

    var body: some View {
        Group {
            if settings.worldClocksPosition == .bottom {
                bottomBarLayout
            } else {
                sidePanelLayout
            }
        }
    }

    private var bottomBarLayout: some View {
        HStack(spacing: 16) {
            ForEach(settings.worldClocks.prefix(3)) { clock in
                WorldClockItem(
                    clock: clock,
                    theme: theme,
                    use24Hour: settings.use24Hour,
                    showAbbreviation: settings.showTimezoneAbbreviation,
                    showDayDiff: settings.showDayDifference,
                    compact: true
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var sidePanelLayout: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(settings.worldClocks.prefix(5)) { clock in
                WorldClockItem(
                    clock: clock,
                    theme: theme,
                    use24Hour: settings.use24Hour,
                    showAbbreviation: settings.showTimezoneAbbreviation,
                    showDayDiff: settings.showDayDifference,
                    compact: false
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(6)
    }
}

struct WorldClockItem: View {
    let clock: WorldClock
    let theme: ColorTheme
    let use24Hour: Bool
    let showAbbreviation: Bool
    let showDayDiff: Bool
    let compact: Bool

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if compact {
                compactLayout
            } else {
                expandedLayout
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(clock.cityName.uppercased())
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(theme.accentColor)

            HStack(spacing: 4) {
                Text(clock.currentTimeString(use24Hour: use24Hour, at: currentTime))
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(theme.primaryColor)

                if showDayDiff && clock.dayDifferenceFromLocal != 0 {
                    Text(clock.dayDifferenceFromLocal > 0 ? "+1" : "-1")
                        .font(.system(size: 8))
                        .foregroundStyle(theme.accentColor.opacity(0.7))
                }
            }
        }
        .frame(minWidth: 70)
    }

    private var expandedLayout: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 2) {
                Text(clock.cityName.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(theme.accentColor)

                if showDayDiff && clock.dayDifferenceFromLocal != 0 {
                    Text(clock.dayDifferenceFromLocal > 0 ? "+1" : "-1")
                        .font(.system(size: 9))
                        .foregroundStyle(theme.accentColor.opacity(0.7))
                }
            }

            Text(clock.currentTimeString(use24Hour: use24Hour, at: currentTime))
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(theme.primaryColor)

            if showAbbreviation {
                Text(clock.timezoneAbbreviation)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.accentColor.opacity(0.6))
            }
        }
    }
}

#Preview("Bottom Bar") {
    let settings = AppSettings()
    settings.worldClocks = [
        WorldClock(id: UUID(), cityName: "New York", timezoneIdentifier: "America/New_York"),
        WorldClock(id: UUID(), cityName: "London", timezoneIdentifier: "Europe/London"),
        WorldClock(id: UUID(), cityName: "Tokyo", timezoneIdentifier: "Asia/Tokyo")
    ]
    settings.worldClocksPosition = .bottom
    return WorldClocksView(settings: settings, theme: .classicWhite)
        .background(.black)
}

#Preview("Side Panel") {
    let settings = AppSettings()
    settings.worldClocks = [
        WorldClock(id: UUID(), cityName: "New York", timezoneIdentifier: "America/New_York"),
        WorldClock(id: UUID(), cityName: "London", timezoneIdentifier: "Europe/London"),
        WorldClock(id: UUID(), cityName: "Tokyo", timezoneIdentifier: "Asia/Tokyo")
    ]
    settings.worldClocksPosition = .side
    return WorldClocksView(settings: settings, theme: .classicWhite)
        .background(.black)
}
