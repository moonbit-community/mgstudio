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
// Bevy source: `bevy/crates/bevy_sprite_render/src/text2d/mod.rs`.
//
// `text_render_system` is the `extract_text2d_sprite` equivalent: it walks the
// laid-out text instances owned by `text` (the `bevy_text` owner) and extracts
// span backgrounds/underlines/strikethroughs as single overlay quads plus
// glyph runs as texture-batched slice batches -- the same
// `ExtractedSprite`/`ExtractedSpriteKind::Slices` split Bevy produces. Span
// color and decoration resolution happens here, matching Bevy's
// `text_colors`/`decoration_query` lookups inside the extractor.
//
// Known deviation (ISS-480): Bevy splits UI text extraction into
// `bevy_ui_render` (`extract_text_sections`); mgstudio's extractor is fused
// over both world-space `Text2d` instances (`ui_node_size == None`) and UI
// text instances, so the UI half is co-located here until that split lands.

///|
priv struct Text2dRenderRuntimeState {
  mut diagnostic_render_cpu_ms : Float
  mut diagnostic_render_visible_text_count : Int
  mut diagnostic_render_culled_text_count : Int
  mut diagnostic_render_submitted_item_count : Int
  overlay_sprites_cache : Array[@sprite_render.OverlaySpriteUvScissor]
  overlay_sprite_slices_batches_cache : Array[
    @sprite_render.OverlaySpriteUvScissorSlices,
  ]
  mut prepared_scene_overlay_sprites : Array[
    @sprite_render.OverlaySpriteUvScissor,
  ]
  mut prepared_ui_overlay_sprites : Array[@sprite_render.OverlaySpriteUvScissor]
  mut prepared_scene_overlay_sprite_slices_batches : Array[
    @sprite_render.OverlaySpriteUvScissorSlices,
  ]
  mut prepared_ui_overlay_sprite_slices_batches : Array[
    @sprite_render.OverlaySpriteUvScissorSlices,
  ]
}

///|
let text2d_render_runtime_state : Text2dRenderRuntimeState = {
  diagnostic_render_cpu_ms: 0.0F,
  diagnostic_render_visible_text_count: 0,
  diagnostic_render_culled_text_count: 0,
  diagnostic_render_submitted_item_count: 0,
  overlay_sprites_cache: [],
  overlay_sprite_slices_batches_cache: [],
  prepared_scene_overlay_sprites: [],
  prepared_ui_overlay_sprites: [],
  prepared_scene_overlay_sprite_slices_batches: [],
  prepared_ui_overlay_sprite_slices_batches: [],
}

///|
priv struct OverlaySpriteSliceBatchBounds {
  mut has_bounds : Bool
  mut min_x : Float
  mut min_y : Float
  mut max_x : Float
  mut max_y : Float
}

///|
fn OverlaySpriteSliceBatchBounds::OverlaySpriteSliceBatchBounds() -> OverlaySpriteSliceBatchBounds {
  { has_bounds: false, min_x: 0.0F, min_y: 0.0F, max_x: 0.0F, max_y: 0.0F }
}

///|
fn OverlaySpriteSliceBatchBounds::expand(
  self : OverlaySpriteSliceBatchBounds,
  point : @math.Vec2,
) -> Unit {
  if !self.has_bounds {
    self.has_bounds = true
    self.min_x = point.x
    self.max_x = point.x
    self.min_y = point.y
    self.max_y = point.y
    return
  }
  if point.x < self.min_x {
    self.min_x = point.x
  }
  if point.x > self.max_x {
    self.max_x = point.x
  }
  if point.y < self.min_y {
    self.min_y = point.y
  }
  if point.y > self.max_y {
    self.max_y = point.y
  }
}

///|
fn OverlaySpriteSliceBatchBounds::clear(
  self : OverlaySpriteSliceBatchBounds,
) -> Unit {
  self.has_bounds = false
  self.min_x = 0.0F
  self.min_y = 0.0F
  self.max_x = 0.0F
  self.max_y = 0.0F
}

///|
fn OverlaySpriteSliceBatchBounds::center(
  self : OverlaySpriteSliceBatchBounds,
) -> @math.Vec2 {
  if !self.has_bounds {
    return @math.Vec2::new(0.0F, 0.0F)
  }
  @math.Vec2::new(
    (self.min_x + self.max_x) * 0.5F,
    (self.min_y + self.max_y) * 0.5F,
  )
}

///|
fn OverlaySpriteSliceBatchBounds::half_size(
  self : OverlaySpriteSliceBatchBounds,
) -> @math.Vec2 {
  if !self.has_bounds {
    return @math.Vec2::new(0.0F, 0.0F)
  }
  @math.Vec2::new(
    (self.max_x - self.min_x) * 0.5F,
    (self.max_y - self.min_y) * 0.5F,
  )
}

