import SwiftUI

/// A single flip digit with split-flap animation
struct FlipDigit: View {
    let digit: Character
    let previousDigit: Character
    let size: CGFloat
    let theme: ColorTheme

    @State private var topFlipAngle: Double = 0
    @State private var bottomFlipAngle: Double = 90
    @State private var showNewDigitOnTop = true

    private var cardWidth: CGFloat { size * 0.65 }
    private var cardHeight: CGFloat { size * 0.9 }
    private var halfHeight: CGFloat { cardHeight / 2 }
    private var cornerRadius: CGFloat { size * 0.08 }
    private var fontSize: CGFloat { size * 0.7 }
    private var gap: CGFloat { 2 }

    private var cardBackground: Color {
        Color.black.opacity(0.25)
    }

    var body: some View {
        ZStack {
            // Background card with blur
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .frame(width: cardWidth, height: cardHeight)

            // STATIC: Bottom half always shows NEW digit
            bottomHalf(digit: digit)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: cornerRadius,
                        bottomTrailingRadius: cornerRadius,
                        topTrailingRadius: 0
                    )
                )
                .offset(y: halfHeight / 2 + gap / 2)

            // STATIC: Top half shows current digit (new after flip completes)
            topHalf(digit: showNewDigitOnTop ? digit : previousDigit)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: cornerRadius,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: cornerRadius
                    )
                )
                .offset(y: -halfHeight / 2 - gap / 2)

            // ANIMATED: Top flap (old digit) flipping down
            if topFlipAngle < 90 {
                topHalf(digit: previousDigit)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: cornerRadius,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: cornerRadius
                        )
                    )
                    .rotation3DEffect(
                        .degrees(-topFlipAngle),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.5
                    )
                    .offset(y: -halfHeight / 2 - gap / 2)
            }

            // ANIMATED: Bottom flap (new digit) flipping into place
            if bottomFlipAngle > 0 {
                bottomHalf(digit: digit)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: cornerRadius,
                            bottomTrailingRadius: cornerRadius,
                            topTrailingRadius: 0
                        )
                    )
                    .rotation3DEffect(
                        .degrees(bottomFlipAngle),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.5
                    )
                    .offset(y: halfHeight / 2 + gap / 2)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        .onChange(of: digit) { oldValue, newValue in
            guard oldValue != newValue else { return }
            triggerFlipAnimation()
        }
    }

    private func triggerFlipAnimation() {
        // Reset for animation
        topFlipAngle = 0
        bottomFlipAngle = 90
        showNewDigitOnTop = false

        // Phase 1: Top flap flips down (0 -> 90 degrees)
        withAnimation(.easeIn(duration: 0.25)) {
            topFlipAngle = 90
        }

        // Phase 2: Bottom flap flips up into place (90 -> 0 degrees)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            showNewDigitOnTop = true
            withAnimation(.easeOut(duration: 0.25)) {
                bottomFlipAngle = 0
            }
        }
    }

    @ViewBuilder
    private func topHalf(digit: Character) -> some View {
        ZStack {
            Rectangle()
                .fill(cardBackground)
                .overlay(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: cardWidth, height: halfHeight)

            Text(String(digit))
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryColor)
                .offset(y: halfHeight / 2)
        }
        .frame(width: cardWidth, height: halfHeight)
    }

    @ViewBuilder
    private func bottomHalf(digit: Character) -> some View {
        ZStack {
            Rectangle()
                .fill(cardBackground)
                .overlay(
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: cardWidth, height: halfHeight)

            Text(String(digit))
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryColor)
                .offset(y: -halfHeight / 2)
        }
        .frame(width: cardWidth, height: halfHeight)
    }
}

/// A pair of flip digits displayed side by side
struct FlipDigitPair: View {
    let value: String
    let previousValue: String
    let size: CGFloat
    let theme: ColorTheme

    private var digits: (Character, Character) {
        let chars = Array(value.padding(toLength: 2, withPad: "0", startingAt: 0))
        return (chars[0], chars[1])
    }

    private var previousDigits: (Character, Character) {
        let chars = Array(previousValue.padding(toLength: 2, withPad: "0", startingAt: 0))
        return (chars[0], chars[1])
    }

    var body: some View {
        HStack(spacing: 4) {
            FlipDigit(
                digit: digits.0,
                previousDigit: previousDigits.0,
                size: size,
                theme: theme
            )
            FlipDigit(
                digit: digits.1,
                previousDigit: previousDigits.1,
                size: size,
                theme: theme
            )
        }
    }
}

