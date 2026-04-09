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
// Bevy source: `bevy/crates/bevy_sprite/src/text2d.rs`.
// Runtime text helpers used by sprite/gizmo text rendering.
fn stroke_text_measure(text : String, font_size : Float) -> @math.Vec2 {
  let scale = font_size / SIMPLEX_CAP_HEIGHT
  let glyph_height = SIMPLEX_HEIGHT * scale
  let line_height = SIMPLEX_LINE_HEIGHT * glyph_height
  let space_advance = float_from_int(simplex_space_advance()) * scale

  let layout_width = Ref::new(0.0F)
  let line_width = Ref::new(0.0F)
  let layout_height = Ref::new(line_height)
  for c in text {
    if c == '\n' {
      if line_width.val > layout_width.val {
        layout_width.val = line_width.val
      }
      line_width.val = 0.0F
      layout_height.val = layout_height.val + line_height
    } else {
      let glyph_advance = if simplex_glyph(c) is Some((advance, _, _)) {
        float_from_int(advance) * scale
      } else {
        space_advance
      }
      line_width.val = line_width.val + glyph_advance
    }
  }
  if line_width.val > layout_width.val {
    layout_width.val = line_width.val
  }
  @math.Vec2::new(layout_width.val, layout_height.val)
}

///|
fn stroke_text_emit_2d(
  config : GizmoConfig,
  isometry : Isometry2d,
  text : String,
  font_size : Float,
  anchor : @math.Vec2,
  color : Color,
) -> Unit {
  let scale = font_size / SIMPLEX_CAP_HEIGHT
  let glyph_height = SIMPLEX_HEIGHT * scale
  let line_height = SIMPLEX_LINE_HEIGHT * glyph_height
  let margin_top = line_height - glyph_height
  let space_advance = float_from_int(simplex_space_advance()) * scale
  let layout_size = stroke_text_measure(text, font_size)
  let layout_anchor = vec2_scale(
    vec2_sub(@math.Vec2::new(-0.5F, 0.5F), anchor),
    1.0F,
  )
  let anchor_offset = @math.Vec2::new(
    layout_size.x * layout_anchor.x,
    layout_size.y * layout_anchor.y,
  )

  let cursor_x = Ref::new(0.0F)
  let cursor_y = Ref::new(-margin_top)
  for c in text {
    if c == '\n' {
      cursor_x.val = 0.0F
      cursor_y.val = cursor_y.val - line_height
      continue
    }

    match simplex_glyph(c) {
      Some((advance, stroke_begin, stroke_end)) => {
        let glyph_x = cursor_x.val
        for stroke_index in stroke_begin..<stroke_end {
          let (point_begin, point_end) = simplex_strokes[stroke_index]
          if point_end - point_begin < 2 {
            continue
          }
          let positions : Array[@math.Vec2] = []
          for point_index in point_begin..<point_end {
            let (px, py) = simplex_positions[point_index]
            let point_local = @math.Vec2::new(
              anchor_offset.x + glyph_x + float_from_int(px) * scale,
              anchor_offset.y +
              cursor_y.val -
              (SIMPLEX_CAP_HEIGHT - float_from_int(py)) * scale,
            )
            positions.push(isometry.transform_point(point_local))
          }
          gizmos_linestrip_with_config(config, positions, color)
        }
        cursor_x.val = cursor_x.val + float_from_int(advance) * scale
      }
      None => cursor_x.val = cursor_x.val + space_advance
    }
  }
}

///|
fn stroke_text_emit_3d(
  config : GizmoConfig,
  isometry : @math.Isometry3d,
  text : String,
  font_size : Float,
  anchor : @math.Vec2,
  color : Color,
) -> Unit {
  let scale = font_size / SIMPLEX_CAP_HEIGHT
  let glyph_height = SIMPLEX_HEIGHT * scale
  let line_height = SIMPLEX_LINE_HEIGHT * glyph_height
  let margin_top = line_height - glyph_height
  let space_advance = float_from_int(simplex_space_advance()) * scale
  let layout_size = stroke_text_measure(text, font_size)
  let layout_anchor = vec2_scale(
    vec2_sub(@math.Vec2::new(-0.5F, 0.5F), anchor),
    1.0F,
  )
  let anchor_offset = @math.Vec2::new(
    layout_size.x * layout_anchor.x,
    layout_size.y * layout_anchor.y,
  )

  let cursor_x = Ref::new(0.0F)
  let cursor_y = Ref::new(-margin_top)
  for c in text {
    if c == '\n' {
      cursor_x.val = 0.0F
      cursor_y.val = cursor_y.val - line_height
      continue
    }

    match simplex_glyph(c) {
      Some((advance, stroke_begin, stroke_end)) => {
        let glyph_x = cursor_x.val
        for stroke_index in stroke_begin..<stroke_end {
          let (point_begin, point_end) = simplex_strokes[stroke_index]
          if point_end - point_begin < 2 {
            continue
          }
          let positions : Array[@math.Vec3] = []
          for point_index in point_begin..<point_end {
            let (px, py) = simplex_positions[point_index]
            let point_local = @math.Vec2::new(
              anchor_offset.x + glyph_x + float_from_int(px) * scale,
              anchor_offset.y +
              cursor_y.val -
              (SIMPLEX_CAP_HEIGHT - float_from_int(py)) * scale,
            )
            positions.push(
              isometry.transform_point3(
                @math.Vec3::new(point_local.x, point_local.y, 0.0F),
              ),
            )
          }
          gizmos_linestrip_3d_with_config(config, positions, color)
        }
        cursor_x.val = cursor_x.val + float_from_int(advance) * scale
      }
      None => cursor_x.val = cursor_x.val + space_advance
    }
  }
}
