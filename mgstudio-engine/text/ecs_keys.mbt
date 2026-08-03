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
pub let ecs_key_text : @ecs.ComponentKey[Text] = @ecs.register_component(
  debug_name="text.text",
)

///|
pub let ecs_key_text_span : @ecs.ComponentKey[TextSpan] = @ecs.register_component(
  debug_name="text.text_span",
)

///|
pub let ecs_key_text_font : @ecs.ComponentKey[TextFont] = @ecs.register_component(
  debug_name="text.text_font",
)

///|
pub let ecs_key_text_color : @ecs.ComponentKey[TextColor] = @ecs.register_component(
  debug_name="text.text_color",
)

///|
pub let ecs_key_text_background_color : @ecs.ComponentKey[TextBackgroundColor] = @ecs.register_component(
  debug_name="text.text_background_color",
)

///|
pub let ecs_key_text_underline_color : @ecs.ComponentKey[UnderlineColor] = @ecs.register_component(
  debug_name="text.text_underline_color",
)

///|
pub let ecs_key_text_underline : @ecs.ComponentKey[Underline] = @ecs.register_component(
  debug_name="text.text_underline",
)

///|
pub let ecs_key_text_strikethrough_color : @ecs.ComponentKey[StrikethroughColor] = @ecs.register_component(
  debug_name="text.text_strikethrough_color",
)

///|
pub let ecs_key_text_strikethrough : @ecs.ComponentKey[Strikethrough] = @ecs.register_component(
  debug_name="text.text_strikethrough",
)

///|
pub let ecs_key_text_layout : @ecs.ComponentKey[TextLayout] = @ecs.register_component(
  debug_name="text.text_layout",
)

///|
pub let ecs_key_text_bounds : @ecs.ComponentKey[TextBounds] = @ecs.register_component(
  debug_name="text.text_bounds",
)

///|
pub let ecs_key_text_line_height : @ecs.ComponentKey[LineHeight] = @ecs.register_component(
  debug_name="text.text_line_height",
)

///|
pub let ecs_key_text_font_hinting : @ecs.ComponentKey[FontHinting] = @ecs.register_component(
  debug_name="text.text_font_hinting",
)

///|
pub let ecs_key_text_shadow : @ecs.ComponentKey[TextShadow] = @ecs.register_component(
  debug_name="text.text_shadow",
)

///|
pub let ecs_key_text_y_axis : @ecs.ComponentKey[YAxisOrientation] = @ecs.register_component(
  debug_name="text.text_y_axis",
)

///|
let ecs_res_key_rem_size : @ecs.ResourceKey[RemSize] = @ecs.register_resource(
  debug_name="text.rem_size",
)

///|
let ecs_res_key_font_cx : @ecs.ResourceKey[FontCx] = @ecs.register_resource(
  debug_name="text.font_cx",
)

///|
let ecs_res_key_font_atlas_set : @ecs.ResourceKey[FontAtlasSet] = @ecs.register_resource(
  debug_name="text.font_atlas_set",
)

///|
pub impl @ecs.Component for Text with fn component() {
  ecs_key_text
}

///|
pub impl @ecs.Component for TextSpan with fn component() {
  ecs_key_text_span
}

///|
pub impl @ecs.Component for TextFont with fn component() {
  ecs_key_text_font
}

///|
pub impl @ecs.Component for TextColor with fn component() {
  ecs_key_text_color
}

///|
pub impl @ecs.Component for TextBackgroundColor with fn component() {
  ecs_key_text_background_color
}

///|
pub impl @ecs.Component for UnderlineColor with fn component() {
  ecs_key_text_underline_color
}

///|
pub impl @ecs.Component for Underline with fn component() {
  ecs_key_text_underline
}

///|
pub impl @ecs.Component for StrikethroughColor with fn component() {
  ecs_key_text_strikethrough_color
}

///|
pub impl @ecs.Component for Strikethrough with fn component() {
  ecs_key_text_strikethrough
}

///|
pub impl @ecs.Component for TextLayout with fn component() {
  ecs_key_text_layout
}

///|
pub impl @ecs.Component for TextBounds with fn component() {
  ecs_key_text_bounds
}

///|
pub impl @ecs.Component for LineHeight with fn component() {
  ecs_key_text_line_height
}

///|
pub impl @ecs.Component for FontHinting with fn component() {
  ecs_key_text_font_hinting
}

