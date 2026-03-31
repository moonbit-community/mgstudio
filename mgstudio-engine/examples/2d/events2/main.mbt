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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(rapier2d_events2_setup))
  .add_systems(@app.Update, @app.system(rapier2d_events2_print))
  .run()
}

///|
fn rapier2d_events2_setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  world
  .resource(@sprite.ClearColor::resource())
  .insert(
    @sprite.ClearColor::new(@sprite.Color::new(0.55F, 0.69F, 0.43F, 1.0F)),
  )
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current) =>
      cfg_res.insert(current.with_gravity(@math.Vec2::new(0.0F, -500.0F)))
    None =>
      cfg_res.insert(
        @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -500.0F)),
      )
  }
  let floor = world.spawn_empty()
  try! world.set_by_key(
    floor,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -250.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=0.0F,
    ),
  )
  try! world.set_by_key(
    floor,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::fixed(),
  )
  try! world.set_by_key(
    floor,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(390.0F, 18.0F),
    ),
  )
  let ball_a = world.spawn_empty()
  try! world.set_by_key(
    ball_a,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-120.0F, 30.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    ball_a,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.95F, 0.55F, 0.35F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(36.0F, 36.0F))),
  )
  try! world.set_by_key(
    ball_a,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    ball_a,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(18.0F)),
  )
  try! world.set_by_key(
    ball_a,
    @physics2d.ecs_key_active_events2d,
    @physics2d.ActiveEvents2d::new(
      @collision.ActiveEvents::collision_events().union(
        @collision.ActiveEvents::contact_force_events(),
      ),
    ),
  )
  try! world.set_by_key(
    ball_a,
    @physics2d.ecs_key_contact_force_event_threshold2d,
    @physics2d.ContactForceEventThreshold2d::new(0.1F),
  )
  let ball_b = world.spawn_empty()
  try! world.set_by_key(
    ball_b,
    @transform.ecs_key_transform,
    @transform.Transform::from_xy_rotation_scale(
      @math.Vec2::new(120.0F, 30.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=1.0F,
    ),
  )
  try! world.set_by_key(
    ball_b,
    @sprite.ecs_key_sprite,
    @sprite.Sprite::from_image(texture)
    .with_color(@sprite.Color::new(0.35F, 0.35F, 0.95F, 1.0F))
    .with_custom_size(Some(@math.Vec2::new(36.0F, 36.0F))),
  )
  try! world.set_by_key(
    ball_b,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    ball_b,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(18.0F)),
  )
  try! world.set_by_key(
    ball_b,
    @physics2d.ecs_key_active_events2d,
    @physics2d.ActiveEvents2d::new(
      @collision.ActiveEvents::collision_events().union(
        @collision.ActiveEvents::contact_force_events(),
      ),
    ),
  )
  try! world.set_by_key(
    ball_b,
    @physics2d.ecs_key_contact_force_event_threshold2d,
    @physics2d.ContactForceEventThreshold2d::new(0.1F),
  )
}

///|
fn rapier2d_events2_print(world : @ecs.World) -> Unit {
  let ev_res = @physics2d.get_physics2d_events_resource(world)
  guard ev_res.get() is Some(events) else { return }
  for ev in events.collisions {
    match ev {
      @physics2d.CollisionEvent2d::Started(a, b, sensor) =>
        println("[events2] collision started: \{a.id} \{b.id} sensor=\{sensor}")
      @physics2d.CollisionEvent2d::Stopped(a, b, sensor) =>
        println("[events2] collision stopped: \{a.id} \{b.id} sensor=\{sensor}")
    }
  }
  for ev in events.contact_forces {
    println(
      "[events2] contact force: \{ev.entity1.id} \{ev.entity2.id} force=\{ev.total_force_magnitude}",
    )
  }
}
