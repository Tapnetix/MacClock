import SwiftUI

struct ClockStyleContainer: View {
    let settings: AppSettings
    var theme: ColorTheme = .classicWhite

    var body: some View {
        switch settings.clockStyle {
        case .digital:
            ClockView(settings: settings, theme: theme)
        case .analog:
            AnalogClockView(settings: settings, theme: theme)
        case .flip:
            FlipClockView(settings: settings, theme: theme)
        }
    }
}

#Preview("Digital") {
    let settings = AppSettings()
    settings.clockStyle = .digital
    return ClockStyleContainer(settings: settings)
        .frame(width: 480, height: 320)
        .background(.black)
}

#Preview("Analog") {
    let settings = AppSettings()
    settings.clockStyle = .analog
    return ClockStyleContainer(settings: settings)
        .frame(width: 480, height: 400)
        .background(.black)
}

#Preview("Flip") {
    let settings = AppSettings()
    settings.clockStyle = .flip
    return ClockStyleContainer(settings: settings)
        .frame(width: 500, height: 300)
        .background(.black)
}
