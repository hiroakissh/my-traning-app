import Foundation
import SwiftData
import WatchConnectivity

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    @Published private(set) var isWatchReachable = false
    @Published private(set) var eventRevision = 0
    @Published var lastErrorMessage: String?

    private let session: WCSession?
    private let defaults: UserDefaults
    private let pendingEventsKey = "watch.pendingWorkoutEvents"
    private let lifecycle = WorkoutSessionLifecycleService()
    private var pendingRecommendation: WatchRecommendationPayload?

    init(
        session: WCSession? = WCSession.isSupported() ? WCSession.default : nil,
        defaults: UserDefaults = .standard
    ) {
        self.session = session
        self.defaults = defaults
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func sendRecommendation(_ recommendation: DailyRecommendation) {
        pendingRecommendation = WatchRecommendationPayload(
            recommendationID: recommendation.id,
            date: recommendation.date,
            title: recommendation.title,
            summary: recommendation.summary,
            recommendationType: recommendation.recommendationType.rawValue,
            exercises: recommendation.plannedExercises
                .sorted { $0.order < $1.order }
                .map {
                    WatchExercisePayload(
                        id: $0.id,
                        name: $0.name,
                        targetSets: $0.targetSets,
                        targetReps: $0.targetReps,
                        weightDescription: $0.weightDescription,
                        durationSeconds: $0.targetSets == nil && $0.estimatedMinutes > 0
                            ? $0.estimatedMinutes * 60
                            : nil
                    )
                }
        )
        flushPendingRecommendationIfPossible()
    }

    func processPendingEvents(using context: ModelContext) {
        let events = readPendingEvents()
        guard events.isEmpty == false else { return }

        var remaining = events
        for event in events {
            do {
                try apply(event, using: context)
                remaining.removeFirst()
                try context.save()
            } catch {
                lastErrorMessage = error.localizedDescription
                break
            }
        }

        writePendingEvents(remaining)
        eventRevision += 1
    }

    private func flushPendingRecommendationIfPossible() {
        guard let session, session.activationState == .activated, let pendingRecommendation else {
            return
        }

        do {
            let data = try WatchSyncCodec.encode(pendingRecommendation)
            try session.updateApplicationContext([
                "kind": WatchMessageKind.recommendation.rawValue,
                "payload": data
            ])
        } catch {
            lastErrorMessage = "Apple Watchへ今日の提案を送れませんでした。"
        }
    }

    private func receiveEventData(_ data: Data) {
        do {
            let event = try WatchSyncCodec.decode(WatchWorkoutEvent.self, from: data)
            enqueue(event)
        } catch {
            lastErrorMessage = "Apple Watchからの記録を読み取れませんでした。"
        }
    }

    private func enqueue(_ event: WatchWorkoutEvent) {
        var events = readPendingEvents()
        guard events.contains(where: { $0.id == event.id }) == false else { return }
        events.append(event)
        writePendingEvents(events)
        eventRevision += 1
    }

    private func readPendingEvents() -> [WatchWorkoutEvent] {
        guard let data = defaults.data(forKey: pendingEventsKey) else { return [] }
        return (try? WatchSyncCodec.decode([WatchWorkoutEvent].self, from: data)) ?? []
    }

    private func writePendingEvents(_ events: [WatchWorkoutEvent]) {
        guard let data = try? WatchSyncCodec.encode(events) else { return }
        defaults.set(data, forKey: pendingEventsKey)
    }

    private func apply(_ event: WatchWorkoutEvent, using context: ModelContext) throws {
        switch event.kind {
        case .startWorkout:
            try startSession(for: event, using: context)
        case .completeSet:
            try updateSet(for: event, using: context) { actualSet in
                actualSet.status = .completed
                actualSet.completedAt = event.sentAt
            }
        case .setRPE:
            try updateSet(for: event, using: context) { actualSet in
                actualSet.rpe = event.rpe
            }
        case .startRest:
            break
        case .endWorkout:
            try finishSession(for: event, using: context)
        case .recordRest:
            try recordRest(for: event, using: context)
        }
    }

    private func startSession(for event: WatchWorkoutEvent, using context: ModelContext) throws {
        guard let recommendationID = event.recommendationID,
              let sessionID = event.sessionID else {
            throw WatchEventProcessingError.missingSessionReference
        }

        let existing = try fetchSession(sessionID, using: context)
        guard existing == nil else { return }

        guard let recommendation = try fetchRecommendation(recommendationID, using: context) else {
            throw WatchEventProcessingError.recommendationNotFound
        }

        let session = lifecycle.makeSession(
            from: recommendation,
            startedAt: event.sentAt
        )
        session.id = sessionID
        session.status = .inProgress
        context.insert(session)
    }

    private func updateSet(
        for event: WatchWorkoutEvent,
        using context: ModelContext,
        update: (ActualSet) -> Void
    ) throws {
        guard let sessionID = event.sessionID,
              let exerciseID = event.exerciseID,
              let setIndex = event.setIndex,
              let session = try fetchSession(sessionID, using: context),
              let exercise = session.exercises.first(where: { $0.plannedExerciseId == exerciseID || $0.id == exerciseID }),
              let actualSet = exercise.actualSets.sorted(by: { $0.order < $1.order }).dropFirst(setIndex).first else {
            throw WatchEventProcessingError.sessionNotFound
        }

        update(actualSet)
        exercise.status = exercise.actualSets.allSatisfy { $0.status.isExecuted }
            ? .completed
            : (exercise.actualSets.contains { $0.status.isExecuted } ? .inProgress : .notStarted)
    }

    private func finishSession(for event: WatchWorkoutEvent, using context: ModelContext) throws {
        guard let sessionID = event.sessionID,
              let session = try fetchSession(sessionID, using: context) else {
            throw WatchEventProcessingError.sessionNotFound
        }

        guard session.endedAt == nil else { return }

        for actualSet in session.exercises.flatMap(\.actualSets) where actualSet.status == .planned {
            actualSet.status = .skipped
        }

        let executedSets = session.exercises.flatMap(\.actualSets).filter { $0.status.isExecuted }
        let allSetsExecuted = session.exercises.flatMap(\.actualSets).allSatisfy { $0.status.isExecuted }
        session.status = executedSets.isEmpty
            ? .cancelled
            : (allSetsExecuted ? .completed : .partiallyCompleted)
        session.endedAt = event.sentAt

        let recommendation = try event.recommendationID.flatMap { try fetchRecommendation($0, using: context) }
        let log = lifecycle.makeTrainingLog(
            from: session,
            recommendation: recommendation,
            endedAt: event.sentAt,
            activeDurationSec: event.elapsedSeconds
        )
        context.insert(log)
    }

    private func recordRest(for event: WatchWorkoutEvent, using context: ModelContext) throws {
        guard let recommendationID = event.recommendationID,
              let recommendation = try fetchRecommendation(recommendationID, using: context) else {
            throw WatchEventProcessingError.recommendationNotFound
        }

        let logs = try context.fetch(FetchDescriptor<TrainingLog>())
        guard logs.contains(where: { $0.recommendationId == recommendationID && $0.activityResult == .rested }) == false else {
            return
        }

        context.insert(lifecycle.makeRestedLog(from: recommendation, date: event.sentAt))
    }

    private func fetchRecommendation(_ id: UUID, using context: ModelContext) throws -> DailyRecommendation? {
        let descriptor = FetchDescriptor<DailyRecommendation>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    private func fetchSession(_ id: UUID, using context: ModelContext) throws -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.isWatchReachable = session.isReachable
            if let error {
                self?.lastErrorMessage = error.localizedDescription
            }
            self?.flushPendingRecommendationIfPossible()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receiveMessage(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receiveMessage(userInfo)
    }

    private nonisolated func receiveMessage(_ message: [String: Any]) {
        guard message["kind"] as? String == WatchMessageKind.workoutEvent.rawValue,
              let data = message["payload"] as? Data else {
            return
        }

        Task { @MainActor [weak self] in
            self?.receiveEventData(data)
        }
    }
}

private enum WatchEventProcessingError: LocalizedError {
    case missingSessionReference
    case recommendationNotFound
    case sessionNotFound

    var errorDescription: String? {
        switch self {
        case .missingSessionReference:
            return "Apple Watchのセッション情報が不足しています。"
        case .recommendationNotFound:
            return "Apple Watchの提案に対応するiPhone側のデータが見つかりません。"
        case .sessionNotFound:
            return "Apple Watchのセット記録に対応するセッションが見つかりません。"
        }
    }
}
