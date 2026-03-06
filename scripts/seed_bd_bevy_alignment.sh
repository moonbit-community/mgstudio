#!/usr/bin/env bash
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

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

export BD_ACTOR="${BD_ACTOR:-codex}"

ROOT_TITLE="EPIC-ROOT Bevy Source-Level Alignment (engine)"

has_existing_issues() {
  if ! bd where >/dev/null 2>&1; then
    return 1
  fi
  bd list --all -n 1 --json 2>/dev/null | rg -q '"id"'
}

create_issue() {
  local type="$1"
  local title="$2"
  local parent="$3"
  local labels="$4"
  local description="$5"
  local acceptance="$6"

  local args=(
    bd create
    --type "$type"
    --title "$title"
    --labels "$labels"
    --description "$description"
    --acceptance "$acceptance"
    --silent
  )
  if [[ -n "$parent" ]]; then
    args+=(--parent "$parent")
  fi
  "${args[@]}"
}

relate_to_cross_cutting() {
  local task_id="$1"
  local x1_id="$2"
  local x2_id="$3"
  bd dep relate "$task_id" "$x1_id" >/dev/null
  bd dep relate "$task_id" "$x2_id" >/dev/null
}

if ! bd where >/dev/null 2>&1; then
  bd init -p bd --skip-hooks >/dev/null
fi

if has_existing_issues; then
  echo "bd database already contains issues; refusing to seed duplicates" >&2
  exit 1
fi

ROOT_ID="$(create_issue \
  epic \
  "$ROOT_TITLE" \
  "" \
  "bevy-align,root" \
  "Master epic for source-level structure and implementation alignment of mgstudio-engine to the vendored Bevy snapshot (0.19.0-dev)." \
  $'1. Engine-only alignment is tracked here.\n2. File-level structure parity and implementation-path parity are both enforced.\n3. Completion requires all global gates in the approved execution plan.' \
)"
INIT_ID="$(create_issue \
  task \
  "INIT-1 Initialize bd Repository" \
  "$ROOT_ID" \
  "bevy-align,init,wave:a,own:docs" \
  "Initialize repo-local bd tracking in .beads and establish the root backlog for the Bevy source-level alignment program." \
  $'1. Repo-local .beads exists.\n2. Root epic and child epics exist.\n3. Dependency graph validates without cycles.' \
)"

create_epic() {
  local code="$1"
  local title="$2"
  local labels="$3"
  local description="$4"
  local acceptance="$5"
  local id
  id="$(create_issue epic "$code $title" "$ROOT_ID" "$labels" "$description" "$acceptance")"
  printf -v "EPIC_${code}" '%s' "$id"
}

get_epic_id() {
  local code="$1"
  local var="EPIC_${code}"
  printf '%s\n' "${!var}"
}

set_task_id() {
  local key="$1"
  local value="$2"
  local sanitized="${key//:/_}"
  printf -v "TASK_${sanitized}" '%s' "$value"
}

get_task_id() {
  local key="$1"
  local sanitized="${key//:/_}"
  local var="TASK_${sanitized}"
  printf '%s\n' "${!var}"
}

create_epic \
  E0 \
  "Baseline Freeze & Parity Tooling" \
  "bevy-align,epic,wave:a,own:docs" \
  "Freeze the vendored Bevy snapshot as the immutable source of truth and build the parity tooling needed to measure crate/file/package alignment." \
  $'1. Baseline snapshot is documented.\n2. Parity tooling exists and runs.\n3. Gap reports are reproducible.' \

create_epic \
  E1 \
  "Structural Mirror Scaffold" \
  "bevy-align,epic,wave:a,own:docs" \
  "Create the mirrored mgstudio-engine package and file scaffold that matches the Bevy crate/module tree at file granularity." \
  $'1. Mirror targets are mapped.\n2. Primary logic is no longer monolith-owned once this epic lands.\n3. Structural gaps are machine-detectable.' \

