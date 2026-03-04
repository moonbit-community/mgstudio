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
pub(open) trait Has_Collider3d {
  get_collider3d_store(self : Self) -> @ecs.ComponentAccess[Collider3d]
}

///|
pub(open) trait Has_Velocity3d {
  get_velocity3d_store(self : Self) -> @ecs.ComponentAccess[Velocity3d]
}

///|
pub(open) trait Has_RigidBody3d {
  get_rigid_body3d_store(self : Self) -> @ecs.ComponentAccess[RigidBody3d]
}

///|
pub(open) trait Has_ActiveHooks3d {
  get_active_hooks3d_store(self : Self) -> @ecs.ComponentAccess[ActiveHooks3d]
}

///|
pub(open) trait Has_ActiveEvents3d {
  get_active_events3d_store(self : Self) -> @ecs.ComponentAccess[ActiveEvents3d]
}

///|
pub(open) trait Has_RapierBodyHandle3d {
  get_rapier_body_handle3d_store(self : Self) -> @ecs.ComponentAccess[
    RapierBodyHandle3d,
  ]
}

///|
pub(open) trait Has_ActiveCollisionTypes3d {
  get_active_collision_types3d_store(self : Self) -> @ecs.ComponentAccess[
    ActiveCollisionTypes3d,
  ]
}

///|
pub(open) trait Has_RapierColliderHandle3d {
  get_rapier_collider_handle3d_store(self : Self) -> @ecs.ComponentAccess[
    RapierColliderHandle3d,
  ]
}

///|
pub(open) trait Has_ContactForceEventThreshold3d {
  get_contact_force_event_threshold3d_store(self : Self) -> @ecs.ComponentAccess[
    ContactForceEventThreshold3d,
  ]
}

///|
pub fn[W : Has_Collider3d] get_collider3d_store(
  world : W,
) -> @ecs.ComponentAccess[Collider3d] {
  world.get_collider3d_store()
}

///|
pub fn[W : Has_Velocity3d] get_velocity3d_store(
  world : W,
) -> @ecs.ComponentAccess[Velocity3d] {
  world.get_velocity3d_store()
}

///|
pub fn[W : Has_RigidBody3d] get_rigid_body3d_store(
  world : W,
) -> @ecs.ComponentAccess[RigidBody3d] {
  world.get_rigid_body3d_store()
}

///|
pub fn[W : Has_ActiveHooks3d] get_active_hooks3d_store(
  world : W,
) -> @ecs.ComponentAccess[ActiveHooks3d] {
  world.get_active_hooks3d_store()
}

///|
pub fn[W : Has_ActiveEvents3d] get_active_events3d_store(
  world : W,
) -> @ecs.ComponentAccess[ActiveEvents3d] {
  world.get_active_events3d_store()
}

///|
pub fn[W : Has_RapierBodyHandle3d] get_rapier_body_handle3d_store(
  world : W,
) -> @ecs.ComponentAccess[RapierBodyHandle3d] {
  world.get_rapier_body_handle3d_store()
}

///|
pub fn[W : Has_ActiveCollisionTypes3d] get_active_collision_types3d_store(
  world : W,
) -> @ecs.ComponentAccess[ActiveCollisionTypes3d] {
  world.get_active_collision_types3d_store()
}

///|
pub fn[W : Has_RapierColliderHandle3d] get_rapier_collider_handle3d_store(
  world : W,
) -> @ecs.ComponentAccess[RapierColliderHandle3d] {
  world.get_rapier_collider_handle3d_store()
}

///|
pub fn[W : Has_ContactForceEventThreshold3d] get_contact_force_event_threshold3d_store(
  world : W,
) -> @ecs.ComponentAccess[ContactForceEventThreshold3d] {
  world.get_contact_force_event_threshold3d_store()
}

///|
pub(open) trait HasRes_Physics3dConfig {
  get_physics3d_config_resource(self : Self) -> @ecs.ResourceAccess[
    Physics3dConfig,
  ]
}

///|
pub(open) trait HasRes_Physics3dEvents {
  get_physics3d_events_resource(self : Self) -> @ecs.ResourceAccess[
    Physics3dEvents,
  ]
}

///|
pub(open) trait HasRes_Physics3dContext {
  get_physics3d_context_resource(self : Self) -> @ecs.ResourceAccess[
    Physics3dContext,
  ]
}

///|
pub fn[W : HasRes_Physics3dConfig] get_physics3d_config_resource(
  world : W,
) -> @ecs.ResourceAccess[Physics3dConfig] {
  world.get_physics3d_config_resource()
}

///|
pub fn[W : HasRes_Physics3dEvents] get_physics3d_events_resource(
  world : W,
) -> @ecs.ResourceAccess[Physics3dEvents] {
  world.get_physics3d_events_resource()
}

///|
pub fn[W : HasRes_Physics3dContext] get_physics3d_context_resource(
  world : W,
) -> @ecs.ResourceAccess[Physics3dContext] {
  world.get_physics3d_context_resource()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_Collider3d for @ecs.World with get_collider3d_store(self) {
  self.component(ecs_key_collider3d)
}

///|
pub impl Has_Velocity3d for @ecs.World with get_velocity3d_store(self) {
  self.component(ecs_key_velocity3d)
}

///|
pub impl Has_RigidBody3d for @ecs.World with get_rigid_body3d_store(self) {
  self.component(ecs_key_rigid_body3d)
}

///|
pub impl Has_ActiveHooks3d for @ecs.World with get_active_hooks3d_store(self) {
  self.component(ecs_key_active_hooks3d)
}

///|
pub impl Has_ActiveEvents3d for @ecs.World with get_active_events3d_store(self) {
  self.component(ecs_key_active_events3d)
}

///|
pub impl Has_RapierBodyHandle3d for @ecs.World with get_rapier_body_handle3d_store(
  self,
) {
  self.component(ecs_key_rapier_body_handle3d)
}

///|
pub impl Has_ActiveCollisionTypes3d for @ecs.World with get_active_collision_types3d_store(
  self,
) {
  self.component(ecs_key_active_collision_types3d)
}

///|
pub impl Has_RapierColliderHandle3d for @ecs.World with get_rapier_collider_handle3d_store(
  self,
) {
  self.component(ecs_key_rapier_collider_handle3d)
}

///|
pub impl Has_ContactForceEventThreshold3d for @ecs.World with get_contact_force_event_threshold3d_store(
  self,
) {
  self.component(ecs_key_contact_force_event_threshold3d)
}

///|
pub impl HasRes_Physics3dConfig for @ecs.World with get_physics3d_config_resource(
  self,
) {
  self.resource(ecs_res_key_physics3d_config)
}

///|
pub impl HasRes_Physics3dEvents for @ecs.World with get_physics3d_events_resource(
  self,
) {
  self.resource(ecs_res_key_physics3d_events)
}

///|
pub impl HasRes_Physics3dContext for @ecs.World with get_physics3d_context_resource(
  self,
) {
  self.resource(ecs_res_key_physics3d_context)
}

///|
/// End ECS bridge impls.
