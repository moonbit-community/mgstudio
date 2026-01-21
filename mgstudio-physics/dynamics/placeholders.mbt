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

///|
struct Island {
  bodies : Array[RigidBodyHandle]
  mut id_in_awake_list : Int?
  mut sleeping : Bool
}

///|
fn Island::new(handle : RigidBodyHandle, sleeping : Bool) -> Island {
  { bodies: [handle], id_in_awake_list: None, sleeping }
}

///|
fn Island::remove_body(self : Island, handle : RigidBodyHandle) -> Bool {
  let mut index = -1
  for i in 0..<self.bodies.length() {
    if handle_equals(self.bodies[i], handle) {
      index = i
      break
    }
  }
  if index < 0 {
    return false
  }
  let last_index = self.bodies.length() - 1
  if index != last_index {
    self.bodies[index] = self.bodies[last_index]
  }
  self.bodies.pop() |> ignore
  true
}

///|
fn Island::contains(self : Island, handle : RigidBodyHandle) -> Bool {
  for i in 0..<self.bodies.length() {
    if handle_equals(self.bodies[i], handle) {
      return true
    }
  }
  false
}

///|
struct SleepCandidate {
  handle : RigidBodyHandle
}

///|
pub struct IslandManager {
  islands : Array[Island?]
  awake_islands : Array[Int]
  free_islands : Array[Int]
  traversal_candidates : Array[SleepCandidate]
  traversal_timestamp : Int
  body_island_ids : Array[Int]
  body_island_generations : Array[Int]
  body_island_indices : Array[Int]
}

///|
pub fn IslandManager::new() -> IslandManager {
  {
    islands: [],
    awake_islands: [],
    free_islands: [],
    traversal_candidates: [],
    traversal_timestamp: 0,
    body_island_ids: [],
    body_island_generations: [],
    body_island_indices: [],
  }
}

///|
fn IslandManager::ensure_body_capacity(self : IslandManager, id : Int) -> Unit {
  if id < 0 {
    return
  }
  let mut i = self.body_island_ids.length()
  while i <= id {
    self.body_island_ids.push(-1)
    self.body_island_generations.push(0)
    self.body_island_indices.push(-1)
    i = i + 1
  }
}

///|
fn IslandManager::insert_island(self : IslandManager, island : Island) -> Int {
  if self.free_islands.pop() is Some(index) {
    self.islands[index] = Some(island)
    index
  } else {
    let index = self.islands.length()
    self.islands.push(Some(island))
    index
  }
}

///|
fn IslandManager::remove_from_awake_list(
  self : IslandManager,
  island_id : Int,
) -> Unit {
  let island = self.islands[island_id]
  if island is Some(value) {
    if value.id_in_awake_list is Some(awake_index) {
      let island_value = value
      let last_index = self.awake_islands.length() - 1
      if awake_index != last_index {
        let moved_id = self.awake_islands[last_index]
        self.awake_islands[awake_index] = moved_id
        if self.islands[moved_id] is Some(moved_island) {
          let updated_island = moved_island
          updated_island.id_in_awake_list = Some(awake_index)
          self.islands[moved_id] = Some(updated_island)
        }
      }
      self.awake_islands.pop() |> ignore
      island_value.id_in_awake_list = None
      self.islands[island_id] = Some(island_value)
    }
  }
}

///|
fn IslandManager::insert_body(
  self : IslandManager,
  handle : RigidBodyHandle,
  sleeping : Bool,
) -> Unit {
  let island = Island::new(handle, sleeping)
  if !sleeping {
    let index = self.awake_islands.length()
    island.id_in_awake_list = Some(index)
  }
  let island_id = self.insert_island(island)
  if !sleeping {
    self.awake_islands.push(island_id)
  }
  self.ensure_body_capacity(handle.id)
  self.body_island_ids[handle.id] = island_id
  self.body_island_generations[handle.id] = handle.generation
  self.body_island_indices[handle.id] = 0
}

