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
/// Legacy ECS component types.
pub let ecs_components : Array[String] = [
  "Node", "Label", "Button", "UiRoot", "UiText", "ZIndex", "Outline", "UiImage",
  "UiLayout", "BoxShadow", "ImageNode", "BorderColor", "ContentSize", "FocusPolicy",
  "Interaction", "UiAntiAlias", "BorderRadius", "ButtonColors", "GlobalZIndex", "ImageNodeSize",
  "CalculatedClip", "ScrollPosition", "BackgroundColor", "AccessibilityLabel", "UiBoxShadowSamples",
  "RelativeCursorPosition",
]

///|
/// Legacy ECS resource types.
pub let ecs_resources : Array[String] = ["UiScale", "UiStack", "UiContext"]

///|
pub(open) trait Has_Node {
  get_node_store(self : Self) -> @core.ComponentStore[Node]
}

///|
pub(open) trait Has_Label {
  get_label_store(self : Self) -> @core.ComponentStore[Label]
}

///|
pub(open) trait Has_Button {
  get_button_store(self : Self) -> @core.ComponentStore[Button]
}

///|
pub(open) trait Has_UiRoot {
  get_ui_root_store(self : Self) -> @core.ComponentStore[UiRoot]
}

///|
pub(open) trait Has_UiText {
  get_ui_text_store(self : Self) -> @core.ComponentStore[UiText]
}

///|
pub(open) trait Has_ZIndex {
  get_z_index_store(self : Self) -> @core.ComponentStore[ZIndex]
}

///|
pub(open) trait Has_Outline {
  get_outline_store(self : Self) -> @core.ComponentStore[Outline]
}

///|
pub(open) trait Has_UiImage {
  get_ui_image_store(self : Self) -> @core.ComponentStore[UiImage]
}

///|
pub(open) trait Has_UiLayout {
  get_ui_layout_store(self : Self) -> @core.ComponentStore[UiLayout]
}

///|
pub(open) trait Has_BoxShadow {
  get_box_shadow_store(self : Self) -> @core.ComponentStore[BoxShadow]
}

///|
pub(open) trait Has_ImageNode {
  get_image_node_store(self : Self) -> @core.ComponentStore[ImageNode]
}

///|
pub(open) trait Has_BorderColor {
  get_border_color_store(self : Self) -> @core.ComponentStore[BorderColor]
}

///|
pub(open) trait Has_ContentSize {
  get_content_size_store(self : Self) -> @core.ComponentStore[ContentSize]
}

///|
pub(open) trait Has_FocusPolicy {
  get_focus_policy_store(self : Self) -> @core.ComponentStore[FocusPolicy]
}

///|
pub(open) trait Has_Interaction {
  get_interaction_store(self : Self) -> @core.ComponentStore[Interaction]
}

///|
pub(open) trait Has_UiAntiAlias {
  get_ui_anti_alias_store(self : Self) -> @core.ComponentStore[UiAntiAlias]
}

///|
pub(open) trait Has_BorderRadius {
  get_border_radius_store(self : Self) -> @core.ComponentStore[BorderRadius]
}

///|
pub(open) trait Has_ButtonColors {
  get_button_colors_store(self : Self) -> @core.ComponentStore[ButtonColors]
}

///|
pub(open) trait Has_GlobalZIndex {
  get_global_z_index_store(self : Self) -> @core.ComponentStore[GlobalZIndex]
}

///|
pub(open) trait Has_ImageNodeSize {
  get_image_node_size_store(self : Self) -> @core.ComponentStore[ImageNodeSize]
}

///|
pub(open) trait Has_CalculatedClip {
  get_calculated_clip_store(self : Self) -> @core.ComponentStore[CalculatedClip]
}

///|
pub(open) trait Has_ScrollPosition {
  get_scroll_position_store(self : Self) -> @core.ComponentStore[ScrollPosition]
}

///|
pub(open) trait Has_BackgroundColor {
  get_background_color_store(self : Self) -> @core.ComponentStore[
    BackgroundColor,
  ]
}

///|
pub(open) trait Has_AccessibilityLabel {
  get_accessibility_label_store(self : Self) -> @core.ComponentStore[
    AccessibilityLabel,
  ]
}

///|
pub(open) trait Has_UiBoxShadowSamples {
  get_ui_box_shadow_samples_store(self : Self) -> @core.ComponentStore[
    UiBoxShadowSamples,
  ]
}

