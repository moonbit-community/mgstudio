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
pub struct TextEntity {
  id : Int
  depth : Int
  font_smoothing : FontSmoothing
}

///|
pub struct TextSpanRange {
  start : Int
  length : Int
}

///|
pub struct CosmicBuffer {
  text : String
  spans : Array[TextSpanRange]
  font_size : Float
  line_height : Float
  justify : Justify
  linebreak : LineBreak
  max_width : Float?
  max_height : Float?
}

///|
pub fn CosmicBuffer::default() -> CosmicBuffer {
  CosmicBuffer::{
    text: "",
    spans: [],
    font_size: 20.0F,
    line_height: 20.0F,
    justify: Justify::Left,
    linebreak: LineBreak::WordBoundary,
    max_width: None,
    max_height: None,
  }
}

///|
pub struct ComputedTextBlock {
  buffer : CosmicBuffer
  needs_rerender : Bool
  entities : Array[TextEntity]
}

///|
pub fn ComputedTextBlock::default() -> ComputedTextBlock {
  ComputedTextBlock::{
    buffer: CosmicBuffer::default(),
    needs_rerender: true,
    entities: [],
  }
}

///|
pub fn ComputedTextBlock::needs_rerender(self : ComputedTextBlock) -> Bool {
  self.needs_rerender
}

///|
pub fn ComputedTextBlock::buffer(self : ComputedTextBlock) -> CosmicBuffer {
  self.buffer
}

///|
pub fn ComputedTextBlock::entities(
  self : ComputedTextBlock,
) -> Array[TextEntity] {
  self.entities
}

///|
pub struct TextPipeline {}

///|
pub fn TextPipeline::default() -> TextPipeline {
  TextPipeline::{  }
}

///|
fn build_text_entities(instance : TextInstance) -> Array[TextEntity] {
  let entities : Array[TextEntity] = []
  entities.push(TextEntity::{
    id: instance.id,
    depth: 0,
    font_smoothing: instance.font.font_smoothing,
  })
  for span in instance.spans {
    entities.push(TextEntity::{
      id: span.id,
      depth: 1,
      font_smoothing: span.font.font_smoothing,
    })
  }
  entities
}

///|
fn build_text_buffer(instance : TextInstance) -> CosmicBuffer {
  let mut text = instance.text.content
  let spans : Array[TextSpanRange] = []
  let mut cursor = text.length()
  spans.push(TextSpanRange::{ start: 0, length: cursor })
  for span in instance.spans {
    let content = span.span.content
    let length = content.length()
    spans.push(TextSpanRange::{ start: cursor, length })
    text = text + content
    cursor = cursor + length
  }
  let line_height = instance.line_height.eval(instance.font.font_size)
  CosmicBuffer::{
    text,
    spans,
    font_size: instance.font.font_size,
    line_height,
    justify: instance.layout.justify,
    linebreak: instance.layout.linebreak,
    max_width: instance.bounds.width,
    max_height: instance.bounds.height,
  }
}

