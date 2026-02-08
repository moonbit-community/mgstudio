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
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(physics2d_showcase_setup)
  .add_system(physics2d_showcase_print_events)
  .run()
}

///|
fn physics2d_showcase_setup(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = @physics2d.HasRes_Physics2dConfig::get_physics2d_config_resource(
    world,
  )
  match cfg_res.get_ref_mut(tick) {
    Some(r) =>
      r.val = @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -600.0F))
    None => ()
  }
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")
  let rb_store = @physics2d.Has_RigidBody2d::get_rigid_body2d_store(world)
  let col_store = @physics2d.Has_Collider2d::get_collider2d_store(world)
  let vel_store = @physics2d.Has_Velocity2d::get_velocity2d_store(world)
  let cf_store = @physics2d.Has_ContactForceEventThreshold2d::get_contact_force_event_threshold2d_store(
    world,
  )
  let floor = @render2d.SpriteBundle::new(
    @render2d.Sprite::from_image(texture),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(0.0F, -220.0F),
      0.0F,
      @math.Vec2::new(8.5F, 0.5F),
      z=0.0F,
    ),
  ).spawn(world)
  rb_store.insert(floor, @physics2d.RigidBody2d::fixed(), tick)
  col_store.insert(
    floor,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(340.0F, 16.0F),
    ),
    tick,
  )
  cf_store.insert(
    floor,
    @physics2d.ContactForceEventThreshold2d::new(0.0F),
    tick,
  )
  for i in 0..<8 {
    let i_f = Float::from_int(i)
    let i_mod_2_f = Float::from_int(i % 2)
    let x = -210.0F + i_f * 60.0F
    let y = 160.0F + i_mod_2_f * 70.0F
    let scale = if i % 2 == 0 { 0.28F } else { 0.34F }
    let e = @render2d.SpriteBundle::new(
      @render2d.Sprite::from_image(texture),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(x, y),
        0.0F,
        @math.Vec2::new(scale, scale),
        z=1.0F + i_f * 0.01F,
      ),
    ).spawn(world)
    rb_store.insert(e, @physics2d.RigidBody2d::dynamic(), tick)
    let collider = if i % 2 == 0 {
      @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(12.0F))
    } else {
      @physics2d.Collider2d::new(
        @physics2d.ColliderShape2d::cuboid(10.0F, 10.0F),
      )
    }
    col_store.insert(e, collider, tick)
    cf_store.insert(e, @physics2d.ContactForceEventThreshold2d::new(0.0F), tick)
    let vx = if i % 2 == 0 { 50.0F } else { -45.0F }
    vel_store.insert(
      e,
      @physics2d.Velocity2d::new(@math.Vec2::new(vx, 0.0F), 0.0F),
      tick,
    )
  }
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore
}

///|
fn physics2d_showcase_print_events(world : @ecs_world.World) -> Unit {
  let ev_res = @physics2d.HasRes_Physics2dEvents::get_physics2d_events_resource(
    world,
  )
  match ev_res.get_ref() {
    Some(r) =>
      for ev in r.val.collisions {
        match ev {
          @physics2d.CollisionEvent2d::Started(a, b, sensor) =>
            println("Collision Started: \{a.id}, \{b.id}, sensor=\{sensor}")
          @physics2d.CollisionEvent2d::Stopped(a, b, sensor) =>
            println("Collision Stopped: \{a.id}, \{b.id}, sensor=\{sensor}")
        }
      }
    None => ()
  }
}
