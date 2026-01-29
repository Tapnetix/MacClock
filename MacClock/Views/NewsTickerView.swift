import SwiftUI
import AppKit

struct NewsTickerView: View {
    let settings: AppSettings
    let theme: ColorTheme
    let newsItems: [NewsItem]

    @State private var scrollOffset: CGFloat = 0
    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Group {
            if settings.newsTickerStyle == .scrolling {
                scrollingTicker
            } else {
                rotatingTicker
            }
        }
        .frame(height: 30)
        .background(Color.black.opacity(0.5))
    }

    private var scrollingTicker: some View {
        GeometryReader { geometry in
            let text = newsItems.map { $0.displayTitle }.joined(separator: "  •  ")

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(theme.primaryColor)
                .lineLimit(1)
                .fixedSize()
                .offset(x: scrollOffset)
                .onAppear {
                    startScrolling(containerWidth: geometry.size.width)
                }
                .onTapGesture {
                    if let item = newsItems.first, let url = item.link {
                        NSWorkspace.shared.open(url)
                    }
                }
        }
        .clipped()
    }

    private var rotatingTicker: some View {
        Group {
            if !newsItems.isEmpty {
                let item = newsItems[currentIndex % newsItems.count]
                Text(item.displayTitle)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .opacity(opacity)
                    .onAppear {
                        startRotating()
                    }
                    .onTapGesture {
                        if let url = item.link {
                            NSWorkspace.shared.open(url)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private func startScrolling(containerWidth: CGFloat) {
        scrollOffset = containerWidth

        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            scrollOffset -= settings.newsScrollSpeed * 0.03
            if scrollOffset < -2000 {
                scrollOffset = containerWidth
            }
        }
    }

    private func startRotating() {
        Timer.scheduledTimer(withTimeInterval: settings.newsRotateInterval, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex += 1
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview {
    let settings = AppSettings()
    let items = [
        NewsItem(title: "Breaking news headline here", link: nil, source: "BBC", publishedDate: nil),
        NewsItem(title: "Another important story", link: nil, source: "Reuters", publishedDate: nil),
    ]
    return NewsTickerView(settings: settings, theme: .classicWhite, newsItems: items)
        .frame(width: 500)
        .background(.black)
}
