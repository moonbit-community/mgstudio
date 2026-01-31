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

///|
/// Word boundary ranges based on swash Unicode analysis (UAX#29-ish).
///
/// Returns segments separated by `Boundary::Word`/`Line`/`Mandatory`.
pub fn word_indices_uax29(s : String) -> Array[(Int, Int)] {
  let chars = s.to_array()
  let analyze = @moon_swash.analyze(chars.iter())
  analyze.set_break_strength(@moon_swash.WordBreakStrength::Normal)
  let ranges : Array[(Int, Int)] = []
  let mut start = 0
  let mut pos = 0
  for ch in chars {
    match analyze.next() {
      None => break
      Some((_props, boundary)) => {
        pos = pos + ch.utf16_len()
        match boundary {
          Word | Line | Mandatory => {
            if pos > start {
              ranges.push((start, pos))
            }
            start = pos
          }
          None => ()
        }
      }
    }
  }
  if pos > start {
    ranges.push((start, pos))
  }
  ranges
}

///|
/// Word segments used for wrapping (cosmic-text-style).
///
/// Upstream uses `unicode_linebreak::linebreaks` to split into segments, then
/// splits trailing whitespace into individual blank "words".
///
/// This helper approximates that behavior using swash boundary analysis:
/// - Use `moon_swash.analyze` to identify UAX#14 linebreak opportunities:
///   split on `Boundary::Line` or `Boundary::Mandatory` (ignore `Boundary::Word`).
/// - For each segment, split trailing whitespace characters into individual blank segments
///   (mirrors upstream's `char::is_whitespace()` scan).
///
/// Returns `(start, end, blank)` ranges in UTF-16 code units.
pub fn wrap_word_segments(s : String) -> Array[(Int, Int, Bool)] {
  let chars = s.to_array()
  if chars.length() == 0 {
    return []
  }

  // Precompute UTF-16 offsets for each char.
  let offs : Array[Int] = []
  let lens : Array[Int] = []
  let mut pos = 0
  for ch in chars {
    offs.push(pos)
    let len = ch.utf16_len()
    lens.push(len)
    pos = pos + len
  }
  fn emit_segment(
    out : Array[(Int, Int, Bool)],
    chars : Array[Char],
    offs : Array[Int],
    lens : Array[Int],
    start_char_i : Int,
    end_char_i : Int,
    start_word : Int,
    end_pos : Int,
  ) -> Unit {
    if end_pos <= start_word || end_char_i < start_char_i {
      return
    }
    // Find the start of trailing whitespace inside [start_word, end_pos).
    let mut start_lb = end_pos
    let mut ws_start_i : Int? = None
    let mut k = end_char_i
    while k >= start_char_i {
      if chars[k].is_whitespace() {
        start_lb = offs[k]
        ws_start_i = Some(k)
      } else {
        break
      }
      if k == 0 {
        break
      }
      k = k - 1
    }

    // Emit non-whitespace word segment.
    if start_word < start_lb {
      out.push((start_word, start_lb, false))
    }

    // Emit trailing whitespace as individual blank segments.
    match ws_start_i {
      None => ()
      Some(i0) =>
        for i in i0..<(end_char_i + 1) {
          out.push((offs[i], offs[i] + lens[i], true))
        }
    }
  }

  // Collect linebreak boundaries from the analyzer.
  let analyze = @moon_swash.analyze(chars.iter())
  analyze.set_break_strength(@moon_swash.WordBreakStrength::Normal)
  let out : Array[(Int, Int, Bool)] = []
  let mut start_char_i = 0
  let mut start_word = 0

  // `Analyze` reports `Boundary::Line|Mandatory` at the character that begins a new segment
  // (i.e. the break is *before* the current char). This matches UAX#14 `linebreaks()` behavior
  // when interpreted as end positions.
  for i in 0..<chars.length() {
    match analyze.next() {
      None => break
      Some((_props, boundary)) =>
        match boundary {
          Line | Mandatory => {
            let end_pos = offs[i]
            emit_segment(
              out,
              chars,
              offs,
              lens,
              start_char_i,
              i - 1,
              start_word,
              end_pos,
            )
            start_char_i = i
            start_word = end_pos
          }
          _ => ()
        }
    }
  }

  // Final segment (end-of-string).
  emit_segment(
    out,
    chars,
    offs,
    lens,
    start_char_i,
    chars.length() - 1,
    start_word,
    s.length(),
  )
  out
}

///|
/// Grapheme cluster ranges `[start,end)` in UTF-16 code units (UAX#29-ish).
///
/// This is sufficient for making Backspace/Delete operate on user-perceived characters.
pub fn grapheme_indices_uax29(s : String) -> Array[(Int, Int)] {
  let chars = s.to_array()
  if chars.length() == 0 {
    return []
  }
  let offs : Array[Int] = []
  let lens : Array[Int] = []
  let breaks : Array[@moon_swash.ClusterBreak] = []
  let pict : Array[Bool] = []
  let mut pos = 0
  for ch in chars {
    offs.push(pos)
    let len = ch.utf16_len()
    lens.push(len)
    let info = @moon_swash.CharInfo::from_char(ch)
    breaks.push(info.cluster_break())
    pict.push(info.properties().is_extended_pictographic())
    pos = pos + len
  }
  fn is_control(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      CN | CR | LF => true
      _ => false
    }
  }

  fn is_hangul_l(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      L => true
      _ => false
    }
  }

  fn is_hangul_v(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      V | LV => true
      _ => false
    }
  }

  fn is_hangul_t(b : @moon_swash.ClusterBreak) -> Bool {
    match b {
      T | LVT => true
      _ => false
    }
  }

  fn should_break(
    i : Int,
    breaks : Array[@moon_swash.ClusterBreak],
    pict : Array[Bool],
  ) -> Bool {
    let prev = breaks[i - 1]
    let cur = breaks[i]

    // GB3
    if prev is CR && cur is LF {
      return false
    }
    // GB4/GB5
    if is_control(prev) || is_control(cur) {
      return true
    }
    // GB6
    if is_hangul_l(prev) {
      match cur {
        L | V | LV | LVT => return false
        _ => ()
      }
    }
    // GB7
    if is_hangul_v(prev) {
      match cur {
        V | T => return false
        _ => ()
      }
    }
    // GB8
    if is_hangul_t(prev) {
      if cur is T {
        return false
      }
    }
    // GB9/9a/9b
    match cur {
      EX | ZWJ | SM => return false
      _ => ()
    }
    if prev is PP {
      return false
    }
    // GB11 (simplified): Extended_Pictographic Extend* ZWJ x Extended_Pictographic
    if cur is @moon_swash.ClusterBreak::XX && pict[i] && prev is ZWJ {
      let mut k = i - 2
      while k >= 0 && breaks[k] is EX {
        k = k - 1
      }
      if k >= 0 && pict[k] {
        return false
      }
    }
    // GB12/13: RI pairs
    if prev is RI && cur is RI {
      let mut count = 0
      let mut k = i - 1
      while k >= 0 && breaks[k] is RI {
        count = count + 1
        if k == 0 {
          break
        }
        k = k - 1
      }
      if count % 2 == 1 {
        return false
      }
    }
    true
  }

  let ranges : Array[(Int, Int)] = []
  let mut start = 0
  for i in 1..<chars.length() {
    if should_break(i, breaks, pict) {
      ranges.push((start, offs[i]))
      start = offs[i]
    }
  }
  ranges.push((start, offs[offs.length() - 1] + lens[lens.length() - 1]))
  ranges
}