///|
pub(open) trait Has_RelativeCursorPosition {
  get_relative_cursor_position_store(self : Self) -> @core.ComponentStore[
    RelativeCursorPosition,
  ]
}

///|
pub fn[W : Has_Node] query_get_node_store(
  world : W,
) -> @core.ComponentStore[Node] {
  world.get_node_store()
}

///|
pub fn[W : Has_Label] query_get_label_store(
  world : W,
) -> @core.ComponentStore[Label] {
  world.get_label_store()
}

///|
pub fn[W : Has_Button] query_get_button_store(
  world : W,
) -> @core.ComponentStore[Button] {
  world.get_button_store()
}

///|
pub fn[W : Has_UiRoot] query_get_ui_root_store(
  world : W,
) -> @core.ComponentStore[UiRoot] {
  world.get_ui_root_store()
}

///|
pub fn[W : Has_UiText] query_get_ui_text_store(
  world : W,
) -> @core.ComponentStore[UiText] {
  world.get_ui_text_store()
}

///|
pub fn[W : Has_ZIndex] query_get_z_index_store(
  world : W,
) -> @core.ComponentStore[ZIndex] {
  world.get_z_index_store()
}

///|
pub fn[W : Has_Outline] query_get_outline_store(
  world : W,
) -> @core.ComponentStore[Outline] {
  world.get_outline_store()
}

///|
pub fn[W : Has_UiImage] query_get_ui_image_store(
  world : W,
) -> @core.ComponentStore[UiImage] {
  world.get_ui_image_store()
}

///|
pub fn[W : Has_UiLayout] query_get_ui_layout_store(
  world : W,
) -> @core.ComponentStore[UiLayout] {
  world.get_ui_layout_store()
}

///|
pub fn[W : Has_BoxShadow] query_get_box_shadow_store(
  world : W,
) -> @core.ComponentStore[BoxShadow] {
  world.get_box_shadow_store()
}

///|
pub fn[W : Has_ImageNode] query_get_image_node_store(
  world : W,
) -> @core.ComponentStore[ImageNode] {
  world.get_image_node_store()
}

///|
pub fn[W : Has_BorderColor] query_get_border_color_store(
  world : W,
) -> @core.ComponentStore[BorderColor] {
  world.get_border_color_store()
}

///|
pub fn[W : Has_ContentSize] query_get_content_size_store(
  world : W,
) -> @core.ComponentStore[ContentSize] {
  world.get_content_size_store()
}

///|
pub fn[W : Has_FocusPolicy] query_get_focus_policy_store(
  world : W,
) -> @core.ComponentStore[FocusPolicy] {
  world.get_focus_policy_store()
}

///|
pub fn[W : Has_Interaction] query_get_interaction_store(
  world : W,
) -> @core.ComponentStore[Interaction] {
  world.get_interaction_store()
}

///|
pub fn[W : Has_UiAntiAlias] query_get_ui_anti_alias_store(
  world : W,
) -> @core.ComponentStore[UiAntiAlias] {
  world.get_ui_anti_alias_store()
}

///|
pub fn[W : Has_BorderRadius] query_get_border_radius_store(
  world : W,
) -> @core.ComponentStore[BorderRadius] {
  world.get_border_radius_store()
}

///|
pub fn[W : Has_ButtonColors] query_get_button_colors_store(
  world : W,
) -> @core.ComponentStore[ButtonColors] {
  world.get_button_colors_store()
}

///|
pub fn[W : Has_GlobalZIndex] query_get_global_z_index_store(
  world : W,
) -> @core.ComponentStore[GlobalZIndex] {
  world.get_global_z_index_store()
}

///|
pub fn[W : Has_ImageNodeSize] query_get_image_node_size_store(
  world : W,
) -> @core.ComponentStore[ImageNodeSize] {
  world.get_image_node_size_store()
}

///|
pub fn[W : Has_CalculatedClip] query_get_calculated_clip_store(
  world : W,
) -> @core.ComponentStore[CalculatedClip] {
  world.get_calculated_clip_store()
}

///|
pub fn[W : Has_ScrollPosition] query_get_scroll_position_store(
  world : W,
) -> @core.ComponentStore[ScrollPosition] {
  world.get_scroll_position_store()
}

///|
pub fn[W : Has_BackgroundColor] query_get_background_color_store(
  world : W,
) -> @core.ComponentStore[BackgroundColor] {
  world.get_background_color_store()
}

///|
pub fn[W : Has_AccessibilityLabel] query_get_accessibility_label_store(
  world : W,
) -> @core.ComponentStore[AccessibilityLabel] {
  world.get_accessibility_label_store()
}