///|
fn IslandManager::remove_body(
  self : IslandManager,
  handle : RigidBodyHandle,
) -> Unit {
  if self.island_id_for(handle) is Some(island_id) {
    if self.islands[island_id] is Some(island) {
      self.ensure_body_capacity(handle.id)
      let mut body_index = self.body_island_indices[handle.id]
      if body_index < 0 ||
        body_index >= island.bodies.length() ||
        !handle_equals(island.bodies[body_index], handle) {
        body_index = -1
        for i in 0..<island.bodies.length() {
          if handle_equals(island.bodies[i], handle) {
            body_index = i
            break
          }
        }
      }
      if body_index < 0 {
        return
      }
      let last_index = island.bodies.length() - 1
      if body_index != last_index {
        let moved_handle = island.bodies[last_index]
        island.bodies[body_index] = moved_handle
        if moved_handle.id >= 0 &&
          moved_handle.id < self.body_island_indices.length() {
          self.body_island_indices[moved_handle.id] = body_index
        }
      }
      island.bodies.pop() |> ignore
      if handle.id >= 0 && handle.id < self.body_island_ids.length() {
        self.body_island_ids[handle.id] = -1
        self.body_island_indices[handle.id] = -1
        self.body_island_generations[handle.id] = handle.generation
      }
      if island.bodies.length() == 0 {
        self.remove_from_awake_list(island_id)
        self.islands[island_id] = None
        self.free_islands.push(island_id)
      } else {
        self.islands[island_id] = Some(island)
      }
    }
  }
}

///|
fn IslandManager::island_id_for(
  self : IslandManager,
  handle : RigidBodyHandle,
) -> Int? {
  if handle.id < 0 || handle.id >= self.body_island_ids.length() {
    return None
  }
  if self.body_island_generations[handle.id] != handle.generation {
    return None
  }
  let island_id = self.body_island_ids[handle.id]
  if island_id < 0 || island_id >= self.islands.length() {
    return None
  }
  if self.islands[island_id] is Some(_) {
    Some(island_id)
  } else {
    None
  }
}

///|
pub fn IslandManager::active_bodies(
  self : IslandManager,
) -> Array[RigidBodyHandle] {
  let result : Array[RigidBodyHandle] = []
  for i in 0..<self.awake_islands.length() {
    let island_id = self.awake_islands[i]
    if island_id >= 0 && island_id < self.islands.length() {
      if self.islands[island_id] is Some(island) {
        for j in 0..<island.bodies.length() {
          result.push(island.bodies[j])
        }
      }
    }
  }
  result
}

///|
pub fn IslandManager::wake_up(
  self : IslandManager,
  handle : RigidBodyHandle,
) -> Unit {
  if self.island_id_for(handle) is Some(island_id) {
    if self.islands[island_id] is Some(island) {
      if island.sleeping {
        island.sleeping = false
      }
      if island.id_in_awake_list is None {
        let index = self.awake_islands.length()
        island.id_in_awake_list = Some(index)
        self.awake_islands.push(island_id)
      }
      self.islands[island_id] = Some(island)
    }
  } else {
    self.insert_body(handle, false)
  }
}

///|
fn IslandManager::merge_islands(
  self : IslandManager,
  target_id : Int,
  source_id : Int,
) -> Unit {
  if target_id == source_id {
    return
  }
  if target_id < 0 || source_id < 0 {
    return
  }
  if target_id >= self.islands.length() || source_id >= self.islands.length() {
    return
  }
  if self.islands[target_id] is Some(target) &&
    self.islands[source_id] is Some(source) {
    let offset = target.bodies.length()
    for i in 0..<source.bodies.length() {
      let handle = source.bodies[i]
      target.bodies.push(handle)
      self.ensure_body_capacity(handle.id)
      self.body_island_ids[handle.id] = target_id
      self.body_island_generations[handle.id] = handle.generation
      self.body_island_indices[handle.id] = offset + i
    }
    let merged_sleeping = target.sleeping && source.sleeping
    target.sleeping = merged_sleeping
    self.remove_from_awake_list(source_id)
    self.islands[source_id] = None
    self.free_islands.push(source_id)
    self.islands[target_id] = Some(target)
    if merged_sleeping {
      self.remove_from_awake_list(target_id)
    } else if self.islands[target_id] is Some(updated) {
      if updated.id_in_awake_list is None {
        let index = self.awake_islands.length()
        updated.id_in_awake_list = Some(index)
        self.awake_islands.push(target_id)
        self.islands[target_id] = Some(updated)
      }
    }
  }
}

