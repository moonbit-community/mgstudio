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
// Bevy source: `bevy/crates/bevy_gltf/src/convert_coordinates.rs`.
pub fn gltf_convert_coordinates_vec3(value : @math.Vec3) -> @math.Vec3 {
  @math.Vec3::new(-value.x, value.y, -value.z)
}

///|
pub fn gltf_convert_coordinates_quat(value : @math.Quat) -> @math.Quat {
  @math.Quat::new(-value.x, value.y, -value.z, value.w)
}

///|
pub fn gltf_convert_coordinates_vec3_components(
  value : (Float, Float, Float),
) -> (Float, Float, Float) {
  (-value.0, value.1, -value.2)
}
