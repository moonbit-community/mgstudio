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
  "Node", "Label", "Button", "UiRoot", "UiText", "ZIndex", "Outline", "UiImage",
  "UiLayout", "BoxShadow", "ImageNode", "BorderColor", "ContentSize", "FocusPolicy",
  "Interaction", "UiAntiAlias", "BorderRadius", "ButtonColors", "GlobalZIndex", "ImageNodeSize",
  "CalculatedClip", "ScrollPosition", "BackgroundColor", "AccessibilityLabel", "UiBoxShadowSamples",
  "RelativeCursorPosition",
]

///|
/// ECS resource bridge types.
pub let ecs_resources : Array[String] = ["UiScale", "UiStack", "UiContext"]

///|
pub(open) trait Has_Node {
  get_node_store(self : Self) -> @ecs.ComponentAccess[Node]
}

///|
pub(open) trait Has_Label {
  get_label_store(self : Self) -> @ecs.ComponentAccess[Label]
}

///|
pub(open) trait Has_Button {
  get_button_store(self : Self) -> @ecs.ComponentAccess[Button]
}

///|
pub(open) trait Has_UiRoot {
  get_ui_root_store(self : Self) -> @ecs.ComponentAccess[UiRoot]
}

///|
pub(open) trait Has_UiText {
  get_ui_text_store(self : Self) -> @ecs.ComponentAccess[UiText]
}

///|
pub(open) trait Has_ZIndex {
  get_z_index_store(self : Self) -> @ecs.ComponentAccess[ZIndex]
}

///|
pub(open) trait Has_Outline {
  get_outline_store(self : Self) -> @ecs.ComponentAccess[Outline]
}

///|
pub(open) trait Has_UiImage {
  get_ui_image_store(self : Self) -> @ecs.ComponentAccess[UiImage]
}

///|
pub(open) trait Has_UiLayout {
  get_ui_layout_store(self : Self) -> @ecs.ComponentAccess[UiLayout]
}

///|
pub(open) trait Has_BoxShadow {
  get_box_shadow_store(self : Self) -> @ecs.ComponentAccess[BoxShadow]
}

///|
pub(open) trait Has_ImageNode {
  get_image_node_store(self : Self) -> @ecs.ComponentAccess[ImageNode]
}

///|
pub(open) trait Has_BorderColor {
  get_border_color_store(self : Self) -> @ecs.ComponentAccess[BorderColor]
}

///|
pub(open) trait Has_ContentSize {
  get_content_size_store(self : Self) -> @ecs.ComponentAccess[ContentSize]
}

///|
pub(open) trait Has_FocusPolicy {
  get_focus_policy_store(self : Self) -> @ecs.ComponentAccess[FocusPolicy]
}

///|
pub(open) trait Has_Interaction {
  get_interaction_store(self : Self) -> @ecs.ComponentAccess[Interaction]
}

///|
pub(open) trait Has_UiAntiAlias {
  get_ui_anti_alias_store(self : Self) -> @ecs.ComponentAccess[UiAntiAlias]
}

///|
pub(open) trait Has_BorderRadius {
  get_border_radius_store(self : Self) -> @ecs.ComponentAccess[BorderRadius]
}

///|
pub(open) trait Has_ButtonColors {
  get_button_colors_store(self : Self) -> @ecs.ComponentAccess[ButtonColors]
}

///|
pub(open) trait Has_GlobalZIndex {
  get_global_z_index_store(self : Self) -> @ecs.ComponentAccess[GlobalZIndex]
}

///|
pub(open) trait Has_ImageNodeSize {
  get_image_node_size_store(self : Self) -> @ecs.ComponentAccess[ImageNodeSize]
}

///|
pub(open) trait Has_CalculatedClip {
  get_calculated_clip_store(self : Self) -> @ecs.ComponentAccess[CalculatedClip]
}

///|
pub(open) trait Has_ScrollPosition {
  get_scroll_position_store(self : Self) -> @ecs.ComponentAccess[ScrollPosition]
}

///|
pub(open) trait Has_BackgroundColor {
  get_background_color_store(self : Self) -> @ecs.ComponentAccess[
    BackgroundColor,
  ]
}

///|
pub(open) trait Has_AccessibilityLabel {
  get_accessibility_label_store(self : Self) -> @ecs.ComponentAccess[
    AccessibilityLabel,
  ]
}

///|
pub(open) trait Has_UiBoxShadowSamples {
  get_ui_box_shadow_samples_store(self : Self) -> @ecs.ComponentAccess[
    UiBoxShadowSamples,
  ]
}

///|
pub(open) trait Has_RelativeCursorPosition {
  get_relative_cursor_position_store(self : Self) -> @ecs.ComponentAccess[
    RelativeCursorPosition,
  ]
}

///|
pub fn[W : Has_Node] get_node_store(world : W) -> @ecs.ComponentAccess[Node] {
  world.get_node_store()
}

///|
pub fn[W : Has_Label] get_label_store(world : W) -> @ecs.ComponentAccess[Label] {
  world.get_label_store()
}