///|
pub impl @ecs.Component for TextShadow with fn component() {
  ecs_key_text_shadow
}

///|
pub impl @ecs.Component for YAxisOrientation with fn component() {
  ecs_key_text_y_axis
}

///|
pub impl @app.Resource for RemSize with fn resource() {
  ecs_res_key_rem_size
}

///|
pub impl @app.Resource for FontCx with fn resource() {
  ecs_res_key_font_cx
}

///|
pub impl @app.Resource for FontAtlasSet with fn resource() {
  ecs_res_key_font_atlas_set
}

///|
priv struct UiEcsTextEntry {
  world_id : Int
  entity : @core.Entity
  handle : TextHandle
  bundle : TextSpawnData
  view_visible : Bool
  span_bundles : Array[TextSpanBundle]
}

///|
let ui_text_ecs_entries : Array[UiEcsTextEntry] = []

///|
let ui_text_ecs_index_by_world_id : Map[Int, Map[Int, Int]] = Map([])

///|
priv struct TextEcsRuntimeState {
  mut world_id : Int?
}

///|
let text_ecs_runtime_state : TextEcsRuntimeState = { world_id: None }

///|
pub let text_ecs_sync_candidate_entity_count : Ref[Int] = Ref(0)

///|
fn reset_text_runtime_state() -> Unit {
  text_state.next_text_id = 0
  text_state.next_span_id = 0
  text_state_clear_instances()
  text_debug_frame_state.draws.clear()
  ui_text_ecs_entries.clear()
  ui_text_ecs_index_by_world_id.clear()
  text_pipeline_runtime_state.font_atlas_set = FontAtlasSet()
  text_pipeline_runtime_state.default_text_font_handle = None
  text_pipeline_runtime_state.cosmic_font_system = {
    font_system: @cosmic.FontSystem::new(),
    handle_to_font_id: [],
    font_id_to_handle_id: [],
    handle_to_family: [],
  }
  swash_font_cache.val.entries.clear()
  cosmic_swash_cache.val = @cosmic.SwashCache::new()
}

///|
pub fn prepare_text_runtime_world(world : @ecs.World) -> Unit {
  let world_id = world.world_id()
  if text_ecs_runtime_state.world_id == Some(world_id) {
    return
  }
  text_ecs_runtime_state.world_id = Some(world_id)
  reset_text_runtime_state()
}

///|
pub fn text_reset_runtime_state_for_tests() -> Unit {
  text_ecs_runtime_state.world_id = None
  reset_text_runtime_state()
}

///|
pub fn sync_text_runtime_rem_size(world : @ecs.World) -> Unit {
  let rem_size = match world.resource(RemSize::resource()).get() {
    Some(value) => value.value()
    None => RemSize::RemSize().value()
  }
  text_set_runtime_rem_size(rem_size)
}

///|
fn float_opt_eq(lhs : Float?, rhs : Float?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => lhs == rhs
    (None, None) => true
    _ => false
  }
}

///|
fn color_eq(lhs : @color.Color, rhs : @color.Color) -> Bool {
  lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
}

///|
fn vec2_eq(lhs : @math.Vec2, rhs : @math.Vec2) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y
}

///|
fn vec3_eq(lhs : @math.Vec3, rhs : @math.Vec3) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
}

///|
fn quat_eq(lhs : @math.Quat, rhs : @math.Quat) -> Bool {
  lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
}

///|
pub fn transform_eq(
  lhs : @transform.Transform,
  rhs : @transform.Transform,
) -> Bool {
  vec3_eq(lhs.translation, rhs.translation) &&
  quat_eq(lhs.rotation, rhs.rotation) &&
  vec3_eq(lhs.scale, rhs.scale)
}

///|
pub fn render_layers_eq(
  lhs : @camera_render_layers.RenderLayers,
  rhs : @camera_render_layers.RenderLayers,
) -> Bool {
  lhs.mask == rhs.mask
}

///|
pub fn vec2_opt_eq(lhs : @math.Vec2?, rhs : @math.Vec2?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => vec2_eq(lhs, rhs)
    (None, None) => true
    _ => false
  }
}

///|
fn font_smoothing_eq(lhs : FontSmoothing, rhs : FontSmoothing) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (AntiAliased, AntiAliased) => true
    _ => false
  }
}

///|
fn text_span_eq(lhs : TextSpan, rhs : TextSpan) -> Bool {
  lhs.content == rhs.content
}

