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
// Bevy source: `bevy/crates/bevy_sprite/src/text2d.rs`.
//
// The 2d text data model. The text pipeline proper stays in `text`, which is
// the `bevy_text` owner; `bevy_sprite` depends on `bevy_text`, never the
// reverse (ISS-480). The layout systems and render extraction move here in
// later phases.

///|
pub(all) struct Text2d {
  mut content : String
}

///|
pub fn Text2d::Text2d() -> Text2d {
  Text2d::new("")
}

///|
pub fn Text2d::new(content : String) -> Text2d {
  { content, }
}

///|
pub let ecs_key_text2d : @ecs.ComponentKey[Text2d] = @ecs.register_component(
  debug_name="text.text2d",
)

///|
pub impl @ecs.Component for Text2d with fn component() {
  ecs_key_text2d
}

///|
pub(all) struct Text2dShadow {
  mut offset : @math.Vec2
  mut color : @color.Color
}

///|
pub fn Text2dShadow::new(
  offset : @math.Vec2,
  color : @color.Color,
) -> Text2dShadow {
  { offset, color }
}

///|
pub fn Text2dShadow::Text2dShadow() -> Text2dShadow {
  Text2dShadow::new(@math.Vec2::new(4.0F, -4.0F), @color.Color::black())
}

///|
pub fn Text2dShadow::with_offset(
  self : Text2dShadow,
  offset : @math.Vec2,
) -> Text2dShadow {
  { ..self, offset, }
}

///|
pub fn Text2dShadow::with_color(
  self : Text2dShadow,
  color : @color.Color,
) -> Text2dShadow {
  { ..self, color, }
}

///|
pub let ecs_key_text2d_shadow : @ecs.ComponentKey[Text2dShadow] = @ecs.register_component(
  debug_name="text.text_2d_shadow",
)

///|
pub impl @ecs.Component for Text2dShadow with fn component() {
  ecs_key_text2d_shadow
}

///|
// The `Text2d` require-list surface (Bevy: the `#[require(...)]` attribute on
// `Text2d` in `bevy_sprite/src/text2d.rs`) expressed as an explicit bundle,
// plus the ECS bridge that drives the retained `text` runtime -- the
// `update_text2d_layout` equivalent. `bevy_sprite` depends on `bevy_text`;
// the bridge converts sprite-typed data into `@text.TextSpawnData` at the
// boundary.

///|
pub struct Text2dBundle {
  text : Text2d
  font : @text.TextFont
  color : @text.TextColor
  background_color : @text.TextBackgroundColor?
  underline : @text.Underline?
  underline_color : @text.UnderlineColor?
  strikethrough : @text.Strikethrough?
  strikethrough_color : @text.StrikethroughColor?
  layout : @text.TextLayout
  bounds : @text.TextBounds
  line_height : @text.LineHeight
  font_hinting : @text.FontHinting
  shadow : Text2dShadow?
  transform : @transform.Transform
  layers : @camera_render_layers.RenderLayers
  no_frustum_culling : Bool
  anchor : Anchor
  y_axis : @text.YAxisOrientation
  logical_viewport_size : @math.Vec2?
}

///|
pub fn Text2dBundle::new(
  text : Text2d,
  font : @text.TextFont,
  transform : @transform.Transform,
) -> Text2dBundle {
  {
    text,
    font,
    color: @text.TextColor::TextColor(),
    background_color: None,
    underline: None,
    underline_color: None,
    strikethrough: None,
    strikethrough_color: None,
    layout: @text.TextLayout::TextLayout(),
    bounds: @text.TextBounds::TextBounds(),
    line_height: @text.LineHeight::default(),
    font_hinting: @text.FontHinting::default(),
    shadow: None,
    transform,
    layers: @camera_render_layers.RenderLayers::RenderLayers(),
    no_frustum_culling: false,
    anchor: Anchor(),
    y_axis: TopToBottom,
    logical_viewport_size: None,
  }
}

///|
pub fn Text2dBundle::new_with_layers(
  text : Text2d,
  font : @text.TextFont,
  transform : @transform.Transform,
  layers : @camera_render_layers.RenderLayers,
) -> Text2dBundle {
  { ..Text2dBundle::new(text, font, transform), layers, }
}

