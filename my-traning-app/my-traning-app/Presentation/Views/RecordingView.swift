import SwiftUI
import Combine

struct RecordingView: View {
    private let workoutGroupsResult: Result<[WorkoutGroup], BundleDecodingError>
    private let healthDataProvider: HealthDataProviding

    @State private var selectedDate = Date()
    @State private var selectedPurpose: TrainingPurpose = .hypertrophy
    @State private var selectedSource: TrainingLogSource = .manual
    @State private var sessionDurationText: String = ""
    @State private var isConditionEnabled = false
    @State private var overallConditionValue: Double = 3
    @State private var noteText: String = ""
    @State private var selectedGroupIndex = 0
    @State private var selectedMenuItems = Set<WorkoutMenuItem>()
    @State private var strengthInputs: [StrengthExerciseInput] = []
    @State private var cardioInput = CardioInput()
    @State private var sessionStartDate: Date?
    @State private var healthSnapshot: HealthDataSnapshot?
    @State private var isFetchingHealthData = false
    @State private var healthErrorMessage: String?
    @State private var lastSavedLog: TrainingLog?
    @State private var restTimerSeconds: Int = 0
    @State private var isRestTimerRunning: Bool = false

    private let restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(bundle: Bundle = .main, healthDataProvider: HealthDataProviding = HealthDataProviderFactory.make()) {
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
        self.healthDataProvider = healthDataProvider
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("トレーニング記録")
        }
        .onReceive(restTimer) { _ in
            guard isRestTimerRunning else { return }
            if restTimerSeconds > 0 {
                restTimerSeconds -= 1
            } else {
                isRestTimerRunning = false
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch workoutGroupsResult {
        case .success(let groups):
            if groups.isEmpty {
                EmptyStateView(title: "トレーニングメニューが登録されていません。", message: "管理画面からメニューを追加してください。")
            } else {
                Form {
                    dateSection
                    workoutSelectionSection(groups: groups)
                    strengthInputSection
                    cardioSection
                    restTimerSection
                    healthSection
                    actionSection
                }
            }
        case .failure(let error):
            EmptyStateView(title: "メニューを読み込めませんでした", message: error.localizedDescription)
                .padding()
        }
    }

    private var dateSection: some View {
        Section("基本情報") {
            DatePicker("トレーニング日", selection: $selectedDate, displayedComponents: .date)

            Picker("目的", selection: $selectedPurpose) {
                ForEach(TrainingPurpose.allCases, id: \.self) { purpose in
                    Text(displayName(for: purpose)).tag(purpose)
                }
            }

            Picker("記録方法", selection: $selectedSource) {
                ForEach(TrainingLogSource.allCases, id: \.self) { source in
                    Text(displayName(for: source)).tag(source)
                }
            }
            .pickerStyle(.segmented)

            TextField("セッション時間 (分)", text: $sessionDurationText)
                .keyboardType(.numberPad)

            Toggle("体調レーティングを入力する", isOn: $isConditionEnabled)
            if isConditionEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $overallConditionValue, in: 1...5, step: 1)
                    Text("今日の体調: \(Int(overallConditionValue)) / 5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            TextField("メモ (任意)", text: $noteText, axis: .vertical)
                .lineLimit(1...3)
        }
    }

    private func workoutSelectionSection(groups: [WorkoutGroup]) -> some View {
        Section("種目選択") {
            let safeIndex = min(selectedGroupIndex, max(groups.count - 1, 0))
            Picker("部位", selection: $selectedGroupIndex) {
                ForEach(0..<groups.count, id: \.self) { index in
                    Text(groups[index].muscleGroup).tag(index)
                }
            }
            .pickerStyle(.segmented)

            ForEach(groups[safeIndex].menus, id: \.id) { item in
                Button(action: {
                    toggleSelection(for: item)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
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
    }

    private var strengthInputSection: some View {
        Group {
            if !strengthInputs.isEmpty {
                Section("筋トレ入力") {
                    ForEach($strengthInputs) { $input in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(input.menuItem.name)
                                .font(.headline)
                            ForEach($input.sets) { $set in
                                HStack {
                                    TextField("重量 (kg)", text: $set.weightText)
                                        .keyboardType(.decimalPad)
                                    TextField("回数", text: $set.repetitionsText)
                                        .keyboardType(.numberPad)
                                }
                            }
                            Button(action: {
                                input.sets.append(StrengthSetInput())
                            }) {
                                Label("セットを追加", systemImage: "plus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }

    private var cardioSection: some View {
        Section("ランニング/有酸素") {
            TextField("距離 (km)", text: $cardioInput.distanceText)
                .keyboardType(.decimalPad)
            TextField("時間 (分:秒)", text: $cardioInput.durationText)
                .keyboardType(.numbersAndPunctuation)

            if let metrics = cardioInput.metrics {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ペース: \(metrics.formattedPace)")
                    Text(String(format: "距離: %.1f km", metrics.distanceInKilometers))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var restTimerSection: some View {
        Section("タイマー") {
            HStack {
                Label("休憩タイマー", systemImage: "timer")
                Spacer()
                Text(formattedRestTime)
                    .monospacedDigit()
            }

            HStack {
                Button(isRestTimerRunning ? "一時停止" : "スタート") {
                    toggleRestTimer()
                }
                .buttonStyle(.borderedProminent)

                Button("リセット", action: resetRestTimer)
                    .buttonStyle(.bordered)
            }

            HStack {
                ForEach([60, 90, 120], id: \.self) { preset in
                    Button("\(preset)秒") {
                        startRestTimer(seconds: preset)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var healthSection: some View {
        Section("ヘルスケアデータ") {
            if let start = sessionStartDate {
                HStack {
                    Label("セッション開始", systemImage: "clock")
                    Spacer()
                    Text(start, style: .time)
                }
            } else {
                Text("記録開始後にHealthKitのデータを取得します。")
                    .foregroundColor(.secondary)
            }

            if isFetchingHealthData {
                ProgressView("ヘルスデータ取得中…")
            }

            if let healthErrorMessage {
                Text(healthErrorMessage)
                    .foregroundColor(.red)
            }

            if let snapshot = healthSnapshot {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(snapshot.availableMetrics.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                        HStack {
                            Text(item.key)
                            Spacer()
                            Text(item.value)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: startRecording) {
                Label("記録を開始", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedMenuItems.isEmpty)

            Button(action: saveLog) {
                Label("保存", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)

            if let lastSavedLog {
                VStack(alignment: .leading, spacing: 4) {
                    Text("保存済み: \(lastSavedLog.strengthExercises.count)種目")
                        .font(.subheadline)
                    if let cardio = lastSavedLog.cardio {
                        Text(String(format: "有酸素: %.1f km", cardio.distanceInKilometers))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let snapshot = lastSavedLog.healthSnapshot {
                        Text("ヘルスデータ: \(snapshot.availableMetrics.count)項目")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func toggleSelection(for item: WorkoutMenuItem) {
        if selectedMenuItems.contains(item) {
            selectedMenuItems.remove(item)
        } else {
            selectedMenuItems.insert(item)
        }
        syncStrengthInputs()
    }

    private func syncStrengthInputs() {
        strengthInputs = strengthInputs.filter { selectedMenuItems.contains($0.menuItem) }
        for menuItem in selectedMenuItems where !strengthInputs.contains(where: { $0.menuItem == menuItem }) {
            strengthInputs.append(StrengthExerciseInput(menuItem: menuItem))
        }
    }

    private func startRestTimer(seconds: Int? = nil) {
        if let seconds {
            restTimerSeconds = seconds
        }
        isRestTimerRunning = true
    }

    private func toggleRestTimer() {
        isRestTimerRunning.toggle()
        if isRestTimerRunning && restTimerSeconds == 0 {
            restTimerSeconds = 60
        }
    }

    private func resetRestTimer() {
        isRestTimerRunning = false
        restTimerSeconds = 0
    }

    private var formattedRestTime: String {
        let minutes = restTimerSeconds / 60
        let seconds = restTimerSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startRecording() {
        let startDate = Date()
        sessionStartDate = startDate
        healthSnapshot = nil
        healthErrorMessage = nil
        isFetchingHealthData = true

        Task {
            do {
                try await healthDataProvider.requestAuthorization()
                let snapshot = try await healthDataProvider.fetchSnapshot(since: startDate)
                await MainActor.run {
                    healthSnapshot = snapshot
                    isFetchingHealthData = false
                }
            } catch {
                await MainActor.run {
                    healthErrorMessage = error.localizedDescription
                    isFetchingHealthData = false
                }
            }
        }
    }

    private func saveLog() {
        let groups = (try? workoutGroupsResult.get()) ?? []

        let strengthLogs = strengthInputs.map { input in
            let bodyPart = bodyPart(for: input.menuItem, groups: groups)
            let setLogs = input.sets.map { set in
                StrengthSetLog(
                    weight: Double(set.weightText),
                    repetitions: Int(set.repetitionsText)
                )
            }
            return StrengthExerciseLog(
                name: input.menuItem.name,
                bodyPart: bodyPart,
                category: .strength,
                sets: setLogs
            )
        }

        var trainingExercises: [TrainingExercise] = strengthLogs.map { log in
            TrainingExercise(
                name: log.name,
                bodyPart: log.bodyPart,
                category: log.category,
                sets: log.sets.enumerated().map { index, set in
                    TrainingSet(
                        order: index + 1,
                        weightKg: set.weight,
                        reps: set.repetitions,
                        durationSec: set.durationSec,
                        rpe: set.rpe,
                        restSec: set.restSec,
                        setNote: set.setNote,
                        isWarmup: set.isWarmup,
                        isBodyweight: set.isBodyweight
                    )
                },
                note: log.note
            )
        }

        var cardioLog: CardioExerciseLog?
        if let metrics = cardioInput.metrics {
            cardioLog = CardioExerciseLog(
                name: "Cardio",
                category: .cardio,
                distanceInKilometers: metrics.distanceInKilometers,
                durationInSeconds: metrics.durationInSeconds,
                pace: metrics.pacePerKilometer
            )

            let cardioSet = TrainingSet(
                order: 1,
                weightKg: nil,
                reps: nil,
                durationSec: Int(metrics.durationInSeconds),
                rpe: nil,
                restSec: nil,
                setNote: nil,
                isWarmup: false,
                isBodyweight: true
            )
            trainingExercises.append(
                TrainingExercise(
                    name: "Cardio",
                    bodyPart: .legs,
                    category: .cardio,
                    sets: [cardioSet],
                    note: nil
                )
            )
        }

        let condition = isConditionEnabled ? TrainingCondition(
            sleepHours: nil,
            sleepQuality: nil,
            fatigueLevel: nil,
            mood: nil,
            soreness: nil,
            conditionNote: nil,
            overallCondition: Int(overallConditionValue)
        ) : nil

        let sessionDurationSec = computeSessionDuration()
        let endDate = sessionStartDate.map { _ in Date() }

        let log = TrainingLog(
            date: selectedDate,
            startedAt: sessionStartDate,
            endedAt: endDate,
            sessionDurationSec: sessionDurationSec,
            purpose: selectedPurpose,
            source: selectedSource,
            condition: condition,
            exercises: trainingExercises,
            strengthExercises: strengthLogs,
            cardio: cardioLog,
            healthSnapshot: healthSnapshot,
            note: noteText.isEmpty ? nil : noteText
        )
        lastSavedLog = log
    }

    private func computeSessionDuration() -> Int? {
        if let start = sessionStartDate {
            return Int(Date().timeIntervalSince(start))
        }
        if let minutes = Int(sessionDurationText), minutes > 0 {
            return minutes * 60
        }
        return nil
    }

    private func bodyPart(for menuItem: WorkoutMenuItem, groups: [WorkoutGroup]) -> BodyPart {
        guard let group = groups.first(where: { $0.menus.contains(menuItem) }) else {
            return .other
        }
        return mapBodyPart(from: group.muscleGroup)
    }

    private func mapBodyPart(from muscleGroup: String) -> BodyPart {
        let lowercased = muscleGroup.lowercased()
        let mappings: [(BodyPart, [String])] = [
            (.chest, ["chest", "胸"]),
            (.back, ["back", "背中"]),
            (.legs, ["leg", "legs", "脚", "足", "下半身"]),
            (.shoulder, ["shoulder", "肩"]),
            (.arms, ["arm", "arms", "腕", "上腕"]),
            (.core, ["core", "腹", "腹筋", "お腹", "体幹"]),
            (.fullBody, ["full", "全身", "フルボディ"])
        ]

        for (bodyPart, keywords) in mappings {
            if keywords.contains(where: { lowercased.contains($0.lowercased()) || muscleGroup.contains($0) }) {
                return bodyPart
            }
        }
        return .other
    }

    private func displayName(for purpose: TrainingPurpose) -> String {
        switch purpose {
        case .refresh: return "リフレッシュ"
        case .hypertrophy: return "筋肥大"
        case .diet: return "ダイエット"
        case .tune: return "調整"
        case .other: return "その他"
        }
    }

    private func displayName(for source: TrainingLogSource) -> String {
        switch source {
        case .timer: return "タイマー"
        case .manual: return "手入力"
        case .imported: return "インポート"
        case .unknown: return "不明"
        }
    }
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

private struct StrengthExerciseInput: Identifiable, Equatable {
    let id = UUID()
    var menuItem: WorkoutMenuItem
    var sets: [StrengthSetInput] = [StrengthSetInput()]
}

private struct StrengthSetInput: Identifiable, Equatable {
    let id = UUID()
    var weightText: String = ""
    var repetitionsText: String = ""
}

private struct CardioInput: Equatable {
    var distanceText: String = ""
    var durationText: String = ""

    var metrics: CardioMetrics? {
        guard let distance = Double(distanceText), distance > 0 else { return nil }
        guard let duration = Self.duration(from: durationText), duration > 0 else { return nil }
        return CardioMetrics(distanceInKilometers: distance, durationInSeconds: duration)
    }

    private static func duration(from text: String) -> TimeInterval? {
        let components = text.split(separator: ":")
        if components.count == 2,
           let minutes = Double(components[0]),
           let seconds = Double(components[1]) {
            return minutes * 60 + seconds
        }
        if let minutes = Double(text) {
            return minutes * 60
        }
        return nil
    }
}

#Preview {
    RecordingView()
}