///|
fn font_source_eq(lhs : FontSource, rhs : FontSource) -> Bool {
  match (lhs, rhs) {
    (Handle(lhs), Handle(rhs)) => lhs.id() == rhs.id()
    (Family(lhs), Family(rhs)) => lhs == rhs
    (Serif, Serif) => true
    (SansSerif, SansSerif) => true
    (Cursive, Cursive) => true
    (Fantasy, Fantasy) => true
    (Monospace, Monospace) => true
    (SystemUi, SystemUi) => true
    (UiSerif, UiSerif) => true
    (UiSansSerif, UiSansSerif) => true
    (UiMonospace, UiMonospace) => true
    (UiRounded, UiRounded) => true
    (Emoji, Emoji) => true
    (Math, Math) => true
    (FangSong, FangSong) => true
    _ => false
  }
}

///|
fn font_size_eq(lhs : FontSize, rhs : FontSize) -> Bool {
  match (lhs, rhs) {
    (Px(lhs), Px(rhs)) => lhs == rhs
    (Vw(lhs), Vw(rhs)) => lhs == rhs
    (Vh(lhs), Vh(rhs)) => lhs == rhs
    (VMin(lhs), VMin(rhs)) => lhs == rhs
    (VMax(lhs), VMax(rhs)) => lhs == rhs
    (Rem(lhs), Rem(rhs)) => lhs == rhs
    _ => false
  }
}

///|
fn font_weight_eq(lhs : FontWeight, rhs : FontWeight) -> Bool {
  lhs.clamp().raw_value() == rhs.clamp().raw_value()
}

///|
fn font_width_eq(lhs : FontWidth, rhs : FontWidth) -> Bool {
  lhs.percentage() == rhs.percentage()
}

///|
fn font_style_eq(lhs : FontStyle, rhs : FontStyle) -> Bool {
  match (lhs, rhs) {
    (Normal, Normal) => true
    (Italic, Italic) => true
    (Oblique(lhs), Oblique(rhs)) => float_opt_eq(lhs, rhs)
    _ => false
  }
}

///|
fn font_feature_tag_eq(lhs : FontFeatureTag, rhs : FontFeatureTag) -> Bool {
  lhs.tag_string() == rhs.tag_string()
}

///|
fn font_features_eq(lhs : FontFeatures, rhs : FontFeatures) -> Bool {
  let lhs_features = lhs.features()
  let rhs_features = rhs.features()
  if lhs_features.length() != rhs_features.length() {
    return false
  }
  for i in 0..<lhs_features.length() {
    if !font_feature_tag_eq(lhs_features[i].0, rhs_features[i].0) {
      return false
    }
    if lhs_features[i].1 != rhs_features[i].1 {
      return false
    }
  }
  true
}

///|
pub fn text_font_eq(lhs : TextFont, rhs : TextFont) -> Bool {
  font_source_eq(lhs.font, rhs.font) &&
  font_size_eq(lhs.font_size, rhs.font_size) &&
  font_weight_eq(lhs.weight, rhs.weight) &&
  font_width_eq(lhs.width, rhs.width) &&
  font_style_eq(lhs.style, rhs.style) &&
  font_features_eq(lhs.font_features, rhs.font_features) &&
  font_smoothing_eq(lhs.font_smoothing, rhs.font_smoothing)
}

///|
pub fn text_color_eq(lhs : TextColor, rhs : TextColor) -> Bool {
  color_eq(lhs.color, rhs.color)
}

///|
pub fn text_background_color_eq(
  lhs : TextBackgroundColor?,
  rhs : TextBackgroundColor?,
) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => color_eq(lhs.color, rhs.color)
    (None, None) => true
    _ => false
  }
}

///|
pub fn underline_color_eq(lhs : UnderlineColor?, rhs : UnderlineColor?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => color_eq(lhs.color, rhs.color)
    (None, None) => true
    _ => false
  }
}

///|
pub fn strikethrough_color_eq(
  lhs : StrikethroughColor?,
  rhs : StrikethroughColor?,
) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => color_eq(lhs.color, rhs.color)
    (None, None) => true
    _ => false
  }
}

///|
pub fn[A] empty_marker_opt_eq(lhs : A?, rhs : A?) -> Bool {
  match (lhs, rhs) {
    (Some(_), Some(_)) => true
    (None, None) => true
    _ => false
  }
}

