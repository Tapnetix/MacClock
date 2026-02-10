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

    @State private var currentTime = Date()
    @State private var previousTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var dateFontSize: CGFloat {
        max(14, settings.clockFontSize / 4.8)
    }

    var body: some View {
        GeometryReader { geometry in
            // Calculate how many digit pairs we need
            let pairCount: CGFloat = settings.showSeconds ? 3 : 2
            // Each pair is roughly 2 * 0.65 * size wide, plus colons
            let widthPerUnit: CGFloat = 1.6
            let totalUnits = pairCount * widthPerUnit + (pairCount - 1) * 0.3

            let maxWidthBasedSize = geometry.size.width / totalUnits
            let maxHeightBasedSize = geometry.size.height * 0.7

            let desiredSize = settings.clockFontSize * 0.9
            let digitSize = min(desiredSize, min(maxWidthBasedSize, maxHeightBasedSize))

            VStack(spacing: 16) {
                // Time display with flip digits
                HStack(spacing: 0) {
                    // Hours
                    FlipDigitPair(
                        value: hourString,
                        previousValue: previousHourString,
                        size: digitSize,
                        theme: theme
                    )

                    FlipColon(size: digitSize, theme: theme)

                    // Minutes
                    FlipDigitPair(
                        value: minuteString,
                        previousValue: previousMinuteString,
                        size: digitSize,
                        theme: theme
                    )

                    // Seconds (optional)
                    if settings.showSeconds {
                        FlipColon(size: digitSize, theme: theme)

                        FlipDigitPair(
                            value: secondString,
                            previousValue: previousSecondString,
                            size: digitSize,
                            theme: theme
                        )
                    }
                }

                // Date display
                Text(dateString)
                    .font(.system(size: min(dateFontSize, digitSize * 0.2), weight: .medium))
                    .foregroundStyle(theme.accentColor)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(timer) { _ in
            previousTime = currentTime
            currentTime = Date()
        }
    }

    // MARK: - Current Time Strings

    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.use24Hour ? "HH" : "hh"
        return formatter.string(from: currentTime)
    }

    private var minuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter.string(from: currentTime)
    }

    private var secondString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: currentTime)
    }

    // MARK: - Previous Time Strings

    private var previousHourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.use24Hour ? "HH" : "hh"
        return formatter.string(from: previousTime)
    }

    private var previousMinuteString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter.string(from: previousTime)
    }

    private var previousSecondString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ss"
        return formatter.string(from: previousTime)
    }

    // MARK: - Date String

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
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
