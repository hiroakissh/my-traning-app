import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let recommendation: DailyRecommendation?
    private let lifecycle = WorkoutSessionLifecycleService()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var session: WorkoutSession
    @State private var timerState = RecordingTimerState()
    @State private var isSessionInserted = false
    @State private var isSaving = false
    @State private var statusMessage: String?

    init(recommendation: DailyRecommendation) {
        self.recommendation = recommendation
        _session = State(initialValue: WorkoutSessionLifecycleService().makeSession(from: recommendation))
    }

    init(session: WorkoutSession, recommendation: DailyRecommendation? = nil) {
        self.recommendation = recommendation
        _session = State(initialValue: session)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                header
                timerSection
                plannedMenuSection
                noteSection
                finishButton
                if let statusMessage {
                    statusBanner(statusMessage)
                }
            }
            .padding(.horizontal, AppLayout.grid * 2)
            .padding(.vertical, AppLayout.grid * 2.5)
        }
        .hudScrollBackground()
        .navigationTitle("")
        .applyIOSNavigationBarHidden(true)
        .onReceive(timer) { now in
            timerState.tick(now: now)
        }
    }

    private var header: some View {
        HudSectionCard(title: nil, subtitle: nil, spacing: AppLayout.grid * 1.3) {
            HStack(spacing: AppLayout.grid) {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(AppColors.primary)
                Text(session.status.displayName)
                    .font(AppTypography.label(13, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if let recommendation {
                    Text(recommendation.recommendationType.displayName)
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Text("今日のメニュー：\(recommendation?.title ?? "予定メニュー")")
                .font(AppTypography.title(24))
                .foregroundColor(AppColors.textPrimary)

            Text(recommendation?.summary ?? "予定セットを確認しながら進めます。")
                .font(AppTypography.body(14))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var timerSection: some View {
        HudSectionCard(title: "セッション", subtitle: "実施時間と現在の進行状況", spacing: AppLayout.grid * 1.4) {
            HStack(alignment: .center, spacing: AppLayout.grid * 1.5) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
                    Text(RecordingTimeFormatter.string(from: timerState.elapsedSeconds))
                        .font(AppTypography.hudNumber(34, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(progressSummary)
                        .font(AppTypography.label())
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Button(action: toggleTimer) {
                    Image(systemName: timerState.isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(timerState.isRunning ? AppColors.secondary : AppColors.primary)
            }
        }
    }

    private var plannedMenuSection: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 1.2) {
            Text("予定メニュー")
                .font(AppTypography.body(18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            if sortedExercises.isEmpty {
                Text("今日は予定セットなしの休養日です。必要なら休養として記録してください。")
                    .font(AppTypography.body(14))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(AppLayout.grid * 1.4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surface2.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
            } else {
                VStack(spacing: AppLayout.grid * 1.2) {
                    ForEach(sortedExercises) { exercise in
                        WorkoutSessionExerciseBlock(
                            exercise: exercise,
                            plannedText: plannedText(for: exercise),
                            onCompleteSet: { completeSet($0, in: exercise) },
                            onSkipSet: { skipSet($0, in: exercise) },
                            onAdjustWeight: { set, delta in adjustWeight(for: set, by: delta, in: exercise) },
                            onAdjustReps: { set, delta in adjustReps(for: set, by: delta, in: exercise) },
                            onSetRPE: { set, rpe in setRPE(rpe, for: set, in: exercise) },
                            onSkipExercise: { skipExercise(exercise) }
                        )
                    }
                }
            }
        }
    }

    private var noteSection: some View {
        HudSectionCard(title: "メモ", subtitle: "短い気づきだけ残せます", spacing: AppLayout.grid) {
            TextField(
                "例：肩に違和感、余裕あり",
                text: Binding(
                    get: { session.userNote ?? "" },
                    set: { session.userNote = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                ),
                axis: .vertical
            )
            .lineLimit(1...3)
            .hudFieldStyle()
        }
    }

    private var finishButton: some View {
        Button(action: finishSession) {
            if isSaving {
                ProgressView()
                    .tint(AppColors.background)
                    .frame(maxWidth: .infinity)
            } else {
                Label("セッション終了", systemImage: "checkmark.seal.fill")
                    .font(AppTypography.body(17, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, AppLayout.grid * 1.2)
        .buttonStyle(.borderedProminent)
        .tint(AppColors.primary)
        .disabled(isSaving || (!timerState.hasStarted && !hasAnySetDecision))
    }

    private var sortedExercises: [WorkoutSessionExercise] {
        session.exercises.sorted { $0.order < $1.order }
    }

    private var allActualSets: [ActualSet] {
        session.exercises.flatMap(\.actualSets)
    }

    private var hasAnySetDecision: Bool {
        allActualSets.contains { $0.status != .planned }
    }

    private var progressSummary: String {
        let completed = allActualSets.filter { $0.status == .completed || $0.status == .modified }.count
        let skipped = allActualSets.filter { $0.status == .skipped }.count
        return "完了 \(completed) / スキップ \(skipped) / 予定 \(allActualSets.count)"
    }

    private func plannedText(for exercise: WorkoutSessionExercise) -> String {
        guard let firstSet = exercise.plannedSets.sorted(by: { $0.order < $1.order }).first else {
            return "予定なし"
        }

        let setCount = exercise.plannedSets.count
        var parts: [String] = []
        if let weight = firstSet.weight {
            parts.append("\(formatNumber(weight))kg")
        }
        if let reps = firstSet.reps {
            parts.append("\(reps)回")
        }
        if let duration = firstSet.durationSeconds {
            parts.append("\(max(duration / 60, 1))分")
        }
        parts.append("\(setCount)セット")
        return parts.joined(separator: " x ")
    }

    private func toggleTimer() {
        if timerState.isRunning {
            timerState.pause()
        } else {
            startSessionIfNeeded()
            if timerState.hasStarted {
                timerState.resume()
            } else {
                timerState.start()
            }
            session.status = .inProgress
        }
    }

    private func completeSet(_ set: ActualSet, in exercise: WorkoutSessionExercise) {
        startSessionIfNeeded()
        set.completedAt = Date()
        set.status = isModified(set, in: exercise) ? .modified : .completed
        updateExerciseStatus(exercise)
        updateSessionStatus()
    }

    private func skipSet(_ set: ActualSet, in exercise: WorkoutSessionExercise) {
        startSessionIfNeeded()
        set.completedAt = nil
        set.status = .skipped
        updateExerciseStatus(exercise)
        updateSessionStatus()
    }

    private func skipExercise(_ exercise: WorkoutSessionExercise) {
        startSessionIfNeeded()
        for set in exercise.actualSets {
            set.completedAt = nil
            set.status = .skipped
        }
        exercise.status = .skipped
        updateSessionStatus()
    }

    private func adjustWeight(for set: ActualSet, by delta: Double, in exercise: WorkoutSessionExercise) {
        startSessionIfNeeded()
        set.weight = max((set.weight ?? 0) + delta, 0)
        markModified(set)
        updateExerciseStatus(exercise)
        updateSessionStatus()
    }

    private func adjustReps(for set: ActualSet, by delta: Int, in exercise: WorkoutSessionExercise) {
        startSessionIfNeeded()
        set.reps = max((set.reps ?? 0) + delta, 0)
        markModified(set)
        updateExerciseStatus(exercise)
        updateSessionStatus()
    }

    private func setRPE(_ rpe: Int, for set: ActualSet, in exercise: WorkoutSessionExercise) {
        startSessionIfNeeded()
        set.rpe = rpe
        if set.status == .completed {
            set.status = isModified(set, in: exercise) ? .modified : .completed
        }
        updateExerciseStatus(exercise)
        updateSessionStatus()
    }

    private func markModified(_ set: ActualSet) {
        if set.status == .completed || set.status == .modified {
            set.status = .modified
        }
    }

    private func startSessionIfNeeded() {
        if !timerState.hasStarted {
            timerState.start()
            session.startedAt = timerState.startTime ?? Date()
        }
        if session.status == .notStarted {
            session.status = .inProgress
        }
        if !isSessionInserted {
            modelContext.insert(session)
            isSessionInserted = true
        }
    }

    private func finishSession() {
        isSaving = true
        startSessionIfNeeded()

        var finalizedTimer = timerState
        finalizedTimer.stop(now: Date())
        timerState = finalizedTimer

        markRemainingSetsSkipped()
        updateAllExerciseStatuses()
        updateSessionStatus(forFinish: true)
        session.endedAt = finalizedTimer.endTime ?? Date()

        let log = lifecycle.makeTrainingLog(
            from: session,
            recommendation: recommendation,
            endedAt: session.endedAt ?? Date(),
            activeDurationSec: finalizedTimer.elapsedSeconds
        )
        modelContext.insert(log)

        do {
            try modelContext.save()
            statusMessage = "TrainingLogとして保存しました。"
            dismiss()
        } catch {
            statusMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
        isSaving = false
    }

    private func markRemainingSetsSkipped() {
        for set in allActualSets where set.status == .planned {
            set.status = .skipped
        }
    }

    private func updateAllExerciseStatuses() {
        for exercise in session.exercises {
            updateExerciseStatus(exercise)
        }
    }

    private func updateExerciseStatus(_ exercise: WorkoutSessionExercise) {
        let sets = exercise.actualSets
        if sets.allSatisfy({ $0.status == .planned }) {
            exercise.status = .notStarted
        } else if sets.allSatisfy({ $0.status == .skipped }) {
            exercise.status = .skipped
        } else if sets.allSatisfy({ $0.status == .completed || $0.status == .modified }) {
            exercise.status = .completed
        } else {
            exercise.status = .inProgress
        }
    }

    private func updateSessionStatus(forFinish: Bool = false) {
        let exercises = session.exercises
        if exercises.isEmpty {
            session.status = forFinish ? .cancelled : .notStarted
        } else if exercises.allSatisfy({ $0.status == .completed }) {
            session.status = .completed
        } else if exercises.allSatisfy({ $0.status == .skipped || $0.status == .notStarted }) {
            session.status = forFinish ? .cancelled : .inProgress
        } else if exercises.contains(where: { $0.status == .completed || $0.status == .skipped || $0.status == .inProgress }) {
            session.status = forFinish ? .partiallyCompleted : .inProgress
        } else {
            session.status = .inProgress
        }
    }

    private func isModified(_ set: ActualSet, in exercise: WorkoutSessionExercise) -> Bool {
        guard let plannedSet = exercise.plannedSets.first(where: { $0.id == set.plannedSetId }) else {
            return true
        }
        return plannedSet.weight != set.weight
            || plannedSet.reps != set.reps
            || plannedSet.durationSeconds != set.durationSeconds
            || plannedSet.distanceMeters != set.distanceMeters
    }

    private func statusBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: AppLayout.grid) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(AppColors.secondary)
            Text(message)
                .font(AppTypography.label())
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(AppLayout.grid * 1.25)
        .background(AppColors.surface2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
    }
}

private struct WorkoutSessionExerciseBlock: View {
    let exercise: WorkoutSessionExercise
    let plannedText: String
    let onCompleteSet: (ActualSet) -> Void
    let onSkipSet: (ActualSet) -> Void
    let onAdjustWeight: (ActualSet, Double) -> Void
    let onAdjustReps: (ActualSet, Int) -> Void
    let onSetRPE: (ActualSet, Int) -> Void
    let onSkipExercise: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid) {
            HStack(alignment: .top, spacing: AppLayout.grid) {
                Text("\(exercise.order)")
                    .font(AppTypography.label(12, weight: .semibold))
                    .foregroundColor(AppColors.background)
                    .frame(width: 24, height: 24)
                    .background(AppColors.primary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppLayout.grid * 0.4) {
                    Text(exercise.name)
                        .font(AppTypography.body(16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("予定：\(plannedText)")
                        .font(AppTypography.label())
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Menu {
                    Button("種目をスキップ", role: .destructive, action: onSkipExercise)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            VStack(spacing: AppLayout.grid * 0.8) {
                ForEach(exercise.actualSets.sorted { $0.order < $1.order }) { set in
                    WorkoutSessionSetRow(
                        set: set,
                        onComplete: { onCompleteSet(set) },
                        onSkip: { onSkipSet(set) },
                        onAdjustWeight: { onAdjustWeight(set, $0) },
                        onAdjustReps: { onAdjustReps(set, $0) },
                        onSetRPE: { onSetRPE(set, $0) }
                    )
                }
            }
        }
        .padding(AppLayout.grid * 1.4)
        .background(AppColors.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }
}

private struct WorkoutSessionSetRow: View {
    let set: ActualSet
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onAdjustWeight: (Double) -> Void
    let onAdjustReps: (Int) -> Void
    let onSetRPE: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.8) {
            HStack(spacing: AppLayout.grid) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 0.3) {
                    Text("Set \(set.order)")
                        .font(AppTypography.label(12, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                    Text(actualText)
                        .font(AppTypography.body(14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                SetStatusPill(status: set.status)
            }

            HStack(spacing: AppLayout.grid * 0.8) {
                Button(action: onComplete) {
                    Label("完了", systemImage: "checkmark.circle.fill")
                        .font(AppTypography.label(12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)

                Menu {
                    Button("+2.5kg") { onAdjustWeight(2.5) }
                    Button("-2.5kg") { onAdjustWeight(-2.5) }
                    Button("+1回") { onAdjustReps(1) }
                    Button("-1回") { onAdjustReps(-1) }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.textSecondary)

                Menu {
                    ForEach(SimpleRPE.allCases) { simpleRPE in
                        Button("\(simpleRPE.displayName) (RPE \(simpleRPE.rpeValue))") {
                            onSetRPE(simpleRPE.rpeValue)
                        }
                    }
                    Divider()
                    ForEach(1...10, id: \.self) { value in
                        Button("RPE \(value)") {
                            onSetRPE(value)
                        }
                    }
                } label: {
                    HStack(spacing: AppLayout.grid * 0.4) {
                        Image(systemName: "gauge")
                        Text(set.rpe.map { "RPE \($0)" } ?? "RPE")
                    }
                    .font(AppTypography.label(12, weight: .semibold))
                    .frame(minWidth: 68, minHeight: 36)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.secondary)

                Button(action: onSkip) {
                    Image(systemName: "forward.end.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.bordered)
                .tint(AppColors.textSecondary)
            }
        }
        .padding(AppLayout.grid)
        .background(AppColors.surface2.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.grid, style: .continuous))
    }

    private var actualText: String {
        var parts: [String] = []
        if let weight = set.weight {
            parts.append("\(formatNumber(weight))kg")
        }
        if let reps = set.reps {
            parts.append("\(reps)回")
        }
        if let duration = set.durationSeconds {
            parts.append("\(max(duration / 60, 1))分")
        }
        return parts.isEmpty ? "実績入力なし" : parts.joined(separator: " x ")
    }
}

private struct SetStatusPill: View {
    let status: SetStatus

    var body: some View {
        Text(status.displayName)
            .font(AppTypography.label(11, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, AppLayout.grid)
            .padding(.vertical, AppLayout.grid * 0.45)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch status {
        case .planned:
            return AppColors.surface
        case .completed, .modified:
            return AppColors.primary
        case .skipped:
            return AppColors.surface2
        }
    }

    private var foreground: Color {
        switch status {
        case .completed, .modified:
            return AppColors.background
        case .planned, .skipped:
            return AppColors.textSecondary
        }
    }
}

private func formatNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return String(Int(value))
    }
    return String(format: "%.1f", value)
}

#Preview {
    let recommendation = DailyRecommendation(
        readinessLevel: .easy,
        recommendationType: .lightWorkout,
        title: "上半身ライト",
        summary: "今日は軽めに進めます。",
        reasons: ["睡眠が短めです。", "疲労を残さない強度にします。"],
        plannedExercises: [
            PlannedExercise(order: 1, name: "ベンチプレス", detail: "フォーム確認", targetSets: 3, targetReps: 8, weightDescription: "60kg", estimatedMinutes: 12, category: .strength),
            PlannedExercise(order: 2, name: "ダンベルロー", detail: "丁寧に引く", targetSets: 3, targetReps: 10, weightDescription: "12kg", estimatedMinutes: 10, category: .strength)
        ],
        alternatives: [
            AlternativePlan(title: "10分版", description: "1種目だけ実行", estimatedMinutes: 10, intensity: 2),
            AlternativePlan(title: "休養", description: "今日は休む", estimatedMinutes: 0, intensity: 1)
        ],
        recoveryAdvice: ["余力を残して終えます。"]
    )

    NavigationStack {
        WorkoutSessionView(recommendation: recommendation)
    }
    .modelContainer(
        for: [
            WorkoutSession.self,
            WorkoutSessionExercise.self,
            PlannedSet.self,
            ActualSet.self,
            TrainingLog.self,
            TrainingExercise.self,
            TrainingSet.self,
            TrainingCondition.self
        ] as [any PersistentModel.Type],
        inMemory: true
    )
}

private extension View {
    @ViewBuilder
    func applyIOSNavigationBarHidden(_ hidden: Bool) -> some View {
        #if os(iOS)
        self.navigationBarHidden(hidden)
        #else
        self
        #endif
    }
}