///|
pub fn Text2dBundle::with_color(
  self : Text2dBundle,
  color : @text.TextColor,
) -> Text2dBundle {
  { ..self, color, }
}

///|
pub fn Text2dBundle::with_background_color(
  self : Text2dBundle,
  background_color : @text.TextBackgroundColor?,
) -> Text2dBundle {
  { ..self, background_color, }
}

///|
pub fn Text2dBundle::with_underline(
  self : Text2dBundle,
  underline : @text.Underline?,
) -> Text2dBundle {
  { ..self, underline, }
}

///|
pub fn Text2dBundle::with_underline_color(
  self : Text2dBundle,
  underline_color : @text.UnderlineColor?,
) -> Text2dBundle {
  { ..self, underline_color, }
}

///|
pub fn Text2dBundle::with_strikethrough(
  self : Text2dBundle,
  strikethrough : @text.Strikethrough?,
) -> Text2dBundle {
  { ..self, strikethrough, }
}

///|
pub fn Text2dBundle::with_strikethrough_color(
  self : Text2dBundle,
  strikethrough_color : @text.StrikethroughColor?,
) -> Text2dBundle {
  { ..self, strikethrough_color, }
}

///|
pub fn Text2dBundle::with_layout(
  self : Text2dBundle,
  layout : @text.TextLayout,
) -> Text2dBundle {
  { ..self, layout, }
}

///|
pub fn Text2dBundle::with_bounds(
  self : Text2dBundle,
  bounds : @text.TextBounds,
) -> Text2dBundle {
  { ..self, bounds, }
}

///|
pub fn Text2dBundle::with_line_height(
  self : Text2dBundle,
  line_height : @text.LineHeight,
) -> Text2dBundle {
  { ..self, line_height, }
}

///|
pub fn Text2dBundle::with_font_hinting(
  self : Text2dBundle,
  font_hinting : @text.FontHinting,
) -> Text2dBundle {
  { ..self, font_hinting, }
}

///|
pub fn Text2dBundle::with_shadow(
  self : Text2dBundle,
  shadow : Text2dShadow?,
) -> Text2dBundle {
  { ..self, shadow, }
}

///|
/// Set the anchor used for world-space `Text2d` positioning (Bevy-aligned).
pub fn Text2dBundle::with_anchor(
  self : Text2dBundle,
  anchor : Anchor,
) -> Text2dBundle {
  { ..self, anchor, }
}

///|
/// Set the layout coordinate orientation.
pub fn Text2dBundle::with_y_axis(
  self : Text2dBundle,
  y_axis : @text.YAxisOrientation,
) -> Text2dBundle {
  { ..self, y_axis, }
}

///|
fn text2d_shadow_to_component(shadow : Text2dShadow?) -> @text.TextShadow? {
  match shadow {
    Some(shadow) => Some(@text.TextShadow::new(shadow.offset, shadow.color))
    None => None
  }
}

///|
fn Text2dBundle::to_spawn_data(self : Text2dBundle) -> @text.TextSpawnData {
  {
    content: self.text.content,
    font: self.font,
    color: self.color,
    background_color: self.background_color,
    underline: self.underline,
    underline_color: self.underline_color,
    strikethrough: self.strikethrough,
    strikethrough_color: self.strikethrough_color,
    layout: self.layout,
    bounds: self.bounds,
    line_height: self.line_height,
    font_hinting: self.font_hinting,
    shadow: text2d_shadow_to_component(self.shadow),
    transform: self.transform,
    layers: self.layers,
    no_frustum_culling: self.no_frustum_culling,
    anchor: self.anchor.as_vec(),
    y_axis: self.y_axis,
    logical_viewport_size: self.logical_viewport_size,
  }
}

///|
pub fn text_spawn(bundle : Text2dBundle) -> @text.TextHandle {
  @text.text_spawn_data(bundle.to_spawn_data())
}

///|
pub fn Text2dBundle::spawn(self : Text2dBundle) -> @text.TextHandle {
  text_spawn(self)
}

