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
            content
                .navigationTitle("トレーニング記録")
        }
        .onReceive(timer) { now in
            timerState.tick(now: now)
        }
        .onChange(of: selectedPurpose) { _ in
            clearStatus()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch workoutGroupsResult {
        case .success(let groups):
            if groups.isEmpty {
                EmptyStateView(title: "トレーニングメニューが登録されていません。", message: "管理画面からメニューを追加してください。")
            } else {
                workoutMenuList(groups: groups)
            }
        case .failure(let error):
            EmptyStateView(title: "メニューを読み込めませんでした", message: error.localizedDescription)
                .padding()
        }
    }

    @ViewBuilder
    private func workoutMenuList(groups: [WorkoutGroup]) -> some View {
        let safeIndex = min(selectedGroupIndex, max(groups.count - 1, 0))

        List {
            if let statusMessage, let statusKind {
                Section {
                    statusBanner(message: statusMessage, kind: statusKind)
                }
            }

            Section {
                Picker("部位", selection: $selectedGroupIndex) {
                    ForEach(0..<groups.count, id: \.self) { index in
                        Text(groups[index].muscleGroup).tag(index)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("目標タイプ")) {
                Picker("目標タイプ", selection: $selectedPurpose) {
                    Text("未選択").tag(Optional<TrainingPurpose>.none)
                    ForEach(TrainingPurpose.allCases, id: \.self) { purpose in
                        Text(purpose.displayName).tag(Optional(purpose))
                    }
                }
                .pickerStyle(.segmented)

                if let message = startValidation.message, !startValidation.isValid {
                    validationMessage(message)
                }
            }

            Section(header: Text("メニュー")) {
                ForEach(groups[safeIndex].menus, id: \.id) { item in
                    Button(action: {
                        if selectedMenuItems.contains(item) {
                            selectedMenuItems.remove(item)
                        } else {
                            selectedMenuItems.insert(item)
                        }
                        clearStatus()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.name)
                                    .font(.headline)
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedMenuItems.contains(item) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: Text("セッション")) {
                selectionSummary
                timerView
                controlButtons

                saveButton

                if timerState.hasStarted, let message = finishValidation.message, !finishValidation.isValid {
                    validationMessage(message)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var selectionSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(selectedMenuItems.count)件のメニューを選択中")
                .font(.headline)
            Text("記録開始には目標タイプとメニュー選択が必要です。保存は計測時間の条件も満たしたときのみ有効になります。")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("経過時間")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(RecordingTimeFormatter.string(from: timerState.elapsedSeconds))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .accessibilityLabel("経過時間 \(RecordingTimeFormatter.string(from: timerState.elapsedSeconds))")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controlButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if timerState.isRunning {
                    Button(action: { handlePause() }) {
                        Label("一時停止", systemImage: "pause.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: { handleStartOrResume() }) {
                        Label(timerState.hasStarted ? "計測を再開" : "記録を開始", systemImage: timerState.hasStarted ? "play.circle" : "stopwatch")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!startValidation.isValid)
                }

                Button(action: { handleReset() }) {
                    Label("リセット", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!timerState.hasStarted && selectedMenuItems.isEmpty && selectedPurpose == nil)
            }
        }
    }

    private var saveButton: some View {
        Button(action: { handleSave() }) {
            if isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Label("終了して保存", systemImage: "externaldrive.badge.checkmark")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(isSaving || !finishValidation.isValid)
    }

    private func validationMessage(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(Color(.systemOrange).opacity(0.12))
        .cornerRadius(8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBanner(message: String, kind: StatusKind) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: kind == .success ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .foregroundColor(kind == .success ? .green : .red)
            Text(message)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(10)
        .background(kind == .success ? Color(.systemGreen).opacity(0.12) : Color(.systemRed).opacity(0.12))
        .cornerRadius(10)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        let validation = finishValidation
        guard validation.isValid, let purpose = selectedPurpose else {
            statusKind = .error
            statusMessage = validation.message
            return
        }

        isSaving = true
        do {
            let log = logBuilder.makeLog(
                purpose: purpose,
                selectedMenus: Array(selectedMenuItems),
                timerState: timerState,
                date: timerState.startTime ?? Date()
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

private struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    RecordingView()
        .modelContainer(for: [TrainingLog.self, TrainingCondition.self, TrainingExercise.self, TrainingSet.self], inMemory: true)
}
