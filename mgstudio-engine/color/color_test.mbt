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
  inspect(white.r.to_double(), content="1")
  inspect(white.g.to_double(), content="1")
  inspect(white.b.to_double(), content="1")
  inspect(white.a.to_double(), content="1")
  inspect(black.r.to_double(), content="0")
  inspect(black.g.to_double(), content="0")
  inspect(black.b.to_double(), content="0")
  inspect(black.a.to_double(), content="1")
}

///|
test "color exposes alpha channel" {
  let color = @color.Color::new(0.2F, 0.4F, 0.6F, 0.25F)
  inspect(color.alpha().to_double(), content="0.25")
}

///|
test "color space bridges round-trip primary colors" {
  let red = @color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F)
  inspect(
    @color.color_approx_eq(
      @color.Hsla::from_color(red).to_color(),
      red,
      0.0001F,
    ),
    content="true",
  )
  inspect(
    @color.color_approx_eq(
      @color.Hsva::from_color(red).to_color(),
      red,
      0.0001F,
    ),
    content="true",
  )
  inspect(
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
  inspect(midpoint.r.to_double(), content="0.5")
  inspect(midpoint.g.to_double(), content="0")
  inspect(midpoint.b.to_double(), content="0.5")
  inspect(midpoint.a.to_double(), content="1")
  let gradient = @color.color_gradient([red, blue]) catch {
    _ => abort("expected color gradient")
  }
  let sample = gradient.at(0.5F)
  inspect(sample.r.to_double(), content="0.5")
  inspect(sample.b.to_double(), content="0.5")
}

///|
test "srgba tuple converts back to authored components" {
  let color = @color.Color::srgba(0.25F, 0.5F, 0.75F, 0.4F)
  let (r, g, b, a) = color.to_srgba_tuple()
  let round_trip = @color.Color::srgba(r, g, b, a)
  inspect(@color.color_approx_eq(round_trip, color, 0.000001F), content="true")
}
