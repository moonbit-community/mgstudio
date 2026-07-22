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
struct Player {}

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.2d.rotate_to_cursor.Player",
)

///|
pub impl @ecs.Component for Player with fn component() {
  player_key
}

///|
struct MainCamera {}

///|
let main_camera_key : @ecs.ComponentKey[MainCamera] = @ecs.register_component(
  debug_name="examples.2d.rotate_to_cursor.MainCamera",
)

///|
pub impl @ecs.Component for MainCamera with fn component() {
  main_camera_key
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param2(Startup, setup)
  .add_systems_param3(FixedUpdate, player_movement_system)
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("textures/simplespace/ship_C.png"),
        ),
        Player::{  },
      ),
    ),
  )
  ignore(
    commands.spawn(
      (@camera_components2d.Camera2d::Camera2d(), MainCamera::{  }),
    ),
  )
}

///|
fn player_movement_system(
  player : @app.Single[@ecs.Write[@transform.Transform], @ecs.With[Player]],
  camera_query : @app.Single[
    (
      @ecs.Read[@camera_camera.Camera],
      @ecs.Read[@camera_projection2d.Projection],
      @ecs.Read[@transform.GlobalTransform],
    ),
    @ecs.With[MainCamera],
  ],
  window : @app.Single[
    @ecs.Read[@window.Window],
    @ecs.With[@window.PrimaryWindow],
  ],
) -> Unit {
  let (camera_comp, projection_comp, camera_global_transform_comp) = camera_query.get()
  let camera = camera_comp.value()
  let projection = projection_comp.value()
  guard projection is Orthographic(orthographic_projection) else { return }
  let camera_transform = camera_global_transform_comp
    .value()
    .to_transform_approx()
  let window_comp = window.get()
  let window = window_comp.value()
  guard @input.mouse_position() is Some(cursor_position) else { return }

  let window_size = @math.IVec2::new(
    window.width().to_int(),
    window.height().to_int(),
  )
  if window_size.x <= 0 || window_size.y <= 0 {
    return
  }
  guard camera.viewport_to_world_2d(
      camera_transform,
      cursor_position,
      orthographic_projection,
      window_size,
      window.scale_factor(),
    )
    is Some(cursor_world_pos) else {
    return
  }

  let player_transform = player.get()
  let current = player_transform.value()
  player_transform.modify(fn(value) {
    value.rotation = @math.Quat::from_rotation_z(
      @math.Vec2::new(
        cursor_world_pos.x - current.translation.x,
        cursor_world_pos.y - current.translation.y,
      ).to_angle() -
      @math.pi_half(),
    )
  })
}
