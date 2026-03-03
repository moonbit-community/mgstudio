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
/// Legacy ECS component types.
pub let ecs_components : Array[String] = [
  "Ccd2d", "Damping2d", "Collider2d", "Friction2d", "Sleeping2d", "Velocity2d", "Dominance2d",
  "RigidBody2d", "LockedAxes2d", "ActiveHooks2d", "ContactSkin2d", "Restitution2d",
  "ActiveEvents2d", "GravityScale2d", "ImpulseJoint2d", "SolverGroups2d", "ExternalForce2d",
  "ColliderParent2d", "MultibodyJoint2d", "ColliderDensity2d", "ColliderEnabled2d",
  "CollisionGroups2d", "ExternalImpulse2d", "RapierBodyHandle2d", "RigidBodyEnabled2d",
  "FrictionCombineRule2d", "ActiveCollisionTypes2d", "RapierColliderHandle2d", "ColliderMassProperties2d",
  "RestitutionCombineRule2d", "AdditionalMassProperties2d", "RapierImpulseJointHandle2d",
  "AdditionalSolverIterations2d", "ContactForceEventThreshold2d", "RapierMultibodyJointHandle2d",
  "KinematicCharacterController2d", "KinematicCharacterControllerOutput2d",
]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = [
  "Physics2dConfig", "Physics2dEvents", "Physics2dContext",
]

///|
pub(open) trait Has_Ccd2d {
  get_ccd2d_store(self : Self) -> @core.ComponentStore[Ccd2d]
}

///|
pub(open) trait Has_Damping2d {
  get_damping2d_store(self : Self) -> @core.ComponentStore[Damping2d]
}

///|
pub(open) trait Has_Collider2d {
  get_collider2d_store(self : Self) -> @core.ComponentStore[Collider2d]
}

///|
pub(open) trait Has_Friction2d {
  get_friction2d_store(self : Self) -> @core.ComponentStore[Friction2d]
}

///|
pub(open) trait Has_Sleeping2d {
  get_sleeping2d_store(self : Self) -> @core.ComponentStore[Sleeping2d]
}

///|
pub(open) trait Has_Velocity2d {
  get_velocity2d_store(self : Self) -> @core.ComponentStore[Velocity2d]
}

///|
pub(open) trait Has_Dominance2d {
  get_dominance2d_store(self : Self) -> @core.ComponentStore[Dominance2d]
}

///|
pub(open) trait Has_RigidBody2d {
  get_rigid_body2d_store(self : Self) -> @core.ComponentStore[RigidBody2d]
}

///|
pub(open) trait Has_LockedAxes2d {
  get_locked_axes2d_store(self : Self) -> @core.ComponentStore[LockedAxes2d]
}

///|
pub(open) trait Has_ActiveHooks2d {
  get_active_hooks2d_store(self : Self) -> @core.ComponentStore[ActiveHooks2d]
}

///|
pub(open) trait Has_ContactSkin2d {
  get_contact_skin2d_store(self : Self) -> @core.ComponentStore[ContactSkin2d]
}

///|
pub(open) trait Has_Restitution2d {
  get_restitution2d_store(self : Self) -> @core.ComponentStore[Restitution2d]
}

///|
pub(open) trait Has_ActiveEvents2d {
  get_active_events2d_store(self : Self) -> @core.ComponentStore[ActiveEvents2d]
}

///|
pub(open) trait Has_GravityScale2d {
  get_gravity_scale2d_store(self : Self) -> @core.ComponentStore[GravityScale2d]
}

///|
pub(open) trait Has_ImpulseJoint2d {
  get_impulse_joint2d_store(self : Self) -> @core.ComponentStore[ImpulseJoint2d]
}

///|
pub(open) trait Has_SolverGroups2d {
  get_solver_groups2d_store(self : Self) -> @core.ComponentStore[SolverGroups2d]
}

///|
pub(open) trait Has_ExternalForce2d {
  get_external_force2d_store(self : Self) -> @core.ComponentStore[
    ExternalForce2d,
  ]
}

