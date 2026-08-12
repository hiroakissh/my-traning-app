import Foundation

enum WatchMessageKind: String, Codable {
    case recommendation
    case workoutEvent
}

enum WatchWorkoutEventKind: String, Codable {
    case startWorkout
    case completeSet
    case setRPE
    case startRest
    case endWorkout
    case recordRest
}

struct WatchExercisePayload: Codable, Equatable, Identifiable {
    let id: UUID
    let name: String
    let targetSets: Int?
    let targetReps: Int?
    let weightDescription: String?
    let durationSeconds: Int?
}

struct WatchRecommendationPayload: Codable, Equatable {
    let recommendationID: UUID
    let date: Date
    let title: String
    let summary: String
    let recommendationType: String
    let exercises: [WatchExercisePayload]

    var isRestDay: Bool {
        recommendationType == "rest"
    }
}

struct WatchWorkoutEvent: Codable, Equatable, Identifiable {
    let id: UUID
    let kind: WatchWorkoutEventKind
    let recommendationID: UUID?
    let sessionID: UUID?
    let exerciseID: UUID?
    let setIndex: Int?
    let rpe: Int?
    let elapsedSeconds: Int?
    let sentAt: Date

    init(
        id: UUID = UUID(),
        kind: WatchWorkoutEventKind,
        recommendationID: UUID? = nil,
        sessionID: UUID? = nil,
        exerciseID: UUID? = nil,
        setIndex: Int? = nil,
        rpe: Int? = nil,
        elapsedSeconds: Int? = nil,
        sentAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.recommendationID = recommendationID
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.setIndex = setIndex
        self.rpe = rpe
        self.elapsedSeconds = elapsedSeconds
        self.sentAt = sentAt
    }
}

enum WatchSyncCodec {
    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
}
