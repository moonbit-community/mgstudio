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
pub fn CosmicBuffer::CosmicBuffer() -> CosmicBuffer {
  {
    text: "",
    spans: [],
    font_size: 20.0F,
    line_height: 20.0F,
    justify: Left,
    linebreak: WordBoundary,
    max_width: None,
    max_height: None,
    uses_viewport_sizes: false,
    uses_rem_sizes: false,
  }
}

///|
pub struct ComputedTextBlock {
  buffer : CosmicBuffer
  scale_factor : Float
  needs_rerender : Bool
  uses_viewport_sizes : Bool
  uses_rem_sizes : Bool
  font_hinting : FontHinting
  logical_viewport_size : @math.Vec2?
  rem_size : Float
  entities : Array[TextEntity]
}

///|
pub fn ComputedTextBlock::ComputedTextBlock() -> ComputedTextBlock {
  {
    buffer: CosmicBuffer(),
    scale_factor: 1.0F,
    needs_rerender: true,
    uses_viewport_sizes: false,
    uses_rem_sizes: false,
    font_hinting: FontHinting::default(),
    logical_viewport_size: None,
    rem_size: 20.0F,
    entities: [],
  }
}

///|
pub fn ComputedTextBlock::needs_rerender(
  self : ComputedTextBlock,
  is_viewport_size_changed : Bool,
  is_rem_size_changed : Bool,
) -> Bool {
  self.needs_rerender ||
  (is_viewport_size_changed && self.uses_viewport_sizes) ||
  (is_rem_size_changed && self.uses_rem_sizes)
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
#warnings("-unnecessary_annotation")
pub fn TextPipeline::TextPipeline() -> TextPipeline {
  TextPipeline::{  }
}

///|
fn build_text_entities(instance : TextInstance) -> Array[TextEntity] {
  let entities : Array[TextEntity] = []
  entities.push({
    id: instance.id,
    depth: 0,
    font_smoothing: instance.font.font_smoothing,
  })
  for span in instance.spans {
    entities.push({
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
pub fn text_pipeline_safe_scale_factor(scale_factor : Float) -> Float {
  if scale_factor <= 0.0F {
    1.0F
  } else {
    scale_factor
  }
}

///|
fn build_text_buffer(
  instance : TextInstance,
  logical_viewport_size : @math.Vec2,
  rem_size : Float,
  scale_factor : Float,
) -> CosmicBuffer {
  let mut text = instance.text.content
  let spans : Array[TextSpanRange] = []
  let mut cursor = text.length()
  spans.push({ start: 0, length: cursor })
  for span in instance.spans {
    let content = span.span.content
    let length = content.length()
    spans.push({ start: cursor, length })
    text = text + content
    cursor = cursor + length
  }
  let font_size = text_evaluated_font_size(
    instance.font.font_size,
    logical_viewport_size,
    rem_size,
  )
  let line_height = instance.line_height.eval(font_size)
  let max_width = match instance.bounds.width {
    Some(width) => Some(width * scale_factor)
    None =>
      match instance.ui_node_size {
        Some(node_size) =>
          if node_size.x > 0.0F {
            Some(node_size.x * scale_factor)
          } else {
            None
          }
        None => None
      }
  }
  let max_height = match instance.bounds.height {
    Some(height) => Some(height * scale_factor)
    None => None
  }
  {
    text,
    spans,
    font_size: font_size * scale_factor,
    line_height: line_height * scale_factor,
    justify: instance.layout.justify,
    linebreak: instance.layout.linebreak,
    max_width,
    max_height,
    uses_viewport_sizes: text_font_supports_viewport_size(instance),
    uses_rem_sizes: text_font_uses_rem_size(instance),
  }
}

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
priv struct TextPipelineRuntimeState {
  mut font_atlas_set : FontAtlasSet
  mut default_text_font_handle : @asset.Handle[@asset.Font]?
  mut cosmic_font_system : CosmicFontSystemState
  mut diagnostic_update_cpu_ms : Float
  mut diagnostic_update_pending_layout_count : Int
}

///|
fn cosmic_font_system_state_new() -> CosmicFontSystemState {
  {
    font_system: @cosmic.FontSystem::new(),
    handle_to_font_id: [],
    font_id_to_handle_id: [],
    handle_to_family: [],
  }
}

///|
let text_pipeline_runtime_state : TextPipelineRuntimeState = {
  font_atlas_set: FontAtlasSet(),
  default_text_font_handle: None,
  cosmic_font_system: cosmic_font_system_state_new(),
  diagnostic_update_cpu_ms: 0.0F,
  diagnostic_update_pending_layout_count: 0,
}

///|
let text_font_asset_events_cursor : @ecs.MessageCursor[
  @asset.AssetEvent[@asset.Font],
] = MessageCursor()

///|
fn text_abort_layout_error(text_id : Int, detail : String) -> Unit {
  let message = "Text2d fatal: inconsistent atlas state, text_id=\{text_id.to_string()}, detail=\{detail}"
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
const DEFAULT_TEXT_FONT_PATH : String = "fonts/FiraMono-subset.ttf"

///|
fn text_pipeline_ensure_default_font_handle() -> @asset.Handle[@asset.Font] {
  match text_pipeline_runtime_state.default_text_font_handle {
    Some(cached) => cached
    None => {
      let loaded = @asset.AssetServer::new().load_font(DEFAULT_TEXT_FONT_PATH)
      text_pipeline_runtime_state.default_text_font_handle = Some(loaded)
      loaded
    }
  }
}

///|
fn text_mark_all_instances_for_rerender() -> Unit {
  let count = text_state.texts.length()
  if count <= 0 {
    return
  }
  for i in 0..<count {
    let instance = text_state.texts[i]
    text_state.texts[i] = {
      ..instance,
      layout_dirty: true,
      computed: { ..instance.computed, needs_rerender: true },
    }
  }
  text_runtime_mark_layout_dirty()
}

///|
fn text_sync_font_assets_from_events(world : @ecs.World) -> Bool {
  let message_key : @ecs.MessageKey[@asset.AssetEvent[@asset.Font]] = @ecs.Message::message()
  if !world.contains_message(message_key) {
    world.init_message(message_key)
  }
  let reader = world.message_reader(
    message_key,
    cursor=text_font_asset_events_cursor,
  )
  let mut new_fonts_added = false
  for event in reader.read() {
    match event {
      Added(handle) => {
        new_fonts_added = true
        cosmic_get_or_load_font_id(handle) |> ignore
      }
      LoadedWithDependencies(_) | Modified(_) | Removed(_) | Unused(_) => ()
    }
  }
  if !new_fonts_added {
    return false
  }
  text_mark_all_instances_for_rerender()
  true
}

///|
fn text_sync_font_assets_system(world : @ecs.World) -> Unit {
  if !text_sync_font_assets_from_events(world) {
    return
  }
}

///|
fn text_trim_shape_run_cache_system(_world : @ecs.World) -> Unit {
  // Bevy parity intent (`trim_source_cache`):
  // keep recently used shaping cache entries and prune stale runs each frame.
  text_pipeline_runtime_state.cosmic_font_system.font_system.shape_run_cache.trim(
    2UL,
  )
}

///|
fn text_pipeline_resolve_default_font(
  font : @asset.Handle[@asset.Font],
) -> @asset.Handle[@asset.Font] {
  if font.id() > 0 {
    return font
  }
  text_pipeline_ensure_default_font_handle()
}

///|
fn font_source_resolved_handle(
  source : FontSource,
) -> @asset.Handle[@asset.Font]? {
  match source {
    Handle(font) => Some(text_pipeline_resolve_default_font(font))
    _ => None
  }
}

///|
fn cosmic_get_or_load_font_id(font : @asset.Handle[@asset.Font]) -> Int? {
  let resolved_font = text_pipeline_resolve_default_font(font)
  let handle_id = resolved_font.id()
  let state0 = text_pipeline_runtime_state.cosmic_font_system
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
  text_pipeline_runtime_state.cosmic_font_system = {
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
  let state0 = text_pipeline_runtime_state.cosmic_font_system
  match find_str_pair_value(state0.handle_to_family, handle_id) {
    Some(v) => Some(v)
    None => {
      // Best-effort: ensure the font is loaded, then query again.
      cosmic_get_or_load_font_id(resolved_font) |> ignore
      find_str_pair_value(
        text_pipeline_runtime_state.cosmic_font_system.handle_to_family,
        handle_id,
      )
    }
  }
}

///|
fn text_font_source_family(source : FontSource) -> @cosmic.Family? {
  match source {
    Handle(font) =>
      match cosmic_font_family_name(font) {
        Some(name) => if name.length() > 0 { Some(Name(name)) } else { None }
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
    Left => true
    _ => false
  }
}

///|
fn justify_to_cosmic_align(justify : Justify) -> @cosmic.Align {
  match justify {
    Left => Left
    Center => Center
    Right => Right
    Justified => Justified
    Start => Start
    End => End
  }
}

///|
fn font_hinting_to_cosmic(hinting : FontHinting) -> @cosmic.Hinting {
  match hinting {
    Disabled => Disabled
    Enabled => Enabled
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
      Zero => 0
      One => 1
      Two => 2
      Three => 3
    }
  }
  // Bevy parity:
  // - FontSmoothing::None rounds subpixel layout fields first, then builds
  //   the physical glyph from that rounded layout glyph.
  // - FontSmoothing::AntiAliased uses the original layout glyph directly.
  match font_smoothing {
    None => {
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
    AntiAliased => {
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
  let is_viewport_size_changed = !text_vec2_opt_eq(
    instance.computed.logical_viewport_size,
    instance.logical_viewport_size,
  )
  let is_rem_size_changed = instance.computed.rem_size !=
    text_runtime_state.rem_size
  let is_scale_factor_changed = text_absf(
      instance.computed.scale_factor -
      text_pipeline_safe_scale_factor(instance.scale_factor),
    ) >
    0.00001F
  instance.computed.needs_rerender(
    is_viewport_size_changed, is_rem_size_changed,
  ) ||
  is_scale_factor_changed
}

///|
fn text_update_layout(instance : TextInstance) -> TextInstance {
  if !text_layout_needs_update(instance) {
    return { ..instance, layout_dirty: false }
  }
  let logical_viewport_size = text_current_logical_viewport_size(instance)
  let rem_size = text_runtime_state.rem_size
  let scale_factor = text_pipeline_safe_scale_factor(instance.scale_factor)
  let inverse_scale_factor = 1.0F / scale_factor
  let buffer = build_text_buffer(
    instance, logical_viewport_size, rem_size, scale_factor,
  )
  let entities = build_text_entities(instance)
  if buffer.font_size <= 0.0F || buffer.line_height <= 0.0F {
    return {
      ..instance,
      layout_info: {
        scale_factor,
        glyphs: [],
        run_geometry: [],
        size: @math.Vec2::new(0.0F, 0.0F),
      },
      cull_margin: text_compute_cull_margin(
        instance.bounds,
        @math.Vec2::new(0.0F, 0.0F),
        instance.transform.scale,
      ),
      layout_dirty: false,
      computed: {
        buffer,
        scale_factor,
        entities,
        needs_rerender: false,
        uses_viewport_sizes: buffer.uses_viewport_sizes,
        uses_rem_sizes: buffer.uses_rem_sizes,
        font_hinting: instance.font_hinting,
        logical_viewport_size: instance.logical_viewport_size,
        rem_size,
      },
    }
  }

  // Ensure all fonts used by this text block are loaded into the cosmic font system.
  //
  // Bevy parity: if required fonts are not ready yet, defer text processing and
  // retry next frame instead of running full layout/raster work on a fallback path.
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
  if needs_retry {
    return {
      ..instance,
      cull_margin: text_compute_cull_margin(
        instance.bounds,
        instance.layout_info.size,
        instance.transform.scale,
      ),
      layout_dirty: true,
      computed: {
        buffer,
        scale_factor,
        entities,
        needs_rerender: true,
        uses_viewport_sizes: buffer.uses_viewport_sizes,
        uses_rem_sizes: buffer.uses_rem_sizes,
        font_hinting: instance.font_hinting,
        logical_viewport_size: instance.logical_viewport_size,
        rem_size,
      },
    }
  }
  let font_system = text_pipeline_runtime_state.cosmic_font_system.font_system

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
    let span_physical_font_size = span_font_size * scale_factor
    let fam = text_font_source_family(sp.font.font)
    let metrics = @cosmic.Metrics::new(
      span_physical_font_size,
      sp.line_height.eval(span_font_size) * scale_factor,
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
    WordBoundary => @cosmic.Wrap::Word
    AnyCharacter => Glyph
    WordOrCharacter => WordOrGlyph
    NoWrap => None
  }
  let align = justify_to_cosmic_align(buffer.justify)
  let mut cosmic_buffer = @cosmic.Buffer::new_empty(base_metrics).set_hinting(
    font_hinting_to_cosmic(instance.font_hinting),
  )
  cosmic_buffer = cosmic_buffer.set_wrap(wrap)
  cosmic_buffer = cosmic_buffer.set_size(buffer.max_width, buffer.max_height)
  cosmic_buffer = cosmic_buffer.set_rich_text(
    spans,
    base_attrs,
    Advanced,
    Some(align),
  )

  // Layout pass.
  cosmic_buffer = cosmic_buffer.layout_all_with_font_system(font_system)
  // Bevy `layout_with_bounds`: if width is unbounded and alignment is not
  // left, align against the measured layout width.
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
    let run_line_y = run.line_y
    // Bevy parity: use layout line bounds directly for run geometry bounds.
    let run_min_y = run.line_top
    let run_max_y = run.line_top + run.line_height

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
        maybe_run_geom = Some({
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
        maybe_run_geom = Some({ ..rg0, bounds, })
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
        instance.font_hinting,
        font_smoothing,
      )
      let atlases = text_pipeline_runtime_state.font_atlas_set.get_or_insert(
        font_key,
      )
      let atlas_info = match get_glyph_atlas_info(atlases, cache_key) {
        Some(atlas_info) => atlas_info
        None => {
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
          let atlas_info_opt = add_glyph_to_atlas(
            atlases, cache_key, raster, font_smoothing,
          )
          if atlas_info_opt is None {
            text_abort_layout_error(instance.id, "failed to add glyph to atlas")
          }
          if atlas_info_opt is Some(v) {
            v
          } else {
            continue
          }
        }
      }
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
        TopToBottom => y_raw
        BottomToTop => box_h - y_raw
      }
      glyphs.push({
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
    scale_factor,
    glyphs,
    run_geometry,
    size: @math.Vec2::new(
      box_w * inverse_scale_factor,
      box_h * inverse_scale_factor,
    ),
  }
  {
    ..instance,
    layout_info: updated,
    cull_margin: text_compute_cull_margin(
      instance.bounds,
      updated.size,
      instance.transform.scale,
    ),
    layout_dirty: needs_retry,
    computed: {
      buffer,
      scale_factor,
      entities,
      needs_rerender: needs_retry,
      uses_viewport_sizes: buffer.uses_viewport_sizes,
      uses_rem_sizes: buffer.uses_rem_sizes,
      font_hinting: instance.font_hinting,
      logical_viewport_size: instance.logical_viewport_size,
      rem_size,
    },
  }
}

///|
fn text_runtime_resolve_rem_size(world : @ecs.World) -> Float {
  match world.resource(RemSize::resource()).get() {
    Some(rem_size) => rem_size.value()
    None => RemSize::RemSize().value()
  }
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
pub fn text_update_system(world : @ecs.World) -> Unit {
  let update_start = @time.host_time_now()
  text_pipeline_runtime_state.diagnostic_update_pending_layout_count = 0
  text_set_runtime_rem_size(text_runtime_resolve_rem_size(world))
  if text_runtime_layout_dirty() {
    text_runtime_clear_layout_dirty()
    let count = text_state.texts.length()
    let mut pending_layout_count = 0
    for i in 0..<count {
      let current = text_state.texts[i]
      if !current.layout_dirty {
        continue
      }
      let instance = text_update_layout(current)
      if instance.layout_dirty {
        pending_layout_count = pending_layout_count + 1
      }
      text_state.texts[i] = instance
    }
    text_pipeline_runtime_state.diagnostic_update_pending_layout_count = pending_layout_count
    if pending_layout_count > 0 {
      text_runtime_mark_layout_dirty()
    }
  }
  world.insert_resource(
    FontAtlasSet::resource(),
    text_pipeline_runtime_state.font_atlas_set,
  )
  text_pipeline_runtime_state.diagnostic_update_cpu_ms = (
      @time.host_time_now() - update_start
    ) *
    1000.0F
}

///|
pub fn text_diagnostic_update_cpu_ms() -> Float {
  text_pipeline_runtime_state.diagnostic_update_cpu_ms
}

///|
pub fn text_diagnostic_update_pending_layout_count() -> Int {
  text_pipeline_runtime_state.diagnostic_update_pending_layout_count
}

///|
pub let text_set_sync_ecs : @app.SystemSet = @app.system_set(
  "mgstudio.text.sync_ecs",
)

///|
pub fn text_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  try! register_text_required_components(app.world())
  text_pipeline_ensure_default_font_handle() |> ignore
  // The render half (extraction/queue systems and their set ordering) lives in
  // `sprite_render/text2d` (Bevy: `bevy_sprite_render/src/text2d/mod.rs`);
  // its plugin orders `mgstudio.text.render_prepare` after `text_set_sync_ecs`.
  app
  .insert_resource(RemSize::RemSize())
  .insert_resource(FontCx::FontCx())
  .insert_resource(FontAtlasSet::FontAtlasSet())
  .add_system(text_update_system)
  .add_last_system(text_trim_shape_run_cache_system)
  .add_post_update_system_config(
    @app.system(text_sync_font_assets_system).in_set(text_set_sync_ecs),
  )
  .add_post_update_system_config(
    @app.system(text_sync_ecs_system).in_set(text_set_sync_ecs),
  )
  .configure_set(PostUpdate, text_set_sync_ecs, after=[
    @app.system_set("mgstudio.ui.stack"),
    @transform.transform_set_propagate,
  ])
}
