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
fn configured_window() -> @window.Window {
  let window = @window.Window::default()
  window.transparent = true
  window.decorations = true
  window.window_level = @window.WindowLevel::AlwaysOnTop
  window
}

///|
fn setup(world : @ecs.World) -> Unit {
  ignore(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::identity(),
    ).spawn(world),
  )

  let asset_server = @asset.AssetServer::new()
  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert(
      (
        @ui.UiRoot::default(),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Percent(100.0F)),
      ),
    ),
  )

  let label = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(label)
    .insert(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new("Hit 'P' then scroll/click around!"),
        @text.TextFont::from_font_size(@text.FontSize::Px(83.0F)).with_font(
          asset_server.load_font("fonts/FiraSans-Bold.ttf"),
        ),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_bottom(@ui.Val::Px(5.0F))
        .with_right(@ui.Val::Px(10.0F)),
      ),
    ),
  )
}

///|
fn toggle_mouse_passthrough(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  cursor_query : @ecs.Query[
    (@ecs.Comp[@window.PrimaryWindow], @ecs.Mut[@window.CursorOptions]),
    @ecs.All,
  ],
) -> Unit {
  if !keyboard_input.just_pressed(@window.KeyCode::KeyP) {
    return
  }
  guard (cursor_query.single() catch { _ => None })
    is Some((_primary, cursor_options)) else {
    return
  }
  let current = cursor_options.value()
  cursor_options.set(@window.CursorOptions::{
    ..current,
    hit_test: !current.hit_test,
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_window()),
      primary_cursor_options: Some(@window.CursorOptions::default()),
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    }),
  )
  .insert_resource(
    @sprite.ClearColor::new(@sprite.Color::new(0.0F, 0.0F, 0.0F, 0.0F)),
  )
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(toggle_mouse_passthrough)),
  )
  .run()
}