///|
pub(open) trait Has_ColliderParent2d {
  get_collider_parent2d_store(self : Self) -> @core.ComponentStore[
    ColliderParent2d,
  ]
}

///|
pub(open) trait Has_MultibodyJoint2d {
  get_multibody_joint2d_store(self : Self) -> @core.ComponentStore[
    MultibodyJoint2d,
  ]
}

///|
pub(open) trait Has_ColliderDensity2d {
  get_collider_density2d_store(self : Self) -> @core.ComponentStore[
    ColliderDensity2d,
  ]
}

///|
pub(open) trait Has_ColliderEnabled2d {
  get_collider_enabled2d_store(self : Self) -> @core.ComponentStore[
    ColliderEnabled2d,
  ]
}

///|
pub(open) trait Has_CollisionGroups2d {
  get_collision_groups2d_store(self : Self) -> @core.ComponentStore[
    CollisionGroups2d,
  ]
}

///|
pub(open) trait Has_ExternalImpulse2d {
  get_external_impulse2d_store(self : Self) -> @core.ComponentStore[
    ExternalImpulse2d,
  ]
}

///|
pub(open) trait Has_RapierBodyHandle2d {
  get_rapier_body_handle2d_store(self : Self) -> @core.ComponentStore[
    RapierBodyHandle2d,
  ]
}

///|
pub(open) trait Has_RigidBodyEnabled2d {
  get_rigid_body_enabled2d_store(self : Self) -> @core.ComponentStore[
    RigidBodyEnabled2d,
  ]
}

///|
pub(open) trait Has_FrictionCombineRule2d {
  get_friction_combine_rule2d_store(self : Self) -> @core.ComponentStore[
    FrictionCombineRule2d,
  ]
}

///|
pub(open) trait Has_ActiveCollisionTypes2d {
  get_active_collision_types2d_store(self : Self) -> @core.ComponentStore[
    ActiveCollisionTypes2d,
  ]
}

///|
pub(open) trait Has_RapierColliderHandle2d {
  get_rapier_collider_handle2d_store(self : Self) -> @core.ComponentStore[
    RapierColliderHandle2d,
  ]
}

///|
pub(open) trait Has_ColliderMassProperties2d {
  get_collider_mass_properties2d_store(self : Self) -> @core.ComponentStore[
    ColliderMassProperties2d,
  ]
}

///|
pub(open) trait Has_RestitutionCombineRule2d {
  get_restitution_combine_rule2d_store(self : Self) -> @core.ComponentStore[
    RestitutionCombineRule2d,
  ]
}

///|
pub(open) trait Has_AdditionalMassProperties2d {
  get_additional_mass_properties2d_store(self : Self) -> @core.ComponentStore[
    AdditionalMassProperties2d,
  ]
}

///|
pub(open) trait Has_RapierImpulseJointHandle2d {
  get_rapier_impulse_joint_handle2d_store(self : Self) -> @core.ComponentStore[
    RapierImpulseJointHandle2d,
  ]
}

///|
pub(open) trait Has_AdditionalSolverIterations2d {
  get_additional_solver_iterations2d_store(self : Self) -> @core.ComponentStore[
    AdditionalSolverIterations2d,
  ]
}

///|
pub(open) trait Has_ContactForceEventThreshold2d {
  get_contact_force_event_threshold2d_store(self : Self) -> @core.ComponentStore[
    ContactForceEventThreshold2d,
  ]
}

///|
pub(open) trait Has_RapierMultibodyJointHandle2d {
  get_rapier_multibody_joint_handle2d_store(self : Self) -> @core.ComponentStore[
    RapierMultibodyJointHandle2d,
  ]
}

///|
pub(open) trait Has_KinematicCharacterController2d {
  get_kinematic_character_controller2d_store(self : Self) -> @core.ComponentStore[
    KinematicCharacterController2d,
  ]
}

