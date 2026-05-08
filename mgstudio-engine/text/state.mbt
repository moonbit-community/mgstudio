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
pub struct Text2dBundle {
  text : Text2d
  font : TextFont
  color : TextColor
  background_color : TextBackgroundColor?
  underline : Underline?
  underline_color : UnderlineColor?
  strikethrough : Strikethrough?
  strikethrough_color : StrikethroughColor?
  layout : TextLayout
  bounds : TextBounds
  line_height : LineHeight
  font_hinting : FontHinting
  shadow : Text2dShadow?
  transform : @transform.Transform
  layers : @sprite.RenderLayers
  no_frustum_culling : Bool
  anchor : @sprite.Anchor
  y_axis : YAxisOrientation
  logical_viewport_size : @math.Vec2?
}

///|
pub fn Text2dBundle::new(
  text : Text2d,
  font : TextFont,
  transform : @transform.Transform,
) -> Text2dBundle {
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
    font_hinting: FontHinting::default(),
    shadow: None,
    transform,
    layers: @sprite.RenderLayers::default(),
    no_frustum_culling: false,
    anchor: @sprite.Anchor::default(),
    y_axis: YAxisOrientation::TopToBottom,
    logical_viewport_size: None,
  }
}

///|
pub fn Text2dBundle::new_with_layers(
  text : Text2d,
  font : TextFont,
  transform : @transform.Transform,
  layers : @sprite.RenderLayers,
) -> Text2dBundle {
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
    font_hinting: FontHinting::default(),
    shadow: None,
    transform,
    layers,
    no_frustum_culling: false,
    anchor: @sprite.Anchor::default(),
    y_axis: YAxisOrientation::TopToBottom,
    logical_viewport_size: None,
  }
}

///|
pub fn Text2dBundle::with_color(
  self : Text2dBundle,
  color : TextColor,
) -> Text2dBundle {
  Text2dBundle::{ ..self, color, }
}

///|
pub fn Text2dBundle::with_background_color(
  self : Text2dBundle,
  background_color : TextBackgroundColor?,
) -> Text2dBundle {
  Text2dBundle::{ ..self, background_color, }
}

///|
pub fn Text2dBundle::with_underline(
  self : Text2dBundle,
  underline : Underline?,
) -> Text2dBundle {
  Text2dBundle::{ ..self, underline, }
}

///|
pub fn Text2dBundle::with_underline_color(
  self : Text2dBundle,
  underline_color : UnderlineColor?,
) -> Text2dBundle {
  Text2dBundle::{ ..self, underline_color, }
}

///|
pub fn Text2dBundle::with_strikethrough(
  self : Text2dBundle,
  strikethrough : Strikethrough?,
) -> Text2dBundle {
  Text2dBundle::{ ..self, strikethrough, }
}

///|
pub fn Text2dBundle::with_strikethrough_color(
  self : Text2dBundle,
  strikethrough_color : StrikethroughColor?,
) -> Text2dBundle {
  Text2dBundle::{ ..self, strikethrough_color, }
}

///|
pub fn Text2dBundle::with_layout(
  self : Text2dBundle,
  layout : TextLayout,
) -> Text2dBundle {
  Text2dBundle::{ ..self, layout, }
}

///|
pub fn Text2dBundle::with_bounds(
  self : Text2dBundle,
  bounds : TextBounds,
) -> Text2dBundle {
  Text2dBundle::{ ..self, bounds, }
}

///|
pub fn Text2dBundle::with_line_height(
  self : Text2dBundle,
  line_height : LineHeight,
) -> Text2dBundle {
  Text2dBundle::{ ..self, line_height, }
}

///|
pub fn Text2dBundle::with_font_hinting(
  self : Text2dBundle,
  font_hinting : FontHinting,
) -> Text2dBundle {
  Text2dBundle::{ ..self, font_hinting, }
}

///|
pub fn Text2dBundle::with_shadow(
  self : Text2dBundle,
  shadow : Text2dShadow?,
) -> Text2dBundle {
  Text2dBundle::{ ..self, shadow, }
}

///|
/// Set the anchor used for world-space `Text2d` positioning (Bevy-aligned).
pub fn Text2dBundle::with_anchor(
  self : Text2dBundle,
  anchor : @sprite.Anchor,
) -> Text2dBundle {
  Text2dBundle::{ ..self, anchor, }
}

