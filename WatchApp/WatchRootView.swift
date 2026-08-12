import SwiftUI

struct WatchRootView: View {
    @StateObject private var coordinator = WatchSessionCoordinator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let recommendation = coordinator.recommendation {
                        recommendationContent(recommendation)
                    } else {
                        emptyState
                    }

                    if let lastErrorMessage = coordinator.lastErrorMessage {
                        Text(lastErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
            }
            .navigationTitle("今日の運動")
        }
    }

    @ViewBuilder
    private func recommendationContent(_ recommendation: WatchRecommendationPayload) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recommendation.title)
                .font(.headline)
            Text(recommendation.summary)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if coordinator.isWorkoutActive {
                workoutContent
            } else if recommendation.isRestDay {
                Text("今日は休養を計画に含める日です。")
                    .font(.footnote)
                Button("休養を記録") {
                    coordinator.recordRest()
                }
                .buttonStyle(.borderedProminent)
            } else {
                exerciseSummary(recommendation)
                Button("ワークアウト開始") {
                    coordinator.startWorkout()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func exerciseSummary(_ recommendation: WatchRecommendationPayload) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(recommendation.exercises) { exercise in
                HStack(alignment: .firstTextBaseline) {
                    Text(exercise.name)
                        .font(.subheadline)
                    Spacer()
                    if let sets = exercise.targetSets, let reps = exercise.targetReps {
                        Text("\(sets)x\(reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let duration = exercise.durationSeconds {
                        Text("\(duration / 60)分")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var workoutContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let exercise = coordinator.currentExercise {
                Text(exercise.name)
                    .font(.title3.weight(.semibold))
                Text("セット \(coordinator.currentSetIndex + 1) / \(coordinator.currentSetCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let weight = exercise.weightDescription {
                    Text(weight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("セット完了") {
                    coordinator.completeCurrentSet()
                }
                .buttonStyle(.borderedProminent)

                Text("直前セットの体感")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    ForEach(WatchRPE.allCases) { rpe in
                        Button("\(rpe.title)\nRPE \(rpe.value)") {
                            coordinator.setRPE(rpe)
                        }
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .disabled(coordinator.canSetRPE == false)
                    }
                }

                if let restEndDate = coordinator.restEndDate {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(Int(restEndDate.timeIntervalSince(context.date).rounded(.up)), 0)
                        Button(remaining > 0 ? "休憩 \(remaining)秒" : "休憩終了") {
                            coordinator.clearRest()
                        }
                        .font(.caption)
                    }
                } else {
                    Button("60秒休憩") {
                        coordinator.startRest()
                    }
                    .font(.caption)
                }
            }

            Button("ワークアウト終了", role: .destructive) {
                coordinator.endWorkout()
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.title2)
            Text("iPhoneで今日の提案を作成すると、ここに表示されます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WatchRootView()
}
