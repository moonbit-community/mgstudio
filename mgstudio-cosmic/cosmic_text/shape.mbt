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
  x_offset : Float
  font_id : Int
  glyph_id : Int
  metadata : Int
}

///|
pub struct ShapeLine {
  rtl : Bool
  glyphs : Array[ShapeGlyph]
}

///|
pub fn ShapeLine::empty() -> ShapeLine {
  ShapeLine::{ rtl: false, glyphs: [] }
}

fn is_tab(code : Int) -> Bool { code == 9 }

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
  _shaping : Shaping,
  tab_width : Int,
) -> ShapeLine {
  let glyphs : Array[ShapeGlyph] = []
  let len = text.length()
  for i in 0..<len {
    let code = text.code_unit_at(i).to_int()
    let advance = if is_tab(code) { Float::from_double(tab_width.to_double()) } else { 1.0F }
    let attrs = attrs_list.get_span(i)
    glyphs.push(ShapeGlyph::{
      start: i,
      end: i + 1,
      x_advance: advance,
      x_offset: 0.0F,
      font_id: 0,
      glyph_id: code,
      metadata: attrs.metadata(),
    })
  }
  ShapeLine::{ rtl: false, glyphs }
}
