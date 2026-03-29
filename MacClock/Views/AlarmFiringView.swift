import SwiftUI

struct AlarmFiringView: View {
    let alarm: Alarm
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    let theme: ColorTheme
    var snoozeCount: Int = 0
    var maxSnoozes: Int = 10

    @State private var pulseOpacity = 1.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Pulsing alarm icon
            Image(systemName: "alarm.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.primaryColor)
                .opacity(pulseOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        pulseOpacity = 0.4
                    }
                }

            // Time
            Text(alarm.timeString)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(theme.primaryColor)

            // Label
            if !alarm.label.isEmpty {
                Text(alarm.label)
                    .font(.title2)
                    .foregroundStyle(theme.accentColor)
            }

            Spacer()

            // Buttons
            HStack(spacing: 40) {
                Button {
                    onSnooze()
                } label: {
                    VStack {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 30))
                        Text("Snooze")
                            .font(.caption)
                    }
                    .foregroundStyle(snoozeCount < maxSnoozes ? theme.accentColor : theme.accentColor.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(snoozeCount >= maxSnoozes)
                .accessibilityLabel("Snooze alarm for \(alarm.snoozeDuration) minutes")

                Button {
                    onDismiss()
                } label: {
                    VStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                        Text("Dismiss")
                            .font(.caption)
                    }
                    .foregroundStyle(theme.primaryColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss alarm")
            }

            if snoozeCount < maxSnoozes {
                Text("Snooze for \(alarm.snoozeDuration) min (\(maxSnoozes - snoozeCount) left)")
                    .font(.caption)
                    .foregroundStyle(theme.accentColor.opacity(0.6))
            } else {
                Text("No snoozes remaining")
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.8))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}

#Preview {
    let alarm = Alarm(
        id: UUID(),
        time: DateComponents(hour: 7, minute: 30),
        label: "Wake up!",
        isEnabled: true,
        repeatDays: [],
        soundName: nil,
        snoozeDuration: 5
    )
    return AlarmFiringView(
        alarm: alarm,
        onDismiss: {},
        onSnooze: {},
        theme: .classicWhite
    )
}
