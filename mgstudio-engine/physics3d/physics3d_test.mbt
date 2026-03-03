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
test "physics3d: falling body collides and writes back transform" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = @ecs.World::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics3d_config_resource(world)
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  @math.get_transform_store(world).insert(
    floor,
    @math.Transform::from_xyz(0.0F, -1.0F, 0.0F),
    tick,
  )
  get_rigid_body3d_store(world).insert(floor, RigidBody3d::fixed(), tick)
  get_collider3d_store(world).insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  @math.get_transform_store(world).insert(
    ball,
    @math.Transform::from_xyz(0.0F, 5.0F, 0.0F),
    tick,
  )
  get_rigid_body3d_store(world).insert(ball, RigidBody3d::dynamic(), tick)
  get_collider3d_store(world).insert(
    ball,
    Collider3d::new(ColliderShape3d::ball(0.5F)),
    tick,
  )
  get_velocity3d_store(world).insert(ball, Velocity3d::zero(), tick)
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let initial_y = @math.get_transform_store(world).get(ball).unwrap().translation.y
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    world.increment_change_tick() |> ignore
    i = i + 1
  }
  let final_y = @math.get_transform_store(world).get(ball).unwrap().translation.y
  inspect(final_y < initial_y, content="true")
}

///|
test "physics3d: sensor collision events are emitted" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = @ecs.World::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics3d_config_resource(world)
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  @math.get_transform_store(world).insert(
    floor,
    @math.Transform::from_xyz(0.0F, -1.0F, 0.0F),
    tick,
  )
  get_rigid_body3d_store(world).insert(floor, RigidBody3d::fixed(), tick)
  get_collider3d_store(world).insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  @math.get_transform_store(world).insert(
    ball,
    @math.Transform::from_xyz(0.0F, 5.0F, 0.0F),
    tick,
  )
  get_rigid_body3d_store(world).insert(ball, RigidBody3d::dynamic(), tick)
  // Mark the ball collider as a sensor so the 3DReal backend will emit Started/Stopped events.
  get_collider3d_store(world).insert(
    ball,
    Collider3d::new(ColliderShape3d::ball(0.5F)).sensor(true),
    tick,
  )
  get_active_events3d_store(world).insert(
    ball,
    ActiveEvents3d::collision_events(),
    tick,
  )
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
  let events = get_physics3d_events_resource(world).get_ref().unwrap().val
  inspect(events.collisions.length() > 0, content="true")
}

///|
test "physics3d: contact force events are emitted" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = @ecs.World::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let cfg_res = get_physics3d_config_resource(world)
  cfg_res.get_ref_mut(tick).unwrap().val = Physics3dConfig::new(
    @math.Vec3::new(0.0F, -200.0F, 0.0F),
  )
  let floor = @core.Entity::new(0, 1)
  let ball = @core.Entity::new(1, 1)
  @math.get_transform_store(world).insert(
    floor,
    @math.Transform::from_xyz(0.0F, -1.0F, 0.0F),
    tick,
  )
  get_rigid_body3d_store(world).insert(floor, RigidBody3d::fixed(), tick)
  get_collider3d_store(world).insert(
    floor,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
    tick,
  )
  @math.get_transform_store(world).insert(
    ball,
    @math.Transform::from_xyz(0.0F, 5.0F, 0.0F),
    tick,
  )
  get_rigid_body3d_store(world).insert(ball, RigidBody3d::dynamic(), tick)
  get_collider3d_store(world).insert(
    ball,
    Collider3d::new(ColliderShape3d::ball(0.5F)),
    tick,
  )
  get_contact_force_event_threshold3d_store(world).insert(
    ball,
    ContactForceEventThreshold3d::new(0.0F),
    tick,
  )
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
  let events = get_physics3d_events_resource(world).get_ref().unwrap().val
  inspect(events.contact_forces.length() > 0, content="true")
}

///|
test "physics3d: active collision type and hook components are accepted" {
  @app.fixed_time_reset()
  @app.fixed_time_set_timestep_seconds(1.0F / 60.0F)
  let world = @ecs.World::new()
  physics3d_init_resources_system(world)
  let tick = world.read_change_tick()
  let body = @core.Entity::new(0, 1)
  @math.get_transform_store(world).insert(
    body,
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F),
    tick,
  )
  get_rigid_body3d_store(world).insert(body, RigidBody3d::dynamic(), tick)
  get_collider3d_store(world).insert(
    body,
    Collider3d::new(ColliderShape3d::ball(1.0F)),
    tick,
  )
  get_active_collision_types3d_store(world).insert(
    body,
    ActiveCollisionTypes3d::new(@collision.ActiveCollisionTypes::all()),
    tick,
  )
  get_active_hooks3d_store(world).insert(
    body,
    ActiveHooks3d::new(@collision.ActiveHooks::all()),
    tick,
  )
  physics3d_sync_insertions_system(world)
  inspect(
    get_rapier_collider_handle3d_store(world).contains(body),
    content="true",
  )
}
