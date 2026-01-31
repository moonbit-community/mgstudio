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
/// Paragraph iterator for bidi-aware text processing.
///
/// Upstream `cosmic-text` uses `unicode-bidi` to find paragraph boundaries.
/// This MoonBit port approximates the behavior:
/// - Fast path for simple ASCII text: split on '\n' (does not special-case CRLF).
/// - Otherwise: split on `BidiClass::B` (Paragraph_Separator) using swash properties.
pub struct BidiParagraphs {
  text : String
  pos : Int
  ascii_fast : Bool
}

///|
pub fn BidiParagraphs::new(text : String) -> BidiParagraphs {
  let mut ascii_fast = true
  for ch in text {
    if ch.to_int() > 0x7F {
      ascii_fast = false
      break
    }
    if ch.is_control() && ch != '\n' && ch != '\r' && ch != '\t' {
      ascii_fast = false
      break
    }
  }
  BidiParagraphs::{ text, pos: 0, ascii_fast }
}

///|
/// Returns (next, paragraph_text) if any.
pub fn BidiParagraphs::next(self : BidiParagraphs) -> (BidiParagraphs, String)? {
  let len = self.text.length()
  if self.pos >= len {
    return None
  }
  let start = self.pos
  if self.ascii_fast {
    // Split on '\n' only, matching the upstream fast path.
    let mut i = start
    while i < len {
      if self.text.code_unit_at(i).to_int() == 10 {
        let para = slice_string(self.text, start, i)
        return Some((BidiParagraphs::{ ..self, pos: i + 1 }, para))
      }
      i = i + 1
    }
    let para = slice_string(self.text, start, len)
    return Some((BidiParagraphs::{ ..self, pos: len }, para))
  }

  // Complex text: split on Paragraph_Separator (BidiClass::B).
  let mut sep_start = len
  let mut sep_end = len
  for p in self.text.iter2() {
    let idx = p.0
    let ch = p.1
    if idx < start {
      continue
    }
    let bc = @moon_swash.CharInfo::from_char(ch).properties().bidi_class()
    match bc {
      B => {
        sep_start = idx
        sep_end = idx + ch.utf16_len()
        break
      }
      _ => ()
    }
  }
  if sep_start == len {
    let para = slice_string(self.text, start, len)
    return Some((BidiParagraphs::{ ..self, pos: len }, para))
  }
  let para = slice_string(self.text, start, sep_start)
  Some((BidiParagraphs::{ ..self, pos: sep_end }, para))
}

///|
pub fn BidiParagraphs::iter(self : BidiParagraphs) -> Iter[String] {
  let mut it = self
  Iter::new(fn() {
    match it.next() {
      None => None
      Some((next, para)) => {
        it = next
        Some(para)
      }
    }
  })
}
