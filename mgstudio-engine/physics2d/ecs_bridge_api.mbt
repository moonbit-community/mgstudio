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
/// ECS component bridge types.
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
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = [
  "Physics2dConfig", "Physics2dEvents", "Physics2dContext",
]

///|
pub let ecs_res_key_physics2d_config : @ecs.ResourceKey[Physics2dConfig] = @ecs.register_resource(
  debug_name="physics2d.physics2d_config",
)

///|
pub let ecs_res_key_physics2d_events : @ecs.ResourceKey[Physics2dEvents] = @ecs.register_resource(
  debug_name="physics2d.physics2d_events",
)

///|
pub let ecs_res_key_physics2d_context : @ecs.ResourceKey[Physics2dContext] = @ecs.register_resource(
  debug_name="physics2d.physics2d_context",
)

///|

///|
pub let ecs_key_ccd2d : @ecs.ComponentKey[Ccd2d] = @ecs.register_component(
  debug_name="physics2d.ccd2d",
)

///|
pub let ecs_key_damping2d : @ecs.ComponentKey[Damping2d] = @ecs.register_component(
  debug_name="physics2d.damping2d",
)

///|
pub let ecs_key_collider2d : @ecs.ComponentKey[Collider2d] = @ecs.register_component(
  debug_name="physics2d.collider2d",
)

///|
pub let ecs_key_friction2d : @ecs.ComponentKey[Friction2d] = @ecs.register_component(
  debug_name="physics2d.friction2d",
)

///|
pub let ecs_key_sleeping2d : @ecs.ComponentKey[Sleeping2d] = @ecs.register_component(
  debug_name="physics2d.sleeping2d",
)

///|
pub let ecs_key_velocity2d : @ecs.ComponentKey[Velocity2d] = @ecs.register_component(
  debug_name="physics2d.velocity2d",
)

///|
pub let ecs_key_dominance2d : @ecs.ComponentKey[Dominance2d] = @ecs.register_component(
  debug_name="physics2d.dominance2d",
)

///|
pub let ecs_key_rigid_body2d : @ecs.ComponentKey[RigidBody2d] = @ecs.register_component(
  debug_name="physics2d.rigid_body2d",
)

///|
pub let ecs_key_locked_axes2d : @ecs.ComponentKey[LockedAxes2d] = @ecs.register_component(
  debug_name="physics2d.locked_axes2d",
)

///|
pub let ecs_key_active_hooks2d : @ecs.ComponentKey[ActiveHooks2d] = @ecs.register_component(
  debug_name="physics2d.active_hooks2d",
)

///|
pub let ecs_key_contact_skin2d : @ecs.ComponentKey[ContactSkin2d] = @ecs.register_component(
  debug_name="physics2d.contact_skin2d",
)

///|
pub let ecs_key_restitution2d : @ecs.ComponentKey[Restitution2d] = @ecs.register_component(
  debug_name="physics2d.restitution2d",
)

///|
pub let ecs_key_active_events2d : @ecs.ComponentKey[ActiveEvents2d] = @ecs.register_component(
  debug_name="physics2d.active_events2d",
)

///|
pub let ecs_key_gravity_scale2d : @ecs.ComponentKey[GravityScale2d] = @ecs.register_component(
  debug_name="physics2d.gravity_scale2d",
)

///|
pub let ecs_key_impulse_joint2d : @ecs.ComponentKey[ImpulseJoint2d] = @ecs.register_component(
  debug_name="physics2d.impulse_joint2d",
)

///|
pub let ecs_key_solver_groups2d : @ecs.ComponentKey[SolverGroups2d] = @ecs.register_component(
  debug_name="physics2d.solver_groups2d",
)

///|
pub let ecs_key_external_force2d : @ecs.ComponentKey[ExternalForce2d] = @ecs.register_component(
  debug_name="physics2d.external_force2d",
)

///|
pub let ecs_key_collider_parent2d : @ecs.ComponentKey[ColliderParent2d] = @ecs.register_component(
  debug_name="physics2d.collider_parent2d",
)

