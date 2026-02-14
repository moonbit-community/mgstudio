#!/usr/bin/env python3
# Copyright 2025 International Digital Economy Academy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
from dataclasses import dataclass
from typing import Any

N_A_CATEGORIES = {"mobile", "no_std"}
ADAPTED_HINTS = ("Baseline parity", "not available", "replacing Bevy", "parity scope")

ROOT_EPIC_TITLE = "[epic] Full Bevy parity program (0.19.0-dev vendored baseline)"
GOVERNANCE_EPIC_TITLE = "[epic] Baseline lock and parity governance"
INFRA_EPIC_TITLE = "[epic] Parity infrastructure and CI gates"
NA_EPIC_TITLE = "[epic] N/A lane: platform-incompatible examples"

API_EPICS = {
    "core": "[epic] API parity: core_app_ecs_state_time_transform_hierarchy",
    "asset_scene_gltf": "[epic] API parity: asset_scene_gltf_animation",
    "render_core_3d": "[epic] API parity: render_core_3d",
    "ui_text_a11y": "[epic] API parity: ui_text_a11y",
    "input_window": "[epic] API parity: input_window",
    "audio_diagnostics": "[epic] API parity: audio_diagnostics_remote_dev",
}

API_TRACK_TASKS = {
    "core": [
        "API parity: schedule semantics + run conditions",
        "API parity: state transitions and hooks",
        "API parity: message/event reader frame-order semantics",
        "API parity: transform propagation edge cases",
    ],
    "asset_scene_gltf": [
        "API parity: typed asset events and load_folder semantics",
        "API parity: scene instantiation pipeline",
        "API parity: glTF loader subset for Bevy examples",
        "API parity: animation API surfaces used by examples",
    ],
    "render_core_3d": [
        "API parity: 3D camera/projection and viewport semantics",
        "API parity: PBR material surface expansion",
        "API parity: post-process hooks (bloom/tonemapping/AA)",
        "API parity: fog/light probe/reflection interfaces",
    ],
    "ui_text_a11y": [
        "API parity: UI style/layout/widget completeness",
        "API parity: UI interaction/navigation parity",
        "API parity: text pipeline compatibility for UI examples",
        "API parity: accessibility/a11y bridge completeness",
    ],
    "input_window": [
        "API parity: keyboard/mouse/touch event + state model",
        "API parity: gamepad model (events/state/rumble capability)",
        "API parity: window events/modes and host bridge",
    ],
    "audio_diagnostics": [
        "API parity: audio surface required by examples",
        "API parity: diagnostics examples support",
        "API parity: remote/dev utilities subset",
    ],
}

CATEGORY_API_TRACK = {
    "2d": "render_core_3d",
    "3d": "render_core_3d",
    "animation": "asset_scene_gltf",
    "app": "core",
    "asset": "asset_scene_gltf",
    "async_tasks": "core",
    "audio": "audio_diagnostics",
    "camera": "input_window",
    "dev_tools": "audio_diagnostics",
    "diagnostics": "audio_diagnostics",
    "ecs": "core",
    "games": "render_core_3d",
    "gizmos": "render_core_3d",
    "gltf": "asset_scene_gltf",
    "helpers": "audio_diagnostics",
    "input": "input_window",
    "large_scenes": "render_core_3d",
    "math": "core",
    "mobile": "input_window",
    "movement": "input_window",
    "no_std": "core",
    "picking": "render_core_3d",
    "reflection": "audio_diagnostics",
    "remote": "audio_diagnostics",
    "scene": "asset_scene_gltf",
    "shader": "render_core_3d",
    "shader_advanced": "render_core_3d",
    "state": "core",
    "stress_tests": "render_core_3d",
    "testbed": "render_core_3d",
    "time": "core",
    "tools": "audio_diagnostics",
    "transforms": "core",
    "ui": "ui_text_a11y",
    "usage": "core",
    "window": "input_window",
}

CATEGORY_PRIORITY = {
    "3d": 1,
    "ui": 1,
    "input": 1,
    "mobile": 3,
    "no_std": 3,
}


@dataclass(frozen=True)
class BevyExample:
    rel: str
    category: str
    stem: str


def run_cmd(root: pathlib.Path, args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=check,
    )


def run_bd_json(root: pathlib.Path, args: list[str]) -> Any:
    cmd = ["bd", *args, "--json"]
    result = run_cmd(root, cmd)
    if not result.stdout.strip():
        return None
    return json.loads(result.stdout)


def list_all_issues(root: pathlib.Path) -> list[dict[str, Any]]:
    data = run_bd_json(root, ["list", "--all", "--limit", "0"])
    if isinstance(data, list):
        return data
    return []


