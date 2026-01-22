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
const DEFAULT_SLEEP_LINEAR_THRESHOLD : @core.Real = 0.4F

///|
const DEFAULT_SLEEP_ANGULAR_THRESHOLD : @core.Real = 0.5F

///|
const DEFAULT_TIME_UNTIL_SLEEP : @core.Real = 2.0F

///|
const MAX_SLEEP_TRAVERSAL_COST : Int = 1000

///|
const MIN_ISLAND_SIZE : Int = 1024

///|
const MAX_ISLAND_SIZE : Int = 4096

///|
struct Island {
  bodies : Array[RigidBodyHandle]
  mut id_in_awake_list : Int?
  mut sleeping : Bool
  mut additional_solver_iterations : Int
}

///|
fn Island::new(
  handle : RigidBodyHandle,
  sleeping : Bool,
  additional_solver_iterations : Int,
) -> Island {
  {
    bodies: [handle],
    id_in_awake_list: None,
    sleeping,
    additional_solver_iterations,
  }
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
pub struct ContactGraph {
  pairs : Array[(RigidBodyHandle, RigidBodyHandle)]
}

///|
pub fn ContactGraph::new() -> ContactGraph {
  { pairs: [] }
}

///|
pub fn ContactGraph::clear(self : ContactGraph) -> Unit {
  self.pairs.clear()
}

///|
pub fn ContactGraph::add_pair(
  self : ContactGraph,
  body1 : RigidBodyHandle,
  body2 : RigidBodyHandle,
) -> Unit {
  self.pairs.push((body1, body2))
}

///|
enum SleepRootState {
  Unknown
  TraversalPending
  Traversed
}

///|
struct IslandsOptimizerMergeState {
  mut curr_awake_id : Int
}

///|
struct IslandsOptimizerSplitState {
  mut curr_awake_id : Int
}

///|
struct IslandsOptimizer {
  mut min_island_size : Int
  mut max_island_size : Int
  mut mode : Int
  merge_state : IslandsOptimizerMergeState
  split_state : IslandsOptimizerSplitState
}

///|
fn IslandsOptimizer::new() -> IslandsOptimizer {
  {
    min_island_size: MIN_ISLAND_SIZE,
    max_island_size: MAX_ISLAND_SIZE,
    mode: 0,
    merge_state: IslandsOptimizerMergeState::{ curr_awake_id: 0 },
    split_state: IslandsOptimizerSplitState::{ curr_awake_id: 0 },
  }
}

///|
pub struct IslandManager {
  islands : Array[Island?]
  awake_islands : Array[Int]
  free_islands : Array[Int]
  traversal_candidates : Array[SleepCandidate]
  mut traversal_timestamp : Int
  optimizer : IslandsOptimizer
  stack : Array[RigidBodyHandle]
  body_island_ids : Array[Int]
  body_island_generations : Array[Int]
  body_island_indices : Array[Int]
  body_sleep_states : Array[SleepRootState]
  body_sleep_timers : Array[@core.Real]
  body_active_timestamps : Array[Int]
  body_state_generations : Array[Int]
  body_last_translation_x : Array[@core.Real]
  body_last_translation_y : Array[@core.Real]
  body_last_rotation : Array[@core.Real]
  body_has_pose : Array[Bool]
}

///|
pub fn IslandManager::new() -> IslandManager {
  {
    islands: [],
    awake_islands: [],
    free_islands: [],
    traversal_candidates: [],
    traversal_timestamp: 0,
    optimizer: IslandsOptimizer::new(),
    stack: [],
    body_island_ids: [],
    body_island_generations: [],
    body_island_indices: [],
    body_sleep_states: [],
    body_sleep_timers: [],
    body_active_timestamps: [],
    body_state_generations: [],
    body_last_translation_x: [],
    body_last_translation_y: [],
    body_last_rotation: [],
    body_has_pose: [],
  }
}

///|
fn IslandManager::set_island_size_limits(
  self : IslandManager,
  min_island_size : Int,
  max_island_size : Int,
) -> Unit {
  self.optimizer.min_island_size = min_island_size
  self.optimizer.max_island_size = max_island_size
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
    self.body_sleep_states.push(SleepRootState::Unknown)
    self.body_sleep_timers.push(0.0F)
    self.body_active_timestamps.push(0)
    self.body_state_generations.push(0)
    self.body_last_translation_x.push(0.0F)
    self.body_last_translation_y.push(0.0F)
    self.body_last_rotation.push(0.0F)
    self.body_has_pose.push(false)
    i = i + 1
  }
}

