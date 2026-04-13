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
pub struct SystemId {
  index : Int
} derive(Eq, Debug)

///|
pub(all) suberror RegisteredSystemError {
  UnknownRegisteredSystem(SystemId)
}

///|
priv struct RegisteredSystemsResource {
  configs : Array[Ref[SystemConfig[@ecs.World]]]
}

///|
let ecs_res_key_registered_systems : @ecs.ResourceKey[RegisteredSystemsResource] = @ecs.register_resource(
  debug_name="mgstudio_ecs::system::RegisteredSystems",
)

///|
fn ensure_registered_systems(world : @ecs.World) -> Unit {
  let existing = try world.get_resource(ecs_res_key_registered_systems) catch {
    _ => None
  } noraise {
    value => value
  }
  if existing is None {
    world.insert_resource(ecs_res_key_registered_systems, { configs: [] })
  }
}

///|
fn registered_systems_ref(world : @ecs.World) -> Ref[RegisteredSystemsResource] {
  ensure_registered_systems(world)
  match
    (try world.get_resource_ref(ecs_res_key_registered_systems) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(resource_ref) => resource_ref
    None => abort("Registered one-shot systems resource should exist")
  }
}

///|
fn run_registered_system_config(
  world : @ecs.World,
  config_ref : Ref[SystemConfig[@ecs.World]],
) -> Unit raise Error {
  for cond_i in 0..<config_ref.val.run_ifs.length() {
    let cond = config_ref.val.run_ifs[cond_i]
    let cond_this_run = world.advance_sequence()
    let cond_ticks = @core.SystemSequence::new(
      config_ref.val.run_if_last_run_sequences[cond_i],
      cond_this_run,
    )
    let cond_ctx = world.get_sequence_context()
    cond_ctx.set(cond_ticks)
    world.set_sequence_context(cond_ctx)
    let prev_world = current_world_ref.val
    current_world_ref.val = Some(world)
    let prev_ticks = current_system_sequence_ref.val
    current_system_sequence_ref.val = Some(cond_ticks)
    let should_run = cond(world, config_ref.val.run_if_states[cond_i])
    current_system_sequence_ref.val = prev_ticks
    current_world_ref.val = prev_world
    config_ref.val.run_if_last_run_sequences[cond_i] = cond_this_run
    if !should_run {
      raise @ecs.Skipped("Registered system run condition returned false")
    }
  }

  let this_run = world.advance_sequence()
  let sys_ticks = @core.SystemSequence::new(
    config_ref.val.last_run_sequence,
    this_run,
  )
  let ctx = world.get_sequence_context()
  ctx.set(sys_ticks)
  world.set_sequence_context(ctx)
  let prev_world = current_world_ref.val
  current_world_ref.val = Some(world)
  let prev_ticks = current_system_sequence_ref.val
  current_system_sequence_ref.val = Some(sys_ticks)
  let prev_outcome = current_system_execution_outcome()
  reset_system_execution_outcome()
  (config_ref.val.system)(world)
  let outcome = current_system_execution_outcome()
  current_system_execution_outcome_ref.val = prev_outcome
  current_system_sequence_ref.val = prev_ticks
  current_world_ref.val = prev_world
  match outcome {
    Success => config_ref.val.last_run_sequence = this_run
    Skipped(message) => raise @ecs.Skipped(message)
    Invalid(message) => raise @ecs.Invalid(message)
    Error(err) => {
      config_ref.val.last_run_sequence = this_run
      match config_ref.val.error_handler {
        Some(handler) =>
          handler(
            err,
            system_context(config_ref.val, ErrorContextKind::System, None),
          )
        None => raise err
      }
    }
  }
}

///|
pub fn register_system(
  world : @ecs.World,
  system : SystemConfig[@ecs.World],
) -> SystemId {
  let configs_ref = registered_systems_ref(world)
  let system_id = SystemId::{ index: configs_ref.val.configs.length() }
  configs_ref.val.configs.push(Ref::new(system))
  system_id
}

///|
pub fn run_system(world : @ecs.World, system_id : SystemId) -> Unit raise Error {
  let configs_ref = registered_systems_ref(world)
  guard system_id.index >= 0 &&
    system_id.index < configs_ref.val.configs.length() else {
    raise UnknownRegisteredSystem(system_id)
  }
  run_registered_system_config(world, configs_ref.val.configs[system_id.index])
}

///|
pub fn run_system_once(
  world : @ecs.World,
  system : SystemConfig[@ecs.World],
) -> Unit raise Error {
  run_registered_system_config(world, Ref::new(system))
}

///|
pub fn register_world_system(
  world : @ecs.World,
  system_fn : (@ecs.World) -> Unit,
) -> SystemId {
  register_system(world, system(system_fn))
}

///|
pub fn[P1 : SystemParam] register_system_param(
  world : @ecs.World,
  system_fn : (P1) -> Unit,
) -> SystemId {
  register_system(world, system(system_param(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam] register_system_param2(
  world : @ecs.World,
  system_fn : (P1, P2) -> Unit,
) -> SystemId {
  register_system(world, system(system_param2(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] register_system_param3(
  world : @ecs.World,
  system_fn : (P1, P2, P3) -> Unit,
) -> SystemId {
  register_system(world, system(system_param3(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam, P4 : SystemParam] register_system_param4(
  world : @ecs.World,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> SystemId {
  register_system(world, system(system_param4(system_fn)))
}

///|
pub fn run_world_system_once(
  world : @ecs.World,
  system_fn : (@ecs.World) -> Unit,
) -> Unit raise Error {
  run_system_once(world, system(system_fn))
}

///|
pub fn[P1 : SystemParam] run_system_once_param(
  world : @ecs.World,
  system_fn : (P1) -> Unit,
) -> Unit raise Error {
  run_system_once(world, system(system_param(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam] run_system_once_param2(
  world : @ecs.World,
  system_fn : (P1, P2) -> Unit,
) -> Unit raise Error {
  run_system_once(world, system(system_param2(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam] run_system_once_param3(
  world : @ecs.World,
  system_fn : (P1, P2, P3) -> Unit,
) -> Unit raise Error {
  run_system_once(world, system(system_param3(system_fn)))
}

///|
pub fn[P1 : SystemParam, P2 : SystemParam, P3 : SystemParam, P4 : SystemParam] run_system_once_param4(
  world : @ecs.World,
  system_fn : (P1, P2, P3, P4) -> Unit,
) -> Unit raise Error {
  run_system_once(world, system(system_param4(system_fn)))
}
