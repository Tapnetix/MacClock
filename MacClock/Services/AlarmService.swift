import Foundation
import UserNotifications
import AVFoundation
import AppKit

@Observable
final class AlarmService {
    private(set) var activeAlarm: Alarm?
    private(set) var isAlarmFiring = false
    private var audioPlayer: AVAudioPlayer?
    private var checkTimer: Timer?
    private var snoozeUntil: Date?

    init() {
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func startMonitoring(alarms: [Alarm]) {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkAlarms(alarms)
        }
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    private func checkAlarms(_ alarms: [Alarm]) {
        // Don't fire if snoozed
        if let snoozeUntil = snoozeUntil, Date() < snoozeUntil {
            return
        }
        snoozeUntil = nil

        let now = Date()

        for alarm in alarms where alarm.isEnabled {
            guard let fireDate = alarm.nextFireDate else { continue }

            // Check if fire date is within this second
            let diff = fireDate.timeIntervalSince(now)
            if diff >= 0 && diff < 1 {
                fireAlarm(alarm)
                break
            }
        }
    }

    private func fireAlarm(_ alarm: Alarm) {
        guard !isAlarmFiring else { return }

        activeAlarm = alarm
        isAlarmFiring = true

        // Send notification
        sendNotification(for: alarm)

        // Play sound if enabled
        if let soundName = alarm.soundName {
            playSound(named: soundName)
        }
    }

    private func sendNotification(for alarm: Alarm) {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = alarm.label.isEmpty ? "Alarm" : alarm.label
        content.categoryIdentifier = "ALARM"

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func playSound(named name: String) {
        guard let url = getSoundURL(for: name) else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            audioPlayer?.play()
        } catch {
            print("Failed to play alarm sound: \(error)")
        }
    }

    private func getSoundURL(for name: String) -> URL? {
        // Check for system sounds
        let systemSoundPath = "/System/Library/Sounds/\(name).aiff"
        if FileManager.default.fileExists(atPath: systemSoundPath) {
            return URL(fileURLWithPath: systemSoundPath)
        }
        return nil
    }

    func dismissAlarm() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false
        activeAlarm = nil
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func snoozeAlarm() {
        guard let alarm = activeAlarm else { return }

        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false

        snoozeUntil = Date().addingTimeInterval(TimeInterval(alarm.snoozeDuration * 60))
        activeAlarm = nil
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    static var availableSounds: [String] {
        [
            "Basso",
            "Blow",
            "Bottle",
            "Frog",
            "Funk",
            "Glass",
            "Hero",
            "Morse",
            "Ping",
            "Pop",
            "Purr",
            "Sosumi",
            "Submarine",
            "Tink"
        ]
    }
}
