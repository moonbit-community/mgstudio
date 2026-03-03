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
  "Collider3d", "Velocity3d", "RigidBody3d", "ActiveHooks3d", "ActiveEvents3d", "RapierBodyHandle3d",
  "ActiveCollisionTypes3d", "RapierColliderHandle3d", "ContactForceEventThreshold3d",
]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = [
  "Physics3dConfig", "Physics3dEvents", "Physics3dContext",
]

///|
pub(open) trait Has_Collider3d {
  get_collider3d_store(self : Self) -> @core.ComponentStore[Collider3d]
}

///|
pub(open) trait Has_Velocity3d {
  get_velocity3d_store(self : Self) -> @core.ComponentStore[Velocity3d]
}

///|
pub(open) trait Has_RigidBody3d {
  get_rigid_body3d_store(self : Self) -> @core.ComponentStore[RigidBody3d]
}

///|
pub(open) trait Has_ActiveHooks3d {
  get_active_hooks3d_store(self : Self) -> @core.ComponentStore[ActiveHooks3d]
}

///|
pub(open) trait Has_ActiveEvents3d {
  get_active_events3d_store(self : Self) -> @core.ComponentStore[ActiveEvents3d]
}

///|
pub(open) trait Has_RapierBodyHandle3d {
  get_rapier_body_handle3d_store(self : Self) -> @core.ComponentStore[
    RapierBodyHandle3d,
  ]
}

///|
pub(open) trait Has_ActiveCollisionTypes3d {
  get_active_collision_types3d_store(self : Self) -> @core.ComponentStore[
    ActiveCollisionTypes3d,
  ]
}

///|
pub(open) trait Has_RapierColliderHandle3d {
  get_rapier_collider_handle3d_store(self : Self) -> @core.ComponentStore[
    RapierColliderHandle3d,
  ]
}

///|
pub(open) trait Has_ContactForceEventThreshold3d {
  get_contact_force_event_threshold3d_store(self : Self) -> @core.ComponentStore[
    ContactForceEventThreshold3d,
  ]
}

///|
pub fn[W : Has_Collider3d] get_collider3d_store(
  world : W,
) -> @core.ComponentStore[Collider3d] {
  world.get_collider3d_store()
}

///|
pub fn[W : Has_Velocity3d] get_velocity3d_store(
  world : W,
) -> @core.ComponentStore[Velocity3d] {
  world.get_velocity3d_store()
}

///|
pub fn[W : Has_RigidBody3d] get_rigid_body3d_store(
  world : W,
) -> @core.ComponentStore[RigidBody3d] {
  world.get_rigid_body3d_store()
}

///|
pub fn[W : Has_ActiveHooks3d] get_active_hooks3d_store(
  world : W,
) -> @core.ComponentStore[ActiveHooks3d] {
  world.get_active_hooks3d_store()
}

///|
pub fn[W : Has_ActiveEvents3d] get_active_events3d_store(
  world : W,
) -> @core.ComponentStore[ActiveEvents3d] {
  world.get_active_events3d_store()
}

///|
pub fn[W : Has_RapierBodyHandle3d] get_rapier_body_handle3d_store(
  world : W,
) -> @core.ComponentStore[RapierBodyHandle3d] {
  world.get_rapier_body_handle3d_store()
}

///|
pub fn[W : Has_ActiveCollisionTypes3d] get_active_collision_types3d_store(
  world : W,
) -> @core.ComponentStore[ActiveCollisionTypes3d] {
  world.get_active_collision_types3d_store()
}

///|
pub fn[W : Has_RapierColliderHandle3d] get_rapier_collider_handle3d_store(
  world : W,
) -> @core.ComponentStore[RapierColliderHandle3d] {
  world.get_rapier_collider_handle3d_store()
}

///|
pub fn[W : Has_ContactForceEventThreshold3d] get_contact_force_event_threshold3d_store(
  world : W,
) -> @core.ComponentStore[ContactForceEventThreshold3d] {
  world.get_contact_force_event_threshold3d_store()
}

///|
pub(open) trait HasRes_Physics3dConfig {
  get_physics3d_config_resource(self : Self) -> @core.Resource[Physics3dConfig]
}

///|
pub(open) trait HasRes_Physics3dEvents {
  get_physics3d_events_resource(self : Self) -> @core.Resource[Physics3dEvents]
}