///|
fn text_absf(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn text_scene_item_visible(
  center_x : Float,
  center_y : Float,
  cosv : Float,
  sinv : Float,
  half_width : Float,
  half_height : Float,
  x : Float,
  y : Float,
  radius : Float,
) -> Bool {
  let dx = x - center_x
  let dy = y - center_y
  let local_x = dx * cosv + dy * sinv
  let local_y = -dx * sinv + dy * cosv
  text_absf(local_x) <= half_width + radius &&
  text_absf(local_y) <= half_height + radius
}

///|
fn text_rotate_vec2(v : @math.Vec2, cosv : Float, sinv : Float) -> @math.Vec2 {
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
fn text_to_y_up(y_axis : @text.YAxisOrientation, v : @math.Vec2) -> @math.Vec2 {
  match y_axis {
    TopToBottom => @math.Vec2::new(v.x, 0.0F - v.y)
    BottomToTop => v
  }
}

///|
fn text_glyph_world_bounds(
  center : @math.Vec2,
  glyph_size : @math.Vec2,
  scale : @math.Vec2,
  rotation : Float,
) -> @math.Rect {
  let rotation_cos = @math.cos(rotation)
  let rotation_sin = @math.sin(rotation)
  let half = @math.Vec2::new(
    glyph_size.x * text_absf(scale.x) / 2.0F,
    glyph_size.y * text_absf(scale.y) / 2.0F,
  )
  let p0 = text_rotate_vec2(
    @math.Vec2::new(0.0F - half.x, 0.0F - half.y),
    rotation_cos,
    rotation_sin,
  )
  let p1 = text_rotate_vec2(
    @math.Vec2::new(half.x, 0.0F - half.y),
    rotation_cos,
    rotation_sin,
  )
  let p2 = text_rotate_vec2(
    @math.Vec2::new(half.x, half.y),
    rotation_cos,
    rotation_sin,
  )
  let p3 = text_rotate_vec2(
    @math.Vec2::new(0.0F - half.x, half.y),
    rotation_cos,
    rotation_sin,
  )
  let x0 = center.x + p0.x
  let y0 = center.y + p0.y
  let x1 = center.x + p1.x
  let y1 = center.y + p1.y
  let x2 = center.x + p2.x
  let y2 = center.y + p2.y
  let x3 = center.x + p3.x
  let y3 = center.y + p3.y
  let mut min_x = x0
  let mut max_x = x0
  let mut min_y = y0
  let mut max_y = y0
  if x1 < min_x {
    min_x = x1
  }
  if x2 < min_x {
    min_x = x2
  }
  if x3 < min_x {
    min_x = x3
  }
  if x1 > max_x {
    max_x = x1
  }
  if x2 > max_x {
    max_x = x2
  }
  if x3 > max_x {
    max_x = x3
  }
  if y1 < min_y {
    min_y = y1
  }
  if y2 < min_y {
    min_y = y2
  }
  if y3 < min_y {
    min_y = y3
  }
  if y1 > max_y {
    max_y = y1
  }
  if y2 > max_y {
    max_y = y2
  }
  if y3 > max_y {
    max_y = y3
  }
  @math.Rect::new(@math.Vec2::new(min_x, min_y), @math.Vec2::new(max_x, max_y))
}

///|
fn text_glyph_world_translation(
  glyph : @text.PositionedGlyph,
  top_to_bottom_y_axis : Bool,
  no_rotation : Bool,
  scale : @math.Vec2,
  text_origin : @math.Vec2,
  rot_cos : Float,
  rot_sin : Float,
) -> @math.Vec2 {
  let glyph_pos = if top_to_bottom_y_axis {
    @math.Vec2::new(glyph.position.x, 0.0F - glyph.position.y)
  } else {
    glyph.position
  }
  if no_rotation {
    return @math.Vec2::new(
      text_origin.x + glyph_pos.x * scale.x,
      text_origin.y + glyph_pos.y * scale.y,
    )
  }
  let local_scaled = @math.Vec2::new(
    glyph_pos.x * scale.x,
    glyph_pos.y * scale.y,
  )
  let offset = text_rotate_vec2(local_scaled, rot_cos, rot_sin)
  @math.Vec2::new(text_origin.x + offset.x, text_origin.y + offset.y)
}

///|
// Bevy resolves per-span styling inside `extract_text2d_sprite` via the
// `text_colors` and `decoration_query` lookups; these helpers are that
// resolution over the retained span instances.
fn text_span_color(
  instance : @text.TextInstance,
  span_index : Int,
) -> @text.TextColor {
  if span_index == 0 {
    instance.color
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].color
    } else {
      instance.color
    }
  }
}

///|
fn text_span_background_color(
  instance : @text.TextInstance,
  span_index : Int,
) -> @text.TextBackgroundColor? {
  if span_index == 0 {
    instance.background_color
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].background_color
    } else {
      instance.background_color
    }
  }
}

///|
fn text_span_underline_color(
  instance : @text.TextInstance,
  span_index : Int,
) -> @text.UnderlineColor? {
  if span_index == 0 {
    instance.underline_color
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].underline_color
    } else {
      instance.underline_color
    }
  }
}

///|
fn text_span_has_underline(
  instance : @text.TextInstance,
  span_index : Int,
) -> Bool {
  if span_index == 0 {
    instance.underline is Some(_)
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].underline is Some(_)
    } else {
      instance.underline is Some(_)
    }
  }
}

///|
fn text_span_strikethrough_color(
  instance : @text.TextInstance,
  span_index : Int,
) -> @text.StrikethroughColor? {
  if span_index == 0 {
    instance.strikethrough_color
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].strikethrough_color
    } else {
      instance.strikethrough_color
    }
  }
}

