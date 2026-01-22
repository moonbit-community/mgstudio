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
/// Segmentation utilities.
///
/// Upstream cosmic-text uses `unicode_segmentation` (UAX#29). This MVP provides a
/// whitespace-based word segmentation that is sufficient for ASCII/Latin text.

fn is_ws(code : Int) -> Bool {
  code == 32 || code == 9 || code == 10 || code == 13
}

///|
/// Returns word ranges `[start,end)` (UTF-16 code unit indices), splitting on whitespace.
pub fn word_indices_whitespace(s : String) -> Array[(Int, Int)] {
  let ranges : Array[(Int, Int)] = []
  let len = s.length()
  let mut i = 0
  while i < len {
    while i < len && is_ws(s.code_unit_at(i).to_int()) {
      i = i + 1
    }
    if i >= len {
      break
    }
    let start = i
    while i < len && !is_ws(s.code_unit_at(i).to_int()) {
      i = i + 1
    }
    ranges.push((start, i))
  }
  ranges
}

