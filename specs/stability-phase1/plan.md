# Stability Phase 1 Implementation Plan

## Context
This plan covers the first stabilization pass for the AI planning and workout loading flows. Work will be completed in the existing SwiftUI targets (`my_traning_app`, `my_traning_appTests`). No new modules are introduced.

## Approach
1. Model Availability Handling
   - Introduce a dedicated `FoundationModelAvailabilityStatus` enum that encapsulates each availability reason and desired user message.
   - Update `LiveFoundationModelClient` to detect availability before making requests, returning a descriptive `FoundationModelError` instead of crashing.
   - Ensure the `LanguageModelSession` is initialized lazily so that availability is re-evaluated when the status changes.
2. Planner Error Mapping
   - Extend `AIWorkoutPlanner` with a helper that translates `FoundationModelError` into localized copy for both plan and suggestion flows.
   - Preserve generic error handling for unknown errors, including logging for diagnostics.
3. UI Messaging
   - Update `HomeView` and `PlanningView` to show richer contextual messaging (e.g., enabling Apple Intelligence) using the planner’s error string.
   - Remove duplicate preview declarations while touching `PlanningView`.
4. Resilient Resource Loading
   - Replace the fatal-error based `Bundle.decode` helper with a throwing API and create a wrapper that returns `Result` to the Recording screen.
   - Update `RecordingView` to handle the new error state with inline messaging.
5. Tests
   - Add unit tests covering the new availability mapping logic and bundle decoding error propagation.
   - Update existing planner tests to assert localized messages when receiving structured errors.

## Phase 1 Constitution Check
- ✅ Aligned with spec goals (no crashing code paths, improved messaging, additional tests).
- ✅ Maintains architectural boundaries (services stay in Domain, UI in Presentation, utilities in Utilities).
- ✅ Keeps complexity low (no new frameworks or patterns introduced).

## Validation Plan
- Run `swift test` to ensure unit coverage passes.
- Manually inspect Home and Planning previews for the new messaging (documented via screenshots if feasible in a later iteration).
- Simulate decoder failure by injecting a mock bundle in tests to ensure graceful handling.

## Rollback Plan
- If runtime regressions occur, revert the feature branch commit. No schema changes are introduced, so rollback is safe.
