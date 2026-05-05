import Foundation
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "今日の運動判断。goは通常実施、easyは軽め、restは休養を表す。")
private enum FoundationReadinessLevelContent {
    case go
    case easy
    case rest

    var domainValue: ReadinessLevel {
        switch self {
        case .go: return .go
        case .easy: return .easy
        case .rest: return .rest
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "今日の提案タイプ。休養や回復も通常の選択肢として扱う。")
private enum FoundationRecommendationTypeContent {
    case fullWorkout
    case lightWorkout
    case recovery
    case rest
    case consultation

    var domainValue: RecommendationType {
        switch self {
        case .fullWorkout: return .fullWorkout
        case .lightWorkout: return .lightWorkout
        case .recovery: return .recovery
        case .rest: return .rest
        case .consultation: return .consultation
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "予定種目の分類。筋トレ、有酸素、モビリティ、その他のいずれか。")
private enum FoundationExerciseCategoryContent {
    case strength
    case cardio
    case mobility
    case other

    var domainValue: ExerciseCategory {
        switch self {
        case .strength: return .strength
        case .cardio: return .cardio
        case .mobility: return .mobility
        case .other: return .other
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "今日実行する予定メニューの1項目。UIにそのまま表示できる粒度にする。")
private struct FoundationPlannedExerciseContent {
    @Guide(description: "種目名。例: ベンチプレス、10分の散歩、股関節ストレッチ。")
    var name: String

    @Guide(description: "実行方法。強度、フォーム、注意点を短く説明する。")
    var detail: String

    @Guide(description: "目標セット数。セット数が不要な有酸素や休養行動では0。", .range(0...8))
    var targetSets: Int

    @Guide(description: "目標回数。回数が不要なメニューでは0。", .range(0...50))
    var targetReps: Int

    @Guide(description: "重量や強度の目安。不要な場合は空文字。")
    var weightDescription: String

    @Guide(description: "見込み所要時間（分）。", .range(0...120))
    var estimatedMinutes: Int

    @Guide(description: "種目カテゴリ。")
    var category: FoundationExerciseCategoryContent

    var domainValue: PlannedExerciseOutput {
        PlannedExerciseOutput(
            name: name,
            detail: detail,
            targetSets: targetSets > 0 ? targetSets : nil,
            targetReps: targetReps > 0 ? targetReps : nil,
            weightDescription: weightDescription.isEmpty ? nil : weightDescription,
            estimatedMinutes: estimatedMinutes,
            category: category.domainValue
        )
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "ユーザーが今日選べる代替プラン。通常、短縮、回復、休養を含める。")
private struct FoundationAlternativePlanContent {
    @Guide(description: "代替案タイトル。例: 20分版に短縮、休養日にする。")
    var title: String

    @Guide(description: "代替案の内容と選ぶべき状況。")
    var description: String

    @Guide(description: "見込み所要時間（分）。完全休養は0。", .range(0...120))
    var estimatedMinutes: Int

    @Guide(description: "主観的な強度。1が最も軽く、10が最も高い。", .range(1...10))
    var intensity: Int

    var domainValue: AlternativePlanOutput {
        AlternativePlanOutput(
            title: title,
            description: description,
            estimatedMinutes: estimatedMinutes,
            intensity: intensity
        )
    }
}

@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "今日の処方箋としてUIに保存・表示する構造化提案。必ず理由、代替案、回復アドバイスを含める。")
private struct FoundationDailyRecommendationContent {
    @Guide(description: "今日の状態判定。go/easy/restの3段階。")
    var readinessLevel: FoundationReadinessLevelContent

    @Guide(description: "今日の提案タイプ。トレーニングだけでなく回復・休養を正式に返す。")
    var recommendationType: FoundationRecommendationTypeContent

    @Guide(description: "今日の提案タイトル。例: 上半身ライト、回復を優先する日。")
    var title: String

    @Guide(description: "提案の短い説明。ホームカードの本文として表示する。")
    var summary: String

    @Guide(description: "ユーザーが納得できる提案理由。チェックイン、目的、最近の記録に基づく。", .count(3...6))
    var reasons: [String]

    @Guide(description: "今日のおすすめメニュー。fullWorkout/lightWorkoutでは1件以上。restでは空にする。", .count(0...5))
    var exercises: [FoundationPlannedExerciseContent]

    @Guide(description: "ユーザーが選べる代替案。短縮版、回復メニュー、休養、相談などを含める。", .count(3...4))
    var alternatives: [FoundationAlternativePlanContent]

    @Guide(description: "回復・安全・継続のための助言。休養日には休んでも計画が崩れていないことを明記する。", .count(2...5))
    var recoveryAdvice: [String]

    var domainValue: DailyRecommendationOutput {
        DailyRecommendationOutput(
            readinessLevel: readinessLevel.domainValue,
            recommendationType: recommendationType.domainValue,
            title: title,
            summary: summary,
            reasons: reasons,
            exercises: exercises.map(\.domainValue),
            alternatives: alternatives.map(\.domainValue),
            recoveryAdvice: recoveryAdvice
        )
    }
}

enum FoundationModelClientFactory {
    static func make() -> FoundationModelClientProtocol {
        if #available(iOS 26.0, macOS 26.0, *) {
            return LiveFoundationModelClient()
        } else {
            return UnavailableFoundationModelClient()
        }
    }
}

// 本番用のAPIクライアント
@available(iOS 26.0, macOS 26.0, *)
struct LiveFoundationModelClient: FoundationModelClientProtocol {
    private final class SessionBox {
        var session: LanguageModelSession?
    }

    private let box = SessionBox()
    private let systemModelProvider: () -> SystemLanguageModel
    private let instructions: Instructions

    init(systemModelProvider: @escaping () -> SystemLanguageModel = { SystemLanguageModel.default }) {
        self.systemModelProvider = systemModelProvider
        self.instructions = Instructions("あなたはパーソナルコンディションコーチです。ユーザーの体調、気分、目的、最近の記録をもとに、運動する・軽く動く・休むを安全に判断してください。休養も計画の一部として扱い、提案には必ず理由と代替案を含めてください。restの場合、予定メニューは空にし、回復行動はrecoveryAdviceに書いてください。")
    }

    func generateTodaySuggestion(prompt: String) async throws -> String {
        let session = try makeSessionIfNeeded()

        let structuredPrompt = Prompt(prompt)
        do {
            let generation = try await session.respond(to: structuredPrompt)
            return generation.content
        } catch {
            throw FoundationModelError.generationFailed(error)
        }
    }

    func generatePlan(prompt: String) async throws -> String {
        let session = try makeSessionIfNeeded()

        let longTermPrompt = """
        以下の情報に基づき、Goal（目標）/ Phase（今のフェーズ）/ Week（今週の作戦）/ Today（今日やること）の観点でトレーニングプランを提案してください。

        # 依頼内容
        \(prompt)

        # 出力要件
        - Goal／Phase／Week／Todayのセクションを含める
        - 週あたりの頻度と主なフォーカス部位を明示する
        - ボリュームや負荷は現実的な範囲で段階的に増やす
        - 休養や軽めの日も計画の一部として明示する
        - 箇条書きで簡潔に
        """

        let structuredPrompt = Prompt(longTermPrompt)
        do {
            let generation = try await session.respond(to: structuredPrompt)
            return generation.content
        } catch {
            throw FoundationModelError.generationFailed(error)
        }
    }

    func generateDailyRecommendation(prompt: String) async throws -> DailyRecommendationOutput {
        let session = try makeSessionIfNeeded()

        let structuredPrompt = Prompt(prompt)
        do {
            let generation = try await session.respond(
                to: structuredPrompt,
                generating: FoundationDailyRecommendationContent.self
            )
            return generation.content.domainValue
        } catch {
            throw FoundationModelError.generationFailed(error)
        }
    }

    private func makeSessionIfNeeded() throws -> LanguageModelSession {
        let model = systemModelProvider()
        let availabilityStatus = FoundationModelAvailabilityStatus(from: model.availability)

        guard availabilityStatus == .available else {
            throw FoundationModelError.unavailable(availabilityStatus)
        }

        if box.session == nil {
            guard model.isAvailable else {
                throw FoundationModelError.sessionUnavailable
            }
            box.session = LanguageModelSession(instructions: instructions)
        }

        guard let session = box.session else {
            throw FoundationModelError.sessionUnavailable
        }

        return session
    }
}

enum FoundationModelAvailabilityStatus: Equatable {
    case available
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unknown(reason: String)

    @available(iOS 26.0, macOS 26.0, *)
    init(from availability: SystemLanguageModel.Availability) {
        switch availability {
        case .available:
            self = .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                self = .deviceNotEligible
            case .appleIntelligenceNotEnabled:
                self = .appleIntelligenceNotEnabled
            case .modelNotReady:
                self = .modelNotReady
            @unknown default:
                self = .unknown(reason: String(describing: reason))
            }
        @unknown default:
            self = .unknown(reason: "unknown")
        }
    }

    var guidanceMessage: String {
        switch self {
        case .available:
            return ""
        case .deviceNotEligible:
            return "このデバイスではApple Intelligenceを利用できません。"
        case .appleIntelligenceNotEnabled:
            return "設定アプリからApple Intelligenceを有効にして再度お試しください。"
        case .modelNotReady:
            return "Apple Intelligenceの準備中です。ダウンロード完了後にもう一度お試しください。"
        case .unknown(let reason):
            if reason.isEmpty {
                return "AIモデルが現在利用できません。時間を置いて再度お試しください。"
            } else {
                return "AIモデルが現在利用できません。時間を置いて再度お試しください。（詳細: \(reason))"
            }
        }
    }
}

// カスタムエラー定義
enum FoundationModelError: Error {
    case unavailable(FoundationModelAvailabilityStatus)
    case sessionUnavailable
    case generationFailed(Error)
}

/// 26.0未満のOSではApple Intelligenceが利用できないため、明示的にエラーを返すクライアント
class UnavailableFoundationModelClient: FoundationModelClientProtocol {
    func generatePlan(prompt: String) async throws -> String {
        throw FoundationModelError.unavailable(.deviceNotEligible)
    }

    func generateTodaySuggestion(prompt: String) async throws -> String {
        throw FoundationModelError.unavailable(.deviceNotEligible)
    }

    func generateDailyRecommendation(prompt: String) async throws -> DailyRecommendationOutput {
        throw FoundationModelError.unavailable(.deviceNotEligible)
    }
}