///|
fn text_span_has_strikethrough(
  instance : @text.TextInstance,
  span_index : Int,
) -> Bool {
  if span_index == 0 {
    instance.strikethrough is Some(_)
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].strikethrough is Some(_)
    } else {
      instance.strikethrough is Some(_)
    }
  }
}

///|
fn text_instance_has_run_overlays(instance : @text.TextInstance) -> Bool {
  if instance.background_color is Some(_) ||
    instance.underline is Some(_) ||
    instance.strikethrough is Some(_) {
    return true
  }
  for span in instance.spans {
    if span.background_color is Some(_) ||
      span.underline is Some(_) ||
      span.strikethrough is Some(_) {
      return true
    }
  }
  false
}

///|
fn text_push_overlay_sprite_slice_batch(
  batches : Array[@sprite_render.OverlaySpriteUvScissorSlices],
  texture_opt : @asset.Handle[@asset.Image]?,
  rotation : Float,
  draw_scale : @math.Vec2,
  z : Float,
  color : @color.Color,
  cull_center : @math.Vec2,
  cull_half_size : @math.Vec2,
  layers : @camera_render_layers.RenderLayers,
  scissor : @math.Rect?,
  target_camera : @core.Entity?,
  slices_xy_uv : Array[Float],
) -> Unit {
  guard texture_opt is Some(texture) else { return }
  if slices_xy_uv.length() == 0 {
    return
  }
  batches.push({
    texture,
    rotation,
    draw_scale,
    z,
    color,
    cull_center,
    cull_half_size,
    layers,
    scissor,
    target_camera,
    slices_xy_uv,
  })
}

///|
fn text_overlay_sprite_slice_scissor_eq(
  lhs : @math.Rect?,
  rhs : @math.Rect?,
) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (Some(a), Some(b)) =>
      a.min.x == b.min.x &&
      a.min.y == b.min.y &&
      a.max.x == b.max.x &&
      a.max.y == b.max.y
    _ => false
  }
}

///|
fn text_overlay_sprite_slice_target_camera_eq(
  lhs : @core.Entity?,
  rhs : @core.Entity?,
) -> Bool {
  match (lhs, rhs) {
    (None, None) => true
    (Some(a), Some(b)) => a.id == b.id && a.generation == b.generation
    _ => false
  }
}

///|
fn text_overlay_sprite_slice_batch_can_merge(
  lhs : @sprite_render.OverlaySpriteUvScissorSlices,
  rhs : @sprite_render.OverlaySpriteUvScissorSlices,
) -> Bool {
  lhs.texture.id() == rhs.texture.id() &&
  lhs.rotation == rhs.rotation &&
  lhs.draw_scale.x == rhs.draw_scale.x &&
  lhs.draw_scale.y == rhs.draw_scale.y &&
  lhs.z == rhs.z &&
  lhs.color.r == rhs.color.r &&
  lhs.color.g == rhs.color.g &&
  lhs.color.b == rhs.color.b &&
  lhs.color.a == rhs.color.a &&
  lhs.layers.mask == rhs.layers.mask &&
  text_overlay_sprite_slice_scissor_eq(lhs.scissor, rhs.scissor) &&
  text_overlay_sprite_slice_target_camera_eq(
    lhs.target_camera,
    rhs.target_camera,
  )
}

///|
fn text_overlay_sprite_slice_batch_union_bounds(
  lhs_center : @math.Vec2,
  lhs_half_size : @math.Vec2,
  rhs_center : @math.Vec2,
  rhs_half_size : @math.Vec2,
) -> (@math.Vec2, @math.Vec2) {
  let lhs_min_x = lhs_center.x - lhs_half_size.x
  let lhs_min_y = lhs_center.y - lhs_half_size.y
  let lhs_max_x = lhs_center.x + lhs_half_size.x
  let lhs_max_y = lhs_center.y + lhs_half_size.y
  let rhs_min_x = rhs_center.x - rhs_half_size.x
  let rhs_min_y = rhs_center.y - rhs_half_size.y
  let rhs_max_x = rhs_center.x + rhs_half_size.x
  let rhs_max_y = rhs_center.y + rhs_half_size.y
  let min_x = if lhs_min_x < rhs_min_x { lhs_min_x } else { rhs_min_x }
  let min_y = if lhs_min_y < rhs_min_y { lhs_min_y } else { rhs_min_y }
  let max_x = if lhs_max_x > rhs_max_x { lhs_max_x } else { rhs_max_x }
  let max_y = if lhs_max_y > rhs_max_y { lhs_max_y } else { rhs_max_y }
  let center = @math.Vec2::new((min_x + max_x) / 2.0F, (min_y + max_y) / 2.0F)
  let half_size = @math.Vec2::new(
    (max_x - min_x) / 2.0F,
    (max_y - min_y) / 2.0F,
  )
  (center, half_size)
}

