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

///|
const PRIMARY_WINDOW_TITLE : String = "Primary window"

///|
const SECONDARY_WINDOW_TITLE : String = "Secondary Window"

///|
const UI_TEXT_PRIMARY : String = "UI Text Primary Window"

///|
const UI_TEXT_SECONDARY : String = "UI Text Secondary Window"

///|
const TEXT2D_PRIMARY : String = "Text2d Primary Window"

///|
const TEXT2D_SECONDARY : String = "Text2d Secondary Window"

///|
const TEXT2D_BOTH : String = "Text2d Both Windows"

///|
fn configured_primary_window() -> @window.Window {
  let window = @window.Window::default()
  window.title = PRIMARY_WINDOW_TITLE
  window.resolution = @window.WindowResolution::default().with_scale_factor_override(
    1.0F,
  )
  window
}

///|
fn configured_secondary_window() -> @window.Window {
  let window = @window.Window::default()
  window.title = SECONDARY_WINDOW_TITLE
  window.resolution = @window.WindowResolution::default().with_scale_factor_override(
    2.0F,
  )
  window
}

///|
fn spawn_ui_label(
  world : @ecs.World,
  content : String,
  ui_camera : @core.Entity?,
  font : @text.TextFont,
) -> Unit {
  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_top(@ui.Val::Px(12.0F))
    .with_left(@ui.Val::Px(12.0F)),
  )

  if ui_camera is Some(camera) {
    try! world.set_by_key(
      root,
      @ui.ecs_key_ui_target_camera,
      @ui.UiTargetCamera::new(camera),
    )
  }

  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text,
    @text.Text::new(content),
  )
  try! world.set_by_key(text_entity, @text.ecs_key_text_font, font)
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::srgb(1.0F, 1.0F, 0.0F)),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_shadow,
    @text.TextShadow::default(),
  )
}

///|
fn setup_scene(world : @ecs.World) -> Unit {
  let text_font = @text.TextFont::from_font_size(30.0F)

  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_clear_color(
      @sprite.Color::srgb(0.14F, 0.12F, 0.20F),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  if @render.host_gpu_mesh3d_preprocess_disabled() {
    spawn_ui_label(world, UI_TEXT_PRIMARY, None, text_font)
    return
  }

  let secondary_window = world.spawn_empty()
  try! world.set_by_key(
    secondary_window,
    @window.ecs_key_window,
    configured_secondary_window(),
  )

  let secondary_window_camera = @sprite.Camera2dBundle::new_with_layers(
    @sprite.Camera::default().with_clear_color(
      @sprite.Color::srgb(0.08F, 0.10F, 0.14F),
    ),
    @transform.Transform::identity(),
    @sprite.RenderTarget::Window(@window.WindowRef::Entity(secondary_window)),
    @sprite.RenderLayers::layer(1),
  ).spawn(world)

  spawn_ui_label(world, UI_TEXT_PRIMARY, None, text_font)
  spawn_ui_label(
    world,
    UI_TEXT_SECONDARY,
    Some(secondary_window_camera),
    text_font,
  )

  @text.Text2dBundle::new(
    @text.Text2d::new(TEXT2D_PRIMARY),
    text_font,
    @transform.Transform::identity(),
  )
  .with_color(@text.TextColor::new(@sprite.Color::srgb(1.0F, 1.0F, 0.0F)))
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore

  @text.Text2dBundle::new_with_layers(
    @text.Text2d::new(TEXT2D_SECONDARY),
    text_font,
    @transform.Transform::identity(),
    @sprite.RenderLayers::layer(1),
  )
  .with_color(@text.TextColor::new(@sprite.Color::srgb(1.0F, 1.0F, 0.0F)))
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore

  @text.Text2dBundle::new_with_layers(
    @text.Text2d::new(TEXT2D_BOTH),
    text_font,
    @transform.Transform::from_xyz(0.0F, -50.0F, 0.0F),
    @sprite.RenderLayers::from_layers([0, 1]),
  )
  .with_color(@text.TextColor::new(@sprite.Color::srgb(0.8784314F, 1.0F, 1.0F)))
  .with_shadow(Some(@text.Text2dShadow::default()))
  .spawn()
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@window.WindowPlugin::{
      primary_window: Some(configured_primary_window()),
      primary_cursor_options: Some(@window.CursorOptions::default()),
      exit_condition: @window.ExitCondition::OnAllClosed,
      close_when_requested: true,
    })
  })
  .add_systems(@app.Startup, @app.system(setup_scene))
  .run()
}
