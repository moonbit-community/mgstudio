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
struct Targeting {
  target : @core.Entity
}

///|
struct TargetedBy {
  entities : Array[@core.Entity]
}

///|
let targeting_component_key : @ecs.ComponentKey[Targeting] = @ecs.register_component(
  debug_name="examples.ecs.relationships.Targeting",
)

///|
let targeted_by_component_key : @ecs.ComponentKey[TargetedBy] = @ecs.register_component(
  debug_name="examples.ecs.relationships.TargetedBy",
)

///|
pub impl @ecs.Component for Targeting with component() {
  targeting_component_key
}

///|
pub impl @ecs.Component for TargetedBy with component() {
  targeted_by_component_key
}

///|
fn Targeting::new(target : @core.Entity) -> Targeting {
  { target, }
}

///|
fn TargetedBy::new(entities : Array[@core.Entity]) -> TargetedBy {
  { entities, }
}

///|
fn entity_in_array(
  entities : Array[@core.Entity],
  entity : @core.Entity,
) -> Bool {
  for current in entities {
    if current == entity {
      return true
    }
  }
  false
}

///|
fn remove_entity_from_array(
  entities : Array[@core.Entity],
  removed : @core.Entity,
) -> Array[@core.Entity] {
  let kept : Array[@core.Entity] = []
  for entity in entities {
    if entity != removed {
      kept.push(entity)
    }
  }
  kept
}

///|
fn relationship_add_reverse(
  world : @ecs.DeferredWorld,
  target : @core.Entity,
  source : @core.Entity,
) -> Unit {
  match (world.get(target, targeted_by_component_key) catch { _ => None }) {
    Some(targeted_by) => {
      if entity_in_array(targeted_by.entities, source) {
        return
      }
      let updated = TargetedBy::new(targeted_by.entities + [source])
      try! (world.replace(target, targeted_by_component_key, updated) |> ignore)
    }
    None =>
      try! world.set(
        target,
        targeted_by_component_key,
        TargetedBy::new([source]),
      )
  }
}

///|
fn relationship_remove_reverse(
  world : @ecs.DeferredWorld,
  target : @core.Entity,
  source : @core.Entity,
) -> Unit {
  guard (world.get(target, targeted_by_component_key) catch { _ => None })
    is Some(targeted_by) else {
    return
  }
  let kept = remove_entity_from_array(targeted_by.entities, source)
  if kept.length() == 0 {
    try! (world.remove(target, targeted_by_component_key) |> ignore)
  } else {
    try! (world.replace(
      target,
      targeted_by_component_key,
      TargetedBy::new(kept),
    )
    |> ignore)
  }
}

///|
fn relationship_targeting_insert(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  guard (world.get(context.entity, targeting_component_key) catch { _ => None })
    is Some(targeting) else {
    return
  }
  relationship_add_reverse(world, targeting.target, context.entity)
}

///|
fn relationship_targeting_replace(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  guard (world.get(context.entity, targeting_component_key) catch { _ => None })
    is Some(targeting) else {
    return
  }
  relationship_remove_reverse(world, targeting.target, context.entity)
}

///|
fn relationship_targeting_remove(
  world : @ecs.DeferredWorld,
  context : @ecs.HookContext,
) -> Unit {
  guard (world.get(context.entity, targeting_component_key) catch { _ => None })
    is Some(targeting) else {
    return
  }
  relationship_remove_reverse(world, targeting.target, context.entity)
}

///|
fn relationship_register_hooks(world : @ecs.World) -> Unit {
  ignore(
    try! world
    .register_component_hooks_for_key(targeting_component_key)
    .on_insert(relationship_targeting_insert)
    .on_replace(relationship_targeting_replace)
    .on_remove(relationship_targeting_remove),
  )
}

///|
fn world_name_or_abort(world : @ecs.World, entity : @core.Entity) -> String {
  match (world.entity(entity).get() catch { _ => None } : @ecs.Name?) {
    Some(name) => name.as_str()
    None => abort("Missing Name in relationships example")
  }
}