///|
fn text_append_overlay_sprite_slice_batch(
  batches : Array[@sprite_render.OverlaySpriteUvScissorSlices],
  batch : @sprite_render.OverlaySpriteUvScissorSlices,
) -> Unit {
  let batch_count = batches.length()
  if batch_count == 0 {
    batches.push(batch)
    return
  }
  let last_index = batch_count - 1
  let last_batch = batches[last_index]
  if !text_overlay_sprite_slice_batch_can_merge(last_batch, batch) {
    batches.push(batch)
    return
  }
  let merged_slices_xy_uv = last_batch.slices_xy_uv
  merged_slices_xy_uv.reserve_capacity(
    merged_slices_xy_uv.length() + batch.slices_xy_uv.length(),
  )
  for value in batch.slices_xy_uv {
    merged_slices_xy_uv.push(value)
  }
  let (merged_center, merged_half_size) = text_overlay_sprite_slice_batch_union_bounds(
    last_batch.cull_center,
    last_batch.cull_half_size,
    batch.cull_center,
    batch.cull_half_size,
  )
  batches[last_index] = {
    texture: last_batch.texture,
    rotation: last_batch.rotation,
    draw_scale: last_batch.draw_scale,
    z: last_batch.z,
    color: last_batch.color,
    cull_center: merged_center,
    cull_half_size: merged_half_size,
    layers: last_batch.layers,
    scissor: last_batch.scissor,
    target_camera: last_batch.target_camera,
    slices_xy_uv: merged_slices_xy_uv,
  }
}

