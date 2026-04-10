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
pub let ecs_resources : Array[String] = [
  "Physics2dConfig", "Physics2dEvents", "Physics2dContext", "Physics2dHooksConfig",
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
pub let ecs_res_key_physics2d_hooks_config : @ecs.ResourceKey[
  Physics2dHooksConfig,
] = @ecs.register_resource(debug_name="physics2d.physics2d_hooks_config")

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
pub impl @ecs.Component for Ccd2d with component() {
  ecs_key_ccd2d
}

///|
pub impl @ecs.Component for Damping2d with component() {
  ecs_key_damping2d
}

///|
pub impl @ecs.Component for Collider2d with component() {
  ecs_key_collider2d
}

///|
pub impl @ecs.Component for Friction2d with component() {
  ecs_key_friction2d
}

///|
pub impl @ecs.Component for Sleeping2d with component() {
  ecs_key_sleeping2d
}

///|
pub impl @ecs.Component for Velocity2d with component() {
  ecs_key_velocity2d
}

///|
pub impl @ecs.Component for Dominance2d with component() {
  ecs_key_dominance2d
}

///|
pub impl @ecs.Component for RigidBody2d with component() {
  ecs_key_rigid_body2d
}

///|
pub impl @ecs.Component for LockedAxes2d with component() {
  ecs_key_locked_axes2d
}

///|
pub impl @ecs.Component for ActiveHooks2d with component() {
  ecs_key_active_hooks2d
}

///|
pub impl @ecs.Component for ContactSkin2d with component() {
  ecs_key_contact_skin2d
}

///|
pub impl @ecs.Component for Restitution2d with component() {
  ecs_key_restitution2d
}

///|
pub impl @ecs.Component for ActiveEvents2d with component() {
  ecs_key_active_events2d
}

///|
pub impl @ecs.Component for GravityScale2d with component() {
  ecs_key_gravity_scale2d
}

///|
pub impl @ecs.Component for ImpulseJoint2d with component() {
  ecs_key_impulse_joint2d
}

///|
pub impl @ecs.Component for SolverGroups2d with component() {
  ecs_key_solver_groups2d
}

///|
pub impl @ecs.Component for ExternalForce2d with component() {
  ecs_key_external_force2d
}

///|
pub impl @ecs.Component for ColliderParent2d with component() {
  ecs_key_collider_parent2d
}

///|
pub impl @ecs.Component for MultibodyJoint2d with component() {
  ecs_key_multibody_joint2d
}

///|
pub impl @ecs.Component for ColliderDensity2d with component() {
  ecs_key_collider_density2d
}

///|
pub impl @ecs.Component for ColliderEnabled2d with component() {
  ecs_key_collider_enabled2d
}

///|
pub impl @ecs.Component for CollisionGroups2d with component() {
  ecs_key_collision_groups2d
}

///|
pub impl @ecs.Component for ExternalImpulse2d with component() {
  ecs_key_external_impulse2d
}

///|
pub impl @ecs.Component for RapierBodyHandle2d with component() {
  ecs_key_rapier_body_handle2d
}

///|
pub impl @ecs.Component for RigidBodyEnabled2d with component() {
  ecs_key_rigid_body_enabled2d
}

///|
pub impl @ecs.Component for FrictionCombineRule2d with component() {
  ecs_key_friction_combine_rule2d
}

///|
pub impl @ecs.Component for ActiveCollisionTypes2d with component() {
  ecs_key_active_collision_types2d
}

///|
pub impl @ecs.Component for RapierColliderHandle2d with component() {
  ecs_key_rapier_collider_handle2d
}

///|
pub impl @ecs.Component for ColliderMassProperties2d with component() {
  ecs_key_collider_mass_properties2d
}

///|
pub impl @ecs.Component for RestitutionCombineRule2d with component() {
  ecs_key_restitution_combine_rule2d
}

///|
pub impl @ecs.Component for AdditionalMassProperties2d with component() {
  ecs_key_additional_mass_properties2d
}

///|
pub impl @ecs.Component for RapierImpulseJointHandle2d with component() {
  ecs_key_rapier_impulse_joint_handle2d
}

///|
pub impl @ecs.Component for AdditionalSolverIterations2d with component() {
  ecs_key_additional_solver_iterations2d
}

///|
pub impl @ecs.Component for ContactForceEventThreshold2d with component() {
  ecs_key_contact_force_event_threshold2d
}

///|
pub impl @ecs.Component for RapierMultibodyJointHandle2d with component() {
  ecs_key_rapier_multibody_joint_handle2d
}

///|
pub impl @ecs.Component for KinematicCharacterController2d with component() {
  ecs_key_kinematic_character_controller2d
}

///|
pub impl @ecs.Component for KinematicCharacterControllerOutput2d with component() {
  ecs_key_kinematic_character_controller_output2d
}

///|
pub fn get_physics2d_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics2dConfig] {
  world.resource(ecs_res_key_physics2d_config)
}

///|
pub fn get_physics2d_events_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics2dEvents] {
  world.resource(ecs_res_key_physics2d_events)
}

///|
pub fn get_physics2d_context_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics2dContext] {
  world.resource(ecs_res_key_physics2d_context)
}

///|
pub fn get_physics2d_hooks_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics2dHooksConfig] {
  world.resource(ecs_res_key_physics2d_hooks_config)
}
