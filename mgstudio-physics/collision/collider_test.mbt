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
/// Ported from rapier collider position setters.
test "collider position setters" {
  let collider = ColliderBuilder::ball(1.0F).build()
  collider.set_translation(@core.Vec2::new(1.0F, -2.0F)) |> ignore
  collider.set_rotation(1.5F) |> ignore
  inspect(collider.translation().x == 1.0F, content="true")
  inspect(collider.translation().y == -2.0F, content="true")
  inspect(collider.rotation() == 1.5F, content="true")
  let position = collider.position()
  inspect(position.translation.x == 1.0F, content="true")
  inspect(position.translation.y == -2.0F, content="true")
  inspect(position.rotation.angle() == 1.5F, content="true")
}

///|
/// Ported from rapier collider parent offset setters.
test "collider parent offset setters" {
  let bodies = @dynamics.RigidBodySet::new()
  let body = @dynamics.RigidBodyBuilder::dynamic().build()
  let body_handle = bodies.insert(body)
  let colliders = ColliderSet::new()
  let collider = ColliderBuilder::ball(0.5F).build()
  let handle = colliders.insert_with_parent(collider, body_handle, bodies)
  if colliders.get_mut(handle) is Some(owned) {
    owned.set_translation_wrt_parent(@core.Vec2::new(0.5F, 1.0F)) |> ignore
    owned.set_rotation_wrt_parent(0.25F) |> ignore
  }
  if colliders.get(handle) is Some(stored) {
    if stored.position_wrt_parent() is Some(position) {
      inspect(position.translation.x == 0.5F, content="true")
      inspect(position.translation.y == 1.0F, content="true")
      inspect(position.rotation.angle() == 0.25F, content="true")
    } else {
      inspect(false, content="true")
    }
  } else {
    inspect(false, content="true")
  }
}
