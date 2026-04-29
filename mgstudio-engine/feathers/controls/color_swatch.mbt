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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/color_swatch.rs`.

///|
pub struct ColorSwatch {} derive(Default, Debug)

///|
pub(all) struct ColorSwatchValue {
  color : @color.Color
}

///|
pub struct ColorSwatchFg {} derive(Default, Debug)

///|
pub fn ColorSwatchValue::new(color : @color.Color) -> ColorSwatchValue {
  ColorSwatchValue::{ color, }
}

///|
pub fn ColorSwatchValue::default() -> ColorSwatchValue {
  ColorSwatchValue::new(@color.Color::white())
}

///|
pub fn color_swatch() -> (ColorSwatch, ColorSwatchValue, ColorSwatchFg) {
  (ColorSwatch::{  }, ColorSwatchValue::default(), ColorSwatchFg::{  })
}

///|
pub struct ColorSwatchPlugin {}

///|
pub fn ColorSwatchPlugin::default() -> ColorSwatchPlugin {
  ColorSwatchPlugin::{  }
}

///|
pub fn color_swatch_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ensure_controls_runtime(app)
}
