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
  "Ccd3d", "Damping3d", "Collider3d", "Friction3d", "Sleeping3d", "Velocity3d", "Dominance3d",
  "RigidBody3d", "LockedAxes3d", "ActiveHooks3d", "ContactSkin3d", "Restitution3d",
  "ActiveEvents3d", "GravityScale3d", "ImpulseJoint3d", "SolverGroups3d", "ExternalForce3d",
  "ColliderParent3d", "MultibodyJoint3d", "ColliderDensity3d", "ColliderEnabled3d",
  "CollisionGroups3d", "ExternalImpulse3d", "RapierBodyHandle3d", "RigidBodyEnabled3d",
  "FrictionCombineRule3d", "ActiveCollisionTypes3d", "RapierColliderHandle3d", "ColliderMassProperties3d",
  "RestitutionCombineRule3d", "AdditionalMassProperties3d", "RapierImpulseJointHandle3d",
  "AdditionalSolverIterations3d", "ContactForceEventThreshold3d", "RapierMultibodyJointHandle3d",
  "KinematicCharacterController3d", "KinematicCharacterControllerOutput3d",
]

///|
pub let ecs_resources : Array[String] = [
  "Physics3dConfig", "Physics3dEvents", "Physics3dContext", "Physics3dHooksConfig",
]

///|
pub let ecs_res_key_physics3d_config : @ecs.ResourceKey[Physics3dConfig] = @ecs.register_resource(
  debug_name="physics3d.physics3d_config",
)

///|
pub let ecs_res_key_physics3d_events : @ecs.ResourceKey[Physics3dEvents] = @ecs.register_resource(
  debug_name="physics3d.physics3d_events",
)

///|
pub let ecs_res_key_physics3d_context : @ecs.ResourceKey[Physics3dContext] = @ecs.register_resource(
  debug_name="physics3d.physics3d_context",
)

///|
pub let ecs_res_key_physics3d_hooks_config : @ecs.ResourceKey[
  Physics3dHooksConfig,
] = @ecs.register_resource(debug_name="physics3d.physics3d_hooks_config")

///|
pub let ecs_key_ccd3d : @ecs.ComponentKey[Ccd3d] = @ecs.register_component(
  debug_name="physics3d.ccd3d",
)

///|
pub let ecs_key_damping3d : @ecs.ComponentKey[Damping3d] = @ecs.register_component(
  debug_name="physics3d.damping3d",
)

///|
pub let ecs_key_collider3d : @ecs.ComponentKey[Collider3d] = @ecs.register_component(
  debug_name="physics3d.collider3d",
)

///|
pub let ecs_key_friction3d : @ecs.ComponentKey[Friction3d] = @ecs.register_component(
  debug_name="physics3d.friction3d",
)

///|
pub let ecs_key_sleeping3d : @ecs.ComponentKey[Sleeping3d] = @ecs.register_component(
  debug_name="physics3d.sleeping3d",
)

///|
pub let ecs_key_velocity3d : @ecs.ComponentKey[Velocity3d] = @ecs.register_component(
  debug_name="physics3d.velocity3d",
)

///|
pub let ecs_key_dominance3d : @ecs.ComponentKey[Dominance3d] = @ecs.register_component(
  debug_name="physics3d.dominance3d",
)

///|
pub let ecs_key_rigid_body3d : @ecs.ComponentKey[RigidBody3d] = @ecs.register_component(
  debug_name="physics3d.rigid_body3d",
)

///|
pub let ecs_key_locked_axes3d : @ecs.ComponentKey[LockedAxes3d] = @ecs.register_component(
  debug_name="physics3d.locked_axes3d",
)

///|
pub let ecs_key_active_hooks3d : @ecs.ComponentKey[ActiveHooks3d] = @ecs.register_component(
  debug_name="physics3d.active_hooks3d",
)

///|
pub let ecs_key_contact_skin3d : @ecs.ComponentKey[ContactSkin3d] = @ecs.register_component(
  debug_name="physics3d.contact_skin3d",
)

///|
pub let ecs_key_restitution3d : @ecs.ComponentKey[Restitution3d] = @ecs.register_component(
  debug_name="physics3d.restitution3d",
)

///|
pub let ecs_key_active_events3d : @ecs.ComponentKey[ActiveEvents3d] = @ecs.register_component(
  debug_name="physics3d.active_events3d",
)

///|
pub let ecs_key_gravity_scale3d : @ecs.ComponentKey[GravityScale3d] = @ecs.register_component(
  debug_name="physics3d.gravity_scale3d",
)

///|
pub let ecs_key_impulse_joint3d : @ecs.ComponentKey[ImpulseJoint3d] = @ecs.register_component(
  debug_name="physics3d.impulse_joint3d",
)

