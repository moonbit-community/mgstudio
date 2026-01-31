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
/// Minimal shaping port scaffold from `cosmic-text/src/shape.rs`.
///
/// This MVP produces 1 glyph per UTF-16 code unit and does not perform script runs,
/// harfbuzz shaping, BiDi, or font fallback.
pub(all) enum Shaping {
  Basic
  Advanced
}

///|
pub struct ShapeGlyph {
  start : Int
  end : Int
  x_advance : Float
  y_advance : Float
  x_offset : Float
  y_offset : Float
  font_id : Int
  font_weight : Int
  glyph_id : Int
  metadata : Int
  /// BiDi embedding level (LTR if divisible by 2).
  level : Int
}

///|
pub fn ShapeGlyph::new(
  start : Int,
  end : Int,
  x_advance : Float,
  y_advance : Float,
  x_offset : Float,
  y_offset : Float,
  font_id : Int,
  glyph_id : Int,
  metadata : Int,
) -> ShapeGlyph {
  ShapeGlyph::{
    start,
    end,
    x_advance,
    y_advance,
    x_offset,
    y_offset,
    font_id,
    font_weight: 400,
    glyph_id,
    metadata,
    level: 0,
  }
}

///|
pub struct ShapeLine {
  rtl : Bool
  glyphs : Array[ShapeGlyph]
}

///|
pub fn ShapeLine::new(rtl : Bool, glyphs : Array[ShapeGlyph]) -> ShapeLine {
  ShapeLine::{ rtl, glyphs }
}

///|
pub fn ShapeLine::empty() -> ShapeLine {
  ShapeLine::{ rtl: false, glyphs: [] }
}

///|
fn is_tab(code : Int) -> Bool {
  code == 9
}

///|
fn utf16_len_of_char(ch : Char) -> Int {
  // UTF-16: codepoints outside BMP take 2 code units.
  if ch.to_int() <= 0xFFFF {
    1
  } else {
    2
  }
}

///|
fn bidi_is_strong_rtl(b : @moon_swash.BidiClass) -> Bool {
  match b {
    R | AL | AN | RLE | RLO | RLI => true
    _ => false
  }
}

///|
fn bidi_is_strong_ltr(b : @moon_swash.BidiClass) -> Bool {
  match b {
    L | LRE | LRO | LRI => true
    _ => false
  }
}

///|
fn detect_base_rtl(text : String) -> Bool {
  // Heuristic: use the first strong directional character.
  for ch in text {
    let props = @moon_swash.CharInfo::from_char(ch).properties()
    let bidi = props.bidi_class()
    if bidi_is_strong_rtl(bidi) {
      return true
    }
    if bidi_is_strong_ltr(bidi) {
      return false
    }
  }
  false
}

///|
fn compute_bidi_levels(text : String, rtl : Bool) -> Array[Int] {
  let base = if rtl { 1 } else { 0 }
  let levels : Array[Int] = Array::makei(text.length(), _ => base)
  for p in text.iter2() {
    let idx = p.0
    let ch = p.1
    let props = @moon_swash.CharInfo::from_char(ch).properties()
    let bidi = props.bidi_class()
    let lev = if bidi_is_strong_rtl(bidi) {
      1
    } else if bidi_is_strong_ltr(bidi) {
      if rtl {
        2
      } else {
        0
      }
    } else {
      base
    }
    let end = idx + ch.utf16_len()
    let mut i = idx
    while i < end && i < levels.length() {
      levels.set(i, lev)
      i = i + 1
    }
  }
  levels
}

///|
fn script_eq(a : @moon_swash.Script, b : @moon_swash.Script) -> Bool {
  a.to_opentype() == b.to_opentype()
}

