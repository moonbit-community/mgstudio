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
/// MVP subset ported from `cosmic-text/src/attrs.rs`.
///
/// NOTE: upstream `Attrs` contains font family/style/weight/features etc.
/// We start with `metadata` only to support BufferLine behavior tests, and will
/// extend it incrementally to match upstream.

///|
/// Text color (ARGB packed, aligned with upstream).
pub struct Color {
  value : UInt
}

///|
pub fn Color::rgba(r : Byte, g : Byte, b : Byte, a : Byte) -> Color {
  let av = a.to_int().reinterpret_as_uint()
  let rv = r.to_int().reinterpret_as_uint()
  let gv = g.to_int().reinterpret_as_uint()
  let bv = b.to_int().reinterpret_as_uint()
  Color::{ value: (av << 24) | (rv << 16) | (gv << 8) | bv }
}

///|
pub fn Color::rgb(r : Byte, g : Byte, b : Byte) -> Color {
  Color::rgba(r, g, b, 0xFF)
}

///|
pub fn Color::r(self : Color) -> Byte {
  ((self.value & 0x00FF0000) >> 16).reinterpret_as_int().to_byte()
}

///|
pub fn Color::g(self : Color) -> Byte {
  ((self.value & 0x0000FF00) >> 8).reinterpret_as_int().to_byte()
}

///|
pub fn Color::b(self : Color) -> Byte {
  (self.value & 0x000000FF).reinterpret_as_int().to_byte()
}

///|
pub fn Color::a(self : Color) -> Byte {
  ((self.value & 0xFF000000) >> 24).reinterpret_as_int().to_byte()
}

///|
pub fn Color::as_rgba(self : Color) -> (Byte, Byte, Byte, Byte) {
  (self.r(), self.g(), self.b(), self.a())
}

pub struct Attrs {
  metadata : Int
}

///|
pub fn Attrs::new() -> Attrs {
  Attrs::with_metadata(0)
}

///|
pub fn Attrs::with_metadata(metadata : Int) -> Attrs {
  Attrs::{ metadata }
}

///|
pub fn Attrs::metadata(self : Attrs) -> Int { self.metadata }

///|
pub struct AttrsSpan {
  start : Int
  end : Int
  attrs : Attrs
}

///|
pub struct AttrsList {
  defaults : Attrs
  spans : Array[AttrsSpan]
}

///|
pub fn AttrsList::new(defaults : Attrs) -> AttrsList {
  AttrsList::{ defaults, spans: [] }
}

///|
pub fn AttrsList::defaults(self : AttrsList) -> Attrs {
  self.defaults
}

///|
pub fn AttrsList::spans_iter(self : AttrsList) -> Array[AttrsSpan] {
  self.spans
}

///|
pub fn AttrsList::add_span(
  self : AttrsList,
  start : Int,
  end : Int,
  attrs : Attrs,
) -> AttrsList {
  if end <= start {
    return self
  }
  // MVP: keep a sorted array by `start` (stable), no merging yet.
  let spans : Array[AttrsSpan] = []
  let mut inserted = false
  for span in self.spans {
    if !inserted && start < span.start {
      spans.push(AttrsSpan::{ start, end, attrs })
      inserted = true
    }
    spans.push(span)
  }
  if !inserted {
    spans.push(AttrsSpan::{ start, end, attrs })
  }
  AttrsList::{ ..self, spans }
}

///|
pub fn AttrsList::get_span(self : AttrsList, pos : Int) -> Attrs {
  let mut found : Attrs? = None
  for span in self.spans {
    if pos >= span.start && pos < span.end {
      found = Some(span.attrs)
    }
  }
  if found is Some(attrs) { attrs } else { self.defaults }
}

fn clamp_nonneg(v : Int) -> Int { if v < 0 { 0 } else { v } }

///|
/// Splits spans at `index` and returns (left, right).
pub fn AttrsList::split_off(self : AttrsList, index : Int) -> (AttrsList, AttrsList) {
  let index = clamp_nonneg(index)
  let left : Array[AttrsSpan] = []
  let right : Array[AttrsSpan] = []

  for span in self.spans {
    if span.end <= index {
      left.push(span)
    } else if span.start >= index {
      right.push(AttrsSpan::{
        start: span.start - index,
        end: span.end - index,
        attrs: span.attrs,
      })
    } else {
      // Span crosses the split point.
      left.push(AttrsSpan::{
        start: span.start,
        end: index,
        attrs: span.attrs,
      })
      right.push(AttrsSpan::{
        start: 0,
        end: span.end - index,
        attrs: span.attrs,
      })
    }
  }

  (
    AttrsList::{ defaults: self.defaults, spans: left },
    AttrsList::{ defaults: self.defaults, spans: right },
  )
}

///|
pub fn AttrsList::eq(self : AttrsList, other : AttrsList) -> Bool {
  if self.defaults.metadata() != other.defaults.metadata() {
    return false
  }
  if self.spans.length() != other.spans.length() {
    return false
  }
  let n = self.spans.length()
  for i in 0..<n {
    let a = self.spans[i]
    let b = other.spans[i]
    if a.start != b.start || a.end != b.end || a.attrs.metadata() != b.attrs.metadata() {
      return false
    }
  }
  true
}
