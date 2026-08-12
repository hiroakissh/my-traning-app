import XCTest
@testable import my_traning_app

final class WatchSyncPayloadTests: XCTestCase {
    func testRecommendationPayloadRoundTripsThroughSharedCodec() throws {
        let recommendationID = UUID()
        let payload = WatchRecommendationPayload(
            recommendationID: recommendationID,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            title: "上半身ライト",
            summary: "フォームを優先して軽めに動きます。",
            recommendationType: "lightWorkout",
            exercises: [
                WatchExercisePayload(
                    id: UUID(),
                    name: "ベンチプレス",
                    targetSets: 3,
                    targetReps: 8,
                    weightDescription: "軽め",
                    durationSeconds: nil
                )
            ]
        )

        let encoded = try WatchSyncCodec.encode(payload)
        let decoded = try WatchSyncCodec.decode(WatchRecommendationPayload.self, from: encoded)

        XCTAssertEqual(decoded, payload)
        XCTAssertEqual(decoded.recommendationID, recommendationID)
    }

    func testWorkoutEventRoundTripsAndKeepsSimpleRPE() throws {
        let event = WatchWorkoutEvent(
            kind: .setRPE,
            recommendationID: UUID(),
            sessionID: UUID(),
            exerciseID: UUID(),
            setIndex: 1,
            rpe: 7,
            elapsedSeconds: 92,
            sentAt: Date(timeIntervalSince1970: 1_700_000_100)
        )

        let encoded = try WatchSyncCodec.encode(event)
        let decoded = try WatchSyncCodec.decode(WatchWorkoutEvent.self, from: encoded)

        XCTAssertEqual(decoded, event)
        XCTAssertEqual(decoded.rpe, 7)
        XCTAssertEqual(decoded.elapsedSeconds, 92)
    }
}
