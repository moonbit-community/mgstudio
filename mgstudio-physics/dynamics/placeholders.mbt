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

struct Island {
  bodies : Array[RigidBodyHandle]
  mut id_in_awake_list : Int?
  sleeping : Bool
}

fn Island::new(handle : RigidBodyHandle, sleeping : Bool) -> Island {
  { bodies: [handle], id_in_awake_list: None, sleeping }
}

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

fn IslandManager::remove_from_awake_list(self : IslandManager, island_id : Int) -> Unit {
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

fn IslandManager::remove_body(self : IslandManager, handle : RigidBodyHandle) -> Unit {
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

struct ImpulseJoint {
  parent : RigidBodyHandle
  child : RigidBodyHandle
  joint : RevoluteJoint
}

priv struct ImpulseJointHandle {
  id : Int
  generation : Int
}

fn ImpulseJointHandle::new(id : Int, generation : Int) -> ImpulseJointHandle {
  { id, generation }
}

fn handle_equals(left : RigidBodyHandle, right : RigidBodyHandle) -> Bool {
  left.id == right.id && left.generation == right.generation
}

fn handle_less(left : RigidBodyHandle, right : RigidBodyHandle) -> Bool {
  if left.id != right.id {
    left.id < right.id
  } else {
    left.generation < right.generation
  }
}

fn push_unique_handle(values : Array[RigidBodyHandle], handle : RigidBodyHandle) -> Unit {
  for i in 0..<values.length() {
    if handle_equals(values[i], handle) {
      return
    }
  }
  values.push(handle)
}

fn pair_equals(
  left : (RigidBodyHandle, RigidBodyHandle),
  right : (RigidBodyHandle, RigidBodyHandle),
) -> Bool {
  handle_equals(left.0, right.0) && handle_equals(left.1, right.1)
}

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

fn ImpulseJointSet::allocate_joint_handle(self : ImpulseJointSet) -> ImpulseJointHandle {
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

fn ImpulseJointSet::remove_joint(self : ImpulseJointSet, joint_id : Int) -> Unit {
  if joint_id < 0 || joint_id >= self.joints.length() {
    return
  }
  if self.joints[joint_id] is Some(joint) {
    let parent_id = joint.parent.id
    let child_id = joint.child.id
    if parent_id >= 0 && parent_id < self.adjacency.length() {
      self.adjacency[parent_id] = filter_out_joint(self.adjacency[parent_id], joint_id)
    }
    if child_id >= 0 && child_id < self.adjacency.length() {
      self.adjacency[child_id] = filter_out_joint(self.adjacency[child_id], joint_id)
    }
    self.joints[joint_id] = None
    self.generations[joint_id] = self.generations[joint_id] + 1
    self.free_list.push(joint_id)
  }
}

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
  self.joints[handle.id] = Some(ImpulseJoint::{parent, child, joint})
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