///|
fn text_span_color(instance : TextInstance, span_index : Int) -> TextColor {
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
let font_atlas_set_state : Ref[FontAtlasSet] = Ref::new(FontAtlasSet::default())

///|
/// Global font system state for `moon_cosmic` (engine-side shaping/wrap/BiDi).
priv struct CosmicFontSystemState {
  font_system : @cosmic.FontSystem
  // Map asset font handle id -> cosmic font id (best-effort: first face in the data).
  handle_to_font_id : Array[(Int, Int)]
  // Map cosmic font id -> asset font handle id (for rasterization/atlas selection).
  font_id_to_handle_id : Array[Int]
  // Cache family names for asset font handles (best-effort).
  handle_to_family : Array[(Int, String)]
}

///|
let cosmic_font_system_state : Ref[CosmicFontSystemState] = Ref::new(CosmicFontSystemState::{
  font_system: @cosmic.FontSystem::new(),
  handle_to_font_id: [],
  font_id_to_handle_id: [],
  handle_to_family: [],
})

///|
fn find_int_pair_value(pairs : Array[(Int, Int)], key : Int) -> Int? {
  let n = pairs.length()
  for i in 0..<n {
    if pairs[i].0 == key {
      return Some(pairs[i].1)
    }
  }
  None
}

///|
fn find_str_pair_value(pairs : Array[(Int, String)], key : Int) -> String? {
  let n = pairs.length()
  for i in 0..<n {
    if pairs[i].0 == key {
      return Some(pairs[i].1)
    }
  }
  None
}

///|
fn cosmic_get_or_load_font_id(font : @asset.Handle[@asset.Font]) -> Int? {
  let handle_id = font.id()
  let state0 = cosmic_font_system_state.val
  match find_int_pair_value(state0.handle_to_font_id, handle_id) {
    Some(id) => return Some(id)
    None => ()
  }
  let bytes_opt = @asset.asset_font_read_bytes(font)
  if bytes_opt is None {
    return None
  }
  let bytes = if bytes_opt is Some(v) { v } else { return None }
  let old_len = state0.font_system.fonts().length()
  let font_system = state0.font_system.load_font_data(bytes)
  let new_len = font_system.fonts().length()
  if new_len <= old_len {
    return None
  }
  let handle_to_font_id = state0.handle_to_font_id
  handle_to_font_id.push((handle_id, old_len))
  let font_id_to_handle_id = state0.font_id_to_handle_id
  // `FontSystem::new()` may preload system fonts, so `font_id` is not
  // guaranteed to start from 0 for user-loaded fonts. Keep an index-aligned
  // mapping (font_id -> asset handle id) and use -1 as "unknown".
  while font_id_to_handle_id.length() < old_len {
    font_id_to_handle_id.push(-1)
  }
  while font_id_to_handle_id.length() < new_len {
    font_id_to_handle_id.push(-1)
  }
  for i in old_len..<new_len {
    font_id_to_handle_id[i] = handle_id
  }
  let handle_to_family = state0.handle_to_family
  if find_str_pair_value(handle_to_family, handle_id) is None {
    let fonts = font_system.fonts()
    if old_len >= 0 && old_len < fonts.length() {
      let family = fonts[old_len].family_name()
      handle_to_family.push((handle_id, family))
    }
  }
  cosmic_font_system_state.val = CosmicFontSystemState::{
    font_system,
    handle_to_font_id,
    font_id_to_handle_id,
    handle_to_family,
  }
  Some(old_len)
}

///|
fn cosmic_font_family_name(font : @asset.Handle[@asset.Font]) -> String? {
  let handle_id = font.id()
  let state0 = cosmic_font_system_state.val
  match find_str_pair_value(state0.handle_to_family, handle_id) {
    Some(v) => Some(v)
    None => {
      // Best-effort: ensure the font is loaded, then query again.
      cosmic_get_or_load_font_id(font) |> ignore
      find_str_pair_value(
        cosmic_font_system_state.val.handle_to_family,
        handle_id,
      )
    }
  }
}

///|
fn cosmic_font_handle_id_for_font_id(font_id : Int) -> Int? {
  let ids = cosmic_font_system_state.val.font_id_to_handle_id
  if font_id < 0 || font_id >= ids.length() {
    return None
  }
  let handle_id = ids[font_id]
  if handle_id <= 0 {
    None
  } else {
    Some(handle_id)
  }
}

///|
fn justify_is_left(justify : Justify) -> Bool {
  match justify {
    Justify::Left => true
    _ => false
  }
}

///|
fn cosmic_physical_xy(
  glyph : @cosmic.LayoutGlyph,
  font_smoothing : FontSmoothing,
) -> (@cosmic.CacheKey, Int, Int, Int, Int) {
  fn bin_index(bin : @cosmic.SubpixelBin) -> Int {
    match bin {
      @cosmic.SubpixelBin::Zero => 0
      @cosmic.SubpixelBin::One => 1
      @cosmic.SubpixelBin::Two => 2
      @cosmic.SubpixelBin::Three => 3
    }
  }
  // Bevy parity:
  // - FontSmoothing::None rounds subpixel layout fields first, then builds
  //   the physical glyph from that rounded layout glyph.
  // - FontSmoothing::AntiAliased uses the original layout glyph directly.
  match font_smoothing {
    FontSmoothing::None => {
      // `moon_cosmic.LayoutGlyph` is externally read-only, so we cannot clone-and-edit
      // like Bevy's Rust code. Rebuild the same rounded physical parameters directly.
      let rounded_x = @cosmic.roundf(glyph.x)
      let rounded_y = @cosmic.roundf(glyph.y)
      let rounded_x_offset = @cosmic.roundf(glyph.x_offset)
      let rounded_y_offset = @cosmic.roundf(glyph.y_offset)
      let x_off = glyph.font_size * rounded_x_offset
      let y_off = glyph.font_size * rounded_y_offset
      let pos_x = rounded_x + x_off
      let pos_y = @cosmic.truncf(rounded_y - y_off)
      let (cache_key, phys_x, phys_y) = @cosmic.CacheKey::new(
        glyph.font_id,
        glyph.glyph_id,
        glyph.font_size,
        (pos_x, pos_y),
        glyph.font_weight,
        glyph.cache_key_flags,
      )
      (
        cache_key,
        phys_x,
        phys_y,
        bin_index(cache_key.x_bin()),
        bin_index(cache_key.y_bin()),
      )
    }
    FontSmoothing::AntiAliased => {
      let physical = glyph.physical((0.0F, 0.0F), 1.0F)
      let cache_key = physical.cache_key
      (
        cache_key,
        physical.x,
        physical.y,
        bin_index(cache_key.x_bin()),
        bin_index(cache_key.y_bin()),
      )
    }
  }
}

///|
fn text_update_layout(instance : TextInstance) -> TextInstance {
  if !instance.computed.needs_rerender {
    return instance
  }
  let buffer = build_text_buffer(instance)
  let entities = build_text_entities(instance)

  // Ensure all fonts used by this text block are loaded into the cosmic font system.
  //
  // Important: When font bytes are not yet available (async host load),
  // `cosmic_get_or_load_font_id` returns None and the layout phase may produce
  // zero glyphs. We must keep `needs_rerender=true` in that case so the text
  // retries once assets become available.
  let mut missing_glyph = false
  if cosmic_get_or_load_font_id(instance.font.font) is None {
    missing_glyph = true
  }
  for span in instance.spans {
    if cosmic_get_or_load_font_id(span.font.font) is None {
      missing_glyph = true
    }
  }
  let font_system = cosmic_font_system_state.val.font_system

  // Build rich text spans for cosmic buffer.
  let spans : Array[(String, @cosmic.Attrs)] = []
  let base_metrics = @cosmic.Metrics::new(buffer.font_size, buffer.line_height)
  let base_family = cosmic_font_family_name(instance.font.font)
  let mut base_attrs = @cosmic.Attrs::with_metadata(0).metrics(base_metrics)
  if base_family is Some(name) && name.length() > 0 {
    base_attrs = base_attrs.family(@cosmic.Family::Name(name))
  }
  spans.push((instance.text.content, base_attrs))
  for i in 0..<instance.spans.length() {
    let sp = instance.spans[i]
    let idx = i + 1
    let fam = cosmic_font_family_name(sp.font.font)
    let metrics = @cosmic.Metrics::new(
      sp.font.font_size,
      sp.line_height.eval(sp.font.font_size),
    )
    let mut attrs = @cosmic.Attrs::with_metadata(idx).metrics(metrics)
    if fam is Some(name) && name.length() > 0 {
      attrs = attrs.family(@cosmic.Family::Name(name))
    }
    spans.push((sp.span.content, attrs))
  }
  let wrap = match buffer.linebreak {
    LineBreak::WordBoundary => @cosmic.Wrap::Word
    LineBreak::AnyCharacter => @cosmic.Wrap::Glyph
    LineBreak::WordOrCharacter => @cosmic.Wrap::WordOrGlyph
    LineBreak::NoWrap => @cosmic.Wrap::None
  }
  let align = match buffer.justify {
    Justify::Left => @cosmic.Align::Left
    Justify::Center => @cosmic.Align::Center
    Justify::Right => @cosmic.Align::Right
    Justify::Justified => @cosmic.Align::Justified
  }
  let mut cosmic_buffer = @cosmic.Buffer::new_empty(base_metrics)
  cosmic_buffer = cosmic_buffer.set_wrap(wrap)
  cosmic_buffer = cosmic_buffer.set_size(buffer.max_width, buffer.max_height)
  cosmic_buffer = cosmic_buffer.set_rich_text(
    spans,
    base_attrs,
    @cosmic.Shaping::Advanced,
    Some(align),
  )

  // Layout pass (best-effort).
  cosmic_buffer = cosmic_buffer.layout_all_with_font_system(font_system)
  // Workaround for alignment not working for unbounded text (bevy parity).
  if buffer.max_width is None && !justify_is_left(buffer.justify) {
    let mut w = 0.0F
    for run in cosmic_buffer.layout_runs() {
      if run.line_w > w {
        w = run.line_w
      }
    }
    cosmic_buffer = cosmic_buffer.set_size(Some(w), buffer.max_height)
    cosmic_buffer = cosmic_buffer.layout_all_with_font_system(font_system)
  }
  // First pass: compute the "box size" used for layout and optional y-axis flip.
  // Mirrors Bevy `buffer_dimensions` (max line width, sum of line heights, ceil).
  let mut box_w_raw = 0.0F
  let mut box_h_raw = 0.0F
  for run in cosmic_buffer.layout_runs() {
    if run.line_w > box_w_raw {
      box_w_raw = run.line_w
    }
    box_h_raw = box_h_raw + run.line_height
  }
  let box_w = Float::from_double(box_w_raw.to_double().ceil())
  let box_h = Float::from_double(box_h_raw.to_double().ceil())

  // Second pass: produce glyphs + run geometry.
  let glyphs : Array[PositionedGlyph] = []
  let run_geometry : Array[RunGeometry] = []
  for run in cosmic_buffer.layout_runs() {
    let run_glyph_start = glyphs.length()
    let mut run_top_correction = 0.0F
    let mut maybe_run_geom : RunGeometry? = None
    let mut end_x = 0.0F
    for layout_glyph0 in run.glyphs {
      let span_index = layout_glyph0.metadata
      if span_index < 0 || span_index >= entities.length() {
        continue
      }
      let font_smoothing = entities[span_index].font_smoothing
      let layout_glyph = layout_glyph0
      if maybe_run_geom is Some(rg) && rg.span_index != span_index {
        run_geometry.push(rg)
        maybe_run_geom = None
      }
      if maybe_run_geom is None {
        let font_opt = font_system.get_font(layout_glyph.font_id)
        let font_ref = match font_opt {
          None => continue
          Some(f) => f
        }
        let m = font_ref.metrics([])
        let upem = m.units_per_em.to_int()
        let scalar = if upem <= 0 {
          0.0F
        } else {
          layout_glyph.font_size / Float::from_double(upem.to_double())
        }
        let stroke = Float::from_double(
          (m.stroke_size * scalar.to_double()).round(),
        )
        let stroke_size = if stroke < 1.0F { 1.0F } else { stroke }
        let start = if end_x > layout_glyph.x { end_x } else { layout_glyph.x }
        maybe_run_geom = Some(RunGeometry::{
          span_index,
          bounds: @math.Rect::new(
            @math.Vec2::new(start, run.line_top),
            @math.Vec2::new(start, run.line_top + run.line_height),
          ),
          strikethrough_y: @cosmic.roundf(
            run.line_y -
            Float::from_double(m.strikeout_offset * scalar.to_double()),
          ),
          strikethrough_thickness: stroke_size,
          underline_y: @cosmic.roundf(
            run.line_y -
            Float::from_double(m.underline_offset * scalar.to_double()),
          ),
          underline_thickness: stroke_size,
        })
      }
      end_x = layout_glyph.x + layout_glyph.w
      if maybe_run_geom is Some(rg0) {
        let bounds = @math.Rect::new(
          rg0.bounds.min,
          @math.Vec2::new(end_x, rg0.bounds.max.y),
        )
        maybe_run_geom = Some(RunGeometry::{ ..rg0, bounds, })
      }
      let (physical_key, phys_x_i, phys_y_i, subpixel_x, subpixel_y) = cosmic_physical_xy(
        layout_glyph, font_smoothing,
      )
      let font_handle_id_opt = cosmic_font_handle_id_for_font_id(
        layout_glyph.font_id,
      )
      if font_handle_id_opt is None {
        missing_glyph = true
        continue
      }
      let font_handle_id = if font_handle_id_opt is Some(v) {
        v
      } else {
        continue
      }
      let font_handle = @asset.Handle::new(font_handle_id)
      let raster_opt = font_rasterize_cache_key(
        font_system, physical_key, font_smoothing,
      )
      if raster_opt is None {
        missing_glyph = true
        continue
      }
      let raster = if raster_opt is Some(v) { v } else { continue }
      let cache_key = GlyphCacheKey::new(
        physical_key.glyph_id,
        subpixel_x,
        subpixel_y,
        physical_key.font_weight,
        physical_key.flags,
      )
      let font_key = FontAtlasKey::new(
        font_handle,
        Float::reinterpret_from_uint(physical_key.font_size_bits),
        font_smoothing,
      )
      let atlases = font_atlas_set_state.val.get_or_insert(font_key)
      let atlas_info_opt = add_glyph_to_atlas(
        atlases, cache_key, raster, font_smoothing,
      )
      if atlas_info_opt is None {
        missing_glyph = true
        continue
      }
      let atlas_info = if atlas_info_opt is Some(v) { v } else { continue }
      let layout_opt = @asset.asset_get_texture_atlas_layout(
        atlas_info.texture_atlas,
      )
      if layout_opt is None {
        missing_glyph = true
        continue
      }
      let atlas_layout = if layout_opt is Some(v) { v } else { continue }
      let rect_opt = atlas_layout.textures.get(atlas_info.location.glyph_index)
      if rect_opt is None {
        missing_glyph = true
        continue
      }
      let rect = if rect_opt is Some(v) { v } else { continue }
      let glyph_size_u = rect.size()
      let glyph_size_x = Float::from_double(glyph_size_u.x.to_double())
      let glyph_size_y = Float::from_double(glyph_size_u.y.to_double())
      let left = Float::from_double(atlas_info.location.offset.x.to_double())
      let top = Float::from_double(atlas_info.location.offset.y.to_double())
      let phys_x = Float::from_double(phys_x_i.to_double())
      let phys_y = Float::from_double(phys_y_i.to_double())
      let correction = if top > phys_y { top - phys_y } else { 0.0F }
      if correction > run_top_correction {
        run_top_correction = correction
      }
      let x = glyph_size_x / 2.0F + left + phys_x
      let y_raw = @cosmic.roundf(run.line_y) +
        phys_y -
        top +
        glyph_size_y / 2.0F
      // Bevy parity: `BottomToTop` flips Y using the computed box height.
      let y = match instance.y_axis {
        YAxisOrientation::TopToBottom => y_raw
        YAxisOrientation::BottomToTop => box_h - y_raw
      }
      glyphs.push(PositionedGlyph::{
        position: @math.Vec2::new(x, y),
        size: @math.Vec2::new(glyph_size_x, glyph_size_y),
        atlas_info,
        span_index,
        line_index: run.line_i,
        byte_index: layout_glyph0.start,
        byte_length: layout_glyph0.end - layout_glyph0.start,
      })
    }
    if instance.y_axis == YAxisOrientation::TopToBottom &&
      run_top_correction > 0.0F {
      let run_glyph_end = glyphs.length()
      for i in run_glyph_start..<run_glyph_end {
        let g = glyphs[i]
        glyphs[i] = PositionedGlyph::{
          ..g,
          position: @math.Vec2::new(
            g.position.x,
            g.position.y + run_top_correction,
          ),
        }
      }
      if maybe_run_geom is Some(rg0) {
        let bounds = @math.Rect::new(
          @math.Vec2::new(
            rg0.bounds.min.x,
            rg0.bounds.min.y + run_top_correction,
          ),
          @math.Vec2::new(
            rg0.bounds.max.x,
            rg0.bounds.max.y + run_top_correction,
          ),
        )
        maybe_run_geom = Some(RunGeometry::{
          ..rg0,
          bounds,
          strikethrough_y: rg0.strikethrough_y + run_top_correction,
          underline_y: rg0.underline_y + run_top_correction,
        })
      }
    }
    if maybe_run_geom is Some(rg) {
      run_geometry.push(rg)
    }
  }
  let updated = TextLayoutInfo::{
    scale_factor: 1.0F,
    glyphs,
    run_geometry,
    size: @math.Vec2::new(box_w, box_h),
  }
  TextInstance::{
    ..instance,
    layout_info: updated,
    computed: ComputedTextBlock::{
      buffer,
      entities,
      needs_rerender: missing_glyph,
    },
  }
}

///|
pub fn[W] text_update_system(_world : W) -> Unit {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    text_state.val.texts[i] = text_update_layout(text_state.val.texts[i])
  }
}

