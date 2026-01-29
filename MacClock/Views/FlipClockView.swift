import SwiftUI

/// A single flip digit with 3D flip animation
struct FlipDigit: View {
    let digit: Character
    let previousDigit: Character
    let size: CGFloat
    let theme: ColorTheme

    @State private var isFlipping = false

    private var cardWidth: CGFloat { size * 0.65 }
    private var cardHeight: CGFloat { size * 0.9 }
    private var cornerRadius: CGFloat { size * 0.1 }
    private var fontSize: CGFloat { size * 0.7 }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.black.opacity(0.8),
                Color.black.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cardBackground)
                .frame(width: cardWidth, height: cardHeight)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

            // Digit text
            Text(String(digit))
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryColor)

            // Split line across middle
            Rectangle()
                .fill(Color.black)
                .frame(width: cardWidth, height: 2)
        }
        .frame(width: cardWidth, height: cardHeight)
        .rotation3DEffect(
            .degrees(isFlipping ? -10 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.5
        )
        .onChange(of: digit) { oldValue, newValue in
            guard oldValue != newValue else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                isFlipping = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isFlipping = false
                }
            }
        }
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
            Circle()
                .fill(theme.primaryColor)
                .frame(width: dotSize, height: dotSize)
        }
        .padding(.horizontal, 4)
    }
}

/// A split-flap style flip clock view
struct FlipClockView: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    @State private var currentTime = Date()
    @State private var previousTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var digitSize: CGFloat {
        settings.clockFontSize * 0.9
    }

    private var dateFontSize: CGFloat {
        max(14, settings.clockFontSize / 4.8)
    }

    var body: some View {
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
                .font(.system(size: dateFontSize, weight: .medium))
                .foregroundStyle(theme.accentColor)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
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
        .background(.black)
}
