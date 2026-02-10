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
/// Physics2D query example:
/// - Builds a simple scene (floor + ball).
/// - Periodically raycasts downward and prints the closest hit.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(physics2d_queries_setup)
  .add_system(physics2d_queries_raycast)
  .run()
}

///|
priv struct QueryState {
  mut accumulator : Float
}

///|
let query_state : Ref[QueryState] = Ref::new(QueryState::{ accumulator: 0.0F })

///|
fn physics2d_queries_setup(world : @ecs_world.World) -> Unit {
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let cfg_res = @physics2d.HasRes_Physics2dConfig::get_physics2d_config_resource(
    world,
  )
  match cfg_res.get_ref_mut(tick) {
    Some(r) =>
      r.val = @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -500.0F))
    None => ()
  }
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  // Floor.
  let floor_sprite = @render2d.Sprite::from_image(texture)
  let floor_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, -200.0F),
    0.0F,
    @math.Vec2::new(8.0F, 0.5F),
    z=0.0F,
  )
  let floor = @render2d.SpriteBundle::new(floor_sprite, floor_transform).spawn(
    world,
  )
  let rb_store = @physics2d.Has_RigidBody2d::get_rigid_body2d_store(world)
  let col_store = @physics2d.Has_Collider2d::get_collider2d_store(world)
  rb_store.insert(floor, @physics2d.RigidBody2d::fixed(), tick)
  col_store.insert(
    floor,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(320.0F, 16.0F),
    ),
    tick,
  )

  // Ball.
  let ball_sprite = @render2d.Sprite::from_image(texture)
  let ball_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, 200.0F),
    0.0F,
    @math.Vec2::new(0.3F, 0.3F),
    z=1.0F,
  )
  let ball = @render2d.SpriteBundle::new(ball_sprite, ball_transform).spawn(
    world,
  )
  rb_store.insert(ball, @physics2d.RigidBody2d::dynamic(), tick)
  col_store.insert(
    ball,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(12.0F)),
    tick,
  )
  @physics2d.Has_Velocity2d::get_velocity2d_store(world).insert(
    ball,
    @physics2d.Velocity2d::zero(),
    tick,
  )

  // Camera.
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn physics2d_queries_raycast(world : @ecs_world.World) -> Unit {
  query_state.val.accumulator = query_state.val.accumulator +
    @time.time_delta_seconds()
  if query_state.val.accumulator < 1.0F {
    return
  }
  query_state.val.accumulator = 0.0F
  let ctx_res = @physics2d.HasRes_Physics2dContext::get_physics2d_context_resource(
    world,
  )
  guard ctx_res.get_ref() is Some(r) else { return }
  let ctx = r.val
  let hit = ctx.cast_ray_and_get_normal_entity(
    @math.Vec2::new(0.0F, 300.0F),
    @math.Vec2::new(0.0F, -1.0F),
    1000.0F,
    true,
  )
  match hit {
    None => println("Ray hit: none")
    Some(h) =>
      println(
        "Ray hit: entity=\{h.entity.id} toi=\{h.toi} normal=(\{h.normal.x},\{h.normal.y})",
      )
  }
}
