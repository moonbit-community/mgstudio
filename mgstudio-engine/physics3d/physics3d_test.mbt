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
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = HasRes_Physics3dConfig::get_physics3d_config_resource(world)
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    floor,
    @math.Transform::from_xyz(0.0F, -1.0F, 0.0F),
    tick,
  )
  Has_RigidBody3d::get_rigid_body3d_store(world).insert(
    floor,
    RigidBody3d::fixed(),
    tick,
  )
  Has_Collider3d::get_collider3d_store(world).insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  @math.Has_Transform::get_transform_store(world).insert(
    ball,
    @math.Transform::from_xyz(0.0F, 5.0F, 0.0F),
    tick,
  )
  Has_RigidBody3d::get_rigid_body3d_store(world).insert(
    ball,
    RigidBody3d::dynamic(),
    tick,
  )
  Has_Collider3d::get_collider3d_store(world).insert(
    ball,
    Collider3d::new(ColliderShape3d::ball(0.5F)),
    tick,
  )
  Has_Velocity3d::get_velocity3d_store(world).insert(
    ball,
    Velocity3d::zero(),
    tick,
  )
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let initial_y = @math.Has_Transform::get_transform_store(world)
    .get(ball)
    .unwrap().translation.y
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    @core.ChangeTickWorld::increment_change_tick(world) |> ignore
    i = i + 1
  }
  let final_y = @math.Has_Transform::get_transform_store(world)
    .get(ball)
    .unwrap().translation.y
  inspect(final_y < initial_y, content="true")
}

///|
test "physics3d: sensor collision events are emitted" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = Physics3dTestWorld::new()
  physics3d_init_resources_system(world)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = HasRes_Physics3dConfig::get_physics3d_config_resource(world)
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  @math.Has_Transform::get_transform_store(world).insert(
    floor,
    @math.Transform::from_xyz(0.0F, -1.0F, 0.0F),
    tick,
  )
  Has_RigidBody3d::get_rigid_body3d_store(world).insert(
    floor,
    RigidBody3d::fixed(),
    tick,
  )
  Has_Collider3d::get_collider3d_store(world).insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  @math.Has_Transform::get_transform_store(world).insert(
    ball,
    @math.Transform::from_xyz(0.0F, 5.0F, 0.0F),
    tick,
  )
  Has_RigidBody3d::get_rigid_body3d_store(world).insert(
    ball,
    RigidBody3d::dynamic(),
    tick,
  )
  // Mark the ball collider as a sensor so the 3DReal backend will emit Started/Stopped events.
  Has_Collider3d::get_collider3d_store(world).insert(
    ball,
    Collider3d::new(ColliderShape3d::ball(0.5F)).sensor(true),
    tick,
  )
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    @core.ChangeTickWorld::increment_change_tick(world) |> ignore
    i = i + 1
  }
  let events = HasRes_Physics3dEvents::get_physics3d_events_resource(world)
    .get_ref()
    .unwrap().val
  inspect(events.collisions.length() > 0, content="true")
}
