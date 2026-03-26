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
  span_bundles : Array[TextSpanBundle]
}

///|
let text_ecs_bridge_entries : Array[EcsTextBridgeEntry] = []

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
let text_runtime_world_id_ref : Ref[Int?] = Ref::new(None)

///|
fn reset_text_runtime_state() -> Unit {
  text_state.val.next_text_id = 0
  text_state.val.next_span_id = 0
  text_state.val.texts.clear()
  text_debug_frame_state.val.draws.clear()
  text_ecs_bridge_entries.clear()
  ui_text_ecs_bridge_entries.clear()
  font_atlas_set_state.val = FontAtlasSet::default()
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
  world.register_required_components(
    ecs_key_text2d, @transform.ecs_key_transform,
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
fn text_ecs_has_required_components(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  if !world.is_alive(entity) {
    return false
  }
  if (try! world.entity(entity).get() : Text2d?) is None {
    return false
  }
  if (try! world.entity(entity).get() : TextFont?) is None {
    return false
  }
  if (try! world.entity(entity).get() : @transform.Transform?) is None {
    return false
  }
  true
}

///|
fn text_ecs_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  text : Text2d,
  font : TextFont,
  local_transform : @transform.Transform,
) -> Text2dBundle {
  let transform = match
    (try! world.entity(entity).get() : @transform.GlobalTransform?) {
    Some(global_transform) => global_transform.to_transform_approx()
    None => local_transform
  }
  let color = match (try! world.entity(entity).get() : TextColor?) {
    Some(color) => color
    None => TextColor::default()
  }
  let background_color : TextBackgroundColor? = try! world.entity(entity).get()
  let underline : Underline? = try! world.entity(entity).get()
  let underline_color : UnderlineColor? = try! world.entity(entity).get()
  let strikethrough : Strikethrough? = try! world.entity(entity).get()
  let strikethrough_color : StrikethroughColor? = try! world
    .entity(entity)
    .get()
  let layout = match (try! world.entity(entity).get() : TextLayout?) {
    Some(layout) => layout
    None => TextLayout::default()
  }
  let bounds = match (try! world.entity(entity).get() : TextBounds?) {
    Some(bounds) => bounds
    None => TextBounds::default()
  }
  let line_height = match (try! world.entity(entity).get() : LineHeight?) {
    Some(line_height) => line_height
    None => LineHeight::default()
  }
  let shadow : Text2dShadow? = try! world.entity(entity).get()
  let layers = match (try! world.entity(entity).get() : @sprite.RenderLayers?) {
    Some(layers) => layers
    None => @sprite.RenderLayers::default()
  }
  let anchor = match (try! world.entity(entity).get() : @sprite.Anchor?) {
    Some(anchor) => anchor
    None => @sprite.Anchor::default()
  }
  let y_axis = match (try! world.entity(entity).get() : YAxisOrientation?) {
    Some(y_axis) => y_axis
    None => YAxisOrientation::TopToBottom
  }
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
    anchor,
    y_axis,
    logical_viewport_size: None,
  }
}

///|
fn text_ecs_span_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  inherited_font : TextFont,
  inherited_line_height : LineHeight,
) -> TextSpanBundle? {
  let span = match (try! world.entity(entity).get() : TextSpan?) {
    Some(span) => span
    None => return None
  }
  let font = match (try! world.entity(entity).get() : TextFont?) {
    Some(font) => font
    None => inherited_font
  }
  let color = match (try! world.entity(entity).get() : TextColor?) {
    Some(color) => color
    None => TextColor::default()
  }
  let background_color : TextBackgroundColor? = try! world.entity(entity).get()
  let underline : Underline? = try! world.entity(entity).get()
  let underline_color : UnderlineColor? = try! world.entity(entity).get()
  let strikethrough : Strikethrough? = try! world.entity(entity).get()
  let strikethrough_color : StrikethroughColor? = try! world
    .entity(entity)
    .get()
  let line_height = match (try! world.entity(entity).get() : LineHeight?) {
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
) -> Array[TextSpanBundle] {
  let span_bundles : Array[TextSpanBundle] = []
  match (try! world.entity(entity).get() : @hierarchy.Children?) {
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
    None => {
      let query : @ecs.Query[
        (@ecs.Comp[TextSpan], @ecs.Comp[@hierarchy.Parent]),
        @ecs.All,
      ] = @ecs.query(world)
      try! query.view(fn(child, data) {
        let (_span, parent) = data
        if parent.value().entity() != entity {
          return
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
      })
    }
  }
  span_bundles
}

///|
fn text_ecs_spawn_entry(
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
    text_update_instance(handle, text_update_layout)
    handle
  })
  text_ecs_bridge_entries.push(EcsTextBridgeEntry::{
    world_id,
    entity,
    handle,
    bundle,
    span_bundles,
  })
}

///|
fn text_ecs_cleanup_stale_entries(world : @ecs.World) -> Unit {
  let world_id = world.world_id()
  let next_entries : Array[EcsTextBridgeEntry] = []
  for entry in text_ecs_bridge_entries {
    if entry.world_id != world_id {
      next_entries.push(entry)
      continue
    }
    if text_ecs_has_required_components(world, entry.entity) {
      next_entries.push(entry)
      continue
    }
    ignore(text_despawn(entry.handle))
  }
  text_ecs_bridge_entries.clear()
  for entry in next_entries {
    text_ecs_bridge_entries.push(entry)
  }
}

///|
fn text_ecs_respawn_entry(
  world : @ecs.World,
  entry : EcsTextBridgeEntry,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
) -> EcsTextBridgeEntry {
  ignore(text_despawn(entry.handle))
  sync_text_runtime_rem_size(world)
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    text_update_instance(handle, text_update_layout)
    handle
  })
  EcsTextBridgeEntry::{ ..entry, handle, bundle, span_bundles }
}

