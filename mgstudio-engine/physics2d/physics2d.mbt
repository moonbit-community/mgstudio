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
/// Rapier-based 2D physics integration (Bevy-like, 2D-first).
///
/// Note:
/// - mgstudio bakes `@math.Transform.scale` into collider shapes (best-effort).
/// - For compound bodies, use `ColliderParent2d` (child colliders) or `ColliderShape2d::compound`.

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct RigidBody2d {
  body_type : @dynamics.RigidBodyType
}

///|
pub fn RigidBody2d::dynamic() -> RigidBody2d {
  { body_type: @dynamics.RigidBodyType::Dynamic }
}

///|
pub fn RigidBody2d::fixed() -> RigidBody2d {
  { body_type: @dynamics.RigidBodyType::Fixed }
}

///|
pub fn RigidBody2d::kinematic_position_based() -> RigidBody2d {
  { body_type: @dynamics.RigidBodyType::KinematicPositionBased }
}

///|
pub fn RigidBody2d::kinematic_velocity_based() -> RigidBody2d {
  { body_type: @dynamics.RigidBodyType::KinematicVelocityBased }
}

///|
pub enum ColliderShape2d {
  Ball(Float)
  Cuboid(Float, Float)
  CapsuleX(Float, Float)
  CapsuleY(Float, Float)
  Segment(@math.Vec2, @math.Vec2)
  Polyline(Array[@math.Vec2], Array[(Int, Int)]?)
  ConvexPolygon(Array[@math.Vec2])
  TriMesh(Array[@math.Vec2], Array[(Int, Int, Int)])
  /// A compound shape composed of sub-shapes with local transforms.
  Compound(Array[(@math.Transform, ColliderShape2d)])
  /// Escape hatch: use a Rapier shape directly.
  Raw(@collision.Shape)
}

///|
/// Constructors for `ColliderShape2d`.
///
/// Note: MoonBit currently exports enums as "read-only" by default, so external
/// packages cannot construct `ColliderShape2d` via `ColliderShape2d::Ball(...)`.
/// These helpers are the public way to create shapes.
pub fn ColliderShape2d::ball(radius : Float) -> ColliderShape2d {
  Ball(radius)
}

///|
pub fn ColliderShape2d::cuboid(hx : Float, hy : Float) -> ColliderShape2d {
  Cuboid(hx, hy)
}

///|
pub fn ColliderShape2d::capsule_x(
  half_height : Float,
  radius : Float,
) -> ColliderShape2d {
  CapsuleX(half_height, radius)
}

///|
pub fn ColliderShape2d::capsule_y(
  half_height : Float,
  radius : Float,
) -> ColliderShape2d {
  CapsuleY(half_height, radius)
}

///|
pub fn ColliderShape2d::segment(
  a : @math.Vec2,
  b : @math.Vec2,
) -> ColliderShape2d {
  Segment(a, b)
}

///|
pub fn ColliderShape2d::polyline(
  vertices : Array[@math.Vec2],
  indices? : Array[(Int, Int)]? = None,
) -> ColliderShape2d {
  Polyline(vertices, indices)
}

///|
/// The vertices are expected to describe a convex polygon in counter-clockwise order.
pub fn ColliderShape2d::convex_polygon(
  vertices : Array[@math.Vec2],
) -> ColliderShape2d {
  ConvexPolygon(vertices)
}

///|
pub fn ColliderShape2d::trimesh(
  vertices : Array[@math.Vec2],
  indices : Array[(Int, Int, Int)],
) -> ColliderShape2d {
  TriMesh(vertices, indices)
}

///|
pub fn ColliderShape2d::compound(
  parts : Array[(@math.Transform, ColliderShape2d)],
) -> ColliderShape2d {
  Compound(parts)
}