///|
fn justify_eq(lhs : Justify, rhs : Justify) -> Bool {
  match (lhs, rhs) {
    (Left, Left) => true
    (Center, Center) => true
    (Right, Right) => true
    (Justified, Justified) => true
    (Start, Start) => true
    (End, End) => true
    _ => false
  }
}

///|
fn line_break_eq(lhs : LineBreak, rhs : LineBreak) -> Bool {
  match (lhs, rhs) {
    (WordBoundary, WordBoundary) => true
    (AnyCharacter, AnyCharacter) => true
    (WordOrCharacter, WordOrCharacter) => true
    (NoWrap, NoWrap) => true
    _ => false
  }
}

///|
pub fn text_layout_eq(lhs : TextLayout, rhs : TextLayout) -> Bool {
  justify_eq(lhs.justify, rhs.justify) &&
  line_break_eq(lhs.linebreak, rhs.linebreak)
}

///|
pub fn line_height_eq(lhs : LineHeight, rhs : LineHeight) -> Bool {
  match (lhs, rhs) {
    (Px(lhs), Px(rhs)) => lhs == rhs
    (RelativeToFont(lhs), RelativeToFont(rhs)) => lhs == rhs
    _ => false
  }
}

///|
pub fn font_hinting_eq(lhs : FontHinting, rhs : FontHinting) -> Bool {
  match (lhs, rhs) {
    (Disabled, Disabled) => true
    (Enabled, Enabled) => true
    _ => false
  }
}

///|
pub fn text_bounds_eq(lhs : TextBounds, rhs : TextBounds) -> Bool {
  float_opt_eq(lhs.width, rhs.width) && float_opt_eq(lhs.height, rhs.height)
}

///|
pub fn y_axis_eq(lhs : YAxisOrientation, rhs : YAxisOrientation) -> Bool {
  match (lhs, rhs) {
    (TopToBottom, TopToBottom) => true
    (BottomToTop, BottomToTop) => true
    _ => false
  }
}

///|
fn text_span_bundle_eq(lhs : TextSpanBundle, rhs : TextSpanBundle) -> Bool {
  text_span_eq(lhs.span, rhs.span) &&
  text_font_eq(lhs.font, rhs.font) &&
  text_color_eq(lhs.color, rhs.color) &&
  text_background_color_eq(lhs.background_color, rhs.background_color) &&
  empty_marker_opt_eq(lhs.underline, rhs.underline) &&
  underline_color_eq(lhs.underline_color, rhs.underline_color) &&
  empty_marker_opt_eq(lhs.strikethrough, rhs.strikethrough) &&
  strikethrough_color_eq(lhs.strikethrough_color, rhs.strikethrough_color) &&
  line_height_eq(lhs.line_height, rhs.line_height)
}

///|
pub fn text_span_bundle_array_eq(
  lhs : Array[TextSpanBundle],
  rhs : Array[TextSpanBundle],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if !text_span_bundle_eq(lhs[i], rhs[i]) {
      return false
    }
  }
  true
}

///|
fn text_component_shadow_eq(lhs : TextShadow?, rhs : TextShadow?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) =>
      vec2_eq(lhs.offset, rhs.offset) && color_eq(lhs.color, rhs.color)
    (None, None) => true
    _ => false
  }
}

///|
fn text_spawn_data_rerender_eq(
  lhs : TextSpawnData,
  rhs : TextSpawnData,
) -> Bool {
  lhs.content == rhs.content &&
  text_font_eq(lhs.font, rhs.font) &&
  text_color_eq(lhs.color, rhs.color) &&
  text_background_color_eq(lhs.background_color, rhs.background_color) &&
  empty_marker_opt_eq(lhs.underline, rhs.underline) &&
  underline_color_eq(lhs.underline_color, rhs.underline_color) &&
  empty_marker_opt_eq(lhs.strikethrough, rhs.strikethrough) &&
  strikethrough_color_eq(lhs.strikethrough_color, rhs.strikethrough_color) &&
  text_layout_eq(lhs.layout, rhs.layout) &&
  text_bounds_eq(lhs.bounds, rhs.bounds) &&
  line_height_eq(lhs.line_height, rhs.line_height) &&
  font_hinting_eq(lhs.font_hinting, rhs.font_hinting) &&
  text_component_shadow_eq(lhs.shadow, rhs.shadow) &&
  y_axis_eq(lhs.y_axis, rhs.y_axis) &&
  vec2_opt_eq(lhs.logical_viewport_size, rhs.logical_viewport_size)
}

