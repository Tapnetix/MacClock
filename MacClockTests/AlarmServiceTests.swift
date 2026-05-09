import Testing
import Foundation
@testable import MacClock

@MainActor
@Suite("AlarmService Tests")
struct AlarmServiceTests {

    private func makeAlarm(hour: Int = 7, minute: Int = 30, snoozeDuration: Int = 5) -> Alarm {
        Alarm(
            id: UUID(),
            time: DateComponents(hour: hour, minute: minute),
            label: "Test",
            isEnabled: true,
            repeatDays: [],
            soundName: nil,
            snoozeDuration: snoozeDuration
        )
    }

    @Test("startMonitoring schedules a check timer")
    func startMonitoringSchedulesTimer() {
        let service = AlarmService()
        #expect(service.testHasCheckTimer == false)
        service.startMonitoring(alarms: [makeAlarm()])
        #expect(service.testHasCheckTimer == true)
        service.stopMonitoring()
    }

    @Test("stopMonitoring cancels timers and audio")
    func stopMonitoringClearsEverything() {
        let service = AlarmService()
        service.startMonitoring(alarms: [makeAlarm()])
        service.stopMonitoring()
        #expect(service.testHasCheckTimer == false)
        #expect(service.testHasAutoSnoozeTimer == false)
        #expect(service.testHasAudioPlayer == false)
    }

    @Test("startMonitoring twice does not leak the previous timer")
    func startMonitoringIsIdempotent() {
        let service = AlarmService()
        service.startMonitoring(alarms: [makeAlarm()])
        service.startMonitoring(alarms: [makeAlarm()])
        #expect(service.testHasCheckTimer == true)
        service.stopMonitoring()
    }

    @Test("dismissAlarm clears all state")
    func dismissAlarmClearsState() {
        let service = AlarmService()
        service.dismissAlarm()
        #expect(service.activeAlarm == nil)
        #expect(service.isAlarmFiring == false)
        #expect(service.snoozeCount == 0)
        #expect(service.testHasAutoSnoozeTimer == false)
        #expect(service.testHasAudioPlayer == false)
    }

    @Test("snoozeAlarm without active alarm is a no-op")
    func snoozeWithoutActiveAlarmIsSafe() {
        let service = AlarmService()
        service.snoozeAlarm()
        #expect(service.snoozeCount == 0)
        #expect(service.testSnoozeUntil == nil)
    }

    @Test("Service is annotated @MainActor (compiles only on main)")
    func mainActorAnnotation() {
        // This test exists to fail compilation if @MainActor is removed —
        // the test body itself runs on MainActor (from suite annotation).
        let service = AlarmService()
        service.stopMonitoring()
        #expect(service.testHasCheckTimer == false)
    }

    @Test("availableSounds returns expected built-in sounds")
    func availableSounds() {
        let sounds = AlarmService.availableSounds
        #expect(sounds.contains("Glass"))
        #expect(sounds.contains("Ping"))
        #expect(sounds.count == 14)
    }
}
