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
test "ecs: entity_count tracks spawned entities across despawn and id reuse" {
  let world = World::new()
  let first = world.spawn_empty()
  let second = world.spawn_empty()
  debug_inspect(world.entity_count(), content="2")

  try! world.despawn(first)
  debug_inspect(world.entity_count(), content="1")

  let replacement = world.spawn_empty()
  debug_inspect(replacement.id, content="0")
  debug_inspect(world.entity_count(), content="2")

  try! world.despawn(second)
  try! world.despawn(replacement)
  debug_inspect(world.entity_count(), content="0")
}
