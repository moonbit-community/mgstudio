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
        Some(set) => set + "#" + index.to_string()
        None => "__system#" + index.to_string()
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
fn schedule_graph_add_edge(
  set_index : @hashmap.HashMap[SystemSet, Int],
  indeg : Array[Int],
  adj : Array[Array[Int]],
  from : SystemSet,
  to : SystemSet,
) -> Unit {
  let from_i = set_index.at(from)
  let to_i = set_index.at(to)
  adj[from_i].push(to_i)
  indeg[to_i] = indeg[to_i] + 1
}

///|
fn schedule_graph_pop_smallest(ready : Array[Int]) -> Int {
  let mut best_pos = 0
  let mut best_value = ready[0]
  let len = ready.length()
  for i in 1..<len {
    let value = ready[i]
    if value < best_value {
      best_value = value
      best_pos = i
    }
  }
  let last_index = ready.length() - 1
  ready[best_pos] = ready[last_index]
  ignore(ready.pop())
  best_value
}

///|
pub fn App::schedule_graph_dot(
  self : App[@ecs.World],
  stage : ScheduleStage,
  settings? : ScheduleGraphSettings = ScheduleGraphSettings::default(),
) -> String {
  let systems = schedule_systems(self.sub_apps.main.schedule, stage)
  let set_edges = schedule_set_edges(self.sub_apps.main.schedule, stage)

  let seen : @hashmap.HashMap[SystemSet, Bool] = @hashmap.HashMap::new()
  let set_order : Array[SystemSet] = []

  fn push_unique(
    seen : @hashmap.HashMap[SystemSet, Bool],
    set_order : Array[SystemSet],
    set : SystemSet,
  ) -> Unit {
    if !seen.contains(set) {
      set_order.push(set)
      seen.set(set, true)
    }
  }

  let system_count = systems.length()
  let groups : Array[SystemSet] = []
  for i in 0..<system_count {
    let cfg = systems[i]
    let group = if cfg.set is Some(set) {
      set
    } else {
      "__anon#" + i.to_string()
    }
    groups.push(group)
    push_unique(seen, set_order, group)
    for other in cfg.before {
      push_unique(seen, set_order, other)
    }
    for other in cfg.after {
      push_unique(seen, set_order, other)
    }
  }
  for edge in set_edges {
    push_unique(seen, set_order, edge.0)
    push_unique(seen, set_order, edge.1)
  }

  let set_count = set_order.length()
  let set_index : @hashmap.HashMap[SystemSet, Int] = @hashmap.HashMap::new()
  for i in 0..<set_count {
    set_index.set(set_order[i], i)
  }
  let indeg : Array[Int] = []
  let adj : Array[Array[Int]] = []
  for _ in 0..<set_count {
    indeg.push(0)
    adj.push([])
  }

  for edge in set_edges {
    schedule_graph_add_edge(set_index, indeg, adj, edge.0, edge.1)
  }
  for i in 0..<system_count {
    let cfg = systems[i]
    let group = groups[i]
    for other in cfg.before {
      schedule_graph_add_edge(set_index, indeg, adj, group, other)
    }
    for other in cfg.after {
      schedule_graph_add_edge(set_index, indeg, adj, other, group)
    }
  }

  let ready : Array[Int] = []
  for i in 0..<set_count {
    if indeg[i] == 0 {
      ready.push(i)
    }
  }
  let topo : Array[Int] = []
  while ready.length() > 0 {
    let next = schedule_graph_pop_smallest(ready)
    topo.push(next)
    for to in adj[next] {
      indeg[to] = indeg[to] - 1
      if indeg[to] == 0 {
        ready.push(to)
      }
    }
  }
  if topo.length() != set_count {
    topo.clear()
    for i in 0..<set_count {
      topo.push(i)
    }
  }

  let systems_by_set : Array[Array[Int]] = []
  for _ in 0..<set_count {
    systems_by_set.push([])
  }
  for i in 0..<system_count {
    let set_i = set_index.at(groups[i])
    systems_by_set[set_i].push(i)
  }

  let execution_order : Array[Int] = []
  for set_i in topo {
    for system_i in systems_by_set[set_i] {
      execution_order.push(system_i)
    }
  }

  let lines : Array[String] = [
    "digraph ScheduleGraph {",
    "  rankdir=LR;",
    "  labelloc=\"t\";",
    "  label=\"stage: " + stage.to_string() + "\";",
  ]

  let included_system_names : Array[String] = []
  for execution_i in 0..<execution_order.length() {
    let system_i = execution_order[execution_i]
    let name = schedule_graph_system_name(systems[system_i], system_i)
    if schedule_graph_include(settings, name) {
      included_system_names.push(name)
      lines.push("  \"" + name + "\";")
    }
  }

  for i in 1..<included_system_names.length() {
    let prev = included_system_names[i - 1]
    let next = included_system_names[i]
    lines.push("  \"" + prev + "\" -> \"" + next + "\";")
  }

  lines.push("}")
  lines.join("\n")
}
