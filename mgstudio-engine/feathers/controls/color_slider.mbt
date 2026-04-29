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
  HslHue
  HslSaturation
  HslLightness
  Alpha
} derive(Eq, Debug)

///|
pub fn ColorChannel::default() -> ColorChannel {
  Red
}

///|
pub fn ColorChannel::range(self : ColorChannel) -> @ui_widgets.SliderRange {
  match self {
    Red | Green | Blue | Alpha | HslSaturation | HslLightness =>
      @ui_widgets.SliderRange::new(0.0, 1.0)
    HslHue => @ui_widgets.SliderRange::new(0.0, 360.0)
  }
}

///|
pub fn ColorChannel::gradient_ends(
  self : ColorChannel,
  base_color : @color.Color,
) -> (@color.Color, @color.Color, @color.Color) {
  match self {
    Red => {
      let (_, green, blue, _) = base_color.to_srgba_tuple()
      (
        @color.Color::srgb(0.0, green, blue),
        @color.Color::srgb(0.5, green, blue),
        @color.Color::srgb(1.0, green, blue),
      )
    }
    Green => {
      let (red, _, blue, _) = base_color.to_srgba_tuple()
      (
        @color.Color::srgb(red, 0.0, blue),
        @color.Color::srgb(red, 0.5, blue),
        @color.Color::srgb(red, 1.0, blue),
      )
    }
    Blue => {
      let (red, green, _, _) = base_color.to_srgba_tuple()
      (
        @color.Color::srgb(red, green, 0.0),
        @color.Color::srgb(red, green, 0.5),
        @color.Color::srgb(red, green, 1.0),
      )
    }
    HslHue =>
      (
        @color.Color::hsl(0.0001, 1.0, 0.5),
        @color.Color::hsl(180.0, 1.0, 0.5),
        @color.Color::hsl(359.9999, 1.0, 0.5),
      )
    HslSaturation => {
      let base_hsla = base_color.to_hsla()
      (
        @color.Color::hsl(base_hsla.hue, 0.0, base_hsla.lightness),
        @color.Color::hsl(base_hsla.hue, 0.5, base_hsla.lightness),
        @color.Color::hsl(base_hsla.hue, 1.0, base_hsla.lightness),
      )
    }
    HslLightness => {
      let base_hsla = base_color.to_hsla()
      (
        @color.Color::hsl(base_hsla.hue, base_hsla.saturation, 0.0),
        @color.Color::hsl(base_hsla.hue, base_hsla.saturation, 0.5),
        @color.Color::hsl(base_hsla.hue, base_hsla.saturation, 1.0),
      )
    }
    Alpha =>
      (
        base_color.with_alpha(0.0),
        base_color.with_alpha(0.5),
        base_color.with_alpha(1.0),
      )
  }
}

///|
pub(all) struct SliderBaseColor {
  color : @color.Color
}

///|
pub fn SliderBaseColor::new(color : @color.Color) -> SliderBaseColor {
  SliderBaseColor::{ color, }
}

///|
pub fn SliderBaseColor::default() -> SliderBaseColor {
  SliderBaseColor::new(@color.Color::white())
}

///|
pub(all) struct ColorSliderProps {
  value : Float
  channel : ColorChannel
}

///|
pub fn ColorSliderProps::default() -> ColorSliderProps {
  ColorSliderProps::{ value: 0.0, channel: Alpha }
}

///|
pub(all) struct ColorSlider {
  channel : ColorChannel
}

///|
pub fn ColorSlider::default() -> ColorSlider {
  ColorSlider::{ channel: ColorChannel::default() }
}

///|
pub fn color_slider(
  props : ColorSliderProps,
) -> (ColorSlider, @ui_widgets.SliderValue, @ui_widgets.SliderRange) {
  (
    ColorSlider::{ channel: props.channel },
    @ui_widgets.SliderValue::new(props.value),
    props.channel.range(),
  )
}

///|
pub struct ColorSliderPlugin {}

///|
pub fn ColorSliderPlugin::default() -> ColorSliderPlugin {
  ColorSliderPlugin::{  }
}

///|
pub fn color_slider_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ensure_controls_runtime(app)
}