def discover_bevy_examples(root: pathlib.Path) -> list[BevyExample]:
    base = root / "bevy" / "examples"
    items: list[BevyExample] = []
    for path in sorted(base.glob("**/*.rs")):
        rel = path.relative_to(base).as_posix()
        category = rel.split("/", 1)[0]
        items.append(BevyExample(rel=rel, category=category, stem=path.stem))
    return items


def discover_mg_examples(root: pathlib.Path) -> dict[tuple[str, str], pathlib.Path]:
    base = root / "mgstudio-engine" / "examples"
    mapping: dict[tuple[str, str], pathlib.Path] = {}
    if not base.exists():
        return mapping
    for category_dir in sorted(base.iterdir()):
        if not category_dir.is_dir():
            continue
        category = category_dir.name
        for example_dir in sorted(category_dir.iterdir()):
            if not example_dir.is_dir():
                continue
            if not (example_dir / "moon.pkg").exists():
                continue
            mapping[(category, example_dir.name)] = example_dir
    return mapping


def is_adapted(example_dir: pathlib.Path) -> bool:
    main = example_dir / "main.mbt"
    if not main.exists():
        return False
    text = main.read_text(encoding="utf-8", errors="ignore")
    return any(hint in text for hint in ADAPTED_HINTS)


def labels_to_csv(labels: list[str]) -> str:
    dedup = []
    seen = set()
    for label in labels:
        if label not in seen:
            dedup.append(label)
            seen.add(label)
    return ",".join(dedup)


def get_issue_by_title(issues: list[dict[str, Any]], title: str) -> dict[str, Any] | None:
    for issue in issues:
        if issue.get("title") == title:
            return issue
    return None


def create_issue(
    root: pathlib.Path,
    issues: list[dict[str, Any]],
    *,
    title: str,
    issue_type: str,
    description: str,
    priority: int,
    labels: list[str],
    parent: str | None = None,
    deps: list[str] | None = None,
) -> tuple[str, bool]:
    existing = get_issue_by_title(issues, title)
    if existing is not None:
        return str(existing["id"]), False

    args = [
        "create",
        "--type",
        issue_type,
        "--title",
        title,
        "--description",
        description,
        "--priority",
        str(priority),
        "--labels",
        labels_to_csv(labels),
    ]
    if parent:
        args.extend(["--parent", parent])
    if deps:
        args.extend(["--deps", ",".join(deps)])

    created = run_bd_json(root, args)
    issue_id = str(created["id"])
    issues.append(created)
    return issue_id, True


def close_issue_if_open(root: pathlib.Path, issue_id: str, reason: str) -> None:
    detail = run_bd_json(root, ["show", issue_id])
    if isinstance(detail, list):
        detail = detail[0] if detail else None
    if detail and detail.get("status") != "closed":
        run_cmd(root, ["bd", "close", issue_id, "--reason", reason])


def ensure_label(root: pathlib.Path, issue_id: str, label: str) -> None:
    detail = run_bd_json(root, ["show", issue_id])
    if isinstance(detail, list):
        detail = detail[0] if detail else None
    labels = detail.get("labels") if detail else []
    if not labels:
        labels = []
    if label not in labels:
        run_cmd(root, ["bd", "label", "add", issue_id, label])


