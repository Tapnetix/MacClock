import SwiftUI
import AVFoundation

enum AlarmTab: String, CaseIterable {
    case alarms = "Alarms"
    case timer = "Timer"
    case stopwatch = "Stopwatch"

    var icon: String {
        switch self {
        case .alarms: return "alarm.fill"
        case .timer: return "timer"
        case .stopwatch: return "stopwatch.fill"
        }
    }
}

struct AlarmPanelView: View {
    @Bindable var settings: AppSettings
    let alarmService: AlarmService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: AlarmTab = .alarms
    @State private var showAlarmEditor = false
    @State private var editingAlarm: Alarm?
    @State private var countdownTimer = CountdownTimer()
    @State private var stopwatch = Stopwatch()

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Alarms & Timers")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Toolbar-style tab bar
            HStack(spacing: 4) {
                ForEach(AlarmTab.allCases, id: \.self) { tab in
                    AlarmTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .alarms:
                    AlarmsTabView(
                        settings: settings,
                        onAddAlarm: {
                            editingAlarm = nil
                            showAlarmEditor = true
                        },
                        onEditAlarm: { alarm in
                            editingAlarm = alarm
                            showAlarmEditor = true
                        }
                    )
                case .timer:
                    TimerTabView(timer: countdownTimer)
                case .stopwatch:
                    StopwatchTabView(stopwatch: stopwatch)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 380, height: 420)
        .sheet(isPresented: $showAlarmEditor) {
            AlarmEditView(
                settings: settings,
                alarm: editingAlarm,
                isPresented: $showAlarmEditor
            )
        }
    }
}

// MARK: - Tab Button

struct AlarmTabButton: View {
    let tab: AlarmTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                    .frame(height: 20)
                Text(tab.rawValue)
                    .font(.system(size: 10))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Alarms Tab

struct AlarmsTabView: View {
    @Bindable var settings: AppSettings
    let onAddAlarm: () -> Void
    let onEditAlarm: (Alarm) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if settings.alarms.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "alarm")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No alarms")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(settings.alarms) { alarm in
                            AlarmRow(
                                alarm: bindingForAlarm(alarm),
                                onEdit: { onEditAlarm(alarm) },
                                onDelete: {
                                    withAnimation {
                                        settings.alarms.removeAll { $0.id == alarm.id }
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }

            Divider()

            Button {
                onAddAlarm()
            } label: {
                Label("Add Alarm", systemImage: "plus.circle.fill")
            }
            .padding()
        }
    }

    private func bindingForAlarm(_ alarm: Alarm) -> Binding<Alarm> {
        Binding(
            get: {
                settings.alarms.first { $0.id == alarm.id } ?? alarm
            },
            set: { newValue in
                if let index = settings.alarms.firstIndex(where: { $0.id == alarm.id }) {
                    settings.alarms[index] = newValue
                }
            }
        )
    }
}

// MARK: - Alarm Row

struct AlarmRow: View {
    @Binding var alarm: Alarm
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Enable/Disable toggle
            Toggle("", isOn: $alarm.isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)

            // Alarm info (tappable to edit)
            Button(action: onEdit) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alarm.timeString)
                            .font(.system(size: 24, weight: .medium, design: .monospaced))
                            .foregroundStyle(alarm.isEnabled ? .primary : .secondary)

                        HStack(spacing: 8) {
                            if !alarm.label.isEmpty {
                                Text(alarm.label)
                                    .font(.caption)
                                    .foregroundStyle(alarm.isEnabled ? .secondary : .tertiary)
                            }

                            Text(alarm.repeatDescription)
                                .font(.caption)
                                .foregroundStyle(alarm.isEnabled ? .secondary : .tertiary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundStyle(.red.opacity(alarm.isEnabled ? 1.0 : 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor).opacity(alarm.isEnabled ? 1.0 : 0.5))
        .cornerRadius(8)
        .opacity(alarm.isEnabled ? 1.0 : 0.7)
    }
}

// MARK: - Timer Tab

struct TimerTabView: View {
    @Bindable var timer: CountdownTimer

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Timer display
            Text(timer.displayTime)
                .font(.system(size: 56, weight: .light, design: .monospaced))
                .foregroundStyle(timer.isComplete ? .green : .primary)

