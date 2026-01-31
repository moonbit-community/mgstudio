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
/// Ported from `cosmic-text/src/cursor.rs` (cosmic-text is dual-licensed MIT OR Apache-2.0).

///|
/// Whether to associate cursors placed at a boundary between runs with the run before or after it.
pub(all) enum Affinity {
  Before
  After
}

///|
pub impl Eq for Affinity with equal(self, other) {
  match (self, other) {
    (Before, Before) => true
    (After, After) => true
    _ => false
  }
}

///|
pub fn Affinity::before(self : Affinity) -> Bool {
  match self {
    Before => true
    After => false
  }
}

///|
pub fn Affinity::after(self : Affinity) -> Bool {
  match self {
    After => true
    Before => false
  }
}

///|
pub fn Affinity::from_before(before : Bool) -> Affinity {
  if before {
    Before
  } else {
    After
  }
}

///|
pub fn Affinity::from_after(after : Bool) -> Affinity {
  if after {
    After
  } else {
    Before
  }
}

///|
/// Current cursor location
pub struct Cursor {
  /// Index of BufferLine in Buffer::lines
  line : Int
  /// First-byte-index of glyph at cursor (upstream uses byte index; in MoonBit MVP we treat it as code-unit index)
  index : Int
  affinity : Affinity
}

///|
pub impl Eq for Cursor with equal(self, other) {
  self.line == other.line &&
  self.index == other.index &&
  self.affinity == other.affinity
}

///|
pub fn Cursor::new(line : Int, index : Int) -> Cursor {
  Cursor::new_with_affinity(line, index, Before)
}

///|
pub fn Cursor::new_with_affinity(
  line : Int,
  index : Int,
  affinity : Affinity,
) -> Cursor {
  Cursor::{ line, index, affinity }
}

///|
/// The position of a cursor within a Buffer.
pub struct LayoutCursor {
  line : Int
  layout : Int
  glyph : Int
}

///|
pub impl Eq for LayoutCursor with equal(self, other) {
  self.line == other.line &&
  self.layout == other.layout &&
  self.glyph == other.glyph
}

///|
pub fn LayoutCursor::new(line : Int, layout : Int, glyph : Int) -> LayoutCursor {
  LayoutCursor::{ line, layout, glyph }
}

///|
/// A motion to perform on a Cursor
pub(all) enum Motion {
  LayoutCursor(LayoutCursor)
  Previous
  Next
  Left
  Right
  Up
  Down
  Home
  SoftHome
  End
  ParagraphStart
  ParagraphEnd
  PageUp
  PageDown
  Vertical(Int)
  PreviousWord
  NextWord
  LeftWord
  RightWord
  BufferStart
  BufferEnd
  GotoLine(Int)
}

///|
pub impl Eq for Motion with equal(self, other) {
  match (self, other) {
    (LayoutCursor(a), LayoutCursor(b)) => a == b
    (Previous, Previous) => true
    (Next, Next) => true
    (Left, Left) => true
    (Right, Right) => true
    (Up, Up) => true
    (Down, Down) => true
    (Home, Home) => true
    (SoftHome, SoftHome) => true
    (End, End) => true
    (ParagraphStart, ParagraphStart) => true
    (ParagraphEnd, ParagraphEnd) => true
    (PageUp, PageUp) => true
    (PageDown, PageDown) => true
    (Vertical(a), Vertical(b)) => a == b
    (PreviousWord, PreviousWord) => true
    (NextWord, NextWord) => true
    (LeftWord, LeftWord) => true
    (RightWord, RightWord) => true
    (BufferStart, BufferStart) => true
    (BufferEnd, BufferEnd) => true
    (GotoLine(a), GotoLine(b)) => a == b
    _ => false
  }
}

///|
/// Scroll position in Buffer
pub struct Scroll {
  line : Int
  vertical : Float
  horizontal : Float
}

///|
pub fn Scroll::default() -> Scroll {
  Scroll::{ line: 0, vertical: 0.0F, horizontal: 0.0F }
}

///|
pub fn Scroll::new(line : Int, vertical : Float, horizontal : Float) -> Scroll {
  Scroll::{ line, vertical, horizontal }
}