///|
pub let ecs_key_multibody_joint2d : @ecs.ComponentKey[MultibodyJoint2d] = @ecs.register_component(
  debug_name="physics2d.multibody_joint2d",
)

///|
pub let ecs_key_collider_density2d : @ecs.ComponentKey[ColliderDensity2d] = @ecs.register_component(
  debug_name="physics2d.collider_density2d",
)

///|
pub let ecs_key_collider_enabled2d : @ecs.ComponentKey[ColliderEnabled2d] = @ecs.register_component(
  debug_name="physics2d.collider_enabled2d",
)

///|
pub let ecs_key_collision_groups2d : @ecs.ComponentKey[CollisionGroups2d] = @ecs.register_component(
  debug_name="physics2d.collision_groups2d",
)

///|
pub let ecs_key_external_impulse2d : @ecs.ComponentKey[ExternalImpulse2d] = @ecs.register_component(
  debug_name="physics2d.external_impulse2d",
)

///|
pub let ecs_key_rapier_body_handle2d : @ecs.ComponentKey[RapierBodyHandle2d] = @ecs.register_component(
  debug_name="physics2d.rapier_body_handle2d",
)

///|
pub let ecs_key_rigid_body_enabled2d : @ecs.ComponentKey[RigidBodyEnabled2d] = @ecs.register_component(
  debug_name="physics2d.rigid_body_enabled2d",
)

///|
pub let ecs_key_friction_combine_rule2d : @ecs.ComponentKey[
  FrictionCombineRule2d,
] = @ecs.register_component(debug_name="physics2d.friction_combine_rule2d")

///|
pub let ecs_key_active_collision_types2d : @ecs.ComponentKey[
  ActiveCollisionTypes2d,
] = @ecs.register_component(debug_name="physics2d.active_collision_types2d")

///|
pub let ecs_key_rapier_collider_handle2d : @ecs.ComponentKey[
  RapierColliderHandle2d,
] = @ecs.register_component(debug_name="physics2d.rapier_collider_handle2d")

///|
pub let ecs_key_collider_mass_properties2d : @ecs.ComponentKey[
  ColliderMassProperties2d,
] = @ecs.register_component(debug_name="physics2d.collider_mass_properties2d")

///|
pub let ecs_key_restitution_combine_rule2d : @ecs.ComponentKey[
  RestitutionCombineRule2d,
] = @ecs.register_component(debug_name="physics2d.restitution_combine_rule2d")

///|
pub let ecs_key_additional_mass_properties2d : @ecs.ComponentKey[
  AdditionalMassProperties2d,
] = @ecs.register_component(debug_name="physics2d.additional_mass_properties2d")

///|
pub let ecs_key_rapier_impulse_joint_handle2d : @ecs.ComponentKey[
  RapierImpulseJointHandle2d,
] = @ecs.register_component(
  debug_name="physics2d.rapier_impulse_joint_handle2d",
)

///|
pub let ecs_key_additional_solver_iterations2d : @ecs.ComponentKey[
  AdditionalSolverIterations2d,
] = @ecs.register_component(
  debug_name="physics2d.additional_solver_iterations2d",
)

///|
pub let ecs_key_contact_force_event_threshold2d : @ecs.ComponentKey[
  ContactForceEventThreshold2d,
] = @ecs.register_component(
  debug_name="physics2d.contact_force_event_threshold2d",
)

///|
pub let ecs_key_rapier_multibody_joint_handle2d : @ecs.ComponentKey[
  RapierMultibodyJointHandle2d,
] = @ecs.register_component(
  debug_name="physics2d.rapier_multibody_joint_handle2d",
)

///|
pub let ecs_key_kinematic_character_controller2d : @ecs.ComponentKey[
  KinematicCharacterController2d,
] = @ecs.register_component(
  debug_name="physics2d.kinematic_character_controller2d",
)

