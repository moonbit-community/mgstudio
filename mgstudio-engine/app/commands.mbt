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
pub struct DeferredCommandEntry {
  run : (@ecs.World, @core.Sequence) -> Unit raise
  error_handler : ErrorHandler?
  source : String
}

///|
fn[T : @ecs.Component] insert_spawn_component(
  world : @ecs.World,
  entity : @core.Entity,
  component : T,
  sequence : @core.Sequence,
  loc~ : SourceLoc,
) -> Unit raise @ecs.EcsError {
  ignore(sequence)
  world.set_by_key(entity, T::component(), component, loc~)
}

///|
pub(open) trait CommandSpawnComponents {
  spawn_components(
    Self,
    @ecs.World,
    @core.Entity,
    @core.Sequence,
    loc~ : SourceLoc,
  ) -> Unit raise @ecs.EcsError
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] CommandSpawnComponents for (
  A,
  B,
) with spawn_components(self, world, entity, sequence, loc~) {
  let (a, b) = self
  insert_spawn_component(world, entity, a, sequence, loc~)
  insert_spawn_component(world, entity, b, sequence, loc~)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component, C : @ecs.Component] CommandSpawnComponents for (
  A,
  B,
  C,
) with spawn_components(self, world, entity, sequence, loc~) {
  let (a, b, c) = self
  insert_spawn_component(world, entity, a, sequence, loc~)
  insert_spawn_component(world, entity, b, sequence, loc~)
  insert_spawn_component(world, entity, c, sequence, loc~)
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
  sequence,
  loc~,
) {
  let (a, b, c, d) = self
  insert_spawn_component(world, entity, a, sequence, loc~)
  insert_spawn_component(world, entity, b, sequence, loc~)
  insert_spawn_component(world, entity, c, sequence, loc~)
  insert_spawn_component(world, entity, d, sequence, loc~)
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
  sequence,
  loc~,
) {
  let (a, b, c, d, e) = self
  insert_spawn_component(world, entity, a, sequence, loc~)
  insert_spawn_component(world, entity, b, sequence, loc~)
  insert_spawn_component(world, entity, c, sequence, loc~)
  insert_spawn_component(world, entity, d, sequence, loc~)
  insert_spawn_component(world, entity, e, sequence, loc~)
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
  sequence,
  loc~,
) {
  let (a, b, c, d, e, f) = self
  insert_spawn_component(world, entity, a, sequence, loc~)
  insert_spawn_component(world, entity, b, sequence, loc~)
  insert_spawn_component(world, entity, c, sequence, loc~)
  insert_spawn_component(world, entity, d, sequence, loc~)
  insert_spawn_component(world, entity, e, sequence, loc~)
  insert_spawn_component(world, entity, f, sequence, loc~)
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
  sequence,
  loc~,
) {
  let (a, b, c, d, e, f, g) = self
  insert_spawn_component(world, entity, a, sequence, loc~)
  insert_spawn_component(world, entity, b, sequence, loc~)
  insert_spawn_component(world, entity, c, sequence, loc~)
  insert_spawn_component(world, entity, d, sequence, loc~)
  insert_spawn_component(world, entity, e, sequence, loc~)
  insert_spawn_component(world, entity, f, sequence, loc~)
  insert_spawn_component(world, entity, g, sequence, loc~)
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
  sequence,
  loc~,
) {
  let (a, b, c, d, e, f, g, h) = self
  insert_spawn_component(world, entity, a, sequence, loc~)
  insert_spawn_component(world, entity, b, sequence, loc~)
  insert_spawn_component(world, entity, c, sequence, loc~)
  insert_spawn_component(world, entity, d, sequence, loc~)
  insert_spawn_component(world, entity, e, sequence, loc~)
  insert_spawn_component(world, entity, f, sequence, loc~)
  insert_spawn_component(world, entity, g, sequence, loc~)
  insert_spawn_component(world, entity, h, sequence, loc~)
}