///|
pub(open) trait Has_KinematicCharacterControllerOutput2d {
  get_kinematic_character_controller_output2d_store(self : Self) -> @core.ComponentStore[
    KinematicCharacterControllerOutput2d,
  ]
}

///|
pub fn[W : Has_Ccd2d] get_ccd2d_store(world : W) -> @core.ComponentStore[Ccd2d] {
  world.get_ccd2d_store()
}

///|
pub fn[W : Has_Damping2d] get_damping2d_store(
  world : W,
) -> @core.ComponentStore[Damping2d] {
  world.get_damping2d_store()
}

///|
pub fn[W : Has_Collider2d] get_collider2d_store(
  world : W,
) -> @core.ComponentStore[Collider2d] {
  world.get_collider2d_store()
}

///|
pub fn[W : Has_Friction2d] get_friction2d_store(
  world : W,
) -> @core.ComponentStore[Friction2d] {
  world.get_friction2d_store()
}

///|
pub fn[W : Has_Sleeping2d] get_sleeping2d_store(
  world : W,
) -> @core.ComponentStore[Sleeping2d] {
  world.get_sleeping2d_store()
}

///|
pub fn[W : Has_Velocity2d] get_velocity2d_store(
  world : W,
) -> @core.ComponentStore[Velocity2d] {
  world.get_velocity2d_store()
}

///|
pub fn[W : Has_Dominance2d] get_dominance2d_store(
  world : W,
) -> @core.ComponentStore[Dominance2d] {
  world.get_dominance2d_store()
}

///|
pub fn[W : Has_RigidBody2d] get_rigid_body2d_store(
  world : W,
) -> @core.ComponentStore[RigidBody2d] {
  world.get_rigid_body2d_store()
}

///|
pub fn[W : Has_LockedAxes2d] get_locked_axes2d_store(
  world : W,
) -> @core.ComponentStore[LockedAxes2d] {
  world.get_locked_axes2d_store()
}

///|
pub fn[W : Has_ActiveHooks2d] get_active_hooks2d_store(
  world : W,
) -> @core.ComponentStore[ActiveHooks2d] {
  world.get_active_hooks2d_store()
}

///|
pub fn[W : Has_ContactSkin2d] get_contact_skin2d_store(
  world : W,
) -> @core.ComponentStore[ContactSkin2d] {
  world.get_contact_skin2d_store()
}

///|
pub fn[W : Has_Restitution2d] get_restitution2d_store(
  world : W,
) -> @core.ComponentStore[Restitution2d] {
  world.get_restitution2d_store()
}

///|
pub fn[W : Has_ActiveEvents2d] get_active_events2d_store(
  world : W,
) -> @core.ComponentStore[ActiveEvents2d] {
  world.get_active_events2d_store()
}

///|
pub fn[W : Has_GravityScale2d] get_gravity_scale2d_store(
  world : W,
) -> @core.ComponentStore[GravityScale2d] {
  world.get_gravity_scale2d_store()
}

///|
pub fn[W : Has_ImpulseJoint2d] get_impulse_joint2d_store(
  world : W,
) -> @core.ComponentStore[ImpulseJoint2d] {
  world.get_impulse_joint2d_store()
}

///|
pub fn[W : Has_SolverGroups2d] get_solver_groups2d_store(
  world : W,
) -> @core.ComponentStore[SolverGroups2d] {
  world.get_solver_groups2d_store()
}

///|
pub fn[W : Has_ExternalForce2d] get_external_force2d_store(
  world : W,
) -> @core.ComponentStore[ExternalForce2d] {
  world.get_external_force2d_store()
}

///|
pub fn[W : Has_ColliderParent2d] get_collider_parent2d_store(
  world : W,
) -> @core.ComponentStore[ColliderParent2d] {
  world.get_collider_parent2d_store()
}

///|
pub fn[W : Has_MultibodyJoint2d] get_multibody_joint2d_store(
  world : W,
) -> @core.ComponentStore[MultibodyJoint2d] {
  world.get_multibody_joint2d_store()
}

