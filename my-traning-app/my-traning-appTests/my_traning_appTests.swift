import XCTest
@testable import my_traning_app

final class WorkoutMenuDecodingTests: XCTestCase {

    func test_decodeWorkoutDataFromInlineJSON() throws {
        let json = """
        {
            "workout_menus": [
                {
                    "muscle_group": "Chest",
                    "menus": [
                        {
                            "name": "Bench Press",
                            "description": "Classic chest exercise",
                            "equipment": "Barbell"
                        },
                        {
                            "name": "Push Up",
                            "description": "Bodyweight push exercise",
                            "equipment": "None"
                        }
                    ]
                }
            ]
        }
        """

        let data = Data(json.utf8)
        let decoded: WorkoutData = try Bundle.decode(WorkoutData.self, from: data, fileName: "inline.json")

        XCTAssertEqual(decoded.workoutMenus.count, 1)
        let group = try XCTUnwrap(decoded.workoutMenus.first)
        XCTAssertEqual(group.muscleGroup, "Chest")
        XCTAssertEqual(group.menus.count, 2)
        let firstMenu = try XCTUnwrap(group.menus.first)
        XCTAssertEqual(firstMenu.name, "Bench Press")
        XCTAssertEqual(firstMenu.description, "Classic chest exercise")
        XCTAssertEqual(firstMenu.equipment, "Barbell")
    }

    func test_bundleDecodingErrorProvidesLocalizedDescription() {
        let error = BundleDecodingError.dataReadFailed(file: "sample.json", reason: "Permission denied")
        XCTAssertEqual(error.errorDescription, "sample.jsonの読み込みに失敗しました: Permission denied")
    }
}