///|
pub struct Commands {
  world : @ecs.World
  sequence : @core.Sequence
  queue : Array[DeferredCommandEntry]
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
pub fn Commands::register_system(
  self : Commands,
  system : SystemConfig[@ecs.World],
) -> SystemId {
  register_system(self.world, system)
}

///|
pub fn[P1 : SystemParam] Commands::register_system_param(
  self : Commands,
  system_fn : (P1) -> Unit,
) -> SystemId {
  self.register_system(system(system_param(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam] Commands::register_system_param2(
  self : Commands,
  system_fn : (P1, P2) -> Unit,
) -> SystemId {
  self.register_system(system(system_param2(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] Commands::register_system_param3(
  self : Commands,
  system_fn : (P1, P2, P3) -> Unit,
) -> SystemId {
  self.register_system(system(system_param3(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam, P4 : SystemParam] Commands::register_system_param4(
  self : Commands,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> SystemId {
  self.register_system(system(system_param4(system_fn)))
}

///|
pub fn Commands::run_system(self : Commands, system_id : SystemId) -> Unit {
  self.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) raise {
      run_system(world, system_id)
    },
    error_handler: None,
    source: "Commands::run_system",
  })
}

///|
#callsite(autofill(loc))
pub fn[T : @ecs.Component] Commands::spawn_component(
  self : Commands,
  component : T,
  loc~ : SourceLoc,
) -> @core.Entity {
  let entity = self.world.spawn_empty()
  self.queue.push({
    run: fn(world : @ecs.World, sequence : @core.Sequence) raise {
      insert_spawn_component(world, entity, component, sequence, loc~)
    },
    error_handler: None,
    source: "Commands::spawn_component",
  })
  entity
}

///|
#callsite(autofill(loc))
pub fn[T : CommandSpawnComponents] Commands::spawn(
  self : Commands,
  components : T,
  loc~ : SourceLoc,
) -> @core.Entity {
  let entity = self.world.spawn_empty()
  self.queue.push({
    run: fn(world : @ecs.World, sequence : @core.Sequence) raise {
      components.spawn_components(world, entity, sequence, loc~)
    },
    error_handler: None,
    source: "Commands::spawn",
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
  for _ in component_batch {
    let entity = self.world.spawn_empty()
    entities.push(entity)
  }
  let queued_components = component_batch
  let queued_entities = entities
  self.queue.push({
    run: fn(world : @ecs.World, sequence : @core.Sequence) raise {
      let count = queued_components.length()
      for i in 0..<count {
        queued_components[i].spawn_components(
          world,
          queued_entities[i],
          sequence,
          loc~,
        )
      }
    },
    error_handler: None,
    source: "Commands::spawn_batch",
  })
  entities
}

///|
pub fn[T : Resource] Commands::insert_resource(
  self : Commands,
  resource : T,
) -> Unit {
  self.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      world.insert_resource(T::resource(), resource)
    },
    error_handler: None,
    source: "Commands::insert_resource",
  })
}

///|
pub fn[T : Resource] Commands::remove_resource(self : Commands) -> Unit {
  let key : @ecs.ResourceKey[T] = T::resource()
  self.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      ignore(world.remove_resource(key) catch { _ => None })
    },
    error_handler: None,
    source: "Commands::remove_resource",
  })
}

///|
pub fn[T] Commands::remove_world_resource(
  self : Commands,
  key : @ecs.ResourceKey[T],
) -> Unit {
  self.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      ignore(world.remove_resource(key) catch { _ => None })
    },
    error_handler: None,
    source: "Commands::remove_world_resource",
  })
}

///|
pub fn Commands::queue(
  self : Commands,
  command : (@ecs.World) -> Unit raise,
) -> Unit {
  self.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) raise {
      command(world)
    },
    error_handler: None,
    source: "Commands::queue",
  })
}

///|
pub fn Commands::queue_handled(
  self : Commands,
  command : (@ecs.World) -> Unit raise,
  handler : ErrorHandler,
) -> Unit {
  self.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) raise {
      command(world)
    },
    error_handler: Some(handler),
    source: "Commands::queue_handled",
  })
}