///|
pub let ecs_key_kinematic_character_controller_output2d : @ecs.ComponentKey[
  KinematicCharacterControllerOutput2d,
] = @ecs.register_component(
  debug_name="physics2d.kinematic_character_controller_output2d",
)

///|
pub(open) trait Has_Ccd2d {
  get_ccd2d_store(self : Self) -> @ecs.ComponentAccess[Ccd2d]
}

///|
pub(open) trait Has_Damping2d {
  get_damping2d_store(self : Self) -> @ecs.ComponentAccess[Damping2d]
}

///|
pub(open) trait Has_Collider2d {
  get_collider2d_store(self : Self) -> @ecs.ComponentAccess[Collider2d]
}

///|
pub(open) trait Has_Friction2d {
  get_friction2d_store(self : Self) -> @ecs.ComponentAccess[Friction2d]
}

///|
pub(open) trait Has_Sleeping2d {
  get_sleeping2d_store(self : Self) -> @ecs.ComponentAccess[Sleeping2d]
}

///|
pub(open) trait Has_Velocity2d {
  get_velocity2d_store(self : Self) -> @ecs.ComponentAccess[Velocity2d]
}

///|
pub(open) trait Has_Dominance2d {
  get_dominance2d_store(self : Self) -> @ecs.ComponentAccess[Dominance2d]
}

///|
pub(open) trait Has_RigidBody2d {
  get_rigid_body2d_store(self : Self) -> @ecs.ComponentAccess[RigidBody2d]
}

///|
pub(open) trait Has_LockedAxes2d {
  get_locked_axes2d_store(self : Self) -> @ecs.ComponentAccess[LockedAxes2d]
}

///|
pub(open) trait Has_ActiveHooks2d {
  get_active_hooks2d_store(self : Self) -> @ecs.ComponentAccess[ActiveHooks2d]
}

///|
pub(open) trait Has_ContactSkin2d {
  get_contact_skin2d_store(self : Self) -> @ecs.ComponentAccess[ContactSkin2d]
}

///|
pub(open) trait Has_Restitution2d {
  get_restitution2d_store(self : Self) -> @ecs.ComponentAccess[Restitution2d]
}

///|
pub(open) trait Has_ActiveEvents2d {
  get_active_events2d_store(self : Self) -> @ecs.ComponentAccess[ActiveEvents2d]
}

///|
pub(open) trait Has_GravityScale2d {
  get_gravity_scale2d_store(self : Self) -> @ecs.ComponentAccess[GravityScale2d]
}

///|
pub(open) trait Has_ImpulseJoint2d {
  get_impulse_joint2d_store(self : Self) -> @ecs.ComponentAccess[ImpulseJoint2d]
}

///|
pub(open) trait Has_SolverGroups2d {
  get_solver_groups2d_store(self : Self) -> @ecs.ComponentAccess[SolverGroups2d]
}

///|
pub(open) trait Has_ExternalForce2d {
  get_external_force2d_store(self : Self) -> @ecs.ComponentAccess[
    ExternalForce2d,
  ]
}

///|
pub(open) trait Has_ColliderParent2d {
  get_collider_parent2d_store(self : Self) -> @ecs.ComponentAccess[
    ColliderParent2d,
  ]
}

///|
pub(open) trait Has_MultibodyJoint2d {
  get_multibody_joint2d_store(self : Self) -> @ecs.ComponentAccess[
    MultibodyJoint2d,
  ]
}

///|
pub(open) trait Has_ColliderDensity2d {
  get_collider_density2d_store(self : Self) -> @ecs.ComponentAccess[
    ColliderDensity2d,
  ]
}

///|
pub(open) trait Has_ColliderEnabled2d {
  get_collider_enabled2d_store(self : Self) -> @ecs.ComponentAccess[
    ColliderEnabled2d,
  ]
}

///|
pub(open) trait Has_CollisionGroups2d {
  get_collision_groups2d_store(self : Self) -> @ecs.ComponentAccess[
    CollisionGroups2d,
  ]
}

