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
struct DespawnMembershipMarker {}

///|
let despawn_membership_marker_key : ComponentKey[DespawnMembershipMarker] = register_component(
  debug_name="tests.ecs.despawn_membership_marker",
)

///|
test "despawn updates component membership count and generation" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, despawn_membership_marker_key, DespawnMembershipMarker::{

  })
  let generation_before = world.component_membership_generation_for_definition(
    despawn_membership_marker_key.id(),
  )
  assert_eq(world.component_count(despawn_membership_marker_key), 1)

  try! world.despawn(entity)

  let generation_after = world.component_membership_generation_for_definition(
    despawn_membership_marker_key.id(),
  )
  debug_inspect(
    (
      world.component_count(despawn_membership_marker_key),
      generation_after - generation_before,
    ),
    content="(0, 1)",
  )
}
