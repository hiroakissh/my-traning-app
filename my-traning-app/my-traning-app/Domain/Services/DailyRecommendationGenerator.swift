import Foundation

struct PlannedExerciseOutput: Equatable {
    var name: String
    var detail: String
    var targetSets: Int?
    var targetReps: Int?
    var weightDescription: String?
    var estimatedMinutes: Int
    var category: ExerciseCategory

    func makeModel(order: Int) -> PlannedExercise {
        PlannedExercise(
            order: order,
            name: name,
            detail: detail,
            targetSets: targetSets,
            targetReps: targetReps,
            weightDescription: weightDescription,
            estimatedMinutes: estimatedMinutes,
            category: category
        )
    }
}

struct AlternativePlanOutput: Equatable {
    var title: String
    var description: String
    var estimatedMinutes: Int
    var intensity: Int

    func makeModel() -> AlternativePlan {
        AlternativePlan(
            title: title,
            description: description,
            estimatedMinutes: estimatedMinutes,
            intensity: intensity
        )
    }
}

struct DailyRecommendationOutput: Equatable {
    var readinessLevel: ReadinessLevel
    var recommendationType: RecommendationType
    var title: String
    var summary: String
    var reasons: [String]
    var exercises: [PlannedExerciseOutput]
    var alternatives: [AlternativePlanOutput]
    var recoveryAdvice: [String]

    func makeModel(date: Date = Date(), generatedAt: Date = Date()) -> DailyRecommendation {
        DailyRecommendation(
            date: date,
            readinessLevel: readinessLevel,
            recommendationType: recommendationType,
            title: title,
            summary: summary,
            reasons: reasons,
            plannedExercises: exercises.enumerated().map { index, exercise in
                exercise.makeModel(order: index + 1)
            },
            alternatives: alternatives.map { $0.makeModel() },
            recoveryAdvice: recoveryAdvice,
            generatedAt: generatedAt
        )
    }
}

struct DailyRecommendationGenerator {
    var calendar: Calendar = .current

    func decideReadiness(checkIn: DailyCheckIn) -> ReadinessLevel {
        var riskScore = 0
        if checkIn.sleepQuality == .poor {
            riskScore += 2
        }
        if checkIn.fatigueLevel == .high {
            riskScore += 2
        }
        if checkIn.sorenessLevel == .strong {
            riskScore += 2
        }
        if checkIn.moodLevel == .low {
            riskScore += 1
        }
        if checkIn.availableMinutes <= 10 {
            riskScore += 1
        }

        if riskScore >= 5 {
            return .rest
        } else if riskScore >= 3 {
            return .easy
        } else {
            return .go
        }
    }

    func generate(
        checkIn: DailyCheckIn,
        goal: UserGoal? = nil,
        recentLogs: [TrainingLog] = [],
        activePlan: ActivePlan? = nil,
        date: Date = Date()
    ) -> DailyRecommendation {
        generateOutput(
            checkIn: checkIn,
            goal: goal,
            recentLogs: recentLogs,
            activePlan: activePlan
        )
        .makeModel(date: calendar.startOfDay(for: date), generatedAt: date)
    }

    func generateOutput(
        checkIn: DailyCheckIn,
        goal: UserGoal? = nil,
        recentLogs: [TrainingLog] = [],
        activePlan: ActivePlan? = nil
    ) -> DailyRecommendationOutput {
        let readiness = decideReadiness(checkIn: checkIn)
        let goalType = goal?.goalType ?? inferGoalType(activePlan: activePlan, recentLogs: recentLogs)
        let reasons = makeReasons(checkIn: checkIn, goalType: goalType, recentLogs: recentLogs)
        let recommendationType = makeRecommendationType(readiness: readiness)
        let exercises = makeExercises(readiness: readiness, goalType: goalType, minutes: checkIn.availableMinutes)
        let title = makeTitle(readiness: readiness, goalType: goalType, minutes: checkIn.availableMinutes)

        return DailyRecommendationOutput(
            readinessLevel: readiness,
            recommendationType: recommendationType,
            title: title,
            summary: makeSummary(readiness: readiness, goalType: goalType, minutes: checkIn.availableMinutes),
            reasons: reasons,
            exercises: exercises,
            alternatives: makeAlternatives(readiness: readiness, goalType: goalType, minutes: checkIn.availableMinutes),
            recoveryAdvice: makeRecoveryAdvice(readiness: readiness, goalType: goalType)
        )
    }

