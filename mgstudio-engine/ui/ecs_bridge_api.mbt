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
/// ECS component bridge types.
pub let ecs_components : Array[String] = [
  "Node", "Label", "Button", "UiRoot", "IsDefaultUiCamera", "UiText", "ZIndex", "Outline",
  "UiImage", "UiLayout", "BoxShadow", "ImageNode", "BorderColor", "ContentSize",
  "FocusPolicy", "Interaction", "UiAntiAlias", "BorderRadius", "ButtonColors", "GlobalZIndex",
  "ImageNodeSize", "CalculatedClip", "ScrollPosition", "BackgroundColor", "AccessibilityLabel",
  "UiBoxShadowSamples", "RelativeCursorPosition",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = ["UiScale", "UiStack", "UiContext"]

///|
pub fn get_node_store(world : @ecs.World) -> @ecs.ComponentAccess[Node] {
  world.component(ecs_key_node)
}

///|
pub fn get_label_store(world : @ecs.World) -> @ecs.ComponentAccess[Label] {
  world.component(ecs_key_label)
}

///|
pub fn get_button_store(world : @ecs.World) -> @ecs.ComponentAccess[Button] {
  world.component(ecs_key_button)
}

///|
pub fn get_ui_root_store(world : @ecs.World) -> @ecs.ComponentAccess[UiRoot] {
  world.component(ecs_key_ui_root)
}

///|
pub fn get_is_default_ui_camera_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[IsDefaultUiCamera] {
  world.component(ecs_key_is_default_ui_camera)
}

///|
pub fn get_ui_text_store(world : @ecs.World) -> @ecs.ComponentAccess[UiText] {
  world.component(ecs_key_ui_text)
}

///|
pub fn get_z_index_store(world : @ecs.World) -> @ecs.ComponentAccess[ZIndex] {
  world.component(ecs_key_z_index)
}

///|
pub fn get_outline_store(world : @ecs.World) -> @ecs.ComponentAccess[Outline] {
  world.component(ecs_key_outline)
}

///|
pub fn get_ui_image_store(world : @ecs.World) -> @ecs.ComponentAccess[UiImage] {
  world.component(ecs_key_ui_image)
}

///|
pub fn get_ui_layout_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[UiLayout] {
  world.component(ecs_key_ui_layout)
}

///|
pub fn get_box_shadow_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[BoxShadow] {
  world.component(ecs_key_box_shadow)
}

///|
pub fn get_image_node_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ImageNode] {
  world.component(ecs_key_image_node)
}

///|
pub fn get_border_color_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[BorderColor] {
  world.component(ecs_key_border_color)
}

///|
pub fn get_content_size_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ContentSize] {
  world.component(ecs_key_content_size)
}

///|
pub fn get_focus_policy_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[FocusPolicy] {
  world.component(ecs_key_focus_policy)
}

///|
pub fn get_interaction_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[Interaction] {
  world.component(ecs_key_interaction)
}

///|
pub fn get_ui_anti_alias_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[UiAntiAlias] {
  world.component(ecs_key_ui_anti_alias)
}

///|
pub fn get_border_radius_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[BorderRadius] {
  world.component(ecs_key_border_radius)
}

///|
pub fn get_button_colors_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ButtonColors] {
  world.component(ecs_key_button_colors)
}

///|
pub fn get_global_z_index_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[GlobalZIndex] {
  world.component(ecs_key_global_z_index)
}

///|
pub fn get_image_node_size_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ImageNodeSize] {
  world.component(ecs_key_image_node_size)
}

///|
pub fn get_calculated_clip_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[CalculatedClip] {
  world.component(ecs_key_calculated_clip)
}

///|
pub fn get_scroll_position_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ScrollPosition] {
  world.component(ecs_key_scroll_position)
}

///|
pub fn get_background_color_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[BackgroundColor] {
  world.component(ecs_key_background_color)
}

///|
pub fn get_accessibility_label_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[AccessibilityLabel] {
  world.component(ecs_key_accessibility_label)
}

///|
pub fn get_ui_box_shadow_samples_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[UiBoxShadowSamples] {
  world.component(ecs_key_ui_box_shadow_samples)
}

///|
pub fn get_relative_cursor_position_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[RelativeCursorPosition] {
  world.component(ecs_key_relative_cursor_position)
}

///|
pub fn get_ui_scale_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[UiScale] {
  world.resource(ecs_key_ui_scale)
}

///|
pub fn get_ui_stack_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[UiStack] {
  world.resource(ecs_key_ui_stack)
}

///|
pub fn get_ui_context_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[UiContext] {
  world.resource(ecs_key_ui_context)
}