///|
fn IslandManager::reset_body_sleep_state(
  self : IslandManager,
  handle : RigidBodyHandle,
) -> Unit {
  if handle.id < 0 {
    return
  }
  self.ensure_body_capacity(handle.id)
  self.body_sleep_states[handle.id] = SleepRootState::Unknown
  self.body_sleep_timers[handle.id] = 0.0F
  self.body_active_timestamps[handle.id] = 0
  self.body_last_translation_x[handle.id] = 0.0F
  self.body_last_translation_y[handle.id] = 0.0F
  self.body_last_rotation[handle.id] = 0.0F
  self.body_has_pose[handle.id] = false
  self.body_state_generations[handle.id] = handle.generation
}

///|
fn IslandManager::wake_up_body(
  self : IslandManager,
  bodies : RigidBodySet,
  handle : RigidBodyHandle,
  strong : Bool,
) -> Unit {
  if handle.id < 0 {
    return
  }
  self.sync_body_state_generation(handle)
  if bodies.get_mut(handle) is Some(body) {
    if !body.is_dynamic_or_kinematic() {
      return
    }
    body.sleeping = false
  } else {
    return
  }
  if !(self.body_sleep_states[handle.id] is SleepRootState::TraversalPending) {
    self.body_sleep_states[handle.id] = SleepRootState::Unknown
  }
  if strong {
    self.body_sleep_timers[handle.id] = 0.0F
  }
}

///|
fn IslandManager::sync_body_state_generation(
  self : IslandManager,
  handle : RigidBodyHandle,
) -> Unit {
  if handle.id < 0 {
    return
  }
  self.ensure_body_capacity(handle.id)
  if self.body_state_generations[handle.id] != handle.generation {
    self.reset_body_sleep_state(handle)
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
      island_value.sleeping = true
      self.islands[island_id] = Some(island_value)
    }
  }
}

