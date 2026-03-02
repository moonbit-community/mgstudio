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
/// Rapier-based 3D physics integration (milestone 2).
///
/// Notes:
/// - Physics v1 ignores `@math.Transform.scale`.
/// - One collider per entity is assumed for v1 (use child entities for compound shapes).

///|
pub struct RigidBody3d {
  body_type : @dynamics.RigidBodyType
}

///|
pub fn RigidBody3d::dynamic() -> RigidBody3d {
  { body_type: @dynamics.RigidBodyType::Dynamic }
}

///|
pub fn RigidBody3d::fixed() -> RigidBody3d {
  { body_type: @dynamics.RigidBodyType::Fixed }
}

///|
pub fn RigidBody3d::kinematic_position_based() -> RigidBody3d {
  { body_type: @dynamics.RigidBodyType::KinematicPositionBased }
}

///|
pub fn RigidBody3d::kinematic_velocity_based() -> RigidBody3d {
  { body_type: @dynamics.RigidBodyType::KinematicVelocityBased }
}

///|
pub enum ColliderShape3d {
  Ball(Float)
  Cuboid(Float, Float, Float)
}

///|
/// Constructors for `ColliderShape3d`.
///
/// MoonBit exports enums as "read-only" by default, so external packages cannot
/// construct `ColliderShape3d` via `ColliderShape3d::Ball(...)`.
pub fn ColliderShape3d::ball(radius : Float) -> ColliderShape3d {
  Ball(radius)
}

///|
pub fn ColliderShape3d::cuboid(
  hx : Float,
  hy : Float,
  hz : Float,
) -> ColliderShape3d {
  Cuboid(hx, hy, hz)
}

///|
pub struct Collider3d {
  shape : ColliderShape3d
  sensor : Bool
}

///|
pub fn Collider3d::new(shape : ColliderShape3d) -> Collider3d {
  { shape, sensor: false }
}

///|
pub fn Collider3d::sensor(self : Collider3d, sensor : Bool) -> Collider3d {
  Collider3d::{ ..self, sensor, }
}

///|
/// Per-collider active event mask (collision/contact-force/intersection events).
pub struct ActiveEvents3d {
  events : @collision.ActiveEvents
}

///|
pub fn ActiveEvents3d::new(events : @collision.ActiveEvents) -> ActiveEvents3d {
  { events, }
}

///|
pub fn ActiveEvents3d::empty() -> ActiveEvents3d {
  { events: @collision.ActiveEvents::empty() }
}

///|
pub fn ActiveEvents3d::collision_events() -> ActiveEvents3d {
  { events: @collision.ActiveEvents::collision_events() }
}

///|
/// Per-collider contact-force event threshold.
pub struct ContactForceEventThreshold3d {
  threshold : Float
}

///|
pub fn ContactForceEventThreshold3d::new(
  threshold : Float,
) -> ContactForceEventThreshold3d {
  { threshold, }
}

///|
/// Per-collider active collision type mask.
pub struct ActiveCollisionTypes3d {
  types : @collision.ActiveCollisionTypes
}

///|
pub fn ActiveCollisionTypes3d::new(
  types : @collision.ActiveCollisionTypes,
) -> ActiveCollisionTypes3d {
  { types, }
}

///|
/// Per-collider active hook mask.
pub struct ActiveHooks3d {
  hooks : @collision.ActiveHooks
}

///|
pub fn ActiveHooks3d::new(hooks : @collision.ActiveHooks) -> ActiveHooks3d {
  { hooks, }
}

///|
pub struct Velocity3d {
  linvel : @math.Vec3
  angvel : @math.Vec3
}

///|
pub fn Velocity3d::new(linvel : @math.Vec3, angvel : @math.Vec3) -> Velocity3d {
  { linvel, angvel }
}

///|
pub fn Velocity3d::zero() -> Velocity3d {
  { linvel: @math.Vec3::zero(), angvel: @math.Vec3::zero() }
}

///|
pub struct RapierBodyHandle3d {
  handle : @dynamics.RigidBodyHandle
}

///|
pub fn RapierBodyHandle3d::new(
  handle : @dynamics.RigidBodyHandle,
) -> RapierBodyHandle3d {
  { handle, }
}

///|
pub struct RapierColliderHandle3d {
  handle : @collision.ColliderHandle3D
}

///|
pub fn RapierColliderHandle3d::new(
  handle : @collision.ColliderHandle3D,
) -> RapierColliderHandle3d {
  { handle, }
}

