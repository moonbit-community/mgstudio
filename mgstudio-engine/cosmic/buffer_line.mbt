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
/// Port scaffold from `cosmic-text/src/buffer_line.rs`.
///
/// This implementation is intentionally minimal and test-driven:
/// - It focuses on cache invalidation and text/span mutations (append/split_off),
///   keeping API naming/semantics aligned with upstream.
fn string_concat(a : String, b : String) -> String {
  let sb = StringBuilder::new(size_hint=(a.length() + b.length()) * 2)
  sb.write_string(a)
  sb.write_string(b)
  sb.to_string()
}

///|
fn substring(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new(size_hint=(end - start) * 2)
  sb.write_view(s[:].view(start_offset=start, end_offset=end))
  sb.to_string()
}

///|
pub struct BufferLine {
  text : String
  ending : LineEnding
  attrs_list : AttrsList
  align : Align?
  shape_opt : Cached[ShapeLine]
  layout_opt : Cached[Array[LayoutLine]]
  shaping : Shaping
  metadata : Int?
}

///|
pub fn BufferLine::new(
  text : String,
  ending : LineEnding,
  attrs_list : AttrsList,
  shaping : Shaping,
) -> BufferLine {
  BufferLine::{
    text,
    ending,
    attrs_list,
    align: None,
    shape_opt: Empty,
    layout_opt: Empty,
    shaping,
    metadata: None,
  }
}

///|
pub fn BufferLine::text(self : BufferLine) -> String {
  self.text
}

///|
pub fn BufferLine::ending(self : BufferLine) -> LineEnding {
  self.ending
}

///|
pub fn BufferLine::set_ending(
  self : BufferLine,
  ending : LineEnding,
) -> BufferLine {
  if ending.as_str() == self.ending.as_str() {
    self
  } else {
    BufferLine::{ ..self, ending, }.reset_layout()
  }
}

///|
pub fn BufferLine::attrs_list(self : BufferLine) -> AttrsList {
  self.attrs_list
}

///|
pub fn BufferLine::align(self : BufferLine) -> Align? {
  self.align
}

///|
pub fn BufferLine::reset(self : BufferLine) -> BufferLine {
  BufferLine::{ ..self, metadata: None }.reset_shaping()
}

///|
pub fn BufferLine::reset_shaping(self : BufferLine) -> BufferLine {
  let shape_opt = self.shape_opt.set_unused()
  BufferLine::{ ..self, shape_opt, }.reset_layout()
}

///|
pub fn BufferLine::reset_layout(self : BufferLine) -> BufferLine {
  let layout_opt = self.layout_opt.set_unused()
  BufferLine::{ ..self, layout_opt, }
}

///|
pub fn BufferLine::shape_opt(self : BufferLine) -> ShapeLine? {
  self.shape_opt.get()
}

///|
pub fn BufferLine::shape(self : BufferLine, tab_width : Int) -> BufferLine {
  if self.shape_opt.is_unused() {
    let (shape_opt, reused_opt) = self.shape_opt.take_unused()
    let reused = if reused_opt is Some(v) { v } else { ShapeLine::empty() }
    let built = reused.build(
      self.text,
      self.attrs_list,
      self.shaping,
      tab_width,
    )
    let shape_opt = shape_opt.set_used(built)
    BufferLine::{ ..self, shape_opt, }.reset_layout()
  } else {
    self
  }
}

///|
/// Shape using a provided FontSystem (best-effort).
///
/// This is an incremental step towards upstream `cosmic-text`:
/// we keep the same cache behavior, but build glyph advances from the font.
pub fn BufferLine::shape_with_font_system(
  self : BufferLine,
  font_system : FontSystem,
  tab_width : Int,
) -> BufferLine {
  if self.shape_opt.is_unused() {
    let (shape_opt, reused_opt) = self.shape_opt.take_unused()
    let reused = if reused_opt is Some(v) { v } else { ShapeLine::empty() }
    let built = reused.build_with_font_system(
      font_system,
      self.text,
      self.attrs_list,
      self.shaping,
      tab_width,
    )
    let shape_opt = shape_opt.set_used(built)
    BufferLine::{ ..self, shape_opt, }.reset_layout()
  } else {
    self
  }
}

///|
pub fn BufferLine::layout_opt(self : BufferLine) -> Array[LayoutLine]? {
  self.layout_opt.get()
}

