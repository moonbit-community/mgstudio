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
fn current_world_or_abort() -> @ecs.World {
  match current_world() {
    Some(world) => world
    None =>
      abort("state mutation requires an active world during system execution")
  }
}

///|
type DeferredCommand = (@ecs.World, @core.Tick) -> Unit

///|
fn[T : @ecs.Component] insert_spawn_component(
  world : @ecs.World,
  entity : @core.Entity,
  component : T,
  change_tick : @core.Tick,
  loc~ : SourceLoc,
) -> Unit {
  let key : @ecs.ComponentKey[T] = @ecs.Component::component()
  world.component(key).insert(entity, component, change_tick, loc~)
}

///|
pub(open) trait CommandSpawnComponents {
  spawn_components(Self, @ecs.World, @core.Entity, @core.Tick, loc~ : SourceLoc) -> Unit
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] CommandSpawnComponents for (
  A,
  B,
) with spawn_components(self, world, entity, change_tick, loc~) {
  let (a, b) = self
  insert_spawn_component(world, entity, a, change_tick, loc~)
  insert_spawn_component(world, entity, b, change_tick, loc~)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, C : @ecs.Component] CommandSpawnComponents for (
  A,
  B,
  C,
) with spawn_components(self, world, entity, change_tick, loc~) {
  let (a, b, c) = self
  insert_spawn_component(world, entity, a, change_tick, loc~)
  insert_spawn_component(world, entity, b, change_tick, loc~)
  insert_spawn_component(world, entity, c, change_tick, loc~)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  D : @ecs.Component,
] CommandSpawnComponents for (A, B, C, D) with spawn_components(
  self,
  world,
  entity,
  change_tick,
  loc~,
) {
  let (a, b, c, d) = self
  insert_spawn_component(world, entity, a, change_tick, loc~)
  insert_spawn_component(world, entity, b, change_tick, loc~)
  insert_spawn_component(world, entity, c, change_tick, loc~)
  insert_spawn_component(world, entity, d, change_tick, loc~)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  D : @ecs.Component,
  E : @ecs.Component,
] CommandSpawnComponents for (A, B, C, D, E) with spawn_components(
  self,
  world,
  entity,
  change_tick,
  loc~,
) {
  let (a, b, c, d, e) = self
  insert_spawn_component(world, entity, a, change_tick, loc~)
  insert_spawn_component(world, entity, b, change_tick, loc~)
  insert_spawn_component(world, entity, c, change_tick, loc~)
  insert_spawn_component(world, entity, d, change_tick, loc~)
  insert_spawn_component(world, entity, e, change_tick, loc~)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  D : @ecs.Component,
  E : @ecs.Component,
  F : @ecs.Component,
] CommandSpawnComponents for (A, B, C, D, E, F) with spawn_components(
  self,
  world,
  entity,
  change_tick,
  loc~,
) {
  let (a, b, c, d, e, f) = self
  insert_spawn_component(world, entity, a, change_tick, loc~)
  insert_spawn_component(world, entity, b, change_tick, loc~)
  insert_spawn_component(world, entity, c, change_tick, loc~)
  insert_spawn_component(world, entity, d, change_tick, loc~)
  insert_spawn_component(world, entity, e, change_tick, loc~)
  insert_spawn_component(world, entity, f, change_tick, loc~)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  D : @ecs.Component,
  E : @ecs.Component,
  F : @ecs.Component,
  G : @ecs.Component,
] CommandSpawnComponents for (A, B, C, D, E, F, G) with spawn_components(
  self,
  world,
  entity,
  change_tick,
  loc~,
) {
  let (a, b, c, d, e, f, g) = self
  insert_spawn_component(world, entity, a, change_tick, loc~)
  insert_spawn_component(world, entity, b, change_tick, loc~)
  insert_spawn_component(world, entity, c, change_tick, loc~)
  insert_spawn_component(world, entity, d, change_tick, loc~)
  insert_spawn_component(world, entity, e, change_tick, loc~)
  insert_spawn_component(world, entity, f, change_tick, loc~)
  insert_spawn_component(world, entity, g, change_tick, loc~)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  C : @ecs.Component,
  D : @ecs.Component,
  E : @ecs.Component,
  F : @ecs.Component,
  G : @ecs.Component,
  H : @ecs.Component,
] CommandSpawnComponents for (A, B, C, D, E, F, G, H) with spawn_components(
  self,
  world,
  entity,
  change_tick,
  loc~,
) {
  let (a, b, c, d, e, f, g, h) = self
  insert_spawn_component(world, entity, a, change_tick, loc~)
  insert_spawn_component(world, entity, b, change_tick, loc~)
  insert_spawn_component(world, entity, c, change_tick, loc~)
  insert_spawn_component(world, entity, d, change_tick, loc~)
  insert_spawn_component(world, entity, e, change_tick, loc~)
  insert_spawn_component(world, entity, f, change_tick, loc~)
  insert_spawn_component(world, entity, g, change_tick, loc~)
  insert_spawn_component(world, entity, h, change_tick, loc~)
}