            Spacer()
                .frame(height: 24)

            // Presets (when not running)
            if !timer.isRunning && timer.remainingSeconds == 0 && !timer.isComplete {
                VStack(spacing: 12) {
                    Text("Quick Start")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach([1, 5, 10, 15, 30], id: \.self) { minutes in
                            Button("\(minutes)m") {
                                timer.start(minutes: minutes)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }

            Spacer()
                .frame(height: 24)

            // Controls
            HStack(spacing: 16) {
                if timer.isRunning {
                    Button("Pause") { timer.pause() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else if timer.remainingSeconds > 0 {
                    Button("Resume") { timer.resume() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }

                if timer.remainingSeconds > 0 || timer.isComplete {
                    Button("Reset") { timer.reset() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            }

            if timer.isComplete {
                Text("Timer Complete!")
                    .font(.headline)
                    .foregroundStyle(.green)
                    .padding(.top, 16)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Stopwatch Tab

struct StopwatchTabView: View {
    @Bindable var stopwatch: Stopwatch

    var body: some View {
        VStack(spacing: 0) {
            // Time display
            Text(stopwatch.displayTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .padding(.top, 20)

            // Controls
            HStack(spacing: 16) {
                if stopwatch.isRunning {
                    Button("Lap") { stopwatch.lap() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    Button("Stop") { stopwatch.stop() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else {
                    Button("Reset") { stopwatch.reset() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(stopwatch.elapsedMilliseconds == 0)
                    Button(stopwatch.elapsedMilliseconds == 0 ? "Start" : "Resume") {
                        stopwatch.start()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(.vertical, 16)

            // Laps
            if !stopwatch.laps.isEmpty {
                Divider()

                List {
                    ForEach(Array(stopwatch.laps.enumerated().reversed()), id: \.offset) { index, lap in
                        HStack {
                            Text("Lap \(index + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(stopwatch.formatLapTime(lap))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                Spacer()
            }
        }
    }
}

// MARK: - Alarm Edit View

struct AlarmEditView: View {
    @Bindable var settings: AppSettings
    var alarm: Alarm?
    @Binding var isPresented: Bool

    @State private var selectedHour = 7
    @State private var selectedMinute = 0
    @State private var label = ""
    @State private var repeatDays: Set<Alarm.Weekday> = []
    @State private var soundName: String? = nil
    @State private var snoozeDuration = 5
    @State private var previewPlayer: AVAudioPlayer?
    @State private var isPreviewPlaying = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    stopPreview()
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text(alarm == nil ? "New Alarm" : "Edit Alarm")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    stopPreview()
                    saveAlarm()
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Time picker
                    AlarmSection(title: "Time") {
                        HStack(spacing: 8) {
                            // Hour
                            VStack(spacing: 4) {
                                Button {
                                    selectedHour = (selectedHour + 1) % 24
                                } label: {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .buttonStyle(.plain)

                                Text(String(format: "%02d", selectedHour))
                                    .font(.system(size: 48, weight: .medium, design: .monospaced))
                                    .frame(width: 70)

                                Button {
                                    selectedHour = (selectedHour - 1 + 24) % 24
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                            }

                            Text(":")
                                .font(.system(size: 48, weight: .medium, design: .monospaced))
                                .padding(.bottom, 8)

                            // Minute
                            VStack(spacing: 4) {
                                Button {
                                    selectedMinute = (selectedMinute + 1) % 60
                                } label: {
                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .buttonStyle(.plain)

                                Text(String(format: "%02d", selectedMinute))
                                    .font(.system(size: 48, weight: .medium, design: .monospaced))
                                    .frame(width: 70)

                                Button {
                                    selectedMinute = (selectedMinute - 1 + 60) % 60
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Label
                    AlarmSection(title: "Label") {
                        TextField("Alarm label", text: $label)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Repeat days
                    AlarmSection(title: "Repeat") {
                        HStack(spacing: 6) {
                            ForEach(Alarm.Weekday.allCases, id: \.self) { day in
                                Button {
                                    if repeatDays.contains(day) {
                                        repeatDays.remove(day)
                                    } else {
                                        repeatDays.insert(day)
                                    }
                                } label: {
                                    Text(String(day.shortName.prefix(1)))
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 28, height: 28)
                                        .background(repeatDays.contains(day) ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                        .foregroundStyle(repeatDays.contains(day) ? .white : .primary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if repeatDays.isEmpty {
                            Text("One-time alarm")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(repeatDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Sound
                    AlarmSection(title: "Sound") {
                        HStack {
                            Picker("", selection: $soundName) {
                                Text("None").tag(nil as String?)
                                ForEach(AlarmService.availableSounds, id: \.self) { sound in
                                    Text(sound).tag(sound as String?)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)

                            Button {
                                togglePreview()
                            } label: {
                                Image(systemName: isPreviewPlaying ? "stop.fill" : "play.fill")
                                    .font(.system(size: 12))
                                    .frame(width: 28, height: 28)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(soundName == nil)
                            .opacity(soundName == nil ? 0.5 : 1.0)
                        }
                    }

                    // Output Device
                    AlarmSection(title: "Output Device") {
                        Picker("", selection: $settings.alarmOutputDeviceUID) {
                            Text("System Default").tag("")
                            ForEach(AlarmService.availableOutputDevices()) { device in
                                Text(device.name).tag(device.id)
                            }
                        }
                        .labelsHidden()
                    }

                    // Snooze
                    AlarmSection(title: "Snooze Duration") {
                        Picker("", selection: $snoozeDuration) {
                            Text("5 minutes").tag(5)
                            Text("10 minutes").tag(10)
                            Text("15 minutes").tag(15)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                .padding()
            }
        }
        .frame(width: 320, height: 480)
        .onAppear {
            if let alarm = alarm {
                selectedHour = alarm.time.hour ?? 7
                selectedMinute = alarm.time.minute ?? 0
                label = alarm.label
                repeatDays = alarm.repeatDays
                soundName = alarm.soundName
                snoozeDuration = alarm.snoozeDuration
            }
        }
        .onDisappear {
            stopPreview()
        }
    }

    private var repeatDescription: String {
        if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays == [.saturday, .sunday] {
            return "Weekends"
        } else if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return "Weekdays"
        } else {
            let sorted = Alarm.Weekday.allCases.filter { repeatDays.contains($0) }
            return sorted.map { $0.shortName }.joined(separator: ", ")
        }
    }

    private func saveAlarm() {
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: DateComponents(hour: selectedHour, minute: selectedMinute),
            label: label,
            isEnabled: alarm?.isEnabled ?? true,
            repeatDays: repeatDays,
            soundName: soundName,
            snoozeDuration: snoozeDuration
        )

        if let existingIndex = settings.alarms.firstIndex(where: { $0.id == newAlarm.id }) {
            settings.alarms[existingIndex] = newAlarm
        } else {
            settings.alarms.append(newAlarm)
        }
    }

    private func togglePreview() {
        if isPreviewPlaying {
            stopPreview()
        } else {
            playPreview()
        }
    }

    private func playPreview() {
        guard let name = soundName else { return }

        let systemSoundPath = "/System/Library/Sounds/\(name).aiff"
        guard FileManager.default.fileExists(atPath: systemSoundPath) else { return }

        let url = URL(fileURLWithPath: systemSoundPath)
        do {
            previewPlayer = try AVAudioPlayer(contentsOf: url)
            previewPlayer?.numberOfLoops = 0  // Play once
            if !settings.alarmOutputDeviceUID.isEmpty {
                previewPlayer?.currentDevice = settings.alarmOutputDeviceUID
            }
            previewPlayer?.play()
            isPreviewPlaying = true

            // Auto-stop after the sound finishes (with a small buffer)
            let duration = previewPlayer?.duration ?? 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.1) {
                if isPreviewPlaying {
                    isPreviewPlaying = false
                }
            }
        } catch {
            print("Failed to preview sound: \(error)")
        }
    }

    private func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPreviewPlaying = false
    }
}

// MARK: - Alarm Section

struct AlarmSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
