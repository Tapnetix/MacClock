import SwiftUI

struct ClockView: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    private var secondaryFontSize: CGFloat {
        settings.clockFontSize / 3.0
    }

    private var dateFontSize: CGFloat {
        max(14, settings.clockFontSize / 4.8)
    }

    // Cached formatters — these are expensive to create
    private static let time24Formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private static let time12Formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f
    }()

    private static let amPmFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "a"
        return f
    }()

    private static let secondsFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ss"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d, yyyy"
        return f
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let currentTime = context.date

            VStack(spacing: 8) {
                // Time display
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(timeString(from: currentTime))
                        .font(.custom("DSEG7Classic-Bold", size: settings.clockFontSize))
                        .foregroundStyle(theme.primaryColor)

                    // AM/PM and seconds stacked vertically to the right
                    VStack(alignment: .leading, spacing: 0) {
                        if !settings.use24Hour {
                            Text(Self.amPmFormatter.string(from: currentTime))
                                .font(.custom("DSEG7Classic-Bold", size: secondaryFontSize))
                                .foregroundStyle(theme.primaryColor)
                        }

                        if settings.showSeconds {
                            Text(Self.secondsFormatter.string(from: currentTime))
                                .font(.custom("DSEG7Classic-Bold", size: secondaryFontSize))
                                .foregroundStyle(theme.primaryColor.opacity(theme.secondaryOpacity))
                        }
                    }
                    .alignmentGuide(.lastTextBaseline) { d in d[.lastTextBaseline] }
                }

                // Date display
                Text(Self.dateFormatter.string(from: currentTime))
                    .font(.system(size: dateFontSize, weight: .medium))
                    .foregroundStyle(theme.accentColor)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = settings.use24Hour ? Self.time24Formatter : Self.time12Formatter
        return formatter.string(from: date)
    }
}

#Preview {
    ClockView(settings: AppSettings(), theme: .classicWhite)
        .frame(width: 480, height: 320)
        .background(.black)
}
