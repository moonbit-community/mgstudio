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
/// Port of `bevy/examples/camera/2d_top_down_camera.rs`.

///|
const PLAYER_SPEED : Float = 100.0F

///|
const CAMERA_DECAY_RATE : Float = 2.0F

///|
struct Player {}

///|
let player_key : @ecs.ComponentKey[Player] = @ecs.register_component(
  debug_name="examples.camera.2d_top_down_camera.Player",
)

///|
pub impl @ecs.Component for Player with component() {
  player_key
}

///|
fn setup_scene(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(
    commands.spawn(
      (
        @sprite.Mesh2d::new(
          meshes.get_ref().val
          |> @sprite.add_mesh(@sprite.Rectangle::new(1000.0F, 700.0F)),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val
          |> @sprite.add_material(@sprite.Color::new(0.2F, 0.2F, 0.3F, 1.0F)),
        ),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        Player::{  },
        @sprite.Mesh2d::new(
          meshes.get_ref().val |> @sprite.add_mesh(@sprite.Circle::new(25.0F)),
        ),
        @sprite.MeshMaterial2d::new(
          materials.get_ref().val
          |> @sprite.add_material(@sprite.Color::new(6.25F, 9.4F, 9.1F, 1.0F)),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 2.0F),
      ),
    ),
  )
}

///|
fn setup_instructions(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Move the light with WASD.\nThe camera will smoothly track the light.",
        ),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          left: @ui.Val::Px(12.0F),
          bottom: @ui.Val::Px(12.0F),
        },
      ),
    ),
  )
}

///|
fn setup_camera(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn((@sprite.Camera2d::default(), @sprite.Bloom::natural())),
  )
}

///|
fn move_player(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query2[@transform.Transform, Player],
) -> Unit {
  let direction = @math.Vec2::zero()
  if keyboard_input.pressed(@window.KeyCode::KeyW) {
    direction.y = direction.y + 1.0F
  }
  if keyboard_input.pressed(@window.KeyCode::KeyS) {
    direction.y = direction.y - 1.0F
  }
  if keyboard_input.pressed(@window.KeyCode::KeyA) {
    direction.x = direction.x - 1.0F
  }
  if keyboard_input.pressed(@window.KeyCode::KeyD) {
    direction.x = direction.x + 1.0F
  }

  let delta_seconds = time.get().delta_seconds()
  let move_delta = direction
    .normalize_or_zero()
    .mul_scalar(PLAYER_SPEED * delta_seconds)
  try! query.for_each(fn(_entity, transform, _player) {
    transform.translation = transform.translation.add(
      @math.Vec3::new(move_delta.x, move_delta.y, 0.0F),
    )
  })
}

///|
fn update_camera(
  player_query : @ecs.Query2[@transform.Transform, Player],
  camera_query : @ecs.Query2[@transform.Transform, @sprite.Camera2d],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let player_translation : Ref[@math.Vec3?] = Ref::new(None)
  try! player_query.for_each(fn(_entity, transform, _player) {
    player_translation.val = Some(transform.translation)
  })
  guard player_translation.val is Some(target_translation) else { return }

  let delta_seconds = time.get().delta_seconds()
  try! camera_query.for_each(fn(_entity, transform, _camera) {
    transform.translation.smooth_nudge(
      @math.Vec3::new(
        target_translation.x,
        target_translation.y,
        transform.translation.z,
      ),
      CAMERA_DECAY_RATE,
      delta_seconds,
    )
  })
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  let move_player_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(move_player),
  )
  let update_camera_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param3(update_camera),
  )
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup_scene)))
  .add_systems(@app.Startup, @app.system(@app.system_param(setup_instructions)))
  .add_systems(@app.Startup, @app.system(@app.system_param(setup_camera)))
  .add_systems(
    @app.Update,
    (move_player_system, update_camera_system) |> @app.chain(),
  )
  .run()
}
