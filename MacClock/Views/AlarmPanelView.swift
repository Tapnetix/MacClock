import SwiftUI

struct AlarmPanelView: View {
    @Bindable var settings: AppSettings
    let alarmService: AlarmService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var showAddAlarm = false
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

            // Tab bar
            HStack(spacing: 0) {
                TabButton(title: "Alarms", isSelected: selectedTab == 0) { selectedTab = 0 }
                TabButton(title: "Timer", isSelected: selectedTab == 1) { selectedTab = 1 }
                TabButton(title: "Stopwatch", isSelected: selectedTab == 2) { selectedTab = 2 }
            }
            .padding(.horizontal)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case 0:
                    AlarmsTabView(settings: settings, showAddAlarm: $showAddAlarm)
                case 1:
                    TimerTabView(timer: countdownTimer)
                case 2:
                    StopwatchTabView(stopwatch: stopwatch)
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 350, height: 400)
        .sheet(isPresented: $showAddAlarm) {
            AlarmEditView(settings: settings, alarm: nil, isPresented: $showAddAlarm)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct AlarmsTabView: View {
    @Bindable var settings: AppSettings
    @Binding var showAddAlarm: Bool

    var body: some View {
        VStack {
            if settings.alarms.isEmpty {
                Spacer()
                Text("No alarms")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach($settings.alarms) { $alarm in
                        AlarmRow(alarm: $alarm, onDelete: {
                            settings.alarms.removeAll { $0.id == alarm.id }
                        })
                    }
                }
            }

            Button {
                showAddAlarm = true
            } label: {
                Label("Add Alarm", systemImage: "plus.circle.fill")
            }
            .padding()
        }
    }
}

struct AlarmRow: View {
    @Binding var alarm: Alarm
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Toggle("", isOn: $alarm.isEnabled)
                .labelsHidden()

            VStack(alignment: .leading) {
                Text(alarm.timeString)
                    .font(.system(size: 20, weight: .medium, design: .monospaced))
                Text(alarm.label.isEmpty ? alarm.repeatDescription : alarm.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}

struct TimerTabView: View {
    @Bindable var timer: CountdownTimer

    var body: some View {
        VStack(spacing: 20) {
            Text(timer.displayTime)
                .font(.system(size: 60, weight: .light, design: .monospaced))

            if !timer.isRunning && timer.remainingSeconds == 0 {
                // Presets
                HStack(spacing: 12) {
                    ForEach([5, 10, 15, 30, 60], id: \.self) { minutes in
                        Button("\(minutes)m") {
                            timer.start(minutes: minutes)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            HStack(spacing: 20) {
                if timer.isRunning {
                    Button("Pause") { timer.pause() }
                        .buttonStyle(.borderedProminent)
                } else if timer.remainingSeconds > 0 {
                    Button("Resume") { timer.resume() }
                        .buttonStyle(.borderedProminent)
                }

                if timer.remainingSeconds > 0 || timer.isComplete {
                    Button("Reset") { timer.reset() }
                        .buttonStyle(.bordered)
                }
            }

            if timer.isComplete {
                Text("Timer Complete!")
                    .font(.headline)
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}

struct StopwatchTabView: View {
    @Bindable var stopwatch: Stopwatch

    var body: some View {
        VStack(spacing: 20) {
            Text(stopwatch.displayTime)
                .font(.system(size: 50, weight: .light, design: .monospaced))

            HStack(spacing: 20) {
                if stopwatch.isRunning {
                    Button("Lap") { stopwatch.lap() }
                        .buttonStyle(.bordered)
                    Button("Stop") { stopwatch.stop() }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Reset") { stopwatch.reset() }
                        .buttonStyle(.bordered)
                        .disabled(stopwatch.elapsedMilliseconds == 0)
                    Button("Start") { stopwatch.start() }
                        .buttonStyle(.borderedProminent)
                }
            }

            if !stopwatch.laps.isEmpty {
                List {
                    ForEach(Array(stopwatch.laps.enumerated().reversed()), id: \.offset) { index, lap in
                        HStack {
                            Text("Lap \(index + 1)")
                            Spacer()
                            Text(stopwatch.formatLapTime(lap))
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding()
    }
}

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

    var body: some View {
        VStack(spacing: 16) {
            Text(alarm == nil ? "Add Alarm" : "Edit Alarm")
                .font(.headline)

            // Time display with steppers
            HStack(spacing: 8) {
                VStack {
                    Text("Hour")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Button {
                            selectedHour = (selectedHour - 1 + 24) % 24
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(.plain)

                        Text(String(format: "%02d", selectedHour))
                            .font(.system(size: 32, weight: .medium, design: .monospaced))
                            .frame(width: 50)

                        Button {
                            selectedHour = (selectedHour + 1) % 24
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(":")
                    .font(.system(size: 32, weight: .medium, design: .monospaced))

                VStack {
                    Text("Minute")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Button {
                            selectedMinute = (selectedMinute - 1 + 60) % 60
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(.plain)

                        Text(String(format: "%02d", selectedMinute))
                            .font(.system(size: 32, weight: .medium, design: .monospaced))
                            .frame(width: 50)

                        Button {
                            selectedMinute = (selectedMinute + 1) % 60
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)

            TextField("Label (optional)", text: $label)
                .textFieldStyle(.roundedBorder)

            // Repeat days
            HStack {
                ForEach(Alarm.Weekday.allCases, id: \.self) { day in
                    Button(day.shortName.prefix(1).uppercased()) {
                        if repeatDays.contains(day) {
                            repeatDays.remove(day)
                        } else {
                            repeatDays.insert(day)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(repeatDays.contains(day) ? .accentColor : .secondary)
                }
            }

            // Sound
            Picker("Sound", selection: $soundName) {
                Text("None").tag(nil as String?)
                ForEach(AlarmService.availableSounds, id: \.self) { sound in
                    Text(sound).tag(sound as String?)
                }
            }

            // Snooze
            Picker("Snooze", selection: $snoozeDuration) {
                Text("5 min").tag(5)
                Text("10 min").tag(10)
                Text("15 min").tag(15)
            }
            .pickerStyle(.segmented)

            HStack {
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered)

                Button("Save") {
                    saveAlarm()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
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
    }

    private func saveAlarm() {
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: DateComponents(hour: selectedHour, minute: selectedMinute),
            label: label,
            isEnabled: true,
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
}