///|
pub fn IslandManager::interaction_started_or_stopped(
  self : IslandManager,
  bodies : RigidBodySet,
  handle1 : RigidBodyHandle?,
  handle2 : RigidBodyHandle?,
  started : Bool,
  wake_up : Bool,
) -> Unit {
  if wake_up {
    if handle1 is Some(value1) {
      self.wake_up(value1)
    }
    if handle2 is Some(value2) {
      self.wake_up(value2)
    }
  }
  if !started {
    return
  }
  if handle1 is Some(value1) && handle2 is Some(value2) {
    if bodies.get(value1) is Some(body1) && bodies.get(value2) is Some(body2) {
      if body1.is_dynamic_or_kinematic() && body2.is_dynamic_or_kinematic() {
        if self.island_id_for(value1) is Some(id1) &&
          self.island_id_for(value2) is Some(id2) {
          if id1 != id2 {
            self.merge_islands(id1, id2)
          }
        }
      }
    }
  }
}

///|
pub fn IslandManager::rigid_body_updated(
  self : IslandManager,
  handle : RigidBodyHandle,
  bodies : RigidBodySet,
) -> Unit {
  if bodies.get(handle) is Some(body) {
    if !body.is_dynamic_or_kinematic() {
      return
    }
    if self.island_id_for(handle) is Some(island_id) {
      if body.is_sleeping() {
        if self.islands[island_id] is Some(island) {
          if !island.sleeping {
            island.sleeping = true
            self.islands[island_id] = Some(island)
            self.remove_from_awake_list(island_id)
          }
        }
      } else {
        self.wake_up(handle)
      }
    } else {
      self.insert_body(handle, body.is_sleeping())
    }
  }
}

///|
pub struct ImpulseJoint {
  parent : RigidBodyHandle
  child : RigidBodyHandle
  joint : RevoluteJoint
  handle : ImpulseJointHandle
}

///|
pub struct ImpulseJointHandle {
  id : Int
  generation : Int
}

///|
fn ImpulseJointHandle::new(id : Int, generation : Int) -> ImpulseJointHandle {
  { id, generation }
}

///|
pub fn ImpulseJointHandle::from_raw_parts(
  id : Int,
  generation : Int,
) -> ImpulseJointHandle {
  ImpulseJointHandle::new(id, generation)
}

///|
pub fn ImpulseJointHandle::into_raw_parts(
  self : ImpulseJointHandle,
) -> (Int, Int) {
  (self.id, self.generation)
}

///|
pub fn ImpulseJointHandle::invalid() -> ImpulseJointHandle {
  ImpulseJointHandle::new(-1, -1)
}

///|
fn handle_equals(left : RigidBodyHandle, right : RigidBodyHandle) -> Bool {
  left.id == right.id && left.generation == right.generation
}

///|
fn handle_less(left : RigidBodyHandle, right : RigidBodyHandle) -> Bool {
  if left.id != right.id {
    left.id < right.id
  } else {
    left.generation < right.generation
  }
}

///|
fn push_unique_handle(
  values : Array[RigidBodyHandle],
  handle : RigidBodyHandle,
) -> Unit {
  for i in 0..<values.length() {
    if handle_equals(values[i], handle) {
      return
    }
  }
  values.push(handle)
}

///|
fn pair_equals(
  left : (RigidBodyHandle, RigidBodyHandle),
  right : (RigidBodyHandle, RigidBodyHandle),
) -> Bool {
  handle_equals(left.0, right.0) && handle_equals(left.1, right.1)
}