///|
pub fn text_render_system(world : @ecs.World) -> Unit {
  let render_start = @time.host_time_now()
  @text.text_debug_clear_frame()
  let debug_capture_enabled = @text.text_debug_capture_enabled()
  let overlay_sprites = text2d_render_runtime_state.overlay_sprites_cache
  overlay_sprites.clear()
  let overlay_sprite_slices_batches = text2d_render_runtime_state.overlay_sprite_slices_batches_cache
  overlay_sprite_slices_batches.clear()
  let white_texture = @asset.asset_white_texture()
  let scene_cull_context = @sprite_render.render2d_primary_scene_cull_context(
    world,
  )
  let scene_cull_values : (Float, Float, Float, Float, Float, Float)? = match
    scene_cull_context {
    Some(context) =>
      Some(@sprite_render.render2d_scene_cull_context_values(context))
    None => None
  }
  let instances = @text.text_instances()
  let text_count = instances.length()
  let mut visible_text_count = 0
  let mut culled_text_count = 0
  for i in 0..<text_count {
    let instance = instances[i]
    if !instance.view_visible {
      culled_text_count = culled_text_count + 1
      continue
    }
    let layout_info = instance.layout_info
    let transform = instance.transform
    let glyph_count = layout_info.glyphs.length()
    let run_count = layout_info.run_geometry.length()
    let tx = transform.translation.x
    let ty = transform.translation.y
    let sx = transform.scale.x
    let sy = transform.scale.y
    let mut scene_visible = true
    // Bevy-aligned intent: skip `Text2d` work for off-screen text.
    // UI text (`ui_node_size` is `Some`) keeps existing UI-space behavior.
    if instance.ui_node_size is None && !instance.no_frustum_culling {
      if scene_cull_values
        is Some((center_x, center_y, cosv, sinv, half_width, half_height)) {
        if !text_scene_item_visible(
            center_x,
            center_y,
            cosv,
            sinv,
            half_width,
            half_height,
            tx,
            ty,
            instance.cull_margin,
          ) {
          scene_visible = false
        }
      }
    }
    if !scene_visible {
      culled_text_count = culled_text_count + 1
      continue
    }
    visible_text_count = visible_text_count + 1
    let bound_w = instance.bounds.width.unwrap_or(layout_info.size.x)
    let bound_h = instance.bounds.height.unwrap_or(layout_info.size.y)
    let scale = @math.Vec2::new(sx, sy)
    let base = @math.Vec2::new(tx, ty)
    let anchor_size = @math.Vec2::new(bound_w, bound_h)

    let rot = transform.rotation_z()
    let rot_cos = @math.cos(rot)
    let rot_sin = @math.sin(rot)

    // Bevy parity:
    // - Text2d: use `Anchor` + (`TextBounds` if set, otherwise `TextLayoutInfo.size`)
    //   to compute the local origin.
    // - UI text: treat `GlobalTransform`/`Transform` as the center of the UI node, then translate
    //   by (-0.5 * node_size) to convert to top-left origin.
    let mut origin_offset_layout = @math.Vec2::new(0.0F, 0.0F)
    if instance.ui_node_size is Some(node_size) {
      origin_offset_layout = @math.Vec2::new(
        0.0F - node_size.x / 2.0F,
        0.0F - node_size.y / 2.0F,
      )
    } else {
      let a = instance.anchor.as_vec()
      // Bevy parity: top_left = (Anchor::TOP_LEFT - anchor) * size
      // for the default TopToBottom layout orientation.
      origin_offset_layout = match instance.y_axis {
        TopToBottom =>
          @math.Vec2::new(
            (0.0F - 0.5F - a.x) * anchor_size.x,
            (0.5F - a.y) * anchor_size.y,
          )
        // Backward-compatible semantics for BottomToTop mode.
        BottomToTop =>
          @math.Vec2::new(
            (0.0F - 0.5F - a.x) * anchor_size.x,
            (0.0F - 0.5F - a.y) * anchor_size.y,
          )
      }
    }

    // Bevy parity for Text2d (`ui_node_size == None`):
    // - `top_left` translation is applied before the Y-flip scale, so it should not be Y-flipped.
    // For UI text we keep existing conversion semantics.
    let origin_offset = match (instance.y_axis, instance.ui_node_size) {
      (TopToBottom, None) => origin_offset_layout
      _ => text_to_y_up(instance.y_axis, origin_offset_layout)
    }
    let origin_scaled = @math.Vec2::new(
      origin_offset.x * scale.x,
      origin_offset.y * scale.y,
    )
    let origin_rotated = text_rotate_vec2(origin_scaled, rot_cos, rot_sin)
    let text_origin = @math.Vec2::new(
      base.x + origin_rotated.x,
      base.y + origin_rotated.y,
    )

    if text_instance_has_run_overlays(instance) {
      let run_inverse_scale_factor = 1.0F /
        @text.text_pipeline_safe_scale_factor(layout_info.scale_factor)
      let run_position_scale = @math.Vec2::new(
        scale.x * run_inverse_scale_factor,
        scale.y * run_inverse_scale_factor,
      )
      for run in layout_info.run_geometry {
        let run_center_layout = text_to_y_up(
          instance.y_axis,
          run.bounds.center(),
        )
        let run_center_scaled = @math.Vec2::new(
          run_center_layout.x * run_position_scale.x,
          run_center_layout.y * run_position_scale.y,
        )
        let run_center_offset = text_rotate_vec2(
          run_center_scaled, rot_cos, rot_sin,
        )
        let run_translation = @math.Vec2::new(
          text_origin.x + run_center_offset.x,
          text_origin.y + run_center_offset.y,
        )
        let run_size = run.bounds.size()
        let run_draw_scale = @math.Vec2::new(
          run_size.x * text_absf(run_position_scale.x),
          run_size.y * text_absf(run_position_scale.y),
        )
        if text_span_background_color(instance, run.span_index)
          is Some(background) &&
          run_draw_scale.x > 0.0F &&
          run_draw_scale.y > 0.0F {
          let background_transform = @transform.Transform::from_xy_rotation_scale(
            run_translation,
            rot,
            run_draw_scale,
            z=instance.transform.translation.z - 0.001F,
          )
          overlay_sprites.push({
            texture: white_texture,
            transform: background_transform,
            uv_min: @math.Vec2::new(0.0F, 0.0F),
            uv_max: @math.Vec2::new(1.0F, 1.0F),
            color: background.color,
            layers: instance.layers,
            scissor: instance.ui_scissor,
            target_camera: instance.ui_camera_entity,
          })
        }

        let span_color = text_span_color(instance, run.span_index).color
        let underline_color = match
          text_span_underline_color(instance, run.span_index) {
          Some(color) => color.color
          None => span_color
        }
        let strikethrough_color = match
          text_span_strikethrough_color(instance, run.span_index) {
          Some(color) => color.color
          None => span_color
        }
        if text_span_has_underline(instance, run.span_index) {
          let underline_position_layout = text_to_y_up(
            instance.y_axis,
            run.underline_position(),
          )
          let underline_scaled = @math.Vec2::new(
            underline_position_layout.x * run_position_scale.x,
            underline_position_layout.y * run_position_scale.y,
          )
          let underline_offset = text_rotate_vec2(
            underline_scaled, rot_cos, rot_sin,
          )
          let underline_translation = @math.Vec2::new(
            text_origin.x + underline_offset.x,
            text_origin.y + underline_offset.y,
          )
          let underline_size = run.underline_size()
          let underline_draw_scale = @math.Vec2::new(
            underline_size.x * text_absf(run_position_scale.x),
            underline_size.y * text_absf(run_position_scale.y),
          )
          if underline_draw_scale.x > 0.0F && underline_draw_scale.y > 0.0F {
            let underline_transform = @transform.Transform::from_xy_rotation_scale(
              underline_translation,
              rot,
              underline_draw_scale,
              z=instance.transform.translation.z + 0.0005F,
            )
            overlay_sprites.push({
              texture: white_texture,
              transform: underline_transform,
              uv_min: @math.Vec2::new(0.0F, 0.0F),
              uv_max: @math.Vec2::new(1.0F, 1.0F),
              color: underline_color,
              layers: instance.layers,
              scissor: instance.ui_scissor,
              target_camera: instance.ui_camera_entity,
            })
          }
        }

        if text_span_has_strikethrough(instance, run.span_index) {
          let strike_position_layout = text_to_y_up(
            instance.y_axis,
            run.strikethrough_position(),
          )
          let strike_scaled = @math.Vec2::new(
            strike_position_layout.x * run_position_scale.x,
            strike_position_layout.y * run_position_scale.y,
          )
          let strike_offset = text_rotate_vec2(strike_scaled, rot_cos, rot_sin)
          let strike_translation = @math.Vec2::new(
            text_origin.x + strike_offset.x,
            text_origin.y + strike_offset.y,
          )
          let strike_size = run.strikethrough_size()
          let strike_draw_scale = @math.Vec2::new(
            strike_size.x * text_absf(run_position_scale.x),
            strike_size.y * text_absf(run_position_scale.y),
          )
          if strike_draw_scale.x > 0.0F && strike_draw_scale.y > 0.0F {
            let strike_transform = @transform.Transform::from_xy_rotation_scale(
              strike_translation,
              rot,
              strike_draw_scale,
              z=instance.transform.translation.z + 0.0005F,
            )
            overlay_sprites.push({
              texture: white_texture,
              transform: strike_transform,
              uv_min: @math.Vec2::new(0.0F, 0.0F),
              uv_max: @math.Vec2::new(1.0F, 1.0F),
              color: strikethrough_color,
              layers: instance.layers,
              scissor: instance.ui_scissor,
              target_camera: instance.ui_camera_entity,
            })
          }
        }
      }
    }

    // Keep UI text origin in continuous space.
    // Snapping world-space origins introduces visible jitter when camera
    // viewport/scale changes dynamically (e.g. 2d_viewport_to_world).
    //
    // Bevy-aligned extraction optimization:
    // group consecutive glyphs into slice batches instead of submitting one
    // sprite item per glyph.
    let glyph_rotation = rot
    let glyph_inverse_scale_factor = 1.0F /
      @text.text_pipeline_safe_scale_factor(layout_info.scale_factor)
    let glyph_draw_scale = @math.Vec2::new(
      scale.x * glyph_inverse_scale_factor,
      scale.y * glyph_inverse_scale_factor,
    )
    let glyph_z = instance.transform.translation.z
    let shadow_opt = instance.shadow
    let top_to_bottom_y_axis = match instance.y_axis {
      TopToBottom => true
      BottomToTop => false
    }
    let no_rotation = rot > -0.000001F && rot < 0.000001F
    let mut cached_span_index = -1
    let mut cached_span_color = @color.Color::srgb(1.0F, 1.0F, 1.0F)

    let instance_main_batches : Array[
      @sprite_render.OverlaySpriteUvScissorSlices,
    ] = []
    let mut main_batch_slices_xy_uv : Array[Float] = []
    let mut main_batch_texture : @asset.Handle[@asset.Image]? = None
    let mut main_batch_texture_id = -1
    let mut main_batch_span_index = -1
    let mut main_batch_color = @color.Color::srgb(1.0F, 1.0F, 1.0F)
    let main_batch_bounds = OverlaySpriteSliceBatchBounds::OverlaySpriteSliceBatchBounds()
    instance_main_batches.reserve_capacity(run_count + 1)
    main_batch_slices_xy_uv.reserve_capacity(glyph_count * 6)

    let instance_shadow_batches : Array[
      @sprite_render.OverlaySpriteUvScissorSlices,
    ] = []
    let mut shadow_batch_slices_xy_uv : Array[Float] = []
    let mut shadow_batch_texture : @asset.Handle[@asset.Image]? = None
    let mut shadow_batch_texture_id = -1
    let shadow_batch_bounds = OverlaySpriteSliceBatchBounds::OverlaySpriteSliceBatchBounds()
    instance_shadow_batches.reserve_capacity(run_count + 1)
    if shadow_opt is Some(_) {
      shadow_batch_slices_xy_uv.reserve_capacity(glyph_count * 6)
    }

    for glyph in layout_info.glyphs {
      let atlas_info = glyph.atlas_info
      let uv_min = glyph.uv_min
      let uv_max = glyph.uv_max
      let translation = text_glyph_world_translation(
        glyph, top_to_bottom_y_axis, no_rotation, glyph_draw_scale, text_origin,
        rot_cos, rot_sin,
      )

      let color = if glyph.span_index == cached_span_index {
        cached_span_color
      } else {
        let span_color = text_span_color(instance, glyph.span_index).color
        cached_span_index = glyph.span_index
        cached_span_color = span_color
        span_color
      }

      let texture_id = atlas_info.texture.id()
      if main_batch_slices_xy_uv.length() > 0 &&
        (
          main_batch_texture_id != texture_id ||
          main_batch_span_index != glyph.span_index
        ) {
        text_push_overlay_sprite_slice_batch(
          instance_main_batches,
          main_batch_texture,
          glyph_rotation,
          glyph_draw_scale,
          glyph_z,
          main_batch_color,
          main_batch_bounds.center(),
          main_batch_bounds.half_size(),
          instance.layers,
          instance.ui_scissor,
          instance.ui_camera_entity,
          main_batch_slices_xy_uv,
        )
        main_batch_slices_xy_uv = []
        main_batch_bounds.clear()
      }
      if main_batch_slices_xy_uv.length() == 0 {
        main_batch_texture = Some(atlas_info.texture)
        main_batch_texture_id = texture_id
        main_batch_span_index = glyph.span_index
        main_batch_color = color
      }
      main_batch_bounds.expand(translation)
      main_batch_slices_xy_uv.push(translation.x)
      main_batch_slices_xy_uv.push(translation.y)
      main_batch_slices_xy_uv.push(uv_min.x)
      main_batch_slices_xy_uv.push(uv_min.y)
      main_batch_slices_xy_uv.push(uv_max.x)
      main_batch_slices_xy_uv.push(uv_max.y)

      if shadow_opt is Some(shadow) {
        if shadow_batch_slices_xy_uv.length() > 0 &&
          shadow_batch_texture_id != texture_id {
          text_push_overlay_sprite_slice_batch(
            instance_shadow_batches,
            shadow_batch_texture,
            glyph_rotation,
            glyph_draw_scale,
            glyph_z,
            shadow.color,
            shadow_batch_bounds.center(),
            shadow_batch_bounds.half_size(),
            instance.layers,
            instance.ui_scissor,
            instance.ui_camera_entity,
            shadow_batch_slices_xy_uv,
          )
          shadow_batch_slices_xy_uv = []
          shadow_batch_bounds.clear()
        }
        if shadow_batch_slices_xy_uv.length() == 0 {
          shadow_batch_texture = Some(atlas_info.texture)
          shadow_batch_texture_id = texture_id
        }
        let shadow_translation = @math.Vec2::new(
          translation.x + shadow.offset.x,
          translation.y + shadow.offset.y,
        )
        shadow_batch_bounds.expand(shadow_translation)
        shadow_batch_slices_xy_uv.push(shadow_translation.x)
        shadow_batch_slices_xy_uv.push(shadow_translation.y)
        shadow_batch_slices_xy_uv.push(uv_min.x)
        shadow_batch_slices_xy_uv.push(uv_min.y)
        shadow_batch_slices_xy_uv.push(uv_max.x)
        shadow_batch_slices_xy_uv.push(uv_max.y)
      }

      if debug_capture_enabled {
        let glyph_bounds = text_glyph_world_bounds(
          translation,
          glyph.size,
          scale,
          rot,
        )
        @text.text_debug_push_glyph(
          instance.id,
          glyph_bounds,
          instance.ui_scissor,
          atlas_info.texture.id(),
          uv_min,
          uv_max,
        )
      }
    }

    text_push_overlay_sprite_slice_batch(
      instance_main_batches,
      main_batch_texture,
      glyph_rotation,
      glyph_draw_scale,
      glyph_z,
      main_batch_color,
      main_batch_bounds.center(),
      main_batch_bounds.half_size(),
      instance.layers,
      instance.ui_scissor,
      instance.ui_camera_entity,
      main_batch_slices_xy_uv,
    )
    main_batch_slices_xy_uv = []
    main_batch_bounds.clear()

    if shadow_opt is Some(shadow) {
      text_push_overlay_sprite_slice_batch(
        instance_shadow_batches,
        shadow_batch_texture,
        glyph_rotation,
        glyph_draw_scale,
        glyph_z,
        shadow.color,
        shadow_batch_bounds.center(),
        shadow_batch_bounds.half_size(),
        instance.layers,
        instance.ui_scissor,
        instance.ui_camera_entity,
        shadow_batch_slices_xy_uv,
      )
      shadow_batch_slices_xy_uv = []
      shadow_batch_bounds.clear()
      for batch in instance_shadow_batches {
        text_append_overlay_sprite_slice_batch(
          overlay_sprite_slices_batches, batch,
        )
      }
    }
    for batch in instance_main_batches {
      text_append_overlay_sprite_slice_batch(
        overlay_sprite_slices_batches, batch,
      )
    }
  }
  let scene_overlay_sprites : Array[@sprite_render.OverlaySpriteUvScissor] = []
  let ui_overlay_sprites : Array[@sprite_render.OverlaySpriteUvScissor] = []
  for sprite in overlay_sprites {
    match sprite.target_camera {
      Some(_) => ui_overlay_sprites.push(sprite)
      None => scene_overlay_sprites.push(sprite)
    }
  }
  let scene_overlay_sprite_slices_batches : Array[
    @sprite_render.OverlaySpriteUvScissorSlices,
  ] = []
  let ui_overlay_sprite_slices_batches : Array[
    @sprite_render.OverlaySpriteUvScissorSlices,
  ] = []
  for batch in overlay_sprite_slices_batches {
    match batch.target_camera {
      Some(_) => ui_overlay_sprite_slices_batches.push(batch)
      None => scene_overlay_sprite_slices_batches.push(batch)
    }
  }
  text2d_render_runtime_state.prepared_scene_overlay_sprites = scene_overlay_sprites
  text2d_render_runtime_state.prepared_ui_overlay_sprites = ui_overlay_sprites
  text2d_render_runtime_state.prepared_scene_overlay_sprite_slices_batches = scene_overlay_sprite_slices_batches
  text2d_render_runtime_state.prepared_ui_overlay_sprite_slices_batches = ui_overlay_sprite_slices_batches
  text2d_render_runtime_state.diagnostic_render_visible_text_count = visible_text_count
  text2d_render_runtime_state.diagnostic_render_culled_text_count = culled_text_count
  text2d_render_runtime_state.diagnostic_render_submitted_item_count = scene_overlay_sprites.length() +
    ui_overlay_sprites.length() +
    scene_overlay_sprite_slices_batches.length() +
    ui_overlay_sprite_slices_batches.length()
  text2d_render_runtime_state.diagnostic_render_cpu_ms = (
      @time.host_time_now() - render_start
    ) *
    1000.0F
}

