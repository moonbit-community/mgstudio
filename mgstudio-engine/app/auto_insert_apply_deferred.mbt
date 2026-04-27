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
priv struct AutoInsertApplyDeferredPass {
  no_sync_edges : Array[(Int, Int)]
  auto_sync_node_ids : Array[(Int, Int)]
}

///|
fn AutoInsertApplyDeferredPass::new() -> AutoInsertApplyDeferredPass {
  { no_sync_edges: [], auto_sync_node_ids: [] }
}

///|
fn AutoInsertApplyDeferredPass::clear_no_sync_edges(
  self : AutoInsertApplyDeferredPass,
) -> Unit {
  while self.no_sync_edges.length() > 0 {
    self.no_sync_edges.pop().unwrap() |> ignore
  }
}

///|
fn AutoInsertApplyDeferredPass::add_dependency(
  self : AutoInsertApplyDeferredPass,
  from_system : Int,
  to_system : Int,
  ignore_deferred : Bool,
) -> Unit {
  if ignore_deferred && !self.no_sync_edges.contains((from_system, to_system)) {
    self.no_sync_edges.push((from_system, to_system))
  }
}

///|
fn AutoInsertApplyDeferredPass::edge_ignores_deferred(
  self : AutoInsertApplyDeferredPass,
  from_system : Int,
  to_system : Int,
) -> Bool {
  self.no_sync_edges.contains((from_system, to_system))
}

///|
fn[W] AutoInsertApplyDeferredPass::get_sync_point(
  self : AutoInsertApplyDeferredPass,
  graph : ScheduleBuildPassGraph[W],
  distance : Int,
) -> Int {
  for entry in self.auto_sync_node_ids {
    if entry.0 == distance {
      return graph.add_auto_sync_node(entry.1)
    }
  }
  let stable_sync_i = self.auto_sync_node_ids.length()
  self.auto_sync_node_ids.push((distance, stable_sync_i))
  graph.add_auto_sync_node(stable_sync_i)
}

///|
fn[W] schedule_auto_insert_apply_deferred_pass(
  schedule_entry : ScheduleEntry[W],
  graph : ScheduleBuildPassGraph[W],
  base_system_order : Array[Int],
  base_system_edges : Array[(Int, Int, Bool)],
  system_accesses : Array[SystemAccess],
  runnable_mask : Array[Bool],
) -> Unit {
  let schedule_graph = schedule_entry.graph
  let pass = schedule_graph.auto_insert_apply_deferred_pass
  pass.clear_no_sync_edges()
  for edge in base_system_edges {
    let (from_system, to_system, ignore_deferred) = edge
    pass.add_dependency(from_system, to_system, ignore_deferred)
  }
  let system_count = schedule_graph.systems.length()
  let valid_explicit_sync : Array[Bool] = []
  let distance : Array[Int] = []
  let pending_sync : Array[Bool] = []
  let outgoing_edges : Array[Array[(Int, Bool)]] = []
  for system_i in 0..<system_count {
    valid_explicit_sync.push(
      runnable_mask[system_i] &&
      schedule_graph.systems[system_i].is_apply_deferred_node &&
      !schedule_system_has_run_conditions(
        schedule_entry,
        schedule_graph.systems[system_i],
      ),
    )
    distance.push(0)
    pending_sync.push(false)
    outgoing_edges.push([])
  }
  for edge in base_system_edges {
    let (from_system, to_system, _) = edge
    outgoing_edges[from_system].push(
      (to_system, pass.edge_ignores_deferred(from_system, to_system)),
    )
  }
  let explicit_sync_distances : Array[(Int, Int)] = []
  fn explicit_sync_for_distance(distance_value : Int) -> Int? {
    for entry in explicit_sync_distances {
      if entry.0 == distance_value {
        return Some(entry.1)
      }
    }
    None
  }
  fn record_explicit_sync(distance_value : Int, system_i : Int) -> Unit {
    if explicit_sync_for_distance(distance_value) is None {
      explicit_sync_distances.push((distance_value, system_i))
    }
  }

  // Mirrors Bevy's distance propagation: distance counts sync points before a
  // node, while pending_sync carries ignored deferred work to a later edge.
  for system_i in base_system_order {
    let node_distance = distance[system_i]
    let mut node_needs_sync = pending_sync[system_i]
    if valid_explicit_sync[system_i] {
      record_explicit_sync(node_distance, system_i)
      node_needs_sync = false
    } else if !node_needs_sync &&
      system_accesses[system_i].uses_deferred_commands() {
      node_needs_sync = true
    }
    for edge in outgoing_edges[system_i] {
      let (target_system, ignore_deferred) = edge
      let mut edge_needs_sync = node_needs_sync
      if node_needs_sync &&
        !system_accesses[target_system].is_exclusive() &&
        ignore_deferred {
        pending_sync[target_system] = true
        edge_needs_sync = false
      }
      let weight = if edge_needs_sync || valid_explicit_sync[target_system] {
        1
      } else {
        0
      }
      let target_distance = node_distance + weight
      if target_distance > distance[target_system] {
        distance[target_system] = target_distance
      }
    }
  }

  // Insert explicit or auto sync nodes on every edge whose sync distance grew.
  for system_i in base_system_order {
    for edge in outgoing_edges[system_i] {
      let target_system = edge.0
      if distance[system_i] == distance[target_system] {
        continue
      }
      if schedule_graph.systems[target_system].is_apply_deferred_node {
        continue
      }
      let source_node = graph.system_node(system_i)
      let target_node = graph.system_node(target_system)
      match explicit_sync_for_distance(distance[target_system]) {
        Some(sync_system) => {
          let sync_node = graph.system_node(sync_system)
          graph.add_edge(source_node, sync_node)
          graph.add_edge(sync_node, target_node)
          graph.remove_edge(source_node, target_node)
        }
        None => {
          let sync_node = pass.get_sync_point(graph, distance[target_system])
          graph.add_edge(source_node, sync_node)
          graph.add_edge(sync_node, target_node)
          graph.remove_edge(source_node, target_node)
        }
      }
    }
  }
}
