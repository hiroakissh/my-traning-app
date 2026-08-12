import Foundation

struct UserProfile: Codable, Equatable {
    let age: Int?
    let gender: String?
    let height: Int?
    let weight: Int?

    init(age: Int? = nil, gender: String? = nil, height: Int? = nil, weight: Int? = nil) {
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
    }

    static let empty = UserProfile()

    var isComplete: Bool {
        guard let age, (13...100).contains(age),
              let height, (100...250).contains(height),
              let weight, (25...300).contains(weight),
              let gender,
              gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return false
        }
        return true
    }

    var validationMessage: String? {
        if age == nil || !(13...100).contains(age ?? 0) {
            return "年齢を13〜100歳で入力してください。"
        }
        if gender?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            return "性別を選択してください。"
        }
        if height == nil || !(100...250).contains(height ?? 0) {
            return "身長を100〜250cmで入力してください。"
        }
        if weight == nil || !(25...300).contains(weight ?? 0) {
            return "体重を25〜300kgで入力してください。"
        }
        return nil
    }

    var agePrompt: String { age.map { "\($0)歳" } ?? "未設定" }
    var genderPrompt: String { gender ?? "未設定" }
    var heightPrompt: String { height.map { "\($0)cm" } ?? "未設定" }
    var weightPrompt: String { weight.map { "\($0)kg" } ?? "未設定" }
}

enum UserProfileStore {
    private static let key = "user.profile"

    static func load(from defaults: UserDefaults = .standard) -> UserProfile {
        guard let data = defaults.data(forKey: key),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return .empty
        }
        return profile
    }

    static func save(_ profile: UserProfile, to defaults: UserDefaults = .standard) throws {
        let data = try JSONEncoder().encode(profile)
        defaults.set(data, forKey: key)
    }
}
