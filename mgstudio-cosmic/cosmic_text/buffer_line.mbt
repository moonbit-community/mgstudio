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

pub(all) enum Shaping {
  Basic
  Advanced
}

///|
/// Placeholder for upstream `ShapeLine`.
pub struct ShapeLine {}

///|
pub fn ShapeLine::empty() -> ShapeLine { ShapeLine::{  } }

fn string_concat(a : String, b : String) -> String {
  let sb = StringBuilder::new(size_hint=(a.length() + b.length()) * 2)
  sb.write_string(a)
  sb.write_string(b)
  sb.to_string()
}

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
pub fn BufferLine::text(self : BufferLine) -> String { self.text }

///|
pub fn BufferLine::ending(self : BufferLine) -> LineEnding { self.ending }

///|
pub fn BufferLine::attrs_list(self : BufferLine) -> AttrsList { self.attrs_list }

///|
pub fn BufferLine::align(self : BufferLine) -> Align? { self.align }

///|
pub fn BufferLine::reset(self : BufferLine) -> BufferLine {
  BufferLine::{ ..self, metadata: None }.reset_shaping()
}

///|
pub fn BufferLine::reset_shaping(self : BufferLine) -> BufferLine {
  let shape_opt = self.shape_opt.set_unused()
  BufferLine::{ ..self, shape_opt }.reset_layout()
}

///|
pub fn BufferLine::reset_layout(self : BufferLine) -> BufferLine {
  let layout_opt = self.layout_opt.set_unused()
  BufferLine::{ ..self, layout_opt }
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
pub fn BufferLine::set_align(self : BufferLine, align : Align?) -> (BufferLine, Bool) {
  // MVP: align impacts layout cache only.
  if align is None && self.align is None {
    (self, false)
  } else {
    (BufferLine::{ ..self, align }.reset_layout(), true)
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
    attrs_list = attrs_list.add_span(len, len + other_len, other.attrs_list.defaults())
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
pub fn BufferLine::split_off(self : BufferLine, index : Int) -> (BufferLine, BufferLine) {
  let index = if index < 0 { 0 } else { index }
  let end = self.text.length()
  let idx = if index > end { end } else { index }
  let left_text = substring(self.text, 0, idx)
  let right_text = substring(self.text, idx, end)
  let (left_attrs, right_attrs) = self.attrs_list.split_off(idx)

  let left = BufferLine::{ ..self, text: left_text, ending: None, attrs_list: left_attrs }.reset()
  let mut right = BufferLine::new(right_text, self.ending, right_attrs, self.shaping)
  right = BufferLine::{ ..right, align: self.align }
  (left, right)
}
