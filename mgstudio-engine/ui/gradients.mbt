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
// Bevy source: `bevy/crates/bevy_ui/src/gradients.rs`.
// Current runtime-bearing visual styling surface.
pub struct BoxShadow {
  color : @sprite.Color
  x_offset : Val
  y_offset : Val
  spread_radius : Val
  blur_radius : Val
} derive(ToJson, FromJson)

///|
pub fn BoxShadow::new(
  color : @sprite.Color,
  x_offset : Val,
  y_offset : Val,
  spread_radius : Val,
  blur_radius : Val,
) -> BoxShadow {
  BoxShadow::{ color, x_offset, y_offset, spread_radius, blur_radius }
}

///|
pub fn BoxShadow::default() -> BoxShadow {
  BoxShadow::{
    color: @sprite.Color::black(),
    x_offset: Val::Percent(20.0F),
    y_offset: Val::Percent(20.0F),
    spread_radius: Val::Px(0.0F),
    blur_radius: Val::Percent(10.0F),
  }
}

///|
pub struct BackgroundColor {
  color : @sprite.Color
} derive(ToJson, FromJson)

///|
pub fn BackgroundColor::new(color : @sprite.Color) -> BackgroundColor {
  BackgroundColor::{ color, }
}
