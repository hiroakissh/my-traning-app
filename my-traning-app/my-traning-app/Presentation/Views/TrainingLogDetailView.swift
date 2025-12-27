import SwiftUI

struct TrainingLogDetailView: View {
    let log: TrainingLog
    let item: TrainingHistoryItem

    var body: some View {
        List {
            Section("概要") {
                LabeledContent("日付", value: item.dateLabel)
                LabeledContent("目的", value: log.purpose.displayName)
                LabeledContent("所要時間", value: durationText(from: log.sessionDurationSec))
                if let note = log.note, !note.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("メモ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(note)
                    }
                }
            }

            Section("種目") {
                if log.exercises.isEmpty {
                    Text("種目が登録されていません。")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(log.exercises, id: \.id) { exercise in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("\(exercise.bodyPart.displayName) ・ \(exercise.category.displayName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if exercise.sets.isEmpty {
                                Text("セット記録なし")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(exercise.sets.sorted(by: { $0.order < $1.order }), id: \.id) { set in
                                    Text(setDescription(for: set, category: exercise.category))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(item.title)
    }

    private func durationText(from seconds: Int) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)時間\(minutes % 60)分"
        } else {
            return "\(minutes)分"
        }
    }

    private func setDescription(for set: TrainingSet, category: ExerciseCategory) -> String {
        switch category {
        case .cardio, .mobility, .other:
            let duration = set.durationSec ?? 0
            let minutes = duration / 60
            let seconds = duration % 60
            let durationText = duration > 0 ? "\(minutes)分\(seconds)秒" : "時間未設定"
            let effort = set.rpe.map { "RPE \($0)" } ?? ""
            return [durationText, effort].filter { !$0.isEmpty }.joined(separator: " / ")
        case .strength:
            let weightText: String
            if set.isBodyweight {
                weightText = "自重"
            } else if let weight = set.weightKg {
                weightText = "\(weight)kg"
            } else {
                weightText = "重量未設定"
            }
            let repsText = set.reps.map { "\($0)回" } ?? "回数未設定"
            return [weightText, repsText].joined(separator: " / ")
        }
    }
}
