import Foundation
import SwiftData

enum PreviewData {
    static var previewContainer: ModelContainer = {
        let schema = Schema([
            TrainingLog.self,
            TrainingExercise.self,
            TrainingSet.self,
            TrainingCondition.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        let context = ModelContext(container)
        seedHistoryData(in: context)
        return container
    }()

    private static func seedHistoryData(in context: ModelContext) {
        let descriptor = FetchDescriptor<TrainingLog>()
        if let existing = try? context.fetch(descriptor), !existing.isEmpty {
            return
        }

        let today = Date()
        let calendar = Calendar(identifier: .gregorian)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let chestLog = TrainingLog(
            date: yesterday,
            sessionDurationSec: 3600,
            purpose: .hypertrophy,
            source: .manual,
            note: "フォームを安定させることを意識"
        )
        let bench = TrainingExercise(
            name: "ベンチプレス",
            bodyPart: .chest,
            category: .strength,
            sets: [
                TrainingSet(order: 1, weightKg: 60, reps: 10),
                TrainingSet(order: 2, weightKg: 65, reps: 8),
                TrainingSet(order: 3, weightKg: 65, reps: 6)
            ]
        )
        let fly = TrainingExercise(
            name: "ダンベルフライ",
            bodyPart: .chest,
            category: .strength,
            sets: [
                TrainingSet(order: 1, weightKg: 18, reps: 12),
                TrainingSet(order: 2, weightKg: 18, reps: 10)
            ]
        )
        chestLog.exercises = [bench, fly]

        let cardioLog = TrainingLog(
            date: today,
            sessionDurationSec: 2400,
            purpose: .refresh,
            source: .manual,
            note: "軽めの有酸素でコンディション回復"
        )
        let run = TrainingExercise(
            name: "トレッドミル",
            bodyPart: .legs,
            category: .cardio,
            sets: [
                TrainingSet(order: 1, durationSec: 900, rpe: 6.0),
                TrainingSet(order: 2, durationSec: 900, rpe: 6.5)
            ]
        )
        cardioLog.exercises = [run]

        context.insert(chestLog)
        context.insert(cardioLog)
        try? context.save()
    }
}
