# Stability Phase 1 Spec

## Summary
The goal of this iteration is to replace crash-based error handling with resilient user-visible flows around AI planning and workout menu loading. We will introduce graceful fallbacks when the on-device Foundation Model is unavailable, surface actionable guidance in the Home and Planning screens, and make JSON resource loading recoverable. The work focuses on eliminating fatal errors that currently terminate the app and aligning the implementation with the documented UX expectations for robust messaging.

## Background
- `LiveFoundationModelClient` currently calls `fatalError()` across multiple `SystemLanguageModel.Availability` branches, causing the app to crash whenever Apple Intelligence is unavailable or restricted.
- `HomeView` and `PlanningView` rely on `AIWorkoutPlanner.errorMessage` to inform users, but the planner only surfaces generic `localizedDescription` strings and cannot distinguish between availability states.
- The JSON loading helper `Bundle.decode` uses `fatalError`, which aborts the process on missing or malformed resource files. The design guidelines call for user-facing error surfaces and recovery paths instead of abrupt termination.

## Goals
1. Detect and classify all Apple Intelligence availability states and return structured errors from `LiveFoundationModelClient` without crashing.
2. Extend `AIWorkoutPlanner` to map structured Foundation Model errors to localized, user-friendly copy required by the Home and Planning screens.
3. Update the UI so that availability guidance is shown inline (e.g., request to enable Apple Intelligence, fallback messaging when the device is unsupported).
4. Refactor `Bundle.decode` to throw errors that can be handled by callers, preventing app termination during workout menu loading.
5. Add unit test coverage that validates the new error mapping behaviour and JSON loading error propagation.
6. Clean up duplicate preview declarations in `PlanningView` while touching the screen for messaging changes.

## Non-Goals
- Implementing the full AI conversation history or plan detail UX described in the screen specification (out of scope for this iteration).
- Introducing persistent storage (SwiftData) for plans or logs.
- Implementing navigation flows from Home to Recording beyond what is necessary to display new error messages.

## User Stories
- As a user on an unsupported device, I want to understand why AI features are unavailable instead of experiencing a crash.
- As a user who has not enabled Apple Intelligence, I want clear guidance on enabling it so that I can use AI planning features.
- As a developer running the app without bundled JSON resources, I want to see recoverable errors that help me diagnose the issue without the simulator crashing.

## Acceptance Criteria
1. Triggering `generateTodaySuggestion` or `generatePlan` on a device where Apple Intelligence is off shows an in-app message asking the user to enable the feature, and the app does not crash.
2. Triggering AI generation on an unsupported device surfaces an inline message explaining that the device is not eligible.
3. When the language model is still downloading, a non-fatal message is logged and the user receives a retry prompt once loading completes.
4. Removing the `workout_menus.json` file from the bundle results in the Recording screen showing a graceful error state instead of crashing.
5. Unit tests cover Foundation Model availability error mapping and the throwable Bundle decoder.
6. `PlanningView` declares a single preview provider.

## Open Questions
- Should we add analytics hooks for each availability error? (Out of scope for now; record decision in future iteration.)
- What is the localized copy for each availability state? (Use Japanese copy aligned with existing UI language, verify with UX later.)

## Dependencies
- Requires access to `FoundationModels` on iOS 18 SDK for availability checks.
- No external services or network calls introduced.