///|
/// Build a shaped line from text and attributes list.
///
/// MVP notes:
/// - 1 code unit -> 1 glyph
/// - `glyph_id` is the code unit value
/// - `x_advance` is measured in "cells": 1.0 for normal chars, `tab_width` for tab.
pub fn ShapeLine::build(
  _self : ShapeLine,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
  tab_width : Int,
) -> ShapeLine {
  let rtl = shaping is Advanced && detect_base_rtl(text)
  let levels = compute_bidi_levels(text, rtl)
  let glyphs : Array[ShapeGlyph] = []
  let len = text.length()
  for i in 0..<len {
    let code = text.code_unit_at(i).to_int()
    let advance = if is_tab(code) {
      Float::from_double(tab_width.to_double())
    } else {
      1.0F
    }
    let attrs = attrs_list.get_span(i)
    glyphs.push(ShapeGlyph::{
      start: i,
      end: i + 1,
      x_advance: advance,
      y_advance: 0.0F,
      x_offset: 0.0F,
      y_offset: 0.0F,
      font_id: 0,
      font_weight: attrs.weight_value().value(),
      glyph_id: code,
      metadata: attrs.metadata(),
      level: if levels.get(i) is Some(v) {
        v
      } else {
        0
      },
    })
  }
  ShapeLine::{ rtl, glyphs }
}

