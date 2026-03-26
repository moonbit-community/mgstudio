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
fn hierarchy_warn_invalid_parent(
  child : @core.Entity,
  parent : @core.Entity,
  reason : String,
) -> Unit {
  println(
    "warning[hierarchy]: Parent(\{parent.id}, \{parent.generation}) on entity (\{child.id}, \{child.generation}) is invalid: \{reason}",
  )
}

///|
fn hierarchy_entities_equal(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn hierarchy_child_index(
  entities : Array[@core.Entity],
  target : @core.Entity,
) -> Int? {
  for i in 0..<entities.length() {
    if hierarchy_entities_equal(entities[i], target) {
      return Some(i)
    }
  }
  None
}

///|
fn hierarchy_add_child(
  world : @ecs.DeferredWorld,
  children_key : @ecs.ComponentKey[Children],
  parent : @core.Entity,
  child : @core.Entity,
) -> Unit {
  if !world.is_alive(parent) {
    return
  }
  let entities = match (try! world.get_by_key(parent, children_key)) {
    Some(children) => children.entities()
    None => []
  }
  if hierarchy_child_index(entities, child) is Some(_) {
    return
  }
  entities.push(child)
  if world.contains_by_key(parent, children_key) {
    try! (world.replace(parent, children_key, Children::new(entities)) |> ignore)
  } else {
    try! world.set_by_key(parent, children_key, Children::new(entities))
  }
}

///|
fn hierarchy_remove_child(
  world : @ecs.DeferredWorld,
  children_key : @ecs.ComponentKey[Children],
  parent : @core.Entity,
  child : @core.Entity,
) -> Unit {
  if !world.is_alive(parent) {
    return
  }
  guard (try! world.get_by_key(parent, children_key)) is Some(children) else {
    return
  }
  let entities = children.entities()
  guard hierarchy_child_index(entities, child) is Some(index) else { return }
  entities.remove(index) |> ignore
  if entities.length() == 0 {
    try! (world.take(parent, children_key) |> ignore)
  } else {
    try! (world.replace(parent, children_key, Children::new(entities)) |> ignore)
  }
}

///|
fn hierarchy_parent_target_valid(
  world : @ecs.DeferredWorld,
  child : @core.Entity,
  parent : @core.Entity,
) -> Bool {
  if hierarchy_entities_equal(child, parent) {
    hierarchy_warn_invalid_parent(
      child, parent, "self-parent relationships are not allowed",
    )
    return false
  }
  if !world.is_alive(parent) {
    hierarchy_warn_invalid_parent(child, parent, "target entity does not exist")
    return false
  }
  true
}

///|
fn hierarchy_parent_on_insert(
  world : @ecs.DeferredWorld,
  parent_key : @ecs.ComponentKey[Parent],
  children_key : @ecs.ComponentKey[Children],
  child : @core.Entity,
) -> Unit {
  guard (try! world.get_by_key(child, parent_key)) is Some(parent_component) else {
    return
  }
  let parent = parent_component.entity()
  if !hierarchy_parent_target_valid(world, child, parent) {
    try! (world.remove_by_key(child, parent_key) |> ignore)
    return
  }
  hierarchy_add_child(world, children_key, parent, child)
}

///|
fn hierarchy_parent_on_replace(
  world : @ecs.DeferredWorld,
  parent_key : @ecs.ComponentKey[Parent],
  children_key : @ecs.ComponentKey[Children],
  child : @core.Entity,
) -> Unit {
  guard (try! world.get_by_key(child, parent_key)) is Some(old_parent_component) else {
    return
  }
  let old_parent = old_parent_component.entity()
  hierarchy_remove_child(world, children_key, old_parent, child)
}

///|
fn hierarchy_parent_on_remove(
  world : @ecs.DeferredWorld,
  parent_key : @ecs.ComponentKey[Parent],
  children_key : @ecs.ComponentKey[Children],
  child : @core.Entity,
) -> Unit {
  guard (try! world.get_by_key(child, parent_key)) is Some(parent_component) else {
    return
  }
  let parent = parent_component.entity()
  hierarchy_remove_child(world, children_key, parent, child)
}

///|
fn hierarchy_register_component_hooks(
  parent_key : @ecs.ComponentKey[Parent],
  children_key : @ecs.ComponentKey[Children],
) -> Bool {
  let parent_hooks = @ecs.register_component_hooks_for_key(parent_key)
  ignore(
    try! parent_hooks
    .on_insert(fn(world, context) {
      hierarchy_parent_on_insert(
        world,
        parent_key,
        children_key,
        context.entity,
      )
    })
    .on_replace(fn(world, context) {
      hierarchy_parent_on_replace(
        world,
        parent_key,
        children_key,
        context.entity,
      )
    })
    .on_remove(fn(world, context) {
      hierarchy_parent_on_remove(
        world,
        parent_key,
        children_key,
        context.entity,
      )
    }),
  )
  let children_hooks = @ecs.register_component_hooks_for_key(children_key)
  ignore(
    try! children_hooks.on_despawn(fn(world, context) {
      guard (try! world.get_by_key(context.entity, children_key))
        is Some(children) else {
        return
      }
      // Snapshot descendants before recursive despawn mutates the hierarchy.
      let child_entities = children.entities().copy()
      for child in child_entities {
        if world.is_alive(child) {
          try! world.despawn(child)
        }
      }
    }),
  )
  true
}