///|
fn text_ecs_ui_root_is_changed(
  world : @ecs.World,
  entity : @core.Entity,
  tick : @core.SystemTicks,
) -> Bool {
  world.is_changed_by_key(entity, ecs_key_text_font, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_color, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_background_color, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_underline, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_underline_color, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_strikethrough, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_strikethrough_color, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_layout, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_line_height, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_font_hinting, tick) ||
  world.is_changed_by_key(entity, ecs_key_text_shadow, tick) ||
  world.is_changed_by_key(entity, @visibility.ecs_key_view_visibility, tick) ||
  world.is_changed_by_key(entity, @hierarchy.ecs_key_children, tick)
}

///|
pub fn text_ecs_entity_id_set_contains(
  set : @hashset.HashSet[Int],
  entity : @core.Entity,
) -> Bool {
  set.contains(entity.id)
}

///|
pub fn text_ecs_changed_span_parent_ids(
  world : @ecs.World,
  span_edges : Array[(@core.Entity, @core.Entity)],
  tick : @core.SystemTicks,
) -> @hashset.HashSet[Int] {
  let dirty_parent_ids : @hashset.HashSet[Int] = HashSet([])
  for edge in span_edges {
    let (parent, child) = edge
    if world.is_changed_by_key(child, ecs_key_text_span, tick) ||
      world.is_changed_by_key(child, ecs_key_text_font, tick) ||
      world.is_changed_by_key(child, ecs_key_text_color, tick) ||
      world.is_changed_by_key(child, ecs_key_text_background_color, tick) ||
      world.is_changed_by_key(child, ecs_key_text_underline, tick) ||
      world.is_changed_by_key(child, ecs_key_text_underline_color, tick) ||
      world.is_changed_by_key(child, ecs_key_text_strikethrough, tick) ||
      world.is_changed_by_key(child, ecs_key_text_strikethrough_color, tick) ||
      world.is_changed_by_key(child, ecs_key_text_line_height, tick) ||
      world.is_changed_by_key(child, @hierarchy.ecs_key_parent, tick) {
      dirty_parent_ids.add(parent.id)
    }
  }
  dirty_parent_ids
}

///|
pub fn text_ecs_world_entity_ref(
  world : @ecs.World,
  entity : @core.Entity,
) -> @ecs.EntityRef? {
  Some(world.entity(entity)) catch {
    _ => None
  }
}

///|
pub fn[T : @ecs.Component] text_ecs_entity_ref_get(
  entity_ref : @ecs.EntityRef,
) -> T? {
  entity_ref.get() catch {
    _ => None
  }
}

///|
pub fn text_ecs_entity_ref_view_visible(entity_ref : @ecs.EntityRef) -> Bool {
  match (text_ecs_entity_ref_get(entity_ref) : @visibility.ViewVisibility?) {
    Some(view_visibility) => view_visibility.is_visible()
    None => true
  }
}

///|
fn text_ecs_span_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  inherited_font : TextFont,
  inherited_line_height : LineHeight,
) -> TextSpanBundle? {
  guard text_ecs_world_entity_ref(world, entity) is Some(entity_ref) else {
    return None
  }
  let span = match (text_ecs_entity_ref_get(entity_ref) : TextSpan?) {
    Some(span) => span
    None => return None
  }
  let font = match (text_ecs_entity_ref_get(entity_ref) : TextFont?) {
    Some(font) => font
    None => inherited_font
  }
  let color = match (text_ecs_entity_ref_get(entity_ref) : TextColor?) {
    Some(color) => color
    None => TextColor()
  }
  let background_color : TextBackgroundColor? = text_ecs_entity_ref_get(
    entity_ref,
  )
  let underline : Underline? = text_ecs_entity_ref_get(entity_ref)
  let underline_color : UnderlineColor? = text_ecs_entity_ref_get(entity_ref)
  let strikethrough : Strikethrough? = text_ecs_entity_ref_get(entity_ref)
  let strikethrough_color : StrikethroughColor? = text_ecs_entity_ref_get(
    entity_ref,
  )
  let line_height = match (text_ecs_entity_ref_get(entity_ref) : LineHeight?) {
    Some(line_height) => line_height
    None => inherited_line_height
  }
  Some({
    span,
    font,
    color,
    background_color,
    underline,
    underline_color,
    strikethrough,
    strikethrough_color,
    line_height,
  })
}

