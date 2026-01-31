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
  scroll : Scroll
  redraw : Bool
  wrap : Wrap
  monospace_width : Float?
  tab_width : Int
  hinting : Hinting
}

///|
pub fn Buffer::new(metrics : Metrics) -> Buffer {
  Buffer::new_empty(metrics)
}

///|
/// Create an empty Buffer with the provided Metrics.
///
/// Panics (fails) if `metrics.line_height` is zero (aligned with upstream).
pub fn Buffer::new_empty(metrics : Metrics) -> Buffer {
  if metrics.line_height == 0.0F {
    abort("line height cannot be 0")
  }
  Buffer::{
    lines: [],
    metrics,
    width_opt: None,
    height_opt: None,
    scroll: Scroll::default(),
    redraw: false,
    wrap: Wrap::WordOrGlyph,
    monospace_width: None,
    tab_width: 8,
    hinting: Hinting::Disabled,
  }
}

///|
pub fn Buffer::metrics(self : Buffer) -> Metrics {
  self.metrics
}

///|
pub fn Buffer::lines(self : Buffer) -> Array[BufferLine] {
  self.lines
}

///|
pub fn Buffer::redraw(self : Buffer) -> Bool {
  self.redraw
}

///|
pub fn Buffer::set_redraw(self : Buffer, redraw : Bool) -> Buffer {
  if self.redraw == redraw {
    self
  } else {
    Buffer::{ ..self, redraw, }
  }
}

///|
pub fn Buffer::scroll(self : Buffer) -> Scroll {
  self.scroll
}

///|
pub fn Buffer::set_scroll(self : Buffer, scroll : Scroll) -> Buffer {
  if self.scroll.line == scroll.line &&
    self.scroll.vertical == scroll.vertical &&
    self.scroll.horizontal == scroll.horizontal {
    self
  } else {
    Buffer::{ ..self, scroll, redraw: true }
  }
}

///|
pub fn Buffer::wrap(self : Buffer) -> Wrap {
  self.wrap
}

///|
pub fn Buffer::hinting(self : Buffer) -> Hinting {
  self.hinting
}

///|
fn wrap_eq(a : Wrap, b : Wrap) -> Bool {
  match (a, b) {
    (None, None) => true
    (Glyph, Glyph) => true
    (Word, Word) => true
    (WordOrGlyph, WordOrGlyph) => true
    _ => false
  }
}

///|
fn hinting_eq(a : Hinting, b : Hinting) -> Bool {
  match (a, b) {
    (Disabled, Disabled) => true
    (Enabled, Enabled) => true
    _ => false
  }
}

///|
pub fn Buffer::set_wrap(self : Buffer, wrap : Wrap) -> Buffer {
  if wrap_eq(self.wrap, wrap) {
    self
  } else {
    Buffer::{ ..self, wrap, redraw: true }
  }
}

///|
pub fn Buffer::set_tab_width(self : Buffer, tab_width : Int) -> Buffer {
  if self.tab_width == tab_width {
    self
  } else {
    Buffer::{ ..self, tab_width, redraw: true }
  }
}

///|
pub fn Buffer::set_hinting(self : Buffer, hinting : Hinting) -> Buffer {
  if hinting_eq(self.hinting, hinting) {
    self
  } else {
    Buffer::{ ..self, hinting, redraw: true }
  }
}

///|
pub fn Buffer::set_monospace_width(
  self : Buffer,
  monospace_width : Float?,
) -> Buffer {
  if self.monospace_width is Some(w0) && monospace_width is Some(w1) && w0 == w1 {
    self
  } else if self.monospace_width is None && monospace_width is None {
    self
  } else {
    Buffer::{ ..self, monospace_width, redraw: true }
  }
}

///|
pub fn Buffer::set_metrics(self : Buffer, metrics : Metrics) -> Buffer {
  if metrics.line_height == 0.0F {
    abort("line height cannot be 0")
  }
  if self.metrics.font_size == metrics.font_size &&
    self.metrics.line_height == metrics.line_height {
    self
  } else {
    Buffer::{ ..self, metrics, redraw: true }
  }
}