///|
pub fn text_bundle(
  content : String,
  font : @text.TextFont,
  transform : @transform.Transform,
) -> Text2dBundle {
  Text2dBundle::new(Text2d::new(content), font, transform)
}

///|
pub fn text_set_anchor(handle : @text.TextHandle, anchor : Anchor) -> Unit {
  @text.text_set_anchor_vec(handle, anchor.as_vec())
}

///|
pub fn text_set_shadow(
  handle : @text.TextHandle,
  shadow : Text2dShadow?,
) -> Unit {
  @text.text_set_text_shadow(handle, text2d_shadow_to_component(shadow))
}

///|
fn text2d_vec2_eq(lhs : @math.Vec2, rhs : @math.Vec2) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y
}

///|
fn text2d_color_eq(lhs : @color.Color, rhs : @color.Color) -> Bool {
  lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
}

///|
fn anchor_eq(lhs : Anchor, rhs : Anchor) -> Bool {
  text2d_vec2_eq(lhs.value, rhs.value)
}

///|
fn text2d_eq(lhs : Text2d, rhs : Text2d) -> Bool {
  lhs.content == rhs.content
}

///|
fn text_shadow_eq(lhs : Text2dShadow?, rhs : Text2dShadow?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) =>
      text2d_vec2_eq(lhs.offset, rhs.offset) &&
      text2d_color_eq(lhs.color, rhs.color)
    (None, None) => true
    _ => false
  }
}

///|
priv struct EcsTextEntry {
  world_id : Int
  entity : @core.Entity
  handle : @text.TextHandle
  bundle : Text2dBundle
  view_visible : Bool
  span_bundles : Array[@text.TextSpanBundle]
}

///|
let text_ecs_entries : Array[EcsTextEntry] = []

///|
let text_ecs_index_by_world_id : Map[Int, Map[Int, Int]] = Map([])

///|
priv struct Text2dEcsRuntimeState {
  mut world_id : Int?
  mut diagnostic_sync_ecs_cpu_ms : Float
  mut diagnostic_sync_ecs_dirty_entity_count : Int
  mut diagnostic_sync_ecs_early_return : Bool
}

///|
let text2d_ecs_runtime_state : Text2dEcsRuntimeState = {
  world_id: None,
  diagnostic_sync_ecs_cpu_ms: 0.0F,
  diagnostic_sync_ecs_dirty_entity_count: 0,
  diagnostic_sync_ecs_early_return: false,
}

///|
fn text2d_prepare_ecs_world(world : @ecs.World) -> Unit {
  // The retained runtime (and the UI bridge) reset through `text`'s shared
  // world tracker; this bridge owns only its own entry stores.
  @text.prepare_text_runtime_world(world)
  let world_id = world.world_id()
  if text2d_ecs_runtime_state.world_id == Some(world_id) {
    return
  }
  text2d_ecs_runtime_state.world_id = Some(world_id)
  text_ecs_entries.clear()
  text_ecs_index_by_world_id.clear()
}

///|
fn register_text_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(
    ecs_key_text2d,
    @text.ecs_key_text_layout,
    fn() { @text.TextLayout::TextLayout() },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @text.ecs_key_text_font,
    fn() { @text.TextFont::TextFont() },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @text.ecs_key_text_color,
    fn() { @text.TextColor::TextColor() },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @text.ecs_key_text_line_height,
    fn() { @text.LineHeight::default() },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @text.ecs_key_text_font_hinting,
    fn() { @text.FontHinting::default() },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @text.ecs_key_text_bounds,
    fn() { @text.TextBounds::TextBounds() },
  )
  world.register_required_components_with(ecs_key_text2d, ecs_key_anchor, fn() {
    Anchor()
  })
  world.register_required_components_with(
    ecs_key_text2d,
    @visibility.ecs_key_visibility,
    fn() { Inherited },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
}

///|
fn text_ecs_find_entry_index(world_id : Int, entity : @core.Entity) -> Int? {
  let count = text_ecs_entries.length()
  for i in 0..<count {
    let entry = text_ecs_entries[i]
    if entry.world_id == world_id && entry.entity == entity {
      return Some(i)
    }
  }
  None
}

