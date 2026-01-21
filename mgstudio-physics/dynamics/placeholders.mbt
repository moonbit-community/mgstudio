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
}

///|
pub fn IslandManager::new() -> IslandManager {
  {
    islands: [],
    awake_islands: [],
    free_islands: [],
    traversal_candidates: [],
    traversal_timestamp: 0,
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
    let island_id = self.insert_island(island)
    self.awake_islands.push(island_id)
  } else {
    self.insert_island(island) |> ignore
  }
}

///|
fn IslandManager::remove_body(
  self : IslandManager,
  handle : RigidBodyHandle,
) -> Unit {
  for i in 0..<self.islands.length() {
    if self.islands[i] is Some(island) {
      if island.remove_body(handle) {
        if island.bodies.length() == 0 {
          self.remove_from_awake_list(i)
          self.islands[i] = None
          self.free_islands.push(i)
        } else {
          self.islands[i] = Some(island)
        }
        return
      }
    }
  }
}

///|
fn IslandManager::island_id_for(
  self : IslandManager,
  handle : RigidBodyHandle,
) -> Int? {
  for i in 0..<self.islands.length() {
    if self.islands[i] is Some(island) && island.contains(handle) {
      return Some(i)
    }
  }
  None
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
    for i in 0..<source.bodies.length() {
      target.bodies.push(source.bodies[i])
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
}

///|
priv struct ImpulseJointHandle {
  id : Int
  generation : Int
}

///|
fn ImpulseJointHandle::new(id : Int, generation : Int) -> ImpulseJointHandle {
  { id, generation }
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
fn filter_out_joint(values : Array[Int], target : Int) -> Array[Int] {
  let filtered : Array[Int] = []
  for i in 0..<values.length() {
    let value = values[i]
    if value != target {
      filtered.push(value)
    }
  }
  filtered
}

///|
fn ensure_body_capacity(values : Array[Array[Int]], id : Int) -> Unit {
  if id < 0 {
    return
  }
  let mut i = values.length()
  while i <= id {
    values.push([])
    i = i + 1
  }
}

///|
fn ImpulseJointSet::allocate_joint_handle(
  self : ImpulseJointSet,
) -> ImpulseJointHandle {
  if self.free_list.pop() is Some(index) {
    let generation = self.generations[index]
    ImpulseJointHandle::new(index, generation)
  } else {
    let index = self.joints.length()
    self.joints.push(None)
    self.generations.push(0)
    ImpulseJointHandle::new(index, 0)
  }
}

///|
fn ImpulseJointSet::remove_joint(
  self : ImpulseJointSet,
  joint_id : Int,
) -> Unit {
  if joint_id < 0 || joint_id >= self.joints.length() {
    return
  }
  if self.joints[joint_id] is Some(joint) {
    let parent_id = joint.parent.id
    let child_id = joint.child.id
    if parent_id >= 0 && parent_id < self.adjacency.length() {
      self.adjacency[parent_id] = filter_out_joint(
        self.adjacency[parent_id],
        joint_id,
      )
    }
    if child_id >= 0 && child_id < self.adjacency.length() {
      self.adjacency[child_id] = filter_out_joint(
        self.adjacency[child_id],
        joint_id,
      )
    }
    self.joints[joint_id] = None
    self.generations[joint_id] = self.generations[joint_id] + 1
    self.free_list.push(joint_id)
  }
}

///|
fn ImpulseJointSet::remove_joints_attached_to_rigid_body(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Unit {
  if handle.id < 0 || handle.id >= self.adjacency.length() {
    return
  }
  let to_remove : Array[Int] = []
  let adjacency = self.adjacency[handle.id]
  for i in 0..<adjacency.length() {
    to_remove.push(adjacency[i])
  }
  for i in 0..<to_remove.length() {
    self.remove_joint(to_remove[i])
  }
  self.adjacency[handle.id] = []
}

///|
pub struct ImpulseJointSet {
  joints : Array[ImpulseJoint?]
  generations : Array[Int]
  free_list : Array[Int]
  adjacency : Array[Array[Int]]
  to_wake_up : Array[RigidBodyHandle]
  to_join : Array[(RigidBodyHandle, RigidBodyHandle)]
}

///|
pub fn ImpulseJointSet::new() -> ImpulseJointSet {
  {
    joints: [],
    generations: [],
    free_list: [],
    adjacency: [],
    to_wake_up: [],
    to_join: [],
  }
}

///|
pub fn ImpulseJointSet::insert(
  self : ImpulseJointSet,
  parent : RigidBodyHandle,
  child : RigidBodyHandle,
  joint : RevoluteJoint,
  wake_up : Bool,
) -> Unit {
  if parent.id < 0 || child.id < 0 {
    return
  }
  let handle = self.allocate_joint_handle()
  self.joints[handle.id] = Some(ImpulseJoint::{ parent, child, joint })
  ensure_body_capacity(self.adjacency, parent.id)
  ensure_body_capacity(self.adjacency, child.id)
  self.adjacency[parent.id].push(handle.id)
  self.adjacency[child.id].push(handle.id)
  if wake_up {
    push_unique_handle(self.to_wake_up, parent)
    push_unique_handle(self.to_wake_up, child)
    let pair = canonical_pair(parent, child)
    push_unique_pair(self.to_join, pair)
  }
}

///|
pub fn ImpulseJointSet::len(self : ImpulseJointSet) -> Int {
  let mut count = 0
  for i in 0..<self.joints.length() {
    if self.joints[i] is Some(_) {
      count = count + 1
    }
  }
  count
}

///|
pub fn ImpulseJointSet::is_empty(self : ImpulseJointSet) -> Bool {
  self.len() == 0
}

///|
pub fn ImpulseJointSet::attached_joints(
  self : ImpulseJointSet,
  handle : RigidBodyHandle,
) -> Array[ImpulseJoint] {
  if handle.id < 0 || handle.id >= self.adjacency.length() {
    return []
  }
  let result : Array[ImpulseJoint] = []
  let adjacency = self.adjacency[handle.id]
  for i in 0..<adjacency.length() {
    let joint_id = adjacency[i]
    if joint_id >= 0 && joint_id < self.joints.length() {
      if self.joints[joint_id] is Some(joint) {
        result.push(joint)
      }
    }
  }
  result
}

///|
pub fn ImpulseJointSet::joints_between(
  self : ImpulseJointSet,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> Array[ImpulseJoint] {
  if body1.id < 0 || body2.id < 0 {
    return []
  }
  if body1.id >= self.adjacency.length() || body2.id >= self.adjacency.length() {
    return []
  }
  let result : Array[ImpulseJoint] = []
  let adjacency = self.adjacency[body1.id]
  for i in 0..<adjacency.length() {
    let joint_id = adjacency[i]
    if joint_id >= 0 && joint_id < self.joints.length() {
      if self.joints[joint_id] is Some(joint) {
        let matches = handle_equals(joint.parent, body2) ||
          handle_equals(joint.child, body2)
        if matches {
          result.push(joint)
        }
      }
    }
  }
  result
}
