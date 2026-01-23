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
/// Ported from rapier island_manager merge behavior.
test "island manager merge islands" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  islands.set_island_size_limits(1, 8)
  let handle1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  islands.rigid_body_updated(handle1, bodies)
  islands.rigid_body_updated(handle2, bodies)
  inspect(islands.awake_islands.length() == 2, content="true")
  if islands.island_id_for(handle1) is Some(id1) &&
    islands.island_id_for(handle2) is Some(id2) {
    islands.merge_islands(bodies, id1, id2)
    if islands.island_id_for(handle1) is Some(merged1) &&
      islands.island_id_for(handle2) is Some(merged2) {
      inspect(merged1 == merged2, content="true")
    } else {
      inspect(false, content="false")
    }
    inspect(islands.awake_islands.length() == 1, content="true")
    if bodies.get(handle1) is Some(body1) {
      inspect(!body1.is_sleeping(), content="true")
    } else {
      inspect(false, content="false")
    }
  } else {
    inspect(false, content="false")
  }
}

///|
fn merge_handles(
  islands : IslandManager,
  bodies : RigidBodySet,
  handle1 : RigidBodyHandle,
  handle2 : RigidBodyHandle,
) -> Unit {
  if islands.island_id_for(handle1) is Some(id1) &&
    islands.island_id_for(handle2) is Some(id2) &&
    id1 != id2 {
    islands.merge_islands(bodies, id1, id2)
  }
}

///|
/// Ported from rapier island_manager sleep extraction behavior.
test "island manager extract sleeping island" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  let contacts = ContactGraph::new()
  let impulse_joints = ImpulseJointSet::new()
  let multibody_joints = MultibodyJointSet::new()
  let handle1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  islands.rigid_body_updated(handle1, bodies)
  islands.rigid_body_updated(handle2, bodies)
  if islands.island_id_for(handle1) is Some(id1) &&
    islands.island_id_for(handle2) is Some(id2) {
    if id1 != id2 {
      islands.merge_islands(bodies, id1, id2)
    }
  }
  if bodies.get_mut(handle1) is Some(body1) {
    body1.activation.time_since_can_sleep = body1.activation.time_until_sleep
    body1.activation.sleep_root_state = SleepRootState::TraversalPending
  }
  if bodies.get_mut(handle2) is Some(body2) {
    body2.activation.time_since_can_sleep = body2.activation.time_until_sleep
  }
  contacts.add_pair(handle1, handle2)
  islands.extract_sleeping_island(
    bodies, contacts, impulse_joints, multibody_joints, handle1,
  )
  |> ignore
  inspect(islands.awake_islands.length() == 0, content="true")
  if bodies.get(handle1) is Some(body1) {
    inspect(body1.is_sleeping(), content="true")
  } else {
    inspect(false, content="false")
  }
  if bodies.get(handle2) is Some(body2) {
    inspect(body2.is_sleeping(), content="true")
  } else {
    inspect(false, content="false")
  }
}

///|
/// Ported from rapier island optimizer merge behavior.
test "island manager incremental merge small islands" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  islands.set_island_size_limits(1, 8)
  let handle1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle3 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle4 = bodies.insert(RigidBodyBuilder::dynamic().build())
  islands.rigid_body_updated(handle1, bodies)
  islands.rigid_body_updated(handle2, bodies)
  islands.rigid_body_updated(handle3, bodies)
  islands.rigid_body_updated(handle4, bodies)
  islands.set_island_size_limits(3, 8)
  merge_handles(islands, bodies, handle1, handle2)
  merge_handles(islands, bodies, handle3, handle4)
  inspect(islands.awake_islands.length() == 2, content="true")
  islands.incremental_merge(bodies)
  inspect(islands.awake_islands.length() == 1, content="true")
  if islands.island_id_for(handle1) is Some(id1) &&
    islands.island_id_for(handle3) is Some(id3) {
    inspect(id1 == id3, content="true")
  } else {
    inspect(false, content="false")
  }
}

///|
/// Ported from rapier island optimizer merge compatibility checks.
test "island manager incremental merge incompatible solver iterations" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  islands.set_island_size_limits(1, 8)
  let handle1 = bodies.insert(
    RigidBodyBuilder::dynamic().additional_solver_iterations(0).build(),
  )
  let handle2 = bodies.insert(
    RigidBodyBuilder::dynamic().additional_solver_iterations(0).build(),
  )
  let handle3 = bodies.insert(
    RigidBodyBuilder::dynamic().additional_solver_iterations(2).build(),
  )
  let handle4 = bodies.insert(
    RigidBodyBuilder::dynamic().additional_solver_iterations(2).build(),
  )
  islands.rigid_body_updated(handle1, bodies)
  islands.rigid_body_updated(handle2, bodies)
  islands.rigid_body_updated(handle3, bodies)
  islands.rigid_body_updated(handle4, bodies)
  islands.set_island_size_limits(3, 8)
  merge_handles(islands, bodies, handle1, handle2)
  merge_handles(islands, bodies, handle3, handle4)
  inspect(islands.awake_islands.length() == 2, content="true")
  islands.incremental_merge(bodies)
  inspect(islands.awake_islands.length() == 2, content="true")
  if islands.island_id_for(handle1) is Some(id1) &&
    islands.island_id_for(handle3) is Some(id3) {
    inspect(id1 != id3, content="true")
  } else {
    inspect(false, content="false")
  }
}

///|
/// Ported from rapier island optimizer split behavior.
test "island manager incremental split over max" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  let contacts = ContactGraph::new()
  let impulse_joints = ImpulseJointSet::new()
  let multibody_joints = MultibodyJointSet::new()
  islands.set_island_size_limits(1, 5)
  let handles : Array[RigidBodyHandle] = []
  for _ in 0..<6 {
    let handle = bodies.insert(RigidBodyBuilder::dynamic().build())
    handles.push(handle)
    islands.rigid_body_updated(handle, bodies)
  }
  islands.set_island_size_limits(2, 5)
  for i in 1..<handles.length() {
    merge_handles(islands, bodies, handles[0], handles[i])
  }
  contacts.add_pair(handles[0], handles[1])
  inspect(islands.awake_islands.length() == 1, content="true")
  islands.incremental_split(bodies, contacts, impulse_joints, multibody_joints)
  inspect(islands.awake_islands.length() == 2, content="true")
  if islands.island_id_for(handles[0]) is Some(id1) &&
    islands.island_id_for(handles[1]) is Some(id2) &&
    islands.island_id_for(handles[2]) is Some(id3) {
    inspect(id1 == id2, content="true")
    inspect(id1 != id3, content="true")
  } else {
    inspect(false, content="false")
  }
}

///|
/// Ported from rapier island_manager interaction merge behavior.
test "island manager cross island contact merge" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  islands.set_island_size_limits(1, 8)
  let handle1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  islands.rigid_body_updated(handle1, bodies)
  islands.rigid_body_updated(handle2, bodies)
  inspect(islands.awake_islands.length() == 2, content="true")
  islands.interaction_started_or_stopped(
    bodies,
    Some(handle1),
    Some(handle2),
    true,
    false,
  )
  if islands.island_id_for(handle1) is Some(id1) &&
    islands.island_id_for(handle2) is Some(id2) {
    inspect(id1 == id2, content="true")
  } else {
    inspect(false, content="false")
  }
}
