import Foundation

enum PlanSuggestionMapper {
    static func map(from response: String, prompt: String, date: Date = Date()) -> [PlanSuggestion] {
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
                summary: summary,
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
                currentTitle = trimmed.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
                currentBody = []
            } else if !trimmed.isEmpty {
                currentBody.append(trimmed)
            }
        }

        if let title = currentTitle {
            sections.append((title, currentBody))
        } else if !currentBody.isEmpty {
            sections.append(("プラン", currentBody))
        }

        return sections
    }
}
