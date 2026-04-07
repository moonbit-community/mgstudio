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
pub let ecs_key_text2d : @ecs.ComponentKey[Text2d] = @ecs.register_component(
  debug_name="text.text2d",
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
pub let ecs_key_text2d_shadow : @ecs.ComponentKey[Text2dShadow] = @ecs.register_component(
  debug_name="text.text_2d_shadow",
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
pub impl @ecs.Component for Text with component() {
  ecs_key_text
}

///|
pub impl @ecs.Component for Text2d with component() {
  ecs_key_text2d
}

///|
pub impl @ecs.Component for TextSpan with component() {
  ecs_key_text_span
}

///|
pub impl @ecs.Component for TextFont with component() {
  ecs_key_text_font
}

///|
pub impl @ecs.Component for TextColor with component() {
  ecs_key_text_color
}

///|
pub impl @ecs.Component for TextBackgroundColor with component() {
  ecs_key_text_background_color
}

///|
pub impl @ecs.Component for UnderlineColor with component() {
  ecs_key_text_underline_color
}

///|
pub impl @ecs.Component for Underline with component() {
  ecs_key_text_underline
}

///|
pub impl @ecs.Component for StrikethroughColor with component() {
  ecs_key_text_strikethrough_color
}

///|
pub impl @ecs.Component for Strikethrough with component() {
  ecs_key_text_strikethrough
}

///|
pub impl @ecs.Component for TextLayout with component() {
  ecs_key_text_layout
}

///|
pub impl @ecs.Component for TextBounds with component() {
  ecs_key_text_bounds
}

///|
pub impl @ecs.Component for LineHeight with component() {
  ecs_key_text_line_height
}

///|
pub impl @ecs.Component for Text2dShadow with component() {
  ecs_key_text2d_shadow
}

///|
pub impl @ecs.Component for TextShadow with component() {
  ecs_key_text_shadow
}

///|
pub impl @ecs.Component for YAxisOrientation with component() {
  ecs_key_text_y_axis
}

///|
pub impl @app.Resource for RemSize with resource() {
  ecs_res_key_rem_size
}

///|
pub impl @app.Resource for FontCx with resource() {
  ecs_res_key_font_cx
}

///|
pub impl @app.Resource for FontAtlasSet with resource() {
  ecs_res_key_font_atlas_set
}

///|
priv struct EcsTextBridgeEntry {
  world_id : Int
  entity : @core.Entity
  handle : TextHandle
  bundle : Text2dBundle
  view_visible : Bool
  span_bundles : Array[TextSpanBundle]
}

///|
let text_ecs_bridge_entries : Array[EcsTextBridgeEntry] = []

///|
let text_ecs_bridge_index_by_world_id_ref : Ref[Map[Int, Map[Int, Int]]] = Ref::new({},
)

///|
priv struct UiEcsTextBridgeEntry {
  world_id : Int
  entity : @core.Entity
  handle : TextHandle
  bundle : Text2dBundle
  span_bundles : Array[TextSpanBundle]
}

///|
let ui_text_ecs_bridge_entries : Array[UiEcsTextBridgeEntry] = []

///|
let ui_text_ecs_bridge_index_by_world_id_ref : Ref[Map[Int, Map[Int, Int]]] = Ref::new({},
)

///|
let text_runtime_world_id_ref : Ref[Int?] = Ref::new(None)

///|
let text_diagnostic_sync_ecs_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
let text_diagnostic_sync_ecs_dirty_entity_count_ref : Ref[Int] = Ref::new(0)

///|
let text_diagnostic_sync_ecs_early_return_ref : Ref[Bool] = Ref::new(false)

///|
fn reset_text_runtime_state() -> Unit {
  text_state.val.next_text_id = 0
  text_state.val.next_span_id = 0
  text_state_clear_instances()
  text_debug_frame_state.val.draws.clear()
  text_ecs_bridge_entries.clear()
  text_ecs_bridge_index_by_world_id_ref.val.clear()
  ui_text_ecs_bridge_entries.clear()
  ui_text_ecs_bridge_index_by_world_id_ref.val.clear()
  font_atlas_set_state.val = FontAtlasSet::default()
  default_text_font_handle_ref.val = None
  cosmic_font_system_state.val = CosmicFontSystemState::{
    font_system: @cosmic.FontSystem::new(),
    handle_to_font_id: [],
    font_id_to_handle_id: [],
    handle_to_family: [],
  }
  swash_font_cache.val.entries.clear()
  cosmic_swash_cache.val = @cosmic.SwashCache::new()
}

///|
fn prepare_text_runtime_world(world : @ecs.World) -> Unit {
  let world_id = world.world_id()
  if text_runtime_world_id_ref.val == Some(world_id) {
    return
  }
  text_runtime_world_id_ref.val = Some(world_id)
  reset_text_runtime_state()
}

///|
pub fn text_reset_runtime_state_for_tests() -> Unit {
  text_runtime_world_id_ref.val = None
  reset_text_runtime_state()
}

///|
fn register_text_required_components(
  world : @ecs.World,
) -> Unit raise @ecs.RequiredComponentsError {
  world.register_required_components_with(ecs_key_text2d, ecs_key_text_layout, fn() {
    TextLayout::default()
  })
  world.register_required_components_with(ecs_key_text2d, ecs_key_text_font, fn() {
    TextFont::default()
  })
  world.register_required_components_with(ecs_key_text2d, ecs_key_text_color, fn() {
    TextColor::default()
  })
  world.register_required_components_with(
    ecs_key_text2d,
    ecs_key_text_line_height,
    fn() { LineHeight::default() },
  )
  world.register_required_components_with(ecs_key_text2d, ecs_key_text_bounds, fn() {
    TextBounds::default()
  })
  world.register_required_components_with(
    ecs_key_text2d,
    @sprite.ecs_key_anchor,
    fn() { @sprite.Anchor::default() },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @visibility.ecs_key_visibility,
    fn() { @visibility.Visibility::Inherited },
  )
  world.register_required_components_with(
    ecs_key_text2d,
    @transform.ecs_key_transform,
    fn() { @transform.Transform::identity() },
  )
}

///|
fn sync_text_runtime_rem_size(world : @ecs.World) -> Unit {
  let rem_size = match world.resource(RemSize::resource()).get() {
    Some(value) => value.value()
    None => RemSize::default().value()
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
fn color_eq(lhs : @sprite.Color, rhs : @sprite.Color) -> Bool {
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
fn transform_eq(lhs : @transform.Transform, rhs : @transform.Transform) -> Bool {
  vec3_eq(lhs.translation, rhs.translation) &&
  quat_eq(lhs.rotation, rhs.rotation) &&
  vec3_eq(lhs.scale, rhs.scale)
}

///|
fn render_layers_eq(
  lhs : @sprite.RenderLayers,
  rhs : @sprite.RenderLayers,
) -> Bool {
  lhs.mask == rhs.mask
}

///|
fn anchor_eq(lhs : @sprite.Anchor, rhs : @sprite.Anchor) -> Bool {
  vec2_eq(lhs.value, rhs.value)
}

///|
fn vec2_opt_eq(lhs : @math.Vec2?, rhs : @math.Vec2?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => vec2_eq(lhs, rhs)
    (None, None) => true
    _ => false
  }
}

///|
fn font_smoothing_eq(lhs : FontSmoothing, rhs : FontSmoothing) -> Bool {
  match (lhs, rhs) {
    (FontSmoothing::None, FontSmoothing::None) => true
    (FontSmoothing::AntiAliased, FontSmoothing::AntiAliased) => true
    _ => false
  }
}

///|
fn text2d_eq(lhs : Text2d, rhs : Text2d) -> Bool {
  lhs.content == rhs.content
}

///|
fn text_span_eq(lhs : TextSpan, rhs : TextSpan) -> Bool {
  lhs.content == rhs.content
}

///|
fn font_source_eq(lhs : FontSource, rhs : FontSource) -> Bool {
  match (lhs, rhs) {
    (FontSource::Handle(lhs), FontSource::Handle(rhs)) => lhs.id() == rhs.id()
    (FontSource::Family(lhs), FontSource::Family(rhs)) => lhs == rhs
    (FontSource::Serif, FontSource::Serif) => true
    (FontSource::SansSerif, FontSource::SansSerif) => true
    (FontSource::Cursive, FontSource::Cursive) => true
    (FontSource::Fantasy, FontSource::Fantasy) => true
    (FontSource::Monospace, FontSource::Monospace) => true
    (FontSource::SystemUi, FontSource::SystemUi) => true
    (FontSource::UiSerif, FontSource::UiSerif) => true
    (FontSource::UiSansSerif, FontSource::UiSansSerif) => true
    (FontSource::UiMonospace, FontSource::UiMonospace) => true
    (FontSource::UiRounded, FontSource::UiRounded) => true
    (FontSource::Emoji, FontSource::Emoji) => true
    (FontSource::Math, FontSource::Math) => true
    (FontSource::FangSong, FontSource::FangSong) => true
    _ => false
  }
}

///|
fn font_size_eq(lhs : FontSize, rhs : FontSize) -> Bool {
  match (lhs, rhs) {
    (FontSize::Px(lhs), FontSize::Px(rhs)) => lhs == rhs
    (FontSize::Vw(lhs), FontSize::Vw(rhs)) => lhs == rhs
    (FontSize::Vh(lhs), FontSize::Vh(rhs)) => lhs == rhs
    (FontSize::VMin(lhs), FontSize::VMin(rhs)) => lhs == rhs
    (FontSize::VMax(lhs), FontSize::VMax(rhs)) => lhs == rhs
    (FontSize::Rem(lhs), FontSize::Rem(rhs)) => lhs == rhs
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
    (FontStyle::Normal, FontStyle::Normal) => true
    (FontStyle::Italic, FontStyle::Italic) => true
    (FontStyle::Oblique(lhs), FontStyle::Oblique(rhs)) => float_opt_eq(lhs, rhs)
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
fn text_font_eq(lhs : TextFont, rhs : TextFont) -> Bool {
  font_source_eq(lhs.font, rhs.font) &&
  font_size_eq(lhs.font_size, rhs.font_size) &&
  font_weight_eq(lhs.weight, rhs.weight) &&
  font_width_eq(lhs.width, rhs.width) &&
  font_style_eq(lhs.style, rhs.style) &&
  font_features_eq(lhs.font_features, rhs.font_features) &&
  font_smoothing_eq(lhs.font_smoothing, rhs.font_smoothing)
}

///|
fn text_color_eq(lhs : TextColor, rhs : TextColor) -> Bool {
  color_eq(lhs.color, rhs.color)
}

///|
fn text_background_color_eq(
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
fn underline_color_eq(lhs : UnderlineColor?, rhs : UnderlineColor?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => color_eq(lhs.color, rhs.color)
    (None, None) => true
    _ => false
  }
}

///|
fn strikethrough_color_eq(
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
fn[A] empty_marker_opt_eq(lhs : A?, rhs : A?) -> Bool {
  match (lhs, rhs) {
    (Some(_), Some(_)) => true
    (None, None) => true
    _ => false
  }
}

///|
fn justify_eq(lhs : Justify, rhs : Justify) -> Bool {
  match (lhs, rhs) {
    (Justify::Left, Justify::Left) => true
    (Justify::Center, Justify::Center) => true
    (Justify::Right, Justify::Right) => true
    (Justify::Justified, Justify::Justified) => true
    _ => false
  }
}

///|
fn line_break_eq(lhs : LineBreak, rhs : LineBreak) -> Bool {
  match (lhs, rhs) {
    (LineBreak::WordBoundary, LineBreak::WordBoundary) => true
    (LineBreak::AnyCharacter, LineBreak::AnyCharacter) => true
    (LineBreak::WordOrCharacter, LineBreak::WordOrCharacter) => true
    (LineBreak::NoWrap, LineBreak::NoWrap) => true
    _ => false
  }
}

///|
fn text_layout_eq(lhs : TextLayout, rhs : TextLayout) -> Bool {
  justify_eq(lhs.justify, rhs.justify) &&
  line_break_eq(lhs.linebreak, rhs.linebreak)
}

///|
fn line_height_eq(lhs : LineHeight, rhs : LineHeight) -> Bool {
  match (lhs, rhs) {
    (LineHeight::Px(lhs), LineHeight::Px(rhs)) => lhs == rhs
    (LineHeight::RelativeToFont(lhs), LineHeight::RelativeToFont(rhs)) =>
      lhs == rhs
    _ => false
  }
}

///|
fn text_bounds_eq(lhs : TextBounds, rhs : TextBounds) -> Bool {
  float_opt_eq(lhs.width, rhs.width) && float_opt_eq(lhs.height, rhs.height)
}

///|
fn text_shadow_eq(lhs : Text2dShadow?, rhs : Text2dShadow?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) =>
      vec2_eq(lhs.offset, rhs.offset) && color_eq(lhs.color, rhs.color)
    (None, None) => true
    _ => false
  }
}

///|
fn text_shadow_component_to_2d(shadow : TextShadow?) -> Text2dShadow? {
  match shadow {
    Some(shadow) => Some(Text2dShadow::new(shadow.offset, shadow.color))
    None => None
  }
}

///|
fn y_axis_eq(lhs : YAxisOrientation, rhs : YAxisOrientation) -> Bool {
  match (lhs, rhs) {
    (YAxisOrientation::TopToBottom, YAxisOrientation::TopToBottom) => true
    (YAxisOrientation::BottomToTop, YAxisOrientation::BottomToTop) => true
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
fn text_span_bundle_array_eq(
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
fn text_bundle_rerender_eq(lhs : Text2dBundle, rhs : Text2dBundle) -> Bool {
  text2d_eq(lhs.text, rhs.text) &&
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
  text_shadow_eq(lhs.shadow, rhs.shadow) &&
  y_axis_eq(lhs.y_axis, rhs.y_axis) &&
  vec2_opt_eq(lhs.logical_viewport_size, rhs.logical_viewport_size)
}

///|
fn text_ecs_find_entry_index(world_id : Int, entity : @core.Entity) -> Int? {
  let count = text_ecs_bridge_entries.length()
  for i in 0..<count {
    let entry = text_ecs_bridge_entries[i]
    if entry.world_id == world_id && entry.entity == entity {
      return Some(i)
    }
  }
  None
}

///|
fn text_ecs_build_entry_index_by_entity_id(world_id : Int) -> Map[Int, Int] {
  if text_ecs_bridge_index_by_world_id_ref.val.get(world_id)
    is Some(index_by_entity_id) {
    return index_by_entity_id
  }
  let index_by_entity_id : Map[Int, Int] = {}
  let count = text_ecs_bridge_entries.length()
  for i in 0..<count {
    let entry = text_ecs_bridge_entries[i]
    if entry.world_id == world_id {
      index_by_entity_id.set(entry.entity.id, i)
    }
  }
  text_ecs_bridge_index_by_world_id_ref.val.set(world_id, index_by_entity_id)
  index_by_entity_id
}

///|
fn[T] text_ecs_union_changed_entities_into(
  world : @ecs.World,
  key : @ecs.ComponentKey[T],
  sequence : @core.SystemSequence,
  dirty_entities : Map[Int, Bool],
  has_text_dirty_entities : Ref[Bool],
) -> Bool {
  let mut has_any = false
  for entity in world.changed_components(key, sequence).read() {
    has_any = true
    dirty_entities.set(entity.id, true)
    if !has_text_dirty_entities.val {
      let is_text_entity = world.contains_by_key(entity, ecs_key_text2d) catch {
        _ => false
      }
      if is_text_entity {
        has_text_dirty_entities.val = true
      }
    }
  }
  has_any
}

///|
fn text_ecs_entity_id_set_contains(
  set : Map[Int, Bool],
  entity : @core.Entity,
) -> Bool {
  set.get(entity.id) is Some(_)
}

///|
fn text_ecs_mark_span_parents_dirty(
  span_edges : Array[(@core.Entity, @core.Entity)],
  dirty_entities : Map[Int, Bool],
  has_text_dirty_entities : Ref[Bool],
) -> Unit {
  for edge in span_edges {
    let (parent, child) = edge
    if !dirty_entities.contains(child.id) {
      continue
    }
    if !dirty_entities.contains(parent.id) {
      dirty_entities.set(parent.id, true)
    }
    has_text_dirty_entities.val = true
  }
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
        index < text_ecs_bridge_entries.length() &&
        text_ecs_bridge_entries[index].world_id == world_id &&
        text_ecs_bridge_entries[index].entity == entity {
        Some(index)
      } else {
        text_ecs_find_entry_index(world_id, entity)
      }
    None => None
  }
}

///|
fn text_ecs_world_entity_ref(
  world : @ecs.World,
  entity : @core.Entity,
) -> @ecs.EntityRef? {
  Some(world.entity(entity)) catch {
    _ => None
  }
}

///|
fn[T : @ecs.Component] text_ecs_entity_ref_get(
  entity_ref : @ecs.EntityRef,
) -> T? {
  entity_ref.get() catch {
    _ => None
  }
}

///|
fn text_ecs_entity_ref_view_visible(entity_ref : @ecs.EntityRef) -> Bool {
  match (text_ecs_entity_ref_get(entity_ref) : @visibility.ViewVisibility?) {
    Some(view_visibility) => view_visibility.is_visible()
    None => true
  }
}

///|
fn text_ecs_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  text : Text2d,
  font : TextFont,
  local_transform : @transform.Transform,
) -> (Text2dBundle, Bool) {
  guard text_ecs_world_entity_ref(world, entity) is Some(entity_ref) else {
    return (
      Text2dBundle::{
        text,
        font,
        color: TextColor::default(),
        background_color: None,
        underline: None,
        underline_color: None,
        strikethrough: None,
        strikethrough_color: None,
        layout: TextLayout::default(),
        bounds: TextBounds::default(),
        line_height: LineHeight::default(),
        shadow: None,
        transform: local_transform,
        layers: @sprite.RenderLayers::default(),
        no_frustum_culling: false,
        anchor: @sprite.Anchor::default(),
        y_axis: YAxisOrientation::TopToBottom,
        logical_viewport_size: None,
      },
      true,
    )
  }
  let transform = match
    (text_ecs_entity_ref_get(entity_ref) : @transform.GlobalTransform?) {
    Some(global_transform) => global_transform.to_transform_approx()
    None => local_transform
  }
  let color = match (text_ecs_entity_ref_get(entity_ref) : TextColor?) {
    Some(color) => color
    None => TextColor::default()
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
    None => TextLayout::default()
  }
  let bounds = match (text_ecs_entity_ref_get(entity_ref) : TextBounds?) {
    Some(bounds) => bounds
    None => TextBounds::default()
  }
  let line_height = match (text_ecs_entity_ref_get(entity_ref) : LineHeight?) {
    Some(line_height) => line_height
    None => LineHeight::default()
  }
  let shadow : Text2dShadow? = text_ecs_entity_ref_get(entity_ref)
  let layers = match
    (text_ecs_entity_ref_get(entity_ref) : @sprite.RenderLayers?) {
    Some(layers) => layers
    None => @sprite.RenderLayers::default()
  }
  let anchor = match (text_ecs_entity_ref_get(entity_ref) : @sprite.Anchor?) {
    Some(anchor) => anchor
    None => @sprite.Anchor::default()
  }
  let y_axis = match (text_ecs_entity_ref_get(entity_ref) : YAxisOrientation?) {
    Some(y_axis) => y_axis
    None => YAxisOrientation::TopToBottom
  }
  let no_frustum_culling = world.contains_by_key(
    entity, @visibility.ecs_key_no_frustum_culling,
  ) catch {
    _ => false
  }
  (
    Text2dBundle::{
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
      shadow,
      transform,
      layers,
      no_frustum_culling,
      anchor,
      y_axis,
      logical_viewport_size: None,
    },
    text_ecs_entity_ref_view_visible(entity_ref),
  )
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
    None => TextColor::default()
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
  Some(TextSpanBundle::{
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
fn text_ecs_collect_span_bundles_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
  bundle : Text2dBundle,
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
        if text_ecs_span_bundle_from_entity(
            world,
            child,
            bundle.font,
            bundle.line_height,
          )
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
        if text_ecs_span_bundle_from_entity(
            world,
            child,
            bundle.font,
            bundle.line_height,
          )
          is Some(span_bundle) {
          span_bundles.push(span_bundle)
        }
      }
  }
  span_bundles
}

///|
fn text_ecs_collect_span_edges(
  world : @ecs.World,
) -> Array[(@core.Entity, @core.Entity)] {
  let span_edges : Array[(@core.Entity, @core.Entity)] = []
  let query : @ecs.Query[
    (@ecs.Comp[TextSpan], @ecs.Comp[@hierarchy.Parent]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(child, data) {
    let (_span, parent) = data
    span_edges.push((parent.value().entity(), child))
  })
  span_edges
}

///|
fn text_ecs_spawn_entry(
  world : @ecs.World,
  world_id : Int,
  entity : @core.Entity,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
  view_visible : Bool,
) -> Unit {
  sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    handle
  })
  text_set_view_visible(handle, view_visible)
  text_ecs_bridge_entries.push(EcsTextBridgeEntry::{
    world_id,
    entity,
    handle,
    bundle,
    view_visible,
    span_bundles,
  })
  text_ecs_build_entry_index_by_entity_id(world_id).set(
    entity.id,
    text_ecs_bridge_entries.length() - 1,
  )
}

///|
fn text_ecs_remove_entry_at_index(
  index : Int,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  let last_index = text_ecs_bridge_entries.length() - 1
  let removed_entry = text_ecs_bridge_entries[index]
  ignore(text_despawn(removed_entry.handle))
  if index != last_index {
    let moved_entry = text_ecs_bridge_entries[last_index]
    text_ecs_bridge_entries[index] = moved_entry
    index_by_entity_id.set(moved_entry.entity.id, index)
  }
  ignore(text_ecs_bridge_entries.pop())
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
  sequence : @core.SystemSequence,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  for entity in world.removed_components(ecs_key_text2d, sequence).read() {
    text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
  for entity in world.removed_components(ecs_key_text_font, sequence).read() {
    text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
  for
    entity in world
    .removed_components(@transform.ecs_key_transform, sequence)
    .read() {
    text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
}

///|
fn text_ecs_respawn_entry(
  world : @ecs.World,
  entry : EcsTextBridgeEntry,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
  view_visible : Bool,
) -> EcsTextBridgeEntry {
  ignore(text_despawn(entry.handle))
  sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    handle
  })
  text_set_view_visible(handle, view_visible)
  EcsTextBridgeEntry::{ ..entry, handle, bundle, view_visible, span_bundles }
}

///|
fn text_ecs_sync_existing_entry(
  world : @ecs.World,
  entry : EcsTextBridgeEntry,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
  view_visible : Bool,
) -> EcsTextBridgeEntry {
  sync_text_runtime_rem_size(world)
  let handle = entry.handle
  if text_get_transform(handle) is None {
    return text_ecs_respawn_entry(
      world, entry, bundle, span_bundles, view_visible,
    )
  }
  if !text_span_bundle_array_eq(entry.span_bundles, span_bundles) {
    return text_ecs_respawn_entry(
      world, entry, bundle, span_bundles, view_visible,
    )
  }
  if entry.view_visible != view_visible {
    text_set_view_visible(handle, view_visible)
  }
  if !text2d_eq(entry.bundle.text, bundle.text) {
    text_set_content(handle, bundle.text.content)
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
  if !underline_color_eq(entry.bundle.underline_color, bundle.underline_color) {
    text_set_underline_color(handle, bundle.underline_color)
  }
  if !empty_marker_opt_eq(entry.bundle.strikethrough, bundle.strikethrough) {
    text_set_strikethrough(handle, bundle.strikethrough)
  }
  if !strikethrough_color_eq(
      entry.bundle.strikethrough_color,
      bundle.strikethrough_color,
    ) {
    text_set_strikethrough_color(handle, bundle.strikethrough_color)
  }
  if !text_layout_eq(entry.bundle.layout, bundle.layout) {
    text_set_layout(handle, bundle.layout)
  }
  if !text_bounds_eq(entry.bundle.bounds, bundle.bounds) {
    text_set_bounds(handle, bundle.bounds)
  }
  if !line_height_eq(entry.bundle.line_height, bundle.line_height) {
    text_set_line_height(handle, bundle.line_height)
  }
  if !text_shadow_eq(entry.bundle.shadow, bundle.shadow) {
    text_set_shadow(handle, bundle.shadow)
  }
  if !transform_eq(entry.bundle.transform, bundle.transform) {
    text_set_transform(handle, bundle.transform)
  }
  if !render_layers_eq(entry.bundle.layers, bundle.layers) {
    text_set_layers(handle, bundle.layers)
  }
  if entry.bundle.no_frustum_culling != bundle.no_frustum_culling {
    text_set_no_frustum_culling(handle, bundle.no_frustum_culling)
  }
  if !anchor_eq(entry.bundle.anchor, bundle.anchor) {
    text_set_anchor(handle, bundle.anchor)
  }
  if !y_axis_eq(entry.bundle.y_axis, bundle.y_axis) {
    text_set_y_axis(handle, bundle.y_axis)
  }
  if !vec2_opt_eq(
      entry.bundle.logical_viewport_size,
      bundle.logical_viewport_size,
    ) {
    text_set_logical_viewport_size(handle, bundle.logical_viewport_size)
  }
  EcsTextBridgeEntry::{ ..entry, bundle, view_visible, span_bundles }
}

///|
fn text_sync_ecs_system(world : @ecs.World) -> Unit {
  let sync_start = @time.host_time_now()
  text_diagnostic_sync_ecs_early_return_ref.val = false
  text_diagnostic_sync_ecs_dirty_entity_count_ref.val = 0
  prepare_text_runtime_world(world)
  let world_id = world.world_id()
  let index_by_entity_id = text_ecs_build_entry_index_by_entity_id(world_id)
  let sequence = world.get_sequence_context().sequence()
  text_ecs_cleanup_removed_entries(
    world, world_id, sequence, index_by_entity_id,
  )
  let span_edges = text_ecs_collect_span_edges(world)
  let has_any_spans = span_edges.length() > 0
  let dirty_entities : Map[Int, Bool] = {}
  let has_text_dirty_entities = Ref::new(false)
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text2d, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_font, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, @transform.ecs_key_transform, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, @transform.ecs_key_global_transform, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_background_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_underline, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_underline_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_strikethrough, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_strikethrough_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_layout, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_bounds, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_line_height, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text2d_shadow, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, @sprite.ecs_key_render_layers, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, @sprite.ecs_key_anchor, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_y_axis, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, @visibility.ecs_key_view_visibility, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  if has_any_spans {
    ignore(
      text_ecs_union_changed_entities_into(
        world, @hierarchy.ecs_key_children, sequence, dirty_entities, has_text_dirty_entities,
      ),
    )
    ignore(
      text_ecs_union_changed_entities_into(
        world, @hierarchy.ecs_key_parent, sequence, dirty_entities, has_text_dirty_entities,
      ),
    )
    ignore(
      text_ecs_union_changed_entities_into(
        world, ecs_key_text_span, sequence, dirty_entities, has_text_dirty_entities,
      ),
    )
    text_ecs_mark_span_parents_dirty(
      span_edges, dirty_entities, has_text_dirty_entities,
    )
  }
  if !has_text_dirty_entities.val && text_ecs_bridge_entries.length() > 0 {
    text_diagnostic_sync_ecs_early_return_ref.val = true
    text_diagnostic_sync_ecs_cpu_ms_ref.val = (
        @time.host_time_now() - sync_start
      ) *
      1000.0F
    return
  }
  text_diagnostic_sync_ecs_dirty_entity_count_ref.val = dirty_entities.length()
  let query : @ecs.Query[
    (@ecs.Comp[Text2d], @ecs.Comp[TextFont], @ecs.Comp[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let existing_index = text_ecs_find_entry_index_from_index(
      world_id, entity, index_by_entity_id,
    )
    if existing_index is Some(_) {
      if !text_ecs_entity_id_set_contains(dirty_entities, entity) {
        return
      }
    }
    let (text, font, local_transform) = data
    let (bundle, view_visible) = text_ecs_bundle_from_entity(
      world,
      entity,
      text.value(),
      font.value(),
      local_transform.value(),
    )
    let span_bundles = if has_any_spans {
      text_ecs_collect_span_bundles_for_entity(
        world, entity, bundle, span_edges,
      )
    } else {
      []
    }
    match existing_index {
      Some(index) => {
        let entry = text_ecs_bridge_entries[index]
        text_ecs_bridge_entries[index] = text_ecs_sync_existing_entry(
          world, entry, bundle, span_bundles, view_visible,
        )
      }
      None => {
        text_ecs_spawn_entry(
          world, world_id, entity, bundle, span_bundles, view_visible,
        )
        index_by_entity_id.set(entity.id, text_ecs_bridge_entries.length() - 1)
      }
    }
  })
  text_diagnostic_sync_ecs_cpu_ms_ref.val = (@time.host_time_now() - sync_start) *
    1000.0F
}

///|
pub fn text_diagnostic_sync_ecs_cpu_ms() -> Float {
  text_diagnostic_sync_ecs_cpu_ms_ref.val
}

///|
pub fn text_diagnostic_sync_ecs_dirty_entity_count() -> Int {
  text_diagnostic_sync_ecs_dirty_entity_count_ref.val
}

///|
pub fn text_diagnostic_sync_ecs_early_return() -> Bool {
  text_diagnostic_sync_ecs_early_return_ref.val
}

///|
fn ui_text_ecs_find_entry_index(world_id : Int, entity : @core.Entity) -> Int? {
  let count = ui_text_ecs_bridge_entries.length()
  for i in 0..<count {
    let entry = ui_text_ecs_bridge_entries[i]
    if entry.world_id == world_id && entry.entity == entity {
      return Some(i)
    }
  }
  None
}

///|
fn ui_text_ecs_build_entry_index_by_entity_id(world_id : Int) -> Map[Int, Int] {
  if ui_text_ecs_bridge_index_by_world_id_ref.val.get(world_id)
    is Some(index_by_entity_id) {
    return index_by_entity_id
  }
  let index_by_entity_id : Map[Int, Int] = {}
  let count = ui_text_ecs_bridge_entries.length()
  for i in 0..<count {
    let entry = ui_text_ecs_bridge_entries[i]
    if entry.world_id == world_id {
      index_by_entity_id.set(entry.entity.id, i)
    }
  }
  ui_text_ecs_bridge_index_by_world_id_ref.val.set(world_id, index_by_entity_id)
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
        index < ui_text_ecs_bridge_entries.length() &&
        ui_text_ecs_bridge_entries[index].world_id == world_id &&
        ui_text_ecs_bridge_entries[index].entity == entity {
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
) -> Text2dBundle {
  guard text_ecs_world_entity_ref(world, entity) is Some(entity_ref) else {
    return Text2dBundle::{
      text: Text2d::new(text.content),
      font: TextFont::default(),
      color: TextColor::default(),
      background_color: None,
      underline: None,
      underline_color: None,
      strikethrough: None,
      strikethrough_color: None,
      layout: TextLayout::default(),
      bounds: TextBounds::default(),
      line_height: LineHeight::default(),
      shadow: None,
      transform: @transform.Transform::identity(),
      layers: @sprite.RenderLayers::default(),
      no_frustum_culling: false,
      anchor: @sprite.Anchor::default(),
      y_axis: YAxisOrientation::TopToBottom,
      logical_viewport_size: None,
    }
  }
  let font = match (text_ecs_entity_ref_get(entity_ref) : TextFont?) {
    Some(font) => font
    None => TextFont::default()
  }
  let color = match (text_ecs_entity_ref_get(entity_ref) : TextColor?) {
    Some(color) => color
    None => TextColor::default()
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
    None => TextLayout::default()
  }
  let line_height = match (text_ecs_entity_ref_get(entity_ref) : LineHeight?) {
    Some(line_height) => line_height
    None => LineHeight::default()
  }
  let shadow_component : TextShadow? = text_ecs_entity_ref_get(entity_ref)
  Text2dBundle::{
    text: Text2d::new(text.content),
    font,
    color,
    background_color,
    underline,
    underline_color,
    strikethrough,
    strikethrough_color,
    layout,
    bounds: TextBounds::default(),
    line_height,
    shadow: text_shadow_component_to_2d(shadow_component),
    transform: @transform.Transform::identity(),
    layers: @sprite.RenderLayers::default(),
    no_frustum_culling: false,
    anchor: @sprite.Anchor::default(),
    y_axis: YAxisOrientation::TopToBottom,
    logical_viewport_size: None,
  }
}

///|
fn ui_text_ecs_spawn_entry(
  world : @ecs.World,
  world_id : Int,
  entity : @core.Entity,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
) -> Unit {
  sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    handle
  })
  ui_text_ecs_bridge_entries.push(UiEcsTextBridgeEntry::{
    world_id,
    entity,
    handle,
    bundle,
    span_bundles,
  })
  ui_text_ecs_build_entry_index_by_entity_id(world_id).set(
    entity.id,
    ui_text_ecs_bridge_entries.length() - 1,
  )
}

///|
fn ui_text_ecs_remove_entry_at_index(
  index : Int,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  let last_index = ui_text_ecs_bridge_entries.length() - 1
  let removed_entry = ui_text_ecs_bridge_entries[index]
  ignore(text_despawn(removed_entry.handle))
  if index != last_index {
    let moved_entry = ui_text_ecs_bridge_entries[last_index]
    ui_text_ecs_bridge_entries[index] = moved_entry
    index_by_entity_id.set(moved_entry.entity.id, index)
  }
  ignore(ui_text_ecs_bridge_entries.pop())
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
  sequence : @core.SystemSequence,
  index_by_entity_id : Map[Int, Int],
) -> Unit {
  for entity in world.removed_components(ecs_key_text, sequence).read() {
    ui_text_ecs_cleanup_removed_entity(world_id, entity, index_by_entity_id)
  }
}

///|
fn ui_text_ecs_respawn_entry(
  world : @ecs.World,
  entry : UiEcsTextBridgeEntry,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
) -> UiEcsTextBridgeEntry {
  ignore(text_despawn(entry.handle))
  sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    handle
  })
  UiEcsTextBridgeEntry::{ ..entry, handle, bundle, span_bundles }
}

///|
fn ui_text_ecs_sync_existing_entry(
  world : @ecs.World,
  entry : UiEcsTextBridgeEntry,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
) -> UiEcsTextBridgeEntry {
  sync_text_runtime_rem_size(world)
  let handle = entry.handle
  if text_get_transform(handle) is None {
    return ui_text_ecs_respawn_entry(world, entry, bundle, span_bundles)
  }
  if !text_span_bundle_array_eq(entry.span_bundles, span_bundles) {
    return ui_text_ecs_respawn_entry(world, entry, bundle, span_bundles)
  }
  let needs_layout = !text_bundle_rerender_eq(entry.bundle, bundle)
  if !text2d_eq(entry.bundle.text, bundle.text) {
    text_set_content(handle, bundle.text.content)
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
  if !text_shadow_eq(entry.bundle.shadow, bundle.shadow) {
    text_set_shadow(handle, bundle.shadow)
  }
  if !vec2_opt_eq(
      entry.bundle.logical_viewport_size,
      bundle.logical_viewport_size,
    ) {
    text_set_logical_viewport_size(handle, bundle.logical_viewport_size)
  }
  ignore(needs_layout)
  UiEcsTextBridgeEntry::{ ..entry, bundle, span_bundles }
}

///|
pub fn ui_text_ecs_handle(
  world : @ecs.World,
  entity : @core.Entity,
) -> TextHandle? {
  match ui_text_ecs_find_entry_index(world.world_id(), entity) {
    Some(index) => Some(ui_text_ecs_bridge_entries[index].handle)
    None => None
  }
}

///|
pub fn ui_text_sync_ecs_system(world : @ecs.World) -> Unit {
  prepare_text_runtime_world(world)
  let world_id = world.world_id()
  let index_by_entity_id = ui_text_ecs_build_entry_index_by_entity_id(world_id)
  let sequence = world.get_sequence_context().sequence()
  ui_text_ecs_cleanup_removed_entries(
    world, world_id, sequence, index_by_entity_id,
  )
  let span_edges = text_ecs_collect_span_edges(world)
  let has_any_spans = span_edges.length() > 0
  let dirty_entities : Map[Int, Bool] = {}
  let has_text_dirty_entities = Ref::new(false)
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_font, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_background_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_underline, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_underline_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_strikethrough, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_strikethrough_color, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_layout, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_line_height, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  ignore(
    text_ecs_union_changed_entities_into(
      world, ecs_key_text_shadow, sequence, dirty_entities, has_text_dirty_entities,
    ),
  )
  if has_any_spans {
    ignore(
      text_ecs_union_changed_entities_into(
        world, @hierarchy.ecs_key_children, sequence, dirty_entities, has_text_dirty_entities,
      ),
    )
    ignore(
      text_ecs_union_changed_entities_into(
        world, @hierarchy.ecs_key_parent, sequence, dirty_entities, has_text_dirty_entities,
      ),
    )
    ignore(
      text_ecs_union_changed_entities_into(
        world, ecs_key_text_span, sequence, dirty_entities, has_text_dirty_entities,
      ),
    )
    text_ecs_mark_span_parents_dirty(
      span_edges, dirty_entities, has_text_dirty_entities,
    )
  }
  if !has_text_dirty_entities.val && ui_text_ecs_bridge_entries.length() > 0 {
    return
  }
  let query : @ecs.Query[@ecs.Comp[Text], @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, text) {
    let existing_index = ui_text_ecs_find_entry_index_from_index(
      world_id, entity, index_by_entity_id,
    )
    if existing_index is Some(_) &&
      !text_ecs_entity_id_set_contains(dirty_entities, entity) {
      return
    }
    let bundle = ui_text_ecs_bundle_from_entity(world, entity, text.value())
    let span_bundles = text_ecs_collect_span_bundles_for_entity(
      world, entity, bundle, span_edges,
    )
    match existing_index {
      Some(index) => {
        let entry = ui_text_ecs_bridge_entries[index]
        ui_text_ecs_bridge_entries[index] = ui_text_ecs_sync_existing_entry(
          world, entry, bundle, span_bundles,
        )
      }
      None => {
        ui_text_ecs_spawn_entry(world, world_id, entity, bundle, span_bundles)
        index_by_entity_id.set(
          entity.id,
          ui_text_ecs_bridge_entries.length() - 1,
        )
      }
    }
  })
}
