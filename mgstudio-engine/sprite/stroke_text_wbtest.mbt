// Copyright 2026 International Digital Economy Academy
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
test "sprite gizmo text measures multiline stroke layout" {
  let size = stroke_text_measure("A\nA", 21.0F)
  debug_inspect(size.x > 0.0F, content="true")
  debug_inspect(size.y > SIMPLEX_CAP_HEIGHT, content="true")
}

///|
test "sprite gizmo text emits line segments for supported glyphs" {
  gizmos_reset()
  stroke_text_emit_2d(
    GizmoConfig::default(),
    Isometry2d::identity(),
    "AB",
    21.0F,
    @math.Vec2::new(0.0F, 0.0F),
    Color::white(),
  )
  debug_inspect(gizmo_state.val.lines.length() > 0, content="true")
  gizmos_reset()
}

///|
test "sprite gizmo text emits 3d line segments for supported glyphs" {
  gizmos_reset()
  stroke_text_emit_3d(
    GizmoConfig::default(),
    @math.Isometry3d::identity(),
    "AB",
    21.0F,
    @math.Vec2::new(0.0F, 0.0F),
    Color::white(),
  )
  debug_inspect(gizmo_state.val.lines_3d.length() > 0, content="true")
  gizmos_reset()
}

///|
test "sprite gizmo text skips unsupported glyph geometry" {
  gizmos_reset()
  stroke_text_emit_2d(
    GizmoConfig::default(),
    Isometry2d::identity(),
    "🙂",
    21.0F,
    @math.Vec2::new(0.0F, 0.0F),
    Color::white(),
  )
  debug_inspect(gizmo_state.val.lines.length(), content="0")
  gizmos_reset()
}

///|
test "sprite gizmo reset clears 2d and 3d text state" {
  gizmos_reset()
  stroke_text_emit_2d(
    GizmoConfig::default(),
    Isometry2d::identity(),
    "A",
    21.0F,
    @math.Vec2::new(0.0F, 0.0F),
    Color::white(),
  )
  stroke_text_emit_3d(
    GizmoConfig::default(),
    @math.Isometry3d::identity(),
    "A",
    21.0F,
    @math.Vec2::new(0.0F, 0.0F),
    Color::white(),
  )
  gizmos_reset()
  debug_inspect(gizmo_state.val.lines.length(), content="0")
  debug_inspect(gizmo_state.val.lines_3d.length(), content="0")
}