    private func makeRecommendationType(readiness: ReadinessLevel) -> RecommendationType {
        switch readiness {
        case .go: return .fullWorkout
        case .easy: return .lightWorkout
        case .rest: return .rest
        }
    }

    private func inferGoalType(activePlan: ActivePlan?, recentLogs: [TrainingLog]) -> GoalType {
        let source = [
            activePlan?.title,
            activePlan?.summary,
            activePlan?.detail,
            activePlan?.sourcePrompt
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        if source.contains("大会") || source.localizedCaseInsensitiveContains("race") || source.contains("レース") || source.contains("マラソン") {
            return .race
        }
        if source.contains("減量") || source.contains("ダイエット") || source.localizedCaseInsensitiveContains("diet") {
            return .diet
        }
        if source.contains("筋力") || source.contains("筋肥大") || source.contains("ベンチ") || source.contains("重量") {
            return .strength
        }
        if source.contains("メンタル") || source.contains("回復") || source.contains("ストレス") {
            return .mentalRecovery
        }
        if source.contains("習慣") || source.contains("初心者") {
            return .habit
        }
        if source.contains("健康") || source.contains("歩数") {
            return .health
        }

        switch recentLogs.sorted(by: { $0.date > $1.date }).first?.purpose {
        case .hypertrophy:
            return .strength
        case .diet:
            return .diet
        case .refresh:
            return .mentalRecovery
        case .tune:
            return .health
        case .other, .none:
            return .health
        }
    }

    private func makeReasons(checkIn: DailyCheckIn, goalType: GoalType, recentLogs: [TrainingLog]) -> [String] {
        var reasons: [String] = []

        switch checkIn.sleepQuality {
        case .poor:
            reasons.append("睡眠の質が低めなので、回復不足の可能性があります。")
        case .normal:
            reasons.append("睡眠は普通で、大きな制限要因ではありません。")
        case .good:
            reasons.append("睡眠状態が良く、体を動かす余地があります。")
        }

        if checkIn.fatigueLevel == .high {
            reasons.append("疲労感が高いため、追い込みよりも回復を優先します。")
        } else if checkIn.fatigueLevel == .low {
            reasons.append("疲労感が軽く、通常メニューを進めやすい状態です。")
        }

        if checkIn.sorenessLevel == .strong {
            reasons.append("筋肉痛が強いため、同じ部位への高負荷は避けます。")
        } else if checkIn.sorenessLevel == .mild {
            reasons.append("軽い筋肉痛があるため、フォーム確認を中心にします。")
        }

        if checkIn.moodLevel == .low {
            reasons.append("気分が低めなので、始めやすい短いメニューに寄せます。")
        }

        if checkIn.availableMinutes <= 10 {
            reasons.append("使える時間が10分程度なので、短時間で戻れる行動を優先します。")
        } else if checkIn.availableMinutes <= 30 {
            reasons.append("30分以内で終えられるように、種目数を絞ります。")
        }

        if let latest = recentLogs.sorted(by: { $0.date > $1.date }).first,
           calendar.isDateInYesterday(latest.date) {
            reasons.append("昨日の記録があるため、連日の疲労を考慮します。")
        }

        reasons.append(goalType.policySummary)
        return reasons
    }

    private func makeTitle(readiness: ReadinessLevel, goalType: GoalType, minutes: Int) -> String {
        switch (readiness, goalType) {
        case (.go, .race):
            return "予定通りのレース準備"
        case (.go, .strength):
            return "全身ストレングス"
        case (.go, .diet):
            return "筋トレ + 有酸素"
        case (.go, .health):
            return "歩く + 軽い筋トレ"
        case (.go, .mentalRecovery):
            return "気分を上げる軽運動"
        case (.go, .habit):
            return "習慣をつなぐ基本メニュー"
        case (.easy, .race):
            return "軽めのジョグ調整"
        case (.easy, .strength):
            return "フォーム確認のライトトレーニング"
        case (.easy, .diet):
            return "20分の軽運動"
        case (.easy, .health):
            return "散歩とストレッチ"
        case (.easy, .mentalRecovery):
            return "散歩と呼吸リセット"
        case (.easy, .habit):
            return "\(min(minutes, 10))分だけ動くメニュー"
        case (.rest, _):
            return "回復を優先する日"
        }
    }

    private func makeSummary(readiness: ReadinessLevel, goalType: GoalType, minutes: Int) -> String {
        switch readiness {
        case .go:
            return "今日は通常メニューを進められる状態です。目的に沿って、やり切れる範囲で負荷をかけます。"
        case .easy:
            return "今日は軽めがおすすめです。追い込まず、習慣を切らさない短いメニューにします。"
        case .rest:
            return "今日は休むことを計画の一部として扱います。軽い回復行動だけで十分です。"
        }
    }

    private func makeExercises(readiness: ReadinessLevel, goalType: GoalType, minutes: Int) -> [PlannedExerciseOutput] {
        let cappedMinutes = max(minutes, 10)

        if readiness == .rest {
            return [
                PlannedExerciseOutput(name: "10分の散歩", detail: "息が上がらないペースで外に出るか室内を歩く", targetSets: nil, targetReps: nil, weightDescription: nil, estimatedMinutes: min(10, cappedMinutes), category: .cardio),
                PlannedExerciseOutput(name: "股関節ストレッチ", detail: "痛みのない範囲でゆっくり伸ばす", targetSets: 2, targetReps: nil, weightDescription: nil, estimatedMinutes: 5, category: .mobility),
                PlannedExerciseOutput(name: "明日のメニュー確認", detail: "今日休んでも計画が崩れていないことを確認する", targetSets: nil, targetReps: nil, weightDescription: nil, estimatedMinutes: 3, category: .other)
            ]
        }

        switch (readiness, goalType) {
        case (.go, .race):
            return [
                PlannedExerciseOutput(name: "イージーラン", detail: "会話できる強度で走る", targetSets: nil, targetReps: nil, weightDescription: nil, estimatedMinutes: min(cappedMinutes, 40), category: .cardio),
                PlannedExerciseOutput(name: "流し", detail: "フォームを整える短い加速走", targetSets: 4, targetReps: nil, weightDescription: "70%程度", estimatedMinutes: 6, category: .cardio),
                PlannedExerciseOutput(name: "下半身ストレッチ", detail: "ふくらはぎ、臀部、股関節を中心にほぐす", estimatedMinutes: 8, category: .mobility)
            ]
        case (.go, .strength):
            return [
                PlannedExerciseOutput(name: "スクワット", detail: "フォームを崩さず進める主種目", targetSets: 3, targetReps: 5, weightDescription: "前回同等から少し上", estimatedMinutes: 15, category: .strength),
                PlannedExerciseOutput(name: "ベンチプレス", detail: "最後の1セットだけ余力を確認する", targetSets: 3, targetReps: 8, weightDescription: "RPE 7-8", estimatedMinutes: 15, category: .strength),
                PlannedExerciseOutput(name: "ダンベルロー", detail: "左右差を見ながら背中を使う", targetSets: 3, targetReps: 10, weightDescription: "中重量", estimatedMinutes: 10, category: .strength)
            ]
        case (.go, .diet):
            return [
                PlannedExerciseOutput(name: "全身サーキット", detail: "スクワット、プッシュアップ、ローを休み短めで回す", targetSets: 3, targetReps: 12, weightDescription: "軽中重量", estimatedMinutes: 18, category: .strength),
                PlannedExerciseOutput(name: "有酸素", detail: "息が少し上がる強度で継続する", estimatedMinutes: min(cappedMinutes, 20), category: .cardio)
            ]
        case (.go, .health):
            return [
                PlannedExerciseOutput(name: "早歩き", detail: "姿勢を保って少し速めに歩く", estimatedMinutes: min(cappedMinutes, 30), category: .cardio),
                PlannedExerciseOutput(name: "自重スクワット", detail: "膝と股関節を動かす", targetSets: 2, targetReps: 10, estimatedMinutes: 6, category: .strength),
                PlannedExerciseOutput(name: "肩甲骨まわし", detail: "デスクワークのこわばりを戻す", targetSets: 2, targetReps: 10, estimatedMinutes: 4, category: .mobility)
            ]
        case (.go, .mentalRecovery):
            return [
                PlannedExerciseOutput(name: "散歩", detail: "気分が上がる場所を選んで歩く", estimatedMinutes: min(cappedMinutes, 25), category: .cardio),
                PlannedExerciseOutput(name: "軽い自重運動", detail: "スクワットとプッシュアップを無理なく行う", targetSets: 2, targetReps: 8, estimatedMinutes: 8, category: .strength),
                PlannedExerciseOutput(name: "呼吸リセット", detail: "4秒吸って6秒吐く", estimatedMinutes: 3, category: .mobility)
            ]
        case (.go, .habit):
            return [
                PlannedExerciseOutput(name: "5分ウォームアップ", detail: "関節を大きく動かす", estimatedMinutes: 5, category: .mobility),
                PlannedExerciseOutput(name: "自重スクワット", detail: "止まらずにできる回数だけ", targetSets: 2, targetReps: 8, estimatedMinutes: 5, category: .strength),
                PlannedExerciseOutput(name: "散歩", detail: "短くても外に出る", estimatedMinutes: min(cappedMinutes, 10), category: .cardio)
            ]
        case (.easy, .race):
            return [
                PlannedExerciseOutput(name: "軽めのジョグ", detail: "予定していた高強度走は避ける", estimatedMinutes: min(cappedMinutes, 25), category: .cardio),
                PlannedExerciseOutput(name: "股関節モビリティ", detail: "走る動きを邪魔する硬さを取る", estimatedMinutes: 8, category: .mobility)
            ]
        case (.easy, .strength):
            return [
                PlannedExerciseOutput(name: "ベンチプレス", detail: "重量を追わずフォーム確認", targetSets: 3, targetReps: 8, weightDescription: "軽め", estimatedMinutes: 12, category: .strength),
                PlannedExerciseOutput(name: "ダンベルロー", detail: "反動なしで背中を使う", targetSets: 3, targetReps: 10, weightDescription: "軽中重量", estimatedMinutes: 10, category: .strength),
                PlannedExerciseOutput(name: "有酸素", detail: "心拍を上げすぎず整える", estimatedMinutes: min(cappedMinutes, 20), category: .cardio)
            ]
        case (.easy, .diet):
            return [
                PlannedExerciseOutput(name: "早歩き", detail: "食欲と疲労を乱さない強度", estimatedMinutes: min(cappedMinutes, 20), category: .cardio),
                PlannedExerciseOutput(name: "体幹", detail: "プランクとデッドバグを軽く行う", targetSets: 2, targetReps: nil, estimatedMinutes: 8, category: .strength)
            ]
        case (.easy, .health):
            return [
                PlannedExerciseOutput(name: "散歩", detail: "少しでも動けた状態を作る", estimatedMinutes: min(cappedMinutes, 20), category: .cardio),
                PlannedExerciseOutput(name: "全身ストレッチ", detail: "肩、股関節、背中を中心にほぐす", estimatedMinutes: 8, category: .mobility)
            ]
        case (.easy, .mentalRecovery):
            return [
                PlannedExerciseOutput(name: "散歩", detail: "気分転換を主目的にする", estimatedMinutes: min(cappedMinutes, 15), category: .cardio),
                PlannedExerciseOutput(name: "呼吸法", detail: "ゆっくり吐く時間を長めにする", estimatedMinutes: 5, category: .mobility)
            ]
        case (.easy, .habit):
            return [
                PlannedExerciseOutput(name: "5分メニュー", detail: "スクワット、肩回し、深呼吸を各1分", estimatedMinutes: min(cappedMinutes, 5), category: .mobility),
                PlannedExerciseOutput(name: "余裕があれば散歩", detail: "できたら追加。できなくても成功扱い", estimatedMinutes: 5, category: .cardio)
            ]
        case (.rest, _):
            return []
        }
    }

    private func makeAlternatives(readiness: ReadinessLevel, goalType: GoalType, minutes: Int) -> [AlternativePlanOutput] {
        let shortMinutes = min(max(minutes, 10), 20)

        switch readiness {
        case .go:
            return [
                AlternativePlanOutput(title: "予定通りやる", description: "今日のおすすめメニューをそのまま実行する", estimatedMinutes: max(minutes, 30), intensity: 7),
                AlternativePlanOutput(title: "\(shortMinutes)分版に短縮", description: "主種目を1つ減らし、フォームと継続を優先する", estimatedMinutes: shortMinutes, intensity: 5),
                AlternativePlanOutput(title: "回復メニューに変更", description: "散歩とストレッチだけにして明日に備える", estimatedMinutes: 15, intensity: 2),
                AlternativePlanOutput(title: "今日は休養にする", description: "疲労が強くなってきた場合は休養として記録する", estimatedMinutes: 0, intensity: 1)
            ]
        case .easy:
            return [
                AlternativePlanOutput(title: "軽めで実行", description: "重量やスピードを追わず、提案メニューを行う", estimatedMinutes: min(max(minutes, 20), 35), intensity: 4),
                AlternativePlanOutput(title: "10分版にする", description: "最初の1種目か散歩だけで終える", estimatedMinutes: 10, intensity: 2),
                AlternativePlanOutput(title: "休養日にする", description: "疲労感が増す場合は休む選択に変える", estimatedMinutes: 0, intensity: 1),
                AlternativePlanOutput(title: "別メニューを提案", description: "\(goalType.displayName)に合わせて別案を作る", estimatedMinutes: shortMinutes, intensity: 3)
            ]
        case .rest:
            return [
                AlternativePlanOutput(title: "完全休養", description: "運動はせず、睡眠と水分を優先する", estimatedMinutes: 0, intensity: 1),
                AlternativePlanOutput(title: "10分だけ散歩", description: "気分転換として息が上がらない範囲で歩く", estimatedMinutes: 10, intensity: 1),
                AlternativePlanOutput(title: "ストレッチだけ", description: "痛みのない範囲で股関節と背中をほぐす", estimatedMinutes: 8, intensity: 1),
                AlternativePlanOutput(title: "AIに相談", description: "痛みや不安がある場合だけ補助的に相談する", estimatedMinutes: 5, intensity: 1)
            ]
        }
    }

    private func makeRecoveryAdvice(readiness: ReadinessLevel, goalType: GoalType) -> [String] {
        var advice = [
            "水分を多めに取り、食事を抜かない。",
            "痛みがある動きは避け、違和感が続く場合は無理に進めない。"
        ]

        if readiness == .rest {
            advice.insert("休むことも計画の一部です。今日は回復できれば成功です。", at: 0)
        } else if readiness == .easy {
            advice.insert("今日は重量やタイムを追わず、終わった後に余力が残る強度で止めます。", at: 0)
        }

        if goalType == .diet {
            advice.append("疲労が強い日は消費カロリーよりも睡眠と食欲の安定を優先します。")
        }
        if goalType == .mentalRecovery {
            advice.append("気分改善が目的なので、達成量よりも始めやすさを優先します。")
        }
        return advice
    }
}
