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
/// Ported from rapier CCD activation behavior.
test "ccd solver updates active flags" {
  let bodies = RigidBodySet::new()
  let islands = IslandManager::new()
  let handle = bodies.insert(RigidBodyBuilder::dynamic().build())
  islands.rigid_body_updated(handle, bodies)
  if bodies.get_mut_internal(handle) is Some(body) {
    body.enable_ccd(true) |> ignore
    body.set_linvel(@core.Vec2::new(2.0F, 0.0F), false) |> ignore
  }
  let solver = CCDSolver::new()
  let active = solver.update_ccd_active_flags(islands, bodies, 0.1F, false)
  inspect(!active, content="true")
  if bodies.get(handle) is Some(body) {
    inspect(!body.is_ccd_active(), content="true")
  } else {
    inspect(false, content="false")
  }
}

///|
/// Ported from rapier CCD clamping behavior.
test "ccd solver clamps motions" {
  let bodies = RigidBodySet::new()
  let handle = bodies.insert(RigidBodyBuilder::dynamic().build())
  if bodies.get_mut_internal(handle) is Some(body) {
    body.set_linvel(@core.Vec2::new(2.0F, 0.0F), false) |> ignore
  }
  let solver = CCDSolver::new()
  let impacts = PredictedImpacts::Impacts([(handle, 0.2F)])
  solver.clamp_motions(0.1F, bodies, impacts)
  if bodies.get(handle) is Some(body) {
    inspect(body.position.next_position.translation.x == 0.4F, content="true")
    inspect(body.position.next_position.translation.y == 0.0F, content="true")
  } else {
    inspect(false, content="false")
  }
}
