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
// Bevy source: `bevy/crates/bevy_mesh/src/primitives/dim3/capsule.rs`.

///|
pub fn capsule3d(radius : Float, length : Float) -> @math.Capsule3d {
  @math.Capsule3d::new(radius, length)
}

///|
pub fn capsule3d_unit() -> @math.Capsule3d {
  capsule3d(0.5, 1.0)
}