///|
fn IslandManager::insert_body(
  self : IslandManager,
  bodies : RigidBodySet,
  handle : RigidBodyHandle,
  sleeping : Bool,
) -> Unit {
  self.reset_body_sleep_state(handle)
  let mut additional_solver_iterations = 0
  if bodies.get(handle) is Some(body) {
    additional_solver_iterations = body.additional_solver_iterations
  }
  let island = Island::new(handle, sleeping, additional_solver_iterations)
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
          self.body_island_ids[moved_handle.id] = island_id
          self.body_island_generations[moved_handle.id] = moved_handle.generation
          self.body_island_indices[moved_handle.id] = body_index
        }
      }
      island.bodies.pop() |> ignore
      if handle.id >= 0 && handle.id < self.body_island_ids.length() {
        self.body_island_ids[handle.id] = -1
        self.body_island_indices[handle.id] = -1
        self.body_island_generations[handle.id] = handle.generation
        self.reset_body_sleep_state(handle)
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
fn is_dynamic_or_kinematic_body(
  bodies : RigidBodySet,
  handle : RigidBodyHandle,
) -> Bool {
  if bodies.get(handle) is Some(body) {
    body.is_dynamic_or_kinematic()
  } else {
    false
  }
}

///|
fn handle_in_list(
  values : Array[RigidBodyHandle],
  handle : RigidBodyHandle,
) -> Bool {
  for i in 0..<values.length() {
    if handle_equals(values[i], handle) {
      return true
    }
  }
  false
}

///|
fn truncate_handles(values : Array[RigidBodyHandle], len : Int) -> Unit {
  while values.length() > len {
    values.pop() |> ignore
  }
}

///|
fn IslandManager::is_body_eligible_for_sleep(
  self : IslandManager,
  handle : RigidBodyHandle,
  body : RigidBody,
) -> Bool {
  if !body.can_sleep {
    return false
  }
  self.sync_body_state_generation(handle)
  self.body_sleep_timers[handle.id] >= DEFAULT_TIME_UNTIL_SLEEP
}

///|
fn IslandManager::update_body_sleep_timer(
  self : IslandManager,
  handle : RigidBodyHandle,
  body : RigidBody,
  dt : @core.Real,
  length_unit : @core.Real,
) -> Bool {
  self.sync_body_state_generation(handle)
  if !body.can_sleep {
    self.body_sleep_timers[handle.id] = 0.0F
    self.body_sleep_states[handle.id] = SleepRootState::Unknown
    self.body_has_pose[handle.id] = false
    return false
  }
  let pos = body.translation()
  let rot = body.rotation().angle()
  if !self.body_has_pose[handle.id] || dt <= 0.0F {
    self.body_last_translation_x[handle.id] = pos.x
    self.body_last_translation_y[handle.id] = pos.y
    self.body_last_rotation[handle.id] = rot
    self.body_has_pose[handle.id] = true
    self.body_sleep_timers[handle.id] = 0.0F
    return false
  }
  let dx = pos.x - self.body_last_translation_x[handle.id]
  let dy = pos.y - self.body_last_translation_y[handle.id]
  let drot = rot - self.body_last_rotation[handle.id]
  let inv_dt = 1.0F / dt
  let sq_linvel = dx * inv_dt * (dx * inv_dt) + dy * inv_dt * (dy * inv_dt)
  let sq_angvel = drot * inv_dt * (drot * inv_dt)
  let can_sleep_now = match body.body_type {
    RigidBodyType::Dynamic => {
      let linear_threshold = DEFAULT_SLEEP_LINEAR_THRESHOLD * length_unit
      sq_linvel < linear_threshold * linear_threshold &&
      sq_angvel <
      DEFAULT_SLEEP_ANGULAR_THRESHOLD * DEFAULT_SLEEP_ANGULAR_THRESHOLD
    }
    RigidBodyType::KinematicPositionBased =>
      sq_linvel == 0.0F && sq_angvel == 0.0F
    RigidBodyType::Fixed => true
  }
  if can_sleep_now {
    self.body_sleep_timers[handle.id] = self.body_sleep_timers[handle.id] + dt
  } else {
    self.body_sleep_timers[handle.id] = 0.0F
  }
  self.body_last_translation_x[handle.id] = pos.x
  self.body_last_translation_y[handle.id] = pos.y
  self.body_last_rotation[handle.id] = rot
  self.body_has_pose[handle.id] = true
  self.body_sleep_timers[handle.id] >= DEFAULT_TIME_UNTIL_SLEEP
}

///|
fn IslandManager::push_contacting_bodies(
  self : IslandManager,
  bodies : RigidBodySet,
  contacts : ContactGraph,
  handle : RigidBodyHandle,
) -> Unit {
  for i in 0..<contacts.pairs.length() {
    let pair = contacts.pairs[i]
    if handle_equals(pair.0, handle) &&
      is_dynamic_or_kinematic_body(bodies, pair.1) {
      self.stack.push(pair.1)
    } else if handle_equals(pair.1, handle) &&
      is_dynamic_or_kinematic_body(bodies, pair.0) {
      self.stack.push(pair.0)
    }
  }
}

///|
fn IslandManager::push_linked_bodies(
  self : IslandManager,
  bodies : RigidBodySet,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
  handle : RigidBodyHandle,
) -> Unit {
  let attached = impulse_joints.attached_joints(handle)
  for i in 0..<attached.length() {
    let joint = attached[i]
    let other = if handle_equals(joint.parent, handle) {
      joint.child
    } else {
      joint.parent
    }
    if is_dynamic_or_kinematic_body(bodies, other) {
      self.stack.push(other)
    }
  }
  if handle.id >= 0 && handle.id < multibody_joints.body_links.length() {
    if multibody_joints.body_links[handle.id] is Some(info) {
      if info.mb_index >= 0 &&
        info.mb_index < multibody_joints.multibodies.length() {
        let multibody = multibody_joints.multibodies[info.mb_index]
        for i in 0..<multibody.links.length() {
          let link = multibody.links[i]
          if !handle_equals(link.rigid_body, handle) &&
            is_dynamic_or_kinematic_body(bodies, link.rigid_body) {
            self.stack.push(link.rigid_body)
          }
        }
      }
    }
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
fn IslandManager::wake_up_island(
  self : IslandManager,
  bodies : RigidBodySet,
  island_id : Int,
) -> Unit {
  if island_id < 0 || island_id >= self.islands.length() {
    return
  }
  if self.islands[island_id] is Some(island) {
    if island.id_in_awake_list is None {
      let index = self.awake_islands.length()
      island.id_in_awake_list = Some(index)
      self.awake_islands.push(island_id)
      island.sleeping = false
      for i in 0..<island.bodies.length() {
        self.wake_up_body(bodies, island.bodies[i], false)
      }
    } else if island.sleeping {
      island.sleeping = false
    }
    self.islands[island_id] = Some(island)
  }
}

///|
pub fn IslandManager::wake_up(
  self : IslandManager,
  bodies : RigidBodySet,
  handle : RigidBodyHandle,
  strong : Bool,
) -> Unit {
  if !is_dynamic_or_kinematic_body(bodies, handle) {
    return
  }
  if self.island_id_for(handle) is Some(island_id) {
    self.wake_up_island(bodies, island_id)
  } else {
    self.insert_body(bodies, handle, false)
  }
  self.wake_up_body(bodies, handle, strong)
}

///|
fn IslandManager::merge_islands(
  self : IslandManager,
  bodies : RigidBodySet,
  island_id1 : Int,
  island_id2 : Int,
) -> Unit {
  if island_id1 == island_id2 {
    return
  }
  if island_id1 < 0 || island_id2 < 0 {
    return
  }
  if island_id1 >= self.islands.length() || island_id2 >= self.islands.length() {
    return
  }
  if self.islands[island_id1] is Some(island1) &&
    self.islands[island_id2] is Some(island2) {
    let sleeping1 = island1.id_in_awake_list is None
    let sleeping2 = island2.id_in_awake_list is None
    if sleeping1 != sleeping2 {
      return
    }
    let (keep_id, remove_id) = if island1.bodies.length() <
      island2.bodies.length() {
      (island_id2, island_id1)
    } else {
      (island_id1, island_id2)
    }
    let keep = if keep_id == island_id1 { island1 } else { island2 }
    let remove = if remove_id == island_id1 { island1 } else { island2 }
    let mut next_index = keep.bodies.length()
    for i in 0..<remove.bodies.length() {
      let handle = remove.bodies[i]
      if bodies.get(handle) is Some(body) {
        if !sleeping1 {
          self.wake_up_body(bodies, handle, false)
        }
        keep.bodies.push(handle)
        if body.additional_solver_iterations > keep.additional_solver_iterations {
          keep.additional_solver_iterations = body.additional_solver_iterations
        }
        self.ensure_body_capacity(handle.id)
        self.body_island_ids[handle.id] = keep_id
        self.body_island_generations[handle.id] = handle.generation
        self.body_island_indices[handle.id] = next_index
        next_index = next_index + 1
      }
    }
    if remove.id_in_awake_list is Some(_) {
      self.remove_from_awake_list(remove_id)
    }
    if sleeping1 {
      keep.id_in_awake_list = None
      keep.sleeping = true
    } else {
      if self.islands[keep_id] is Some(updated_keep) {
        keep.id_in_awake_list = updated_keep.id_in_awake_list
      }
      keep.sleeping = false
    }
    self.islands[remove_id] = None
    self.free_islands.push(remove_id)
    self.islands[keep_id] = Some(keep)
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
      self.wake_up(bodies, value1, false)
    }
    if handle2 is Some(value2) {
      self.wake_up(bodies, value2, false)
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
            self.merge_islands(bodies, id1, id2)
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
    self.sync_body_state_generation(handle)
    if !body.is_dynamic_or_kinematic() {
      return
    }
    if self.island_id_for(handle) is Some(island_id) {
      if !body.is_sleeping() {
        if self.islands[island_id] is Some(island) {
          if island.id_in_awake_list is None {
            self.wake_up(bodies, handle, false)
          }
        }
      }
    } else if !body.is_sleeping() {
      let mut target_id = -1
      if self.awake_islands.length() > 0 {
        let last_id = self.awake_islands[self.awake_islands.length() - 1]
        if self.islands[last_id] is Some(island) {
          if island.bodies.length() < self.optimizer.min_island_size &&
            island.id_in_awake_list is Some(_) {
            target_id = last_id
          }
        }
      }
      if target_id >= 0 {
        if self.islands[target_id] is Some(island) {
          let index = island.bodies.length()
          island.bodies.push(handle)
          self.islands[target_id] = Some(island)
          self.ensure_body_capacity(handle.id)
          self.body_island_ids[handle.id] = target_id
          self.body_island_generations[handle.id] = handle.generation
          self.body_island_indices[handle.id] = index
        }
      } else {
        self.insert_body(bodies, handle, false)
      }
    } else {
      self.insert_body(bodies, handle, true)
    }
  }
}

///|
fn IslandManager::extract_sub_island(
  self : IslandManager,
  bodies : RigidBodySet,
  island_id : Int,
  extracted : Array[RigidBodyHandle],
  sleeping : Bool,
) -> Unit {
  if island_id < 0 || island_id >= self.islands.length() {
    return
  }
  if extracted.length() == 0 {
    return
  }
  if self.islands[island_id] is Some(island) {
    let new_island_id = self.insert_island(Island::{
      bodies: [],
      id_in_awake_list: None,
      sleeping,
      additional_solver_iterations: 0,
    })
    let new_island_bodies : Array[RigidBodyHandle] = []
    let mut additional_solver_iterations = 0
    for i in 0..<extracted.length() {
      let handle = extracted[i]
      let mut body_index = -1
      if handle.id >= 0 && handle.id < self.body_island_ids.length() {
        if self.body_island_generations[handle.id] == handle.generation &&
          self.body_island_ids[handle.id] == island_id {
          body_index = self.body_island_indices[handle.id]
        }
      }
      if body_index < 0 ||
        body_index >= island.bodies.length() ||
        !handle_equals(island.bodies[body_index], handle) {
        body_index = -1
        for j in 0..<island.bodies.length() {
          if handle_equals(island.bodies[j], handle) {
            body_index = j
            break
          }
        }
      }
      if body_index < 0 {
        continue
      }
      let last_index = island.bodies.length() - 1
      if body_index != last_index {
        let moved_handle = island.bodies[last_index]
        island.bodies[body_index] = moved_handle
        if moved_handle.id >= 0 &&
          moved_handle.id < self.body_island_indices.length() {
          self.body_island_ids[moved_handle.id] = island_id
          self.body_island_generations[moved_handle.id] = moved_handle.generation
          self.body_island_indices[moved_handle.id] = body_index
        }
      }
      island.bodies.pop() |> ignore
      let new_index = new_island_bodies.length()
      new_island_bodies.push(handle)
      self.ensure_body_capacity(handle.id)
      self.body_island_ids[handle.id] = new_island_id
      self.body_island_generations[handle.id] = handle.generation
      self.body_island_indices[handle.id] = new_index
      if sleeping {
        if bodies.get_mut(handle) is Some(body) {
          body.sleeping = true
        }
      }
      if bodies.get(handle) is Some(body) {
        if body.additional_solver_iterations > additional_solver_iterations {
          additional_solver_iterations = body.additional_solver_iterations
        }
      }
    }
    if island.bodies.length() == 0 {
      self.remove_from_awake_list(island_id)
      self.islands[island_id] = None
      self.free_islands.push(island_id)
    } else {
      self.islands[island_id] = Some(island)
    }
    let created_island = Island::{
      bodies: new_island_bodies,
      id_in_awake_list: None,
      sleeping,
      additional_solver_iterations,
    }
    if !sleeping {
      let index = self.awake_islands.length()
      created_island.id_in_awake_list = Some(index)
      self.awake_islands.push(new_island_id)
    }
    self.islands[new_island_id] = Some(created_island)
  }
}

///|
fn IslandManager::extract_sleeping_island(
  self : IslandManager,
  bodies : RigidBodySet,
  contacts : ContactGraph,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
  sleep_root : RigidBodyHandle,
) -> Int {
  if sleep_root.id < 0 {
    return 0
  }
  if bodies.get(sleep_root) is None {
    return 0
  }
  self.sync_body_state_generation(sleep_root)
  if self.body_sleep_states[sleep_root.id] is SleepRootState::TraversalPending {
    self.body_sleep_states[sleep_root.id] = SleepRootState::Traversed
  } else {
    return 0
  }
  if self.island_id_for(sleep_root) is Some(island_id) {
    if self.islands[island_id] is Some(active_island) {
      if active_island.id_in_awake_list is None {
        return 0
      }
      let new_island_bodies : Array[RigidBodyHandle] = []
      self.stack.clear()
      self.stack.push(sleep_root)
      self.traversal_timestamp = self.traversal_timestamp + 1
      let mut visited_count = 0
      while self.stack.pop() is Some(handle) {
        if bodies.get(handle) is Some(body) {
          if !body.is_dynamic_or_kinematic() {
            continue
          }
          self.sync_body_state_generation(handle)
          if self.body_active_timestamps[handle.id] == self.traversal_timestamp {
            continue
          }
          self.body_active_timestamps[handle.id] = self.traversal_timestamp
          visited_count = visited_count + 1
          if self.is_body_eligible_for_sleep(handle, body) {
            self.body_sleep_states[handle.id] = SleepRootState::Traversed
          } else {
            self.stack.clear()
            return visited_count
          }
          if self.island_id_for(handle) is Some(other_island_id) {
            if other_island_id != island_id {
              self.stack.clear()
              return visited_count
            }
          }
          self.push_contacting_bodies(bodies, contacts, handle)
          self.push_linked_bodies(
            bodies, impulse_joints, multibody_joints, handle,
          )
          new_island_bodies.push(handle)
        }
      }
      if active_island.bodies.length() == new_island_bodies.length() {
        for i in 0..<active_island.bodies.length() {
          let handle = active_island.bodies[i]
          if bodies.get_mut(handle) is Some(body) {
            body.sleeping = true
          }
        }
        active_island.sleeping = true
        self.remove_from_awake_list(island_id)
        self.islands[island_id] = Some(active_island)
      } else {
        visited_count = visited_count + new_island_bodies.length()
        self.extract_sub_island(bodies, island_id, new_island_bodies, true)
      }
      visited_count
    } else {
      0
    }
  } else {
    0
  }
}

///|
fn IslandManager::update_optimizer(
  self : IslandManager,
  bodies : RigidBodySet,
  contacts : ContactGraph,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
) -> Unit {
  if self.optimizer.mode % 2 == 0 {
    self.incremental_merge(bodies)
  } else {
    self.incremental_split(bodies, contacts, impulse_joints, multibody_joints)
  }
  self.optimizer.mode = self.optimizer.mode + 1
}

///|
fn IslandManager::incremental_merge(
  self : IslandManager,
  bodies : RigidBodySet,
) -> Unit {
  if self.optimizer.merge_state.curr_awake_id >= self.awake_islands.length() {
    self.optimizer.merge_state.curr_awake_id = 0
  }
  let mut first_awake_id = -1
  let mut first_island_id = -1
  let mut first_solver_iterations = 0
  for
    awake_id in self.optimizer.merge_state.curr_awake_id..<self.awake_islands.length() {
    let island_id = self.awake_islands[awake_id]
    if self.islands[island_id] is Some(island) {
      if island.bodies.length() < self.optimizer.min_island_size {
        first_awake_id = awake_id
        first_island_id = island_id
        first_solver_iterations = island.additional_solver_iterations
        break
      }
    }
  }
  if first_awake_id < 0 {
    self.optimizer.merge_state.curr_awake_id = 0
    return
  }
  self.optimizer.merge_state.curr_awake_id = first_awake_id + 1
  let mut found_next = false
  for awake_id in (first_awake_id + 1)..<self.awake_islands.length() {
    let island_id = self.awake_islands[awake_id]
    if self.islands[island_id] is Some(island) {
      if island.bodies.length() < self.optimizer.min_island_size {
        if island.additional_solver_iterations == first_solver_iterations {
          self.merge_islands(bodies, first_island_id, island_id)
          return
        } else if !found_next {
          self.optimizer.merge_state.curr_awake_id = awake_id
          found_next = true
        }
      }
    }
  }
}

///|
fn IslandManager::incremental_split(
  self : IslandManager,
  bodies : RigidBodySet,
  contacts : ContactGraph,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
) -> Unit {
  if self.optimizer.split_state.curr_awake_id >= self.awake_islands.length() {
    self.optimizer.split_state.curr_awake_id = 0
  }
  for
    awake_id in self.optimizer.split_state.curr_awake_id..<self.awake_islands.length() {
    let island_id = self.awake_islands[awake_id]
    if self.islands[island_id] is Some(island) {
      if island.bodies.length() > self.optimizer.max_island_size {
        self.stack.clear()
        let new_island_bodies : Array[RigidBodyHandle] = []
        self.traversal_timestamp = self.traversal_timestamp + 1
        for root_index in 0..<island.bodies.length() {
          self.stack.push(island.bodies[root_index])
          let len_before = new_island_bodies.length()
          while self.stack.pop() is Some(handle) {
            if bodies.get(handle) is Some(body) {
              if !body.is_dynamic_or_kinematic() {
                continue
              }
              self.sync_body_state_generation(handle)
              if self.body_active_timestamps[handle.id] ==
                self.traversal_timestamp {
                continue
              }
              self.body_active_timestamps[handle.id] = self.traversal_timestamp
              self.push_contacting_bodies(bodies, contacts, handle)
              self.push_linked_bodies(
                bodies, impulse_joints, multibody_joints, handle,
              )
              new_island_bodies.push(handle)
              if new_island_bodies.length() > self.optimizer.max_island_size {
                truncate_handles(new_island_bodies, len_before)
                self.stack.clear()
                break
              }
            }
          }
          if new_island_bodies.length() == 0 {
            return
          } else if new_island_bodies.length() >= self.optimizer.min_island_size {
            self.extract_sub_island(bodies, island_id, new_island_bodies, false)
            return
          }
        }
      }
      self.optimizer.split_state.curr_awake_id = awake_id + 1
    }
  }
}

///|
fn IslandManager::pop_traversal_candidate(
  self : IslandManager,
) -> SleepCandidate? {
  if self.traversal_candidates.length() == 0 {
    return None
  }
  let candidate = self.traversal_candidates[0]
  let mut i = 1
  while i < self.traversal_candidates.length() {
    self.traversal_candidates[i - 1] = self.traversal_candidates[i]
    i = i + 1
  }
  self.traversal_candidates.pop() |> ignore
  Some(candidate)
}

///|
pub fn IslandManager::update_islands(
  self : IslandManager,
  dt : @core.Real,
  length_unit : @core.Real,
  bodies : RigidBodySet,
  contacts : ContactGraph,
  impulse_joints : ImpulseJointSet,
  multibody_joints : MultibodyJointSet,
) -> Unit {
  for handle in self.active_bodies() {
    if handle.id < 0 {
      continue
    }
    if bodies.get(handle) is Some(body) {
      if body.enabled && body.is_dynamic_or_kinematic() {
        let eligible = self.update_body_sleep_timer(
          handle, body, dt, length_unit,
        )
        if eligible {
          if self.body_sleep_states[handle.id] is SleepRootState::Unknown {
            self.traversal_candidates.push(SleepCandidate::{ handle, })
            self.body_sleep_states[handle.id] = SleepRootState::TraversalPending
          }
        } else {
          self.body_sleep_states[handle.id] = SleepRootState::Unknown
        }
      }
    }
  }
  let mut cost = 0
  while true {
    if self.pop_traversal_candidate() is Some(candidate) {
      cost = cost +
        self.extract_sleeping_island(
          bodies,
          contacts,
          impulse_joints,
          multibody_joints,
          candidate.handle,
        )
      if cost > MAX_SLEEP_TRAVERSAL_COST {
        break
      }
    } else {
      break
    }
  }
  self.update_optimizer(bodies, contacts, impulse_joints, multibody_joints)
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
pub fn ImpulseJointSet::take_wake_up(
  self : ImpulseJointSet,
) -> Array[RigidBodyHandle] {
  let result : Array[RigidBodyHandle] = []
  for i in 0..<self.to_wake_up.length() {
    result.push(self.to_wake_up[i])
  }
  self.to_wake_up.clear()
  result
}

///|
pub fn ImpulseJointSet::take_to_join(
  self : ImpulseJointSet,
) -> Array[(RigidBodyHandle, RigidBodyHandle)] {
  let result : Array[(RigidBodyHandle, RigidBodyHandle)] = []
  for i in 0..<self.to_join.length() {
    result.push(self.to_join[i])
  }
  self.to_join.clear()
  result
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
  push_unique_pair(self.to_join, (parent, child))
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
    let edges_snapshot = self.adjacency[node_index]
    for i in 0..<edges_snapshot.length() {
      let edge_id = edges_snapshot[i]
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
    if node_index >= 0 &&
      node_index < self.adjacency.length() &&
      self.adjacency[node_index].length() == 0 {
      self.remove_node(node_index)
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
