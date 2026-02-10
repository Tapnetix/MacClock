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

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var dateFontSize: CGFloat {
        max(14, settings.clockFontSize / 4.8)
    }

    var body: some View {
        GeometryReader { geometry in
            // Calculate clock size based on available space, keeping it square
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height - 40 // Leave room for date
            let availableSize = min(availableWidth, availableHeight)
            let desiredSize = settings.clockFontSize * 2.5
            let clockSize = min(desiredSize, availableSize * 0.85)

            VStack(spacing: 8) {
                // Clock face - use fixed aspect ratio to keep it circular
                ZStack {
                    // Outer ring with glow for visibility
                    Circle()
                        .stroke(
                            theme.primaryColor.opacity(0.5),
                            lineWidth: max(1.5, clockSize * 0.008)
                        )
                        .shadow(color: theme.primaryColor.opacity(0.3), radius: 4)
                        .shadow(color: .black.opacity(0.5), radius: 2)

                    // Hour markers
                    ForEach(0..<12, id: \.self) { hour in
                        hourMarker(for: hour, clockSize: clockSize)
                    }

                    // Hour hand
                    ClockHand(
                        length: clockSize * 0.25,
                        width: max(2, clockSize * 0.016),
                        color: theme.primaryColor,
                        angle: hourAngle
                    )

                    // Minute hand
                    ClockHand(
                        length: clockSize * 0.35,
                        width: max(2, clockSize * 0.012),
                        color: theme.primaryColor,
                        angle: minuteAngle
                    )

                    // Second hand (if showSeconds enabled)
                    if settings.showSeconds {
                        ClockHand(
                            length: clockSize * 0.4,
                            width: 1,
                            color: theme.accentColor,
                            angle: secondAngle
                        )
                    }

                    // Center dot
                    Circle()
                        .fill(theme.primaryColor)
                        .frame(width: max(4, clockSize * 0.03), height: max(4, clockSize * 0.03))
                }
                .frame(width: clockSize, height: clockSize)
                .aspectRatio(1, contentMode: .fit)

                // Date display (same style as digital)
                Text(dateString)
                    .font(.system(size: min(dateFontSize, clockSize * 0.08), weight: .medium))
                    .foregroundStyle(theme.accentColor)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(y: -20) // Move clock up slightly
        }
        .onReceive(timer) { _ in
            currentTime = Date()
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

    private var hourAngle: Double {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: currentTime) % 12)
        let minute = Double(calendar.component(.minute, from: currentTime))
        return (hour + minute / 60.0) * 30.0
    }

    private var minuteAngle: Double {
        let calendar = Calendar.current
        let minute = Double(calendar.component(.minute, from: currentTime))
        let second = Double(calendar.component(.second, from: currentTime))
        return (minute + second / 60.0) * 6.0
    }

    private var secondAngle: Double {
        let calendar = Calendar.current
        let second = Double(calendar.component(.second, from: currentTime))
        let nanosecond = Double(calendar.component(.nanosecond, from: currentTime))
        return (second + nanosecond / 1_000_000_000.0) * 6.0
    }

    // MARK: - Date String

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    AnalogClockView(settings: AppSettings(), theme: .classicWhite)
        .frame(width: 480, height: 400)
        .background(.black)
}
