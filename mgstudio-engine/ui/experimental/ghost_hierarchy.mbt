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
fn ui_entity_key(entity : @core.Entity) -> (Int, Int) {
  (entity.id, entity.generation)
}

///|
fn ui_is_ghost_node(world : @ecs.World, entity : @core.Entity) -> Bool {
  try! world.contains_by_key(entity, @ui.ecs_key_ghost_node)
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
  if (try! world.contains_by_key(entity, @ui.ecs_key_node)) {
    out.push(entity)
  }
}

///|
fn ui_collect_ghost_nodes(
  world : @ecs.World,
  entity : @core.Entity,
  out : Array[@core.Entity],
) -> Unit {
  if (try! world.get_by_key(entity, @hierarchy.ecs_key_children))
    is Some(children) {
    for child in children.entities {
      if ui_is_ghost_node(world, child) {
        out.push(child)
        ui_collect_ghost_nodes(world, child, out)
      }
    }
  }
}

///|
pub struct UiChildren {
  world : @ecs.World
}

///|
pub fn UiChildren::new(world : @ecs.World) -> UiChildren {
  UiChildren::{ world, }
}

///|
pub fn UiChildren::iter_ui_children(
  self : UiChildren,
  entity : @core.Entity,
) -> Array[@core.Entity] {
  let out : Array[@core.Entity] = []
  if (try! self.world.get_by_key(entity, @hierarchy.ecs_key_children))
    is Some(children) {
    for child in children.entities {
      ui_collect_effective_child_entities(self.world, child, out)
    }
  }
  out
}

///|
pub fn UiChildren::get_parent(
  self : UiChildren,
  entity : @core.Entity,
) -> @core.Entity? {
  let mut current = match
    (try! self.world.get_by_key(entity, @hierarchy.ecs_key_parent)) {
    Some(parent) => Some(parent.entity())
    None => None
  }
  while current is Some(parent_entity) {
    if !ui_is_ghost_node(self.world, parent_entity) {
      return Some(parent_entity)
    }
    current = match
      (try! self.world.get_by_key(parent_entity, @hierarchy.ecs_key_parent)) {
      Some(parent) => Some(parent.entity())
      None => None
    }
  }
  None
}

///|
pub fn UiChildren::iter_ghost_nodes(
  self : UiChildren,
  entity : @core.Entity,
) -> Array[@core.Entity] {
  let out : Array[@core.Entity] = []
  ui_collect_ghost_nodes(self.world, entity, out)
  out
}

///|
pub fn UiChildren::is_changed(self : UiChildren, entity : @core.Entity) -> Bool {
  let sequence = self.world.get_sequence_context().sequence()
  if self.world.is_changed_by_key(entity, @hierarchy.ecs_key_children, sequence) {
    return true
  }
  for ghost_entity in self.iter_ghost_nodes(entity) {
    if self.world.is_changed_by_key(
        ghost_entity, @hierarchy.ecs_key_children, sequence,
      ) {
      return true
    }
  }
  false
}

///|
pub fn UiChildren::is_ui_node(self : UiChildren, entity : @core.Entity) -> Bool {
  (try! self.world.contains_by_key(entity, @ui.ecs_key_node)) ||
  (try! self.world.contains_by_key(entity, @ui.ecs_key_ghost_node))
}

///|
pub struct UiRootNodes {
  world : @ecs.World
  children : UiChildren
}

///|
pub fn UiRootNodes::new(world : @ecs.World) -> UiRootNodes {
  UiRootNodes::{ world, children: UiChildren::new(world) }
}

///|
pub fn UiRootNodes::iter(self : UiRootNodes) -> Array[@core.Entity] {
  let visited : @hashmap.HashMap[(Int, Int), Bool] = @hashmap.HashMap::new()
  let roots : Array[@core.Entity] = []
  self.world.for_each_component(@ui.ecs_key_node, fn(entity, _node) {
    if (try! self.world.contains_by_key(entity, @hierarchy.ecs_key_parent)) {
      return
    }
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(entity)
  })

  self.world.for_each_component(@ui.ecs_key_ghost_node, fn(entity, _ghost) {
    if (try! self.world.contains_by_key(entity, @hierarchy.ecs_key_parent)) {
      return
    }
    for child in self.children.iter_ui_children(entity) {
      let key = ui_entity_key(child)
      if visited.contains(key) {
        continue
      }
      visited.set(key, true)
      roots.push(child)
    }
  })

  // Compatibility root marker used by mgstudio examples/tests.
  self.world.for_each_component(@ui.ecs_key_ui_root, fn(entity, _marker) {
    let key = ui_entity_key(entity)
    if visited.contains(key) {
      return
    }
    visited.set(key, true)
    roots.push(entity)
  })
  roots
}

///|
pub fn ui_children(world : @ecs.World) -> UiChildren {
  UiChildren::new(world)
}

///|
pub fn ui_root_nodes(world : @ecs.World) -> UiRootNodes {
  UiRootNodes::new(world)
}
