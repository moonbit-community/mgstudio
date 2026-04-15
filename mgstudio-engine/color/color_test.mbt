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
test "color owns Color constructors" {
  let white = @color.Color::white()
  let black = @color.Color::black()
  debug_inspect(white.r.to_double(), content="1")
  debug_inspect(white.g.to_double(), content="1")
  debug_inspect(white.b.to_double(), content="1")
  debug_inspect(white.a.to_double(), content="1")
  debug_inspect(black.r.to_double(), content="0")
  debug_inspect(black.g.to_double(), content="0")
  debug_inspect(black.b.to_double(), content="0")
  debug_inspect(black.a.to_double(), content="1")
}

///|
test "color exposes alpha channel" {
  let color = @color.Color::new(0.2F, 0.4F, 0.6F, 0.25F)
  debug_inspect(color.alpha().to_double(), content="0.25")
}

///|
test "color space bridges round-trip primary colors" {
  let red = @color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F)
  debug_inspect(
    @color.color_approx_eq(
      @color.Hsla::from_color(red).to_color(),
      red,
      0.0001F,
    ),
    content="true",
  )
  debug_inspect(
    @color.color_approx_eq(
      @color.Hsva::from_color(red).to_color(),
      red,
      0.0001F,
    ),
    content="true",
  )
  debug_inspect(
    @color.color_approx_eq(
      @color.Hwba::from_color(red).to_color(),
      red,
      0.0001F,
    ),
    content="true",
  )
}

///|
test "color range and gradient interpolate linear colors" {
  let red = @color.Color::new(1.0F, 0.0F, 0.0F, 1.0F)
  let blue = @color.Color::new(0.0F, 0.0F, 1.0F, 1.0F)
  let midpoint = red.range_to(blue).at(0.5F)
  debug_inspect(midpoint.r.to_double(), content="0.5")
  debug_inspect(midpoint.g.to_double(), content="0")
  debug_inspect(midpoint.b.to_double(), content="0.5")
  debug_inspect(midpoint.a.to_double(), content="1")
  let gradient = @color.color_gradient([red, blue]) catch {
    _ => abort("expected color gradient")
  }
  let sample = gradient.at(0.5F)
  debug_inspect(sample.r.to_double(), content="0.5")
  debug_inspect(sample.b.to_double(), content="0.5")
}

///|
test "srgba tuple converts back to authored components" {
  let color = @color.Color::srgba(0.25F, 0.5F, 0.75F, 0.4F)
  let (r, g, b, a) = color.to_srgba_tuple()
  let round_trip = @color.Color::srgba(r, g, b, a)
  debug_inspect(
    @color.color_approx_eq(round_trip, color, 0.000001F),
    content="true",
  )
}

///|
fn approx_eq(lhs : Float, rhs : Float, tolerance : Float) -> Bool {
  let delta = if lhs >= rhs { lhs - rhs } else { rhs - lhs }
  delta <= tolerance
}

///|
test "xyza conversion matches bevy red constants" {
  let red = @color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F)
  let xyza = @color.xyza_from_color(red)
  debug_inspect(approx_eq(xyza.x, 0.4124564F, 0.0001F), content="true")
  debug_inspect(approx_eq(xyza.y, 0.2126729F, 0.0001F), content="true")
  debug_inspect(approx_eq(xyza.z, 0.0193339F, 0.0001F), content="true")
  debug_inspect(approx_eq(xyza.alpha, 1.0F, 0.000001F), content="true")
}

///|
test "lab and oklab round-trip from color" {
  let samples = [
    @color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F),
    @color.Color::srgba(0.0F, 1.0F, 0.0F, 1.0F),
    @color.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F),
    @color.Color::srgba(0.5F, 0.5F, 0.5F, 1.0F),
    @color.Color::srgba(0.18F, 0.39F, 0.92F, 0.8F),
  ]
  for sample in samples {
    let from_lab = @color.laba_to_color(@color.laba_from_color(sample))
    debug_inspect(
      @color.color_approx_eq(from_lab, sample, 0.003F),
      content="true",
    )
    let from_lch = @color.lcha_to_color(@color.lcha_from_color(sample))
    debug_inspect(
      @color.color_approx_eq(from_lch, sample, 0.003F),
      content="true",
    )
    let from_oklab = @color.oklaba_to_color(@color.oklaba_from_color(sample))
    debug_inspect(
      @color.color_approx_eq(from_oklab, sample, 0.0005F),
      content="true",
    )
    let from_oklch = @color.oklcha_to_color(@color.oklcha_from_color(sample))
    debug_inspect(
      @color.color_approx_eq(from_oklch, sample, 0.0005F),
      content="true",
    )
  }
}

///|
test "lcha and oklcha sequential dispersed generate deterministic hues" {
  let lcha0 = @color.Lcha::sequential_dispersed(0U)
  let lcha1 = @color.Lcha::sequential_dispersed(1U)
  debug_inspect(lcha0.hue >= 0.0F && lcha0.hue < 360.0F, content="true")
  debug_inspect(lcha1.hue >= 0.0F && lcha1.hue < 360.0F, content="true")
  debug_inspect(lcha0.hue != lcha1.hue, content="true")

  let oklcha0 = @color.Oklcha::sequential_dispersed(0U)
  let oklcha1 = @color.Oklcha::sequential_dispersed(1U)
  debug_inspect(oklcha0.hue >= 0.0F && oklcha0.hue < 360.0F, content="true")
  debug_inspect(oklcha1.hue >= 0.0F && oklcha1.hue < 360.0F, content="true")
  debug_inspect(oklcha0.hue != oklcha1.hue, content="true")
}
