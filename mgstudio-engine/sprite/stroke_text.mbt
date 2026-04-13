// Copyright 2024 The Bevy Contributors
// Copyright 2026 International Digital Economy Academy
//
// SPDX-License-Identifier: Apache-2.0 OR MIT
//
// This file contains stroke text layout and rendering logic used by gizmo text.

///|
// Runtime implementation now lives in `text2d.mbt` in this package.
pub fn sprite_stroke_text_measure(
  text : String,
  font_size : Float,
) -> @math.Vec2 {
  stroke_text_measure(text, font_size)
}

///|
pub fn sprite_stroke_text_emit_2d(
  config : GizmoConfig,
  isometry : Isometry2d,
  text : String,
  font_size : Float,
  anchor : @math.Vec2,
  color : Color,
) -> Unit {
  stroke_text_emit_2d(config, isometry, text, font_size, anchor, color)
}

///|
pub fn sprite_stroke_text_emit_3d(
  config : GizmoConfig,
  isometry : @math.Isometry3d,
  text : String,
  font_size : Float,
  anchor : @math.Vec2,
  color : Color,
) -> Unit {
  stroke_text_emit_3d(config, isometry, text, font_size, anchor, color)
}
