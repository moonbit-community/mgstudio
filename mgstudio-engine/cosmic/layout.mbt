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
/// Minimal layout scaffolding ported from `cosmic-text/src/layout.rs`.
///
/// NOTE: This is an MVP focused on wrap/layout tests; shaping/font fallback will be added later.

///|
/// Metrics hinting strategy
pub(all) enum Hinting {
  Disabled
  Enabled
}

///|
/// Wrapping mode
pub(all) enum Wrap {
  None
  Glyph
  Word
  WordOrGlyph
}

///|
/// Align or justify
pub(all) enum Align {
  Left
  Right
  Center
  Justified
  End
}

///|
/// A laid out glyph (MVP subset)
pub struct LayoutGlyph {
  start : Int
  end : Int
  font_size : Float
  font_id : Int
  font_weight : Int
  glyph_id : Int
  x : Float
  y : Float
  w : Float
  /// BiDi embedding level (LTR if divisible by 2).
  level : Int
  line_height_opt : Float?
  x_offset : Float
  y_offset : Float
  color_opt : Color?
  metadata : Int
  cache_key_flags : CacheKeyFlags
}

///|
/// Convenience constructor (fills optional fields with defaults).
pub fn LayoutGlyph::new(
  start : Int,
  end : Int,
  font_size : Float,
  font_id : Int,
  font_weight : Int,
  glyph_id : Int,
  x : Float,
  y : Float,
  w : Float,
  metadata : Int,
) -> LayoutGlyph {
  LayoutGlyph::{
    start,
    end,
    font_size,
    font_id,
    font_weight,
    glyph_id,
    x,
    y,
    w,
    level: 0,
    line_height_opt: None,
    x_offset: 0.0F,
    y_offset: 0.0F,
    color_opt: None,
    metadata,
    cache_key_flags: 0U,
  }
}

///|
/// A line of laid out glyphs (MVP subset)
pub struct LayoutLine {
  start : Int
  end : Int
  w : Float
  max_ascent : Float
  max_descent : Float
  line_height_opt : Float?
  glyphs : Array[LayoutGlyph]
}

///|
/// A laid out glyph in physical/pixel coordinates, ready for rasterization.
pub struct PhysicalGlyph {
  cache_key : CacheKey
  x : Int
  y : Int
}

///|
pub fn LayoutGlyph::physical(
  self : LayoutGlyph,
  offset : (Float, Float),
  scale : Float,
) -> PhysicalGlyph {
  let x_off = self.font_size * self.x_offset
  let y_off = self.font_size * self.y_offset
  let pos_x = (self.x + x_off) * scale + offset.0
  // Hinting in Y axis (match upstream idea): truncate to integral.
  let pos_y = truncf((self.y - y_off) * scale + offset.1)
  let (cache_key, x, y) = CacheKey::new(
    self.font_id,
    self.glyph_id,
    self.font_size * scale,
    (pos_x, pos_y),
    self.font_weight,
    self.cache_key_flags,
  )
  PhysicalGlyph::{ cache_key, x, y }
}

///|
fn float_from_int(v : Int) -> Float {
  Float::from_double(v.to_double())
}

///|

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn reverse_shape_glyph_slice(
  glyphs : Array[ShapeGlyph],
  start : Int,
  end : Int,
) -> Unit {
  let mut i = start
  let mut j = end - 1
  while i < j {
    let a = glyphs[i]
    let b = glyphs[j]
    glyphs.set(i, b)
    glyphs.set(j, a)
    i = i + 1
    j = j - 1
  }
}

///|
/// Reorder a logical glyph sequence into visual order based on embedding levels.
///
/// This follows the Unicode Bidirectional Algorithm reordering procedure:
/// for each level from max down to 1, reverse contiguous runs with level >= current.
fn reorder_bidi_glyphs(glyphs : Array[ShapeGlyph]) -> Array[ShapeGlyph] {
  let out : Array[ShapeGlyph] = []
  for g in glyphs {
    out.push(g)
  }
  if out.length() < 2 {
    return out
  }
  let mut max_level = out[0].level
  for g in out {
    if g.level > max_level {
      max_level = g.level
    }
  }
  let mut level = max_level
  while level >= 1 {
    let mut i = 0
    while i < out.length() {
      while i < out.length() && out[i].level < level {
        i = i + 1
      }
      let start = i
      while i < out.length() && out[i].level >= level {
        i = i + 1
      }
      let end = i
      if end > start + 1 {
        reverse_shape_glyph_slice(out, start, end)
      }
    }
    level = level - 1
  }
  out
}

