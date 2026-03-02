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
/// Port of `bevy/examples/window/clear_color.rs`.

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins_ecs()
  @app.App::new(@ecs.World::new())
  .insert_resource(
    @render2d.ClearColor::new(@render2d.Color::new(0.5F, 0.5F, 0.9F, 1.0F)),
  )
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(@app.system_param2(change_clear_color_system))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn_ecs(world)
  |> ignore
}

///|
fn change_clear_color_system(
  input : @input.ButtonInput[@window.KeyCode],
  clear_color : @app.ResMut[@render2d.ClearColor],
) -> Unit {
  if input.just_pressed(Space) {
    clear_color.get_ref().val = @render2d.ClearColor::new(
      @render2d.Color::new(0.5F, 0.0F, 0.5F, 1.0F),
    )
  }
}
