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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(physics2d_falling_setup))
  .add_systems(@app.Update, @app.system(physics2d_print_events))
  .run()
}

///|
fn physics2d_falling_setup(world : @ecs.World) -> Unit {
  // Make gravity visible in "pixel-ish" space.
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current_cfg) => {
      let cfg = Ref::new(current_cfg)
      cfg.val = @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -500.0F))
      cfg_res.insert(cfg.val)
    }
    None => ()
  }
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  // Floor.
  let floor_sprite = @sprite.Sprite::from_image(texture)
  let floor_transform = @transform.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, -200.0F),
    0.0F,
    @math.Vec2::new(8.0F, 0.5F),
    z=0.0F,
  )
  let floor = @sprite.SpriteBundle::new(floor_sprite, floor_transform).spawn(
    world,
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
      @physics2d.ColliderShape2d::cuboid(320.0F, 16.0F),
    ),
  )
  // Enable contact force events for the floor/ball interaction.
  try! world.set_by_key(
    floor,
    @physics2d.ecs_key_contact_force_event_threshold2d,
    @physics2d.ContactForceEventThreshold2d::new(0.0F),
  )

  // Ball.
  let ball_sprite = @sprite.Sprite::from_image(texture)
  let ball_transform = @transform.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, 200.0F),
    0.0F,
    @math.Vec2::new(0.3F, 0.3F),
    z=1.0F,
  )
  let ball = @sprite.SpriteBundle::new(ball_sprite, ball_transform).spawn(world)
  try! world.set_by_key(
    ball,
    @physics2d.ecs_key_rigid_body2d,
    @physics2d.RigidBody2d::dynamic(),
  )
  try! world.set_by_key(
    ball,
    @physics2d.ecs_key_collider2d,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(12.0F)),
  )
  try! world.set_by_key(
    ball,
    @physics2d.ecs_key_contact_force_event_threshold2d,
    @physics2d.ContactForceEventThreshold2d::new(0.0F),
  )
  try! world.set_by_key(
    ball,
    @physics2d.ecs_key_velocity2d,
    @physics2d.Velocity2d::zero(),
  )

  // Camera.
  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @transform.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn physics2d_print_events(world : @ecs.World) -> Unit {
  let ev_res = @physics2d.get_physics2d_events_resource(world)
  match ev_res.get() {
    Some(events) => {
      for ev in events.collisions {
        match ev {
          @physics2d.CollisionEvent2d::Started(a, b, sensor) =>
            println("Collision Started: \{a.id}, \{b.id}, sensor=\{sensor}")
          @physics2d.CollisionEvent2d::Stopped(a, b, sensor) =>
            println("Collision Stopped: \{a.id}, \{b.id}, sensor=\{sensor}")
        }
      }
      for ev in events.contact_forces {
        println(
          "Contact force: \{ev.entity1.id}, \{ev.entity2.id}, |F|=\{ev.total_force_magnitude}",
        )
      }
    }
    None => ()
  }
}