///|
pub struct Commands {
  world : @ecs.World
  change_tick : @core.Tick
  queue : Array[DeferredCommand]
}

///|
pub struct EntityCommands {
  commands : Commands
  entity : @core.Entity
}

///|
pub fn Commands::spawn_empty(self : Commands) -> @core.Entity {
  self.world.spawn_empty()
}

///|
pub fn Commands::entity(
  self : Commands,
  entity : @core.Entity,
) -> EntityCommands {
  EntityCommands::{ commands: self, entity }
}

///|
#callsite(autofill(loc))
pub fn[T : CommandSpawnComponents] Commands::spawn(
  self : Commands,
  components : T,
  loc~ : SourceLoc,
) -> @core.Entity {
  let entity = self.world.spawn_empty()
  self.queue.push(fn(world : @ecs.World, change_tick : @core.Tick) {
    components.spawn_components(world, entity, change_tick, loc~)
  })
  entity
}

///|
#callsite(autofill(loc))
pub fn[T : CommandSpawnComponents] Commands::spawn_batch(
  self : Commands,
  component_batch : Array[T],
  loc~ : SourceLoc,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  for components in component_batch {
    entities.push(self.spawn(components, loc~))
  }
  entities
}

///|
#callsite(autofill(loc))
pub fn[T : CommandSpawnComponents] EntityCommands::insert(
  self : EntityCommands,
  components : T,
  loc~ : SourceLoc,
) -> Unit {
  let entity = self.entity
  self.commands.queue.push(fn(world : @ecs.World, change_tick : @core.Tick) {
    components.spawn_components(world, entity, change_tick, loc~)
  })
}

///|
#callsite(autofill(loc))
pub fn[T : @ecs.Component] EntityCommands::insert_component(
  self : EntityCommands,
  component : T,
  loc~ : SourceLoc,
) -> Unit {
  let entity = self.entity
  self.commands.queue.push(fn(world : @ecs.World, change_tick : @core.Tick) {
    insert_spawn_component(world, entity, component, change_tick, loc~)
  })
}

///|
#callsite(autofill(loc))
pub fn EntityCommands::despawn(self : EntityCommands, loc~ : SourceLoc) -> Unit {
  let entity = self.entity
  self.commands.queue.push(fn(world : @ecs.World, _change_tick : @core.Tick) {
    if world.is_alive(entity) {
      try! world.despawn(entity, loc~)
    }
  })
}

///|
#callsite(autofill(loc))
pub fn[T] EntityCommands::remove_component(
  self : EntityCommands,
  key : @ecs.ComponentKey[T],
  loc~ : SourceLoc,
) -> Unit {
  let entity = self.entity
  self.commands.queue.push(fn(world : @ecs.World, _change_tick : @core.Tick) {
    if world.is_alive(entity) {
      ignore(try! world.remove(entity, key, loc~))
    }
  })
}

///|
#callsite(autofill(loc))
pub fn[T] EntityCommands::remove(
  self : EntityCommands,
  key : @ecs.ComponentKey[T],
  loc~ : SourceLoc,
) -> Unit {
  self.remove_component(key, loc~)
}

///|
fn Commands::flush(self : Commands) -> Unit {
  self.queue.each(fn(command) { command(self.world, self.change_tick) })
  self.queue.clear()
}

///|
pub impl SystemParam for Commands with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl SystemParam for Commands with get(_state) {
  Commands::{
    world: system_param_abort_missing_world(),
    change_tick: current_system_ticks().this_run,
    queue: [],
  }
}

///|
pub impl SystemParam for Commands with store(self, state) {
  self.flush()
  system_param_store_no_state(self, state)
}

///|
pub fn[S : States] set_state(state : S) -> Unit {
  let world = current_world_or_abort()
  let next_key = next_state_resource_key(state)
  guard world_next_state(world, state) is Some(current) else {
    abort("NextState resource is missing for " + state_type_debug_name(state))
  }
  world.insert_resource(next_key, current.set(state))
}

///|
pub fn[S : States] set_state_if_neq(state : S) -> Unit {
  let world = current_world_or_abort()
  let next_key = next_state_resource_key(state)
  guard world_next_state(world, state) is Some(current) else {
    abort("NextState resource is missing for " + state_type_debug_name(state))
  }
  world.insert_resource(next_key, current.set_if_neq(state))
}