///|
pub let ecs_key_solver_groups3d : @ecs.ComponentKey[SolverGroups3d] = @ecs.register_component(
  debug_name="physics3d.solver_groups3d",
)

///|
pub let ecs_key_external_force3d : @ecs.ComponentKey[ExternalForce3d] = @ecs.register_component(
  debug_name="physics3d.external_force3d",
)

///|
pub let ecs_key_collider_parent3d : @ecs.ComponentKey[ColliderParent3d] = @ecs.register_component(
  debug_name="physics3d.collider_parent3d",
)

///|
pub let ecs_key_multibody_joint3d : @ecs.ComponentKey[MultibodyJoint3d] = @ecs.register_component(
  debug_name="physics3d.multibody_joint3d",
)

///|
pub let ecs_key_collider_density3d : @ecs.ComponentKey[ColliderDensity3d] = @ecs.register_component(
  debug_name="physics3d.collider_density3d",
)

///|
pub let ecs_key_collider_enabled3d : @ecs.ComponentKey[ColliderEnabled3d] = @ecs.register_component(
  debug_name="physics3d.collider_enabled3d",
)

///|
pub let ecs_key_collision_groups3d : @ecs.ComponentKey[CollisionGroups3d] = @ecs.register_component(
  debug_name="physics3d.collision_groups3d",
)

///|
pub let ecs_key_external_impulse3d : @ecs.ComponentKey[ExternalImpulse3d] = @ecs.register_component(
  debug_name="physics3d.external_impulse3d",
)

///|
pub let ecs_key_rapier_body_handle3d : @ecs.ComponentKey[RapierBodyHandle3d] = @ecs.register_component(
  debug_name="physics3d.rapier_body_handle3d",
)

///|
pub let ecs_key_rigid_body_enabled3d : @ecs.ComponentKey[RigidBodyEnabled3d] = @ecs.register_component(
  debug_name="physics3d.rigid_body_enabled3d",
)

///|
pub let ecs_key_friction_combine_rule3d : @ecs.ComponentKey[
  FrictionCombineRule3d,
] = @ecs.register_component(debug_name="physics3d.friction_combine_rule3d")

///|
pub let ecs_key_active_collision_types3d : @ecs.ComponentKey[
  ActiveCollisionTypes3d,
] = @ecs.register_component(debug_name="physics3d.active_collision_types3d")

///|
pub let ecs_key_rapier_collider_handle3d : @ecs.ComponentKey[
  RapierColliderHandle3d,
] = @ecs.register_component(debug_name="physics3d.rapier_collider_handle3d")

///|
pub let ecs_key_collider_mass_properties3d : @ecs.ComponentKey[
  ColliderMassProperties3d,
] = @ecs.register_component(debug_name="physics3d.collider_mass_properties3d")

///|
pub let ecs_key_restitution_combine_rule3d : @ecs.ComponentKey[
  RestitutionCombineRule3d,
] = @ecs.register_component(debug_name="physics3d.restitution_combine_rule3d")

///|
pub let ecs_key_additional_mass_properties3d : @ecs.ComponentKey[
  AdditionalMassProperties3d,
] = @ecs.register_component(debug_name="physics3d.additional_mass_properties3d")

///|
pub let ecs_key_rapier_impulse_joint_handle3d : @ecs.ComponentKey[
  RapierImpulseJointHandle3d,
] = @ecs.register_component(
  debug_name="physics3d.rapier_impulse_joint_handle3d",
)

///|
pub let ecs_key_additional_solver_iterations3d : @ecs.ComponentKey[
  AdditionalSolverIterations3d,
] = @ecs.register_component(
  debug_name="physics3d.additional_solver_iterations3d",
)

///|
pub let ecs_key_contact_force_event_threshold3d : @ecs.ComponentKey[
  ContactForceEventThreshold3d,
] = @ecs.register_component(
  debug_name="physics3d.contact_force_event_threshold3d",
)

///|
pub let ecs_key_rapier_multibody_joint_handle3d : @ecs.ComponentKey[
  RapierMultibodyJointHandle3d,
] = @ecs.register_component(
  debug_name="physics3d.rapier_multibody_joint_handle3d",
)

///|
pub let ecs_key_kinematic_character_controller3d : @ecs.ComponentKey[
  KinematicCharacterController3d,
] = @ecs.register_component(
  debug_name="physics3d.kinematic_character_controller3d",
)

///|
pub let ecs_key_kinematic_character_controller_output3d : @ecs.ComponentKey[
  KinematicCharacterControllerOutput3d,
] = @ecs.register_component(
  debug_name="physics3d.kinematic_character_controller_output3d",
)

///|
pub impl @ecs.Component for Ccd3d with component() {
  ecs_key_ccd3d
}

///|
pub impl @ecs.Component for Damping3d with component() {
  ecs_key_damping3d
}

