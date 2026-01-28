import SwiftUI

@main
struct MacClockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("MacClock")
            .frame(width: 480, height: 320)
    }
}