///|
fn text_ecs_build_entry_index_by_entity_id(world_id : Int) -> Map[Int, Int] {
  if text_ecs_index_by_world_id.get(world_id) is Some(index_by_entity_id) {
    return index_by_entity_id
  }
  let index_by_entity_id : Map[Int, Int] = Map([])
  let count = text_ecs_entries.length()
  for i in 0..<count {
    let entry = text_ecs_entries[i]
    if entry.world_id == world_id {
      index_by_entity_id.set(entry.entity.id, i)
    }
  }
  text_ecs_index_by_world_id.set(world_id, index_by_entity_id)
  index_by_entity_id
}

///|
fn text_ecs_text2d_root_is_changed(
  world : @ecs.World,
  entity : @core.Entity,
  tick : @core.SystemTicks,
) -> Bool {
  world.is_changed_by_key(entity, @transform.ecs_key_global_transform, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_color, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_background_color, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_underline, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_underline_color, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_strikethrough, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_strikethrough_color, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_layout, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_bounds, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_line_height, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_font_hinting, tick) ||
  world.is_changed_by_key(entity, ecs_key_text2d_shadow, tick) ||
  world.is_changed_by_key(
    entity, @camera_render_layers.ecs_key_render_layers, tick,
  ) ||
  world.is_changed_by_key(entity, ecs_key_anchor, tick) ||
  world.is_changed_by_key(entity, @text.ecs_key_text_y_axis, tick) ||
  world.is_changed_by_key(entity, @visibility.ecs_key_view_visibility, tick) ||
  world.is_changed_by_key(entity, @hierarchy.ecs_key_children, tick)
}

///|
fn text_ecs_find_entry_index_from_index(
  world_id : Int,
  entity : @core.Entity,
  index_by_entity_id : Map[Int, Int],
) -> Int? {
  match index_by_entity_id.get(entity.id) {
    Some(index) =>
      if index >= 0 &&
        index < text_ecs_entries.length() &&
        text_ecs_entries[index].world_id == world_id &&
        text_ecs_entries[index].entity == entity {
        Some(index)
      } else {
        text_ecs_find_entry_index(world_id, entity)
      }
    None => None
  }
}

///|
fn text_ecs_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  text : Text2d,
  font : @text.TextFont,
  local_transform : @transform.Transform,
) -> (Text2dBundle, Bool) {
  guard @text.text_ecs_world_entity_ref(world, entity) is Some(entity_ref) else {
    return (Text2dBundle::new(text, font, local_transform), true)
  }
  let transform = match
    (@text.text_ecs_entity_ref_get(entity_ref) : @transform.GlobalTransform?) {
    Some(global_transform) => global_transform.to_transform_approx()
    None => local_transform
  }
  let color = match
    (@text.text_ecs_entity_ref_get(entity_ref) : @text.TextColor?) {
    Some(color) => color
    None => @text.TextColor::TextColor()
  }
  let background_color : @text.TextBackgroundColor? = @text.text_ecs_entity_ref_get(
    entity_ref,
  )
  let underline : @text.Underline? = @text.text_ecs_entity_ref_get(entity_ref)
  let underline_color : @text.UnderlineColor? = @text.text_ecs_entity_ref_get(
    entity_ref,
  )
  let strikethrough : @text.Strikethrough? = @text.text_ecs_entity_ref_get(
    entity_ref,
  )
  let strikethrough_color : @text.StrikethroughColor? = @text.text_ecs_entity_ref_get(
    entity_ref,
  )
  let layout = match
    (@text.text_ecs_entity_ref_get(entity_ref) : @text.TextLayout?) {
    Some(layout) => layout
    None => @text.TextLayout::TextLayout()
  }
  let bounds = match
    (@text.text_ecs_entity_ref_get(entity_ref) : @text.TextBounds?) {
    Some(bounds) => bounds
    None => @text.TextBounds::TextBounds()
  }
  let line_height = match
    (@text.text_ecs_entity_ref_get(entity_ref) : @text.LineHeight?) {
    Some(line_height) => line_height
    None => @text.LineHeight::default()
  }
  let font_hinting = match
    (@text.text_ecs_entity_ref_get(entity_ref) : @text.FontHinting?) {
    Some(font_hinting) => font_hinting
    None => @text.FontHinting::default()
  }
  let shadow : Text2dShadow? = @text.text_ecs_entity_ref_get(entity_ref)
  let layers : @camera_render_layers.RenderLayers = match
    @text.text_ecs_entity_ref_get(entity_ref) {
    Some(layers) => layers
    None => @camera_render_layers.RenderLayers::RenderLayers()
  }
  let anchor = match (@text.text_ecs_entity_ref_get(entity_ref) : Anchor?) {
    Some(anchor) => anchor
    None => Anchor()
  }
  let y_axis = match
    (@text.text_ecs_entity_ref_get(entity_ref) : @text.YAxisOrientation?) {
    Some(y_axis) => y_axis
    None => TopToBottom
  }
  let no_frustum_culling = (world.contains_by_key(
      entity, @visibility.ecs_key_no_frustum_culling,
    ) catch {
      _ => false
    }) ||
    (world.contains_by_key(entity, @visibility.ecs_key_no_cpu_culling) catch {
      _ => false
    })
  (
    {
      text,
      font,
      color,
      background_color,
      underline,
      underline_color,
      strikethrough,
      strikethrough_color,
      layout,
      bounds,
      line_height,
      font_hinting,
      shadow,
      transform,
      layers,
      no_frustum_culling,
      anchor,
      y_axis,
      logical_viewport_size: None,
    },
    @text.text_ecs_entity_ref_view_visible(entity_ref),
  )
}

