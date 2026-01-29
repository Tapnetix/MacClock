# MacClock Feature Expansion Design

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:writing-plans to create implementation plan from this design.

**Goal:** Expand MacClock from a simple clock display to a full-featured desk clock with alarms, customization, information display, and cross-device sync.

**Date:** January 29, 2026

---

## 1. Alarms & Timers

### Overview
Separate floating panel for managing alarms, countdown timers, and stopwatch. Alarms only fire when app is running (no background daemon).

### Alarm Panel Layout
```
+------------------------------------------+
|  Alarms      Timer      Stopwatch        |  <- Tab bar
+------------------------------------------+
|                                          |
|  ( ) 7:00 AM   Wake Up        [Edit] [x] |
|  ( ) 9:00 AM   Standup        [Edit] [x] |
|  (*) 12:30 PM  Lunch (repeat) [Edit] [x] |
|                                          |
|              [+ Add Alarm]               |
|                                          |
+------------------------------------------+
```

### Alarm Settings (per alarm)
- Time picker (hour:minute, AM/PM or 24h based on global setting)
- Label (optional text)
- Repeat: Never / Daily / Weekdays / Weekends / Custom days
- Sound: None (default), system sounds, or custom audio file
- Snooze duration: 5 / 10 / 15 minutes

### When Alarm Fires
1. macOS notification appears with Snooze/Dismiss actions
2. Clock display pulses gently (opacity oscillation or border glow)
3. Sound plays if enabled (respects system volume)
4. Sound is OFF by default - user must enable

### Timer Tab
- Preset buttons: 5, 10, 15, 30, 60 minutes
- Custom time input
- Large countdown display
- Audio alert when complete

### Stopwatch Tab
- Start / Stop / Lap / Reset buttons
- Lap time list with splits
- Elapsed time in large display

### Technical Notes
- Uses `UserNotifications` framework for macOS notifications
- Alarm data stored in `AppSettings` (syncs via iCloud)
- Timer/stopwatch state is ephemeral (not persisted)

---

## 2. Display Customization

### Clock Styles

**Digital (current)**
- DSEG7 LCD-style font
- Configurable size
- Optional seconds display

**Analog**
- Minimalist circular face with hour markers (no numerals)
- Smooth sweeping second hand
- Hour and minute hands with subtle shadow
- Date shown below clock face
- Optional small digital time beneath

**Flip Clock (Solari-style)**
- Split-flap mechanical display aesthetic
- Animated card flip on digit change
- Slight 3D perspective effect
- Optional mechanical flip sound (off by default)

### Color Themes (6 Presets)

| Theme | Digits | Accents | Best With |
|-------|--------|---------|-----------|
| Classic White | #FFFFFF | #AAAAAA | Any background |
| Neon Blue | #00FFFF | #0066FF | Dark backgrounds |
| Warm Amber | #FFA500 | #FFD700 | Night mode |
| Matrix Green | #00FF00 | #006600 | Dark backgrounds |
| Sunset Red | #FF6B6B | #FF69B4 | Nature photos |
| Minimal Gray | #CCCCCC | #888888 | Professional |

Themes affect: digit color, date text, weather text, UI accents, clock hands (analog)

### Auto-Dim

**Trigger Options:**
1. Sunrise/Sunset (recommended) - uses weather API data
2. Fixed Schedule - user sets dim/brighten times
3. Follow macOS Appearance - dims when Dark Mode activates

**Settings:**
- Dim level: 20% - 80% (slider)
- Night color theme: optionally switch to Warm Amber when dimmed
- Transition duration: 2 seconds (smooth fade)

### Auto Theme Switching
- Day theme / Night theme selection
- Switches based on sunrise/sunset or macOS appearance
- Independent from auto-dim (can use both)

---

## 3. Smart Features

### Focus Mode Integration

When any macOS Focus mode is active:

| Element | Behavior |
|---------|----------|
| Weather | Hidden |
| News ticker | Hidden |
| Calendar events | Hidden |
| World clocks | Hidden |
| Alarm sounds | Suppressed (visual pulse only) |
| Clock + Date | Always visible |

**Settings:**
- Master toggle for Focus integration
- Individual toggles for each element
- Optional moon icon indicator when Focus is active

**Technical:** Uses `NSWorkspace.shared.notificationCenter` to observe Focus state changes.

---

## 4. Additional Information Display

### Calendar Integration

**Next Event Countdown (top bar):**
```
[calendar icon] Team Standup in 25 min
```

**Day Agenda Panel (optional, off by default):**
- Vertical list on left or right side
- Shows remaining events for today
- Color-coded by calendar source
- Tap event to open in Calendar.app

**Settings:**
- Toggle countdown display
- Toggle agenda panel
- Panel position: Left / Right
- Calendar selection (which calendars to show)

