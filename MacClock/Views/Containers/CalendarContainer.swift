import SwiftUI

struct CalendarContainer<Content: View>: View {
    let settings: AppSettings
    @ViewBuilder let content: (CalendarEvent?, [CalendarEvent]) -> Content

    var body: some View {
        content(nil, [])
    }
}
