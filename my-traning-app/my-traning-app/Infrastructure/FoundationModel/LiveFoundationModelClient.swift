import Foundation
import FoundationModels

// 本番用のAPIクライアント
class LiveFoundationModelClient: FoundationModelClientProtocol {
    private var session: LanguageModelSession?
    private let systemModelProvider: () -> SystemLanguageModel
    private let instructions: Instructions

    init(systemModelProvider: @escaping () -> SystemLanguageModel = { SystemLanguageModel.default }) {
        self.systemModelProvider = systemModelProvider
        self.instructions = Instructions("あなたは優秀なフィットネストレーナーです。ユーザーの状況や質問に応じて、簡潔で的確なアドバイスをしてください。")
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

    // 長期プラン生成（今回は未実装だが、将来のためにプレースホルダーを設置）
    func generatePlan(prompt: String) async throws -> String {
        return try await generateTodaySuggestion(prompt: prompt)
    }

    private func makeSessionIfNeeded() throws -> LanguageModelSession {
        let model = systemModelProvider()
        let availabilityStatus = FoundationModelAvailabilityStatus(from: model.availability)

        guard availabilityStatus == .available else {
            throw FoundationModelError.unavailable(availabilityStatus)
        }

        if session == nil {
            guard model.isAvailable else {
                throw FoundationModelError.sessionUnavailable
            }
            session = LanguageModelSession(instructions: instructions)
        }

        guard let session else {
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
