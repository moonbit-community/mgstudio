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
/// Port of `bevy/examples/dev_tools/fps_overlay.rs`.
fn overlay_red() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 0.0F, 0.0F)
}

///|
fn overlay_green() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 1.0F, 0.0F)
}

///|
fn main {
  let overlay_plugin = @dev_tools.FpsOverlayPlugin::{
    config: @dev_tools.FpsOverlayConfig::{
      text_config: @text.TextFont::from_font_size(42.0F),
      text_color: overlay_green(),
      refresh_interval: @core.Duration::from_millis(100),
      enabled: true,
      frame_time_graph_config: @dev_tools.FrameTimeGraphConfig::{
        enabled: true,
        min_fps: 30.0F,
        target_fps: 144.0F,
      },
    },
  }

  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_plugin(fn(app) {
    @dev_tools.fps_overlay_plugin_with(app, overlay_plugin)
  })
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(@app.system_param2(customize_config)))
  .run()
}

///|
fn setup(world : @ecs.World) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let tick = world.increment_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_bottom(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@text.ecs_key_text)
  .insert(
    text_entity,
    @text.Text::new(
      "Press 1 to toggle the overlay color.\n" +
      "Press 2 to decrease the overlay size.\n" +
      "Press 3 to increase the overlay size.\n" +
      "Press 4 to toggle the text visibility.\n" +
      "Press 5 to toggle the frame time graph.",
    ),
    tick,
  )
  world
  .component(@text.ecs_key_text_font)
  .insert(text_entity, @text.TextFont::default().with_font_size(20.0F), tick)
  world
  .component(@text.ecs_key_text_color)
  .insert(text_entity, @text.TextColor::new(@sprite.Color::white()), tick)
  world
  .component(@text.ecs_key_text_layout)
  .insert(
    text_entity,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
    tick,
  )
}

///|
fn color_is_green(color : @sprite.Color) -> Bool {
  color.r == overlay_green().r &&
  color.g == overlay_green().g &&
  color.b == overlay_green().b &&
  color.a == overlay_green().a
}

///|
fn customize_config(
  input : @input.ButtonInput[@window.KeyCode],
  overlay : @app.ResMut[@dev_tools.FpsOverlayConfig],
) -> Unit {
  if input.just_pressed(Digit1) {
    if color_is_green(overlay.get_ref().val.text_color) {
      overlay.get_ref().val.text_color = overlay_red()
    } else {
      overlay.get_ref().val.text_color = overlay_green()
    }
  }

  if input.just_pressed(Digit2) {
    let next_size = overlay.get_ref().val.text_config.font_size - 2.0F
    if next_size < 2.0F {
      overlay.get_ref().val.text_config.font_size = 2.0F
    } else {
      overlay.get_ref().val.text_config.font_size = next_size
    }
  }
  if input.just_pressed(Digit3) {
    overlay.get_ref().val.text_config.font_size = overlay.get_ref().val.text_config.font_size +
      2.0F
  }
  if input.just_pressed(Digit4) {
    overlay.get_ref().val.enabled = !overlay.get_ref().val.enabled
  }
  if input.just_released(Digit5) {
    let current = overlay.get_ref().val.frame_time_graph_config.enabled
    overlay.get_ref().val.frame_time_graph_config.enabled = !current
  }
}