///|
pub fn[W : Has_UiBoxShadowSamples] query_get_ui_box_shadow_samples_store(
  world : W,
) -> @core.ComponentStore[UiBoxShadowSamples] {
  world.get_ui_box_shadow_samples_store()
}

///|
pub fn[W : Has_RelativeCursorPosition] query_get_relative_cursor_position_store(
  world : W,
) -> @core.ComponentStore[RelativeCursorPosition] {
  world.get_relative_cursor_position_store()
}

///|
pub(open) trait HasRes_UiScale {
  get_ui_scale_resource(self : Self) -> @core.Resource[UiScale]
}

///|
pub(open) trait HasRes_UiStack {
  get_ui_stack_resource(self : Self) -> @core.Resource[UiStack]
}

///|
pub(open) trait HasRes_UiContext {
  get_ui_context_resource(self : Self) -> @core.Resource[UiContext]
}

///|
pub fn[W : HasRes_UiScale] query_get_ui_scale_resource(
  world : W,
) -> @core.Resource[UiScale] {
  world.get_ui_scale_resource()
}

///|
pub fn[W : HasRes_UiStack] query_get_ui_stack_resource(
  world : W,
) -> @core.Resource[UiStack] {
  world.get_ui_stack_resource()
}

///|
pub fn[W : HasRes_UiContext] query_get_ui_context_resource(
  world : W,
) -> @core.Resource[UiContext] {
  world.get_ui_context_resource()
}

///|
/// ECS bridge impls for @ecs.World (auto-generated).

///|
let bridge_get_node_store_by_world : Map[Int, @core.ComponentStore[Node]] = {}

