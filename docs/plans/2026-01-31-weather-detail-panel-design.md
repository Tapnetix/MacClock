# Weather Detail Panel Design

## Overview

Add an expandable weather detail panel that appears when clicking the temperature display. Shows extended forecast information in a dropdown overlay, matching the visual style of existing panels (world clocks, calendar agenda).

## User Interaction

**Trigger:** Click on weather display (temperature/icon) in top-left corner

**Behavior:**
- First click: Panel drops down, overlaying the clock area
- Second click: Panel disappears
- Clicking outside panel also closes it

**Animation:** Smooth slide-down (0.2s ease-out)

## Visual Design

**Panel positioning:**
- Anchored to weather display (top-left aligned)
- Drops down vertically below weather row
- Width: ~200px
- Does not extend window - overlays existing content

**Panel styling (matches world clocks):**
- Background: `Color.black.opacity(0.3)`
- Corner radius: 6px
- Padding: 10px horizontal, 8px vertical
- Text colors: Theme's `primaryColor` and `accentColor`
- Subtle drop shadow

**Content layout:**
```
┌─────────────────────────┐
│ Feels like 4°C          │
│ Humidity 85%            │
│ High 8°  Low 3°         │
├─────────────────────────┤
│ ☀ 07:32    🌙 17:45     │
├─────────────────────────┤
│ 11:00  12:00  13:00 ... │
│  🌧     🌧     🌥    ... │
│  5°     6°     6°   ... │
├─────────────────────────┤
│ Today      🌧   8° / 3° │
│ Sat        🌥   9° / 4° │
│ Sun        ☀  11° / 5° │
└─────────────────────────┘
```

**Typography:**
- Section data: 14-16px, primary color
- Hourly temps: 12px, compact
- Daily rows: 12px, day left-aligned, icon centered, temps right-aligned

## Configuration

**Settings UI (Weather section):**
```
┌─ Weather Details ─────────────────────┐
│ ☑ Enable weather detail panel         │
│                                       │
│ Show in panel:                        │
│   ☑ Current conditions                │
│     (feels like, humidity, high/low)  │
│   ☑ Sunrise & sunset                  │
│   ☑ Hourly forecast (6 hours)         │
│   ☑ Daily forecast (3 days)           │
└───────────────────────────────────────┘
```

**New AppSettings properties:**
- `weatherDetailEnabled: Bool` (default: true)
- `weatherShowCurrentDetails: Bool` (default: true)
- `weatherShowSunriseSunset: Bool` (default: true)
- `weatherShowHourly: Bool` (default: true)
- `weatherShowDaily: Bool` (default: true)

## Data Requirements

**Extended Open-Meteo API request:**
- Current: `apparent_temperature`, `relative_humidity_2m`
- Daily: `temperature_2m_max`, `temperature_2m_min`, `weather_code` (3 days)
- Hourly: `temperature_2m`, `weather_code` (next 6 hours)

**Extended WeatherData model:**
```swift
struct WeatherData {
    // Existing
    let temperature: Double
    let condition: WeatherCondition
    let locationName: String
    let sunrise: Date
    let sunset: Date

    // New
    let feelsLike: Double
    let humidity: Int
    let highTemp: Double
    let lowTemp: Double
    let hourlyForecast: [HourlyWeather]  // 6 items
    let dailyForecast: [DailyWeatherForecast]  // 3 items
}

struct HourlyWeather {
    let time: Date
    let temperature: Double
    let condition: WeatherCondition
}

struct DailyWeatherForecast {
    let date: Date
    let highTemp: Double
    let lowTemp: Double
    let condition: WeatherCondition
}
```

## Files Affected

1. `MacClock/Models/WeatherData.swift` - Extended model
2. `MacClock/Services/WeatherService.swift` - Fetch additional data
3. `MacClock/Views/WeatherView.swift` - Click handler and dropdown panel
4. `MacClock/Models/AppSettings.swift` - New preferences
5. `MacClock/Views/SettingsView.swift` - Weather settings section
6. `MacClock/MacClockApp.swift` - Pass state to WeatherView

## Forecast Limits

- Hourly forecast: 6 hours ahead
- Daily forecast: 3 days (today + 2 days)
