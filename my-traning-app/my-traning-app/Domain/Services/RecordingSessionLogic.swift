import Foundation

struct RecordingValidationResult: Equatable {
    let isValid: Bool
    let message: String?
}

private struct RecordingSessionValidationRule {
    let minimumMenuCount: Int
    let minimumDuration: Int
}

struct RecordingSessionValidator {
    private let rules: [TrainingPurpose: RecordingSessionValidationRule]
    private let defaultRule = RecordingSessionValidationRule(minimumMenuCount: 1, minimumDuration: 0)

    init(rules: [TrainingPurpose: RecordingSessionValidationRule] = [:]) {
        var mergedRules: [TrainingPurpose: RecordingSessionValidationRule] = [
            .hypertrophy: RecordingSessionValidationRule(minimumMenuCount: 2, minimumDuration: 0),
            .tune: RecordingSessionValidationRule(minimumMenuCount: 2, minimumDuration: 0),
            .diet: RecordingSessionValidationRule(minimumMenuCount: 1, minimumDuration: 600),
            .refresh: RecordingSessionValidationRule(minimumMenuCount: 1, minimumDuration: 180),
            .other: RecordingSessionValidationRule(minimumMenuCount: 1, minimumDuration: 0)
        ]

        rules.forEach { mergedRules[$0.key] = $0.value }
        self.rules = mergedRules
    }

    func validateForStart(purpose: TrainingPurpose?, selectedMenuCount: Int) -> RecordingValidationResult {
        guard let purpose else {
            return RecordingValidationResult(isValid: false, message: "目標タイプを選択してください。")
        }

        let rule = rules[purpose] ?? defaultRule

        guard selectedMenuCount >= rule.minimumMenuCount else {
            return RecordingValidationResult(isValid: false, message: startMenuMessage(for: purpose))
        }

        return RecordingValidationResult(isValid: true, message: nil)
    }

    func validateForFinish(
        purpose: TrainingPurpose?,
        selectedMenuCount: Int,
        elapsedSeconds: Int,
        hasStarted: Bool
    ) -> RecordingValidationResult {
        guard let purpose else {
            return RecordingValidationResult(isValid: false, message: "目標タイプを選択してください。")
        }

        let rule = rules[purpose] ?? defaultRule

        guard selectedMenuCount >= rule.minimumMenuCount else {
            return RecordingValidationResult(isValid: false, message: startMenuMessage(for: purpose))
        }

        guard hasStarted else {
            return RecordingValidationResult(isValid: false, message: "計測を開始してください。")
        }

        if elapsedSeconds < rule.minimumDuration {
            if rule.minimumDuration == 0 {
                return RecordingValidationResult(isValid: true, message: nil)
            }
            return RecordingValidationResult(
                isValid: false,
                message: durationMessage(for: purpose, requiredSeconds: rule.minimumDuration)
            )
        }

        return RecordingValidationResult(isValid: true, message: nil)
    }

    private func startMenuMessage(for purpose: TrainingPurpose) -> String {
        switch purpose {
        case .hypertrophy, .tune:
            return "筋肥大/調整では最低2件のメニューを選択してください。"
        default:
            return "最低1件のメニューを選択してください。"
        }
    }

    private func durationMessage(for purpose: TrainingPurpose, requiredSeconds: Int) -> String {
        let minuteDescription: String
        if requiredSeconds % 60 == 0 {
            minuteDescription = "\(requiredSeconds / 60)分"
        } else {
            minuteDescription = RecordingTimeFormatter.string(from: requiredSeconds)
        }

        switch purpose {
        case .diet:
            return "減量では\(minuteDescription)以上（\(requiredSeconds)秒）の計測が必要です。"
        case .refresh:
            return "リフレッシュでは\(minuteDescription)以上（\(requiredSeconds)秒）の計測が必要です。"
        default:
            return "\(minuteDescription)以上の計測を完了してください。"
        }
    }
}

struct RecordingTimerState: Equatable {
    private(set) var startTime: Date?
    private(set) var endTime: Date?
    private(set) var elapsedSeconds: Int = 0
    private(set) var isRunning: Bool = false
    private var lastResumeDate: Date?

    var hasStarted: Bool {
        startTime != nil
    }

    mutating func start(now: Date = Date()) {
        startTime = now
        endTime = nil
        elapsedSeconds = 0
        isRunning = true
        lastResumeDate = now
    }

    mutating func tick(now: Date = Date()) {
        guard isRunning, let lastResumeDate else {
            return
        }

        let delta = Int(now.timeIntervalSince(lastResumeDate))
        guard delta > 0 else {
            return
        }

        elapsedSeconds += delta
        self.lastResumeDate = now
    }

    mutating func pause(now: Date = Date()) {
        tick(now: now)
        isRunning = false
        lastResumeDate = nil
    }

    mutating func resume(now: Date = Date()) {
        if startTime == nil {
            start(now: now)
            return
        }

        isRunning = true
        lastResumeDate = now
        endTime = nil
    }

    mutating func stop(now: Date = Date()) {
        tick(now: now)
        isRunning = false
        lastResumeDate = nil
        endTime = now
    }

    mutating func reset() {
        startTime = nil
        endTime = nil
        elapsedSeconds = 0
        isRunning = false
        lastResumeDate = nil
    }
}

enum RecordingTimeFormatter {
    static func string(from seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
}

struct RecordingSessionLogBuilder {
    func makeLog(
        purpose: TrainingPurpose,
        selectedMenus: [WorkoutMenuItem],
        timerState: RecordingTimerState,
        date: Date = Date(),
        source: LogSource = .timer
    ) -> TrainingLog {
        let startTime = timerState.startTime ?? date
        let endTime = timerState.endTime ?? startTime.addingTimeInterval(TimeInterval(timerState.elapsedSeconds))
        let logDate = Calendar.current.startOfDay(for: startTime)

        let exercises = selectedMenus.map {
            TrainingExercise(name: $0.name, bodyPart: .other, category: .strength, sets: [])
        }

        return TrainingLog(
            date: logDate,
            startTime: startTime,
            endTime: endTime,
            sessionDurationSec: timerState.elapsedSeconds,
            purpose: purpose,
            source: source,
            exercises: exercises
        )
    }
}
