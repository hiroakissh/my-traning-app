import Foundation

struct WorkoutData: Codable {
    let workoutMenus: [WorkoutGroup]
    
    private enum CodingKeys: String, CodingKey {
        case workoutMenus = "workout_menus"
    }
}

struct WorkoutGroup: Codable, Identifiable {
    let id = UUID()
    let muscleGroup: String
    let menus: [WorkoutMenuItem]

    private enum CodingKeys: String, CodingKey {
        case muscleGroup = "muscle_group"
        case menus
    }
}

struct WorkoutMenuItem: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let equipment: String

    private enum CodingKeys: String, CodingKey {
        case name, description, equipment
    }
}