///|
pub fn[W : Has_Button] get_button_store(
  world : W,
) -> @ecs.ComponentAccess[Button] {
  world.get_button_store()
}

///|
pub fn[W : Has_UiRoot] get_ui_root_store(
  world : W,
) -> @ecs.ComponentAccess[UiRoot] {
  world.get_ui_root_store()
}

///|
pub fn[W : Has_UiText] get_ui_text_store(
  world : W,
) -> @ecs.ComponentAccess[UiText] {
  world.get_ui_text_store()
}

///|
pub fn[W : Has_ZIndex] get_z_index_store(
  world : W,
) -> @ecs.ComponentAccess[ZIndex] {
  world.get_z_index_store()
}

///|
pub fn[W : Has_Outline] get_outline_store(
  world : W,
) -> @ecs.ComponentAccess[Outline] {
  world.get_outline_store()
}

///|
pub fn[W : Has_UiImage] get_ui_image_store(
  world : W,
) -> @ecs.ComponentAccess[UiImage] {
  world.get_ui_image_store()
}

///|
pub fn[W : Has_UiLayout] get_ui_layout_store(
  world : W,
) -> @ecs.ComponentAccess[UiLayout] {
  world.get_ui_layout_store()
}

///|
pub fn[W : Has_BoxShadow] get_box_shadow_store(
  world : W,
) -> @ecs.ComponentAccess[BoxShadow] {
  world.get_box_shadow_store()
}

///|
pub fn[W : Has_ImageNode] get_image_node_store(
  world : W,
) -> @ecs.ComponentAccess[ImageNode] {
  world.get_image_node_store()
}

///|
pub fn[W : Has_BorderColor] get_border_color_store(
  world : W,
) -> @ecs.ComponentAccess[BorderColor] {
  world.get_border_color_store()
}

///|
pub fn[W : Has_ContentSize] get_content_size_store(
  world : W,
) -> @ecs.ComponentAccess[ContentSize] {
  world.get_content_size_store()
}

///|
pub fn[W : Has_FocusPolicy] get_focus_policy_store(
  world : W,
) -> @ecs.ComponentAccess[FocusPolicy] {
  world.get_focus_policy_store()
}

///|
pub fn[W : Has_Interaction] get_interaction_store(
  world : W,
) -> @ecs.ComponentAccess[Interaction] {
  world.get_interaction_store()
}

///|
pub fn[W : Has_UiAntiAlias] get_ui_anti_alias_store(
  world : W,
) -> @ecs.ComponentAccess[UiAntiAlias] {
  world.get_ui_anti_alias_store()
}

///|
pub fn[W : Has_BorderRadius] get_border_radius_store(
  world : W,
) -> @ecs.ComponentAccess[BorderRadius] {
  world.get_border_radius_store()
}

///|
pub fn[W : Has_ButtonColors] get_button_colors_store(
  world : W,
) -> @ecs.ComponentAccess[ButtonColors] {
  world.get_button_colors_store()
}

///|
pub fn[W : Has_GlobalZIndex] get_global_z_index_store(
  world : W,
) -> @ecs.ComponentAccess[GlobalZIndex] {
  world.get_global_z_index_store()
}

///|
pub fn[W : Has_ImageNodeSize] get_image_node_size_store(
  world : W,
) -> @ecs.ComponentAccess[ImageNodeSize] {
  world.get_image_node_size_store()
}

///|
pub fn[W : Has_CalculatedClip] get_calculated_clip_store(
  world : W,
) -> @ecs.ComponentAccess[CalculatedClip] {
  world.get_calculated_clip_store()
}

///|
pub fn[W : Has_ScrollPosition] get_scroll_position_store(
  world : W,
) -> @ecs.ComponentAccess[ScrollPosition] {
  world.get_scroll_position_store()
}

///|
pub fn[W : Has_BackgroundColor] get_background_color_store(
  world : W,
) -> @ecs.ComponentAccess[BackgroundColor] {
  world.get_background_color_store()
}

///|
pub fn[W : Has_AccessibilityLabel] get_accessibility_label_store(
  world : W,
) -> @ecs.ComponentAccess[AccessibilityLabel] {
  world.get_accessibility_label_store()
}

///|
pub fn[W : Has_UiBoxShadowSamples] get_ui_box_shadow_samples_store(
  world : W,
) -> @ecs.ComponentAccess[UiBoxShadowSamples] {
  world.get_ui_box_shadow_samples_store()
}

///|
pub fn[W : Has_RelativeCursorPosition] get_relative_cursor_position_store(
  world : W,
) -> @ecs.ComponentAccess[RelativeCursorPosition] {
  world.get_relative_cursor_position_store()
}

///|
pub(open) trait HasRes_UiScale {
  get_ui_scale_resource(self : Self) -> @ecs.ResourceAccess[UiScale]
}

///|
pub(open) trait HasRes_UiStack {
  get_ui_stack_resource(self : Self) -> @ecs.ResourceAccess[UiStack]
}

