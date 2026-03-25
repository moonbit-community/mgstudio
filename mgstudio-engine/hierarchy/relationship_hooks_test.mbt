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
fn hierarchy_child_ids(children : Children) -> Array[Int] {
  let ids : Array[Int] = []
  for entity in children.entities() {
    ids.push(entity.id)
  }
  ids
}

///|
test "hierarchy: inserting Parent immediately inserts Children on target" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(child, ecs_key_parent, Parent::new(parent))

  let children = (try! world.get_by_key(parent, ecs_key_children)).unwrap()
  inspect(hierarchy_child_ids(children), content="[1]")
}

///|
test "hierarchy: replacing Parent moves child between parents" {
  let world = @ecs.World::new()
  let parent_a = world.spawn_empty()
  let parent_b = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(child, ecs_key_parent, Parent::new(parent_a))
  try! world.set_by_key(child, ecs_key_parent, Parent::new(parent_b))

  inspect(
    (try! world.get_by_key(parent_a, ecs_key_children)) is None,
    content="true",
  )
  let children = (try! world.get_by_key(parent_b, ecs_key_children)).unwrap()
  inspect(hierarchy_child_ids(children), content="[2]")
}

///|
test "hierarchy: removing Parent removes child from Children" {
  let world = @ecs.World::new()
  let parent = world.spawn_empty()
  let child = world.spawn_empty()

  try! world.set_by_key(child, ecs_key_parent, Parent::new(parent))
  try! (world.remove_by_key(child, ecs_key_parent) |> ignore)

  inspect(
    (try! world.get_by_key(parent, ecs_key_children)) is None,
    content="true",
  )
}

///|
test "hierarchy: despawning parent recursively despawns descendants" {
  let world = @ecs.World::new()
  let root = world.spawn_empty()
  let child = world.spawn_empty()
  let grandchild = world.spawn_empty()

  try! world.set_by_key(child, ecs_key_parent, Parent::new(root))
  try! world.set_by_key(grandchild, ecs_key_parent, Parent::new(child))
  try! world.despawn(root)

  inspect(world.is_alive(root), content="false")
  inspect(world.is_alive(child), content="false")
  inspect(world.is_alive(grandchild), content="false")
}

///|
test "hierarchy: invalid self parent is removed immediately" {
  let world = @ecs.World::new()
  let entity = world.spawn_empty()

  try! world.set_by_key(entity, ecs_key_parent, Parent::new(entity))

  inspect(
    (try! world.get_by_key(entity, ecs_key_parent)) is None,
    content="true",
  )
}

///|
test "hierarchy: missing parent target is removed immediately" {
  let world = @ecs.World::new()
  let child = world.spawn_empty()
  let missing_parent = @core.Entity::new(999, 1)

  try! world.set_by_key(child, ecs_key_parent, Parent::new(missing_parent))

  inspect(
    (try! world.get_by_key(child, ecs_key_parent)) is None,
    content="true",
  )
}
