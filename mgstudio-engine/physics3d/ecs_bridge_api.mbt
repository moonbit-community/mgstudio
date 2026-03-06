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
  "Collider3d", "Velocity3d", "RigidBody3d", "ActiveHooks3d", "ActiveEvents3d", "RapierBodyHandle3d",
  "ActiveCollisionTypes3d", "RapierColliderHandle3d", "ContactForceEventThreshold3d",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = [
  "Physics3dConfig", "Physics3dEvents", "Physics3dContext",
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

///|
pub let ecs_key_collider3d : @ecs.ComponentKey[Collider3d] = @ecs.register_component(
  debug_name="physics3d.collider3d",
)

///|
pub let ecs_key_velocity3d : @ecs.ComponentKey[Velocity3d] = @ecs.register_component(
  debug_name="physics3d.velocity3d",
)

///|
pub let ecs_key_rigid_body3d : @ecs.ComponentKey[RigidBody3d] = @ecs.register_component(
  debug_name="physics3d.rigid_body3d",
)

///|
pub let ecs_key_active_hooks3d : @ecs.ComponentKey[ActiveHooks3d] = @ecs.register_component(
  debug_name="physics3d.active_hooks3d",
)

///|
pub let ecs_key_active_events3d : @ecs.ComponentKey[ActiveEvents3d] = @ecs.register_component(
  debug_name="physics3d.active_events3d",
)

///|
pub let ecs_key_rapier_body_handle3d : @ecs.ComponentKey[RapierBodyHandle3d] = @ecs.register_component(
  debug_name="physics3d.rapier_body_handle3d",
)

///|
pub let ecs_key_active_collision_types3d : @ecs.ComponentKey[
  ActiveCollisionTypes3d,
] = @ecs.register_component(debug_name="physics3d.active_collision_types3d")

///|
pub let ecs_key_rapier_collider_handle3d : @ecs.ComponentKey[
  RapierColliderHandle3d,
] = @ecs.register_component(debug_name="physics3d.rapier_collider_handle3d")

///|
pub let ecs_key_contact_force_event_threshold3d : @ecs.ComponentKey[
  ContactForceEventThreshold3d,
] = @ecs.register_component(
  debug_name="physics3d.contact_force_event_threshold3d",
)

///|
pub impl @ecs.Component for Collider3d with component() {
  ecs_key_collider3d
}

///|
pub impl @ecs.Component for Velocity3d with component() {
  ecs_key_velocity3d
}

///|
pub impl @ecs.Component for RigidBody3d with component() {
  ecs_key_rigid_body3d
}

///|
pub impl @ecs.Component for ActiveHooks3d with component() {
  ecs_key_active_hooks3d
}

///|
pub impl @ecs.Component for ActiveEvents3d with component() {
  ecs_key_active_events3d
}

///|
pub impl @ecs.Component for RapierBodyHandle3d with component() {
  ecs_key_rapier_body_handle3d
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
pub impl @ecs.Component for ContactForceEventThreshold3d with component() {
  ecs_key_contact_force_event_threshold3d
}

///|
pub fn get_collider3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Collider3d] {
  world.component(ecs_key_collider3d)
}

///|
pub fn get_velocity3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Velocity3d] {
  world.component(ecs_key_velocity3d)
}

///|
pub fn get_rigid_body3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[RigidBody3d] {
  world.component(ecs_key_rigid_body3d)
}

///|
pub fn get_active_hooks3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ActiveHooks3d] {
  world.component(ecs_key_active_hooks3d)
}

///|
pub fn get_active_events3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ActiveEvents3d] {
  world.component(ecs_key_active_events3d)
}

///|
pub fn get_rapier_body_handle3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[RapierBodyHandle3d] {
  world.component(ecs_key_rapier_body_handle3d)
}

///|
pub fn get_active_collision_types3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ActiveCollisionTypes3d] {
  world.component(ecs_key_active_collision_types3d)
}

///|
pub fn get_rapier_collider_handle3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[RapierColliderHandle3d] {
  world.component(ecs_key_rapier_collider_handle3d)
}

///|
pub fn get_contact_force_event_threshold3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ContactForceEventThreshold3d] {
  world.component(ecs_key_contact_force_event_threshold3d)
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