///|
pub(open) trait HasRes_UiContext {
  get_ui_context_resource(self : Self) -> @ecs.ResourceAccess[UiContext]
}

///|
pub fn[W : HasRes_UiScale] get_ui_scale_resource(
  world : W,
) -> @ecs.ResourceAccess[UiScale] {
  world.get_ui_scale_resource()
}

///|
pub fn[W : HasRes_UiStack] get_ui_stack_resource(
  world : W,
) -> @ecs.ResourceAccess[UiStack] {
  world.get_ui_stack_resource()
}

///|
pub fn[W : HasRes_UiContext] get_ui_context_resource(
  world : W,
) -> @ecs.ResourceAccess[UiContext] {
  world.get_ui_context_resource()
}

///|
/// ECS bridge impls for @ecs.World.

///|
pub impl Has_Node for @ecs.World with get_node_store(self) {
  self.component(ecs_key_node)
}

///|
pub impl Has_Label for @ecs.World with get_label_store(self) {
  self.component(ecs_key_label)
}

///|
pub impl Has_Button for @ecs.World with get_button_store(self) {
  self.component(ecs_key_button)
}

///|
pub impl Has_UiRoot for @ecs.World with get_ui_root_store(self) {
  self.component(ecs_key_ui_root)
}

///|
pub impl Has_UiText for @ecs.World with get_ui_text_store(self) {
  self.component(ecs_key_ui_text)
}

///|
pub impl Has_ZIndex for @ecs.World with get_z_index_store(self) {
  self.component(ecs_key_z_index)
}

///|
pub impl Has_Outline for @ecs.World with get_outline_store(self) {
  self.component(ecs_key_outline)
}

///|
pub impl Has_UiImage for @ecs.World with get_ui_image_store(self) {
  self.component(ecs_key_ui_image)
}

///|
pub impl Has_UiLayout for @ecs.World with get_ui_layout_store(self) {
  self.component(ecs_key_ui_layout)
}

///|
pub impl Has_BoxShadow for @ecs.World with get_box_shadow_store(self) {
  self.component(ecs_key_box_shadow)
}

///|
pub impl Has_ImageNode for @ecs.World with get_image_node_store(self) {
  self.component(ecs_key_image_node)
}

///|
pub impl Has_BorderColor for @ecs.World with get_border_color_store(self) {
  self.component(ecs_key_border_color)
}

///|
pub impl Has_ContentSize for @ecs.World with get_content_size_store(self) {
  self.component(ecs_key_content_size)
}

///|
pub impl Has_FocusPolicy for @ecs.World with get_focus_policy_store(self) {
  self.component(ecs_key_focus_policy)
}

///|
pub impl Has_Interaction for @ecs.World with get_interaction_store(self) {
  self.component(ecs_key_interaction)
}

///|
pub impl Has_UiAntiAlias for @ecs.World with get_ui_anti_alias_store(self) {
  self.component(ecs_key_ui_anti_alias)
}

///|
pub impl Has_BorderRadius for @ecs.World with get_border_radius_store(self) {
  self.component(ecs_key_border_radius)
}

///|
pub impl Has_ButtonColors for @ecs.World with get_button_colors_store(self) {
  self.component(ecs_key_button_colors)
}

///|
pub impl Has_GlobalZIndex for @ecs.World with get_global_z_index_store(self) {
  self.component(ecs_key_global_z_index)
}

///|
pub impl Has_ImageNodeSize for @ecs.World with get_image_node_size_store(self) {
  self.component(ecs_key_image_node_size)
}

///|
pub impl Has_CalculatedClip for @ecs.World with get_calculated_clip_store(self) {
  self.component(ecs_key_calculated_clip)
}

///|
pub impl Has_ScrollPosition for @ecs.World with get_scroll_position_store(self) {
  self.component(ecs_key_scroll_position)
}

///|
pub impl Has_BackgroundColor for @ecs.World with get_background_color_store(
  self,
) {
  self.component(ecs_key_background_color)
}

///|
pub impl Has_AccessibilityLabel for @ecs.World with get_accessibility_label_store(
  self,
) {
  self.component(ecs_key_accessibility_label)
}

///|
pub impl Has_UiBoxShadowSamples for @ecs.World with get_ui_box_shadow_samples_store(
  self,
) {
  self.component(ecs_key_ui_box_shadow_samples)
}

///|
pub impl Has_RelativeCursorPosition for @ecs.World with get_relative_cursor_position_store(
  self,
) {
  self.component(ecs_key_relative_cursor_position)
}

///|
pub impl HasRes_UiScale for @ecs.World with get_ui_scale_resource(self) {
  self.resource(ecs_key_ui_scale)
}

///|
pub impl HasRes_UiStack for @ecs.World with get_ui_stack_resource(self) {
  self.resource(ecs_key_ui_stack)
}

///|
pub impl HasRes_UiContext for @ecs.World with get_ui_context_resource(self) {
  self.resource(ecs_key_ui_context)
}

///|
/// End ECS bridge impls.
