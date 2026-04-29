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
// Bevy source: `bevy/crates/bevy_ui_render/src/gradient.rs`.
fn clamp_nonneg(v : Float) -> Float {
  if v < 0.0F {
    0.0F
  } else {
    v
  }
}

///|
fn resolve_axis(
  val : @ui.Val,
  node_axis : Float,
  viewport_size : @math.Vec2,
) -> Float {
  match val {
    @ui.Val::Auto => 0.0F
    @ui.Val::Px(px) => px
    @ui.Val::Percent(p) => node_axis * (p / 100.0F)
    @ui.Val::Vw(p) => viewport_size.x * (p / 100.0F)
    @ui.Val::Vh(p) => viewport_size.y * (p / 100.0F)
    @ui.Val::VMin(p) => {
      let m = if viewport_size.x < viewport_size.y {
        viewport_size.x
      } else {
        viewport_size.y
      }
      m * (p / 100.0F)
    }
    @ui.Val::VMax(p) => {
      let m = if viewport_size.x > viewport_size.y {
        viewport_size.x
      } else {
        viewport_size.y
      }
      m * (p / 100.0F)
    }
  }
}

///|
fn clamp_radius_nonneg(radius : Float, node_size : @math.Vec2) -> Float {
  let clamped = clamp_nonneg(radius)
  let min_elem = if node_size.x < node_size.y {
    node_size.x
  } else {
    node_size.y
  }
  let max_r = 0.5F * min_elem
  if clamped > max_r {
    max_r
  } else {
    clamped
  }
}