///|
pub impl @ecs.Component for Collider3d with component() {
  ecs_key_collider3d
}

///|
pub impl @ecs.Component for Friction3d with component() {
  ecs_key_friction3d
}

///|
pub impl @ecs.Component for Sleeping3d with component() {
  ecs_key_sleeping3d
}

///|
pub impl @ecs.Component for Velocity3d with component() {
  ecs_key_velocity3d
}

///|
pub impl @ecs.Component for Dominance3d with component() {
  ecs_key_dominance3d
}

///|
pub impl @ecs.Component for RigidBody3d with component() {
  ecs_key_rigid_body3d
}

///|
pub impl @ecs.Component for LockedAxes3d with component() {
  ecs_key_locked_axes3d
}

///|
pub impl @ecs.Component for ActiveHooks3d with component() {
  ecs_key_active_hooks3d
}

///|
pub impl @ecs.Component for ContactSkin3d with component() {
  ecs_key_contact_skin3d
}

///|
pub impl @ecs.Component for Restitution3d with component() {
  ecs_key_restitution3d
}

///|
pub impl @ecs.Component for ActiveEvents3d with component() {
  ecs_key_active_events3d
}

///|
pub impl @ecs.Component for GravityScale3d with component() {
  ecs_key_gravity_scale3d
}

///|
pub impl @ecs.Component for ImpulseJoint3d with component() {
  ecs_key_impulse_joint3d
}

///|
pub impl @ecs.Component for SolverGroups3d with component() {
  ecs_key_solver_groups3d
}

///|
pub impl @ecs.Component for ExternalForce3d with component() {
  ecs_key_external_force3d
}

///|
pub impl @ecs.Component for ColliderParent3d with component() {
  ecs_key_collider_parent3d
}

///|
pub impl @ecs.Component for MultibodyJoint3d with component() {
  ecs_key_multibody_joint3d
}

///|
pub impl @ecs.Component for ColliderDensity3d with component() {
  ecs_key_collider_density3d
}

///|
pub impl @ecs.Component for ColliderEnabled3d with component() {
  ecs_key_collider_enabled3d
}

///|
pub impl @ecs.Component for CollisionGroups3d with component() {
  ecs_key_collision_groups3d
}

///|
pub impl @ecs.Component for ExternalImpulse3d with component() {
  ecs_key_external_impulse3d
}

///|
pub impl @ecs.Component for RapierBodyHandle3d with component() {
  ecs_key_rapier_body_handle3d
}

///|
pub impl @ecs.Component for RigidBodyEnabled3d with component() {
  ecs_key_rigid_body_enabled3d
}

///|
pub impl @ecs.Component for FrictionCombineRule3d with component() {
  ecs_key_friction_combine_rule3d
}

///|
pub impl @ecs.Component for ActiveCollisionTypes3d with component() {
  ecs_key_active_collision_types3d
}

///|
pub impl @ecs.Component for RapierColliderHandle3d with component() {
  ecs_key_rapier_collider_handle3d
}

///|
pub impl @ecs.Component for ColliderMassProperties3d with component() {
  ecs_key_collider_mass_properties3d
}

///|
pub impl @ecs.Component for RestitutionCombineRule3d with component() {
  ecs_key_restitution_combine_rule3d
}

///|
pub impl @ecs.Component for AdditionalMassProperties3d with component() {
  ecs_key_additional_mass_properties3d
}

///|
pub impl @ecs.Component for RapierImpulseJointHandle3d with component() {
  ecs_key_rapier_impulse_joint_handle3d
}

///|
pub impl @ecs.Component for AdditionalSolverIterations3d with component() {
  ecs_key_additional_solver_iterations3d
}

///|
pub impl @ecs.Component for ContactForceEventThreshold3d with component() {
  ecs_key_contact_force_event_threshold3d
}

///|
pub impl @ecs.Component for RapierMultibodyJointHandle3d with component() {
  ecs_key_rapier_multibody_joint_handle3d
}

///|
pub impl @ecs.Component for KinematicCharacterController3d with component() {
  ecs_key_kinematic_character_controller3d
}

///|
pub impl @ecs.Component for KinematicCharacterControllerOutput3d with component() {
  ecs_key_kinematic_character_controller_output3d
}

///|
pub fn get_physics3d_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics3dConfig] {
  world.resource(ecs_res_key_physics3d_config)
}

///|
pub fn get_physics3d_events_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics3dEvents] {
  world.resource(ecs_res_key_physics3d_events)
}

///|
pub fn get_physics3d_context_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics3dContext] {
  world.resource(ecs_res_key_physics3d_context)
}

///|
pub fn get_physics3d_hooks_config_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[Physics3dHooksConfig] {
  world.resource(ecs_res_key_physics3d_hooks_config)
}
