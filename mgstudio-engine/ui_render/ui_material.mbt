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
// Bevy source: `bevy/crates/bevy_ui_render/src/ui_material.rs`.
fn rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
fn button_color_for_state(
  colors : @ui.ButtonColors,
  state : @ui.Interaction?,
) -> @sprite.Color {
  match state {
    Some(s) =>
      match s {
        @ui.Interaction::Pressed => colors.pressed
        @ui.Interaction::Hovered => colors.hovered
        @ui.Interaction::None => colors.normal
      }
    None => colors.normal
  }
}
