import SwiftUI

struct CalendarCountdownView: View {
    let event: CalendarEvent?
    let theme: ColorTheme

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        if let event = event {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.primaryColor.opacity(0.9))

                Text(event.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)

                // Show actual time, not just countdown
                Text(timeFormatter.string(from: event.startDate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.accentColor)
            }
            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
    }
}

struct CalendarAgendaView: View {
    let events: [CalendarEvent]
    let theme: ColorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TODAY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.accentColor)

            if events.isEmpty {
                Text("No events")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.accentColor.opacity(0.6))
            } else {
                ForEach(events.prefix(6)) { event in
                    CalendarAgendaItem(event: event, theme: theme)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

struct CalendarAgendaItem: View {
    let event: CalendarEvent
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 8) {
            // Color indicator
            if let color = event.calendarColor {
                Circle()
                    .fill(Color(cgColor: color))
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)

                Text(formatTime(event))
                    .font(.system(size: 10))
                    .foregroundStyle(theme.accentColor)
            }
        }
    }

    private func formatTime(_ event: CalendarEvent) -> String {
        if event.isAllDay { return "All day" }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
}

#Preview {
    VStack {
        CalendarCountdownView(
            event: nil,
            theme: .classicWhite
        )

        CalendarAgendaView(
            events: [],
            theme: .classicWhite
        )
    }
    .padding()
    .background(.black)
}