///|
/// Set the layout coordinate orientation.
pub fn Text2dBundle::with_y_axis(
  self : Text2dBundle,
  y_axis : YAxisOrientation,
) -> Text2dBundle {
  Text2dBundle::{ ..self, y_axis, }
}

///|
pub fn Text2dBundle::spawn(self : Text2dBundle) -> TextHandle {
  text_spawn(self)
}

///|
pub struct TextSpanBundle {
  span : TextSpan
  font : TextFont
  color : TextColor
  background_color : TextBackgroundColor?
  underline : Underline?
  underline_color : UnderlineColor?
  strikethrough : Strikethrough?
  strikethrough_color : StrikethroughColor?
  line_height : LineHeight
}

///|
pub fn TextSpanBundle::new(span : TextSpan, font : TextFont) -> TextSpanBundle {
  TextSpanBundle::{
    span,
    font,
    color: TextColor::default(),
    background_color: None,
    underline: None,
    underline_color: None,
    strikethrough: None,
    strikethrough_color: None,
    line_height: LineHeight::default(),
  }
}

///|
pub fn TextSpanBundle::with_color(
  self : TextSpanBundle,
  color : TextColor,
) -> TextSpanBundle {
  TextSpanBundle::{ ..self, color, }
}

///|
pub fn TextSpanBundle::with_background_color(
  self : TextSpanBundle,
  background_color : TextBackgroundColor?,
) -> TextSpanBundle {
  TextSpanBundle::{ ..self, background_color, }
}

///|
pub fn TextSpanBundle::with_underline(
  self : TextSpanBundle,
  underline : Underline?,
) -> TextSpanBundle {
  TextSpanBundle::{ ..self, underline, }
}

///|
pub fn TextSpanBundle::with_underline_color(
  self : TextSpanBundle,
  underline_color : UnderlineColor?,
) -> TextSpanBundle {
  TextSpanBundle::{ ..self, underline_color, }
}

///|
pub fn TextSpanBundle::with_strikethrough(
  self : TextSpanBundle,
  strikethrough : Strikethrough?,
) -> TextSpanBundle {
  TextSpanBundle::{ ..self, strikethrough, }
}

///|
pub fn TextSpanBundle::with_strikethrough_color(
  self : TextSpanBundle,
  strikethrough_color : StrikethroughColor?,
) -> TextSpanBundle {
  TextSpanBundle::{ ..self, strikethrough_color, }
}

///|
pub fn TextSpanBundle::spawn(
  self : TextSpanBundle,
  parent : TextHandle,
) -> TextSpanHandle {
  text_spawn_span(parent, self)
}

///|
priv struct TextSpanInstance {
  id : Int
  span : TextSpan
  font : TextFont
  color : TextColor
  background_color : TextBackgroundColor?
  underline : Underline?
  underline_color : UnderlineColor?
  strikethrough : Strikethrough?
  strikethrough_color : StrikethroughColor?
  line_height : LineHeight
}

///|
priv struct TextInstance {
  id : Int
  text : Text2d
  font : TextFont
  color : TextColor
  background_color : TextBackgroundColor?
  underline : Underline?
  underline_color : UnderlineColor?
  strikethrough : Strikethrough?
  strikethrough_color : StrikethroughColor?
  layout : TextLayout
  bounds : TextBounds
  line_height : LineHeight
  font_hinting : FontHinting
  shadow : Text2dShadow?
  transform : @transform.Transform
  layers : @sprite.RenderLayers
  view_visible : Bool
  no_frustum_culling : Bool
  anchor : @sprite.Anchor
  y_axis : YAxisOrientation
  /// When set, this text handle is treated as "UI text" and will be positioned
  /// relative to a UI node's top-left corner (Bevy UI extraction semantics).
  ui_node_size : @math.Vec2?
  logical_viewport_size : @math.Vec2?
  scale_factor : Float
  /// Optional UI target camera for overlay extraction.
  ui_camera_entity : @core.Entity?
  /// Optional UI clip rect (logical UI space) propagated from `ui_clip_system`.
  /// When present, glyph sprites are submitted with scissor.
  ui_scissor : @math.Rect?
  cull_margin : Float
  spans : Array[TextSpanInstance]
  layout_dirty : Bool
  computed : ComputedTextBlock
  layout_info : TextLayoutInfo
}

///|
priv struct TextState {
  mut next_text_id : Int
  mut next_span_id : Int
  texts : Array[TextInstance]
  text_index_by_id : Map[Int, Int]
}

///|
let text_state : Ref[TextState] = Ref(TextState::{
  next_text_id: 0,
  next_span_id: 0,
  texts: [],
  text_index_by_id: {},
})