///|
pub fn BufferLine::layout(
  self : BufferLine,
  font_size : Float,
  width_opt : Float?,
  wrap : Wrap,
  match_mono_width : Float?,
  tab_width : Int,
  hinting : Hinting,
) -> BufferLine {
  if self.layout_opt.is_unused() {
    let line = self.shape(tab_width)
    let shape_opt = line.shape_opt()
    if shape_opt is Some(shape) {
      let cell_w = if match_mono_width is Some(w) { w } else { font_size }
      let mut layout = layout_from_shape(
        line.text,
        shape,
        font_size,
        cell_w,
        width_opt,
        wrap,
      )
      let default_align = if shape.rtl { Align::Right } else { Align::Left }
      let align = if line.align is Some(a) { a } else { default_align }
      if width_opt is Some(width) {
        match align {
          Justified => {
            fn justify_line(
              text : String,
              line : LayoutLine,
              width : Float,
            ) -> LayoutLine {
              let extra = width - line.w
              if extra <= 0.0F {
                return line
              }
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

            let out : Array[LayoutLine] = []
            let n = layout.length()
            for i in 0..<n {
              if i == n - 1 {
                out.push(layout[i])
              } else {
                out.push(justify_line(line.text, layout[i], width))
              }
            }
            layout = out
          }
          _ => layout = apply_align(line.text, layout, width, align)
        }
      }
      if hinting is Hinting::Enabled {
        fn hint_line(l : LayoutLine) -> LayoutLine {
          if l.glyphs.length() == 0 {
            return l
          }
          let glyphs : Array[LayoutGlyph] = []
          let mut x = roundf(l.glyphs[0].x)
          let start_x = x
          for g in l.glyphs {
            let w = roundf(g.w)
            glyphs.push(LayoutGlyph::{ ..g, x, w })
            x = x + w
          }
          LayoutLine::{ ..l, w: x - start_x, glyphs }
        }

        let out : Array[LayoutLine] = []
        for l in layout {
          out.push(hint_line(l))
        }
        layout = out
      }
      let (layout_opt, _) = line.layout_opt.take_unused()
      let layout_opt = layout_opt.set_used(layout)
      BufferLine::{ ..line, layout_opt, }
    } else {
      line
    }
  } else {
    self
  }
}

///|
/// Layout using a provided FontSystem (best-effort).
pub fn BufferLine::layout_with_font_system(
  self : BufferLine,
  font_system : FontSystem,
  font_size : Float,
  width_opt : Float?,
  wrap : Wrap,
  match_mono_width : Float?,
  tab_width : Int,
  hinting : Hinting,
) -> BufferLine {
  if self.layout_opt.is_unused() {
    let line = self.shape_with_font_system(font_system, tab_width)
    let shape_opt = line.shape_opt()
    if shape_opt is Some(shape) {
      let cell_w = if match_mono_width is Some(w) { w } else { font_size }
      let mut layout = layout_from_shape(
        line.text,
        shape,
        font_size,
        cell_w,
        width_opt,
        wrap,
      )
      let default_align = if shape.rtl { Align::Right } else { Align::Left }
      let align = if line.align is Some(a) { a } else { default_align }
      if width_opt is Some(width) {
        match align {
          Justified => {
            fn justify_line(
              text : String,
              line : LayoutLine,
              width : Float,
            ) -> LayoutLine {
              let extra = width - line.w
              if extra <= 0.0F {
                return line
              }
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

            let out : Array[LayoutLine] = []
            let n = layout.length()
            for i in 0..<n {
              if i == n - 1 {
                out.push(layout[i])
              } else {
                out.push(justify_line(line.text, layout[i], width))
              }
            }
            layout = out
          }
          _ => layout = apply_align(line.text, layout, width, align)
        }
      }
      if hinting is Hinting::Enabled {
        fn hint_line(l : LayoutLine) -> LayoutLine {
          if l.glyphs.length() == 0 {
            return l
          }
          let glyphs : Array[LayoutGlyph] = []
          let mut x = roundf(l.glyphs[0].x)
          let start_x = x
          for g in l.glyphs {
            let w = roundf(g.w)
            glyphs.push(LayoutGlyph::{ ..g, x, w })
            x = x + w
          }
          LayoutLine::{ ..l, w: x - start_x, glyphs }
        }

        let out : Array[LayoutLine] = []
        for l in layout {
          out.push(hint_line(l))
        }
        layout = out
      }
      let (layout_opt, _) = line.layout_opt.take_unused()
      let layout_opt = layout_opt.set_used(layout)
      BufferLine::{ ..line, layout_opt, }
    } else {
      line
    }
  } else {
    // Match existing API: if layout is cached, no work.
    // `hinting` is currently unused (MVP), but kept for API parity.
    ignore(hinting)
    self
  }
}

///|
pub fn BufferLine::set_text(
  self : BufferLine,
  text : String,
  ending : LineEnding,
  attrs_list : AttrsList,
) -> (BufferLine, Bool) {
  if text != self.text ||
    ending.as_str() != self.ending.as_str() ||
    !attrs_list.eq(self.attrs_list) {
    let updated = BufferLine::{ ..self, text, ending, attrs_list }.reset()
    (updated, true)
  } else {
    (self, false)
  }
}

///|
pub fn BufferLine::set_align(
  self : BufferLine,
  align : Align?,
) -> (BufferLine, Bool) {
  // MVP: align impacts layout cache only.
  if align is None && self.align is None {
    (self, false)
  } else {
    (BufferLine::{ ..self, align, }.reset_layout(), true)
  }
}

///|
/// Append `other` to `self` (consumes both, returns updated line).
pub fn BufferLine::append(self : BufferLine, other : BufferLine) -> BufferLine {
  let len = self.text.length()
  let other_text = other.text
  let other_len = other_text.length()
  let mut attrs_list = self.attrs_list
  if other.attrs_list.defaults().metadata != attrs_list.defaults().metadata {
    attrs_list = attrs_list.add_span(
      len,
      len + other_len,
      other.attrs_list.defaults(),
    )
  }
  for span in other.attrs_list.spans_iter() {
    attrs_list = attrs_list.add_span(
      span.start + len,
      span.end + len,
      span.attrs,
    )
  }
  BufferLine::{
    ..self,
    text: string_concat(self.text, other_text),
    ending: other.ending,
    attrs_list,
  }.reset()
}

///|
/// Split off new line at index. Returns (left, right).
pub fn BufferLine::split_off(
  self : BufferLine,
  index : Int,
) -> (BufferLine, BufferLine) {
  let index = if index < 0 { 0 } else { index }
  let end = self.text.length()
  let idx = if index > end { end } else { index }
  let left_text = substring(self.text, 0, idx)
  let right_text = substring(self.text, idx, end)
  let (left_attrs, right_attrs) = self.attrs_list.split_off(idx)
  let left = BufferLine::{
    ..self,
    text: left_text,
    ending: None,
    attrs_list: left_attrs,
  }.reset()
  let mut right = BufferLine::new(
    right_text,
    self.ending,
    right_attrs,
    self.shaping,
  )
  right = BufferLine::{ ..right, align: self.align }
  (left, right)
}
