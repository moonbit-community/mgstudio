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

/// Metrics hinting strategy
pub(all) enum Hinting {
  Disabled
  Enabled
}

/// Wrapping mode
pub(all) enum Wrap {
  None
  Glyph
  Word
  WordOrGlyph
}

/// Align or justify
pub(all) enum Align {
  Left
  Right
  Center
  Justified
  End
}

/// A laid out glyph (MVP subset)
pub struct LayoutGlyph {
  start : Int
  end : Int
  x : Float
  y : Float
  w : Float
  x_offset : Float
  y_offset : Float
  metadata : Int
}

/// A line of laid out glyphs (MVP subset)
pub struct LayoutLine {
  start : Int
  end : Int
  w : Float
  glyphs : Array[LayoutGlyph]
}

fn float_from_int(v : Int) -> Float {
  Float::from_double(v.to_double())
}

fn is_space_u16(c : UInt16) -> Bool {
  c == 32
}

fn max_int(a : Int, b : Int) -> Int {
  if a > b { a } else { b }
}

fn build_layout_line_from_shape(
  shape : ShapeLine,
  start : Int,
  end : Int,
  cell_w : Float,
) -> LayoutLine {
  let glyphs : Array[LayoutGlyph] = []
  let mut x = 0.0F
  // MVP: glyph index == code unit index.
  for i in start..<end {
    let g = shape.glyphs[i]
    let w = g.x_advance * cell_w
    glyphs.push(LayoutGlyph::{
      start: g.start,
      end: g.end,
      x,
      y: 0.0F,
      w,
      x_offset: 0.0F,
      y_offset: 0.0F,
      metadata: g.metadata,
    })
    x = x + w
  }
  LayoutLine::{ start, end, w: x, glyphs }
}

fn push_layout_line_from_shape(
  lines : Array[LayoutLine],
  shape : ShapeLine,
  start : Int,
  end : Int,
  cell_w : Float,
) -> Unit {
  if end <= start {
    return
  }
  lines.push(build_layout_line_from_shape(shape, start, end, cell_w))
}

fn push_line(lines : Array[LayoutLine], text_start : Int, text_end : Int, glyph_w : Float) -> Unit {
  let len = text_end - text_start
  let w = glyph_w * float_from_int(len)
  // MVP: 1 glyph per code unit, with x computed from glyph width.
  let glyphs : Array[LayoutGlyph] = []
  for i in 0..<len {
    glyphs.push(LayoutGlyph::{
      start: text_start + i,
      end: text_start + i + 1,
      x: glyph_w * float_from_int(i),
      y: 0.0F,
      w: glyph_w,
      x_offset: 0.0F,
      y_offset: 0.0F,
      metadata: 0,
    })
  }
  lines.push(LayoutLine::{ start: text_start, end: text_end, w, glyphs })
}

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
pub fn layout_ascii(text : String, glyph_w : Float, width_opt : Float?, wrap : Wrap) -> Array[LayoutLine] {
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

  // Word/WordOrGlyph: treat runs of non-space as words, spaces as separators.
  let mut line_start = 0
  let mut line_end = 0
  let mut i = 0
  while i < len {
    // Skip leading spaces for the next word. We drop them at the start of a line.
    while i < len && is_space_u16(text.code_unit_at(i)) {
      i = i + 1
      if line_end == line_start {
        line_start = i
        line_end = i
      }
    }
    if i >= len {
      break
    }

    // Word range [word_start, word_end)
    let word_start = i
    while i < len && !is_space_u16(text.code_unit_at(i)) {
      i = i + 1
    }
    let word_end = i

    let word_w = glyph_w * float_from_int(word_end - word_start)
    let cur_w = glyph_w * float_from_int(line_end - line_start)
    let would_w = cur_w + word_w

    if line_end == line_start {
      // Empty line: word must be placed here.
      if word_w > max_w && fallback_to_glyph {
        push_line_glyph_chunks(lines, word_start, word_end, glyph_w, max_w)
        line_start = i
        line_end = i
      } else {
        line_end = word_end
      }
    } else if would_w > max_w {
      // New line before this word.
      push_line(lines, line_start, line_end, glyph_w)
      line_start = word_start
      if word_w > max_w && fallback_to_glyph {
        push_line_glyph_chunks(lines, word_start, word_end, glyph_w, max_w)
        line_start = i
        line_end = i
      } else {
        line_end = word_end
      }
    } else {
      // Append word
      line_end = word_end
    }
  }

  if line_end > line_start {
    push_line(lines, line_start, line_end, glyph_w)
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
  cell_w : Float,
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
      push_layout_line_from_shape(lines, shape, 0, len, cell_w)
      return lines
    }
    _ => ()
  }
  if width_opt is None {
    push_layout_line_from_shape(lines, shape, 0, len, cell_w)
    return lines
  }

  let max_w = if width_opt is Some(w) { w } else { 0.0F }

  match wrap {
    Glyph => {
      let max_cells_f = (max_w / cell_w).to_double()
      let max_cells = max_int(1, max_cells_f.to_int())
      let mut start = 0
      let mut x = 0
      for i in 0..<len {
        let adv = shape.glyphs[i].x_advance
        // Convert to integer-ish cells for packing. Tabs may be >1.
        let adv_cells = adv.to_double().to_int()
        if x + adv_cells > max_cells && i > start {
          push_layout_line_from_shape(lines, shape, start, i, cell_w)
          start = i
          x = 0
        }
        x = x + adv_cells
      }
      push_layout_line_from_shape(lines, shape, start, len, cell_w)
      return lines
    }
    _ => ()
  }

  let fallback_to_glyph = match wrap {
    WordOrGlyph => true
    _ => false
  }

  // Word/WordOrGlyph: whitespace-based word indices for now.
  let words = word_indices_whitespace(text)
  if words.length() == 0 {
    return lines
  }

  let mut line_start = words[0].0
  let mut line_end = words[0].1

  for wi in 1..<words.length() {
    let word = words[wi]
    let w_start = word.0
    let w_end = word.1
    let word_cells = w_end - w_start
    let cur_cells = line_end - line_start
    let would_cells = cur_cells + word_cells
    let would_w = float_from_int(would_cells) * cell_w
    if would_w > max_w {
      // emit current
      push_layout_line_from_shape(lines, shape, line_start, line_end, cell_w)
      line_start = w_start
      line_end = w_end

      if fallback_to_glyph && float_from_int(word_cells) * cell_w > max_w {
        // Re-layout this single word with glyph wrapping.
        let word_lines = layout_from_shape(
          text,
          shape,
          cell_w,
          width_opt,
          Glyph,
        )
        // Filter the word-only lines that are within [w_start,w_end).
        for l in word_lines {
          if l.start >= w_start && l.end <= w_end {
            lines.push(l)
          }
        }
        line_start = w_end
        line_end = w_end
      }
    } else {
      line_end = w_end
    }
  }

  push_layout_line_from_shape(lines, shape, line_start, line_end, cell_w)
  lines
}

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
      LayoutLine::{ ..line, glyphs }
    }
    Right | End => {
      let dx = extra
      let glyphs : Array[LayoutGlyph] = []
      for g in line.glyphs {
        glyphs.push(LayoutGlyph::{ ..g, x: g.x + dx })
      }
      LayoutLine::{ ..line, glyphs }
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
        if g.end - g.start == 1 && g.start >= 0 && g.start < text.length() &&
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
