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
fn[W] schedule_auto_insert_apply_deferred_pass(
  schedule_entry : ScheduleEntry[W],
  graph : ScheduleBuildPassGraph[W],
  base_system_order : Array[Int],
  base_system_edges : Array[(Int, Int, Bool)],
  system_accesses : Array[SystemAccess],
  runnable_mask : Array[Bool],
) -> Unit {
  let system_count = schedule_entry.systems.length()
  let valid_explicit_sync : Array[Bool] = []
  let distance : Array[Int] = []
  let pending_sync : Array[Bool] = []
  let outgoing_edges : Array[Array[(Int, Bool)]] = []
  for system_i in 0..<system_count {
    valid_explicit_sync.push(
      runnable_mask[system_i] &&
      schedule_entry.systems[system_i].is_apply_deferred_node &&
      !schedule_system_has_run_conditions(
        schedule_entry,
        schedule_entry.systems[system_i],
      ),
    )
    distance.push(0)
    pending_sync.push(false)
    outgoing_edges.push([])
  }
  for edge in base_system_edges {
    let (from_system, to_system, ignore_deferred) = edge
    outgoing_edges[from_system].push((to_system, ignore_deferred))
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

  let synthetic_sync_nodes : Array[(Int, Int)] = []
  fn synthetic_sync_node_for_distance(distance_value : Int) -> Int {
    for entry in synthetic_sync_nodes {
      if entry.0 == distance_value {
        return entry.1
      }
    }
    let node_i = graph.add_auto_sync_node()
    synthetic_sync_nodes.push((distance_value, node_i))
    node_i
  }

  // Insert explicit or auto sync nodes on every edge whose sync distance grew.
  for system_i in base_system_order {
    for edge in outgoing_edges[system_i] {
      let target_system = edge.0
      if distance[system_i] == distance[target_system] {
        continue
      }
      if schedule_entry.systems[target_system].is_apply_deferred_node {
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
          let sync_node = synthetic_sync_node_for_distance(
            distance[target_system],
          )
          graph.add_edge(source_node, sync_node)
          graph.add_edge(sync_node, target_node)
          graph.remove_edge(source_node, target_node)
        }
      }
    }
  }
}