///|
pub fn text_render_transparent_2d_queue_system(world : @ecs.World) -> Unit {
  let scene_overlay_sprites = text2d_render_runtime_state.prepared_scene_overlay_sprites
  let scene_overlay_sprite_slices_batches = text2d_render_runtime_state.prepared_scene_overlay_sprite_slices_batches
  if scene_overlay_sprites.length() > 0 {
    @sprite_render.render2d_push_sprite_uv_scissor_batch(
      world, scene_overlay_sprites,
    )
  }
  if scene_overlay_sprite_slices_batches.length() > 0 {
    @sprite_render.render2d_push_sprite_uv_scissor_slices_batch(
      world, scene_overlay_sprite_slices_batches,
    )
  }
  text2d_render_runtime_state.prepared_scene_overlay_sprites = []
  text2d_render_runtime_state.prepared_scene_overlay_sprite_slices_batches = []
}

///|
pub fn text_render_transparent_ui_queue_system(world : @ecs.World) -> Unit {
  let ui_overlay_sprites = text2d_render_runtime_state.prepared_ui_overlay_sprites
  let ui_overlay_sprite_slices_batches = text2d_render_runtime_state.prepared_ui_overlay_sprite_slices_batches
  if ui_overlay_sprites.length() > 0 {
    @sprite_render.render2d_push_sprite_uv_scissor_batch(
      world, ui_overlay_sprites,
    )
  }
  if ui_overlay_sprite_slices_batches.length() > 0 {
    @sprite_render.render2d_push_sprite_uv_scissor_slices_batch(
      world, ui_overlay_sprite_slices_batches,
    )
  }
  text2d_render_runtime_state.prepared_ui_overlay_sprites = []
  text2d_render_runtime_state.prepared_ui_overlay_sprite_slices_batches = []
}

