import SwiftUI

struct ClockView: View {
    let settings: AppSettings

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            // Time display
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(timeString)
                    .font(.custom("DSEG7Classic-Bold", size: 96))
                    .foregroundStyle(.white)

                Text(amPmString)
                    .font(.custom("DSEG7Classic-Bold", size: 32))
                    .foregroundStyle(.white)
                    .padding(.leading, 8)
            }

            if settings.showSeconds {
                Text(secondsString)
                    .font(.custom("DSEG7Classic-Bold", size: 36))
                    .foregroundStyle(.white.opacity(0.8))
            }

            // Date display
            Text(dateString)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.use24Hour ? "HH:mm" : "h:mm"
        return formatter.string(from: currentTime)
    }

    private var amPmString: String {
        if settings.use24Hour { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: currentTime)
    }

    private var secondsString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = ":ss"
        return formatter.string(from: currentTime)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }
}

#Preview {
    ClockView(settings: AppSettings())
        .frame(width: 480, height: 320)
        .background(.black)
}
