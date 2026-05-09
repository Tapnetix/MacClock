import SwiftUI

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