**Technical:** Uses `EventKit` framework. Requires calendar permission.

### World Clocks

**Bottom Bar Mode:**
```
+------------+------------+------------+
| NYC        | LONDON     | TOKYO      |
| 7:45 AM    | 12:45 PM   | 9:45 PM +1 |
+------------+------------+------------+
```

**Side Panel Mode:**
```
+-------------+
| NEW YORK    |
| 7:45 AM EST |
+-------------+
| LONDON      |
| 12:45 PM GMT|
+-------------+
| TOKYO       |
| 9:45 PM +1  |
| JST         |
+-------------+
```

**Settings:**
- Position: Bottom bar / Side panel
- Add city (searchable, uses system timezone DB)
- Maximum 5 cities
- Show timezone abbreviation toggle
- Show day difference (+1, -1) toggle

### News Ticker

**Display Styles:**

*Scrolling Marquee:*
- Continuous left-to-right scroll at bottom
- Pauses on hover
- Configurable speed

*Rotating Headlines:*
- One headline at a time
- Fade transition
- Configurable interval (5-30 seconds)

**Built-in Sources:**
- BBC World News
- Reuters Top Stories
- AP News
- NPR News
- The Guardian

**Custom RSS:**
- User can add any RSS feed URL
- Validation on add
- Remove button per feed

**Behavior:**
- Click headline to open in browser
- Refresh interval: 15 / 30 / 60 minutes
- Graceful fallback if feeds unavailable

---

## 5. iCloud Sync

### What Syncs

| Category | Data | Method |
|----------|------|--------|
| Display | Theme, clock style, font size, opacity | NSUbiquitousKeyValueStore |
| Alarms | All alarms with full settings | NSUbiquitousKeyValueStore |
| World Clocks | City list, positions | NSUbiquitousKeyValueStore |
| News | Feed URLs, selected sources | NSUbiquitousKeyValueStore |
| Calendar | Which calendars, panel settings | NSUbiquitousKeyValueStore |
| Backgrounds | Custom images only | CloudKit (CKAsset) |

### Settings UI
```
+------------------------------------------+
| iCloud Sync                        [ON]  |
+------------------------------------------+
| What to sync:                            |
|   [x] Preferences & display settings     |
|   [x] Alarms & timers                    |
|   [x] World clocks                       |
|   [x] News feed sources                  |
|   [ ] Custom background images           |
|                                          |
| Status: Synced 2 minutes ago             |
|                                          |
| [Sync Now]                               |
|                                          |
| Note: Backgrounds use iCloud storage     |
| Currently using: 12.4 MB                 |
+------------------------------------------+
```

### Sync Behavior
- Auto-sync on settings change (5-second debounce)
- Pull latest on app launch
- Conflict resolution: most recent wins
- Works offline (local settings always available)

### First-Time Setup
- Detects existing iCloud settings: "Settings found from another Mac. Use them?" [Yes / Keep Local]
- Background sync prompted separately due to storage

---

## 6. Updated Settings Organization

Settings will be reorganized into sections:

1. **Display**
   - Clock style (Digital / Analog / Flip)
   - Theme
   - Clock size
   - Show seconds
   - 24-hour time

2. **Appearance**
   - Auto-dim settings
   - Auto theme switching
   - Window opacity

3. **Window**
   - Behavior (Normal / Floating / Desktop)
   - Launch at login

4. **Location & Weather**
   - Auto-detect / Manual location
   - Temperature unit

5. **Background**
   - Mode (Time of Day / Nature / Custom)
   - Cycle interval
   - Custom image selection

6. **Information**
   - Calendar settings
   - World clocks
   - News ticker

7. **Alarms** (opens separate panel)

8. **Focus Mode**
   - Integration toggles

9. **iCloud**
   - Sync toggles

---

## 7. Implementation Priority

Suggested implementation order based on complexity and user value:

### Phase 1: Core Enhancements
1. Color themes (preset only)
2. Auto-dim with sunrise/sunset
3. Background crossfade animation

### Phase 2: Display Options
4. Analog clock style
5. Flip clock style
6. Auto theme switching

### Phase 3: Information
7. World clocks
8. Calendar integration
9. News ticker

### Phase 4: Alarms
10. Alarm panel and basic alarms
11. Timer and stopwatch
12. Alarm sounds and notifications

### Phase 5: Smart & Sync
13. Focus mode integration
14. iCloud sync (settings)
15. iCloud sync (backgrounds)

---

## Appendix: New Permissions Required

| Feature | Permission | Framework |
|---------|-----------|-----------|
| Calendar | Calendar access | EventKit |
| Notifications | Push notifications | UserNotifications |
| iCloud | iCloud container | CloudKit |

All permissions should be requested just-in-time when feature is first enabled, not at app launch.