///|
pub fn text_ecs_collect_span_bundles_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
  font : TextFont,
  line_height : LineHeight,
  span_edges : Array[(@core.Entity, @core.Entity)],
) -> Array[TextSpanBundle] {
  let span_bundles : Array[TextSpanBundle] = []
  let children : @hierarchy.Children? = match
    text_ecs_world_entity_ref(world, entity) {
    Some(entity_ref) => text_ecs_entity_ref_get(entity_ref)
    None => None
  }
  match children {
    Some(children) =>
      for child in children.entities() {
        if text_ecs_span_bundle_from_entity(world, child, font, line_height)
          is Some(span_bundle) {
          span_bundles.push(span_bundle)
        }
      }
    None =>
      for edge in span_edges {
        let parent = edge.0
        let child = edge.1
        if parent != entity {
          continue
        }
        if text_ecs_span_bundle_from_entity(world, child, font, line_height)
          is Some(span_bundle) {
          span_bundles.push(span_bundle)
        }
      }
  }
  span_bundles
}

///|
pub fn text_ecs_collect_span_edges(
  world : @ecs.World,
) -> Array[(@core.Entity, @core.Entity)] {
  let span_edges : Array[(@core.Entity, @core.Entity)] = []
  let query : @ecs.Query[
    (@ecs.Read[TextSpan], @ecs.Read[@hierarchy.Parent]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(child, data) {
    let (_span, parent) = data
    span_edges.push((parent.value().entity(), child))
  })
  span_edges
}

///|
fn ui_text_ecs_find_entry_index(world_id : Int, entity : @core.Entity) -> Int? {
  let count = ui_text_ecs_entries.length()
  for i in 0..<count {
    let entry = ui_text_ecs_entries[i]
    if entry.world_id == world_id && entry.entity == entity {
      return Some(i)
    }
  }
  None
}

///|
fn ui_text_ecs_build_entry_index_by_entity_id(world_id : Int) -> Map[Int, Int] {
  if ui_text_ecs_index_by_world_id.get(world_id) is Some(index_by_entity_id) {
    return index_by_entity_id
  }
  let index_by_entity_id : Map[Int, Int] = Map([])
  let count = ui_text_ecs_entries.length()
  for i in 0..<count {
    let entry = ui_text_ecs_entries[i]
    if entry.world_id == world_id {
      index_by_entity_id.set(entry.entity.id, i)
    }
  }
  ui_text_ecs_index_by_world_id.set(world_id, index_by_entity_id)
  index_by_entity_id
}

///|
fn ui_text_ecs_find_entry_index_from_index(
  world_id : Int,
  entity : @core.Entity,
  index_by_entity_id : Map[Int, Int],
) -> Int? {
  match index_by_entity_id.get(entity.id) {
    Some(index) =>
      if index >= 0 &&
        index < ui_text_ecs_entries.length() &&
        ui_text_ecs_entries[index].world_id == world_id &&
        ui_text_ecs_entries[index].entity == entity {
        Some(index)
      } else {
        ui_text_ecs_find_entry_index(world_id, entity)
      }
    None => None
  }
}

///|
fn ui_text_ecs_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  text : Text,
) -> TextSpawnData {
  guard text_ecs_world_entity_ref(world, entity) is Some(entity_ref) else {
    return {
      content: text.content,
      font: TextFont(),
      color: TextColor(),
      background_color: None,
      underline: None,
      underline_color: None,
      strikethrough: None,
      strikethrough_color: None,
      layout: TextLayout(),
      bounds: TextBounds(),
      line_height: LineHeight::default(),
      font_hinting: FontHinting::default(),
      shadow: None,
      transform: @transform.Transform::identity(),
      layers: RenderLayers(),
      no_frustum_culling: false,
      anchor: @math.Vec2::new(0.0F, 0.0F),
      y_axis: TopToBottom,
      logical_viewport_size: None,
    }
  }
  let font = match (text_ecs_entity_ref_get(entity_ref) : TextFont?) {
    Some(font) => font
    None => TextFont()
  }
  let color = match (text_ecs_entity_ref_get(entity_ref) : TextColor?) {
    Some(color) => color
    None => TextColor()
  }
  let background_color : TextBackgroundColor? = text_ecs_entity_ref_get(
    entity_ref,
  )
  let underline : Underline? = text_ecs_entity_ref_get(entity_ref)
  let underline_color : UnderlineColor? = text_ecs_entity_ref_get(entity_ref)
  let strikethrough : Strikethrough? = text_ecs_entity_ref_get(entity_ref)
  let strikethrough_color : StrikethroughColor? = text_ecs_entity_ref_get(
    entity_ref,
  )
  let layout = match (text_ecs_entity_ref_get(entity_ref) : TextLayout?) {
    Some(layout) => layout
    None => TextLayout()
  }
  let line_height = match (text_ecs_entity_ref_get(entity_ref) : LineHeight?) {
    Some(line_height) => line_height
    None => LineHeight::default()
  }
  let font_hinting = match
    (text_ecs_entity_ref_get(entity_ref) : FontHinting?) {
    Some(font_hinting) => font_hinting
    None => FontHinting::default()
  }
  let shadow_component : TextShadow? = text_ecs_entity_ref_get(entity_ref)
  {
    content: text.content,
    font,
    color,
    background_color,
    underline,
    underline_color,
    strikethrough,
    strikethrough_color,
    layout,
    bounds: TextBounds(),
    line_height,
    font_hinting,
    shadow: shadow_component,
    transform: @transform.Transform::identity(),
    layers: RenderLayers(),
    no_frustum_culling: false,
    anchor: @math.Vec2::new(0.0F, 0.0F),
    y_axis: TopToBottom,
    logical_viewport_size: None,
  }
}