def sync_issues(root: pathlib.Path) -> None:
    run_cmd(root, ["bd", "sync"])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Create bd tasks for Bevy full parity program.")
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[1],
        help="Repository root.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = args.root.resolve()

    issues = list_all_issues(root)

    root_epic_id, _ = create_issue(
        root,
        issues,
        title=ROOT_EPIC_TITLE,
        issue_type="epic",
        description="Program-level epic for full Bevy parity (API + examples, WASM-first).",
        priority=0,
        labels=["bevy", "parity", "program", "baseline:0.19-dev", "wasm-first"],
    )

    governance_epic_id, _ = create_issue(
        root,
        issues,
        title=GOVERNANCE_EPIC_TITLE,
        issue_type="epic",
        description="Baseline lock, documentation governance, and parity status vocabulary.",
        priority=0,
        labels=["bevy", "parity", "governance", "baseline:0.19-dev", "wasm-first"],
        parent=root_epic_id,
    )

    infra_epic_id, _ = create_issue(
        root,
        issues,
        title=INFRA_EPIC_TITLE,
        issue_type="epic",
        description="Parity matrix generation, drift checks, build-all gate, and smoke runner.",
        priority=0,
        labels=["bevy", "parity", "infra", "baseline:0.19-dev", "wasm-first"],
        parent=root_epic_id,
    )

    na_epic_id, _ = create_issue(
        root,
        issues,
        title=NA_EPIC_TITLE,
        issue_type="epic",
        description="Track platform-incompatible examples with explicit N/A rationale.",
        priority=3,
        labels=["bevy", "parity", "examples", "n-a", "baseline:0.19-dev", "wasm-first"],
        parent=root_epic_id,
    )

    bootstrap_tasks = [
        ("Lock Bevy baseline docs to vendored snapshot", governance_epic_id),
        ("Create full-parity roadmap and matrix SoT docs", governance_epic_id),
        ("Add Bevy example parity generator and artifacts", infra_epic_id),
        ("Add CI drift check for parity artifacts", infra_epic_id),
        ("Add build-all + smoke gate for representative examples", infra_epic_id),
    ]
    for title, parent in bootstrap_tasks:
        task_id, created = create_issue(
            root,
            issues,
            title=title,
            issue_type="task",
            description="Bootstrap task for full parity program foundation.",
            priority=0,
            labels=["bevy", "parity", "infra", "baseline:0.19-dev", "wasm-first"],
            parent=parent,
        )
        if created:
            close_issue_if_open(root, task_id, "Implemented in this changeset.")

    api_epic_ids: dict[str, str] = {}
    for track, title in API_EPICS.items():
        epic_id, _ = create_issue(
            root,
            issues,
            title=title,
            issue_type="epic",
            description=f"API parity track: {track}.",
            priority=0,
            labels=[
                "bevy",
                "parity",
                "api",
                f"track:{track}",
                "baseline:0.19-dev",
                "wasm-first",
            ],
            parent=root_epic_id,
        )
        api_epic_ids[track] = epic_id

    for track, task_titles in API_TRACK_TASKS.items():
        for task_title in task_titles:
            create_issue(
                root,
                issues,
                title=task_title,
                issue_type="task",
                description=f"Deliver API parity work item under track {track}.",
                priority=0 if track in {"core", "render_core_3d", "input_window"} else 1,
                labels=[
                    "bevy",
                    "parity",
                    "api",
                    f"track:{track}",
                    "baseline:0.19-dev",
                    "wasm-first",
                ],
                parent=api_epic_ids[track],
                deps=[infra_epic_id],
            )

    examples = discover_bevy_examples(root)
    mg_examples = discover_mg_examples(root)

    categories = sorted({example.category for example in examples})
    category_epic_ids: dict[str, str] = {}

    for category in categories:
        parent = na_epic_id if category in N_A_CATEGORIES else root_epic_id
        category_epic_id, _ = create_issue(
            root,
            issues,
            title=f"[epic] Examples parity: {category}",
            issue_type="epic",
            description=f"Track parity for bevy/examples/{category}.",
            priority=CATEGORY_PRIORITY.get(category, 2),
            labels=[
                "bevy",
                "parity",
                "examples",
                f"cat:{category}",
                "baseline:0.19-dev",
                "wasm-first",
            ],
            parent=parent,
        )
        category_epic_ids[category] = category_epic_id

    created_count = 0
    closed_count = 0

    for example in examples:
        category = example.category
        track = CATEGORY_API_TRACK.get(category, "core")
        api_epic_id = api_epic_ids[track]
        category_epic_id = category_epic_ids[category]

        key = (category, example.stem)
        mg_example_dir = mg_examples.get(key)

        if category in N_A_CATEGORIES:
            parity_status = "n-a"
        elif mg_example_dir is None:
            parity_status = "blocked"
        elif is_adapted(mg_example_dir):
            parity_status = "adapted"
        else:
            parity_status = "ported"

        title = f"Port bevy/examples/{example.rel}"
        description = (
            "Migrate and verify this Bevy example under the 0.19.0-dev vendored baseline. "
            "Record parity note with status and runtime constraints."
        )

        labels = [
            "bevy",
            "parity",
            "examples",
            f"cat:{category}",
            f"parity-status:{parity_status}",
            "baseline:0.19-dev",
            "wasm-first",
        ]

        deps = []
        if category not in N_A_CATEGORIES:
            deps = [infra_epic_id, api_epic_id]

        issue_id, created = create_issue(
            root,
            issues,
            title=title,
            issue_type="task",
            description=description,
            priority=CATEGORY_PRIORITY.get(category, 2),
            labels=labels,
            parent=category_epic_id,
            deps=deps,
        )
        if created:
            created_count += 1

        ensure_label(root, issue_id, f"parity-status:{parity_status}")

        if parity_status == "n-a":
            close_issue_if_open(
                root,
                issue_id,
                "WASM-first policy: platform-incompatible category (mobile/no_std).",
            )
            closed_count += 1
        elif parity_status == "ported":
            close_issue_if_open(root, issue_id, "Example is already ported with exact parity status.")
            closed_count += 1
        elif parity_status == "adapted":
            close_issue_if_open(
                root,
                issue_id,
                "Example is already ported with documented adaptations.",
            )
            closed_count += 1

    sync_issues(root)

    print(f"root epic: {root_epic_id}")
    print(f"infra epic: {infra_epic_id}")
    print(f"created example tasks: {created_count}")
    print(f"closed example tasks: {closed_count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