///|
fn text_ecs_spawn_entry(
  world : @ecs.World,
  world_id : Int,
  entity : @core.Entity,
  bundle : Text2dBundle,
  span_bundles : Array[@text.TextSpanBundle],
  view_visible : Bool,
) -> Unit {
  @text.sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(@text.text_spawn_span(handle, span_bundle))
    }
    handle
  })
  @text.text_set_view_visible(handle, view_visible)
  text_ecs_entries.push({
    world_id,
    entity,
    handle,
    bundle,
    view_visible,
    span_bundles,
  })
  text_ecs_build_entry_index_by_entity_id(world_id).set(
    entity.id,
    text_ecs_entries.length() - 1,
  )
}

///|
fn text_ecs_remove_entry_at_index(
  index : Int,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  let last_index = text_ecs_entries.length() - 1
  let removed_entry = text_ecs_entries[index]
  ignore(@text.text_despawn(removed_entry.handle))
  if index != last_index {
    let moved_entry = text_ecs_entries[last_index]
    text_ecs_entries[index] = moved_entry
    index_by_entity_id.set(moved_entry.entity.id, index)
  }
  ignore(text_ecs_entries.pop())
  ignore(index_by_entity_id.remove(removed_entry.entity.id))
}

///|
fn text_ecs_cleanup_removed_entity(
  world_id : Int,
  entity : @core.Entity,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  match
    text_ecs_find_entry_index_from_index(world_id, entity, index_by_entity_id) {
    Some(index) => text_ecs_remove_entry_at_index(index, index_by_entity_id)
    None => ()
  }
}

