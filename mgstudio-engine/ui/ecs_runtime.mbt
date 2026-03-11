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
pub let ecs_key_node : @ecs.ComponentKey[Node] = @ecs.register_component(
  debug_name="ui.node",
)

///|
pub let ecs_key_label : @ecs.ComponentKey[Label] = @ecs.register_component(
  debug_name="ui.label",
)

///|
pub let ecs_key_button : @ecs.ComponentKey[Button] = @ecs.register_component(
  debug_name="ui.button",
)

///|
pub let ecs_key_ui_root : @ecs.ComponentKey[UiRoot] = @ecs.register_component(
  debug_name="ui.ui_root",
)

///|
pub let ecs_key_is_default_ui_camera : @ecs.ComponentKey[IsDefaultUiCamera] = @ecs.register_component(
  debug_name="ui.is_default_ui_camera",
)

///|
pub let ecs_key_ui_target_camera : @ecs.ComponentKey[UiTargetCamera] = @ecs.register_component(
  debug_name="ui.ui_target_camera",
)

///|
pub let ecs_key_computed_ui_target_camera : @ecs.ComponentKey[
  ComputedUiTargetCamera,
] = @ecs.register_component(debug_name="ui.computed_ui_target_camera")

///|
pub let ecs_key_computed_ui_render_target_info : @ecs.ComponentKey[
  ComputedUiRenderTargetInfo,
] = @ecs.register_component(debug_name="ui.computed_ui_render_target_info")

///|
pub let ecs_key_ui_text : @ecs.ComponentKey[UiText] = @ecs.register_component(
  debug_name="ui.ui_text",
)

///|
pub let ecs_key_z_index : @ecs.ComponentKey[ZIndex] = @ecs.register_component(
  debug_name="ui.z_index",
)

///|
pub let ecs_key_outline : @ecs.ComponentKey[Outline] = @ecs.register_component(
  debug_name="ui.outline",
)

///|
pub let ecs_key_ui_image : @ecs.ComponentKey[UiImage] = @ecs.register_component(
  debug_name="ui.ui_image",
)

///|
pub let ecs_key_ui_layout : @ecs.ComponentKey[UiLayout] = @ecs.register_component(
  debug_name="ui.ui_layout",
)

///|
pub let ecs_key_box_shadow : @ecs.ComponentKey[BoxShadow] = @ecs.register_component(
  debug_name="ui.box_shadow",
)

///|
pub let ecs_key_image_node : @ecs.ComponentKey[ImageNode] = @ecs.register_component(
  debug_name="ui.image_node",
)

///|
pub let ecs_key_border_color : @ecs.ComponentKey[BorderColor] = @ecs.register_component(
  debug_name="ui.border_color",
)

///|
pub let ecs_key_content_size : @ecs.ComponentKey[ContentSize] = @ecs.register_component(
  debug_name="ui.content_size",
)

///|
pub let ecs_key_focus_policy : @ecs.ComponentKey[FocusPolicy] = @ecs.register_component(
  debug_name="ui.focus_policy",
)

///|
pub let ecs_key_interaction : @ecs.ComponentKey[Interaction] = @ecs.register_component(
  debug_name="ui.interaction",
)

///|
pub let ecs_key_border_radius : @ecs.ComponentKey[BorderRadius] = @ecs.register_component(
  debug_name="ui.border_radius",
)

///|
pub let ecs_key_button_colors : @ecs.ComponentKey[ButtonColors] = @ecs.register_component(
  debug_name="ui.button_colors",
)

///|
pub let ecs_key_global_z_index : @ecs.ComponentKey[GlobalZIndex] = @ecs.register_component(
  debug_name="ui.global_z_index",
)

///|
pub let ecs_key_image_node_size : @ecs.ComponentKey[ImageNodeSize] = @ecs.register_component(
  debug_name="ui.image_node_size",
)

///|
pub let ecs_key_calculated_clip : @ecs.ComponentKey[CalculatedClip] = @ecs.register_component(
  debug_name="ui.calculated_clip",
)