///|
pub impl Has_Node for @ecs.World with get_node_store(self) {
  bridge_get_node_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_label_store_by_world : Map[Int, @core.ComponentStore[Label]] = {}

///|
pub impl Has_Label for @ecs.World with get_label_store(self) {
  bridge_get_label_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_button_store_by_world : Map[Int, @core.ComponentStore[Button]] = {}

///|
pub impl Has_Button for @ecs.World with get_button_store(self) {
  bridge_get_button_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_ui_root_store_by_world : Map[Int, @core.ComponentStore[UiRoot]] = {}

///|
pub impl Has_UiRoot for @ecs.World with get_ui_root_store(self) {
  bridge_get_ui_root_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_ui_text_store_by_world : Map[Int, @core.ComponentStore[UiText]] = {}

///|
pub impl Has_UiText for @ecs.World with get_ui_text_store(self) {
  bridge_get_ui_text_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_z_index_store_by_world : Map[Int, @core.ComponentStore[ZIndex]] = {}

///|
pub impl Has_ZIndex for @ecs.World with get_z_index_store(self) {
  bridge_get_z_index_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_outline_store_by_world : Map[Int, @core.ComponentStore[Outline]] = {}

///|
pub impl Has_Outline for @ecs.World with get_outline_store(self) {
  bridge_get_outline_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_ui_image_store_by_world : Map[Int, @core.ComponentStore[UiImage]] = {}

///|
pub impl Has_UiImage for @ecs.World with get_ui_image_store(self) {
  bridge_get_ui_image_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_ui_layout_store_by_world : Map[
  Int,
  @core.ComponentStore[UiLayout],
] = {}

///|
pub impl Has_UiLayout for @ecs.World with get_ui_layout_store(self) {
  bridge_get_ui_layout_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_box_shadow_store_by_world : Map[
  Int,
  @core.ComponentStore[BoxShadow],
] = {}

///|
pub impl Has_BoxShadow for @ecs.World with get_box_shadow_store(self) {
  bridge_get_box_shadow_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_image_node_store_by_world : Map[
  Int,
  @core.ComponentStore[ImageNode],
] = {}

///|
pub impl Has_ImageNode for @ecs.World with get_image_node_store(self) {
  bridge_get_image_node_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_border_color_store_by_world : Map[
  Int,
  @core.ComponentStore[BorderColor],
] = {}

///|
pub impl Has_BorderColor for @ecs.World with get_border_color_store(self) {
  bridge_get_border_color_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_content_size_store_by_world : Map[
  Int,
  @core.ComponentStore[ContentSize],
] = {}

///|
pub impl Has_ContentSize for @ecs.World with get_content_size_store(self) {
  bridge_get_content_size_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_focus_policy_store_by_world : Map[
  Int,
  @core.ComponentStore[FocusPolicy],
] = {}

///|
pub impl Has_FocusPolicy for @ecs.World with get_focus_policy_store(self) {
  bridge_get_focus_policy_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_interaction_store_by_world : Map[
  Int,
  @core.ComponentStore[Interaction],
] = {}

///|
pub impl Has_Interaction for @ecs.World with get_interaction_store(self) {
  bridge_get_interaction_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_ui_anti_alias_store_by_world : Map[
  Int,
  @core.ComponentStore[UiAntiAlias],
] = {}

///|
pub impl Has_UiAntiAlias for @ecs.World with get_ui_anti_alias_store(self) {
  bridge_get_ui_anti_alias_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_border_radius_store_by_world : Map[
  Int,
  @core.ComponentStore[BorderRadius],
] = {}

///|
pub impl Has_BorderRadius for @ecs.World with get_border_radius_store(self) {
  bridge_get_border_radius_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_button_colors_store_by_world : Map[
  Int,
  @core.ComponentStore[ButtonColors],
] = {}

///|
pub impl Has_ButtonColors for @ecs.World with get_button_colors_store(self) {
  bridge_get_button_colors_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_global_z_index_store_by_world : Map[
  Int,
  @core.ComponentStore[GlobalZIndex],
] = {}

///|
pub impl Has_GlobalZIndex for @ecs.World with get_global_z_index_store(self) {
  bridge_get_global_z_index_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_image_node_size_store_by_world : Map[
  Int,
  @core.ComponentStore[ImageNodeSize],
] = {}

///|
pub impl Has_ImageNodeSize for @ecs.World with get_image_node_size_store(self) {
  bridge_get_image_node_size_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_calculated_clip_store_by_world : Map[
  Int,
  @core.ComponentStore[CalculatedClip],
] = {}

///|
pub impl Has_CalculatedClip for @ecs.World with get_calculated_clip_store(self) {
  bridge_get_calculated_clip_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_scroll_position_store_by_world : Map[
  Int,
  @core.ComponentStore[ScrollPosition],
] = {}

///|
pub impl Has_ScrollPosition for @ecs.World with get_scroll_position_store(self) {
  bridge_get_scroll_position_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_background_color_store_by_world : Map[
  Int,
  @core.ComponentStore[BackgroundColor],
] = {}

///|
pub impl Has_BackgroundColor for @ecs.World with get_background_color_store(
  self,
) {
  bridge_get_background_color_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_accessibility_label_store_by_world : Map[
  Int,
  @core.ComponentStore[AccessibilityLabel],
] = {}

///|
pub impl Has_AccessibilityLabel for @ecs.World with get_accessibility_label_store(
  self,
) {
  bridge_get_accessibility_label_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_ui_box_shadow_samples_store_by_world : Map[
  Int,
  @core.ComponentStore[UiBoxShadowSamples],
] = {}

///|
pub impl Has_UiBoxShadowSamples for @ecs.World with get_ui_box_shadow_samples_store(
  self,
) {
  bridge_get_ui_box_shadow_samples_store_by_world.get_or_init(self.world_id(), fn() {
    @core.ComponentStore::new()
  })
}

///|
let bridge_get_relative_cursor_position_store_by_world : Map[
  Int,
  @core.ComponentStore[RelativeCursorPosition],
] = {}

///|
pub impl Has_RelativeCursorPosition for @ecs.World with get_relative_cursor_position_store(
  self,
) {
  bridge_get_relative_cursor_position_store_by_world.get_or_init(
    self.world_id(),
    fn() { @core.ComponentStore::new() },
  )
}

///|
let bridge_get_ui_scale_resource_by_world : Map[Int, @core.Resource[UiScale]] = {}

///|
pub impl HasRes_UiScale for @ecs.World with get_ui_scale_resource(self) {
  bridge_get_ui_scale_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_ui_stack_resource_by_world : Map[Int, @core.Resource[UiStack]] = {}

///|
pub impl HasRes_UiStack for @ecs.World with get_ui_stack_resource(self) {
  bridge_get_ui_stack_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
let bridge_get_ui_context_resource_by_world : Map[
  Int,
  @core.Resource[UiContext],
] = {}

///|
pub impl HasRes_UiContext for @ecs.World with get_ui_context_resource(self) {
  bridge_get_ui_context_resource_by_world.get_or_init(self.world_id(), fn() {
    @core.Resource::new()
  })
}

///|
/// End ECS bridge impls.
