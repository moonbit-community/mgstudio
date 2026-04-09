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
// Bevy source: `bevy/crates/bevy_ui/src/experimental/ghost_hierarchy.rs`.
fn ui_entity_eq(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn ui_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

///|
fn ui_entity_gt(a : @core.Entity, b : @core.Entity) -> Bool {
  if a.id > b.id {
    true
  } else if a.id < b.id {
    false
  } else {
    a.generation > b.generation
  }
}

///|
fn ui_is_ghost_node(world : @ecs.World, entity : @core.Entity) -> Bool {
  try! world.contains_by_key(entity, ecs_key_ghost_node)
}

///|
fn ui_effective_parent(
  world : @ecs.World,
  entity : @core.Entity,
) -> @core.Entity? {
  let mut current = match
    (try! world.get_by_key(entity, @hierarchy.ecs_key_parent)) {
    Some(parent) => Some(parent.entity())
    None => None
  }
  while current is Some(parent_entity) {
    if !ui_is_ghost_node(world, parent_entity) {
      return Some(parent_entity)
    }
    current = match
      (try! world.get_by_key(parent_entity, @hierarchy.ecs_key_parent)) {
      Some(parent) => Some(parent.entity())
      None => None
    }
  }
  None
}

///|
fn ui_collect_effective_child_entities(
  world : @ecs.World,
  entity : @core.Entity,
  out : Array[@core.Entity],
) -> Unit {
  if ui_is_ghost_node(world, entity) {
    if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
      is Some(children) {
      for child in children.entities {
        ui_collect_effective_child_entities(world, child, out)
      }
    }
    return
  }
  out.push(entity)
}

///|
fn ui_collect_effective_children(
  world : @ecs.World,
  entity : @core.Entity,
) -> Array[@core.Entity] {
  let out : Array[@core.Entity] = []
  if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
    is Some(children) {
    for child in children.entities {
      ui_collect_effective_child_entities(world, child, out)
    }
  }
  out
}

///|
fn ui_collect_root_entities(world : @ecs.World) -> Array[@core.Entity] {
  let visited : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  let roots : Array[@core.Entity] = []
  world.for_each_component(ecs_key_node, fn(entity, _node) {
    if (try! world.contains_by_key(entity, @hierarchy.ecs_key_parent)) {
      return
    }
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(entity)
  })
  world.for_each_component(ecs_key_ui_root, fn(entity, _marker) {
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(entity)
  })
  world.for_each_component(ecs_key_ghost_node, fn(entity, _ghost) {
    if (try! world.contains_by_key(entity, @hierarchy.ecs_key_parent)) {
      return
    }
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(entity)
  })
  roots
}
