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
pub let ecs_key_text_underline : @ecs.ComponentKey[Underline] = @ecs.register_component(
  debug_name="text.text_underline",
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
pub impl @ecs.Component for Underline with component() {
  ecs_key_text_underline
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
priv struct EcsTextBridgeEntry {
  world_id : Int
  entity : @core.Entity
  handle : TextHandle
  bundle : Text2dBundle
  span_bundles : Array[TextSpanBundle]
}

///|
let text_ecs_bridge_entries : Ref[Array[EcsTextBridgeEntry]] = Ref::new([])

///|
priv struct UiEcsTextBridgeEntry {
  world_id : Int
  entity : @core.Entity
  handle : TextHandle
  bundle : Text2dBundle
  span_bundles : Array[TextSpanBundle]
}

///|
let ui_text_ecs_bridge_entries : Ref[Array[UiEcsTextBridgeEntry]] = Ref::new([])

///|
let text_runtime_world_id_ref : Ref[Int?] = Ref::new(None)

///|
fn reset_text_runtime_state() -> Unit {
  text_state.val.next_text_id = 0
  text_state.val.next_span_id = 0
  text_state.val.texts.clear()
  text_debug_frame_state.val.draws.clear()
  text_ecs_bridge_entries.val.clear()
  ui_text_ecs_bridge_entries.val.clear()
  font_atlas_set_state.val = FontAtlasSet::default()
  cosmic_font_system_state.val = CosmicFontSystemState::{
    font_system: @cosmic.FontSystem::new(),
    handle_to_font_id: [],
    font_id_to_handle_id: [],
    handle_to_family: [],
  }
  swash_font_cache.val.entries.clear()
  cosmic_swash_cache.val = @cosmic.SwashCache::new()
  text_warned_missing_font_mapping_ids.val.clear()
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
fn text_font_eq(lhs : TextFont, rhs : TextFont) -> Bool {
  lhs.font.id() == rhs.font.id() &&
  lhs.font_size == rhs.font_size &&
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
  empty_marker_opt_eq(lhs.strikethrough, rhs.strikethrough) &&
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
  empty_marker_opt_eq(lhs.strikethrough, rhs.strikethrough) &&
  text_layout_eq(lhs.layout, rhs.layout) &&
  text_bounds_eq(lhs.bounds, rhs.bounds) &&
  line_height_eq(lhs.line_height, rhs.line_height) &&
  text_shadow_eq(lhs.shadow, rhs.shadow) &&
  y_axis_eq(lhs.y_axis, rhs.y_axis)
}

///|
fn text_ecs_find_entry_index(world_id : Int, entity : @core.Entity) -> Int? {
  let count = text_ecs_bridge_entries.val.length()
  for i in 0..<count {
    let entry = text_ecs_bridge_entries.val[i]
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
  if (try! world.get_component(entity) : Text2d?) is None {
    return false
  }
  if (try! world.get_component(entity) : TextFont?) is None {
    return false
  }
  if (try! world.get_component(entity) : @transform.Transform?) is None {
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
    (try! world.get_component(entity) : @transform.GlobalTransform?) {
    Some(global_transform) => global_transform.to_transform_approx()
    None => local_transform
  }
  let color = match (try! world.get_component(entity) : TextColor?) {
    Some(color) => color
    None => TextColor::default()
  }
  let background_color : TextBackgroundColor? = try! world.get_component(entity)
  let underline : Underline? = try! world.get_component(entity)
  let strikethrough : Strikethrough? = try! world.get_component(entity)
  let layout = match (try! world.get_component(entity) : TextLayout?) {
    Some(layout) => layout
    None => TextLayout::default()
  }
  let bounds = match (try! world.get_component(entity) : TextBounds?) {
    Some(bounds) => bounds
    None => TextBounds::default()
  }
  let line_height = match (try! world.get_component(entity) : LineHeight?) {
    Some(line_height) => line_height
    None => LineHeight::default()
  }
  let shadow : Text2dShadow? = try! world.get_component(entity)
  let layers = match
    (try! world.get_component(entity) : @sprite.RenderLayers?) {
    Some(layers) => layers
    None => @sprite.RenderLayers::default()
  }
  let anchor = match (try! world.get_component(entity) : @sprite.Anchor?) {
    Some(anchor) => anchor
    None => @sprite.Anchor::default()
  }
  let y_axis = match (try! world.get_component(entity) : YAxisOrientation?) {
    Some(y_axis) => y_axis
    None => YAxisOrientation::TopToBottom
  }
  Text2dBundle::{
    text,
    font,
    color,
    background_color,
    underline,
    strikethrough,
    layout,
    bounds,
    line_height,
    shadow,
    transform,
    layers,
    anchor,
    y_axis,
  }
}

///|
fn text_ecs_span_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  inherited_font : TextFont,
  inherited_line_height : LineHeight,
) -> TextSpanBundle? {
  let span = match (try! world.get_component(entity) : TextSpan?) {
    Some(span) => span
    None => return None
  }
  let font = match (try! world.get_component(entity) : TextFont?) {
    Some(font) => font
    None => inherited_font
  }
  let color = match (try! world.get_component(entity) : TextColor?) {
    Some(color) => color
    None => TextColor::default()
  }
  let background_color : TextBackgroundColor? = try! world.get_component(entity)
  let underline : Underline? = try! world.get_component(entity)
  let strikethrough : Strikethrough? = try! world.get_component(entity)
  let line_height = match (try! world.get_component(entity) : LineHeight?) {
    Some(line_height) => line_height
    None => inherited_line_height
  }
  Some(TextSpanBundle::{
    span,
    font,
    color,
    background_color,
    underline,
    strikethrough,
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
  match (try! world.get_component(entity) : @hierarchy.Children?) {
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
      let query = world.query2(
        ecs_key_text_span,
        @hierarchy.Parent::component(),
      )
      try! query.for_each(fn(child, _span, parent) {
        if parent.entity() != entity {
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
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    text_update_instance(handle, text_update_layout)
    handle
  })
  text_ecs_bridge_entries.val.push(EcsTextBridgeEntry::{
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
  for entry in text_ecs_bridge_entries.val {
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
  text_ecs_bridge_entries.val.clear()
  for entry in next_entries {
    text_ecs_bridge_entries.val.push(entry)
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
  if !empty_marker_opt_eq(entry.bundle.strikethrough, bundle.strikethrough) {
    text_set_strikethrough(handle, bundle.strikethrough)
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
  let query = world.query3(
    ecs_key_text2d, ecs_key_text_font, @transform.ecs_key_transform,
  )
  try! query.for_each(fn(entity, text, font, local_transform) {
    let bundle = text_ecs_bundle_from_entity(
      world, entity, text, font, local_transform,
    )
    let span_bundles = text_ecs_collect_span_bundles_for_entity(
      world, entity, bundle,
    )
    match text_ecs_find_entry_index(world_id, entity) {
      Some(index) => {
        let entry = text_ecs_bridge_entries.val[index]
        text_ecs_bridge_entries.val[index] = text_ecs_sync_existing_entry(
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
  let count = ui_text_ecs_bridge_entries.val.length()
  for i in 0..<count {
    let entry = ui_text_ecs_bridge_entries.val[i]
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
  (try! world.get_component(entity) : Text?) is Some(_)
}

///|
fn ui_text_ecs_bundle_from_entity(
  world : @ecs.World,
  entity : @core.Entity,
  text : Text,
) -> Text2dBundle {
  let font = match (try! world.get_component(entity) : TextFont?) {
    Some(font) => font
    None => TextFont::default()
  }
  let color = match (try! world.get_component(entity) : TextColor?) {
    Some(color) => color
    None => TextColor::default()
  }
  let background_color : TextBackgroundColor? = try! world.get_component(entity)
  let underline : Underline? = try! world.get_component(entity)
  let strikethrough : Strikethrough? = try! world.get_component(entity)
  let layout = match (try! world.get_component(entity) : TextLayout?) {
    Some(layout) => layout
    None => TextLayout::default()
  }
  let line_height = match (try! world.get_component(entity) : LineHeight?) {
    Some(line_height) => line_height
    None => LineHeight::default()
  }
  let shadow_component : TextShadow? = try! world.get_component(entity)
  Text2dBundle::{
    text: Text2d::new(text.content),
    font,
    color,
    background_color,
    underline,
    strikethrough,
    layout,
    bounds: TextBounds::default(),
    line_height,
    shadow: text_shadow_component_to_2d(shadow_component),
    transform: @transform.Transform::identity(),
    layers: @sprite.RenderLayers::default(),
    anchor: @sprite.Anchor::default(),
    y_axis: YAxisOrientation::TopToBottom,
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
  let handle = @asset.asset_with_world(world, fn() {
    let handle = text_spawn(bundle)
    for span_bundle in span_bundles {
      ignore(text_spawn_span(handle, span_bundle))
    }
    text_update_instance(handle, text_update_layout)
    handle
  })
  ui_text_ecs_bridge_entries.val.push(UiEcsTextBridgeEntry::{
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
  for entry in ui_text_ecs_bridge_entries.val {
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
  ui_text_ecs_bridge_entries.val.clear()
  for entry in next_entries {
    ui_text_ecs_bridge_entries.val.push(entry)
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
  text_set_transform(handle, bundle.transform)
  text_set_layers(handle, bundle.layers)
  text_set_anchor(handle, bundle.anchor)
  text_set_y_axis(handle, bundle.y_axis)
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
    Some(index) => Some(ui_text_ecs_bridge_entries.val[index].handle)
    None => None
  }
}

///|
pub fn ui_text_sync_ecs_system(world : @ecs.World) -> Unit {
  prepare_text_runtime_world(world)
  ui_text_ecs_cleanup_stale_entries(world)
  let world_id = world.world_id()
  let query = world.query1(ecs_key_text)
  try! query.for_each(fn(entity, text) {
    let bundle = ui_text_ecs_bundle_from_entity(world, entity, text)
    let span_bundles = text_ecs_collect_span_bundles_for_entity(
      world, entity, bundle,
    )
    match ui_text_ecs_find_entry_index(world_id, entity) {
      Some(index) => {
        let entry = ui_text_ecs_bridge_entries.val[index]
        ui_text_ecs_bridge_entries.val[index] = ui_text_ecs_sync_existing_entry(
          world, entry, bundle, span_bundles,
        )
      }
      None =>
        ui_text_ecs_spawn_entry(world, world_id, entity, bundle, span_bundles)
    }
  })
}
