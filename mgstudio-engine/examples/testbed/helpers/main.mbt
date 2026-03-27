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
const ITEM_COUNT : Int = 180

///|
struct Wiggle {
  phase : Float
}

///|
let wiggle_key : @ecs.ComponentKey[Wiggle] = @ecs.register_component(
  debug_name="examples.testbed.helpers.Wiggle",
)

///|
pub impl @ecs.Component for Wiggle with component() {
  wiggle_key
}

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
  let icon = asset_server.get().load("branding/icon.png")
  let bird = asset_server.get().load("branding/bevy_bird_dark.png")

  for i in 0..<ITEM_COUNT {
    let angle = float_from_int(i) /
      float_from_int(ITEM_COUNT) *
      6.283185307179586F
    let radius = 80.0F + float_from_int(i % 12) * 22.0F
    let texture = if i % 2 == 0 { icon } else { bird }
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::from_image(texture)
          .with_custom_size(Some(@math.Vec2::new(28.0F, 28.0F)))
          .with_color(
            @sprite.Color::hsl(float_from_int(i * 13 % 360), 0.8F, 0.62F),
          ),
          @transform.Transform::from_xyz(
            @math.cos(angle) * radius,
            @math.sin(angle) * radius,
            float_from_int(i % 100) / 100.0F,
          ),
          Wiggle::{ phase: angle },
        ),
      ),
    )
  }
}

///|
fn animate(
  time : @app.Res[@time.Time[Unit]],
  items : @ecs.Query[
    (@ecs.Comp[Wiggle], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! items.for_each(fn(_entity, data) {
    let (wiggle, transform) = data
    let transform_ref = transform.get_ref()
    transform_ref.val.translation.x += @math.sin(t + wiggle.value().phase) *
      0.7F
    transform_ref.val.translation.y += @math.cos(t + wiggle.value().phase) *
      0.7F
    transform_ref.val.rotation = @math.Quat::from_rotation_z(
      t * 0.4F + wiggle.value().phase,
    )
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
  .add_systems(@app.Update, @app.system(@app.system_param2(animate)))
  .run()
}
