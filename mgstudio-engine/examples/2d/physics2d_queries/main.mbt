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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(physics2d_queries_setup))
  .add_systems(@app.Update, @app.system(physics2d_queries_raycast))
  .run()
}

///|
priv struct QueryState {
  mut accumulator : Float
  mut phase : Float
  mut ray_line : @core.Entity?
  mut hit_marker : @core.Entity?
}

///|
let query_state : Ref[QueryState] = Ref::new(QueryState::{
  accumulator: 0.0F,
  phase: 0.0F,
  ray_line: None,
  hit_marker: None,
})

///|
const RAY_ORIGIN_Y : Float = 300.0F

///|
const RAY_LENGTH : Float = 1000.0F

///|
const RAY_HALF_LENGTH : Float = 500.0F

///|
const RAY_LINE_SCALE_Y : Float = 7.8125F

///|
const RAY_SWEEP_AMPLITUDE : Float = 220.0F

///|
fn physics2d_queries_setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let cfg_res = @physics2d.get_physics2d_config_resource(world)
  match cfg_res.get() {
    Some(current_cfg) => {
      let cfg = Ref::new(current_cfg)
      cfg.val = @physics2d.Physics2dConfig::new(@math.Vec2::new(0.0F, -500.0F))
      cfg_res.insert(cfg.val, tick)
    }
    None => ()
  }
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/icon.png")

  // Floor.
  let floor_sprite = @sprite.Sprite::from_image(texture)
  let floor_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, -200.0F),
    0.0F,
    @math.Vec2::new(8.0F, 0.5F),
    z=0.0F,
  )
  let floor = @sprite.SpriteBundle::new(floor_sprite, floor_transform).spawn(
    world,
  )
  let rb_store = @physics2d.get_rigid_body2d_store(world)
  let col_store = @physics2d.get_collider2d_store(world)
  rb_store.insert(floor, @physics2d.RigidBody2d::fixed(), tick)
  col_store.insert(
    floor,
    @physics2d.Collider2d::new(
      @physics2d.ColliderShape2d::cuboid(320.0F, 16.0F),
    ),
    tick,
  )

  // Ball.
  let ball_sprite = @sprite.Sprite::from_image(texture)
  let ball_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, 200.0F),
    0.0F,
    @math.Vec2::new(0.3F, 0.3F),
    z=1.0F,
  )
  let ball = @sprite.SpriteBundle::new(ball_sprite, ball_transform).spawn(world)
  rb_store.insert(ball, @physics2d.RigidBody2d::dynamic(), tick)
  col_store.insert(
    ball,
    @physics2d.Collider2d::new(@physics2d.ColliderShape2d::ball(12.0F)),
    tick,
  )
  @physics2d.get_velocity2d_store(world).insert(
    ball,
    @physics2d.Velocity2d::zero(),
    tick,
  )

  // Camera.
  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(world)
  |> ignore

  // Visible query line.
  let ray_line_sprite = @sprite.Sprite::from_image(texture).with_color(
    @sprite.Color::new(1.0F, 0.95F, 0.2F, 0.65F),
  )
  let ray_line_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, RAY_ORIGIN_Y - RAY_HALF_LENGTH),
    0.0F,
    @math.Vec2::new(0.035F, RAY_LINE_SCALE_Y),
    z=2.0F,
  )
  let ray_line = @sprite.SpriteBundle::new(ray_line_sprite, ray_line_transform).spawn(
    world,
  )

  // Visible hit marker.
  let hit_marker_sprite = @sprite.Sprite::from_image(texture).with_color(
    @sprite.Color::new(1.0F, 0.25F, 0.25F, 0.9F),
  )
  let hit_marker_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(0.0F, RAY_ORIGIN_Y),
    0.0F,
    @math.Vec2::new(0.14F, 0.14F),
    z=3.0F,
  )
  let hit_marker = @sprite.SpriteBundle::new(
    hit_marker_sprite, hit_marker_transform,
  ).spawn(world)

  query_state.val.phase = 0.0F
  query_state.val.ray_line = Some(ray_line)
  query_state.val.hit_marker = Some(hit_marker)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in physics2d_queries example")
  }
}

///|
fn physics2d_queries_raycast(world : @ecs.World) -> Unit {
  let delta_seconds = world_time(world).delta_seconds()
  let tick = world.read_change_tick()
  let transform_store = world.component(@math.ecs_key_transform)
  query_state.val.phase = query_state.val.phase + delta_seconds * 0.75F
  let ray_x = @math.sin(query_state.val.phase) * RAY_SWEEP_AMPLITUDE

  if query_state.val.ray_line is Some(ray_line) {
    let ray_transform = @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(ray_x, RAY_ORIGIN_Y - RAY_HALF_LENGTH),
      0.0F,
      @math.Vec2::new(0.035F, RAY_LINE_SCALE_Y),
      z=2.0F,
    )
    transform_store.insert(ray_line, ray_transform, tick)
  }

  query_state.val.accumulator = query_state.val.accumulator + delta_seconds
  if query_state.val.accumulator < 1.0F {
    return
  }
  query_state.val.accumulator = 0.0F
  let ctx_res = @physics2d.get_physics2d_context_resource(world)
  guard ctx_res.get() is Some(ctx) else { return }
  let hit = ctx.cast_ray_and_get_normal_entity(
    @math.Vec2::new(ray_x, RAY_ORIGIN_Y),
    @math.Vec2::new(0.0F, -1.0F),
    RAY_LENGTH,
    true,
  )
  match hit {
    None => {
      if query_state.val.hit_marker is Some(hit_marker) {
        let hidden_transform = @math.Transform::from_xy_rotation_scale(
          @math.Vec2::new(ray_x, RAY_ORIGIN_Y + 128.0F),
          0.0F,
          @math.Vec2::new(0.08F, 0.08F),
          z=3.0F,
        )
        transform_store.insert(hit_marker, hidden_transform, tick)
      }
      println("Ray hit: none")
    }
    Some(h) => {
      if query_state.val.hit_marker is Some(hit_marker) {
        let hit_transform = @math.Transform::from_xy_rotation_scale(
          @math.Vec2::new(ray_x, RAY_ORIGIN_Y - h.toi),
          0.0F,
          @math.Vec2::new(0.14F, 0.14F),
          z=3.0F,
        )
        transform_store.insert(hit_marker, hit_transform, tick)
      }
      println(
        "Ray hit: entity=\{h.entity.id} toi=\{h.toi} normal=(\{h.normal.x},\{h.normal.y})",
      )
    }
  }
}
