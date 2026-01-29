import Foundation

@Observable
final class CountdownTimer {
    private(set) var remainingSeconds: Int = 0
    private(set) var isRunning = false
    private(set) var isComplete = false
    private var timer: Timer?

    var displayTime: String {
        let hours = remainingSeconds / 3600
        let minutes = (remainingSeconds % 3600) / 60
        let seconds = remainingSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start(minutes: Int) {
        remainingSeconds = minutes * 60
        isRunning = true
        isComplete = false

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func start(seconds: Int) {
        remainingSeconds = seconds
        isRunning = true
        isComplete = false

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            complete()
        }
    }

    private func complete() {
        isRunning = false
        isComplete = true
        timer?.invalidate()
        timer = nil
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resume() {
        guard !isRunning && remainingSeconds > 0 else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func reset() {
        pause()
        remainingSeconds = 0
        isComplete = false
    }
}

@Observable
final class Stopwatch {
    private(set) var elapsedMilliseconds: Int = 0
    private(set) var isRunning = false
    private(set) var laps: [Int] = []  // lap times in milliseconds
    private var timer: Timer?
    private var startTime: Date?
    private var accumulatedTime: Int = 0

    var displayTime: String {
        let totalSeconds = elapsedMilliseconds / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let centiseconds = (elapsedMilliseconds % 1000) / 10

        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
        }
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    private func update() {
        guard let startTime = startTime else { return }
        let elapsed = Int(Date().timeIntervalSince(startTime) * 1000)
        elapsedMilliseconds = accumulatedTime + elapsed
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        accumulatedTime = elapsedMilliseconds
        timer?.invalidate()
        timer = nil
        startTime = nil
    }

    func lap() {
        guard isRunning else { return }
        let lapTime = laps.isEmpty ? elapsedMilliseconds : elapsedMilliseconds - laps.reduce(0, +)
        laps.append(lapTime)
    }

    func reset() {
        stop()
        elapsedMilliseconds = 0
        accumulatedTime = 0
        laps = []
    }

    func formatLapTime(_ milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centiseconds = (milliseconds % 1000) / 10
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}
