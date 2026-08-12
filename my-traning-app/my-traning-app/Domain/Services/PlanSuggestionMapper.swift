import Foundation

enum PlanSuggestionMapper {
    static func map(from output: PlanSuggestionsOutput, prompt: String, date: Date = Date()) -> [PlanSuggestion] {
        mapPayloads(output.plans, prompt: prompt, date: date, raw: output.jsonString)
    }

    static func map(from response: String, prompt: String, date: Date = Date()) -> [PlanSuggestion] {
        // 1. JSON形式 (推奨) を優先してパース
        if let jsonSuggestions = decodeJSONSuggestions(from: response, prompt: prompt, date: date), jsonSuggestions.isEmpty == false {
            return jsonSuggestions
        }

        // 2. Markdown風セクションのフォールバック
        let sections = splitIntoSections(from: response)
        let trimmedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSections = sections.isEmpty ? [("プラン", trimmedResponse.isEmpty ? [] : [trimmedResponse])] : sections

        return normalizedSections.enumerated().map { index, section in
            let title = section.0.isEmpty ? "プラン" : section.0
            let detail = section.1.isEmpty ? (trimmedResponse.isEmpty ? "提案が見つかりませんでした。" : trimmedResponse) : section.1.joined(separator: "\n")
            let summary = section.1.first ?? title

            return PlanSuggestion(
                id: UUID(),
                horizon: PlanHorizon.fromTitle(title),
                title: title,
                summary: cleanMarkdownLine(summary),
                detail: detail,
                rawText: response,
                sourcePrompt: prompt,
                createdAt: date.addingTimeInterval(TimeInterval(index))
            )
        }
    }

    private static func splitIntoSections(from response: String) -> [(String, [String])] {
        let lines = response.components(separatedBy: .newlines)
        var sections: [(String, [String])] = []
        var currentTitle: String?
        var currentBody: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                let headingLevel = trimmed.prefix { $0 == "#" }.count
                guard headingLevel >= 3 else { continue }

                if let title = currentTitle {
                    sections.append((title, currentBody))
                } else if !currentBody.isEmpty {
                    sections.append(("プラン", currentBody))
                }
                currentTitle = cleanMarkdownLine(trimmed.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression))
                currentBody = []
            } else if !trimmed.isEmpty {
                currentBody.append(cleanMarkdownLine(trimmed))
            }
        }

        if let title = currentTitle {
            sections.append((title, currentBody))
        } else if !currentBody.isEmpty {
            sections.append(("プラン", currentBody))
        }

        return sections
    }

    // MARK: - JSON parser (推奨形式)

    private static func decodeJSONSuggestions(from response: String, prompt: String, date: Date) -> [PlanSuggestion]? {
        guard let json = extractJSONPayload(from: response) else { return nil }
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // パターン1: 配列ルート
        if let payloads = try? decoder.decode([PlanSuggestionOutput].self, from: data) {
            return mapPayloads(payloads, prompt: prompt, date: date, raw: response)
        }
        // パターン2: { "plans": [...] }
        if let envelope = try? decoder.decode(PlanSuggestionsOutput.self, from: data) {
            return mapPayloads(envelope.plans, prompt: prompt, date: date, raw: response)
        }

        return nil
    }

    private static func mapPayloads(_ payloads: [PlanSuggestionOutput], prompt: String, date: Date, raw: String) -> [PlanSuggestion] {
        payloads.enumerated().map { index, item in
            let title = item.title.isEmpty ? "プラン" : item.title
            let horizon = PlanHorizon(rawValue: item.horizon) ?? PlanHorizon.fromTitle(title)
            let detailText = item.detail.isEmpty ? item.summary : item.detail

            return PlanSuggestion(
                id: UUID(),
                horizon: horizon,
                title: cleanMarkdownLine(title),
                summary: cleanMarkdownLine(item.summary.isEmpty ? title : item.summary),
                detail: detailText,
                rawText: raw,
                sourcePrompt: prompt,
                createdAt: date.addingTimeInterval(TimeInterval(index))
            )
        }
    }

    private static func extractJSONPayload(from response: String) -> String? {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            return trimmed
        }

        if let firstObject = trimmed.firstIndex(of: "{"),
           let lastObject = trimmed.lastIndex(of: "}"),
           firstObject < lastObject {
            return String(trimmed[firstObject...lastObject])
        }

        if let firstArray = trimmed.firstIndex(of: "["),
           let lastArray = trimmed.lastIndex(of: "]"),
           firstArray < lastArray {
            return String(trimmed[firstArray...lastArray])
        }

        return nil
    }

    private static func cleanMarkdownLine(_ value: String) -> String {
        var line = value.trimmingCharacters(in: .whitespacesAndNewlines)
        line = line.replacingOccurrences(of: "^[-*•]+\\s*", with: "", options: .regularExpression)
        line = line.replacingOccurrences(of: "**", with: "")
        line = line.replacingOccurrences(of: "__", with: "")
        line = line.replacingOccurrences(of: "`", with: "")
        line = line.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return line.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
