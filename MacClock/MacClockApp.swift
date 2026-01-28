import SwiftUI
import CoreText

@main
struct MacClockApp: App {
    init() {
        registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func registerFonts() {
        guard let fontsURL = Bundle.module.url(forResource: "Fonts", withExtension: nil),
              let fontURLs = try? FileManager.default.contentsOfDirectory(
                at: fontsURL,
                includingPropertiesForKeys: nil
              ).filter({ $0.pathExtension == "ttf" }) else {
            return
        }

        for fontURL in fontURLs {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("12:34")
            .font(.custom("DSEG7Classic-Bold", size: 72))
            .frame(width: 480, height: 320)
    }
}
