import Testing
import SwiftUI
import Foundation
@testable import MacClock

/// Visual snapshot tests for the smaller display widgets: weather,
/// news ticker, world clock items, calendar countdown, alarm firing
/// overlay. Renders happen at small canvases (<= 480×240) so PNGs
/// stay around ~10–60 KB each.
///
/// To re-record: `MACCLOCK_RECORD_SNAPSHOTS=1 swift test`
@MainActor
@Suite("Widget snapshots")
struct WidgetSnapshotTests {
    /// Fixed render date: 2026-05-09 13:42:30 UTC. Same anchor as
    /// ClockSnapshotTests so visual diff'ing is consistent.
    private static let fixedDate: Date = {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 9
        components.hour = 13
        components.minute = 42
        components.second = 30
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 1_778_420_550)
    }()

    // MARK: - Weather

    @Test func weatherLoaded() throws {
        let weather = WeatherData(
            temperature: 18.0,
            condition: .clear,
            locationName: "San Francisco",
            sunrise: Self.fixedDate,
            sunset: Self.fixedDate.addingTimeInterval(8 * 3600),
            feelsLike: 17.0,
            humidity: 60,
            highTemp: 21.0,
            lowTemp: 12.0,
            hourlyForecast: [],
            dailyForecast: []
        )
        let settings = AppSettings.snapshotFixture { _ in }
        let view = WeatherView(
            weather: weather,
            useCelsius: true,
            settings: settings,
            theme: .classicWhite,
            showDetailPanel: .constant(false)
        )
        .padding()
        .background(.black)
        try Snapshot.assert(view, named: "widget_weather_loaded", size: CGSize(width: 320, height: 80))
    }

    @Test func weatherLoading() throws {
        let settings = AppSettings.snapshotFixture { _ in }
        let view = WeatherView(
            weather: nil,
            useCelsius: true,
            settings: settings,
            theme: .classicWhite,
            showDetailPanel: .constant(false)
        )
        .padding()
        .background(.black)
        try Snapshot.assert(view, named: "widget_weather_loading", size: CGSize(width: 320, height: 80))
    }

    // MARK: - News ticker

    @Test func newsTickerWithItems() throws {
        let settings = AppSettings.snapshotFixture { s in
            s.newsTickerStyle = .rotating // rotating is more deterministic than scrolling
        }
        let items = [
            NewsItem(title: "Test headline number one", link: nil, source: "BBC", publishedDate: nil),
            NewsItem(title: "Another notable story today", link: nil, source: "Reuters", publishedDate: nil),
        ]
        let view = NewsTickerView(settings: settings, theme: .classicWhite, newsItems: items)
            .background(.black)
        try Snapshot.assert(view, named: "widget_news_with_items", size: CGSize(width: 480, height: 30))
    }

    @Test func newsTickerEmpty() throws {
        let settings = AppSettings.snapshotFixture { s in
            s.newsTickerStyle = .rotating
        }
        let view = NewsTickerView(settings: settings, theme: .classicWhite, newsItems: [])
            .background(.black)
        try Snapshot.assert(view, named: "widget_news_empty", size: CGSize(width: 480, height: 30))
    }

    // MARK: - World clock

    @Test func worldClockCompact() throws {
        let clock = WorldClock(id: UUID(), cityName: "London", timezoneIdentifier: "Europe/London")
        let view = WorldClockItem(
            clock: clock,
            theme: .classicWhite,
            use24Hour: true,
            showAbbreviation: false,
            showDayDiff: false,
            compact: true,
            testDate: Self.fixedDate
        )
        .padding()
        .background(.black)
        try Snapshot.assert(view, named: "widget_worldclock_compact", size: CGSize(width: 160, height: 80))
    }

    @Test func worldClockExpanded() throws {
        let clock = WorldClock(id: UUID(), cityName: "Tokyo", timezoneIdentifier: "Asia/Tokyo")
        let view = WorldClockItem(
            clock: clock,
            theme: .classicWhite,
            use24Hour: true,
            showAbbreviation: true,
            showDayDiff: true,
            compact: false,
            testDate: Self.fixedDate
        )
        .padding()
        .background(.black)
        try Snapshot.assert(view, named: "widget_worldclock_expanded", size: CGSize(width: 200, height: 100))
    }

    // MARK: - Calendar countdown

    @Test func calendarCountdownWithEvent() throws {
        let event = CalendarEvent(
            id: "test-1",
            title: "Team standup",
            startDate: Self.fixedDate.addingTimeInterval(3600),
            endDate: Self.fixedDate.addingTimeInterval(5400),
            calendarTitle: "Work",
            calendarColor: nil,
            isAllDay: false
        )
        let view = CalendarCountdownView(event: event, theme: .classicWhite)
            .padding()
            .background(.black)
        try Snapshot.assert(view, named: "widget_calendar_with_event", size: CGSize(width: 320, height: 60))
    }

    @Test func calendarCountdownNilEvent() throws {
        let view = CalendarCountdownView(event: nil, theme: .classicWhite)
            .padding()
            .frame(width: 320, height: 60)
            .background(.black)
        try Snapshot.assert(view, named: "widget_calendar_nil_event", size: CGSize(width: 320, height: 60))
    }

    // MARK: - Alarm firing

    // NOTE: AlarmFiringView snapshots are intentionally omitted.
    // The view pulses an icon via `withAnimation(.repeatForever)` triggered
    // from `.onAppear`, which makes ImageRenderer capture an indeterminate
    // animation phase. Even with `.transaction { $0.disablesAnimations = true }`
    // the opacity drift produces ~10-byte PNG variance run-to-run. The view
    // is exercised by the accessibility tests instead.
}
