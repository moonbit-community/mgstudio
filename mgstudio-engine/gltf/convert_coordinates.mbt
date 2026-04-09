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
pub(all) struct GltfConvertCoordinates {
  rotate_scene_entity : Bool
  rotate_meshes : Bool
}

///|
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

///|
pub fn GltfConvertCoordinates::default() -> GltfConvertCoordinates {
  { rotate_scene_entity: false, rotate_meshes: false }
}

///|
fn gltf_coordinate_conversion_transform() -> @transform.Transform {
  @transform.Transform::from_rotation(@math.Quat::from_rotation_y(@math.pi()))
}

///|
pub fn GltfConvertCoordinates::scene_conversion_transform(
  self : GltfConvertCoordinates,
) -> @transform.Transform {
  if self.rotate_scene_entity {
    gltf_coordinate_conversion_transform()
  } else {
    @transform.Transform::identity()
  }
}

///|
pub fn GltfConvertCoordinates::mesh_conversion_transform(
  self : GltfConvertCoordinates,
) -> @transform.Transform {
  if self.rotate_meshes {
    gltf_coordinate_conversion_transform()
  } else {
    @transform.Transform::identity()
  }
}

///|
pub fn GltfConvertCoordinates::mesh_conversion_transform_inverse(
  self : GltfConvertCoordinates,
) -> @transform.Transform {
  self.mesh_conversion_transform()
}