///|
pub(open) trait Has_ExternalImpulse2d {
  get_external_impulse2d_store(self : Self) -> @ecs.ComponentAccess[
    ExternalImpulse2d,
  ]
}

///|
pub(open) trait Has_RapierBodyHandle2d {
  get_rapier_body_handle2d_store(self : Self) -> @ecs.ComponentAccess[
    RapierBodyHandle2d,
  ]
}

///|
pub(open) trait Has_RigidBodyEnabled2d {
  get_rigid_body_enabled2d_store(self : Self) -> @ecs.ComponentAccess[
    RigidBodyEnabled2d,
  ]
}

///|
pub(open) trait Has_FrictionCombineRule2d {
  get_friction_combine_rule2d_store(self : Self) -> @ecs.ComponentAccess[
    FrictionCombineRule2d,
  ]
}

///|
pub(open) trait Has_ActiveCollisionTypes2d {
  get_active_collision_types2d_store(self : Self) -> @ecs.ComponentAccess[
    ActiveCollisionTypes2d,
  ]
}

///|
pub(open) trait Has_RapierColliderHandle2d {
  get_rapier_collider_handle2d_store(self : Self) -> @ecs.ComponentAccess[
    RapierColliderHandle2d,
  ]
}

///|
pub(open) trait Has_ColliderMassProperties2d {
  get_collider_mass_properties2d_store(self : Self) -> @ecs.ComponentAccess[
    ColliderMassProperties2d,
  ]
}

///|
pub(open) trait Has_RestitutionCombineRule2d {
  get_restitution_combine_rule2d_store(self : Self) -> @ecs.ComponentAccess[
    RestitutionCombineRule2d,
  ]
}

///|
pub(open) trait Has_AdditionalMassProperties2d {
  get_additional_mass_properties2d_store(self : Self) -> @ecs.ComponentAccess[
    AdditionalMassProperties2d,
  ]
}

///|
pub(open) trait Has_RapierImpulseJointHandle2d {
  get_rapier_impulse_joint_handle2d_store(self : Self) -> @ecs.ComponentAccess[
    RapierImpulseJointHandle2d,
  ]
}

///|
pub(open) trait Has_AdditionalSolverIterations2d {
  get_additional_solver_iterations2d_store(self : Self) -> @ecs.ComponentAccess[
    AdditionalSolverIterations2d,
  ]
}

///|
pub(open) trait Has_ContactForceEventThreshold2d {
  get_contact_force_event_threshold2d_store(self : Self) -> @ecs.ComponentAccess[
    ContactForceEventThreshold2d,
  ]
}

///|
pub(open) trait Has_RapierMultibodyJointHandle2d {
  get_rapier_multibody_joint_handle2d_store(self : Self) -> @ecs.ComponentAccess[
    RapierMultibodyJointHandle2d,
  ]
}

///|
pub(open) trait Has_KinematicCharacterController2d {
  get_kinematic_character_controller2d_store(self : Self) -> @ecs.ComponentAccess[
    KinematicCharacterController2d,
  ]
}

///|
pub(open) trait Has_KinematicCharacterControllerOutput2d {
  get_kinematic_character_controller_output2d_store(self : Self) -> @ecs.ComponentAccess[
    KinematicCharacterControllerOutput2d,
  ]
}

///|
pub fn[W : Has_Ccd2d] get_ccd2d_store(world : W) -> @ecs.ComponentAccess[Ccd2d] {
  world.get_ccd2d_store()
}

///|
pub fn[W : Has_Damping2d] get_damping2d_store(
  world : W,
) -> @ecs.ComponentAccess[Damping2d] {
  world.get_damping2d_store()
}

///|
pub fn[W : Has_Collider2d] get_collider2d_store(
  world : W,
) -> @ecs.ComponentAccess[Collider2d] {
  world.get_collider2d_store()
}

///|
pub fn[W : Has_Friction2d] get_friction2d_store(
  world : W,
) -> @ecs.ComponentAccess[Friction2d] {
  world.get_friction2d_store()
}

