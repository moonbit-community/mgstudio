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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/color_plane.rs`.

///|
pub(all) enum ColorPlane {
  Rg
  Rb
  Gb
  HueSat
  HueValue
  SatValue
} derive(Eq, Debug)

///|
pub struct ColorPlaneValue {
  x : Float
  y : Float
  z : Float
}

///|
pub fn ColorPlaneValue::new(x : Float, y : Float, z : Float) -> ColorPlaneValue {
  ColorPlaneValue::{ x, y, z }
}

///|
pub struct ColorPlaneWidget {
  plane : ColorPlane
  value : ColorPlaneValue
}

///|
pub fn color_plane(
  plane : ColorPlane,
  value : ColorPlaneValue,
) -> ColorPlaneWidget {
  ColorPlaneWidget::{ plane, value }
}

///|
pub struct ColorPlanePlugin {}

///|
pub fn ColorPlanePlugin::default() -> ColorPlanePlugin {
  ColorPlanePlugin::{  }
}

///|
pub fn color_plane_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ensure_controls_runtime(app)
}
