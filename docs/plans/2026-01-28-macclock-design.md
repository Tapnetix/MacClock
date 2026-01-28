# MacClock - Design Document

**Date:** 2026-01-28
**Status:** Approved

## Overview

A native macOS clock application displaying time, date, and weather against scenic backgrounds. Designed to sit in a corner of a multi-monitor setup as a desktop companion while working.

## Core Features

- Large digital time display (LCD/LED segment style) with optional seconds
- Date display (day of week, month, day, year)
- Current weather: temperature, conditions icon, location name
- Time-based scenic backgrounds (dawn, day, dusk, night) with option for custom images
- Configurable window behavior (normal, floating, desktop level)

## Technology Stack

- **Platform:** macOS 13+ (Ventura)
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Weather API:** Open-Meteo (free, no API key required)
- **Dependencies:** None external - Apple frameworks only (SwiftUI, CoreLocation, Foundation, ServiceManagement)

## User Interface

### Main Window

```
┌─────────────────────────────────────────┐
│  ☀️ 72°F  San Francisco          [⚙️]  │  ← Weather top-left, settings gear top-right
│                                         │
│           11:59 AM                      │  ← Large digital time, center
│              :45                        │  ← Seconds smaller, below or beside
│                                         │
│       Sunday, January 28, 2026          │  ← Date below time
│                                         │
└─────────────────────────────────────────┘
    ↑ Scenic background image fills window
```

### Window Specifications

- Resizable with sensible default (480x320 points)
- No title bar in "widget mode", standard title bar in "normal window" mode
- Remembers position and size between launches
- Works correctly across multiple displays

### Typography

- **Time:** Custom LCD/LED segment font (DSEG, OFL licensed)
- **Date/Weather:** SF Pro or system font with subtle shadow for readability

### Settings Panel

Accessible via gear icon, contains:
- Window behavior: Normal / Always on Top / Desktop Level
- Location: Auto-detect toggle + manual city search
- Background: Grid of bundled images + "Choose Custom..." button
- Display: 12/24 hour, show/hide seconds, temperature unit (°F/°C)
- Launch at login toggle

## Backgrounds

### Bundled Backgrounds

4 time-based scenes included (dawn, day, dusk, night). Time thresholds based on actual sunrise/sunset from weather API:

- **Dawn:** 1 hour before sunrise → sunrise
- **Day:** sunrise → 1 hour before sunset
- **Dusk:** 1 hour before sunset → 1 hour after sunset
- **Night:** 1 hour after sunset → 1 hour before sunrise

### Custom Backgrounds

- User can select a single image or a folder
- If folder selected: randomly picks one on launch
- Supports JPEG, PNG, HEIC
- Images scaled to fill with aspect ratio preserved

## Weather Integration

### API

- **Service:** Open-Meteo (`https://api.open-meteo.com/v1/forecast`)
- **Data fetched:** current temperature, weather code, sunrise/sunset times
- **Refresh interval:** every 30 minutes

### Location

- Primary: CoreLocation (automatic, with user permission)
- Fallback: Manual city entry with geocoding
- User can override automatic location with a fixed city

### Error Handling

- If weather fetch fails, clock continues working
- Weather area shows "—" when data unavailable
- Retries on next interval

### Weather Icons

SF Symbols mapped from Open-Meteo weather codes:
- Clear: `sun.max.fill`
- Cloudy: `cloud.fill`
- Rain: `cloud.rain.fill`
- Snow: `cloud.snow.fill`
- etc.

## Window Behavior

### Configurable Levels

1. **Normal:** Standard window, appears in Cmd+Tab and Mission Control, can be covered
2. **Floating:** Stays above normal windows, doesn't appear in Cmd+Tab
3. **Desktop:** Sits behind all windows on desktop layer

### Persistence

- Position, size, and display saved to UserDefaults
- Restored on launch to same screen if available
- Falls back to main screen if saved display disconnected

### Menu Bar

- Optional menu bar icon (allows hiding Dock icon)

## Project Structure

```
MacClock/
├── MacClockApp.swift          # App entry point
├── Views/
│   ├── ClockView.swift        # Main clock display
│   ├── SettingsView.swift     # Preferences panel
│   └── WeatherView.swift      # Weather display component
├── Models/
│   ├── WeatherData.swift      # Weather response model
│   └── AppSettings.swift      # Settings model with UserDefaults
├── Services/
│   ├── WeatherService.swift   # Open-Meteo API client
│   ├── LocationService.swift  # CoreLocation wrapper
│   └── BackgroundManager.swift# Time-based image selection
├── Utilities/
│   └── WindowManager.swift    # Window level control
├── Resources/
│   ├── Backgrounds/           # Bundled dawn/day/dusk/night images
│   └── Fonts/                 # DSEG LCD font
└── Assets.xcassets            # App icon, colors
```

## Scope

### In Scope (MVP)

- Digital clock with time, date, seconds (toggleable)
- Weather display with temperature, icon, location name
- 4 bundled time-based backgrounds + custom image support
- Settings panel for all customization options
- Configurable window behavior (normal/floating/desktop)
- Remember window position/size across launches
- Launch at login option
- 12/24 hour and °F/°C toggles

### Out of Scope

- Alarms/timers
- World clocks
- Calendar integration
- News ticker
- Multiple themes/clock styles
- Menu bar-only mode

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| LCD font licensing | Use DSEG font (OFL licensed, free for any use) |
| Background image licensing | Source from Unsplash/Pexels (royalty-free) |
| Location permission denied | Graceful fallback to manual entry, clear messaging |
| Weather API unavailable | Clock works without weather, shows placeholder |

## Distribution

Starting as personal use (run from Xcode). Options for later:
- Mac App Store (requires Developer account, sandboxing)
- Direct download with notarization
- Open source on GitHub
