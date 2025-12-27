import XCTest
import SwiftData
@testable import my_traning_app

@MainActor
final class ActivePlanTests: XCTestCase {

    func test_activePlanStoresHorizonRawValue() {
        let plan = ActivePlan(
            horizon: .midTerm,
            title: "中期プラン",
            summary: "週4回の分割トレーニング",
            detail: "詳細",
            sourcePrompt: "prompt"
        )

        XCTAssertEqual(plan.horizon, .midTerm)
        plan.horizon = .longTerm
        XCTAssertEqual(plan.horizonRaw, PlanHorizon.longTerm.rawValue)
    }

    func test_fetchesLatestPlanByAdoptedAt() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ActivePlan.self, configurations: configuration)
        let context = ModelContext(container)

        let older = ActivePlan(
            horizon: .shortTerm,
            title: "短期プラン",
            summary: "先週のプラン",
            detail: "detail",
            sourcePrompt: "prompt",
            adoptedAt: Date().addingTimeInterval(-3600)
        )
        let latest = ActivePlan(
            horizon: .longTerm,
            title: "長期プラン",
            summary: "最新のプラン",
            detail: "detail",
            sourcePrompt: "prompt",
            adoptedAt: Date()
        )

        context.insert(older)
        context.insert(latest)
        try context.save()

        var descriptor = FetchDescriptor<ActivePlan>()
        descriptor.sortBy = [SortDescriptor(\.adoptedAt, order: .reverse)]

        let fetched = try context.fetch(descriptor)

        XCTAssertEqual(fetched.count, 2)
        XCTAssertEqual(fetched.first?.title, "長期プラン")
    }
}