create_epic \
  E2 \
  "ECS JSON Core" \
  "bevy-align,epic,wave:b,own:ecs" \
  "Rebuild ECS internals into a Bevy-aligned module tree while using JSON-based unified upcasting for storage and runtime dispatch." \
  $'1. ECS structure mirrors bevy_ecs.\n2. JSON upcasting backend is authoritative.\n3. ECS semantic parity tests pass.' \

create_epic \
  E3 \
  "App/Plugin/Schedule Alignment" \
  "bevy-align,epic,wave:b,own:app" \
  "Align app construction, plugin wiring, schedules, states, time, and diagnostics with the Bevy source structure and execution order." \
  $'1. App/plugin/schedule module structure mirrors Bevy.\n2. Execution ordering matches intended Bevy behavior.\n3. Startup/update/state tests pass.' \

create_epic \
  E4 \
  "Asset/Scene/Reflect Alignment" \
  "bevy-align,epic,wave:b,own:asset" \
  "Align asset loading, scenes, and reflection-facing runtime structure with the corresponding Bevy crates." \
  $'1. Asset/scene/reflect module structure mirrors Bevy.\n2. Loader and lifecycle behavior matches intended Bevy flow.\n3. Asset and scene tests pass.' \

create_epic \
  E5 \
  "Render Core Split & Alignment" \
  "bevy-align,epic,wave:c,own:render-core" \
  "Split the native runtime render backend into Bevy-aligned render-core modules and align pass orchestration, resource lifetime, and pipeline setup." \
  $'1. Render-core monolith is split into aligned modules.\n2. Render orchestration follows Bevy-style stage boundaries.\n3. Core render smoke gates pass.' \

create_epic \
  E6 \
  "2D Render Alignment" \
  "bevy-align,epic,wave:d,own:render2d" \
  "Align sprite, mesh2d, text2d, and related 2D render code to the Bevy source structure and data flow." \
  $'1. 2D render structure mirrors Bevy counterparts.\n2. 2D representative examples render correctly.\n3. 2D parity tests pass.' \

create_epic \
  E7 \
  "3D/PBR/Light/PostProcess Alignment" \
  "bevy-align,epic,wave:d,own:render3d" \
  "Align camera, light, pbr, material, shadow, and post-process paths to the Bevy source structure and implementation chain." \
  $'1. 3D render structure mirrors Bevy counterparts.\n2. Shadow and near-camera-face blockers are fixed by source-aligned implementation.\n3. 3D visual gates pass.' \

create_epic \
  E8 \
  "Input/Window/A11y/Audio Alignment" \
  "bevy-align,epic,wave:c,own:io" \
  "Align native-only input, window, accessibility, and audio modules to the corresponding Bevy structure where applicable." \
  $'1. IO-related module structure mirrors intended Bevy counterparts.\n2. Native smoke tests pass.\n3. Runtime bridge leftovers are removed.' \

create_epic \
  E9 \
  "Examples/Docs/Parity Matrix" \
  "bevy-align,epic,wave:e,own:docs" \
  "Realign examples, docs, and parity matrices to the Bevy taxonomy and to the migrated engine structure." \
  $'1. Example taxonomy is mapped.\n2. Docs and parity matrices are updated.\n3. Representative examples are validated.' \

create_epic \
  E10 \
  "Fallback/Legacy Hard-Cut Cleanup" \
  "bevy-align,epic,wave:e,own:docs" \
  "Delete fallback codepaths, stubs, transport-era shims, and obsolete structures once aligned implementations are authoritative." \
  $'1. Placeholder and fallback codepaths are removed.\n2. Cleanup gates pass.\n3. Remaining deltas are only documented exceptions.' \