///|
pub fn[W : Has_ColliderDensity2d] get_collider_density2d_store(
  world : W,
) -> @core.ComponentStore[ColliderDensity2d] {
  world.get_collider_density2d_store()
}

///|
pub fn[W : Has_ColliderEnabled2d] get_collider_enabled2d_store(
  world : W,
) -> @core.ComponentStore[ColliderEnabled2d] {
  world.get_collider_enabled2d_store()
}

///|
pub fn[W : Has_CollisionGroups2d] get_collision_groups2d_store(
  world : W,
) -> @core.ComponentStore[CollisionGroups2d] {
  world.get_collision_groups2d_store()
}

///|
pub fn[W : Has_ExternalImpulse2d] get_external_impulse2d_store(
  world : W,
) -> @core.ComponentStore[ExternalImpulse2d] {
  world.get_external_impulse2d_store()
}

///|
pub fn[W : Has_RapierBodyHandle2d] get_rapier_body_handle2d_store(
  world : W,
) -> @core.ComponentStore[RapierBodyHandle2d] {
  world.get_rapier_body_handle2d_store()
}

///|
pub fn[W : Has_RigidBodyEnabled2d] get_rigid_body_enabled2d_store(
  world : W,
) -> @core.ComponentStore[RigidBodyEnabled2d] {
  world.get_rigid_body_enabled2d_store()
}

///|
pub fn[W : Has_FrictionCombineRule2d] get_friction_combine_rule2d_store(
  world : W,
) -> @core.ComponentStore[FrictionCombineRule2d] {
  world.get_friction_combine_rule2d_store()
}

///|
pub fn[W : Has_ActiveCollisionTypes2d] get_active_collision_types2d_store(
  world : W,
) -> @core.ComponentStore[ActiveCollisionTypes2d] {
  world.get_active_collision_types2d_store()
}

///|
pub fn[W : Has_RapierColliderHandle2d] get_rapier_collider_handle2d_store(
  world : W,
) -> @core.ComponentStore[RapierColliderHandle2d] {
  world.get_rapier_collider_handle2d_store()
}

///|
pub fn[W : Has_ColliderMassProperties2d] get_collider_mass_properties2d_store(
  world : W,
) -> @core.ComponentStore[ColliderMassProperties2d] {
  world.get_collider_mass_properties2d_store()
}

///|
pub fn[W : Has_RestitutionCombineRule2d] get_restitution_combine_rule2d_store(
  world : W,
) -> @core.ComponentStore[RestitutionCombineRule2d] {
  world.get_restitution_combine_rule2d_store()
}

///|
pub fn[W : Has_AdditionalMassProperties2d] get_additional_mass_properties2d_store(
  world : W,
) -> @core.ComponentStore[AdditionalMassProperties2d] {
  world.get_additional_mass_properties2d_store()
}

///|
pub fn[W : Has_RapierImpulseJointHandle2d] get_rapier_impulse_joint_handle2d_store(
  world : W,
) -> @core.ComponentStore[RapierImpulseJointHandle2d] {
  world.get_rapier_impulse_joint_handle2d_store()
}

///|
pub fn[W : Has_AdditionalSolverIterations2d] get_additional_solver_iterations2d_store(
  world : W,
) -> @core.ComponentStore[AdditionalSolverIterations2d] {
  world.get_additional_solver_iterations2d_store()
}

///|
pub fn[W : Has_ContactForceEventThreshold2d] get_contact_force_event_threshold2d_store(
  world : W,
) -> @core.ComponentStore[ContactForceEventThreshold2d] {
  world.get_contact_force_event_threshold2d_store()
}

///|
pub fn[W : Has_RapierMultibodyJointHandle2d] get_rapier_multibody_joint_handle2d_store(
  world : W,
) -> @core.ComponentStore[RapierMultibodyJointHandle2d] {
  world.get_rapier_multibody_joint_handle2d_store()
}

