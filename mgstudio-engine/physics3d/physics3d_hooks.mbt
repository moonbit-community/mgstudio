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
/// World-resource physics hooks configuration for 3D Rapier integration.

///|
pub struct Physics3dHooksConfig {
  filter_contact_pair : ((
    @dynamics.RigidBodySet3D,
    @collision.ColliderSet3D,
    @collision.ColliderHandle3D,
    @collision.ColliderHandle3D,
  ) -> Bool)?
  filter_intersection_pair : ((
    @dynamics.RigidBodySet3D,
    @collision.ColliderSet3D,
    @collision.ColliderHandle3D,
    @collision.ColliderHandle3D,
  ) -> Bool)?
  modify_solver_contacts : ((
    @dynamics.RigidBodySet3D,
    @collision.ColliderSet3D,
    @collision.ColliderHandle3D,
    @collision.ColliderHandle3D,
    @rapier_core.Vec3,
  ) -> (Bool, @rapier_core.Vec3?))?
}

///|
pub fn Physics3dHooksConfig::default() -> Physics3dHooksConfig {
  {
    filter_contact_pair: None,
    filter_intersection_pair: None,
    modify_solver_contacts: None,
  }
}

///|
let physics3d_hook_collider_to_entity : Ref[
  @hashmap.HashMap[(Int, Int), @core.Entity],
] = Ref(@hashmap.HashMap([]))

///|
pub fn physics3d_hooks_config(world : @ecs.World) -> Physics3dHooksConfig {
  match get_physics3d_hooks_config_resource(world).get() {
    Some(cfg) => cfg
    None => Physics3dHooksConfig::default()
  }
}

///|
pub fn physics3d_hooks_set_config(
  world : @ecs.World,
  config : Physics3dHooksConfig,
) -> Unit {
  get_physics3d_hooks_config_resource(world).insert(config)
}

///|
pub fn physics3d_set_filter_contact_pair(
  world : @ecs.World,
  f : (
    @dynamics.RigidBodySet3D,
    @collision.ColliderSet3D,
    @collision.ColliderHandle3D,
    @collision.ColliderHandle3D,
  ) -> Bool,
) -> Unit {
  let c = physics3d_hooks_config(world)
  physics3d_hooks_set_config(world, Physics3dHooksConfig::{
    ..c,
    filter_contact_pair: Some(f),
  })
}

///|
pub fn physics3d_clear_filter_contact_pair(world : @ecs.World) -> Unit {
  let c = physics3d_hooks_config(world)
  physics3d_hooks_set_config(world, Physics3dHooksConfig::{
    ..c,
    filter_contact_pair: None,
  })
}

///|
pub fn physics3d_set_filter_intersection_pair(
  world : @ecs.World,
  f : (
    @dynamics.RigidBodySet3D,
    @collision.ColliderSet3D,
    @collision.ColliderHandle3D,
    @collision.ColliderHandle3D,
  ) -> Bool,
) -> Unit {
  let c = physics3d_hooks_config(world)
  physics3d_hooks_set_config(world, Physics3dHooksConfig::{
    ..c,
    filter_intersection_pair: Some(f),
  })
}

///|
pub fn physics3d_clear_filter_intersection_pair(world : @ecs.World) -> Unit {
  let c = physics3d_hooks_config(world)
  physics3d_hooks_set_config(world, Physics3dHooksConfig::{
    ..c,
    filter_intersection_pair: None,
  })
}

///|
pub fn physics3d_set_modify_solver_contacts(
  world : @ecs.World,
  f : (
    @dynamics.RigidBodySet3D,
    @collision.ColliderSet3D,
    @collision.ColliderHandle3D,
    @collision.ColliderHandle3D,
    @rapier_core.Vec3,
  ) -> (Bool, @rapier_core.Vec3?),
) -> Unit {
  let c = physics3d_hooks_config(world)
  physics3d_hooks_set_config(world, Physics3dHooksConfig::{
    ..c,
    modify_solver_contacts: Some(f),
  })
}

///|
pub fn physics3d_clear_modify_solver_contacts(world : @ecs.World) -> Unit {
  let c = physics3d_hooks_config(world)
  physics3d_hooks_set_config(world, Physics3dHooksConfig::{
    ..c,
    modify_solver_contacts: None,
  })
}

///|
pub fn physics3d_hook_entity_from_collider_handle(
  h : @collision.ColliderHandle3D,
) -> @core.Entity? {
  physics3d_hook_collider_to_entity.val.get(h.into_raw_parts())
}

///|
pub fn physics3d_hooks_set_current_collider_map(
  map : @hashmap.HashMap[(Int, Int), @core.Entity],
) -> Unit {
  physics3d_hook_collider_to_entity.val = map
}

///|
pub fn physics3d_hooks_clear_current_collider_map() -> Unit {
  physics3d_hook_collider_to_entity.val = @hashmap.HashMap([])
}

///|
pub fn physics3d_apply_hooks(
  world : @ecs.World,
  ctx : Physics3dContext,
) -> Unit {
  let c = physics3d_hooks_config(world)
  let mut hooks = @pipeline.PhysicsHooks3D::new()
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
  ctx.hooks = hooks
}