create_task_chain() {
  local epic_code="$1"
  local owner="$2"
  local wave="$3"
  local bevy_paths="$4"
  local mgstudio_paths="$5"

  local parent_id
  parent_id="$(get_epic_id "$epic_code")"
  local map_id split_id port_id test_id doc_id cut_id

  map_id="$(create_issue \
    task \
    "$epic_code MAP Bevy Source File Mapping" \
    "$parent_id" \
    "bevy-align,task,$wave,$owner" \
    "Produce the Bevy-to-mgstudio file mapping for this subsystem. Bevy scope: $bevy_paths. mgstudio target scope: $mgstudio_paths." \
    $'1. Bevy source files are mapped to mgstudio target files.\n2. Missing and extra modules are called out.\n3. Mapping is committed to docs or scripts as appropriate.' \
  )"

  split_id="$(create_issue \
    task \
    "$epic_code SPLIT Structural Mirror" \
    "$parent_id" \
    "bevy-align,task,$wave,$owner" \
    "Split and rearrange the mgstudio subsystem into a Bevy-aligned module tree without introducing behavior drift. Bevy scope: $bevy_paths. mgstudio target scope: $mgstudio_paths." \
    $'1. The target subtree exists in aligned structure.\n2. Logic ownership moves out of monolith files where applicable.\n3. Build remains in a recoverable state for follow-up PORT work.' \
  )"

  port_id="$(create_issue \
    task \
    "$epic_code PORT Behavior and Dataflow Alignment" \
    "$parent_id" \
    "bevy-align,task,$wave,$owner" \
    "Port subsystem behavior by reading and following Bevy source directly. Bevy source paths: $bevy_paths. Corresponding mgstudio modules: $mgstudio_paths." \
    $'1. Implementation follows Bevy source paths, not runtime guesswork.\n2. Any non-1:1 blockers are registered before continuing.\n3. Dataflow and control-flow match the intended Bevy implementation shape.' \
  )"

  test_id="$(create_issue \
    task \
    "$epic_code TEST Parity Verification" \
    "$parent_id" \
    "bevy-align,task,$wave,$owner" \
    "Add or update subsystem verification so structure and behavior changes are checked continuously. Bevy reference scope: $bevy_paths. mgstudio scope: $mgstudio_paths." \
    $'1. Tests or reproducible verification steps exist.\n2. Acceptance scenarios for the subsystem pass.\n3. Regressions are detectable by automation where feasible.' \
  )"

  doc_id="$(create_issue \
    task \
    "$epic_code DOC Chinese Alignment Notes" \
    "$parent_id" \
    "bevy-align,task,$wave,own:docs" \
    "Write Chinese alignment notes in .private/docs for this subsystem, including source mappings, implementation choices, and any exceptions." \
    $'1. Chinese design notes exist in .private/docs.\n2. Bevy source references and mgstudio target modules are listed.\n3. Differences are explicitly justified.' \
  )"

  cut_id="$(create_issue \
    task \
    "$epic_code CUT Hard-Cut Cleanup" \
    "$parent_id" \
    "bevy-align,task,$wave,$owner" \
    "Delete fallback, stub, or obsolete codepaths for this subsystem after aligned implementations are authoritative. Scope: $mgstudio_paths." \
    $'1. Old codepaths are removed.\n2. No fallback remains in the active path for this subsystem.\n3. Cleanup validation passes.' \
  )"

  set_task_id "$epic_code:MAP" "$map_id"
  set_task_id "$epic_code:SPLIT" "$split_id"
  set_task_id "$epic_code:PORT" "$port_id"
  set_task_id "$epic_code:TEST" "$test_id"
  set_task_id "$epic_code:DOC" "$doc_id"
  set_task_id "$epic_code:CUT" "$cut_id"

  bd dep "$map_id" --blocks "$split_id" >/dev/null
  bd dep "$split_id" --blocks "$port_id" >/dev/null
  bd dep "$port_id" --blocks "$test_id" >/dev/null
  bd dep "$test_id" --blocks "$doc_id" >/dev/null
  bd dep "$doc_id" --blocks "$cut_id" >/dev/null
}