///|
pub fn[E : @ecs.TriggerEvent] Commands::trigger(
  self : Commands,
  event : E,
) -> Unit {
  let source = "Commands::trigger(" + E::debug_name() + ")"
  self.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      world.trigger(event, caller=Some(source))
    },
    error_handler: None,
    source,
  })
}

///|
#callsite(autofill(loc))
pub fn[T : CommandSpawnComponents] EntityCommands::insert(
  self : EntityCommands,
  components : T,
  loc~ : SourceLoc,
) -> Unit {
  let entity = self.entity
  self.commands.queue.push({
    run: fn(world : @ecs.World, sequence : @core.Sequence) raise {
      components.spawn_components(world, entity, sequence, loc~)
    },
    error_handler: None,
    source: "EntityCommands::insert",
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
  self.commands.queue.push({
    run: fn(world : @ecs.World, sequence : @core.Sequence) raise {
      insert_spawn_component(world, entity, component, sequence, loc~)
    },
    error_handler: None,
    source: "EntityCommands::insert_component",
  })
}

///|
#callsite(autofill(loc))
pub fn EntityCommands::despawn(self : EntityCommands, loc~ : SourceLoc) -> Unit {
  let entity = self.entity
  self.commands.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) raise {
      if world.is_alive(entity) {
        world.despawn(entity, loc~)
      }
    },
    error_handler: None,
    source: "EntityCommands::despawn",
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
  self.commands.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) raise {
      if world.is_alive(entity) {
        ignore(world.remove_by_key(entity, key, loc~))
      }
    },
    error_handler: None,
    source: "EntityCommands::remove_component",
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
pub fn[K : PointerObserverKind] EntityCommands::observe_pointer(
  self : EntityCommands,
  observer : (OnPointer[K]) -> Unit,
) -> EntityCommands {
  let entity = self.entity
  self.commands.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer(" + K::source_label() + ")",
        Some(entity),
        system_param(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer(" + K::source_label() + ")",
  })
  self
}

///|
pub fn[K : PointerObserverKind, P2 : SystemParam] EntityCommands::observe_pointer2(
  self : EntityCommands,
  observer : (OnPointer[K], P2) -> Unit,
) -> EntityCommands {
  let entity = self.entity
  self.commands.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer2(" + K::source_label() + ")",
        Some(entity),
        system_param2(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer2(" + K::source_label() + ")",
  })
  self
}

///|
pub fn[K : PointerObserverKind, P2 : SystemParam, P3 : SystemParam] EntityCommands::observe_pointer3(
  self : EntityCommands,
  observer : (OnPointer[K], P2, P3) -> Unit,
) -> EntityCommands {
  let entity = self.entity
  self.commands.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer3(" + K::source_label() + ")",
        Some(entity),
        system_param3(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer3(" + K::source_label() + ")",
  })
  self
}

///|
pub fn[
  K : PointerObserverKind,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] EntityCommands::observe_pointer4(
  self : EntityCommands,
  observer : (OnPointer[K], P2, P3, P4) -> Unit,
) -> EntityCommands {
  let entity = self.entity
  self.commands.queue.push({
    run: fn(world : @ecs.World, _sequence : @core.Sequence) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer4(" + K::source_label() + ")",
        Some(entity),
        system_param4(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer4(" + K::source_label() + ")",
  })
  self
}

///|
fn Commands::flush(self : Commands) -> Unit {
  self.queue.each(fn(entry) {
    (entry.run)(self.world, self.sequence) catch {
      err => {
        let context = ErrorContext::new(
          ErrorContextKind::Command,
          entry.source,
          stage=current_schedule_stage(),
        )
        match entry.error_handler {
          Some(handler) => handler(err, context)
          None => report_world_error(self.world, err, context)
        }
      }
    }
  })
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
    sequence: current_system_sequence().this_run,
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