///|
/// Returns the first glyph index whose covered text range intersects `text_offset`.
///
/// This is used to map text indices (code units) to glyph indices for wrapping.
fn glyph_index_for_text_start(shape : ShapeLine, text_offset : Int) -> Int {
  let len = shape.glyphs.length()
  for i in 0..<len {
    let g = shape.glyphs[i]
    if g.end > text_offset {
      return i
    }
  }
  len
}

///|
/// Returns the first glyph index whose start is at or after `text_offset`.
fn glyph_index_for_text_end(shape : ShapeLine, text_offset : Int) -> Int {
  let len = shape.glyphs.length()
  for i in 0..<len {
    if shape.glyphs[i].start >= text_offset {
      return i
    }
  }
  len
}

///|
fn prefix_range_w(prefix : Array[Float], start : Int, end : Int) -> Float {
  let s = if start < 0 { 0 } else { start }
  let e = if end < s { s } else { end }
  let a = if prefix.get(s) is Some(v) { v } else { 0.0F }
  let b = if prefix.get(e) is Some(v) { v } else { a }
  b - a
}

///|
fn build_layout_line_from_shape(
  shape : ShapeLine,
  glyph_start : Int,
  glyph_end : Int,
  font_size : Float,
  cell_w : Float,
) -> LayoutLine {
  let glyphs : Array[LayoutGlyph] = []
  // Compute the source text span for this visual line from glyph coverage.
  let mut text_start = shape.glyphs[glyph_start].start
  let mut text_end = shape.glyphs[glyph_start].end
  for i in glyph_start..<glyph_end {
    let g = shape.glyphs[i]
    if g.start < text_start {
      text_start = g.start
    }
    if g.end > text_end {
      text_end = g.end
    }
  }
  // Reorder glyphs into visual order (handles mixed-direction text).
  let logical : Array[ShapeGlyph] = []
  for i in glyph_start..<glyph_end {
    logical.push(shape.glyphs[i])
  }
  let visual = reorder_bidi_glyphs(logical)
  let mut x = 0.0F
  for g in visual {
    let w = g.x_advance * cell_w
    glyphs.push(LayoutGlyph::{
      start: g.start,
      end: g.end,
      font_size,
      font_id: g.font_id,
      font_weight: g.font_weight,
      glyph_id: g.glyph_id,
      x,
      y: 0.0F,
      w,
      level: g.level,
      line_height_opt: None,
      x_offset: g.x_offset,
      y_offset: g.y_offset,
      color_opt: None,
      metadata: g.metadata,
      cache_key_flags: 0U,
    })
    x = x + w
  }
  LayoutLine::{
    start: text_start,
    end: text_end,
    w: x,
    max_ascent: 0.0F,
    max_descent: 0.0F,
    line_height_opt: None,
    glyphs,
  }
}

///|
fn push_layout_line_from_shape(
  lines : Array[LayoutLine],
  shape : ShapeLine,
  glyph_start : Int,
  glyph_end : Int,
  font_size : Float,
  cell_w : Float,
) -> Unit {
  if glyph_end <= glyph_start {
    return
  }
  lines.push(
    build_layout_line_from_shape(
      shape, glyph_start, glyph_end, font_size, cell_w,
    ),
  )
}

///|
fn layout_glyph_wrap_range(
  shape : ShapeLine,
  range_start : Int,
  range_end : Int,
  font_size : Float,
  cell_w : Float,
  max_w : Float,
) -> Array[LayoutLine] {
  let lines : Array[LayoutLine] = []
  if range_end <= range_start {
    return lines
  }
  let mut start = range_start
  let mut w = 0.0F
  for i in range_start..<range_end {
    let adv_w = shape.glyphs[i].x_advance * cell_w
    if w + adv_w > max_w && i > start {
      push_layout_line_from_shape(lines, shape, start, i, font_size, cell_w)
      start = i
      w = 0.0F
    }
    w = w + adv_w
  }
  push_layout_line_from_shape(lines, shape, start, range_end, font_size, cell_w)
  lines
}

