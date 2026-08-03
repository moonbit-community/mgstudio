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
// Bevy source: `bevy/crates/bevy_sprite/src/text2d.rs`.
//
// The 2d text data model. The text pipeline proper stays in `text`, which is
// the `bevy_text` owner; `bevy_sprite` depends on `bevy_text`, never the
// reverse (ISS-480). The layout systems and render extraction move here in
// later phases.

///|
pub(all) struct Text2d {
  mut content : String
}

///|
pub fn Text2d::Text2d() -> Text2d {
  Text2d::new("")
}

///|
pub fn Text2d::new(content : String) -> Text2d {
  { content, }
}

///|
pub let ecs_key_text2d : @ecs.ComponentKey[Text2d] = @ecs.register_component(
  debug_name="text.text2d",
)

///|
pub impl @ecs.Component for Text2d with fn component() {
  ecs_key_text2d
}

///|
pub(all) struct Text2dShadow {
  mut offset : @math.Vec2
  mut color : @color.Color
}

///|
pub fn Text2dShadow::new(
  offset : @math.Vec2,
  color : @color.Color,
) -> Text2dShadow {
  { offset, color }
}

///|
pub fn Text2dShadow::Text2dShadow() -> Text2dShadow {
  Text2dShadow::new(@math.Vec2::new(4.0F, -4.0F), @color.Color::black())
}

///|
pub fn Text2dShadow::with_offset(
  self : Text2dShadow,
  offset : @math.Vec2,
) -> Text2dShadow {
  { ..self, offset, }
}

///|
pub fn Text2dShadow::with_color(
  self : Text2dShadow,
  color : @color.Color,
) -> Text2dShadow {
  { ..self, color, }
}

///|
pub let ecs_key_text2d_shadow : @ecs.ComponentKey[Text2dShadow] = @ecs.register_component(
  debug_name="text.text_2d_shadow",
)

///|
pub impl @ecs.Component for Text2dShadow with fn component() {
  ecs_key_text2d_shadow
}
