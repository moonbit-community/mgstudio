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
fn hierarchy_decode_parent(payload : @any.Any) -> Parent {
  let value_ref : Ref[Parent] = try! payload.to()
  value_ref.val
}

///|
fn hierarchy_decode_children(payload : @any.Any) -> Children {
  let value_ref : Ref[Children] = try! payload.to()
  value_ref.val
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
  world : @ecs.World,
  children_key : @ecs.ComponentKey[Children],
  parent : @core.Entity,
  child : @core.Entity,
) -> Unit {
  if !world.is_alive(parent) {
    return
  }
  let change_tick = world.read_change_tick()
  let children_access = world.component(children_key)
  let entities = match children_access.get(parent) {
    Some(children) => children.entities()
    None => []
  }
  if hierarchy_child_index(entities, child) is Some(_) {
    return
  }
  entities.push(child)
  if children_access.contains(parent) {
    children_access.set(parent, Children::new(entities), change_tick) |> ignore
  } else {
    children_access.insert(parent, Children::new(entities), change_tick)
  }
}

///|
fn hierarchy_remove_child(
  world : @ecs.World,
  children_key : @ecs.ComponentKey[Children],
  parent : @core.Entity,
  child : @core.Entity,
) -> Unit {
  if !world.is_alive(parent) {
    return
  }
  let children_access = world.component(children_key)
  guard children_access.get(parent) is Some(children) else { return }
  let entities = children.entities()
  guard hierarchy_child_index(entities, child) is Some(index) else { return }
  entities.remove(index) |> ignore
  if entities.length() == 0 {
    children_access.remove(parent) |> ignore
  } else {
    children_access.set(
      parent,
      Children::new(entities),
      world.read_change_tick(),
    )
    |> ignore
  }
}

///|
fn hierarchy_parent_target_valid(
  world : @ecs.World,
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
  world : @ecs.World,
  parent_key : @ecs.ComponentKey[Parent],
  children_key : @ecs.ComponentKey[Children],
  child : @core.Entity,
  payload : @any.Any,
) -> Unit {
  let parent = hierarchy_decode_parent(payload).entity()
  if !hierarchy_parent_target_valid(world, child, parent) {
    try! (world.remove(child, parent_key) |> ignore)
    return
  }
  hierarchy_add_child(world, children_key, parent, child)
}

///|
fn hierarchy_parent_on_replace(
  world : @ecs.World,
  parent_key : @ecs.ComponentKey[Parent],
  children_key : @ecs.ComponentKey[Children],
  child : @core.Entity,
  old_payload : @any.Any,
  new_payload : @any.Any,
) -> Unit {
  let old_parent = hierarchy_decode_parent(old_payload).entity()
  let new_parent = hierarchy_decode_parent(new_payload).entity()
  if hierarchy_entities_equal(old_parent, new_parent) {
    return
  }
  hierarchy_remove_child(world, children_key, old_parent, child)
  if !hierarchy_parent_target_valid(world, child, new_parent) {
    try! (world.remove(child, parent_key) |> ignore)
    return
  }
  hierarchy_add_child(world, children_key, new_parent, child)
}

///|
fn hierarchy_parent_on_remove(
  world : @ecs.World,
  children_key : @ecs.ComponentKey[Children],
  child : @core.Entity,
  payload : @any.Any,
) -> Unit {
  let parent = hierarchy_decode_parent(payload).entity()
  hierarchy_remove_child(world, children_key, parent, child)
}

///|
fn hierarchy_children_on_despawn(
  world : @ecs.World,
  _parent : @core.Entity,
  payload : @any.Any,
) -> Unit {
  let children = hierarchy_decode_children(payload)
  for child in children.entities() {
    if world.is_alive(child) {
      try! world.despawn(child)
    }
  }
}

///|
fn hierarchy_register_component_hooks(
  parent_key : @ecs.ComponentKey[Parent],
  children_key : @ecs.ComponentKey[Children],
) -> Bool {
  try! @ecs.register_component_hooks(
    parent_key,
    @ecs.ComponentHooks::new(
      on_insert=Some(fn(world, child, payload) {
        hierarchy_parent_on_insert(
          world, parent_key, children_key, child, payload,
        )
      }),
      on_replace=Some(fn(world, child, old_payload, new_payload) {
        hierarchy_parent_on_replace(
          world, parent_key, children_key, child, old_payload, new_payload,
        )
      }),
      on_remove=Some(fn(world, child, payload) {
        hierarchy_parent_on_remove(world, children_key, child, payload)
      }),
    ),
  )
  try! @ecs.register_component_hooks(
    children_key,
    @ecs.ComponentHooks::new(on_despawn=Some(hierarchy_children_on_despawn)),
  )
  true
}