///|
fn ui_text_ecs_spawn_entry(
  world : @ecs.World,
  world_id : Int,
  entity : @core.Entity,
  bundle : TextSpawnData,
  span_bundles : Array[TextSpanBundle],
  view_visible : Bool,
) -> Unit {
  sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn_data(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    handle
  })
  text_set_view_visible(handle, view_visible)
  ui_text_ecs_entries.push({
    world_id,
    entity,
    handle,
    bundle,
    view_visible,
    span_bundles,
  })
  ui_text_ecs_build_entry_index_by_entity_id(world_id).set(
    entity.id,
    ui_text_ecs_entries.length() - 1,
  )
}

///|
fn ui_text_ecs_remove_entry_at_index(
  index : Int,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  let last_index = ui_text_ecs_entries.length() - 1
  let removed_entry = ui_text_ecs_entries[index]
  ignore(text_despawn(removed_entry.handle))
  if index != last_index {
    let moved_entry = ui_text_ecs_entries[last_index]
    ui_text_ecs_entries[index] = moved_entry
    index_by_entity_id.set(moved_entry.entity.id, index)
  }
  ignore(ui_text_ecs_entries.pop())
  ignore(index_by_entity_id.remove(removed_entry.entity.id))
}

///|
fn ui_text_ecs_cleanup_removed_entity(
  world_id : Int,
  entity : @core.Entity,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  match
    ui_text_ecs_find_entry_index_from_index(
      world_id, entity, index_by_entity_id,
    ) {
    Some(index) => ui_text_ecs_remove_entry_at_index(index, index_by_entity_id)
    None => ()
  }
}

///|
fn ui_text_ecs_cleanup_removed_entries(
  world : @ecs.World,
  world_id : Int,
  tick : @core.SystemTicks,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  for entity in world.removed_components(ecs_key_text, tick).read() {
    ui_text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
}

///|
fn ui_text_ecs_respawn_entry(
  world : @ecs.World,
  entry : UiEcsTextEntry,
  bundle : TextSpawnData,
  span_bundles : Array[TextSpanBundle],
  view_visible : Bool,
) -> UiEcsTextEntry {
  ignore(text_despawn(entry.handle))
  sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn_data(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    handle
  })
  text_set_view_visible(handle, view_visible)
  { ..entry, handle, bundle, view_visible, span_bundles }
}

