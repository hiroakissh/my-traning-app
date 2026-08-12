import Foundation
import WatchConnectivity

enum WatchRPE: String, CaseIterable, Identifiable {
    case easy
    case normal
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "軽い"
        case .normal: return "普通"
        case .hard: return "きつい"
        }
    }

    var value: Int {
        switch self {
        case .easy: return 5
        case .normal: return 7
        case .hard: return 9
        }
    }
}

@MainActor
final class WatchSessionCoordinator: NSObject, ObservableObject {
    @Published private(set) var recommendation: WatchRecommendationPayload?
    @Published private(set) var isWorkoutActive = false
    @Published private(set) var sessionID: UUID?
    @Published private(set) var startedAt: Date?
    @Published private(set) var currentExerciseIndex = 0
    @Published private(set) var currentSetIndex = 0
    @Published private(set) var restEndDate: Date?
    @Published private(set) var canSetRPE = false
    @Published var lastErrorMessage: String?

    private let session: WCSession?
    private let defaults: UserDefaults
    private let pendingEventsKey = "watch.outgoingWorkoutEvents"
    private var rpeTarget: (exerciseID: UUID, setIndex: Int)?

    init(
        session: WCSession? = WCSession.isSupported() ? WCSession.default : nil,
        defaults: UserDefaults = .standard
    ) {
        self.session = session
        self.defaults = defaults
        super.init()
        session?.delegate = self
        loadRecommendation(from: session?.receivedApplicationContext)
        session?.activate()
    }

    var currentExercise: WatchExercisePayload? {
        guard let recommendation,
              recommendation.exercises.indices.contains(currentExerciseIndex) else {
            return nil
        }
        return recommendation.exercises[currentExerciseIndex]
    }

    var currentSetCount: Int {
        max(currentExercise?.targetSets ?? 1, 1)
    }

    var hasCompletedAllSets: Bool {
        guard let recommendation else { return false }
        guard recommendation.exercises.isEmpty == false else { return false }
        let lastExerciseIndex = recommendation.exercises.count - 1
        return currentExerciseIndex == lastExerciseIndex && currentSetIndex >= currentSetCount - 1
    }

    func startWorkout() {
        guard let recommendation, recommendation.isRestDay == false else { return }

        let newSessionID = UUID()
        sessionID = newSessionID
        startedAt = Date()
        currentExerciseIndex = 0
        currentSetIndex = 0
        restEndDate = nil
        rpeTarget = nil
        canSetRPE = false
        isWorkoutActive = true

        enqueue(
            WatchWorkoutEvent(
                kind: .startWorkout,
                recommendationID: recommendation.recommendationID,
                sessionID: newSessionID,
                sentAt: startedAt ?? Date()
            )
        )
        flushPendingEventsIfPossible()
    }

    func completeCurrentSet() {
        guard isWorkoutActive,
              let recommendation,
              let exercise = currentExercise,
              let sessionID else {
            return
        }

        enqueue(
            WatchWorkoutEvent(
                kind: .completeSet,
                recommendationID: recommendation.recommendationID,
                sessionID: sessionID,
                exerciseID: exercise.id,
                setIndex: currentSetIndex
            )
        )
        rpeTarget = (exercise.id, currentSetIndex)
        canSetRPE = true
        advanceCurrentSet()
        flushPendingEventsIfPossible()
    }

    func setRPE(_ rpe: WatchRPE) {
        guard isWorkoutActive,
              let recommendation,
              let sessionID else {
            return
        }

        let target = rpeTarget ?? currentExercise.map { ($0.id, currentSetIndex) }
        guard let target else { return }

        enqueue(
            WatchWorkoutEvent(
                kind: .setRPE,
                recommendationID: recommendation.recommendationID,
                sessionID: sessionID,
                exerciseID: target.0,
                setIndex: target.1,
                rpe: rpe.value
            )
        )
        rpeTarget = nil
        canSetRPE = false
        flushPendingEventsIfPossible()
    }

    func startRest() {
        guard isWorkoutActive, let recommendation, let sessionID else { return }
        restEndDate = Date().addingTimeInterval(60)
        enqueue(
            WatchWorkoutEvent(
                kind: .startRest,
                recommendationID: recommendation.recommendationID,
                sessionID: sessionID
            )
        )
        flushPendingEventsIfPossible()
    }

    func clearRest() {
        restEndDate = nil
    }

    func endWorkout() {
        guard isWorkoutActive, let recommendation, let sessionID else { return }
        let elapsedSeconds = startedAt.map { max(Int(Date().timeIntervalSince($0)), 0) }
        enqueue(
            WatchWorkoutEvent(
                kind: .endWorkout,
                recommendationID: recommendation.recommendationID,
                sessionID: sessionID,
                elapsedSeconds: elapsedSeconds
            )
        )
        isWorkoutActive = false
        restEndDate = nil
        rpeTarget = nil
        canSetRPE = false
        flushPendingEventsIfPossible()
    }

    func recordRest() {
        guard let recommendation, recommendation.isRestDay else { return }
        enqueue(
            WatchWorkoutEvent(
                kind: .recordRest,
                recommendationID: recommendation.recommendationID
            )
        )
        flushPendingEventsIfPossible()
    }

    private func advanceCurrentSet() {
        if currentSetIndex + 1 < currentSetCount {
            currentSetIndex += 1
            return
        }

        guard let recommendation,
              currentExerciseIndex + 1 < recommendation.exercises.count else {
            return
        }

        currentExerciseIndex += 1
        currentSetIndex = 0
    }

    private func loadRecommendation(from context: [String: Any]?) {
        guard let context,
              context["kind"] as? String == WatchMessageKind.recommendation.rawValue,
              let data = context["payload"] as? Data else {
            return
        }

        do {
            recommendation = try WatchSyncCodec.decode(WatchRecommendationPayload.self, from: data)
        } catch {
            lastErrorMessage = "iPhoneからの今日の提案を読み取れませんでした。"
        }
    }

    private func enqueue(_ event: WatchWorkoutEvent) {
        var events = readPendingEvents()
        guard events.contains(where: { $0.id == event.id }) == false else { return }
        events.append(event)
        writePendingEvents(events)
    }

    private func readPendingEvents() -> [WatchWorkoutEvent] {
        guard let data = defaults.data(forKey: pendingEventsKey) else { return [] }
        return (try? WatchSyncCodec.decode([WatchWorkoutEvent].self, from: data)) ?? []
    }

    private func writePendingEvents(_ events: [WatchWorkoutEvent]) {
        guard let data = try? WatchSyncCodec.encode(events) else { return }
        defaults.set(data, forKey: pendingEventsKey)
    }

    private func flushPendingEventsIfPossible() {
        guard let session, session.activationState == .activated else { return }
        let events = readPendingEvents()
        guard events.isEmpty == false else { return }

        for event in events {
            guard let data = try? WatchSyncCodec.encode(event) else { continue }
            session.transferUserInfo([
                "kind": WatchMessageKind.workoutEvent.rawValue,
                "payload": data
            ])
        }
        writePendingEvents([])
    }
}

extension WatchSessionCoordinator: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            if let error {
                self?.lastErrorMessage = error.localizedDescription
            }
            self?.flushPendingEventsIfPossible()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor [weak self] in
            self?.loadRecommendation(from: applicationContext)
        }
    }
}