///|
pub fn[W : Has_Sleeping2d] get_sleeping2d_store(
  world : W,
) -> @ecs.ComponentAccess[Sleeping2d] {
  world.get_sleeping2d_store()
}

///|
pub fn[W : Has_Velocity2d] get_velocity2d_store(
  world : W,
) -> @ecs.ComponentAccess[Velocity2d] {
  world.get_velocity2d_store()
}

///|
pub fn[W : Has_Dominance2d] get_dominance2d_store(
  world : W,
) -> @ecs.ComponentAccess[Dominance2d] {
  world.get_dominance2d_store()
}

///|
pub fn[W : Has_RigidBody2d] get_rigid_body2d_store(
  world : W,
) -> @ecs.ComponentAccess[RigidBody2d] {
  world.get_rigid_body2d_store()
}

///|
pub fn[W : Has_LockedAxes2d] get_locked_axes2d_store(
  world : W,
) -> @ecs.ComponentAccess[LockedAxes2d] {
  world.get_locked_axes2d_store()
}

///|
pub fn[W : Has_ActiveHooks2d] get_active_hooks2d_store(
  world : W,
) -> @ecs.ComponentAccess[ActiveHooks2d] {
  world.get_active_hooks2d_store()
}

///|
pub fn[W : Has_ContactSkin2d] get_contact_skin2d_store(
  world : W,
) -> @ecs.ComponentAccess[ContactSkin2d] {
  world.get_contact_skin2d_store()
}

///|
pub fn[W : Has_Restitution2d] get_restitution2d_store(
  world : W,
) -> @ecs.ComponentAccess[Restitution2d] {
  world.get_restitution2d_store()
}

///|
pub fn[W : Has_ActiveEvents2d] get_active_events2d_store(
  world : W,
) -> @ecs.ComponentAccess[ActiveEvents2d] {
  world.get_active_events2d_store()
}

///|
pub fn[W : Has_GravityScale2d] get_gravity_scale2d_store(
  world : W,
) -> @ecs.ComponentAccess[GravityScale2d] {
  world.get_gravity_scale2d_store()
}

///|
pub fn[W : Has_ImpulseJoint2d] get_impulse_joint2d_store(
  world : W,
) -> @ecs.ComponentAccess[ImpulseJoint2d] {
  world.get_impulse_joint2d_store()
}

///|
pub fn[W : Has_SolverGroups2d] get_solver_groups2d_store(
  world : W,
) -> @ecs.ComponentAccess[SolverGroups2d] {
  world.get_solver_groups2d_store()
}

///|
pub fn[W : Has_ExternalForce2d] get_external_force2d_store(
  world : W,
) -> @ecs.ComponentAccess[ExternalForce2d] {
  world.get_external_force2d_store()
}

///|
pub fn[W : Has_ColliderParent2d] get_collider_parent2d_store(
  world : W,
) -> @ecs.ComponentAccess[ColliderParent2d] {
  world.get_collider_parent2d_store()
}

///|
pub fn[W : Has_MultibodyJoint2d] get_multibody_joint2d_store(
  world : W,
) -> @ecs.ComponentAccess[MultibodyJoint2d] {
  world.get_multibody_joint2d_store()
}

///|
pub fn[W : Has_ColliderDensity2d] get_collider_density2d_store(
  world : W,
) -> @ecs.ComponentAccess[ColliderDensity2d] {
  world.get_collider_density2d_store()
}

///|
pub fn[W : Has_ColliderEnabled2d] get_collider_enabled2d_store(
  world : W,
) -> @ecs.ComponentAccess[ColliderEnabled2d] {
  world.get_collider_enabled2d_store()
}

///|
pub fn[W : Has_CollisionGroups2d] get_collision_groups2d_store(
  world : W,
) -> @ecs.ComponentAccess[CollisionGroups2d] {
  world.get_collision_groups2d_store()
}

///|
pub fn[W : Has_ExternalImpulse2d] get_external_impulse2d_store(
  world : W,
) -> @ecs.ComponentAccess[ExternalImpulse2d] {
  world.get_external_impulse2d_store()
}

