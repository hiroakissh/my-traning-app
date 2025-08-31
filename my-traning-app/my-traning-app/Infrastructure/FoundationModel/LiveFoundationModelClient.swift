import Foundation
import FoundationModels

// 本番用のAPIクライアント
class LiveFoundationModelClient: FoundationModelClientProtocol {
    private var session: LanguageModelSession?

    init() {
        // モデルが利用可能かチェックし、セッションを初期化
        if SystemLanguageModel.default.isAvailable {
            let instructions = Instructions("あなたは優秀なフィットネストレーナーです。ユーザーの状況や質問に応じて、簡潔で的確なアドバイスをしてください。")
            self.session = LanguageModelSession(instructions: instructions)
        } else {
            self.session = nil
        }
    }

    func generateTodaySuggestion(prompt: String) async throws -> String {

        var model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            // Intelligence UIの表示
            fatalError()
        case .unavailable(.deviceNotEligible):
            // 代替UIの表示
            fatalError()
        case .unavailable(.appleIntelligenceNotEnabled):
            // Apple Intelligence をオンにするよう依頼
            fatalError()
        case .unavailable(let reason):
            // モデルはダウンロード中、またはその他のシステム上の理由により準備ができていない
            switch reason {
            case .modelNotReady:
                print("Model is not ready")
            case .deviceNotEligible:
                print("Device is not supported")
            case .appleIntelligenceNotEnabled:
                print("Access is restricted")
            @unknown default:
                print("Unknown reason")
            }
        case .unavailable(let other):
            // 不明な理由によりモデルが利用できない
            fatalError()
        }

        guard let session = session else {
            throw FoundationModelError.modelNotAvailable
        }

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
        // TODO: 長期プラン用のより複雑なプロンプトやオプションを設定する
        return try await generateTodaySuggestion(prompt: prompt)
    }
}

// カスタムエラー定義
enum FoundationModelError: Error, LocalizedError {
    case modelNotAvailable
    case generationFailed(Error)

    var errorDescription: String? {
        switch self {
        case .modelNotAvailable:
            return "AIモデルがこのデバイスで利用できません。"
        case .generationFailed(let underlyingError):
            return "AIからの応答生成に失敗しました: \(underlyingError.localizedDescription)"
        }
    }
}
