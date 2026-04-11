// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

export const NON_GOAL_EXAMPLE_PREFIXES = [
  "async_tasks/",
  "ecs/dynamic.rs",
  "mobile/",
  "no_std/",
  "reflection/",
  "remote/",
  "3d/solari.rs",
]

export const ALWAYS_EXCLUDED_SOURCE_PREFIXES = [
  {
    prefix: "bevy/crates/bevy_ecs/",
    reason: "non_goal_ecs",
  },
  {
    prefix: "bevy/crates/bevy_ecs_macros/",
    reason: "non_goal_ecs",
  },
  {
    prefix: "bevy/crates/bevy_reflect/",
    reason: "non_goal_reflect",
  },
  {
    prefix: "bevy/crates/bevy_reflect_derive/",
    reason: "non_goal_reflect",
  },
  // Keep reflect permanently out of migration scope for mgstudio.
  // This prevents `sync_bevy_rs_to_mbt_paths.sh` from recreating
  // `mgstudio-engine/reflect/*` after manual cleanup.
  {
    prefix: "bevy/crates/bevy_reflect/macros/",
    reason: "non_goal_reflect",
  },
  {
    prefix: "bevy/crates/bevy_tasks/",
    reason: "non_goal_tasks",
  },
  {
    prefix: "bevy/crates/bevy_platform/",
    reason: "non_goal_platform",
  },
  {
    prefix: "bevy/crates/bevy_android/",
    reason: "non_goal_platform",
  },
  {
    prefix: "bevy/crates/bevy_derive/",
    reason: "non_goal_macro",
  },
  {
    prefix: "bevy/crates/bevy_macro_utils/",
    reason: "non_goal_macro",
  },
  {
    prefix: "bevy/crates/bevy_dylib/",
    reason: "non_goal_macro",
  },
  {
    prefix: "bevy/crates/bevy_encase_derive/",
    reason: "non_goal_macro",
  },
  {
    prefix: "bevy/crates/bevy_remote/",
    reason: "scope_removed_remote",
  },
  {
    prefix: "bevy/crates/bevy_solari/",
    reason: "scope_removed_solari",
  },
]

function nonGoalExampleReason(exampleSub) {
  if (NON_GOAL_EXAMPLE_PREFIXES.some((prefix) => exampleSub.startsWith(prefix))) {
    return "non_goal_example"
  }
  return null
}

export function excludeReasonForSource(
  source,
  { includeNonGoal = false, includeExcluded = false, exampleSub = null } = {},
) {
  if (includeExcluded) return null

  for (const rule of ALWAYS_EXCLUDED_SOURCE_PREFIXES) {
    if (source.startsWith(rule.prefix)) return rule.reason
  }

  if (
    source === "bevy/crates/bevy_asset/src/reflect.rs" ||
    source === "bevy/crates/bevy_scene/src/reflect_utils.rs" ||
    source === "bevy/crates/bevy_state/src/reflect.rs"
  ) {
    return "non_goal_reflect"
  }

  if (
    source === "bevy/crates/bevy_scene/src/dynamic_scene.rs" ||
    source === "bevy/crates/bevy_scene/src/dynamic_scene_builder.rs" ||
    source === "bevy/crates/bevy_scene/src/scene_filter.rs"
  ) {
    return "non_goal_dynamic_scene"
  }

  if (source.includes("/bevy_reflect/")) {
    return "non_goal_reflect"
  }

  if (source.startsWith("bevy/crates/") && source.includes("/macros/")) {
    return "non_goal_macro"
  }

  if (source.startsWith("bevy/crates/") && source.includes("_derive/")) {
    return "non_goal_macro"
  }

  if (!includeNonGoal && source.startsWith("bevy/examples/") && exampleSub !== null) {
    return nonGoalExampleReason(exampleSub)
  }

  return null
}
