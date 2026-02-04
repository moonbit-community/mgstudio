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
/// Global physics hooks configuration for 2D Rapier integration.
///
/// Rapier's `PhysicsHooks` callbacks are invoked from inside `PhysicsPipeline::step`
/// and do not have access to mgstudio's ECS world. We still provide:
/// - A global place to register callbacks.
/// - A helper to map `ColliderHandle -> Entity` during the current `step`.

///|
pub struct Physics2dHooksConfig {
  /// Return false to ignore the contact pair entirely.
  filter_contact_pair : ((
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
  ) -> Bool)?

  /// Return false to ignore the intersection (sensor) pair entirely.
  filter_intersection_pair : ((
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
  ) -> Bool)?

  /// Return (solve_contacts, friction_dir2) to override solver behavior.
  modify_solver_contacts : ((
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
    @collision.ContactManifold,
  ) -> (Bool, @rapier_core.Vec2))?

  modify_solver_contacts_with_solver_contacts : ((
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
    @collision.ContactManifold,
    Array[@collision.SolverContact],
    @collision.SolverFlags,
  ) -> @collision.SolverFlags)?
}

///|
pub fn Physics2dHooksConfig::default() -> Physics2dHooksConfig {
  {
    filter_contact_pair: None,
    filter_intersection_pair: None,
    modify_solver_contacts: None,
    modify_solver_contacts_with_solver_contacts: None,
  }
}

let physics2d_hooks_state : Ref[Physics2dHooksConfig] = Ref::new(
  Physics2dHooksConfig::default(),
)

let physics2d_hook_collider_to_entity : Ref[
  @hashmap.HashMap[(Int, Int), @core.Entity],
] = Ref::new(@hashmap.HashMap::new())

///|
pub fn physics2d_hooks_config() -> Physics2dHooksConfig {
  physics2d_hooks_state.val
}

///|
pub fn physics2d_hooks_set_config(config : Physics2dHooksConfig) -> Unit {
  physics2d_hooks_state.val = config
}

///|
pub fn physics2d_set_filter_contact_pair(
  f : (
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
  ) -> Bool,
) -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{ ..c, filter_contact_pair: Some(f) }
}

///|
pub fn physics2d_clear_filter_contact_pair() -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{ ..c, filter_contact_pair: None }
}

///|
pub fn physics2d_set_filter_intersection_pair(
  f : (
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
  ) -> Bool,
) -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{
    ..c,
    filter_intersection_pair: Some(f),
  }
}

///|
pub fn physics2d_clear_filter_intersection_pair() -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{ ..c, filter_intersection_pair: None }
}

///|
pub fn physics2d_set_modify_solver_contacts(
  f : (
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
    @collision.ContactManifold,
  ) -> (Bool, @rapier_core.Vec2),
) -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{ ..c, modify_solver_contacts: Some(f) }
}

///|
pub fn physics2d_clear_modify_solver_contacts() -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{ ..c, modify_solver_contacts: None }
}

///|
pub fn physics2d_set_modify_solver_contacts_with_solver_contacts(
  f : (
    @dynamics.RigidBodySet,
    @collision.ColliderSet,
    @collision.ColliderHandle,
    @collision.ColliderHandle,
    @collision.ContactManifold,
    Array[@collision.SolverContact],
    @collision.SolverFlags,
  ) -> @collision.SolverFlags,
) -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{
    ..c,
    modify_solver_contacts_with_solver_contacts: Some(f),
  }
}

///|
pub fn physics2d_clear_modify_solver_contacts_with_solver_contacts() -> Unit {
  let c = physics2d_hooks_state.val
  physics2d_hooks_state.val = Physics2dHooksConfig::{
    ..c,
    modify_solver_contacts_with_solver_contacts: None,
  }
}

///|
/// Map a Rapier collider handle to the owning entity for the current `PhysicsPipeline::step`.
///
/// Note: This is only valid during the time the engine is stepping physics.
pub fn physics2d_hook_entity_from_collider_handle(
  h : @collision.ColliderHandle,
) -> @core.Entity? {
  physics2d_hook_collider_to_entity.val.get(h.into_raw_parts())
}

///|
pub fn physics2d_hooks_set_current_collider_map(
  map : @hashmap.HashMap[(Int, Int), @core.Entity],
) -> Unit {
  physics2d_hook_collider_to_entity.val = map
}

///|
pub fn physics2d_hooks_clear_current_collider_map() -> Unit {
  physics2d_hook_collider_to_entity.val = @hashmap.HashMap::new()
}

///|
pub fn physics2d_apply_global_hooks(ctx : Physics2dContext) -> Unit {
  let c = physics2d_hooks_state.val
  let mut hooks = @pipeline.PhysicsHooks::new()
  match c.filter_contact_pair {
    Some(f) => hooks = hooks.filter_contact_pair(f)
    None => ()
  }
  match c.filter_intersection_pair {
    Some(f) => hooks = hooks.filter_intersection_pair(f)
    None => ()
  }
  match c.modify_solver_contacts {
    Some(f) => hooks = hooks.modify_solver_contacts(f)
    None => ()
  }
  match c.modify_solver_contacts_with_solver_contacts {
    Some(f) => hooks = hooks.modify_solver_contacts_with_solver_contacts(f)
    None => ()
  }
  ctx.hooks = hooks
}
