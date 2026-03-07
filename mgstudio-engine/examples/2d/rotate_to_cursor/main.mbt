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
priv struct RotateToCursorState {
  mut player : @core.Entity
}

///|
let rotate_to_cursor_state : Ref[RotateToCursorState] = Ref::new(RotateToCursorState::{
  player: @core.Entity::placeholder(),
})

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(rotate_to_cursor_setup))
  .add_systems(@app.FixedUpdate, @app.system(rotate_to_cursor_update))
  .run()
}

///|
fn rotate_to_cursor_setup(world : @ecs.World) -> Unit {
  rotate_to_cursor_state.val.player = @core.Entity::placeholder()

  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("textures/simplespace/ship_C.png")
  let sprite = @render2d.Sprite::from_image(texture)
  let transform = @math.Transform::identity()
  let player = @render2d.SpriteBundle::new(sprite, transform).spawn(world)
  rotate_to_cursor_state.val.player = player

  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}

///|
fn rotate_to_cursor_update(world : @ecs.World) -> Unit {
  let player = rotate_to_cursor_state.val.player
  if player.is_placeholder() {
    return
  }

  if @input.mouse_position() is Some(screen_pos) {
    if @render2d.render2d_viewport_to_world_2d(world, screen_pos)
      is Some(world_pos) {
      guard (try! world.get(player, @math.ecs_key_transform)) is Some(transform) else {
        return
      }

      let delta = @math.Vec2::new(
        world_pos.x - transform.translation.x,
        world_pos.y - transform.translation.y,
      )
      let angle = delta.to_angle() - @math.pi_half()
      let next_transform = @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(transform.translation.x, transform.translation.y),
        angle,
        @math.Vec2::new(transform.scale.x, transform.scale.y),
        z=transform.translation.z,
      )

      try! world.set(player, @math.ecs_key_transform, next_transform)
    }
  }
}