///|
/// Build a shaped line using a FontSystem (best-effort).
///
/// Current behavior is still "Basic shaping" (1 UTF-16 code unit -> 1 glyph),
/// but uses `moon_swash` charmap + glyph metrics so advances are font-derived.
pub fn ShapeLine::build_with_font_system(
  _self : ShapeLine,
  font_system : FontSystem,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
  tab_width : Int,
) -> ShapeLine {
  if shaping is Basic {
    return ShapeLine::build(
      ShapeLine::empty(),
      text,
      attrs_list,
      shaping,
      tab_width,
    )
  }
  let default_font_id_opt = font_system.resolve(attrs_list.defaults())
  let default_font_id = match default_font_id_opt {
    None =>
      return ShapeLine::build(
        ShapeLine::empty(),
        text,
        attrs_list,
        shaping,
        tab_width,
      )
    Some(id) => id
  }
  let default_font_opt = font_system.get_font(default_font_id)
  let default_font = match default_font_opt {
    None =>
      return ShapeLine::build(
        ShapeLine::empty(),
        text,
        attrs_list,
        shaping,
        tab_width,
      )
    Some(f) => f
  }

  // Use swash's shaping engine for clusters/ligatures/marks. We intentionally use
  // size=1.0 so the returned advances/offsets are in "em" units (like upstream),
  // which are later multiplied by `font_size` during layout.
  let rtl = detect_base_rtl(text)
  let levels = compute_bidi_levels(text, rtl)
  let direction = if rtl {
    @shape.Direction::RightToLeft
  } else {
    @shape.Direction::LeftToRight
  }
  let cx = @shape.ShapeContext::new()
  let empty_features : Array[@moon_swash.Setting[UInt16]] = []
  let empty_variations : Array[@moon_swash.Setting[Double]] = []
  let default_cmap = @moon_swash.Charmap::from_font(default_font)
  let runs : Array[(Int, @moon_swash.Script, Array[@moon_swash.Token])] = []
  let mut off = 0U
  let mut cur_script = @moon_swash.Script::Latin
  let mut cur_font_id = default_font_id
  let mut cur_tokens : Array[@moon_swash.Token] = []
  for ch0 in text {
    let script0 = @moon_swash.CharInfo::from_char(ch0).properties().script()
    let len_u = utf16_len_of_char(ch0).reinterpret_as_uint()
    let i = off.reinterpret_as_int()
    let attrs = attrs_list.get_span(i)
    // Tabs are shaped as spaces (upstream behavior).
    let ch = if ch0 == '\t' { ' ' } else { ch0 }
    let cp = ch.to_int().reinterpret_as_uint()
    let font_id = match font_system.resolve_for_codepoint(attrs, cp) {
      None => default_font_id
      Some(id) => id
    }
    let info = @moon_swash.CharInfo::from_char(ch)
    let tok = @moon_swash.Token::new(
      ch,
      off,
      len_u,
      info,
      attrs.metadata().reinterpret_as_uint(),
    )
    let effective = match script0 {
      Common | Inherited | Unknown =>
        if cur_tokens.length() == 0 {
          @moon_swash.Script::Latin
        } else {
          cur_script
        }
      _ => script0
    }
    if cur_tokens.length() == 0 {
      cur_script = effective
      cur_font_id = font_id
    } else if !script_eq(effective, cur_script) || font_id != cur_font_id {
      runs.push((cur_font_id, cur_script, cur_tokens))
      cur_tokens = []
      cur_script = effective
      cur_font_id = font_id
    }
    cur_tokens.push(tok)
    off = off + len_u
  }
  let glyphs : Array[ShapeGlyph] = []
  if cur_tokens.length() != 0 {
    runs.push((cur_font_id, cur_script, cur_tokens))
  }
  let cluster = @moon_swash.CharCluster::new()
  for run in runs {
    let font_id = run.0
    let script = run.1
    let run_tokens = run.2
    let font_opt = font_system.get_font(font_id)
    let font = match font_opt {
      None => continue
      Some(f) => f
    }
    let cmap = @moon_swash.Charmap::from_font(font)
    let shaper = cx
      .builder(font)
      .script(script)
      .direction(direction)
      .language(None)
      .size(1.0)
      .features(empty_features.iter())
      .variations(empty_variations.iter())
      .build()
    let parser = @moon_swash.Parser::new(script, run_tokens.iter())
    while parser.next(cluster) {
      cluster.map(fn(ch) { cmap.map(ch.to_int().reinterpret_as_uint()) })
      |> ignore
      shaper.add_cluster(cluster)
    }
    shaper.shape_with(fn(gc) {
      let start = gc.source().start().reinterpret_as_int()
      let end = gc.source().end().reinterpret_as_int()
      let attrs = attrs_list.get_span(start)
      let meta = gc.data().reinterpret_as_int()
      let lev = if levels.get(start) is Some(v) {
        v
      } else if rtl {
        1
      } else {
        0
      }
      for g in gc.glyphs() {
        glyphs.push(ShapeGlyph::{
          start,
          end,
          x_advance: Float::from_double(g.advance()),
          y_advance: 0.0F,
          x_offset: Float::from_double(g.x()),
          y_offset: Float::from_double(g.y()),
          font_id,
          font_weight: attrs.weight_value().value(),
          glyph_id: g.id().to_int(),
          metadata: meta,
          level: lev,
        })
      }
    })
  }

  // If shaping produces no glyphs, fall back to the simple shaper to keep layout stable.
  if glyphs.length() == 0 {
    return ShapeLine::build(
      ShapeLine::empty(),
      text,
      attrs_list,
      shaping,
      tab_width,
    )
  }

  // Apply tab stops by snapping to the next multiple of (space_advance * tab_width).
  let gm = default_font.glyph_metrics([])
  let upem = gm.units_per_em().to_int().to_double()
  let space_gid = default_cmap.map(32U)
  let space_adv = if upem == 0.0 {
    0.0
  } else {
    gm.advance_width(space_gid) / upem
  }
  let step = space_adv * tab_width.to_double()
  if step != 0.0 {
    let mut x = 0.0
    for i in 0..<glyphs.length() {
      let g0 = glyphs[i]
      let is_tab_glyph = g0.end - g0.start == 1 &&
        g0.start >= 0 &&
        g0.start < text.length() &&
        is_tab(text.code_unit_at(g0.start).to_int())
      if is_tab_glyph {
        let next = ((x / step).floor() + 1.0) * step
        let adv = next - x
        let g1 = ShapeGlyph::{ ..g0, x_advance: Float::from_double(adv) }
        glyphs.set(i, g1)
        x = next
      } else {
        x = x + g0.x_advance.to_double()
      }
    }
  }
  ShapeLine::{ rtl, glyphs }
}