///|
fn push_line(
  lines : Array[LayoutLine],
  text_start : Int,
  text_end : Int,
  glyph_w : Float,
) -> Unit {
  let len = text_end - text_start
  let w = glyph_w * float_from_int(len)
  // MVP: 1 glyph per code unit, with x computed from glyph width.
  let glyphs : Array[LayoutGlyph] = []
  for i in 0..<len {
    glyphs.push(LayoutGlyph::{
      start: text_start + i,
      end: text_start + i + 1,
      font_size: glyph_w,
      font_id: 0,
      font_weight: 400,
      glyph_id: 0,
      x: glyph_w * float_from_int(i),
      y: 0.0F,
      w: glyph_w,
      level: 0,
      line_height_opt: None,
      x_offset: 0.0F,
      y_offset: 0.0F,
      color_opt: None,
      metadata: 0,
      cache_key_flags: 0U,
    })
  }
  lines.push(LayoutLine::{
    start: text_start,
    end: text_end,
    w,
    max_ascent: 0.0F,
    max_descent: 0.0F,
    line_height_opt: None,
    glyphs,
  })
}

///|
fn push_line_glyph_chunks(
  lines : Array[LayoutLine],
  text_start : Int,
  text_end : Int,
  glyph_w : Float,
  max_w : Float,
) -> Unit {
  let max_glyphs_f = (max_w / glyph_w).to_double()
  let max_glyphs = max_int(1, max_glyphs_f.to_int())
  let mut i = text_start
  while i < text_end {
    let next = if i + max_glyphs > text_end { text_end } else { i + max_glyphs }
    push_line(lines, i, next, glyph_w)
    i = next
  }
}

///|
/// ASCII-only layout for wrap tests.
///
/// Semantics:
/// - Treat each code unit as one glyph.
/// - `glyph_w` is a monospace advance in pixels.
pub fn layout_ascii(
  text : String,
  glyph_w : Float,
  width_opt : Float?,
  wrap : Wrap,
) -> Array[LayoutLine] {
  let len = text.length()
  let lines : Array[LayoutLine] = []
  if len == 0 {
    return lines
  }
  match wrap {
    None => {
      push_line(lines, 0, len, glyph_w)
      return lines
    }
    Glyph => {
      let max_w = if width_opt is Some(w) { w } else { 0.0F }
      push_line_glyph_chunks(lines, 0, len, glyph_w, max_w)
      return lines
    }
    _ => ()
  }
  if width_opt is None {
    push_line(lines, 0, len, glyph_w)
    return lines
  }
  let max_w = if width_opt is Some(w) { w } else { 0.0F }
  let fallback_to_glyph = match wrap {
    WordOrGlyph => true
    _ => false
  }

  // Word/WordOrGlyph: linebreak-based segments with explicit blank tokens.
  let segs = wrap_word_segments(text)
  let mut i = 0
  while i < segs.length() {
    // Skip leading blank segments.
    while i < segs.length() && segs[i].2 {
      i = i + 1
    }
    if i >= segs.length() {
      break
    }
    let line_start_i = i
    let start_pos = segs[line_start_i].0
    let mut cur_end_pos = start_pos
    let mut last_non_blank_end_pos = start_pos
    let mut emitted = false
    while i < segs.length() {
      let seg = segs[i]
      let blank = seg.2
      let word_w = glyph_w * float_from_int(seg.1 - seg.0)
      let cur_w = glyph_w * float_from_int(cur_end_pos - start_pos)
      let would_w = glyph_w * float_from_int(seg.1 - start_pos)
      let fits = would_w <= max_w || (blank && cur_w <= max_w)
      if fits {
        cur_end_pos = seg.1
        if !blank {
          last_non_blank_end_pos = seg.1
        }
        i = i + 1
        continue
      }

      // Doesn't fit.
      if cur_end_pos == start_pos {
        // Segment doesn't fit on an empty line.
        if fallback_to_glyph && !blank && word_w > max_w {
          push_line_glyph_chunks(lines, seg.0, seg.1, glyph_w, max_w)
          i = i + 1
          emitted = true
          break
        } else {
          // Place it anyway (may overflow), then start new line.
          push_line(lines, seg.0, seg.1, glyph_w)
          i = i + 1
          emitted = true
          break
        }
      }

      // Emit current line without trailing blanks (blank tokens are explicit).
      if last_non_blank_end_pos > start_pos {
        push_line(lines, start_pos, last_non_blank_end_pos, glyph_w)
      }
      emitted = true
      // Start a new line at the current segment (don't consume it).
      break
    }

    // End-of-input: emit remaining line (trim trailing blanks).
    if i >= segs.length() && !emitted && last_non_blank_end_pos > start_pos {
      push_line(lines, start_pos, last_non_blank_end_pos, glyph_w)
    }
  }
  lines
}