///|
pub fn Buffer::set_size(
  self : Buffer,
  width_opt : Float?,
  height_opt : Float?,
) -> Buffer {
  // MVP: any size change triggers redraw.
  if self.width_opt is Some(w0) &&
    width_opt is Some(w1) &&
    w0 == w1 &&
    self.height_opt is Some(h0) &&
    height_opt is Some(h1) &&
    h0 == h1 {
    self
  } else if self.width_opt is None &&
    width_opt is None &&
    self.height_opt is None &&
    height_opt is None {
    self
  } else {
    Buffer::{ ..self, width_opt, height_opt, redraw: true }
  }
}

///|
pub fn Buffer::size(self : Buffer) -> (Float?, Float?) {
  (self.width_opt, self.height_opt)
}

///|
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
  // Upstream behavior: ensure there is a trailing line with `LineEnding::None`.
  let need_trailing = if new_lines.length() == 0 {
    true
  } else {
    match new_lines[new_lines.length() - 1].ending() {
      None => false
      _ => true
    }
  }
  if need_trailing {
    new_lines.push(BufferLine::new("", LineEnding::None, attrs_list, shaping))
  }
  Buffer::{ ..self, lines: new_lines, redraw: true }
}

///|
/// Set rich text of buffer using styled spans (pairs of text and attrs).
///
/// This mirrors `cosmic-text`'s `Buffer::set_rich_text` behavior:
/// - Concatenates spans into one string.
/// - Splits into paragraphs using `BidiParagraphs`.
/// - Builds per-line `AttrsList` spans relative to each line.
/// - Uses `LineEnding::default()` for all lines.
pub fn Buffer::set_rich_text(
  self : Buffer,
  spans : Array[(String, Attrs)],
  default_attrs : Attrs,
  shaping : Shaping,
  alignment : Align?,
) -> Buffer {
  let string_sb = StringBuilder::new(size_hint=256)
  let span_data : Array[(Attrs, Int, Int)] = []
  let mut end = 0
  for sp in spans {
    let text = sp.0
    let attrs = sp.1
    let start = end
    end = end + text.length()
    string_sb.write_string(text)
    span_data.push((attrs, start, end))
  }
  let string = string_sb.to_string()

  // Empty text: keep one empty line.
  if string.length() == 0 {
    let line = BufferLine::new(
      "",
      LineEnding::default(),
      AttrsList::new(default_attrs),
      shaping,
    )
    let (line2, _) = line.set_align(alignment)
    return Buffer::{
      ..self,
      lines: [line2],
      scroll: Scroll::default(),
      redraw: true,
    }
  }
  let lines : Array[BufferLine] = []
  let mut paras = BidiParagraphs::new(string)
  while true {
    let start = paras.pos
    match paras.next() {
      None => break
      Some((next, para)) => {
        paras = next
        let end0 = start + para.length()
        let mut attrs_list = AttrsList::new(default_attrs)
        for si in 0..<span_data.length() {
          let s = span_data[si]
          let attrs = s.0
          let s_start = s.1
          let s_end = s.2
          let isect_start = if s_start > start { s_start } else { start }
          let isect_end = if s_end < end0 { s_end } else { end0 }
          if isect_start < isect_end && attrs != default_attrs {
            attrs_list = attrs_list.add_span(
              isect_start - start,
              isect_end - start,
              attrs,
            )
          }
        }
        let line = BufferLine::new(
          para,
          LineEnding::default(),
          attrs_list,
          shaping,
        )
        let (line2, _) = line.set_align(alignment)
        lines.push(line2)
      }
    }
  }
  Buffer::{ ..self, lines, scroll: Scroll::default(), redraw: true }
}

///|
/// Shape all lines using a provided FontSystem (best-effort).
///
/// This is a coarse-grained helper for clients that do not want to manage
/// per-line shaping manually yet.
pub fn Buffer::shape_all_with_font_system(
  self : Buffer,
  font_system : FontSystem,
) -> Buffer {
  let lines : Array[BufferLine] = []
  for line in self.lines {
    lines.push(line.shape_with_font_system(font_system, self.tab_width))
  }
  Buffer::{ ..self, lines, }
}

///|
/// Layout all lines using a provided FontSystem (best-effort).
pub fn Buffer::layout_all_with_font_system(
  self : Buffer,
  font_system : FontSystem,
) -> Buffer {
  let lines : Array[BufferLine] = []
  for line in self.lines {
    lines.push(
      line.layout_with_font_system(
        font_system,
        self.metrics.font_size,
        self.width_opt,
        self.wrap,
        self.monospace_width,
        self.tab_width,
        self.hinting,
      ),
    )
  }
  Buffer::{ ..self, lines, }
}

