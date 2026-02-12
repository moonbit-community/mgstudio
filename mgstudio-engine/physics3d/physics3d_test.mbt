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
struct Physics3dTestWorld {
  mut tick : @core.Tick
  transform : @core.ComponentStore[@math.Transform]
  rigid_body : @core.ComponentStore[RigidBody3d]
  collider : @core.ComponentStore[Collider3d]
  active_collision_types : @core.ComponentStore[ActiveCollisionTypes3d]
  active_events : @core.ComponentStore[ActiveEvents3d]
  contact_force_threshold : @core.ComponentStore[ContactForceEventThreshold3d]
  active_hooks : @core.ComponentStore[ActiveHooks3d]
  velocity : @core.ComponentStore[Velocity3d]
  body_handle : @core.ComponentStore[RapierBodyHandle3d]
  collider_handle : @core.ComponentStore[RapierColliderHandle3d]
  config : @core.Resource[Physics3dConfig]
  context : @core.Resource[Physics3dContext]
  events : @core.Resource[Physics3dEvents]
}

///|
fn Physics3dTestWorld::new() -> Physics3dTestWorld {
  {
    tick: 0,
    transform: @core.ComponentStore::new(),
    rigid_body: @core.ComponentStore::new(),
    collider: @core.ComponentStore::new(),
    active_collision_types: @core.ComponentStore::new(),
    active_events: @core.ComponentStore::new(),
    contact_force_threshold: @core.ComponentStore::new(),
    active_hooks: @core.ComponentStore::new(),
    velocity: @core.ComponentStore::new(),
    body_handle: @core.ComponentStore::new(),
    collider_handle: @core.ComponentStore::new(),
    config: @core.Resource::new(),
    context: @core.Resource::new(),
    events: @core.Resource::new(),
  }
}

///|
impl @core.ChangeTickWorld for Physics3dTestWorld with read_change_tick(self) {
  self.tick
}

///|
impl @core.ChangeTickWorld for Physics3dTestWorld with increment_change_tick(
  self,
) {
  self.tick = self.tick + 1
  self.tick
}

///|
impl @math.Has_Transform for Physics3dTestWorld with get_transform_store(self) {
  self.transform
}

///|
impl Has_RigidBody3d for Physics3dTestWorld with get_rigid_body3d_store(self) {
  self.rigid_body
}

///|
impl Has_Collider3d for Physics3dTestWorld with get_collider3d_store(self) {
  self.collider
}

///|
impl Has_ActiveCollisionTypes3d for Physics3dTestWorld with get_active_collision_types3d_store(
  self,
) {
  self.active_collision_types
}

///|
impl Has_ActiveEvents3d for Physics3dTestWorld with get_active_events3d_store(
  self,
) {
  self.active_events
}

///|
impl Has_ContactForceEventThreshold3d for Physics3dTestWorld with get_contact_force_event_threshold3d_store(
  self,
) {
  self.contact_force_threshold
}

///|
impl Has_ActiveHooks3d for Physics3dTestWorld with get_active_hooks3d_store(
  self,
) {
  self.active_hooks
}

///|
impl Has_Velocity3d for Physics3dTestWorld with get_velocity3d_store(self) {
  self.velocity
}

///|
impl Has_RapierBodyHandle3d for Physics3dTestWorld with get_rapier_body_handle3d_store(
  self,
) {
  self.body_handle
}

///|
impl Has_RapierColliderHandle3d for Physics3dTestWorld with get_rapier_collider_handle3d_store(
  self,
) {
  self.collider_handle
}

///|
impl HasRes_Physics3dConfig for Physics3dTestWorld with get_physics3d_config_resource(
  self,
) {
  self.config
}

///|
impl HasRes_Physics3dContext for Physics3dTestWorld with get_physics3d_context_resource(
  self,
) {
  self.context
}

///|
impl HasRes_Physics3dEvents for Physics3dTestWorld with get_physics3d_events_resource(
  self,
) {
  self.events
}

