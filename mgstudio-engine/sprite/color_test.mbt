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
fn color_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn color_approx_eq(a : Float, b : Float) -> Bool {
  color_abs(a - b) < 0.0001F
}

///|
test "render2d: color darker follows Bevy additive luminance semantics" {
  let color = Color::new(0.6F, 0.3F, 0.2F, 0.75F)
  let twice = color.darker(0.1F).darker(0.2F)
  let once = color.darker(0.3F)
  inspect(color_approx_eq(twice.r, once.r), content="true")
  inspect(color_approx_eq(twice.g, once.g), content="true")
  inspect(color_approx_eq(twice.b, once.b), content="true")
  inspect(color_approx_eq(twice.a, 0.75F), content="true")
}

///|
test "render2d: color darker clamps to black" {
  let color = Color::new(0.05F, 0.1F, 0.15F, 1.0F).darker(1.0F)
  inspect(color_approx_eq(color.r, 0.0F), content="true")
  inspect(color_approx_eq(color.g, 0.0F), content="true")
  inspect(color_approx_eq(color.b, 0.0F), content="true")
  inspect(color_approx_eq(color.a, 1.0F), content="true")
}
