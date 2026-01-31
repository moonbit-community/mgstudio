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
/// Ported from `cosmic-text/src/line_ending.rs` (cosmic-text is dual-licensed MIT OR Apache-2.0).
pub(all) enum LineEnding {
  Lf
  CrLf
  Cr
  LfCr
  None
}

///|
pub fn LineEnding::as_str(self : LineEnding) -> String {
  match self {
    Lf => "\n"
    CrLf => "\r\n"
    Cr => "\r"
    LfCr => "\n\r"
    None => ""
  }
}

///|
/// Default line ending (matches upstream: LF).
pub fn LineEnding::default() -> LineEnding {
  Lf
}

///|
pub struct LineIter {
  string : String
  start : Int
  end : Int
}

///|
pub fn LineIter::new(string : String) -> LineIter {
  LineIter::{ string, start: 0, end: string.length() }
}

///|
fn is_cr(code : Int) -> Bool {
  code == 13
}

///|
fn is_lf(code : Int) -> Bool {
  code == 10
}

///|
/// Returns (start, end, ending) where [start,end) is the line content range.
pub fn LineIter::next(self : LineIter) -> (LineIter, (Int, Int, LineEnding)?) {
  let start = self.start
  let len = self.end
  let mut i = start
  while i < len {
    let code = self.string.code_unit_at(i).to_int()
    if is_cr(code) || is_lf(code) {
      let end = i
      let after0 = code
      let after1 = if i + 1 < len {
        self.string.code_unit_at(i + 1).to_int()
      } else {
        -1
      }
      let ending = if is_cr(after0) && is_lf(after1) {
        CrLf
      } else if is_lf(after0) && is_cr(after1) {
        LfCr
      } else if is_lf(after0) {
        Lf
      } else if is_cr(after0) {
        Cr
      } else {
        None
      }
      let next_start = i + ending.as_str().length()
      let iter = LineIter::{ ..self, start: next_start }
      return (iter, Some((start, end, ending)))
    }
    i = i + 1
  }
  if start < len {
    let iter = LineIter::{ ..self, start: len }
    (iter, Some((start, len, None)))
  } else {
    (self, None)
  }
}