///|
pub fn[W : @render2d.HasRes_RenderState + @core.ChangeTickWorld] text_render_system(
  world : W,
) -> Unit {
  @render2d.render2d_clear_overlay_sprites(world)
  text_debug_clear_frame()
  let texts = text_state.val.texts
  for instance in texts {
    let layout_info = instance.layout_info
    fn rotate_vec2(v : @math.Vec2, rot : Float) -> @math.Vec2 {
      let cosv = @math.cos(rot)
      let sinv = @math.sin(rot)
      @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
    }

    fn absf(v : Float) -> Float {
      if v < 0.0F {
        0.0F - v
      } else {
        v
      }
    }

    fn to_y_up(y_axis : YAxisOrientation, v : @math.Vec2) -> @math.Vec2 {
      match y_axis {
        YAxisOrientation::TopToBottom => @math.Vec2::new(v.x, 0.0F - v.y)
        YAxisOrientation::BottomToTop => v
      }
    }

    fn round_to_pixel(v : Float, pixel_scale : Float) -> Float {
      let sf = if pixel_scale <= 0.0F { 1.0F } else { pixel_scale }
      Float::from_double(
        (v.to_double() * sf.to_double()).round() / sf.to_double(),
      )
    }

    fn glyph_world_bounds(
      center : @math.Vec2,
      glyph_size : @math.Vec2,
      scale : @math.Vec2,
      rotation : Float,
    ) -> @math.Rect {
      let half = @math.Vec2::new(
        glyph_size.x * absf(scale.x) / 2.0F,
        glyph_size.y * absf(scale.y) / 2.0F,
      )
      let p0 = rotate_vec2(
        @math.Vec2::new(0.0F - half.x, 0.0F - half.y),
        rotation,
      )
      let p1 = rotate_vec2(@math.Vec2::new(half.x, 0.0F - half.y), rotation)
      let p2 = rotate_vec2(@math.Vec2::new(half.x, half.y), rotation)
      let p3 = rotate_vec2(@math.Vec2::new(0.0F - half.x, half.y), rotation)
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
      @math.Rect::new(
        @math.Vec2::new(min_x, min_y),
        @math.Vec2::new(max_x, max_y),
      )
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

    // Bevy parity:
    // - Text2d: use `Anchor` + `TextLayoutInfo.size` to compute the local origin.
    // - UI text: treat `GlobalTransform`/`Transform` as the center of the UI node, then translate
    //   by (-0.5 * node_size) to convert to top-left origin.
    let layout_size = layout_info.size
    let mut origin_offset_layout = @math.Vec2::new(0.0F, 0.0F)
    if instance.ui_node_size is Some(node_size) {
      origin_offset_layout = @math.Vec2::new(
        0.0F - node_size.x / 2.0F,
        0.0F - node_size.y / 2.0F,
      )
    } else {
      let a = instance.anchor.as_vec()
      // text_anchor = -(anchor + 0.5)
      let text_anchor = @math.Vec2::new(
        0.0F - (a.x + 0.5F),
        0.0F - (a.y + 0.5F),
      )
      origin_offset_layout = @math.Vec2::new(
        layout_size.x * text_anchor.x,
        layout_size.y * text_anchor.y,
      )
    }

    // Convert layout coordinates (+Y down for UI) into our world-style local (+Y up) coordinates.
    let origin_offset = to_y_up(instance.y_axis, origin_offset_layout)
    let origin_scaled = @math.Vec2::new(
      origin_offset.x * scale.x,
      origin_offset.y * scale.y,
    )
    let origin_rotated = rotate_vec2(origin_scaled, rot)
    let mut text_origin = @math.Vec2::new(
      base.x + origin_rotated.x,
      base.y + origin_rotated.y,
    )
    // Bevy parity for UI text extraction: snap the node's top-left origin to
    // physical pixels (DPR aware) before adding per-glyph offsets.
    // before adding per-glyph offsets.
    if instance.ui_node_size is Some(_) {
      let pixel_scale = @window.window_scale_factor()
      text_origin = @math.Vec2::new(
        round_to_pixel(text_origin.x, pixel_scale),
        round_to_pixel(text_origin.y, pixel_scale),
      )
    }
    for glyph in layout_info.glyphs {
      let atlas_info = glyph.atlas_info
      let layout_opt = @asset.asset_get_texture_atlas_layout(
        atlas_info.texture_atlas,
      )
      if layout_opt is None {
        continue
      }
      let layout = if layout_opt is Some(value) { value } else { continue }
      let index = atlas_info.location.glyph_index
      if index < 0 || index >= layout.textures.length() {
        continue
      }
      let rect = layout.textures[index]
      let atlas_size = layout.size
      if atlas_size.x <= 0 || atlas_size.y <= 0 {
        continue
      }
      let atlas_width = Float::from_double(atlas_size.x.to_double())
      let atlas_height = Float::from_double(atlas_size.y.to_double())
      let uv_min = @math.Vec2::new(
        Float::from_double(rect.min.x.to_double()) / atlas_width,
        Float::from_double(rect.min.y.to_double()) / atlas_height,
      )
      let uv_max = @math.Vec2::new(
        Float::from_double(rect.max.x.to_double()) / atlas_width,
        Float::from_double(rect.max.y.to_double()) / atlas_height,
      )
      let glyph_pos = to_y_up(instance.y_axis, glyph.position)
      let local_scaled = @math.Vec2::new(
        glyph_pos.x * scale.x,
        glyph_pos.y * scale.y,
      )
      let offset = rotate_vec2(local_scaled, rot)
      let translation = @math.Vec2::new(
        text_origin.x + offset.x,
        text_origin.y + offset.y,
      )
      let transform = @math.Transform::from_xy_rotation_scale(
        translation,
        rot,
        scale,
        z=instance.transform.translation.z,
      )
      let glyph_bounds = glyph_world_bounds(translation, glyph.size, scale, rot)
      let color = text_span_color(instance, glyph.span_index).color
      if instance.shadow is Some(shadow) {
        let shadow_translation = @math.Vec2::new(
          translation.x + shadow.offset.x,
          translation.y + shadow.offset.y,
        )
        let shadow_transform = @math.Transform::from_xy_rotation_scale(
          shadow_translation,
          instance.transform.rotation_z(),
          scale,
          z=instance.transform.translation.z,
        )
        @render2d.render2d_push_sprite_uv_scissor(
          world,
          atlas_info.texture,
          shadow_transform,
          uv_min,
          uv_max,
          shadow.color,
          instance.layers,
          instance.ui_scissor,
        )
      }
      @render2d.render2d_push_sprite_uv_scissor(
        world,
        atlas_info.texture,
        transform,
        uv_min,
        uv_max,
        color,
        instance.layers,
        instance.ui_scissor,
      )
      text_debug_push_glyph(
        instance.id,
        glyph_bounds,
        instance.ui_scissor,
        atlas_info.texture.id(),
        uv_min,
        uv_max,
      )
    }
  }
}

///|
pub fn[W : @render2d.HasRes_RenderState + @core.ChangeTickWorld] text_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app.add_system(text_update_system).add_system(text_render_system)
}