///|
fn text_state_clear_instances() -> Unit {
  text_state.val.texts.clear()
  text_state.val.text_index_by_id.clear()
}

///|
fn text_state_find_index_by_id(id : Int) -> Int? {
  match text_state.val.text_index_by_id.get(id) {
    Some(index) =>
      if index >= 0 &&
        index < text_state.val.texts.length() &&
        text_state.val.texts[index].id == id {
        Some(index)
      } else {
        let count = text_state.val.texts.length()
        for i in 0..<count {
          if text_state.val.texts[i].id == id {
            text_state.val.text_index_by_id.set(id, i)
            return Some(i)
          }
        }
        ignore(text_state.val.text_index_by_id.remove(id))
        None
      }
    None => {
      let count = text_state.val.texts.length()
      for i in 0..<count {
        if text_state.val.texts[i].id == id {
          text_state.val.text_index_by_id.set(id, i)
          return Some(i)
        }
      }
      None
    }
  }
}

///|
pub fn text_compute_cull_margin(
  bounds : TextBounds,
  layout_size : @math.Vec2,
  scale : @math.Vec3,
) -> Float {
  let width = bounds.width.unwrap_or(layout_size.x)
  let height = bounds.height.unwrap_or(layout_size.y)
  let abs_sx = if scale.x < 0.0F { 0.0F - scale.x } else { scale.x }
  let abs_sy = if scale.y < 0.0F { 0.0F - scale.y } else { scale.y }
  let cull_width = width * abs_sx
  let cull_height = height * abs_sy
  let cull_radius = if cull_width > cull_height {
    cull_width
  } else {
    cull_height
  }
  cull_radius * 0.6F + 16.0F
}

///|
let text_runtime_rem_size_ref : Ref[Float] = Ref(20.0F)

///|
let text_layout_dirty_ref : Ref[Bool] = Ref(true)

///|
pub fn text_runtime_mark_layout_dirty() -> Unit {
  text_layout_dirty_ref.val = true
}

///|
pub fn text_runtime_layout_dirty() -> Bool {
  text_layout_dirty_ref.val
}

///|
pub fn text_runtime_clear_layout_dirty() -> Unit {
  text_layout_dirty_ref.val = false
}

///|
pub struct TextDebugGlyphDraw {
  text_id : Int
  bounds : @math.Rect
  scissor : @math.Rect?
  texture_id : Int
  uv_min : @math.Vec2
  uv_max : @math.Vec2
}

///|
pub struct TextDebugTextInfo {
  text_id : Int
  content : String
}

///|
priv struct TextDebugFrameState {
  draws : Array[TextDebugGlyphDraw]
}

///|
let text_debug_frame_state : Ref[TextDebugFrameState] = Ref(TextDebugFrameState::{
  draws: [],
})

///|
let text_debug_capture_enabled_state : Ref[Bool] = Ref(false)

///|
pub fn text_debug_capture_enabled() -> Bool {
  text_debug_capture_enabled_state.val
}

///|
pub fn text_debug_set_capture_enabled(enabled : Bool) -> Unit {
  text_debug_capture_enabled_state.val = enabled
  if !enabled {
    text_debug_frame_state.val.draws.clear()
  }
}

///|
pub fn text_debug_clear_frame() -> Unit {
  if !text_debug_capture_enabled_state.val {
    if text_debug_frame_state.val.draws.length() > 0 {
      text_debug_frame_state.val.draws.clear()
    }
    return
  }
  text_debug_frame_state.val.draws.clear()
}

///|
pub fn text_debug_push_glyph(
  text_id : Int,
  bounds : @math.Rect,
  scissor : @math.Rect?,
  texture_id : Int,
  uv_min : @math.Vec2,
  uv_max : @math.Vec2,
) -> Unit {
  if !text_debug_capture_enabled_state.val {
    return
  }
  text_debug_frame_state.val.draws.push(TextDebugGlyphDraw::{
    text_id,
    bounds,
    scissor,
    texture_id,
    uv_min,
    uv_max,
  })
}

///|
pub fn text_debug_draw_count(handle : TextHandle) -> Int {
  let mut count = 0
  for draw in text_debug_frame_state.val.draws {
    if draw.text_id == handle.id {
      count = count + 1
    }
  }
  count
}

