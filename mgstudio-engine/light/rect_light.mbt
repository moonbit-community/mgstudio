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
// Bevy source: `bevy/crates/bevy_light/src/rect_light.rs`.

///|
pub struct RectLight {
  color : @sprite.Color
  intensity : Float
  range : Float
  width : Float
  height : Float
} derive(ToJson, FromJson)

///|
pub fn RectLight::RectLight() -> RectLight {
  RectLight::{
    color: @sprite.Color::white(),
    intensity: 1_000_000.0F,
    range: 20.0F,
    width: 1.0F,
    height: 1.0F,
  }
}

///|
pub fn RectLight::new(
  color : @sprite.Color,
  intensity : Float,
  range : Float,
  width : Float,
  height : Float,
) -> RectLight {
  RectLight::{
    color,
    intensity: light_sanitize_non_negative(intensity),
    range: light_sanitize_non_negative(range),
    width: light_sanitize_non_negative(width),
    height: light_sanitize_non_negative(height),
  }
}

///|
pub fn RectLight::color(self : RectLight) -> @sprite.Color {
  self.color
}

///|
pub fn RectLight::intensity(self : RectLight) -> Float {
  self.intensity
}

///|
pub fn RectLight::range(self : RectLight) -> Float {
  self.range
}

///|
pub fn RectLight::width(self : RectLight) -> Float {
  self.width
}

///|
pub fn RectLight::height(self : RectLight) -> Float {
  self.height
}

///|
pub let ecs_key_rect_light : @ecs.ComponentKey[RectLight] = @ecs.register_component(
  debug_name="mgstudio.light.RectLight",
)

///|
pub impl @ecs.Component for RectLight with component() {
  ecs_key_rect_light
}
