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
// Bevy source: `bevy/crates/bevy_ui/src/interaction_states.rs`.
pub struct RelativeCursorPosition {
  normalized_visible_node_rect : @math.Rect
  normalized : @math.Vec2?
} derive(ToJson, FromJson)

///|
pub fn RelativeCursorPosition::default() -> RelativeCursorPosition {
  RelativeCursorPosition::{
    normalized_visible_node_rect: @math.Rect::new(
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 1.0F),
    ),
    normalized: None,
  }
}

///|
pub fn RelativeCursorPosition::cursor_over(
  self : RelativeCursorPosition,
) -> Bool {
  match self.normalized {
    Some(normalized) => self.normalized_visible_node_rect.contains(normalized)
    None => false
  }
}

///|
pub(all) enum Interaction {
  None
  Hovered
  Pressed
} derive(Eq, Show, ToJson, FromJson)

///|
pub struct ButtonColors {
  normal : @sprite.Color
  hovered : @sprite.Color
  pressed : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn ButtonColors::new(
  normal : @sprite.Color,
  hovered : @sprite.Color,
  pressed : @sprite.Color,
) -> ButtonColors {
  ButtonColors::{ normal, hovered, pressed }
}