///|
/// Layout all lines using the built-in shaping (no font system).
pub fn Buffer::layout_all(self : Buffer) -> Buffer {
  let lines : Array[BufferLine] = []
  for line in self.lines {
    lines.push(
      line.layout(
        self.metrics.font_size,
        self.width_opt,
        self.wrap,
        self.monospace_width,
        self.tab_width,
        self.hinting,
      ),
    )
  }
  Buffer::{ ..self, lines, }
}

///|
/// A line of visible text for rendering (MVP subset).
pub struct LayoutRun {
  line_i : Int
  line_y : Float
  line_top : Float
  line_height : Float
  text : String
  rtl : Bool
  glyphs : Array[LayoutGlyph]
  line_w : Float
}

///|
pub fn Buffer::layout_runs(self : Buffer) -> Iter[LayoutRun] {
  let runs : Array[LayoutRun] = []
  let line_height = self.metrics.line_height
  let mut y = 0.0F
  let n = self.lines.length()
  for i in 0..<n {
    let line = self.lines[i]
    let shape_opt = line.shape_opt()
    let rtl = if shape_opt is Some(s) { s.rtl } else { false }
    match line.layout_opt() {
      None => {
        runs.push(LayoutRun::{
          line_i: i,
          line_y: y,
          line_top: y,
          line_height,
          text: line.text(),
          rtl,
          glyphs: [],
          line_w: 0.0F,
        })
        y = y + line_height
      }
      Some(layout_lines) =>
        if layout_lines.length() == 0 {
          runs.push(LayoutRun::{
            line_i: i,
            line_y: y,
            line_top: y,
            line_height,
            text: line.text(),
            rtl,
            glyphs: [],
            line_w: 0.0F,
          })
          y = y + line_height
        } else {
          for l in layout_lines {
            runs.push(LayoutRun::{
              line_i: i,
              line_y: y,
              line_top: y,
              line_height,
              text: line.text(),
              rtl,
              glyphs: l.glyphs,
              line_w: l.w,
            })
            y = y + line_height
          }
        }
    }
  }
  runs.iter()
}

///|
/// Hit-testing: map a physical x/y position to a cursor (MVP).
pub fn Buffer::hit(self : Buffer, x : Float, y : Float) -> Cursor? {
  let buffer = self.layout_all()
  let mut last : Cursor? = None
  for run in buffer.layout_runs() {
    let line_cursor = if run.glyphs.length() == 0 {
      Cursor::new_with_affinity(run.line_i, 0, After)
    } else {
      Cursor::new_with_affinity(
        run.line_i,
        run.glyphs[run.glyphs.length() - 1].end,
        Before,
      )
    }
    last = Some(line_cursor)
    if y >= run.line_top && y < run.line_top + run.line_height {
      if run.glyphs.length() == 0 {
        return Some(Cursor::new_with_affinity(run.line_i, 0, After))
      }
      let glyphs = run.glyphs
      let mut min_start = glyphs[0].start
      let mut max_end = glyphs[0].end
      for g in glyphs {
        if g.start < min_start {
          min_start = g.start
        }
        if g.end > max_end {
          max_end = g.end
        }
      }
      // Clamp to glyph span.
      let last_g = glyphs[glyphs.length() - 1]
      if run.rtl {
        if x <= glyphs[0].x {
          return Some(Cursor::new_with_affinity(run.line_i, max_end, Before))
        }
        if x >= last_g.x + last_g.w {
          return Some(Cursor::new_with_affinity(run.line_i, min_start, After))
        }
      } else {
        if x <= glyphs[0].x {
          return Some(Cursor::new_with_affinity(run.line_i, min_start, After))
        }
        if x >= last_g.x + last_g.w {
          return Some(Cursor::new_with_affinity(run.line_i, max_end, Before))
        }
      }
      for g in glyphs {
        let mid = g.x + g.w / 2.0F
        if x < mid {
          if run.rtl {
            return Some(Cursor::new_with_affinity(run.line_i, g.end, Before))
          }
          return Some(Cursor::new_with_affinity(run.line_i, g.start, After))
        }
        if x < g.x + g.w {
          if run.rtl {
            return Some(Cursor::new_with_affinity(run.line_i, g.start, After))
          }
          return Some(Cursor::new_with_affinity(run.line_i, g.end, Before))
        }
      }
      return Some(line_cursor)
    }
  }
  last
}

