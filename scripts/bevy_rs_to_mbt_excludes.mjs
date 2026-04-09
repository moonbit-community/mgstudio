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
  {
    prefix: "bevy/crates/bevy_tasks/",
    reason: "non_goal_tasks",
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

  if (!includeNonGoal && source.startsWith("bevy/examples/") && exampleSub !== null) {
    return nonGoalExampleReason(exampleSub)
  }

  return null
}