///|
pub fn ColliderShape2d::raw(shape : @collision.Shape) -> ColliderShape2d {
  Raw(shape)
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Collider2d {
  shape : ColliderShape2d
  sensor : Bool
}

///|
pub fn Collider2d::new(shape : ColliderShape2d) -> Collider2d {
  { shape, sensor: false }
}

///|
pub fn Collider2d::sensor(self : Collider2d, sensor : Bool) -> Collider2d {
  Collider2d::{ ..self, sensor, }
}

///|
/// Attach a collider entity to a different rigid-body entity.
///
/// This is the 2D equivalent of Bevy+Rapier "child colliders": set `RigidBody2d`
/// on one entity and `Collider2d + ColliderParent2d` on another to create
/// multi-collider rigid bodies.
///
/// Note: The collider entity's `@math.Transform` is interpreted as the collider
/// pose relative to the parent body.
#ecs.component
pub struct ColliderParent2d {
  parent : @core.Entity
}

///|
pub fn ColliderParent2d::new(parent : @core.Entity) -> ColliderParent2d {
  { parent, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Velocity2d {
  linvel : @math.Vec2
  angvel : Float
}

///|
pub fn Velocity2d::zero() -> Velocity2d {
  { linvel: @math.Vec2::new(0.0F, 0.0F), angvel: 0.0F }
}

///|
pub fn Velocity2d::new(linvel : @math.Vec2, angvel : Float) -> Velocity2d {
  { linvel, angvel }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Damping2d {
  linear : Float
  angular : Float
}

///|
pub fn Damping2d::new(linear : Float, angular : Float) -> Damping2d {
  { linear, angular }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct GravityScale2d {
  scale : Float
}

///|
pub fn GravityScale2d::new(scale : Float) -> GravityScale2d {
  GravityScale2d::{ scale, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct LockedAxes2d {
  lock_translations : Bool
  lock_rotations : Bool
}

///|
pub fn LockedAxes2d::new(
  lock_translations : Bool,
  lock_rotations : Bool,
) -> LockedAxes2d {
  { lock_translations, lock_rotations }
}

///|
pub fn LockedAxes2d::locked() -> LockedAxes2d {
  { lock_translations: true, lock_rotations: true }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Ccd2d {
  enabled : Bool
  soft_prediction : Float
}

///|
pub fn Ccd2d::enabled() -> Ccd2d {
  { enabled: true, soft_prediction: 0.0F }
}

///|
pub fn Ccd2d::new(enabled : Bool, soft_prediction : Float) -> Ccd2d {
  { enabled, soft_prediction }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Dominance2d {
  group : Int
}

///|
pub fn Dominance2d::new(group : Int) -> Dominance2d {
  Dominance2d::{ group, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Sleeping2d {
  sleeping : Bool
}

///|
pub fn Sleeping2d::new(sleeping : Bool) -> Sleeping2d {
  Sleeping2d::{ sleeping, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ExternalForce2d {
  force : @math.Vec2
  torque : Float
}

///|
pub fn ExternalForce2d::zero() -> ExternalForce2d {
  { force: @math.Vec2::new(0.0F, 0.0F), torque: 0.0F }
}

///|
pub fn ExternalForce2d::new(
  force : @math.Vec2,
  torque : Float,
) -> ExternalForce2d {
  { force, torque }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ExternalImpulse2d {
  impulse : @math.Vec2
  torque_impulse : Float
}

///|
pub fn ExternalImpulse2d::zero() -> ExternalImpulse2d {
  { impulse: @math.Vec2::new(0.0F, 0.0F), torque_impulse: 0.0F }
}

///|
pub fn ExternalImpulse2d::new(
  impulse : @math.Vec2,
  torque_impulse : Float,
) -> ExternalImpulse2d {
  { impulse, torque_impulse }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ContactForceEventThreshold2d {
  threshold : Float
}

///|
pub fn ContactForceEventThreshold2d::new(
  threshold : Float,
) -> ContactForceEventThreshold2d {
  ContactForceEventThreshold2d::{ threshold, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct ColliderDensity2d {
  density : Float
}

///|
pub fn ColliderDensity2d::new(density : Float) -> ColliderDensity2d {
  { density, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Friction2d {
  coefficient : Float
}

///|
pub fn Friction2d::new(coefficient : Float) -> Friction2d {
  { coefficient, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct FrictionCombineRule2d {
  rule : @dynamics.CoefficientCombineRule
}

///|
pub fn FrictionCombineRule2d::new(
  rule : @dynamics.CoefficientCombineRule,
) -> FrictionCombineRule2d {
  { rule, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Restitution2d {
  coefficient : Float
}

///|
pub fn Restitution2d::new(coefficient : Float) -> Restitution2d {
  { coefficient, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct RestitutionCombineRule2d {
  rule : @dynamics.CoefficientCombineRule
}

///|
pub fn RestitutionCombineRule2d::new(
  rule : @dynamics.CoefficientCombineRule,
) -> RestitutionCombineRule2d {
  { rule, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct CollisionGroups2d {
  memberships : Int
  filter : Int
  test_mode : @dynamics.InteractionTestMode
}

///|
pub fn CollisionGroups2d::new(
  memberships : Int,
  filter : Int,
  test_mode : @dynamics.InteractionTestMode,
) -> CollisionGroups2d {
  { memberships, filter, test_mode }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct SolverGroups2d {
  memberships : Int
  filter : Int
  test_mode : @dynamics.InteractionTestMode
}

///|
pub fn SolverGroups2d::new(
  memberships : Int,
  filter : Int,
  test_mode : @dynamics.InteractionTestMode,
) -> SolverGroups2d {
  { memberships, filter, test_mode }
}

///|
/// Enable/disable a collider without despawning it.
#ecs.component
pub struct ColliderEnabled2d {
  enabled : Bool
}

///|
pub fn ColliderEnabled2d::new(enabled : Bool) -> ColliderEnabled2d {
  { enabled, }
}

///|
pub fn ColliderEnabled2d::disabled() -> ColliderEnabled2d {
  { enabled: false }
}

///|
/// Per-collider active collision type mask.
#ecs.component
pub struct ActiveCollisionTypes2d {
  types : @collision.ActiveCollisionTypes
}

///|
pub fn ActiveCollisionTypes2d::new(
  types : @collision.ActiveCollisionTypes,
) -> ActiveCollisionTypes2d {
  { types, }
}

///|
/// Per-collider active event mask (collision/contact-force events).
#ecs.component
pub struct ActiveEvents2d {
  events : @collision.ActiveEvents
}

///|
pub fn ActiveEvents2d::new(events : @collision.ActiveEvents) -> ActiveEvents2d {
  { events, }
}

///|
/// Per-collider active hook mask (enables contact/intersection filtering, etc.).
#ecs.component
pub struct ActiveHooks2d {
  hooks : @collision.ActiveHooks
}

///|
pub fn ActiveHooks2d::new(hooks : @collision.ActiveHooks) -> ActiveHooks2d {
  { hooks, }
}

///|
/// Per-collider contact skin thickness.
#ecs.component
pub struct ContactSkin2d {
  skin : Float
}

///|
pub fn ContactSkin2d::new(skin : Float) -> ContactSkin2d {
  { skin, }
}

///|
/// Override per-collider mass properties.
#ecs.component
pub struct ColliderMassProperties2d {
  mass_properties : @rapier_core.MassProperties
}

///|
pub fn ColliderMassProperties2d::new(
  mass_properties : @rapier_core.MassProperties,
) -> ColliderMassProperties2d {
  { mass_properties, }
}

///|
/// Enable/disable a rigid body without despawning it.
#ecs.component
pub struct RigidBodyEnabled2d {
  enabled : Bool
}

///|
pub fn RigidBodyEnabled2d::new(enabled : Bool) -> RigidBodyEnabled2d {
  { enabled, }
}

///|
pub fn RigidBodyEnabled2d::disabled() -> RigidBodyEnabled2d {
  { enabled: false }
}

///|
/// Additional mass-properties applied on top of the collider-derived mass.
#ecs.component
pub struct AdditionalMassProperties2d {
  props : @dynamics.RigidBodyAdditionalMassProps
}

///|
pub fn AdditionalMassProperties2d::mass(
  mass : Float,
) -> AdditionalMassProperties2d {
  { props: @dynamics.RigidBodyAdditionalMassProps::mass(mass) }
}

///|
pub fn AdditionalMassProperties2d::mass_properties(
  props : @rapier_core.MassProperties,
) -> AdditionalMassProperties2d {
  { props: @dynamics.RigidBodyAdditionalMassProps::mass_properties(props) }
}

///|
/// Additional solver iterations for a rigid body.
#ecs.component
pub struct AdditionalSolverIterations2d {
  iterations : Int
}

///|
pub fn AdditionalSolverIterations2d::new(
  iterations : Int,
) -> AdditionalSolverIterations2d {
  { iterations, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct RapierBodyHandle2d {
  handle : @dynamics.RigidBodyHandle
}

///|
pub fn RapierBodyHandle2d::new(
  handle : @dynamics.RigidBodyHandle,
) -> RapierBodyHandle2d {
  { handle, }
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct RapierColliderHandle2d {
  handle : @collision.ColliderHandle
}

///|
pub fn RapierColliderHandle2d::new(
  handle : @collision.ColliderHandle,
) -> RapierColliderHandle2d {
  { handle, }
}

///|
/// Joint authoring components live in `physics2d_joints.mbt`.

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct Physics2dConfig {
  gravity : @math.Vec2
  /// If false, the physics pipeline does not step.
  physics_pipeline_active : Bool
  /// Integration parameters (dt is overridden by mgstudio fixed timestep).
  integration : @dynamics.IntegrationParameters
}

///|
pub fn Physics2dConfig::default() -> Physics2dConfig {
  {
    gravity: @math.Vec2::new(0.0F, -9.81F),
    physics_pipeline_active: true,
    integration: @dynamics.IntegrationParameters::default(),
  }
}

///|
pub fn Physics2dConfig::new(gravity : @math.Vec2) -> Physics2dConfig {
  Physics2dConfig::{ ..Physics2dConfig::default(), gravity, }
}

///|
pub fn Physics2dConfig::with_gravity(
  self : Physics2dConfig,
  gravity : @math.Vec2,
) -> Physics2dConfig {
  Physics2dConfig::{ ..self, gravity, }
}

///|
pub fn Physics2dConfig::with_physics_pipeline_active(
  self : Physics2dConfig,
  active : Bool,
) -> Physics2dConfig {
  Physics2dConfig::{ ..self, physics_pipeline_active: active }
}

///|
pub fn Physics2dConfig::with_integration_parameters(
  self : Physics2dConfig,
  integration : @dynamics.IntegrationParameters,
) -> Physics2dConfig {
  Physics2dConfig::{ ..self, integration, }
}

///|
// ECS resource marker for codegen (`mgstudio gen`).
#ecs.resource
pub struct Physics2dContext {
  rigid_bodies : @dynamics.RigidBodySet
  colliders : @collision.ColliderSet
  islands : @dynamics.IslandManager
  broad_phase : @collision.BroadPhaseBvh
  narrow_phase : @collision.NarrowPhase
  impulse_joints : @dynamics.ImpulseJointSet
  multibody_joints : @dynamics.MultibodyJointSet
  ccd : @dynamics.CCDSolver
  mut pipeline : @pipeline.PhysicsPipeline
  mut integration : @dynamics.IntegrationParameters
  mut hooks : @pipeline.PhysicsHooks
  mut event_handler : @pipeline.EventHandler
  mut query_pipeline : @collision.QueryPipelineMut

  // (entity.id, entity.generation) -> handle
  entity_to_body : @hashmap.HashMap[(Int, Int), @dynamics.RigidBodyHandle]
  entity_to_collider : @hashmap.HashMap[(Int, Int), @collision.ColliderHandle]
  entity_to_impulse_joint : @hashmap.HashMap[
    (Int, Int),
    @dynamics.ImpulseJointHandle,
  ]
  entity_to_multibody_joint : @hashmap.HashMap[
    (Int, Int),
    @dynamics.MultibodyJointHandle,
  ]
  // (collider_handle.id, collider_handle.generation) -> entity
  collider_to_entity : @hashmap.HashMap[(Int, Int), @core.Entity]
}

///|
pub fn Physics2dContext::new() -> Physics2dContext {
  let rigid_bodies = @dynamics.RigidBodySet::new()
  let colliders = @collision.ColliderSet::new()
  let query_pipeline = @collision.QueryPipelineMut::new(
    @collision.QueryFilter::new(),
    rigid_bodies,
    colliders,
  )
  Physics2dContext::{
    rigid_bodies,
    colliders,
    islands: @dynamics.IslandManager::new(),
    broad_phase: @collision.BroadPhaseBvh::new(),
    narrow_phase: @collision.NarrowPhase::new(),
    impulse_joints: @dynamics.ImpulseJointSet::new(),
    multibody_joints: @dynamics.MultibodyJointSet::new(),
    ccd: @dynamics.CCDSolver::new(),
    pipeline: @pipeline.PhysicsPipeline::new(),
    integration: @dynamics.IntegrationParameters::default(),
    hooks: @pipeline.PhysicsHooks::new(),
    event_handler: @pipeline.EventHandler::new(),
    query_pipeline,
    entity_to_body: @hashmap.HashMap::new(),
    entity_to_collider: @hashmap.HashMap::new(),
    entity_to_impulse_joint: @hashmap.HashMap::new(),
    entity_to_multibody_joint: @hashmap.HashMap::new(),
    collider_to_entity: @hashmap.HashMap::new(),
  }
}

///|
pub fn Physics2dContext::query(
  self : Physics2dContext,
) -> @collision.QueryPipeline {
  self.query_pipeline.as_ref()
}

///|
pub fn[
  W : @core.ChangeTickWorld + @core.SystemContextWorld + @core.SpawnWorld + @math.Has_Transform + Has_RigidBody2d + Has_Collider2d + Has_ColliderParent2d + Has_KinematicCharacterController2d + Has_KinematicCharacterControllerOutput2d + Has_Velocity2d + Has_Damping2d + Has_GravityScale2d + Has_LockedAxes2d + Has_Ccd2d + Has_Dominance2d + Has_Sleeping2d + Has_ExternalForce2d + Has_ExternalImpulse2d + Has_RigidBodyEnabled2d + Has_AdditionalMassProperties2d + Has_AdditionalSolverIterations2d + Has_ContactForceEventThreshold2d + Has_ColliderDensity2d + Has_Friction2d + Has_FrictionCombineRule2d + Has_Restitution2d + Has_RestitutionCombineRule2d + Has_CollisionGroups2d + Has_SolverGroups2d + Has_ColliderEnabled2d + Has_ActiveCollisionTypes2d + Has_ActiveEvents2d + Has_ActiveHooks2d + Has_ContactSkin2d + Has_ColliderMassProperties2d + Has_ImpulseJoint2d + Has_MultibodyJoint2d + Has_RapierBodyHandle2d + Has_RapierColliderHandle2d + Has_RapierImpulseJointHandle2d + Has_RapierMultibodyJointHandle2d + HasRes_Physics2dConfig + HasRes_Physics2dContext + HasRes_Physics2dEvents + HasRes_Physics2dHooks,
] physics2d_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_startup_system(physics2d_init_resources_system)
  .add_pre_update_system(physics2d_clear_events_system)
  .add_pre_update_system(physics2d_cleanup_despawned_system)
  .add_fixed_update_system(physics2d_sync_insertions_system)
  .add_fixed_update_system(physics2d_sync_joints_system)
  .add_fixed_update_system(physics2d_sync_world_to_rapier_system)
  .add_fixed_update_system(physics2d_character_controller_system)
  .add_fixed_update_system(physics2d_step_system)
  .add_fixed_update_system(physics2d_writeback_system)
  .add_post_update_system(physics2d_debug_render_system)
}
