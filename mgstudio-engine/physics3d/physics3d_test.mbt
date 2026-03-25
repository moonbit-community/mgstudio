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
fn configure_fixed_time(world : @ecs.World, timestep_seconds : Float) -> Unit {
  world.insert_resource(
    @time.fixed_time_resource_key(),
    @time.Time::from_seconds(timestep_seconds),
  )
}

///|
let ecs_key_transform : @ecs.ComponentKey[@transform.Transform] = @transform.ecs_key_transform

///|
test "physics3d: falling body collides and writes back transform" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics3d_init_resources_system(world)
  let cfg_res = get_physics3d_config_resource(world)
  let cfg_ref = Ref::new(cfg_res.get().unwrap())
  cfg_ref.val = Physics3dConfig::new(@math.Vec3::new(0.0F, -200.0F, 0.0F))
  cfg_res.insert(cfg_ref.val)
  let floor = world.spawn()
  let ball = world.spawn()
  try! world.set_by_key(
    floor,
    ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, -1.0F, 0.0F),
  )
  try! world.set_by_key(floor, ecs_key_rigid_body3d, RigidBody3d::fixed())
  try! world.set_by_key(
    floor,
    ecs_key_collider3d,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
  )
  try! world.set_by_key(
    ball,
    ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 5.0F, 0.0F),
  )
  try! world.set_by_key(ball, ecs_key_rigid_body3d, RigidBody3d::dynamic())
  try! world.set_by_key(
    ball,
    ecs_key_collider3d,
    Collider3d::new(ColliderShape3d::ball(0.5F)),
  )
  try! world.set_by_key(ball, ecs_key_velocity3d, Velocity3d::zero())
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let initial_y = try! world.get_by_key(ball, ecs_key_transform).unwrap().translation.y
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    world.advance_sequence() |> ignore
    i = i + 1
  }
  let final_y = try! world.get_by_key(ball, ecs_key_transform).unwrap().translation.y
  inspect(final_y < initial_y, content="true")
}

///|
test "physics3d: sensor collision events are emitted" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics3d_init_resources_system(world)
  let cfg_res = get_physics3d_config_resource(world)
  let cfg_ref = Ref::new(cfg_res.get().unwrap())
  cfg_ref.val = Physics3dConfig::new(@math.Vec3::new(0.0F, -200.0F, 0.0F))
  cfg_res.insert(cfg_ref.val)
  let floor = world.spawn()
  let ball = world.spawn()
  try! world.set_by_key(
    floor,
    ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, -1.0F, 0.0F),
  )
  try! world.set_by_key(floor, ecs_key_rigid_body3d, RigidBody3d::fixed())
  try! world.set_by_key(
    floor,
    ecs_key_collider3d,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
  )
  try! world.set_by_key(
    ball,
    ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 5.0F, 0.0F),
  )
  try! world.set_by_key(ball, ecs_key_rigid_body3d, RigidBody3d::dynamic())
  // Mark the ball collider as a sensor so the 3DReal backend will emit Started/Stopped events.
  try! world.set_by_key(
    ball,
    ecs_key_collider3d,
    Collider3d::new(ColliderShape3d::ball(0.5F)).sensor(true),
  )
  try! world.set_by_key(
    ball,
    ecs_key_active_events3d,
    ActiveEvents3d::collision_events(),
  )
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    world.advance_sequence() |> ignore
    i = i + 1
  }
  let events = get_physics3d_events_resource(world).get().unwrap()
  inspect(events.collisions.length() > 0, content="true")
}

///|
test "physics3d: contact force events are emitted" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics3d_init_resources_system(world)
  let cfg_res = get_physics3d_config_resource(world)
  let cfg_ref = Ref::new(cfg_res.get().unwrap())
  cfg_ref.val = Physics3dConfig::new(@math.Vec3::new(0.0F, -200.0F, 0.0F))
  cfg_res.insert(cfg_ref.val)
  let floor = world.spawn()
  let ball = world.spawn()
  try! world.set_by_key(
    floor,
    ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, -1.0F, 0.0F),
  )
  try! world.set_by_key(floor, ecs_key_rigid_body3d, RigidBody3d::fixed())
  try! world.set_by_key(
    floor,
    ecs_key_collider3d,
    Collider3d::new(ColliderShape3d::cuboid(10.0F, 0.5F, 10.0F)),
  )
  try! world.set_by_key(
    ball,
    ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 5.0F, 0.0F),
  )
  try! world.set_by_key(ball, ecs_key_rigid_body3d, RigidBody3d::dynamic())
  try! world.set_by_key(
    ball,
    ecs_key_collider3d,
    Collider3d::new(ColliderShape3d::ball(0.5F)),
  )
  try! world.set_by_key(
    ball,
    ecs_key_contact_force_event_threshold3d,
    ContactForceEventThreshold3d::new(0.0F),
  )
  physics3d_clear_events_system(world)
  physics3d_sync_insertions_system(world)
  let mut i = 0
  while i < 120 {
    physics3d_sync_world_to_rapier_system(world)
    physics3d_step_system(world)
    physics3d_writeback_system(world)
    world.advance_sequence() |> ignore
    i = i + 1
  }
  let events = get_physics3d_events_resource(world).get().unwrap()
  inspect(events.contact_forces.length() > 0, content="true")
}

///|
test "physics3d: active collision type and hook components are accepted" {
  let world = @ecs.World::new()
  configure_fixed_time(world, 1.0F / 60.0F)
  physics3d_init_resources_system(world)
  let body = world.spawn()
  try! world.set_by_key(
    body,
    ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
  )
  try! world.set_by_key(body, ecs_key_rigid_body3d, RigidBody3d::dynamic())
  try! world.set_by_key(
    body,
    ecs_key_collider3d,
    Collider3d::new(ColliderShape3d::ball(1.0F)),
  )
  try! world.set_by_key(
    body,
    ecs_key_active_collision_types3d,
    ActiveCollisionTypes3d::new(@collision.ActiveCollisionTypes::all()),
  )
  try! world.set_by_key(
    body,
    ecs_key_active_hooks3d,
    ActiveHooks3d::new(@collision.ActiveHooks::all()),
  )
  physics3d_sync_insertions_system(world)
  inspect(
    try! world.contains_by_key(body, ecs_key_rapier_collider_handle3d),
    content="true",
  )
}
