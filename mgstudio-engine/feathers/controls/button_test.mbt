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
test "feathers controls button: props mirror Bevy defaults" {
  let props = ButtonProps::default()
  debug_inspect(props.variant is ButtonVariant::Normal, content="true")
  debug_inspect(
    props.corners is @rounded_corners.RoundedCorners::All,
    content="true",
  )
}

///|
test "feathers controls selection templates keep state in components" {
  let checkbox0 = checkbox("enabled")
  let radio0 = radio("choice")
  let switch0 = toggle_switch()
  debug_inspect(checkbox0.label, content="\"enabled\"")
  debug_inspect(radio0.label, content="\"choice\"")
  ignore(switch0)
  debug_inspect("ok", content="\"ok\"")
}

///|
fn color_tuple_eq(
  color : @color.Color,
  red : Float,
  green : Float,
  blue : Float,
  alpha : Float,
) -> Bool {
  fn approx(lhs : Float, rhs : Float) -> Bool {
    let delta = if lhs >= rhs { lhs - rhs } else { rhs - lhs }
    delta <= 0.0001F
  }
  let (actual_red, actual_green, actual_blue, actual_alpha) = color.to_srgba_tuple()
  approx(actual_red, red) &&
  approx(actual_green, green) &&
  approx(actual_blue, blue) &&
  approx(actual_alpha, alpha)
}

///|
test "feathers controls color slider mirrors Bevy data model" {
  debug_inspect(ColorChannel::default() is ColorChannel::Red, content="true")
  let hue_range = ColorChannel::HslHue.range()
  debug_inspect(hue_range.start() == 0.0F, content="true")
  debug_inspect(hue_range.end() == 360.0F, content="true")
  let alpha_range = ColorChannel::Alpha.range()
  debug_inspect(alpha_range.start() == 0.0F, content="true")
  debug_inspect(alpha_range.end() == 1.0F, content="true")

  let base = @color.Color::srgba(0.25F, 0.5F, 0.75F, 0.8F)
  let (alpha0, alpha_mid, alpha1) = ColorChannel::Alpha.gradient_ends(base)
  debug_inspect(
    color_tuple_eq(alpha0, 0.25F, 0.5F, 0.75F, 0.0F),
    content="true",
  )
  debug_inspect(
    color_tuple_eq(alpha_mid, 0.25F, 0.5F, 0.75F, 0.5F),
    content="true",
  )
  debug_inspect(
    color_tuple_eq(alpha1, 0.25F, 0.5F, 0.75F, 1.0F),
    content="true",
  )

  let props = ColorSliderProps::default()
  debug_inspect(props.channel is ColorChannel::Alpha, content="true")
  let (slider0, value0, range0) = color_slider(props)
  debug_inspect(slider0.channel is ColorChannel::Alpha, content="true")
  debug_inspect(value0.value() == 0.0F, content="true")
  debug_inspect(range0.end() == 1.0F, content="true")
}

///|
test "feathers controls color plane and swatch mirror Bevy defaults" {
  debug_inspect(
    ColorPlane::default() is ColorPlane::HueLightness,
    content="true",
  )
  let (plane0, value0) = color_plane(ColorPlane::HueSaturation)
  debug_inspect(plane0 is ColorPlane::HueSaturation, content="true")
  debug_inspect(
    value0.value.x == 0.0F && value0.value.y == 0.0F && value0.value.z == 0.0F,
    content="true",
  )

  let (_, swatch_value, _) = color_swatch()
  debug_inspect(
    color_tuple_eq(swatch_value.color, 1.0F, 1.0F, 1.0F, 1.0F),
    content="true",
  )
}
