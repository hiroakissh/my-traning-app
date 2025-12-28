#!/usr/bin/env python3
"""
Generate lightweight Swift skeleton files from a plain-text screen specification.
- Avoids overwriting existing files.
- Produces minimal SwiftData + Observation friendly scaffolds.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from textwrap import dedent


def to_pascal_case(text: str) -> str:
    tokens = re.split(r"[^A-Za-z0-9]+", text)
    return "".join(t.title() for t in tokens if t) or "Feature"


def render_files(feature: str, spec_excerpt: str) -> dict[str, str]:
    model_type = f"{feature}Item"
    repository_type = f"{feature}Repository"
    view_model_type = f"{feature}ViewModel"
    view_type = f"{feature}View"

    return {
        "Model.swift": dedent(
            f"""
            import Foundation
            import SwiftData

            /// Derived from specification:
            /// {spec_excerpt}
            @Model
            final class {model_type} {{
                @Attribute(.unique) var id: UUID
                var title: String
                var detail: String
                var createdAt: Date

                init(id: UUID = UUID(), title: String, detail: String, createdAt: Date = .init()) {{
                    self.id = id
                    self.title = title
                    self.detail = detail
                    self.createdAt = createdAt
                }}
            }
            """
        ).strip()
        + "\n",
        "Repository.swift": dedent(
            f"""
            import Foundation
            import SwiftData

            protocol {repository_type} {{
                func fetchItems() async throws -> [ {model_type} ]
                func save(_ item: {model_type}) async throws
            }

            struct Default{repository_type}: {repository_type} {{
                let modelContext: ModelContext

                init(modelContext: ModelContext) {{
                    self.modelContext = modelContext
                }}

                func fetchItems() async throws -> [ {model_type} ] {{
                    let descriptor = FetchDescriptor<{model_type}>(sortBy: [ .init(\.createdAt, order: .reverse) ])
                    return try modelContext.fetch(descriptor)
                }}

                func save(_ item: {model_type}) async throws {{
                    modelContext.insert(item)
                    try modelContext.save()
                }}
            }
            """
        ).strip()
        + "\n",
        "ViewModel.swift": dedent(
            f"""
            import Foundation
            import Observation

            @Observable
            @MainActor
            final class {view_model_type} {{
                @ObservationIgnored private let repository: {repository_type}
                var items: [ {model_type} ] = []
                var draftTitle: String = ""
                var draftDetail: String = ""

                init(repository: {repository_type}) {{
                    self.repository = repository
                }}

                func load() async {
                    do {
                        items = try await repository.fetchItems()
                    } catch {
                        // TODO: surface error state to the View.
                    }
                }

                func addItem() async {
                    let newItem = {model_type}(title: draftTitle, detail: draftDetail)
                    do {
                        try await repository.save(newItem)
                        draftTitle = ""
                        draftDetail = ""
                        await load()
                    } catch {
                        // TODO: error handling & retry policy.
                    }
                }
            }
            """
        ).strip()
        + "\n",
        "ContentView.swift": dedent(
            f"""
            import SwiftUI
            import SwiftData

            struct {view_type}: View {{
                @State private var viewModel: {view_model_type}

                init(repository: {repository_type}) {{
                    _viewModel = State(initialValue: {view_model_type}(repository: repository))
                }}

                var body: some View {{
                    NavigationStack {{
                        VStack(alignment: .leading, spacing: 16) {{
                            Text("{feature} Spec")
                                .font(.title2)
                                .bold()

                            VStack(alignment: .leading) {{
                                TextField("Title", text: $viewModel.draftTitle)
                                TextField("Detail", text: $viewModel.draftDetail)
                                Button("Add") {{
                                    Task {{ await viewModel.addItem() }}
                                }}
                            }}
                            .textFieldStyle(.roundedBorder)

                            List(viewModel.items, id: \.id) {{ item in
                                VStack(alignment: .leading) {{
                                    Text(item.title).font(.headline)
                                    Text(item.detail).font(.subheadline)
                                }}
                            }}
                        }}
                        .padding()
                        .task { await viewModel.load() }
                    }}
                }}
            }

            #Preview {
                let container = try! ModelContainer(for: {model_type}.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                let repository = Default{repository_type}(modelContext: container.mainContext)
                return {view_type}(repository: repository)
            }
            """
        ).strip()
        + "\n",
        "Tests.swift": dedent(
            f"""
            import XCTest
            @testable import my_traning_app

            final class {feature}FlowTests: XCTestCase {{
                func testAddingItemPersistsAndReloads() async throws {{
                    // TODO: inject in-memory ModelContainer and verify save + fetch lifecycle.
                    XCTAssertTrue(true, "Replace with real assertions")
                }}
            }}
            """
        ).strip()
        + "\n",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Swift skeleton from a screen spec")
    parser.add_argument("--spec", required=True, help="Path to the screen specification text file")
    parser.add_argument("--out", default="./Generated", help="Output directory for generated Swift files")
    args = parser.parse_args()

    spec_path = Path(args.spec)
    if not spec_path.is_file():
        sys.stderr.write(f"Spec file not found: {spec_path}\n")
        return 1

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    feature = to_pascal_case(spec_path.stem)
    spec_excerpt = " ".join(spec_path.read_text(encoding="utf-8").splitlines())[:120] or "No specification provided"

    files = render_files(feature, spec_excerpt)
    collision = [ (out_dir / name) for name in files if (out_dir / name).exists() ]
    if collision:
        sys.stderr.write("Refusing to overwrite existing files:\n")
        for path in collision:
            sys.stderr.write(f" - {path}\n")
        return 1

    for name, content in files.items():
        target = out_dir / name
        target.write_text(content, encoding="utf-8")
        print(f"Created {target}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
