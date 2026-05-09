import SwiftUI

struct AlarmContainer<Content: View>: View {
    let settings: AppSettings
    let theme: ColorTheme
    @ViewBuilder let content: (Binding<Bool>) -> Content

    @State private var showAlarmPanel = false

    var body: some View {
        content($showAlarmPanel)
    }
}