///|
pub let ecs_key_scroll_position : @ecs.ComponentKey[ScrollPosition] = @ecs.register_component(
  debug_name="ui.scroll_position",
)

///|
pub let ecs_key_background_color : @ecs.ComponentKey[BackgroundColor] = @ecs.register_component(
  debug_name="ui.background_color",
)

///|
pub let ecs_key_accessibility_label : @ecs.ComponentKey[AccessibilityLabel] = @ecs.register_component(
  debug_name="ui.accessibility_label",
)

///|
pub let ecs_key_relative_cursor_position : @ecs.ComponentKey[
  RelativeCursorPosition,
] = @ecs.register_component(debug_name="ui.relative_cursor_position")

///|
pub impl @ecs.Component for Node with component() {
  ecs_key_node
}

///|
pub impl @ecs.Component for Label with component() {
  ecs_key_label
}

///|
pub impl @ecs.Component for Button with component() {
  ecs_key_button
}

///|
pub impl @ecs.Component for UiRoot with component() {
  ecs_key_ui_root
}

///|
pub impl @ecs.Component for IsDefaultUiCamera with component() {
  ecs_key_is_default_ui_camera
}

///|
pub impl @ecs.Component for UiTargetCamera with component() {
  ecs_key_ui_target_camera
}

///|
pub impl @ecs.Component for ComputedUiTargetCamera with component() {
  ecs_key_computed_ui_target_camera
}

///|
pub impl @ecs.Component for ComputedUiRenderTargetInfo with component() {
  ecs_key_computed_ui_render_target_info
}

///|
pub impl @ecs.Component for UiText with component() {
  ecs_key_ui_text
}

///|
pub impl @ecs.Component for ZIndex with component() {
  ecs_key_z_index
}

///|
pub impl @ecs.Component for Outline with component() {
  ecs_key_outline
}

///|
pub impl @ecs.Component for UiImage with component() {
  ecs_key_ui_image
}

///|
pub impl @ecs.Component for UiLayout with component() {
  ecs_key_ui_layout
}

///|
pub impl @ecs.Component for BoxShadow with component() {
  ecs_key_box_shadow
}

///|
pub impl @ecs.Component for ImageNode with component() {
  ecs_key_image_node
}

///|
pub impl @ecs.Component for BorderColor with component() {
  ecs_key_border_color
}

///|
pub impl @ecs.Component for ContentSize with component() {
  ecs_key_content_size
}

///|
pub impl @ecs.Component for FocusPolicy with component() {
  ecs_key_focus_policy
}

///|
pub impl @ecs.Component for Interaction with component() {
  ecs_key_interaction
}

///|
pub impl @ecs.Component for BorderRadius with component() {
  ecs_key_border_radius
}

///|
pub impl @ecs.Component for ButtonColors with component() {
  ecs_key_button_colors
}

///|
pub impl @ecs.Component for GlobalZIndex with component() {
  ecs_key_global_z_index
}

///|
pub impl @ecs.Component for ImageNodeSize with component() {
  ecs_key_image_node_size
}

///|
pub impl @ecs.Component for CalculatedClip with component() {
  ecs_key_calculated_clip
}

///|
pub impl @ecs.Component for ScrollPosition with component() {
  ecs_key_scroll_position
}

///|
pub impl @ecs.Component for BackgroundColor with component() {
  ecs_key_background_color
}

///|
pub impl @ecs.Component for AccessibilityLabel with component() {
  ecs_key_accessibility_label
}

///|
pub impl @ecs.Component for RelativeCursorPosition with component() {
  ecs_key_relative_cursor_position
}

///|
pub let ecs_key_ui_scale : @ecs.ResourceKey[UiScale] = @ecs.register_resource(
  debug_name="ui.ui_scale",
)

///|
pub let ecs_key_ui_stack : @ecs.ResourceKey[UiStack] = @ecs.register_resource(
  debug_name="ui.ui_stack",
)

///|
pub let ecs_key_ui_context : @ecs.ResourceKey[UiContext] = @ecs.register_resource(
  debug_name="ui.ui_context",
)
