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
/// Minimal `Buffer` port scaffold from `cosmic-text/src/buffer.rs`.
///
/// This MVP focuses on line splitting, cache invalidation and redraw semantics.

pub struct Buffer {
  lines : Array[BufferLine]
  metrics : Metrics
  width_opt : Float?
  height_opt : Float?
  redraw : Bool
  wrap : Wrap
  tab_width : Int
}

///|
pub fn Buffer::new(metrics : Metrics) -> Buffer {
  Buffer::{
    lines: [],
    metrics,
    width_opt: None,
    height_opt: None,
    redraw: true,
    wrap: Wrap::None,
    tab_width: 4,
  }
}

///|
pub fn Buffer::metrics(self : Buffer) -> Metrics { self.metrics }

///|
pub fn Buffer::lines(self : Buffer) -> Array[BufferLine] { self.lines }

///|
pub fn Buffer::redraw(self : Buffer) -> Bool { self.redraw }

///|
pub fn Buffer::set_size(self : Buffer, width_opt : Float?, height_opt : Float?) -> Buffer {
  // MVP: any size change triggers redraw.
  if self.width_opt is Some(w0) &&
    width_opt is Some(w1) &&
    w0 == w1 &&
    self.height_opt is Some(h0) &&
    height_opt is Some(h1) &&
    h0 == h1 {
    self
  } else if self.width_opt is None && width_opt is None && self.height_opt is None &&
    height_opt is None {
    self
  } else {
    Buffer::{ ..self, width_opt, height_opt, redraw: true }
  }
}

fn slice_string(s : String, start : Int, end : Int) -> String {
  let sb = StringBuilder::new(size_hint=(end - start) * 2)
  sb.write_view(s[:].view(start_offset=start, end_offset=end))
  sb.to_string()
}

///|
/// Set full text of buffer (MVP).
///
/// NOTE: `attrs_list` is copied per line (upstream spans are per line).
pub fn Buffer::set_text(
  self : Buffer,
  text : String,
  attrs_list : AttrsList,
  shaping : Shaping,
) -> Buffer {
  let mut iter = LineIter::new(text)
  let new_lines : Array[BufferLine] = []
  while true {
    let (next_iter, item_opt) = iter.next()
    iter = next_iter
    if item_opt is Some(item) {
      let start = item.0
      let end = item.1
      let ending = item.2
      let line_text = slice_string(text, start, end)
      // MVP: attrs_list is shared; once we implement per-line ranges this will be adjusted.
      new_lines.push(BufferLine::new(line_text, ending, attrs_list, shaping))
    } else {
      break
    }
  }
  Buffer::{ ..self, lines: new_lines, redraw: true }
}
