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
/// Bevy-style physics hooks configuration for 2D Rapier integration.
///
/// Rapier invokes `PhysicsHooks` callbacks from inside `PhysicsPipeline::step`.
/// Those callbacks do not have access to mgstudio's ECS world.
///
/// Like `bevy_rapier`, mgstudio stores the owning `Entity` on each Rapier collider
/// (and rigid-body) using `user_data128 = (entity.id, entity.generation)`.
/// This lets hooks recover entity semantics from Rapier handles.

///|
pub struct Physics2dPairHookContext {
  bodies : @dynamics.RigidBodySet
  colliders : @collision.ColliderSet
  collider1 : @collision.ColliderHandle
  collider2 : @collision.ColliderHandle
  entity1 : @core.Entity?
  entity2 : @core.Entity?
}

///|
pub struct Physics2dContactHookContext {
  bodies : @dynamics.RigidBodySet
  colliders : @collision.ColliderSet
  collider1 : @collision.ColliderHandle
  collider2 : @collision.ColliderHandle
  entity1 : @core.Entity?
  entity2 : @core.Entity?
  manifold : @collision.ContactManifold
}

///|
pub struct Physics2dContactHookWithSolverContactsContext {
  bodies : @dynamics.RigidBodySet
  colliders : @collision.ColliderSet
  collider1 : @collision.ColliderHandle
  collider2 : @collision.ColliderHandle
  entity1 : @core.Entity?
  entity2 : @core.Entity?
  manifold : @collision.ContactManifold
  solver_contacts : Array[@collision.SolverContact]
  solver_flags : @collision.SolverFlags
}

///|
/// Register user-defined callbacks as an ECS resource (Bevy-style).
#ecs.resource
pub struct Physics2dHooks {
  /// Return false to ignore the contact pair entirely.
  filter_contact_pair : ((Physics2dPairHookContext) -> Bool)?
  /// Return false to ignore the intersection (sensor) pair entirely.
  filter_intersection_pair : ((Physics2dPairHookContext) -> Bool)?
  /// Return (solve_contacts, friction_dir2) to override solver behavior.
  modify_solver_contacts : ((Physics2dContactHookContext) -> (
    Bool,
    @rapier_core.Vec2,
  ))?
  modify_solver_contacts_with_solver_contacts : ((
    Physics2dContactHookWithSolverContactsContext,
  ) -> @collision.SolverFlags)?
}

///|
pub fn Physics2dHooks::default() -> Physics2dHooks {
  {
    filter_contact_pair: None,
    filter_intersection_pair: None,
    modify_solver_contacts: None,
    modify_solver_contacts_with_solver_contacts: None,
  }
}

///|
pub fn Physics2dHooks::with_filter_contact_pair(
  self : Physics2dHooks,
  f : (Physics2dPairHookContext) -> Bool,
) -> Physics2dHooks {
  Physics2dHooks::{ ..self, filter_contact_pair: Some(f) }
}

///|
pub fn Physics2dHooks::with_filter_intersection_pair(
  self : Physics2dHooks,
  f : (Physics2dPairHookContext) -> Bool,
) -> Physics2dHooks {
  Physics2dHooks::{ ..self, filter_intersection_pair: Some(f) }
}

///|
pub fn Physics2dHooks::with_modify_solver_contacts(
  self : Physics2dHooks,
  f : (Physics2dContactHookContext) -> (Bool, @rapier_core.Vec2),
) -> Physics2dHooks {
  Physics2dHooks::{ ..self, modify_solver_contacts: Some(f) }
}

///|
pub fn Physics2dHooks::with_modify_solver_contacts_with_solver_contacts(
  self : Physics2dHooks,
  f : (Physics2dContactHookWithSolverContactsContext) -> @collision.SolverFlags,
) -> Physics2dHooks {
  Physics2dHooks::{
    ..self,
    modify_solver_contacts_with_solver_contacts: Some(f),
  }
}

///|
fn physics2d_user_data128_from_entity(
  e : @core.Entity,
) -> @rapier_core.UserData128 {
  let hi = UInt64::extend_uint(e.id.reinterpret_as_uint())
  let lo = UInt64::extend_uint(e.generation.reinterpret_as_uint())
  @rapier_core.UserData128::from_parts(hi, lo)
}

///|
fn physics2d_entity_from_user_data128(
  data : @rapier_core.UserData128,
) -> @core.Entity? {
  let (_hi, lo) = data.to_parts()
  // Generation `0` is reserved for placeholders/unset.
  if UInt64::equal(lo, UInt64::default()) {
    return None
  }
  let (hi, lo) = data.to_parts()
  Some(@core.Entity::new(hi.to_int(), lo.to_int()))
}

///|
fn physics2d_entity_from_collider_handle_via_user_data(
  colliders : @collision.ColliderSet,
  h : @collision.ColliderHandle,
) -> @core.Entity? {
  match colliders.get(h) {
    Some(c) => physics2d_entity_from_user_data128(c.user_data128())
    None => None
  }
}

///|
fn physics2d_build_rapier_hooks(cfg : Physics2dHooks) -> @pipeline.PhysicsHooks {
  let mut hooks = @pipeline.PhysicsHooks::new()
  match cfg.filter_contact_pair {
    Some(f) =>
      hooks = hooks.filter_contact_pair(fn(bodies, colliders, h1, h2) {
        f(Physics2dPairHookContext::{
          bodies,
          colliders,
          collider1: h1,
          collider2: h2,
          entity1: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h1,
          ),
          entity2: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h2,
          ),
        })
      })
    None => ()
  }
  match cfg.filter_intersection_pair {
    Some(f) =>
      hooks = hooks.filter_intersection_pair(fn(bodies, colliders, h1, h2) {
        f(Physics2dPairHookContext::{
          bodies,
          colliders,
          collider1: h1,
          collider2: h2,
          entity1: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h1,
          ),
          entity2: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h2,
          ),
        })
      })
    None => ()
  }
  match cfg.modify_solver_contacts {
    Some(f) =>
      hooks = hooks.modify_solver_contacts(fn(bodies, colliders, h1, h2, m) {
        f(Physics2dContactHookContext::{
          bodies,
          colliders,
          collider1: h1,
          collider2: h2,
          entity1: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h1,
          ),
          entity2: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h2,
          ),
          manifold: m,
        })
      })
    None => ()
  }
  match cfg.modify_solver_contacts_with_solver_contacts {
    Some(f) =>
      hooks = hooks.modify_solver_contacts_with_solver_contacts(fn(
        bodies,
        colliders,
        h1,
        h2,
        m,
        contacts,
        flags,
      ) {
        f(Physics2dContactHookWithSolverContactsContext::{
          bodies,
          colliders,
          collider1: h1,
          collider2: h2,
          entity1: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h1,
          ),
          entity2: physics2d_entity_from_collider_handle_via_user_data(
            colliders, h2,
          ),
          manifold: m,
          solver_contacts: contacts,
          solver_flags: flags,
        })
      })
    None => ()
  }
  hooks
}

///|
fn physics2d_apply_hooks(ctx : Physics2dContext, cfg : Physics2dHooks) -> Unit {
  ctx.hooks = physics2d_build_rapier_hooks(cfg)
}