///|
test "physics3d: falling body collides and writes back transform" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics3dTestWorld::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = world.get_physics3d_config_resource()
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  world
  .get_transform_store()
  .insert(floor, @math.Transform::from_xyz(0.0F, -1.0F, 0.0F), tick)
  world.get_rigid_body3d_store().insert(floor, RigidBody3d::fixed(), tick)
  world
  .get_collider3d_store()
  .insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  world
  .get_transform_store()
  .insert(ball, @math.Transform::from_xyz(0.0F, 5.0F, 0.0F), tick)
  world.get_rigid_body3d_store().insert(ball, RigidBody3d::dynamic(), tick)
  world
  .get_collider3d_store()
  .insert(ball, Collider3d::new(ColliderShape3d::ball(0.5F)), tick)
  world.get_velocity3d_store().insert(ball, Velocity3d::zero(), tick)
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let initial_y = world.get_transform_store().get(ball).unwrap().translation.y
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  let final_y = world.get_transform_store().get(ball).unwrap().translation.y
  inspect(final_y < initial_y, content="true")
}

///|
test "physics3d: sensor collision events are emitted" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics3dTestWorld::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = world.get_physics3d_config_resource()
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  world
  .get_transform_store()
  .insert(floor, @math.Transform::from_xyz(0.0F, -1.0F, 0.0F), tick)
  world.get_rigid_body3d_store().insert(floor, RigidBody3d::fixed(), tick)
  world
  .get_collider3d_store()
  .insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  world
  .get_transform_store()
  .insert(ball, @math.Transform::from_xyz(0.0F, 5.0F, 0.0F), tick)
  world.get_rigid_body3d_store().insert(ball, RigidBody3d::dynamic(), tick)
  // Mark the ball collider as a sensor so the 3DReal backend will emit Started/Stopped events.
  world
  .get_collider3d_store()
  .insert(ball, Collider3d::new(ColliderShape3d::ball(0.5F)).sensor(true), tick)
  world
  .get_active_events3d_store()
  .insert(ball, ActiveEvents3d::collision_events(), tick)
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  let events = world.get_physics3d_events_resource().get_ref().unwrap().val
  inspect(events.collisions.length() > 0, content="true")
}

///|
test "physics3d: contact force events are emitted" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics3dTestWorld::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = world.get_physics3d_config_resource()
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  world
  .get_transform_store()
  .insert(floor, @math.Transform::from_xyz(0.0F, -1.0F, 0.0F), tick)
  world.get_rigid_body3d_store().insert(floor, RigidBody3d::fixed(), tick)
  world
  .get_collider3d_store()
  .insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  world
  .get_transform_store()
  .insert(ball, @math.Transform::from_xyz(0.0F, 5.0F, 0.0F), tick)
  world.get_rigid_body3d_store().insert(ball, RigidBody3d::dynamic(), tick)
  world
  .get_collider3d_store()
  .insert(ball, Collider3d::new(ColliderShape3d::ball(0.5F)), tick)
  world
  .get_contact_force_event_threshold3d_store()
  .insert(ball, ContactForceEventThreshold3d::new(0.0F), tick)
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  let events = world.get_physics3d_events_resource().get_ref().unwrap().val
  inspect(events.contact_forces.length() > 0, content="true")
}

///|
test "physics3d: active collision type and hook components are accepted" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics3dTestWorld::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let body = @core.Entity::new(0, 1)
  world
  .get_transform_store()
  .insert(body, @math.Transform::from_xyz(0.0F, 0.0F, 0.0F), tick)
  world.get_rigid_body3d_store().insert(body, RigidBody3d::dynamic(), tick)
  world
  .get_collider3d_store()
  .insert(body, Collider3d::new(ColliderShape3d::ball(1.0F)), tick)
  world
  .get_active_collision_types3d_store()
  .insert(
    body,
    ActiveCollisionTypes3d::new(@collision.ActiveCollisionTypes::all()),
    tick,
  )
  world
  .get_active_hooks3d_store()
  .insert(body, ActiveHooks3d::new(@collision.ActiveHooks::all()), tick)
  physics3d_sync_insertions_system(world)
  inspect(
    world.get_rapier_collider_handle3d_store().contains(body),
    content="true",
  )
}
