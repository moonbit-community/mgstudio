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
// Bevy source: `bevy/crates/bevy_ui/src/lib.rs`.
fn register_ui_text_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(@text.ecs_key_text, ecs_key_node, fn() {
    Node::default()
  })
  world.register_required_components_with(
    @text.ecs_key_text,
    @text.ecs_key_text_font,
    fn() { @text.TextFont::default() },
  )
  world.register_required_components_with(
    @text.ecs_key_text,
    @text.ecs_key_text_color,
    fn() { @text.TextColor::default() },
  )
  world.register_required_components_with(
    @text.ecs_key_text,
    @text.ecs_key_text_layout,
    fn() { @text.TextLayout::default() },
  )
  world.register_required_components_with(
    @text.ecs_key_text,
    @text.ecs_key_text_line_height,
    fn() { @text.LineHeight::default() },
  )
  world.register_required_components_with(
    @text.ecs_key_text,
    @text.ecs_key_text_font_hinting,
    fn() { @text.FontHinting::default() },
  )
}

///|
fn register_ui_ghost_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_ghost_node,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
}

///|
pub fn ui_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  try! register_ui_text_required_components(app.world())
  try! register_ui_ghost_required_components(app.world())
  app
  .add_component_observer(on_add_disabled)
  .add_component_observer(on_remove_disabled)
  .add_component_observer(on_add_checkable)
  .add_component_observer(on_remove_checkable)
  .add_component_observer(on_add_checked)
  .add_component_observer(on_remove_checked)
  .add_pre_update_system_config(
    @app.system(ui_update_context_system).in_set(ui_set_focus),
  )
  .add_pre_update_system_config(
    @app.system(ui_interaction_system).in_set(ui_set_focus),
  )
  .add_post_update_system_config(
    @app.system(ui_update_context_system).in_set(ui_set_prepare),
  )
  .add_post_update_system_config(
    @app.system(ui_propagate_target_cameras_system).in_set(ui_set_prepare),
  )
  .add_post_update_system_config(
    @app.system(ui_scroll_system).in_set(ui_set_propagate),
  )
  .add_post_update_system_config(
    @app.system(@text.ui_text_sync_ecs_system).in_set(ui_set_text_content),
  )
  .add_post_update_system_config(
    @app.system(ui_image_content_size_system).in_set(ui_set_content),
  )
  .add_post_update_system_config(
    @app.system(ui_layout_system).in_set(ui_set_layout),
  )
  .add_post_update_system_config(
    @app.system(ui_clip_system).in_set(ui_set_post_layout),
  )
  .add_post_update_system_config(
    @app.system(ui_stack_system).in_set(ui_set_stack),
  )
  .add_post_update_system_config(
    @app.system(ui_a11y_update_system).in_set(ui_set_post_layout),
  )
}
