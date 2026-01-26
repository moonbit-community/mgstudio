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
fn resolve_span_index(buffer : CosmicBuffer, byte_index : Int) -> Int {
  let count = buffer.spans.length()
  for i in 0..<count {
    let span = buffer.spans[i]
    if byte_index >= span.start && byte_index < span.start + span.length {
      return i
    }
  }
  0
}

///|
fn text_span_font(instance : TextInstance, span_index : Int) -> TextFont {
  if span_index == 0 {
    instance.font
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].font
    } else {
      instance.font
    }
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
fn text_span_line_height(
  instance : TextInstance,
  span_index : Int,
) -> LineHeight {
  if span_index == 0 {
    instance.line_height
  } else {
    let index = span_index - 1
    if index >= 0 && index < instance.spans.length() {
      instance.spans[index].line_height
    } else {
      instance.line_height
    }
  }
}

///|
let font_atlas_set_state : Ref[FontAtlasSet] = Ref::new(FontAtlasSet::default())

///|
fn text_update_layout(instance : TextInstance) -> TextInstance {
  if !instance.computed.needs_rerender {
    return instance
  }
  let buffer = build_text_buffer(instance)
  let entities = build_text_entities(instance)
  let glyphs : Array[PositionedGlyph] = []
  let run_geometry : Array[RunGeometry] = []
  let mut missing_glyph = false
  let mut max_x = 0.0F
  let mut max_y = 0.0F
  let mut line_index = 0
  let mut x = 0.0F
  let line_height = instance.line_height.eval(instance.font.font_size)
  let mut line_y = line_height
  let line_widths : Array[Float] = [0.0F]
  let max_width = match buffer.max_width {
    Some(value) => value
    None => -1.0F
  }
  let wrap_enabled = if max_width <= 0.0F {
    false
  } else {
    match buffer.linebreak {
      LineBreak::NoWrap => false
      _ => true
    }
  }
  let count = buffer.text.length()
  for i in 0..<count {
    let code = buffer.text.code_unit_at(i).to_int()
    if code == 10 {
      if x > max_x {
        max_x = x
      }
      line_widths[line_index] = x
      x = 0.0F
      line_index = line_index + 1
      if line_index >= line_widths.length() {
        line_widths.push(0.0F)
      }
      line_y = line_y + line_height
      continue
    }
    let span_index = resolve_span_index(buffer, i)
    let text_font = text_span_font(instance, span_index)
    let span_line_height = text_span_line_height(instance, span_index)
    let span_height = span_line_height.eval(text_font.font_size)
    let smoothing = entities[span_index].font_smoothing
    let advance = host_font_measure_advance(
      text_font.font.id(),
      text_font.font_size,
      code,
    )
    if code == 32 {
      x = x + advance
      continue
    }
    if code == 9 {
      let space_advance = host_font_measure_advance(
        text_font.font.id(),
        text_font.font_size,
        32,
      )
      x = x + space_advance * 4.0F
      continue
    }
    if wrap_enabled && x > 0.0F && advance > 0.0F && x + advance > max_width {
      if x > max_x {
        max_x = x
      }
      line_widths[line_index] = x
      x = 0.0F
      line_index = line_index + 1
      if line_index >= line_widths.length() {
        line_widths.push(0.0F)
      }
      line_y = line_y + line_height
    }
    let raster_opt = font_rasterize_glyph(
      text_font.font,
      text_font.font_size,
      code,
      smoothing,
    )
    if raster_opt is None {
      missing_glyph = true
      continue
    }
    let raster = if raster_opt is Some(value) { value } else { continue }
    let cache_key = GlyphCacheKey::new(raster.id, 0, 0)
    let font_key = FontAtlasKey::new(
      text_font.font,
      text_font.font_size,
      smoothing,
    )
    let atlases = font_atlas_set_state.val.get_or_insert(font_key)
    let atlas_info_opt = add_glyph_to_atlas(
      atlases, cache_key, raster, smoothing,
    )
    if atlas_info_opt is None {
      missing_glyph = true
      continue
    }
    let atlas_info = if atlas_info_opt is Some(value) {
      value
    } else {
      continue
    }
    let size_x = Float::from_double(raster.size.x.to_double())
    let size_y = Float::from_double(raster.size.y.to_double())
    let offset_x = Float::from_double(raster.offset.x.to_double())
    let offset_y = Float::from_double(raster.offset.y.to_double())
    let glyph_min_x = x + offset_x
    let line_base = if span_height > line_height {
      span_height
    } else {
      line_height
    }
    let glyph_min_y = line_y - offset_y + (line_base - line_height)
    let glyph_center_x = glyph_min_x + size_x / 2.0F
    let glyph_center_y = glyph_min_y + size_y / 2.0F
    let glyph_pos = @math.Vec2::new(glyph_center_x, glyph_center_y)
    let glyph_size = @math.Vec2::new(size_x, size_y)
    glyphs.push(PositionedGlyph::{
      position: glyph_pos,
      size: glyph_size,
      atlas_info,
      span_index,
      line_index,
      byte_index: i,
      byte_length: 1,
    })
    let glyph_max_x = glyph_min_x + size_x
    let glyph_max_y = glyph_min_y + size_y
    if glyph_max_x > max_x {
      max_x = glyph_max_x
    }
    if glyph_max_y > max_y {
      max_y = glyph_max_y
    }
    if advance > 0.0F {
      x = x + advance
    } else {
      x = x + size_x
    }
  }
  if x > max_x {
    max_x = x
  }
  if line_index < line_widths.length() {
    line_widths[line_index] = x
  }
  if line_y > max_y {
    max_y = line_y
  }
  let mut target_width = max_x
  if max_width > 0.0F && max_width > target_width {
    target_width = max_width
  }
  let adjusted_glyphs : Array[PositionedGlyph] = []
  for glyph in glyphs {
    let mut offset_x = 0.0F
    if glyph.line_index >= 0 && glyph.line_index < line_widths.length() {
      let line_width = line_widths[glyph.line_index]
      offset_x = match buffer.justify {
        Justify::Left => 0.0F
        Justify::Center => (target_width - line_width) / 2.0F
        Justify::Right => target_width - line_width
        Justify::Justified => 0.0F
      }
    }
    adjusted_glyphs.push(PositionedGlyph::{
      position: @math.Vec2::new(glyph.position.x + offset_x, glyph.position.y),
      size: glyph.size,
      atlas_info: glyph.atlas_info,
      span_index: glyph.span_index,
      line_index: glyph.line_index,
      byte_index: glyph.byte_index,
      byte_length: glyph.byte_length,
    })
  }
  let updated = TextLayoutInfo::{
    scale_factor: 1.0F,
    glyphs: adjusted_glyphs,
    run_geometry,
    size: @math.Vec2::new(target_width, max_y),
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
pub fn text_update_system() -> Unit {
  let count = text_state.val.texts.length()
  for i in 0..<count {
    text_state.val.texts[i] = text_update_layout(text_state.val.texts[i])
  }
}

///|
pub fn text_render_system() -> Unit {
  @render2d.render2d_clear_overlay_sprites()
  let texts = text_state.val.texts
  for instance in texts {
    let layout_info = instance.layout_info
    let layout_size = layout_info.size
    let origin_x = 0.0F - layout_size.x / 2.0F
    let origin_y = layout_size.y / 2.0F
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
      let glyph_pos = glyph.position
      let offset = @math.Vec2::new(
        origin_x + glyph_pos.x,
        origin_y - glyph_pos.y,
      )
      let translation = @math.Vec2::new(
        instance.transform.translation.x + offset.x,
        instance.transform.translation.y + offset.y,
      )
      let transform = @math.Transform::new(
        translation,
        instance.transform.rotation,
        instance.transform.scale,
      )
      let color = text_span_color(instance, glyph.span_index).color
      if instance.shadow is Some(shadow) {
        let shadow_translation = @math.Vec2::new(
          translation.x + shadow.offset.x,
          translation.y + shadow.offset.y,
        )
        let shadow_transform = @math.Transform::new(
          shadow_translation,
          instance.transform.rotation,
          instance.transform.scale,
        )
        @render2d.render2d_push_sprite_uv(
          atlas_info.texture,
          shadow_transform,
          uv_min,
          uv_max,
          shadow.color,
          instance.layers,
        )
      }
      @render2d.render2d_push_sprite_uv(
        atlas_info.texture,
        transform,
        uv_min,
        uv_max,
        color,
        instance.layers,
      )
    }
  }
}

///|
pub fn text_plugin(app : @app.App) -> @app.App {
  app.add_system(text_update_system).add_system(text_render_system)
}
