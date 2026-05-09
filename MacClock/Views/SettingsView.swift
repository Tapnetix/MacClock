import SwiftUI
import ServiceManagement
import AppKit
import EventKit

enum SettingsTab: String, CaseIterable {
    case general = "General"
    case appearance = "Appearance"
    case window = "Window"
    case location = "Location"
    case worldClocks = "World Clocks"
    case calendar = "Calendar"
    case news = "News"
    case extras = "Extras"

    var icon: String {
        switch self {
        case .general: return "clock.fill"
        case .appearance: return "paintbrush.fill"
        case .window: return "macwindow"
        case .location: return "location.fill"
        case .worldClocks: return "globe"
        case .calendar: return "calendar"
        case .news: return "newspaper.fill"
        case .extras: return "sparkles"
        }
    }

    var title: String { rawValue }
}

extension SettingsTab: TabKind {}

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let locationService: LocationService

    @State private var selectedTab: SettingsTab = .general
    @State private var citySearch = ""
    @State private var searchError: String?
    @FocusState private var isCityFieldFocused: Bool
    @State private var showCityPicker = false
    @State private var citySearchService = CitySearchService()
    @State private var calendarService = CalendarService()
    @State private var showAlarmPanel = false
    @State private var alarmService = AlarmService()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar-style tab bar
            HStack(spacing: 2) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    TabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Divider()

            // Tab content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .general:
                        GeneralTabView(settings: settings)
                    case .appearance:
                        AppearanceTabView(settings: settings)
                    case .window:
                        WindowTabView(settings: settings)
                    case .location:
                        LocationTabView(
                            settings: settings,
                            locationService: locationService,
                            citySearch: $citySearch,
                            searchError: $searchError,
                            isCityFieldFocused: _isCityFieldFocused
                        )
                    case .worldClocks:
                        WorldClocksTabView(
                            settings: settings,
                            showCityPicker: $showCityPicker
                        )
                    case .calendar:
                        CalendarTabView(settings: settings, calendarService: calendarService)
                    case .news:
                        NewsTabView(settings: settings)
                    case .extras:
                        ExtrasTabView(
                            settings: settings,
                            showAlarmPanel: $showAlarmPanel
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 420, height: 400)
        .sheet(isPresented: $showCityPicker) {
            CityPickerSheet(
                settings: settings,
                searchService: citySearchService,
                isPresented: $showCityPicker
            )
        }
        .sheet(isPresented: $showAlarmPanel) {
            AlarmPanelView(settings: settings, alarmService: alarmService)
        }
    }
}

// MARK: - City Picker Sheet

struct CityPickerSheet: View {
    let settings: AppSettings
    let searchService: CitySearchService
    @Binding var isPresented: Bool

    @State private var searchText = ""
    @State private var searchResults: [CitySearchResult] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add City")
                    .font(.headline)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            TextField("Search city...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .onChange(of: searchText) { _, newValue in
                    Task {
                        searchResults = await searchService.search(query: newValue)
                    }
                }

            List(searchResults) { result in
                Button {
                    let clock = WorldClock(
                        id: UUID(),
                        cityName: result.cityName,
                        timezoneIdentifier: result.timezoneIdentifier
                    )
                    settings.worldClocks.append(clock)
                    isPresented = false
                } label: {
                    HStack {
                        Text(result.displayName)
                        Spacer()
                        Text(TimeZone(identifier: result.timezoneIdentifier)?.abbreviation() ?? "")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.plain)
        }
        .frame(width: 350, height: 400)
        .task {
            searchResults = await searchService.allCities()
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings(), locationService: LocationService())
}
