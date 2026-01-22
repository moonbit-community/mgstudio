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
  w : Float
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
      w: glyph_w,
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
