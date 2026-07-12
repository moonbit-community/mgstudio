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
  run : (@ecs.World, @core.Tick) -> Unit raise
  error_handler : ErrorHandler?
  source : String
}

///|
pub struct Commands {
  world : @ecs.World
  tick : @core.Tick
  queue : Array[DeferredCommandEntry]
}

///|
pub struct EntityCommands {
  commands : Commands
  entity : @core.Entity
}

///|
fn[T : @ecs.Component] insert_single_component(
  world : @ecs.World,
  entity : @core.Entity,
  component : T,
  loc~ : SourceLoc,
) -> Unit raise @ecs.EcsError {
  world.set_by_key(entity, T::component(), component, loc~)
}

///|
priv struct DeferredCommandRuntimeState {
  mut batch_queue : Array[(@core.Tick, DeferredCommandEntry)]?
}

///|
let deferred_command_runtime_state_resource_key : @ecs.ResourceKey[
  DeferredCommandRuntimeState,
] = @ecs.register_resource(
  debug_name="mgstudio_app::DeferredCommandRuntimeState",
)

///|
fn deferred_command_runtime_state_new() -> DeferredCommandRuntimeState {
  DeferredCommandRuntimeState::{ batch_queue: None }
}

///|
fn ensure_deferred_command_runtime_state(world : @ecs.World) -> Unit {
  if world.get_resource(deferred_command_runtime_state_resource_key) is None {
    world.insert_resource(
      deferred_command_runtime_state_resource_key,
      deferred_command_runtime_state_new(),
    )
  }
}

///|
fn[R] modify_deferred_command_runtime_state(
  world : @ecs.World,
  f : (DeferredCommandRuntimeState) -> R,
) -> R {
  ensure_deferred_command_runtime_state(world)
  match world.get_resource_mut(deferred_command_runtime_state_resource_key) {
    Some(state) => state.modify(f)
    None => abort("deferred command runtime state resource is missing")
  }
}

///|
fn begin_deferred_command_batch(world : @ecs.World) -> Unit {
  modify_deferred_command_runtime_state(world, fn(state) {
    match state.batch_queue {
      Some(_) => ()
      None => state.batch_queue = Some([])
    }
  })
}

///|
pub fn queue_deferred_world_action(
  action : (@ecs.World) -> Unit,
  source? : String = "app::queue_deferred_world_action",
) -> Unit {
  let world = current_world_or_abort()
  let tick = current_system_ticks().this_run
  let entry = DeferredCommandEntry::{
    run: fn(world : @ecs.World, _tick : @core.Tick) { action(world) },
    error_handler: None,
    source,
  }
  append_deferred_command_entries(world, [(tick, entry)])
}

///|
fn deferred_command_batch_has_entries(world : @ecs.World) -> Bool {
  match world.get_resource(deferred_command_runtime_state_resource_key) {
    Some(state) =>
      match state.batch_queue {
        Some(entries) => entries.length() > 0
        None => false
      }
    None => false
  }
}

///|
fn flush_deferred_command_entries(
  world : @ecs.World,
  entries : Array[(@core.Tick, DeferredCommandEntry)],
) -> Unit {
  entries.each(fn(entry) {
    let (tick, command) = entry
    (command.run)(world, tick) catch {
      err => {
        let context = ErrorContext::new(
          ErrorContextKind::Command,
          command.source,
          stage=current_schedule_stage(),
        )
        match command.error_handler {
          Some(handler) => handler(err, context)
          None => report_world_error(world, err, context)
        }
      }
    }
  })
  entries.clear()
}

///|
fn append_deferred_command_entries(
  world : @ecs.World,
  entries : Array[(@core.Tick, DeferredCommandEntry)],
) -> Unit {
  if entries.length() == 0 {
    return
  }
  let should_flush_now : Ref[Bool] = Ref(false)
  modify_deferred_command_runtime_state(world, fn(state) {
    match state.batch_queue {
      Some(batch) =>
        for entry in entries {
          batch.push(entry)
        }
      None => should_flush_now.val = true
    }
  })
  if should_flush_now.val {
    flush_deferred_command_entries(world, entries)
  }
}

