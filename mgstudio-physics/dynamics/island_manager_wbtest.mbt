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
  let handle1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  islands.wake_up(bodies, handle1, true)
  islands.wake_up(bodies, handle2, true)
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
/// Ported from rapier island_manager sleep extraction behavior.
test "island manager extract sleeping island" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  let contacts = ContactGraph::new()
  let impulse_joints = ImpulseJointSet::new()
  let multibody_joints = MultibodyJointSet::new()
  let handle1 = bodies.insert(RigidBodyBuilder::dynamic().build())
  let handle2 = bodies.insert(RigidBodyBuilder::dynamic().build())
  islands.wake_up(bodies, handle1, true)
  islands.wake_up(bodies, handle2, true)
  if islands.island_id_for(handle1) is Some(id1) &&
    islands.island_id_for(handle2) is Some(id2) {
    if id1 != id2 {
      islands.merge_islands(bodies, id1, id2)
    }
  }
  contacts.add_pair(handle1, handle2)
  islands.body_sleep_timers[handle1.id] = DEFAULT_TIME_UNTIL_SLEEP
  islands.body_sleep_timers[handle2.id] = DEFAULT_TIME_UNTIL_SLEEP
  islands.body_sleep_states[handle1.id] = SleepRootState::TraversalPending
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
