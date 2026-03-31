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
/// - Physics v1 ignores `@transform.Transform.scale`.
/// - For compound bodies, use `ColliderParent3d` (child colliders) or
///   `ColliderShape3d::compound`.

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
  CapsuleX(Float, Float)
  CapsuleY(Float, Float)
  CapsuleZ(Float, Float)
  Cylinder(Float, Float)
  Cone(Float, Float)
  HalfSpace(@math.Vec3)
  Triangle(@math.Vec3, @math.Vec3, @math.Vec3)
  TriMesh(Array[@math.Vec3], Array[(Int, Int, Int)])
  ConvexHull(Array[@math.Vec3])
  Compound(Array[(@transform.Transform, ColliderShape3d)])
  Heightfield(Array[Float], Int, Int, @math.Vec3)
  Raw(@collision.Shape3D)
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
pub fn ColliderShape3d::capsule_x(
  half_height : Float,
  radius : Float,
) -> ColliderShape3d {
  CapsuleX(half_height, radius)
}

///|
pub fn ColliderShape3d::capsule_y(
  half_height : Float,
  radius : Float,
) -> ColliderShape3d {
  CapsuleY(half_height, radius)
}

///|
pub fn ColliderShape3d::capsule_z(
  half_height : Float,
  radius : Float,
) -> ColliderShape3d {
  CapsuleZ(half_height, radius)
}

///|
pub fn ColliderShape3d::cylinder(
  half_height : Float,
  radius : Float,
) -> ColliderShape3d {
  Cylinder(half_height, radius)
}

///|
pub fn ColliderShape3d::cone(
  half_height : Float,
  radius : Float,
) -> ColliderShape3d {
  Cone(half_height, radius)
}

///|
pub fn ColliderShape3d::halfspace(normal : @math.Vec3) -> ColliderShape3d {
  HalfSpace(normal)
}

///|
pub fn ColliderShape3d::triangle(
  a : @math.Vec3,
  b : @math.Vec3,
  c : @math.Vec3,
) -> ColliderShape3d {
  Triangle(a, b, c)
}

///|
pub fn ColliderShape3d::trimesh(
  vertices : Array[@math.Vec3],
  indices : Array[(Int, Int, Int)],
) -> ColliderShape3d {
  TriMesh(vertices, indices)
}

///|
pub fn ColliderShape3d::convex_hull(
  vertices : Array[@math.Vec3],
) -> ColliderShape3d {
  ConvexHull(vertices)
}

///|
pub fn ColliderShape3d::compound(
  parts : Array[(@transform.Transform, ColliderShape3d)],
) -> ColliderShape3d {
  Compound(parts)
}

///|
pub fn ColliderShape3d::heightfield(
  heights : Array[Float],
  nrows : Int,
  ncols : Int,
  scale : @math.Vec3,
) -> ColliderShape3d {
  Heightfield(heights, nrows, ncols, scale)
}

