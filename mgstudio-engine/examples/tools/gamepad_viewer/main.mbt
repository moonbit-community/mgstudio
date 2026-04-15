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
struct GamepadIndicator {}

///|
let gamepad_indicator_key : @ecs.ComponentKey[GamepadIndicator] = @ecs.register_component(
  debug_name="examples.tools.gamepad_viewer.GamepadIndicator",
)

///|
pub impl @ecs.Component for GamepadIndicator with component() {
  gamepad_indicator_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(360.0F, 220.0F)).with_color(
          @sprite.Color::srgb(0.15F, 0.18F, 0.2F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, -1.0F),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::sized(@math.Vec2::new(280.0F, 280.0F)).with_color(
          @sprite.Color::srgb(0.9F, 0.3F, 0.25F),
        ),
        @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
        GamepadIndicator::{  },
      ),
    ),
  )
}

///|
fn update_indicator(
  time : @app.Res[@time.Time[Unit]],
  gamepads : @ecs.Query[@ecs.Comp[@input.Gamepad], @ecs.All],
  indicators : @ecs.Query[@ecs.Mut[@sprite.Sprite], @ecs.With[GamepadIndicator]],
) -> Unit {
  let mut connected = 0
  let mut any_pressed = false
  try! gamepads.for_each(fn(_entity, gamepad) {
    connected += 1
    let state = gamepad.value()
    if state.pressed(@input.GamepadButton::South) ||
      state.pressed(@input.GamepadButton::East) ||
      state.pressed(@input.GamepadButton::West) ||
      state.pressed(@input.GamepadButton::North) {
      any_pressed = true
    }
  })

  let pulse = 0.5F + 0.5F * @math.sin(time.get().elapsed_secs() * 3.2F)
  let color = if connected == 0 {
    @sprite.Color::srgb(0.9F, 0.3F, 0.25F)
  } else if any_pressed {
    @sprite.Color::srgb(0.25F, 0.95F, 0.35F)
  } else {
    @sprite.Color::srgb(0.2F + pulse * 0.25F, 0.45F + pulse * 0.35F, 1.0F)
  }
  try! indicators.for_each(fn(_entity, indicator) {
    indicator.get_ref().val.color = color
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param3(update_indicator)))
  .run()
}