///|
/// Layout from ShapeLine (MVP).
///
/// `cell_w` is the pixel width per "advance cell" (ShapeGlyph.x_advance is in cells).
pub fn layout_from_shape(
  text : String,
  shape : ShapeLine,
  font_size : Float,
  cell_w : Float,
  width_opt : Float?,
  wrap : Wrap,
) -> Array[LayoutLine] {
  let lines : Array[LayoutLine] = []
  if text.length() == 0 {
    return lines
  }
  let glyph_len = shape.glyphs.length()
  if glyph_len == 0 {
    return lines
  }
  match wrap {
    None => {
      push_layout_line_from_shape(lines, shape, 0, glyph_len, font_size, cell_w)
      return lines
    }
    _ => ()
  }
  match (width_opt, wrap) {
    // No width constraint:
    // - Glyph wrap: no wrapping required, keep full glyph span (includes spaces).
    // - Word/WordOrGlyph: still trim leading/trailing whitespace by using word boundaries,
    //   so feeding measured width back as a wrap limit stays stable.
    (None, Glyph) => {
      push_layout_line_from_shape(lines, shape, 0, glyph_len, font_size, cell_w)
      return lines
    }
    (None, Word) | (None, WordOrGlyph) => {
      let segs = wrap_word_segments(text)
      let words : Array[(Int, Int)] = []
      for seg in segs {
        if !seg.2 {
          words.push((seg.0, seg.1))
        }
      }
      if words.length() == 0 {
        return lines
      }
      let first = words[0]
      let last = words[words.length() - 1]
      let start_g = glyph_index_for_text_start(shape, first.0)
      let end_g = glyph_index_for_text_end(shape, last.1)
      push_layout_line_from_shape(
        lines, shape, start_g, end_g, font_size, cell_w,
      )
      return lines
    }
    _ => ()
  }
  let max_w = if width_opt is Some(w) { w } else { 0.0F }
  match wrap {
    Glyph => {
      let mut start = 0
      let mut w = 0.0F
      for i in 0..<glyph_len {
        let adv_w = shape.glyphs[i].x_advance * cell_w
        if w + adv_w > max_w && i > start {
          push_layout_line_from_shape(lines, shape, start, i, font_size, cell_w)
          start = i
          w = 0.0F
        }
        w = w + adv_w
      }
      push_layout_line_from_shape(
        lines, shape, start, glyph_len, font_size, cell_w,
      )
      return lines
    }
    _ => ()
  }
  let fallback_to_glyph = match wrap {
    WordOrGlyph => true
    _ => false
  }

  // Prefix sums of pixel advances for quick range width queries.
  let prefix : Array[Float] = []
  let mut acc = 0.0F
  prefix.push(acc)
  for i in 0..<glyph_len {
    acc = acc + shape.glyphs[i].x_advance * cell_w
    prefix.push(acc)
  }

  // Word/WordOrGlyph: linebreak-based segments with explicit blank tokens.
  let segs = wrap_word_segments(text)
  if segs.length() == 0 {
    return lines
  }
  let mut i = 0
  while i < segs.length() {
    // Skip leading blank segments.
    while i < segs.length() && segs[i].2 {
      i = i + 1
    }
    if i >= segs.length() {
      break
    }
    let line_start_i = i
    let line_start_text = segs[line_start_i].0
    let line_start_g = glyph_index_for_text_start(shape, line_start_text)
    let mut cur_end_g = line_start_g
    let mut last_non_blank_end_g = line_start_g
    let mut emitted = false
    // Track last "fitting" glyph end (including blanks), but emit trimmed.
    while i < segs.length() {
      let seg = segs[i]
      let blank = seg.2
      let would_end_g = glyph_index_for_text_end(shape, seg.1)
      let would_w = prefix_range_w(prefix, line_start_g, would_end_g)
      let cur_w = prefix_range_w(prefix, line_start_g, cur_end_g)
      let fits = would_w <= max_w || (blank && cur_w <= max_w)
      if fits {
        cur_end_g = would_end_g
        if !blank {
          last_non_blank_end_g = would_end_g
        }
        i = i + 1
        continue
      }

      // Doesn't fit.
      if i == line_start_i {
        // Segment doesn't fit on an empty line.
        let word_start_g = glyph_index_for_text_start(shape, seg.0)
        let word_end_g = glyph_index_for_text_end(shape, seg.1)
        if fallback_to_glyph &&
          !blank &&
          prefix_range_w(prefix, word_start_g, word_end_g) > max_w {
          let word_lines = layout_glyph_wrap_range(
            shape, word_start_g, word_end_g, font_size, cell_w, max_w,
          )
          for l in word_lines {
            lines.push(l)
          }
          i = i + 1
          emitted = true
        } else {
          // Place the word anyway (may overflow).
          push_layout_line_from_shape(
            lines, shape, word_start_g, word_end_g, font_size, cell_w,
          )
          i = i + 1
          emitted = true
        }
        break
      }

      // Emit current line trimmed of trailing blanks.
      if last_non_blank_end_g > line_start_g {
        push_layout_line_from_shape(
          lines, shape, line_start_g, last_non_blank_end_g, font_size, cell_w,
        )
      }
      emitted = true
      // Start a new line at the current segment (do not consume it).
      break
    }

    // End-of-input: emit remaining line trimmed.
    if i >= segs.length() && !emitted && last_non_blank_end_g > line_start_g {
      push_layout_line_from_shape(
        lines, shape, line_start_g, last_non_blank_end_g, font_size, cell_w,
      )
    }
  }
  lines
}

