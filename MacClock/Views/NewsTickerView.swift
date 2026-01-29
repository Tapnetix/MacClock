import SwiftUI
import AppKit

struct NewsTickerView: View {
    let settings: AppSettings
    let theme: ColorTheme
    let newsItems: [NewsItem]

    @State private var scrollOffset: CGFloat = 0
    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0
    @State private var isHovering = false
    @State private var isPaused = false
    @State private var scrollTimer: Timer?
    @State private var rotateTimer: Timer?
    @State private var pauseTimer: Timer?

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
        .onDisappear {
            scrollTimer?.invalidate()
            rotateTimer?.invalidate()
            pauseTimer?.invalidate()
        }
    }

    private var scrollingTicker: some View {
        GeometryReader { geometry in
            let text = newsItems.map { $0.displayTitle }.joined(separator: "  •  ")

            HStack(spacing: 0) {
                // Left navigation arrow
                if isHovering {
                    Button {
                        navigatePrevious()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.primaryColor.opacity(0.8))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.primaryColor)
                    .lineLimit(1)
                    .fixedSize()
                    .offset(x: scrollOffset)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                    .onTapGesture {
                        openCurrentItem()
                    }

                // Right navigation arrow
                if isHovering {
                    Button {
                        navigateNext()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(theme.primaryColor.opacity(0.8))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
            .onAppear {
                startScrolling(containerWidth: geometry.size.width)
            }
        }
    }

    private var rotatingTicker: some View {
        Group {
            if !newsItems.isEmpty {
                let item = newsItems[currentIndex % newsItems.count]

                HStack(spacing: 0) {
                    // Left navigation arrow
                    if isHovering {
                        Button {
                            navigatePrevious()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.primaryColor.opacity(0.8))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }

                    Text(item.displayTitle)
                        .font(.system(size: 14))
                        .foregroundStyle(theme.primaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .opacity(opacity)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            openCurrentItem()
                        }

                    // Right navigation arrow
                    if isHovering {
                        Button {
                            navigateNext()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(theme.primaryColor.opacity(0.8))
                                .frame(width: 30, height: 30)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isHovering)
                .onHover { hovering in
                    isHovering = hovering
                }
                .onAppear {
                    startRotating()
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Navigation

    private func navigatePrevious() {
        pauseAutoAdvance()

        if settings.newsTickerStyle == .rotating {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex = (currentIndex - 1 + newsItems.count) % newsItems.count
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1
                }
            }
        } else {
            // For scrolling, jump to previous logical position
            currentIndex = (currentIndex - 1 + newsItems.count) % newsItems.count
        }
    }

    private func navigateNext() {
        pauseAutoAdvance()

        if settings.newsTickerStyle == .rotating {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                currentIndex = (currentIndex + 1) % newsItems.count
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 1
                }
            }
        } else {
            currentIndex = (currentIndex + 1) % newsItems.count
        }
    }

    private func pauseAutoAdvance() {
        isPaused = true
        pauseTimer?.invalidate()
        pauseTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            isPaused = false
        }
    }

    private func openCurrentItem() {
        guard !newsItems.isEmpty else { return }
        let index = currentIndex % newsItems.count
        if let url = newsItems[index].link {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Auto-Advance

    private func startScrolling(containerWidth: CGFloat) {
        scrollOffset = containerWidth

        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            guard !isPaused else { return }
            scrollOffset -= settings.newsScrollSpeed * 0.03
            if scrollOffset < -2000 {
                scrollOffset = containerWidth
            }
        }
    }

    private func startRotating() {
        rotateTimer = Timer.scheduledTimer(withTimeInterval: settings.newsRotateInterval, repeats: true) { _ in
            guard !isPaused else { return }

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
