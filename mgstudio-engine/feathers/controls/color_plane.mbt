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
  RedGreen
  RedBlue
  GreenBlue
  HueSaturation
  HueLightness
} derive(Eq, Debug)

///|
pub fn ColorPlane::default() -> ColorPlane {
  HueLightness
}

///|
pub(all) struct ColorPlaneValue {
  value : @math.Vec3
}

///|
pub fn ColorPlaneValue::new(value : @math.Vec3) -> ColorPlaneValue {
  ColorPlaneValue::{ value, }
}

///|
pub fn ColorPlaneValue::default() -> ColorPlaneValue {
  ColorPlaneValue::new(@math.Vec3::zero())
}

///|
pub fn color_plane(plane : ColorPlane) -> (ColorPlane, ColorPlaneValue) {
  (plane, ColorPlaneValue::default())
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
