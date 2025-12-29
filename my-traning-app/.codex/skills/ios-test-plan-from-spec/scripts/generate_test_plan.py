#!/usr/bin/env python3
"""
Generate a minimal test plan skeleton for SwiftUI + SwiftData screens from a plain-text spec.
- Avoids overwriting an existing output file.
- Highlights DI and persistence considerations.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path
from textwrap import dedent


TEMPLATE = """# {title} - Test Plan (Skeleton)

## A. Clarifications & Assumptions
- Questions (max 3):
  1. {q1}
  2. {q2}
  3. {q3}
- Assumptions:
  - {assumption1}
  - {assumption2}

## B. Scope & Risk
- In scope: feature flows, persistence, error states.
- Out of scope: heavy animations, analytics (unless specified).
- Risks/Ambiguities: {risks}

## C. Test Matrix (P0/P1/P2)
- Functional:
  - P0: happy path flow from initial state to save/confirm.
  - P1: validation failure and inline error rendering.
- State transitions (Observation):
  - P0: draft mutations reflect in UI immediately.
  - P1: navigation or dismissal preserves unsaved draft?
- Persistence (SwiftData):
  - P0: create/read/update/delete roundtrip using in-memory ModelContainer.
- Error handling:
  - P0: repository failure surfaces banner/state.
- Offline/Connectivity:
  - P1: actions queue or block when network is unavailable (if applicable).
- Accessibility:
  - P1: labels, traits, focus order for primary controls.

## D. Data & Fixtures
- SwiftData: in-memory ModelContainer with seed objects.
- Mocks/Stubs: repository/service protocol substitution for failures and delays.
- Sample data: {sample_data}

## E. Environment & DI
- Inject repository via initializer; avoid singletons.
- Use @MainActor view models; isolate async work for testability.
- Constrain concurrency (no unbounded tasks) to keep tests deterministic.

## F. Regression & Non-Functional
- Regression: ensure existing flows (list load, add, edit) remain intact.
- Performance: list rendering under 200 items is responsive.
- Localization: copy pulled from Localized strings where applicable.

## G. Next Steps
- Fill concrete cases per flow step and edge conditions.
- Confirm open questions above with stakeholders.
- Add snapshot test targets if UI differs by size class.
"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate test plan skeleton from a screen spec")
    parser.add_argument("--spec", required=True, help="Path to the screen specification text file")
    parser.add_argument("--out", required=True, help="Output markdown path")
    args = parser.parse_args()

    spec_path = Path(args.spec)
    if not spec_path.is_file():
        sys.stderr.write(f"Spec file not found: {spec_path}\n")
        return 1

    out_path = Path(args.out)
    if out_path.exists():
        sys.stderr.write(f"Refusing to overwrite existing file: {out_path}\n")
        return 1

    # Lightweight defaults derived from the spec filename
    title = spec_path.stem.replace("_", " ").title() or "Screen"
    content = spec_path.read_text(encoding="utf-8")
    lines = [line.strip() for line in content.splitlines() if line.strip()]
    default_question = "Clarify data source (remote/local) and error states"
    q1 = lines[0][:80] if lines else default_question
    q2 = lines[1][:80] if len(lines) > 1 else "Confirm navigation/flow exit conditions"
    q3 = lines[2][:80] if len(lines) > 2 else "Confirm persistence expectations (sync/offline)"
    assumption1 = "Proceed with in-memory SwiftData ModelContainer for tests"
    assumption2 = "Repository conforms to protocol and is DI-friendly"
    sample_data = lines[0][:80] if lines else "Sample item title/body for display"
    risks = "Missing validation rules" if not lines else "Potential gaps in: " + ", ".join(lines[:3])

    plan = TEMPLATE.format(
        title=title,
        q1=q1,
        q2=q2,
        q3=q3,
        assumption1=assumption1,
        assumption2=assumption2,
        sample_data=sample_data,
        risks=risks,
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(plan, encoding="utf-8")
    print(f"Created {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
