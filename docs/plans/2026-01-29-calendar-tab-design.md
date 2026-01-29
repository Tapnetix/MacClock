# Calendar Tab & iCal Integration Design

## Overview

Split Calendar functionality from Extras tab into its own dedicated tab, fix native macOS calendar access, and add support for external calendars via iCal URLs.

## Goals

1. Fix "Grant Calendar Access" button not working
2. Dedicated Calendar tab in Settings for better organization
3. Support external calendars (Google, Outlook, etc.) via iCal/ICS URLs
4. Unified event display from all calendar sources

## Problem: Native Calendar Access Not Working

The "Grant Calendar Access" button has no effect because `NSCalendarsUsageDescription` is missing from Info.plist. macOS requires this usage description to show the permission dialog.

**Fix:** Add to Info.plist:
```xml
<key>NSCalendarsUsageDescription</key>
<string>MacClock needs calendar access to display your upcoming events.</string>
```

## Settings Tab Changes

### Current Tabs
1. General
2. Appearance
3. Window
4. Location
5. World Clocks
6. News
7. Extras (Calendar + Alarms)

### New Tabs
1. General
2. Appearance
3. Window
4. Location
5. World Clocks
6. **Calendar** (split out)
7. News
8. Extras (Alarms only)

## UI Design

### Calendar Tab in Settings

```
[Calendar Tab Icon: calendar]

┌─ Display ──────────────────────────────────┐
│ ☑ Show Next Event Countdown                │
│ ☑ Show Agenda Panel                        │
│   Position: [Side ▾]                       │
└────────────────────────────────────────────┘

┌─ Local Calendars ──────────────────────────┐
│ [Grant Calendar Access]  ← if not granted  │
│                                            │
│ ☑ Home                                     │
│ ☑ Work                                     │
│ ☐ Birthdays                                │
└────────────────────────────────────────────┘

┌─ Online Calendars (iCal) ──────────────────┐
│ ☑ Google (Personal)           [Edit] [×]   │
│ ☑ Outlook (Work)              [Edit] [×]   │
│                                            │
│ [+ Add iCal URL]                           │
└────────────────────────────────────────────┘
```

### Add iCal URL Sheet

```
┌─ Add Online Calendar ─────────────────────┐
│                                           │
│ Name: [Google Calendar          ]         │
│                                           │
│ iCal URL:                                 │
│ [https://calendar.google.com/...ics ]     │
│                                           │
│ Color: [● Red ▾]                          │
│                                           │
│ ℹ️ To find your Google Calendar URL:       │
│    Calendar Settings → [calendar name]    │
│    → "Secret address in iCal format"      │
│                                           │
│           [Cancel]  [Add]                 │
└───────────────────────────────────────────┘
```

### Edit iCal Feed Sheet

Same as Add sheet, but with current values pre-filled and "Save" instead of "Add".

## Data Model

### New ICalFeed Model

```swift
struct ICalFeed: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String        // User-provided name like "Work (Google)"
    var url: String         // The iCal URL
    var isEnabled: Bool
    var colorHex: String    // Hex color for event display

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}
```

### AppSettings Additions

```swift
// Existing
var calendarEnabled: Bool
var calendarShowCountdown: Bool
var calendarShowAgenda: Bool
var calendarAgendaPosition: WorldClocksPosition
var selectedCalendarIDs: [String]

// New
var iCalFeeds: [ICalFeed]
```

## Services

### ICalService

```swift
actor ICalService {
    /// Fetch and parse events from an iCal URL
    func fetchEvents(from feed: ICalFeed) async throws -> [CalendarEvent]

    /// Parse ICS content into calendar events
    func parseICS(_ content: String, feedName: String, color: CGColor) -> [CalendarEvent]

    /// Validate that a URL returns valid ICS content
    func validateFeed(url: URL) async throws -> Bool
}
```

**ICS Parsing:**
- Parse VEVENT components
- Extract: SUMMARY (title), DTSTART, DTEND, UID
- Handle all-day events (DATE vs DATE-TIME)
- Basic RRULE support for recurring events (daily, weekly, monthly)

### Updated CalendarService

Add method to fetch combined events:

```swift
func fetchAllTodayEvents(
    localCalendarIDs: [String],
    iCalFeeds: [ICalFeed],
    iCalService: ICalService
) async -> [CalendarEvent]
```

This merges local EventKit events with iCal feed events, sorted by start time.

## Refresh Strategy

- **On app launch:** Fetch all iCal feeds
- **Periodic refresh:** Every 15 minutes while app is running
- **Cache:** Store last successful fetch to show stale data on network failure
- **Error handling:** Log errors, continue showing cached/other events

## Color Presets for iCal Feeds

Offer a picker with common colors:
- Red, Orange, Yellow, Green, Blue, Purple, Pink, Gray

User can also enter custom hex color.

## Implementation Tasks

1. Add `NSCalendarsUsageDescription` to Info.plist
2. Create `ICalFeed` model
3. Create `ICalService` with ICS parsing
4. Add `iCalFeeds` to AppSettings
5. Add `SettingsTab.calendar` case with icon
6. Create `CalendarTabView` for Settings
7. Create `AddICalFeedSheet` for adding/editing feeds
8. Update `CalendarService` to merge local + iCal events
9. Remove Calendar section from `ExtrasTabView`
10. Update `MainClockView` to use combined event fetching
11. Write tests for ICalService parsing

## ICS Format Reference

Standard iCal event structure:
```
BEGIN:VEVENT
UID:event-unique-id@example.com
DTSTART:20260129T100000Z
DTEND:20260129T110000Z
SUMMARY:Team Meeting
DESCRIPTION:Weekly sync
RRULE:FREQ=WEEKLY;BYDAY=WE
END:VEVENT
```

All-day event:
```
BEGIN:VEVENT
DTSTART;VALUE=DATE:20260129
DTEND;VALUE=DATE:20260130
SUMMARY:Holiday
END:VEVENT
```