///|
fn text_ecs_sync_existing_entry(
  world : @ecs.World,
  entry : EcsTextBridgeEntry,
  bundle : Text2dBundle,
  span_bundles : Array[TextSpanBundle],
) -> EcsTextBridgeEntry {
  sync_text_runtime_rem_size(world)
  let handle = entry.handle
  if text_get_transform(handle) is None {
    return text_ecs_respawn_entry(world, entry, bundle, span_bundles)
  }
  if !text_span_bundle_array_eq(entry.span_bundles, span_bundles) {
    return text_ecs_respawn_entry(world, entry, bundle, span_bundles)
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
  text_set_transform(handle, bundle.transform)
  text_set_layers(handle, bundle.layers)
  text_set_anchor(handle, bundle.anchor)
  text_set_y_axis(handle, bundle.y_axis)
  if !vec2_opt_eq(
      entry.bundle.logical_viewport_size,
      bundle.logical_viewport_size,
    ) {
    text_set_logical_viewport_size(handle, bundle.logical_viewport_size)
  }
  if needs_layout {
    @asset.asset_with_world(world, fn() {
      text_update_instance(handle, text_update_layout)
    })
  }
  EcsTextBridgeEntry::{ ..entry, bundle, span_bundles }
}

///|
fn text_sync_ecs_system(world : @ecs.World) -> Unit {
  prepare_text_runtime_world(world)
  text_ecs_cleanup_stale_entries(world)
  let world_id = world.world_id()
  let query : @ecs.Query[
    (@ecs.Comp[Text2d], @ecs.Comp[TextFont], @ecs.Comp[@transform.Transform]),
    @ecs.All,
  ] = @ecs.query(world)
  try! query.view(fn(entity, data) {
    let (text, font, local_transform) = data
    let bundle = text_ecs_bundle_from_entity(
      world,
      entity,
      text.value(),
      font.value(),
      local_transform.value(),
    )
    let span_bundles = text_ecs_collect_span_bundles_for_entity(
      world, entity, bundle,
    )
    match text_ecs_find_entry_index(world_id, entity) {
      Some(index) => {
        let entry = text_ecs_bridge_entries[index]
        text_ecs_bridge_entries[index] = text_ecs_sync_existing_entry(
          world, entry, bundle, span_bundles,
        )
      }
      None =>
        text_ecs_spawn_entry(world, world_id, entity, bundle, span_bundles)
    }
  })
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
fn ui_text_ecs_has_required_components(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  if !world.is_alive(entity) {
    return false
  }
  (try! world.entity(entity).get() : Text?) is Some(_)
}

///|
fn ui_text_ecs_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  text : Text,
) -> Text2dBundle {
  let font = match (try! world.entity(entity).get() : TextFont?) {
    Some(font) => font
    None => TextFont::default()
  }
  let color = match (try! world.entity(entity).get() : TextColor?) {
    Some(color) => color
    None => TextColor::default()
  }
  let background_color : TextBackgroundColor? = try! world.entity(entity).get()
  let underline : Underline? = try! world.entity(entity).get()
  let underline_color : UnderlineColor? = try! world.entity(entity).get()
  let strikethrough : Strikethrough? = try! world.entity(entity).get()
  let strikethrough_color : StrikethroughColor? = try! world
    .entity(entity)
    .get()
  let layout = match (try! world.entity(entity).get() : TextLayout?) {
    Some(layout) => layout
    None => TextLayout::default()
  }
  let line_height = match (try! world.entity(entity).get() : LineHeight?) {
    Some(line_height) => line_height
    None => LineHeight::default()
  }
  let shadow_component : TextShadow? = try! world.entity(entity).get()
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
    text_update_instance(handle, text_update_layout)
    handle
  })
  ui_text_ecs_bridge_entries.push(UiEcsTextBridgeEntry::{
    world_id,
    entity,
    handle,
    bundle,
    span_bundles,
  })
}

///|
fn ui_text_ecs_cleanup_stale_entries(world : @ecs.World) -> Unit {
  let world_id = world.world_id()
  let next_entries : Array[UiEcsTextBridgeEntry] = []
  for entry in ui_text_ecs_bridge_entries {
    if entry.world_id != world_id {
      next_entries.push(entry)
      continue
    }
    if ui_text_ecs_has_required_components(world, entry.entity) {
      next_entries.push(entry)
      continue
    }
    ignore(text_despawn(entry.handle))
  }
  ui_text_ecs_bridge_entries.clear()
  for entry in next_entries {
    ui_text_ecs_bridge_entries.push(entry)
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
    text_update_instance(handle, text_update_layout)
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
  if needs_layout {
    @asset.asset_with_world(world, fn() {
      text_update_instance(handle, text_update_layout)
    })
  }
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
  ui_text_ecs_cleanup_stale_entries(world)
  let world_id = world.world_id()
  let query : @ecs.Query[@ecs.Comp[Text], @ecs.All] = @ecs.query(world)
  try! query.view(fn(entity, text) {
    let bundle = ui_text_ecs_bundle_from_entity(world, entity, text.value())
    let span_bundles = text_ecs_collect_span_bundles_for_entity(
      world, entity, bundle,
    )
    match ui_text_ecs_find_entry_index(world_id, entity) {
      Some(index) => {
        let entry = ui_text_ecs_bridge_entries[index]
        ui_text_ecs_bridge_entries[index] = ui_text_ecs_sync_existing_entry(
          world, entry, bundle, span_bundles,
        )
      }
      None =>
        ui_text_ecs_spawn_entry(world, world_id, entity, bundle, span_bundles)
    }
  })
}