///|
fn push_unique_pair(
  values : Array[(RigidBodyHandle, RigidBodyHandle)],
  pair : (RigidBodyHandle, RigidBodyHandle),
) -> Unit {
  for i in 0..<values.length() {
    if pair_equals(values[i], pair) {
      return
    }
  }
  values.push(pair)
}

///|
fn canonical_pair(
  left : RigidBodyHandle,
  right : RigidBodyHandle,
) -> (RigidBodyHandle, RigidBodyHandle) {
  if handle_less(right, left) {
    (right, left)
  } else {
    (left, right)
  }
}

///|
priv struct JointGraphEdge {
  mut node1 : Int
  mut node2 : Int
  joint : ImpulseJoint
}

///|
fn remove_edge_index(values : Array[Int], target : Int) -> Unit {
  let mut index = -1
  for i in 0..<values.length() {
    if values[i] == target {
      index = i
      break
    }
  }
  if index < 0 {
    return
  }
  let last_index = values.length() - 1
  if index != last_index {
    values[index] = values[last_index]
  }
  values.pop() |> ignore
}

///|
fn replace_edge_index(
  values : Array[Int],
  old_index : Int,
  new_index : Int,
) -> Unit {
  for i in 0..<values.length() {
    if values[i] == old_index {
      values[i] = new_index
      return
    }
  }
}

///|
struct ImpulseJointSet {
  rb_graph_ids : Array[Int]
  rb_graph_generations : Array[Int]
  graph_nodes : Array[RigidBodyHandle]
  graph_edges : Array[JointGraphEdge]
  adjacency : Array[Array[Int]]
  joint_generations : Array[Int]
  joint_edge_ids : Array[Int]
  free_handles : Array[Int]
  to_wake_up : Array[RigidBodyHandle]
  to_join : Array[(RigidBodyHandle, RigidBodyHandle)]
}

///|
pub fn ImpulseJointSet::new() -> ImpulseJointSet {
  {
    rb_graph_ids: [],
    rb_graph_generations: [],
    graph_nodes: [],
    graph_edges: [],
    adjacency: [],
    joint_generations: [],
    joint_edge_ids: [],
    free_handles: [],
    to_wake_up: [],
    to_join: [],
  }
}

///|
fn ImpulseJointSet::ensure_body_mapping_capacity(
  self : ImpulseJointSet,
  id : Int,
) -> Unit {
  if id < 0 {
    return
  }
  let mut i = self.rb_graph_ids.length()
  while i <= id {
    self.rb_graph_ids.push(-1)
    self.rb_graph_generations.push(0)
    i = i + 1
  }
}