///|
pub fn text_debug_draws(handle : TextHandle) -> Array[TextDebugGlyphDraw] {
  let draws : Array[TextDebugGlyphDraw] = []
  for draw in text_debug_frame_state.val.draws {
    if draw.text_id == handle.id {
      draws.push(draw)
    }
  }
  draws
}

///|
pub fn text_debug_all_draws() -> Array[TextDebugGlyphDraw] {
  text_debug_frame_state.val.draws
}

///|
pub fn text_debug_text_infos() -> Array[TextDebugTextInfo] {
  let infos : Array[TextDebugTextInfo] = []
  for instance in text_state.val.texts {
    infos.push(TextDebugTextInfo::{
      text_id: instance.id,
      content: instance.text.content,
    })
  }
  infos
}

///|
fn text_debug_rects_intersect(a : @math.Rect, b : @math.Rect) -> Bool {
  if a.max.x <= b.min.x || b.max.x <= a.min.x {
    return false
  }
  if a.max.y <= b.min.y || b.max.y <= a.min.y {
    return false
  }
  true
}

///|
fn text_debug_rect_intersection(a : @math.Rect, b : @math.Rect) -> @math.Rect {
  let min_x = if a.min.x > b.min.x { a.min.x } else { b.min.x }
  let min_y = if a.min.y > b.min.y { a.min.y } else { b.min.y }
  let max_x = if a.max.x < b.max.x { a.max.x } else { b.max.x }
  let max_y = if a.max.y < b.max.y { a.max.y } else { b.max.y }
  @math.Rect::new(@math.Vec2::new(min_x, min_y), @math.Vec2::new(max_x, max_y))
}

///|
fn text_debug_rect_non_empty(rect : @math.Rect) -> Bool {
  rect.max.x > rect.min.x && rect.max.y > rect.min.y
}

///|
fn text_debug_visible_bounds(draw : TextDebugGlyphDraw) -> @math.Rect? {
  match draw.scissor {
    None => Some(draw.bounds)
    Some(scissor) => {
      let clipped = text_debug_rect_intersection(draw.bounds, scissor)
      if text_debug_rect_non_empty(clipped) {
        Some(clipped)
      } else {
        None
      }
    }
  }
}

///|
pub fn text_debug_overlap_count(lhs : TextHandle, rhs : TextHandle) -> Int {
  let mut overlap = 0
  for a in text_debug_frame_state.val.draws {
    if a.text_id != lhs.id {
      continue
    }
    for b in text_debug_frame_state.val.draws {
      if b.text_id != rhs.id {
        continue
      }
      if text_debug_rects_intersect(a.bounds, b.bounds) {
        overlap = overlap + 1
      }
    }
  }
  overlap
}

///|
pub fn text_debug_visible_draw_count(handle : TextHandle) -> Int {
  let mut count = 0
  for draw in text_debug_frame_state.val.draws {
    if draw.text_id != handle.id {
      continue
    }
    if text_debug_visible_bounds(draw) is Some(_) {
      count = count + 1
    }
  }
  count
}

///|
pub fn text_debug_visible_overlap_count(
  lhs : TextHandle,
  rhs : TextHandle,
) -> Int {
  let mut overlap = 0
  for a in text_debug_frame_state.val.draws {
    if a.text_id != lhs.id {
      continue
    }
    let visible_a = text_debug_visible_bounds(a)
    guard visible_a is Some(a_rect) else { continue }
    for b in text_debug_frame_state.val.draws {
      if b.text_id != rhs.id {
        continue
      }
      let visible_b = text_debug_visible_bounds(b)
      guard visible_b is Some(b_rect) else { continue }
      if text_debug_rects_intersect(a_rect, b_rect) {
        overlap = overlap + 1
      }
    }
  }
  overlap
}

///|
pub fn text_spawn(bundle : Text2dBundle) -> TextHandle {
  let id = text_state.val.next_text_id
  let index = text_state.val.texts.length()
  text_state.val.next_text_id = id + 1
  text_runtime_mark_layout_dirty()
  text_state.val.texts.push(TextInstance::{
    id,
    text: bundle.text,
    font: bundle.font,
    color: bundle.color,
    background_color: bundle.background_color,
    underline: bundle.underline,
    underline_color: bundle.underline_color,
    strikethrough: bundle.strikethrough,
    strikethrough_color: bundle.strikethrough_color,
    layout: bundle.layout,
    bounds: bundle.bounds,
    line_height: bundle.line_height,
    font_hinting: bundle.font_hinting,
    shadow: bundle.shadow,
    transform: bundle.transform,
    layers: bundle.layers,
    view_visible: true,
    no_frustum_culling: bundle.no_frustum_culling,
    anchor: bundle.anchor,
    y_axis: bundle.y_axis,
    ui_node_size: None,
    logical_viewport_size: bundle.logical_viewport_size,
    scale_factor: 1.0F,
    ui_camera_entity: None,
    ui_scissor: None,
    cull_margin: text_compute_cull_margin(
      bundle.bounds,
      @math.Vec2::new(0.0F, 0.0F),
      bundle.transform.scale,
    ),
    spans: [],
    layout_dirty: true,
    computed: ComputedTextBlock::default(),
    layout_info: TextLayoutInfo::default(),
  })
  text_state.val.text_index_by_id.set(id, index)
  TextHandle::{ id, }
}

