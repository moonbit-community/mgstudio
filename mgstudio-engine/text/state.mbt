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
pub struct TextHandle {
  id : Int
}

///|
pub fn TextHandle::new(id : Int) -> TextHandle {
  TextHandle::{ id, }
}

///|
pub fn TextHandle::id(self : TextHandle) -> Int {
  self.id
}

///|
pub struct TextSpanHandle {
  id : Int
}

///|
pub fn TextSpanHandle::new(id : Int) -> TextSpanHandle {
  TextSpanHandle::{ id, }
}

///|
pub struct Text2dBundle {
  text : Text2d
  font : TextFont
  color : TextColor
  layout : TextLayout
  bounds : TextBounds
  line_height : LineHeight
  shadow : Text2dShadow?
  transform : @math.Transform
  layers : @render2d.RenderLayers
  anchor : @render2d.Anchor
  y_axis : YAxisOrientation
}

///|
pub fn Text2dBundle::new(
  text : Text2d,
  font : TextFont,
  transform : @math.Transform,
) -> Text2dBundle {
  Text2dBundle::{
    text,
    font,
    color: TextColor::default(),
    layout: TextLayout::default(),
    bounds: TextBounds::default(),
    line_height: LineHeight::default(),
    shadow: None,
    transform,
    layers: @render2d.RenderLayers::default(),
    anchor: @render2d.Anchor::default(),
    y_axis: YAxisOrientation::BottomToTop,
  }
}

///|
pub fn Text2dBundle::new_with_layers(
  text : Text2d,
  font : TextFont,
  transform : @math.Transform,
  layers : @render2d.RenderLayers,
) -> Text2dBundle {
  Text2dBundle::{
    text,
    font,
    color: TextColor::default(),
    layout: TextLayout::default(),
    bounds: TextBounds::default(),
    line_height: LineHeight::default(),
    shadow: None,
    transform,
    layers,
    anchor: @render2d.Anchor::default(),
    y_axis: YAxisOrientation::BottomToTop,
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
  anchor : @render2d.Anchor,
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
  line_height : LineHeight
}

///|
pub fn TextSpanBundle::new(span : TextSpan, font : TextFont) -> TextSpanBundle {
  TextSpanBundle::{
    span,
    font,
    color: TextColor::default(),
    line_height: LineHeight::default(),
  }
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
  line_height : LineHeight
}

///|
priv struct TextInstance {
  id : Int
  text : Text2d
  font : TextFont
  color : TextColor
  layout : TextLayout
  bounds : TextBounds
  line_height : LineHeight
  shadow : Text2dShadow?
  transform : @math.Transform
  layers : @render2d.RenderLayers
  anchor : @render2d.Anchor
  y_axis : YAxisOrientation
  /// When set, this text handle is treated as "UI text" and will be positioned
  /// relative to a UI node's top-left corner (Bevy UI extraction semantics).
  ui_node_size : @math.Vec2?
  /// Optional UI clip rect (logical UI space) propagated from `ui_clip_system`.
  /// When present, glyph sprites are submitted with scissor.
  ui_scissor : @math.Rect?
  spans : Array[TextSpanInstance]
  computed : ComputedTextBlock
  layout_info : TextLayoutInfo
}

///|
priv struct TextState {
  mut next_text_id : Int
  mut next_span_id : Int
  texts : Array[TextInstance]
}

///|
let text_state : Ref[TextState] = Ref::new(TextState::{
  next_text_id: 0,
  next_span_id: 0,
  texts: [],
})

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
let text_debug_frame_state : Ref[TextDebugFrameState] = Ref::new(TextDebugFrameState::{
  draws: [],
})

///|
pub fn text_debug_clear_frame() -> Unit {
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
  text_state.val.next_text_id = id + 1
  text_state.val.texts.push(TextInstance::{
    id,
    text: bundle.text,
    font: bundle.font,
    color: bundle.color,
    layout: bundle.layout,
    bounds: bundle.bounds,
    line_height: bundle.line_height,
    shadow: bundle.shadow,
    transform: bundle.transform,
    layers: bundle.layers,
    anchor: bundle.anchor,
    y_axis: bundle.y_axis,
    ui_node_size: None,
    ui_scissor: None,
    spans: [],
    computed: ComputedTextBlock::default(),
    layout_info: TextLayoutInfo::default(),
  })
  TextHandle::{ id, }
}

///|
pub fn text_spawn_span(
  parent : TextHandle,
  bundle : TextSpanBundle,
) -> TextSpanHandle {
  let span_id = text_state.val.next_span_id
  text_state.val.next_span_id = span_id + 1
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == parent.id {
      let instance = text_state.val.texts[i]
      instance.spans.push(TextSpanInstance::{
        id: span_id,
        span: bundle.span,
        font: bundle.font,
        color: bundle.color,
        line_height: bundle.line_height,
      })
      text_state.val.texts[i] = TextInstance::{
        ..instance,
        spans: instance.spans,
        computed: ComputedTextBlock::{
          ..instance.computed,
          needs_rerender: true,
        },
      }
      break
    }
  }
  TextSpanHandle::{ id: span_id }
}