///|
fn ImpulseJointSet::graph_node_for(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Int? {
  if handle.id < 0 || handle.id >= self.rb_graph_ids.length() {
    return None
  }
  let node_id = self.rb_graph_ids[handle.id]
  if node_id < 0 || node_id >= self.graph_nodes.length() {
    return None
  }
  if self.rb_graph_generations[handle.id] != handle.generation {
    return None
  }
  if !handle_equals(self.graph_nodes[node_id], handle) {
    return None
  }
  Some(node_id)
}

///|
fn ImpulseJointSet::ensure_graph_node(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Int {
  self.ensure_body_mapping_capacity(handle.id)
  if self.graph_node_for(handle) is Some(node_id) {
    node_id
  } else {
    let node_id = self.graph_nodes.length()
    self.graph_nodes.push(handle)
    self.adjacency.push([])
    self.rb_graph_ids[handle.id] = node_id
    self.rb_graph_generations[handle.id] = handle.generation
    node_id
  }
}

///|
fn ImpulseJointSet::allocate_joint_handle(
  self : ImpulseJointSet,
) -> ImpulseJointHandle {
  if self.free_handles.pop() is Some(index) {
    let generation = self.joint_generations[index]
    ImpulseJointHandle::new(index, generation)
  } else {
    let index = self.joint_generations.length()
    self.joint_generations.push(0)
    self.joint_edge_ids.push(-1)
    ImpulseJointHandle::new(index, 0)
  }
}

///|
fn ImpulseJointSet::is_handle_valid(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
) -> Bool {
  if handle.id < 0 || handle.id >= self.joint_generations.length() {
    return false
  }
  if self.joint_generations[handle.id] != handle.generation {
    return false
  }
  let edge_id = self.joint_edge_ids[handle.id]
  edge_id >= 0 && edge_id < self.graph_edges.length()
}

///|
fn ImpulseJointSet::remove_edge(
  self : ImpulseJointSet,
  edge_id : Int,
) -> ImpulseJoint? {
  if edge_id < 0 || edge_id >= self.graph_edges.length() {
    return None
  }
  let removed_edge = self.graph_edges[edge_id]
  remove_edge_index(self.adjacency[removed_edge.node1], edge_id)
  if removed_edge.node2 != removed_edge.node1 {
    remove_edge_index(self.adjacency[removed_edge.node2], edge_id)
  }
  let last_index = self.graph_edges.length() - 1
  if edge_id != last_index {
    let moved_edge = self.graph_edges[last_index]
    self.graph_edges[edge_id] = moved_edge
    replace_edge_index(self.adjacency[moved_edge.node1], last_index, edge_id)
    if moved_edge.node2 != moved_edge.node1 {
      replace_edge_index(self.adjacency[moved_edge.node2], last_index, edge_id)
    }
    let handle_id = moved_edge.joint.handle.id
    if handle_id >= 0 && handle_id < self.joint_edge_ids.length() {
      self.joint_edge_ids[handle_id] = edge_id
    }
  }
  self.graph_edges.pop() |> ignore
  Some(removed_edge.joint)
}

///|
fn ImpulseJointSet::remove_node(self : ImpulseJointSet, node_id : Int) -> Unit {
  if node_id < 0 || node_id >= self.graph_nodes.length() {
    return
  }
  let removed_handle = self.graph_nodes[node_id]
  if removed_handle.id >= 0 && removed_handle.id < self.rb_graph_ids.length() {
    self.rb_graph_ids[removed_handle.id] = -1
  }
  let last_index = self.graph_nodes.length() - 1
  if node_id != last_index {
    let moved_handle = self.graph_nodes[last_index]
    self.graph_nodes[node_id] = moved_handle
    self.adjacency[node_id] = self.adjacency[last_index]
    if moved_handle.id >= 0 && moved_handle.id < self.rb_graph_ids.length() {
      self.rb_graph_ids[moved_handle.id] = node_id
      self.rb_graph_generations[moved_handle.id] = moved_handle.generation
    }
    let edges = self.adjacency[node_id]
    for i in 0..<edges.length() {
      let edge_id = edges[i]
      if edge_id >= 0 && edge_id < self.graph_edges.length() {
        let edge = self.graph_edges[edge_id]
        if edge.node1 == last_index {
          edge.node1 = node_id
        }
        if edge.node2 == last_index {
          edge.node2 = node_id
        }
        self.graph_edges[edge_id] = edge
      }
    }
  }
  self.graph_nodes.pop() |> ignore
  self.adjacency.pop() |> ignore
}

///|
pub fn ImpulseJointSet::insert(
  self : ImpulseJointSet,
  parent : RigidBodyHandle,
  child : RigidBodyHandle,
  joint : RevoluteJoint,
  wake_up : Bool,
) -> ImpulseJointHandle {
  let handle = self.allocate_joint_handle()
  if parent.id < 0 || child.id < 0 {
    return handle
  }
  let node1 = self.ensure_graph_node(parent)
  let node2 = self.ensure_graph_node(child)
  let impulse_joint = ImpulseJoint::{ parent, child, joint, handle }
  let edge_id = self.graph_edges.length()
  self.graph_edges.push(JointGraphEdge::{ node1, node2, joint: impulse_joint })
  self.adjacency[node1].push(edge_id)
  if node2 != node1 {
    self.adjacency[node2].push(edge_id)
  }
  self.joint_edge_ids[handle.id] = edge_id
  if wake_up {
    push_unique_handle(self.to_wake_up, parent)
    push_unique_handle(self.to_wake_up, child)
  }
  let pair = canonical_pair(parent, child)
  push_unique_pair(self.to_join, pair)
  handle
}

///|
pub fn ImpulseJointSet::len(self : ImpulseJointSet) -> Int {
  self.graph_edges.length()
}

///|
pub fn ImpulseJointSet::is_empty(self : ImpulseJointSet) -> Bool {
  self.graph_edges.length() == 0
}

///|
pub fn ImpulseJointSet::contains(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
) -> Bool {
  self.is_handle_valid(handle)
}

///|
pub fn ImpulseJointSet::get(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
) -> ImpulseJoint? {
  if !self.is_handle_valid(handle) {
    return None
  }
  let edge_id = self.joint_edge_ids[handle.id]
  if edge_id < 0 || edge_id >= self.graph_edges.length() {
    return None
  }
  Some(self.graph_edges[edge_id].joint)
}

///|
pub fn ImpulseJointSet::remove(
  self : ImpulseJointSet,
  handle : ImpulseJointHandle,
  wake_up : Bool,
) -> ImpulseJoint? {
  if !self.is_handle_valid(handle) {
    return None
  }
  let edge_id = self.joint_edge_ids[handle.id]
  let removed = self.remove_edge(edge_id)
  if removed is Some(joint) {
    self.joint_edge_ids[handle.id] = -1
    self.joint_generations[handle.id] = self.joint_generations[handle.id] + 1
    self.free_handles.push(handle.id)
    if wake_up {
      push_unique_handle(self.to_wake_up, joint.parent)
      push_unique_handle(self.to_wake_up, joint.child)
    }
    Some(joint)
  } else {
    None
  }
}

///|
pub fn ImpulseJointSet::remove_joints_attached_to_rigid_body(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Array[ImpulseJointHandle] {
  if self.graph_node_for(handle) is Some(node_index) {
    let to_remove : Array[ImpulseJointHandle] = []
    let edges = self.adjacency[node_index]
    for i in 0..<edges.length() {
      let edge_id = edges[i]
      if edge_id >= 0 && edge_id < self.graph_edges.length() {
        to_remove.push(self.graph_edges[edge_id].joint.handle)
      }
    }
    let removed : Array[ImpulseJointHandle] = []
    for i in 0..<to_remove.length() {
      let handle_to_remove = to_remove[i]
      if self.remove(handle_to_remove, true) is Some(_) {
        removed.push(handle_to_remove)
      }
    }
    if self.graph_node_for(handle) is Some(updated_node) {
      if self.adjacency[updated_node].length() == 0 {
        self.remove_node(updated_node)
      }
    }
    removed
  } else {
    []
  }
}

///|
pub fn ImpulseJointSet::attached_joints(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Array[ImpulseJoint] {
  if self.graph_node_for(handle) is Some(node_index) {
    let result : Array[ImpulseJoint] = []
    let edges = self.adjacency[node_index]
    for i in 0..<edges.length() {
      let edge_id = edges[i]
      if edge_id >= 0 && edge_id < self.graph_edges.length() {
        result.push(self.graph_edges[edge_id].joint)
      }
    }
    result
  } else {
    []
  }
}

///|
pub fn ImpulseJointSet::joints_between(
  self : ImpulseJointSet,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> Array[ImpulseJoint] {
  if self.graph_node_for(body1) is Some(node1_index) &&
    self.graph_node_for(body2) is Some(node2_index) {
    let result : Array[ImpulseJoint] = []
    let edges = self.adjacency[node1_index]
    for i in 0..<edges.length() {
      let edge_id = edges[i]
      if edge_id >= 0 && edge_id < self.graph_edges.length() {
        let edge = self.graph_edges[edge_id]
        if edge.node1 == node2_index || edge.node2 == node2_index {
          result.push(edge.joint)
        }
      }
    }
    result
  } else {
    []
  }
}
