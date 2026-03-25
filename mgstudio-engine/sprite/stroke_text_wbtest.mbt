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
  inspect(size.x > 0.0F, content="true")
  inspect(size.y > SIMPLEX_CAP_HEIGHT, content="true")
}

///|
test "sprite gizmo text emits line segments for supported glyphs" {
  gizmos_clear()
  stroke_text_emit_2d(
    GizmoConfig::default(),
    Isometry2d::identity(),
    "AB",
    21.0F,
    @math.Vec2::new(0.0F, 0.0F),
    Color::white(),
  )
  inspect(gizmo_state.val.lines.length() > 0, content="true")
  gizmos_clear()
}

///|
test "sprite gizmo text skips unsupported glyph geometry" {
  gizmos_clear()
  stroke_text_emit_2d(
    GizmoConfig::default(),
    Isometry2d::identity(),
    "🙂",
    21.0F,
    @math.Vec2::new(0.0F, 0.0F),
    Color::white(),
  )
  inspect(gizmo_state.val.lines.length(), content="0")
  gizmos_clear()
}