///|
fn relationship_find_entity_by_name(
  world : @ecs.World,
  target_name : String,
) -> @core.Entity {
  let query : @ecs.Query[@ecs.Comp[@ecs.Name], @ecs.All] = @ecs.query(world)
  let found : Ref[@core.Entity?] = Ref::new(None)
  try! query.view(fn(entity, name_comp) {
    if name_comp.value().as_str() == target_name {
      found.val = Some(entity)
    }
  })
  match found.val {
    Some(entity) => entity
    None => abort("Missing expected entity name: \{target_name}")
  }
}

///|
fn relationship_targeted_by_names(
  world : @ecs.World,
  entity : @core.Entity,
) -> String {
  match (world.entity(entity).get() catch { _ => None } : TargetedBy?) {
    Some(targeted_by) => {
      let names : Array[String] = []
      for source in targeted_by.entities {
        names.push(world_name_or_abort(world, source))
      }
      names.join(", ")
    }
    None => "nobody"
  }
}

///|
fn relationship_debug(world : @ecs.World) -> Unit {
  let query : @ecs.Query[(@ecs.Comp[@ecs.Name], @ecs.Comp[Targeting]), @ecs.All] = @ecs.query(
    world,
  )
  let lines : Array[String] = []
  try! query.view(fn(entity, data) {
    let (name_comp, targeting_comp) = data
    let name = name_comp.value().as_str()
    let target_name = world_name_or_abort(world, targeting_comp.value().target)
    let targeted_by = relationship_targeted_by_names(world, entity)
    lines.push(
      "\{name} is targeting \{target_name}, and is targeted by \{targeted_by}",
    )
  })
  for line in lines {
    println(line)
  }
  println("")
}

///|
fn relationship_has_cycle_from(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  let visited : Array[@core.Entity] = []
  fn walk(world : @ecs.World, current : @core.Entity) -> Bool {
    if entity_in_array(visited, current) {
      return true
    }
    visited.push(current)
    match (world.entity(current).get() catch { _ => None } : Targeting?) {
      Some(targeting) => walk(world, targeting.target)
      None => false
    }
  }
  walk(world, entity)
}

///|
fn main {
  let world = @ecs.World::new()
  relationship_register_hooks(world)
  ignore(world.advance_sequence())

  let alice = world.spawn_empty()
  try! (world.entity_mut(alice).insert_component(@ecs.Name::new("Alice"))
  |> ignore)
  let bob = world.spawn_empty()
  try! (world
  .entity_mut(bob)
  .insert((@ecs.Name::new("Bob"), Targeting::new(alice)))
  |> ignore)
  let charlie = world.spawn_empty()
  try! (world
  .entity_mut(charlie)
  .insert((@ecs.Name::new("Charlie"), Targeting::new(bob)))
  |> ignore)
  let devon = world.spawn_empty()
  try! (world
  .entity_mut(devon)
  .insert((@ecs.Name::new("Devon"), Targeting::new(charlie)))
  |> ignore)
  try! (world.entity_mut(alice).insert_component(Targeting::new(charlie))
  |> ignore)

  relationship_debug(world)
  println(
    "Cycle from Alice: \{relationship_has_cycle_from(world, alice).to_string()}",
  )
  println("")

  let devon_entity = relationship_find_entity_by_name(world, "Devon")
  let alice_entity = relationship_find_entity_by_name(world, "Alice")
  println("Making Devon target Alice.")
  try! (world
  .entity_mut(devon_entity)
  .insert_component(Targeting::new(alice_entity))
  |> ignore)
  relationship_debug(world)

  println("Removing Charlie's targeting relationship.")
  let removed : Targeting? = try! world.entity_mut(charlie).remove_component()
  ignore(removed)
  relationship_debug(world)
  println(
    "Cycle from Alice: \{relationship_has_cycle_from(world, alice).to_string()}",
  )
}