///|
pub fn ColliderShape3d::raw(shape : @collision.Shape3D) -> ColliderShape3d {
  Raw(shape)
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
pub struct ColliderParent3d {
  parent : @core.Entity
}

///|
pub fn ColliderParent3d::new(parent : @core.Entity) -> ColliderParent3d {
  { parent, }
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
pub struct Damping3d {
  linear : Float
  angular : Float
}

///|
pub fn Damping3d::new(linear : Float, angular : Float) -> Damping3d {
  { linear, angular }
}

///|
pub struct GravityScale3d {
  scale : Float
}

///|
pub fn GravityScale3d::new(scale : Float) -> GravityScale3d {
  { scale, }
}

///|
pub struct LockedAxes3d {
  lock_translation_x : Bool
  lock_translation_y : Bool
  lock_translation_z : Bool
  lock_rotation_x : Bool
  lock_rotation_y : Bool
  lock_rotation_z : Bool
}

///|
pub fn LockedAxes3d::new(
  lock_translation_x : Bool,
  lock_translation_y : Bool,
  lock_translation_z : Bool,
  lock_rotation_x : Bool,
  lock_rotation_y : Bool,
  lock_rotation_z : Bool,
) -> LockedAxes3d {
  {
    lock_translation_x,
    lock_translation_y,
    lock_translation_z,
    lock_rotation_x,
    lock_rotation_y,
    lock_rotation_z,
  }
}

///|
pub fn LockedAxes3d::locked() -> LockedAxes3d {
  LockedAxes3d::{
    lock_translation_x: true,
    lock_translation_y: true,
    lock_translation_z: true,
    lock_rotation_x: true,
    lock_rotation_y: true,
    lock_rotation_z: true,
  }
}

///|
pub struct Ccd3d {
  enabled : Bool
  soft_prediction : Float
}

///|
pub fn Ccd3d::enabled() -> Ccd3d {
  { enabled: true, soft_prediction: 0.0F }
}

///|
pub fn Ccd3d::new(enabled : Bool, soft_prediction : Float) -> Ccd3d {
  { enabled, soft_prediction }
}

///|
pub struct Dominance3d {
  group : Int
}

///|
pub fn Dominance3d::new(group : Int) -> Dominance3d {
  { group, }
}

///|
pub struct Sleeping3d {
  sleeping : Bool
}

///|
pub fn Sleeping3d::new(sleeping : Bool) -> Sleeping3d {
  { sleeping, }
}

///|
pub struct ExternalForce3d {
  force : @math.Vec3
  torque : @math.Vec3
}

///|
pub fn ExternalForce3d::zero() -> ExternalForce3d {
  { force: @math.Vec3::zero(), torque: @math.Vec3::zero() }
}

///|
pub fn ExternalForce3d::new(
  force : @math.Vec3,
  torque : @math.Vec3,
) -> ExternalForce3d {
  { force, torque }
}

///|
pub struct ExternalImpulse3d {
  impulse : @math.Vec3
  torque_impulse : @math.Vec3
}

///|
pub fn ExternalImpulse3d::zero() -> ExternalImpulse3d {
  { impulse: @math.Vec3::zero(), torque_impulse: @math.Vec3::zero() }
}

///|
pub fn ExternalImpulse3d::new(
  impulse : @math.Vec3,
  torque_impulse : @math.Vec3,
) -> ExternalImpulse3d {
  { impulse, torque_impulse }
}

///|
pub struct ColliderDensity3d {
  density : Float
}

///|
pub fn ColliderDensity3d::new(density : Float) -> ColliderDensity3d {
  { density, }
}

///|
pub struct Friction3d {
  coefficient : Float
}

///|
pub fn Friction3d::new(coefficient : Float) -> Friction3d {
  { coefficient, }
}

///|
pub struct FrictionCombineRule3d {
  rule : @dynamics.CoefficientCombineRule
}

///|
pub fn FrictionCombineRule3d::new(
  rule : @dynamics.CoefficientCombineRule,
) -> FrictionCombineRule3d {
  { rule, }
}

///|
pub struct Restitution3d {
  coefficient : Float
}

///|
pub fn Restitution3d::new(coefficient : Float) -> Restitution3d {
  { coefficient, }
}

///|
pub struct RestitutionCombineRule3d {
  rule : @dynamics.CoefficientCombineRule
}

///|
pub fn RestitutionCombineRule3d::new(
  rule : @dynamics.CoefficientCombineRule,
) -> RestitutionCombineRule3d {
  { rule, }
}

///|
pub struct CollisionGroups3d {
  memberships : Int
  filter : Int
  test_mode : @dynamics.InteractionTestMode
}

///|
pub fn CollisionGroups3d::new(
  memberships : Int,
  filter : Int,
  test_mode : @dynamics.InteractionTestMode,
) -> CollisionGroups3d {
  { memberships, filter, test_mode }
}

///|
pub struct SolverGroups3d {
  memberships : Int
  filter : Int
  test_mode : @dynamics.InteractionTestMode
}

///|
pub fn SolverGroups3d::new(
  memberships : Int,
  filter : Int,
  test_mode : @dynamics.InteractionTestMode,
) -> SolverGroups3d {
  { memberships, filter, test_mode }
}

///|
pub struct ColliderEnabled3d {
  enabled : Bool
}

///|
pub fn ColliderEnabled3d::new(enabled : Bool) -> ColliderEnabled3d {
  { enabled, }
}

///|
pub fn ColliderEnabled3d::disabled() -> ColliderEnabled3d {
  { enabled: false }
}

///|
pub struct ContactSkin3d {
  skin : Float
}

///|
pub fn ContactSkin3d::new(skin : Float) -> ContactSkin3d {
  { skin, }
}

///|
pub struct ColliderMassProperties3d {
  mass_properties : @rapier_core.MassProperties3
}

///|
pub fn ColliderMassProperties3d::new(
  mass_properties : @rapier_core.MassProperties3,
) -> ColliderMassProperties3d {
  { mass_properties, }
}

///|
pub struct RigidBodyEnabled3d {
  enabled : Bool
}

///|
pub fn RigidBodyEnabled3d::new(enabled : Bool) -> RigidBodyEnabled3d {
  { enabled, }
}

///|
pub fn RigidBodyEnabled3d::disabled() -> RigidBodyEnabled3d {
  { enabled: false }
}

///|
pub enum AdditionalMassProperties3d {
  Mass(Float)
  MassProperties(@rapier_core.MassProperties3)
}

///|
pub fn AdditionalMassProperties3d::mass(
  mass : Float,
) -> AdditionalMassProperties3d {
  Mass(mass)
}

///|
pub fn AdditionalMassProperties3d::mass_properties(
  props : @rapier_core.MassProperties3,
) -> AdditionalMassProperties3d {
  MassProperties(props)
}

///|
pub struct AdditionalSolverIterations3d {
  iterations : Int
}

///|
pub fn AdditionalSolverIterations3d::new(
  iterations : Int,
) -> AdditionalSolverIterations3d {
  { iterations, }
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
  physics_pipeline_active : Bool
  integration : @dynamics.IntegrationParameters
}

///|
pub fn Physics3dConfig::default() -> Physics3dConfig {
  {
    gravity: @math.Vec3::new(0.0F, -9.81F, 0.0F),
    physics_pipeline_active: true,
    integration: @dynamics.IntegrationParameters::default(),
  }
}

///|
pub fn Physics3dConfig::new(gravity : @math.Vec3) -> Physics3dConfig {
  Physics3dConfig::{ ..Physics3dConfig::default(), gravity, }
}

///|
pub fn Physics3dConfig::with_gravity(
  self : Physics3dConfig,
  gravity : @math.Vec3,
) -> Physics3dConfig {
  Physics3dConfig::{ ..self, gravity, }
}

///|
pub fn Physics3dConfig::with_physics_pipeline_active(
  self : Physics3dConfig,
  active : Bool,
) -> Physics3dConfig {
  Physics3dConfig::{ ..self, physics_pipeline_active: active }
}

///|
pub fn Physics3dConfig::with_integration_parameters(
  self : Physics3dConfig,
  integration : @dynamics.IntegrationParameters,
) -> Physics3dConfig {
  Physics3dConfig::{ ..self, integration, }
}

///|
pub struct Physics3dContext {
  rigid_bodies : @dynamics.RigidBodySet3D
  colliders : @collision.ColliderSet3D
  islands : @dynamics.IslandManager3D
  broad_phase : @collision.BroadPhase3D
  narrow_phase : @collision.NarrowPhase3D
  mut rope_joints : @dynamics.RopeJointSet3DReal
  mut impulse_joints : @dynamics.JointSet3DReal
  mut multibody_joints : @dynamics.MultibodyJointSet3DReal
  pipeline : @pipeline.PhysicsPipeline3DReal
  mut integration : @dynamics.IntegrationParameters
  mut hooks : @pipeline.PhysicsHooks3D
  event_handler : @pipeline.EventHandler3D
  query_pipeline : @collision.QueryPipeline3DReal

  // (entity.id, entity.generation) -> handle
  entity_to_body : @hashmap.HashMap[(Int, Int), @dynamics.RigidBodyHandle]
  entity_to_collider : @hashmap.HashMap[(Int, Int), @collision.ColliderHandle3D]
  entity_to_impulse_joint : @hashmap.HashMap[
    (Int, Int),
    @dynamics.JointHandle3DReal,
  ]
  entity_to_multibody_joint : @hashmap.HashMap[
    (Int, Int),
    @dynamics.MultibodyJointHandle,
  ]
  // (collider_handle.id, collider_handle.generation) -> entity
  collider_to_entity : @hashmap.HashMap[(Int, Int), @core.Entity]
}

///|
pub fn Physics3dContext::new() -> Physics3dContext {
  let rigid_bodies = @dynamics.RigidBodySet3D::new()
  let colliders = @collision.ColliderSet3D::new()
  let query_pipeline = @collision.QueryPipeline3DReal::new(
    @collision.QueryFilter3DReal::new(),
    rigid_bodies,
    colliders,
  )
  Physics3dContext::{
    rigid_bodies,
    colliders,
    islands: @dynamics.IslandManager3D::new(),
    broad_phase: @collision.BroadPhase3D::new(),
    narrow_phase: @collision.NarrowPhase3D::new(),
    rope_joints: @dynamics.RopeJointSet3DReal::new(),
    impulse_joints: @dynamics.JointSet3DReal::new(),
    multibody_joints: @dynamics.MultibodyJointSet3DReal::new(),
    pipeline: @pipeline.PhysicsPipeline3DReal::new(),
    integration: @dynamics.IntegrationParameters::default(),
    hooks: @pipeline.PhysicsHooks3D::new(),
    event_handler: @pipeline.EventHandler3D::new(),
    query_pipeline,
    entity_to_body: @hashmap.HashMap::new(),
    entity_to_collider: @hashmap.HashMap::new(),
    entity_to_impulse_joint: @hashmap.HashMap::new(),
    entity_to_multibody_joint: @hashmap.HashMap::new(),
    collider_to_entity: @hashmap.HashMap::new(),
  }
}

///|
pub fn Physics3dContext::query(
  self : Physics3dContext,
) -> @collision.QueryPipeline3DReal {
  self.query_pipeline
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
pub let physics3d_set_sync_joints : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.sync_joints",
)

///|
pub let physics3d_set_sync_world_to_rapier : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.sync_world_to_rapier",
)

///|
pub let physics3d_set_character_controller : @app.SystemSet = @app.system_set(
  "mgstudio.physics3d.character_controller",
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
pub fn physics3d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
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
    @app.system(physics3d_sync_joints_system).in_set(physics3d_set_sync_joints),
  )
  .add_fixed_update_system_config(
    @app.system(physics3d_sync_world_to_rapier_system).in_set(
      physics3d_set_sync_world_to_rapier,
    ),
  )
  .add_fixed_update_system_config(
    @app.system(physics3d_character_controller_system).in_set(
      physics3d_set_character_controller,
    ),
  )
  .add_fixed_update_system_config(
    @app.system(physics3d_step_system).in_set(physics3d_set_step),
  )
  .add_fixed_update_system_config(
    @app.system(physics3d_writeback_system).in_set(physics3d_set_writeback),
  )
  .configure_set(@app.FixedUpdate, physics3d_set_sync_insertions, before=[
    physics3d_set_sync_joints,
  ])
  .configure_set(@app.FixedUpdate, physics3d_set_sync_joints, before=[
    physics3d_set_sync_world_to_rapier,
  ])
  .configure_set(@app.FixedUpdate, physics3d_set_sync_world_to_rapier, before=[
    physics3d_set_character_controller,
  ])
  .configure_set(@app.FixedUpdate, physics3d_set_character_controller, before=[
    physics3d_set_step,
  ])
  .configure_set(@app.FixedUpdate, physics3d_set_step, before=[
    physics3d_set_writeback,
  ])
}