///|
fn text_update_instance(
  handle : TextHandle,
  update : (TextInstance) -> TextInstance,
) -> Unit {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == handle.id {
      text_state.val.texts[i] = update(text_state.val.texts[i])
      break
    }
  }
}

///|
pub fn text_set_content(handle : TextHandle, content : String) -> Unit {
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    text: Text2d::{ content, },
    computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
  })
}

///|
/// Update the transform of a text handle without marking it as needing rerender.
pub fn text_set_transform(
  handle : TextHandle,
  transform : @math.Transform,
) -> Unit {
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    transform,
  })
}

///|
/// Get the current transform for a text handle.
pub fn text_get_transform(handle : TextHandle) -> @math.Transform? {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == handle.id {
      return Some(text_state.val.texts[i].transform)
    }
  }
  None
}

///|
/// Update the render layers of a text handle without marking it as needing rerender.
pub fn text_set_layers(
  handle : TextHandle,
  layers : @render2d.RenderLayers,
) -> Unit {
  text_update_instance(handle, instance => TextInstance::{ ..instance, layers, })
}

///|
/// Update the anchor of a text handle without marking it as needing rerender.
pub fn text_set_anchor(handle : TextHandle, anchor : @render2d.Anchor) -> Unit {
  text_update_instance(handle, instance => TextInstance::{ ..instance, anchor, })
}

///|
/// Update the y-axis orientation of a text handle without marking it as needing rerender.
pub fn text_set_y_axis(handle : TextHandle, y_axis : YAxisOrientation) -> Unit {
  // Orientation affects glyph coordinates, so we must relayout.
  text_update_instance(handle, instance => if instance.y_axis == y_axis {
    instance
  } else {
    TextInstance::{
      ..instance,
      y_axis,
      computed: ComputedTextBlock::{ ..instance.computed, needs_rerender: true },
    }
  })
}

///| Mark a text handle as UI text and provide the size of the owning UI node in logical pixels.

///|

///|
/// This does not affect shaping, but it changes how glyphs are positioned when rendered.
pub fn text_set_ui_node_size(handle : TextHandle, size : @math.Vec2?) -> Unit {
  text_update_instance(handle, instance => TextInstance::{
    ..instance,
    ui_node_size: size,
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
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == handle.id {
      return text_state.val.texts[i].ui_scissor
    }
  }
  None
}

///|
/// Get the last computed logical layout size (may lag by one frame).
pub fn text_get_layout_size(handle : TextHandle) -> @math.Vec2? {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == handle.id {
      return Some(text_state.val.texts[i].layout_info.size)
    }
  }
  None
}

///|
/// Get the current text content for a handle.
pub fn text_get_content(handle : TextHandle) -> String? {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id == handle.id {
      return Some(text_state.val.texts[i].text.content)
    }
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

  let count = text_state.val.texts.length()
  for i in 0..<count {
    if text_state.val.texts[i].id != handle.id {
      continue
    }
    let instance = text_state.val.texts[i]
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
    let origin_offset_layout = match instance.ui_node_size {
      Some(node_size) =>
        @math.Vec2::new(0.0F - node_size.x / 2.0F, 0.0F - node_size.y / 2.0F)
      None => {
        let anchor = instance.anchor.as_vec()
        let text_anchor = @math.Vec2::new(
          0.0F - (anchor.x + 0.5F),
          0.0F - (anchor.y + 0.5F),
        )
        @math.Vec2::new(
          layout_size.x * text_anchor.x,
          layout_size.y * text_anchor.y,
        )
      }
    }
    let origin_offset = to_y_up(instance.y_axis, origin_offset_layout)
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

    let min_x_ref = Ref::new(0.0F)
    let min_y_ref = Ref::new(0.0F)
    let max_x_ref = Ref::new(0.0F)
    let max_y_ref = Ref::new(0.0F)
    let initialized_ref = Ref::new(false)
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