///|
pub fn text_spawn_span(
  parent : TextHandle,
  bundle : TextSpanBundle,
) -> TextSpanHandle {
  let span_id = text_state.val.next_span_id
  text_state.val.next_span_id = span_id + 1
  text_runtime_mark_layout_dirty()
  if text_state_find_index_by_id(parent.id) is Some(index) {
    let instance = text_state.val.texts[index]
    instance.spans.push(TextSpanInstance::{
      id: span_id,
      span: bundle.span,
      font: bundle.font,
      color: bundle.color,
      background_color: bundle.background_color,
      underline: bundle.underline,
      underline_color: bundle.underline_color,
      strikethrough: bundle.strikethrough,
      strikethrough_color: bundle.strikethrough_color,
      line_height: bundle.line_height,
    })
    text_state.val.texts[index] = TextInstance::{
      ..instance,
      spans: instance.spans,
      layout_dirty: true,
      computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
    }
  }
  TextSpanHandle::{ id: span_id }
}

///|
pub fn text_despawn(handle : TextHandle) -> Bool {
  guard text_state_find_index_by_id(handle.id) is Some(index) else {
    return false
  }
  let last_index = text_state.val.texts.length() - 1
  if index != last_index {
    let moved = text_state.val.texts[last_index]
    text_state.val.texts[index] = moved
    text_state.val.text_index_by_id.set(moved.id, index)
  }
  ignore(text_state.val.texts.pop())
  ignore(text_state.val.text_index_by_id.remove(handle.id))
  if text_debug_frame_state.val.draws.length() > 0 {
    let next_draws : Array[TextDebugGlyphDraw] = []
    for draw in text_debug_frame_state.val.draws {
      if draw.text_id != handle.id {
        next_draws.push(draw)
      }
    }
    text_debug_frame_state.val.draws.clear()
    for draw in next_draws {
      text_debug_frame_state.val.draws.push(draw)
    }
  }
  true
}

///|
fn text_update_instance(
  handle : TextHandle,
  update : (TextInstance) -> TextInstance,
) -> Unit {
  if text_state_find_index_by_id(handle.id) is Some(index) {
    text_state.val.texts[index] = update(text_state.val.texts[index])
  }
}

///|
fn text_state_transform_eq(
  lhs : @transform.Transform,
  rhs : @transform.Transform,
) -> Bool {
  lhs.translation.x == rhs.translation.x &&
  lhs.translation.y == rhs.translation.y &&
  lhs.translation.z == rhs.translation.z &&
  lhs.rotation.x == rhs.rotation.x &&
  lhs.rotation.y == rhs.rotation.y &&
  lhs.rotation.z == rhs.rotation.z &&
  lhs.rotation.w == rhs.rotation.w &&
  lhs.scale.x == rhs.scale.x &&
  lhs.scale.y == rhs.scale.y &&
  lhs.scale.z == rhs.scale.z
}

///|
fn text_state_entity_opt_eq(lhs : @core.Entity?, rhs : @core.Entity?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs_entity), Some(rhs_entity)) =>
      lhs_entity.id == rhs_entity.id &&
      lhs_entity.generation == rhs_entity.generation
    (None, None) => true
    _ => false
  }
}

