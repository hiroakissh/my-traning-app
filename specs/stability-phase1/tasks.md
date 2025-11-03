# Stability Phase 1 Tasks

1. **Add availability abstraction**
   - File: `Infrastructure/FoundationModel/LiveFoundationModelClient.swift`
   - Introduce `FoundationModelAvailabilityStatus` and refactor availability checks to return `FoundationModelError` without crashing.
   - Ensure session initialization happens after availability gating.
   - Write unit tests (new file in `my_traning_appTests`) covering each availability branch.
2. **Map structured errors in planner**
   - File: `Domain/Services/AIWorkoutPlanner.swift`
   - Add helper for translating `FoundationModelError` to localized copy.
   - Update both `createPlan` and `suggestTodayWorkout` to use the helper and reset generated content on failure.
   - Extend `AIWorkoutPlannerTests` with cases asserting localized messages for each error type.
3. **Update Home and Planning UI messaging**
   - Files: `Presentation/Views/HomeView.swift`, `Presentation/Views/PlanningView.swift`
   - Display more descriptive error strings and remove duplicate preview in Planning view.
   - Ensure retry buttons stay disabled while loading.
4. **Make bundle decoding safe**
   - Files: `Utilities/Bundle+Decoder.swift`, `Presentation/Views/RecordingView.swift`
   - Change decoder to throw and add a convenience wrapper that returns `Result`.
   - Update `RecordingView` to handle failure states with inline messaging.
   - Add unit tests validating decoder behaviour with missing and malformed data.
5. **Regression test run**
   - Execute `swift test` and capture results for the PR.
