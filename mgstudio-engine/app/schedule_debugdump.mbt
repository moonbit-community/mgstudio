// Copyright 2026 International Digital Economy Academy
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

///|
pub struct ScheduleGraphSettings {
  include_system_name : ((String) -> Bool)?
}

///|
pub fn ScheduleGraphSettings::default() -> ScheduleGraphSettings {
  { include_system_name: None }
}

///|
pub fn ScheduleGraphSettings::with_include_system_name(
  _ : ScheduleGraphSettings,
  include_system_name : (String) -> Bool,
) -> ScheduleGraphSettings {
  ScheduleGraphSettings::{ include_system_name: Some(include_system_name) }
}

///|
fn schedule_graph_system_name(
  cfg : SystemConfig[@ecs.World],
  index : Int,
) -> String {
  match cfg.name {
    Some(name) => name
    None =>
      match cfg.set {
        Some(set) =>
          if set.has_prefix("__chain__:") {
            match cfg.debug_name {
              Some(debug_name) => "\{debug_name}#\{index.to_string()}"
              None => "__system#\{index.to_string()}"
            }
          } else {
            "\{set}#\{index.to_string()}"
          }
        None =>
          match cfg.debug_name {
            Some(debug_name) => "\{debug_name}#\{index.to_string()}"
            None => "__system#\{index.to_string()}"
          }
      }
  }
}

///|
fn schedule_graph_include(
  settings : ScheduleGraphSettings,
  name : String,
) -> Bool {
  match settings.include_system_name {
    Some(include_system_name) => include_system_name(name)
    None => true
  }
}

///|
pub fn App::schedule_graph_dot(
  self : App[@ecs.World],
  stage : ScheduleStage,
  settings? : ScheduleGraphSettings = ScheduleGraphSettings::default(),
) -> String {
  let systems = schedule_systems(self.sub_apps.main.schedule, stage)
  let graph_plan = schedule_resolve_graph_plan(
    schedule_entry_ref(self.sub_apps.main.schedule, stage).val,
    stage,
  )
  let execution_order = if graph_plan.build_error is Some(_) {
    let fallback : Array[Int] = []
    for i in 0..<systems.length() {
      fallback.push(i)
    }
    fallback
  } else {
    graph_plan.execution_order
  }

  let lines : Array[String] = [
    "digraph ScheduleGraph {",
    "  rankdir=LR;",
    "  labelloc=\"t\";",
    "  label=\"stage: \{to_repr(stage).to_string()}\";",
  ]

  let included_system_names : Array[String] = []
  for execution_i in 0..<execution_order.length() {
    let system_i = execution_order[execution_i]
    let name = schedule_graph_system_name(systems[system_i], system_i)
    if schedule_graph_include(settings, name) {
      included_system_names.push(name)
      lines.push("  \"\{name}\";")
    }
  }

  for i in 1..<included_system_names.length() {
    let prev = included_system_names[i - 1]
    let next = included_system_names[i]
    lines.push("  \"\{prev}\" -> \"\{next}\";")
  }

  lines.push("}")
  lines.join("\n")
}