///|
pub fn[W : Has_KinematicCharacterController2d] get_kinematic_character_controller2d_store(
  world : W,
) -> @core.ComponentStore[KinematicCharacterController2d] {
  world.get_kinematic_character_controller2d_store()
}

///|
pub fn[W : Has_KinematicCharacterControllerOutput2d] get_kinematic_character_controller_output2d_store(
  world : W,
) -> @core.ComponentStore[KinematicCharacterControllerOutput2d] {
  world.get_kinematic_character_controller_output2d_store()
}

///|
pub(open) trait HasRes_Physics2dConfig {
  get_physics2d_config_resource(self : Self) -> @core.Resource[Physics2dConfig]
}

///|
pub(open) trait HasRes_Physics2dEvents {
  get_physics2d_events_resource(self : Self) -> @core.Resource[Physics2dEvents]
}

///|
pub(open) trait HasRes_Physics2dContext {
  get_physics2d_context_resource(self : Self) -> @core.Resource[
    Physics2dContext,
  ]
}

///|
pub fn[W : HasRes_Physics2dConfig] get_physics2d_config_resource(
  world : W,
) -> @core.Resource[Physics2dConfig] {
  world.get_physics2d_config_resource()
}

///|
pub fn[W : HasRes_Physics2dEvents] get_physics2d_events_resource(
  world : W,
) -> @core.Resource[Physics2dEvents] {
  world.get_physics2d_events_resource()
}

///|
pub fn[W : HasRes_Physics2dContext] get_physics2d_context_resource(
  world : W,
) -> @core.Resource[Physics2dContext] {
  world.get_physics2d_context_resource()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_ccd2d_store_by_world : Map[Int, @core.ComponentStore[Ccd2d]] = {}

///|
pub impl Has_Ccd2d for @ecs.World with get_ccd2d_store(self) {
  bridge_get_ccd2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_damping2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Damping2d],
] = {}

///|
pub impl Has_Damping2d for @ecs.World with get_damping2d_store(self) {
  bridge_get_damping2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_collider2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Collider2d],
] = {}

///|
pub impl Has_Collider2d for @ecs.World with get_collider2d_store(self) {
  bridge_get_collider2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_friction2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Friction2d],
] = {}

///|
pub impl Has_Friction2d for @ecs.World with get_friction2d_store(self) {
  bridge_get_friction2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_sleeping2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Sleeping2d],
] = {}

///|
pub impl Has_Sleeping2d for @ecs.World with get_sleeping2d_store(self) {
  bridge_get_sleeping2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_velocity2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Velocity2d],
] = {}

///|
pub impl Has_Velocity2d for @ecs.World with get_velocity2d_store(self) {
  bridge_get_velocity2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_dominance2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Dominance2d],
] = {}

///|
pub impl Has_Dominance2d for @ecs.World with get_dominance2d_store(self) {
  bridge_get_dominance2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_rigid_body2d_store_by_world : Map[
  Int,
  @core.ComponentStore[RigidBody2d],
] = {}

///|
pub impl Has_RigidBody2d for @ecs.World with get_rigid_body2d_store(self) {
  bridge_get_rigid_body2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_locked_axes2d_store_by_world : Map[
  Int,
  @core.ComponentStore[LockedAxes2d],
] = {}

///|
pub impl Has_LockedAxes2d for @ecs.World with get_locked_axes2d_store(self) {
  bridge_get_locked_axes2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_active_hooks2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ActiveHooks2d],
] = {}

///|
pub impl Has_ActiveHooks2d for @ecs.World with get_active_hooks2d_store(self) {
  bridge_get_active_hooks2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_contact_skin2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ContactSkin2d],
] = {}

///|
pub impl Has_ContactSkin2d for @ecs.World with get_contact_skin2d_store(self) {
  bridge_get_contact_skin2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_restitution2d_store_by_world : Map[
  Int,
  @core.ComponentStore[Restitution2d],
] = {}

///|
pub impl Has_Restitution2d for @ecs.World with get_restitution2d_store(self) {
  bridge_get_restitution2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_active_events2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ActiveEvents2d],
] = {}