create_task_chain E0 own:docs wave:a "bevy/Cargo.toml; bevy/crates/*; bevy/examples/**" "scripts/**; .private/docs/**"
create_task_chain E1 own:docs wave:a "bevy/crates/*/src/**" "mgstudio-engine/**"
create_task_chain E2 own:ecs wave:b "bevy/crates/bevy_ecs/src/**" "mgstudio-engine/ecs/**"
create_task_chain E3 own:app wave:b "bevy/crates/bevy_app/src/**; bevy/crates/bevy_state/src/**; bevy/crates/bevy_time/src/**; bevy/crates/bevy_diagnostic/src/**" "mgstudio-engine/app/**; mgstudio-engine/time/**; mgstudio-engine/diagnostics/**; mgstudio-engine/default_plugins.mbt"
create_task_chain E4 own:asset wave:b "bevy/crates/bevy_asset/src/**; bevy/crates/bevy_scene/src/**; bevy/crates/bevy_reflect/src/**" "mgstudio-engine/asset/**; mgstudio-engine/scene/**; mgstudio-engine/internal/**"
create_task_chain E5 own:render-core wave:c "bevy/crates/bevy_render/src/**; bevy/crates/bevy_camera/src/**; bevy/crates/bevy_shader/src/**" "mgstudio-engine/runtime_native/**; mgstudio-engine/window/**"
create_task_chain E6 own:render2d wave:d "bevy/crates/bevy_sprite/src/**; bevy/crates/bevy_sprite_render/src/**; bevy/crates/bevy_text/src/**; bevy/crates/bevy_ui_render/src/**" "mgstudio-engine/render2d/**; mgstudio-engine/text/**"
create_task_chain E7 own:render3d wave:d "bevy/crates/bevy_pbr/src/**; bevy/crates/bevy_light/src/**; bevy/crates/bevy_core_pipeline/src/**; bevy/crates/bevy_post_process/src/**; bevy/crates/bevy_material/src/**" "mgstudio-engine/render3d/**; mgstudio-engine/mesh/**"
create_task_chain E8 own:io wave:c "bevy/crates/bevy_input/src/**; bevy/crates/bevy_window/src/**; bevy/crates/bevy_a11y/src/**; bevy/crates/bevy_audio/src/**; bevy/crates/bevy_winit/src/**" "mgstudio-engine/input/**; mgstudio-engine/window/**; mgstudio-engine/a11y/**"
create_task_chain E9 own:docs wave:e "bevy/examples/**; bevy/examples/README.md" "mgstudio-engine/examples/**; README.md; .private/docs/**"
create_task_chain E10 own:docs wave:e "all referenced Bevy-aligned subsystems" "mgstudio-engine/**"

X1_ID="$(create_issue \
  task \
  "X1 Exception Register" \
  "$ROOT_ID" \
  "bevy-align,task,wave:a,own:docs,cross-cutting" \
  "Maintain .private/docs/engine/BEVY_ALIGNMENT_EXCEPTIONS.md. Record every unavoidable non-1:1 deviation with Bevy reference path, mgstudio path, reason, impact, and disposition." \
  $'1. Exception register exists.\n2. Every unavoidable delta is recorded before continuing implementation.\n3. Entries include Bevy path, mgstudio path, reason, impact, and owner.' \
)"
set_task_id "X1" "$X1_ID"

X2_ID="$(create_issue \
  task \
  "X2 Upstream Requests" \
  "$ROOT_ID" \
  "bevy-align,task,wave:a,own:docs,cross-cutting" \
  "Maintain .private/docs/engine/BEVY_ALIGNMENT_UPSTREAM_REQUESTS.md for MoonBit or community dependency gaps that block 1:1 alignment. Do not modify .mooncakes." \
  $'1. Upstream request log exists.\n2. Dependency blockers are captured instead of patched in .mooncakes.\n3. Each item is actionable for upstream maintainers.' \
)"
set_task_id "X2" "$X2_ID"

