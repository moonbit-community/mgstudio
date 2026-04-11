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
// Bevy source: `bevy/examples/window/low_power.rs`.

///|
pub(all) enum ExampleMode {
  Game
  Application
  ApplicationWithRequestRedraw
} derive(Eq, Debug)

///|
let example_mode_resource : @ecs.ResourceKey[ExampleMode] = @ecs.register_resource(
  debug_name="examples.window.low_power.ExampleMode",
)

///|
pub impl @app.Resource for ExampleMode with resource() {
  example_mode_resource
}

///|
fn cycle_modes(
  mode : @app.ResMut[ExampleMode],
  keyboard : @input.ButtonInput[@window.KeyCode],
) -> Unit {
  if !keyboard.just_pressed(@window.KeyCode::Space) {
    return
  }
  mode.get_ref().val = match mode.get_ref().val {
    Game => Application
    Application => ApplicationWithRequestRedraw
    ApplicationWithRequestRedraw => Game
  }
}

///|
fn update_winit(
  mode : @app.Res[ExampleMode],
  settings : @app.ResMut[@winit.WinitSettings],
  redraw_request_writer : @ecs.MessageWriter[@window.RequestRedraw],
) -> Unit {
  settings.get_ref().val = match mode.get() {
    Game => @winit.WinitSettings::game()
    Application => @winit.WinitSettings::desktop_app()
    ApplicationWithRequestRedraw => {
      ignore(redraw_request_writer.write(@window.RequestRedraw::{  }))
      @winit.WinitSettings::desktop_app()
    }
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::desktop_app())
  .insert_resource(ExampleMode::Game)
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Update, @app.system(@app.system_param2(cycle_modes)))
  .add_systems(@app.Update, @app.system(@app.system_param3(update_winit)))
  .run()
}