///|
fn apply_align_to_line(
  text : String,
  line : LayoutLine,
  width : Float,
  align : Align,
) -> LayoutLine {
  let extra = width - line.w
  if extra <= 0.0F {
    return line
  }
  match align {
    Left => line
    Center => {
      let dx = extra / 2.0F
      let glyphs : Array[LayoutGlyph] = []
      for g in line.glyphs {
        glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx })
      }
      LayoutLine::{ ..line, glyphs, }
    }
    Right | End => {
      let dx = extra
      let glyphs : Array[LayoutGlyph] = []
      for g in line.glyphs {
        glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx })
      }
      LayoutLine::{ ..line, glyphs, }
    }
    Justified => {
      // MVP: distribute extra width across ASCII spaces in this line.
      let mut space_count = 0
      for i in line.start..<line.end {
        if i >= 0 && i < text.length() && text.code_unit_at(i) == 32 {
          space_count = space_count + 1
        }
      }
      if space_count == 0 {
        return line
      }
      let add = extra / Float::from_double(space_count.to_double())
      let glyphs : Array[LayoutGlyph] = []
      let mut dx = 0.0F
      for g in line.glyphs {
        let mut w = g.w
        // Space glyph is identified by [start,end) covering a single code unit space.
        if g.end - g.start == 1 &&
          g.start >= 0 &&
          g.start < text.length() &&
          text.code_unit_at(g.start) == 32 {
          w = w + add
          glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx, w })
          dx = dx + add
        } else {
          glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx, w })
        }
      }
      LayoutLine::{ ..line, w: line.w + extra, glyphs }
    }
  }
}

///|
/// Apply Align to precomputed layout lines (requires a finite width).
pub fn apply_align(
  text : String,
  lines : Array[LayoutLine],
  width : Float,
  align : Align,
) -> Array[LayoutLine] {
  let out : Array[LayoutLine] = []
  for line in lines {
    out.push(apply_align_to_line(text, line, width, align))
  }
  out
}