///|
/// Cursor motion based on current layout runs (MVP).
///
/// This uses visual lines from `layout_runs()` for vertical movement.
pub fn Buffer::cursor_motion(
  self : Buffer,
  cursor : Cursor,
  cursor_x_opt : Int?,
  motion : Motion,
) -> (Cursor, Int?)? {
  // Layout to get visual line runs.
  let buffer = self.layout_all()
  let runs : Array[LayoutRun] = []
  for r in buffer.layout_runs() {
    runs.push(r)
  }
  if runs.length() == 0 {
    return None
  }
  fn x_for_index(run : LayoutRun, index : Int) -> Float {
    let glyphs = run.glyphs
    if glyphs.length() == 0 {
      return 0.0F
    }
    // Order-independent mapping (glyphs may be in visual order, not start-index order).
    let mut min_start = glyphs[0].start
    let mut min_start_x0 = glyphs[0].x
    let mut min_start_x1 = glyphs[0].x + glyphs[0].w
    let mut max_end = glyphs[0].end
    let mut max_end_x0 = glyphs[0].x
    let mut max_end_x1 = glyphs[0].x + glyphs[0].w
    for g in glyphs {
      if g.start < min_start {
        min_start = g.start
        min_start_x0 = g.x
        min_start_x1 = g.x + g.w
      }
      if g.end > max_end {
        max_end = g.end
        max_end_x0 = g.x
        max_end_x1 = g.x + g.w
      }
      if index == g.start {
        return if run.rtl { g.x + g.w } else { g.x }
      }
      if index == g.end {
        return if run.rtl { g.x } else { g.x + g.w }
      }
      if index > g.start && index < g.end {
        let span = g.end - g.start
        let off = index - g.start
        let t = Float::from_double(off.to_double() / span.to_double())
        return if run.rtl { g.x + g.w - g.w * t } else { g.x + g.w * t }
      }
    }
    if index <= min_start {
      if run.rtl {
        min_start_x1
      } else {
        min_start_x0
      }
    } else if index >= max_end {
      if run.rtl {
        max_end_x0
      } else {
        max_end_x1
      }
    } else {
      0.0F
    }
  }

  fn index_for_x(run : LayoutRun, x : Float) -> Int {
    if run.glyphs.length() == 0 {
      return 0
    }
    let glyphs = run.glyphs
    // Clamp to the visual extents.
    let mut min_x = glyphs[0].x
    let mut min_x_start = glyphs[0].start
    let mut max_x = glyphs[0].x + glyphs[0].w
    let mut max_x_end = glyphs[0].end
    for g in glyphs {
      if g.x < min_x {
        min_x = g.x
        min_x_start = g.start
      }
      if g.x + g.w > max_x {
        max_x = g.x + g.w
        max_x_end = g.end
      }
    }
    if x <= min_x {
      return if run.rtl { max_x_end } else { min_x_start }
    }
    if x >= max_x {
      return if run.rtl { min_x_start } else { max_x_end }
    }
    for g in glyphs {
      let mid = g.x + g.w / 2.0F
      if x < mid {
        return if run.rtl { g.end } else { g.start }
      }
      if x < g.x + g.w {
        return if run.rtl { g.start } else { g.end }
      }
    }
    if run.rtl {
      min_x_start
    } else {
      max_x_end
    }
  }

  fn int_from_float(v : Float) -> Int {
    v.to_double().to_int()
  }

  fn find_run_idx(cursor : Cursor) -> Int? {
    let mut cur_run_idx : Int? = None
    for i in 0..<runs.length() {
      let run = runs[i]
      if run.line_i != cursor.line {
        continue
      }
      if run.glyphs.length() == 0 {
        if cursor.index == 0 {
          cur_run_idx = Some(i)
          break
        }
      } else {
        let mut min_start = run.glyphs[0].start
        let mut max_end = run.glyphs[0].end
        for g in run.glyphs {
          if g.start < min_start {
            min_start = g.start
          }
          if g.end > max_end {
            max_end = g.end
          }
        }
        if cursor.index >= min_start {
          if cursor.index < max_end {
            cur_run_idx = Some(i)
            break
          }
          if cursor.index == max_end {
            // Prefer the next run if this is a wrap boundary.
            if i + 1 >= runs.length() || runs[i + 1].line_i != cursor.line {
              cur_run_idx = Some(i)
              break
            }
          }
        }
      }
    }
    // If we can't map index -> run (e.g. stale cursor), fall back to first run on the line.
    if cur_run_idx is None {
      for i in 0..<runs.length() {
        if runs[i].line_i == cursor.line {
          cur_run_idx = Some(i)
          break
        }
      }
    }
    cur_run_idx
  }

  match motion {
    LayoutCursor(layout_cursor) => {
      let line_run_idxs : Array[Int] = []
      for i in 0..<runs.length() {
        if runs[i].line_i == layout_cursor.line {
          line_run_idxs.push(i)
        }
      }
      if line_run_idxs.length() == 0 {
        return None
      }
      let mut layout = layout_cursor.layout
      if layout < 0 {
        layout = 0
      }
      if layout >= line_run_idxs.length() {
        layout = line_run_idxs.length() - 1
      }
      let run = runs[line_run_idxs[layout]]
      if run.glyphs.length() == 0 {
        return Some(
          (Cursor::new_with_affinity(run.line_i, 0, After), cursor_x_opt),
        )
      }
      let mut glyph_i = layout_cursor.glyph
      if glyph_i < 0 {
        glyph_i = 0
      }
      if glyph_i < run.glyphs.length() {
        let glyph = run.glyphs[glyph_i]
        return Some(
          (
            Cursor::new_with_affinity(run.line_i, glyph.start, After),
            cursor_x_opt,
          ),
        )
      }
      let mut max_end = run.glyphs[0].end
      for g in run.glyphs {
        if g.end > max_end {
          max_end = g.end
        }
      }
      return Some(
        (Cursor::new_with_affinity(run.line_i, max_end, Before), cursor_x_opt),
      )
    }
    _ => ()
  }

  // Vertical movement uses visual runs.
  let delta_opt : Int? = match motion {
    Up => Some(-1)
    Down => Some(1)
    Vertical(px) => {
      let lh = int_from_float(buffer.metrics.line_height)
      if lh == 0 {
        None
      } else {
        Some(px / lh)
      }
    }
    PageUp =>
      match buffer.height_opt {
        None => None
        Some(h) => {
          let lh = int_from_float(buffer.metrics.line_height)
          if lh == 0 {
            None
          } else {
            Some(-int_from_float(h) / lh)
          }
        }
      }
    PageDown =>
      match buffer.height_opt {
        None => None
        Some(h) => {
          let lh = int_from_float(buffer.metrics.line_height)
          if lh == 0 {
            None
          } else {
            Some(int_from_float(h) / lh)
          }
        }
      }
    _ => None
  }
  if delta_opt is Some(delta0) {
    if delta0 == 0 {
      return Some((cursor, cursor_x_opt))
    }
    let cur_run_idx_opt = find_run_idx(cursor)
    if cur_run_idx_opt is None {
      return None
    }
    let cur_idx = if cur_run_idx_opt is Some(v) { v } else { 0 }
    let cur_run = runs[cur_idx]
    let cur_x = x_for_index(cur_run, cursor.index)
    let desired_x = match cursor_x_opt {
      None => cur_x
      Some(xi) => Float::from_double(xi.to_double())
    }
    let target = cur_idx + delta0
    if target < 0 || target >= runs.length() {
      return None
    }
    let run = runs[target]
    let new_index = index_for_x(run, desired_x)
    return Some(
      (
        Cursor::new_with_affinity(run.line_i, new_index, cursor.affinity),
        Some(int_from_float(desired_x)),
      ),
    )
  }

  // Fallback: text-index motion (same as Editor's MVP cursor_motion).
  let mut c = cursor
  fn move_prev_grapheme(buffer : Buffer, c0 : Cursor) -> Cursor {
    let mut c = c0
    if c.index > 0 {
      let text = buffer.lines()[c.line].text()
      let ranges = grapheme_indices_uax29(text)
      let mut found = 0
      for r in ranges {
        if c.index > r.0 && c.index <= r.1 {
          found = r.0
        }
      }
      c = Cursor::new_with_affinity(c.line, found, Affinity::After)
    } else if c.line > 0 {
      let prev = c.line - 1
      let prev_len = buffer.lines()[prev].text().length()
      c = Cursor::new_with_affinity(prev, prev_len, Affinity::After)
    }
    c
  }

  fn move_next_grapheme(buffer : Buffer, c0 : Cursor) -> Cursor {
    let mut c = c0
    let len = buffer.lines()[c.line].text().length()
    if c.index < len {
      let text = buffer.lines()[c.line].text()
      let ranges = grapheme_indices_uax29(text)
      let mut found = len
      for r in ranges {
        if c.index >= r.0 && c.index < r.1 {
          found = r.1
          break
        }
      }
      c = Cursor::new_with_affinity(c.line, found, Affinity::Before)
    } else if c.line + 1 < buffer.lines().length() {
      c = Cursor::new_with_affinity(c.line + 1, 0, Affinity::Before)
    }
    c
  }

  fn move_prev_word(buffer : Buffer, c0 : Cursor) -> Cursor {
    let mut c = c0
    let text = buffer.lines()[c.line].text()
    if c.index > 0 {
      let ranges = word_indices_uax29(text)
      let mut found = 0
      let mut i = ranges.length() - 1
      while i >= 0 {
        let (ws, _we) = ranges[i]
        if ws < c.index {
          found = ws
          break
        }
        if i == 0 {
          break
        }
        i = i - 1
      }
      c = Cursor::new_with_affinity(c.line, found, c.affinity)
    } else if c.line > 0 {
      let prev = c.line - 1
      c = Cursor::new_with_affinity(
        prev,
        buffer.lines()[prev].text().length(),
        c.affinity,
      )
    }
    c
  }

  fn move_next_word(buffer : Buffer, c0 : Cursor) -> Cursor {
    let mut c = c0
    let text = buffer.lines()[c.line].text()
    if c.index < text.length() {
      let ranges = word_indices_uax29(text)
      let mut found = text.length()
      for pair in ranges {
        let we = pair.1
        if we > c.index {
          found = we
          break
        }
      }
      c = Cursor::new_with_affinity(c.line, found, c.affinity)
    } else if c.line + 1 < buffer.lines().length() {
      c = Cursor::new_with_affinity(c.line + 1, 0, c.affinity)
    }
    c
  }

  match motion {
    Previous => c = move_prev_grapheme(buffer, c)
    Next => c = move_next_grapheme(buffer, c)
    Left => {
      let rtl = match buffer.lines()[c.line].shape_opt() {
        None => false
        Some(s) => s.rtl
      }
      c = if rtl {
        move_next_grapheme(buffer, c)
      } else {
        move_prev_grapheme(buffer, c)
      }
    }
    Right => {
      let rtl = match buffer.lines()[c.line].shape_opt() {
        None => false
        Some(s) => s.rtl
      }
      c = if rtl {
        move_prev_grapheme(buffer, c)
      } else {
        move_next_grapheme(buffer, c)
      }
    }
    PreviousWord => c = move_prev_word(buffer, c)
    NextWord => c = move_next_word(buffer, c)
    LeftWord => {
      let rtl = match buffer.lines()[c.line].shape_opt() {
        None => false
        Some(s) => s.rtl
      }
      c = if rtl {
        move_next_word(buffer, c)
      } else {
        move_prev_word(buffer, c)
      }
    }
    RightWord => {
      let rtl = match buffer.lines()[c.line].shape_opt() {
        None => false
        Some(s) => s.rtl
      }
      c = if rtl {
        move_prev_word(buffer, c)
      } else {
        move_next_word(buffer, c)
      }
    }
    Home =>
      match find_run_idx(c) {
        None => c = Cursor::new_with_affinity(c.line, 0, After)
        Some(idx) => {
          let run = runs[idx]
          if run.glyphs.length() == 0 {
            c = Cursor::new_with_affinity(c.line, 0, After)
          } else {
            let mut min_start = run.glyphs[0].start
            for g in run.glyphs {
              if g.start < min_start {
                min_start = g.start
              }
            }
            c = Cursor::new_with_affinity(c.line, min_start, After)
          }
        }
      }
    End =>
      match find_run_idx(c) {
        None =>
          c = Cursor::new_with_affinity(
            c.line,
            buffer.lines()[c.line].text().length(),
            Before,
          )
        Some(idx) => {
          let run = runs[idx]
          if run.glyphs.length() == 0 {
            c = Cursor::new_with_affinity(c.line, 0, Before)
          } else {
            let mut max_end = run.glyphs[0].end
            for g in run.glyphs {
              if g.end > max_end {
                max_end = g.end
              }
            }
            c = Cursor::new_with_affinity(c.line, max_end, Before)
          }
        }
      }
    SoftHome => {
      let text = buffer.lines()[c.line].text()
      // Upstream `cosmic-text` behavior: always jump to the first non-whitespace
      // character on the line, or 0 if the line is all whitespace.
      let mut target = 0
      for p in text.iter2() {
        let idx = p.0
        let ch = p.1
        if !ch.is_whitespace() {
          target = idx
          break
        }
      }
      c = Cursor::new_with_affinity(c.line, target, c.affinity)
    }
    BufferStart => c = Cursor::new_with_affinity(0, 0, c.affinity)
    BufferEnd => {
      let last = buffer.lines().length() - 1
      c = Cursor::new_with_affinity(
        last,
        buffer.lines()[last].text().length(),
        c.affinity,
      )
    }
    ParagraphStart => c = Cursor::new_with_affinity(c.line, 0, c.affinity)
    ParagraphEnd =>
      c = Cursor::new_with_affinity(
        c.line,
        buffer.lines()[c.line].text().length(),
        c.affinity,
      )
    GotoLine(line_i) => {
      if line_i < 0 || line_i >= buffer.lines().length() {
        return None
      }
      match find_run_idx(c) {
        None => c = Cursor::new_with_affinity(line_i, 0, c.affinity)
        Some(run_idx) => {
          // Find current line-local visual layout and glyph indices.
          let mut layout = 0
          for i in 0..<run_idx {
            if runs[i].line_i == c.line {
              layout = layout + 1
            }
          }
          let run = runs[run_idx]
          let mut glyph = 0
          if run.glyphs.length() > 0 {
            let mut found = false
            for gi in 0..<run.glyphs.length() {
              if run.glyphs[gi].start == c.index {
                glyph = gi
                found = true
                break
              }
            }
            if !found {
              let mut max_end = run.glyphs[0].end
              for g in run.glyphs {
                if g.end > max_end {
                  max_end = g.end
                }
              }
              if c.index == max_end {
                glyph = run.glyphs.length()
              }
            }
          }
          let lc = LayoutCursor::new(line_i, layout, glyph)
          match
            buffer.cursor_motion(c, cursor_x_opt, Motion::LayoutCursor(lc)) {
            None => return None
            Some((nc, nx)) => return Some((nc, nx))
          }
        }
      }
    }
    _ => ()
  }
  Some((c, None))
}

