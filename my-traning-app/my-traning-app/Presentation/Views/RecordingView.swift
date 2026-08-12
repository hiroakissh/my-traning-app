import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    private let workoutGroupsResult: Result<[WorkoutGroup], BundleDecodingError>
    private let validator = RecordingSessionValidator()
    private let logBuilder = RecordingSessionLogBuilder()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var selectedGroupIndex = 0
    @State private var selectedMenuItems = Set<WorkoutMenuItem>()
    @State private var selectedPurpose: TrainingPurpose?
    @State private var timerState = RecordingTimerState()
    @State private var statusMessage: String?
    @State private var statusKind: StatusKind?
    @State private var isSaving = false

    init(bundle: Bundle = .main) {
        let dataResult: Result<WorkoutData, BundleDecodingError>
        do {
            let data: WorkoutData = try bundle.decode("workout_menus.json")
            dataResult = .success(data)
        } catch let decodingError as BundleDecodingError {
            dataResult = .failure(decodingError)
        } catch {
            dataResult = .failure(.dataReadFailed(file: "workout_menus.json", reason: error.localizedDescription))
        }
        self.workoutGroupsResult = dataResult.map { $0.workoutMenus }
    }

    private var startValidation: RecordingValidationResult {
        validator.validateForStart(purpose: selectedPurpose, selectedMenuCount: selectedMenuItems.count)
    }

    private var finishValidation: RecordingValidationResult {
        validator.validateForFinish(
            purpose: selectedPurpose,
            selectedMenuCount: selectedMenuItems.count,
            elapsedSeconds: timerState.elapsedSeconds,
            hasStarted: timerState.hasStarted
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 2) {
                    header
                    purposeChips
                    workoutTabs
                    timerSection
                    saveControls
                    if let statusMessage, let statusKind {
                        statusBanner(message: statusMessage, kind: statusKind)
                    }
                }
                .padding(.horizontal, AppLayout.grid * 2)
                .padding(.vertical, AppLayout.grid * 2.5)
            }
            .hudScrollBackground()
            .navigationTitle("")
            .applyIOSNavigationBarHidden(true)
        }
        .hudBackground()
        .onReceive(timer) { now in
            timerState.tick(now: now)
        }
        .onChange(of: selectedPurpose) { _, _ in
            clearStatus()
        }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
            Text("手動記録")
                .font(AppTypography.title(26))
                .foregroundColor(AppColors.textPrimary)
            Text("提案メニュー以外を残すための補助記録")
                .font(AppTypography.label())
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Purpose chips
    private var purposeChips: some View {
        HudSectionCard(title: "目標タイプ", subtitle: nil, spacing: AppLayout.grid) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppLayout.grid) {
                    ForEach(TrainingPurpose.allCases, id: \.self) { purpose in
                        Button(action: {
                            selectedPurpose = purpose
                            clearStatus()
                        }) {
                            HStack(spacing: AppLayout.grid * 0.6) {
                                Image(systemName: icon(for: purpose))
                                Text(purpose.displayName)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                            }
                            .font(AppTypography.label(13, weight: .semibold))
                            .padding(.horizontal, AppLayout.grid * 2)
                            .padding(.vertical, AppLayout.grid * 0.9)
                            .background(selectedPurpose == purpose ? AppColors.primary : AppColors.surface2)
                            .foregroundColor(selectedPurpose == purpose ? AppColors.background : AppColors.textSecondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(AppColors.strokeGlow, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            if let message = startValidation.message, !startValidation.isValid {
                validationMessage(message)
            }
        }
    }

    // MARK: Workout tabs
    @ViewBuilder
    private var workoutTabs: some View {
        switch workoutGroupsResult {
        case .success(let groups):
            if groups.isEmpty {
                emptyState("トレーニングメニューが登録されていません。管理画面から追加してください。")
            } else {
                let safeIndex = min(selectedGroupIndex, max(groups.count - 1, 0))
                VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
                    Text("種目を選択")
                        .font(AppTypography.body(16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppLayout.grid) {
                            ForEach(0..<groups.count, id: \.self) { index in
                                Button(action: {
                                    selectedGroupIndex = index
                                    selectedMenuItems.removeAll()
                                    clearStatus()
                                }) {
                                    Text(groups[index].muscleGroup)
                                        .font(AppTypography.body(14, weight: .semibold))
                                        .padding(.horizontal, AppLayout.grid * 2)
                                        .padding(.vertical, AppLayout.grid * 1.1)
                                        .background(selectedGroupIndex == index ? AppColors.primary : AppColors.surface2)
                                        .foregroundColor(selectedGroupIndex == index ? AppColors.background : AppColors.textSecondary)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                        Text("メニュー")
                            .font(AppTypography.body(15, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        if selectedMenuItems.isEmpty == false {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppLayout.grid) {
                                    ForEach(Array(selectedMenuItems), id: \.self) { item in
                                        Button(action: {
                                            selectedMenuItems.remove(item)
                                            clearStatus()
                                        }) {
                                            HStack(spacing: AppLayout.grid * 0.8) {
                                                Text(item.name)
                                                    .font(AppTypography.label(12, weight: .semibold))
                                                Image(systemName: "xmark.circle.fill")
                                            }
                                            .padding(.horizontal, AppLayout.grid * 1.5)
                                            .padding(.vertical, AppLayout.grid * 0.8)
                                            .background(AppColors.surface2)
                                            .foregroundColor(AppColors.textPrimary)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(AppColors.strokeGlow, lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }

                        ForEach(groups[safeIndex].menus, id: \.id) { item in
                            Button(action: {
                                if selectedMenuItems.contains(item) {
                                    selectedMenuItems.remove(item)
                                } else {
                                    selectedMenuItems.insert(item)
                                }
                                clearStatus()
                            }) {
                                HStack(alignment: .center, spacing: AppLayout.grid) {
                                    VStack(alignment: .leading, spacing: AppLayout.grid * 0.6) {
                                        Text(item.name)
                                            .font(AppTypography.body(16, weight: .semibold))
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(item.description)
                                            .font(AppTypography.label())
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: selectedMenuItems.contains(item) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedMenuItems.contains(item) ? AppColors.primary : AppColors.textSecondary)
                                }
                                .padding(AppLayout.grid * 1.5)
                                .background(AppColors.surface.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                                        .stroke(AppColors.strokeGlow, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        case .failure(let error):
            emptyState("メニューを読み込めませんでした: \(error.localizedDescription)")
        }
    }

    // MARK: Timer section
    private var timerSection: some View {
        HudSectionCard(title: "セッション", subtitle: "\(selectedMenuItems.count)件のメニューを選択中", spacing: AppLayout.grid * 1.5) {
            circularTimer
            controlButtons
        }
    }

    private var circularTimer: some View {
        let elapsed = Double(timerState.elapsedSeconds)
        let target: Double = max(elapsed, 1)
        let progress = min(max(elapsed / max(target, 1), 0), 1)

        return VStack(spacing: AppLayout.grid * 1.5) {
            ZStack {
                Circle()
                    .stroke(AppColors.primary.opacity(0.2), lineWidth: 16)
                    .frame(height: 240)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.secondary, AppColors.primary],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(height: 240)
                VStack(spacing: AppLayout.grid) {
                    Text(RecordingTimeFormatter.string(from: timerState.elapsedSeconds))
                        .font(AppTypography.hudNumber(38, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("経過時間")
                        .font(AppTypography.label(13))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            if timerState.hasStarted, let message = finishValidation.message, !finishValidation.isValid {
                validationMessage(message)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: AppLayout.grid * 1.5) {
            if timerState.isRunning {
                Button(action: { handlePause() }) {
                    Label("一時停止", systemImage: "pause.fill")
                        .font(AppTypography.body(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.secondary)
            } else {
                Button(action: { handleStartOrResume() }) {
                    Label(timerState.hasStarted ? "計測を再開" : "スタート", systemImage: "play.fill")
                        .font(AppTypography.body(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)
                .disabled(!startValidation.isValid)
            }

            Button(action: { handleReset() }) {
                Label("リセット", systemImage: "arrow.counterclockwise")
                    .font(AppTypography.body(16, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.textSecondary)
            .disabled(!timerState.hasStarted && selectedMenuItems.isEmpty && selectedPurpose == nil)
        }
    }

    // MARK: Save controls
    private var saveControls: some View {
        Button(action: { handleSave() }) {
            if isSaving {
                ProgressView()
                    .tint(AppColors.background)
                    .frame(maxWidth: .infinity)
            } else {
                Label("終了して保存", systemImage: "externaldrive.badge.checkmark")
                    .font(AppTypography.body(17, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, AppLayout.grid * 1.2)
        .buttonStyle(.borderedProminent)
        .tint(AppColors.primary)
        .disabled(isSaving || !finishValidation.isValid)
    }

    // MARK: Helpers
    private func validationMessage(_ message: String) -> some View {
        HStack(alignment: .top, spacing: AppLayout.grid) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(AppTypography.label())
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .padding(AppLayout.grid * 1.25)
        .background(AppColors.surface2.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    private func statusBanner(message: String, kind: StatusKind) -> some View {
        HStack(alignment: .top, spacing: AppLayout.grid) {
            Image(systemName: kind == .success ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .foregroundColor(kind == .success ? AppColors.primary : .red)
            Text(message)
                .font(AppTypography.label())
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(AppLayout.grid * 1.25)
        .background(kind == .success ? AppColors.surface2.opacity(0.9) : Color.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .stroke(AppColors.strokeGlow, lineWidth: 1)
        )
    }

    private func icon(for purpose: TrainingPurpose) -> String {
        switch purpose {
        case .hypertrophy: return "dumbbell"
        case .diet: return "flame.fill"
        case .refresh: return "wind"
        case .tune: return "waveform.path.ecg"
        case .other: return "circle"
        }
    }

    private func emptyState(_ message: String) -> some View {
        VStack(spacing: AppLayout.grid) {
            Text(message)
                .font(AppTypography.label())
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private func handleStartOrResume() {
        guard startValidation.isValid else {
            statusKind = .error
            statusMessage = startValidation.message
            return
        }
        statusMessage = nil
        statusKind = nil

        if timerState.hasStarted {
            timerState.resume()
        } else {
            timerState.start()
        }
    }

    private func handlePause() {
        timerState.pause()
    }

    private func handleReset() {
        timerState.reset()
        statusMessage = nil
        statusKind = nil
    }

    private func handleSave() {
        var finalizedTimerState = timerState
        finalizedTimerState.stop(now: Date())

        let validation = validator.validateForFinish(
            purpose: selectedPurpose,
            selectedMenuCount: selectedMenuItems.count,
            elapsedSeconds: finalizedTimerState.elapsedSeconds,
            hasStarted: finalizedTimerState.hasStarted
        )

        guard validation.isValid, let purpose = selectedPurpose else {
            statusKind = .error
            statusMessage = validation.message
            timerState = finalizedTimerState
            return
        }

        timerState = finalizedTimerState

        isSaving = true
        do {
            let log = logBuilder.makeLog(
                purpose: purpose,
                selectedMenus: Array(selectedMenuItems),
                timerState: finalizedTimerState,
                date: finalizedTimerState.startTime ?? Date()
            )
            modelContext.insert(log)
            try modelContext.save()
            statusKind = .success
            statusMessage = "トレーニングを保存しました。"
            selectedMenuItems.removeAll()
            selectedPurpose = nil
            timerState.reset()
        } catch {
            statusKind = .error
            statusMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
        isSaving = false
    }

    private func clearStatus() {
        statusMessage = nil
        statusKind = nil
    }
}

private enum StatusKind {
    case success
    case error
}

#Preview {
    RecordingView()
        .modelContainer(for: [TrainingLog.self, TrainingCondition.self, TrainingExercise.self, TrainingSet.self] as [any PersistentModel.Type], inMemory: true)
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
