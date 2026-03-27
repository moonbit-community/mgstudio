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
const GRID_HALF_X : Int = 20

///|
const GRID_HALF_Y : Int = 12

///|
const SPACING : Float = 42.0F

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let texture = asset_server.get().load("branding/icon.png")
  for y in -GRID_HALF_Y..<GRID_HALF_Y {
    for x in -GRID_HALF_X..<GRID_HALF_X {
      let idx = (y + GRID_HALF_Y) * (GRID_HALF_X * 2) + (x + GRID_HALF_X)
      ignore(
        commands.spawn(
          (
            @sprite.Sprite::from_image(texture)
            .with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F)))
            .with_color(
              @sprite.Color::hsl(float_from_int(idx % 360), 0.75F, 0.62F),
            ),
            @transform.Transform::from_xyz(
              float_from_int(x) * SPACING,
              float_from_int(y) * SPACING,
              float_from_int(idx % 100) / 100.0F,
            ).with_rotation(
              @math.Quat::from_rotation_z(
                float_from_int(idx % 360) * 0.017453292519943295F,
              ),
            ),
          ),
        ),
      )
    }
  }
}

///|
fn move_camera(
  time : @app.Res[@time.Time[Unit]],
  camera : @ecs.Query[
    @ecs.Mut[@transform.Transform],
    @ecs.With[@sprite.Camera2d],
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! camera.for_each(fn(_entity, transform) {
    let transform_ref = transform.get_ref()
    transform_ref.val.translation = @math.Vec3::new(
      @math.cos(t * 0.22F) * 360.0F,
      @math.sin(t * 0.22F) * 220.0F,
      0.0F,
    )
    transform_ref.val.rotation = @math.Quat::from_rotation_z(t * 0.08F)
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(move_camera)))
  .run()
}