///|
pub fn[W : Has_RapierBodyHandle2d] get_rapier_body_handle2d_store(
  world : W,
) -> @ecs.ComponentAccess[RapierBodyHandle2d] {
  world.get_rapier_body_handle2d_store()
}

///|
pub fn[W : Has_RigidBodyEnabled2d] get_rigid_body_enabled2d_store(
  world : W,
) -> @ecs.ComponentAccess[RigidBodyEnabled2d] {
  world.get_rigid_body_enabled2d_store()
}

///|
pub fn[W : Has_FrictionCombineRule2d] get_friction_combine_rule2d_store(
  world : W,
) -> @ecs.ComponentAccess[FrictionCombineRule2d] {
  world.get_friction_combine_rule2d_store()
}

///|
pub fn[W : Has_ActiveCollisionTypes2d] get_active_collision_types2d_store(
  world : W,
) -> @ecs.ComponentAccess[ActiveCollisionTypes2d] {
  world.get_active_collision_types2d_store()
}

///|
pub fn[W : Has_RapierColliderHandle2d] get_rapier_collider_handle2d_store(
  world : W,
) -> @ecs.ComponentAccess[RapierColliderHandle2d] {
  world.get_rapier_collider_handle2d_store()
}

///|
pub fn[W : Has_ColliderMassProperties2d] get_collider_mass_properties2d_store(
  world : W,
) -> @ecs.ComponentAccess[ColliderMassProperties2d] {
  world.get_collider_mass_properties2d_store()
}

///|
pub fn[W : Has_RestitutionCombineRule2d] get_restitution_combine_rule2d_store(
  world : W,
) -> @ecs.ComponentAccess[RestitutionCombineRule2d] {
  world.get_restitution_combine_rule2d_store()
}

///|
pub fn[W : Has_AdditionalMassProperties2d] get_additional_mass_properties2d_store(
  world : W,
) -> @ecs.ComponentAccess[AdditionalMassProperties2d] {
  world.get_additional_mass_properties2d_store()
}

///|
pub fn[W : Has_RapierImpulseJointHandle2d] get_rapier_impulse_joint_handle2d_store(
  world : W,
) -> @ecs.ComponentAccess[RapierImpulseJointHandle2d] {
  world.get_rapier_impulse_joint_handle2d_store()
}

///|
pub fn[W : Has_AdditionalSolverIterations2d] get_additional_solver_iterations2d_store(
  world : W,
) -> @ecs.ComponentAccess[AdditionalSolverIterations2d] {
  world.get_additional_solver_iterations2d_store()
}

///|
pub fn[W : Has_ContactForceEventThreshold2d] get_contact_force_event_threshold2d_store(
  world : W,
) -> @ecs.ComponentAccess[ContactForceEventThreshold2d] {
  world.get_contact_force_event_threshold2d_store()
}

///|
pub fn[W : Has_RapierMultibodyJointHandle2d] get_rapier_multibody_joint_handle2d_store(
  world : W,
) -> @ecs.ComponentAccess[RapierMultibodyJointHandle2d] {
  world.get_rapier_multibody_joint_handle2d_store()
}

///|
pub fn[W : Has_KinematicCharacterController2d] get_kinematic_character_controller2d_store(
  world : W,
) -> @ecs.ComponentAccess[KinematicCharacterController2d] {
  world.get_kinematic_character_controller2d_store()
}

///|
pub fn[W : Has_KinematicCharacterControllerOutput2d] get_kinematic_character_controller_output2d_store(
  world : W,
) -> @ecs.ComponentAccess[KinematicCharacterControllerOutput2d] {
  world.get_kinematic_character_controller_output2d_store()
}

///|
pub(open) trait HasRes_Physics2dConfig {
  get_physics2d_config_resource(self : Self) -> @ecs.ResourceAccess[
    Physics2dConfig,
  ]
}

///|
pub(open) trait HasRes_Physics2dEvents {
  get_physics2d_events_resource(self : Self) -> @ecs.ResourceAccess[
    Physics2dEvents,
  ]
}