///|
pub impl Has_ActiveEvents2d for @ecs.World with get_active_events2d_store(self) {
  bridge_get_active_events2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_gravity_scale2d_store_by_world : Map[
  Int,
  @core.ComponentStore[GravityScale2d],
] = {}

///|
pub impl Has_GravityScale2d for @ecs.World with get_gravity_scale2d_store(self) {
  bridge_get_gravity_scale2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_impulse_joint2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ImpulseJoint2d],
] = {}

///|
pub impl Has_ImpulseJoint2d for @ecs.World with get_impulse_joint2d_store(self) {
  bridge_get_impulse_joint2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_solver_groups2d_store_by_world : Map[
  Int,
  @core.ComponentStore[SolverGroups2d],
] = {}

///|
pub impl Has_SolverGroups2d for @ecs.World with get_solver_groups2d_store(self) {
  bridge_get_solver_groups2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_external_force2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ExternalForce2d],
] = {}

///|
pub impl Has_ExternalForce2d for @ecs.World with get_external_force2d_store(
  self,
) {
  bridge_get_external_force2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_collider_parent2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ColliderParent2d],
] = {}

///|
pub impl Has_ColliderParent2d for @ecs.World with get_collider_parent2d_store(
  self,
) {
  bridge_get_collider_parent2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_multibody_joint2d_store_by_world : Map[
  Int,
  @core.ComponentStore[MultibodyJoint2d],
] = {}

///|
pub impl Has_MultibodyJoint2d for @ecs.World with get_multibody_joint2d_store(
  self,
) {
  bridge_get_multibody_joint2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_collider_density2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ColliderDensity2d],
] = {}

///|
pub impl Has_ColliderDensity2d for @ecs.World with get_collider_density2d_store(
  self,
) {
  bridge_get_collider_density2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_collider_enabled2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ColliderEnabled2d],
] = {}

///|
pub impl Has_ColliderEnabled2d for @ecs.World with get_collider_enabled2d_store(
  self,
) {
  bridge_get_collider_enabled2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_collision_groups2d_store_by_world : Map[
  Int,
  @core.ComponentStore[CollisionGroups2d],
] = {}

///|
pub impl Has_CollisionGroups2d for @ecs.World with get_collision_groups2d_store(
  self,
) {
  bridge_get_collision_groups2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_external_impulse2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ExternalImpulse2d],
] = {}

