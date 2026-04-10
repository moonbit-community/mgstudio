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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/color_slider.rs`.

///|
pub(all) enum ColorChannel {
  Red
  Green
  Blue
  Alpha
  Hue
  Saturation
  Value
} derive(Eq, Debug)

///|
pub struct SliderBaseColor {
  color_hex : String
}

///|
pub fn SliderBaseColor::new(color_hex : String) -> SliderBaseColor {
  SliderBaseColor::{ color_hex, }
}

///|
pub struct ColorSliderProps {
  channel : ColorChannel
  value : Float
  base_color : SliderBaseColor
}

///|
pub fn ColorSliderProps::default() -> ColorSliderProps {
  ColorSliderProps::{
    channel: Red,
    value: 0.0,
    base_color: SliderBaseColor::new("#000000"),
  }
}

///|
pub struct ColorSlider {
  props : ColorSliderProps
}

///|
pub fn color_slider(props : ColorSliderProps) -> ColorSlider {
  ColorSlider::{ props, }
}

///|
pub struct ColorSliderPlugin {}

///|
pub fn ColorSliderPlugin::default() -> ColorSliderPlugin {
  ColorSliderPlugin::{  }
}

///|
pub fn color_slider_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app
}