///|
pub fn text_set_content(handle : TextHandle, content : String) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    text: Text2d::{ content, },
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_font(handle : TextHandle, font : TextFont) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    font,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_color(handle : TextHandle, color : TextColor) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    color,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_background_color(
  handle : TextHandle,
  background_color : TextBackgroundColor?,
) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    background_color,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_underline(handle : TextHandle, underline : Underline?) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    underline,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_underline_color(
  handle : TextHandle,
  underline_color : UnderlineColor?,
) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    underline_color,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_strikethrough(
  handle : TextHandle,
  strikethrough : Strikethrough?,
) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    strikethrough,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_strikethrough_color(
  handle : TextHandle,
  strikethrough_color : StrikethroughColor?,
) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    strikethrough_color,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_layout(handle : TextHandle, layout : TextLayout) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    layout,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_bounds(handle : TextHandle, bounds : TextBounds) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    bounds,
    cull_margin: text_compute_cull_margin(
      bounds,
      instance.layout_info.size,
      instance.transform.scale,
    ),
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_line_height(
  handle : TextHandle,
  line_height : LineHeight,
) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    line_height,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_font_hinting(
  handle : TextHandle,
  font_hinting : FontHinting,
) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    font_hinting,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
pub fn text_set_shadow(handle : TextHandle, shadow : Text2dShadow?) -> Unit {
  text_runtime_mark_layout_dirty()
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    shadow,
    layout_dirty: true,
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
/// Update the transform of a text handle without marking it as needing rerender.
pub fn text_set_transform(
  handle : TextHandle,
  transform : @transform.Transform,
) -> Unit {
  text_update_instance(handle, instance => {
    if text_state_transform_eq(instance.transform, transform) {
      instance
    } else {
      TextInstance::{
        ..instance,
        transform,
        cull_margin: text_compute_cull_margin(
          instance.bounds,
          instance.layout_info.size,
          transform.scale,
        ),
      }
    }
  })
}

///|
/// Get the current transform for a text handle.
pub fn text_get_transform(handle : TextHandle) -> @transform.Transform? {
  if text_state_find_index_by_id(handle.id) is Some(index) {
    return Some(text_state.val.texts[index].transform)
  }
  None
}

///|
/// Update the render layers of a text handle without marking it as needing rerender.
pub fn text_set_layers(
  handle : TextHandle,
  layers : @sprite.RenderLayers,
) -> Unit {
  text_update_instance(handle, instance => {
    if instance.layers.mask == layers.mask {
      instance
    } else {
      TextInstance::{ ..instance, layers, }
    }
  })
}

///|
/// Update the extracted `ViewVisibility` of a text handle without marking rerender.
pub fn text_set_view_visible(handle : TextHandle, view_visible : Bool) -> Unit {
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    view_visible,
  })
}

///|
/// Update the frustum-culling marker of a text handle without marking rerender.
pub fn text_set_no_frustum_culling(
  handle : TextHandle,
  no_frustum_culling : Bool,
) -> Unit {
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    no_frustum_culling,
  })
}

///|
/// Update the anchor of a text handle without marking it as needing rerender.
pub fn text_set_anchor(handle : TextHandle, anchor : @sprite.Anchor) -> Unit {
  text_update_instance(handle, instance => TextInstance::{ ..instance, anchor, })
}

///|
/// Update the y-axis orientation of a text handle without marking it as needing rerender.
pub fn text_set_y_axis(handle : TextHandle, y_axis : YAxisOrientation) -> Unit {
  // Orientation affects glyph coordinates, so we must relayout.
  text_update_instance(handle, instance => {
    if instance.y_axis == y_axis {
      instance
    } else {
      text_runtime_mark_layout_dirty()
      TextInstance::{
        ..instance,
        y_axis,
        layout_dirty: true,
        computed: ComputedTextBlock::{
          ..instance.computed,
          needs_rerender: true,
        },
      }
    }
  })
}

///| Mark a text handle as UI text and provide the size of the owning UI node in logical pixels.

///|
/// This does not affect shaping, but it changes how glyphs are positioned when rendered.
pub fn text_set_ui_node_size(handle : TextHandle, size : @math.Vec2?) -> Unit {
  text_update_instance(handle, instance => {
    if text_state_vec2_opt_eq(instance.ui_node_size, size) {
      instance
    } else {
      text_runtime_mark_layout_dirty()
      TextInstance::{
        ..instance,
        ui_node_size: size,
        layout_dirty: true,
        computed: ComputedTextBlock::{
          ..instance.computed,
          needs_rerender: true,
        },
      }
    }
  })
}

///|
fn text_state_vec2_opt_eq(lhs : @math.Vec2?, rhs : @math.Vec2?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => lhs.x == rhs.x && lhs.y == rhs.y
    (None, None) => true
    _ => false
  }
}

///|
fn text_state_safe_scale_factor(scale_factor : Float) -> Float {
  if scale_factor <= 0.0F {
    1.0F
  } else {
    scale_factor
  }
}