///|
pub impl Has_ExternalImpulse2d for @ecs.World with get_external_impulse2d_store(
  self,
) {
  bridge_get_external_impulse2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_rapier_body_handle2d_store_by_world : Map[
  Int,
  @core.ComponentStore[RapierBodyHandle2d],
] = {}

///|
pub impl Has_RapierBodyHandle2d for @ecs.World with get_rapier_body_handle2d_store(
  self,
) {
  bridge_get_rapier_body_handle2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_rigid_body_enabled2d_store_by_world : Map[
  Int,
  @core.ComponentStore[RigidBodyEnabled2d],
] = {}

///|
pub impl Has_RigidBodyEnabled2d for @ecs.World with get_rigid_body_enabled2d_store(
  self,
) {
  bridge_get_rigid_body_enabled2d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_friction_combine_rule2d_store_by_world : Map[
  Int,
  @core.ComponentStore[FrictionCombineRule2d],
] = {}

///|
pub impl Has_FrictionCombineRule2d for @ecs.World with get_friction_combine_rule2d_store(
  self,
) {
  bridge_get_friction_combine_rule2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_active_collision_types2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ActiveCollisionTypes2d],
] = {}

///|
pub impl Has_ActiveCollisionTypes2d for @ecs.World with get_active_collision_types2d_store(
  self,
) {
  bridge_get_active_collision_types2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_rapier_collider_handle2d_store_by_world : Map[
  Int,
  @core.ComponentStore[RapierColliderHandle2d],
] = {}

///|
pub impl Has_RapierColliderHandle2d for @ecs.World with get_rapier_collider_handle2d_store(
  self,
) {
  bridge_get_rapier_collider_handle2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_collider_mass_properties2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ColliderMassProperties2d],
] = {}

///|
pub impl Has_ColliderMassProperties2d for @ecs.World with get_collider_mass_properties2d_store(
  self,
) {
  bridge_get_collider_mass_properties2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_restitution_combine_rule2d_store_by_world : Map[
  Int,
  @core.ComponentStore[RestitutionCombineRule2d],
] = {}

///|
pub impl Has_RestitutionCombineRule2d for @ecs.World with get_restitution_combine_rule2d_store(
  self,
) {
  bridge_get_restitution_combine_rule2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_additional_mass_properties2d_store_by_world : Map[
  Int,
  @core.ComponentStore[AdditionalMassProperties2d],
] = {}

///|
pub impl Has_AdditionalMassProperties2d for @ecs.World with get_additional_mass_properties2d_store(
  self,
) {
  bridge_get_additional_mass_properties2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_rapier_impulse_joint_handle2d_store_by_world : Map[
  Int,
  @core.ComponentStore[RapierImpulseJointHandle2d],
] = {}

///|
pub impl Has_RapierImpulseJointHandle2d for @ecs.World with get_rapier_impulse_joint_handle2d_store(
  self,
) {
  bridge_get_rapier_impulse_joint_handle2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_additional_solver_iterations2d_store_by_world : Map[
  Int,
  @core.ComponentStore[AdditionalSolverIterations2d],
] = {}

///|
pub impl Has_AdditionalSolverIterations2d for @ecs.World with get_additional_solver_iterations2d_store(
  self,
) {
  bridge_get_additional_solver_iterations2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_contact_force_event_threshold2d_store_by_world : Map[
  Int,
  @core.ComponentStore[ContactForceEventThreshold2d],
] = {}

///|
pub impl Has_ContactForceEventThreshold2d for @ecs.World with get_contact_force_event_threshold2d_store(
  self,
) {
  bridge_get_contact_force_event_threshold2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_rapier_multibody_joint_handle2d_store_by_world : Map[
  Int,
  @core.ComponentStore[RapierMultibodyJointHandle2d],
] = {}

///|
pub impl Has_RapierMultibodyJointHandle2d for @ecs.World with get_rapier_multibody_joint_handle2d_store(
  self,
) {
  bridge_get_rapier_multibody_joint_handle2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_kinematic_character_controller2d_store_by_world : Map[
  Int,
  @core.ComponentStore[KinematicCharacterController2d],
] = {}

///|
pub impl Has_KinematicCharacterController2d for @ecs.World with get_kinematic_character_controller2d_store(
  self,
) {
  bridge_get_kinematic_character_controller2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_kinematic_character_controller_output2d_store_by_world : Map[
  Int,
  @core.ComponentStore[KinematicCharacterControllerOutput2d],
] = {}

///|
pub impl Has_KinematicCharacterControllerOutput2d for @ecs.World with get_kinematic_character_controller_output2d_store(
  self,
) {
  bridge_get_kinematic_character_controller_output2d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_physics2d_config_resource_by_world : Map[
  Int,
  @core.Resource[Physics2dConfig],
] = {}

///|
pub impl HasRes_Physics2dConfig for @ecs.World with get_physics2d_config_resource(
  self,
) {
  bridge_get_physics2d_config_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_physics2d_events_resource_by_world : Map[
  Int,
  @core.Resource[Physics2dEvents],
] = {}

///|
pub impl HasRes_Physics2dEvents for @ecs.World with get_physics2d_events_resource(
  self,
) {
  bridge_get_physics2d_events_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_physics2d_context_resource_by_world : Map[
  Int,
  @core.Resource[Physics2dContext],
] = {}

///|
pub impl HasRes_Physics2dContext for @ecs.World with get_physics2d_context_resource(
  self,
) {
  bridge_get_physics2d_context_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
/// End ECS bridge impls.