///|
/// Draw the buffer using a `SwashCache`.
///
/// For compatibility with upstream's legacy renderer helper, the callback is
/// called per pixel (`w = 1`, `h = 1`).
pub fn Buffer::draw_with_font_system(
  self : Buffer,
  font_system : FontSystem,
  swash_cache : SwashCache,
  text_color : Color,
  f : (Int, Int, UInt, UInt, Color) -> Unit,
) -> (Buffer, SwashCache) {
  let buffer = self.layout_all_with_font_system(font_system)
  let mut y = 0.0F
  for line in buffer.lines {
    match line.layout_opt() {
      None => y = y + buffer.metrics.line_height
      Some(layout_lines) =>
        for layout_line in layout_lines {
          for glyph in layout_line.glyphs {
            let physical = glyph.physical((0.0F, y), 1.0F)
            swash_cache.with_pixels(
              font_system,
              physical.cache_key,
              text_color,
              fn(px, py, color) {
                f(physical.x + px, physical.y + py, 1U, 1U, color)
              },
            )
          }
          y = y + buffer.metrics.line_height
        }
    }
  }
  (buffer, swash_cache)
}

///|
/// Draw the buffer with a font system and swash cache.
///
/// This is a naming-aligned convenience wrapper (matches upstream's `Buffer::draw` intent).
pub fn Buffer::draw(
  self : Buffer,
  font_system : FontSystem,
  swash_cache : SwashCache,
  text_color : Color,
  f : (Int, Int, UInt, UInt, Color) -> Unit,
) -> (Buffer, SwashCache) {
  self.draw_with_font_system(font_system, swash_cache, text_color, f)
}