X3_ID="$(create_issue \
  task \
  "X3 Visual Gates" \
  "$ROOT_ID" \
  "bevy-align,task,wave:a,own:docs,cross-cutting" \
  "Build fixed-camera visual gate workflows for representative examples, especially 3d_scene shadows, 3d_shapes near-camera faces, and 2d_shapes visible geometry." \
  $'1. Fixed-camera visual gate procedure is documented.\n2. Representative examples and expected screenshots are defined.\n3. Visual comparisons are reproducible.' \
)"
set_task_id "X3" "$X3_ID"

X4_ID="$(create_issue \
  task \
  "X4 Parity Checker" \
  "$ROOT_ID" \
  "bevy-align,task,wave:a,own:docs,cross-cutting" \
  "Build structure coverage tooling that compares Bevy crate/file organization with mgstudio-engine package/file organization and reports missing or extra modules." \
  $'1. Checker exists in repo scripts.\n2. It reports crate/package and file/module coverage.\n3. Missing and extra modules are surfaced reproducibly.' \
)"
set_task_id "X4" "$X4_ID"

for code in E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 E10; do
  relate_to_cross_cutting "$(get_task_id "$code:PORT")" "$X1_ID" "$X2_ID"
  relate_to_cross_cutting "$(get_task_id "$code:TEST")" "$X1_ID" "$X2_ID"
done

bd dep "$(get_epic_id E0)" --blocks "$(get_epic_id E1)" >/dev/null
bd dep "$(get_epic_id E1)" --blocks "$(get_epic_id E2)" >/dev/null
bd dep "$(get_epic_id E2)" --blocks "$(get_epic_id E3)" >/dev/null
bd dep "$(get_epic_id E2)" --blocks "$(get_epic_id E4)" >/dev/null
bd dep "$(get_epic_id E3)" --blocks "$(get_epic_id E5)" >/dev/null
bd dep "$(get_epic_id E4)" --blocks "$(get_epic_id E5)" >/dev/null
bd dep "$(get_epic_id E5)" --blocks "$(get_epic_id E6)" >/dev/null
bd dep "$(get_epic_id E5)" --blocks "$(get_epic_id E7)" >/dev/null
bd dep "$(get_epic_id E3)" --blocks "$(get_epic_id E8)" >/dev/null
bd dep "$(get_epic_id E6)" --blocks "$(get_epic_id E9)" >/dev/null
bd dep "$(get_epic_id E7)" --blocks "$(get_epic_id E9)" >/dev/null
bd dep "$(get_epic_id E8)" --blocks "$(get_epic_id E9)" >/dev/null
bd dep "$(get_epic_id E9)" --blocks "$(get_epic_id E10)" >/dev/null
bd dep "$X1_ID" --blocks "$(get_epic_id E10)" >/dev/null
bd dep "$X2_ID" --blocks "$(get_epic_id E10)" >/dev/null
bd dep "$X3_ID" --blocks "$(get_epic_id E10)" >/dev/null
bd dep "$X4_ID" --blocks "$(get_epic_id E10)" >/dev/null

bd dep cycles >/dev/null
bd swarm create "$ROOT_ID" >/dev/null
bd swarm validate "$ROOT_ID" >/dev/null
bd close "$INIT_ID" >/dev/null

cat <<EOF
ROOT_ID=$ROOT_ID
INIT_ID=$INIT_ID
E0_ID=$(get_epic_id E0)
E1_ID=$(get_epic_id E1)
E2_ID=$(get_epic_id E2)
E3_ID=$(get_epic_id E3)
E4_ID=$(get_epic_id E4)
E5_ID=$(get_epic_id E5)
E6_ID=$(get_epic_id E6)
E7_ID=$(get_epic_id E7)
E8_ID=$(get_epic_id E8)
E9_ID=$(get_epic_id E9)
E10_ID=$(get_epic_id E10)
X1_ID=$X1_ID
X2_ID=$X2_ID
X3_ID=$X3_ID
X4_ID=$X4_ID
EOF