/// A flip-style colon separator
struct FlipColon: View {
    let size: CGFloat
    let theme: ColorTheme

    private var dotSize: CGFloat { size * 0.1 }
    private var spacing: CGFloat { size * 0.2 }

    var body: some View {
        VStack(spacing: spacing) {
            Circle()
                .fill(theme.primaryColor)
                .frame(width: dotSize, height: dotSize)
                .shadow(color: .black.opacity(0.3), radius: 2)
            Circle()
                .fill(theme.primaryColor)
                .frame(width: dotSize, height: dotSize)
                .shadow(color: .black.opacity(0.3), radius: 2)
        }
        .padding(.horizontal, 6)
    }
}

/// A split-flap style flip clock view
struct FlipClockView: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    /// Test-only override for the rendered time. When non-nil, the view
    /// renders that fixed date instead of subscribing to TimelineView.
    /// Used by snapshot tests to produce deterministic PNGs. Production
    /// callers always leave this as `nil`.
    var testDate: Date? = nil

    @State private var currentTime = Date()
    @State private var previousTime = Date()
    @State private var lastSecond: Int = -1

    private static let hour24Formatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH"; return f
    }()
    private static let hour12Formatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "hh"; return f
    }()
    private static let minuteFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "mm"; return f
    }()
    private static let secondFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "ss"; return f
    }()
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d, yyyy"; return f
    }()
    private static let accessibilityTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    private var dateFontSize: CGFloat {
        max(14, settings.clockFontSize / 4.8)
    }

    var body: some View {
        if let testDate {
            // Test-only fixed render path. Skip TimelineView so the snapshot is deterministic.
            // Use the same date for current and previous (no flip animation in tests).
            flipContent(now: testDate, previous: testDate)
        } else {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let _ = updateTimes(context.date)
                flipContent(now: currentTime, previous: previousTime)
            }
        }
    }

    @ViewBuilder
    private func flipContent(now: Date, previous: Date) -> some View {
        GeometryReader { geometry in
            let pairCount: CGFloat = settings.showSeconds ? 3 : 2
            let widthPerUnit: CGFloat = 1.6
            let totalUnits = pairCount * widthPerUnit + (pairCount - 1) * 0.3

            let maxWidthBasedSize = geometry.size.width / totalUnits
            let maxHeightBasedSize = geometry.size.height * 0.7

            let desiredSize = settings.clockFontSize * 0.9
            let digitSize = min(desiredSize, min(maxWidthBasedSize, maxHeightBasedSize))

            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    FlipDigitPair(
                        value: hourString(for: now),
                        previousValue: hourString(for: previous),
                        size: digitSize,
                        theme: theme
                    )

                    FlipColon(size: digitSize, theme: theme)

                    FlipDigitPair(
                        value: Self.minuteFormatter.string(from: now),
                        previousValue: Self.minuteFormatter.string(from: previous),
                        size: digitSize,
                        theme: theme
                    )

                    if settings.showSeconds {
                        FlipColon(size: digitSize, theme: theme)

                        FlipDigitPair(
                            value: Self.secondFormatter.string(from: now),
                            previousValue: Self.secondFormatter.string(from: previous),
                            size: digitSize,
                            theme: theme
                        )
                    }
                }

                Text(Self.dateFormatter.string(from: now))
                    .font(.system(size: min(dateFontSize, digitSize * 0.2), weight: .medium))
                    .foregroundStyle(theme.accentColor)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current time")
            .accessibilityValue(Self.accessibilityTimeFormatter.string(from: now))
        }
    }

    private func hourString(for date: Date) -> String {
        let formatter = settings.use24Hour ? Self.hour24Formatter : Self.hour12Formatter
        return formatter.string(from: date)
    }

    /// Called inside TimelineView closure to update previous/current time.
    /// Uses `let _ =` discard pattern so SwiftUI evaluates it each frame.
    private func updateTimes(_ date: Date) {
        let second = Calendar.current.component(.second, from: date)
        if second != lastSecond {
            previousTime = currentTime
            currentTime = date
            lastSecond = second
        }
    }

}

#Preview {
    FlipClockView(settings: AppSettings(), theme: .classicWhite)
        .frame(width: 600, height: 320)
        .background(
            Image(systemName: "photo")
                .resizable()
                .aspectRatio(contentMode: .fill)
        )
}
