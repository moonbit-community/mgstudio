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
  uses_viewport_sizes : Bool
  uses_rem_sizes : Bool
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
    uses_viewport_sizes: false,
    uses_rem_sizes: false,
  }
}

///|
pub struct ComputedTextBlock {
  buffer : CosmicBuffer
  needs_rerender : Bool
  uses_viewport_sizes : Bool
  uses_rem_sizes : Bool
  logical_viewport_size : @math.Vec2?
  rem_size : Float
  entities : Array[TextEntity]
}

///|
pub fn ComputedTextBlock::default() -> ComputedTextBlock {
  ComputedTextBlock::{
    buffer: CosmicBuffer::default(),
    needs_rerender: true,
    uses_viewport_sizes: false,
    uses_rem_sizes: false,
    logical_viewport_size: None,
    rem_size: 20.0F,
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
fn text_vec2_opt_eq(lhs : @math.Vec2?, rhs : @math.Vec2?) -> Bool {
  match (lhs, rhs) {
    (Some(lhs), Some(rhs)) => lhs.x == rhs.x && lhs.y == rhs.y
    (None, None) => true
    _ => false
  }
}

///|
fn text_font_supports_viewport_size(instance : TextInstance) -> Bool {
  if instance.font.font_size.uses_viewport_size() {
    return true
  }
  for span in instance.spans {
    if span.font.font_size.uses_viewport_size() {
      return true
    }
  }
  false
}

///|
fn text_font_uses_rem_size(instance : TextInstance) -> Bool {
  if instance.font.font_size.uses_rem_size() {
    return true
  }
  for span in instance.spans {
    if span.font.font_size.uses_rem_size() {
      return true
    }
  }
  false
}

///|
fn text_current_logical_viewport_size(instance : TextInstance) -> @math.Vec2 {
  match instance.logical_viewport_size {
    Some(size) => size
    None => @math.Vec2::new(0.0F, 0.0F)
  }
}

///|
fn text_evaluated_font_size(
  font_size : FontSize,
  logical_viewport_size : @math.Vec2,
  rem_size : Float,
) -> Float {
  font_size.eval(logical_viewport_size, rem_size)
}

///|
fn build_text_buffer(
  instance : TextInstance,
  logical_viewport_size : @math.Vec2,
  rem_size : Float,
) -> CosmicBuffer {
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
  let font_size = text_evaluated_font_size(
    instance.font.font_size,
    logical_viewport_size,
    rem_size,
  )
  let line_height = instance.line_height.eval(font_size)
  CosmicBuffer::{
    text,
    spans,
    font_size,
    line_height,
    justify: instance.layout.justify,
    linebreak: instance.layout.linebreak,
    max_width: instance.bounds.width,
    max_height: instance.bounds.height,
    uses_viewport_sizes: text_font_supports_viewport_size(instance),
    uses_rem_sizes: text_font_uses_rem_size(instance),
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
fn text_span_background_color(
  instance : TextInstance,
  span_index : Int,
) -> TextBackgroundColor? {
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
  instance : TextInstance,
  span_index : Int,
) -> UnderlineColor? {
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
fn text_span_has_underline(instance : TextInstance, span_index : Int) -> Bool {
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
  instance : TextInstance,
  span_index : Int,
) -> StrikethroughColor? {
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
  instance : TextInstance,
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
fn text_abort_layout_error(text_id : Int, detail : String) -> Unit {
  let message = "Text2d fatal: inconsistent atlas state, text_id=" +
    text_id.to_string() +
    ", detail=" +
    detail
  @window.host_debug_string(value=message)
  abort(message)
}

///|
fn text_range_is_non_renderable_whitespace(
  text : String,
  start : Int,
  end_ : Int,
) -> Bool {
  if start < 0 || end_ < start || end_ > text.length() {
    return false
  }
  if end_ == start {
    return true
  }
  let mut i = start
  while i < end_ {
    let code = text.code_unit_at(i).to_int() & 0xFFFF
    // Bevy parity:
    // positioned glyph iteration skips layout-only whitespace/control segments.
    // Treat ASCII control + whitespace ranges as non-renderable here.
    if code > 32 && code != 127 {
      return false
    }
    i = i + 1
  }
  true
}

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
const DEFAULT_TEXT_FONT_PATH : String = "fonts/FiraMono-Medium.ttf"

///|
fn text_pipeline_resolve_default_font(
  font : @asset.Handle[@asset.Font],
) -> @asset.Handle[@asset.Font] {
  if font.id() > 0 {
    return font
  }
  @asset.AssetServer::new().load_font(DEFAULT_TEXT_FONT_PATH)
}

///|
fn font_source_resolved_handle(
  source : FontSource,
) -> @asset.Handle[@asset.Font]? {
  match source {
    FontSource::Handle(font) => Some(text_pipeline_resolve_default_font(font))
    _ => None
  }
}

///|
fn cosmic_get_or_load_font_id(font : @asset.Handle[@asset.Font]) -> Int? {
  let resolved_font = text_pipeline_resolve_default_font(font)
  let handle_id = resolved_font.id()
  let state0 = cosmic_font_system_state.val
  match find_int_pair_value(state0.handle_to_font_id, handle_id) {
    Some(id) => return Some(id)
    None => ()
  }
  let bytes_opt = @asset.asset_font_read_bytes(resolved_font)
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
  let resolved_font = text_pipeline_resolve_default_font(font)
  let handle_id = resolved_font.id()
  let state0 = cosmic_font_system_state.val
  match find_str_pair_value(state0.handle_to_family, handle_id) {
    Some(v) => Some(v)
    None => {
      // Best-effort: ensure the font is loaded, then query again.
      cosmic_get_or_load_font_id(resolved_font) |> ignore
      find_str_pair_value(
        cosmic_font_system_state.val.handle_to_family,
        handle_id,
      )
    }
  }
}

///|
fn text_font_source_family(source : FontSource) -> @cosmic.Family? {
  match source {
    FontSource::Handle(font) =>
      match cosmic_font_family_name(font) {
        Some(name) =>
          if name.length() > 0 {
            Some(@cosmic.Family::Name(name))
          } else {
            None
          }
        None => None
      }
    _ => font_source_to_cosmic_family(source)
  }
}

///|
fn text_font_source_ready(source : FontSource) -> Bool {
  match font_source_resolved_handle(source) {
    Some(font) => cosmic_get_or_load_font_id(font) is Some(_)
    None => true
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
  line_y_offset : Float,
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
      let pos_y = @cosmic.truncf(rounded_y - y_off + line_y_offset)
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
      let physical = glyph.physical((0.0F, line_y_offset), 1.0F)
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
fn text_layout_needs_update(instance : TextInstance) -> Bool {
  if instance.computed.needs_rerender {
    return true
  }
  if instance.computed.uses_viewport_sizes &&
    !text_vec2_opt_eq(
      instance.computed.logical_viewport_size,
      instance.logical_viewport_size,
    ) {
    return true
  }
  if instance.computed.uses_rem_sizes &&
    instance.computed.rem_size != text_runtime_rem_size_ref.val {
    return true
  }
  false
}

///|
fn text_update_layout(instance : TextInstance) -> TextInstance {
  if !text_layout_needs_update(instance) {
    return instance
  }
  let logical_viewport_size = text_current_logical_viewport_size(instance)
  let rem_size = text_runtime_rem_size_ref.val
  let buffer = build_text_buffer(instance, logical_viewport_size, rem_size)
  let entities = build_text_entities(instance)
  if buffer.font_size <= 0.0F || buffer.line_height <= 0.0F {
    return TextInstance::{
      ..instance,
      layout_info: TextLayoutInfo::{
        scale_factor: 1.0F,
        glyphs: [],
        run_geometry: [],
        size: @math.Vec2::new(0.0F, 0.0F),
      },
      computed: ComputedTextBlock::{
        buffer,
        entities,
        needs_rerender: false,
        uses_viewport_sizes: buffer.uses_viewport_sizes,
        uses_rem_sizes: buffer.uses_rem_sizes,
        logical_viewport_size: instance.logical_viewport_size,
        rem_size,
      },
    }
  }

  // Ensure all fonts used by this text block are loaded into the cosmic font system.
  //
  // Important: When font bytes are not yet available (async host load),
  // `cosmic_get_or_load_font_id` returns None and the layout phase may produce
  // zero glyphs. We must keep `needs_rerender=true` in that case so the text
  // retries once assets become available.
  // Retry only for async font-byte loading paths.
  //
  // Other glyph failures:
  // - missing glyph image keeps partial layout and retries next frame.
  // - atlas state mismatches are treated as fatal runtime errors.
  let mut needs_retry = false
  if !text_font_source_ready(instance.font.font) {
    needs_retry = true
  }
  for span in instance.spans {
    if !text_font_source_ready(span.font.font) {
      needs_retry = true
    }
  }
  let font_system = cosmic_font_system_state.val.font_system

  // Build rich text spans for cosmic buffer.
  let spans : Array[(String, @cosmic.Attrs)] = []
  let base_metrics = @cosmic.Metrics::new(buffer.font_size, buffer.line_height)
  let base_family = text_font_source_family(instance.font.font)
  let mut base_attrs = @cosmic.Attrs::with_metadata(0)
    .metrics(base_metrics)
    .weight(font_weight_to_cosmic(instance.font.weight))
    .stretch(font_width_to_swash(instance.font.width))
    .style(font_style_to_swash(instance.font.style))
    .font_features(font_features_to_cosmic(instance.font.font_features))
  if base_family is Some(family) {
    base_attrs = base_attrs.family(family)
  }
  spans.push((instance.text.content, base_attrs))
  for i in 0..<instance.spans.length() {
    let sp = instance.spans[i]
    let idx = i + 1
    let span_font_size = text_evaluated_font_size(
      sp.font.font_size,
      logical_viewport_size,
      rem_size,
    )
    let fam = text_font_source_family(sp.font.font)
    let metrics = @cosmic.Metrics::new(
      span_font_size,
      sp.line_height.eval(span_font_size),
    )
    let mut attrs = @cosmic.Attrs::with_metadata(idx)
      .metrics(metrics)
      .weight(font_weight_to_cosmic(sp.font.weight))
      .stretch(font_width_to_swash(sp.font.width))
      .style(font_style_to_swash(sp.font.style))
      .font_features(font_features_to_cosmic(sp.font.font_features))
    if fam is Some(family) {
      attrs = attrs.family(family)
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
    // Reconstruct run vertical bounds from font metrics.
    // Baseline (`run.line_y`) comes from `moon_cosmic` layout.
    let mut run_max_ascent = 0.0F
    let mut run_max_descent = 0.0F
    for g in run.glyphs {
      let font_opt = font_system.get_font(g.font_id)
      if font_opt is Some(font_ref) {
        let m = font_ref.metrics([])
        let upem = m.units_per_em.to_int()
        if upem > 0 {
          let scalar = g.font_size / Float::from_double(upem.to_double())
          let ascent = Float::from_double(m.ascent * scalar.to_double())
          let descent = Float::from_double(m.descent * scalar.to_double())
          if ascent > run_max_ascent {
            run_max_ascent = ascent
          }
          if descent > run_max_descent {
            run_max_descent = descent
          }
        }
      }
    }
    let run_glyph_height = run_max_ascent + run_max_descent
    let run_line_y = run.line_y
    let run_min_y = if run_glyph_height > 0.0F {
      run_line_y - run_max_ascent
    } else {
      run.line_top
    }
    let run_max_y = if run_glyph_height > 0.0F {
      run_min_y + run_glyph_height
    } else {
      run.line_top + run.line_height
    }

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
            @math.Vec2::new(start, run_min_y),
            @math.Vec2::new(start, run_max_y),
          ),
          strikethrough_y: @cosmic.roundf(
            run_line_y -
            Float::from_double(m.strikeout_offset * scalar.to_double()),
          ),
          strikethrough_thickness: stroke_size,
          underline_y: @cosmic.roundf(
            run_line_y -
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
      let glyph_byte_start = layout_glyph0.start
      let glyph_byte_end = layout_glyph0.end
      if text_range_is_non_renderable_whitespace(
          run.text,
          glyph_byte_start,
          glyph_byte_end,
        ) {
        continue
      }
      let (physical_key, phys_x_i, phys_y_i, subpixel_x, subpixel_y) = cosmic_physical_xy(
        layout_glyph, font_smoothing, run_line_y,
      )
      let raster_opt = font_rasterize_cache_key(
        font_system, physical_key, font_smoothing,
      )
      if raster_opt is None {
        // Bevy parity intent:
        // layout extraction should skip non-renderable spacing/cluster glyphs.
        // `moon_cosmic` can emit such glyphs with no raster image even when
        // byte ranges do not map cleanly to visible whitespace.
        // Treat them as non-renderable and continue without forcing rerender.
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
        physical_key.font_id,
        Float::reinterpret_from_uint(physical_key.font_size_bits),
        font_smoothing,
      )
      let atlases = font_atlas_set_state.val.get_or_insert(font_key)
      let atlas_info_opt = add_glyph_to_atlas(
        atlases, cache_key, raster, font_smoothing,
      )
      if atlas_info_opt is None {
        text_abort_layout_error(instance.id, "failed to add glyph to atlas")
      }
      let atlas_info = if atlas_info_opt is Some(v) { v } else { continue }
      let layout_opt = @asset.asset_get_texture_atlas_layout(
        atlas_info.texture_atlas,
      )
      if layout_opt is None {
        text_abort_layout_error(instance.id, "missing texture atlas layout")
      }
      let atlas_layout = if layout_opt is Some(v) { v } else { continue }
      let rect_opt = atlas_layout.textures.get(atlas_info.location.glyph_index)
      if rect_opt is None {
        text_abort_layout_error(
          instance.id,
          "missing glyph rect in atlas layout",
        )
      }
      let rect = if rect_opt is Some(v) { v } else { continue }
      let atlas_size = atlas_layout.size
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
      let glyph_size_u = rect.size()
      let glyph_size_x = Float::from_double(glyph_size_u.x.to_double())
      let glyph_size_y = Float::from_double(glyph_size_u.y.to_double())
      let left = Float::from_double(atlas_info.location.offset.x.to_double())
      let top = Float::from_double(atlas_info.location.offset.y.to_double())
      let phys_x = Float::from_double(phys_x_i.to_double())
      let phys_y = Float::from_double(phys_y_i.to_double())
      let x = glyph_size_x / 2.0F + left + phys_x
      let y_raw = glyph_size_y / 2.0F + phys_y - top
      // Bevy parity: `BottomToTop` flips Y using the computed box height.
      let y = match instance.y_axis {
        YAxisOrientation::TopToBottom => y_raw
        YAxisOrientation::BottomToTop => box_h - y_raw
      }
      glyphs.push(PositionedGlyph::{
        position: @math.Vec2::new(x, y),
        size: @math.Vec2::new(glyph_size_x, glyph_size_y),
        atlas_info,
        uv_min,
        uv_max,
        span_index,
        line_index: run.line_i,
        byte_index: glyph_byte_start,
        byte_length: glyph_byte_end - glyph_byte_start,
      })
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
      needs_rerender: needs_retry,
      uses_viewport_sizes: buffer.uses_viewport_sizes,
      uses_rem_sizes: buffer.uses_rem_sizes,
      logical_viewport_size: instance.logical_viewport_size,
      rem_size,
    },
  }
}

///|
fn text_runtime_resolve_rem_size(world : @ecs.World) -> Float {
  match world.resource(RemSize::resource()).get() {
    Some(rem_size) => rem_size.value()
    None => RemSize::default().value()
  }
}

///|
pub fn text_update_system(world : @ecs.World) -> Unit {
  text_set_runtime_rem_size(text_runtime_resolve_rem_size(world))
  let count = text_state.val.texts.length()
  for i in 0..<count {
    text_state.val.texts[i] = text_update_layout(text_state.val.texts[i])
  }
  world.insert_resource(FontAtlasSet::resource(), font_atlas_set_state.val)
}

///|
pub fn text_render_system(world : @ecs.World) -> Unit {
  text_debug_clear_frame()
  let debug_capture_enabled = text_debug_capture_enabled()
  let overlay_sprites : Array[@sprite.OverlaySpriteUvScissor] = []
  let white_texture = @asset.asset_white_texture()
  let texts = text_state.val.texts
  for instance in texts {
    let layout_info = instance.layout_info
    fn rotate_vec2(v : @math.Vec2, cosv : Float, sinv : Float) -> @math.Vec2 {
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

    fn glyph_world_bounds(
      center : @math.Vec2,
      glyph_size : @math.Vec2,
      scale : @math.Vec2,
      rotation : Float,
    ) -> @math.Rect {
      let rotation_cos = @math.cos(rotation)
      let rotation_sin = @math.sin(rotation)
      let half = @math.Vec2::new(
        glyph_size.x * absf(scale.x) / 2.0F,
        glyph_size.y * absf(scale.y) / 2.0F,
      )
      let p0 = rotate_vec2(
        @math.Vec2::new(0.0F - half.x, 0.0F - half.y),
        rotation_cos,
        rotation_sin,
      )
      let p1 = rotate_vec2(
        @math.Vec2::new(half.x, 0.0F - half.y),
        rotation_cos,
        rotation_sin,
      )
      let p2 = rotate_vec2(
        @math.Vec2::new(half.x, half.y),
        rotation_cos,
        rotation_sin,
      )
      let p3 = rotate_vec2(
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
      @math.Rect::new(
        @math.Vec2::new(min_x, min_y),
        @math.Vec2::new(max_x, max_y),
      )
    }

    let rot = instance.transform.rotation_z()
    let rot_cos = @math.cos(rot)
    let rot_sin = @math.sin(rot)
    let scale = @math.Vec2::new(
      instance.transform.scale.x,
      instance.transform.scale.y,
    )
    let base = @math.Vec2::new(
      instance.transform.translation.x,
      instance.transform.translation.y,
    )

    // Bevy parity:
    // - Text2d: use `Anchor` + (`TextBounds` if set, otherwise `TextLayoutInfo.size`)
    //   to compute the local origin.
    // - UI text: treat `GlobalTransform`/`Transform` as the center of the UI node, then translate
    //   by (-0.5 * node_size) to convert to top-left origin.
    let anchor_size = @math.Vec2::new(
      instance.bounds.width.unwrap_or(layout_info.size.x),
      instance.bounds.height.unwrap_or(layout_info.size.y),
    )
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
        YAxisOrientation::TopToBottom =>
          @math.Vec2::new(
            (0.0F - 0.5F - a.x) * anchor_size.x,
            (0.5F - a.y) * anchor_size.y,
          )
        // Backward-compatible semantics for BottomToTop mode.
        YAxisOrientation::BottomToTop =>
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
      (YAxisOrientation::TopToBottom, None) => origin_offset_layout
      _ => to_y_up(instance.y_axis, origin_offset_layout)
    }
    let origin_scaled = @math.Vec2::new(
      origin_offset.x * scale.x,
      origin_offset.y * scale.y,
    )
    let origin_rotated = rotate_vec2(origin_scaled, rot_cos, rot_sin)
    let text_origin = @math.Vec2::new(
      base.x + origin_rotated.x,
      base.y + origin_rotated.y,
    )

    for run in layout_info.run_geometry {
      let run_center_layout = to_y_up(instance.y_axis, run.bounds.center())
      let run_center_scaled = @math.Vec2::new(
        run_center_layout.x * scale.x,
        run_center_layout.y * scale.y,
      )
      let run_center_offset = rotate_vec2(run_center_scaled, rot_cos, rot_sin)
      let run_translation = @math.Vec2::new(
        text_origin.x + run_center_offset.x,
        text_origin.y + run_center_offset.y,
      )
      let run_size = run.bounds.size()
      let run_draw_scale = @math.Vec2::new(
        run_size.x * absf(scale.x),
        run_size.y * absf(scale.y),
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
        overlay_sprites.push(@sprite.OverlaySpriteUvScissor::{
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
        let underline_position_layout = to_y_up(
          instance.y_axis,
          run.underline_position(),
        )
        let underline_scaled = @math.Vec2::new(
          underline_position_layout.x * scale.x,
          underline_position_layout.y * scale.y,
        )
        let underline_offset = rotate_vec2(underline_scaled, rot_cos, rot_sin)
        let underline_translation = @math.Vec2::new(
          text_origin.x + underline_offset.x,
          text_origin.y + underline_offset.y,
        )
        let underline_size = run.underline_size()
        let underline_draw_scale = @math.Vec2::new(
          underline_size.x * absf(scale.x),
          underline_size.y * absf(scale.y),
        )
        if underline_draw_scale.x > 0.0F && underline_draw_scale.y > 0.0F {
          let underline_transform = @transform.Transform::from_xy_rotation_scale(
            underline_translation,
            rot,
            underline_draw_scale,
            z=instance.transform.translation.z + 0.0005F,
          )
          overlay_sprites.push(@sprite.OverlaySpriteUvScissor::{
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
        let strike_position_layout = to_y_up(
          instance.y_axis,
          run.strikethrough_position(),
        )
        let strike_scaled = @math.Vec2::new(
          strike_position_layout.x * scale.x,
          strike_position_layout.y * scale.y,
        )
        let strike_offset = rotate_vec2(strike_scaled, rot_cos, rot_sin)
        let strike_translation = @math.Vec2::new(
          text_origin.x + strike_offset.x,
          text_origin.y + strike_offset.y,
        )
        let strike_size = run.strikethrough_size()
        let strike_draw_scale = @math.Vec2::new(
          strike_size.x * absf(scale.x),
          strike_size.y * absf(scale.y),
        )
        if strike_draw_scale.x > 0.0F && strike_draw_scale.y > 0.0F {
          let strike_transform = @transform.Transform::from_xy_rotation_scale(
            strike_translation,
            rot,
            strike_draw_scale,
            z=instance.transform.translation.z + 0.0005F,
          )
          overlay_sprites.push(@sprite.OverlaySpriteUvScissor::{
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

    // Keep UI text origin in continuous space.
    // Snapping world-space origins introduces visible jitter when camera
    // viewport/scale changes dynamically (e.g. 2d_viewport_to_world).
    for glyph in layout_info.glyphs {
      let atlas_info = glyph.atlas_info
      let uv_min = glyph.uv_min
      let uv_max = glyph.uv_max
      let glyph_pos = to_y_up(instance.y_axis, glyph.position)
      let local_scaled = @math.Vec2::new(
        glyph_pos.x * scale.x,
        glyph_pos.y * scale.y,
      )
      let offset = rotate_vec2(local_scaled, rot_cos, rot_sin)
      let translation = @math.Vec2::new(
        text_origin.x + offset.x,
        text_origin.y + offset.y,
      )
      let transform = @transform.Transform::from_xy_rotation_scale(
        translation,
        rot,
        scale,
        z=instance.transform.translation.z,
      )
      let color = text_span_color(instance, glyph.span_index).color
      if instance.shadow is Some(shadow) {
        let shadow_translation = @math.Vec2::new(
          translation.x + shadow.offset.x,
          translation.y + shadow.offset.y,
        )
        let shadow_transform = @transform.Transform::from_xy_rotation_scale(
          shadow_translation,
          instance.transform.rotation_z(),
          scale,
          z=instance.transform.translation.z,
        )
        overlay_sprites.push(@sprite.OverlaySpriteUvScissor::{
          texture: atlas_info.texture,
          transform: shadow_transform,
          uv_min,
          uv_max,
          color: shadow.color,
          layers: instance.layers,
          scissor: instance.ui_scissor,
          target_camera: instance.ui_camera_entity,
        })
      }
      overlay_sprites.push(@sprite.OverlaySpriteUvScissor::{
        texture: atlas_info.texture,
        transform,
        uv_min,
        uv_max,
        color,
        layers: instance.layers,
        scissor: instance.ui_scissor,
        target_camera: instance.ui_camera_entity,
      })
      if debug_capture_enabled {
        let glyph_bounds = glyph_world_bounds(
          translation,
          glyph.size,
          scale,
          rot,
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
  @sprite_render.render2d_push_sprite_uv_scissor_batch(world, overlay_sprites)
}

///|
pub let text_set_render_extract : @app.SystemSet = @app.system_set(
  "bevy.text.render_extract",
)

///|
pub let text_set_sync_ecs : @app.SystemSet = @app.system_set(
  "mgstudio.text.sync_ecs",
)

///|
pub fn text_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  try! register_text_required_components(app.world())
  let next = app
    .insert_resource(RemSize::default())
    .insert_resource(FontCx::default())
    .insert_resource(FontAtlasSet::default())
    .add_system(text_update_system)
    .add_post_update_system_config(
      @app.system(text_sync_ecs_system).in_set(text_set_sync_ecs),
    )
    .configure_set(
      @app.PostUpdate,
      text_set_sync_ecs,
      after=[
        @app.system_set("bevy.ui.stack"),
        @transform.transform_set_sync_simple_transforms,
      ],
      before=[text_set_render_extract],
    )
    .configure_set(@app.PostUpdate, text_set_render_extract, after=[
      text_set_sync_ecs,
    ])
  @render.with_render_app(next, fn(render_app) {
    render_app
    .add_systems(
      @app.PostUpdate,
      @app.system(text_render_system).in_set(text_set_render_extract),
    )
    .configure_set(@app.PostUpdate, text_set_render_extract, before=[
      @sprite_render.render2d_set_extract,
    ])
  })
}