///|
fn end_deferred_command_batch(world : @ecs.World) -> Unit {
  let entries_ref : Ref[Array[(@core.Tick, DeferredCommandEntry)]?] = Ref(None)
  modify_deferred_command_runtime_state(world, fn(state) {
    entries_ref.val = state.batch_queue
    state.batch_queue = None
  })
  match entries_ref.val {
    Some(entries) => flush_deferred_command_entries(world, entries)
    None => ()
  }
}

///|
pub fn Commands::spawn_empty(self : Commands) -> @core.Entity {
  let entity = self.world.entity_allocator().alloc()
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
      ignore(world.spawn_empty_at(entity))
    },
    error_handler: None,
    source: "Commands::spawn_empty",
  })
  entity
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
  self.register_system(system_config_param(system_fn))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam] Commands::register_system_param2(
  self : Commands,
  system_fn : (P1, P2) -> Unit,
) -> SystemId {
  self.register_system(system_config_param2(system_fn))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] Commands::register_system_param3(
  self : Commands,
  system_fn : (P1, P2, P3) -> Unit,
) -> SystemId {
  self.register_system(system_config_param3(system_fn))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam, P4 : SystemParam] Commands::register_system_param4(
  self : Commands,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> SystemId {
  self.register_system(system_config_param4(system_fn))
}

///|
pub fn[
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
] Commands::register_system_param5(
  self : Commands,
  system_fn : (P1, P2, P3, P4, P5) -> Unit,
) -> SystemId {
  self.register_system(system_config_param5(system_fn))
}

///|
pub fn[
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
] Commands::register_system_param6(
  self : Commands,
  system_fn : (P1, P2, P3, P4, P5, P6) -> Unit,
) -> SystemId {
  self.register_system(system_config_param6(system_fn))
}

///|
pub fn[
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
] Commands::register_system_param7(
  self : Commands,
  system_fn : (P1, P2, P3, P4, P5, P6, P7) -> Unit,
) -> SystemId {
  self.register_system(system_config_param7(system_fn))
}

///|
pub fn[
  P1 : SystemParam,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
  P5 : SystemParam,
  P6 : SystemParam,
  P7 : SystemParam,
  P8 : SystemParam,
] Commands::register_system_param8(
  self : Commands,
  system_fn : (P1, P2, P3, P4, P5, P6, P7, P8) -> Unit,
) -> SystemId {
  self.register_system(system_config_param8(system_fn))
}

///|
pub fn Commands::run_system(self : Commands, system_id : SystemId) -> Unit {
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
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
  let entity = self.world.entity_allocator().alloc()
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
      ignore(world.spawn_empty_at(entity))
      insert_single_component(world, entity, component, loc~)
    },
    error_handler: None,
    source: "Commands::spawn_component",
  })
  entity
}

///|
#callsite(autofill(loc))
pub fn[B : @ecs.Bundle] Commands::spawn(
  self : Commands,
  bundle : B,
  loc~ : SourceLoc,
) -> @core.Entity {
  let entity = self.world.entity_allocator().alloc()
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
      ignore(world.spawn_empty_at(entity))
      B::insert_into(bundle, world, entity, loc~)
    },
    error_handler: None,
    source: "Commands::spawn",
  })
  entity
}

///|
#callsite(autofill(loc))
pub fn[B : @ecs.Bundle] Commands::spawn_batch(
  self : Commands,
  bundles : Array[B],
  loc~ : SourceLoc,
) -> Array[@core.Entity] {
  let entities : Array[@core.Entity] = []
  for _ in bundles {
    let entity = self.world.entity_allocator().alloc()
    entities.push(entity)
  }
  let queued_bundles = bundles
  let queued_entities = entities
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
      let count = queued_bundles.length()
      for i in 0..<count {
        ignore(world.spawn_empty_at(queued_entities[i]))
        B::insert_into(queued_bundles[i], world, queued_entities[i], loc~)
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
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      world.insert_resource(T::resource(), resource)
    },
    error_handler: None,
    source: "Commands::insert_resource",
  })
}

