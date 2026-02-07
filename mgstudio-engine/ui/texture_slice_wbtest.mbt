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
fn approx_eq(a : Float, b : Float, eps : Float) -> Bool {
  let d = a - b
  let ad = if d < 0.0F { 0.0F - d } else { d }
  ad <= eps
}

///|
fn vec4_approx_eq(
  v : @math.Vec4,
  e0 : Float,
  e1 : Float,
  e2 : Float,
  e3 : Float,
) -> Bool {
  let eps = 0.0001F
  approx_eq(v.x, e0, eps) &&
  approx_eq(v.y, e1, eps) &&
  approx_eq(v.z, e2, eps) &&
  approx_eq(v.w, e3, eps)
}

///|
test "ui: sliced image uses Bevy-like normalized borders" {
  let slicer = TextureSlicer::{
    border: BorderRect::new(10.0F, 30.0F, 20.0F, 40.0F),
    center_scale_mode: SliceScaleMode::Stretch,
    sides_scale_mode: SliceScaleMode::Stretch,
    max_corner_scale: 1.0F,
  }
  let (slices, border, repeat) = compute_texture_slices(
    @math.Vec2::new(100.0F, 200.0F),
    @math.Vec2::new(300.0F, 400.0F),
    NodeImageMode::Sliced(slicer),
  )
  inspect(vec4_approx_eq(slices, 0.1F, 0.1F, 0.7F, 0.8F), content="true")
  inspect(vec4_approx_eq(border, 0.0333333F, 0.05F, 0.9F, 0.9F), content="true")
  inspect(vec4_approx_eq(repeat, 1.0F, 1.0F, 1.0F, 1.0F), content="true")
}

///|
test "ui: sliced tile mode computes repeat factors per axis" {
  let slicer = TextureSlicer::{
    border: BorderRect::square(10.0F),
    center_scale_mode: SliceScaleMode::Stretch,
    sides_scale_mode: SliceScaleMode::Tile(0.5F),
    max_corner_scale: 1.0F,
  }
  let (slices, border, repeat) = compute_texture_slices(
    @math.Vec2::new(100.0F, 100.0F),
    @math.Vec2::new(220.0F, 120.0F),
    NodeImageMode::Sliced(slicer),
  )
  inspect(vec4_approx_eq(slices, 0.1F, 0.1F, 0.9F, 0.9F), content="true")
  inspect(
    vec4_approx_eq(border, 0.0454545F, 0.0833333F, 0.9545454F, 0.9166666F),
    content="true",
  )
  inspect(vec4_approx_eq(repeat, 5.0F, 2.5F, 1.0F, 1.0F), content="true")
}

///|
test "ui: tiled image mode maps repeat to center channels" {
  let (slices, border, repeat) = compute_texture_slices(
    @math.Vec2::new(64.0F, 32.0F),
    @math.Vec2::new(256.0F, 96.0F),
    NodeImageMode::Tiled(true, false, 2.0F),
  )
  inspect(vec4_approx_eq(slices, 0.0F, 0.0F, 1.0F, 1.0F), content="true")
  inspect(vec4_approx_eq(border, 0.0F, 0.0F, 1.0F, 1.0F), content="true")
  inspect(vec4_approx_eq(repeat, 1.0F, 1.0F, 2.0F, 1.0F), content="true")
}
