import Foundation
import UserNotifications
import AVFoundation
import AppKit
import CoreAudio

struct AudioOutputDevice: Identifiable, Hashable {
    let id: String  // Device UID
    let name: String
}

@MainActor
@Observable
final class AlarmService {
    private(set) var activeAlarm: Alarm?
    private(set) var isAlarmFiring = false
    private(set) var snoozeCount = 0
    private static let maxSnoozes = 10
    private static let autoSnoozeSeconds: TimeInterval = 120 // 2 minutes
    private var audioPlayer: AVAudioPlayer?
    private var checkTimer: Timer?
    private var autoSnoozeTimer: Timer?
    private var snoozeUntil: Date?
    var outputDeviceUID: String = ""  // Empty = system default
    var onAlarmDismissed: ((Alarm) -> Void)?  // Called when alarm is auto-dismissed

    // MARK: - Test hooks (internal)
    // Note: avoid `_` prefix on these — `@Observable` generates `_propertyName`
    // for every observed property, which would collide.
    /// True when an audio player is currently allocated. Test-only.
    @ObservationIgnored var testHasAudioPlayer: Bool { audioPlayer != nil }
    /// True when a check timer is currently scheduled. Test-only.
    @ObservationIgnored var testHasCheckTimer: Bool { checkTimer != nil }
    /// True when an auto-snooze timer is currently scheduled. Test-only.
    @ObservationIgnored var testHasAutoSnoozeTimer: Bool { autoSnoozeTimer != nil }
    /// Current snoozeUntil value, if any. Test-only.
    @ObservationIgnored var testSnoozeUntil: Date? { snoozeUntil }

    nonisolated init() {
        // Dispatch the MainActor-isolated permission prompt off the init path
        // so this initialiser is callable from any actor (e.g. SwiftUI @State
        // default values, which Swift 5.10 evaluates in a nonisolated context).
        Task { @MainActor in
            self.requestNotificationPermission()
        }
    }

    /// Returns `UNUserNotificationCenter.current()` only when running in a real
    /// app context. In `swift test` the call crashes because there's no bundle
    /// proxy; this guard keeps unit tests safe.
    private var notificationCenter: UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }

    private func requestNotificationPermission() {
        notificationCenter?.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func startMonitoring(alarms: [Alarm]) {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAlarms(alarms)
            }
        }
    }

    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
        autoSnoozeTimer?.invalidate()
        autoSnoozeTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
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

        // Auto-snooze after 2 minutes if not dismissed
        autoSnoozeTimer?.invalidate()
        autoSnoozeTimer = Timer.scheduledTimer(withTimeInterval: Self.autoSnoozeSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.autoSnooze()
            }
        }
    }

    private func autoSnooze() {
        guard isAlarmFiring, let alarm = activeAlarm else { return }

        if snoozeCount >= Self.maxSnoozes {
            // Exceeded max snoozes — dismiss permanently
            let alarmToDisable = alarm
            dismissAlarm()
            onAlarmDismissed?(alarmToDisable)
            return
        }

        snoozeCount += 1
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false

        snoozeUntil = Date().addingTimeInterval(TimeInterval(alarm.snoozeDuration * 60))
        activeAlarm = nil
        notificationCenter?.removeAllDeliveredNotifications()
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

        notificationCenter?.add(request)
    }

    private func playSound(named name: String) {
        guard let url = getSoundURL(for: name) else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1  // Loop indefinitely
            if !outputDeviceUID.isEmpty {
                audioPlayer?.currentDevice = outputDeviceUID
            }
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
        autoSnoozeTimer?.invalidate()
        autoSnoozeTimer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false
        activeAlarm = nil
        snoozeCount = 0
        notificationCenter?.removeAllDeliveredNotifications()
    }

    func snoozeAlarm() {
        guard let alarm = activeAlarm else { return }

        autoSnoozeTimer?.invalidate()
        autoSnoozeTimer = nil

        if snoozeCount >= Self.maxSnoozes {
            dismissAlarm()
            return
        }

        snoozeCount += 1
        audioPlayer?.stop()
        audioPlayer = nil
        isAlarmFiring = false

        snoozeUntil = Date().addingTimeInterval(TimeInterval(alarm.snoozeDuration * 60))
        activeAlarm = nil
        notificationCenter?.removeAllDeliveredNotifications()
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

    static func availableOutputDevices() -> [AudioOutputDevice] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize
        )
        guard status == noErr else { return [] }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceIDs
        )
        guard status == noErr else { return [] }

        var devices: [AudioOutputDevice] = []

        for deviceID in deviceIDs {
            // Check if device has output channels
            var outputAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )

            var outputSize: UInt32 = 0
            status = AudioObjectGetPropertyDataSize(deviceID, &outputAddress, 0, nil, &outputSize)
            guard status == noErr, outputSize > 0 else { continue }

            let bufferListPtr = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
            defer { bufferListPtr.deallocate() }

            status = AudioObjectGetPropertyData(deviceID, &outputAddress, 0, nil, &outputSize, bufferListPtr)
            guard status == noErr else { continue }

            let bufferList = UnsafeMutableAudioBufferListPointer(bufferListPtr)
            let outputChannels = bufferList.reduce(0) { $0 + Int($1.mNumberChannels) }
            guard outputChannels > 0 else { continue }

            // Get device name
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var nameRef: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            status = AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, &nameRef)
            guard status == noErr else { continue }
            let name = nameRef as String

            // Get device UID
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var uidRef: CFString = "" as CFString
            var uidSize = UInt32(MemoryLayout<CFString>.size)
            status = AudioObjectGetPropertyData(deviceID, &uidAddress, 0, nil, &uidSize, &uidRef)
            guard status == noErr else { continue }
            let uid = uidRef as String

            devices.append(AudioOutputDevice(id: uid, name: name))
        }

        return devices.sorted { $0.name < $1.name }
    }
}