///|
pub fn[T] Commands::insert_world_resource(
  self : Commands,
  key : @ecs.ResourceKey[T],
  resource : T,
) -> Unit {
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      world.insert_resource(key, resource)
    },
    error_handler: None,
    source: "Commands::insert_world_resource",
  })
}

///|
pub fn[T : Resource] Commands::remove_resource(self : Commands) -> Unit {
  let key : @ecs.ResourceKey[T] = T::resource()
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      ignore(world.remove_resource(key))
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
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      ignore(world.remove_resource(key))
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
    run: fn(world : @ecs.World, _tick : @core.Tick) raise { command(world) },
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
    run: fn(world : @ecs.World, _tick : @core.Tick) raise { command(world) },
    error_handler: Some(handler),
    source: "Commands::queue_handled",
  })
}

///|
pub fn[E : @ecs.TriggerEvent] Commands::trigger(
  self : Commands,
  event : E,
) -> Unit {
  let source = "Commands::trigger(\{E::debug_name()})"
  self.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      world.trigger(event, caller=Some(source))
    },
    error_handler: None,
    source,
  })
}

///|
#callsite(autofill(loc))
pub fn[B : @ecs.Bundle] EntityCommands::insert(
  self : EntityCommands,
  bundle : B,
  loc~ : SourceLoc,
) -> Unit {
  let entity = self.entity
  self.commands.queue.push({
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
      B::insert_into(bundle, world, entity, loc~)
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
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
      insert_single_component(world, entity, component, loc~)
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
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
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
    run: fn(world : @ecs.World, _tick : @core.Tick) raise {
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
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer(\{K::source_label()})",
        Some(entity),
        system_param(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer(\{K::source_label()})",
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
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer2(\{K::source_label()})",
        Some(entity),
        system_param2(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer2(\{K::source_label()})",
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
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer3(\{K::source_label()})",
        Some(entity),
        system_param3(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer3(\{K::source_label()})",
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
    run: fn(world : @ecs.World, _tick : @core.Tick) {
      guard world.is_alive(entity) else { return }
      register_pointer_observer_entry_in_world(
        world,
        K::event_kind(),
        "EntityCommands::observe_pointer4(\{K::source_label()})",
        Some(entity),
        system_param4(observer),
      )
    },
    error_handler: None,
    source: "EntityCommands::observe_pointer4(\{K::source_label()})",
  })
  self
}

///|
pub impl SystemParam for Commands with fn init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl SystemParam for Commands with fn get(_state) {
  Commands::{
    world: system_param_abort_missing_world(),
    tick: current_system_ticks().this_run,
    queue: [],
  }
}

///|
pub impl SystemParam for Commands with fn store(self, state) {
  let entries : Array[(@core.Tick, DeferredCommandEntry)] = []
  for entry in self.queue {
    entries.push((self.tick, entry))
  }
  append_deferred_command_entries(self.world, entries)
  self.queue.clear()
  system_param_store_no_state(self, state)
}

///|
pub impl SystemParam for Commands with fn access(_world) {
  let access = SystemAccess::new()
  access.mark_deferred_commands()
  access
}

///|
pub fn[S : States] set_state(state : S) -> Unit {
  let world = current_world_or_abort()
  let next_key = next_state_resource_key(state)
  guard world_next_state(world, state) is Some(current) else {
    abort("NextState resource is missing for \{state_type_debug_name(state)}")
  }
  world.insert_resource(next_key, current.set(state))
}

///|
pub fn[S : States] set_state_if_neq(state : S) -> Unit {
  let world = current_world_or_abort()
  let next_key = next_state_resource_key(state)
  guard world_next_state(world, state) is Some(current) else {
    abort("NextState resource is missing for \{state_type_debug_name(state)}")
  }
  world.insert_resource(next_key, current.set_if_neq(state))
}
