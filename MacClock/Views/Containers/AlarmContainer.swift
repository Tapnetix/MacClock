import SwiftUI

/// Owns the AlarmService lifecycle, the firing-alarm overlay, and the alarm
/// panel sheet. Exposes a `Binding<Bool>` (showAlarmPanel) to its content
/// closure so the parent's alarm-toolbar button can trigger the sheet.
struct AlarmContainer<Content: View>: View {
    let settings: AppSettings
    let theme: ColorTheme
    @ViewBuilder let content: (Binding<Bool>) -> Content

    @State private var alarmService = AlarmService()
    @State private var showAlarmPanel = false

    var body: some View {
        ZStack {
            content($showAlarmPanel)

            if alarmService.isAlarmFiring, let alarm = alarmService.activeAlarm {
                AlarmFiringView(
                    alarm: alarm,
                    onDismiss: {
                        disableIfOneTime(alarm)
                        alarmService.dismissAlarm()
                    },
                    onSnooze: { alarmService.snoozeAlarm() },
                    theme: theme,
                    snoozeCount: alarmService.snoozeCount,
                    maxSnoozes: 10
                )
            }
        }
        .sheet(isPresented: $showAlarmPanel) {
            AlarmPanelView(settings: settings, alarmService: alarmService)
        }
        .onAppear {
            alarmService.outputDeviceUID = settings.alarmOutputDeviceUID
            alarmService.onAlarmDismissed = { [weak settings] alarm in
                guard let settings else { return }
                guard alarm.repeatDays.isEmpty else { return }
                if let index = settings.alarms.firstIndex(where: { $0.id == alarm.id }) {
                    settings.alarms[index].isEnabled = false
                }
            }
            alarmService.startMonitoring(alarms: settings.alarms)
        }
        .onDisappear {
            alarmService.stopMonitoring()
        }
        .onChange(of: settings.alarms) { _, newAlarms in
            alarmService.startMonitoring(alarms: newAlarms)
        }
        .onChange(of: settings.alarmOutputDeviceUID) { _, newUID in
            alarmService.outputDeviceUID = newUID
        }
    }

    private func disableIfOneTime(_ alarm: Alarm) {
        guard alarm.repeatDays.isEmpty else { return }
        if let index = settings.alarms.firstIndex(where: { $0.id == alarm.id }) {
            settings.alarms[index].isEnabled = false
        }
    }
}