///|
fn text_ecs_cleanup_removed_entries(
  world : @ecs.World,
  world_id : Int,
  tick : @core.SystemTicks,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  for entity in world.removed_components(ecs_key_text2d, tick).read() {
    text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
  for entity in world.removed_components(@text.ecs_key_text_font, tick).read() {
    text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
  for
    entity in world
    .removed_components(@text.ecs_key_text_font_hinting, tick)
    .read() {
    text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
  for
    entity in world
    .removed_components(@transform.ecs_key_transform, tick)
    .read() {
    text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
}

///|
fn text_ecs_respawn_entry(
  world : @ecs.World,
  entry : EcsTextEntry,
  bundle : Text2dBundle,
  span_bundles : Array[@text.TextSpanBundle],
  view_visible : Bool,
) -> EcsTextEntry {
  ignore(@text.text_despawn(entry.handle))
  @text.sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(@text.text_spawn_span(handle, span_bundle))
    }
    handle
  })
  @text.text_set_view_visible(handle, view_visible)
  { ..entry, handle, bundle, view_visible, span_bundles }
}

///|
fn text_ecs_sync_existing_entry(
  world : @ecs.World,
  entry : EcsTextEntry,
  bundle : Text2dBundle,
  span_bundles : Array[@text.TextSpanBundle],
  view_visible : Bool,
) -> EcsTextEntry {
  @text.sync_text_runtime_rem_size(world)
  let handle = entry.handle
  if @text.text_get_transform(handle) is None {
    return text_ecs_respawn_entry(
      world, entry, bundle, span_bundles, view_visible,
    )
  }
  if !@text.text_span_bundle_array_eq(entry.span_bundles, span_bundles) {
    return text_ecs_respawn_entry(
      world, entry, bundle, span_bundles, view_visible,
    )
  }
  if entry.view_visible != view_visible {
    @text.text_set_view_visible(handle, view_visible)
  }
  if !text2d_eq(entry.bundle.text, bundle.text) {
    @text.text_set_content(handle, bundle.text.content)
  }
  if !@text.text_font_eq(entry.bundle.font, bundle.font) {
    @text.text_set_font(handle, bundle.font)
  }
  if !@text.text_color_eq(entry.bundle.color, bundle.color) {
    @text.text_set_color(handle, bundle.color)
  }
  if !@text.text_background_color_eq(
      entry.bundle.background_color,
      bundle.background_color,
    ) {
    @text.text_set_background_color(handle, bundle.background_color)
  }
  if !@text.empty_marker_opt_eq(entry.bundle.underline, bundle.underline) {
    @text.text_set_underline(handle, bundle.underline)
  }
  if !@text.underline_color_eq(
      entry.bundle.underline_color,
      bundle.underline_color,
    ) {
    @text.text_set_underline_color(handle, bundle.underline_color)
  }
  if !@text.empty_marker_opt_eq(
      entry.bundle.strikethrough,
      bundle.strikethrough,
    ) {
    @text.text_set_strikethrough(handle, bundle.strikethrough)
  }
  if !@text.strikethrough_color_eq(
      entry.bundle.strikethrough_color,
      bundle.strikethrough_color,
    ) {
    @text.text_set_strikethrough_color(handle, bundle.strikethrough_color)
  }
  if !@text.text_layout_eq(entry.bundle.layout, bundle.layout) {
    @text.text_set_layout(handle, bundle.layout)
  }
  if !@text.text_bounds_eq(entry.bundle.bounds, bundle.bounds) {
    @text.text_set_bounds(handle, bundle.bounds)
  }
  if !@text.line_height_eq(entry.bundle.line_height, bundle.line_height) {
    @text.text_set_line_height(handle, bundle.line_height)
  }
  if !@text.font_hinting_eq(entry.bundle.font_hinting, bundle.font_hinting) {
    @text.text_set_font_hinting(handle, bundle.font_hinting)
  }
  if !text_shadow_eq(entry.bundle.shadow, bundle.shadow) {
    text_set_shadow(handle, bundle.shadow)
  }
  if !@text.transform_eq(entry.bundle.transform, bundle.transform) {
    @text.text_set_transform(handle, bundle.transform)
  }
  if !@text.render_layers_eq(entry.bundle.layers, bundle.layers) {
    @text.text_set_layers(handle, bundle.layers)
  }
  if entry.bundle.no_frustum_culling != bundle.no_frustum_culling {
    @text.text_set_no_frustum_culling(handle, bundle.no_frustum_culling)
  }
  if !anchor_eq(entry.bundle.anchor, bundle.anchor) {
    text_set_anchor(handle, bundle.anchor)
  }
  if !@text.y_axis_eq(entry.bundle.y_axis, bundle.y_axis) {
    @text.text_set_y_axis(handle, bundle.y_axis)
  }
  if !@text.vec2_opt_eq(
      entry.bundle.logical_viewport_size,
      bundle.logical_viewport_size,
    ) {
    @text.text_set_logical_viewport_size(handle, bundle.logical_viewport_size)
  }
  { ..entry, bundle, view_visible, span_bundles }
}

///|
pub fn text_sync_ecs_system(world : @ecs.World) -> Unit {
  let sync_start = @time.host_time_now()
  @text.text_ecs_sync_candidate_entity_count.val = 0
  text2d_ecs_runtime_state.diagnostic_sync_ecs_early_return = false
  text2d_ecs_runtime_state.diagnostic_sync_ecs_dirty_entity_count = 0
  text2d_prepare_ecs_world(world)
  let world_id = world.world_id()
  let index_by_entity_id = text_ecs_build_entry_index_by_entity_id(world_id)
  let tick = world.get_tick_context().ticks()
  text_ecs_cleanup_removed_entries(world, world_id, tick, index_by_entity_id)
  let span_edges = @text.text_ecs_collect_span_edges(world)
  let has_any_spans = span_edges.length() > 0
  let changed_span_parent_ids = @text.text_ecs_changed_span_parent_ids(
    world, span_edges, tick,
  )
  let dirty_root_count = Ref(0)
  let query : @ecs.Query[
    (
      @ecs.Read[Text2d],
      @ecs.Read[@text.TextFont],
      @ecs.Read[@transform.Transform],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    @text.text_ecs_sync_candidate_entity_count.val = @text.text_ecs_sync_candidate_entity_count.val +
      1
    let existing_index = text_ecs_find_entry_index_from_index(
      world_id, entity, index_by_entity_id,
    )
    let (text, font, local_transform) = data
    if existing_index is Some(_) &&
      !text.is_changed() &&
      !font.is_changed() &&
      !local_transform.is_changed() &&
      !text_ecs_text2d_root_is_changed(world, entity, tick) &&
      !@text.text_ecs_entity_id_set_contains(changed_span_parent_ids, entity) {
      return
    }
    dirty_root_count.val = dirty_root_count.val + 1
    let (bundle, view_visible) = text_ecs_bundle_from_entity(
      world,
      entity,
      text.value(),
      font.value(),
      local_transform.value(),
    )
    let span_bundles = if has_any_spans {
      @text.text_ecs_collect_span_bundles_for_entity(
        world,
        entity,
        bundle.font,
        bundle.line_height,
        span_edges,
      )
    } else {
      []
    }
    match existing_index {
      Some(index) => {
        let entry = text_ecs_entries[index]
        text_ecs_entries[index] = text_ecs_sync_existing_entry(
          world, entry, bundle, span_bundles, view_visible,
        )
      }
      None => {
        text_ecs_spawn_entry(
          world, world_id, entity, bundle, span_bundles, view_visible,
        )
        index_by_entity_id.set(entity.id, text_ecs_entries.length() - 1)
      }
    }
  })
  text2d_ecs_runtime_state.diagnostic_sync_ecs_dirty_entity_count = dirty_root_count.val
  text2d_ecs_runtime_state.diagnostic_sync_ecs_early_return = dirty_root_count.val ==
    0 &&
    text_ecs_entries.length() > 0
  text2d_ecs_runtime_state.diagnostic_sync_ecs_cpu_ms = (
      @time.host_time_now() - sync_start
    ) *
    1000.0F
}

///|
pub fn text_diagnostic_sync_ecs_cpu_ms() -> Float {
  text2d_ecs_runtime_state.diagnostic_sync_ecs_cpu_ms
}

///|
pub fn text_diagnostic_sync_ecs_dirty_entity_count() -> Int {
  text2d_ecs_runtime_state.diagnostic_sync_ecs_dirty_entity_count
}

///|
pub fn text_diagnostic_sync_ecs_early_return() -> Bool {
  text2d_ecs_runtime_state.diagnostic_sync_ecs_early_return
}

///|
/// The `Text2d` half of the text plugin surface (Bevy: `SpritePlugin`
/// registers `update_text2d_layout`): required components plus the ECS
/// bridge system, scheduled in `text`'s sync set.
pub fn text2d_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  try! register_text_required_components(app.world())
  app.add_post_update_system_config(
    @app.system(text_sync_ecs_system).in_set(@text.text_set_sync_ecs),
  )
}