///|
pub(open) trait HasRes_Physics3dContext {
  get_physics3d_context_resource(self : Self) -> @core.Resource[
    Physics3dContext,
  ]
}

///|
pub fn[W : HasRes_Physics3dConfig] get_physics3d_config_resource(
  world : W,
) -> @core.Resource[Physics3dConfig] {
  world.get_physics3d_config_resource()
}

///|
pub fn[W : HasRes_Physics3dEvents] get_physics3d_events_resource(
  world : W,
) -> @core.Resource[Physics3dEvents] {
  world.get_physics3d_events_resource()
}

///|
pub fn[W : HasRes_Physics3dContext] get_physics3d_context_resource(
  world : W,
) -> @core.Resource[Physics3dContext] {
  world.get_physics3d_context_resource()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_collider3d_store_by_world : Map[
  Int,
  @core.ComponentStore[Collider3d],
] = {}

///|
pub impl Has_Collider3d for @ecs.World with get_collider3d_store(self) {
  bridge_get_collider3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_velocity3d_store_by_world : Map[
  Int,
  @core.ComponentStore[Velocity3d],
] = {}

///|
pub impl Has_Velocity3d for @ecs.World with get_velocity3d_store(self) {
  bridge_get_velocity3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_rigid_body3d_store_by_world : Map[
  Int,
  @core.ComponentStore[RigidBody3d],
] = {}

///|
pub impl Has_RigidBody3d for @ecs.World with get_rigid_body3d_store(self) {
  bridge_get_rigid_body3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_active_hooks3d_store_by_world : Map[
  Int,
  @core.ComponentStore[ActiveHooks3d],
] = {}

///|
pub impl Has_ActiveHooks3d for @ecs.World with get_active_hooks3d_store(self) {
  bridge_get_active_hooks3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_active_events3d_store_by_world : Map[
  Int,
  @core.ComponentStore[ActiveEvents3d],
] = {}

///|
pub impl Has_ActiveEvents3d for @ecs.World with get_active_events3d_store(self) {
  bridge_get_active_events3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_rapier_body_handle3d_store_by_world : Map[
  Int,
  @core.ComponentStore[RapierBodyHandle3d],
] = {}

///|
pub impl Has_RapierBodyHandle3d for @ecs.World with get_rapier_body_handle3d_store(
  self,
) {
  bridge_get_rapier_body_handle3d_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_active_collision_types3d_store_by_world : Map[
  Int,
  @core.ComponentStore[ActiveCollisionTypes3d],
] = {}

///|
pub impl Has_ActiveCollisionTypes3d for @ecs.World with get_active_collision_types3d_store(
  self,
) {
  bridge_get_active_collision_types3d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_rapier_collider_handle3d_store_by_world : Map[
  Int,
  @core.ComponentStore[RapierColliderHandle3d],
] = {}

///|
pub impl Has_RapierColliderHandle3d for @ecs.World with get_rapier_collider_handle3d_store(
  self,
) {
  bridge_get_rapier_collider_handle3d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_contact_force_event_threshold3d_store_by_world : Map[
  Int,
  @core.ComponentStore[ContactForceEventThreshold3d],
] = {}

///|
pub impl Has_ContactForceEventThreshold3d for @ecs.World with get_contact_force_event_threshold3d_store(
  self,
) {
  bridge_get_contact_force_event_threshold3d_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_physics3d_config_resource_by_world : Map[
  Int,
  @core.Resource[Physics3dConfig],
] = {}

///|
pub impl HasRes_Physics3dConfig for @ecs.World with get_physics3d_config_resource(
  self,
) {
  bridge_get_physics3d_config_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_physics3d_events_resource_by_world : Map[
  Int,
  @core.Resource[Physics3dEvents],
] = {}

///|
pub impl HasRes_Physics3dEvents for @ecs.World with get_physics3d_events_resource(
  self,
) {
  bridge_get_physics3d_events_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_physics3d_context_resource_by_world : Map[
  Int,
  @core.Resource[Physics3dContext],
] = {}

///|
pub impl HasRes_Physics3dContext for @ecs.World with get_physics3d_context_resource(
  self,
) {
  bridge_get_physics3d_context_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
/// End ECS bridge impls.