///|
fn ui_text_ecs_sync_existing_entry(
  world : @ecs.World,
  entry : UiEcsTextEntry,
  bundle : TextSpawnData,
  span_bundles : Array[TextSpanBundle],
  view_visible : Bool,
) -> UiEcsTextEntry {
  sync_text_runtime_rem_size(world)
  let handle = entry.handle
  if text_get_transform(handle) is None {
    return ui_text_ecs_respawn_entry(
      world, entry, bundle, span_bundles, view_visible,
    )
  }
  if !text_span_bundle_array_eq(entry.span_bundles, span_bundles) {
    return ui_text_ecs_respawn_entry(
      world, entry, bundle, span_bundles, view_visible,
    )
  }
  if entry.view_visible != view_visible {
    text_set_view_visible(handle, view_visible)
  }
  let needs_layout = !text_spawn_data_rerender_eq(entry.bundle, bundle)
  if entry.bundle.content != bundle.content {
    text_set_content(handle, bundle.content)
  }
  if !text_font_eq(entry.bundle.font, bundle.font) {
    text_set_font(handle, bundle.font)
  }
  if !text_color_eq(entry.bundle.color, bundle.color) {
    text_set_color(handle, bundle.color)
  }
  if !text_background_color_eq(
      entry.bundle.background_color,
      bundle.background_color,
    ) {
    text_set_background_color(handle, bundle.background_color)
  }
  if !empty_marker_opt_eq(entry.bundle.underline, bundle.underline) {
    text_set_underline(handle, bundle.underline)
  }
  if !empty_marker_opt_eq(entry.bundle.strikethrough, bundle.strikethrough) {
    text_set_strikethrough(handle, bundle.strikethrough)
  }
  if !text_layout_eq(entry.bundle.layout, bundle.layout) {
    text_set_layout(handle, bundle.layout)
  }
  if !line_height_eq(entry.bundle.line_height, bundle.line_height) {
    text_set_line_height(handle, bundle.line_height)
  }
  if !font_hinting_eq(entry.bundle.font_hinting, bundle.font_hinting) {
    text_set_font_hinting(handle, bundle.font_hinting)
  }
  if !text_component_shadow_eq(entry.bundle.shadow, bundle.shadow) {
    text_set_text_shadow(handle, bundle.shadow)
  }
  if !vec2_opt_eq(
      entry.bundle.logical_viewport_size,
      bundle.logical_viewport_size,
    ) {
    text_set_logical_viewport_size(handle, bundle.logical_viewport_size)
  }
  ignore(needs_layout)
  { ..entry, bundle, view_visible, span_bundles }
}

///|
pub fn ui_text_ecs_handle(
  world : @ecs.World,
  entity : @core.Entity,
) -> TextHandle? {
  match ui_text_ecs_find_entry_index(world.world_id(), entity) {
    Some(index) => Some(ui_text_ecs_entries[index].handle)
    None => None
  }
}

///|
pub fn ui_text_sync_ecs_system(world : @ecs.World) -> Unit {
  text_ecs_sync_candidate_entity_count.val = 0
  prepare_text_runtime_world(world)
  let world_id = world.world_id()
  let index_by_entity_id = ui_text_ecs_build_entry_index_by_entity_id(world_id)
  let tick = world.get_tick_context().ticks()
  ui_text_ecs_cleanup_removed_entries(world, world_id, tick, index_by_entity_id)
  let span_edges = text_ecs_collect_span_edges(world)
  let changed_span_parent_ids = text_ecs_changed_span_parent_ids(
    world, span_edges, tick,
  )
  let query : @ecs.Query[@ecs.Read[Text], @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, text) {
    text_ecs_sync_candidate_entity_count.val = text_ecs_sync_candidate_entity_count.val +
      1
    let existing_index = ui_text_ecs_find_entry_index_from_index(
      world_id, entity, index_by_entity_id,
    )
    if existing_index is Some(_) &&
      !text.is_changed() &&
      !text_ecs_ui_root_is_changed(world, entity, tick) &&
      !text_ecs_entity_id_set_contains(changed_span_parent_ids, entity) {
      return
    }
    let bundle = ui_text_ecs_bundle_from_entity(world, entity, text.value())
    let view_visible = match text_ecs_world_entity_ref(world, entity) {
      Some(entity_ref) => text_ecs_entity_ref_view_visible(entity_ref)
      None => true
    }
    let span_bundles = text_ecs_collect_span_bundles_for_entity(
      world,
      entity,
      bundle.font,
      bundle.line_height,
      span_edges,
    )
    match existing_index {
      Some(index) => {
        let entry = ui_text_ecs_entries[index]
        ui_text_ecs_entries[index] = ui_text_ecs_sync_existing_entry(
          world, entry, bundle, span_bundles, view_visible,
        )
      }
      None => {
        ui_text_ecs_spawn_entry(
          world, world_id, entity, bundle, span_bundles, view_visible,
        )
        index_by_entity_id.set(entity.id, ui_text_ecs_entries.length() - 1)
      }
    }
  })
}