///|
pub fn text_set_logical_viewport_size(
  handle : TextHandle,
  logical_viewport_size : @math.Vec2?,
) -> Unit {
  text_update_instance(handle, instance => {
    if text_state_vec2_opt_eq(
        instance.logical_viewport_size,
        logical_viewport_size,
      ) {
      instance
    } else {
      text_runtime_mark_layout_dirty()
      TextInstance::{
        ..instance,
        logical_viewport_size,
        layout_dirty: true,
        computed: ComputedTextBlock::{
          ..instance.computed,
          needs_rerender: true,
        },
      }
    }
  })
}

///|
pub fn text_set_scale_factor(handle : TextHandle, scale_factor : Float) -> Unit {
  let safe_scale_factor = text_state_safe_scale_factor(scale_factor)
  text_update_instance(handle, instance => {
    if text_absf(instance.scale_factor - safe_scale_factor) <= 0.00001F {
      instance
    } else {
      text_runtime_mark_layout_dirty()
      TextInstance::{
        ..instance,
        scale_factor: safe_scale_factor,
        layout_dirty: true,
        computed: ComputedTextBlock::{
          ..instance.computed,
          needs_rerender: true,
        },
      }
    }
  })
}

///|
pub fn text_set_ui_camera_entity(
  handle : TextHandle,
  camera_entity : @core.Entity?,
) -> Unit {
  text_update_instance(handle, instance => {
    if text_state_entity_opt_eq(instance.ui_camera_entity, camera_entity) {
      instance
    } else {
      TextInstance::{ ..instance, ui_camera_entity: camera_entity }
    }
  })
}

///|
/// Set optional UI clip rect for a text handle.
pub fn text_set_ui_scissor(handle : TextHandle, scissor : @math.Rect?) -> Unit {
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    ui_scissor: scissor,
  })
}

///|
/// Get current optional UI clip rect for a text handle.
pub fn text_get_ui_scissor(handle : TextHandle) -> @math.Rect? {
  if text_state_find_index_by_id(handle.id) is Some(index) {
    return text_state.val.texts[index].ui_scissor
  }
  None
}

///|
/// Get the last computed logical layout size (may lag by one frame).
pub fn text_get_layout_size(handle : TextHandle) -> @math.Vec2? {
  if text_state_find_index_by_id(handle.id) is Some(index) {
    return Some(text_state.val.texts[index].layout_info.size)
  }
  None
}

///|
pub fn text_set_runtime_rem_size(rem_size : Float) -> Unit {
  if text_runtime_rem_size_ref.val != rem_size {
    let count = text_state.val.texts.length()
    for i in 0..<count {
      let instance = text_state.val.texts[i]
      text_state.val.texts[i] = TextInstance::{ ..instance, layout_dirty: true }
    }
    text_runtime_mark_layout_dirty()
  }
  text_runtime_rem_size_ref.val = rem_size
}

///|
/// Get the current text content for a handle.
pub fn text_get_content(handle : TextHandle) -> String? {
  if text_state_find_index_by_id(handle.id) is Some(index) {
    return Some(text_state.val.texts[index].text.content)
  }
  None
}

