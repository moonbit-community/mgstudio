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
/// Rendering helpers for Editor (ported from `cosmic-text/src/edit/editor.rs`).
///
/// This is an MVP: selection/cursor rendering is based on current `layout_runs()`
/// and uses code-unit indices (not grapheme clusters).
fn int_from_float(v : Float) -> Int {
  v.to_double().to_int()
}

///|
fn uint_from_int(v : Int) -> UInt {
  if v <= 0 {
    0U
  } else {
    v.reinterpret_as_uint()
  }
}

///|
fn width_int(width_opt : Float?) -> Int {
  match width_opt {
    None => 0
    Some(w) => int_from_float(w)
  }
}

///|
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

///|
fn cursor_position_in_run(cursor : Cursor, run : LayoutRun) -> (Int, Int)? {
  if cursor.line != run.line_i {
    return None
  }
  if run.glyphs.length() == 0 {
    return Some((0, int_from_float(run.line_top)))
  }
  // Prefer the run whose glyph span contains the index.
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
  if cursor.index < min_start || cursor.index > max_end {
    return None
  }
  let x = x_for_index(run, cursor.index)
  Some((int_from_float(x), int_from_float(run.line_top)))
}

///|
/// Get X and Y position of the top-left corner of the cursor (MVP).
pub fn Editor::cursor_position(self : Editor) -> (Int, Int)? {
  let buffer = self.buffer.layout_all()
  let mut fallback : (Int, Int)? = None
  for run in buffer.layout_runs() {
    if run.line_i == self.cursor.line {
      // Keep last run on this line as a fallback (for wrapped lines).
      fallback = Some(
        (int_from_float(run.line_w), int_from_float(run.line_top)),
      )
    }
    match cursor_position_in_run(self.cursor, run) {
      None => ()
      Some(pos) => return Some(pos)
    }
  }
  fallback
}

///|
/// Render editor contents with selection and cursor highlights.
pub fn[R : Renderer] Editor::render(
  self : Editor,
  renderer : R,
  text_color : Color,
  cursor_color : Color,
  selection_color : Color,
  selected_text_color : Color,
) -> Unit {
  let selection_bounds = self.selection_bounds()
  let buffer = self.buffer.layout_all()
  let width_opt = buffer.size().0
  for run in buffer.layout_runs() {
    // Highlight selection.
    match selection_bounds {
      None => ()
      Some((start, end)) =>
        if run.line_i >= start.line && run.line_i <= end.line {
          let mut range_opt : (Int, Int)? = None
          for glyph in run.glyphs {
            // Split the glyph's cluster into grapheme-sized subcells (upstream behavior).
            let cluster = slice_string(run.text, glyph.start, glyph.end)
            let graphemes = grapheme_indices_uax29(cluster)
            let total = graphemes.length()
            if total == 0 {
              continue
            }
            let c_w = glyph.w / Float::from_double(total.to_double())
            let mut c_x = glyph.x
            for r in graphemes {
              let c_start = glyph.start + r.0
              let c_end = glyph.start + r.1
              if (start.line != run.line_i || c_end > start.index) &&
                (end.line != run.line_i || c_start < end.index) {
                let x0 = int_from_float(c_x)
                let x1 = int_from_float(c_x + c_w)
                match range_opt {
                  None => range_opt = Some((x0, x1))
                  Some((min0, max0)) => {
                    let min1 = if x0 < min0 { x0 } else { min0 }
                    let max1 = if x1 > max0 { x1 } else { max0 }
                    range_opt = Some((min1, max1))
                  }
                }
              } else {
                match range_opt {
                  None => ()
                  Some((min0, max0)) => {
                    renderer.rectangle(
                      min0,
                      int_from_float(run.line_top),
                      uint_from_int(max0 - min0),
                      uint_from_int(int_from_float(run.line_height)),
                      selection_color,
                    )
                    range_opt = None
                  }
                }
              }
              c_x = c_x + c_w
            }
          }
          if run.glyphs.length() == 0 && end.line > run.line_i {
            // Highlight internal empty lines.
            range_opt = Some((0, width_int(width_opt)))
          }
          match range_opt {
            None => ()
            Some((min0, max0)) => {
              let mut min = min0
              let mut max = max0
              if end.line > run.line_i {
                // Draw to end of line.
                let w = width_int(width_opt)
                if run.rtl {
                  min = 0
                } else {
                  max = w
                }
              }
              renderer.rectangle(
                min,
                int_from_float(run.line_top),
                uint_from_int(max - min),
                uint_from_int(int_from_float(run.line_height)),
                selection_color,
              )
            }
          }
        }
    }

    // Draw cursor.
    match cursor_position_in_run(self.cursor, run) {
      None => ()
      Some((x, y)) =>
        renderer.rectangle(
          x,
          y,
          1U,
          uint_from_int(int_from_float(run.line_height)),
          cursor_color,
        )
    }

    // Draw glyphs.
    for g in run.glyphs {
      let physical = g.physical((0.0F, run.line_y), 1.0F)
      let mut glyph_color = match g.color_opt {
        None => text_color
        Some(c) => c
      }
      if text_color != selected_text_color {
        match selection_bounds {
          None => ()
          Some((start, end)) =>
            if run.line_i >= start.line &&
              run.line_i <= end.line &&
              (start.line != run.line_i || g.end > start.index) &&
              (end.line != run.line_i || g.start < end.index) {
              glyph_color = selected_text_color
            }
        }
      }
      renderer.glyph(physical, glyph_color)
    }
  }
}
