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
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(physics3d_sanity_setup)
  .add_system(physics3d_sanity_print)
  .run()
}

///|
priv struct SanityState {
  mut ball : @core.Entity?
}

///|
let state : Ref[SanityState] = Ref::new({ ball: None })

///|
fn physics3d_sanity_setup(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = @physics3d.HasRes_Physics3dConfig::get_physics3d_config_resource(
    world,
  )
  match cfg_res.get_ref_mut(tick) {
    Some(r) =>
      r.val = @physics3d.Physics3dConfig::new(
        @math.Vec3::new(0.0F, -500.0F, 0.0F),
      )
    None => ()
  }
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  // Floor (rendered as a 2D sprite; simulated with 3D collider at z=0).
  let floor_sprite = @render2d.Sprite::from_image(texture)
  let floor_transform = @math.Transform::from_xyz(0.0F, -200.0F, 0.0F)
  let floor = @render2d.SpriteBundle::new(floor_sprite, floor_transform).spawn(
    world,
  )
  let rb_store = @physics3d.Has_RigidBody3d::get_rigid_body3d_store(world)
  let col_store = @physics3d.Has_Collider3d::get_collider3d_store(world)
  rb_store.insert(floor, @physics3d.RigidBody3d::fixed(), tick)
  col_store.insert(
    floor,
    @physics3d.Collider3d::new(
      @physics3d.ColliderShape3d::cuboid(320.0F, 16.0F, 16.0F),
    ),
    tick,
  )

  // Ball.
  let ball_sprite = @render2d.Sprite::from_image(texture)
  let ball_transform = @math.Transform::from_xyz(0.0F, 200.0F, 0.0F)
  let ball = @render2d.SpriteBundle::new(ball_sprite, ball_transform).spawn(
    world,
  )
  rb_store.insert(ball, @physics3d.RigidBody3d::dynamic(), tick)
  col_store.insert(
    ball,
    @physics3d.Collider3d::new(@physics3d.ColliderShape3d::ball(12.0F)),
    tick,
  )
  state.val.ball = Some(ball)

  // Camera.
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn physics3d_sanity_print(world : @ecs_world.World) -> Unit {
  match state.val.ball {
    None => ()
    Some(ball) => {
      let transform_store = @math.Has_Transform::get_transform_store(world)
      match transform_store.get(ball) {
        None => ()
        Some(t) => println("ball.y=\{t.translation.y}")
      }
      let ev_res = @physics3d.HasRes_Physics3dEvents::get_physics3d_events_resource(
        world,
      )
      match ev_res.get_ref() {
        Some(r) =>
          for ev in r.val.collisions {
            match ev {
              @physics3d.CollisionEvent3d::Started(a, b, sensor) =>
                println("Collision Started: \{a.id}, \{b.id}, sensor=\{sensor}")
              @physics3d.CollisionEvent3d::Stopped(a, b, sensor) =>
                println("Collision Stopped: \{a.id}, \{b.id}, sensor=\{sensor}")
            }
          }
        None => ()
      }
    }
  }
}