///|
pub fn text_diagnostic_render_cpu_ms() -> Float {
  text2d_render_runtime_state.diagnostic_render_cpu_ms
}

///|
pub fn text_diagnostic_render_visible_text_count() -> Int {
  text2d_render_runtime_state.diagnostic_render_visible_text_count
}

///|
pub fn text_diagnostic_render_culled_text_count() -> Int {
  text2d_render_runtime_state.diagnostic_render_culled_text_count
}

///|
pub fn text_diagnostic_render_submitted_item_count() -> Int {
  text2d_render_runtime_state.diagnostic_render_submitted_item_count
}

///|
pub let text_set_render_prepare : @app.SystemSet = @app.system_set(
  "mgstudio.text.render_prepare",
)

///|
pub let text_set_render_transparent_2d : @app.SystemSet = @app.system_set(
  "mgstudio.text.render_transparent_2d",
)

///|
pub let text_set_render_transparent_ui : @app.SystemSet = @app.system_set(
  "mgstudio.text.render_transparent_ui",
)

///|
pub let text_set_render_extract : @app.SystemSet = text_set_render_prepare

///|
pub let text_set_render_queue : @app.SystemSet = text_set_render_transparent_2d

///|
pub fn text2d_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let next = app
    .configure_set(
      PostUpdate,
      text_set_render_prepare,
      after=[@text.text_set_sync_ecs, @sprite_render.render2d_set_extract],
      before=[text_set_render_transparent_2d],
    )
    .configure_set(
      PostUpdate,
      text_set_render_transparent_2d,
      after=[text_set_render_prepare, @sprite_render.render2d_set_prepare],
      before=[text_set_render_transparent_ui],
    )
    .configure_set(
      PostUpdate,
      text_set_render_transparent_ui,
      after=[text_set_render_transparent_2d],
      before=[@sprite_render.render2d_set_queue],
    )
  @render.with_render_app(next, fn(render_app) {
    let stage = @render.render_schedule_stage()
    @render.configure_base_render_sets(render_app)
    .add_systems(
      stage,
      @app.system(text_render_system).in_set(text_set_render_prepare),
    )
    .add_systems(
      stage,
      @app.system(text_render_transparent_2d_queue_system).in_set(
        text_set_render_transparent_2d,
      ),
    )
    .add_systems(
      stage,
      @app.system(text_render_transparent_ui_queue_system).in_set(
        text_set_render_transparent_ui,
      ),
    )
    .configure_set(
      stage,
      text_set_render_prepare,
      after=[@sprite_render.render2d_set_extract],
      before=[text_set_render_transparent_2d],
    )
    .configure_set(stage, @render.render_system_set_queue_meshes, before=[
      text_set_render_prepare,
    ])
    .configure_set(
      stage,
      text_set_render_transparent_2d,
      after=[text_set_render_prepare, @sprite_render.render2d_set_prepare],
      before=[text_set_render_transparent_ui],
    )
    .configure_set(stage, @render.render_system_set_queue_meshes, before=[
      text_set_render_transparent_2d,
    ])
    .configure_set(
      stage,
      text_set_render_transparent_ui,
      after=[text_set_render_transparent_2d],
      before=[@sprite_render.render2d_set_queue],
    )
    .configure_set(stage, text_set_render_transparent_ui, before=[
      @render.render_system_set_queue_sweep,
    ])
  })
}

///|
pub struct Text2dRenderPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn Text2dRenderPlugin::Text2dRenderPlugin() -> Text2dRenderPlugin {
  Text2dRenderPlugin::{  }
}

///|
pub impl @app.Plugin for Text2dRenderPlugin with fn name(_self) {
  "mgstudio.sprite_render.Text2dRenderPlugin"
}

///|
pub impl @app.Plugin for Text2dRenderPlugin with fn build(_self, app) {
  text2d_render_plugin(app)
}