///|
pub(open) trait HasRes_Physics2dContext {
  get_physics2d_context_resource(self : Self) -> @ecs.ResourceAccess[
    Physics2dContext,
  ]
}

///|
pub fn[W : HasRes_Physics2dConfig] get_physics2d_config_resource(
  world : W,
) -> @ecs.ResourceAccess[Physics2dConfig] {
  world.get_physics2d_config_resource()
}

///|
pub fn[W : HasRes_Physics2dEvents] get_physics2d_events_resource(
  world : W,
) -> @ecs.ResourceAccess[Physics2dEvents] {
  world.get_physics2d_events_resource()
}

///|
pub fn[W : HasRes_Physics2dContext] get_physics2d_context_resource(
  world : W,
) -> @ecs.ResourceAccess[Physics2dContext] {
  world.get_physics2d_context_resource()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_Ccd2d for @ecs.World with get_ccd2d_store(self) {
  self.component(ecs_key_ccd2d)
}

///|
pub impl Has_Damping2d for @ecs.World with get_damping2d_store(self) {
  self.component(ecs_key_damping2d)
}

///|
pub impl Has_Collider2d for @ecs.World with get_collider2d_store(self) {
  self.component(ecs_key_collider2d)
}

///|
pub impl Has_Friction2d for @ecs.World with get_friction2d_store(self) {
  self.component(ecs_key_friction2d)
}

///|
pub impl Has_Sleeping2d for @ecs.World with get_sleeping2d_store(self) {
  self.component(ecs_key_sleeping2d)
}

///|
pub impl Has_Velocity2d for @ecs.World with get_velocity2d_store(self) {
  self.component(ecs_key_velocity2d)
}

///|
pub impl Has_Dominance2d for @ecs.World with get_dominance2d_store(self) {
  self.component(ecs_key_dominance2d)
}

///|
pub impl Has_RigidBody2d for @ecs.World with get_rigid_body2d_store(self) {
  self.component(ecs_key_rigid_body2d)
}

///|
pub impl Has_LockedAxes2d for @ecs.World with get_locked_axes2d_store(self) {
  self.component(ecs_key_locked_axes2d)
}

///|
pub impl Has_ActiveHooks2d for @ecs.World with get_active_hooks2d_store(self) {
  self.component(ecs_key_active_hooks2d)
}

///|
pub impl Has_ContactSkin2d for @ecs.World with get_contact_skin2d_store(self) {
  self.component(ecs_key_contact_skin2d)
}

///|
pub impl Has_Restitution2d for @ecs.World with get_restitution2d_store(self) {
  self.component(ecs_key_restitution2d)
}

///|
pub impl Has_ActiveEvents2d for @ecs.World with get_active_events2d_store(self) {
  self.component(ecs_key_active_events2d)
}

///|
pub impl Has_GravityScale2d for @ecs.World with get_gravity_scale2d_store(self) {
  self.component(ecs_key_gravity_scale2d)
}

///|
pub impl Has_ImpulseJoint2d for @ecs.World with get_impulse_joint2d_store(self) {
  self.component(ecs_key_impulse_joint2d)
}

///|
pub impl Has_SolverGroups2d for @ecs.World with get_solver_groups2d_store(self) {
  self.component(ecs_key_solver_groups2d)
}

///|
pub impl Has_ExternalForce2d for @ecs.World with get_external_force2d_store(
  self,
) {
  self.component(ecs_key_external_force2d)
}

///|
pub impl Has_ColliderParent2d for @ecs.World with get_collider_parent2d_store(
  self,
) {
  self.component(ecs_key_collider_parent2d)
}

///|
pub impl Has_MultibodyJoint2d for @ecs.World with get_multibody_joint2d_store(
  self,
) {
  self.component(ecs_key_multibody_joint2d)
}

///|
pub impl Has_ColliderDensity2d for @ecs.World with get_collider_density2d_store(
  self,
) {
  self.component(ecs_key_collider_density2d)
}

///|
pub impl Has_ColliderEnabled2d for @ecs.World with get_collider_enabled2d_store(
  self,
) {
  self.component(ecs_key_collider_enabled2d)
}

///|
pub impl Has_CollisionGroups2d for @ecs.World with get_collision_groups2d_store(
  self,
) {
  self.component(ecs_key_collision_groups2d)
}

///|
pub impl Has_ExternalImpulse2d for @ecs.World with get_external_impulse2d_store(
  self,
) {
  self.component(ecs_key_external_impulse2d)
}

///|
pub impl Has_RapierBodyHandle2d for @ecs.World with get_rapier_body_handle2d_store(
  self,
) {
  self.component(ecs_key_rapier_body_handle2d)
}

///|
pub impl Has_RigidBodyEnabled2d for @ecs.World with get_rigid_body_enabled2d_store(
  self,
) {
  self.component(ecs_key_rigid_body_enabled2d)
}

///|
pub impl Has_FrictionCombineRule2d for @ecs.World with get_friction_combine_rule2d_store(
  self,
) {
  self.component(ecs_key_friction_combine_rule2d)
}

///|
pub impl Has_ActiveCollisionTypes2d for @ecs.World with get_active_collision_types2d_store(
  self,
) {
  self.component(ecs_key_active_collision_types2d)
}

///|
pub impl Has_RapierColliderHandle2d for @ecs.World with get_rapier_collider_handle2d_store(
  self,
) {
  self.component(ecs_key_rapier_collider_handle2d)
}

///|
pub impl Has_ColliderMassProperties2d for @ecs.World with get_collider_mass_properties2d_store(
  self,
) {
  self.component(ecs_key_collider_mass_properties2d)
}

///|
pub impl Has_RestitutionCombineRule2d for @ecs.World with get_restitution_combine_rule2d_store(
  self,
) {
  self.component(ecs_key_restitution_combine_rule2d)
}

///|
pub impl Has_AdditionalMassProperties2d for @ecs.World with get_additional_mass_properties2d_store(
  self,
) {
  self.component(ecs_key_additional_mass_properties2d)
}

///|
pub impl Has_RapierImpulseJointHandle2d for @ecs.World with get_rapier_impulse_joint_handle2d_store(
  self,
) {
  self.component(ecs_key_rapier_impulse_joint_handle2d)
}

///|
pub impl Has_AdditionalSolverIterations2d for @ecs.World with get_additional_solver_iterations2d_store(
  self,
) {
  self.component(ecs_key_additional_solver_iterations2d)
}

///|
pub impl Has_ContactForceEventThreshold2d for @ecs.World with get_contact_force_event_threshold2d_store(
  self,
) {
  self.component(ecs_key_contact_force_event_threshold2d)
}

///|
pub impl Has_RapierMultibodyJointHandle2d for @ecs.World with get_rapier_multibody_joint_handle2d_store(
  self,
) {
  self.component(ecs_key_rapier_multibody_joint_handle2d)
}

///|
pub impl Has_KinematicCharacterController2d for @ecs.World with get_kinematic_character_controller2d_store(
  self,
) {
  self.component(ecs_key_kinematic_character_controller2d)
}

///|
pub impl Has_KinematicCharacterControllerOutput2d for @ecs.World with get_kinematic_character_controller_output2d_store(
  self,
) {
  self.component(ecs_key_kinematic_character_controller_output2d)
}

///|
pub impl HasRes_Physics2dConfig for @ecs.World with get_physics2d_config_resource(
  self,
) {
  self.resource(ecs_res_key_physics2d_config)
}

///|
pub impl HasRes_Physics2dEvents for @ecs.World with get_physics2d_events_resource(
  self,
) {
  self.resource(ecs_res_key_physics2d_events)
}

///|
pub impl HasRes_Physics2dContext for @ecs.World with get_physics2d_context_resource(
  self,
) {
  self.resource(ecs_res_key_physics2d_context)
}

///|
/// End ECS bridge impls.
