import SwiftUI
import EventKit

// MARK: - Calendar Tab

struct CalendarTabView: View {
    @Bindable var settings: AppSettings
    let calendarService: CalendarService
    @State private var showAddFeed = false
    @State private var editingFeed: ICalFeed?
    @State private var testingFeed: ICalFeed?

    var body: some View {
        SettingsSection(title: "Display") {
            Toggle("Show Next Event Countdown", isOn: $settings.calendarShowCountdown)
            Toggle("Show Agenda Panel", isOn: $settings.calendarShowAgenda)

            if settings.calendarShowAgenda {
                LabeledContent("Panel Position") {
                    Picker("", selection: $settings.calendarAgendaPosition) {
                        ForEach(WorldClocksPosition.allCases, id: \.self) { pos in
                            Text(pos.rawValue).tag(pos)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }
        }

        SettingsSection(title: "Local Calendars") {
            if calendarService.authorizationStatus != .fullAccess && calendarService.authorizationStatus != .authorized {
                Button("Grant Calendar Access") {
                    Task { await calendarService.requestAccess() }
                }
                .buttonStyle(.borderedProminent)

                Text("Allow access to show events from your Mac's calendars")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if calendarService.availableCalendars.isEmpty {
                Text("No calendars found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                    HStack {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor ?? CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)))
                            .frame(width: 10, height: 10)

                        Toggle(calendar.title, isOn: Binding(
                            get: { settings.selectedCalendarIDs.contains(calendar.calendarIdentifier) },
                            set: { enabled in
                                if enabled {
                                    settings.selectedCalendarIDs.append(calendar.calendarIdentifier)
                                } else {
                                    settings.selectedCalendarIDs.removeAll { $0 == calendar.calendarIdentifier }
                                }
                            }
                        ))
                    }
                }
            }
        }

        SettingsSection(title: "Online Calendars (iCal)") {
            if settings.iCalFeeds.isEmpty {
                Text("No online calendars added")
                    .foregroundStyle(.secondary)
            } else {
                ForEach($settings.iCalFeeds) { $feed in
                    ICalFeedRow(feed: $feed, onTest: {
                        testingFeed = feed
                    }, onEdit: {
                        editingFeed = feed
                    }, onDelete: {
                        settings.iCalFeeds.removeAll { $0.id == feed.id }
                    })
                }
            }

            Button {
                showAddFeed = true
            } label: {
                Label("Add iCal URL", systemImage: "plus.circle")
            }
            .padding(.top, 4)
        }
        .sheet(isPresented: $showAddFeed) {
            AddICalFeedSheet(isPresented: $showAddFeed) { feed in
                settings.iCalFeeds.append(feed)
            }
        }
        .sheet(item: $editingFeed) { feed in
            EditICalFeedSheet(feed: feed, isPresented: Binding(
                get: { editingFeed != nil },
                set: { if !$0 { editingFeed = nil } }
            )) { updatedFeed in
                if let index = settings.iCalFeeds.firstIndex(where: { $0.id == updatedFeed.id }) {
                    settings.iCalFeeds[index] = updatedFeed
                }
            }
        }
        .sheet(item: $testingFeed) { feed in
            TestICalFeedSheet(feed: feed, isPresented: Binding(
                get: { testingFeed != nil },
                set: { if !$0 { testingFeed = nil } }
            ))
        }
    }
}