///|
pub struct Physics3dConfig {
  gravity : @math.Vec3
}

///|
pub fn Physics3dConfig::default() -> Physics3dConfig {
  { gravity: @math.Vec3::new(0.0F, -9.81F, 0.0F) }
}

///|
pub fn Physics3dConfig::new(gravity : @math.Vec3) -> Physics3dConfig {
  Physics3dConfig::{ gravity, }
}

///|
pub struct Physics3dContext {
  rigid_bodies : @dynamics.RigidBodySet3D
  colliders : @collision.ColliderSet3D
  islands : @dynamics.IslandManager3D
  broad_phase : @collision.BroadPhase3D
  narrow_phase : @collision.NarrowPhase3D
  mut pipeline : @pipeline.PhysicsPipeline3DReal
  mut integration : @dynamics.IntegrationParameters
  mut event_handler : @pipeline.EventHandler3D

  // (entity.id, entity.generation) -> handle
  entity_to_body : @hashmap.HashMap[(Int, Int), @dynamics.RigidBodyHandle]
  entity_to_collider : @hashmap.HashMap[(Int, Int), @collision.ColliderHandle3D]
  // (collider_handle.id, collider_handle.generation) -> entity
  collider_to_entity : @hashmap.HashMap[(Int, Int), @core.Entity]
}

///|
pub fn Physics3dContext::new() -> Physics3dContext {
  Physics3dContext::{
    rigid_bodies: @dynamics.RigidBodySet3D::new(),
    colliders: @collision.ColliderSet3D::new(),
    islands: @dynamics.IslandManager3D::new(),
    broad_phase: @collision.BroadPhase3D::new(),
    narrow_phase: @collision.NarrowPhase3D::new(),
    pipeline: @pipeline.PhysicsPipeline3DReal::new(),
    integration: @dynamics.IntegrationParameters::default(),
    event_handler: @pipeline.EventHandler3D::new(),
    entity_to_body: @hashmap.HashMap::new(),
    entity_to_collider: @hashmap.HashMap::new(),
    collider_to_entity: @hashmap.HashMap::new(),
  }
}

///|
pub(open) trait Physics3dPluginWorld: Physics3dResourcesWorld + Physics3dCleanupWorld + Physics3dSyncInsertionsWorld + Physics3dSyncWorldToRapierWorld + Physics3dWritebackWorld {
}

///|
pub let physics3d_set_clear_events : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.clear_events",
)

///|
pub let physics3d_set_cleanup : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.cleanup",
)

///|
pub let physics3d_set_sync_insertions : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.sync_insertions",
)

///|
pub let physics3d_set_sync_world_to_rapier : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.sync_world_to_rapier",
)

///|
pub let physics3d_set_step : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.step",
)

///|
pub let physics3d_set_writeback : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.writeback",
)

///|
pub fn[W : Physics3dPluginWorld] physics3d_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_startup_system(physics3d_init_resources_system)
  .add_pre_update_system_config(
    @app.system(physics3d_clear_events_system).in_set(
      physics3d_set_clear_events,
    ),
  )
  .add_pre_update_system_config(
    @app.system(physics3d_cleanup_despawned_system).in_set(
      physics3d_set_cleanup,
    ),
  )
  .configure_set(@app.PreUpdate, physics3d_set_clear_events, before=[
    physics3d_set_cleanup,
  ])
  .add_fixed_update_system_config(
    @app.system(physics3d_sync_insertions_system).in_set(
      physics3d_set_sync_insertions,
    ),
  )
  .add_fixed_update_system_config(
    @app.system(physics3d_sync_world_to_rapier_system).in_set(
      physics3d_set_sync_world_to_rapier,
    ),
  )
  .add_fixed_update_system_config(
    @app.system(physics3d_step_system).in_set(physics3d_set_step),
  )
  .add_fixed_update_system_config(
    @app.system(physics3d_writeback_system).in_set(physics3d_set_writeback),
  )
  .configure_set(@app.FixedUpdate, physics3d_set_sync_insertions, before=[
    physics3d_set_sync_world_to_rapier,
  ])
  .configure_set(@app.FixedUpdate, physics3d_set_sync_world_to_rapier, before=[
    physics3d_set_step,
  ])
  .configure_set(@app.FixedUpdate, physics3d_set_step, before=[
    physics3d_set_writeback,
  ])
}
