import SwiftUI

/// A single clock hand drawn as a rotated rectangle
struct ClockHand: View {
    let length: CGFloat
    let width: CGFloat
    let color: Color
    let angle: Double

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }
}

struct AnalogClockView: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    /// Test-only override for the rendered time. When non-nil, the view
    /// renders that fixed date instead of subscribing to TimelineView.
    /// Used by snapshot tests to produce deterministic PNGs. Production
    /// callers always leave this as `nil`.
    var testDate: Date? = nil

    private var dateFontSize: CGFloat {
        max(14, settings.clockFontSize / 4.8)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f
    }()

    private static let accessibilityTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        if let testDate {
            // Test-only fixed render path. Skip TimelineView so the snapshot is deterministic.
            clockContent(for: testDate)
        } else if settings.showSeconds {
            TimelineView(.animation) { context in
                clockContent(for: context.date)
            }
        } else {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                clockContent(for: context.date)
            }
        }
    }

    @ViewBuilder
    private func clockContent(for currentTime: Date) -> some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height - 40
            let availableSize = min(availableWidth, availableHeight)
            let desiredSize = settings.clockFontSize * 2.5
            let clockSize = min(desiredSize, availableSize * 0.85)

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(
                            theme.primaryColor.opacity(0.5),
                            lineWidth: max(1.5, clockSize * 0.008)
                        )
                        .shadow(color: theme.primaryColor.opacity(0.3), radius: 4)
                        .shadow(color: .black.opacity(0.5), radius: 2)

                    ForEach(0..<12, id: \.self) { hour in
                        hourMarker(for: hour, clockSize: clockSize)
                    }

                    ClockHand(
                        length: clockSize * 0.25,
                        width: max(2, clockSize * 0.016),
                        color: theme.primaryColor,
                        angle: hourAngle(from: currentTime)
                    )

                    ClockHand(
                        length: clockSize * 0.35,
                        width: max(2, clockSize * 0.012),
                        color: theme.primaryColor,
                        angle: minuteAngle(from: currentTime)
                    )

                    if settings.showSeconds {
                        ClockHand(
                            length: clockSize * 0.4,
                            width: 1,
                            color: theme.accentColor,
                            angle: secondAngle(from: currentTime)
                        )
                    }

                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: max(4, clockSize * 0.03), height: max(4, clockSize * 0.03))
                }
                .frame(width: clockSize, height: clockSize)
                .aspectRatio(1, contentMode: .fit)

                Text(Self.dateFormatter.string(from: currentTime))
                    .font(.system(size: min(dateFontSize, clockSize * 0.08), weight: .medium))
                    .foregroundStyle(theme.accentColor)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(y: -20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Current time")
            .accessibilityValue(Self.accessibilityTimeFormatter.string(from: currentTime))
        }
    }

    // MARK: - Hour Markers

    @ViewBuilder
    private func hourMarker(for hour: Int, clockSize: CGFloat) -> some View {
        let isCardinal = hour == 0 || hour == 3 || hour == 6 || hour == 9
        let markerLength: CGFloat = isCardinal ? max(8, clockSize * 0.05) : max(4, clockSize * 0.025)
        let markerWidth: CGFloat = isCardinal ? max(2, clockSize * 0.012) : max(1, clockSize * 0.008)
        let angle = Double(hour) * 30.0

        Rectangle()
            .fill(theme.primaryColor.opacity(isCardinal ? 1.0 : 0.6))
            .frame(width: markerWidth, height: markerLength)
            .offset(y: -(clockSize / 2 - markerLength / 2 - 4))
            .rotationEffect(.degrees(angle))
    }

    // MARK: - Time Angles

    private func hourAngle(from date: Date) -> Double {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: date) % 12)
        let minute = Double(calendar.component(.minute, from: date))
        return (hour + minute / 60.0) * 30.0
    }

    private func minuteAngle(from date: Date) -> Double {
        let calendar = Calendar.current
        let minute = Double(calendar.component(.minute, from: date))
        let second = Double(calendar.component(.second, from: date))
        return (minute + second / 60.0) * 6.0
    }

    private func secondAngle(from date: Date) -> Double {
        let calendar = Calendar.current
        let second = Double(calendar.component(.second, from: date))
        let nanosecond = Double(calendar.component(.nanosecond, from: date))
        return (second + nanosecond / 1_000_000_000.0) * 6.0
    }
}

#Preview {
    AnalogClockView(settings: AppSettings(), theme: .classicWhite)
        .frame(width: 480, height: 400)
        .background(.black)
}
