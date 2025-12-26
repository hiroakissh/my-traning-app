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
            ZStack {
                AppColors.background.ignoresSafeArea()
                content
            }
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
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: AppLayout.grid * 2) {
                        basicInfoSection
                        workoutSelectionSection(groups: groups)
                        if !strengthInputs.isEmpty {
                            strengthInputSection
                        }
                        cardioSection
                        restTimerSection
                        healthSection
                        actionSection
                    }
                    .padding(.horizontal, AppLayout.grid * 2.5)
                    .padding(.vertical, AppLayout.grid * 3)
                }
            }
        case .failure(let error):
            EmptyStateView(title: "メニューを読み込めませんでした", message: error.localizedDescription)
                .padding()
        }
    }

    private var basicInfoSection: some View {
        HudSectionCard(title: "基本情報", subtitle: "日付と目的を決めてシンプルに記録") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
                hudLabeledField("トレーニング日") {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .tint(AppColors.primary)
                }

                hudLabeledField("目的") {
                    Picker("目的", selection: $selectedPurpose) {
                        ForEach(TrainingPurpose.allCases, id: \.self) { purpose in
                            Text(displayName(for: purpose))
                                .tag(purpose)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(AppColors.primary)
                }

                VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
                    fieldLabel("記録方法")
                    Picker("記録方法", selection: $selectedSource) {
                        ForEach(TrainingLogSource.allCases, id: \.self) { source in
                            Text(displayName(for: source)).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(AppColors.primary)
                }

                hudLabeledField("セッション時間 (分)") {
                    TextField("セッション時間 (分)", text: $sessionDurationText)
                        .keyboardType(.numberPad)
                }

                Toggle("体調レーティングを入力する", isOn: $isConditionEnabled)
                    .tint(AppColors.primary)
                    .font(AppTypography.body())
                    .foregroundColor(AppColors.textPrimary)

                if isConditionEnabled {
                    VStack(alignment: .leading, spacing: AppLayout.grid) {
                        Slider(value: $overallConditionValue, in: 1...5, step: 1)
                            .tint(AppColors.primary)
                        Text("今日の体調: \(Int(overallConditionValue)) / 5")
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppLayout.grid * 0.5)
                }

                hudLabeledField("メモ (任意)") {
                    TextField("メモ", text: $noteText, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
        }
    }

    private func workoutSelectionSection(groups: [WorkoutGroup]) -> some View {
        HudSectionCard(title: "種目選択", subtitle: "部位を選んでメニューをピック") {
            let safeIndex = min(selectedGroupIndex, max(groups.count - 1, 0))

            VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
                    fieldLabel("部位")
                    Picker("部位", selection: $selectedGroupIndex) {
                        ForEach(0..<groups.count, id: \.self) { index in
                            Text(groups[index].muscleGroup).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(AppColors.primary)
                }

                LazyVStack(spacing: AppLayout.grid) {
                    ForEach(groups[safeIndex].menus, id: \.id) { item in
                        Button(action: {
                            toggleSelection(for: item)
                        }) {
                            HStack(alignment: .top, spacing: AppLayout.grid) {
                                VStack(alignment: .leading, spacing: AppLayout.grid * 0.5) {
                                    Text(item.name)
                                        .font(AppTypography.body(16, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(item.description)
                                        .font(AppTypography.label(12))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                Spacer()
                                if selectedMenuItems.contains(item) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .padding(.horizontal, AppLayout.grid * 1.5)
                            .padding(.vertical, AppLayout.grid * 1.25)
                            .background(AppColors.surface2.opacity(0.92))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous)
                                    .stroke(selectedMenuItems.contains(item) ? AppColors.primary : AppColors.divider, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: AppLayout.buttonRadius, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var strengthInputSection: some View {
        HudSectionCard(title: "筋トレ入力", subtitle: "セットを追加して重さと回数を記録") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.5) {
                ForEach($strengthInputs) { $input in
                    VStack(alignment: .leading, spacing: AppLayout.grid) {
                        Text(input.menuItem.name)
                            .font(AppTypography.body(16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        ForEach($input.sets) { $set in
                            HStack(spacing: AppLayout.grid) {
                                TextField("重量 (kg)", text: $set.weightText)
                                    .keyboardType(.decimalPad)
                                    .hudFieldStyle()
                                TextField("回数", text: $set.repetitionsText)
                                    .keyboardType(.numberPad)
                                    .hudFieldStyle()
                            }
                        }
                        Button(action: {
                            input.sets.append(StrengthSetInput())
                        }) {
                            Label("セットを追加", systemImage: "plus.circle")
                                .font(AppTypography.body(15, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: AppLayout.buttonRadius))
                        .tint(AppColors.primary)
                    }
                    .padding(.vertical, AppLayout.grid * 0.5)
                }
            }
        }
    }

    private var cardioSection: some View {
        HudSectionCard(title: "ランニング/有酸素", subtitle: "距離と時間を淡々と入力") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                hudLabeledField("距離 (km)") {
                    TextField("距離 (km)", text: $cardioInput.distanceText)
                        .keyboardType(.decimalPad)
                }

                hudLabeledField("時間 (分:秒)") {
                    TextField("時間 (分:秒)", text: $cardioInput.durationText)
                        .keyboardType(.numbersAndPunctuation)
                }

                if let metrics = cardioInput.metrics {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
                        Text("ペース: \(metrics.formattedPace)")
                            .font(AppTypography.body())
                            .foregroundColor(AppColors.textPrimary)
                        Text(String(format: "距離: %.1f km", metrics.distanceInKilometers))
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.top, AppLayout.grid * 0.5)
                }
            }
        }
    }

    private var restTimerSection: some View {
        HudSectionCard(title: "タイマー", subtitle: "休憩もHUDらしく管理") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                HStack {
                    Label("休憩タイマー", systemImage: "timer")
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Text(formattedRestTime)
                        .font(AppTypography.hudNumber(38))
                        .foregroundColor(AppColors.primary)
                }

                HStack(spacing: AppLayout.grid) {
                    Button(isRestTimerRunning ? "一時停止" : "スタート") {
                        toggleRestTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: AppLayout.buttonRadius))
                    .tint(AppColors.primary)

                    Button("リセット", action: resetRestTimer)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: AppLayout.buttonRadius))
                        .tint(AppColors.textSecondary)
                }

                HStack(spacing: AppLayout.grid) {
                    ForEach([60, 90, 120], id: \.self) { preset in
                        Button("\(preset)秒") {
                            startRestTimer(seconds: preset)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.roundedRectangle(radius: AppLayout.buttonRadius))
                        .tint(AppColors.secondary)
                    }
                }
            }
        }
    }

    private var healthSection: some View {
        HudSectionCard(title: "ヘルスケアデータ", subtitle: "開始から取得したスナップショット") {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                if let start = sessionStartDate {
                    HStack {
                        Label("セッション開始", systemImage: "clock")
                        Spacer()
                        Text(start, style: .time)
                            .font(AppTypography.body())
                    }
                    .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("記録開始後にHealthKitのデータを取得します。")
                        .foregroundColor(AppColors.textSecondary)
                        .font(AppTypography.body())
                }

                if isFetchingHealthData {
                    ProgressView("ヘルスデータ取得中…")
                        .tint(AppColors.primary)
                        .foregroundColor(AppColors.textSecondary)
                }

                if let healthErrorMessage {
                    HStack(alignment: .top, spacing: AppLayout.grid) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(AppColors.secondary)
                        Text(healthErrorMessage)
                            .font(AppTypography.label(12))
                            .foregroundColor(AppColors.textPrimary)
                    }
                }

                if let snapshot = healthSnapshot {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
                        ForEach(snapshot.availableMetrics.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                            HStack {
                                Text(item.key)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text(item.value)
                                    .foregroundColor(AppColors.textSecondary)
                                    .font(AppTypography.label(12))
                            }
                            if item.key != snapshot.availableMetrics.keys.sorted().last {
                                Divider().overlay(AppColors.divider)
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        HudSectionCard(useSecondarySurface: true) {
            VStack(alignment: .leading, spacing: AppLayout.grid * 1.25) {
                Button(action: startRecording) {
                    Label("記録を開始", systemImage: "play.fill")
                        .font(AppTypography.body(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: AppLayout.buttonRadius))
                .tint(AppColors.primary)
                .disabled(selectedMenuItems.isEmpty)

                Button(action: saveLog) {
                    Label("保存", systemImage: "checkmark.circle")
                        .font(AppTypography.body(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: AppLayout.buttonRadius))
                .tint(AppColors.primary)

                if let lastSavedLog {
                    VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
                        Text("保存済み: \(lastSavedLog.strengthExercises.count)種目")
                            .font(AppTypography.body(15))
                            .foregroundColor(AppColors.textPrimary)
                        if let cardio = lastSavedLog.cardio {
                            Text(String(format: "有酸素: %.1f km", cardio.distanceInKilometers))
                                .font(AppTypography.label(12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        if let snapshot = lastSavedLog.healthSnapshot {
                            Text("ヘルスデータ: \(snapshot.availableMetrics.count)項目")
                                .font(AppTypography.label(12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func hudLabeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppLayout.grid * 0.75) {
            fieldLabel(title)
            content()
                .hudFieldStyle()
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.label())
            .foregroundColor(AppColors.textSecondary)
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
        VStack(spacing: AppLayout.grid * 1.5) {
            Text(title)
                .font(AppTypography.body(17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text(message)
                .font(AppTypography.body(15))
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .hudBackground()
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
