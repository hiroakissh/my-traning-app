---
name: "foundation-model-structured-output"
description: "Use when editing this Swift app's Foundation Models integration, especially plan generation, daily recommendations, or any UI/persistence flow that consumes AI output. Enforces @Generable/@Guide structured output, validation, fallback, and Markdown-free UI rendering."
---

# Foundation Models Structured Output

## Rule

When Foundation Models output is saved, shown in UI, or used to drive domain behavior, do not use free-form `String` as the primary contract.

Use:

- `@Generable` for the generated response type
- `@Guide` for fields, counts, ranges, and safety constraints
- `session.respond(to:generating:)` instead of plain `respond(to:)`
- Domain DTO mapping before SwiftData persistence
- Validator or Mapper before UI rendering
- Rule-based fallback when generation or validation fails

Plain `respond(to:) -> String` is only acceptable for transient chat-style text that is not parsed, persisted as structured state, or rendered as a plan.

## Required Pattern

1. Define a Foundation Models content type in `Infrastructure/FoundationModel`.
2. Map it to a Domain output DTO such as `DailyRecommendationOutput` or `PlanSuggestionsOutput`.
3. Validate or normalize the DTO in `Domain/Services`.
4. Persist only domain models, not raw model prose.
5. Render structured UI components, not Markdown text.

## Prompt Constraints

Every structured prompt should explicitly say:

- Output must follow the generated schema.
- Markdown, code fences, and decoration symbols are not allowed for UI fields.
- Counts and ranges must respect the `@Guide` constraints.
- Rest and recovery are valid plan outcomes.
- Unsafe or low-readiness conditions should prefer easy/recovery/rest.

## Fallback

If Foundation Models are unavailable or invalid:

- Do not show only an error.
- Return a safe rule-based recommendation where possible.
- Explain that a simple plan was prepared from local inputs.