///|
/// Compute current world-space visual bounds from positioned glyph quads.
///
/// This reflects the same transform path used by `text_render_system`, so UI
/// tests can assert the rendered placement instead of only transform center/z.
pub fn text_get_visual_bounds(handle : TextHandle) -> @math.Rect? {
  fn rotate_vec2(v : @math.Vec2, rot : Float) -> @math.Vec2 {
    let cosv = @math.cos(rot)
    let sinv = @math.sin(rot)
    @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
  }

  fn to_y_up(y_axis : YAxisOrientation, v : @math.Vec2) -> @math.Vec2 {
    match y_axis {
      YAxisOrientation::TopToBottom => @math.Vec2::new(v.x, 0.0F - v.y)
      YAxisOrientation::BottomToTop => v
    }
  }

  fn absf(v : Float) -> Float {
    if v < 0.0F {
      0.0F - v
    } else {
      v
    }
  }

  if text_state_find_index_by_id(handle.id) is Some(index) {
    let instance = text_state.val.texts[index]
    let glyphs = instance.layout_info.glyphs
    if glyphs.length() == 0 {
      return None
    }
    let rot = instance.transform.rotation_z()
    let scale = @math.Vec2::new(
      instance.transform.scale.x,
      instance.transform.scale.y,
    )
    let base = @math.Vec2::new(
      instance.transform.translation.x,
      instance.transform.translation.y,
    )
    let layout_size = instance.layout_info.size
    let anchor_size = @math.Vec2::new(
      instance.bounds.width.unwrap_or(layout_size.x),
      instance.bounds.height.unwrap_or(layout_size.y),
    )
    let origin_offset_layout = match instance.ui_node_size {
      Some(node_size) =>
        @math.Vec2::new(0.0F - node_size.x / 2.0F, 0.0F - node_size.y / 2.0F)
      None => {
        let anchor = instance.anchor.as_vec()
        match instance.y_axis {
          YAxisOrientation::TopToBottom =>
            @math.Vec2::new(
              (0.0F - 0.5F - anchor.x) * anchor_size.x,
              (0.5F - anchor.y) * anchor_size.y,
            )
          YAxisOrientation::BottomToTop =>
            @math.Vec2::new(
              (0.0F - 0.5F - anchor.x) * anchor_size.x,
              (0.0F - 0.5F - anchor.y) * anchor_size.y,
            )
        }
      }
    }
    let origin_offset = match (instance.y_axis, instance.ui_node_size) {
      (YAxisOrientation::TopToBottom, None) => origin_offset_layout
      _ => to_y_up(instance.y_axis, origin_offset_layout)
    }
    fn extend_with_point(
      p : @math.Vec2,
      min_x : Ref[Float],
      min_y : Ref[Float],
      max_x : Ref[Float],
      max_y : Ref[Float],
      initialized : Ref[Bool],
    ) -> Unit {
      if !initialized.val {
        min_x.val = p.x
        min_y.val = p.y
        max_x.val = p.x
        max_y.val = p.y
        initialized.val = true
        return
      }
      if p.x < min_x.val {
        min_x.val = p.x
      }
      if p.y < min_y.val {
        min_y.val = p.y
      }
      if p.x > max_x.val {
        max_x.val = p.x
      }
      if p.y > max_y.val {
        max_y.val = p.y
      }
    }

    let min_x_ref = Ref(0.0F)
    let min_y_ref = Ref(0.0F)
    let max_x_ref = Ref(0.0F)
    let max_y_ref = Ref(0.0F)
    let initialized_ref = Ref(false)
    for glyph in glyphs {
      let glyph_pos = to_y_up(instance.y_axis, glyph.position)
      let local_pos = @math.Vec2::new(
        origin_offset.x + glyph_pos.x,
        origin_offset.y + glyph_pos.y,
      )
      let local_scaled = @math.Vec2::new(
        local_pos.x * scale.x,
        local_pos.y * scale.y,
      )
      let center_offset = rotate_vec2(local_scaled, rot)
      let center = @math.Vec2::new(
        base.x + center_offset.x,
        base.y + center_offset.y,
      )
      let half_w = absf(glyph.size.x * scale.x) / 2.0F
      let half_h = absf(glyph.size.y * scale.y) / 2.0F
      let c0 = rotate_vec2(@math.Vec2::new(0.0F - half_w, 0.0F - half_h), rot)
      let c1 = rotate_vec2(@math.Vec2::new(half_w, 0.0F - half_h), rot)
      let c2 = rotate_vec2(@math.Vec2::new(half_w, half_h), rot)
      let c3 = rotate_vec2(@math.Vec2::new(0.0F - half_w, half_h), rot)
      extend_with_point(
        @math.Vec2::new(center.x + c0.x, center.y + c0.y),
        min_x_ref,
        min_y_ref,
        max_x_ref,
        max_y_ref,
        initialized_ref,
      )
      extend_with_point(
        @math.Vec2::new(center.x + c1.x, center.y + c1.y),
        min_x_ref,
        min_y_ref,
        max_x_ref,
        max_y_ref,
        initialized_ref,
      )
      extend_with_point(
        @math.Vec2::new(center.x + c2.x, center.y + c2.y),
        min_x_ref,
        min_y_ref,
        max_x_ref,
        max_y_ref,
        initialized_ref,
      )
      extend_with_point(
        @math.Vec2::new(center.x + c3.x, center.y + c3.y),
        min_x_ref,
        min_y_ref,
        max_x_ref,
        max_y_ref,
        initialized_ref,
      )
    }
    if !initialized_ref.val {
      return None
    }
    return Some(
      @math.Rect::new(
        @math.Vec2::new(min_x_ref.val, min_y_ref.val),
        @math.Vec2::new(max_x_ref.val, max_y_ref.val),
      ),
    )
  }
  None
}
